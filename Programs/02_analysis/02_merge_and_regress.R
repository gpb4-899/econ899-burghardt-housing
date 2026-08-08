# 02_merge_and_regress.R
# ---------------------------------------------------------------
# Builds the country by quarter panel and estimates the paper's main
# local projections.
#
# Baseline specification: Jorda local projection with the standard
# dynamic controls, two lags of the shock and two lags of house price
# growth, plus lagged GDP growth, lagged inflation and a COVID dummy,
# with country fixed effects and Driscoll Kraay standard errors.
#
# Alternative specification: the same without the dynamic terms. It is
# reported alongside the baseline because the interaction coefficient
# is sensitive to whether the dynamics are included, and that
# sensitivity is a result in its own right.
#
# Writes: Results/tables/lp_main.tex          (Table 2, both specs)
#         Results/tables/lp_robust_unemp.tex  (appendix)
#         Results/figures/irf_interaction.pdf (Figure 1)
#         Results/figures/irf_baseline.pdf    (Figure 2)
# ---------------------------------------------------------------

source("config.R")

library(dplyr)
library(tidyr)
library(fixest)
library(ggplot2)

# ---- 1. Load the cleaned inputs ----
shock    <- readRDS(file.path(PATH$clean, "mp_shock_quarterly.rds"))
hp       <- readRDS(file.path(PATH$clean, "house_prices_quarterly.rds"))
controls <- readRDS(file.path(PATH$clean, "controls_quarterly.rds"))

mortgage_structure <- MORTGAGE_STRUCTURE   # defined in config.R

# ---- 2. Build the panel ----
# The shock file carries its own year/quarter columns; drop them before
# the join so they do not duplicate the house price panel's columns.
panel <- hp |>
  inner_join(shock |> select(-year, -quarter), by = "yq") |>
  left_join(controls, by = c("country", "yq")) |>
  left_join(mortgage_structure, by = "country") |>
  filter(yq >= as.Date(SAMPLE_START)) |>
  arrange(country, yq) |>
  rename(shock = shock_pure) |>
  mutate(
    log_hp = log(hp_real),
    covid  = as.integer(yq >= as.Date("2020-01-01") &
                        yq <= as.Date("2021-06-01"))
  )

# ---- 3. Lags. Controls are predetermined; the dynamic terms are the
# standard local projection controls. ----
panel <- panel |>
  group_by(country) |>
  arrange(yq, .by_group = TRUE) |>
  mutate(
    lag_log_hp   = dplyr::lag(log_hp, 1),
    g            = 100 * (log_hp - dplyr::lag(log_hp, 1)),
    l1_g         = dplyr::lag(g, 1),
    l2_g         = dplyr::lag(g, 2),
    l1_shock     = dplyr::lag(shock, 1),
    l2_shock     = dplyr::lag(shock, 2),
    l_gdp_growth = dplyr::lag(gdp_growth, 1),
    l_inflation  = dplyr::lag(inflation, 1),
    l_unemp      = dplyr::lag(unemp, 1)
  ) |>
  ungroup()

cat("Merged panel:\n")
cat("  Countries:", paste(sort(unique(panel$country)), collapse = ", "), "\n")
cat("  Range:", format(min(panel$yq)), "to", format(max(panel$yq)), "\n")
cat("  Rows:", nrow(panel), "\n\n")

# ---- 4. Outcome: cumulative log change from t-1 to t+h, in percent ----
H <- 12
make_dy <- function(df, h) {
  df |>
    group_by(country) |>
    arrange(yq, .by_group = TRUE) |>
    mutate(dy = 100 * (dplyr::lead(log_hp, h) - lag_log_hp)) |>
    ungroup()
}

ctrl_dyn    <- paste("l1_shock + l2_shock + l1_g + l2_g +",
                     "l_gdp_growth + l_inflation + covid")   # baseline
ctrl_simple <- "l_gdp_growth + l_inflation + covid"          # alternative
ctrl_unemp  <- paste(ctrl_dyn, "+ l_unemp")                  # appendix

# Note: the lagged dynamics enter uninteracted. The object of interest is
# the contemporaneous shock x arm term; interacting the full lag set with
# arm would add several parameters to an already weakly identified
# specification. This is a deliberate simplification, stated in the paper.
fit <- function(d, ctrl, interact = TRUE) {
  rhs <- if (interact) "shock + shock:arm" else "shock"
  f <- as.formula(paste("dy ~", rhs, "+", ctrl, "| country"))
  feols(f, data = d, panel.id = ~ country + yq, vcov = "DK")
}

# ---- 5. Impulse responses under both specifications ----
irf <- lapply(0:H, function(h) {
  d  <- make_dy(panel, h)
  mb <- fit(d, ctrl_dyn)         # baseline, with dynamics
  ms <- fit(d, ctrl_simple)      # alternative, no dynamics
  mn <- fit(d, ctrl_dyn, interact = FALSE)   # average effect, baseline
  tibble(
    h            = h,
    nobs         = mb$nobs,
    b_avg        = coef(mn)["shock"],       se_avg   = se(mn)["shock"],
    b_inter_dyn  = coef(mb)["shock:arm"],   se_inter_dyn  = se(mb)["shock:arm"],
    b_inter_simp = coef(ms)["shock:arm"],   se_inter_simp = se(ms)["shock:arm"]
  )
}) |> bind_rows()

cat("Impulse responses (baseline = with dynamics):\n")
print(as.data.frame(round(irf, 4)))

# ---- 6. Table 2: both specifications at horizons 0, 4, 8 ----
models <- list()
for (h in c(0, 4, 8)) {
  d <- make_dy(panel, h)
  models[[paste0("Baseline h=", h)]]     <- fit(d, ctrl_dyn)
  models[[paste0("No dynamics h=", h)]]  <- fit(d, ctrl_simple)
}

lbl <- c(dy = "Cumulative real house price change (\\%)",
         shock = "MP shock", "shock:arm" = "MP shock $\\times$ ARM",
         l1_shock = "MP shock (t-1)", l2_shock = "MP shock (t-2)",
         l1_g = "House price growth (t-1)", l2_g = "House price growth (t-2)",
         l_gdp_growth = "GDP growth (t-1)", l_inflation = "Inflation (t-1)",
         l_unemp = "Unemployment (t-1)", covid = "COVID (2020 to 2021H1)")

etable(models,
       tex     = TRUE,
       file    = file.path(PATH$tables, "Table02_lp_main.tex"),
       replace = TRUE,
       title   = paste("House price response to ECB monetary policy shocks",
                       "by mortgage market structure"),
       label   = "tab:main",
       headers = c("h = 0", "h = 0", "h = 4", "h = 4", "h = 8", "h = 8"),
       notes   = paste("Country by quarter panel of eleven euro area countries,",
                       "1999Q4 to 2025Q4. The dependent variable is the cumulative",
                       "change in log real house prices from $t-1$ to $t+h$, in",
                       "percent per basis point of tightening surprise. Columns (1),",
                       "(3) and (5) show the baseline with dynamic controls at",
                       "horizons 0, 4 and 8, columns (2), (4) and (6) the same",
                       "specification without the dynamic controls."),
       dict    = lbl)

# ---- 7. Appendix: adding unemployment to the baseline ----
rob <- list()
for (h in c(0, 4, 8)) {
  d <- make_dy(panel, h)
  rob[[paste0("h=", h)]] <- fit(d, ctrl_unemp)
}
etable(rob,
       tex = TRUE, file = file.path(PATH$tables, "TableA1_lp_robust_unemp.tex"),
       replace = TRUE,
       title = "Appendix: baseline specification adding unemployment",
       label = "tab:robust_unemp",
       headers = c("h = 0", "h = 4", "h = 8"),
       notes = paste("Baseline specification with the lagged unemployment rate",
                     "added, at horizons 0, 4 and 8. Sample and construction as",
                     "in the main table."),
       dict = lbl)

# ---- 8. Figure 1: interaction under both specifications ----
p_int <- irf |>
  mutate(lo = b_inter_dyn - 1.96 * se_inter_dyn,
         hi = b_inter_dyn + 1.96 * se_inter_dyn) |>
  ggplot(aes(x = h)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.18) +
  geom_line(aes(y = b_inter_dyn), linewidth = 0.9) +
  geom_line(aes(y = b_inter_simp), linewidth = 0.7, linetype = "dotted") +
  scale_x_continuous(breaks = seq(0, 12, 2)) +
  labs(x = "Quarters after the shock",
       y = "Differential response of ARM countries (pp)",
       caption = paste("Solid: baseline with dynamics (95% band).",
                       "Dotted: same specification without dynamic controls.")) +
  theme_minimal(base_size = 12)
ggsave(file.path(PATH$figures, "Fig02_irf_interaction.pdf"), p_int,
       width = 7, height = 4.5)

# ---- 9. Figure 2: average house price response, baseline ----
p_avg <- irf |>
  mutate(lo = b_avg - 1.96 * se_avg, hi = b_avg + 1.96 * se_avg) |>
  ggplot(aes(x = h, y = b_avg)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.18) +
  geom_line(linewidth = 0.9) +
  scale_x_continuous(breaks = seq(0, 12, 2)) +
  labs(x = "Quarters after the shock",
       y = "Real house price response (%)",
       caption = "Average response to a one basis point tightening surprise, 95% band.") +
  theme_minimal(base_size = 12)
ggsave(file.path(PATH$figures, "Fig01_irf_baseline.pdf"), p_avg,
       width = 7, height = 4.5)

# ---- 10. Appendix Table A4: time fixed effects, interaction only ----
# Time fixed effects absorb the shock, its lags, the covid dummy and every
# other euro area wide variable. The main effect drops out and the
# interaction is identified from the within quarter difference between the
# two country groups.
tfe <- list()
for (h in c(0, 4, 8)) {
  d <- make_dy(panel, h)
  f <- as.formula(paste("dy ~ shock:arm + l1_g + l2_g +",
                        "l_gdp_growth + l_inflation | country + yq"))
  tfe[[paste0("h=", h)]] <- feols(f, data = d, panel.id = ~ country + yq,
                                  vcov = "DK")
}
cat("\nTime FE robustness (interaction only):\n")
print(lapply(tfe, function(m) round(coeftable(m)["shock:arm", ], 4)))
etable(tfe, tex = TRUE,
       file = file.path(PATH$tables, "TableA4_timefe.tex"),
       replace = TRUE,
       title = "Robustness: interaction with time fixed effects",
       label = "tab:timefe",
       headers = c("h = 0", "h = 4", "h = 8"),
       notes = paste("Time fixed effects absorb the shock, its lags, the",
                     "pandemic dummy and every other common variable, so only",
                     "the interaction and the country level controls remain.",
                     "Driscoll Kraay standard errors."),
       dict = lbl)

cat("\nSaved: Table02_lp_main.tex, TableA1_lp_robust_unemp.tex,",
    "Fig02_irf_interaction.pdf, Fig01_irf_baseline.pdf and TableA4_timefe.tex\n")
