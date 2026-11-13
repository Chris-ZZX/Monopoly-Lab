source(here::here("R", "board.R"))
source(here::here("R", "plots.R"))
board <- load_board()

test_that("board_tikz names one node per square", {
  tikz <- board_tikz(board)
  expect_type(tikz, "character")
  nodes <- regmatches(tikz, regexpr("\\(sq[0-9]+\\) at", tikz))
  expect_equal(nodes, sprintf("(sq%d) at", seq_len(N_SQUARES)))
  expect_true(any(grepl("(inner)", tikz, fixed = TRUE)))
  # Unbalanced braces would break the LaTeX build.
  chars <- strsplit(paste(tikz, collapse = ""), "")[[1]]
  expect_equal(sum(chars == "{"), sum(chars == "}"))
})

test_that("every street is drawn with its name and colour", {
  tikz <- paste(board_tikz(board), collapse = "\n")
  streets <- board[board$type == "street", ]
  for (i in seq_len(nrow(streets))) {
    expect_match(tikz, paste0("{", streets$name[i], "}"), fixed = TRUE)
  }
  expect_match(tikz, "\\fill[pg-orange]", fixed = TRUE)
})

test_that("long names are shortened and LaTeX characters escaped", {
  expect_true(all(names(SHORT_NAMES) %in% board$name))
  expect_equal(latex_escape("A & B_1"), "A \\& B\\_1")
})
