# R/strategies.R -- player personalities and tournaments (Task 4).
#
# A player is a list (see R/game.R): name, buy(game, me, pos), reserve, jail.
# All players build houses evenly on every full set they own, keeping their
# reserve; they differ in what they buy and how much cash they keep.
#
# Usage:
#   players <- personalities(board)
#   res <- run_tournament(board, cards, players, n_games = 100)
#   win_rates(res)

make_player <- function(name, buy, reserve = 100, jail = "pay") {
  list(name = name, buy = buy, reserve = reserve, jail = jail)
}

# Buy-functions for a set of positions.
buys_only <- function(positions) function(game, me, pos) pos %in% positions

# The five personalities of the talk.
personalities <- function(board) {
  of <- function(cond) board$pos[cond]
  list(
    make_player("Orange Fanatic", buys_only(of(board$group %in% "orange")), reserve = 50),
    make_player("Hoarder",        function(game, me, pos) TRUE,             reserve = 100),
    make_player("Paris Snob",     buys_only(of(board$group %in% "dark_blue")), reserve = 50),
    make_player("Jet-Setter",     buys_only(of(board$type == "railroad")),  reserve = 50),
    make_player("Grandma",        function(game, me, pos) FALSE,            reserve = 0)
  )
}

# One player per colour set, each buying only its own set. Nobody competes for
# a city, so the game compares the sets themselves. A set is completed only if
# its owner lands on every one of its squares before going bankrupt.
set_fanatics <- function(board, reserve = 50) {
  groups <- names(GROUP_COLOURS)
  lapply(groups, function(gr) {
    make_player(gr, buys_only(board$pos[board$group %in% gr]), reserve = reserve)
  })
}

# Play n_games games. The seating order is shuffled every game, so nobody
# profits from always moving first. Returns one row per game. Columns
# `<set>_by` name the player who first owned the whole colour set (NA if
# nobody did), for example `orange_by`.
run_tournament <- function(board, cards, players, n_games, max_rounds = 300) {
  rows <- lapply(seq_len(n_games), function(i) {
    seats <- sample(length(players))
    res <- play_game(board, cards, players[seats], max_rounds)
    sets <- as.data.frame(as.list(setNames(res$first_set$by,
                                           paste0(res$first_set$set, "_by"))))
    cbind(data.frame(game = i, winner = res$name, rounds = res$rounds,
                     ended = res$ended, first = players[[seats[1]]]$name), sets)
  })
  do.call(rbind, rows)
}

# Win rate of every player with an exact 95% binomial confidence interval
# (Clopper-Pearson, from binom.test).
win_rates <- function(results, players = unique(results$winner)) {
  n <- nrow(results)
  out <- lapply(players, function(p) {
    wins <- sum(results$winner == p)
    ci <- stats::binom.test(wins, n)$conf.int
    data.frame(player = p, wins = wins, games = n, rate = wins / n,
               lower = ci[1], upper = ci[2])
  })
  out <- do.call(rbind, out)
  out[order(-out$rate), ]
}
