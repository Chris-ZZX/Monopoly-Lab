# Tasks

Pick an open task, put your name in the table and push the change. Each task owns its own files, so we rarely edit the same file.

**Scope.** Last year's decks (zombie grandmas, a South Park swear counter, a network of Hornik's papers) each had one model, one simulation or analysis, 3–5 plots, some R code on the slides, and a running joke. We aim for the same level: keep it simple, make it correct, make it funny. Our joke: the uncle who swears by the orange set, which on our 1999 Euro board means Stockholm, **Vienna** and Lisbon.

| # | Task | Owner | Code | Slides |
|---|---|---|---|---|
| 0 | Board setup | Nikola (done) | `data/`, `R/board.R` | `02-board` |
| 1 | Markov chain and stationary distribution | Nikola | `R/markov.R` | `03-markov` |
| 2 | Check the chain by simulation, plus jail strategy | *open* | `R/walk.R` | `03-markov` |
| 3 | Game engine: "Monopoly lite" | *open* | `R/game.R` | `04-simulation` |
| 4 | Player personalities and tournament | *open* | `R/strategies.R` | `04-simulation`, `05-orange` |
| 5 | Expected income and payback per colour set | *open* | `R/returns.R` | `05-orange` |
| 6 | Board heatmap, story and presentation lead | *open* | `R/plots.R` | `01`, `06`, overall |

```
board (0) ──> Markov chain (1) ──> sim check (2), income (5), board heatmap (6)
          └─> game engine (3) ──> tournament (4)
```

Nobody has to wait. Tasks 2, 5 and 6 can use `rep(1/40, 40)` as a stand-in for π until Task 1 is merged. Task 4 can write the personalities against a stub until Task 3 is merged.

## 1. Markov chain (Nikola)

- Transition matrix for one turn: two dice, doubles (three in a row → jail), Chance/Community Chest moves, Go To Jail, jail states.
- Stationary distribution π (solve πP = π) and the most-landed squares.
- Provides for others: `landing_probs(board, cards)`, a numeric vector of length 40 indexed by position that sums to 1.
- Tests: rows of P sum to 1, π sums to 1.

## 2. Check the chain by simulation, plus jail strategy

- Roll one token around the board for many turns (no money). Compare landing frequencies with π, and plot how the gap shrinks as the number of turns grows.
- Compare the two jail strategies, "pay and leave at once" and "sit in jail as long as allowed", and show how π changes.
- Needs only `R/board.R`, so you can start now.

## 3. Game engine: "Monopoly lite"

One function, about the size of last year's zombie simulation: `play_game(board, cards, players, max_turns)` returns the winner and the final cash and properties.

- **Keep:** buying, rent (full-set double rent, stations, utilities), houses and hotels, all 32 cards, jail, bankruptcy. The last player standing wins; at the turn cap, the richest player wins.
- **Drop:** trading, auctions, mortgages, the house shortage.
- Agree the interface with Task 4 on day one. For example, each player is a list of functions such as `buy(state, square)` and `build(state)`.

## 4. Player personalities and tournament

- Write each strategy as a personality: The Orange Fanatic, The Hoarder (buys everything), The Paris Snob (only Berlin and Paris), The Jet-Setter (airports only), and Grandma (never buys anything, collects €200 and knits). Grandma is a nod to last year's grandma deck, apparently a favourite of Hornik's. Add or change personalities as you like.
- Run thousands of games (`set.seed()`), report win rates with 95% confidence intervals, and save them to `results/tournament.rds`.

## 5. Expected income and payback per colour set

- Combine π with the rent tables: expected rent per opponent turn for each set at 0–5 buildings, development cost, and the number of turns until a set pays for itself.
- This gives the analytic answer to "why orange?", which Task 4 then tests in full games.

## 6. Board heatmap, story and presentation lead

- Board heatmap: π drawn on a square board layout, using `GROUP_COLOURS`. This is the key picture of the talk.
- Owns the story and the jokes (title, uncle, cards), the intro and conclusion slides, and the 10-minute timing.
- Runs one rehearsal and makes sure `Rscript slides/build.R` works for everyone.

## Milestones

| When | What |
|---|---|
| Sun 15 Nov | Everyone has picked a task and pushed a branch. Tasks 3 and 4 have agreed their interface |
| Wed 18 Nov | First working versions merged (before the Computing exam on Thu 19 Nov) |
| Sat 21 Nov | All results merged, no red TODOs left in the slides |
| Mon 23 Nov | One rehearsal, timed under 10 minutes |
| **Tue 24 Nov** | **Presentation** |
