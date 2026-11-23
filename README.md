# Pacific Flyway Spring Migration

BDA 600 Capstone, San Diego State University, Fall 2026

This project estimates when, where, and how many birds migrate through the Pacific Flyway in spring, what drives migration night to night, and what that means for a "Lights Out" campaign in San Diego. It combines six open data sources:

- **eBird Status & Trends** (Cornell Lab of Ornithology): weekly share of each species' population in a given area
- **BirdFlow** (UMass Amherst / Cornell): estimated (synthetic) migration routes for each species
- **NEXRAD weather radar** (NOAA, hosted on AWS): number of birds in the air each night, and how high they fly
- **ERA5 weather reanalysis** (Copernicus / ECMWF, via the Open-Meteo API): hourly wind, temperature, rain and cloud at each radar
- **NASA Black Marble** (VNP46A4): annual night-time light, to measure artificial light along the routes
- **Lights Out San Diego** (San Diego Bird Alliance): the program's spring dates and recommended hours

We first planned to study fall migration. Ranking the available BirdFlow models by how much of each species' population uses our study states showed spring was the stronger season for most western species, so we switched. The analysis can be re-run for fall by changing the season settings in `R/config.R`.

## Pipeline

Run the notebooks in order. Each one reads the outputs of the ones before it.

1. `00_setup.qmd`: install packages and store your eBird key (run once, by hand)
2. `01_species_check.qmd`: rank species by Pacific Flyway use and confirm data quality
3. `02_ebird_abundance.qmd`: weekly population share in the study area
4. `03_birdflow_routes.qmd`: simulated migration routes
5. `04_radar_test_night.qmd`: one night of radar data for San Diego (doesn't need an eBird key)
6. `05_radar_season.qmd`: the full spring season (Mar 1 – Jun 15) at three radars. Downloads, processes and deletes each night's raw files; takes many hours
7. `06_migration_models.qmd`: timing (radar vs eBird), weather models, flight altitude and time of night, and the Lights Out analysis
8. `07_migration_map.qmd`: builds the interactive map, `figures/migration_map.html`

After the notebooks, `source("R/data_inventory.R")` records how much data each stage used, in `data/derived/data_inventory.csv` (for the report's data management section).

All settings (season, species, study area, radars, file paths) live in `R/config.R`. Make changes there rather than inside the notebooks.

## Getting started

1. Install R (4.3 or later), RStudio, and Quarto.
2. Clone the repo and open `bird-migration-capstone.Rproj` in RStudio.
3. Request your own eBird Status & Trends key at https://ebird.org/st/request (Educational use case). Keys are personal, so don't share or commit them.
4. Run `00_setup.qmd` one chunk at a time.
5. Run notebooks 01 through 07 in order.
6. Optional, for the night-lights step in notebook 06: get a free NASA Earthdata token (see below). Without it, that step is skipped and everything else runs.

### NASA Earthdata token (night lights)

1. Register at https://urs.earthdata.nasa.gov and fill in your profile (affiliation, study area, user type).
2. Under **Applications → Authorized Apps**, approve **LAADS Web**.
3. Click **Generate Token**, then add it to your R environment file (`usethis::edit_r_environ()`) as `NASA_BEARER=<token>`, with no quotes. Restart R.
4. `install.packages("blackmarbler")`.

The token is personal, like the eBird key: never commit or share it. `.Renviron` lives in your home folder, outside this repo.

## Folders

- `R/`: shared settings (`config.R`), the study-area helper and `data_inventory.R`
- `templates/`: the map page's design (`migration_map_template.html`), filled in by notebook 07
- `data/raw/`: large downloaded files such as radar scans and the night-lights map (not committed to Git)
- `data/derived/`: small outputs we create, like CSV, GeoJSON and radar profile files (committed)
- `figures/`: charts for the report and website, and the interactive map (`migration_map.html`)
- `package_versions.csv`: package versions used (created by `00_setup.qmd`); compare if teammates get different results

Raw eBird data and BirdFlow models aren't stored in this repo. The `ebirdst` and `BirdFlowR` packages keep them in their own folders on each computer.

## Data use rules

From the eBird Status & Trends Terms of Use (Educational use case):

- Show eBird-based maps and animations on the website, but don't offer the raw data files for download.
- Include the eBird citation (with DOI) and disclaimer in the report, website, slides, and video. Both are saved in `R/config.R`.
- Label BirdFlow routes as model estimates, not tracked birds.

Other sources:

- **Open-Meteo / ERA5** (CC BY 4.0): credit "Weather data by Open-Meteo.com" with a link where the data are shown, and include "Generated using Copernicus Climate Change Service information".
- **NASA Black Marble**: NASA data are free to use; cite Román et al. (2018). Keep your Earthdata token out of the repo.
- **NEXRAD**: public NOAA data; cite the NOAA dataset DOI below.

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
- **Night-lights download fails with "cannot open this file as a SpatRaster":** NASA sent a login page instead of data. Approve LAADS Web under Authorized Apps, generate a new token, update `.Renviron`, and restart R.
- **`no applicable method for 'map'` in notebook 06:** another package's `map()` was loaded after purrr's. Restart R (Session → Restart R) and run the notebook from the top.

## Citations

**Data**

- Fink, D., et al. (2024). eBird Status and Trends, Data Version: 2023; Released: 2025. Cornell Lab of Ornithology, Ithaca, New York. https://doi.org/10.2173/WZTW8903 (full author list in `R/config.R`)
- NOAA National Weather Service Radar Operations Center (1991). NEXRAD Level II Base Data. NOAA National Centers for Environmental Information. https://doi.org/10.7289/V5W9574V
- Hersbach, H., et al. (2020). The ERA5 global reanalysis. *Quarterly Journal of the Royal Meteorological Society*, 146, 1999–2049. https://doi.org/10.1002/qj.3803
- Zippenfenig, P. (2023). Open-Meteo.com Weather API [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.7970649
- Román, M. O., et al. (2018). NASA's Black Marble nighttime lights product suite. *Remote Sensing of Environment*, 210, 113–143. https://doi.org/10.1016/j.rse.2018.03.017
- San Diego Bird Alliance. Lights Out San Diego. https://www.sandiegobirdalliance.org/what-we-do/lights-out-san-diego-english.html

**Methods and software**

- Fuentes, M., Van Doren, B. M., Fink, D., & Sheldon, D. (2023). BirdFlow: Learning seasonal bird movements from eBird data. *Methods in Ecology and Evolution*, 14(3), 923–938. https://doi.org/10.1111/2041-210X.14052
- Dokter, A. M., Liechti, F., Stark, H., Delobbe, L., Tabary, P., & Holleman, I. (2011). Bird migration flight altitudes studied by a network of operational weather radars. *Journal of the Royal Society Interface*, 8, 30–43. https://doi.org/10.1098/rsif.2010.0116
- Dokter, A. M., et al. (2019). bioRad: biological analysis and visualization of weather radar data. *Ecography*, 42, 852–860. https://doi.org/10.1111/ecog.04028
- Wright, M. N., & Ziegler, A. (2017). ranger: A fast implementation of random forests for high dimensional data in C++ and R. *Journal of Statistical Software*, 77(1).

**Background**

- Van Doren, B. M., & Horton, K. G. (2018). A continental system for forecasting bird migration. *Science*, 361, 1115–1118. https://doi.org/10.1126/science.aat7526
- Newcombe, P. B., Nilsson, C., Lin, T.-Y., Winner, K., Bernstein, G., Maji, S., Sheldon, D., Farnsworth, A., & Horton, K. G. (2019). Migratory flight on the Pacific Flyway: strategies and tendencies of wind drift compensation. *Biology Letters*, 15(9), 20190383. https://doi.org/10.1098/rsbl.2019.0383
- La Sorte, F. A., et al. (2014). The role of atmospheric conditions in the seasonal dynamics of North American migration flyways. *Journal of Biogeography*, 41, 1685–1696. https://doi.org/10.1111/jbi.12328
- Horton, K. G., Nilsson, C., Van Doren, B. M., La Sorte, F. A., Dokter, A. M., & Farnsworth, A. (2019). Bright lights in the big cities: migratory birds' exposure to artificial light. *Frontiers in Ecology and the Environment*, 17(4), 209–214. https://doi.org/10.1002/fee.2029
- Van Doren, B. M., et al. (2021). Drivers of fatal bird collisions in an urban center. *PNAS*, 118(24), e2101666118. https://doi.org/10.1073/pnas.2101666118
