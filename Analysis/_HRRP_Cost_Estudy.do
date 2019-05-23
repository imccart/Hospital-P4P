capture log close
set logtype text
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "D:\CloudStation\Professional\Research Projects\Hospital Readmissions\Logs\DataLog`logdate'.log", replace

***********************************************************************************
** Title:	      Build Final Dataset for Hospital Response to HRRP
** Author:        Ian McCarthy
** Date created:  12/2/2016
** Date edited:   1/23/2018
** Notes:		  - Removed HSA power calculations on 10/3 - by definition most HSAs only have one hospital
***********************************************************************************
set more off
global DATA_FINAL "D:\CloudStation\Professional\Research Projects\Hospital Readmissions\Data\"
global DATA_HSA "D:\CloudStation\Professional\Research Data\Zip and MSA\"

***********************************************************************************
/* Merge Data */

** Begin with HCRIS data at Hospital FYear
use "${DATA_FINAL}HCRIS_Hospital_Level.dta", clear

** Merge with AHA data (at hospital FYear)
merge 1:1 provider_number FYear using "${DATA_FINAL}AHA_Data.dta", keep(master match) generate(AHA_merge)

** Merge with Hospital VBP adjustments (at federal FY level)
merge 1:1 provider_number FYear using "${DATA_FINAL}Hospital_VBP.dta", keep(master match) generate(VBP_merge)

** Merge with PPS (case mix index data, at federal FY level)
merge 1:1 provider_number FYear using "${DATA_FINAL}Hospital_PPS.dta", keep(master match) generate(PPS_merge)

** Merge with Hospital Compare (data at calendar year level)
merge m:1 provider_number CYear using "${DATA_FINAL}Hospital_Compare.dta", keep(master match) generate(Compare_merge)

** replace missing zip data
replace zip=0 if zip==.
bys provider_number: egen max=max(zip)
replace zip=max if zip==0 & max!=0
drop max 

** replace missing fips
gen byte nonmiss=!mi(fips)
sort provider_number fips nonmiss
bys provider_number (nonmiss): replace fips=fips[_N] if nonmiss==0
drop nonmiss

** fill in missing state data
gen byte nonmiss=!mi(state)
sort provider_number state nonmiss
bys provider_number (nonmiss): replace state=state[_N] if nonmiss==0
drop nonmiss

gen Year=CYear
merge m:1 zip Year using "${DATA_HSA}Zip_HSA_HRR.dta", keep(master match) generate(HSA_merge)
drop Year

merge m:1 fips CYear using "${DATA_FINAL}ACS_Data.dta", keep(master match) generate(ACS_merge)
merge m:1 state using "${DATA_FINAL}medicaid_expansion_states.dta", keep(master match) generate(Medicaid_merge)
replace expand=0 if FYear<2014

split fips, parse("_")
destring fips2, replace
gen str3 fips3 = string(fips2, "%03.0f")
gen fips_clean=fips1+fips3
destring fips_clean, replace
sort fips_clean
drop fips fips1 fips2 fips3
rename fips_clean fips
sort fips FYear

***********************************************************************************
/* New Variables */
replace TotalPop=TotalPop/1000
gen hrr_new=hrrnum
replace hrr_new=HRRCODE if hrrnum==.
drop HRRCODE hrrnum
rename hrr_new hrr
rename hsanum hsa
gen Hospital_VI=(Int_HOS_2==3)
bys provider_number: egen min_vi=min(Hospital_VI)
bys provider_number: egen max_vi=max(Hospital_VI)
gen always_vi=(min_vi==max_vi & Hospital_VI==1)
gen never_vi=(min_vi==max_vi & Hospital_VI==0)
gen Pre_VI=Hospital_VI*(FYear<2012)
bys provider_number: egen EverVI_Pre=max(Pre_VI)

** Calculate medicaid & medicare share and impute if missing
bys provider_number: egen max_mcare=max(mcare_discharges)
bys provider_number: egen max_mcaid=max(mcaid_discharges)
bys provider_number: egen max_totdis=max(total_discharges)
replace mcare_discharges=. if mcare_discharges<(.05*(max_mcare))
replace mcaid_discharges=. if mcaid_discharges<(.05*(max_mcaid))
replace total_discharges=. if total_discharges<(.05*(max_totdis))

gen medicaid_share=mcaid_discharges/total_discharges
gen medicare_share=mcare_discharges/total_discharges
gen other_share=1-medicaid_share-medicare_share
gen public_share=medicaid_share+medicare_share
gen public_discharges=mcaid_discharges+mcare_discharges
gen other_discharges=total_discharges-public_discharges

sort provider_number
by provider_number: egen aid_avg=mean(medicaid_share)
by provider_number: egen are_avg=mean(medicare_share)
by provider_number: egen mcaid_avg_disch=mean(mcaid_discharges)
by provider_number: egen mcare_avg_disch=mean(mcare_discharges)
by provider_number: egen tot_avg_disch=mean(total_discharges)
replace medicaid_share=aid_avg if medicaid_share==.
replace medicare_share=are_avg if medicare_share==.
replace public_share=medicaid_share+medicare_share if public_share==.
replace public_share=1 if public_share>1 & public_share!=.
replace other_share=1-public_share if other_share==.
replace other_share=0 if other_share<0

replace total_discharges=tot_avg_disch if total_discharges==.
replace mcaid_discharges=mcaid_avg_disch if mcaid_discharges==.
replace mcare_discharges=mcare_avg_disch if mcare_discharges==.
replace public_discharges=mcaid_discharges+mcare_discharges if public_discharges==.
replace other_discharges=total_discharges-public_discharges if other_discharges==.
replace other_discharges=0 if other_discharges<0


** Impute profitability index if missing
bys provider_number: egen pindex_avg=mean(Percent_Profitable)
replace Percent_Profitable=pindex_avg if Percent_Profitable==.

** Impute HCAHPS measures if missing
bys provider_number: egen rating_avg=mean(hcahps_rating)
replace hcahps_rating=rating_avg if hcahps_rating==.
bys provider_number: egen recommend_avg=mean(hcahps_recommend)
replace hcahps_recommend=recommend_avg if hcahps_recommend==.


** Calculate penalty variables
replace VBP_adj=1 if FYear<2013 | (FYear==2013 & fmonth<10)
/*
gen hrrp_penalty=(adj<1)
gen vbp_penalty = (VBP_adj<1)
gen vbp_rebate = (VBP_adj>1 & VBP_adj!=.)
gen penalty=(hrrp_penalty==1 | vbp_penalty==1)
gen HRRP=(Year>=2013)
gen pen_none=(vbp_penalty==0 & hrrp_penalty==0)
gen pen_one=(vbp_penalty==1 | hrrp_penalty==1)
gen pen_both=(vbp_penalty==1 & hrrp_penalty==1)
replace pen_one=0 if pen_both==1
*/
replace hrrp_payment=-hrrp_payment if hrrp_payment>0
egen amt_penalty=rowtotal(hrrp_payment hvbp_payment) if hrrp_payment!=. | hvbp_payment!=.
replace amt_penalty=amt_penalty*-1
gen post_period=(FYear>=2013 | FYear==2012 & fmonth>=10)
gen net_penalty=(amt_penalty>0) if amt_penalty!=.
replace net_penalty=0 if amt_penalty==. & post_period==0
bys provider_number: egen everpen=max(net_penalty)

** Hospitals and discharges by markets
bys zip FYear: egen Zip_Hospitals=count(provider_number) if zip!=.
bys zip FYear: egen Zip_Discharges=total(total_discharges) if zip!=.
bys fips FYear: egen FIPS_Hospitals=count(provider_number) if fips!=.
bys fips FYear: egen FIPS_Discharges=total(total_discharges) if fips!=.
bys hsa FYear: egen HSA_Hospitals=count(provider_number) if hsa!=.
bys hsa FYear: egen HSA_Discharges=total(total_discharges) if hsa!=.
gen fips_share2=(total_discharges/FIPS_Discharges)^2 if fips!=.

** fill in HRR for missing year data (2014-2015)
gen byte nonmiss=!mi(hrr)
sort provider_number hrr nonmiss
bys provider_number (nonmiss): replace hrr=hrr[_N] if nonmiss==0
drop nonmiss
bys hrr FYear: egen HRR_Hospitals=count(provider_number) if hrr!=.
bys hrr FYear: egen HRR_Discharges=total(total_discharges) if hrr!=.

** add national readmission rates from hospital compare
gen natl_ami=19.9 if CYear==2009
gen natl_hf=24.5 if CYear==2009
gen natl_pn=18.2 if CYear==2009
replace natl_ami=19.9 if CYear==2010
replace natl_hf=24.7 if CYear==2010
replace natl_pn=18.3 if CYear==2010
replace natl_ami=19.8 if CYear==2011
replace natl_hf=24.8 if CYear==2011
replace natl_pn=18.4 if CYear==2011
replace natl_ami=19.7 if CYear==2012
replace natl_hf=24.7 if CYear==2012
replace natl_pn=18.5 if CYear==2012
replace natl_ami=18.3 if CYear==2013
replace natl_hf=23.0 if CYear==2013
replace natl_pn=17.6 if CYear==2013
replace natl_ami=17.8 if CYear==2014
replace natl_hf=22.7 if CYear==2014
replace natl_pn=17.3 if CYear==2014
replace natl_ami=17.0 if CYear==2015
replace natl_hf=22.0 if CYear==2015
replace natl_pn=16.9 if CYear==2015

** winsorize hospital (cmi-adjusted) prices
gen price_cmi=price/CMI
gen lnprice=log(price_cmi)
winsor2 lnprice, replace cuts(5 95) by(FYear)
gen lnexp=log(tot_opexp)
gen lnrev=log(tot_charges)

** calculate measures of market power and relative market power (impute if missing)
bys fips FYear: egen HHI_FIPS=total(fips_share2)
gen fips_monopoly=(FIPS_Hospitals==1)
gen fips_duopoly=(FIPS_Hospitals==2)
gen fips_triopoly=(FIPS_Hospitals==3)

gen hsa_monopoly=(HSA_Hospitals==1)
gen hsa_duopoly=(HSA_Hospitals==2)
gen hsa_triopoly=(HSA_Hospitals==3)

** identify if ever for profit
bys provider_number: egen max_forprofit=max(Profit)
bys provider_number: egen min_forprofit=min(Profit)
gen always_forprofit=(min_forprofit==1)
gen always_notforprofit=(max_forprofit==0)

** additional price variables
gen lncmi=log(CMI)
gen lncost_per_discharge=log(tot_opexp/total_discharges)
gen op_rev=(tot_charges-ip_charges - intcare_charges - ancserv_charges)/tot_charges

** Year vars
forvalues y=2010/2015 {
	gen Year_`y'=(FYear==`y')
}
gen year_trend=FYear-2009


********************************************************************************
* Apply sample criteria
********************************************************************************
drop if state=="PR" | state=="GU" | state=="VI" | state=="AK" | state=="HI" | state=="MP"
drop if Beds<30
drop if total_discharges<100
keep if Urban==1
drop if FYear==2016
drop if other_share==.
drop if fips==.
	
	
** drop if missing year
sort provider_number year_trend
by provider_number: gen temp=_n
by provider_number: egen max=max(temp)
tab max if year_trend==1
keep if max==8
drop max
	
	
********************************************************************************
* Deal with missing variables
********************************************************************************
** Identify observations with missing demographic variables
global COUNTY_VARS 		TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black Income_50to75 ///
						Income_75to100 Income_100to150 Income_150plus Educ_HSGrad Educ_Bach Emp_FullTime
gen m_census=0
replace m_census=1 if TotalPop==.
foreach y of global COUNTY_VARS{
replace `y'=-99 if `y'==.
}

** Identify observations with missing hospital data
ren Teaching_Hospital1 teach1
ren Teaching_Hospital2 teach2
global HOSPITAL_VARS 	teach1 teach2 System Nonprofit Profit Labor_Nurse Labor_Other ///
						Beds hcahps_rating hcahps_recommend
gen m_sys=0
replace m_sys=1 if System==.
gen m_nfp=0
replace m_nfp=1 if Nonprofit==.
gen m_teach=0
replace m_teach=1 if teach1==.
gen m_hcahps=0
replace m_hcahps=1 if hcahps_rating==.
foreach y of varlist teach1 teach2 System Nonprofit Profit hcahps_rating hcahps_recommend {
replace `y'=-99 if `y'==.
}
gen m_lnurse=0
gen m_lother=0
replace m_lnurse=1 if Labor_Nurse==.
replace m_lother=1 if Labor_Other==.
foreach y of varlist Labor_Nurse Labor_Other {
replace `y'=-99 if `y'==.
}

** Identify observations with missing price data
ren lncost_per_discharge lnc_p_d
global PRICE_VARS 		lncmi lnc_p_d op_rev
gen m_p_d=0
gen m_op=0
replace m_p_d=1 if lnc_p_d==.
replace m_op=1 if op_rev==.
foreach y of varlist lnc_p_d op_rev {
replace `y'=-99 if `y'==.
}


********************************************************************************
* Now collect missing terms and define samples
********************************************************************************
global missing m_census m_sys m_teach m_hcahps m_lnurse m_lother m_p_d m_op
gen sample_price=0
replace sample_price=1 if lnprice~=.
tab year_trend, gen(y)
for num 1/6: gen evYX=everpen*yX
for num 1/6: gen fips_monoX=yX*fips_monopoly

***********************************************************************************
/* Save Final Dataset */
rename FYear Year

sort provider_number
gen low=.
replace low=Year if net_penalty==1
by provider_number: egen first=min(low)
drop low
gen time=(Year-first)+1
replace time=0 if everpen==0

gen pen_group=(first==2012 | first==2013)
gen es1=(Year==2008 & pen_group==1)
gen es2=(Year==2009 & pen_group==1)
gen es3=(Year==2010 & pen_group==1)
gen es4=(Year==2011 & pen_group==1)
gen es5=(Year==2012 & pen_group==1)
gen es6=(Year==2013 & pen_group==1)
gen es7=(Year==2014 & pen_group==1)
gen es8=(Year==2015 & pen_group==1)


xtset provider_number Year
xtreg lnc_p_d es1 es2 es3 es4 es6 es7 es8 hsa_monopoly hsa_duopoly hsa_triopoly $COUNTY_VARS $HOSPITAL_VARS m_* i.Year if (pen_group==1 | time==0), fe cluster(provider_number)
est sto estudy_all
coefplot estudy_all, ci(90) keep(es1 es2 es3 es4 es6 es7 es8) vert ytitle(Coefficient) yline(0) xline(4.2) xtitle(Period) coeflabels(es1="2008" es2="2009" es3="2010" es4="2011" es6="2013" es7="2014" es8="2015") 
save "${DATA_FINAL}estudy_cost.gph", replace
graph export "${DATA_FINAL}estudy_cost.pdf", as(pdf) replace  	
