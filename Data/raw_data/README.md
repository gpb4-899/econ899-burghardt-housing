# Raw data

Provenance for all raw inputs is documented in the main README.

- `Dataset_EA-MPD.xlsx` is committed here. It is the ECB Euro Area Monetary
  Policy event study Database (Altavilla et al. 2019). It is small and has no
  public API, so it is kept in the repo to make the package self contained.
- All other raw data is downloaded at run time by the programs in
  `Programs/01_dataprep` and is not versioned.
