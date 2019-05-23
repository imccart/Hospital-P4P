********************************************************************************
*  	Title: 		"Do Hospitals Cost-Shift? New Evidence from the Hospital 		   	
*			 		Readmission Reduction Program"
*  	Authors: 	Michael Darden, Ian McCarthy, and Eric Barrette		
*	Date:		July 1st, 2017
*   Updated:	July 3rd, 2017
*	Notes: 		This do-file takes HRRP_Final_Data.dta and produces final_sample.dta.
* 				The sample is constructed to have no missing values.  I create missing
*				binary variables for all independent variables that are missing.
********************************************************************************
clear
cd "/Users/darden/Dropbox/Research/Cost_shifting/Darden_McCarthy_HRRP/Data"
use HRRP_Final_Data.dta
count
by provider_number: gen c=_n
tab c if year==1
drop c
********************************************************************************
* First I impute share variables if missing with the within provider mean. I 
* drop observations if this is not possible.
********************************************************************************
sort provider_number
by provider_number: egen aid_avg=mean(medicaid_share)
by provider_number: egen are_avg=mean(medicare_share)
replace medicaid_share=aid_avg if medicaid_share==.
replace medicare_share=are_avg if medicare_share==.
replace public_share=medicaid_share+medicare_share if public_share==.
replace other_share=1-public_share if other_share==.
keep if other_share~=.
sum medicaid_share medicare_share public_share other_share
by provider_number: gen c=_n
tab c if year==1
drop c
********************************************************************************
* Next clean up the Market variables.  I drop observations if there is no market
* power information after trying to impute.				
********************************************************************************
global MKT	hsa_power fips_power hsa_monopoly hsa_duopoly hsa_triopoly fips_monopoly fips_duopoly fips_triopoly
count
sum $MKT
sort provider_number year
replace hsa_power=hsa_power[_n-1] if provider_number==provider_number[_n-1]
replace fips_power=fips_power[_n-1] if provider_number==provider_number[_n-1]
sum $MKT
drop if hsa_power==.
drop if fips_power==.
count
by provider_number: gen c=_n
tab c if year==1
drop c
tab hsa_power, gen(hsa_power_)
tab fips_power, gen(fips_power_)
********************************************************************************
* Next I drop those providers with a missing year.  This is the final sample.
********************************************************************************
sort provider_number year
by provider_number: gen temp=_n
by provider_number: egen max=max(temp)
tab max if year==1
keep if max==6
count
by provider_number: gen c=_n
tab c if year==1
drop c max

********************************************************************************
* Next I start working on the ind. variables. Fill in the fips code when missing.
********************************************************************************
replace fips=0 if fips==.
by provider_number: egen max=max(fips)
replace fips=max if fips==0
drop max 
********************************************************************************
* Next fill in the county variables.  The max of Emp_Fulltime is 938, and more
* are missing that other variables.  I drop it.
********************************************************************************
drop Emp_FullTime
global COUNTY_VARS 		TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black Income_50to75 ///
						Income_75to100 Income_100to150 Income_150plus Educ_HSGrad Educ_Bach 	
count						
sum $COUNTY_VARS
gen m_census=0
replace m_census=1 if TotalPop==.
foreach y of global COUNTY_VARS{
replace `y'=-99 if `y'==.
}
sum $COUNTY_VARS if m_census==0
sum $COUNTY_VARS if m_census==1
********************************************************************************
* Next clean up the hospital_variables and rename for future stored results
********************************************************************************
ren Teaching_Hospital1 teach1
ren Teaching_Hospital2 teach2
global HOSPITAL_VARS 	teach1 teach2 System Nonprofit Profit Labor_Nurse Labor_Other ///
						Beds VBP_adj
count
sum $HOSPITAL_VARS
replace VBP_adj=1 if year<4

gen m_sys=0
replace m_sys=1 if teach1==.
foreach y of varlist teach1 teach2 System Nonprofit {
replace `y'=-99 if `y'==.
}
sum teach1 teach2 System Nonprofit if m_sys==0
sum teach1 teach2 System Nonprofit if m_sys==1
gen m_lnurse=0
gen m_lother=0
replace m_lnurse=1 if Labor_Nurse==.
replace m_lother=1 if Labor_Other==.
foreach y of varlist Labor_Nurse Labor_Other {
replace `y'=-99 if `y'==.
}
sum Labor_Nurse if m_lnurse==0		
sum Labor_Nurse if m_lnurse==1	
sum Labor_Other if m_lother==0
sum Labor_Other if m_lother==1
********************************************************************************
* Finally clean up the price control variables
********************************************************************************
ren lncost_per_discharge lnc_p_d
count
global PRICE_VARS 		lncmi lnc_p_d op_rev
sum $PRICE_VARS
gen m_p_d=0
gen m_op=0
replace m_p_d=1 if lnc_p_d==.
replace m_op=1 if op_rev==.
foreach y of varlist lnc_p_d op_rev {
replace `y'=-99 if `y'==.
}
sum lnc_p_d if m_p_d==0
sum lnc_p_d if m_p_d==1
sum op_rev if m_op==0
sum op_rev if m_op==1
********************************************************************************
********************************************************************************
* Now collect missing terms and define samples
********************************************************************************
********************************************************************************
global missing m_census m_sys m_lnurse m_lother m_p_d m_op
gen sample_price=0
replace sample_price=1 if lnprice~=.
tab year, gen(y)
for num 1/6: gen evYX=everpen*yX
for num 1/6: gen mpX=yX*hsa_power
for num 1/6: gen monoX=yX*hsa_monopoly
for num 1/6: gen fips_mpX=yX*fips_power
for num 1/6: gen fips_monoX=yX*fips_monopoly
for num 1/6: gen nprX=yX*any_notforprofit
gen vbp_penalty = (VBP_adj<1)
gen vbp_rebate = (VBP_adj>1)


















save final_sample.dta, replace



