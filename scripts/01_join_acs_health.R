# writes output_data/all_nhood_yr_acs_health_comb.rds
source("_utils/pkgs.R")
if (exists("snakemake")) {
  acs_year <- snakemake@params[["acs_year"]]
  cdc_year <- snakemake@params[["cdc_year"]]
} else {
  acs_year <- 2022
  cdc_year <- 2023
}

geos <- readRDS(file.path("_utils", "city_geos.rds"))

# datasets need indicators as tXother_race, mXasthma to match meta
acs <- readRDS(file.path("input_data", stringr::str_glue("acs_nhoods_by_city_{acs_year}.rds"))) |>
  map(select, -city) |>
  bind_rows(.id = "city") |>
  mutate(name = ifelse(name %in% dupe_nhoods, paste(name, city), name)) |>
  select(topic, city, name, year, indicator = group, estimate, share) |>
  tidyr::pivot_longer(estimate:share, names_to = "type", values_drop_na = TRUE) |>
  mutate(
    type = fct_recode(type, t = "estimate", m = "share"),
    year = as.character(year)
  )

# add comparison locations to nhoods for cdc data
# need to be more clever since every city has a neighborhood called downtown
cdc <- readRDS(file.path("input_data", stringr::str_glue("cdc_health_all_lvls_nhood_{cdc_year}.rds"))) |>
  mutate(name = ifelse(name %in% dupe_nhoods, paste(name, city), name)) |>
  select(topic, name, year, indicator = question, value) |>
  mutate(
    type = factor("m"),
    indicator = indicator |>
      fct_relabel(snakecase::to_snake_case) |>
      fct_recode(checkup = "annual_checkup", 
                 heart_disease = "coronary_heart_disease", 
                 asthma = "current_asthma", 
                 blood_pressure = "high_blood_pressure", 
                 dental = "dental_visit", 
                 smoking = "current_smoking", 
                 sleep = "sleep_7_hours", 
                 life_exp = "life_expectancy", 
                 insurance = "health_insurance")
  ) |>
  mutate(topic = fct_recode(topic, health_outcomes = "life_expectancy")) |>
  inner_join(geos |> select(city, name), by = "name", relationship = "many-to-many")



out_by_city <- bind_rows(acs, cdc) |>
  inner_join(geos, by = c("city", "name")) |>
  mutate(name = stringr::str_replace(name, "\\bOf\\b", "of")) |>
  mutate(topic = case_when(
    topic == "pov_age" & grepl("00_17", indicator) ~ "income_children",
    topic == "pov_age" & grepl("65", indicator) ~ "income_seniors",
    TRUE ~ topic
  ) |>
    as_factor() |>
    fct_recode(health_risk_behaviors = "RISKBEH", 
               health_outcomes = "HLTHOUT", 
               prevention = "PREVENT", 
               immigration = "foreign_born", 
               income = "poverty",
               disability = "DISABLT") |>
    fct_collapse(housing = c("housing_cost", "tenure"))) |>
  tidyr::unite(col = indicator, type, indicator, sep = "X") |>
  # left_join(meta, by = "indicator") |>
  arrange(topic, city, level, name) |>
  split(~city) |>
  map(janitor::remove_empty, "cols") |>
  map(select, topic, level, everything(), -city) |>
  map(distinct, topic, level, name, indicator, .keep_all = TRUE)

saveRDS(out_by_city, file.path("output_data", stringr::str_glue("all_nhood_{acs_year}_acs_health_comb.rds")))
