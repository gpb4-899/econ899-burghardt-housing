# 00_setup.R  --  run once. Installs all packages.
pkgs <- c(
  "fixest",      # panel regression + Driscoll Kraay, etable -> LaTeX
  "dplyr",       # data manipulation
  "tidyr",       # reshaping
  "lubridate",   # date handling (quarters)
  "readxl",      # read EA-MPD Excel
  "eurostat",    # Eurostat API
  "rdbnomics",   # OECD house prices via DBnomics
  "janitor",     # clean column names
  "ggplot2"      # figures
)
to_install <- setdiff(pkgs, rownames(installed.packages()))
if (length(to_install) > 0) install.packages(to_install)
cat("Setup complete.\n")

