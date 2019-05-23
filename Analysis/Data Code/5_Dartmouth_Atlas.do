**set logtype text
cd "E:\"
global DATA_DARTMOUTH "C:\Users\immccar\Professional\Research Data\Dartmouth Atlas\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"

***********************************************************************************
** Title:	      Dartmouth Atlas Data Input and Formating
** Author:        Ian McCarthy
** Date created:  12/2/2016
** Date edited:   6/3/2017
***********************************************************************************
set more off

***********************************************************************************
/* Read and Clean Dartmouth Atlas Data */
***********************************************************************************

********************************
** 2010 Data
insheet using "${DATA_DARTMOUTH}DAP_hospital_data_2010.txt", clear tab
gen Year=2010
save temp_dap_2010, replace

********************************
** 2011 Data
insheet using "${DATA_DARTMOUTH}DAP_hospital_data_2011v2.txt", clear tab
gen Year=2011
save temp_dap_2011, replace

********************************
** 2012 Data
insheet using "${DATA_DARTMOUTH}DAP_hospital_data_2012.txt", clear tab
gen Year=2012
save temp_dap_2012, replace

********************************
** 2013 Data
insheet using "${DATA_DARTMOUTH}DAP_hospital_data_2013.txt", clear tab
gen Year=2013
save temp_dap_2013, replace

********************************
** 2014 Data
insheet using "${DATA_DARTMOUTH}DAP_hospital_data_2014.txt", clear tab
gen Year=2014
save temp_dap_2014, replace

********************************
** Combine Dartmouth Atlas Data
clear
use temp_dap_2010
append using temp_dap_2011
append using temp_dap_2012
append using temp_dap_2013
append using temp_dap_2014
rename providerid provider_number
save "${DATA_FINAL}DartmouthAtlas_Data.dta", replace
