local d = "$S_DATE"
log using "$log\DMB_sum_stat_`d'.log", replace
********************************************************************************
*** Table 1: Demonstration of penalties and prices over time
********************************************************************************
tabstat amt_penalty net_penalty, by(Year) f(%5.3f)
tabstat amt_penalty if amt_penalty>0, by(Year) f(%10.2f)
tabstat price price_hcci, by(Year) f(%5.2f) stat(mean sd)
tabstat mcaid_discharges mcare_discharges total_discharges other_discharges, by(Year) f(%5.2f) stat(mean sd)
********************************************************************************
*** Table 2: Summary Statistics by whether a hospital is ever penalized
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
cap log close



