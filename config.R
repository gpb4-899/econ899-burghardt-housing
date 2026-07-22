# config.R  --  source() this at the start of every program.
# The only file the user is expected to edit.

# Project root (the RStudio project sets the working directory automatically)
ROOT <- getwd()

# Central paths
PATH <- list(
  raw      = file.path(ROOT, "Data", "raw_data"),
  clean    = file.path(ROOT, "Data", "data_for_analysis"),
  prep     = file.path(ROOT, "Programs", "01_dataprep"),
  analysis = file.path(ROOT, "Programs", "02_analysis"),
  tables   = file.path(ROOT, "Results", "tables"),
  figures  = file.path(ROOT, "Results", "figures")
)

# Sample: euro-area countries for the panel
SAMPLE_COUNTRIES <- c("DE","FR","IT","ES","NL","BE","AT","FI","IE","PT","GR")

# Sample period
SAMPLE_START <- "1999-01-01"

# Mortgage market structure: 1 = adjustable rate dominant, 0 = fixed rate
# dominant. Based on Badarinza et al. (2018) and related euro area evidence.
# Defined here so every program uses the same classification.
MORTGAGE_STRUCTURE <- data.frame(
  country = c("DE","AT","FR","BE","NL","FI","IE","PT","ES","IT","GR"),
  arm     = c(  0,   0,   0,   0,   0,   1,   1,   1,   1,   1,   1),
  stringsAsFactors = FALSE
)

