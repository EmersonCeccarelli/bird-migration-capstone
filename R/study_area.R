# =============================================================================
# study_area.R  —  one function that builds our study-area polygons
# =============================================================================
# Notebooks 02 and 03 both need the same study area. Defining it once here
# guarantees they use IDENTICAL boundaries; if we change it, both update.
#
# Usage (after sourcing R/config.R):
#   source(here::here("R", "study_area.R"))
#   states     <- study_states()            # one polygon per state
#   study_area <- study_states(merge = TRUE) # one merged polygon
# =============================================================================

library(sf)
library(dplyr)

#' Build the study-area state polygons.
#'
#' @param states Character vector of lower-case state names (as labelled by
#'   the `maps` package). Defaults to STUDY_STATES from R/config.R.
#' @param merge If TRUE, dissolve all states into a single polygon.
#' @return An sf object in CONUS Albers Equal Area (EPSG:5070).
study_states <- function(states = STUDY_STATES, merge = FALSE) {

  outlines <- maps::map("state", regions = states, plot = FALSE, fill = TRUE) |>
    st_as_sf()

  # (1) LABEL the outlines as WGS84 (EPSG:4326).
  #     `maps` tags its data with an old datum (Clarke 1866 / NAD27-style).
  #     Converting from that datum makes PROJ try to download correction
  #     grids from the internet; offline or behind a firewall that fails
  #     SILENTLY and shifts points. The datum difference is ~100 m — far
  #     below our 27 km grid — so we simply declare WGS84 instead.
  #     suppressWarnings() hides sf's (expected) "does not reproject" note.
  outlines <- suppressWarnings(st_set_crs(outlines, 4326))

  out <- outlines |>
    # (2) PROJECT to CONUS Albers Equal Area (EPSG:5070) before repairing.
    #     The raw outlines contain tiny self-crossing edges. In lon/lat, sf's
    #     spherical engine (s2) rejects them; in a flat equal-area CRS,
    #     st_make_valid() repairs them cleanly. Equal-area also means
    #     st_area() returns true areas, handy for the report.
    st_transform(5070) |>
    st_make_valid() |>
    # (3) Some states come in several pieces ("washington:main",
    #     "washington:san juan island"). Strip ":piece" and merge, so we
    #     have exactly one row per state.
    mutate(state = sub(":.*", "", ID)) |>
    group_by(state) |>
    summarise(.groups = "drop")

  if (merge) {
    out <- out |> summarise(name = "Pacific Flyway (study states)")
  }
  out
}
