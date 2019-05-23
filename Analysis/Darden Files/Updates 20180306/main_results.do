local d = "$S_DATE"
log using "$log\DMB_main_results_`d'.log", replace
**************************************************************
* 1.) Extensive Margin FE results
**************************************************************
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
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
gen bonus=(amt_penalty<0)
xtile rank1=amt_penalty if bonus==1, n(2)
xtile rank2=amt_penalty if bonus==0, n(2)

gen high_bonus=(rank1==1)
gen low_pen=(rank2==1)
gen high_pen=(rank2==2)

*a.)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' high_bonus low_pen high_pen hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y'  high_bonus low_pen high_pen hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, keep( high_bonus low_pen high_pen) b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear


*b.)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' quart1 quart2 quart3 quart4  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' quart1 quart2 quart3 quart4   hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, keep(quart1 quart2 quart3 quart4) b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
*c.)
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' amt_penalty  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  , absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' amt_penalty   hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 , absorb(provider_number) cluster(provider_number)
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
tab time if first==3
qui: reghdfe `y' ev4 ev6 ev7 ev8 ev9 hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (first==3 | time==0), absorb(provider_number) cluster(provider_number)
est sto h3_`y'
coefplot h3_`y', keep(ev4 ev6 ev7 ev8 ev9) vert ytitle(Coefficient) yline(0) xline(1.2) xtitle(Period)  coeflabels(ev4="-1" ev6="First" ev7="+1" ev8="+2" ev9="+3")
graph save `y'_ev_2012
qui: reghdfe  `y' ev3 ev4 ev6 ev7 ev8  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (first==4 | time==0), absorb(provider_number) cluster(provider_number)
est sto h4_`y'
coefplot h4_`y', keep(ev3 ev4 ev6 ev7 ev8) vert ytitle(Coefficient) yline(0) xline(2.2) xtitle(Period)  coeflabels(ev3="-2" ev4="-1" ev6="First" ev7="+1" ev8="+2")
graph save `y'_ev_2013
qui: reghdfe  `y' ev2 ev3 ev4 ev6 ev7  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (first==5 | time==0), absorb(provider_number) cluster(provider_number)
est sto h5_`y'
coefplot h5_`y', keep(ev2 ev3 ev4 ev6 ev7) vert ytitle(Coefficient) yline(0) xline(3.2) xtitle(Period) coeflabels(ev2= "-3" ev3="-2" ev4="-1" ev6="First" ev7="+1")
graph save `y'_ev_2014
qui: reghdfe  `y' ev1 ev2 ev3 ev4 ev6  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (first==6 | time==0), absorb(provider_number) cluster(provider_number)
est sto h6_`y'
coefplot h6_`y', keep(ev1 ev2 ev3 ev4 ev6) vert ytitle(Coefficient) yline(0) xline(4.2) xtitle(Period) coeflabels(ev1= "-4" ev2= "-3" ev3="-2" ev4="-1" ev6="First")
graph save `y'_ev_2015
qui: reghdfe  `y' ev4 ev6  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6 if (time>-2 & time<2), absorb(provider_number) cluster(provider_number)
est sto hbal_`y'
coefplot hbal_`y', keep(ev4 ev6) vert ytitle(Coefficient) yline(0) xline(1.2) xtitle(Period)  coeflabels(ev4="-1" ev6="First")
graph save `y'_ev_bal
qui: reghdfe  `y' $events  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est sto hall_`y'
coefplot hall_`y', keep(ev1 ev2 ev3 ev4 ev6 ev7 ev8 ev9) vert ytitle(Coefficient) yline(0) xline(4.2) xtitle(Period)  coeflabels(ev1="-4" ev2="-3" ev3="-2" ev4="-1" ev6="First" ev7="+1" ev8="+2" ev9="+3")
graph save `y'_ev_all
est clear
}

foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' ev4 ev6 ev7 ev8 ev9  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS} m_*  y2 y3 y4 y5 y6 if (first==3 | time==0), absorb(provider_number) cluster(provider_number)
est sto h3_`y'
coefplot h3_`y', keep(ev4 ev6 ev7 ev8 ev9) vert ytitle(Coefficient) yline(0) xline(1.2) xtitle(Period)  coeflabels(ev4="-1" ev6="First" ev7="+1" ev8="+2" ev9="+3")
graph save `y'_ev_2012
qui: reghdfe  `y' ev3 ev4 ev6 ev7 ev8  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (first==4 | time==0), absorb(provider_number) cluster(provider_number)
est sto h4_`y'
coefplot h4_`y', keep(ev3 ev4 ev6 ev7 ev8) vert ytitle(Coefficient) yline(0) xline(2.2) xtitle(Period)  coeflabels(ev3="-2" ev4="-1" ev6="First" ev7="+1" ev8="+2")
graph save `y'_ev_2013
qui: reghdfe  `y' ev2 ev3 ev4 ev6 ev7  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (first==5 | time==0), absorb(provider_number) cluster(provider_number)
est sto h5_`y'
coefplot h5_`y', keep(ev2 ev3 ev4 ev6 ev7) vert ytitle(Coefficient) yline(0) xline(3.2) xtitle(Period) coeflabels(ev2= "-3" ev3="-2" ev4="-1" ev6="First" ev7="+1")
graph save `y'_ev_2014
qui: reghdfe  `y' ev1 ev2 ev3 ev4 ev6  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (first==6 | time==0), absorb(provider_number) cluster(provider_number)
est sto h6_`y'
coefplot h6_`y', keep(ev1 ev2 ev3 ev4 ev6) vert ytitle(Coefficient) yline(0) xline(4.2) xtitle(Period) coeflabels(ev1= "-4" ev2= "-3" ev3="-2" ev4="-1" ev6="First")
graph save `y'_ev_2015
qui: reghdfe  `y' ev4 ev6  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (time>-2 & time<2), absorb(provider_number) cluster(provider_number)
est sto hbal_`y'
coefplot hbal_`y', keep(ev4 ev6) vert ytitle(Coefficient) yline(0) xline(1.2) xtitle(Period)  coeflabels(ev4="-1" ev6="First")
graph save `y'_ev_bal
qui: reghdfe  `y' $events  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
est sto hall_`y'
coefplot hall_`y', keep(ev1 ev2 ev3 ev4 ev6 ev7 ev8 ev9) vert ytitle(Coefficient) yline(0) xline(4.2) xtitle(Period)  coeflabels(ev1="-4" ev2="-3" ev3="-2" ev4="-1" ev6="First" ev7="+1" ev8="+2" ev9="+3")
graph save `y'_ev_all
est clear
}





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
	qui: reghdfe lnprice_hcci_`d' net_penalty   hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
	est store h_lnprice_hcci_`d'
	esttab h_lnprice_hcci_`d', b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
    est clear
	qui: reghdfe lnprice_hcci_`d' amt_penalty   hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6 if (everpen==1 ), absorb(provider_number) cluster(provider_number)
	est store h_lnprice_hcci_`d'
	esttab h_lnprice_hcci_`d', b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
restore
}
**************************************************************
* 5.) Nonprofit vs. for-profit
**************************************************************
foreach y of global DIS_OUTCOMES{
qui: reghdfe `y' net_penalty  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  if any_forprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui:reghdfe `y' net_penalty   hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if any_forprofit==0, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
*** Nonprofit
esttab h_ln_mcaid_discharges h_ln_mcare_discharges h_ln_total_discharges h_ln_other_discharges h_pindex h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear
foreach y of global DIS_OUTCOMES{
qui:reghdfe `y' net_penalty  hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6  if any_forprofit==1, absorb(provider_number) cluster(provider_number)
est store h_`y'
}
foreach y of global PRICE_OUTCOMES{
qui: reghdfe `y' net_penalty   hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if any_forprofit==1, absorb(provider_number) cluster(provider_number)
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
qui: reghdfe `y' net_penalty ps2 ps3 ps4 net_penalty2 net_penalty3 net_penalty4   hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size  ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS}  m_*  y2 y3 y4 y5 y6  if fips_power~=., absorb(provider_number fips) cluster(provider_number)
est store h_`y'
}
esttab h_lnprice  h_lnprice_hcci, b(%5.3f) se(%5.3f) star(* 0.1 ** 0.05 *** 0.01) 
est clear



cap log close
