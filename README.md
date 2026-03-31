# Staggered Difference-in-Differences: Minimum Wage Laws and County Employment

This repository implements a staggered difference-in-differences analysis of the effect of **US state minimum wage laws on county-level employment**, using the dataset from Callaway & Sant'Anna (2021).

The project was built to demonstrate applied knowledge of modern DiD methods, with a focus on the **`did_multiplegt_dyn`** estimator developed by de Chaisemartin & D'Haultfoeuille (2024).

---

## Dataset

**Source:** Callaway & Sant'Anna (2021), *Difference-in-Differences with Multiple Time Periods*, Journal of Econometrics.  
Available via the R package `did` (`data(mpdta)`).

| Variable | Description |
|---|---|
| `county_id` | County FIPS code (group identifier) |
| `year` | Year (2003–2007) |
| `log_emp` | Log county-level employment (outcome) |
| `log_pop` | Log county population (control) |
| `first_treat` | Year of first treatment (0 = never treated) |
| `treat` | =1 if county is treated in this year |

**Treatment cohorts:**
- **Cohort 2004** — 20 counties, treated from 2004 onwards
- **Cohort 2006** — 40 counties, treated from 2006 onwards  
- **Cohort 2007** — 131 counties, treated from 2007 onwards
- **Never treated** — 309 counties (control group)

---

## Methods

### 1. Two-Way Fixed Effects (TWFE)
Standard panel estimator with county and year fixed effects. With staggered adoption, TWFE may be biased if treatment effects are heterogeneous across cohorts or over time.

```
log_emp_it = α_i + λ_t + β·treat_it + ε_it
```

Estimated coefficient: **β = -0.037** (SE = 0.013, p = 0.006)

### 2. Bacon Decomposition
Decomposes the TWFE estimator into weighted averages of all possible 2×2 DiD comparisons. Reveals whether "forbidden comparisons" (already-treated units used as controls) drive the results.

**Key finding:** 86% of the TWFE weight comes from the clean `Never-treated vs Timing` comparison — reassuring.

### 3. `did_multiplegt_dyn` (de Chaisemartin & D'Haultfoeuille, 2024)
Heterogeneity-robust estimator that only uses clean comparisons: newly treated units vs not-yet-treated units. Estimates dynamic treatment effects for each period relative to treatment.

| Period | Estimate | SE | Significant |
|---|---|---|---|
| +1 | -0.019 | 0.012 | No |
| +2 | -0.054 | 0.017 | Yes |
| +3 | -0.137 | 0.036 | Yes |
| +4 | -0.101 | 0.035 | Yes |

**Placebo test** (pre-trends): p-value = 0.22 — parallel trends assumption not rejected ✅

---

## Results

| | TWFE | dCdH (Avg.) |
|---|---|---|
| Estimate | -0.037** | -0.040** |
| SE | (0.013) | (0.012) |

Both estimators agree: minimum wage laws reduce county employment by approximately **3.7–4.0%** on average. The dynamic effects suggest the impact grows over time, reaching ~13% by period +3.

---

## Repository Structure

```
did-minwage-staggered/
├── data/
│   ├── raw/
│   │   └── mpdta.csv          ← original dataset (Callaway & Sant'Anna 2021)
│   └── minwage_clean.dta      ← cleaned Stata dataset
├── stata/
│   └── analysis.do            ← full analysis script
├── output/
│   ├── table_summary.csv      ← descriptive statistics by cohort
│   ├── table_twfe.csv         ← TWFE regression results
│   └── figures/
│       ├── trends_by_cohort.png   ← employment trends by cohort
│       ├── bacon_decomp.png       ← Bacon decomposition scatter
│       └── event_study.png        ← event study plot (dCdH 2024)
└── README.md
```

---

## How to Replicate

1. Clone the repository
2. Open Stata and set the working directory to the project root
3. Run `stata/analysis.do`

The script installs all required packages automatically (`did_multiplegt_dyn`, `estout`, `bacondecomp`).

---

## References

- Callaway, B. & Sant'Anna, P. (2021). *Difference-in-Differences with Multiple Time Periods*. Journal of Econometrics, 225(2), 200–230.
- de Chaisemartin, C. & D'Haultfoeuille, X. (2024). *Difference-in-Differences Estimators of Intertemporal Treatment Effects*. Review of Economics and Statistics.
- Goodman-Bacon, A. (2021). *Difference-in-Differences with Variation in Treatment Timing*. Journal of Econometrics, 225(2), 254–277.

---

*This project was developed as part of applied econometrics training at the Barcelona School of Economics.*
