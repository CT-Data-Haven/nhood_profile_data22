source("_utils/pkgs.R")

############ CITY GEOS #################################################
# use distinct names to collect all possible locations by city
data_path <- list.files("input_data", pattern = "acs.+\\.rds", full.names = TRUE)[1]
geos <- readRDS(data_path) %>%
  map(distinct, town, name, level) %>%
  bind_rows(.id = "city") %>%
  mutate(
    level = fct_relabel(level, stringr::str_remove, "^\\d_") %>%
      fct_recode(region = "county") %>%
      fct_drop(),
    name = ifelse(name %in% dupe_nhoods, paste(name, city), name)
  ) %>%
  arrange(level) %>%
  mutate(level = paste(as.numeric(level), as.character(level), sep = "_") %>%
    as_factor())

geo_meta <- geos %>%
  filter(
    grepl("region", level),
    !grepl("County", name)
  ) %>%
  select(city, name) %>%
  tibble::deframe() %>%
  imap(function(reg, city) {
    towns <- sort(cwi::regions[[reg]])
    list(region = reg, def = knitr::combine_words(towns))
  })

saveRDS(geos, file.path("_utils", "city_geos.rds"))


############ NOTES #####################################################
# geography meta, sources, download URLs
sources <- readr::read_delim(file.path("_utils", "manual", "sources.txt"), delim = ";", show_col_types = FALSE)
urls <- readr::read_csv(file.path("_utils", "manual", "urls.txt"), show_col_types = FALSE) %>%
  tibble::deframe() %>%
  as.list()

notes <- list(geography = geo_meta, sources = sources, dwurls = urls)
jsonlite::write_json(notes, file.path("to_viz", "notes.json"), auto_unbox = TRUE)
