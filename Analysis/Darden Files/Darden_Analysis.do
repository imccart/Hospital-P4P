clear all
*cd "/Users/darden/Dropbox/Research/Cost_shifting/Darden_McCarthy_HRRP/Data"
cd "/Users/michaeldarden/Dropbox/Research/Cost_shifting/Darden_McCarthy_HRRP/Data"
cap log close
log using analysis.log, replace
*** Analysis of data file HRRP_Final_Data.dta
*** 6/16/2017

use HRRP_Final_Data_v12.dta
gen other_discharges=other_share*total_discharges
**** Introduce new variables
sort provider_number
by provider_number: egen everpen=max(penalty)
gen HRRP_everpen=HRRP*everpen
by provider_number: gen count=_n
tab everpen if count==1



replace Profit=0 if Profit==.
bys provider_number: egen any_forprofit=max(Profit)
bys provider_number: egen any_notforprofit=min(Profit)
gen lncmi=log(CMI)
gen lncost_per_discharge=log(tot_opexp/total_discharges)
gen op_rev=(tot_charges-ip_charges - intcare_charges - ancserv_charges)/tot_charges

gen Share_Zip=total_discharges/Zip_Discharges
gen Share_HRR=total_discharges/HRR_Discharges

qui sum Share_HRR
local mean_share=r(mean)
gen Half_Market=(Share_HRR>=`mean_share') if Share_HRR!=.
qui sum HHI_FIPS
local mean_hhi=r(mean)
gen Low_Insurance=(HHI_FIPS<=`mean_hhi') if HHI_FIPS!=.
gen Relative_Power=Half_Market*Low_Insurance
bys provider_number: egen mkt_power=max(Relative_Power) if Relative_Power!=.
gen mono_duo=(monopoly==1 | duopoly==1)



** Generate trend and alternate trend
replace HRRP=0 if Year==2012
tab Year, gen(y)
for num 1/6: gen evYX=everpen*yX
for num 1/6: gen mpX=yX*mkt_power
for num 1/6: gen monoX=yX*monopoly
for num 1/6: gen nprX=yX*any_notforprofit
**** Globals
global COUNTY_VARS TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black Income_50to75 Income_75to100 Income_100to150 Income_150plus ///
   Educ_HSGrad Educ_Bach Emp_FullTime
global HOSPITAL_VARS Teaching_Hospital1 Teaching_Hospital2 System Nonprofit Profit Labor_Nurse Labor_Other Beds
global OUTCOMES medicare_share other_share other_discharges total_discharges

*global PRICE_VARS lncmi lncost_per_discharge op_rev
global PRICE_VARS
global HOSPITAL_VARS Teaching_Hospital1 Teaching_Hospital2 System Labor_Nurse Labor_Other Beds

count
sum $OUTCOMES penalty ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly



***********************************************************************************
* Strategy:Focus first on contemporaneous effects 
* First estimate a FE model of outcomes on penalty.
*	This strategy is valid if there are no time-varying unobservables which are effecting the penalized hospitals relative to the nonpenalized.  
* 	Test for time-varying unobserved heterogeneity by testing for differential trends throughout by ever penalized *conditional* on penalty
* Second, estimate a scaled difference-in-differences in which we predict penalty with interactions between ever penalized and year.
*	Overid test is that pre-period interactions should not predict outcome in main equation
* Third, separate triple differences with mkt_power, and notforprofit.
* Fourth, repeat all of these models with lagged penalty as the X of interest.
***********************************************************************************
/* Examine contemporaneous change in distribution of patients */
foreach y of global OUTCOMES{
xtreg `y' penalty  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly, fe cluster(provider_number)
est store b_`y'
}
xtreg lnprice penalty  y2 y3 y4 y5 y6 ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly, fe cluster(provider_number)
** Test for time-varying unobservables
foreach y of global OUTCOMES{
xtreg `y' penalty  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly, fe cluster(provider_number)
test evY2 evY3 evY4 evY5 evY6
scalar `y'_fe_p=r(p)
}
xtreg lnprice penalty   y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly, fe cluster(provider_number)
test evY2 evY3 evY4 evY5 evY6
** Scaled Difference-in-differences
foreach y of global OUTCOMES{
xtivreg2  `y' y2 y3 y4 y5 y6   ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly (penalty = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
xtivreg2  `y' y2 y3 y4 y5 y6 evY2 evY3   ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly (penalty = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
test evY2 evY3
}
xtivreg2  lnprice y2 y3 y4 y5 y6   ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly (penalty = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
xtivreg2  lnprice y2 y3 y4 y5 y6 evY2 evY3   ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly (penalty = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
test evY2 evY3
** Triple Difference with mkt_share
foreach y of global OUTCOMES{
xtreg `y' penalty##mkt_power  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' penalty##mkt_power  y2 y3 y4 y5 y6 mp2 mp3 mp4 mp5 mp6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test mp2 mp3 mp4 mp5 mp6
est store b_`y'
}
xtreg lnprice penalty##mkt_power  y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice penalty##mkt_power  y2 y3 y4 y5 y6 mp2 mp3 mp4 mp5 mp6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test mp2 mp3 mp4 mp5 mp6
** Triple Difference with notforprofit
foreach y of global OUTCOMES{
xtreg `y' penalty##any_notforprofit  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' penalty##any_notforprofit  y2 y3 y4 y5 y6 npr2 npr3 npr4 npr5 npr6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test   npr2 npr3 npr4 npr5 npr6
est store b_`y'
}
xtreg lnprice penalty##any_notforprofit y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice penalty##any_notforprofit  y2 y3 y4 y5 y6  npr2 npr3 npr4 npr5 npr6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test  npr2 npr3 npr4 npr5 npr6
** Now repeat for lagged penalty 
gen lpen=l.pen
replace lpen=0 if Year==2010
/* Examine lagged change in distribution of patients */
foreach y of global OUTCOMES{
xtreg `y' lpen  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly, fe cluster(provider_number)
est store b_`y'
}
xtreg lnprice lpen  y2 y3 y4 y5 y6 ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly, fe cluster(provider_number)
** Test for time-varying unobservables
foreach y of global OUTCOMES{
xtreg `y' lpen  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly, fe cluster(provider_number)
test evY2 evY3 evY4 evY5 evY6
}
xtreg lnprice lpen   y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly, fe cluster(provider_number)
test evY2 evY3 evY4 evY5 evY6
** Scaled Difference-in-differences
foreach y of global OUTCOMES{
xtivreg2  `y' y2 y3 y4 y5 y6   ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly (lpen = evY2 evY3 evY4 evY5 evY6) , first fe cluster(provider_number)  
xtivreg2  `y' y2 y3 y4 y5 y6 evY2 evY3   ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly (lpen = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
test evY2 evY3
}
xtivreg2  lnprice y2 y3 y4 y5 y6   ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly (lpen = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
xtivreg2  lnprice y2 y3 y4 y5 y6 evY2 evY3   ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly (lpen = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
test evY2 evY3
** Triple Difference with mkt_share
foreach y of global OUTCOMES{
xtreg `y' lpen##mkt_power  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' lpen##mkt_power  y2 y3 y4 y5 y6 mp2 mp3 mp4 mp5 mp6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test mp2 mp3 mp4 mp5 mp6
est store b_`y'
}
xtreg lnprice lpen##mkt_power  y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice lpen##mkt_power  y2 y3 y4 y5 y6 mp2 mp3 mp4 mp5 mp6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test mp2 mp3 mp4 mp5 mp6
** Triple Difference with monopoly
foreach y of global OUTCOMES{
xtreg `y' lpen##monopoly  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' lpen##monopoly  y2 y3 y4 y5 y6 mono2 mono3 mono4 mono5 mono6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test  mono2 mono3 mono4 mono5 mono6
est store b_`y'
}
xtreg lnprice lpen##monopoly  y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice lpen##monopoly  y2 y3 y4 y5 y6 mono2 mono3 mono4 mono5 mono6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test  mono2 mono3 mono4 mono5 mono6
** Triple Difference with notforprofit
foreach y of global OUTCOMES{
xtreg `y' lpen##any_notforprofit  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' lpen##any_notforprofit  y2 y3 y4 y5 y6 npr2 npr3 npr4 npr5 npr6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test   npr2 npr3 npr4 npr5 npr6
est store b_`y'
}
xtreg lnprice lpen##any_notforprofit y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice lpen##any_notforprofit  y2 y3 y4 y5 y6  npr2 npr3 npr4 npr5 npr6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test  npr2 npr3 npr4 npr5 npr6



****************************************************************
****************************************************************
******* Add in models on the intensive margin of penalties
sort provider_number Year
gen pper=0
replace pper=abs(adj-1) if adj~=.
tabstat pper, by(Year) stat(mean min max)
gen lper=0
replace lper=l.pper






/* Examine contemporaneous change in distribution of patients */
foreach y of global OUTCOMES{
xtreg `y' pper  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly, fe cluster(provider_number)
est store b_`y'
}
xtreg lnprice pper   y2 y3 y4 y5 y6 ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly, fe cluster(provider_number)
** Test for time-varying unobservables
foreach y of global OUTCOMES{
xtreg `y' pper   y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly, fe cluster(provider_number)
test evY2 evY3 evY4 evY5 evY6
}
xtreg lnprice pper    y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly, fe cluster(provider_number)
test evY2 evY3 evY4 evY5 evY6
** Scaled Difference-in-differences
foreach y of global OUTCOMES{
xtivreg2  `y' y2 y3 y4 y5 y6   ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly (pper  = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
xtivreg2  `y' y2 y3 y4 y5 y6 evY2 evY3   ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly (pper = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
test evY2 evY3
}
xtivreg2  lnprice y2 y3 y4 y5 y6   ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly (pper  = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
xtivreg2  lnprice y2 y3 y4 y5 y6 evY2 evY3   ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly (pper  = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
test evY2 evY3
** Triple Difference with mkt_share
foreach y of global OUTCOMES{
xtreg `y' c.pper##mkt_power  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' c.pper##mkt_power  y2 y3 y4 y5 y6 mp2 mp3 mp4 mp5 mp6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test mp2 mp3 mp4 mp5 mp6
est store b_`y'
}
xtreg lnprice c.pper##mkt_power  y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice c.pper##mkt_power  y2 y3 y4 y5 y6 mp2 mp3 mp4 mp5 mp6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test mp2 mp3 mp4 mp5 mp6
** Triple Difference with notforprofit
foreach y of global OUTCOMES{
xtreg `y' c.pper##any_notforprofit  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' c.pper##any_notforprofit  y2 y3 y4 y5 y6 npr2 npr3 npr4 npr5 npr6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test   npr2 npr3 npr4 npr5 npr6
est store b_`y'
}
xtreg lnprice c.pper##any_notforprofit y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice c.pper##any_notforprofit  y2 y3 y4 y5 y6  npr2 npr3 npr4 npr5 npr6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test  npr2 npr3 npr4 npr5 npr6
** Now repeat for lagged penalty 

/* Examine lagged change in distribution of patients */
foreach y of global OUTCOMES{
xtreg `y' lper  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly, fe cluster(provider_number)
est store b_`y'
}
xtreg lnprice lper  y2 y3 y4 y5 y6 ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly, fe cluster(provider_number)
** Test for time-varying unobservables
foreach y of global OUTCOMES{
xtreg `y' lper  y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly, fe cluster(provider_number)
test evY2 evY3 evY4 evY5 evY6
}
xtreg lnprice lper   y2 y3 y4 y5 y6 evY2 evY3 evY4 evY5 evY6 ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly, fe cluster(provider_number)
test evY2 evY3 evY4 evY5 evY6
** Scaled Difference-in-differences
foreach y of global OUTCOMES{
xtivreg2  `y' y2 y3 y4 y5 y6   ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly (lper = evY2 evY3 evY4 evY5 evY6) , first fe cluster(provider_number)  
xtivreg2  `y' y2 y3 y4 y5 y6 evY2 evY3   ${COUNTY_VARS} ${HOSPITAL_VARS} monopoly duopoly triopoly (lper = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
test evY2 evY3
}
xtivreg2  lnprice y2 y3 y4 y5 y6   ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly (lper = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
xtivreg2  lnprice y2 y3 y4 y5 y6 evY2 evY3   ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit monopoly duopoly triopoly (lper = evY2 evY3 evY4 evY5 evY6) , fe cluster(provider_number)  
test evY2 evY3
** Triple Difference with mkt_share
foreach y of global OUTCOMES{
xtreg `y' c.lper##mkt_power  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' c.lper##mkt_power  y2 y3 y4 y5 y6 mp2 mp3 mp4 mp5 mp6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test mp2 mp3 mp4 mp5 mp6
est store b_`y'
}
xtreg lnprice c.lper##mkt_power  y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice c.lper##mkt_power  y2 y3 y4 y5 y6 mp2 mp3 mp4 mp5 mp6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test mp2 mp3 mp4 mp5 mp6
** Triple Difference with monopoly
foreach y of global OUTCOMES{
xtreg `y' c.lper##monopoly  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' c.lper##monopoly  y2 y3 y4 y5 y6 mono2 mono3 mono4 mono5 mono6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test  mono2 mono3 mono4 mono5 mono6
est store b_`y'
}
xtreg lnprice c.lper##monopoly  y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice c.lper##monopoly  y2 y3 y4 y5 y6 mono2 mono3 mono4 mono5 mono6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test  mono2 mono3 mono4 mono5 mono6
** Triple Difference with notforprofit
foreach y of global OUTCOMES{
xtreg `y' c.lper##any_notforprofit  y2 y3 y4 y5 y6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
xtreg `y' c.lper##any_notforprofit  y2 y3 y4 y5 y6 npr2 npr3 npr4 npr5 npr6  ${COUNTY_VARS} ${HOSPITAL_VARS} , fe cluster(provider_number)
test   npr2 npr3 npr4 npr5 npr6
est store b_`y'
}
xtreg lnprice c.lper##any_notforprofit y2 y3 y4 y5 y6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
xtreg lnprice c.lper##any_notforprofit  y2 y3 y4 y5 y6  npr2 npr3 npr4 npr5 npr6 medicaid_share medicare_share ${PRICE_VARS} ${COUNTY_VARS} ${HOSPITAL_VARS} any_forprofit , fe cluster(provider_number)
test  npr2 npr3 npr4 npr5 npr6















cap log close
