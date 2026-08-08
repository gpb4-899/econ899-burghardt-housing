# config.R -- sourced by every program. The only file the user edits.

ROOT <- getwd()

PATH <- list(
  raw      = file.path(ROOT, "Data", "raw_data"),
  clean    = file.path(ROOT, "Data", "data_for_analysis"),
  prep     = file.path(ROOT, "Programs", "01_dataprep"),
  analysis = file.path(ROOT, "Programs", "02_analysis"),
  tables   = file.path(ROOT, "Results", "tables"),
  figures  = file.path(ROOT, "Results", "figures")
)

SAMPLE_COUNTRIES <- c("DE","FR","IT","ES","NL","BE","AT","FI","IE","PT","GR")

SAMPLE_START <- "1999-01-01"

# Mortgage market structure: arm = 1 if adjustable rate dominant,
# following Badarinza et al. (2018).
MORTGAGE_STRUCTURE <- data.frame(
  country = c("DE","AT","FR","BE","NL","FI","IE","PT","ES","IT","GR"),
  arm     = c(  0,   0,   0,   0,   0,   1,   1,   1,   1,   1,   1),
  stringsAsFactors = FALSE
)

