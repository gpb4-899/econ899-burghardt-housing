# 02_house_prices.R
# OECD real house price indices via DBnomics -> country quarter panel.
# Writes: Data/data_for_analysis/house_prices_quarterly.rds (+ .csv)

source("config.R")

library(rdbnomics)
library(dplyr)
library(tidyr)
library(lubridate)
library(janitor)

iso2_to_iso3 <- c(
  DE = "DEU", FR = "FRA", IT = "ITA", ES = "ESP", NL = "NLD",
  BE = "BEL", AT = "AUT", FI = "FIN", IE = "IRL", PT = "PRT", GR = "GRC"
)
iso3 <- unname(iso2_to_iso3[SAMPLE_COUNTRIES])

cat("Downloading OECD house prices via DBnomics...\n")

hp_raw <- rdb(
  provider_code = "OECD",
  dataset_code  = "DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES",
  dimensions = list(
    REF_AREA = iso3,
    FREQ     = "Q"
  )
) |> clean_names()

cat("\nAvailable measures:\n"); print(unique(hp_raw$measure))

# DBnomics returns full measure LABELS, not codes.
hp <- hp_raw |>
  filter(measure == "Real house price indices") |>
  transmute(
    iso3    = ref_area,
    date    = as.Date(period),          # DBnomics already parses the period
    hp_real = as.numeric(value)
  ) |>
  filter(!is.na(hp_real))

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

cat("\nHouse price panel:\n")
cat("  Countries:", paste(sort(unique(hp$country)), collapse = ", "), "\n")
cat("  Range:", format(min(hp$yq)), "to", format(max(hp$yq)), "\n")
cat("  Rows:", nrow(hp), "\n")
print(hp |> group_by(country) |>
        summarise(first = min(yq), last = max(yq), n = n()))

saveRDS(hp, file.path(PATH$clean, "house_prices_quarterly.rds"))
write.csv(hp, file.path(PATH$clean, "house_prices_quarterly.csv"), row.names = FALSE)

cat("\nSaved: house_prices_quarterly.rds / .csv\n")