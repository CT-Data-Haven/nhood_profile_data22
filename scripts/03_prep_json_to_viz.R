# writes to_viz/nhood_wide
source("_utils/pkgs.R")

acs_year <- snakemake@params[["acs_year"]]

############ DATA ######################################################
# prof_wide has format
# {
#   "bridgeport": {
#     "age": [
#       {
#         "level": "1_state",
#         "location": "Connecticut"
# ...
prof_wide <- readRDS(file.path("output_data", stringr::str_glue("all_nhood_{acs_year}_acs_health_comb.rds"))) %>%
  map(mutate, across(c(topic, indicator), forcats::as_factor)) %>%
  map(select, -year) %>%
  map(rename, location = name) %>%
  map(~ split(., .$topic)) %>%
  map_depth(2, tidyr::pivot_wider, names_from = indicator) %>%
  map_depth(2, select, -topic)

jsonlite::write_json(prof_wide, file.path("to_viz", stringr::str_glue("nhood_wide_{acs_year}.json")), auto_unbox = TRUE)