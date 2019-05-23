***********************************************************************************
** Title:	      Value based purchasing data
** Author:        Ian McCarthy
** Date created:  6/30/17
** Date edited:   6/30/17
***********************************************************************************

cd "E:\"
global DATA_VBP "C:\Users\immccar\Professional\Research Data\Hospital VBP\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"
set more off

***********************************************************************************
** 2013 files
import excel using "${DATA_VBP}FY2013\CMS-1588-F Table 16_Proxy_and Actual_VBP_Factors_Feb2013 Update.xlsx", sheet("Actual_Table 16_February 2013") cellrange(A3:B2986) clear
rename A provider_number
rename B VBP_adj
gen FYear=2013
save temp_vbp_2013, replace

***********************************************************************************
** 2014 files
import excel using "${DATA_VBP}FY2014\FY_2014_Tables_16B and 16A_Oct2013.xlsx", sheet("Final Factors - Table_16B") cellrange(A3:B2730) clear
destring A, replace
destring B, replace
rename A provider_number
rename B VBP_adj
gen FYear=2014
save temp_vbp_2014, replace

***********************************************************************************
** 2015 files
import excel using "${DATA_VBP}FY2015\CMS-1607-F Tables 16A and 16B_FY 2015.xlsx", sheet("Table 16B - FY15") cellrange(A3:B3091) clear
destring A, replace
destring B, replace
rename A provider_number
rename B VBP_adj
gen FYear=2015
save temp_vbp_2015, replace

***********************************************************************************
** Append Yearly Data
use temp_vbp_2013, clear
append using temp_vbp_2014
append using temp_vbp_2015

** Save Final Risk/Rebate Data
save "${DATA_FINAL}Hospital_VBP.dta", replace
