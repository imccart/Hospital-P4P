local d = "$S_DATE"
log using "$results\DMB_diff_trends_`d'.log", replace

**************************************************************
* 1.) Test for differential trends by treatment group
**************************************************************
use temp_data, clear
sort provider_number
gen low=.
replace low=Year if net_penalty==1
by provider_number: egen first=min(low)
drop low
gen time=(Year-first)+1
replace time=0 if everpen==0
tab time, gen(ev)

forvalues t=2012(1)2015 {
	gen temp_pen_`t'=net_penalty*(Year==`t')
	bys provider_number: egen pen_`t'=max(temp_pen_`t')
	drop temp_pen_`t'
}
gen pen2012_only=(pen_2012==1 & pen_2013==1 & pen_2014==1 & pen_2015==1)
gen pen2013_only=(pen_2012==0 & pen_2013==1 & pen_2014==1 & pen_2015==1)

forvalues t=2010(1)2015 {
	gen pen_2012_`t'=pen_2012*(Year==`t')
	gen pen_2013_`t'=pen_2013*(Year==`t')
	gen pen_2014_`t'=pen_2014*(Year==`t')
	gen pen_2015_`t'=pen_2015*(Year==`t')
	gen pen_y`t'=(everpen==0)*(Year==`t')
}
reghdfe lnprice_hcci net_penalty y2 y3 y4 y5 y6 ///
	pen_2012_2011 pen_2012_2012 pen_2012_2013 pen_2012_2014 pen_2012_2015 ///
	pen_2013_2011 pen_2013_2012 pen_2013_2013 pen_2013_2014 pen_2013_2015 ///
	pen_2014_2011 pen_2014_2012 pen_2014_2013 pen_2014_2014 pen_2014_2015 ///
	pen_2015_2011 pen_2015_2012 pen_2015_2013 pen_2015_2014 pen_2015_2015 ///
	hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size ${COUNTY_VARS} ${HOSPITAL_VARS} ///
	${PRICE_VARS} m_*, absorb(provider_number) cluster(provider_number)
test pen_2012_2011 pen_2013_2011 pen_2013_2012 ///
	pen_2014_2011 pen_2014_2012 pen_2014_2013 pen_2015_2011 pen_2015_2012 pen_2015_2013 pen_2015_2014


reghdfe lnprice_hcci net_penalty y2 y3 y4 y5 y6 ///
	hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size ${COUNTY_VARS} ${HOSPITAL_VARS} ///
	${PRICE_VARS} m_* if (first==2012 | first==2013 | everpen==0), absorb(provider_number) cluster(provider_number)
reghdfe lnprice_hcci net_penalty y2 y3 y4 y5 y6 ///
	pen_2012_2011 pen_2012_2012 pen_2012_2013 pen_2012_2014 pen_2012_2015 ///
	pen_2013_2011 pen_2013_2012 pen_2013_2013 pen_2013_2014 pen_2013_2015 ///
	hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size ${COUNTY_VARS} ${HOSPITAL_VARS} ///
	${PRICE_VARS} m_* if (first==2012 | first==2013 | everpen==0), absorb(provider_number) cluster(provider_number)
test pen_2012_2011 pen_2013_2011 pen_2013_2012
save temp_trends, replace	


**************************************************************
* 2.) Effects with differential trends
**************************************************************
*** 2012 treatment group
use temp_trends, clear
keep if first==2012 | everpen==0
reghdfe lnprice_hcci net_penalty pen_y2011 pen_y2012 pen_y2013 pen_y2014 pen_y2015 hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
test net_penalty

reghdfe price_hcci hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS} m_* y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number) residuals(resid)
predict resid_price, r
drop resid

gen pen_group=(first==2012)
bys pen_group: egen mean_price=mean(price_hcci)
collapse (first) mean_price (mean) resid_price price_hcci, by(pen_group Year)
replace resid_price=resid_price+price_hcci
graph twoway (connected resid_price Year if pen_group==1, color(black) lpattern(dash)) ///
	(connected resid_price Year if pen_group==0, color(black) lpattern(solid)),	///
	xtitle("Year") ytitle("Mean Price ($)") legend(order(1 "Penalty" 2 "No Penalty"))  ///
	ylabel(, format(%6.0fc)) xlabel(2010(1)2015) xline(2011.5) saving("$results\price_resid_2012.gph", replace)


*** 2013 treatment group	
use temp_trends, clear
keep if first==2013 | everpen==0
reghdfe lnprice_hcci net_penalty pen_y2011 pen_y2012 pen_y2013 pen_y2014 pen_y2015 hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
test net_penalty

reghdfe price_hcci hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS} m_* y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number) residuals(resid)
predict resid_price, r
drop resid

gen pen_group=(first==2013)
bys pen_group: egen mean_price=mean(price_hcci)
collapse (first) mean_price (mean) resid_price price_hcci, by(pen_group Year)
replace resid_price=resid_price+price_hcci
graph twoway (connected resid_price Year if pen_group==1, color(black) lpattern(dash)) ///
	(connected resid_price Year if pen_group==0, color(black) lpattern(solid)),	///
	xtitle("Year") ytitle("Mean Price ($)") legend(order(1 "Penalty" 2 "No Penalty"))  ///
	ylabel(, format(%6.0fc)) xlabel(2010(1)2015) xline(2012.5) saving("$results\price_resid_2013.gph", replace)	

	
	
*** 2014 treatment group	
use temp_trends, clear
keep if first==2014 | everpen==0
reghdfe lnprice_hcci net_penalty pen_y2011 pen_y2012 pen_y2013 pen_y2014 pen_y2015 hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
test net_penalty

reghdfe price_hcci hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS} m_* y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number) residuals(resid)
predict resid_price, r
drop resid

gen pen_group=(first==2014)
bys pen_group: egen mean_price=mean(price_hcci)
collapse (first) mean_price (mean) resid_price price_hcci, by(pen_group Year)
replace resid_price=resid_price+price_hcci
graph twoway (connected resid_price Year if pen_group==1, color(black) lpattern(dash)) ///
	(connected resid_price Year if pen_group==0, color(black) lpattern(solid)),	///
	xtitle("Year") ytitle("Mean Price ($)") legend(order(1 "Penalty" 2 "No Penalty"))  ///
	ylabel(, format(%6.0fc)) xlabel(2010(1)2015) xline(2013.5) saving("$results\price_resid_2014.gph", replace)

	
	
*** 2015 treatment group	
use temp_trends, clear
keep if first==2015 | everpen==0
reghdfe lnprice_hcci net_penalty pen_y2011 pen_y2012 pen_y2013 pen_y2014 pen_y2015 hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size   ${COUNTY_VARS} ${HOSPITAL_VARS} m_*  y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number)
test net_penalty

reghdfe price_hcci hsa_monopoly hsa_duopoly hsa_triopoly i.fips_size ${COUNTY_VARS} ${HOSPITAL_VARS} ${PRICE_VARS} m_* y2 y3 y4 y5 y6, absorb(provider_number) cluster(provider_number) residuals(resid)
predict resid_price, r
drop resid

gen pen_group=(first==2015)
bys pen_group: egen mean_price=mean(price_hcci)
collapse (first) mean_price (mean) resid_price price_hcci, by(pen_group Year)
replace resid_price=resid_price+price_hcci
graph twoway (connected resid_price Year if pen_group==1, color(black) lpattern(dash)) ///
	(connected resid_price Year if pen_group==0, color(black) lpattern(solid)),	///
	xtitle("Year") ytitle("Mean Price ($)") legend(order(1 "Penalty" 2 "No Penalty"))  ///
	ylabel(, format(%6.0fc)) xlabel(2010(1)2015) xline(2014.5) saving("$results\price_resid_2015.gph", replace)
	

	
graph use "$results\ev_lnprice_hcci_2013.gph"
graph use "$results\price_resid_2013.gph"
	
**************************************************************
* 3.) IV Estimates
**************************************************************
use temp_trends, clear
gen es1=(Year==2010 & everpen==1)
gen es2=(Year==2011 & everpen==1)
gen es3=(Year==2012 & everpen==1)
gen es4=(Year==2013 & everpen==1)
gen es5=(Year==2014 & everpen==1)
gen es6=(Year==2015 & everpen==1)

xtset provider_number Year
xtivreg2 lnprice_hcci hsa_monopoly hsa_duopoly hsa_triopoly ${COUNTY_VARS} ${HOSPITAL_VARS} m_* ///
  y2 y3 y4 y5 y6 (net_penalty=es2 es3 es4 es5 es6), fe cluster(provider_number) first

xtivreg2 lnprice_hcci hsa_monopoly hsa_duopoly hsa_triopoly ${COUNTY_VARS} ${HOSPITAL_VARS} m_* ///
  y2 y3 y4 y5 y6 es2 (net_penalty=es2 es3 es4 es5 es6), fe cluster(provider_number) first
test es2

cap log close
