# Tasks

Pick an open task, put your name in the table and push the change. Each task owns its own files, so we rarely edit the same file.

**Scope.** Last year's decks (zombie grandmas, a South Park swear counter, a network of Hornik's papers) each had one model, one simulation or analysis, 3–5 plots, some R code on the slides, and a running joke. We aim for the same level: keep it simple, make it correct, make it funny. Our joke: the uncle who swears by the orange set, which on our 1999 Euro board means Stockholm, **Vienna** and Lisbon.

| # | Task | Owner | Code | Slides |
|---|---|---|---|---|
| 0 | Board setup | Nikola (done) | `data/`, `R/board.R` | `02-board` |
| 1 | Markov chain and stationary distribution | Nikola (done) | `R/markov.R` | `03-markov` |
| 2 | Check the chain by simulation, plus jail strategy | Nikola (done) | `R/walk.R` | `03-markov` |
| 3 | Game engine: "Monopoly lite" | Nikola (done) | `R/game.R` | `04-simulation` |
| 4 | Player personalities and tournaments | Nikola (done) | `R/strategies.R` | `04-simulation`, `05-orange` |
| 5 | Expected income and payback per colour set | *dropped* (slides are full) | — | — |
| 6 | Story, intro, conclusion, heatmap | Nikola (done) | `R/plots.R` | `01`, `06` |
| 7 | Rehearsal: who presents which slides, timed under 10 minutes | *open* | — | all |

All slides are written; `slides/NOTES.md` explains the maths and numbers behind each one. What is left is Task 7: split the 20 slides between the six of us, read the notes for your slides, and rehearse once.

## Milestones

| When | What |
|---|---|
| Sun 15 Nov | Everyone has picked a task and pushed a branch. Tasks 3 and 4 have agreed their interface |
| Wed 18 Nov | First working versions merged (before the Computing exam on Thu 19 Nov) |
| Sat 21 Nov | All results merged, no red TODOs left in the slides |
| Mon 23 Nov | One rehearsal, timed under 10 minutes |
| **Tue 24 Nov** | **Presentation** |
