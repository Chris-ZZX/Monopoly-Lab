source(here::here("R", "board.R"))
source(here::here("R", "markov.R"))
board <- load_board()
cards <- load_cards(board)

test_that("dice table has 36 outcomes, 6 doubles", {
  expect_equal(nrow(DICE), 36)
  expect_equal(P_DOUBLE, 1 / 6)
  expect_equal(as.vector(table(DICE$total)), c(1:6, 5:1))
})

test_that("landing matrix resolves Go To Jail and cards", {
  L <- landing_matrix(board, cards)
  expect_true(all(abs(rowSums(L) - 1) < 1e-12))
  expect_equal(L[31, N_SQUARES + 1], 1)
  # Chance on square 8: 6/16 stay, Go to Jail card 1/16.
  expect_equal(L[8, 8], 6 / 16)
  expect_equal(L[8, N_SQUARES + 1], 1 / 16)
  # Chance on 37 "go back 3" lands on Community Chest (34), which draws again.
  expect_equal(L[37, 34], 1 / 16 * 14 / 16)
})

test_that("transition matrices are stochastic for both jail strategies", {
  for (j in c("stay", "pay")) {
    P <- transition_matrix(board, cards, j)
    expect_equal(dim(P), c(N_STATES, N_STATES))
    expect_true(all(P >= 0))
    expect_true(all(abs(rowSums(P) - 1) < 1e-12))
  }
})

test_that("three doubles in a row send you to jail", {
  P <- transition_matrix(board, cards, "stay")
  # From any square, jail is at least as likely as three doubles, (1/6)^3.
  expect_gt(P[21, N_SQUARES + 1], (1 / 6)^3)
  # Jail attempts: fail with prob 5/6 to the next attempt.
  expect_equal(unname(P[N_SQUARES + 1, N_SQUARES + 2]), 5 / 6)
  expect_equal(unname(P[N_SQUARES + 2, N_SQUARES + 3]), 5 / 6)
  # After the last attempt you always leave (unless a card sends you back).
  expect_equal(unname(P[N_SQUARES + 3, N_SQUARES + 2:3]), c(0, 0))
})

test_that("pi is stationary and sums to 1", {
  for (j in c("stay", "pay")) {
    P  <- transition_matrix(board, cards, j)
    pi <- stationary(P)
    expect_equal(sum(pi), 1)
    expect_true(all(pi >= -1e-15))
    expect_equal(drop(pi %*% P), pi, tolerance = 1e-12)
  }
  pi_pay <- stationary(transition_matrix(board, cards, "pay"))
  expect_equal(unname(pi_pay[N_SQUARES + 2:3]), c(0, 0))
})

test_that("landing_probs has 40 entries, sums to 1, Jail on top", {
  lp <- landing_probs(board, cards)
  expect_length(lp, N_SQUARES)
  expect_equal(sum(lp), 1)
  expect_equal(unname(which.max(lp)), board$pos[board$type == "jail"])
  # Go To Jail is never the end of a turn.
  expect_equal(unname(lp[board$type == "go_to_jail"]), 0)
})

test_that("landings per turn exceed one (extra rolls after doubles)", {
  v <- landings_per_turn(board, cards)
  expect_length(v, N_SQUARES)
  expect_gt(sum(v), 1)
  expect_lt(sum(v), 1 + 2 * P_DOUBLE)
})
