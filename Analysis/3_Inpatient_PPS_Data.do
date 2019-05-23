set logtype text
cd "E:\"
global DATA_IPPS "C:\Users\immccar\Professional\Research Data\Hospital Inpatient PPS\PPS Payment Impact Files\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"

***********************************************************************************
** Title:	      Hospital Case Mix Data
** Author:        Ian McCarthy
** Date created:  3/15/17
** Date edited:   6/2/17
***********************************************************************************
version 12.1
set more off

******************************************************************
/* Read in Case Mix Adjusted Admissions from Medicare Inpatient PPS Files */
******************************************************************
** 2008 Data
insheet using "${DATA_IPPS}FY 2008\imppuf08_103107.txt", clear
rename providernumber MCRNUM
rename tacmiv24 CMI 
rename caseta24 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename adc Daily_Census
gen Year=2008
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census Year
save temp_pps_2008, replace

** 2009 Data
insheet using "${DATA_IPPS}FY 2009\imppuf09_080929.csv", clear case
rename ProviderNumber MCRNUM
rename TACMIV26 CMI 
rename CASETA26 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(URSPA=="LURBAN" | URSPA=="OURBAN")
rename BEDS Beds
rename AverageDailyCensus Daily_Census
gen Year=2009
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census Year
save temp_pps_2009, replace

** 2010 Data
insheet using "${DATA_IPPS}FY 2010\FY_2010_Final_Rule_Impact_File_1.txt", clear
rename providernumber MCRNUM
rename tacmiv26 CMI 
rename caseta26 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2010
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census Year
save temp_pps_2010, replace

** 2011 Data
insheet using "${DATA_IPPS}FY 2011\FY 2011 Final Rule- IPPS Impact File PUF_1.txt", clear
rename providernumber MCRNUM
rename tacmiv27 CMI 
rename caseta27 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2011
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census Year
save temp_pps_2011, replace

** 2012 Data
insheet using "${DATA_IPPS}FY 2012\FY 2012 Final Rule- IPPS Impact File PUF-August 15, 2011_1.txt", clear
rename providernumber MCRNUM
rename tacmiv28 CMI 
rename caseta28 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2012
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census Year
save temp_pps_2012, replace


** 2013 Data
insheet using "${DATA_IPPS}FY 2013\FY 2013 Final Rule CN - IPPS Impact File PUF-March 2013.txt", clear
rename providernumber MCRNUM
rename tacmiv29 CMI 
rename caseta29 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2013
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census Year
save temp_pps_2013, replace

** 2014 Data
insheet using "${DATA_IPPS}FY 2014\FY 2014 Final Rule IPPS Impact PUF.txt", clear
rename providernumber MCRNUM
rename tacmiv30 CMI 
rename caseta30 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2014
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census Year
save temp_pps_2014, replace

** 2015 Data
insheet using "${DATA_IPPS}FY 2015\FY 2015 IPPS Final Rule Impact PUF (FR data).txt", clear
rename providernumber MCRNUM
rename tacmiv31 CMI 
rename caseta31 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2015
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census Year
save temp_pps_2015, replace


use temp_pps_2008, clear
forvalues t=2009/2015 {
  append using temp_pps_`t'
}
rename MCRNUM provider_number
rename Year FYear
save "${DATA_FINAL}Hospital_PPS.dta", replace
