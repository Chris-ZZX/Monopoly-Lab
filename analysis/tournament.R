# analysis/tournament.R -- Task 4: let the players fight it out.
# Run from anywhere in the repo:  Rscript analysis/tournament.R   (about 2 minutes)
# Saves results/tournament.rds, which the slides read.
#
# Two tournaments:
#   personalities  the five personalities of the talk, all at one table
#   colour war     eight players, each buying only one colour set, so nobody
#                  competes for a city: which set wins a fair fight?

source(here::here("R", "board.R"))
source(here::here("R", "game.R"))
source(here::here("R", "strategies.R"))
board <- load_board()
cards <- load_cards(board)
set.seed(2026)

n_games    <- 5000
max_rounds <- 300

pers  <- personalities(board)
fans  <- set_fanatics(board)
res_p <- run_tournament(board, cards, pers, n_games, max_rounds)
res_c <- run_tournament(board, cards, fans, n_games, max_rounds)

out <- list(
  n_games = n_games, max_rounds = max_rounds,
  personalities = list(games = res_p, rates = win_rates(res_p, vapply(pers, `[[`, "", "name"))),
  colour_war    = list(games = res_c, rates = win_rates(res_c, vapply(fans, `[[`, "", "name")))
)
saveRDS(out, here::here("results", "tournament.rds"))
print(out$personalities$rates)
print(out$colour_war$rates)
