# Build slides/slides.pdf. Run from anywhere in the repo:
#   Rscript slides/build.R
# Build another .Rnw in slides/ by naming it:  Rscript slides/build.R preview-intro
args <- commandArgs(trailingOnly = TRUE)
name <- if (length(args) > 0) basename(sub("\\.Rnw$", "", args[1])) else "slides"

setwd(here::here("slides"))
utils::Sweave(paste0(name, ".Rnw"), encoding = "UTF-8")

# Sweave.sty ships with R, not with LaTeX: tell LaTeX where to find it.
Sys.setenv(TEXINPUTS = paste0(file.path(R.home("share"), "texmf", "tex", "latex"),
                              .Platform$path.sep))
tinytex::latexmk(paste0(name, ".tex"))
