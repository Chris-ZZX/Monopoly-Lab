# Speaker notes: Orange Is the New Black

One section per slide, in the order of `slides/slides.pdf` (frame numbers as in the footline). Each section says what the slide claims, why it is true, where each number comes from in the code, which assumptions it rests on, and questions you may get.

Numbers are from the current code and from `results/*.rds` (seed 2026). If the model changes, rerun `Rscript analysis/walk.R` and `Rscript analysis/tournament.R`, rebuild, and recheck the numbers quoted here. The slides compute every number themselves; only this file has them typed in.

**Notation used throughout.** $D_1, D_2$ are the two dice, $D = D_1 + D_2$. $X_t$ is the state of one token after turn $t$. $P$ is the transition matrix and $P_{ij} = \Pr(X_{t+1} = j \mid X_t = i)$. $\pi$ is the stationary distribution. $\Pr$ is a probability; plain $P$ is always the matrix.

---

## Frame 1: Title deed

*Orange Is the New Black*: Jail is the state you are in most often (frame 7), and on this board the orange set is Stockholm, **Vienna**, Lisbon. The jail cell on the intro board is drawn orange for the same joke.

Group 8: Atharv Gudi, Zixin Zheng, Richard Takacs, Jakob Lutz, Parker Joseph Edward Ellis, Nikola Meshkovski.

---

## Frame 2: The board, in five steps (`sections/01-question.Rnw`)

The board is drawn by `board_tikz()` (`R/plots.R`) straight from `data/board.csv`. Each step adds one idea and one bit of maths.

### Step 1: what we follow

- 22 capitals, 4 airports, 2 dice, 32 cards: counted from `board` and `cards`.
- $X_t$ = where the token stands after turn $t$. A turn is everything one player does before the next player moves, including extra rolls after doubles.
- Why "where it stands" and not "its square": square 11 is both *Just Visiting* and *In Jail*, and the two behave differently. Step 3 makes that precise.

### Step 2: the dice

- $D_1, D_2$ are independent and uniform on $\{1,\dots,6\}$, so all 36 pairs have probability $1/36$. The number of pairs with sum $k$ is $6 - |k-7|$ for $k = 2,\dots,12$ (1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1). Hence
  $$\Pr(D = k) = \frac{6 - |k-7|}{36}.$$
- 7 is the most likely total, with $\Pr(D=7) = 6/36 = 1/6$. Also $\mathbb E[D] = 7$, $\operatorname{Var}(D) = 2 \cdot \tfrac{35}{12} = \tfrac{35}{6}$.
- "One roll: square $i \to i + D \pmod{40}$". Two caveats:
  1. Positions are $1,\dots,40$, so strictly it is $(i - 1 + D) \bmod 40 + 1$. This is `move()` in `R/board.R`; "mod 40" on the slide means "wrap around the board".
  2. It is one **roll**, not one turn. After doubles you roll again, and cards or Go To Jail can move you further.
- The example $4 + 3 = 7$ from GO lands on square 8, a Chance square. The slide code checks that, so a board change would stop the build rather than show something wrong.

### Step 3: cards, and why it is a Markov chain

- **Moving cards.** `advance`, `advance_nearest`, `back` and `jail` move you. Chance has 10 of them (5 advance, 3 advance-to-nearest, 1 back 3, 1 go to jail) and Community Chest has 2 (advance to GO, go to jail): 12 of 32 in total. So $\Pr(\text{move} \mid \text{Chance}) = 10/16$.
- **The arrows** start at square 8 and point at the 9 *different* places a Chance card sends you from there: Paris, GO, Dublin, Budapest, Amsterdam Schiphol, Frankfurt (nearest airport), European Parliament (nearest utility), Income Tax (back 3) and Jail. That is 10 moving cards; the two "nearest airport" cards go to the same place, so there are 9 arrows.
- **Markov property.** The future depends on the past only through the present state:
  $$\Pr(X_{t+1} = j \mid X_t = i, X_{t-1} = i_{t-1}, \dots) = \Pr(X_{t+1} = j \mid X_t = i) = P_{ij}.$$
  This only holds with the right *state* and two modelling choices (the grey line on the slide):
  1. **Jail needs extra states.** The state is the square, plus "In Jail, before attempt 1/2/3". How many attempts you have left changes what happens next, so it must be part of the state.
  2. **Cards are drawn at random each time.** In the real game a deck is drawn in order, so the cards already drawn tell you something about the next one, which breaks the Markov property. We treat each draw as a fresh random card, as if the deck were reshuffled every time. Ash and Bishop (1972) make the same assumption.
  3. **Doubles don't need extra states, because one step is one whole turn.** The doubles count resets at the start of every turn, so it never carries over. It is handled *inside* $P$ (frame 6).
- Get Out of Jail Free cards are treated as non-moving cards and never used in the chain. They are used in the game simulation.

### Step 4: Jail

Three ways in:

| Route | Number on slide | Meaning |
|---|---|---|
| Land on Go To Jail | 1 square of 40 | |
| Draw a Go to Jail card | $2/32$ | 2 of the 32 cards (one per deck), so $1/16$ for each draw |
| Three doubles in a row | $(1/6)^3 = 1/216$ | chance per turn of doubles on rolls 1, 2 and 3, by independence of the rolls |

- $\pi_i$ is the long-run share of turns that end in state $i$ (frame 6). If every square were equally likely, $\pi_i = 1/40 = 2.5\%$.
- "And Jail?": frame 7 answers it with 10.9% of turns spent in jail, plus 2.1% on Just Visiting.

### Step 5: orange, and the uncle

- Squares after jail (square 11): Stockholm $+6$, Vienna $+8$, Lisbon $+9$.
- Totals 6 and 8 have 5 ways each and 9 has 4 ways, so
  $$\Pr(D \in \{6, 8, 9\}) = \frac{5 + 5 + 4}{36} = \frac{14}{36} \approx 39\%.$$
  That is the chance that **one** roll from square 11 hits orange. Totals 6–9 sit at the peak of the dice distribution, which is why the set right after jail is special.
- Caveat if asked: a token that leaves jail **by rolling doubles** can only roll 6 (3+3) or 8 (4+4) among these totals. The 39% is the chance for one ordinary roll from square 11, for example after paying the fine or when Just Visiting.
- Last line: "Solve $\pi = \pi P$" is section 3; "let the uncle play full games" is sections 4–5.

---

## Frames 3–4: The board as data (`sections/02-board.Rnw`)

- Frame 3: `subset(board, group == "orange")` shows that the board is just a data frame. Row number = position.
- 40 squares, of which 28 are for sale (22 capitals, 4 airports, 2 utilities), and 32 cards. `load_board()` and `load_cards()` refuse malformed CSVs.
- Frame 4: per set, the set price, house cost and top hotel rent, computed from `board`. Orange: set €560, house €100, top hotel rent €1000. Paris is the most expensive square (€400).
- Fun fact: the 1999 board lists Geneva as the capital of Switzerland; a 2001 reprint changed it to Bern.

---

## Frame 5: Chance card, "Advance to the Markov chain."

Section opener.

---

## Frame 6: The board as a Markov chain (`R/markov.R`)

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

- **Existence and uniqueness.** The reachable states form one closed class. Go To Jail and, under "pay", attempts 2–3 are never entered. That class is aperiodic: you can return to a square in 2 turns and in 3 turns, and $\gcd(2,3) = 1$. So $\pi$ is unique, and the long-run share of turns in each state converges to it (ergodic theorem). Frame 8 checks exactly this.
- **Computing it.** `stationary()` solves the linear system $(P^\top - I)\pi = 0$ with one equation replaced by $\mathbf 1^\top \pi = 1$. Uniqueness of $\pi$ means $P^\top - I$ has rank 42, so the replaced system has exactly one solution. Tests check $\pi P = \pi$ to $10^{-12}$.
- **Output on the slide** (percent): In Jail 1: 4.33, In Jail 2: 3.61, In Jail 3: 3.01, Dublin: 2.95. Each jail attempt state alone beats every square.

### Check against the literature

This board has the same layout and card effects as the US board: Dublin = Illinois Ave, Paris = Boardwalk, Budapest = St. Charles Place, Schiphol = Reading Railroad. So our numbers can be compared with published US tables, where Illinois Ave is the most visited street, as Dublin is here. **To check before quoting:** I recall published long-jail values of about 2.9% for GO and 3% for Illinois Ave, close to our 2.91% and 2.95%, but I have not verified them against a source.

Likely question: *"Is $\pi$ the landing frequency?"* Not quite. $\pi$ counts where turns **end**. If you roll doubles, you also land on the squares in between, and those landings pay rent too. `landings_per_turn()` counts every landing: on average 1.10 landings per turn (more than 1 because of doubles, less than $1 + \tfrac16 + \tfrac1{36} \approx 1.19$ because turns in jail have no move). For rent (Task 5) use `landings_per_turn()`.

---

## Frame 7: Where do you land most? (heatmap)

- Each square shows $100\,\pi_i$ (2 decimals). Redder means larger; the scale runs over the 36 non-corner squares.
- The table merges the three jail states into one "In Jail" row: $4.33 + 3.61 + 3.01 = 10.94\%$ of turns. Next come Dublin 2.95%, GO 2.91%, Lisbon 2.85%, Vienna 2.84% and Paris CDG Airport 2.83%. Just Visiting alone is 2.08%, so the jail corner as a whole is $10.94 + 2.08 \approx 13\%$.
- **Why Jail:** three ways in (frame 2, step 4), and with "stay" you sit there for up to three turns.
- **Why squares 5–9 after jail are high:** everyone leaves jail sooner or later from square 11, and totals 6–8 are the most likely rolls. Stockholm (+6), Vienna (+8) and Lisbon (+9) are ranks 4, 3 and 2 among the 22 capitals; Dublin (+14) is first, helped by the "Advance to Dublin" card.
- **Why Chance squares are low (0.79–1.03%):** 10 of 16 cards move you away, so few turns *end* there.
- Go To Jail is 0%: nobody ends a turn on it.
- Least visited capitals: Vilnius 1.90%, Berlin 1.93%, Riga 1.95%. The stretch from square 32 round to 4 is reached mostly by tokens coming from squares 21–39. Go To Jail (31) and the Chance at 37 send many of those tokens elsewhere, so fewer arrive.

---

## Frame 8: Check, theory vs. simulation (`R/walk.R`, `analysis/walk.R`)

- `simulate_walk()` rolls real dice and draws random cards for one token, turn by turn. It does not use $L$, $N$, $D$ or $P$: it is a second, independent implementation of the same rules.
- After $n$ turns, the empirical distribution is $\hat\pi_i = \#\{t \le n : X_t = i\} / n$.
- **Distance.** We use total variation:
  $$d_{TV}(\hat\pi, \pi) = \tfrac12 \sum_i |\hat\pi_i - \pi_i| = \max_A |\hat\pi(A) - \pi(A)|.$$
  It is the largest possible difference in probability between the two distributions for any event $A$, and lies between 0 and 1.
- **Result.** 5 runs of $10^6$ turns each, distance measured at 17 checkpoints from $10^2$ to $10^6$ turns. Average distance: 0.24 at 100 turns, 0.025 at $10^4$, 0.0025 at $10^6$ (strategy "stay"; "pay" gives 0.0022).
- **Rate $1/\sqrt{n}$.** Each $\hat\pi_i$ is an average along the chain. By the central limit theorem for ergodic Markov chains, its error is of order $\sigma_i/\sqrt{n}$, so the sum is too. In the plot, 100 times more turns gives 10 times smaller distance, a straight line of slope $-\tfrac12$ on log-log axes. The dashed orange line is $c/\sqrt n$, anchored at the final value.
- **Why this convinces:** two independent programs agree to 0.25%, and the error shrinks at exactly the rate random noise should. A modelling bug (say, a wrong card target) would leave a gap that does not shrink. `tests/test-walk.R` also requires the distance after 50,000 turns to be below 0.02 for both strategies.

---

## Frame 9: Jail, stay or pay?

- **Stay:** try for doubles on up to 3 turns (the chain's default). **Pay:** pay €50 at once, then take a normal turn.
- Share of turns spent in jail: 10.94% with stay vs 4.69% with pay.
- **The bars** show $100(\pi^{\text{pay}}_i - \pi^{\text{stay}}_i)$ in percentage points for every square except Jail. Their sum is minus the change for the jail square: the total stays 1.
- **Most squares gain** because paying means you move every turn. The biggest gains are Community Chest 18 (+7 after jail) at +0.37 pp, Frankfurt Airport (+5) at +0.35 pp and Lisbon (+9) at +0.33 pp. Lisbon gains most among the capitals.
- **A few squares lose:** EU Parliament (+2) −0.13 pp, Helsinki (+4) −0.06, Free Parking (+10) −0.03 and Chance 23 (+12) −0.03. All of these are *doubles totals* from jail. Under "stay", leaving with doubles ends your turn there (no extra roll), which piles turn-ends onto squares an even distance after jail. Under "pay", doubles give an extra roll, so the turn ends further on. Stockholm (+6) and Vienna (+8) are doubles totals too, which is why they gain little.
- **What it means for players** (not on the slide; good for questions): in jail you still collect rent but cannot land on anyone's hotel. So: pay early (to buy cities) and stay late (when the board is full of hotels). Our game players always pay; the chain shows the default "stay".

---

## Frame 10: Community Chest card, "Bank error in your favour. Simulate 10 000 games for free."

Two tournaments of 5,000 games each = 10,000 games.

---

## Frame 11: Monopoly lite, the rules we simulate (`R/game.R`)

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

**Game over:** the last player standing wins. After 300 rounds the highest net worth (cash + purchase prices + house costs) wins. Of the 5,000 personality games, 1.2% hit the cap; of the colour-war games, 17.4% (8 players take longer: median 81 rounds vs 60).

**Simplifications to admit if asked:**
- Cards are random draws, as in the chain.
- All players use the same jail habit: use a Get Out of Jail Free card if they have one, otherwise pay at once.
- Building happens at the start of the player's own turn only.

---

## Frame 12: One game in R

- The live code runs one game between the five personalities with `set.seed(24)`. Here the Orange Fanatic wins by bankruptcy in round 83. This is one game picked for fun; frames 15–16 are the statistics.
- A player is `make_player(name, buy, reserve, jail)`. `buy(game, me, pos)` returns TRUE/FALSE for the unowned square `pos`. `reserve` is cash the player never spends on buying or building. `jail` is "pay" or "stay".
- `play_game()` is 38 lines and `R/game.R` is about 270 lines including comments, both counted live on the slide. Tested in `tests/test-game.R`: rent rules, house sales, bankruptcy to a creditor, even building, Grandma never buys.

---

## Frame 13: Meet the players (`R/strategies.R`)

| Player | Buys | Keeps |
|---|---|---|
| Orange Fanatic | Stockholm, Vienna, Lisbon only | €50 |
| Hoarder | everything it lands on | €100 |
| Paris Snob | Berlin and Paris only | €50 |
| Jet-Setter | the four airports only | €50 |
| Grandma | nothing | €0 |

Everyone builds houses evenly on every full set they own, as fast as the reserve allows, and pays to leave jail.

---

## Frame 14: Expected income per colour set (Task 5, not ours)

Left for the group. The tools are there: `landings_per_turn()` × rent table → expected rent per opponent turn.

---

## Frame 15: Tournament 1, all five at one table (`analysis/tournament.R`)

- **Setup.** 5,000 games, all five personalities at one table, seating order shuffled every game (`sample()`), cap 300 rounds, seed 2026.
- **Win rates and exact 95% Clopper–Pearson intervals** (`binom.test`):

| Player | Win rate | 95% CI |
|---|---|---|
| Hoarder | 68.9% | [67.6, 70.2] |
| Paris Snob | 21.5% | [20.4, 22.7] |
| Orange Fanatic | 8.2% | [7.5, 9.0] |
| Jet-Setter | 1.3% | [1.0, 1.6] |
| Grandma | 0.06% | 3 wins |

- The dashed line at $1/5$ is what pure luck would give.
- **Why the Hoarder wins:** it owns many cities early, and its random landings complete sets (including orange) before the specialists can. The Hoarder is the first to own the whole orange set in 60.0% of games. That includes sets gained from a bankrupt Orange Fanatic.
- **The Orange Fanatic gets all three in only 12.8% of games, but then wins 64.6% of them.** When it doesn't complete the set it never wins (0 of 4,362 games). Orange is strong *if* you get it; the hard part is getting it.
- **The Paris Snob does better** than the Orange Fanatic: a 2-city set is easier to complete, and Paris/Berlin hotels charge up to €2000/€1500.
- **Interval method.** Clopper–Pearson inverts the exact binomial test. With $n = 5000$, the half-width is about $1.96\sqrt{p(1-p)/n}$, roughly ±1.3 pp at $p = 0.69$.
- **Seat order barely matters:** the Hoarder wins 66–73% whichever seat moves first.

---

## Frame 16: Tournament 2, colour war

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
- **"A tie at the top."** Orange, dark blue and red have overlapping intervals. Overlap is a rough guide, not a test, so here is a direct check. Win counts are multinomial; for two players, $\widehat{\operatorname{Var}}(\hat p_1 - \hat p_2) = (p_1 + p_2 - (p_1 - p_2)^2)/n$.
  - Orange vs dark blue: difference 0.2 pp, $z \approx 0.2$.
  - Orange vs red: difference 1.2 pp, $z \approx 1.4$.

  Neither is significant at 5%, so "orange is at least as good as anything" is fair. "Orange is strictly best" is not supported.
- **Even unopposed, a set gets completed only when its owner has landed on every square of it before going bankrupt.** Orange is completed most often (48.4%) because its squares have the highest $\pi$ of any 3-city set (frame 7). Dark blue (45.1%) needs only 2 cities, which offsets its low $\pi$. That is the link between section 3 (where you land) and section 5 (who wins).
- **Win rate if completed:** orange 41.5%, red 44.1%, dark blue 44.1%, yellow 41.1%, green 37.8%, pink 24.1%, light blue 11.3%, brown 1.0%. No uncle ever won without completing his own set (0 of 5,000 games). Once completed, orange, red, yellow and dark blue are about equally strong; orange's edge is how *often* it gets completed.
- **Brown completes 42% of the time but almost never wins:** hotel rent €250–450 is too small against everyone else's.

### Answer to the uncle (for the conclusion slide, which the group will write)

1. You land most in Jail; among the capitals, Dublin, then Lisbon and Vienna.
2. In a fair fight between sets, orange is joint best. But only if you actually get all three cities; against a Hoarder who buys everything, waiting for orange loses.

---

## Assumptions worth saying out loud (all in one place)

1. **Cards are random draws** (Markov chain, walk and game alike). Real decks cycle in order.
2. **The Markov chain ignores money** and Get Out of Jail Free cards. It describes one token's movement only.
3. **Jail strategy:** the chain shows "stay" by default (frames 6–7) and compares it with "pay" (frame 9). Game players always pay.
4. **The game drops** trading, auctions, mortgages and the house shortage, and caps games at 300 rounds.
5. **Personalities are deliberately simple:** fixed buy lists and a cash reserve. Real players trade, which would help the Orange Fanatic complete its set.

## References

- Ash, R. B. and Bishop, R. L. (1972). Monopoly as a Markov process. *Mathematics Magazine* 45(1), 26–29.
- Stewart, I. (1996). How fair is Monopoly? *Scientific American* 274(4), 104–105.
