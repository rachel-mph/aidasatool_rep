********************************************************************************
** 	TITLE	: pol_econ_replication 
**	PURPOSE	: This .do replicates the main tables from Sextion 2016 
**	AUTHOR	: Rachel Pizatella
**	DATE	: 04/10/2024 | DATE MODIFIED: 04/24/2024
********************************************************************************

*********************************** GLOBALS ************************************

clear all
set mem 1g
set matsize 4000
set more off

**# directories  
*------------------------------------------------------------------------------*
	* Define username
	global suser = c(username)

	* Rachel Pizatella-Haswell
	else if "${suser}" == "rachelhaswell" {
		global cwd = "/Users/rachelhaswell/Documents/github/aidasatool_rep"
	}

	gl do					"$cwd/do"			
	gl da 					"$cwd/data"		
	gl ta 					"$cwd/outputs"	

**# datasets 
*------------------------------------------------------------------------------*
	* aid data  
	gl aid_merged	  		"$da/sexton-afg-apsr.dta"
	
** You need the following files in addition to this .do file:

** sexton-afg-apsr.dta
** sexton-afghanistan-apsr-replication-dependency.do

********************
* Run dependency .do file
********************

do "$do/sexton-afghanistan-apsr-replication-dependency"

** Load and label data

use "$aid_merged", clear
tsset districtid week
label_var

********************
* Summary Statistics (Table 3)
********************

** week 1 excluded from main sample due to lag structure
sum pop10k troops CERPdummy CERPdollars_pcap type3_pcap type5_pcap type18_pcap type19_pcap budget_pcap if sample==1 & week!=1

**# Table 4 
*------------------------------------------------------------------------------*
	* import datasets
	use "$aid_merged", clear 

	* clean variable names 
	ren type3_pcap bombings
	ren type18_pcap enemy_actions
	ren type19_pcap exp_hazards
	
	ren troops controlled
	
	ren CERPdollars_pcap CERP
	
	ren type3_pcap_neighbor bombings_neighb 
	ren type18_pcap_neighbor enemy_actions_neighb
	ren type19_pcap_neighbor exp_hazards_neighb
	
	* generate lagged variables 
	tsset districtid week
	
	foreach var of varlist controlled CERP bombings enemy_actions exp_hazards ///
	bombings_neighb enemy_actions_neighb exp_hazards_neighb {
		gen `var'_L1 = L1.`var'
		gen `var'_L2 = L2.`var'
	}
	
	* run regression 
	foreach var of varlist bombings enemy_actions exp_hazards {
		reg `var' c.CERP##controlled_L1 L.c.CERP##controlled_L2 `var'_L1 ///
		i.districtid i.week if sample==1 , vce(cl districtid)
	}

********************
** Predicted Effects (Figures 4, 5 and 6)
********************

** Bombings
use bombings_projected,clear
twoway (line secured_mean t, lc(black) lw(thick)) (line secured_h t,lp(dash) lc(gs7)) (line secured_l t,lp(dash)lc(gs7)) ///
(line unsecured_mean t, lc(black) lp(longdash) lw(thick)) (line unsecured_h t,lp(dash) lc(gs7)) (line unsecured_l t,lp(dash)lc(gs7)), ///
legend(order(4 1) label(1 "Secured") label(4 "Unsecured"))  xlabel(1(1)4) xtitle(" Week ")
graph export bombings.pdf, as(pdf) replace

** Enemy Actions
use enemyactions_projected,clear
twoway (line secured_mean t, lc(black) lw(thick)) (line secured_h t,lp(dash) lc(gs7)) (line secured_l t,lp(dash)lc(gs7)) ///
(line unsecured_mean t, lc(black) lp(longdash) lw(thick)) (line unsecured_h t,lp(dash) lc(gs7)) (line unsecured_l t,lp(dash)lc(gs7)) if t<5, ///
legend(order(4 1) label(1 "Secured") label(4 "Unsecured"))  xlabel(1(1)4) xtitle(" Week ")
graph export enactions.pdf, as(pdf) replace

** Explosive Hazards
use explosive_projected, clear
twoway (line secured_mean t, lc(black) lw(thick)) (line secured_h t,lp(dash) lc(gs7)) (line secured_l t,lp(dash)lc(gs7)) ///
(line unsecured_mean t, lc(black) lp(longdash) lw(thick)) (line unsecured_h t,lp(dash) lc(gs7)) (line unsecured_l t,lp(dash)lc(gs7)) if t<5, ///
legend(order(4 1) label(1 "Secured") label(4 "Unsecured"))  xlabel(1(1)4) xtitle(" Week ")
graph export explosive.pdf, as(pdf) replace

** Predicted total effects
use bombings_projected,clear
gen label=3
append using enemyactions_projected
replace label=18 if missing(label)
append using explosive_projected
replace label=19 if missing(label)
keep if t==4

gen fivehundred_mean1=(unsecured_mean)
gen fivehundred_mean2=(secured_mean)
gen millionmean1=(unsecured_mean*2)
gen millionmean2=(secured_mean*2)

**71.6 million in unsecured
gen total1=(millionmean1*71.6)
** 47.7 million in secured
gen total2=(millionmean2*47.7)

sum total1
di r(sum)
sum total2
di r(sum)

********************
** Project type Predicted Effects (Table 5, 6)
********************

use predicted_projects,clear

texsave t unsecured_mean unsecured_se secured_mean secured_se id2 if id1==13 using projects13.tex,replace
texsave t unsecured_mean unsecured_se secured_mean secured_se id2 if id1==12 using projects12.tex,replace

********************
** Geographic Spillovers (Table 7, 8)
********************
**# Table 7
*------------------------------------------------------------------------------*	
	* import datasets
	use "$aid_merged", clear 

	* clean variable names 
	ren type3_pcap bombings
	ren type18_pcap enemy_actions
	ren type19_pcap exp_hazards
	
	ren troops controlled
	
	ren CERPdollars_pcap CERP
	
	ren type3_pcap_neighbor bombings_neighb 
	ren type18_pcap_neighbor enemy_actions_neighb
	ren type19_pcap_neighbor exp_hazards_neighb
	
	* generate lagged variables 
	tsset districtid week
	
	foreach var of varlist controlled CERP bombings enemy_actions exp_hazards ///
	bombings_neighb enemy_actions_neighb exp_hazards_neighb {
		gen `var'_L1 = L1.`var'
		gen `var'_L2 = L2.`var'
	}
	* run regression 
	foreach var of varlist bombings enemy_actions exp_hazards {
		reg `var' c.CERP##controlled_L1 L.c.CERP##controlled_L2 `var'_L1 ///
		`var'_neighb `var'_neighb_L1 i.districtid i.week if sample==1 , vce(cl districtid)
	}
	
	/* DONE */
	

**# Table 8
*------------------------------------------------------------------------------*	
	* run regression 
	foreach var of varlist bombings enemy_actions exp_hazards {
		reg `var'_neighb c.CERP##controlled_L1 L.c.CERP##controlled_L2 ///
		`var'_neighb_L1 i.districtid i.week if sample==1 , vce(cl districtid)
	}
	

********************
** Northern Distribution Network (Table 9)
********************
use "$da/sexton-afg-apsr", clear
gen tag=(province=="Baghlan" | province=="Balkh" | province=="Samangan" | province=="Parwan")
gen after=(week>=42)

tsset districtid week
eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##after L.y_pcap L.CERPdollars_pcap i.week i.districtid ///
if tag==1 & week>30 & week<54 & sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap 
}
estout using ndn1.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap L.CERPdollars_pcap 1.after#c.CERPdollars_pcap 1.after L.y_pcap  )


********************
** Mechanisms (Table 10-12)
********************

* operations and ied defuse
eststo clear
foreach y in type5 defuse defuse2 {
	rename `y'_pcap y_pcap
	reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap L.c.CERPdollars_pcap##L2.troops i.week i.districtid if sample==1, vce(cl districtid)
	eststo
	rename y_pcap `y'_pcap
	}
estout using operations.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )

* large projects
eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_large_pcap##L.troops L.y_pcap  L.c.CERPdollars_large_pcap##L2.troops i.week i.districtid if sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using large.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_large_pcap 1L.troops#c.CERPdollars_large_pcap 1L.troops L.y_pcap L.CERPdollars_large_pcap 1L2.troops 1L2.troops#cL.CERPdollars_large_pcap  )

* small projects
eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_small_pcap##L.troops L.y_pcap  L.c.CERPdollars_small_pcap##L2.troops i.week i.districtid if sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using small.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_small_pcap 1L.troops#c.CERPdollars_small_pcap 1L.troops L.y_pcap L.CERPdollars_small_pcap 1L2.troops 1L2.troops#cL.CERPdollars_small_pcap  )

********************
** Placebo Test (Table 13)
********************

eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap F.c.CERPdollars_pcap##troops c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops i.week i.districtid if sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using placebo.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(F.CERPdollars_pcap 1.troops#cF.CERPdollars_pcap 1.troops CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops ///
 L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap )


********************
** Appendix (Appendix Tables 1-24, Figures 1, 2)
********************

* Appendix A: Results by project types

	foreach i in 20 7 4 19 11{
eststo clear
foreach y in 3 18 19{
		rename type`y'_pcap y_pcap
		reg y_pcap c.CERPdollars_`i'_pcap##L.troops L.y_pcap  L.c.CERPdollars_`i'_pcap##L2.troops i.week i.districtid if sample==1, vce(cl districtid)
		eststo type`y'
		rename y_pcap type`y'_pcap
	}
	estout using projects`i'.tex, replace stats(r2 N)cells(b(star fmt(2)) ///
	se(par fmt(2))) style(tex) keep(CERPdollars_`i'_pcap 1L.troops#c.CERPdollars_`i'_pcap 1L.troops L.y_pcap L.CERPdollars_`i'_pcap 1L2.troops 1L2.troops#cL.CERPdollars_`i'_pcap)
	}
	
* Appendix B: Alternative Specifications

* Model 1
reg type3_pcap c.CERPdollars_pcap##troops i.week i.districtid if sample==1,vce(cl districtid)
predict residuals1, res
reg  residuals1 c.CERPdollars_pcap##troops L.residuals1

scalar N=_result(1)-1
scalar R2=_result(7) 
scalar NR2= N*R2-1 
scalar list N  R2  NR2 

scalar chi15=invchi2(1, .95) 
scalar p=1-chi2(1,NR2)
scalar list chi15 NR2 p

** Model 2
reg type3_pcap cD.CERPdollars_pcap##troops i.week i.districtid if sample==1, vce(cl districtid)
predict residuals2, res
reg residuals2 L.residuals2  cD.CERPdollars_pcap##troops 

scalar N=_result(1)-1
scalar R2=_result(7) 
scalar NR2= N*R2
scalar list N  R2  NR2 

scalar chi15=invchi2(1, .95) 
scalar p=1-chi2(1,NR2)
scalar list chi15 NR2 p

** Model 3

reg type3_pcap c.CERPdollars_pcap##L2.troops L.type3_pcap  L.c.CERPdollars_pcap##L2.troops i.week ///
i.districtid if sample==1,vce(cl districtid)
predict residuals3, res
reg  residuals3 c.CERPdollars_pcap##L.troops L.c.CERPdollars_pcap##L.troops L.residuals3

scalar N=_result(1)-1
scalar R2=_result(7) 
scalar NR2= N*R2
scalar list N  R2  NR2 

scalar chi15=invchi2(1, .95) 
scalar p=1-chi2(1,NR2)
scalar list chi15 NR2 p

** Model 4
reg type3_pcap c.CERPdollars_pcap##L.troops L.type3_pcap L2.type3_pcap L.c.CERPdollars_pcap##L2.troops L2.c.CERPdollars_pcap##L3.troops ///
i.week i.districtid if sample==1, vce(cl districtid)
predict residuals4, res

reg  residuals4 c.CERPdollars_pcap##L.troops L.c.CERPdollars_pcap##L2.troops L2.c.CERPdollars_pcap##L3.troops L.residuals4 

scalar N=_result(1)-1
scalar R2=_result(7) 
scalar NR2= N*R2
scalar list N  R2  NR2 

scalar chi15=invchi2(1, .95) 
scalar p=1-chi2(1,NR2)
scalar list chi15 NR2 p

** ADL-2 Results

gen sample2=sample
replace sample2=0 if missing(L2.type3_pcap)
	eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap L2.y_pcap  L.c.CERPdollars_pcap##L2.troops ///
L2.c.CERPdollars_pcap##L3.troops i.week i.districtid if sample2==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using adl2.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L2.y_pcap ///
 L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  L2.CERPdollars_pcap 1L3.troops 1L3.troops#cL2.CERPdollars_pcap  )

 ** Arellano Bond Estimator
 
 capture ssc install xtabond2
 mata: mata set matafavor speed, perm
 set more off
 
 	gen CERPdollars_pcap_Ltroops_int=(CERPdollars_pcap*L.troops)
	gen Ltroops=L.troops
	
eststo clear
xtabond2 type3_pcap l(0/1).CERPdollars_pcap l(0/1).CERPdollars_pcap_Ltroops_int l(0/1).Ltroops l(1/2).type3_pcap if sample2==1, gmm(CERPdollars_pcap CERPdollars_pcap_Ltroops_int Ltroops type3_pcap , lag (1 2))  cluster(districtid)
eststo
xtabond2 type18_pcap l(0/1).CERPdollars_pcap l(0/1).CERPdollars_pcap_Ltroops_int l(0/1).Ltroops l(1/2).type18_pcap if sample2==1, gmm(CERPdollars_pcap CERPdollars_pcap_Ltroops_int Ltroops type18_pcap, lag (1 2))  cluster(districtid)
eststo
xtabond2 type19_pcap l(0/1).CERPdollars_pcap l(0/1).CERPdollars_pcap_Ltroops_int l(0/1).Ltroops l(1/2).type19_pcap if sample2==1, gmm(CERPdollars_pcap CERPdollars_pcap_Ltroops_int Ltroops type19_pcap, lag (1 2))  cluster(districtid)
eststo
	
estout using arellano.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap CERPdollars_pcap_Ltroops_int Ltroops L.CERPdollars_pcap L.CERPdollars_pcap_Ltroops_int L.Ltroops  ///
 L.type3_pcap L2.type3_pcap L.type18_pcap L2.type18_pcap L.type19_pcap L2.type19_pcap  )


* Appendix C: Robustness Checks
use "$da/sexton-afg-apsr", clear
tsset districtid week
label_var

** Relationship between control and civilian aid
gen budget2=(budget_pcap>0)

eststo clear
reg budget_pcap troops i.districtid i.week, vce(cl districtid)
eststo
margins, at(troops=(0 1))
reg budget2 troops i.districtid i.week, vce(cl districtid)
eststo
margins, at(troops=(0 1))

estout using budgetaid.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(troops)
 
 ** Robustness of estimates to lagged control definition
 * eight weeks
 gen troops2=(L7.troops==1)
 * twelve 12 weeks
 gen troops3=(L11.troops==1)
 
 eststo clear
  reg type3_pcap c.CERPdollars_pcap##troops L.type3_pcap  L.c.CERPdollars_pcap##L.troops  ///
  i.week i.districtid if !missing(type3_pcap), vce(cl districtid)
  eststo
  rename troops troops0
  rename troops2 troops
   reg type3_pcap c.CERPdollars_pcap##troops L.type3_pcap  L.c.CERPdollars_pcap##L.troops  ///
  i.week i.districtid if !missing(type3_pcap), vce(cl districtid)
  eststo
  rename troops troops2
  rename troops3 troops
   reg type3_pcap c.CERPdollars_pcap##troops L.type3_pcap  L.c.CERPdollars_pcap##L.troops  ///
  i.week i.districtid if !missing(type3_pcap), vce(cl districtid)
  eststo
  rename troops troops3
  rename troops0 troops
  estout using redefine_control, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1.troops#c.CERPdollars_pcap 1.troops 1L.troops L.type3_pcap L.CERPdollars_pcap 1L.troops#cL.CERPdollars_pcap)


** Aggregation to  two and four weeks 
use projected_multiweek,clear 

texsave using multiweek.tex,replace 

** Regression outputs for multiweek aggregation
use "$da/sexton-afg-apsr", clear
tsset districtid week
label_var

eststo clear
reg type3_pcap c.CERPdollars_pcap##L.troops L.type3_pcap  L.c.CERPdollars_pcap##L.troops i.week i.districtid, vce(cl districtid)
eststo one

gen twoweek=ceil(week/2)
gen fourweek=ceil(week/4)
collapse (mean) *_pcap (mean) troops (mean) fourweek, by(twoweek districtid)
replace troops=ceil(troops)
tsset twoweek districtid

reg type3_pcap c.CERPdollars_pcap##L.troops L.type3_pcap  L.c.CERPdollars_pcap##L.troops  ///
  i.twoweek i.districtid if !missing(type3_pcap), vce(cl districtid)
eststo two	

collapse (mean) *_pcap (mean) troops, by(fourweek districtid)
replace troops=ceil(troops)
tsset fourweek districtid

reg type3_pcap c.CERPdollars_pcap##L.troops L.type3_pcap  L.c.CERPdollars_pcap##L.troops  ///
  i.fourweek i.districtid if !missing(type3_pcap), vce(cl districtid)
eststo	four	
estout using aggregate1.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.type3_pcap L.CERPdollars_pcap  1L.troops#cL.CERPdollars_pcap  )

** Reporting bias

use "$da/sexton-afg-apsr", clear
tsset districtid week
label_var

gen nonied_pcap=ansototal_pcap-type3_pcap

eststo clear
reg nonied_pcap c.CERPdollars_pcap##troops L.nonied_pcap L.c.CERPdollars_pcap##L.troops i.week i.districtid, vce(cl districtid)
eststo
estout using reporting_bias.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1.troops#c.CERPdollars_pcap 1.troops L.nonied_pcap L.CERPdollars_pcap 1L.troops 1L.troops#cL.CERPdollars_pcap  )

	** Influential observations and outliers
		** Dropping districts with high spending
		
		bysort districtid: egen CERP_district_mean=mean(CERPdollars_pcap)
eststo clear
foreach y in 3 18 19{
	rename type`y'_pcap y_pcap
	reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops ///
	i.week i.districtid if sample==1 & CERP_district_mean<.1815, vce(cl districtid)
	eststo
	rename y_pcap type`y'_pcap
	}
estout using influence1.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )
	
		** Drop the 34 Cook's D observations
		
qui reg type3_pcap c.CERPdollars_pcap##troops L.type3_pcap L2.type3_pcap L.c.CERPdollars_pcap##troops ///
 L2.c.CERPdollars_pcap##troops i.week i.districtid if !missing(type3_pcap)
predict d1, cook
gen influence=(d1>0.0101 & !missing(d1))
qui reg type18_pcap c.CERPdollars_pcap##troops L.type3_pcap L2.type3_pcap L.c.CERPdollars_pcap##troops ///
 L2.c.CERPdollars_pcap##troops i.week i.districtid if !missing(type3_pcap)
predict d2, cook
replace influence=1 if (d2>0.0101 & !missing(d2))==1
qui reg type19_pcap c.CERPdollars_pcap##troops L.type3_pcap L2.type3_pcap L.c.CERPdollars_pcap##troops ///
 L2.c.CERPdollars_pcap##troops i.week i.districtid if !missing(type3_pcap)
predict d3, cook
replace influence=1 if (d3>0.0101 & !missing(d3))==1

		** Drop the 34 Cook's D observations
		drop if influence==1
eststo clear
foreach y in 3 18 19{
	rename type`y'_pcap y_pcap
	reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops ///
	i.week i.districtid if sample==1 , vce(cl districtid)
	eststo
	rename y_pcap type`y'_pcap
	}
estout using influence2.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )
	
	** Geographic Sub-samples (South and East)
use "$da/sexton-afg-apsr", clear
tsset districtid week
label_var	
	* South

	eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops i.week i.districtid if sample==1 & region=="South", vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using south1, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )

   *East
  gen east=(province=="Khost" | province=="Nangarhar"| province=="Paktika" | province=="Paktia")
  
  	eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops i.week i.districtid if sample==1 & east==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using east1.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )

 	** Varying time effects
use "$da/sexton-afg-apsr", clear
tsset districtid week
label_var
** two and four week fixed effects
gen twoweek=ceil(week/2)
gen fourweek=ceil(week/4)

eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops i.twoweek i.districtid if sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using twoweek-fe.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )

 eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops i.fourweek i.districtid if sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using fourweek-fe.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )

 ** linear and quadratic time trend
gen week2=(week*week)

eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops week i.districtid if sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using linear-week.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap week  )

 eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap  L.c.CERPdollars_pcap##L2.troops week week2 i.districtid if sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using quad-week.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap week week2  )

 ** Include civilian aid as a covariate
	eststo clear
foreach y in 3 18 19{
rename type`y'_pcap y_pcap
reg y_pcap c.CERPdollars_pcap##L.troops L.y_pcap budget_pcap L.budget_pcap  L.c.CERPdollars_pcap##L2.troops i.week i.districtid if sample==1, vce(cl districtid)
eststo
rename y_pcap type`y'_pcap
}
estout using budget1, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.y_pcap budget_pcap L.budget_pcap L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )

 	** Robust to missing ANSO data
	eststo clear
replace type3_pcap=0 if missing(type3_pcap)
reg type3_pcap c.CERPdollars_pcap##L.troops L.type3_pcap  L.c.CERPdollars_pcap##L2.troops i.week i.districtid, vce(cl districtid)
eststo
di .0471329+(3*.1887003)
gen y_checkhigh=type3_pcap
replace y_checkhigh=.6132338 if missing(type3_pcap)
 reg y_checkhigh c.CERPdollars_pcap##L.troops L.y_checkhigh  L.c.CERPdollars_pcap##L2.troops i.week i.districtid, vce(cl districtid)
eststo
estout using missing1.tex, replace stats(r2 N)cells(b(star fmt(2)) se(par fmt(2))) ///
 style(tex) keep(CERPdollars_pcap 1L.troops#c.CERPdollars_pcap 1L.troops L.type3_pcap L.y_checkhigh  L.CERPdollars_pcap 1L2.troops 1L2.troops#cL.CERPdollars_pcap  )

 *Appendix E: Additional Northern Distribution Network Figures
 
 use "$da/sexton-afg-apsr", clear
tsset districtid week
label_var

keep if province=="Baghlan" | province=="Balkh" | province=="Samangan" | province=="Parwan"
gen after=(week>=42)
keep if week>30 & week<54

foreach y in type3_pcap type18_pcap type19_pcap {
replace `y'=(`y'*6.53)
bysort week: egen `y'2=mean(`y')
}

tsset districtid week

twoway (scatter type3_pcap2 week) (lpoly type3_pcap week if after==1, lc(black) k(gau)) (lpoly type3_pcap week if after==0, lc(black) k(gau)) /// 
(lpolyci type3_pcap week if after==1,ciplot(rline) k(gau) level(90)) (lpolyci type3_pcap week if after==0,ciplot(rline) k(gau) level(90))  ///
 , xline(41.5) xlabel(41.5 "Nothern Distribution Network Start") ytitle("Incidents per 65,300 population")  ///
legend(off) title("Bombing Incidents by Week in NDN Provinces") name(c, replace)
graph export NDN3.pdf, as(pdf) replace


twoway (scatter type18_pcap2 week) (lpoly type18_pcap week if after==1, lc(black) k(gau)) (lpoly type18_pcap week if after==0, lc(black) k(gau)) /// 
(lpolyci type18_pcap week if after==1,ciplot(rline) k(gau) level(90)) (lpolyci type18_pcap week if after==0,ciplot(rline) k(gau) level(90))  ///
 , xline(41.5) xlabel(41.5 "Nothern Distribution Network Start") ytitle("Incidents per 65,300 population") ///
legend(off) title("Enemy Actions by Week in NDN Provinces") name(d, replace)
graph export NDN4.pdf, as(pdf) replace



