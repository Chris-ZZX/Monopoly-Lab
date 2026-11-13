# analysis/walk.R -- Task 2: check the Markov chain by simulation.
# Run from anywhere in the repo:  Rscript analysis/walk.R   (under 1 minute)
# Saves results/walk.rds, which slides/sections/03-markov.Rnw reads.

source(here::here("R", "board.R"))
source(here::here("R", "markov.R"))
source(here::here("R", "walk.R"))
board <- load_board()
cards <- load_cards(board)
set.seed(2026)

n_turns     <- 1e6
n_runs      <- 5
checkpoints <- round(10^seq(2, log10(n_turns), by = 0.25))

out <- list(checkpoints = checkpoints, n_turns = n_turns)
for (j in c("stay", "pay")) {
  pi <- stationary(transition_matrix(board, cards, j))
  runs <- lapply(seq_len(n_runs), function(r) simulate_walk(board, cards, n_turns, jail = j))
  out[[j]] <- list(
    pi        = pi,
    empirical = tabulate(runs[[1]], nbins = N_STATES) / n_turns,
    tv        = sapply(runs, convergence, pi = pi, checkpoints = checkpoints)
  )
}

saveRDS(out, here::here("results", "walk.rds"))
cat("TV distance after", n_turns, "turns:\n")
print(sapply(c("stay", "pay"), function(j) out[[j]]$tv[length(checkpoints), ]))
