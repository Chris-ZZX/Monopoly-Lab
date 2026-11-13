# Build slides/slides.pdf. Run from anywhere in the repo:
#   Rscript slides/build.R
# Build another .Rnw in slides/ by naming it:  Rscript slides/build.R preview-intro
args <- commandArgs(trailingOnly = TRUE)
name <- if (length(args) > 0) basename(sub("\\.Rnw$", "", args[1])) else "slides"

# A build script may change directory (README's "no setwd()" rule is for
# R/ and analysis/ code): Sweave and LaTeX write their files next to the .Rnw.
setwd(here::here("slides"))
utils::Sweave(paste0(name, ".Rnw"), encoding = "UTF-8")

# Sweave.sty ships with R, not with LaTeX. Copy it next to the .tex file, so
# that compiling slides.tex directly (TeX editor, VS Code, latexmk) works too.
file.copy(file.path(R.home("share"), "texmf", "tex", "latex", "Sweave.sty"),
          "Sweave.sty", overwrite = TRUE)
tinytex::latexmk(paste0(name, ".tex"))

# Remove beamer's helper files. Keep the .tex, Sweave.sty and the figure PDFs,
# so slides.tex still compiles on its own in a TeX editor.
unlink(paste0(name, c(".nav", ".snm", ".toc", ".vrb", ".out")))
