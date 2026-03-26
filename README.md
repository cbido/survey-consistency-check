# survey-consistency-check

An R Markdown template for automated data consistency analysis of household surveys. One `.Rmd` file reads the raw database, verifies structural integrity, checks skip logic, flags missing values, and produces a PDF report with a formal ruling — all reactive to the data. When the database gets corrected and resubmitted, you re-run the document and every finding, count, and paragraph updates automatically.

## The problem

Data consistency analysis for household surveys usually happens in a disconnected workflow: someone reviews the database in R or Excel, writes findings in a Word document, and sends it to the data provider. When the corrected database comes back, the entire review has to be repeated manually. This template eliminates that manual loop.

## How it works

The system has three layers:

### 1. Incidence accumulator

A global list that collects every finding classified by severity (critical, medium, minor) as the document generates:

```r
add_incidence <- function(severity, section, variable, description, n = NA) {
  new_row <- data.frame(Section = section, Variable = variable, 
                        Description = description, N_Affected = n,
                        stringsAsFactors = FALSE)
  if(severity == "critical")    incidences$critical <<- rbind(incidences$critical, new_row)
  else if(severity == "medium") incidences$medium   <<- rbind(incidences$medium, new_row)
  else                          incidences$minor    <<- rbind(incidences$minor, new_row)
}
```

### 2. Module-by-module verification blocks

Each survey module has its own code chunk that evaluates the instrument's rules and calls `add_incidence()` when it finds a problem. This includes duplicate detection, household composition rules, missing value checks, and skip logic validation across all six modules (roster, dwelling, income, food consumption, health, education).

### 3. Reactive inline text

Below each verification, the report text uses inline R to write the result automatically. If there are no errors, the paragraph says everything is in order; if there are, it reports the exact count and severity:

```r
**Result:** `r ifelse(n_error_rent == 0, 
  "All records comply with the skip rule.", 
  paste("**MEDIUM:**", n_error_rent, "households that own their dwelling reported a monthly rent."))`
```

At the end, the ruling generates automatically based on accumulated incidences:

```r
ruling <- if(n_critical > 0) "REJECTED" 
          else if(n_medium > 0 | n_minor > 0) "ACCEPTED WITH OBSERVATIONS" 
          else "ACCEPTED"
```

## What the template checks

The sample survey has six modules. The template verifies:

**Roster**
- Duplicate person IDs
- Household composition — missing head of household, multiple heads, head under 15
- Functional screening completeness (four domains)

**Dwelling**
- Duplicate household IDs
- Missing values in mandatory fields (wall, roof, floor materials, rooms, water source, cooking fuel)
- Skip logic — monthly rent reported by owners, electricity hours reported by households without electricity, shared toilet reported by households without a toilet

**Income**
- Skip logic — main activity reported by persons who did not work, remittance amount reported by non-recipients

**Food consumption**
- Skip logic across ten food groups — days consumed and source reported for food groups the household did not consume

**Health**
- Skip logic — treatment-seeking reported by persons who were not ill, coverage type reported by persons without health coverage

**Education**
- Skip logic — school type reported by persons not currently enrolled

## Quick start

1. Clone this repo
2. Run `data/generate_sample_data.R` to create the sample dataset (or replace it with your own)
3. Knit `consistency_check.Rmd`

```r
source("data/generate_sample_data.R")
rmarkdown::render("consistency_check.Rmd")
```

The sample dataset includes deliberately injected errors (duplicates, missing values, skip logic violations across all modules) so you can see the system in action.

## Adapting to your own survey

The template is designed to be extended. To add a new verification:

1. Add a code chunk that identifies the problem
2. Call `add_incidence()` with the appropriate severity
3. Add an inline R paragraph below the chunk that reports the result reactively

The accumulator collects everything, and the final ruling updates automatically.

## Requirements

- R >= 4.0
- Packages: `readxl`, `tidyverse`, `knitr`, `kableExtra`, `openxlsx` (for sample data generation)
- A LaTeX distribution for PDF output (or change the output to `html_document`)

## Author

Camila Bidó Cuello — [Bidó Social Science Consulting](https://www.linkedin.com/in/camilabido/)

## License

MIT
