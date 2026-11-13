# R/plots.R -- pictures of the board for the slides.
#
# board_tikz() draws the board as TikZ code, straight from board.csv, so the
# picture always matches our data and uses the slide fonts and colours.
# Use it in a Sweave chunk with results=tex inside a tikzpicture:
#
#   \begin{tikzpicture}
#   <<intro-board, echo=FALSE, results=tex>>=
#   cat(board_tikz(board), sep = "\n")
#   @
#   \end{tikzpicture}
#
# Every square becomes a TikZ node named sq<pos> (sq1 = GO, sq11 = Jail, ...),
# and the empty middle of the board is the node `inner`. Slides draw arrows,
# highlights and text on top of these, for example
#   \draw[->] (sq31) -- (sq11);

# Long names that do not fit in a square.
SHORT_NAMES <- c("Amsterdam Schiphol"        = "Schiphol Airport",
                 "Frankfurt Rhein-Main"      = "Frankfurt Airport",
                 "Paris Charles de Gaulle"   = "Paris CDG Airport",
                 "London Heathrow"           = "Heathrow Airport",
                 "European Parliament"       = "EU Parliament",
                 "European Court of Justice" = "EU Court of Justice")

# TikZ styles shared by the board pictures.
TIKZ_STYLES <- c(
  "\\tikzset{",
  "  pg cell/.style={draw=pg-ink, line width=0.4pt, inner sep=0pt, fill=white},",
  "  pg text/.style={inner sep=0pt, align=center, text=pg-ink,",
  "    font=\\fontsize{5}{5.6}\\selectfont},",
  "  pg glyph/.style={inner sep=0pt, font=\\robotoslab\\bfseries\\fontsize{13}{13}\\selectfont}",
  "}")

# TikZ code for the whole board: a colour band and the name on each square.
#   width, height, corner  sizes in cm. The board may be wider than tall to
#                          fill a 16:9 slide; corners are corner x corner.
#   fill    optional, 40 TikZ colours for the squares' background (a heatmap)
#   values  optional, 40 strings printed in bold under the names
board_tikz <- function(board, width = 14, height = 7.7, corner = 1.15,
                       fill = NULL, values = NULL) {
  stopifnot(nrow(board) == N_SQUARES, N_SQUARES %% 4 == 0,
            is.null(fill) || length(fill) == N_SQUARES,
            is.null(values) || length(values) == N_SQUARES)

  per_side <- N_SQUARES / 4 - 1                 # 9 squares between two corners
  cell_w   <- (width - 2 * corner) / per_side   # squares on top and bottom
  cell_h   <- (height - 2 * corner) / per_side  # squares on left and right
  band     <- 0.22                              # colour band depth in cm

  out <- c(
    TIKZ_STYLES,
    sprintf("\\fill[pg-paper] (0,0) rectangle (%.3f,%.3f);", width, height),
    sprintf("\\node[inner sep=0pt, minimum width=%.3fcm, minimum height=%.3fcm] (inner) at (%.3f,%.3f) {};",
            width - 2 * corner, height - 2 * corner, width / 2, height / 2)
  )

  for (pos in seq_len(N_SQUARES)) {
    sq   <- board[pos, ]
    side <- (pos - 1) %/% (per_side + 1)        # 0 bottom, 1 left, 2 top, 3 right
    j    <- (pos - 1) %%  (per_side + 1)        # 0 = corner, 1..9 along the side

    # Rectangle of the square; the board runs anticlockwise from GO (bottom right).
    if (j == 0) {
      x0 <- c(width - corner, 0, 0, width - corner)[side + 1]
      y0 <- c(0, 0, height - corner, height - corner)[side + 1]
      x1 <- x0 + corner
      y1 <- y0 + corner
    } else if (side == 0) {
      x0 <- width - corner - j * cell_w; x1 <- x0 + cell_w; y0 <- 0; y1 <- corner
    } else if (side == 1) {
      y0 <- corner + (j - 1) * cell_h; y1 <- y0 + cell_h; x0 <- 0; x1 <- corner
    } else if (side == 2) {
      x0 <- corner + (j - 1) * cell_w; x1 <- x0 + cell_w; y0 <- height - corner; y1 <- height
    } else {
      y1 <- height - corner - (j - 1) * cell_h; y0 <- y1 - cell_h; x0 <- width - corner; x1 <- width
    }

    out <- c(out, sprintf(
      "\\node[pg cell, minimum width=%.3fcm, minimum height=%.3fcm%s] (sq%d) at (%.3f,%.3f) {};",
      x1 - x0, y1 - y0, if (is.null(fill)) "" else paste0(", fill=", fill[pos]),
      pos, (x0 + x1) / 2, (y0 + y1) / 2))

    if (j == 0) {
      out <- c(out, if (is.null(values)) corner_tikz(sq, x0, y0, corner)
                    else corner_value_tikz(sq, x0, y0, corner, values[pos]))
      next
    }

    # Colour of the square's band (streets, airports, utilities).
    colour <- switch(sq$type,
                     street   = paste0("pg-", gsub("_", "", sq$group)),
                     railroad = "pg-railroad",
                     utility  = "pg-utility",
                     NA)

    # The band sits on the inner edge of the square, facing the middle.
    tx0 <- x0; tx1 <- x1; ty0 <- y0; ty1 <- y1      # area left for text
    if (side == 0)      { bx <- c(x0, x1); by <- c(y1 - band, y1); ty1 <- y1 - band }
    else if (side == 1) { bx <- c(x1 - band, x1); by <- c(y0, y1); tx1 <- x1 - band }
    else if (side == 2) { bx <- c(x0, x1); by <- c(y0, y0 + band); ty0 <- y0 + band }
    else                { bx <- c(x0, x0 + band); by <- c(y0, y1); tx0 <- x0 + band }

    if (!is.na(colour)) {
      out <- c(out, sprintf("\\fill[%s] (%.3f,%.3f) rectangle (%.3f,%.3f);",
                            colour, bx[1], by[1], bx[2], by[2]))
      out <- c(out, sprintf("\\draw[pg-ink, line width=0.4pt] (sq%d.south west) rectangle (sq%d.north east);",
                            pos, pos))
    }

    # Text and symbols inside the square.
    cx <- (tx0 + tx1) / 2
    cy <- (ty0 + ty1) / 2
    text_w <- tx1 - tx0 - 0.1
    value <- if (is.null(values)) "" else sprintf("\\\\[0.2ex]\\textbf{%s}", values[pos])
    if (sq$type %in% c("chance", "chest") && is.null(values)) {
      glyph  <- if (sq$type == "chance") "?" else "\\texteuro"
      gcol   <- if (sq$type == "chance") "pg-orange" else "pg-lightblue!80!pg-darkblue"
      # Side squares are short: put the glyph next to the label, not above it.
      if (side %in% c(1, 3)) {
        out <- c(out, sprintf("\\node[pg glyph, text=%s] at (%.3f,%.3f) {%s};",
                              gcol, (x0 + x1) / 2, (y0 + y1) / 2, glyph))
      } else {
        label <- if (sq$type == "chance") "Chance" else "Community Chest"
        out <- c(out,
          sprintf("\\node[pg glyph, text=%s] at (%.3f,%.3f) {%s};",
                  gcol, cx, cy + 0.12, glyph),
          sprintf("\\node[pg text, text width=%.3fcm, anchor=north] at (%.3f,%.3f) {%s};",
                  text_w, cx, cy - 0.12, label))
      }
      next
    }
    name <- latex_escape(ifelse(sq$name %in% names(SHORT_NAMES),
                                SHORT_NAMES[sq$name], sq$name))
    if (sq$type == "chest" && side %in% c(1, 3)) name <- "Chest"
    # Long single words do not fit the narrow side squares: use a smaller font.
    if (side %in% c(1, 3) && nchar(name) >= 9 && !grepl(" ", name))
      name <- paste0("{\\fontsize{4.3}{5}\\selectfont ", name, "}")
    out <- c(out, sprintf("\\node[pg text, text width=%.3fcm] at (%.3f,%.3f) {%s%s};",
                          text_w, cx, cy, name, value))
  }

  c(out, "\\draw[pg-ink, line width=0.8pt] (0,0) rectangle",
         sprintf("  (%.3f,%.3f);", width, height))
}

# The four corner squares: GO, Jail, Free Parking, Go To Jail.
corner_tikz <- function(sq, x0, y0, size) {
  cx <- x0 + size / 2
  cy <- y0 + size / 2
  big <- "font=\\robotoslab\\bfseries\\fontsize{%s}{%s}\\selectfont"
  switch(sq$type,
    go = c(
      sprintf("\\node[pg text, %s, text=pg-red] at (%.3f,%.3f) {GO};",
              sprintf(big, 15, 15), cx, cy + 0.12),
      sprintf("\\node[pg text] at (%.3f,%.3f) {collect \\texteuro%d};",
              cx, cy - 0.25, RULES$go_salary),
      sprintf("\\draw[pg-red, line width=1.2pt, -{Latex[length=1.6mm]}] (%.3f,%.3f) -- (%.3f,%.3f);",
              x0 + size - 0.15, y0 + 0.14, x0 + 0.15, y0 + 0.14)),
    jail = c(
      # The cell (orange, of course) sits in the inner corner; visitors walk
      # along the outer edges.
      sprintf("\\fill[pg-orange!70] (%.3f,%.3f) rectangle (%.3f,%.3f);",
              x0 + 0.3 * size, y0 + 0.3 * size, x0 + size, y0 + size),
      sprintf("\\foreach \\b in {1,...,5} \\draw[pg-ink, line width=0.7pt] (%.3f+\\b*%.3f,%.3f) -- ++(0,%.3f);",
              x0 + 0.3 * size, 0.7 * size / 6, y0 + 0.3 * size, 0.7 * size),
      sprintf("\\draw[pg-ink, line width=0.4pt] (%.3f,%.3f) rectangle (%.3f,%.3f);",
              x0 + 0.3 * size, y0 + 0.3 * size, x0 + size, y0 + size),
      sprintf("\\node[pg text, fill=white, inner sep=1pt, %s] at (%.3f,%.3f) {JAIL};",
              sprintf(big, 7, 7), x0 + 0.65 * size, y0 + 0.65 * size),
      sprintf("\\node[pg text] at (%.3f,%.3f) {just visiting};",
              cx, y0 + 0.15 * size)),
    parking = sprintf("\\node[pg text, %s] at (%.3f,%.3f) {FREE\\\\PARKING};",
                      sprintf(big, 7, 8.5), cx, cy),
    go_to_jail = sprintf("\\node[pg text, %s] at (%.3f,%.3f) {GO TO\\\\JAIL};",
                         sprintf(big, 7, 8.5), cx, cy),
    stop("unknown corner type: ", sq$type))
}

# TikZ code for the way out of Jail: the Jail corner, the `n` squares after it
# in a row, and above each square a bar with the number of the 36 dice rolls
# whose total reaches it. Squares of colour set `highlight` get an orange ring
# and orange bars. Sizes in cm; (x0, y0) is the bottom left of the first square
# after Jail. Nodes: `exjail` for Jail, `ex1`..`exn` for the squares,
# `bar1`..`barn` for the bar tops (k = steps after Jail).
jail_exit_tikz <- function(board, n = 12, x0 = 2.4, y0 = 0.5, cell = 0.95,
                           cell_h = 1.15, corner = 2.0, bar_unit = 0.22,
                           highlight = "orange") {
  jail  <- board$pos[board$type == "jail"]
  ways  <- tabulate(outer(1:6, 1:6, "+"), nbins = n)   # ways[k]: rolls with total k
  band  <- 0.2
  big   <- "font=\\robotoslab\\bfseries\\fontsize{%s}{%s}\\selectfont"
  bar0  <- y0 + cell_h + 0.15                          # base line of the bars

  # The Jail corner, drawn like the board's corner but larger.
  cx0 <- x0 - corner
  out <- c(
    TIKZ_STYLES,
    sprintf("\\node[pg cell, minimum width=%.3fcm, minimum height=%.3fcm] (exjail) at (%.3f,%.3f) {};",
            corner, corner, cx0 + corner / 2, y0 + corner / 2),
    sprintf("\\fill[pg-orange!70] (%.3f,%.3f) rectangle (%.3f,%.3f);",
            cx0 + 0.3 * corner, y0 + 0.3 * corner, x0, y0 + corner),
    sprintf("\\foreach \\b in {1,...,5} \\draw[pg-ink, line width=0.9pt] (%.3f+\\b*%.3f,%.3f) -- ++(0,%.3f);",
            cx0 + 0.3 * corner, 0.7 * corner / 6, y0 + 0.3 * corner, 0.7 * corner),
    sprintf("\\draw[pg-ink, line width=0.4pt] (%.3f,%.3f) rectangle (%.3f,%.3f);",
            cx0 + 0.3 * corner, y0 + 0.3 * corner, x0, y0 + corner),
    sprintf("\\node[pg text, fill=white, inner sep=1.5pt, %s] at (%.3f,%.3f) {JAIL};",
            sprintf(big, 11, 11), cx0 + 0.65 * corner, y0 + 0.65 * corner),
    sprintf("\\node[pg text, font=\\fontsize{6}{7}\\selectfont] at (%.3f,%.3f) {just visiting};",
            cx0 + corner / 2, y0 + 0.15 * corner)
  )

  for (k in seq_len(n)) {
    pos <- move(jail, k)
    sq  <- board[pos, ]
    xa  <- x0 + (k - 1) * cell
    xm  <- xa + cell / 2
    hot <- identical(sq$group, highlight)
    colour <- switch(sq$type,
                     street   = paste0("pg-", gsub("_", "", sq$group)),
                     railroad = "pg-railroad",
                     utility  = "pg-utility",
                     NA)
    name <- switch(sq$type,
                   chance  = "Chance",
                   chest   = "Community Chest",
                   parking = "Free Parking",
                   latex_escape(ifelse(sq$name %in% names(SHORT_NAMES),
                                       SHORT_NAMES[sq$name], sq$name)))
    out <- c(out,
      sprintf("\\node[pg cell, minimum width=%.3fcm, minimum height=%.3fcm] (ex%d) at (%.3f,%.3f) {};",
              cell, cell_h, k, xm, y0 + cell_h / 2),
      if (!is.na(colour)) sprintf("\\fill[%s] (%.3f,%.3f) rectangle (%.3f,%.3f);",
                                  colour, xa, y0 + cell_h - band, xa + cell, y0 + cell_h),
      sprintf("\\draw[pg-ink, line width=0.4pt] (ex%d.south west) rectangle (ex%d.north east);", k, k),
      sprintf("\\node[pg text, text width=%.3fcm] at (%.3f,%.3f) {%s};",
              cell - 0.1, xm, y0 + (cell_h - band) / 2, name),
      sprintf("\\node[font=\\scriptsize, text=pg-muted] at (%.3f,%.3f) {+%d};",
              xm, y0 - 0.25, k),
      if (hot) sprintf("\\draw[pg-orange, line width=1.8pt, rounded corners=1pt] (ex%d.south west) rectangle (ex%d.north east);", k, k))

    h <- ways[k] * bar_unit
    out <- c(out,
      sprintf("\\coordinate (bar%d) at (%.3f,%.3f);", k, xm, bar0 + h),
      if (ways[k] > 0) c(
        sprintf("\\fill[%s] (%.3f,%.3f) rectangle (%.3f,%.3f);",
                if (hot) "pg-orange" else "pg-ink!45", xm - 0.3 * cell, bar0, xm + 0.3 * cell, bar0 + h),
        sprintf("\\node[font=\\scriptsize%s, text=%s, anchor=south] at (bar%d) {%d};",
                if (hot) "\\bfseries" else "", if (hot) "pg-orange!80!pg-ink" else "pg-muted",
                k, ways[k])))
  }
  c(out, sprintf("\\draw[pg-muted, line width=0.4pt] (%.3f,%.3f) -- (%.3f,%.3f);",
                 x0, bar0, x0 + n * cell, bar0))
}

# A plain corner for heatmaps: its name and the value, no pictures.
corner_value_tikz <- function(sq, x0, y0, size, value) {
  label <- switch(sq$type, go = "GO", jail = "Just\\\\Visiting",
                  parking = "Free\\\\Parking", go_to_jail = "Go To\\\\Jail",
                  stop("unknown corner type: ", sq$type))
  sprintf("\\node[pg text, font=\\fontsize{6}{7}\\selectfont] at (%.3f,%.3f) {%s\\\\[0.3ex]\\textbf{%s}};",
          x0 + size / 2, y0 + size / 2, label, value)
}

latex_escape <- function(x) {
  gsub("([&%$#_])", "\\\\\\1", x)
}

# ---- Plots for the slides (base R) ------------------------------------------
# Transparent background, so the slide paper shows through.

PLOT_INK   <- "#1E2430"
PLOT_MUTED <- "#7A7468"

plot_style <- function(mar = c(3.2, 3.6, 0.6, 0.6)) {
  par(mar = mar, mgp = c(2.1, 0.6, 0), las = 1, bty = "n", tcl = -0.25,
      col.axis = PLOT_MUTED, col.lab = PLOT_INK, fg = PLOT_MUTED, cex.axis = 0.8)
}

# Plot colour of every square: its colour set, dark for airports, grey otherwise.
square_colours <- function(board) {
  col <- rep("#C9C2B2", N_SQUARES)
  street <- board$type == "street"
  col[street] <- GROUP_COLOURS[board$group[street]]
  col[board$type == "railroad"] <- "#2E2E2E"
  col[board$type == "utility"]  <- "#9C9C9C"
  col
}

# Total variation distance to pi against the number of simulated turns,
# one line per run, with the 1/sqrt(n) rate for reference.
plot_convergence <- function(walk, jail = "stay") {
  n  <- walk$checkpoints
  tv <- walk[[jail]]$tv
  plot_style(mar = c(3.2, 4.4, 0.6, 0.6))
  matplot(n, tv, type = "l", lty = 1, col = adjustcolor(PLOT_INK, 0.45), log = "xy",
          xlab = "simulated turns n", ylab = "", xaxt = "n")
  title(ylab = expression("distance " * italic(d)), line = 3.2)
  e <- seq(ceiling(log10(min(n))), floor(log10(max(n))))
  axis(1, at = 10^e, labels = parse(text = paste0("10^", e)))
  ref <- mean(tv[length(n), ]) * sqrt(max(n) / n)
  lines(n, ref, lty = 2, lwd = 2, col = GROUP_COLOURS[["orange"]])
  text(n[3], ref[3], expression("rate " * 1 / sqrt(n)), pos = 4,
       col = GROUP_COLOURS[["orange"]], cex = 0.9)
}

# Change in pi (percentage points) per square when you pay to leave jail at
# once instead of staying. The jail square itself is left out (shown in text).
plot_jail_shift <- function(board, pi_stay, pi_pay) {
  plot_style(mar = c(3.2, 3.6, 0.6, 0.2))
  d <- 100 * (pi_pay[seq_len(N_SQUARES)] - pi_stay[seq_len(N_SQUARES)])
  jail_sq <- board$pos[board$type == "jail"]
  d[jail_sq] <- NA
  at <- barplot(unname(d), col = square_colours(board), border = NA, space = 0.15,
                ylab = expression("change in " * pi * " (pp)"), xlab = "square (position)")
  ticks <- c(board$pos[board$type %in% c("go", "jail", "parking", "go_to_jail")], N_SQUARES)
  axis(1, at = at[ticks], labels = ticks)
  abline(h = 0, col = PLOT_MUTED)
}

# Win rates with 95% confidence intervals, best on top.
plot_win_rates <- function(rates, colours, chance_level = NULL) {
  rates <- rates[order(rates$rate), ]
  plot_style(mar = c(3.2, 8.5, 0.6, 1))
  k <- nrow(rates)
  plot(100 * rates$rate, seq_len(k), xlim = c(0, 100 * max(rates$upper) * 1.05),
       ylim = c(0.5, k + 0.5), yaxt = "n", pch = 19, cex = 1.4,
       col = colours[rates$player], xlab = "games won (%)", ylab = "")
  axis(2, at = seq_len(k), labels = gsub("_", " ", rates$player), col = NA,
       col.axis = PLOT_INK, cex.axis = 0.85)
  segments(100 * rates$lower, seq_len(k), 100 * rates$upper, seq_len(k),
           lwd = 2, col = colours[rates$player])
  if (!is.null(chance_level)) abline(v = 100 * chance_level, lty = 2, col = PLOT_MUTED)
}
