source(here::here("R", "board.R"))
source(here::here("R", "game.R"))
source(here::here("R", "strategies.R"))
board <- load_board()
cards <- load_cards(board)

test_that("personalities buy what they promise", {
  pl <- personalities(board)
  names(pl) <- vapply(pl, `[[`, "", "name")
  vienna <- which(board$name == "Vienna")
  paris  <- which(board$name == "Paris")
  expect_true(pl[["Orange Fanatic"]]$buy(NULL, 1, vienna))
  expect_false(pl[["Orange Fanatic"]]$buy(NULL, 1, paris))
  expect_true(pl[["Paris Snob"]]$buy(NULL, 1, paris))
  expect_true(all(vapply(board$pos[board$type == "railroad"],
                         function(p) pl[["Jet-Setter"]]$buy(NULL, 1, p), TRUE)))
  expect_false(pl[["Grandma"]]$buy(NULL, 1, vienna))
})

test_that("set fanatics cover each colour set exactly once", {
  sf <- set_fanatics(board)
  expect_equal(vapply(sf, `[[`, "", "name"), names(GROUP_COLOURS))
  street <- board$pos[board$type == "street"]
  buyers <- vapply(street, function(p) sum(vapply(sf, function(pl) pl$buy(NULL, 1, p), TRUE)), 1)
  expect_true(all(buyers == 1))
})

test_that("tournament and win rates have the right shape", {
  set.seed(9)
  res <- run_tournament(board, cards, personalities(board), n_games = 10)
  expect_equal(nrow(res), 10)
  wr <- win_rates(res, vapply(personalities(board), `[[`, "", "name"))
  expect_equal(sum(wr$wins), 10)
  expect_true(all(wr$lower <= wr$rate & wr$rate <= wr$upper))
})
