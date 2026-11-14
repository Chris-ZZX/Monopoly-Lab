# Speaker notes: Orange Is the New Black

One section per slide, in the order of `slides/slides.pdf` (slide numbers as in the footline; every page has its own number). Each section says what the slide claims, why it is true, where each number comes from in the code, which assumptions it rests on, and questions you may get.

Numbers are from the current code and from `results/*.rds` (seed 2026). If the model changes, rerun `Rscript analysis/walk.R` and `Rscript analysis/tournament.R`, rebuild, and recheck the numbers quoted here. The slides compute every result (probabilities, win rates, intervals) from the code and saved results; only this file has them typed in. A few rule counts are typed on the slides (three jail tries, up to three rolls per turn, the players' buy lists), as in the official rules.

**Notation.** Every symbol is defined on the slide where it first appears. In order of appearance:

| Symbol | Meaning | First defined |
|---|---|---|
| $X_t$ | state of one token after turn $t$ | frame 2; again on frame 8 |
| $D_1, D_2$, $D = D_1 + D_2$ | the two dice and their total (2 to 12) | frame 3 |
| $\Pr$ | a probability (plain $P$ is always the matrix) | frame 3 |
| $P$, $P_{ij}$ | transition matrix, $P_{ij} = \Pr(X_{t+1} = j \mid X_t = i)$ | frame 4; again on frame 8 |
| $i, j$ | states, numbered $1, \dots, 43$ | frame 8 |
| $\pi$, $\pi_i$ | stationary distribution: long-run share of turns that end in state $i$ | frame 9 (named on frame 5) |
| $\hat\pi_i$ | share of the first $n$ simulated turns that end in state $i$ | frame 11 |
| $n$ | number of simulated turns | frame 11 |
| $d$ | distance $\tfrac12 \sum_{i=1}^{43} \lvert\hat\pi_i - \pi_i\rvert$ between simulation and chain | frame 11 |
| $\pi^{\text{stay}}, \pi^{\text{pay}}$ | $\pi$ under the two jail rules | frame 12 |
| pp | percentage points (difference of two percentages) | frame 12 |
| net worth, cash reserve | game terms | frames 14–15 |
| 95% confidence interval | range for the true win rate | frame 17 |

**Slide order (20 slides).** 1 title · 2–5 the question (board, dice, cards, Jail and orange) · 6 colour sets · 7 Chance card · 8 Markov chain · 9 heatmap · 10 simulation check · 11 jail stay or pay · 12 Community Chest card · 13 rules · 14 players · 15 one game in R · 16 tournament 1 · 17 tournament 2 · 18 conclusion · 19 Chance card · 20 references. About 10 minutes: intro 1.5, board 0.5, Markov 3, simulation 1.5, tournaments 2.5, conclusion 1.

---

## Frame 1: Title deed

*Orange Is the New Black*: Jail is the state you are in most often (frame 10), and on this board the orange set is Stockholm, **Vienna**, Lisbon. The jail cell on the board is drawn orange for the same joke.

Group 8: Nikola Meshkovski, Atharv Gudi, Zixin Zheng, Richard Takacs, Jakob Lutz, Parker Joseph Edward Ellis.

---

## Frames 2–5: The question (`sections/01-question.Rnw`)

Frames 2–4 show the board, drawn by `board_tikz()` (`R/plots.R`) straight from `data/board.csv`. Frame 5 zooms in on Jail and the squares after it, drawn by `jail_exit_tikz()`. Each frame adds one idea and one bit of maths.

### Frame 2: what we follow

- 22 capitals, 4 airports, 2 dice, 32 cards: counted from `board` and `cards`.
- $X_t$ = where the token stands after turn $t$. A turn is everything one player does before the next player moves, including extra rolls after doubles.
- Why "where it stands" and not "its square": square 11 is both *Just Visiting* and *In Jail*, and the two behave differently. Frame 4 makes that precise.

### Frame 3: the dice

- $D_1, D_2$ are the two dice, independent and uniform on $\{1,\dots,6\}$, so all 36 pairs have probability $1/36$. $D = D_1 + D_2$ is their total, from 2 to 12. The number of pairs with sum $k$ is $6 - |k-7|$ for $k = 2,\dots,12$ (1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1). Hence
  $$\Pr(D = k) = \frac{6 - |k-7|}{36}.$$
- 7 is the most likely total, with $\Pr(D=7) = 6/36 = 1/6$. Also $\mathbb E[D] = 7$, $\operatorname{Var}(D) = 2 \cdot \tfrac{35}{12} = \tfrac{35}{6}$.
- "One roll: square $i \to$ square $i + D$ (after square 40, count on from GO)". Two caveats:
  1. Positions are $1,\dots,40$, so strictly it is $(i - 1 + D) \bmod 40 + 1$. This is `move()` in `R/board.R`.
  2. It is one **roll**, not one turn. After doubles you roll again, and cards or Go To Jail can move you further.
- The example $4 + 3 = 7$ from GO lands on square 8, a Chance square. The slide code checks that, so a board change would stop the build rather than show something wrong.

### Frame 4: cards, and why it is a Markov chain

- **Moving cards.** `advance`, `advance_nearest`, `back` and `jail` move you. Chance has 10 of them (5 advance, 3 advance-to-nearest, 1 back 3, 1 go to jail) and Community Chest has 2 (advance to GO, go to jail): 12 of 32 in total, and 10 of the 16 Chance cards.
- **The arrows** start at square 8 and point at the 9 *different* places a Chance card sends you from there: Paris, GO, Dublin, Budapest, Amsterdam Schiphol, Frankfurt (nearest airport), European Parliament (nearest utility), Income Tax (back 3) and Jail. That is 10 moving cards; the two "nearest airport" cards go to the same place, so there are 9 arrows.
- **Markov property.** The future depends on the past only through the present state:
  $$\Pr(X_{t+1} = j \mid X_t = i, X_{t-1} = i_{t-1}, \dots) = \Pr(X_{t+1} = j \mid X_t = i) = P_{ij}.$$
  This only holds with the right *state* and two modelling choices (no longer on the slide: say them out loud if asked):
  1. **Jail needs extra states.** The state must tell *In Jail* (and on which try) apart from *Just Visiting*. How many tries you have left changes what happens next, so it must be part of the state.
  2. **Every card is a random draw.** In the real game a deck is drawn in order, so the cards already drawn tell you something about the next one, which breaks the Markov property. We treat each draw as a fresh random card, as if the deck were reshuffled every time. Ash and Bishop (1972) make the same assumption.
  3. **Doubles don't need extra states, because one step is one whole turn.** The doubles count resets at the start of every turn, so it never carries over. It is handled *inside* $P$ (frame 8).
- Get Out of Jail Free cards are treated as non-moving cards and never used in the chain. They are used in the game simulation.

### Frame 5: Jail, and the way out to orange

The picture: the Jail corner on the left, then the 12 squares after it in a row (+1 Budapest to +12 Chance). Above each square, a bar with the number of the 36 dice rolls whose total reaches it (+$k$ needs total $k$: 0 ways for +1, then 1, 2, …, 6, …, 1). Orange squares are ringed and their bars are orange.

Three ways in:

| Route | Number on slide | Meaning |
|---|---|---|
| Land on Go To Jail | 1 of 40 squares | |
| Draw a Go to Jail card | 2 of 32 cards | one per deck, so $1/16$ for each draw |
| Roll doubles 3 times in a row | $(1/6)^3 = 1/216$ | chance per turn of doubles on rolls 1, 2 and 3, by independence of the rolls |

- Squares after jail (square 11): Stockholm $+6$, Vienna $+8$, Lisbon $+9$.
- Totals 6 and 8 have 5 ways each and 9 has 4 ways, so
  $$\Pr(D \in \{6, 8, 9\}) = \frac{5 + 5 + 4}{36} = \frac{14}{36} \approx 39\%.$$
  That is the chance that **one** roll from the Jail corner hits orange. Totals 6–9 sit at the peak of the dice distribution, which is why the set right after jail is special.
- Caveat if asked: a token that leaves jail **by rolling doubles** can only roll 6 (3+3) or 8 (4+4) among these totals, $2/36$ per try. That is why the slide says "Pay to leave Jail, roll 6, 8 or 9": the 39% is for one ordinary roll from square 11, after paying the fine or when Just Visiting.
- "Find $\pi$" is section 3 (frames 8–12); "let the uncle play full games" is sections 4–5.

---

## Frame 6: The board in R, 22 capitals in eight colour sets (`sections/02-board.Rnw`)

- The board and the cards are two CSV files (`data/board.csv`, `data/cards.csv`), read into R as data frames by `load_board()` and `load_cards()`, which refuse malformed files. Row $i$ of `board` is square $i$, counted from GO (GO = 1, Jail = 11, Free Parking = 21, Go To Jail = 31, Paris = 40).
- 40 squares, of which 28 are for sale (22 capitals, 4 airports, 2 utilities), and 32 cards.
- The table is computed from `board`: per set, the set price (sum of the street prices), the cost of one house and the highest hotel rent. Orange: set €560, house €100, top hotel rent €1000. Paris is the most expensive square (€400).
- Why the table is here: the tournaments (frames 17–18) refer to it. Brown is cheap but its hotels earn little (€450 at most); dark blue has only two cities and the highest rents.
- Fun fact: the 1999 board lists Geneva as the capital of Switzerland; a 2001 reprint changed it to Bern.

---

## Frame 7: Chance card, "Advance to the Markov chain."

Section opener.

---

## Frames 8–9: The board as a Markov chain, and the stationary distribution (`R/markov.R`)

**Frame 8, in words.** The state $X_t$ is where the token is after turn $t$: one of 40 squares, or *In Jail* and waiting for the 1st, 2nd or 3rd try to roll doubles; 43 states in total (square 11 is Just Visiting: say it, the slide does not). One step of the chain is one whole turn. $P_{ij}$ is the probability of going from state $i$ to state $j$ in one turn; R computes it exactly from the 36 dice outcomes and the 32 cards.

**The heatmap of $P$** (`plot_transition_matrix()` in `R/plots.R`, "stay" rule). Row $i$ (top to bottom) is where the turn starts, column $j$ where it ends; every row sums to 1. Cells are binned (0, under 1%, 1–5%, 5–10%, over 10%) so that rare card jumps stay visible next to the dice. Walk the audience through it:
- **Dark diagonal band:** the dice, 2 to 12 squares ahead, centred on 7. It wraps round at the bottom left (squares 30–40 pass GO).
- **Empty column 31:** Go To Jail sends you to In Jail 1 at once, so no turn ends there.
- **Jail column (41, In Jail 1):** filled in almost every row: Go To Jail, the Go to Jail cards and three doubles. Below the dashed line, the jail rows: In Jail 1 → In Jail 2 → In Jail 3 with 5/6 (no doubles), the rest is the roll out of Jail.
- **Light scattered cells:** cards (Chance at 8, 23, 37; Community Chest at 3, 18, 34) and the extra rolls after doubles. Many are tiny (under 1%), but not zero.

**Frame 9, in words.** $\pi$ solves $\pi P = \pi$ with entries summing to 1, and $\pi_i$ is the long-run share of turns that end in state $i$. Sums like $\sum_{i=1}^{43}$ run over the 43 states.

Neither slide shows the formula for $P$. Everything below is for questions about *how* $P$ is computed.

### The state space (43 states)

- 1–40: the squares. State 11 means **Just Visiting**.
- 41, 42, 43: **In Jail, before attempt 1, 2, 3** (named "In Jail 1/2/3" in the R output).
- Go To Jail (31) is never the end of a turn, so $\pi_{31} = 0$.

### One roll: the matrices $N$ and $D$

**Square effects.** First, `landing_matrix()` builds a $43 \times 43$ matrix $L$. $L_{s,\cdot}$ is where a token that has just landed on square $s$ ends up after the square's effect:
- Go To Jail sends it to state 41.
- Chance or Community Chest: each card has probability $1/16$, and the token goes wherever that card sends it.
- Chance "go back 3" from square 37 lands on Community Chest (34), which draws again. That is why Community Chest is processed first. For example $L_{37,34} = \tfrac1{16} \cdot \tfrac{14}{16}$: you must draw "back 3" and then one of the 14 chest cards that don't move you.
- All other rows are unit vectors (you stay where you landed).

**Split by doubles.** Then `roll_matrices()` splits one roll from square $s$ by whether it is a double:
$$N_{s,\cdot} = \sum_{\substack{(a,b)\\ a \ne b}} \tfrac{1}{36} L_{s + a + b,\cdot}, \qquad D_{s,\cdot} = \sum_{a=1}^{6} \tfrac{1}{36} L_{s + 2a,\cdot}$$
(positions mod 40). The row sums are $5/6$ and $1/6$. The rows for the jail states are zero here and filled in later.

### One turn: up to three rolls

Work backwards from the last roll:
- **Roll 3:** no doubles means move ($N$); doubles mean straight to jail without moving ($\tfrac16 J$, where $J$ sends every square to state 41).
- **Rolls 1 and 2:** no doubles means move and stop ($N$); doubles mean move and roll again ($D \cdot$ next roll).
- $E$ (identity on state 41) keeps a token that was sent to jail *during* the turn in jail for the rest of the turn: no more rolling.

Together, for the 40 square rows:
$$P = N + D\bigl(E + N + D\,(E + N + \tfrac16 J)\bigr).$$
In the code this is `P <- N + P_DOUBLE * to_jail + E`, followed by `P <- N + D %*% P + E` applied twice. Each row sums to 1, which is checked in `tests/test-markov.R`. The arithmetic: $\tfrac56 + \tfrac16(\tfrac56 + \tfrac16(\tfrac56 + \tfrac16)) = 1$.

**Jail rows**, strategy "stay" (the default):
- Attempts 1 and 2: doubles (prob $1/6$) mean you leave and move by that roll, with no extra roll (the official rule). That is row $D_{11,\cdot}$. Otherwise (prob $5/6$) you go to the next attempt.
- Attempt 3: doubles mean you move; otherwise you pay €50 and move by that roll. Both together give $D_{11,\cdot} + N_{11,\cdot}$.
- On average a token in jail spends $1 + \tfrac56 + (\tfrac56)^2 \approx 2.53$ turns there.

**Jail rows**, strategy "pay": pay €50 at once and take a normal turn from Just Visiting, so every jail row equals row 11 of $P$. Attempts 2 and 3 can then never happen, and their $\pi$ is 0.

### The stationary distribution

$\pi$ is a row vector with $\pi P = \pi$ and $\sum_i \pi_i = 1$.

- **Existence and uniqueness.** The reachable states form one closed class. Go To Jail and, under "pay", attempts 2–3 are never entered. That class is aperiodic: you can return to a square in 2 turns and in 3 turns, and $\gcd(2,3) = 1$. So $\pi$ is unique, and the long-run share of turns in each state converges to it (ergodic theorem). Frame 11 checks exactly this.
- **Computing it.** `stationary()` solves the linear system $(P^\top - I)\pi = 0$ with one equation replaced by $\mathbf 1^\top \pi = 1$. Uniqueness of $\pi$ means $P^\top - I$ has rank 42, so the replaced system has exactly one solution. Tests check $\pi P = \pi$ to $10^{-12}$.
- **Output on the slide** (percent): In Jail 1: 4.33, In Jail 2: 3.61, In Jail 3: 3.01, Dublin: 2.95. Each jail attempt state alone beats every square.

### Check against the literature

This board has the same layout and card effects as the US board: Dublin = Illinois Ave, Paris = Boardwalk, Budapest = St. Charles Place, Schiphol = Reading Railroad. So our numbers can be compared with published tables for the US board (for example Ash and Bishop 1972), where Illinois Ave is the most visited street, as Dublin is here. Do not quote exact published percentages from memory: the published tables differ in their rules (card handling, jail strategy, whether turn ends or landings are counted).

Likely question: *"Is $\pi$ the landing frequency?"* Not quite. $\pi$ counts where turns **end**. If you roll doubles, you also land on the squares in between, and those landings pay rent too. `landings_per_turn()` counts every landing: on average 1.10 landings per turn (more than 1 because of doubles, less than $1 + \tfrac16 + \tfrac1{36} \approx 1.19$ because turns in jail have no move). For rent, `landings_per_turn()` is the right measure.

---

## Frame 10: Where do you land most? (heatmap)

- Each square shows $100\,\pi_i$ (2 decimals). Redder means larger; the scale runs over the 36 non-corner squares.
- The table merges the three jail states into one "In Jail" row (the note under the table says so): $4.33 + 3.61 + 3.01 = 10.94\%$ of turns. Next come Dublin 2.95%, GO 2.91%, Lisbon 2.85%, Vienna 2.84% and Paris CDG Airport 2.83%. Just Visiting alone is 2.08%, so the jail corner as a whole is $10.94 + 2.08 \approx 13\%$.
- **Why Jail:** three ways in (frame 5), and with "stay" you sit there for up to three turns.
- **Why squares 5–9 after jail are high:** everyone leaves jail sooner or later from square 11, and totals 6–8 are the most likely rolls. Stockholm (+6), Vienna (+8) and Lisbon (+9) are ranks 4, 3 and 2 among the 22 capitals (say it: "Lisbon 2nd, Vienna 3rd, Stockholm 4th"; the slide no longer lists them); Dublin (+14) is first, helped by the "Advance to Dublin" card.
- **Why Chance squares are low (0.79–1.03%):** 10 of 16 cards move you away, so few turns *end* there.
- Go To Jail is 0% (say it, the slide no longer does): it sends you to Jail at once, so no turn ends there.
- Least visited capitals: Vilnius 1.90%, Berlin 1.93%, Riga 1.95%. The stretch from square 32 round to 4 is reached mostly by tokens coming from squares 21–39. Go To Jail (31) and the Chance at 37 send many of those tokens elsewhere, so fewer arrive.

---

## Frame 11: Check, theory vs. simulation (`R/walk.R`, `analysis/walk.R`)

- `simulate_walk()` rolls real dice and draws random cards for one token, turn by turn. It does not use $L$, $N$, $D$ or $P$: it is an independent implementation of the *turn logic*. It shares the data and helpers with the chain (`cards.csv`, `move()`, `nearest()`, `RULES`), so it checks how `R/markov.R` builds the matrices, not the data itself (the data is checked by `load_board()`, `load_cards()` and the tests).
- After $n$ turns, the empirical distribution (the slide's $\hat\pi_i$) is $\hat\pi_i = \#\{t \le n : X_t = i\} / n$.
- **Distance.** The slide calls it $d$. Its name is the total variation distance:
  $$d = d_{TV}(\hat\pi, \pi) = \tfrac12 \sum_{i=1}^{43} |\hat\pi_i - \pi_i| = \max_A |\hat\pi(A) - \pi(A)|.$$
  The sum runs over the 43 **states** $i$, not over the $n$ turns: $n$ is already inside $\hat\pi_i$, which is a share of the first $n$ turns.
  It is the largest possible difference in probability between the two distributions for any event $A$, and lies between 0 and 1.
- **Result.** 5 runs of $10^6$ turns each, distance measured at 17 checkpoints from $10^2$ to $10^6$ turns. Average distance: 0.24 at 100 turns, 0.025 at $10^4$, 0.0025 at $10^6$ (strategy "stay"; "pay" gives 0.0022).
- **Rate $1/\sqrt{n}$.** Each $\hat\pi_i$ is an average along the chain. By the central limit theorem for ergodic Markov chains, its error is of order $\sigma_i/\sqrt{n}$, so the sum is too. In the plot, 100 times more turns gives 10 times smaller distance, a straight line of slope $-\tfrac12$ on log-log axes. The dashed orange line is $c/\sqrt n$, anchored at the final value.
- **Why this convinces:** two independent programs agree to 0.25%, and the error shrinks at exactly the rate random noise should. A bug in building the matrices (say, processing Chance before Community Chest, which mishandles "go back 3" from square 37) would leave a gap that does not shrink. `tests/test-walk.R` also requires the distance after 50,000 turns to be below 0.02 for both strategies.

---

## Frame 12: Jail, stay or pay?

- **Stay:** try for doubles on up to 3 turns, then pay €50 (the chain's default, used on frames 8–11). **Pay:** pay €50 at once, then take a normal turn.
- $\pi^{\text{stay}}$ and $\pi^{\text{pay}}$ are the stationary distributions under the two rules.
- Share of turns that **end** in jail: 10.94% with stay vs 4.69% with pay. Under "pay" you never sit a turn out; the 4.69% are turns that end with being sent to jail.
- **The bars** show $\pi^{\text{pay}}_i - \pi^{\text{stay}}_i$ in percentage points (pp: the difference of two percentages) for every square except Jail. Their sum is minus the change for the jail square: the total stays 1.
- **Most squares gain** because paying means you move every turn. The biggest gains are Community Chest 18 (+7 after jail) at +0.37 pp, Frankfurt Airport (+5) at +0.35 pp and Lisbon (+9) at +0.33 pp. Lisbon gains most among the capitals.
- **A few squares lose:** EU Parliament (+2) −0.13 pp, Helsinki (+4) −0.06, Free Parking (+10) −0.03 and Chance 23 (+12) −0.03. All of these are *doubles totals* from jail. Under "stay", leaving with doubles ends your turn there (no extra roll), which piles turn-ends onto squares an even distance after jail. Under "pay", doubles give an extra roll, so the turn ends further on. Stockholm (+6) and Vienna (+8) are doubles totals too, which is why they gain little.
- **What it means for players** (not on the slide; good for questions): in jail you still collect rent but cannot land on anyone's hotel. So: pay early (to buy cities) and stay late (when the board is full of hotels). Our game players always pay; the chain shows the default "stay".

---

## Frame 13: Community Chest card, "Bank error in your favour. Simulate 10 000 games for free."

Two tournaments of 5,000 games each = 10,000 games.

---

## Frame 14: Monopoly lite, the rules we simulate (`R/game.R`)

**Kept:**
- Buying cities, airports and utilities.
- Rent:
  - Streets: base rent, doubled on an unimproved full set (`RULES$full_set_multiplier`), and the 1–4 house / hotel rents from `board.csv`.
  - Airports: €25/50/100/200 for 1–4 owned.
  - Utilities: 4 or 10 times the dice.
- All 32 cards, including "pay each player", "collect from each player", repairs, Get Out of Jail Free, and the advance-to-nearest cards with their special rents: airport rent doubled, utility = 10 × a fresh roll.
- Doubles: roll again, and the third double means jail. Jail itself.
- Houses built evenly (no street of a set more than one house ahead of another). A hotel is level 5.

**Dropped:**
- Trading and auctions.
- Mortgages. A player who can't pay sells houses back to the bank at half price, always from the most built-up street.
- The house shortage (32 houses / 12 hotels).

**Bankruptcy:** if selling every house is still not enough, the player is out. Their remaining cash and all cities go to the creditor, or back to the bank (unowned) if they owe the bank.

**Players:** 5 in tournament 1, 8 in tournament 2 (stated at the top of the slide), each starting on GO with €1500.

**Who wins:** the last player who is not bankrupt. After 300 rounds (the slide says "300 turns each") the highest net worth (cash + purchase prices of cities + cost of houses) wins. A round is one turn for every player. Of the 5,000 personality games, 1.2% hit the cap; of the one-per-set games (tournament 2), 17.4% (8 players take longer: median 81 rounds vs 60).

**Simplifications to admit if asked:**
- Cards are random draws, as in the chain.
- All players use the same jail habit: use a Get Out of Jail Free card if they have one, otherwise pay at once.
- Building happens at the start of the player's own turn only.

---

## Frame 15: Meet the players (`R/strategies.R`)

| Player | Buys | Cash reserve |
|---|---|---|
| Orange Fanatic | Stockholm, Vienna, Lisbon only | €50 |
| Hoarder | everything it lands on | €100 |
| Paris Snob | Berlin and Paris only | €50 |
| Jet-Setter | the four airports only | €50 |
| Grandma | nothing | €0 |

The cash reserve is money the player never spends on buying or building. Everyone builds houses evenly on every full set they own, as fast as the reserve allows, and pays to leave jail.

---

## Frame 16: One game in R

- The live code runs one game between the five personalities with `set.seed(69)`. The Hoarder wins by bankruptcy in round 68, and nobody completes the orange set (the Hoarder completes brown, green, pink, dark blue and red). One game proves nothing; frames 17–18 are the statistics. The seed only affects this slide: the tournaments use their own seed (2026).
- A player is `make_player(name, buy, reserve, jail)`. `buy(game, me, pos)` returns TRUE/FALSE for the unowned square `pos`. `reserve` is cash the player never spends on buying or building. `jail` is "pay" or "stay".
- `play_game()` is about 30 lines; `R/game.R` is about 270 lines including comments. Tested in `tests/test-game.R`: rent rules, house sales, bankruptcy to a creditor, even building, Grandma never buys.

---

## Frame 17: Tournament 1, all five at one table (`analysis/tournament.R`)

- **Setup.** 5,000 games, all five personalities at one table, seating order shuffled every game (`sample()`), cap 300 rounds, seed 2026.
- **Win rates and exact 95% Clopper–Pearson intervals** (`binom.test`):

| Player | Win rate | 95% CI |
|---|---|---|
| Hoarder | 68.9% | [67.6, 70.2] |
| Paris Snob | 21.5% | [20.4, 22.7] |
| Orange Fanatic | 8.2% | [7.5, 9.0] |
| Jet-Setter | 1.3% | [1.0, 1.6] |
| Grandma | 0.06% | 3 wins |

- Dot = share of games won; bar = 95% confidence interval (for the Hoarder it is narrower than the dot). The dashed line at $1/5$ is what pure luck would give.
- **Why the Hoarder wins:** it owns many cities early, and its random landings complete sets (including orange) before the specialists can. The Hoarder is the first to own the whole orange set in 60.0% of games. That includes sets gained from a bankrupt Orange Fanatic.
- **The Orange Fanatic completes orange in only 12.8% of games, and wins 64.6% of those.** In the other games it never wins (0 of 4,362). Careful: this conditions on something that happens *during* the game (completing the set needs the Fanatic to survive and to beat the Hoarder to the cities), so 64.6% is not "the effect of owning orange". Say "among games where it completed the set".
- **The Paris Snob does better** than the Orange Fanatic (21.5% [20.4, 22.7] vs 8.2% [7.5, 9.0]): a 2-city set is easier to complete (35.3% of games vs 12.8%), and Paris/Berlin hotels charge up to €2000/€1500.
- **Why not "the generalist always wins":** tournament 1 compares these five players only. The Hoarder is the only one who competes with every specialist for its cities, and it keeps a larger reserve (€100 vs €50). The conclusion therefore says "against our opponents".
- **Interval method.** Clopper–Pearson inverts the exact binomial test. With $n = 5000$, the half-width is about $1.96\sqrt{p(1-p)/n}$, roughly ±1.3 pp at $p = 0.69$.
- **Seat order barely matters:** the Hoarder wins 66–73% whichever seat moves first.

---

## Frame 18: Tournament 2, one player per colour set

- **Setup.** 8 players, one per colour set, each buying **only** its own set and building as fast as a €50 reserve allows. Nobody competes for the same city, so this compares the sets themselves. 5,000 games, shuffled seats.

| Set | Win rate | 95% CI | Owner completes the set |
|---|---|---|---|
| orange | 20.1% | [19.0, 21.2] | 48.4% |
| dark blue | 19.9% | [18.8, 21.0] | 45.1% |
| red | 18.9% | [17.8, 20.0] | 42.8% |
| yellow | 15.4% | [14.4, 16.5] | 37.6% |
| green | 12.6% | [11.7, 13.5] | 33.3% |
| pink | 8.8% | [8.0, 9.6] | 36.4% |
| light blue | 3.9% | [3.4, 4.5] | 34.7% |
| brown | 0.4% | [0.3, 0.7] | 42.1% |

- The dashed line at $1/8 = 12.5\%$ is pure luck.
- **"The intervals overlap: we cannot rank them."** Orange, dark blue and red have overlapping intervals. Overlap is a rough guide, not a test, so here is a direct check. Win counts are multinomial; for two players, $\widehat{\operatorname{Var}}(\hat p_1 - \hat p_2) = (p_1 + p_2 - (p_1 - p_2)^2)/n$.
  - Orange vs dark blue: difference 0.2 pp, $z \approx 0.2$.
  - Orange vs red: difference 1.2 pp, $z \approx 1.4$.

  Neither is significant at 5%, so "orange is at least as good as anything" is fair. "Orange is strictly best" is not supported.
- **Even unopposed, a set gets completed only when its owner has landed on every square of it before going bankrupt.** Orange is completed most often (48.4%), in line with its squares having the highest $\pi$ of any 3-city set (frame 10). Dark blue (45.1%) needs only 2 cities, which offsets its low $\pi$. That is the link between section 3 (where you land) and section 5 (who wins).
- **Win rate if completed:** orange 41.5%, red 44.1%, dark blue 44.1%, yellow 41.1%, green 37.8%, pink 24.1%, light blue 11.3%, brown 1.0%. No player ever won without completing their own set (0 of 5,000 games). Once completed, orange, red, yellow and dark blue are about equally strong; orange's edge is how *often* it gets completed.
- **Brown completes 42% of the time but almost never wins:** hotel rent €250–450 is too small against everyone else's.

---

## Frame 19: Conclusion (`sections/06-conclusion.Rnw`)

Both answers are computed from the same objects as the earlier slides (`pi_stay`, `tied`, `rp`), so they change if the results change.

1. **Where do you land most?** In Jail: 10.9% of all turns end there (frame 10), against 2.5% per square on a fair board. Among the capitals: Dublin, then Lisbon and Vienna, almost tied (2.85% vs 2.84%). Counting every landing with `landings_per_turn()` instead of turn ends, the Jail corner (6.21% of all landings, Just Visiting plus being sent there) and Dublin (3.18%) stay on top; Vienna (2.99%) and Lisbon (2.98%) swap places, which is why the slide calls them almost tied. A build check stops the build if Jail and the top capital ever differ between the two counts. Orange lies 6, 8 and 9 squares after Jail, and totals near 7 are the most likely rolls (frame 5).
2. **Should you buy Vienna?** Yes, if you can get the whole set: in tournament 2 orange is joint best with dark blue and red (frame 18). But buying *only* orange is not enough against our opponents: the Hoarder wins 68.9% of games in tournament 1 (frame 17).
3. **Verdict on the uncle:** half right. Buy orange, and everything else too.

`stopifnot()` in `05-orange.Rnw` stops the build if a rerun changes any of these claims (orange among the leaders, orange completed most often, Hoarder first in tournament 1).

## Frames 20–21: Chance card and references

"Go directly to questions." The references are listed at the end of this file, with what each one is for.

---

## Assumptions worth saying out loud (all in one place)

1. **Cards are random draws** (Markov chain, walk and game alike). Real decks cycle in order.
2. **The Markov chain ignores money** and Get Out of Jail Free cards. It describes one token's movement only.
3. **Jail strategy:** the chain shows "stay" by default (frames 8–11) and compares it with "pay" (frame 12). Game players always pay.
4. **The game drops** trading, auctions, mortgages and the house shortage, and caps games at 300 rounds.
5. **Personalities are deliberately simple:** fixed buy lists and a cash reserve. Real players trade, which would help the Orange Fanatic complete its set.

## References (frame 21)

What each reference is for, in case someone asks:

- Ash, R. B. and Bishop, R. L. (1972). Monopoly as a Markov process. *Mathematics Magazine* 45(1), 26–29. The original Markov chain model of Monopoly, including the random-card assumption.
- Stewart, I. (1996). How fair is Monopoly? *Scientific American* 274(4), 104–105. Popular account of the same idea.
- Levin, D. A. and Peres, Y. (2017). *Markov Chains and Mixing Times*, 2nd ed. AMS. Stationary distributions, the ergodic theorem and the total variation distance $d$.
- Clopper, C. J. and Pearson, E. S. (1934). The use of confidence or fiducial limits illustrated in the case of the binomial. *Biometrika* 26(4), 404–413. The exact 95% intervals from `binom.test()`.
- Waddingtons / Hasbro (1999). *Monopoly*, Euro edition; layout from worldofmonopoly.com (see `data/README.md`).
- R Core Team; Leisch (2002) for Sweave; Müller (2020) for `here`; Wickham (2011) for `testthat`; Xie (2019) for TinyTeX; Tantau et al. for beamer and TikZ/PGF.
