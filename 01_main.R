# 01_main.R
# ---------------------------------------------------------------
# Master run script. Sources config.R and then every program in the
# correct order, data preparation first, then analysis. It does NOT
# run the setup program: run 00_setup.R once by hand before this to
# install the required packages.
#
# Usage (from the RStudio project root, project open so the working
# directory is the repo root):
#   source("01_main.R")
# ---------------------------------------------------------------

source("config.R")

message("\n==================== DATA PREPARATION ====================")
source(file.path(PATH$prep, "01_shock_series.R"))   # EA-MPD -> quarterly MP shock
source(file.path(PATH$prep, "02_house_prices.R"))   # OECD real house prices (DBnomics)
source(file.path(PATH$prep, "03_controls.R"))       # Eurostat GDP, HICP, unemployment

message("\n==================== ANALYSIS ====================")
source(file.path(PATH$analysis, "01_summary_stats.R"))      # summary statistics table
source(file.path(PATH$analysis, "03_merge_and_regress.R"))  # main tables + IRF
source(file.path(PATH$analysis, "04_coverage_audit.R"))     # sample coverage check
source(file.path(PATH$analysis, "05_diagnostics.R"))        # shock, dynamics, subsample

message("\nPipeline complete. Outputs written to Results/tables and Results/figures.")
