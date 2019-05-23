********************************************************************************
*  	Title: 		"Hospital Pricing and Public Payments"
*  	Authors: 	Michael Darden, Ian McCarthy, and Eric Barrette		
*	Date:		February 16th, 2018
*   Updated:	February 16th, 2018
*	Notes: 		I have broken the do-file into the following sub-files:		
*					1.) Summary Statistics
*					2.) Main Results
*					3.) Extensions
*				Each sub-file opens and closes its own log file.  
********************************************************************************
clear
capture log close
set more off
pause on
set type double 
*set paths*
gl script   = "H:\~Research\Cost shifting\Analysis\Scripts"
gl main     = subinstr("$script", "\Scripts", "", .)
gl root     = subinstr("$main", "\Analysis", "", .)

gl input   "$main\Input"
gl output  "$main\Output"
gl log     "$main\Logs"
gl temp    "$main\Temp"

gl data    "$root\Data\Output"
**************************************************************
*Load data
*use "$output\Reg data - all hosp price.dta", clear
*drop if balanced == 0
use HRRP_Final_Data.dta
gen ln_mcaid_discharges = ln(mcaid_discharges)
gen ln_mcare_discharges = ln(mcare_discharges)
gen ln_total_discharges = ln(total_discharges)
gen ln_other_discharges = ln(other_discharges)
xtset provider_number Year 
encode state, gen(st)
global COUNTY_VARS 		TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black Income_50to75 ///
						Income_75to100 Income_100to150 Income_150plus Educ_HSGrad Educ_Bach 
global HOSPITAL_VARS 	post_period teach1 teach2 System Nonprofit Profit Labor_Nurse Labor_Other ///
						Beds	
global MISSING 			m_census m_sys m_lnurse m_lother 										
global DIS_OUTCOMES		ln_mcaid_discharges ln_mcare_discharges ln_total_discharges ln_other_discharges pindex 
global PRICE_OUTCOMES	lnprice lnprice_hcci 

global NOMISSING		post_period net_penalty hsa_monopoly hsa_duopoly hsa_triopoly fips_monopoly fips_duopoly fips_triopoly ///
						medicaid_share medicare_share public_share other_share pindex Profit lncmi

						
do sum_stat.do
do main_results.do
do extensions.do





