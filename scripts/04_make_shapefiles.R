# writes to_viz/cities
source("_utils/pkgs.R")
library(sf, warn.conflicts = FALSE, quietly = TRUE)
sf::sf_use_s2(FALSE)

############ SHAPEFILES ################################################
# would love a json file of readable topojson, but last time that didn't seem possible
shps <- tibble::lst(cwi::bridgeport_sf, cwi::hartford_sf, cwi::new_haven_sf, cwi::stamford_sf) %>%
  set_names(stringr::str_extract, "([a-z_]+)(?=_sf)") %>%
  map(st_transform, 4326) %>%
  map(st_cast, "MULTIPOLYGON") %>%
  imap(function(shp, city) mutate(shp, name = ifelse(name %in% dupe_nhoods, paste(name, stringr::str_to_title(city)), as.character(name)))) %>%
  map(function(shp) mutate(shp, name = stringr::str_replace(name, "\\bOf\\b", "of") %>% stringr::str_replace("New_haven", "New Haven")))

# topojson_write is deprecated
# iwalk(function(shp, city) {
# geojsonio::topojson_write(shp, object_name = "city", file = file.path("to_viz", "cities", paste(city, "topo.json", sep = "_")))
# })

shps %>%
  imap(function(shp, city) geojsonio::geojson_write(shp, object_name = "city", file = file.path("to_viz", "cities", paste(city, "topo.json", sep = "_")))) %>%
  map(pluck, "path") %>%
  walk(function(pth) {
    system(stringr::str_glue("mapshaper {pth} -o force format=topojson {pth}"))
  })