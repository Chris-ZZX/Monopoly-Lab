# Simulation check of the Markov chain: move one token around with random
# dice and cards (no money) and compare the share of turns in each state with
# pi. Doesn't use anything from markov.R, so it's an independent check.
# States are numbered like in markov.R.
#
#   states <- simulate_walk(board, cards, n_turns = 1e5)

simulate_walk <- function(board, cards, n_turns, jail = c("stay", "pay"),
                          start = 1L) {
  jail     <- match.arg(jail)
  jail_sq  <- board$pos[board$type == "jail"]
  jail_in  <- N_SQUARES + 1L
  last_try <- N_SQUARES + RULES$max_jail_turns
  type     <- board$type
  decks    <- lapply(split(cards, cards$deck), as.list)

  roll <- function() sample.int(6, 2, replace = TRUE)

  # apply Go To Jail / cards after landing on pos
  resolve <- function(pos) {
    if (type[pos] == "go_to_jail") return(jail_in)
    if (type[pos] %in% c("chance", "chest")) {
      deck <- decks[[type[pos]]]
      k    <- sample.int(length(deck$action), 1)
      new <- switch(deck$action[k],
                    advance         = deck$target_pos[k],
                    advance_nearest = nearest(pos, deck$target[k], board),
                    back            = move(pos, -deck$amount[k]),
                    jail            = jail_in,
                    pos)
      if (new != pos && new <= N_SQUARES) return(resolve(new))
      return(new)
    }
    pos
  }

  out   <- integer(n_turns)
  state <- as.integer(start)
  for (t in seq_len(n_turns)) {
    if (state > N_SQUARES) {                      # in jail
      if (jail == "pay") {
        state <- jail_sq                          # pay and play normally
      } else {
        d <- roll()
        if (d[1] == d[2] || state == last_try) {  # doubles or 3rd try
          state <- resolve(move(jail_sq, sum(d)))
        } else {
          state <- state + 1L
        }
        out[t] <- state
        next
      }
    }

    n_doubles <- 0
    repeat {
      d <- roll()
      if (d[1] == d[2]) n_doubles <- n_doubles + 1
      if (n_doubles == RULES$doubles_to_jail) { state <- jail_in; break }
      state <- resolve(move(state, sum(d)))
      if (state > N_SQUARES || d[1] != d[2]) break
    }
    out[t] <- state
  }
  out
}

# Total variation distance.
tv_distance <- function(p, q) sum(abs(p - q)) / 2

# TV distance to pi after the first n turns, for each n in checkpoints.
convergence <- function(states, pi, checkpoints) {
  vapply(checkpoints, function(n) {
    tv_distance(tabulate(states[seq_len(n)], nbins = length(pi)) / n, pi)
  }, numeric(1))
}
