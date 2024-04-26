
**************
*** Aid as a Tool against Insurgency
*** Renard Sexton, July 2016
*** Replication dependency
***************

ssc install texsave
capture ssc install estout

** Nicholas J Cox cosort program **
program define cosort
	version 6 
	syntax varlist(min=2) [if] [in] 
	tokenize `varlist' 
	tempvar touse order 
	mark `touse' `if' `in' 
	qui replace `touse' = 1 - `touse' 
	sort `touse' `1' 
	gen long `order' = _n
	mac shift 
	qui while "`1'" != "" { 
		tempvar copy 
		local type : type `1' 
		gen `type' `copy' = `1' 
		sort `touse' `1' 
		replace `1' = `copy'[`order']
		drop `copy' 
		mac shift 
	}	
	sort `order' 
end

********************
* Variable Labels 
********************
capture program label_var
label var districtid "District ID Number"
label var week "Week Number"
label var pop10k "District Population (x 10,000)"
label var troops "Secured (dummy)"
label var CERPdummy "Number of CERP projects active"
label var CERPdollars_pcap "CERP spending per capita"
label var CERPdollars_large_pcap "Large project CERP spending per capita (>$50k projects)"
label var CERPdollars_small_pcap "Small project CERP spending per capita (<$50k projects)"
label var type3_pcap "Bombings per capita (ANSO)"
label var type18_pcap "Enemy Actions per capita (CIDNE)"
label var type19_pcap "Explosive Hazards per capita (CIDNE)"
label var type5_pcap "NATO and Afghan Army Operations per capita (ANSO)"
label var budget_pcap "Civilian aid per capita (MRRG)"
label var CERPdollars_13_pcap "Protective Measures CERP projects spending per capita"
label var CERPdollars_12_pcap "Humanitarian CERP projects spending per capita"
label var CERPdollars_7_pcap "Healthcare CERP projects spending per capita"
label var CERPdollars_19_pcap "Telecommunications CERP projects spending per capita"
label var CERPdollars_11_pcap "'Other' CERP projects spending per capita"
label var CERPdollars_20_pcap "Transportation CERP projects spending per capita"
label var CERPdollars_4_pcap "Education CERP projects spending per capita"
label var type3_pcap_neighbor "Bombings per capita in adjacent districts"
label var type18_pcap_neighbor "Enemy Actions per capita in adjacent districts"
label var type19_pcap_neighbor "Explosive Hazards per capita in adjacent districts"
label var defuse_pcap "ANP and ANSF IED clearances per capita(ANSO)"
label var defuse2_pcap "NATO IED clearances per capita (ANSO)"
end


** 1. Constructing cumulative effects (IRF)

** 1.1 Outcome: Bombings (ANSO) Figure 4
use "$da/sexton-afg-apsr", clear
tsset districtid week

reg type3_pcap c.CERPdollars_pcap##L.troops L.type3_pcap  L.c.CERPdollars_pcap##L2.troops ///
L2.c.CERPdollars_pcap##L3.troops L2_type3_pcap i.week i.districtid if sample==1, vce(cl districtid)
matrix x1= e(V)
matrix x2= e(b)
mat vcv1=x1[1..11,1..11]
mat means1=x2[1,1..11]

set seed 143
drawnorm x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11, n(1000) means(means1) cov(vcv1) clear

*First period, Independent Effect
gen unsecured_first=x1
gen secured_first=x1+x5
*Second period, Independent Effect
gen unsecured_second=x7+(x6*x1)
gen secured_second=x7+x11+(x6*(x1+x5))

*Projected
forvalues i=1/4 {
	gen unsecuredx`i'=(`i'*unsecured_first)+((`i'-1)*unsecured_second)
	gen securedx`i'=(`i'*secured_first)+((`i'-1)*secured_second)
}
drop x*

cosort secured* unsecured*
gen id=_n
sum unsecured_first unsecured_second secured_first secured_second if id>50 | id<951
drop if id<51 | id>950

forvalues i=1/4 {
	egen unsecured_mean`i'=mean(unsecuredx`i')
	egen secured_mean`i'=mean(securedx`i')
	egen unsecured_h`i'=max(unsecuredx`i')
	egen secured_h`i'=max(securedx`i')
	egen unsecured_l`i'=min(unsecuredx`i')
	egen secured_l`i'=min(securedx`i')
	}
drop *first *second securedx* unsecuredx*
 
	reshape long unsecured_mean secured_mean unsecured_h secured_h unsecured_l secured_l, i(id)
	keep if id==51
	drop id
	rename _j t
	
* adjust for $500,000 spending over 4 weeks
	foreach x in unsecured_mean unsecured_l unsecured_h secured_l secured_mean secured_h {
replace `x'=(`x'*1.25)
}	
save bombings_projected,replace


** 1.2 Outcome: Enemy Actions (CIDNE) Figure 5
use "$da/sexton-afg-apsr", clear
tsset districtid week

reg type18_pcap c.CERPdollars_pcap##L.troops L.type18_pcap  L.c.CERPdollars_pcap##L2.troops ///
 L2.c.CERPdollars_pcap##L3.troops L2_type18_pcap i.week i.districtid if sample==1, vce(cl districtid) 
matrix x1= e(V)
matrix x2= e(b)
mat vcv1=x1[1..11,1..11]
mat means1=x2[1,1..11]

set seed 143
drawnorm x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11, n(1000) means(means1) cov(vcv1) clear

*First period, Independent Effect
gen unsecured_first=x1
gen secured_first=x1+x5
*Second period, Independent Effect
gen unsecured_second=x7+(x6*x1)
gen secured_second=x7+x11+(x6*(x1+x5))

*Projected

forvalues i=1/4 {
	gen unsecuredx`i'=(`i'*unsecured_first)+((`i'-1)*unsecured_second)
	gen securedx`i'=(`i'*secured_first)+((`i'-1)*secured_second)
}
drop x*

cosort secured* unsecured*
gen id=_n
sum unsecured_first unsecured_second secured_first secured_second if id>50 | id<951
drop if id<51 | id>950

forvalues i=1/4 {
	egen unsecured_mean`i'=mean(unsecuredx`i')
	egen secured_mean`i'=mean(securedx`i')
	egen unsecured_h`i'=max(unsecuredx`i')
	egen secured_h`i'=max(securedx`i')
	egen unsecured_l`i'=min(unsecuredx`i')
	egen secured_l`i'=min(securedx`i')
	}
drop *first *second securedx* unsecuredx*
 
	reshape long unsecured_mean secured_mean unsecured_h secured_h unsecured_l secured_l, i(id)
	keep if id==51
	drop id
	rename _j t
	
* adjust for $500,000 spending over 4 weeks
	foreach x in unsecured_mean unsecured_l unsecured_h secured_l secured_mean secured_h {
replace `x'=(`x'*1.25)
}
save enemyactions_projected,replace

** 1.3 Outcome: Explosive Hazards (CIDNE) Figure 6
use "$da/sexton-afg-apsr", clear
tsset districtid week

reg type19_pcap c.CERPdollars_pcap##L.troops L.type19_pcap  L.c.CERPdollars_pcap##L2.troops ///
L2.c.CERPdollars_pcap##L3.troops L2_type19_pcap i.week i.districtid if sample==1, vce(cl districtid)
matrix x1= e(V)
matrix x2= e(b)
mat vcv1=x1[1..11,1..11]
mat means1=x2[1,1..11]

set seed 143
drawnorm x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11, n(1000) means(means1) cov(vcv1) clear

*First period, Independent Effect
gen unsecured_first=x1
gen secured_first=x1+x5
*Second period, Independent Effect
gen unsecured_second=x7+(x6*x1)
gen secured_second=x7+x11+(x6*(x1+x5))

*Projected

forvalues i=1/4 {
	gen unsecuredx`i'=(`i'*unsecured_first)+((`i'-1)*unsecured_second)
	gen securedx`i'=(`i'*secured_first)+((`i'-1)*secured_second)
}
drop x*

cosort secured* unsecured*
gen id=_n
sum unsecured_first unsecured_second secured_first secured_second if id>50 | id<951
drop if id<51 | id>950

forvalues i=1/4 {
	egen unsecured_mean`i'=mean(unsecuredx`i')
	egen secured_mean`i'=mean(securedx`i')
	egen unsecured_h`i'=max(unsecuredx`i')
	egen secured_h`i'=max(securedx`i')
	egen unsecured_l`i'=min(unsecuredx`i')
	egen secured_l`i'=min(securedx`i')
	}
drop *first *second securedx* unsecuredx*
 
	reshape long unsecured_mean secured_mean unsecured_h secured_h unsecured_l secured_l, i(id)
	keep if id==200
	drop id
	rename _j t

	* adjust for $500,000 spending over 4 weeks
	foreach x in unsecured_mean unsecured_l unsecured_h secured_l secured_mean secured_h {
replace `x'=(`x'*1.25)
}
	
save explosive_projected,replace


** 2. Project types

** 13 (Protective Measures) and 12 (Other Humanitarian)

foreach x in 13 12{
	foreach y in 3 18 19 {
		use "$da/sexton-afg-apsr", clear
		tsset districtid week

		reg type`y'_pcap c.CERPdollars_`x'_pcap##L.troops L.type`y'_pcap  L.c.CERPdollars_`x'_pcap##L2.troops ///
		 L2.c.CERPdollars_`x'_pcap##L3.troops L2.type`y'_pcap i.week i.districtid if sample==1, vce(cl districtid)
		matrix x1= e(V)
		matrix x2= e(b)
		mat vcv1=x1[1..11,1..11]
		mat means1=x2[1,1..11]

		set seed 143
		drawnorm x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11, n(1000) means(means1) cov(vcv1) clear

		*First period, Independent Effect
		gen unsecured_first=x1
		gen secured_first=x1+x5
		*Second period, Independent Effect
		gen unsecured_second=x7+(x6*x1)
		gen secured_second=x7+x11+(x6*(x1+x5))

		*Projected

		forvalues i=1/4 {
			gen unsecuredx`i'=(`i'*unsecured_first)+((`i'-1)*unsecured_second)
			gen securedx`i'=(`i'*secured_first)+((`i'-1)*secured_second)
		}
		drop x*

		cosort secured* unsecured*
		gen id=_n
		sum unsecured_first unsecured_second secured_first secured_second if id>50 | id<951
		drop if id<51 | id>950

		forvalues i=1/4 {
			egen unsecured_mean`i'=mean(unsecuredx`i')
			egen secured_mean`i'=mean(securedx`i')
			egen unsecured_se`i'=sd(unsecuredx`i')
			egen secured_se`i'=sd(securedx`i')
			
			}
		drop *first *second securedx* unsecuredx*
		 
			reshape long unsecured_mean secured_mean unsecured_se secured_se, i(id)
			keep if id==101
			drop id
			rename _j t
			gen id1=`x'
			gen id2=`y'
		save project`x'_type`y',replace
	}
}

** put them together
clear
foreach x in 13 12{
	foreach y in 3 18 19 {
	append using project`x'_type`y'
	erase project`x'_type`y'.dta
	}
}

sort id1 id2  t
keep if t==2 | t==4
save predicted_projects,replace

** 3. Appendix

** Collapse to 2 and 4 weeks
use "$da/sexton-afg-apsr", clear
tsset districtid week

gen twoweek=ceil(week/2)
collapse (sum) *_pcap (mean) troops, by(twoweek districtid)
gen troopsx=ceil(troops)

tsset twoweek districtid

reg type3_pcap c.CERPdollars_pcap##L.troopsx L.type3_pcap  L.c.CERPdollars_pcap##L.troopsx  ///
  i.twoweek i.districtid if !missing(type3_pcap), vce(cl districtid)
matrix x1= e(V)
matrix x2= e(b)
mat vcv1=x1[1..9,1..9]
mat means1=x2[1,1..9]

set seed 143
drawnorm x1 x2 x3 x4 x5 x6 x7 x8 x9 , n(1000) means(means1) cov(vcv1) clear

*First period, Independent Effect
gen unsecured_first=x1
gen secured_first=x1+x5
*Second period, Independent Effect
gen unsecured_second=x7+(x6*x1)
gen secured_second=x7+x9+(x6*(x1+x5))

*Projected

forvalues i=1/8 {
	gen unsecuredx`i'=(`i'*unsecured_first)+((`i'-1)*unsecured_second)
	gen securedx`i'=(`i'*secured_first)+((`i'-1)*secured_second)
}
drop x*

cosort secured* unsecured*
gen id=_n
*sum unsecured_first unsecured_second secured_first secured_second if id>50 | id<951
*drop if id<51 | id>950

forvalues i=1/4 {
	egen unsecured_mean`i'=mean(unsecuredx`i')
	egen secured_mean`i'=mean(securedx`i')
	egen unsecured_sd`i'=sd(unsecuredx`i')
	egen secured_sd`i'=sd(securedx`i')
	}
drop *first *second securedx* unsecuredx*
 
	reshape long unsecured_mean secured_mean unsecured_sd secured_sd, i(id)
	keep if id==100
	drop id
	rename _j t
	gen weekly=2
save bombings_twoweek_projected,replace

** Four weeks

use "$da/sexton-afg-apsr", clear
tsset districtid week

gen fourweek=ceil(week/4)
collapse (sum) *_pcap (mean) troops, by(fourweek districtid)
gen troopsx=ceil(troops)

tsset fourweek districtid

reg type3_pcap c.CERPdollars_pcap##L.troopsx L.type3_pcap  L.c.CERPdollars_pcap##L.troopsx  ///
  i.fourweek i.districtid if !missing(type3_pcap), vce(cl districtid)
matrix x1= e(V)
matrix x2= e(b)
mat vcv1=x1[1..9,1..9]
mat means1=x2[1,1..9]

set seed 143
drawnorm x1 x2 x3 x4 x5 x6 x7 x8 x9 , n(1000) means(means1) cov(vcv1) clear

*First period, Independent Effect
gen unsecured_first=x1
gen secured_first=x1+x5
*Second period, Independent Effect
gen unsecured_second=x7+(x6*x1)
gen secured_second=x7+x9+(x6*(x1+x5))

*Projected

forvalues i=1/8 {
	gen unsecuredx`i'=(`i'*unsecured_first)+((`i'-1)*unsecured_second)
	gen securedx`i'=(`i'*secured_first)+((`i'-1)*secured_second)
}
drop x*

cosort secured* unsecured*
gen id=_n
*sum unsecured_first unsecured_second secured_first secured_second if id>50 | id<951
*drop if id<51 | id>950

forvalues i=1/4 {
	egen unsecured_mean`i'=mean(unsecuredx`i')
	egen secured_mean`i'=mean(securedx`i')
	egen unsecured_sd`i'=sd(unsecuredx`i')
	egen secured_sd`i'=sd(securedx`i')
	}
drop *first *second securedx* unsecuredx*
 
	reshape long unsecured_mean secured_mean unsecured_sd secured_sd, i(id)
	keep if id==100
	drop id
	rename _j t
	gen weekly=4
save bombings_fourweek_projected,replace

** One week est. sd

use "$da/sexton-afg-apsr", clear
tsset districtid week

reg type3_pcap c.CERPdollars_pcap##L.troops L.type3_pcap  L.c.CERPdollars_pcap##L2.troops ///
L2.c.CERPdollars_pcap##L3.troops L2.type19_pcap i.week i.districtid if sample==1, vce(cl districtid)
matrix x1= e(V)
matrix x2= e(b)
mat vcv1=x1[1..11,1..11]
mat means1=x2[1,1..11]

set seed 143
drawnorm x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11, n(1000) means(means1) cov(vcv1) clear

*First period, Independent Effect
gen unsecured_first=x1
gen secured_first=x1+x5
*Second period, Independent Effect
gen unsecured_second=x7+(x6*x1)
gen secured_second=x7+x11+(x6*(x1+x5))

*Projected

forvalues i=1/4 {
	gen unsecuredx`i'=(`i'*unsecured_first)+((`i'-1)*unsecured_second)
	gen securedx`i'=(`i'*secured_first)+((`i'-1)*secured_second)
}
drop x*

cosort secured* unsecured*
gen id=_n
sum unsecured_first unsecured_second secured_first secured_second if id>50 | id<951
drop if id<51 | id>950

forvalues i=1/4 {
	egen unsecured_mean`i'=mean(unsecuredx`i')
	egen secured_mean`i'=mean(securedx`i')
	egen unsecured_sd`i'=sd(unsecuredx`i')
	egen secured_sd`i'=sd(securedx`i')
	
	}
drop *first *second securedx* unsecuredx*
 
	reshape long unsecured_mean secured_mean unsecured_sd secured_sd, i(id)
	keep if id==51
	drop id
	rename _j t
	gen weekly=1

append using bombings_fourweek_projected
append using bombings_twoweek_projected
sort weekly t
keep if t==2 | t==4
save projected_multiweek,replace

erase bombings_fourweek_projected.dta
erase bombings_twoweek_projected.dta


