# 01_summary_stats.R
# Summary statistics for the estimation sample of the baseline
# specification at h = 0, so N matches column (1) of the main table.
# Writes: Results/tables/Table01_summary_stats.tex

source("config.R")

library(dplyr)

shock    <- readRDS(file.path(PATH$clean, "mp_shock_quarterly.rds"))
hp       <- readRDS(file.path(PATH$clean, "house_prices_quarterly.rds"))
controls <- readRDS(file.path(PATH$clean, "controls_quarterly.rds"))

mortgage_structure <- MORTGAGE_STRUCTURE   # defined in config.R

# Same panel construction as 02_merge_and_regress.R.
panel <- hp |>
  inner_join(shock |> select(-year, -quarter), by = "yq") |>
  left_join(controls, by = c("country", "yq")) |>
  left_join(mortgage_structure, by = "country") |>
  filter(yq >= as.Date(SAMPLE_START)) |>
  arrange(country, yq) |>
  rename(shock = shock_pure) |>
  mutate(log_hp = log(hp_real)) |>
  group_by(country) |>
  arrange(yq, .by_group = TRUE) |>
  mutate(
    hp_growth    = 100 * (log_hp - dplyr::lag(log_hp, 1)),
    dy0          = 100 * (log_hp - dplyr::lag(log_hp, 1)),  # h = 0 outcome
    l1_g         = dplyr::lag(hp_growth, 1),
    l2_g         = dplyr::lag(hp_growth, 2),
    l1_shock     = dplyr::lag(shock, 1),
    l2_shock     = dplyr::lag(shock, 2),
    l_gdp_growth = dplyr::lag(gdp_growth, 1),
    l_inflation  = dplyr::lag(inflation, 1)
  ) |>
  ungroup()

# Restrict to the baseline estimation sample at horizon zero.
panel <- panel |>
  filter(complete.cases(dy0, shock, l1_shock, l2_shock, l1_g, l2_g,
                        l_gdp_growth, l_inflation))
cat("Estimation sample (baseline, h = 0):", nrow(panel), "observations\n")

vars <- c(
  "Real house price index"            = "hp_real",
  "Real house price growth (\\%, q/q)"= "hp_growth",
  "MP shock (bp)"                     = "shock",
  "GDP growth (\\%, q/q)"             = "gdp_growth",
  "Inflation (\\%, y/y)"              = "inflation",
  "Unemployment (\\%)"               = "unemp",
  "ARM country (=1)"                  = "arm"
)

fmt <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")

body <- vapply(names(vars), function(lab) {
  x <- panel[[vars[[lab]]]]
  x <- x[is.finite(x)]
  sprintf("%s & %d & %s & %s & %s & %s \\\\",
          lab, length(x), fmt(mean(x)), fmt(sd(x)), fmt(min(x)), fmt(max(x)))
}, character(1))

rng <- sprintf("%sQ%d to %sQ%d",
               format(min(panel$yq), "%Y"), (as.integer(format(min(panel$yq), "%m")) + 2) %/% 3,
               format(max(panel$yq), "%Y"), (as.integer(format(max(panel$yq), "%m")) + 2) %/% 3)
n_ctry <- length(unique(panel$country))

tex <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Summary statistics}", "\\label{tab:summary}",
  "\\begin{tabular}{lrrrrr}", "\\hline\\hline",
  "Variable & N & Mean & SD & Min & Max \\\\", "\\hline",
  body,
  "\\hline\\hline", "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}\\footnotesize",
  sprintf(paste0("\\vspace{4pt} Notes: Country by quarter panel, %d euro area countries, %s. ",
    "The sample is the estimation sample of the baseline specification at horizon zero. ",
    "House prices are OECD real residential price indices. The MP shock is the information cleaned ",
    "ECB monetary policy surprise (Jarocinski Karadi poor man's sign restriction on the 3 month OIS). ",
    "Controls are from Eurostat. ARM country is a binary indicator for variable rate dominant markets."),
    n_ctry, rng),
  "\\end{minipage}", "\\end{table}"
)

writeLines(tex, file.path(PATH$tables, "Table01_summary_stats.tex"))
cat("Wrote Results/tables/Table01_summary_stats.tex\n")
cat("Panel:", n_ctry, "countries,", rng, "\n")
