# 05_diagnostics.R
# ---------------------------------------------------------------
# Three diagnostics on why the full sample interaction is weak:
#   PART 1  Shock validation. Plot the pure shock over time, print
#           its values in known ECB episodes, and compare the raw
#           versus information cleaned shock in the baseline LP.
#   PART 2  LP dynamics. Add lags of the shock and lags of house
#           price growth to the interaction specification, as is
#           standard for local projections, and re estimate.
#   PART 3  Subsample split. Estimate the interaction separately for
#           1999 to 2008 and for 2009 onward to see whether the
#           heterogeneity is period specific.
#
# Reads the cleaned inputs, writes:
#   Results/figures/shock_series.pdf
#   Results/figures/irf_dynamics.pdf
#   Results/tables/subsample_interaction.csv
# ---------------------------------------------------------------

source("config.R")

library(dplyr)
library(tidyr)
library(fixest)
library(ggplot2)

# ---- Rebuild the panel (same construction as 03_merge_and_regress.R) ----
shock    <- readRDS(file.path(PATH$clean, "mp_shock_quarterly.rds"))
hp       <- readRDS(file.path(PATH$clean, "house_prices_quarterly.rds"))
controls <- readRDS(file.path(PATH$clean, "controls_quarterly.rds"))

mortgage_structure <- MORTGAGE_STRUCTURE   # defined in config.R

panel <- hp |>
  inner_join(shock |> select(-year, -quarter), by = "yq") |>
  left_join(controls, by = c("country", "yq")) |>
  left_join(mortgage_structure, by = "country") |>
  filter(yq >= as.Date(SAMPLE_START)) |>
  arrange(country, yq) |>
  mutate(
    log_hp    = log(hp_real),
    shock     = shock_pure,   # information cleaned pure MP shock (3M OIS)
    shock_raw = ois_3m,       # raw 3 month OIS surprise, no filtering
    covid     = as.integer(yq >= as.Date("2020-01-01") &
                           yq <= as.Date("2021-06-01"))
  )

# Within country lags and house price growth for the LP dynamics.
panel <- panel |>
  group_by(country) |>
  arrange(yq, .by_group = TRUE) |>
  mutate(
    lag_log_hp   = dplyr::lag(log_hp, 1),
    g            = 100 * (log_hp - dplyr::lag(log_hp, 1)),  # q on q growth
    l1_g         = dplyr::lag(g, 1),
    l2_g         = dplyr::lag(g, 2),
    l1_shock     = dplyr::lag(shock, 1),
    l2_shock     = dplyr::lag(shock, 2),
    l_gdp_growth = dplyr::lag(gdp_growth, 1),
    l_inflation  = dplyr::lag(inflation, 1),
    l_unemp      = dplyr::lag(unemp, 1)
  ) |>
  ungroup()

# Cumulative outcome from t-1 to t+h, in percent (as in the main script).
make_dy <- function(df, h) {
  df |>
    group_by(country) |>
    arrange(yq, .by_group = TRUE) |>
    mutate(dy = 100 * (dplyr::lead(log_hp, h) - lag_log_hp)) |>
    ungroup()
}

# =================================================================
# PART 1: SHOCK VALIDATION
# =================================================================
cat("\n########## PART 1: SHOCK VALIDATION ##########\n")

# 1a. The shock is common across countries, so collapse to one row/quarter.
sh <- panel |> distinct(yq, shock, shock_raw)

p_sh <- ggplot(sh, aes(x = yq, y = shock)) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_col(width = 60) +
  labs(
    x = NULL,
    y = "Pure MP shock (summed 3m OIS surprise, bp)",
    title = "Information cleaned ECB monetary policy shock",
    subtitle = "Positive = tightening surprise"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(PATH$figures, "shock_series.pdf"), p_sh, width = 8, height = 4)

# 1b. Print the shock in quarters of well known ECB moves so you can
# eyeball whether the sign and size are plausible.
episodes <- c("2008-10-01",  # crisis cuts
              "2011-04-01","2011-07-01",  # Trichet hikes
              "2014-07-01","2015-01-01",  # easing / QE announcement
              "2022-07-01","2022-10-01","2023-01-01")  # tightening cycle
cat("\nShock in known ECB episodes (expect + in hiking quarters,",
    "- in easing quarters):\n")
print(sh |> filter(yq %in% as.Date(episodes)) |> as.data.frame())
cat("\nCorrelation raw vs pure shock:", round(cor(sh$shock_raw, sh$shock), 3), "\n")

# 1c. Baseline LP with the raw shock vs the pure shock, side by side.
# If the raw shock gives the wrong sign and the pure shock does not,
# the information filter is doing its job; if both are flat, the
# problem is elsewhere.
cat("\nBaseline house price response: raw vs pure shock\n")
cmp <- lapply(0:8, function(h) {
  d <- make_dy(panel, h)
  m_raw  <- feols(dy ~ shock_raw + l_gdp_growth + l_inflation + covid | country,
                  data = d, panel.id = ~ country + yq, vcov = "DK")
  m_pure <- feols(dy ~ shock + l_gdp_growth + l_inflation + covid | country,
                  data = d, panel.id = ~ country + yq, vcov = "DK")
  tibble(
    h      = h,
    b_raw  = coef(m_raw)["shock_raw"],  se_raw  = se(m_raw)["shock_raw"],
    b_pure = coef(m_pure)["shock"],     se_pure = se(m_pure)["shock"]
  )
}) |> bind_rows()
print(as.data.frame(round(cmp, 4)))

# =================================================================
# PART 2: LP DYNAMICS
# =================================================================
cat("\n########## PART 2: LP WITH DYNAMICS ##########\n")
# Add two lags of the shock and two lags of house price growth. This
# is the standard Jorda local projection control set and usually
# tightens the estimates.
ctrl_dyn <- paste("l1_shock + l2_shock + l1_g + l2_g +",
                  "l_gdp_growth + l_inflation + covid")

irf_dyn <- lapply(0:12, function(h) {
  d <- make_dy(panel, h)
  f <- as.formula(paste("dy ~ shock + shock:arm +", ctrl_dyn, "| country"))
  m <- feols(f, data = d, panel.id = ~ country + yq, vcov = "DK")
  tibble(
    h        = h,
    nobs     = m$nobs,
    b_shock  = coef(m)["shock"],      se_shock = se(m)["shock"],
    b_inter  = coef(m)["shock:arm"],  se_inter = se(m)["shock:arm"]
  )
}) |> bind_rows()
cat("\nInteraction IRF with dynamics (compare b_inter to the main run):\n")
print(as.data.frame(round(irf_dyn, 4)))

p_dyn <- irf_dyn |>
  mutate(lo = b_inter - 1.96 * se_inter, hi = b_inter + 1.96 * se_inter) |>
  ggplot(aes(x = h, y = b_inter)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2) +
  geom_line(linewidth = 0.8) +
  labs(x = "Quarters after shock",
       y = "Differential response of ARM countries (pp)",
       title = "Interaction IRF with LP dynamics") +
  theme_minimal(base_size = 12)
ggsave(file.path(PATH$figures, "irf_dynamics.pdf"), p_dyn, width = 7, height = 4.5)

# =================================================================
# PART 3: SUBSAMPLE SPLIT (pre vs post 2009)
# =================================================================
cat("\n########## PART 3: SUBSAMPLE SPLIT ##########\n")
# dy is built on the full panel first, then filtered on the base
# quarter t, so the horizon leads still use all available data.
run_sub <- function(lo, hi, label) {
  cat("\n", label, "\n")
  res <- lapply(c(0, 4, 8), function(h) {
    d <- make_dy(panel, h) |>
      filter(yq >= as.Date(lo), yq <= as.Date(hi))
    f <- as.formula(paste("dy ~ shock + shock:arm +", ctrl_dyn, "| country"))
    m <- feols(f, data = d, panel.id = ~ country + yq, vcov = "DK")
    tibble(
      sample   = label,
      h        = h,
      nobs     = m$nobs,
      b_shock  = coef(m)["shock"],      se_shock = se(m)["shock"],
      b_inter  = coef(m)["shock:arm"],  se_inter = se(m)["shock:arm"]
    )
  }) |> bind_rows()
  res |>
    mutate(across(where(is.numeric), \(x) round(x, 4))) |>
    as.data.frame() |>
    print()
  res
}

# The post sample runs to the end of the available panel, so the
# 2024/25 quarters recovered by the date parsing fix are included.
sub_pre  <- run_sub("1999-01-01", "2008-10-01", "PRE 2009 (1999 to 2008)")
sub_post <- run_sub("2009-01-01", as.character(max(panel$yq)),
                    "POST 2009 (2009 onward)")

bind_rows(sub_pre, sub_post) |>
  write.csv(file.path(PATH$tables, "subsample_interaction.csv"),
            row.names = FALSE)

cat("\nSaved: shock_series.pdf, irf_dynamics.pdf, subsample_interaction.csv\n")
