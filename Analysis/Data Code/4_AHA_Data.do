**set logtype text
cd "E:\"
global DATA_AHA "C:\Users\immccar\Professional\Research Data\AHA Data\"
global DATA_FINAL "C:\Users\immccar\Professional\Research Projects\Hospital Readmissions\Data\"

***********************************************************************************
** Title:	      AHA Data Input and Formating
** Author:        Ian McCarthy
** Date created:  12/2/2016
** Date edited:   6/2/2017
***********************************************************************************
set more off

***********************************************************************************
/* Read and Clean AHA Data */
***********************************************************************************

********************************
** 2008 Data
insheet using "${DATA_AHA}AHA FY 2008\Comma\pubas08.csv", clear case

drop DBEGM DBEGD DBEGY DENDM DENDD DENDY FISM FISD FISY MADMIN TELNO NETPHONE MLOS
foreach x of varlist DTBEG DTEND FISYR {
  gen `x'_clean=date(`x',"MDY")
  drop `x'
  rename `x'_clean `x'
  format `x' %td
}

gen AHAYEAR=2008
tostring MLOCZIP, replace
replace SYSTELN=subinstr(SYSTELN,"-","",1)
destring SYSTELN, replace
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
rename NPI_NUM NPINUM
save temp_data_2008, replace


********************************
** 2009 Data
insheet using "${DATA_AHA}AHA FY 2009\Comma\pubas09.csv", clear case

drop DBEGM DBEGD DBEGY DENDM DENDD DENDY FISM FISD FISY MADMIN TELNO NETPHONE MLOS
foreach x of varlist DTBEG DTEND FISYR {
  gen `x'_clean=date(`x',"MDY")
  drop `x'
  rename `x'_clean `x'
  format `x' %td
}

gen AHAYEAR=2009
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2009, replace

********************************
** 2010 Data
insheet using "${DATA_AHA}AHA FY 2010\COMMA\ASPUB10.csv", clear case
replace EHLTH="0" if EHLTH=="N"
replace EHLTH="" if EHLTH=="." | EHLTH=="2"
destring EHLTH, replace

drop TELNO NETPHONE MLOS
foreach x of varlist DTBEG DTEND FISYR {
  gen `x'_clean=date(`x',"MDY")
  drop `x'
  rename `x'_clean `x'
  format `x' %td
}

gen AHAYEAR=2010
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2010, replace


********************************
** 2011 Data
insheet using "${DATA_AHA}AHA FY 2011\COMMA\ASPUB11.csv", clear case

drop TELNO NETPHONE
foreach x of varlist DTBEG DTEND FISYR {
  gen `x'_clean=date(`x',"MDY")
  drop `x'
  rename `x'_clean `x'
  format `x' %td
}

gen AHAYEAR=2011
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2011, replace


********************************
** 2012 Data
insheet using "${DATA_AHA}AHA FY 2012\COMMA\ASPUB12.csv", clear case

drop TELNO NETPHONE
foreach x of varlist DTBEG DTEND FISYR {
  gen `x'_clean=date(`x',"MDY")
  drop `x'
  rename `x'_clean `x'
  format `x' %td
}


gen AHAYEAR=2012
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2012, replace


********************************
** 2013 Data
insheet using "${DATA_AHA}AHA FY 2013\COMMA\ASPUB13.csv", clear case

drop TELNO NETPHONE
foreach x of varlist DTBEG DTEND FISYR {
  todate `x', gen(`x'_clean) p(mmddyy) cend(2100)
  drop `x'
  rename `x'_clean `x'
}

gen byte notnumeric=(real(MCRNUM)==. & MCRNUM!="")
replace MCRNUM="" if notnumeric==1
destring MCRNUM, replace
gen AHAYEAR=2013
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2013, replace

********************************
** 2014 Data
insheet using "${DATA_AHA}AHA FY 2014\COMMA\ASPUB14.csv", clear case

drop TELNO NETPHONE
foreach x of varlist DTBEG DTEND FISYR {
  todate `x', gen(`x'_clean) p(mmddyy) cend(2100)
  drop `x'
  rename `x'_clean `x'
}

gen byte notnumeric=(real(MCRNUM)==. & MCRNUM!="")
replace MCRNUM="" if notnumeric==1
destring MCRNUM, replace
gen AHAYEAR=2014
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2014, replace

********************************
** 2015 Data
insheet using "${DATA_AHA}AHA FY 2015\COMMA\ASPUB15.csv", clear case

drop TELNO NETPHONE
foreach x of varlist DTBEG DTEND FISYR {
  todate `x', gen(`x'_clean) p(mmddyy) cend(2100)
  drop `x'
  rename `x'_clean `x'
}

gen byte notnumeric=(real(MCRNUM)==. & MCRNUM!="")
replace MCRNUM="" if notnumeric==1
destring MCRNUM, replace
gen AHAYEAR=2015
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2015, replace


********************************
** Append All Years
use temp_data_2008, clear
forvalues t=2009/2015 {
  append using temp_data_`t'
}

rename AHAYEAR Year

** Keep Community Hospitals
keep if COMMTY=="Y"

replace SERV=49 if SERV==48              /* Assign "other" to chronic specialty hospital (only 1 in data) */
replace SERV=49 if SERV==45              /* Assign "other" to eye, ear, nose, and through specialty hospital (only 17 in data) */
replace MNGT=0 if MNGT==.
replace NETWRK=0 if NETWRK==.

** drop prison and college hospitals, children's hospitals, physchiatric hospitals, rehab hospitals, and dependency centers
keep if SERV==10 | SERV==13 | SERV==33 | SERV==41 | SERV==42 | SERV==44 | SERV==45 ///
   | SERV==47 | SERV==48 | SERV==49

** Hospital Characteristics
gen Own_Type=inrange(CNTRL,12,16) + 2*inrange(CNTRL,21,23) + 3*inrange(CNTRL,30,33) + 4*inrange(CNTRL,41,48)
gen Government=(Own_Type==1)
gen Nonprofit=(Own_Type==2)
gen Profit=(Own_Type==3)
gen Teaching_Hospital1=(MAPP8==1) if MAPP8!=.
gen Teaching_Hospital2=(MAPP3==1 | MAPP5==1 | MAPP8==1 | MAPP12==1 | MAPP13==1)
gen System=(SYSID!=. | MHSMEMB==1)
replace BDTOT=BDTOT/100
gen Labor_Phys=FTEMD
gen Labor_Residents=FTERES
gen Labor_Nurse=FTERN+FTELPN
gen Labor_Other=FTEH-Labor_Phys-Labor_Residents-Labor_Nurse
replace Labor_Other=. if Labor_Other<=0
gen Capital_Imaging=MAMMSHOS+ACLABHOS+ENDOCHOS+ENDOUHOS+REDSHOS+CTSCNHOS+DRADFHOS+EBCTHOS+FFDMHOS+MRIHOS+IMRIHOS ///
   + MSCTHOS+MSCTGHOS+PETHOS+PETCTHOS+SPECTHOS+ULTSNHOS
gen Capital_CareSetting=AMBSHOS+EMDEPHOS
gen Capital_Services=ICLABHOS+ADTCHOS+ADTEHOS+CHTHHOS+CAOSHOS+ONCOLHOS+RASTHOS+IMRTHOS+PTONHOS

keep ID MCRNUM NPINUM Year fips DTBEG DTEND FISYR BDTOT LAT LONG Teaching_Hospital1 Teaching_Hospital2 System Labor_* Capital_* Profit Nonprofit
rename MCRNUM provider_number
bys provider_number Year: gen obs=_N
drop if obs>1
drop obs  
save "${DATA_FINAL}AHA_Data.dta", replace
