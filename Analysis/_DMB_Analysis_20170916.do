********************************************************************************
*  	Title: 		"Do Hospitals Cost-Shift? New Evidence from the Hospital 		   	
*			 		Readmission Reduction Program"
*  	Authors: 	Michael Darden, Ian McCarthy, and Eric Barrette		
*	Date:		July 1st, 2017
*   Updated:	September 15th, 2017
*	Notes: 		This do-file executes all analysis for the paper.  The main data input is final_sample.dta.  
*				When adding price data, the relevant variables on which to merge are provider_number and year.  Please
*				make sure that there are no missing values for prices.  If necessary, delete all provider_number records
*				if that provider has any missing value of price - we want a balanced sample. After merging price data, 
*				the cleaned dependent variables should be placed in the global "PRICE_OUTCOMES."		 
********************************************************************************
clear
cap log close
cd "/Users/darden/Dropbox/Research/Cost_shifting/Darden_McCarthy_HRRP/Analysis"
log using DMB_Results.log, replace
use HRRP_Final_Data.dta, clear
lkj;
xtset provider_number Year
*global MKT				fips_monopoly fips_duopoly fips_triopoly HHI_FIPS
global MKT
global POWER			fips_power_2 fips_power_3 
global COUNTY_VARS 		TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black Income_50to75 ///
						Income_75to100 Income_100to150 Income_150plus Educ_HSGrad Educ_Bach 
global HOSPITAL_VARS 	teach1 teach2 System Nonprofit Profit Labor_Nurse Labor_Other ///
						Beds vbp_rebate	
global MISSING 			m_census m_sys m_lnurse m_lother m_p_d m_op											
global SHARE_OUTCOMES	medicaid_share medicare_share public_share other_share pindex
global PRICE_OUTCOMES	lnprice 
global NOMISSING		pen_both pen_one hsa_monopoly hsa_duopoly hsa_triopoly fips_monopoly fips_duopoly fips_triopoly ///
						medicaid_share medicare_share public_share other_share pindex Profit vbp_rebate lncmi
********************************************************************************
*** Table 1: Summary Statistics by whether a hospital is ever penalized
********************************************************************************
qui: estpost ttest $NOMISSING , by(everpen)
esttab ., cell((mu_1(fmt(3)  label(Never)) mu_2(label(Ever)) p))

qui: estpost ttest hsa_power_1 hsa_power_2 hsa_power_3 fips_power_1 fips_power_2 fips_power_3 , by(everpen)
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
tabstat pen_none pen_one pen_both  $PRICE_OUTCOMES, by(Year) f(%5.3f)

**tabstat price_hcci procedure_price1 ... procedure_priceN , by(Year) f(%5.3f)
********************************************************************************
*** Table 3: FE models along with p-values for trends tests.
********************************************************************************
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one $POWER  ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_medicaid_share h_medicare_share h_public_share h_other_share h_pindex h_lnprice, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6  $POWER ${COUNTY_VARS} ${HOSPITAL_VARS} ${MKT} m_*, absorb(provider_number fips) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6   $POWER ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} ${MKT} m_*, absorb(provider_number fips) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
esttab h_trend_medicaid_share h_trend_medicare_share h_trend_public_share h_trend_other_share h_trend_pindex h_trend_lnprice, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)
foreach y of varlist $SHARE_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all
********************************************************************************
*** Table 4: FE models by for profit status with p-values for trends tests
********************************************************************************
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_* y2 y3 y4 y5 y6  if any_forprofit==0, absorb(provider_number fips) cluster(provider_number)
est store h_`y'_nfp
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_* y2 y3 y4 y5 y6  if any_forprofit==1, absorb(provider_number fips) cluster(provider_number)
est store h_`y'_fp
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if any_forprofit==0, absorb(provider_number fips) cluster(provider_number)
est store h_`y'_nfp
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if any_forprofit==1, absorb(provider_number fips) cluster(provider_number)
est store h_`y'_fp
}
esttab h_medicaid_share_nfp h_medicare_share_nfp h_public_share_nfp h_other_share_nfp h_pindex_nfp h_lnprice_nfp, title("Nonprofit Hospitals") b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab h_medicaid_share_fp h_medicare_share_fp h_public_share_fp h_other_share_fp h_pindex_nfp h_lnprice_fp, title("For-profit Hospitals") b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6  $POWER ${COUNTY_VARS} ${HOSPITAL_VARS} ${MKT} m_* if any_forprofit==0, absorb(provider_number fips) cluster(provider_number)
est store th_`y'_nfp
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty_nfp=r(p)
qui: reghdfe `y' pen_both pen_one  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6  $POWER ${COUNTY_VARS} ${HOSPITAL_VARS} ${MKT} m_* if any_forprofit==1, absorb(provider_number fips) cluster(provider_number)
est store th_`y'_fp
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty_fp=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6  $POWER ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} ${MKT} m_* if any_forprofit==0, absorb(provider_number fips) cluster(provider_number)
est store th_`y'_nfp
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty_nfp=r(p)
qui: reghdfe `y' pen_both pen_one  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6  $POWER ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} ${MKT} m_* if any_forprofit==1, absorb(provider_number fips) cluster(provider_number)
est store th_`y'_fp
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty_fp=r(p)
}
esttab th_medicaid_share_nfp th_medicare_share_nfp th_public_share_nfp th_other_share_nfp th_pindex_nfp th_lnprice_nfp, title("Nonprofit Hospitals") b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
esttab th_medicaid_share_fp th_medicare_share_fp th_public_share_fp th_other_share_fp th_pindex_nfp th_lnprice_fp, title("For-profit Hospitals") b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
foreach y of varlist $SHARE_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty_nfp `y'_penalty_fp
}
est clear
scalar drop _all
********************************************************************************
*** Table 5: DDD Estimators											
********************************************************************************
** First by Market Share
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_one##i.fips_power_2 pen_one##i.fips_power_3 pen_both##i.fips_power_2 pen_both##i.fips_power_3 ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_one##i.fips_power_2 pen_one##i.fips_power_3 pen_both##i.fips_power_2 pen_both##i.fips_power_3 ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_medicaid_share h_medicare_share h_public_share h_other_share h_pindex h_lnprice, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
** Second, by payer mix, following Wu(2010)
xtile psper=public_share, n(4)
tab psper, gen(ps)
for num 2/4: gen ps_oneX=psX*pen_one
for num 2/4: gen ps_bothX=psX*pen_both
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_one pen_both ps2 ps3 ps4 ps_one* ps_both* ${POWER} ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_lnprice, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear

********************************************************************************
*** Table 6: Robustness 										
********************************************************************************
******** County specific linear time trends
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one $POWER  ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
esttab h_medicaid_share h_medicare_share h_public_share h_other_share h_pindex h_lnprice, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
******** Only years < 2014 to see if full ACA is confounding results
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one $POWER  ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if Year<2014, absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if Year<2014, absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
esttab h_medicaid_share h_medicare_share h_public_share h_other_share h_pindex h_lnprice, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
******** Controlling for hcahps ratings
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one hcahps_rating $POWER  ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 , absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one hcahps_rating $POWER ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
esttab h_medicaid_share h_medicare_share h_public_share h_other_share h_pindex h_lnprice, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
******** By Medicaid Expansion
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one $POWER  ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if expand==0 , absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if expand==0 , absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
esttab h_medicaid_share h_medicare_share h_public_share h_other_share h_pindex h_lnprice, title("Nonexpansion States") b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
foreach y of global SHARE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one $POWER  ${MKT} ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if expand==1 , absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' pen_both pen_one  $POWER ${MKT}  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if expand==1 , absorb(provider_number fips fips#year_trend) cluster(provider_number)
est store h_`y'
}
esttab h_medicaid_share h_medicare_share h_public_share h_other_share h_pindex h_lnprice, title("Expansion States") b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear




cap log close
