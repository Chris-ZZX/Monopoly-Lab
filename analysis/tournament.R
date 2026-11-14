# The two tournaments (takes about 2 minutes), saved to results/tournament.rds.
# 1) our five players at one table
# 2) one player per colour set, to see which set wins when nobody competes

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
