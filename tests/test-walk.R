source(here::here("R", "board.R"))
source(here::here("R", "markov.R"))
source(here::here("R", "walk.R"))
board <- load_board()
cards <- load_cards(board)

test_that("simulated walk only visits valid states", {
  set.seed(1)
  s <- simulate_walk(board, cards, 2000)
  expect_length(s, 2000)
  expect_true(all(s >= 1 & s <= N_STATES))
  expect_false(any(s == board$pos[board$type == "go_to_jail"]))
  s_pay <- simulate_walk(board, cards, 2000, jail = "pay")
  expect_false(any(s_pay > N_SQUARES + 1))
})

test_that("simulation agrees with the Markov chain", {
  set.seed(42)
  for (j in c("stay", "pay")) {
    s  <- simulate_walk(board, cards, 50000, jail = j)
    pi <- stationary(transition_matrix(board, cards, j))
    expect_lt(tv_distance(tabulate(s, nbins = N_STATES) / length(s), pi), 0.02)
  }
})

test_that("tv_distance is half the L1 distance", {
  expect_equal(tv_distance(c(1, 0), c(0, 1)), 1)
  expect_equal(tv_distance(c(0.5, 0.5), c(0.5, 0.5)), 0)
})
