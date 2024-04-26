********************************************************************************
** 	TITLE	: pol_econ_replication 
**	PURPOSE	: This .do replicates the main tables from Sextion 2016 and extends the analysis
**	AUTHOR	: Rachel Pizatella
**	DATE	: 04/10/2024 | DATE MODIFIED: 04/25/2024
********************************************************************************

*********************************** GLOBALS ************************************

	clear all
	set more off
	set maxvar 50000


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
	
*********************************** ANALYSIS ***********************************

**# Figure 2 - 3
*------------------------------------------------------------------------------*	
	
	/* NOTES
	------------------------
	See jupyter notebook
	
	------------------------
	*/

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

**# Table 7
*------------------------------------------------------------------------------*	
	* run regression 
	foreach var of varlist bombings enemy_actions exp_hazards {
		reg `var' c.CERP##controlled_L1 L.c.CERP##controlled_L2 `var'_L1 ///
		`var'_neighb `var'_neighb_L1 i.districtid i.week if sample==1 , vce(cl districtid)
	}
	
**# Table 8
*------------------------------------------------------------------------------*	
	* run regression 
	foreach var of varlist bombings enemy_actions exp_hazards {
		reg `var'_neighb c.CERP##controlled_L1 L.c.CERP##controlled_L2 ///
		`var'_neighb_L1 i.districtid i.week if sample==1 , vce(cl districtid)
	}
	
************************************** ++ **************************************

**# Province level analysis
*------------------------------------------------------------------------------*	
	preserve
	* Create province-level variables 
	sort province week
	foreach var of varlist CERP controlled bombings enemy_actions exp_hazards {
		egen `var'_prov = total(`var'), by(province week)
	}
	
	replace controlled_prov = 1 if controlled_prov > 0
		
	* Keep only 1 observation per province per week
	duplicates drop province week, force
		
	* Main results at province level 
	encode province, gen(provinceid)

	tsset provinceid week

	foreach var of varlist bombings_prov enemy_actions_prov exp_hazards_prov {
		reg `var' c.CERP_prov##L.controlled_prov ///
		L.c.CERP_prov##L2.controlled_prov L.`var' i.provinceid i.week ///
		if sample==1 , vce(cl provinceid)
	}
	restore
	
**# Urban vs. rural 
*------------------------------------------------------------------------------*	
	* urban districts 
	gen urban = 0
	replace urban = 1 if strpos(province, "Kabul" "Herat" "Nangarhar" "Balkh" "Kandahar")
	
	* run regression
	foreach var of varlist bombings enemy_actions exp_hazards {
		reg `var' c.CERP##urban L.`var' i.week i.districtid if sample==1 , vce(cl districtid)
	}

	
**# Sensitivity
*------------------------------------------------------------------------------*	
	
	* create lagged variables 
	foreach var of varlist bombings enemy_actions exp_hazards {
		forval i = 1/138 {
			gen `var'_`i' = L`i'.`var'
		}		
	}
	
	* run regressions and store estimates 
	gen weeks = _n - 1
	gen est_bomb = .
	gen est_enemy = .
	gen est_explos = .
	
	foreach var of varlist bombings enemy_actions exp_hazards{
		rename `var' `var'_0
	}

	forval i = 0/50 {
		quietly reg bombings_`i' c.CERP##controlled_L1 L.c.CERP##controlled_L2 bombings_1 ///
    i.districtid i.week if sample == 1 , vce(cluster districtid)
	scalar coef`i' = _b[CERP]
	replace est_bomb = coef`i' if weeks == `i'
	
		quietly reg enemy_actions_`i' c.CERP##controlled_L1 L.c.CERP##controlled_L2 enemy_actions_1 ///
    i.districtid i.week if sample == 1 , vce(cluster districtid)
	scalar coef_e`i' = _b[CERP]
	replace est_enemy = coef_e`i' if weeks == `i'

	
		quietly reg exp_hazards_`i' c.CERP##controlled_L1 L.c.CERP##controlled_L2 exp_hazards_1 ///
    i.districtid i.week if sample == 1 , vce(cluster districtid)
	scalar coefex`i' = _b[CERP]
	replace est_explos = coefex`i' if weeks == `i'
	}	
	
	* plot 
	grstyle init
	grstyle set imesh, horizontal compact minor
	grstyle set legend 4, nobox stack
	grstyle linewidth plineplot 0.7
	grstyle set color hue, n(4)
	
	preserve
	drop if weeks >51
	twoway line est_bomb est_enemy est_explos weeks, title("Violent outcomes over time") 
	graph save "$ta/outcomes_timelags_50.gph", replace
	restore 
	
	preserve
	drop if weeks >13
	twoway line est_bomb est_enemy est_explos weeks, title("Violent outcomes over time") 
	graph save "$ta/outcomes_timelags_12.gph", replace
	restore 
	
	preserve	
	drop if weeks >5
	twoway line est_bomb est_enemy est_explos weeks, title("Violent outcomes over time") 
	graph save "$ta/outcomes_timelags_5.gph", replace
	restore 
		

	
	