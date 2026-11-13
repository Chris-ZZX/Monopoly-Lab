# R/board.R -- the Monopoly board, card decks and rule constants.
# Board: 1999 Euro edition (22 European capitals, airports as stations), in euro.

# Everything else in this project builds on these objects. The data itself
# lives in data/board.csv and data/cards.csv (columns: data/README.md).

# ONE POSITION CONVENTION FOR THE WHOLE PROJECT
#   A square's position is its row number in `board`:
#     1 = GO, 11 = Jail / Just Visiting, 21 = Free Parking,
#     31 = Go To Jail, 40 = Paris.
#   Use the same numbers as row/column indices of transition matrices.
#   Move with move(pos, steps) so the board wraps around after square 40.

# Usage (works from any folder inside the repo):
#   source(here::here("R", "board.R"))
#   board <- load_board()
#   cards <- load_cards(board)

N_SQUARES <- 40L

SQUARE_TYPES <- c("go", "street", "railroad", "utility", "tax",
                  "chance", "chest", "jail", "parking", "go_to_jail")

CARD_ACTIONS <- c("advance", "advance_nearest", "back", "jail", "jail_free",
                  "collect", "pay", "collect_each", "pay_each", "repairs")

# Standard rules. Positions come from `board`, so only amounts
# and counts live here.
RULES <- list(
  starting_cash       = 1500,
  go_salary           = 200,
  jail_fine           = 50,              # pay to leave jail
  max_jail_turns      = 3,               # roll for doubles at most 3 turns, then pay and move
  doubles_to_jail     = 3,               # 3rd double in one turn sends you to jail
  full_set_multiplier = 2,               # unimproved street rent if owner holds the whole group
  railroad_rent       = c(25, 50, 100, 200),  # by number of railroads owned
  utility_multiplier  = c(4, 10)         # times the dice total, by number of utilities owned
)
# Not modelled: the bank's limit of 32 houses and 12 hotels (see R/game.R).

# Plot colour of each street group.
# Keep in sync with the pg-* colours in slides/beamerthemepassgo.sty.
GROUP_COLOURS <- c(brown = "#8B4513", light_blue = "#A6DCF5", pink = "#D93A96",
                   orange = "#F7941D", red = "#ED1B24", yellow = "#FEF200",
                   green = "#1FB25A", dark_blue = "#0072BB")


load_board <- function(path = here::here("data", "board.csv")) {
  board <- utils::read.csv(path, na.strings = "", stringsAsFactors = FALSE,
                           fileEncoding = "UTF-8")

  buyable <- board$type %in% c("street", "railroad", "utility")
  street  <- board$type == "street"
  rents   <- c("rent", "rent_1h", "rent_2h", "rent_3h", "rent_4h", "rent_hotel")

  stopifnot(
    "board.csv: need 40 squares with pos = 1, 2, ..., 40" =
      identical(board$pos, seq_len(N_SQUARES)),
    "board.csv: unknown type (allowed: see SQUARE_TYPES)" =
      all(board$type %in% SQUARE_TYPES),
    "board.csv: every street, railroad and utility needs a price" =
      !anyNA(board$price[buyable]),
    "board.csv: every street needs a group, house_cost and all six rents" =
      !anyNA(board[street, c("group", "house_cost", rents)]),
    "board.csv: unknown group (allowed: see GROUP_COLOURS)" =
      all(board$group[street] %in% names(GROUP_COLOURS)),
    "board.csv: every tax square needs a tax amount" =
      !anyNA(board$tax[board$type == "tax"])
  )
  board
}


# Adds `target_pos`: the position an `advance` card sends you to (NA otherwise).
load_cards <- function(board = load_board(),
                       path = here::here("data", "cards.csv")) {
  cards <- utils::read.csv(path, na.strings = "", stringsAsFactors = FALSE,
                           fileEncoding = "UTF-8")

  is_advance   <- cards$action == "advance"
  is_nearest   <- cards$action == "advance_nearest"
  needs_amount <- cards$action %in% c("back", "collect", "pay",
                                      "collect_each", "pay_each", "repairs")

  cards$target_pos <- NA_integer_
  cards$target_pos[is_advance] <- match(cards$target[is_advance], board$name)

  stopifnot(
    "cards.csv: deck must be 'chance' or 'chest'" =
      all(cards$deck %in% c("chance", "chest")),
    "cards.csv: unknown action (allowed: see CARD_ACTIONS)" =
      all(cards$action %in% CARD_ACTIONS),
    "cards.csv: 'advance' target must be a square name from board.csv" =
      !anyNA(cards$target_pos[is_advance]),
    "cards.csv: 'advance_nearest' target must be a square type" =
      all(cards$target[is_nearest] %in% SQUARE_TYPES),
    "cards.csv: this action needs an amount" =
      !anyNA(cards$amount[needs_amount]),
    "cards.csv: 'repairs' needs amount_hotel" =
      !anyNA(cards$amount_hotel[cards$action == "repairs"])
  )
  cards
}


# Square reached after moving `steps` squares from `pos` (negative = backwards).
# Vectorised: move(1:40, 7) gives the landing square from every square.
move <- function(pos, steps) {
  (pos - 1L + steps) %% N_SQUARES + 1L
}

# First square of `type` strictly ahead of `pos`, wrapping past GO.
# Example: nearest(37, "railroad", board) is 6 (Amsterdam Schiphol).
nearest <- function(pos, type, board) {
  targets <- board$pos[board$type == type]
  ahead <- targets[targets > pos]
  if (length(ahead) > 0) min(ahead) else min(targets)
}
