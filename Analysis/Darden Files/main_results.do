local d = "$S_DATE"
log using "$log\DMB_main_results_`d'.log", replace
**************************************************************
* 1.) Extensive Margin FE results
**************************************************************
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
**************************************************************
* 2.) Intensive Margin.  Three models:
* 		a.) Dummy out bonus vs. penalty
*		b.) Penalty quartiles
*		c.) Continuous RHS variable
**************************************************************
replace amt_penalty=0 if amt_penalty==. & post_period==0
gen bonus=(amt_penalty<0)
xtile rank=amt_penalty if post_period==1, n(4)
replace rank=0 if rank==. & post_period==0
tab rank, gen(quart)
*a.)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty bonus i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty bonus  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, keep(net_penalty bonus) b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
*b.)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' quart1 quart2 quart3 quart4 i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' quart1 quart2 quart3 quart4  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, keep(quart1 quart2 quart3 quart4) b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
*c.)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, keep(amt_penalty) b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
**************************************************************
* 3.) Event Study
**************************************************************
sort provider_number
gen low=.
replace low=year if net_penalty==1
by provider_number: egen first=min(low)
drop low
gen time=(year-first)+1
replace time=0 if everpen==0
tab time, gen(ev)
global events "ev1 ev2 ev3 ev4 ev6 ev7 ev8 ev9"
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' $events i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' $events  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice h_lnprice_hcci, keep($events) b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
reghdfe lnprice_hcci  $events  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est sto h_y
coefplot h_y, keep(ev1 ev2 ev3 ev4 ev6 ev7 ev8 ev9) vert ytitle(Coefficient) yline(0) xline(4.2) xtitle(Period) title(Event Study of Log Mean Payment) coeflabels(ev1="-4" ev2="-3" ev3="-2" ev4="-1" ev6="First" ev7="+1" ev8="+2" ev9="+3")
graph save event, replace
est clear
********************************************************************************
*** 4.) Condition Specific Analysis 										
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
restore
}
**************************************************************
* 5.) Nonprofit vs. for-profit
**************************************************************
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  if any_forprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui:reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if any_forprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
*** Nonprofit
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
foreach y of global DIS_OUTCOMES{
qui:reghdfe `y' net_penalty i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  if any_forprofit==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty  i.fips_power i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if any_forprofit==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
*** FORprofit
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
**************************************************************
* 6.) DDD by Payer Mix
**************************************************************
xtile psper=public_share, n(4)
tab psper, gen(ps)
for num 2/4: gen net_penaltyX=psX*net_penalty
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty ps2 ps3 ps4 net_penalty2 net_penalty3 net_penalty4  i.fips_power i.fips_size  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear



cap log close
