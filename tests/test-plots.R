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
    expect_match(tikz, paste0(streets$name[i], "}"), fixed = TRUE)
  }
  expect_match(tikz, "\\fill[pg-orange]", fixed = TRUE)
})

test_that("long names are shortened and LaTeX characters escaped", {
  expect_true(all(names(SHORT_NAMES) %in% board$name))
  expect_equal(latex_escape("A & B_1"), "A \\& B\\_1")
})

test_that("jail_exit_tikz draws the squares after Jail with dice bars", {
  tikz <- jail_exit_tikz(board)
  nodes <- regmatches(tikz, regexpr("\\(ex[0-9]+\\) at", tikz))
  expect_equal(nodes, sprintf("(ex%d) at", 1:12))
  expect_true(any(grepl("(exjail)", tikz, fixed = TRUE)))
  # Bar labels: number of dice rolls with total 2, ..., 12 (+1 has no bar).
  labels <- as.integer(sub(".*\\{([0-9]+)\\};$", "\\1",
                           grep("anchor=south] at \\(bar", tikz, value = TRUE)))
  expect_equal(labels, c(1:6, 5:1))
  # The orange squares (Jail + 6, 8, 9) get a ring.
  expect_equal(sum(grepl("pg-orange, line width=1.8pt", tikz)), 3)
  chars <- strsplit(paste(tikz, collapse = ""), "")[[1]]
  expect_equal(sum(chars == "{"), sum(chars == "}"))
})
