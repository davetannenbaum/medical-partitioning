** =============================================================================
** This file: cleanup script.do
** Format: Stata 12 do-file
** Author: David Tannenbaum <davetannenbaum@gmail.com>
** Purpose:STATA code for cleaning raw data used in Tannenbaum et al., 2015 
** "Nudging physician prescription decisions by partitioning the order set:
** Results of a vignette-based study"
** =============================================================================

** IMPORTANT: change the working directory to current file location
** =============================================================================
version 12.1
cd "~/GitHub/medical-partitioning/"
use "raw data.dta", clear

** Labeling variables in data set
** Note: this cleanup requires the add-on module 'rencode'
** =============================================================================
rename practice_type specialty
label var cond1 "partition - OTC vs antibiotic"
label var cond2 "partition - narrow vs broad"
label var cond3 "grouping on top vs bottom"
label var cond4 "block ordering"
label var cond5 "item ordering"

** One subject reported an age of 1. We assumed this was a typo and replaced
** with a missing value
** =============================================================================
replace age = . if age == 1

** Generating outcome variables
** =============================================================================
// OTC vs Rx block: dummy coded for aggressive treatment choice
gen dv1a = inrange(acute_nonstrep1,1,3)
gen dv1b = inrange(acute_nonstrep2,1,3)
gen dv1c = inrange(acute_nonstrep3,1,3)
gen dv2a = inrange(acute_bronchitis1,1,4)
gen dv2b = inrange(acute_bronchitis2,1,4)
gen dv2c = inrange(acute_bronchitis3,1,4)
gen dv3a = inrange(acute_nasopharyngitis1,1,4)
gen dv3b = inrange(acute_nasopharyngitis2,1,4)
gen dv3c = inrange(acute_nasopharyngitis3,1,4)
egen dv1 = rowtotal(dv1a dv1b dv1c)
egen dv2 = rowtotal(dv2a dv2b dv2c)
egen dv3 = rowtotal(dv3a dv3b dv3c)
replace dv1 = inrange(dv1,1,3)
replace dv2 = inrange(dv2,1,3)
replace dv3 = inrange(dv3,1,3)

// Narrow vs Broad Spectrum block: dummy coded for aggressive treatment choice
gen dv4 = inrange(otitis_media,1,7)
gen dv5 = inrange(urinary,1,5)
gen dv6 = inrange(sinusitis,1,8)
gen dv7 = inrange(cellulitis,1,6)

// The code above sets a value of 0 even if the participant failed to respond
// Here we fix this by replacing them with missing values
replace dv1 = . if acute_nonstrep1 == .
replace dv2 = . if acute_bronchitis1 == .
replace dv3 = . if acute_nasopharyngitis1 == .
replace dv4 = . if otitis_media == .
replace dv5 = . if urinary == .
replace dv6 = . if sinusitis == .
replace dv7 = . if cellulitis == .

** Recoded Responses
** =============================================================================
// dropping 3 responses for errors on forms
replace dv2 = . if subject_id == 205
replace dv2 = . if subject_id == 184
replace dv2 = . if subject_id == 140

// instances where doctors wrote in another response that required recoding. To
// reproduce the Table in the Supplementary Materials, simply run the cleanup
// while omitting this portion
replace dv2 = 0 if subject_id == 150
replace dv5 = . if subject_id == 151
replace dv6 = . if subject_id == 151
replace dv7 = . if subject_id == 151
replace dv5 = 0 if subject_id == 179
replace dv5 = 1 if subject_id == 182
replace dv1 = 0 if subject_id == 197
replace dv4 = 1 if subject_id == 206
replace dv1 = 1 if subject_id == 242
replace dv4 = . if subject_id == 260
replace dv5 = . if subject_id == 260
replace dv6 = 1 if subject_id == 260
replace dv7 = 1 if subject_id == 260
replace dv1 = 0 if subject_id == 227
replace dv1 = 0 if subject_id == 248

** Merging file with provider network data (which includes additional provider
** characteristics)
** =============================================================================
// dropping gender and specialty items... these are already included in the
// provider demographic set and allows for smooth merging of the two data sets
drop gender
drop specialty

// merging data and additional recoding (requires 'recode' and 'rencode' packages)
merge 1:1 subject_id using "provider network data.dta", gen(responder)
replace responder = responder - 2
label define responderl 0 "nonresponders" 1 "responders"
label val responder responderl
rencode degree, replace
recode degree (2 3 = 1 ) (5 6 = 2) (1 4 = 3)
label define degreel 1 "MD" 2 "PA" 3 "NP"
label val degree degreel
rencode specialty, replace
recode specialty (1 2 3 = 1) (4 5 = 2) (6 7 8 = 3)
label define specialty 1 "Family Medicine" 2 "Internal Medicine" 3 "Other", replace
label val specialty specialtyl
rencode practice_type, replace

** Pruning data set
** =============================================================================
keep subject_id cond1-cond5 gender age specialty degree practice_type years_practice hours responder dv1-dv7
order subject_id cond1-cond5 gender age specialty degree practice_type years_practice hours responder dv1-dv7


** Labeling and Reshaping Data
** =============================================================================
label define cond1l 0 "Antibiotics unpacked" 1 "OTC unpacked"
label define cond2l 0 "Broad unpacked" 1 "Narrow unpacked"
label define cond3l 0 "grouping on bottom" 1 "grouping on top"
label define cond4l 0 "OTC block first" 1 "OTC block second"
label define cond5l 0 "regular ordering" 1 "reverse ordering"
label define genderl 1 "male" 2 "female"
label define specialtyl 1 "Internal medicine" 2 "Family medicine" 3 "Other"
label val cond1 cond1l
label val cond2 cond2l
label val cond3 cond3l
label val cond4 cond4l
label val cond5 cond5l
label val gender genderl
label val specialty specialtyl
gen id = _n
reshape long dv, i(id) j(trial)
gen cond = .
replace cond = 1 if cond1 == 0 & inrange(trial,1,3)
replace cond = 0 if cond1 == 1 & inrange(trial,1,3)
replace cond = 1 if cond2 == 0 & inrange(trial,4,7)
replace cond = 0 if cond2 == 1 & inrange(trial,4,7)

** Saving data to file
** =============================================================================
export delimited "cleaned data.csv", replace
save "cleaned data.dta", replace