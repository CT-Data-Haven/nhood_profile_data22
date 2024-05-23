# writes to_viz/cities
source("_utils/pkgs.R")
library(sf, warn.conflicts = FALSE, quietly = TRUE)
sf::sf_use_s2(FALSE)

############ SHAPEFILES ################################################
# would love a json file of readable topojson, but last time that didn't seem possible
shps <- tibble::lst(cwi::bridgeport_sf, cwi::hartford_sf, cwi::new_haven_sf, cwi::stamford_sf) |>
  set_names(stringr::str_extract, "([a-z_]+)(?=_sf)") |>
  map(st_transform, 4326) |>
  map(st_cast, "MULTIPOLYGON") |>
  imap(function(shp, city) {
    mutate(shp, name = ifelse(name %in% dupe_nhoods,
      paste(name, snakecase::to_title_case(city)),
      as.character(name)
    ))
  })

shps |>
  imap(function(df, city) {
    id <- paste(city, "topo", sep = "_")
    fn <- xfun::with_ext(id, "json")
    geojsonio::topojson_write(df,
      geometry = "polygon",
      file = file.path("to_viz", "cities", fn),
      overwrite = TRUE,
      object_name = id
    )
  })