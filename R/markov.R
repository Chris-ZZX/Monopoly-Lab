# R/markov.R -- Monopoly as a Markov chain (Task 1).
#
# One step of the chain is one full turn of one player: the first roll, any
# extra rolls after doubles, card moves and Go To Jail.
#
# STATES (N_STATES = 43)
#   1..40   the squares, by position. State 11 means "Just Visiting".
#   41..43  "In Jail", about to make attempt 1, 2 or 3 to roll doubles.
#
# ASSUMPTIONS
#   * Every card is a fresh random draw from its deck (as if the deck were
#     reshuffled before each draw), so each card has probability 1/16.
#   * Get Out of Jail Free cards are never used: they count as cards that do
#     not move you.
#   * Jail strategy "stay": try for doubles on up to 3 turns; after the third
#     failed attempt, pay the fine and move by that roll. Leaving with doubles
#     does not give an extra roll.
#     Jail strategy "pay": pay the fine at once and take a normal turn from
#     Just Visiting, so attempts 2 and 3 never happen.
#
# Usage:
#   P  <- transition_matrix(board, cards)       # 43 x 43, rows sum to 1
#   pi <- stationary(P)                         # long-run share of turns
#   landing_probs(board, cards)                 # the same, per square (40)

N_JAIL_STATES <- RULES$max_jail_turns
N_STATES      <- N_SQUARES + N_JAIL_STATES

# All 36 outcomes of two dice, each with probability 1/36.
DICE <- within(expand.grid(d1 = 1:6, d2 = 1:6), {
  total  <- d1 + d2
  double <- d1 == d2
})
P_DOUBLE <- mean(DICE$double)   # 1/6

# Readable names for the 43 states.
state_names <- function(board) {
  jail_sq <- board$pos[board$type == "jail"]
  nm <- board$name
  nm[jail_sq] <- "Just Visiting"
  c(nm, sprintf("In Jail %d", seq_len(N_JAIL_STATES)))   # before attempt 1, 2, 3
}

# Where each card of `deck` sends a token that drew it on square `pos`.
# One entry per card; non-moving cards return `pos` itself.
card_destinations <- function(deck, pos, board, cards) {
  d <- cards[cards$deck == deck, ]
  jail_in <- N_SQUARES + 1
  vapply(seq_len(nrow(d)), function(k) {
    switch(d$action[k],
           advance         = d$target_pos[k],
           advance_nearest = nearest(pos, d$target[k], board),
           back            = move(pos, -d$amount[k]),
           jail            = jail_in,
           pos)
  }, numeric(1))
}

# L[s, ]: where a token that has just landed on square s really ends up,
# after Go To Jail and cards. Rows of other squares are unit vectors.
landing_matrix <- function(board, cards) {
  L <- diag(N_STATES)
  jail_in <- N_SQUARES + 1
  L[board$pos[board$type == "go_to_jail"], ] <- 0
  L[board$pos[board$type == "go_to_jail"], jail_in] <- 1

  # Community Chest first: Chance "go back 3" can land on a Community Chest.
  for (deck in c("chest", "chance")) {
    for (pos in board$pos[board$type == deck]) {
      dest <- card_destinations(deck, pos, board, cards)
      row  <- numeric(N_STATES)
      for (d in dest) {
        row <- row + (if (d == pos) diag(N_STATES)[pos, ] else L[d, ]) / length(dest)
      }
      L[pos, ] <- row
    }
  }
  L
}

# One roll of the dice from each square, split by doubles / no doubles.
#   N[s, ] = P(roll is not doubles, end up in each state)
#   D[s, ] = P(roll is doubles,     end up in each state)
# Rows of the jail states are zero.
roll_matrices <- function(board, cards) {
  L <- landing_matrix(board, cards)
  N <- D <- matrix(0, N_STATES, N_STATES)
  for (s in seq_len(N_SQUARES)) {
    for (k in seq_len(nrow(DICE))) {
      row <- L[move(s, DICE$total[k]), ] / nrow(DICE)
      if (DICE$double[k]) D[s, ] <- D[s, ] + row else N[s, ] <- N[s, ] + row
    }
  }
  list(N = N, D = D)
}

# Transition matrix of one full turn, N_STATES x N_STATES.
# `m` lets callers reuse roll_matrices() they already computed.
transition_matrix <- function(board, cards, jail = c("stay", "pay"),
                              m = roll_matrices(board, cards)) {
  jail    <- match.arg(jail)
  N       <- m$N
  D       <- m$D
  jail_sq <- board$pos[board$type == "jail"]
  js      <- N_SQUARES + seq_len(N_JAIL_STATES)   # the in-jail states

  # E keeps a token that went to jail mid-turn in jail for the rest of the turn.
  E <- matrix(0, N_STATES, N_STATES)
  E[js[1], js[1]] <- 1
  # To_jail: from any square straight to jail (the last allowed double).
  to_jail <- matrix(0, N_STATES, N_STATES)
  to_jail[seq_len(N_SQUARES), js[1]] <- 1

  # Work backwards from the last roll. On roll number RULES$doubles_to_jail,
  # doubles send you to jail without moving; on earlier rolls doubles mean
  # "move, then roll again".
  P <- N + P_DOUBLE * to_jail + E
  for (r in seq_len(RULES$doubles_to_jail - 1)) P <- N + D %*% P + E

  # Rows of the in-jail states.
  for (a in seq_along(js)) {
    if (jail == "pay") {
      P[js[a], ] <- P[jail_sq, ]   # pay the fine, then a normal turn
    } else {
      P[js[a], ] <- D[jail_sq, ]   # doubles: leave and move, no extra roll
      if (a < length(js)) {
        P[js[a], js[a + 1]] <- P[js[a], js[a + 1]] + (1 - P_DOUBLE)
      } else {
        P[js[a], ] <- P[js[a], ] + N[jail_sq, ]   # last attempt: pay and move
      }
    }
  }
  dimnames(P) <- list(state_names(board), state_names(board))
  P
}

# Stationary distribution: the row vector pi with pi P = pi and sum(pi) = 1.
# Solves (P^T - I) pi = 0 with one equation replaced by sum(pi) = 1.
stationary <- function(P) {
  n <- nrow(P)
  A <- t(P) - diag(n)
  A[n, ] <- 1
  pi <- solve(A, c(rep(0, n - 1), 1))
  names(pi) <- rownames(P)
  pi
}

# Long-run share of turns that end on each square (length 40, sums to 1).
# Turns that end in jail count for the jail square.
landing_probs <- function(board, cards, jail = c("stay", "pay")) {
  pi <- stationary(transition_matrix(board, cards, match.arg(jail)))
  jail_sq <- board$pos[board$type == "jail"]
  out <- pi[seq_len(N_SQUARES)]
  out[jail_sq] <- out[jail_sq] + sum(pi[-seq_len(N_SQUARES)])
  names(out) <- board$name
  out
}

# Expected number of times per turn that a token lands on each square
# (length 40), counting every landing, also the ones in between doubles.
# This is what rent depends on. Being sent to jail counts as a landing on the
# jail square; sitting in jail does not.
landings_per_turn <- function(board, cards, jail = c("stay", "pay")) {
  jail    <- match.arg(jail)
  m       <- roll_matrices(board, cards)
  pi      <- stationary(transition_matrix(board, cards, jail, m))
  N       <- m$N
  D       <- m$D
  M       <- N + D
  jail_sq <- board$pos[board$type == "jail"]
  js      <- N_SQUARES + seq_len(N_JAIL_STATES)

  # V[s, ]: expected landings on each state during a turn that starts in s.
  to_jail <- matrix(0, N_STATES, N_STATES)
  to_jail[seq_len(N_SQUARES), js[1]] <- 1
  V <- N + P_DOUBLE * to_jail
  for (r in seq_len(RULES$doubles_to_jail - 1)) V <- M + D %*% V
  for (a in seq_along(js)) {
    V[js[a], ] <- if (jail == "pay") V[jail_sq, ]
                  else if (a < length(js)) D[jail_sq, ]
                  else M[jail_sq, ]
  }

  visits <- drop(pi %*% V)
  out <- visits[seq_len(N_SQUARES)]
  out[jail_sq] <- out[jail_sq] + sum(visits[js])
  names(out) <- board$name
  out
}
