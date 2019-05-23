********************************************************************************
*  	Title: 		"Do Hospitals Cost-Shift? New Evidence from the Hospital 		   	
*			 		Readmission Reduction Program"
*  	Authors: 	Michael Darden, Ian McCarthy, and Eric Barrette		
*	Date:		July 1st, 2017
*   Updated:	October, 30th 2017
*	Notes: 		This do-file executes all analysis for the paper.  The main data input is final_sample.dta.  
*				When adding price data, the relevant variables on which to merge are provider_number and year.  Please
*				make sure that there are no missing values for prices.  If necessary, delete all provider_number records
*				if that provider has any missing value of price - we want a balanced sample. After merging price data, 
*				the cleaned dependent variables should be placed in the global "PRICE_OUTCOMES."		 
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

local d = "$S_DATE"
log using "$log\03 Hosp price - DMB_Results_`d'.log", replace
**************************************************************

*Load data
use "$output\Reg data - all hosp price.dta", clear
drop if balanced == 0

use HRRP_Final_Data.dta

gen ln_mcaid_discharges = ln(mcaid_discharges)
gen ln_mcare_discharges = ln(mcare_discharges)
gen ln_total_discharges = ln(total_discharges)
gen ln_other_discharges = ln(other_discharges)
replace amt_penalty=amt_penalty/1000


*set globals*
xtset provider_number Year 

encode state, gen(st)

global COUNTY_VARS 		TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black Income_50to75 ///
						Income_75to100 Income_100to150 Income_150plus Educ_HSGrad Educ_Bach 
global HOSPITAL_VARS 	teach1 teach2 System Nonprofit Profit Labor_Nurse Labor_Other ///
						Beds	
global MISSING 			m_census m_sys m_lnurse m_lother 										
global DIS_OUTCOMES		ln_mcaid_discharges ln_mcare_discharges ln_total_discharges ln_other_discharges pindex medicaid_share medicare_share other_share public_share
global PRICE_OUTCOMES	lnprice lnprice_hcci 
global NOMISSING		net_penalty hsa_monopoly hsa_duopoly hsa_triopoly fips_monopoly fips_duopoly fips_triopoly ///
						medicaid_share medicare_share public_share other_share pindex Profit lncmi
********************************************************************************
*** Table 1: Summary Statistics by whether a hospital is ever penalized
********************************************************************************
qui: estpost ttest $NOMISSING , by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest fips_power1 fips_power2 fips_power fips_size , by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest $COUNTY_VARS if m_census==0, by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest teach1 teach2 System Nonprofit if m_sys==0, by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest Labor_Nurse if m_lnurse==0, by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest Labor_Other if m_lother==0, by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest lnc_p_d if m_p_d==0, by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest op_rev if m_op==0, by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest $PRICE_OUTCOMES if m_op==0, by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))
********************************************************************************
*** Table 2: Demonstration of penalties and prices over time
********************************************************************************
tabstat net_penalty  $PRICE_OUTCOMES, by(Year) f(%5.3f)
tabstat amt_penalty, by(Year) f(%5.3f)
*tabstat price price_hcci, by(Year) f(%5.2f) stat(mean sd)
tabstat price, by(Year) f(%5.2f) stat(mean sd)
********************************************************************************
*** Table 3: FE models along with p-values for trends tests.
********************************************************************************

**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear

**** Now Penalty Amount conditional on (everpen==1)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1 ) , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1 ), absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear

****Now the same with variable trends:
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
esttab h_trend_ln_mcaid_discharges h_trend_ln_mcare_discharges h_trend_ln_total_discharges h_trend_ln_other_discharges h_trend_pindex h_trend_lnprice  h_trend_lnprice_hcci , b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)
esttab h_trend_medicaid_share h_trend_medicare_share h_trend_other_share h_trend_public_share , b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)
foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all


**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if (everpen==1 ), absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if (everpen==1 ), absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
esttab h_trend_ln_mcaid_discharges h_trend_ln_mcare_discharges h_trend_ln_total_discharges h_trend_ln_other_discharges h_trend_pindex h_trend_lnprice  h_trend_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)
esttab h_trend_medicaid_share h_trend_medicare_share h_trend_other_share h_trend_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)

foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all

********************************************************************************
*** Table 4: FE models by for profit status with p-values for trends tests
********************************************************************************

***** Just NON-PROFITS


**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  if any_forprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if any_forprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
*** Nonprofit
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1) & any_forprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1 )  & any_forprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
*** Nonprofit
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

****Now the same with variable trends:
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if any_forprofit==0, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if any_forprofit==0, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
*** Nonprofit
esttab h_trend_ln_mcaid_discharges h_trend_ln_mcare_discharges h_trend_ln_total_discharges h_trend_ln_other_discharges h_trend_pindex h_trend_lnprice  h_trend_lnprice_hcci , b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)
esttab h_trend_medicaid_share h_trend_medicare_share h_trend_other_share h_trend_public_share , b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)

foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all


**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if (everpen==1) & any_forprofit==0, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if (everpen==1 ) & any_forprofit==0, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
*** Nonprofit
esttab h_trend_ln_mcaid_discharges h_trend_ln_mcare_discharges h_trend_ln_total_discharges h_trend_ln_other_discharges h_trend_pindex h_trend_lnprice  h_trend_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)
esttab h_trend_medicaid_share h_trend_medicare_share h_trend_other_share h_trend_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)

foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all






***** Just FOR-PROFITS


**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  if any_notforprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if any_notforprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
*** FORprofit
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1 ) & any_notforprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1)  & any_notforprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
*** FORprofit
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

****Now the same with variable trends:
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if any_notforprofit==0, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if any_notforprofit==0, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
*** FORprofit
esttab h_trend_ln_mcaid_discharges h_trend_ln_mcare_discharges h_trend_ln_total_discharges h_trend_ln_other_discharges h_trend_pindex h_trend_lnprice  h_trend_lnprice_hcci , b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)
esttab h_trend_medicaid_share h_trend_medicare_share h_trend_other_share h_trend_public_share , b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)

foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all


**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if (everpen==1) & any_notforprofit==0, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if (everpen==1 ) & any_notforprofit==0, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
*** FORprofit
esttab h_trend_ln_mcaid_discharges h_trend_ln_mcare_discharges h_trend_ln_total_discharges h_trend_ln_other_discharges h_trend_pindex h_trend_lnprice  h_trend_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)
esttab h_trend_medicaid_share h_trend_medicare_share h_trend_other_share h_trend_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)

foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all



********************************************************************************
*** Table 5: DDD Estimators											
********************************************************************************
** First by Market Share for the small markets
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty##i.fips_power1  ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if fips_power1~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty##i.fips_power1   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power1~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear
** Market Share for the big markets
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty##i.fips_power2  ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if fips_power2~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty##i.fips_power2    ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power2~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear


** Second, by payer mix, following Wu(2010)
xtile psper=public_share, n(4)
tab psper, gen(ps)
for num 2/4: gen net_penaltyX=psX*net_penalty
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty ps2 ps3 ps4 net_penalty2 net_penalty3 net_penalty4  i.fips_power i.fips_size  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear

********************************************************************************
*** Table 6: Robustness 										
********************************************************************************

*1.) County FE
**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1 ), absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1 ), absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

*2.) No FE
**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reg `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reg `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6,  cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reg `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1 ),  cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reg `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1 ),  cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

* 3.) Controlling for Medicaid Expansion States
**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty expand i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  expand i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty  expand i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1 ), absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  expand i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1 ), absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

* 4.)Controlling for hcahps ratings
**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty hcahps_rating i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty hcahps_rating i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty hcahps_rating i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1 ), absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty hcaphs_rating i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1), absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

*5.) Now just for those hospitals that are never .

**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if never_vi==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if never_vi==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1 ) &  never_vi==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1) &  never_vi==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

*6.) Now just years<2014.

**** Start by looking at just net_penalty
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if Year<2014, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if Year<2014, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

**** Now Penalty Amount conditional on (everpen==1 & amt_penalty>=0)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (everpen==1 ) &  Year<2014, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1 ) &  Year<2014, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share h_medicare_share h_other_share h_public_share, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear
********************************************************************************
*** Table 7: Condition Specific Analysis 										
********************************************************************************
*** Loop through conditions.  "CONDITION`d'PRICE" is the place holder.
/*
MDC reference:
0 - all admissions
1 - Nervous system
4 - Respiratory system
5 - Circulatory system
8 - Musculoskeletal system and connective tissue
14 - Pregnancy, childbirth, puerperium
15 - Newborns and other neonates
*/

foreach d in 1 4 5 8 14 15 {
preserve
	
	drop if lnprice_hcci_`d' == 0
	bysort aha_hnpi: egen check = total(balanced) 
	assert check == 5
	drop check

	di "* * * * * * * * Output for MDC: `d' * * * * * * * *"
	
	*Average price and MDC price of MDC sample
	tabstat price_hcci price_hcci_`d', by(Year) f(%5.2f)

	*Baseline Model
	qui: reghdfe lnprice_hcci_`d' net_penalty  i.fips_power i.fips_size  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
	est store h_lnprice_hcci_`d'
	esttab h_lnprice_hcci_`d', b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
    est clear
	qui: reghdfe lnprice_hcci_`d' amt_penalty  i.fips_power i.fips_size  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1 ), absorb(provider_number) cluster(provider_number)
	est store h_lnprice_hcci_`d'
	esttab h_lnprice_hcci_`d', b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

	
	* Market share triple diff for small markets
	qui: reghdfe lnprice_hcci_`d' net_penalty##i.fips_power1 ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power1~=., absorb(provider_number fips) cluster(provider_number)
	est store h_lnprice_hcci_`d'
	esttab h_lnprice_hcci_`d', b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
	est clear
	* Market share triple diff for big markets
	qui: reghdfe lnprice_hcci_`d' net_penalty##i.fips_power2   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power2~=., absorb(provider_number fips) cluster(provider_number)
	est store h_lnprice_hcci_`d'
	esttab h_lnprice_hcci_`d', b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
	est clear
	
	* Payer Mix triple diff
	qui: reghdfe lnprice_hcci_`d'  net_penalty ps2 ps3 ps4 net_penalty2 net_penalty3 net_penalty4  i.fips_power i.fips_size  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power~=., absorb(provider_number fips) cluster(provider_number)
	est store h_lnprice_hcci_`d' 
	esttab h_lnprice_hcci_`d' , b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
	est clear

restore
}

capture log close
*END
