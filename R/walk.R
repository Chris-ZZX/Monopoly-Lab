# R/walk.R -- check the Markov chain by simulation (Task 2).
#
# simulate_walk() rolls real dice and draws real cards for one token, turn by
# turn, with no money involved. It does not use any matrix from R/markov.R,
# so it is an independent check: if both are right, the share of turns spent
# in each state converges to the stationary distribution pi.
#
# States are numbered as in R/markov.R: 1..40 squares (11 = Just Visiting),
# 41..43 in jail before attempt 1, 2, 3.
#
# Usage:
#   set.seed(1)
#   states <- simulate_walk(board, cards, n_turns = 1e5, jail = "stay")
#   empirical <- tabulate(states, nbins = N_STATES) / length(states)

simulate_walk <- function(board, cards, n_turns, jail = c("stay", "pay"),
                          start = 1L) {
  jail     <- match.arg(jail)
  jail_sq  <- board$pos[board$type == "jail"]
  jail_in  <- N_SQUARES + 1L
  last_try <- N_SQUARES + RULES$max_jail_turns
  type     <- board$type
  decks    <- lapply(split(cards, cards$deck), as.list)   # columns as vectors

  roll <- function() sample.int(6, 2, replace = TRUE)

  # Square effects after landing on `pos`: Go To Jail and cards.
  # Returns the final state (a square, or jail_in).
  resolve <- function(pos) {
    if (type[pos] == "go_to_jail") return(jail_in)
    if (type[pos] %in% c("chance", "chest")) {
      deck <- decks[[type[pos]]]
      k    <- sample.int(length(deck$action), 1)   # a fresh random draw
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
        state <- jail_sq                          # pay, then a normal turn
      } else {
        d <- roll()
        if (d[1] == d[2] || state == last_try) {  # doubles, or pay on last try
          state <- resolve(move(jail_sq, sum(d)))
        } else {
          state <- state + 1L
        }
        out[t] <- state
        next
      }
    }

    n_doubles <- 0
    repeat {                                      # a normal turn
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

# Total variation distance between two distributions: the largest possible
# difference in probability that p and q give to the same event.
tv_distance <- function(p, q) sum(abs(p - q)) / 2

# Distance between the empirical distribution of the first n turns of `states`
# and `pi`, for each n in `checkpoints`.
convergence <- function(states, pi, checkpoints) {
  vapply(checkpoints, function(n) {
    tv_distance(tabulate(states[seq_len(n)], nbins = length(pi)) / n, pi)
  }, numeric(1))
}
