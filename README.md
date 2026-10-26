# Pacific Flyway Spring Migration

BDA 600 Capstone, San Diego State University, Fall 2026

This project estimates when, where, and how many birds migrate through the Pacific Flyway in spring, using three open data sources:

- **eBird Status & Trends** (Cornell Lab of Ornithology): weekly share of each species' population in a given area
- **BirdFlow** (UMass / Cornell): estimated (synthetic) migration routes for each species
- **NEXRAD weather radar** (NOAA, hosted on AWS): number of birds in the air each night

We first planned to study fall migration. Ranking the available BirdFlow models by how much of each species' population uses our study states showed spring was the stronger season for most western species, so we switched. The analysis can be re-run for fall by changing the season settings in `R/config.R`.

## Pipeline

Run the notebooks in order. Each one reads the outputs of the one before it.

1. `00_setup.qmd`: install packages and store your eBird key (run once, by hand)
2. `01_species_check.qmd`: rank species by Pacific Flyway use and confirm data quality
3. `02_ebird_abundance.qmd`: weekly population share in the study area
4. `03_birdflow_routes.qmd`: simulated migration routes
5. `04_radar_test_night.qmd`: one night of radar data for San Diego (doesn't need an eBird key)

All settings (season, species, study area, file paths) live in `R/config.R`. Make changes there rather than inside the notebooks.

## Getting started

1. Install R (4.3 or later), RStudio, and Quarto.
2. Clone the repo and open `bird-migration-capstone.Rproj` in RStudio.
3. Request your own eBird Status & Trends key at https://ebird.org/st/request (Educational use case). Keys are personal, so don't share or commit them.
4. Run `00_setup.qmd` one chunk at a time.
5. Run notebooks 01 through 04 in order.

## Folders

- `R/`: shared settings and helper functions
- `data/raw/`: large downloaded files such as radar scans (not committed to Git)
- `data/derived/`: small outputs we create, like CSV and GeoJSON files (committed)
- `figures/`: charts and maps for the report and website
- `package_versions.csv`: package versions used (created by `00_setup.qmd`); compare if teammates get different results

Raw eBird data isn't stored in this repo. The `ebirdst` package keeps it in its own folder on each computer.

## Data use rules

These come from the eBird Status & Trends Terms of Use (Educational use case):

- Show eBird-based maps and animations on the website, but don't offer the raw data files for download.
- Include the eBird citation (with DOI) and disclaimer in the report, website, slides, and video. Both are saved in `R/config.R`.
- Label BirdFlow routes as model estimates, not tracked birds.

## Code comments

These notebooks double as our methods documentation:

- Use the text above each code chunk to explain why we made a choice, and code comments to explain what the code does.
- Cite the source for each analysis choice (a paper, the Terms of Use, or a team decision with the date).
- If you change a setting, update `R/config.R` and its comment, then re-run the affected notebooks.

## Troubleshooting

- **Warnings mentioning `cdn.proj.org`:** your network blocked an optional download. These are safe to ignore.
- **`object '..md5..' not found` when R starts:** a leftover file from an earlier package-version tool. Run `unlink(c(".Rprofile", "renv", "renv.lock"), recursive = TRUE)` and restart R.
- **GitHub "HTTP error 401 / Bad credentials" when installing BirdFlowR:** use the fallback chunk in `00_setup.qmd`.
- **BirdFlow says a model isn't in the collection:** that species doesn't have a model yet. Pick a backup species (listed in `R/config.R`) and re-run notebook 01.
- **eBird download fails:** your key isn't loaded. Restart R and check `nchar(Sys.getenv("EBIRDST_KEY")) > 0`.

## Citations

- eBird Status & Trends: full citation in `R/config.R` (DOI: 10.2173/WZTW8903)
- Fuentes, M., Van Doren, B. M., Fink, D., & Sheldon, D. (2023). BirdFlow: Learning seasonal bird movements from eBird data. *Methods in Ecology and Evolution*, 14(3), 923–938. https://doi.org/10.1111/2041-210X.14052
- Dokter, A. M., et al. (2011). Bird migration flight altitudes studied by a network of operational weather radars. *Journal of the Royal Society Interface*, 8, 30–43. https://doi.org/10.1098/rsif.2010.0116
- Horton, K. G., et al. (2019). Migratory flight on the Pacific Flyway: strategies and tendencies of wind drift compensation. *Biology Letters*.
- La Sorte, F. A., et al. (2014). The role of atmospheric conditions in the seasonal dynamics of North American migration flyways. *Journal of Biogeography*.
- NOAA National Weather Service Radar Operations Center (1991). NEXRAD Level 2 Base Data. NOAA National Centers for Environmental Information. doi:10.7289/V5W9574V
