**set logtype text
cd "E:\"
global DATA_ACS "C:\Users\immccar\Professional\Research Data\ACS Data\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"

***********************************************************************************
** Title:	      ACS Data Input and Formating
** Author:        Ian McCarthy
** Date created:  3/15/2017
** Date edited:   6/2/2017
***********************************************************************************
set more off

***********************************************************************************
/* Read and Clean AHA Data */
***********************************************************************************

use "${DATA_ACS}2007 Clean\ACS_Data.dta", clear
gen year=2007
append using "${DATA_ACS}2008 Clean\ACS_Data.dta"
replace year=2008 if year==.
append using "${DATA_ACS}2009 Clean\ACS_Data.dta"
replace year=2009 if year==.
append using "${DATA_ACS}2010 Clean\ACS_Data.dta"
replace year=2010 if year==.
append using "${DATA_ACS}2011 Clean\ACS_Data.dta"
replace year=2011 if year==.
append using "${DATA_ACS}2012 Clean\ACS_Data.dta"
replace year=2012 if year==.
append using "${DATA_ACS}2013 Clean\ACS_Data.dta"
replace year=2013 if year==.
append using "${DATA_ACS}2014 Clean\ACS_Data.dta"
replace year=2014 if year==.
append using "${DATA_ACS}2015 Clean\ACS_Data.dta"
replace year=2015 if year==.

/*
split fips, parse("_")
gen str3 fips3 = string(county, "%03.0f")
gen fips_clean=fips1+fips3
destring fips_clean, replace
sort fips_clean
drop fips fips1 fips2 fips3
rename fips_clean fips
rename name ACS_Name
sort fips year
*/
drop state county
rename year CYear
save "${DATA_FINAL}ACS_Data.dta", replace
