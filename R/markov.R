# Monopoly as a Markov chain. One step = one whole turn (including extra
# rolls after doubles, cards and Go To Jail).
#
# States: 1-40 are the squares (11 = Just Visiting), 41-43 are "in jail"
# before the 1st, 2nd and 3rd try to roll doubles.
#
# Assumptions:
# - cards are drawn at random every time (like reshuffling the deck), so
#   each card has probability 1/16
# - Get Out of Jail Free cards are treated as cards that don't move you
# - jail "stay": try for doubles up to 3 times, after the 3rd miss pay and
#   move with that roll; doubles out of jail don't give another roll
# - jail "pay": pay right away and play a normal turn from Just Visiting
#
#   P  <- transition_matrix(board, cards)   # 43 x 43
#   pi <- stationary(P)

N_JAIL_STATES <- RULES$max_jail_turns
N_STATES      <- N_SQUARES + N_JAIL_STATES

# The 36 outcomes of two dice.
DICE <- within(expand.grid(d1 = 1:6, d2 = 1:6), {
  total  <- d1 + d2
  double <- d1 == d2
})
P_DOUBLE <- mean(DICE$double)   # 1/6

# Names for the 43 states.
state_names <- function(board) {
  jail_sq <- board$pos[board$type == "jail"]
  nm <- board$name
  nm[jail_sq] <- "Just Visiting"
  c(nm, sprintf("In Jail %d", seq_len(N_JAIL_STATES)))   # before attempt 1, 2, 3
}

# Destination of each card in `deck` when drawn on square `pos`
# (cards that don't move you just return pos).
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

# L[s, ] = where you end up after landing on s, once Go To Jail and cards
# are applied. For normal squares the row is just a 1 at s.
landing_matrix <- function(board, cards) {
  L <- diag(N_STATES)
  jail_in <- N_SQUARES + 1
  L[board$pos[board$type == "go_to_jail"], ] <- 0
  L[board$pos[board$type == "go_to_jail"], jail_in] <- 1

  # Chest before Chance, because "go back 3" from Chance can hit a Chest.
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

# One roll from every square, split into no doubles (N) and doubles (D).
# The jail rows stay zero here.
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

# Transition matrix for one full turn. Pass `m` to reuse roll_matrices().
transition_matrix <- function(board, cards, jail = c("stay", "pay"),
                              m = roll_matrices(board, cards)) {
  jail    <- match.arg(jail)
  N       <- m$N
  D       <- m$D
  jail_sq <- board$pos[board$type == "jail"]
  js      <- N_SQUARES + seq_len(N_JAIL_STATES)   # jail states

  # If you get sent to jail during the turn, you stay there.
  E <- matrix(0, N_STATES, N_STATES)
  E[js[1], js[1]] <- 1
  # third double: straight to jail
  to_jail <- matrix(0, N_STATES, N_STATES)
  to_jail[seq_len(N_SQUARES), js[1]] <- 1

  # Start from the last roll and go backwards: on the 3rd roll doubles mean
  # jail, before that they mean move and roll again.
  P <- N + P_DOUBLE * to_jail + E
  for (r in seq_len(RULES$doubles_to_jail - 1)) P <- N + D %*% P + E

  # jail rows
  for (a in seq_along(js)) {
    if (jail == "pay") {
      P[js[a], ] <- P[jail_sq, ]   # pay, then normal turn
    } else {
      P[js[a], ] <- D[jail_sq, ]   # doubles: move out, no extra roll
      if (a < length(js)) {
        P[js[a], js[a + 1]] <- P[js[a], js[a + 1]] + (1 - P_DOUBLE)
      } else {
        P[js[a], ] <- P[js[a], ] + N[jail_sq, ]   # 3rd miss: pay and move
      }
    }
  }
  dimnames(P) <- list(state_names(board), state_names(board))
  P
}

# Stationary distribution: solve pi P = pi, replacing one equation by
# sum(pi) = 1.
stationary <- function(P) {
  n <- nrow(P)
  A <- t(P) - diag(n)
  A[n, ] <- 1
  pi <- solve(A, c(rep(0, n - 1), 1))
  names(pi) <- rownames(P)
  pi
}

# Share of turns ending on each of the 40 squares (jail states added to
# the jail square).
landing_probs <- function(board, cards, jail = c("stay", "pay")) {
  pi <- stationary(transition_matrix(board, cards, match.arg(jail)))
  jail_sq <- board$pos[board$type == "jail"]
  out <- pi[seq_len(N_SQUARES)]
  out[jail_sq] <- out[jail_sq] + sum(pi[-seq_len(N_SQUARES)])
  names(out) <- board$name
  out
}

# Expected landings per turn on each square, also counting the stops in
# between doubles (that's what matters for rent). Getting sent to jail counts
# as landing on the jail square, sitting in jail doesn't.
landings_per_turn <- function(board, cards, jail = c("stay", "pay")) {
  jail    <- match.arg(jail)
  m       <- roll_matrices(board, cards)
  pi      <- stationary(transition_matrix(board, cards, jail, m))
  N       <- m$N
  D       <- m$D
  M       <- N + D
  jail_sq <- board$pos[board$type == "jail"]
  js      <- N_SQUARES + seq_len(N_JAIL_STATES)

  # V[s, ] = expected landings during a turn that starts in s
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
