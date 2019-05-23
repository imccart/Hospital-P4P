**set logtype text
cd "E:\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"
global DATA_MA "C:\Users\immccar\Professional\Research Projects\Multimarket Contact in Medicare Advantage\Data\"
global MA_CODE "C:\Users\immccar\Professional\Research Projects\Multimarket Contact in Medicare Advantage\Analysis\"


***********************************************************************************
** Title:	      Build MA Dataset for Measures of Insurer Competition
** Author:        Ian McCarthy
** Date created:  4/20/2017
** Date edited:   6/2/2017
** Notes:		  MA data come from prior work on "Multimarket Contact in MA"
***********************************************************************************
set more off
use "${DATA_MA}MA_Data.dta", clear
keep if organizationtype=="Local CCP" | organizationtype=="MSA" | organizationtype=="PFFS" ///
   | organizationtype=="RFB - PFFS" | organizationtype=="Regional CCP"
do "${MA_CODE}Insurer_Classification.do"


replace Insurer=parentorganization if Insurer=="" & parentorganization!="."
replace Insurer=organizationmarketingname if Insurer==""
drop if Insurer==""
egen Insurer_Group=group(Insurer)

** Calculate share of each insurer
bys Insurer_Group fips year: egen ins_enroll=sum(avg_enrollment)
bys Insurer_Group fips year: gen obs=_n
gen ins_share=ins_enroll/avg_enrolled
drop if ins_share==0
keep if obs==1

** Calculate HHI and number of insurers
gen ins_share2=ins_share^2
bys fips year: egen HHI_FIPS=sum(ins_share2)
bys fips year: gen ins_count=_N

** Drop markets with "bad" data (i.e., shares too big or HHI too big)
bys fips year: egen max_share=max(ins_share)
drop if max_share>1
bys fips year: egen max_hhi=max(HHI_FIPS)
drop if max_hhi>1

** Collapse to market-level
bys fips year: gen fips_obs=_n
keep if fips_obs==1

** Save final dataset
rename year Year
keep fips Year ins_count HHI_FIPS max_share avg_enrolled
save "${DATA_FINAL}MA_Market_Data.dta", replace
