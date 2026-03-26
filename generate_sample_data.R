# =============================================================================
# Generate sample household survey data for the consistency check template
# A fictitious livelihood and welfare survey with six modules:
#   1. Household roster
#   2. Dwelling conditions
#   3. Income and livelihoods
#   4. Food consumption
#   5. Health access
#   6. Education
# Run this script once to create the sample Excel file
# =============================================================================

library(openxlsx)
set.seed(42)

n_households <- 500

# --- MODULE 1: HOUSEHOLD ROSTER ---
# One row per person. We generate households first, then populate members.

hh_ids <- seq(5001, 5000 + n_households)
# Inject 2 duplicate household IDs
hh_ids_with_dups <- c(hh_ids, 5003, 5003)

roster <- data.frame()

for (hid in unique(hh_ids)) {
  n_members <- sample(1:7, 1, prob = c(0.08, 0.22, 0.30, 0.22, 0.10, 0.05, 0.03))
  
  for (m in 1:n_members) {
    age <- if (m == 1) sample(18:78, 1) else sample(0:85, 1)
    sex <- sample(c("M", "F"), 1)
    rel <- if (m == 1) "head" else sample(c("spouse", "child", "parent", "sibling", "other"), 1,
                                           prob = c(0.30, 0.40, 0.10, 0.10, 0.10))
    
    # Marital status (ages 12+)
    marital <- if (age >= 12) sample(c("single", "married", "cohabiting", "divorced", "widowed"), 1,
                                      prob = c(0.35, 0.30, 0.15, 0.10, 0.10)) else NA
    
    # Functional screening — 4 domains
    # 1 = no difficulty, 2 = some, 3 = a lot, 4 = cannot do at all
    func_mobility    <- sample(1:4, 1, prob = c(0.70, 0.15, 0.10, 0.05))
    func_cognition   <- sample(1:4, 1, prob = c(0.72, 0.14, 0.09, 0.05))
    func_vision      <- sample(1:4, 1, prob = c(0.68, 0.18, 0.09, 0.05))
    func_daily_tasks <- sample(1:4, 1, prob = c(0.74, 0.13, 0.08, 0.05))
    
    roster <- rbind(roster, data.frame(
      hh_id = hid,
      member_id = paste0("P", hid, sprintf("%02d", m)),
      relationship = rel,
      sex = sex,
      age = age,
      marital_status = marital,
      func_mobility = func_mobility,
      func_cognition = func_cognition,
      func_vision = func_vision,
      func_daily_tasks = func_daily_tasks,
      stringsAsFactors = FALSE
    ))
  }
}

# Inject composition errors: remove head from 4 households
hh_no_head <- sample(unique(hh_ids)[15:120], 4)
roster$relationship[roster$hh_id %in% hh_no_head & roster$relationship == "head"] <- "other"

# Inject 3 households with two heads
hh_double_head <- sample(setdiff(unique(hh_ids), hh_no_head)[1:50], 3)
for (hid in hh_double_head) {
  non_head_rows <- which(roster$hh_id == hid & roster$relationship != "head")
  if (length(non_head_rows) > 0) {
    roster$relationship[non_head_rows[1]] <- "head"
  }
}

# --- MODULE 2: DWELLING CONDITIONS (one row per household) ---
dwelling <- data.frame(
  hh_id = c(hh_ids_with_dups),
  region_code = sample(c("R01", "R02", "R03", "R04"), length(hh_ids_with_dups), replace = TRUE),
  district_code = sample(paste0("D", sprintf("%03d", 1:20)), length(hh_ids_with_dups), replace = TRUE),
  locality_type = sample(c("urban", "rural"), length(hh_ids_with_dups), replace = TRUE, prob = c(0.55, 0.45)),
  n_rooms = sample(1:6, length(hh_ids_with_dups), replace = TRUE, prob = c(0.12, 0.30, 0.28, 0.18, 0.08, 0.04)),
  wall_material = sample(c("brick", "concrete", "wood", "mud", "metal_sheet", "other"), 
                         length(hh_ids_with_dups), replace = TRUE, prob = c(0.25, 0.30, 0.20, 0.10, 0.10, 0.05)),
  roof_material = sample(c("concrete", "metal_sheet", "tile", "thatch", "other"),
                         length(hh_ids_with_dups), replace = TRUE, prob = c(0.30, 0.35, 0.15, 0.12, 0.08)),
  floor_material = sample(c("tile", "concrete", "earth", "wood", "other"),
                          length(hh_ids_with_dups), replace = TRUE, prob = c(0.25, 0.35, 0.20, 0.12, 0.08)),
  owns_dwelling = sample(c("yes", "no"), length(hh_ids_with_dups), replace = TRUE, prob = c(0.55, 0.45)),
  monthly_rent = NA,
  electricity_source = sample(c("grid", "solar", "generator", "none"),
                              length(hh_ids_with_dups), replace = TRUE, prob = c(0.50, 0.15, 0.15, 0.20)),
  hours_electricity_day = NA,
  main_water_source = sample(c("piped_indoor", "piped_yard", "public_tap", "well", "river", "purchased"),
                             length(hh_ids_with_dups), replace = TRUE, prob = c(0.20, 0.15, 0.15, 0.20, 0.15, 0.15)),
  toilet_type = sample(c("flush", "pit_improved", "pit_basic", "none"),
                       length(hh_ids_with_dups), replace = TRUE, prob = c(0.25, 0.30, 0.25, 0.20)),
  shared_toilet = NA,
  cooking_fuel = sample(c("gas", "electricity", "charcoal", "wood", "kerosene"),
                        length(hh_ids_with_dups), replace = TRUE, prob = c(0.30, 0.10, 0.25, 0.25, 0.10)),
  stringsAsFactors = FALSE
)

# Fill skip logic fields correctly
for (i in 1:nrow(dwelling)) {
  # monthly_rent only if does not own
  if (dwelling$owns_dwelling[i] == "no") {
    dwelling$monthly_rent[i] <- sample(seq(50, 800, by = 25), 1)
  }
  # hours_electricity_day only if has electricity
  if (dwelling$electricity_source[i] != "none") {
    dwelling$hours_electricity_day[i] <- sample(2:24, 1)
  }
  # shared_toilet only if has a toilet
  if (dwelling$toilet_type[i] != "none") {
    dwelling$shared_toilet[i] <- sample(c("yes", "no"), 1, prob = c(0.30, 0.70))
  }
}

# Inject skip logic errors: 10 households answered monthly_rent despite owning
own_rows <- which(dwelling$owns_dwelling == "yes" & is.na(dwelling$monthly_rent))
if (length(own_rows) >= 10) {
  dwelling$monthly_rent[own_rows[1:10]] <- sample(seq(100, 600, by = 50), 10, replace = TRUE)
}

# Inject skip logic errors: 6 households answered hours_electricity despite having none
no_elec_rows <- which(dwelling$electricity_source == "none" & is.na(dwelling$hours_electricity_day))
if (length(no_elec_rows) >= 6) {
  dwelling$hours_electricity_day[no_elec_rows[1:6]] <- sample(4:18, 6, replace = TRUE)
}

# Inject missing values in 5 households for mandatory fields
missing_rows <- c(3, 18, 67, 130, 245)
dwelling$wall_material[missing_rows] <- NA
dwelling$roof_material[missing_rows] <- NA
dwelling$floor_material[missing_rows] <- NA

# --- MODULE 3: INCOME AND LIVELIHOODS (one row per person aged 15+) ---
adults <- roster[roster$age >= 15, ]

activities <- c("farming", "livestock", "fishing", "trade", "construction", 
                "transport", "domestic_work", "public_sector", "private_sector", "casual_labor")

income <- data.frame(
  hh_id = adults$hh_id,
  member_id = adults$member_id,
  worked_last_30_days = sample(c("yes", "no"), nrow(adults), replace = TRUE, prob = c(0.55, 0.45)),
  main_activity = NA,
  secondary_activity = NA,
  monthly_earnings = NA,
  received_remittances = sample(c("yes", "no"), nrow(adults), replace = TRUE, prob = c(0.15, 0.85)),
  remittance_amount = NA,
  received_govt_transfer = sample(c("yes", "no"), nrow(adults), replace = TRUE, prob = c(0.25, 0.75)),
  transfer_program_name = NA,
  stringsAsFactors = FALSE
)

for (i in 1:nrow(income)) {
  if (income$worked_last_30_days[i] == "yes") {
    income$main_activity[i] <- sample(activities, 1)
    if (runif(1) < 0.25) income$secondary_activity[i] <- sample(activities, 1)
    income$monthly_earnings[i] <- round(rlnorm(1, meanlog = 5.5, sdlog = 1.0))
  }
  if (income$received_remittances[i] == "yes") {
    income$remittance_amount[i] <- sample(seq(20, 500, by = 10), 1)
  }
  if (income$received_govt_transfer[i] == "yes") {
    income$transfer_program_name[i] <- sample(c("Program A", "Program B", "Program C"), 1)
  }
}

# Inject skip logic errors: 8 people who didn't work have a main_activity
not_worked <- which(income$worked_last_30_days == "no" & is.na(income$main_activity))
if (length(not_worked) >= 8) {
  income$main_activity[not_worked[1:8]] <- sample(activities, 8, replace = TRUE)
}

# Inject skip logic errors: 5 people who didn't receive remittances have an amount
no_remit <- which(income$received_remittances == "no" & is.na(income$remittance_amount))
if (length(no_remit) >= 5) {
  income$remittance_amount[no_remit[1:5]] <- sample(seq(50, 300, by = 25), 5, replace = TRUE)
}

# --- MODULE 4: FOOD CONSUMPTION (one row per household, last 7 days) ---
food <- data.frame(
  hh_id = unique(hh_ids),
  stringsAsFactors = FALSE
)

food_groups <- c("cereals", "roots_tubers", "legumes", "vegetables", "fruits", 
                 "meat", "fish", "dairy", "oils_fats", "sugar")

for (fg in food_groups) {
  food[[paste0("consumed_", fg)]] <- sample(c("yes", "no"), nrow(food), replace = TRUE,
                                             prob = c(0.60, 0.40))
  food[[paste0("days_", fg)]] <- NA
  food[[paste0("source_", fg)]] <- NA
}

sources <- c("own_production", "purchased", "gift", "food_aid", "gathered")

for (i in 1:nrow(food)) {
  for (fg in food_groups) {
    if (food[[paste0("consumed_", fg)]][i] == "yes") {
      food[[paste0("days_", fg)]][i] <- sample(1:7, 1)
      food[[paste0("source_", fg)]][i] <- sample(sources, 1)
    }
  }
}

# Inject skip logic errors: for 7 households, answer days_cereals despite not consuming
no_cereal <- which(food$consumed_cereals == "no" & is.na(food$days_cereals))
if (length(no_cereal) >= 7) {
  food$days_cereals[no_cereal[1:7]] <- sample(1:5, 7, replace = TRUE)
}

# --- MODULE 5: HEALTH ACCESS (one row per person) ---
health <- data.frame(
  hh_id = roster$hh_id,
  member_id = roster$member_id,
  illness_last_30_days = sample(c("yes", "no"), nrow(roster), replace = TRUE, prob = c(0.30, 0.70)),
  sought_treatment = NA,
  treatment_facility = NA,
  reason_no_treatment = NA,
  has_health_coverage = sample(c("yes", "no"), nrow(roster), replace = TRUE, prob = c(0.40, 0.60)),
  coverage_type = NA,
  chronic_condition = sample(c("yes", "no"), nrow(roster), replace = TRUE, prob = c(0.15, 0.85)),
  condition_type = NA,
  stringsAsFactors = FALSE
)

facilities <- c("public_hospital", "health_center", "private_clinic", "pharmacy", "traditional_healer")
no_treat_reasons <- c("too_expensive", "too_far", "not_severe", "no_time", "distrust")
coverage_types <- c("public", "employer", "private", "community")
conditions <- c("diabetes", "hypertension", "respiratory", "cardiovascular", "other")

for (i in 1:nrow(health)) {
  if (health$illness_last_30_days[i] == "yes") {
    health$sought_treatment[i] <- sample(c("yes", "no"), 1, prob = c(0.65, 0.35))
    if (health$sought_treatment[i] == "yes") {
      health$treatment_facility[i] <- sample(facilities, 1)
    } else {
      health$reason_no_treatment[i] <- sample(no_treat_reasons, 1)
    }
  }
  if (health$has_health_coverage[i] == "yes") {
    health$coverage_type[i] <- sample(coverage_types, 1)
  }
  if (health$chronic_condition[i] == "yes") {
    health$condition_type[i] <- sample(conditions, 1)
  }
}

# Inject skip logic errors: 10 people who were not ill have sought_treatment
not_ill <- which(health$illness_last_30_days == "no" & is.na(health$sought_treatment))
if (length(not_ill) >= 10) {
  health$sought_treatment[not_ill[1:10]] <- sample(c("yes", "no"), 10, replace = TRUE)
}

# Inject skip logic errors: 6 people without coverage have a coverage_type
no_coverage <- which(health$has_health_coverage == "no" & is.na(health$coverage_type))
if (length(no_coverage) >= 6) {
  health$coverage_type[no_coverage[1:6]] <- sample(coverage_types, 6, replace = TRUE)
}

# --- MODULE 6: EDUCATION (one row per person aged 3+) ---
school_age <- roster[roster$age >= 3, ]

school_types <- c("public", "private", "religious", "community")
edu_levels <- c("none", "primary_incomplete", "primary_complete", "secondary_incomplete", 
                "secondary_complete", "post_secondary")
not_enrolled_reasons <- c("too_expensive", "too_far", "working", "completed", 
                          "disability", "not_interested", "family_obligations")

education <- data.frame(
  hh_id = school_age$hh_id,
  member_id = school_age$member_id,
  age = school_age$age,
  can_read_write = ifelse(school_age$age >= 5,
                          sample(c("yes", "no"), nrow(school_age), replace = TRUE, prob = c(0.80, 0.20)),
                          NA),
  currently_enrolled = NA,
  school_type = NA,
  highest_level_completed = NA,
  reason_not_enrolled = NA,
  stringsAsFactors = FALSE
)

for (i in 1:nrow(education)) {
  a <- education$age[i]
  if (a >= 3 & a <= 24) {
    education$currently_enrolled[i] <- sample(c("yes", "no"), 1, 
                                               prob = if (a <= 14) c(0.85, 0.15) else c(0.45, 0.55))
    if (education$currently_enrolled[i] == "yes") {
      education$school_type[i] <- sample(school_types, 1, prob = c(0.50, 0.20, 0.15, 0.15))
    } else {
      education$reason_not_enrolled[i] <- sample(not_enrolled_reasons, 1)
    }
  }
  if (a >= 5) {
    education$highest_level_completed[i] <- sample(edu_levels, 1, 
                                                    prob = c(0.05, 0.15, 0.25, 0.20, 0.25, 0.10))
  }
}

# Inject skip logic errors: 6 people not enrolled have a school_type
not_enrolled <- which(education$currently_enrolled == "no" & is.na(education$school_type))
if (length(not_enrolled) >= 6) {
  education$school_type[not_enrolled[1:6]] <- sample(school_types, 6, replace = TRUE)
}

# --- WRITE EXCEL ---
wb <- createWorkbook()
addWorksheet(wb, "ROSTER")
addWorksheet(wb, "DWELLING")
addWorksheet(wb, "INCOME")
addWorksheet(wb, "FOOD_CONSUMPTION")
addWorksheet(wb, "HEALTH")
addWorksheet(wb, "EDUCATION")
writeData(wb, "ROSTER", roster)
writeData(wb, "DWELLING", dwelling)
writeData(wb, "INCOME", income)
writeData(wb, "FOOD_CONSUMPTION", food)
writeData(wb, "HEALTH", health)
writeData(wb, "EDUCATION", education)
saveWorkbook(wb, "data/sample_survey.xlsx", overwrite = TRUE)

cat("Sample data created: data/sample_survey.xlsx\n")
cat("Households:", length(unique(roster$hh_id)), 
    "(with", sum(duplicated(dwelling$hh_id)), "duplicate rows in dwelling)\n")
cat("Persons:", nrow(roster), "\n")
cat("Sheets: ROSTER, DWELLING, INCOME, FOOD_CONSUMPTION, HEALTH, EDUCATION\n")
cat("Injected errors:\n")
cat("  - Duplicate hh_id in dwelling\n")
cat("  - 4 households without head, 3 with multiple heads\n")
cat("  - Missing mandatory dwelling fields (5 households)\n")
cat("  - Skip logic violations in: dwelling (rent, electricity), income (activity, remittances),\n")
cat("    food consumption (days consumed), health (treatment, coverage), education (school type)\n")
