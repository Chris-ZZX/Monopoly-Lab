# Builds slides/slides.pdf:  Rscript slides/build.R
# (or another .Rnw in slides/:  Rscript slides/build.R other-file)
args <- commandArgs(trailingOnly = TRUE)
name <- if (length(args) > 0) basename(sub("\\.Rnw$", "", args[1])) else "slides"

# Sweave and LaTeX write their files next to the .Rnw
setwd(here::here("slides"))
utils::Sweave(paste0(name, ".Rnw"), encoding = "UTF-8")

# copy Sweave.sty from R so slides.tex also compiles on its own
file.copy(file.path(R.home("share"), "texmf", "tex", "latex", "Sweave.sty"),
          "Sweave.sty", overwrite = TRUE)
tinytex::latexmk(paste0(name, ".tex"))

# clean up beamer's aux files
unlink(paste0(name, c(".nav", ".snm", ".toc", ".vrb", ".out")))
