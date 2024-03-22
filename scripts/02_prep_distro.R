library(dplyr, quietly = TRUE)

acs_year <- snakemake@params[["acs_year"]]

hdrs <- jsonlite::read_json(file.path("to_viz", "indicators.json"), simplifyVector = TRUE) |>
  purrr::map_dfr(purrr::pluck, "indicators") |>
  select(indicator, display)

############ FLAT FILES BY CITY ########################################
prof_list <- readRDS(file.path("output_data", stringr::str_glue("all_nhood_{acs_year}_acs_health_comb.rds"))) |>
  purrr::map(left_join, hdrs, by = "indicator") |>
  purrr::map(distinct, name, display, year, .keep_all = TRUE) |>
  purrr::map(tidyr::pivot_wider, id_cols = any_of(c("level", "town", "name")), names_from = c(display, year)) |>
  purrr::map(mutate, level = forcats::fct_relabel(level, stringr::str_remove, "^\\d_"))

purrr::imap(prof_list, function(df, city) {
  city_nm <- janitor::make_clean_names(city)
  fn <- stringr::str_glue("{city_nm}_nhood_{acs_year}_acs_health_comb.csv")
  readr::write_csv(df, file.path("to_distro", fn), na = "")
})
