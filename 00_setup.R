# 00_setup.R  --  run once. Installs all packages.
pkgs <- c(
  "fixest",      # panel regression + Driscoll-Kraay
  "lpirfs",      # local projections impulse responses
  "data.table",  # fast data prep
  "dplyr",       # data manipulation
  "tidyr",       # reshaping
  "lubridate",   # date handling (quarters)
  "readxl",      # read EA-MPD Excel
  "eurostat",    # Eurostat API
  "rsdmx",       # ECB/SDMX access
  "janitor",     # clean column names
  "ggplot2",     # figures
  "modelsummary" # regression tables -> LaTeX
)
to_install <- setdiff(pkgs, rownames(installed.packages()))
if (length(to_install) > 0) install.packages(to_install)
cat("Setup complete.\n")

