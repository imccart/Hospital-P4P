**set logtype text
cd "E:\"
global DATA_HRRP "C:\Users\immccar\Professional\Research Data\Hospital Readmission Reduction\readmission_v2\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"

***********************************************************************************
** Title:	      Readmissions Data Input and Formating (raw data from M. Darden)
** Author:        Ian McCarthy
** Date created:  3/13/2017
** Date edited:   6/2/17
***********************************************************************************
set more off

***********************************************************************************
/* Read and Clean Fiscal Year Readmissions Data from HRRP */
***********************************************************************************
use "${DATA_HRRP}readmission_hrrp.dta", clear
rename h_id provider_number
rename year FYear
save temp_hrrp, replace


***********************************************************************************
/* Read and Clean Full Readmissions Data */
***********************************************************************************
use "${DATA_HRRP}readmissions_hos.dta", clear
egen hosp_year_gp=group(id fyear)
sort id fyear month
rename id provider_number

/* ** Take modal values from HOS
foreach x of newlist ami hf pn hk copd {
	foreach y of newlist rate ratio num_dis {
		bys provider_number fyear: egen mode_`y'_`x'=mode(`y'_`x'), maxmode
	}
}
bys provider_number fyear: gen obs=_n
keep if obs==1
keep provider_number fyear mode_*
foreach x of newlist ami hf pn hk copd {
	foreach y of newlist rate ratio num_dis {
		rename mode_`y'_`x' `y'_`x'
	}
}
*/
rename fyear FYear
rename year CYear
save temp_readmissions, replace


***********************************************************************************
/* Combine datasets */
***********************************************************************************
use temp_readmissions, clear
merge m:1 provider_number FYear using temp_hrrp, nogenerate

tab month if round(ratio_ami,0.01)==round(ami,0.01) & ratio_ami!=. & ami!=. & FYear==2013
tab month if round(ratio_ami,0.01)==round(ami,0.01) & ratio_ami!=. & ami!=. & FYear==2014
tab month if round(ratio_ami,0.01)==round(ami,0.01) & ratio_ami!=. & ami!=. & FYear==2015
tab month if round(ratio_ami,0.01)==round(ami,0.01) & ratio_ami!=. & ami!=. & FYear==2016

foreach x of varlist ami hf pn hk copd {
  gen diff_`x'=abs(ratio_`x'-`x') if ratio_`x'!=. & ratio_`x'!=0 & `x'!=. & `x'!=0
}
gen month_match=((FYear==2010 & month==12) | (FYear==2011 & month==10) | (FYear==2012 & month==10) | (FYear==2013 & month==10) ///
   | (FYear==2014 & month==10) | (FYear==2015 & month==12) | (FYear==2016 & month==10) )

/* ** Check Matching
bys provider_number Year: gen obs=_n
bys provider_number Year month_match: gen obs_match=_n if month_match==1
count if obs==1
count if obs_match==1
bys provider_number Year: egen no_match=min(obs_match)
count if no_match==.
*/

keep if month_match==1
drop CYear
sort provider_number FYear
save "${DATA_FINAL}Final_Readmissions.dta", replace
