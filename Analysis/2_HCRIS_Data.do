set logtype text
global DATA_HCRIS "D:\CloudStation\Professional\Research Data\Hospital Cost Reports\Final HCRIS Data\"
global DATA_FINAL "D:\CloudStation\Professional\Research Projects\Hospital Readmissions\Data\"

***********************************************************************************
** Title:	      Hospital Cost Report Data
** Author:        Ian McCarthy
** Date created:  12/2/16
** Date edited:   6/2/17
** Notes:		  Combines data from CMS hospital cost reports on the number of 
**                discharges and bed sizes for each hospital per year.
***********************************************************************************
version 12.1
set more off

***********************************************************************************
/* Read in data from hospital cost reports */

** 2006
insheet using "${DATA_HCRIS}HospitalData_2006.txt", comma clear
gen Year=2006
save temp_data_2006, replace

** 2007
insheet using "${DATA_HCRIS}HospitalData_2007.txt", comma clear
gen Year=2007
save temp_data_2007, replace

** 2008
insheet using "${DATA_HCRIS}HospitalData_2008.txt", comma clear
gen Year=2008
save temp_data_2008, replace

** 2009
insheet using "${DATA_HCRIS}HospitalData_2009.txt", comma clear
gen Year=2009
save temp_data_2009, replace

** 2010
insheet using "${DATA_HCRIS}HospitalData_2010a.txt", comma clear
gen Year=2010
save temp_data_2010a, replace

insheet using "${DATA_HCRIS}HospitalData_2010b.txt", comma clear
gen Year=2010
save temp_data_2010b, replace

use temp_data_2010a, clear
append using temp_data_2010b
bys rpt_rec_num: gen obs=_n
bys rpt_rec_num: gen maxobs=_N
keep if obs==1
drop obs maxobs
save temp_data_2010, replace


** 2011
insheet using "${DATA_HCRIS}HospitalData_2011a.txt", comma clear
gen Year=2011
save temp_data_2011a, replace

insheet using "${DATA_HCRIS}HospitalData_2011b.txt", comma clear
gen Year=2011
save temp_data_2011b, replace

use temp_data_2011a, clear
append using temp_data_2011b
bys rpt_rec_num: gen obs=_n
bys rpt_rec_num: gen maxobs=_N
keep if obs==1
drop obs maxobs
save temp_data_2011, replace


** 2012
insheet using "${DATA_HCRIS}HospitalData_2012.txt", comma clear
gen Year=2012
save temp_data_2012, replace


** 2013
insheet using "${DATA_HCRIS}HospitalData_2013.txt", comma clear
gen Year=2013
save temp_data_2013, replace


** 2014
insheet using "${DATA_HCRIS}HospitalData_2014.txt", comma clear
gen Year=2014
save temp_data_2014, replace


** 2015
insheet using "${DATA_HCRIS}HospitalData_2015.txt", comma clear
gen Year=2015
save temp_data_2015, replace


** Append Data
use temp_data_2006, clear
forvalues i=2007(1)2015 {
  append using temp_data_`i'
}

sort state county
save temp_cost_reports, replace


***********************************************************************************
/* Create final datasets */
***********************************************************************************
use temp_cost_reports, clear
gen zip_5=substr(zip,1,5)
destring zip_5, replace
drop zip
rename zip_5 zip
drop Year

gen FY=year(date(fy_end,"MDYhms"))
gen FYear=FY
gen fmonth=month(date(fy_end,"MDYhms"))

gen CYear=FYear
replace CYear=FYear-1 if fmonth<6
save temp_hcris, replace

***********************************************************************************
/* Hospital-level dataset */
use temp_hcris, clear

** Generate price index
rename provider_number MCRNUM
drop if MCRNUM==.
gen fyear=clock(fy_end,"MDYhms")
format fyear %tc
gsort MCRNUM FY -fyear
by MCRNUM FY: gen obs=_n
drop if obs>1
drop obs
drop FY fyear

replace intcare_charges=0 if intcare_charges==.
replace ancserv_charges=0 if ancserv_charges==.
gen discount_factor=(1-tot_discounts/tot_charges)
gen price= (ip_charges + intcare_charges + ancserv_charges)*discount_factor - tot_mcarepymt
replace price= price/(total_discharges-mcare_discharges)

** Overall market share
by FYear zip, sort: egen Market_Discharges=total(total_discharges)
gen discharge_share=total_discharges/Market_Discharges
rename MCRNUM provider_number
save "${DATA_FINAL}HCRIS_Hospital_Level.dta", replace

** Summary Statistics by County
use temp_hcris, clear
by FYear zip, sort: egen Market_Discharges=total(total_discharges)
gen discharge_share=total_discharges/Market_Discharges
gen discharge_share2=discharge_share^2
collapse (sum) total_discharges HHI_Discharge=discharge_share2 TotalBeds=beds (count) Hospitals=provider_number, by(zip FYear)
sort zip FYear
save "${DATA_FINAL}HCRIS_County_Level.dta", replace

