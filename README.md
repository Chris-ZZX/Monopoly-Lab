# Monopoly Lab

**Which Monopoly square do you land on most, and is buying the orange set really optimal?**

1. Model the board as a Markov chain and compute its stationary distribution, which gives the long-run share of turns spent on each square.
2. Simulate full games to test whether an orange-set strategy beats the alternatives.

Everything is in R and uses no external data. The board is the **1999 Euro edition**: 22 European capitals, and the orange set includes **Vienna** (see [data/README.md](data/README.md)). We present on **Tue 24 Nov** (Computing, Prof. Hornik): 10 minutes, Beamer slides built by Sweave.

Who does what: see **[TASKS.md](TASKS.md)**.

## Quick start

```r
install.packages(c("here", "testthat", "tinytex"))
tinytex::install_tinytex()   # only if you have no LaTeX installed yet
```

Open `Monopoly-Lab.Rproj` in RStudio, or just work from the repo folder. Then:

```r
source(here::here("R", "board.R"))
board <- load_board()      # 40 squares, one row each
cards <- load_cards(board) # 16 Chance + 16 Community Chest cards
board[board$group %in% "orange", ]
```

| Do this | Command (from the repo folder) |
|---|---|
| Run the tests | `Rscript -e 'testthat::test_dir(here::here("tests"))'` |
| Build the slides | `Rscript slides/build.R` → `slides/slides.pdf` (or **Compile PDF** on `slides.Rnw` in RStudio) |
| Compile in a TeX editor | run the build once, then `slides/slides.tex` compiles on its own. Rerun the build after editing any `.Rnw` |
| Check the slides' maths | read `slides/NOTES.md`, one section per slide |

## What is where

```
data/board.csv, cards.csv  the board and the card decks (column guide: data/README.md)
R/board.R          loads + checks the data; RULES constants; move() and nearest()
R/markov.R         the Markov chain: transition matrix P and stationary distribution
R/walk.R           simulates one token with dice and cards, to check the chain
R/game.R           "Monopoly lite": one full game with money
R/strategies.R     the player personalities and the tournaments
R/plots.R          the board pictures (TikZ) and plots for the slides
analysis/          scripts that run the long simulations and save results/
results/           saved .rds results the slides read (keeps slide builds fast)
tests/             testthat checks, one file per R/ file
slides/slides.Rnw  main Beamer file; each section lives in slides/sections/
slides/NOTES.md    speaker notes: the maths and numbers behind every slide
slides/beamerthemepassgo.sty   our Beamer theme (title deed, board footline, cards)
slides/build.R     builds slides/slides.pdf
```

Rerun the long simulations (about 2 minutes for the tournaments, under 1 for the walk) only when the model changes:

```sh
Rscript analysis/walk.R         # Task 2 -> results/walk.rds
Rscript analysis/tournament.R   # Task 4 -> results/tournament.rds
```

## Conventions

These keep six people's code compatible:

- **Position = row number of `board`.** 1 = GO, 11 = Jail / Just Visiting, 21 = Free Parking, 31 = Go To Jail, 40 = Paris. Transition matrices use the same indices. Move with `move(pos, steps)`, never with your own `%% 40`.
- **No hard-coded board facts.** Look prices, rents and positions up in `board`, `cards` or `RULES` (for example `board$pos[board$type == "go_to_jail"]`), not as `31` or `200` in your code.
- **Functions in `R/` take `board` and `cards` as arguments.** Only scripts and slides load files. Build paths with `here::here(...)`, never `setwd()`.
- **Board changes affect everyone.** Edit `data/` or `R/board.R` only in a separate pull request and tell the group. `load_board()` and `load_cards()` refuse malformed CSVs.
- **Reproducible simulations:** call `set.seed()` in every script, save results with `saveRDS()` into `results/`, and only `readRDS()` them in the slides.
- **New package?** Add it to the `install.packages()` line above.

## Git workflow

1. Pick a task in [TASKS.md](TASKS.md) and put your name on it.
2. `git switch main && git pull`, then `git switch -c <short-task-name>`.
3. Commit small steps. Run the tests before you push.
4. Push and open a pull request into `main`. One teammate reviews, then merge.

## Slides

The story: an uncle swears by the orange set. We find where you really land (Markov chain), then let player personalities fight it out in two tournaments of 5,000 games each (simulation). The title, *Orange Is the New Black*, is a nod to the fact that Jail is the most visited square.

- `slides/slides.Rnw` loads `board` and `cards` once and includes one file per section from `slides/sections/`. Edit only your section to avoid merge conflicts. Each section file lists its owner and minutes at the top, 10 minutes in total.
- Our theme, `passgo`, has a title deed title page, frame titles in the section's colour, and a footline showing the board, where a token goes once around during the talk. Theme commands:
  - `\boardsection{orange}{Title}` starts a section in a colour set (`brown`, `lightblue`, `pink`, `orange`, `red`, `yellow`, `green`, `darkblue`).
  - `\chancecard{...}` and `\chestcard{...}` make a full-slide card. Use them sparingly, as punchlines.
- Show R code like last year's groups did: an `echo=TRUE` chunk inside `\begin{frame}[fragile]`. Keep code lines under 60 characters.
- Sweave chunk labels must be unique across all sections, so prefix yours (`markov-`, `sim-`, `orange-`, ...).
- `\todo{...}` prints a red placeholder. The final PDF must contain no red TODOs.
