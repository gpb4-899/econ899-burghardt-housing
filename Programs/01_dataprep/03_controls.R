# 03_controls.R
# ---------------------------------------------------------------
# Downloads quarterly macro controls from Eurostat for the euro
# area sample and reshapes to a country by quarter panel:
#   real GDP growth, HICP inflation, unemployment rate.
# Writes: Data/data_for_analysis/controls_quarterly.rds (+ .csv)
# ---------------------------------------------------------------

source("config.R")

library(eurostat)
library(dplyr)
library(tidyr)
library(lubridate)
library(janitor)

# Eurostat uses EL for Greece, so map from our ISO2 sample codes.
iso2_to_eurostat <- c(
  DE = "DE", FR = "FR", IT = "IT", ES = "ES", NL = "NL", BE = "BE",
  AT = "AT", FI = "FI", IE = "IE", PT = "PT", GR = "EL"
)
geo_codes <- unname(iso2_to_eurostat[SAMPLE_COUNTRIES])

# ---- 1. Real GDP (chain linked volumes), seasonally adjusted ----
# time_format = "date" makes eurostat return ready parsed Date objects,
# so we only need to floor them to the quarter start.
gdp <- get_eurostat("namq_10_gdp", time_format = "date") |>
  clean_names() |>
  filter(
    geo %in% geo_codes,
    na_item == "B1GQ",       # gross domestic product at market prices
    unit == "CLV10_MEUR",    # chain linked volumes, 2010 reference
    s_adj == "SCA"           # seasonally and calendar adjusted
  ) |>
  transmute(geo, yq = floor_date(time_period, "quarter"),
            gdp = as.numeric(values))

# ---- 2. HICP, all items, monthly index ----
hicp <- get_eurostat("prc_hicp_midx", time_format = "date") |>
  clean_names() |>
  filter(
    geo %in% geo_codes,
    coicop == "CP00",        # all items
    unit == "I15"            # index, 2015 = 100
  ) |>
  transmute(geo, month = time_period, hicp = as.numeric(values))

# ---- 3. Unemployment rate, MONTHLY then averaged to quarterly ----
# NOTE: the quarterly series une_rt_q only starts around 2009 for most
# euro area countries in the current Eurostat vintage, which was the
# single cause of the ~400 observation loss once unemployment was
# required in the regression. The monthly harmonised series une_rt_m
# carries the same concept back to the late 1990s, so we pull it and
# collapse to a quarterly average instead.
unemp_raw <- get_eurostat("une_rt_m", time_format = "date") |>
  clean_names()

# une_rt_m codes the total working age band as "TOTAL" (not "Y15-74",
# which is what the quarterly une_rt_q uses). Same headline concept,
# total unemployment rate as a share of the active population.
unemp_m <- unemp_raw |>
  filter(
    geo   %in% geo_codes,
    s_adj == "SA",
    age   == "TOTAL",
    sex   == "T",
    unit  == "PC_ACT"        # percent of active population
  ) |>
  transmute(geo, month = time_period, unemp = as.numeric(values))

# Safety net: if a dimension code ever changes and the filter empties,
# stop and show what the dataset actually offers instead of silently
# returning all NA.
if (nrow(unemp_m) == 0) {
  cat("une_rt_m filter returned 0 rows. Available codes:\n")
  cat("  age :", paste(sort(unique(unemp_raw$age)),   collapse = ", "), "\n")
  cat("  unit:", paste(sort(unique(unemp_raw$unit)),  collapse = ", "), "\n")
  cat("  sex :", paste(sort(unique(unemp_raw$sex)),   collapse = ", "), "\n")
  cat("  s_adj:", paste(sort(unique(unemp_raw$s_adj)), collapse = ", "), "\n")
  stop("Adjust the une_rt_m filter to one of the codes listed above.")
}

unemp <- unemp_m |>
  mutate(yq = floor_date(month, "quarter")) |>
  group_by(geo, yq) |>
  summarise(unemp = mean(unemp, na.rm = TRUE), .groups = "drop")

cat("Downloaded Eurostat series.\n")

# ---- 4. Collapse monthly HICP to a quarterly average ----
hicp_q <- hicp |>
  mutate(yq = floor_date(month, "quarter")) |>
  group_by(geo, yq) |>
  summarise(hicp = mean(hicp, na.rm = TRUE), .groups = "drop")

# ---- 5. Merge the three, map geo back to our ISO2 codes ----
eurostat_to_iso2 <- setNames(names(iso2_to_eurostat), iso2_to_eurostat)

controls <- gdp |>
  full_join(hicp_q, by = c("geo", "yq")) |>
  full_join(unemp, by = c("geo", "yq")) |>
  mutate(country = eurostat_to_iso2[geo]) |>
  filter(!is.na(country)) |>
  arrange(country, yq)

# ---- 6. Derive growth rates and inflation ----
controls <- controls |>
  group_by(country) |>
  arrange(yq, .by_group = TRUE) |>
  mutate(
    gdp_growth = 100 * (log(gdp) - log(dplyr::lag(gdp, 1))),   # q on q
    inflation  = 100 * (log(hicp) - log(dplyr::lag(hicp, 4)))  # y on y
  ) |>
  ungroup() |>
  select(country, yq, gdp_growth, inflation, unemp)

# ---- 7. Sanity checks + explicit coverage report ----
# Print the first non missing quarter per country for every control so
# a coverage gap can never hide again and silently drop observations.
cat("\nControls panel:\n")
cat("  Countries:", paste(sort(unique(controls$country)), collapse = ", "), "\n")
cat("  Range:", format(min(controls$yq)), "to", format(max(controls$yq)), "\n")
cat("  Rows:", nrow(controls), "\n")
print(summary(controls[, c("gdp_growth", "inflation", "unemp")]))

cat("\nEarliest non missing quarter per country (coverage check):\n")
coverage <- controls |>
  group_by(country) |>
  summarise(
    gdp_growth = format(min(yq[!is.na(gdp_growth)])),
    inflation  = format(min(yq[!is.na(inflation)])),
    unemp      = format(min(yq[!is.na(unemp)])),
    .groups = "drop"
  )
print(as.data.frame(coverage))

# ---- 8. Save ----
saveRDS(controls, file.path(PATH$clean, "controls_quarterly.rds"))
write.csv(controls, file.path(PATH$clean, "controls_quarterly.csv"), row.names = FALSE)

cat("\nSaved: controls_quarterly.rds / .csv\n")