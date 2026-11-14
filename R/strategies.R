# Players and tournaments. A player is a list with name, buy(game, me, pos),
# reserve and jail (see game.R). Everyone builds the same way; they only
# differ in what they buy and how much cash they keep.

make_player <- function(name, buy, reserve = 100, jail = "pay") {
  list(name = name, buy = buy, reserve = reserve, jail = jail)
}

# buy() that only says yes to the given squares
buys_only <- function(positions) function(game, me, pos) pos %in% positions

# Our five players.
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

# One player per colour set, each only buys their own set, so nobody
# competes for the same city.
set_fanatics <- function(board, reserve = 50) {
  groups <- names(GROUP_COLOURS)
  lapply(groups, function(gr) {
    make_player(gr, buys_only(board$pos[board$group %in% gr]), reserve = reserve)
  })
}

# Play n_games games with shuffled seats. One row per game; the <set>_by
# columns (e.g. orange_by) say who completed that set first.
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

# Win rates with 95% Clopper-Pearson intervals (binom.test).
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
