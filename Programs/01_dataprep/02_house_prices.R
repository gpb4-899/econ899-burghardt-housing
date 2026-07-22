# 02_house_prices.R
# ---------------------------------------------------------------
# Downloads real residential property price indices from the OECD
# Analytical House Prices dataset via DBnomics (which mirrors OECD
# and handles the SDMX key construction), for the euro-area sample,
# and reshapes to a country-quarter panel.
# Writes: Data/data_for_analysis/house_prices_quarterly.rds (+ .csv)
# ---------------------------------------------------------------

source("config.R")

library(rdbnomics)
library(dplyr)
library(tidyr)
library(lubridate)
library(janitor)

# ---- 1. Map ISO2 sample codes to OECD ISO3 country codes ----
iso2_to_iso3 <- c(
  DE = "DEU", FR = "FRA", IT = "ITA", ES = "ESP", NL = "NLD",
  BE = "BEL", AT = "AUT", FI = "FIN", IE = "IRL", PT = "PRT", GR = "GRC"
)
iso3 <- unname(iso2_to_iso3[SAMPLE_COUNTRIES])

# ---- 2. Pull the real house price index from DBnomics ----
# DBnomics dataset: OECD/DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES
# We fetch quarterly (Q) series for our countries and keep the
# real house price index after download.
cat("Downloading OECD house prices via DBnomics...\n")

hp_raw <- rdb(
  provider_code = "OECD",
  dataset_code  = "DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES",
  dimensions = list(
    REF_AREA = iso3,
    FREQ     = "Q"
  )
) |> clean_names()

# ---- 3. Inspect what came back ----
cat("\nAvailable measures:\n"); print(unique(hp_raw$measure))

# ---- 4. Keep the real house price index, quarterly ----
# DBnomics returns full measure LABELS, not codes.
hp <- hp_raw |>
  filter(measure == "Real house price indices") |>
  transmute(
    iso3    = ref_area,
    date    = as.Date(period),          # DBnomics already parses the period
    hp_real = as.numeric(value)
  ) |>
  filter(!is.na(hp_real))

# ---- 5. Add ISO2 code + derive year/quarter from the parsed date ----
iso3_to_iso2 <- setNames(names(iso2_to_iso3), iso2_to_iso3)

hp <- hp |>
  mutate(
    country = iso3_to_iso2[iso3],
    year    = year(date),
    quarter = quarter(date),
    yq      = floor_date(date, "quarter")
  ) |>
  select(country, iso3, yq, year, quarter, hp_real) |>
  arrange(country, yq)

# ---- 6. Sanity checks ----
cat("\nHouse price panel:\n")
cat("  Countries:", paste(sort(unique(hp$country)), collapse = ", "), "\n")
cat("  Range:", format(min(hp$yq)), "to", format(max(hp$yq)), "\n")
cat("  Rows:", nrow(hp), "\n")
print(hp |> group_by(country) |>
        summarise(first = min(yq), last = max(yq), n = n()))

# ---- 7. Save ----
saveRDS(hp, file.path(PATH$clean, "house_prices_quarterly.rds"))
write.csv(hp, file.path(PATH$clean, "house_prices_quarterly.csv"), row.names = FALSE)

cat("\nSaved: house_prices_quarterly.rds / .csv\n")