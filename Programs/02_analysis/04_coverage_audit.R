# 04_coverage_audit.R
# ---------------------------------------------------------------
# Documents sample coverage. Rebuilds the same panel as
# 03_merge_and_regress.R (hp inner join shock, left join controls,
# controls lagged one quarter), then reports:
#   (1) how many observations each lagged control keeps or drops
#   (2) completeness on the BASELINE controls (lagged GDP growth and
#       inflation; unemployment is a robustness check only) and,
#       separately, once unemployment is also required
#   (3) which control is the binding constraint
#   (4) lost observations by country and by year, earliest complete
#       quarter per country
# Writes a compact coverage table to Results/tables/coverage_audit.csv
# so the numbers can be shown to the supervisor.
# ---------------------------------------------------------------

source("config.R")

library(dplyr)
library(tidyr)

# ---- 1. Load the cleaned inputs (same as the regression script) ----
shock    <- readRDS(file.path(PATH$clean, "mp_shock_quarterly.rds"))
hp       <- readRDS(file.path(PATH$clean, "house_prices_quarterly.rds"))
controls <- readRDS(file.path(PATH$clean, "controls_quarterly.rds"))

# ---- 2. Rebuild the panel exactly as in 03_merge_and_regress.R ----
panel <- hp |>
  inner_join(shock |> select(-year, -quarter), by = "yq") |>
  left_join(controls, by = c("country", "yq")) |>
  filter(yq >= as.Date(SAMPLE_START)) |>
  arrange(country, yq)

# ---- 3. Lag the controls one quarter (predetermined), as in reg ----
panel <- panel |>
  group_by(country) |>
  arrange(yq, .by_group = TRUE) |>
  mutate(
    l_gdp_growth = dplyr::lag(gdp_growth, 1),
    l_inflation  = dplyr::lag(inflation, 1),
    l_unemp      = dplyr::lag(unemp, 1)
  ) |>
  ungroup()

reg_cols <- c("l_gdp_growth", "l_inflation", "l_unemp")

# ---- 4. Overall coverage ----
cat("=====================================================\n")
cat(" COVERAGE AUDIT: house price + shock panel\n")
cat("=====================================================\n")
cat("Total country by quarter observations:", nrow(panel), "\n\n")

cat("Non missing by control (after lagging):\n")
for (c in reg_cols) {
  nm <- sum(!is.na(panel[[c]]))
  cat(sprintf("  %-14s kept %4d   dropped %4d\n",
              c, nm, nrow(panel) - nm))
}

# Baseline specification uses only GDP growth and inflation; unemployment
# enters a separate robustness table. Report both sample definitions.
base_cols <- c("l_gdp_growth", "l_inflation")
complete_base <- complete.cases(panel[, base_cols])
complete      <- complete.cases(panel[, reg_cols])
cat("\nComplete on the BASELINE controls (gdp + inflation):",
    sum(complete_base), " -> lost:", sum(!complete_base), "\n")
cat("Complete if unemployment is also required:      ",
    sum(complete), " -> lost:", sum(!complete), "\n")

# ---- 5. Binding constraint: rows missing ONLY one control ----
cat("\nBinding constraint (rows missing ONLY this control):\n")
miss <- is.na(panel[, reg_cols])
for (c in reg_cols) {
  others <- setdiff(reg_cols, c)
  only_c <- miss[, c] & rowSums(miss[, others, drop = FALSE]) == 0
  cat(sprintf("  only %-14s missing: %4d\n", c, sum(only_c)))
}

# ---- 6. Coverage by country, baseline and with unemployment ----
cat("\nCoverage by country:\n")
by_country <- panel |>
  mutate(complete_base = complete_base, complete_all = complete) |>
  group_by(country) |>
  summarise(n = n(),
            kept_baseline   = sum(complete_base),
            kept_with_unemp = sum(complete_all),
            .groups = "drop")
print(as.data.frame(by_country))

# ---- 7. Earliest complete quarter per country ----
cat("\nEarliest quarter with all three controls present:\n")
first_ok <- panel[complete, ] |>
  group_by(country) |>
  summarise(first_complete = min(yq), .groups = "drop")
print(as.data.frame(first_ok))

# ---- 8. Lost observations by year ----
cat("\nLost observations by year:\n")
by_year <- panel |>
  mutate(complete = complete, year = as.integer(format(yq, "%Y"))) |>
  filter(!complete) |>
  group_by(year) |>
  summarise(lost = n(), .groups = "drop")
print(as.data.frame(by_year))

# ---- 9. Save a compact table for the supervisor ----
write.csv(by_country,
          file.path(PATH$tables, "coverage_audit.csv"),
          row.names = FALSE)

cat("\nSaved: Results/tables/coverage_audit.csv\n")
