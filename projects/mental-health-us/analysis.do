
**************************************************************************
*/////////////////////////// ECONOMETRICS CODE //////////////////////////*
**************************************************************************

********************************************************
*////////////////////// PREAMBLE //////////////////////*
********************************************************

// TITLE : The prevalence of anxiety and depression disorder with demographic and socio-economic factors : the case of the United States
// CODER NAME : BAPTISTE MESSANT, MAELLE TCHOUKRIEL--EYRAUD, VICTORIA GODIO
// LAST MODIFICATION DATE : 26/02/2025
// SOFTWARE VERSION : STATA SE 18.5
// PROCESSORS : 2,9 GHz Intel Core i5 double cœur
// MACHINE : MACBOOK PRO 
// MACHINE VERSION : macOS Monteney 12.7.6


************************************************************************************
*////////////////////// BEGENING OF THE ECONOMETRIC ANALYSIS //////////////////////*
************************************************************************************

clear all

// this file start the log file 

log using LOG_APPLIED_GROUP_5.txt, replace text

// setting the path to the computer 

global path "/Users/baptiste/Desktop/Master_1/applied_bdd_$"
cd "$path"

// charging the data 

use MHCLDcomb.dta, clear

// we use the destring function in order to transform our variables in bytes instead of string 
// in order to run our econometrics analysis 


destring age, replace
destring employment_status, replace 
destring education, replace
destring residential_status, replace
destring gender, replace
destring race, replace
destring marital_status, replace
destring not_labor_force_status, replace
destring region, replace 


// we use the label function in order to attribute a label to every value of the differents variables, this enable us to have clearer results when we regress on the variables 

label define age_label 1 "0-11 years" 2 "12-14 years " 3 "15-17 years" 4 "18-20 years " 5 "21-24 years" 6 "25-29 years " 7 "30-34 years" 8 "35-39 years " 9 "40-44 years" 10 "45-49 years " 11 "50-54 years" 12 "55-59 years " 13 "60-64 years" 14 "65 years and older "
label values age age_label

label define education_label 1 "Special education" 2 "0 to 8 " 3 "9 to 11" 4 "12 (or GED) " 5 "More than 12"
label values education education_label

label define race_label 1 "American Indian/Alaska Native" 2 "Asian" 3 "Black or African American" 4 "Native Hawaiian or Other Pacific Islander" 5 "White" 6 "Some other race alone/two or more races"
label values race race_label 

label define gender_label 1 "Male" 2 "Female"
label values gender gender_label

label define marital_status_label 1 "Never married" 2 "Now married " 3 "Separated" 4 "Divorced, widowed"
label values marital_status marital_status_label

label define employment_status_label 1 "Full-time" 2 "Part-time" 3 "Employed full-time/part-time not differentiated" 4 "Unemployed" 5 "Not in labor force"
label values employment_status employment_status_label

label define not_labor_force_status_label 1 "Retired, disabled" 2 "Student" 3 "Homemaker" 4 "Sheltered/non-competitive employment " 5 "Other"
label values not_labor_force_status not_labor_force_status_label

label define residential_status_label 1 "Experiencing Homelessness" 2 "Private residence " 3 "Other" 
label values residential_status residential_status_label

label define region_label 0 "Other jurisdictions" 1 "Northeast" 2 "Midwest" 3 "South" 4 "West"
label values region region_label 



*********************************************************************
*////////////////////////// RESEARCH PART //////////////////////////*
*********************************************************************



// in this part we done a lot of regressions in order to find the relevant results on our dependant variable so those regression will not figure in the report. All the regressions that will be use in the report and in the presentation are in the anxiety final model part and in the depression final model part.



********************************************************************
*////////////////////// ANXIETY (anxietyflg) //////////////////////*  
********************************************************************



// here we use the stepwise command in order to create a model with only the relevant variables 

// log close
// log using results_probit.log, replace

// here we filter the variables in the dataset to be more efficient 

// use anxiety gender marstat race age region educ employ livarag detnlf before_covid during_covid after_covid using MHCLDcomb.dta

// We reduce the sample to 5% since we have too many data our computer dosen't run the the stepwise function 

// sample 5
// stepwise, pe(.05) : probit anxiety i.age i.race i.gender i.marstat i.region i.educ i.employ i.livarag i.detnlf

// here we are doing multiple regression in order to look at the differents interactions within the variables 
// this is in order to best explain what impact the output 

// here we use the full dataset to see the interactions 
// in this part we are regressing anxiety on different variable in order to see lots of interaction we always use the same syntax 

//all the regression are in green since they were used to define our models so they are not interesting and will not figure in the report 

// log close
// log using employ*educ_educ*detnlf.log, replace
// probit anxiety i.employ##i.educ i.detnlf##i.educ

// log close 
// log using gender*marstat_gender*employ_gender*detnlf.log, replace 
// probit anxiety gender##marstat gender##employ gender##detnlf

// log close 
// log using marstat*employ_marstat*detnlf.log, replace 
// probit anxiety marstat##employ marstat##detnlf

// log close 
// log using region*educ_region*employ.log, replace 
// probit anxiety region##educ region##employ

// log close 
// log using race*employ_race*detnlf.log, replace 
// probit anxiety race##employ race##detnlf

// log close 
// log using region*detnlf_region*race_region*genre.log, replace 
// probit anxiety region##detnlf region##race region##gender

// log close 
// log using educ*marstat_educ*race.log, replace
// probit anxiety educ##marstat educ##race

// log close 
// log using marstat*livarag.log,replace
// probit anxiety marstat##livarag

// log close 
// log using age*employ_age*region_age*detnlf_age*educ.log, replace
// probit anxiety age##employ age##region age##educ age##detnlf

// log close 
// log using anxiety_full.log, replace 
// probit anxiety i.gender i.age i.region i.livarag i.employ i.educ i.detnlf educ#age educ#race educ#detnlf region#gender region#educ region#employ gender#detnlf

// log close 
// log using anxiety_employ_interaction.log, replace
// probit anxiety i.employ employ#region employ#educ employ#gender employ#livarag employ#detnlf employ#age employ#marstat 

// log close 
// log using anxiety_final_all_periods.log, replace 
// probit anxiety i.gender i.age i.region i.livarag i.marstat i.educ i.detnlf marstat#age educ#age educ#race educ#region detnlf#region marstat#gender marstat#educ educ#detnlf age#gender age#region detnlf#age age#race race#region

// log close 
// log using anxiety_final_before_covid.log, replace 
// probit anxiety i.gender i.age i.region i.livarag i.marstat i.educ i.detnlf marstat#age educ#age educ#race educ#region detnlf#region marstat#gender marstat#educ educ#detnlf age#gender age#region detnlf#age age#race race#region if before_covid == 1

// log close 
// log using anxiety_final_during_covid.log, replace 
// probit anxiety i.gender i.age i.region i.livarag i.marstat i.educ i.detnlf marstat#age educ#age educ#race educ#region detnlf#region marstat#gender marstat#educ educ#detnlf age#gender age#region detnlf#age age#race race#region if during_covid == 1

// log close 
// log using anxiety_final_after_covid.log, replace 
// probit anxiety i.gender i.age i.region i.livarag i.marstat i.educ i.detnlf marstat#age educ#age educ#race educ#region detnlf#region marstat#gender marstat#educ educ#detnlf age#gender age#region detnlf#age age#race race#region if after_covid == 1

// log close 
// log using anxiety2.log, replace
// probit anxiety i.gender i.region i.age i.livarag i.educ i.detnlf i.race educ#region educ#detnlf educ#age detnlf#region region#race gender#age 

// log close 
// log using anxiety3_before.log, replace
// probit anxiety i.gender i.region i.age i.livarag i.educ i.detnlf educ#region educ#detnlf educ#age detnlf#age gender#age age#region if before_covid == 1

// log close 
// log using anxiety3_during.log, replace
// probit anxiety i.gender i.region i.age i.livarag i.educ i.detnlf educ#region educ#detnlf educ#age detnlf#age gender#age age#region if during_covid == 1

// log close 
// log using anxiety3_after.log, replace
// probit anxiety i.gender i.region i.age i.livarag i.educ i.detnlf educ#region educ#detnlf educ#age detnlf#age gender#age age#region if after_covid == 1

// log close 
// log using Model_4A.log, replace 
// probit anxiety ib2.education#race#ib1.region ib1.region#race ib3.employment_status#ib2.education#ib1.region 



***********************************************************************
*////////////////////// DEPRESSION (depressflg) //////////////////////*
***********************************************************************


// here we do the same thing as before but for the variable depression 

// log close
// log using ascendant_depression.log, replace
// use depressflg gender marstat race age region educ employ livarag detnlf before_covid during_covid after_covid using MHCLDcomb.dta
// sample 5
// stepwise, pe(.05) : probit depressflg i.age i.race i.gender i.marstat i.region i.educ i.employ i.livarag i.detnlf

// all the regressions are in green since they were used to define our models, so they are not interesting and will not figure in the report 

// log close 
// log using depression_first_interaction.log,replace
// probit depressflg i.gender i.region i.educ i.employ i.detnlf educ#detnlf educ#race educ#employ region#livarag region#detnlf  region#race  region#educ  region#employ gender#employ gender#educ gender#livarag gender#region gender#detnlf

// log close 
// log using depression_employ_interaction.log, replace
// probit depressflg i.employ employ#region employ#educ employ#gender employ#livarag employ#detnlf employ#age employ#marstat 

// log close 
// log using depression1.log, replace 
// probit depressflg i.age i.gender i.employ i.region gender#marstat gender#employ gender#race employ#educ gender#age race#region educ#race livarag#employ livarag#region 

// log close 
// log using depression1_employ4_educ5_livarag1.log , replace 
// probit depressflg i.age i.gender i.employ i.region gender#marstat gender#employ gender#race employ#educ gender#age race#region educ#race livarag#employ livarag#region  if educ == 5 & employ == 4 & livarag == 1 

// log close 
// log using depression2_employ4_race3_region3_educ5_livarag1.log, replace 
// probit depressflg i.age i.gender i.employ i.region gender#marstat gender#employ race#region gender#race employ#educ gender#age race#region educ#race livarag#employ livarag#region if employ == 4 & race == 3 & region == 3 & educ == 5

// log close 
// log using depression3.log, replace 
// probit depressflg i.gender i.age i.employ i.educ i.region i.detnlf detnlf#gender gender#marstat employ#educ educ#race livarag#employ livarag#region livarag#educ gender#region age#employ 

// log close 
// log using depression4.log, replace 
// probit depressflg race##region race##livarag educ##race i.gender 

// log close 
// log using depression5.log, replace 
// probit depressflg i.livarag i.employ i.region i.age livarag#employ livarag#region livarag##age livarag#educ

// log close 
// log using depression7.log, replace 
// probit depressflg i.age i.educ i.employ i.region i.gender i.detnlf detnlf#age race#livarag gender#marstat employ#educ livarag#region age#employ 

// log close 
// log using depression8.log, replace 
// probit depressflg i.age ib2.educ ib5.employ ib4.region i.gender ib3.livarag i.detnlf race#livarag gender#marstat livarag#region

// log close 
// log using depression9.log, replace
// probit depressflg employ##age employ#educ employ#gender

// log close 
// log using depression10.log, replace 
// probit depressflg livarag##region livarag#race livarag#detnlf livarag#employ


// log close 
// log using Model_2D.log, replace 
// probit depression gender##marital_status gender#age 


// log close 
// log using Model_4D.log, replace 
// probit depression ib2.education ib2.education#gender ib2.education#age ib1.region#race ib1.region


// log close 
// log using model2NEW.log,replace
// probit depression ib2.education i.gender i.marital_status gender#marital_status ib2.education#gender, robust



************************************************************
*////////////////////// FINAL MODELS  /////////////////////*
************************************************************



// in these two last part we provide the final models of the econometrics analysis it also contain all the graphs we have used in the report 



****************************************************************************
*////////////////////// ANXIETY FINAL MODEL (anxiety) /////////////////////*
****************************************************************************


// Model 1A

probit anxiety i.age i.employment_status  ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust

// this show the marginals effects on the Model_1A in order to get interpretable coefficents (magnitude)

margins, dydx(*)


// Model 3A 

probit anxiety ib3.employment_status ib3.employment_status#ib1.region ib3.employment_status#ib2.education ib3.employment_status#gender ib3.employment_status#age, robust

// margins, dydx(*)

// Marginals effects Model 3A

// the condition if uniform() < 0.1 allow us to select only 10% of our database randomly, we do this since it is to big to compute the marginal effect for models with interactions inside. 

// the command atmeans allow us to compute the marginal effect on the means of the coeficient and not on based on each observation we used this in order to regress it faster 

// the at command allow us to derive the marginals effect of interactions between variables 

// probit anxiety ib3.employment_status ib3.employment_status#ib1.region ib3.employment_status#ib2.education ib3.employment_status#gender ib3.employment_status#age if uniform() < 0.1, robust


// margins, dydx(employment_status) at(region = (0(1)4)) atmeans


// margins, dydx(employment_status) at(education = (1(1)4)) atmeans


// margins, dydx(employment_status) at(gender = (1(1)2)) atmeans




**********************************************************************************
*///////////////////// DEPRESSION FINAL MODEL (depression) //////////////////////*
**********************************************************************************

// Model 1D

probit depression i.employment_status i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust

// this show the marginals effects on the Model_1D in order to get interpretable coefficents (magnitude)

margins,dydx(*)


// Model 3D 

probit depression ib3.employment_status ib3.employment_status#ib2.education ib3.employment_status#gender ib3.employment_status#ib1.region, robust

// margins, dydx(*)

// Marginals effects Model 3D

// the condition if uniform() < 0.1 allow us to select only 10% of our database randomly, we do this since it is to big to compute the marginal effect for models with interactions inside. 

// the command atmeans allow us to compute the marginal effect on the means of the coeficient and not on based on each observation we used this in order to regress it faster 

// the at command allow us to derive the marginals effect of interactions between variables 

// probit depression ib3.employment_status ib3.employment_status#ib2.education ib3.employment_status#gender ib3.employment_status#ib1.region if uniform() < 0.1, robust


// margins, dydx(employment_status) at(education = (1(1)5)) atmeans


// margins, dydx(employment_status) at(gender = (1(1)2)) atmeans

 
// margins, dydx(employment_status) at(region = (0(1)4)) atmeans


*************************************
*///////////// GRAPHS //////////////*
*************************************


// in this section we will code all the differents graphs we have used in the paper and/or in the oral presentation to explain or present our results. Before each graph you have a caption that indicate you the number of the corresponding figure in our research paper.


*********************************
* figure number 1 in the paper  *
*********************************

// this graph provide a represention of the predicted probability to be depressed or anxious by age 

// here we are regressing and computing the estimated probability for both models 

probit depression i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust
margins age, predict(pr) asbalanced saving(depression_age_margins, replace)


probit anxiety i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust
margins age, predict(pr) asbalanced saving(anxiety_age_margins, replace)

// the command combomarginsplot allow us to plot the predicted probability of the 2 models on the same graph 

combomarginsplot depression_age_margins anxiety_age_margins, ///
    legend(order(1 "Depression" 2 "Anxiety")) ///
    xtitle("AGE") ///
    ytitle("Estimated probability") ///
    xlabel(1 "0-11" 2 "12-14" 3 "15-17" 4 "18-20" 5 "21-24" 6 "25-29" ///
           7 "30-34" 8 "35-39" 9 "40-44" 10 "45-49" 11 "50-54" ///
           12 "55-59" 13 "60-64" 14 "65 +", labsize(vsmall)) ///
	title("")
// this line save the graph as a pdf 

graph export "anxiety_depression_age.pdf", as(pdf) replace


*********************************
* figure number 2 in the paper  *
*********************************

// this graph provide a represention of the predicted probability to be depressed or anxious by race

// here we are regressing and computing the estimated probability for both models 

probit depression i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust
margins education, predict(pr) asbalanced saving(depression_education_margins, replace)


probit anxiety i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust
margins education, predict(pr) asbalanced saving(anxiety_education_margins, replace)

// the command combomarginsplot allow us to plot the predicted probability of the 2 models on the same graph 

combomarginsplot depression_education_margins anxiety_education_margins, ///
    legend(order(1 "Depression" 2 "Anxiety")) ///
    xtitle("EDUC") ///
    ytitle("Estimated probability") ///
    xlabel(1 "Special education" 2 "0 to 8 " 3 "9 to 11" 4 "12 (or GED) " 5 "More than 12", labsize(vsmall)) ///
    title("")

// this line save the graph as a pdf 

graph export "anxiety_depression_educ.pdf", as(pdf) replace



*********************************
* figure number 3 in the paper  *
*********************************


// this graph provide a represention of the predicted probability to be depressed or anxious by race

// here we are regressing and computing the estimated probability for both models 

probit depression i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust
margins race, predict(pr) saving(depression_race_margins, replace)


probit anxiety i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust
margins race, predict(pr) saving(anxiety_race_margins, replace)

// the command combomarginsplot allow us to plot the predicted probability of the 2 models on the same graph, the last two lines allow us to delete the lines between the point in the graph and also to increase the size of the points 

combomarginsplot depression_race_margins anxiety_race_margins, ///
    legend(order(1 "Depression" 2 "Anxiety")) ///
    xtitle("RACE") ///
    ytitle("Estimated probability") ///
    xlabel(1 "American Indian/Alaska Native" 2 "Asian" 3 "Black or African American" 4 "Pacific Islander" 5 "White" 6 "other or two races", labsize(vsmall)) ///
    title("") ///
    plot1opts(msymbol(O) connect(none) msize(large)) ///
    plot2opts(msymbol(O) connect(none) msize(large))
	
// this line save the graph as a pdf 

graph export "anxiety_depression_race.pdf", as(pdf) replace


*********************************
* figure number 4 in the paper  *
*********************************

	
// this graph provide a represention of the predicted probability to be depressed or anxious by region

// here we are regressing and computing the estimated probability for both models 

probit depression i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust
margins region, predict(pr) saving(depression_region_margins, replace)


probit anxiety i.age ib2.education i.race i.gender i.marital_status i.not_labor_force_status ib2.residential_status ib1.region, robust
margins region, predict(pr) saving(anxiety_region_margins, replace)

// the command combomarginsplot allow us to plot the predicted probability of the 2 models on the same graph, the last two lines allow us to delete the lines between the point in the graph and also to increase the size of the points 
	
combomarginsplot depression_region_margins anxiety_region_margins, ///
    legend(order(1 "Depression" 2 "Anxiety")) ///
    xtitle("REGION") ///
    ytitle("Estimated probability") ///
    xlabel(0 "Other jurisdictions" 1 "Northeast" 2 "Midwest" 3 "South" 4 "West", labsize(vsmall)) ///
    title("") ///
    plot1opts(msymbol(O) connect(none) msize(large)) ///
    plot2opts(msymbol(O) connect(none) msize(large))
	
// this line save the graph as a pdf 

graph export "anxiety_depression_region.pdf", as(pdf) replace


*********************************
* figure number 5 in the paper  *
*********************************

// this graph provide a represention of the predicted probability to be depressed by employment status and education

// here we are regressing and computing the estimated probability for the model 

probit depression ib3.employment_status ib3.employment_status#ib2.education ib3.employment_status#gender ib3.employment_status#ib1.region, robust
margins employment_status#education, predict(pr) asbalanced saving(anxiety_employ#educ_margins, replace)

// the command combomarginsplot allow us to plot the predicted probability of the model on the graph 

combomarginsplot depression_employ#educ_margins, ///
    noci ///
    xtitle("EMPLOY") ///
    ytitle("Estimated probability") ///
    xlabel(1 "Full-time" 2 "Part-time" 3 "full-time/part-time not differ" 4 "Unemployed" 5 "Not in labor force", labsize(vsmall)) ///
    title("", size(small))

// this line save the graph as a pdf 
	
graph export "depression_employ#educ.pdf", as(pdf) replace

// in this graph we have modified it manualy by deleting the line corresponding to "special education", because it wasn't necessary in the reseach paper. 


*********************************
* figure number 6 in the paper  *
*********************************

// this graph provide a represention of the predicted probability to be anxious by employment status and education

// here we are regressing and computing the estimated probability for the model

probit anxiety ib3.employment_status ib3.employment_status#ib1.region ib3.employment_status#ib2.education ib3.employment_status#gender ib3.employment_status#age, robust
margins employment_status#education, predict(pr) asbalanced saving(depression_employ#educ_margins, replace)

// the command combomarginsplot allow us to plot the predicted probability of the model on the graph 

combomarginsplot anxiety_employ#educ_margins, ///
    noci ///
    xtitle("EMPLOY") ///
    ytitle("Estimated probability") ///
    xlabel(1 "Full-time" 2 "Part-time" 3 "full-time/part-time not differ" 4 "Unemployed" 5 "Not in labor force", labsize(vsmall)) ///
    title("", size(small))

// this line save the graph as a pdf 	

graph export "anxiety_employ#educ.pdf", as(pdf) replace

// in this graph we have modified it manualy by deleting the line corresponding to "special education", because it wasn't necessary in the reseach paper. 

	
// this command close the log file 
	
log close 
