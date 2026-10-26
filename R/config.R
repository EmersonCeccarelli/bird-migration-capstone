# =============================================================================
# config.R  —  shared settings for every notebook in this project
# =============================================================================
#
# WHY THIS FILE EXISTS
# --------------------
# Every notebook starts with `source(here::here("R", "config.R"))`. Keeping the
# species list, study area, season and file paths in ONE place means:
#   * if we change a species or the study area, we change it here once and
#     re-run the notebooks, instead of hunting through five files;
#   * every teammate's run uses identical settings, so our results match;
#   * the report's Methods section can point to this file as the single
#     source of truth for our analysis choices.
#
# RULE OF THUMB: if a value is a *decision* (which species, which season,
# which radar), it belongs here. If it's a *calculation*, it belongs in a
# notebook.
# =============================================================================


# --- Packages used by config itself -------------------------------------------
# `here` builds file paths relative to the project root (the folder holding
# the .Rproj file). This makes paths work on every teammate's computer,
# whether the repo lives in ~/Projects, ~/Documents or anywhere else.
library(here)


# --- 1. Season ----------------------------------------------------------------
# DECISION (team, 10/25): spring (pre-breeding) migration is our core season.
#   * We first planned fall, but ranking all 60 BirdFlow 2026 models by
#     Pacific Flyway use (notebook 01, Step 1) showed spring share was higher
#     for 12 of the 16 species with >10% of their population in our states.
#   * Matches Horton et al. (2019, Biology Letters): more Pacific Flyway flight
#     activity in spring than fall; and La Sorte et al. (2014): western
#     migrants take different ("looped") routes in spring vs fall.
#
# The three names below must agree. To switch seasons, change all three:
#   spring: "spring" / "prebreeding_migration"  / "spring"
#   fall:   "fall"   / "postbreeding_migration" / "fall"
SEASON_BIRDFLOW <- "spring"                 # BirdFlowR's season name
SEASON_EBIRD    <- "prebreeding_migration"  # eBird's season name
SEASON_LABEL    <- "spring"                 # used in file names and titles


# --- 2. Species ---------------------------------------------------------------
# DECISION (team, 10/25): chosen from the BirdFlow 2026 models by measured
# Pacific Flyway use (data/derived/birdflow_models_ranked.csv). Our first
# literature-based list (Wilson's Warbler, Swainson's Thrush, etc.) had only
# one species with a model, so we let the available models drive the choice.
#
# Share = fraction of the species' population inside our study states during
# migration (spring / fall):
CANDIDATE_SPECIES <- c(
  "westan",  # Western Tanager        49% / 47%  western icon; night migrant
  "lazbun",  # Lazuli Bunting         69% / 67%  top share in both seasons
  "casvir",  # Cassin's Vireo         54% / 33%  Pacific Coast breeder
  "gocspa",  # Golden-crowned Sparrow 22% / 39%  migrating sparrow with fall strength
  "virwar",  # Virginia's Warbler     41% / 27%  interior Southwest
  "rufhum"   # Rufous Hummingbird     23% / 25%  DAY migrant: should NOT appear
             #                                   in night radar (a useful check);
             #                                   textbook looped migrant
)
# Backups if one fails notebook 01: "calhum" (Calliope Hummingbird, 78% spring),
# "gocspa" (Golden-crowned Sparrow, winters in coastal California).

# Upper limit on how many species we carry forward (scope guard: ~7 weeks).
MAX_SPECIES <- 6


# --- 3. Study area ------------------------------------------------------------
# DECISION: the US states that make up the core of the Pacific Flyway west of
# the Rockies. We use whole states (rather than a hand-drawn box) because
# state boundaries are easy to explain in the report and on the website.
#
# These are lower-case full names because that's how the `maps` package
# labels its state polygons (see notebook 02).
STUDY_STATES <- c(
  "california", "oregon", "washington",
  "nevada", "arizona", "idaho", "utah"
)

# A smaller focus area for local storytelling (San Diego / Los Angeles).
# Used for the radar comparison and for "what flies over us" figures.
FOCUS_STATE <- "california"


# --- 4. Spatial resolution ----------------------------------------------------
# eBird Status rasters come at 3 km, 9 km or 27 km.
# DECISION: 27 km.
#   * 27 km files are ~80x smaller than 3 km, so downloads are quick and the
#     whole team can work on laptops.
#   * Our questions are flyway-scale (hundreds of km), so 3 km adds detail
#     we wouldn't use.
#   * BirdFlow models are coarser still (~100–150 km cells), so finer eBird
#     data wouldn't improve the route estimates.
EBIRD_RESOLUTION <- "27km"


# --- 5. BirdFlow route settings -----------------------------------------------
# Number of synthetic routes ("simulated birds") to generate per species.
# More routes = smoother animation but bigger files. 200 is plenty for a map;
# raise it for quantitative summaries.
N_ROUTES <- 200

# Random seed so every teammate gets the SAME synthetic routes. BirdFlow
# routes are random draws from a probability model — without a fixed seed,
# each run would produce different lines and our figures wouldn't match.
RANDOM_SEED <- 600   # (BDA 600)


# --- 6. Radar settings --------------------------------------------------------
# NEXRAD station codes for Southern California. VERIFY on the NOAA station
# map before relying on these: https://www.roc.noaa.gov/
#   KNKX = San Diego
#   KSOX = Santa Ana Mountains (Orange County / Inland Empire)
#   KVTX = Los Angeles (Ventura County)
RADAR_STATIONS <- c("KNKX", "KSOX", "KVTX")

# Radar cross-section per bird, in cm^2. 11 cm^2 is the standard value for
# nocturnal songbird migrants used by BirdCast and Van Doren & Horton (2018).
# It converts radar reflectivity into an estimated NUMBER of birds; change it
# only with a citation.
RADAR_RCS <- 11


# --- 7. File paths ------------------------------------------------------------
# DATA RULES (from the eBird Status & Trends Terms of Use, Educational use case):
#   * RAW eBird rasters are NEVER committed to Git or posted on the website.
#     ebirdst stores them in its own folder outside this repo
#     (see `ebirdst::ebirdst_data_dir()`), which keeps them out by design.
#   * DERIVED products (weekly summaries, synthetic routes) go in
#     data/derived/ and MAY be shared as part of course materials.
#   * Raw radar files are large; they go in data/raw/ (git-ignored).
PATHS <- list(
  raw      = here("data", "raw"),
  derived  = here("data", "derived"),
  routes   = here("data", "derived", "routes"),
  radar    = here("data", "raw", "radar"),
  figures  = here("figures")
)

# Create the folders if they don't exist yet (safe to run repeatedly).
invisible(lapply(PATHS, dir.create, recursive = TRUE, showWarnings = FALSE))


# --- 8. Required attribution --------------------------------------------------
# Every deliverable (report, website, slides, video) must carry BOTH of these.
# Check `ebirdst::ebirdst_version()` — if the data version is not 2023, copy
# the matching citation from https://ebird.org/science/status-and-trends/recommended-citation
EBIRD_CITATION <- paste(
  "Fink, D., T. Auer, A. Johnston, M. Strimas-Mackey, S. Ligocki, O. Robinson,",
  "W. Hochachka, L. Jaromczyk, C. Crowley, K. Dunham, A. Stillman, C. Davis,",
  "M. Stokowski, P. Sharma, V. Pantoja, D. Burgin, P. Crowe, M. Bell, S. Ray,",
  "I. Davies, V. Ruiz-Gutierrez, C. Wood, A. Rodewald. 2024. eBird Status and",
  "Trends, Data Version: 2023; Released: 2025. Cornell Lab of Ornithology,",
  "Ithaca, New York. https://doi.org/10.2173/WZTW8903"
)

EBIRD_DISCLAIMER <- paste(
  "This material uses data from the eBird Status and Trends Project at the",
  "Cornell Lab of Ornithology, eBird.org. Any opinions, findings, and",
  "conclusions or recommendations expressed in this material are those of the",
  "author(s) and do not necessarily reflect the views of the Cornell Lab of",
  "Ornithology."
)

# Short caption for figures (the full citation goes in the report/website).
FIGURE_CAPTION <- "Data: eBird Status & Trends (2023), Cornell Lab of Ornithology; BirdFlow (Fuentes et al. 2023)."
