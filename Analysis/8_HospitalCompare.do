******************************************************************
**	Title:			Hospital Compare
**	Author:			Ian McCarthy
**	Date Created:	5/16/17
**	Date Updated:	9/15/17
**  Notes:			-- Updated on 9/15/17 to incorporate HCAHPS ratings and recommendation scores
******************************************************************
**cd "C:\Users\immccar\My Documents\"
cd "E:\"
global DATA_HOS "C:\Users\immccar\Professional\Research Data\Hospital Compare\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"

******************************************************************
/* Read in Hospital Compare Data from CMS */
******************************************************************
insheet using "${DATA_HOS}Hospital_Quality_2009.txt", clear comma
rename b_id MCRNUM

drop c_id d_id e_id f_id g_id h_id i_id providernumber
gen Year=2009
save temp_compare_2009, replace

insheet using "${DATA_HOS}Hospital_Quality_2010.txt", clear comma
rename b_id MCRNUM
foreach x of varlist hcahps_rating hcahps_recommend mortality_ha mortality_lower_ha mortality_upper_ha readmission_ha ///
   readmission_lower_ha readmission_upper_ha mortality_hf mortality_lower_hf mortality_upper_hf ///
   readmission_hf readmission_lower_hf readmission_upper_hf mortality_pneumonia mortality_lower_pneumonia ///
   mortality_upper_pneumonia readmission_pneumonia readmission_lower_pneumonia readmission_upper_pneumonia {
  replace `x'="" if `x'=="N/A"
  destring `x', replace
}

drop a_id c_id d_id e_id f_id g_id h_id i_id providernumber
gen Year=2010
save temp_compare_2010, replace

insheet using "${DATA_HOS}Hospital_Quality_2011.txt", clear comma
rename b_id MCRNUM
gen federal=(strpos(MCRNUM,"F")>0)
replace MCRNUM="" if federal==1
destring MCRNUM, replace
destring zipcode, replace
foreach x of varlist hcahps_rating hcahps_recommend mortality_ha mortality_lower_ha mortality_upper_ha readmission_ha ///
   readmission_lower_ha readmission_upper_ha mortality_hf mortality_lower_hf mortality_upper_hf ///
   readmission_hf readmission_lower_hf readmission_upper_hf mortality_pneumonia mortality_lower_pneumonia ///
   mortality_upper_pneumonia readmission_pneumonia readmission_lower_pneumonia readmission_upper_pneumonia {
  replace `x'="" if `x'=="N/A"
  destring `x', replace
}

drop a_id c_id d_id e_id f_id g_id h_id i_id providernumber
gen Year=2011
save temp_compare_2011, replace

insheet using "${DATA_HOS}Hospital_Quality_2012.txt", clear comma
rename b_id MCRNUM
gen federal=(strpos(MCRNUM,"F")>0)
replace MCRNUM="" if federal==1
destring MCRNUM, replace
destring zipcode, replace
foreach x of varlist hcahps_rating hcahps_recommend mortality_ha mortality_lower_ha mortality_upper_ha readmission_ha ///
   readmission_lower_ha readmission_upper_ha mortality_hf mortality_lower_hf mortality_upper_hf ///
   readmission_hf readmission_lower_hf readmission_upper_hf mortality_pneumonia mortality_lower_pneumonia ///
   mortality_upper_pneumonia readmission_pneumonia readmission_lower_pneumonia readmission_upper_pneumonia {
  replace `x'="" if `x'=="N/A" | `x'=="Not Available"
  destring `x', replace
}

drop a_id c_id d_id e_id f_id g_id h_id i_id providernumber
gen Year=2012
save temp_compare_2012, replace


insheet using "${DATA_HOS}Hospital_Quality_2013.txt", clear comma
rename b_id MCRNUM
gen federal=(strpos(MCRNUM,"F")>0)
replace MCRNUM="" if federal==1
destring MCRNUM, replace
destring zipcode, replace
foreach x of varlist hcahps_rating hcahps_recommend mortality_ha mortality_lower_ha mortality_upper_ha readmission_ha ///
   readmission_lower_ha readmission_upper_ha mortality_hf mortality_lower_hf mortality_upper_hf ///
   readmission_hf readmission_lower_hf readmission_upper_hf mortality_pneumonia mortality_lower_pneumonia ///
   mortality_upper_pneumonia readmission_pneumonia readmission_lower_pneumonia readmission_upper_pneumonia {
  replace `x'="" if `x'=="N/A" | `x'=="Not Available"
  destring `x', replace
}

drop a_id c_id d_id e_id f_id g_id h_id i_id providernumber
gen Year=2013
save temp_compare_2013, replace

insheet using "${DATA_HOS}Hospital_Quality_2014.txt", clear comma
rename b_id MCRNUM
gen federal=(strpos(MCRNUM,"F")>0)
replace MCRNUM="" if federal==1
destring MCRNUM, replace
destring zipcode, replace
foreach x of varlist hcahps_rating hcahps_recommend mortality_ha mortality_lower_ha mortality_upper_ha readmission_ha ///
   readmission_lower_ha readmission_upper_ha mortality_hf mortality_lower_hf mortality_upper_hf ///
   readmission_hf readmission_lower_hf readmission_upper_hf mortality_pneumonia mortality_lower_pneumonia ///
   mortality_upper_pneumonia readmission_pneumonia readmission_lower_pneumonia readmission_upper_pneumonia {
  replace `x'="" if `x'=="N/A" | `x'=="Not Available"
  destring `x', replace
}

drop a_id c_id d_id e_id f_id g_id h_id i_id providerid
gen Year=2014
save temp_compare_2014, replace

insheet using "${DATA_HOS}Hospital_Quality_2015.txt", clear comma
rename b_id MCRNUM
gen federal=(strpos(MCRNUM,"F")>0)
replace MCRNUM="" if federal==1
destring MCRNUM, replace
destring zipcode, replace
foreach x of varlist hcahps_rating hcahps_recommend mortality_ha mortality_lower_ha mortality_upper_ha readmission_ha ///
   readmission_lower_ha readmission_upper_ha mortality_hf mortality_lower_hf mortality_upper_hf ///
   readmission_hf readmission_lower_hf readmission_upper_hf mortality_pneumonia mortality_lower_pneumonia ///
   mortality_upper_pneumonia readmission_pneumonia readmission_lower_pneumonia readmission_upper_pneumonia {
  replace `x'="" if `x'=="N/A" | `x'=="Not Available"
  destring `x', replace
}

drop a_id c_id d_id e_id f_id g_id h_id i_id providerid
gen Year=2015
save temp_compare_2015, replace


** Append all years
use temp_compare_2009, clear
append using temp_compare_2010
append using temp_compare_2011
append using temp_compare_2012
append using temp_compare_2013
append using temp_compare_2014
append using temp_compare_2015

drop if MCRNUM==.
keep MCRNUM Year mortality_ha mortality_lower_ha mortality_upper_ha readmission_ha ///
   readmission_lower_ha readmission_upper_ha mortality_hf mortality_lower_hf mortality_upper_hf ///
   readmission_hf readmission_lower_hf readmission_upper_hf mortality_pneumonia mortality_lower_pneumonia ///
   mortality_upper_pneumonia readmission_pneumonia readmission_lower_pneumonia readmission_upper_pneumonia ///
   hcahps_rating hcahps_recommend
sort MCRNUM Year

** add national readmission rates from hospital compare
gen natl_ami=19.9 if Year==2009
gen natl_hf=24.5 if Year==2009
gen natl_pn=18.2 if Year==2009
replace natl_ami=19.9 if Year==2010
replace natl_hf=24.7 if Year==2010
replace natl_pn=18.3 if Year==2010
replace natl_ami=19.8 if Year==2011
replace natl_hf=24.8 if Year==2011
replace natl_pn=18.4 if Year==2011
replace natl_ami=19.7 if Year==2012
replace natl_hf=24.7 if Year==2012
replace natl_pn=18.5 if Year==2012
replace natl_ami=18.3 if Year==2013
replace natl_hf=23.0 if Year==2013
replace natl_pn=17.6 if Year==2013
replace natl_ami=17.8 if Year==2014
replace natl_hf=22.7 if Year==2014
replace natl_pn=17.3 if Year==2014
replace natl_ami=17.0 if Year==2015
replace natl_hf=22.0 if Year==2015
replace natl_pn=16.9 if Year==2015

** calculate ratios
gen ami_ratio=readmission_ha/natl_ami
rename MCRNUM provider_number

** Save final dataset
keep provider_number Year hcahps_rating hcahps_recommend
rename Year CYear
save "${DATA_FINAL}Hospital_Compare.dta", replace

