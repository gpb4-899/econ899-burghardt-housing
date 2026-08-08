# 01_main.R -- runs the whole pipeline in order, data preparation
# first, then analysis. Run 00_setup.R once beforehand.

source("config.R")

message("\n==================== DATA PREPARATION ====================")
source(file.path(PATH$prep, "01_shock_series.R"))   # EA-MPD -> quarterly MP shock
source(file.path(PATH$prep, "02_house_prices.R"))   # OECD real house prices (DBnomics)
source(file.path(PATH$prep, "03_controls.R"))       # Eurostat GDP, HICP, unemployment

message("\n==================== ANALYSIS ====================")
source(file.path(PATH$analysis, "01_summary_stats.R"))      # summary statistics table
source(file.path(PATH$analysis, "02_merge_and_regress.R"))  # main tables + IRF
source(file.path(PATH$analysis, "03_coverage_audit.R"))     # sample coverage check
source(file.path(PATH$analysis, "04_diagnostics.R"))        # shock, dynamics, subsample

message("\nPipeline complete. Outputs written to Results/tables and Results/figures.")
