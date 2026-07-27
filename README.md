# Replication package

Mortgage market structure and the transmission of ECB monetary policy to
euro area house prices. ECON 899, Simon Fraser University.

## Overview

The code in this repository downloads and cleans the data, then estimates
panel local projections of real house prices on information cleaned ECB
monetary policy shocks, interacted with national mortgage market structure.
Running `01_main.R` reproduces every table and figure in the paper from the
raw data.

## Data availability

| Data | Source | In repo? | Obtained by |
| --- | --- | --- | --- |
| EA-MPD monetary policy surprises | Altavilla et al. (2019), ECB Euro Area Monetary Policy event study Database | Yes, `Data/raw_data/Dataset_EA-MPD.xlsx` | committed (small, no public API) |
| Real house price indices | OECD Analytical House Prices, via DBnomics `OECD/DSD_AN_HOUSE_PRICES` | No | `Programs/01_dataprep/02_house_prices.R` (rdbnomics) |
| Real GDP, HICP, unemployment | Eurostat `namq_10_gdp`, `prc_hicp_midx`, `une_rt_m` | No | `Programs/01_dataprep/03_controls.R` (eurostat) |
| Mortgage market structure | Badarinza et al. (2018) and related euro area evidence | n/a | classification defined once in `config.R` (`MORTGAGE_STRUCTURE`) |

Cleaned data (`Data/data_for_analysis`) and results (`Results`) are not
versioned; they are produced by the code.

## Computational requirements

- R 4.3 or later
- Packages listed in `00_setup.R` (fixest, eurostat, rdbnomics, dplyr,
  tidyr, lubridate, readxl, janitor, ggplot2)
- Internet access, since house prices and controls are downloaded at run time
- Runtime: a few minutes, dominated by the Eurostat downloads

## Description of the code

- `config.R` sets file paths, the country sample and the sample start. It is
  the only file the user edits, and every program sources it.
- `00_setup.R` installs the required packages. Run once.
- `01_main.R` runs the whole pipeline in order (data preparation, then
  analysis). It does not run the setup program.
- `Programs/01_dataprep/` reads raw data and writes cleaned data.
  - `01_shock_series.R` builds the quarterly monetary policy shock from the
    EA-MPD using the Jarocinski Karadi poor man's sign restriction on the
    3 month OIS surprise.
  - `02_house_prices.R` downloads real house price indices.
  - `03_controls.R` downloads GDP growth, inflation and unemployment.
- `Programs/02_analysis/` reads cleaned data and writes to `Results`.
  - `02_merge_and_regress.R` builds the panel and estimates the main local
    projections. The baseline includes the standard dynamic controls; the
    same specification without them is reported alongside it. Writes the
    main results table and both figures.
  - `03_coverage_audit.R` documents the sample coverage.
  - `04_diagnostics.R` shock validation, LP dynamics, and the pre/post 2009
    subsample split.

## Instructions to replicators

1. Open the RStudio project `econ899-housing-mp.Rproj` so the working
   directory is the repository root.
2. Run `source("00_setup.R")` once to install packages.
3. Run `source("01_main.R")` to reproduce all outputs.

Outputs appear in `Results/tables` and `Results/figures`.

## List of exhibits

| Output | Produced by |
| --- | --- |
| `Results/tables/Table01_summary_stats.tex` | `02_analysis/01_summary_stats.R` |
| `Results/tables/Table02_lp_main.tex` | `02_analysis/02_merge_and_regress.R` |
| `Results/tables/TableA1_lp_robust_unemp.tex` | `02_analysis/02_merge_and_regress.R` |
| `Results/figures/Fig02_irf_interaction.pdf` | `02_analysis/02_merge_and_regress.R` |
| `Results/figures/Fig01_irf_baseline.pdf` | `02_analysis/02_merge_and_regress.R` |
| `Results/tables/coverage_audit.csv` | `02_analysis/03_coverage_audit.R` |
| `Results/figures/FigA1_shock_series.pdf`, `irf_dynamics.pdf` | `02_analysis/04_diagnostics.R` |
| `Results/tables/subsample_interaction.csv` | `02_analysis/04_diagnostics.R` |

## References

Altavilla, C., Brugnolini, L., Gurkaynak, R., Motto, R., Ragusa, G. (2019).
Measuring euro area monetary policy. Journal of Monetary Economics 108, 162-179.
