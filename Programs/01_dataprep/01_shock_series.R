# 01_shock_series.R
# EA-MPD events -> quarterly information cleaned MP shock (Jarocinski
# Karadi poor man's sign restriction on the 3 month OIS surprise).
# Writes: Data/data_for_analysis/mp_shock_quarterly.rds (+ .csv)

source("config.R")

library(readxl)
library(dplyr)
library(lubridate)
library(janitor)

ea_mpd_file <- file.path(PATH$raw, "Dataset_EA-MPD.xlsx")

mp_raw <- read_excel(ea_mpd_file, sheet = "Monetary Event Window") |>
  clean_names()

# The date column mixes Excel serial numbers (older rows) and text in
# dd/mm/yyyy (2024 onward); coercing everything with as.numeric() would
# silently drop the recent events.
parse_event_date <- function(x) {
  if (inherits(x, "Date"))    return(x)
  if (inherits(x, "POSIXct")) return(as.Date(x))
  xc  <- as.character(x)
  num <- suppressWarnings(as.numeric(xc))
  out <- as.Date(rep(NA_real_, length(xc)), origin = "1970-01-01")
  # Older rows are stored as Excel serial numbers.
  ok <- !is.na(num)
  out[ok] <- as.Date(num[ok], origin = "1899-12-30")
  # Rows from 2024 onward are stored as TEXT in dd/mm/yyyy format.
  txt <- !ok & !is.na(xc) & nzchar(xc)
  out[txt] <- suppressWarnings(lubridate::dmy(xc[txt]))
  # Last resort for any ISO style strings.
  iso <- txt & is.na(out)
  out[iso] <- suppressWarnings(lubridate::ymd(xc[iso]))
  out
}

n_before <- nrow(mp_raw)
mp_raw <- mp_raw |> mutate(date = parse_event_date(date))
n_bad <- sum(is.na(mp_raw$date))
cat("Date parsing: ", n_before, " rows, ", n_bad, " unparsed.\n", sep = "")

mp_events <- mp_raw |>
  select(date, ois_1m, ois_3m, ois_6m, ois_1y, ois_2y, ois_5y,
         ois_10y, stoxx50) |>
  filter(!is.na(date)) |>
  arrange(date)

# Per event: opposite signs of OIS and STOXX -> pure MP shock,
# same signs -> information shock, zero or missing -> pure by
# convention (missing STOXX events are counted below).
mp_events <- mp_events |>
  mutate(
    is_information = if_else(ois_3m * stoxx50 > 0, 1L, 0L, missing = 0L),
    mp_pure   = if_else(is_information == 0L, ois_3m, 0),
    mp_info   = if_else(is_information == 1L, ois_3m, 0)
  )

cat("Event classification:\n")
cat("  Total events:      ", nrow(mp_events), "\n")
cat("  Information events:", sum(mp_events$is_information), "\n")
cat("  Pure MP events:    ", sum(mp_events$is_information == 0L), "\n")
cat("  Missing STOXX (pure by convention):",
    sum(is.na(mp_events$stoxx50)), "\n\n")

mp_q <- mp_events |>
  mutate(
    year    = year(date),
    quarter = quarter(date),
    yq      = floor_date(date, "quarter")
  ) |>
  group_by(yq, year, quarter) |>
  summarise(
    # raw shock (all events, unadjusted) for comparison
    ois_1m       = sum(ois_1m,  na.rm = TRUE),
    ois_3m       = sum(ois_3m,  na.rm = TRUE),
    ois_1y       = sum(ois_1y,  na.rm = TRUE),
    ois_2y       = sum(ois_2y,  na.rm = TRUE),
    ois_10y      = sum(ois_10y, na.rm = TRUE),
    # information cleaned series
    shock_pure   = sum(mp_pure, na.rm = TRUE),
    shock_info   = sum(mp_info, na.rm = TRUE),
    n_events     = n(),
    n_info       = sum(is_information),
    .groups      = "drop"
  ) |>
  arrange(yq)

cat("Quarterly shock series:\n")
cat("  Range:", format(min(mp_q$yq)), "to", format(max(mp_q$yq)), "\n")
cat("  Quarters:", nrow(mp_q), "\n")
cat("  Correlation raw 3M vs pure:",
    round(cor(mp_q$ois_3m, mp_q$shock_pure), 3), "\n")
print(head(mp_q))
print(tail(mp_q))

saveRDS(mp_q, file.path(PATH$clean, "mp_shock_quarterly.rds"))
write.csv(mp_q, file.path(PATH$clean, "mp_shock_quarterly.csv"), row.names = FALSE)

cat("\nSaved: mp_shock_quarterly.rds / .csv\n")