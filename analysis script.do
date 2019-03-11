** =============================================================================
** This file: analysis script.do
** Format: Stata 12 do-file
** Author: David Tannenbaum <davetannenbaum@gmail.com>
** =============================================================================

** IMPORTANT: change the working directory to wherever you have placed the files
** =============================================================================
version 12.1
use "https://github.com/davetannenbaum/medical-partitioning/blob/master/cleaned%20data.dta?raw=true", clear

** Demographics
** =============================================================================
preserve
collapse responder gender age specialty degree practice_type years_practice hours, by(id)
tabulate responder gender, row chi2 // provider gender
summarize age, detail // provider age
tabulate responder specialty, row chi2 // professional specialty
tabulate responder degree, row chi2 // professional degree
tabulate responder practice_type, row chi2 // practice setting
summarize years_practice, detail // years practicing
summarize hours, detail // hours per week
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