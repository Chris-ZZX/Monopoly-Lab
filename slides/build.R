# Build slides/slides.pdf. Run from anywhere in the repo:
#   Rscript slides/build.R
setwd(here::here("slides"))
utils::Sweave("slides.Rnw", encoding = "UTF-8")

# Sweave.sty ships with R, not with LaTeX: tell LaTeX where to find it.
Sys.setenv(TEXINPUTS = paste0(file.path(R.home("share"), "texmf", "tex", "latex"),
                              .Platform$path.sep))
tinytex::latexmk("slides.tex")
