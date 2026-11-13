source(here::here("R", "board.R"))
source(here::here("R", "game.R"))
source(here::here("R", "strategies.R"))
board <- load_board()
cards <- load_cards(board)
info  <- game_info(board)
everything <- function(game, me, pos) TRUE
nothing    <- function(game, me, pos) FALSE
two <- list(make_player("A", everything), make_player("B", everything))

test_that("rent follows the rules", {
  g <- new_game(board, two)
  vienna <- which(board$name == "Vienna")
  orange <- info$members$orange
  g$owner[vienna] <- 1L
  expect_equal(rent(g, info, vienna, 7), board$rent[vienna])
  g$owner[orange] <- 1L                       # full set: double rent
  expect_equal(rent(g, info, vienna, 7), 2 * board$rent[vienna])
  g$houses[vienna] <- 5L                      # hotel
  expect_equal(rent(g, info, vienna, 7), board$rent_hotel[vienna])
  g$owner[info$railroads[1:3]] <- 2L          # 3 airports
  expect_equal(rent(g, info, info$railroads[1], 7), RULES$railroad_rent[3])
  expect_equal(rent(g, info, info$railroads[1], 7, card = "railroad"),
               2 * RULES$railroad_rent[3])
  g$owner[info$utilities] <- 2L               # both utilities
  expect_equal(rent(g, info, info$utilities[1], 9), 9 * RULES$utility_multiplier[2])
})

test_that("paying sells houses, then goes bankrupt to the creditor", {
  g <- new_game(board, two)
  orange <- info$members$orange
  g$owner[orange] <- 1L
  g$houses[orange] <- 2L
  g$cash <- c(10, 0)
  g <- pay(g, info, 1, 2, 60)                 # sells one house (50) -> pays
  expect_equal(g$cash, c(0, 60))
  expect_equal(sum(g$houses[orange]), 5)
  g <- pay(g, info, 1, 2, 10000)              # cannot pay -> bankrupt
  expect_false(g$alive[1])
  expect_true(all(g$owner[orange] == 2))
  expect_true(all(g$houses[orange] == 0))
})

test_that("building is even and keeps the reserve", {
  g <- new_game(board, two)
  orange <- info$members$orange
  g$owner[orange] <- 1L
  g$cash[1] <- 450
  g <- build(g, info, 1, reserve = 100)       # 3 houses of 100 fit
  expect_equal(sort(g$houses[orange]), c(1, 1, 1))
  expect_equal(g$cash[1], 150)
})

test_that("games end with a winner and conserve the rules", {
  set.seed(7)
  for (i in 1:20) {
    res <- play_game(board, cards, personalities(board), max_rounds = 200)
    expect_true(res$winner %in% seq_along(personalities(board)))
    expect_true(all(res$game$cash >= 0))
    expect_true(all(res$game$houses <= 5))
    expect_true(all(res$game$houses[res$game$owner == 0] == 0))
    if (res$ended == "bankruptcy") expect_equal(sum(res$game$alive), 1)
  }
})

test_that("Grandma never buys", {
  set.seed(8)
  pl <- list(make_player("Grandma", nothing), make_player("Grandma 2", nothing))
  res <- play_game(board, cards, pl, max_rounds = 50)
  expect_true(all(res$game$owner == 0))
  expect_equal(res$ended, "time")
})
