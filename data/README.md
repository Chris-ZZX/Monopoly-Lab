# Board data

Two small tables describe the whole game. Change game facts here, never inside R code. Load them with `load_board()` and `load_cards(board)` from `R/board.R`. Both functions check the files and stop with a clear message if something is wrong.

An empty cell means "not applicable" and becomes `NA` in R. Files are UTF-8 (the cards use €).

## Edition

We use the **1999 Monopoly Euro edition** (Waddingtons/Hasbro). Its 22 properties are European capitals, its stations are four airports and its utilities are the European Parliament and the European Court of Justice. Amounts are in euro. The orange set is Stockholm, **Vienna** and Lisbon.

- Sources: [World of Monopoly, 1999 Euro edition](https://www.worldofmonopoly.com/europe/european/1999-euro/uk/index.php) and [Wikipedia](https://en.wikipedia.org/wiki/List_of_licensed_and_localized_editions_of_Monopoly:_Europe). Capitals are written in English (the board itself says "Bukarest", "Genève").
- Geneva is kept as printed. The 1999 board names it the capital of Switzerland; a 2001 reprint corrected it to Bern.
- The sources only list the capitals per colour set. We assume the standard layout, prices, rents, house costs and card effects. Within each set, and for the airports and utilities, we take the listed order as the board order.
- In the data, airports have type `railroad`: they follow the station rules.
- Income Tax is a flat €200.

## board.csv: one row per square, in board order

| Column | Meaning |
|---|---|
| `pos` | Position 1–40, equal to the row number. 1 = GO, 11 = Jail / Just Visiting, 21 = Free Parking, 31 = Go To Jail, 40 = Paris |
| `name` | Square name (Chance and Community Chest appear three times each) |
| `type` | `go`, `street`, `railroad` (an airport here), `utility`, `tax`, `chance`, `chest`, `jail`, `parking`, `go_to_jail` |
| `group` | Colour set of a capital: `brown`, `light_blue`, `pink`, `orange`, `red`, `yellow`, `green`, `dark_blue` |
| `country` | Country of the capital |
| `price` | Purchase price in € (capitals, airports, utilities) |
| `house_cost` | Cost of one house. A hotel costs one more `house_cost` and replaces 4 houses |
| `rent`, `rent_1h` … `rent_4h`, `rent_hotel` | Rent with 0–4 houses or a hotel |
| `tax` | Amount paid when landing on a tax square |

Rules that are not per-square live in `RULES` in `R/board.R`: railroad and utility rents (they depend on how many you own), double rent for an unimproved full set, the GO salary, jail rules, starting cash and house supply.

## cards.csv: 16 Chance + 16 Community Chest cards

| Column | Meaning |
|---|---|
| `deck` | `chance` or `chest` |
| `action` | What the card does (see below) |
| `target` | A square **name** for `advance`, a square **type** for `advance_nearest` |
| `amount` | Euros; spaces for `back`; per house for `repairs` |
| `amount_hotel` | Per hotel, for `repairs` only |
| `text` | Short description of the card |

`load_cards()` adds `target_pos`, the position an `advance` card sends you to.

| `action` | Effect | Moves you? |
|---|---|---|
| `advance` | Move forward to `target`; collect the GO salary if you pass GO | yes |
| `advance_nearest` | Move forward to the next square of that type (see the card text for the rent) | yes |
| `back` | Move back `amount` squares | yes |
| `jail` | Go directly to jail | yes |
| `jail_free` | Keep it; use it to leave jail | no |
| `collect` / `pay` | Receive from / pay to the bank | no |
| `collect_each` / `pay_each` | Receive from / pay to every other player | no |
| `repairs` | Pay `amount` per house and `amount_hotel` per hotel you own | no |

For the Markov chain only the moving cards matter: 10 of 16 Chance cards and 2 of 16 Community Chest cards.
