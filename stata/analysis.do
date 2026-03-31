********************************************************************************
* Staggered DiD: Effect of Minimum Wage Laws on County-Level Employment
* Dataset: Callaway & Sant'Anna (2021) — mpdta
*
* Author: Giulio Conte
* Barcelona School of Economics
* Date: March 2026
*
* Panel: ~500 US counties, 2003-2007
* Outcome: log employment (lemp)
* Treatment: county-level minimum wage law adoption
* Treatment cohorts: 2004, 2006, 2007 (staggered), 0 = never treated
*
* Estimators:
*   1. TWFE (baseline)
*   2. Bacon decomposition (diagnose heterogeneity bias)
*   3. did_multiplegt_dyn (de Chaisemartin & D'Haultfoeuille 2024)
********************************************************************************

clear all
set more off
cap log close
log using "output/log_analysis.log", replace

********************************************************************************
* 0. INSTALL PACKAGES
********************************************************************************

foreach pkg in did_multiplegt_dyn estout bacondecomp {
    cap which `pkg'
    if _rc != 0 {
        ssc install `pkg', replace
    }
}

********************************************************************************
* 1. LOAD AND PREPARE DATA
********************************************************************************

import delimited "data/raw/mpdta.csv", clear

* Fix variable names
rename countyreal county_id
rename firsttreat first_treat
rename lemp       log_emp
rename lpop       log_pop

label var county_id   "County FIPS code"
label var year        "Year"
label var log_emp     "Log county employment (outcome)"
label var log_pop     "Log county population (control)"
label var first_treat "Year of first treatment (0 = never treated)"

* Reconstruct treat as a clean absorbing indicator
* (original treat variable may have inconsistencies)
drop treat
gen treat = (first_treat > 0 & year >= first_treat)
label var treat "=1 if county is treated in this year (absorbing)"

* Never-treated indicator
gen never_treated = (first_treat == 0)
label var never_treated "=1 if county never treated"

* Treatment cohort
gen cohort = first_treat
label define cohort_lbl 0 "Never Treated" 2004 "Cohort 2004" ///
                         2006 "Cohort 2006" 2007 "Cohort 2007"
label values cohort cohort_lbl

* Set panel
xtset county_id year

* Verify treat is monotonically increasing (required for bacondecomp)
bysort county_id (year): assert treat >= treat[_n-1] if _n > 1
di "Treatment variable is monotonically non-decreasing: OK"

save "data/minwage_clean.dta", replace

********************************************************************************
* 2. DESCRIPTIVE STATISTICS
********************************************************************************

use "data/minwage_clean.dta", clear

* Sample composition
tab cohort

* Summary statistics
estpost tabstat log_emp log_pop, ///
    by(cohort) statistics(mean sd n) columns(statistics)

esttab using "output/table_summary.csv", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) count(fmt(0))") ///
    title("Summary Statistics by Treatment Cohort") noobs

* Trends by cohort
preserve
collapse (mean) log_emp, by(year cohort)

twoway ///
    (line log_emp year if cohort == 0,    lcolor(navy)         lwidth(medium)) ///
    (line log_emp year if cohort == 2004, lcolor(cranberry)    lwidth(medium) lpattern(dash)) ///
    (line log_emp year if cohort == 2006, lcolor(forest_green) lwidth(medium) lpattern(dot)) ///
    (line log_emp year if cohort == 2007, lcolor(orange)       lwidth(medium) lpattern(longdash)), ///
    legend(label(1 "Never Treated") label(2 "Cohort 2004") ///
           label(3 "Cohort 2006")   label(4 "Cohort 2007") rows(2) size(small)) ///
    xtitle("Year") ytitle("Mean Log Employment") ///
    title("Employment Trends by Treatment Cohort") ///
    xline(2004, lcolor(cranberry)    lpattern(shortdash) lwidth(thin)) ///
    xline(2006, lcolor(forest_green) lpattern(shortdash) lwidth(thin)) ///
    xline(2007, lcolor(orange)       lpattern(shortdash) lwidth(thin)) ///
    note("Source: Callaway & Sant'Anna (2021) — mpdta")

graph export "output/figures/trends_by_cohort.png", replace width(1400)
restore

********************************************************************************
* 3. TWFE DiD (BASELINE)
********************************************************************************

use "data/minwage_clean.dta", clear

xtreg log_emp treat i.year, fe vce(cluster county_id)
estimates store twfe_basic
estadd local fe "County + Year"
estadd local control "No"

xtreg log_emp treat log_pop i.year, fe vce(cluster county_id)
estimates store twfe_controls
estadd local fe "County + Year"
estadd local control "Yes"

esttab twfe_basic twfe_controls using "output/table_twfe.csv", replace ///
    keep(treat) ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    stats(fe control N, labels("Fixed Effects" "Pop. Control" "Observations")) ///
    title("TWFE DiD: Effect of Minimum Wage on Log Employment") ///
    mtitles("Basic TWFE" "With Controls") ///
    note("SE clustered at county level.")

********************************************************************************
* 4. BACON DECOMPOSITION
********************************************************************************

use "data/minwage_clean.dta", clear
xtset county_id year

bacondecomp log_emp treat, ddetail

graph export "output/figures/bacon_decomp.png", replace width(1200)

********************************************************************************
* 5. DID_MULTIPLEGT_DYN (de Chaisemartin & D'Haultfoeuille, 2024)
********************************************************************************

use "data/minwage_clean.dta", clear

did_multiplegt_dyn log_emp county_id year treat, ///
    effects(4) placebo(3)                        ///
    controls(log_pop)                            ///
    cluster(county_id)

graph export "output/figures/event_study.png", replace width(1400)

********************************************************************************
log close
di "Done. Outputs saved to output/"
