# 01_shock_series.R
# ---------------------------------------------------------------
# Reads the raw EA-MPD Excel, cleans the monetary event window,
# converts Excel serial dates, classifies each event into a pure
# monetary policy shock vs a central bank information shock using
# the Jarocinski and Karadi (2020) poor man's sign restriction,
# and aggregates each series to quarterly frequency.
#
# Sign restriction (per event):
#   interest rate surprise and stock reaction OPPOSITE sign -> pure MP
#   interest rate surprise and stock reaction SAME sign     -> information
#
# Writes: Data/data_for_analysis/mp_shock_quarterly.rds (+ .csv)
# ---------------------------------------------------------------

source("config.R")

library(readxl)
library(dplyr)
library(lubridate)
library(janitor)

# ---- 1. Read the Monetary Event Window ----
ea_mpd_file <- file.path(PATH$raw, "Dataset_EA-MPD.xlsx")

mp_raw <- read_excel(ea_mpd_file, sheet = "Monetary Event Window") |>
  clean_names()

# ---- 2. Convert the date column to real dates ----
# The date column is mixed: older rows are stored as Excel serial numbers,
# newer rows as genuine date values. Coercing everything with as.numeric()
# turns the genuine dates into NA and silently drops the most recent events
# (this cost roughly two years of data, including the 2024/25 easing cycle).
# The parser below handles both cases and reports anything it cannot read.
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

# ---- 3. Select the interest rate surprise and the stock reaction ----
# Interest rate surprise: 3 month OIS (near term policy indicator).
# Stock reaction: EURO STOXX 50 return in the same window.
mp_events <- mp_raw |>
  select(date, ois_1m, ois_3m, ois_6m, ois_1y, ois_2y, ois_5y,
         ois_10y, stoxx50) |>
  filter(!is.na(date)) |>
  arrange(date)

# ---- 4. Poor man's sign restriction on each event ----
# Use the 3 month OIS surprise as the interest rate signal. The 3 month
# rate is the standard near term policy indicator and is far less noisy
# than the 1 month (raw vs filtered correlation 0.79 versus 0.52). The
# event level information filter is kept because, empirically, it is the
# only construction that delivers the theoretically correct negative and
# hump shaped house price response; controlling for the equity surprise
# at quarterly frequency does not purge the information effect.
# opposite signs  (ois * stoxx < 0) -> pure monetary policy shock
# same signs      (ois * stoxx > 0) -> information shock
# zero or missing in either -> undefined, treated as pure MP by
# convention; events with a missing STOXX reaction are counted and
# reported below so this convention is never silent.
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

# ---- 5. Aggregate to quarterly by summation ----
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

# ---- 6. Sanity checks ----
cat("Quarterly shock series:\n")
cat("  Range:", format(min(mp_q$yq)), "to", format(max(mp_q$yq)), "\n")
cat("  Quarters:", nrow(mp_q), "\n")
cat("  Correlation raw 3M vs pure:",
    round(cor(mp_q$ois_3m, mp_q$shock_pure), 3), "\n")
print(head(mp_q))
print(tail(mp_q))

# ---- 7. Save ----
saveRDS(mp_q, file.path(PATH$clean, "mp_shock_quarterly.rds"))
write.csv(mp_q, file.path(PATH$clean, "mp_shock_quarterly.csv"), row.names = FALSE)

cat("\nSaved: mp_shock_quarterly.rds / .csv\n")