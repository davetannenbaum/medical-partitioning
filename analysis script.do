** =============================================================================
** This file: analysis script.do
** Format: Stata 12 do-file
** Author: David Tannenbaum <davetannenbaum@gmail.com>
** Purpose:STATA code for analyzing cleaned data used in Tannenbaum et al., 2015 
** "Nudging physician prescription decisions by partitioning the order set:
** Results of a vignette-based study"
** =============================================================================

** IMPORTANT: change the working directory to wherever you have placed the files
** =============================================================================
version 12.1
cd "~/GitHub/medical-partitioning/"
use "cleaned data.dta", clear

** Demographics
** =============================================================================
preserve
collapse responder gender age specialty degree practice_type years_practice hours, by(id)
tab responder gender, row chi2 // provider gender
sum age, detail // provider age
tab responder specialty, row chi2 // professional specialty
tab responder degree, row chi2 // professional degree
tab responder practice_type, row chi2 // practice setting
sum years_practice, detail // years practicing
sum hours, detail // hours per week
restore

** Model I (not adjusting for provider characteristics)
** =============================================================================
// All trials
logit dv i.cond i.trial, cluster(id)
margins cond
margins, dydx(cond)

// OTC vs Rx block
preserve
keep if inrange(trial,1,3)
logit dv i.cond i.trial, cluster(id)
margins cond
margins, dydx(cond)
restore

// Narrow vs Broad block
preserve
keep if inrange(trial,4,7)
logit dv i.cond i.trial, cluster(id)
margins cond
margins, dydx(cond)
restore

// Separately by vignette
forvalues i = 1/7 {
	quietly logit dv i.cond if trial == `i', nolog
	margins cond
	margins, dydx(cond)
}

** Model II (adjusting for provider characteristics)
** =============================================================================
// assembling provider characteristics 
local covariates = "i.trial i.gender c.age c.years_practice c.hours i.specialty"

// All trials 
logit dv i.cond `covariates', cluster(id)
margins cond
margins, dydx(cond)

// OTC vs Rx block 
preserve
keep if inrange(trial,1,3)
logit dv i.cond `covariates', cluster(id)
margins cond
margins, dydx(cond)
restore

// Narrow vs Broad block 
preserve
keep if inrange(trial,4,7)
logit dv i.cond `covariates', cluster(id)
margins cond
margins, dydx(cond)
restore

// Separately by vignette 
forvalues i = 1/7 {
	quietly logit dv i.cond `covariates' if trial == `i', nolog
	quietly margins cond
	margins, dydx(cond)
}