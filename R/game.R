# R/game.R -- "Monopoly lite": one full game with money (Task 3).
#
# KEPT   buying, rent (double rent on an unimproved full set, airports,
#        utilities), houses and hotels, all 32 cards, jail, bankruptcy.
#        The last player standing wins; at the round cap the richest wins.
# DROPPED  trading, auctions, mortgages, the house shortage.
#
# SIMPLIFICATIONS
#   * Cards are fresh random draws, as in the Markov chain. A Get Out of Jail
#     Free card is kept and used the next time the player is in jail.
#   * Players who cannot pay first sell houses back to the bank at half price.
#     If that is not enough, they are bankrupt: their cash and properties go
#     to the creditor (or back to the bank if they owe the bank).
#
# PLAYERS are lists made by make_player() in R/strategies.R:
#   name     label for results
#   buy      function(game, me, pos): TRUE to buy the unowned square `pos`
#   reserve  cash the player always keeps when buying or building
#   jail     "pay" (leave at once) or "stay" (try for doubles)
#
# Usage:
#   set.seed(1)
#   res <- play_game(board, cards, list(player_a, player_b), max_rounds = 300)
#   res$winner

# Facts about the board that the game looks up again and again.
game_info <- function(board) {
  street <- board$type == "street"
  list(
    type      = board$type,
    price     = board$price,
    tax       = board$tax,
    group     = board$group,
    house     = board$house_cost,
    rents     = unname(as.matrix(board[, c("rent", "rent_1h", "rent_2h", "rent_3h",
                                           "rent_4h", "rent_hotel")])),
    buyable   = board$type %in% c("street", "railroad", "utility"),
    members   = split(board$pos[street], board$group[street]),
    railroads = board$pos[board$type == "railroad"],
    utilities = board$pos[board$type == "utility"],
    jail_sq   = board$pos[board$type == "jail"]
  )
}

new_game <- function(board, players) {
  n <- length(players)
  list(cash      = rep(RULES$starting_cash, n),
       pos       = rep(board$pos[board$type == "go"], n),
       alive     = rep(TRUE, n),
       jail_try  = integer(n),   # 0 = free; k = in jail before attempt k
       jail_card = integer(n),   # Get Out of Jail Free cards held
       owner     = integer(N_SQUARES),   # 0 = bank
       houses    = integer(N_SQUARES))   # 0-4 houses, 5 = hotel
}

# Does player p own every street of the group of square `pos`?
owns_set <- function(g, info, p, pos) {
  all(g$owner[info$members[[info$group[pos]]]] == p)
}

net_worth <- function(g, info, p) {
  mine <- which(g$owner == p)
  g$cash[p] + sum(info$price[mine]) + sum(g$houses[mine] * info$house[mine], na.rm = TRUE)
}

# ---- Money -------------------------------------------------------------------

# Player p pays `amount` to player `to` (0 = the bank). Sells houses if needed;
# goes bankrupt if even that is not enough.
pay <- function(g, info, p, to, amount) {
  if (amount <= 0 || !g$alive[p]) return(g)
  # Sell houses at half price, always from the most built-up street, so the
  # sets stay evenly built.
  while (g$cash[p] < amount && any(g$houses[g$owner == p] > 0)) {
    mine <- which(g$owner == p & g$houses > 0)
    s <- mine[which.max(g$houses[mine])]
    g$houses[s] <- g$houses[s] - 1L
    g$cash[p] <- g$cash[p] + info$house[s] / 2
  }
  if (g$cash[p] >= amount) {
    g$cash[p] <- g$cash[p] - amount
    if (to > 0) g$cash[to] <- g$cash[to] + amount
    return(g)
  }
  # Bankrupt.
  if (to > 0) g$cash[to] <- g$cash[to] + g$cash[p]
  g$owner[g$owner == p] <- to
  g$cash[p]  <- 0
  g$alive[p] <- FALSE
  g
}

# Rent for landing on the owned square `pos`. `card` is "railroad" or
# "utility" when an advance-to-nearest card sent the player there.
rent <- function(g, info, pos, dice_total, card = "") {
  o <- g$owner[pos]
  switch(info$type[pos],
    street = {
      h <- g$houses[pos]
      if (h > 0) info$rents[pos, h + 1]
      else info$rents[pos, 1] * (if (owns_set(g, info, o, pos)) RULES$full_set_multiplier else 1)
    },
    railroad = {
      n <- sum(g$owner[info$railroads] == o)
      RULES$railroad_rent[n] * (if (card == "railroad") 2 else 1)
    },
    utility = {
      n <- sum(g$owner[info$utilities] == o)
      if (card == "utility") {   # the card says: roll again, pay 10 times
        max(RULES$utility_multiplier) * sum(sample.int(6, 2, replace = TRUE))
      } else {
        RULES$utility_multiplier[n] * dice_total
      }
    })
}

# ---- Moving ------------------------------------------------------------------

send_to_jail <- function(g, info, p) {
  g$pos[p] <- info$jail_sq
  g$jail_try[p] <- 1L
  g
}

# Move player p forward to square `to`, collecting the GO salary if passing GO.
advance_to <- function(g, p, to) {
  if (to <= g$pos[p]) g$cash[p] <- g$cash[p] + RULES$go_salary
  g$pos[p] <- to
  g
}

# Everything that happens after player p lands on square `pos`.
land <- function(g, info, board, cards, players, p, dice_total, card = "") {
  pos <- g$pos[p]
  switch(info$type[pos],
    go_to_jail = return(send_to_jail(g, info, p)),
    tax        = return(pay(g, info, p, 0, info$tax[pos])),
    chance     = ,
    chest      = return(draw_card(g, info, board, cards, players, p, dice_total)))

  if (!info$buyable[pos]) return(g)
  o <- g$owner[pos]
  if (o == 0) {
    if (players[[p]]$buy(g, p, pos) &&
        g$cash[p] - info$price[pos] >= players[[p]]$reserve) {
      g$cash[p]   <- g$cash[p] - info$price[pos]
      g$owner[pos] <- p
    }
  } else if (o != p) {
    g <- pay(g, info, p, o, rent(g, info, pos, dice_total, card))
  }
  g
}

draw_card <- function(g, info, board, cards, players, p, dice_total) {
  pos  <- g$pos[p]
  deck <- which(cards$deck == info$type[pos])
  k    <- deck[sample.int(length(deck), 1)]
  others <- setdiff(which(g$alive), p)
  switch(cards$action[k],
    advance = {
      g <- advance_to(g, p, cards$target_pos[k])
      g <- land(g, info, board, cards, players, p, dice_total)
    },
    advance_nearest = {
      g <- advance_to(g, p, nearest(pos, cards$target[k], board))
      g <- land(g, info, board, cards, players, p, dice_total, card = cards$target[k])
    },
    back = {
      g$pos[p] <- move(pos, -cards$amount[k])
      g <- land(g, info, board, cards, players, p, dice_total)
    },
    jail      = g <- send_to_jail(g, info, p),
    jail_free = g$jail_card[p] <- g$jail_card[p] + 1L,
    collect   = g$cash[p] <- g$cash[p] + cards$amount[k],
    pay       = g <- pay(g, info, p, 0, cards$amount[k]),
    collect_each = for (o in others) g <- pay(g, info, o, p, cards$amount[k]),
    pay_each     = for (o in others) g <- pay(g, info, p, o, cards$amount[k]),
    repairs = {
      h <- g$houses[g$owner == p]
      g <- pay(g, info, p, 0, cards$amount[k] * sum(h[h < 5]) +
                              cards$amount_hotel[k] * sum(h == 5))
    })
  g
}

# ---- Building ----------------------------------------------------------------

# Build houses evenly on every full set player p owns, keeping `reserve`.
build <- function(g, info, p, reserve) {
  repeat {
    sets <- Filter(function(m) all(g$owner[m] == p), info$members)
    if (length(sets) == 0) return(g)
    # Even building: only the least built-up streets of each set qualify.
    cand <- unlist(lapply(sets, function(m) m[g$houses[m] == min(g$houses[m]) & g$houses[m] < 5]))
    cand <- cand[g$cash[p] - info$house[cand] >= reserve]
    if (length(cand) == 0) return(g)
    s <- cand[order(g$houses[cand], info$house[cand])[1]]
    g$houses[s] <- g$houses[s] + 1L
    g$cash[p]   <- g$cash[p] - info$house[s]
  }
}

# ---- Turns and games ---------------------------------------------------------

take_turn <- function(g, info, board, cards, players, p) {
  g <- build(g, info, p, players[[p]]$reserve)

  if (g$jail_try[p] > 0) {
    if (g$jail_card[p] > 0) {
      g$jail_card[p] <- g$jail_card[p] - 1L
      g$jail_try[p] <- 0L
    } else if (players[[p]]$jail == "pay") {
      g <- pay(g, info, p, 0, RULES$jail_fine)
      g$jail_try[p] <- 0L
    } else {
      d <- sample.int(6, 2, replace = TRUE)
      if (d[1] != d[2] && g$jail_try[p] < RULES$max_jail_turns) {
        g$jail_try[p] <- g$jail_try[p] + 1L
        return(g)
      }
      if (d[1] != d[2]) g <- pay(g, info, p, 0, RULES$jail_fine)
      g$jail_try[p] <- 0L
      if (!g$alive[p]) return(g)
      g <- advance_to(g, p, move(g$pos[p], sum(d)))
      return(land(g, info, board, cards, players, p, sum(d)))
    }
    if (!g$alive[p]) return(g)
  }

  n_doubles <- 0
  repeat {
    d <- sample.int(6, 2, replace = TRUE)
    if (d[1] == d[2]) n_doubles <- n_doubles + 1
    if (n_doubles == RULES$doubles_to_jail) return(send_to_jail(g, info, p))
    g <- advance_to(g, p, move(g$pos[p], sum(d)))
    g <- land(g, info, board, cards, players, p, sum(d))
    if (!g$alive[p] || g$jail_try[p] > 0 || d[1] != d[2]) return(g)
  }
}

# Play one game. Players move in list order. Returns the winner's index and
# name, the number of rounds, how the game ended, everyone's net worth and
# `first_set`: for each colour set, the player who first owned all of it
# (NA if nobody did) and in which round.
play_game <- function(board, cards, players, max_rounds = 300) {
  info <- game_info(board)
  g    <- new_game(board, players)
  ended <- "time"
  first_by    <- setNames(rep(NA_integer_, length(info$members)), names(info$members))
  first_round <- first_by
  for (round in seq_len(max_rounds)) {
    for (p in seq_along(players)) {
      if (!g$alive[p]) next
      g <- take_turn(g, info, board, cards, players, p)
      for (s in names(info$members)[is.na(first_by)]) {
        o <- g$owner[info$members[[s]]]
        if (o[1] > 0 && all(o == o[1])) { first_by[s] <- o[1]; first_round[s] <- round }
      }
      if (sum(g$alive) == 1) { ended <- "bankruptcy"; break }
    }
    if (ended == "bankruptcy") break
  }
  worth <- vapply(seq_along(players), function(p) net_worth(g, info, p), numeric(1))
  worth[!g$alive] <- 0
  # After a bankruptcy finish the survivor wins, even with nothing left.
  winner <- if (ended == "bankruptcy") which(g$alive) else which.max(worth)
  names_ <- vapply(players, `[[`, "", "name")
  list(winner = winner, name = players[[winner]]$name, rounds = round,
       ended = ended, worth = setNames(worth, names_),
       first_set = data.frame(set = names(first_by), by = names_[first_by],
                              round = first_round, row.names = NULL),
       game = g)
}
