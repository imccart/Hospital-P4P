local d = "$S_DATE"
log using "$log\DMB_extensions_`d'.log", replace
********************************************************************************
*Trend Analysis
********************************************************************************
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
foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all

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

foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all

foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if any_forprofit==1, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 if any_forprofit==1, absorb(provider_number) cluster(provider_number)
est sto h_trend_`y'
qui: test evY2 evY3 evY4 evY5 evY6
scalar `y'_penalty=r(p)
}
*** FORprofit
esttab h_trend_ln_mcaid_discharges h_trend_ln_mcare_discharges h_trend_ln_total_discharges h_trend_ln_other_discharges h_trend_pindex h_trend_lnprice  h_trend_lnprice_hcci , b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01)

foreach y of varlist $DIS_OUTCOMES $PRICE_OUTCOMES {
scalar list `y'_penalty
}
est clear
scalar drop _all


********************************************************************************
*** Robustness 										
********************************************************************************

*1.) County FE
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear


*2.) No FE
foreach y of global DIS_OUTCOMES{
qui: reg `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reg `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6,  cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear


* 3.) Controlling for Medicaid Expansion States
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty expand i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  expand i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear



* 4.)Controlling for hcahps ratings
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty hcahps_rating i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty hcahps_rating i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear


*5.) Now just for those hospitals that are never .

foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if never_vi==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if never_vi==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear



*6.) Now just years<2014.

foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if Year<2014, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if Year<2014, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear


*7.) Dropping FY2012
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if Year~=2012, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if Year~=2012, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear

*8.) Controlling for log case mix

foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 lncmi , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 lncmi, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 

est clear



cap log close
