# =============================================================================
# data_inventory.R  —  how much data the project used, at each stage
# =============================================================================
#
# For the report's "Database management" section and the pipeline diagram.
# Reads only: the radar log notebook 05 wrote for every night, the data
# caches, and the project folders. Changes nothing except writing one table:
#
#   data/derived/data_inventory.csv   (small, tracked in git)
#
# Run after notebooks 00–07:   source(here::here("R", "data_inventory.R"))
# =============================================================================

source(here::here("R", "config.R"))
suppressPackageStartupMessages({ library(dplyr); library(readr) })

inv <- list()   # rows of: stage, dataset, measure, value, unit
add <- function(stage, dataset, measure, value, unit = "") {
  inv[[length(inv) + 1]] <<- tibble(stage, dataset, measure,
                                    value = as.character(value), unit)
}
# Files and megabytes in a folder (recursive).
dir_size <- function(d, pattern = NULL) {
  f <- list.files(d, pattern = pattern, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  list(files = length(f), mb = round(sum(file.size(f), na.rm = TRUE) / 1e6, 1))
}
# Run a block; if a package or folder is missing, note it and carry on.
try_block <- function(name, expr) {
  tryCatch(expr, error = function(e) message("Skipped ", name, ": ", conditionMessage(e)))
}

# --- 1. NEXRAD radar: notebook 05's per-night log ------------------------------
# Each night's CSV records how many volume files were downloaded, their size,
# how many scans vol2bird processed and how long it took. The raw files were
# deleted after processing, so this log is the record of the raw volume.
try_block("radar", {
  nights <- list.files(file.path(PATHS$derived, "radar", SEASON_LABEL, "nights"),
                       pattern = "\\.csv$", full.names = TRUE) |>
    lapply(read_csv, show_col_types = FALSE,
           col_types = cols(night = col_date(), peak_time_local = col_character())) |>
    bind_rows()

  add("raw", "NEXRAD Level II", "stations", n_distinct(nights$station))
  add("raw", "NEXRAD Level II", "date range",
      paste(min(nights$night), "to", max(nights$night)))
  add("raw", "NEXRAD Level II", "station-nights", nrow(nights))
  add("raw", "NEXRAD Level II", "station-nights processed OK", sum(nights$status == "ok"))
  add("raw", "NEXRAD Level II", "volume files downloaded", sum(nights$n_files, na.rm = TRUE))
  add("raw", "NEXRAD Level II", "raw data downloaded and processed",
      round(sum(nights$raw_mb, na.rm = TRUE) / 1000, 1), "GB")
  add("processing", "vol2bird / bioRad", "radar scans processed",
      sum(nights$n_scans, na.rm = TRUE))
  if ("minutes" %in% names(nights))
    add("processing", "vol2bird / bioRad", "processing time",
        round(sum(nights$minutes, na.rm = TRUE) / 60, 1), "hours")

  for (s in sort(unique(nights$station))) {
    d <- filter(nights, station == s)
    add("raw", paste("NEXRAD", s), "raw data", round(sum(d$raw_mb, na.rm = TRUE) / 1000, 1), "GB")
  }

  p <- dir_size(file.path(PATHS$derived, "radar", SEASON_LABEL, "profiles"), "\\.rds$")
  add("derived", "Vertical profiles (vpts)", "files", p$files)
  add("derived", "Vertical profiles (vpts)", "size", p$mb, "MB")
  add("derived", "Nightly radar totals", "rows", nrow(nights))
})

# --- 2. eBird Status & Trends (raw rasters, kept outside the repo) -----------
try_block("ebird", {
  e <- dir_size(ebirdst::ebirdst_data_dir())
  add("raw", "eBird Status & Trends", "files (ebirdst cache, outside repo)", e$files)
  add("raw", "eBird Status & Trends", "size", e$mb, "MB")
  add("raw", "eBird Status & Trends", "resolution", EBIRD_RESOLUTION)
})

# --- 3. BirdFlow models and simulated routes -----------------------------------
try_block("birdflow", {
  b <- dir_size(BirdFlowR::birdflow_options("cache"), "\\.hdf5$")
  add("raw", "BirdFlow models", "model files (cache, outside repo)", b$files)
  add("raw", "BirdFlow models", "size", b$mb, "MB")
})
try_block("routes", {
  r <- dir_size(PATHS$routes, "\\.geojson$")
  pts <- list.files(PATHS$routes, "_routes\\.geojson$", full.names = TRUE)
  add("derived", "Simulated routes", "species", length(pts))
  add("derived", "Simulated routes", "simulated birds per species", N_ROUTES)
  add("derived", "Simulated routes", "weekly positions",
      sum(vapply(pts, \(f) nrow(sf::st_read(f, quiet = TRUE)), numeric(1))))
  add("derived", "Simulated routes", "size", r$mb, "MB")
})

# --- 4. Weather -----------------------------------------------------------------
try_block("weather", {
  for (f in list.files(file.path(PATHS$derived, "weather"), "\\.csv$", full.names = TRUE)) {
    add("raw", "Open-Meteo ERA5 weather", paste(basename(f), "rows"),
        nrow(read_csv(f, show_col_types = FALSE)))
  }
})

# --- 5. NASA Black Marble night lights -----------------------------------------
try_block("black marble", {
  f <- list.files(PATHS$raw, "black_marble.*\\.tif$", full.names = TRUE)[1]
  r <- terra::rast(f)
  add("raw", "NASA Black Marble VNP46A4", "file", basename(f))
  add("raw", "NASA Black Marble VNP46A4", "size", round(file.size(f) / 1e6, 1), "MB")
  add("raw", "NASA Black Marble VNP46A4", "grid cells",
      paste(dim(r)[1], "x", dim(r)[2]))
})

# --- 6. Project folders and software --------------------------------------------
for (d in c("raw", "derived", "figures")) {
  s <- dir_size(PATHS[[d]])
  add("project", paste0(d, "/ folder"), "files", s$files)
  add("project", paste0(d, "/ folder"), "size", s$mb, "MB")
}
try_block("git", add("project", "GitHub repository", "files tracked",
                     length(suppressWarnings(system("git ls-files", intern = TRUE)))))
add("software", "R", "version", paste(R.version$major, R.version$minor, sep = "."))
try_block("quarto", add("software", "Quarto", "version", system("quarto --version", intern = TRUE)))
add("software", "inventory", "date run", format(Sys.Date()))

# --- Save and show -----------------------------------------------------------
inventory <- bind_rows(inv)
write_csv(inventory, file.path(PATHS$derived, "data_inventory.csv"))
print(inventory, n = Inf, width = Inf)
message("Saved data/derived/data_inventory.csv")
