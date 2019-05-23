**set logtype text
cd "C:\Users\immccar\My Documents\"
global DATA_OSHPD "C:\Users\immccar\Professional\Research Data\California OSHPD\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"

***********************************************************************************
** Title:	      California Hospital (OSHPD) Data Input and Formating
** Author:        Ian McCarthy
** Date created:  12/13/2016
** Date edited:   12/13/2016
***********************************************************************************
set more off

***********************************************************************************
/* Read and Clean Annual Financial Data (includes Medicare Provider Number)
     and Utilization Files */
***********************************************************************************

********************************
forvalues y=2008/2015 {
  insheet using "${DATA_OSHPD}Annual Financial Data\FY`y'.txt", clear tab
  if `y'==2015 {
    rename state_oshpd_facility_number oshpd_id
    rename medicare_provider_number Medicare_Pvdr_Num  
  } 
  else {
    rename stateoshpdfacilitynumber oshpd_id
    rename medicareprovidernumber Medicare_Pvdr_Num
  }
  keep oshpd_id Medicare_Pvdr_Num
  drop if oshpd_id==.
  bys oshpd_id: gen obs=_n
  drop if obs>1
  drop obs
  save oshpd_financial_`y', replace
  
  insheet using "${DATA_OSHPD}Annual Utilization Data\FY`y'_A.txt", clear tab
  drop if oshpd_id==.
  bys oshpd_id: gen obs=_n
  drop if obs>1
  drop obs
  save oshpd_util_`y'a, replace  

  insheet using "${DATA_OSHPD}Annual Utilization Data\FY`y'_B.txt", clear tab
  drop if oshpd_id==.
  bys oshpd_id: gen obs=_n
  drop if obs>1
  drop obs  
  save oshpd_util_`y'b, replace
  
  use oshpd_util_`y'a, clear
  merge 1:1 oshpd_id using oshpd_util_`y'b, nogenerate 
  save oshpd_util_`y', replace

  use oshpd_util_`y', clear
  merge 1:1 oshpd_id using oshpd_financial_`y', nogenerate keep(match)
  drop mcare_provider_no aclaims_no equip_* hospice_*
  save oshpd_`y', replace
}

use oshpd_2008, clear
gen Year=2008
forvalues y=2009/2015 {
  append using oshpd_`y'
  replace Year=`y' if Year==.
}
save "${DATA_FINAL}OSHPD_Data.dta", replace
