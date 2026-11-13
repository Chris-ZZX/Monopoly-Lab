# Run all tests from anywhere in the repo:
#   Rscript -e 'testthat::test_dir(here::here("tests"))'

source(here::here("R", "board.R"))
board <- load_board()
cards <- load_cards(board)

test_that("board has the standard layout", {
  expect_equal(board$name[c(1, 11, 21, 31, 40)],
               c("GO", "Jail / Just Visiting", "Free Parking", "Go To Jail", "Paris"))
  expect_equal(as.vector(table(board$type)[c("street", "railroad", "utility")]),
               c(22, 4, 2))
  expect_equal(board$pos[board$type == "chance"], c(8, 23, 37))
  expect_equal(board$pos[board$type == "chest"], c(3, 18, 34))
})

test_that("colour groups have the right sizes", {
  sizes <- table(board$group)
  expect_equal(as.vector(sizes[names(GROUP_COLOURS)]), c(2, 3, 3, 3, 3, 3, 3, 2))
  expect_equal(board$name[board$group %in% "orange"],
               c("Stockholm", "Vienna", "Lisbon"))
})

test_that("each deck has 16 cards and the expected movers", {
  expect_equal(as.vector(table(cards$deck)[c("chance", "chest")]), c(16, 16))
  moves <- c("advance", "advance_nearest", "back", "jail")
  expect_equal(sum(cards$deck == "chance" & cards$action %in% moves), 10)
  expect_equal(sum(cards$deck == "chest" & cards$action %in% moves), 2)
  expect_setequal(cards$target_pos[cards$action == "advance"], c(1, 6, 12, 25, 40))
})

test_that("move() wraps around the board", {
  expect_equal(move(39, 3), 2)
  expect_equal(move(40, 1), 1)
  expect_equal(move(8, -3), 5)
  expect_equal(move(2, -3), 39)
  expect_equal(move(1:40, 40), 1:40)
})

test_that("nearest() finds the next railroad / utility from each Chance square", {
  expect_equal(sapply(c(8, 23, 37), nearest, type = "railroad", board = board), c(16, 26, 6))
  expect_equal(sapply(c(8, 23, 37), nearest, type = "utility", board = board), c(13, 29, 13))
})
