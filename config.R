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

