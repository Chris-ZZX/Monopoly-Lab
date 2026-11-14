# Your Uncle Is Half Right: Monopoly Edition

Group 8, Computing (Prof. Hornik), WU Vienna, 24 November 2026:
Nikola Meshkovski, Atharv Gudi, Zixin Zheng, Richard Takacs, Jakob Lutz,
Parker Joseph Edward Ellis.

Every Christmas our uncle tells us to always buy the orange set. We wanted to
know if he is right, so we asked two questions:

1. **Which square do you land on most?** We model one token as a Markov chain
   and compute its stationary distribution, i.e. the long-run share of turns
   that end on each square.
2. **Should you buy Vienna?** We simulate full games ("Monopoly lite") between
   different kinds of players and see who wins.

We use the 1999 Euro edition of the board, where the orange set is Stockholm,
Vienna and Lisbon (see [data/README.md](data/README.md)). Everything is
written in R, and the slides are made with Sweave and Beamer.

## Running it

```r
install.packages(c("here", "testthat", "tinytex"))
tinytex::install_tinytex()   # only if you don't have LaTeX yet
```

From the repo folder:

```sh
Rscript slides/build.R                                   # -> slides/slides.pdf
Rscript -e 'testthat::test_dir(here::here("tests"))'     # tests
```

You can also open `slides/slides.Rnw` in RStudio and click **Compile PDF**.

The slides read saved simulation results from `results/`, so they build in a
few seconds. To run the simulations again:

```sh
Rscript analysis/walk.R         # simulation check of the chain, < 1 min
Rscript analysis/tournament.R   # the two tournaments, about 2 min
```

## Files

```
data/board.csv, cards.csv  the board and the two card decks
R/board.R          loads and checks the data, rule constants, move(), nearest()
R/markov.R         transition matrix P and stationary distribution
R/walk.R           simulates one token with dice and cards (check of the chain)
R/game.R           "Monopoly lite": a full game with money
R/strategies.R     the players and the tournaments
R/plots.R          board pictures (TikZ) and plots for the slides
analysis/          scripts for the long simulations, they save to results/
results/           saved simulation results (.rds)
tests/             testthat tests, one file per R/ file
slides/slides.Rnw  the slides, with one file per section in slides/sections/
slides/beamerthemepassgo.sty   our Beamer theme
slides/NOTES.md    speaker notes: the maths and numbers behind each slide
```

Positions on the board are the row numbers of `board`: 1 = GO, 11 = Jail /
Just Visiting, 21 = Free Parking, 31 = Go To Jail, 40 = Paris. The transition
matrix uses the same numbers, plus states 41-43 for being in jail.
