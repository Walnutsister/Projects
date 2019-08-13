**************************************
****Final Do File Cleaning and Aggregating**
**************************************


//Create vulerable index in the roster dataset
use "/Users/panwen/Desktop/LGPA Data Final/LGPA_roster.dta", clear

***********************
***EDUCATION***********
***********************

//NEET: a person who is "Not in Education, Employment, or Training"; aged between 16 and 24
//Create age index (age = 1 if people aged between 16 and 24)
gen age = 0
replace age = 1 if Q_152 >= 15 & Q_152 <= 29
label var age "if a person's age is between 15 and 29, age = 1 yes, age = 0 no"

//Create education index
gen ineduc = 0
replace ineduc = 1 if Q_159 == 1
label var ineduc "if this person is currently in education, ineduc = 1 yes, ineduc = 0 no"

//Create employment index
gen inemp = 0
replace inemp =1 if Q_163 ==1 
label var inemp "if this person is currently in employment, inemp = 1 yes, inemp = 0 no"

//Create marginalization index (NEET)
gen edu_vul_neet = 0
replace edu_vul_neet = 1 if age == 1 & inedu ==0 & inemp == 0
label var edu_vul_neet "if this person is marginalized in education, mar= 1 yes, mar = 0 no"

********************
***HEALTH***********
********************

// Create vulnerable indicator of health facility for individual level
//According to definition of marginalized population, we focus on children under 15 and the elderly above 60.
generate hlth_vul_age = 1
replace hlth_vul_age = 0 if Q_152 >15 &  Q_152 < 60

label var hlth_vul_age "Is this individual under 15 or above 60?"

// Create a variable accounting for the number of people in the household 
// Collapse the individual data to household level
gen num_ppl =1

collapse (max) edu_vul_neet (mean) hlth_vul_age (sum) num_ppl, by(hhid)

save marginalization, replace

// Process household level data
use "/Users/panwen/Desktop/LGPA Data Final/LGPA_questionnaire_data.dta",clear

***********************
***EDUCATION***********
***********************

//Nearest primary school is Govt school indicator, baseline is private, UNWRA, or other.
recode Q3_04_1 (1 = 1 "Governmental") (2 3 88 = 0 "Non_governmental"), gen(pri_govt)
label var pri_govt "nearest primary school type, 1=Governmental; 0=Non_governmental"

//Nearest secondary school is Govt school indicator, baseline is private, UNWRA, or other.
recode Q3_04_2 (1 = 1 "Governmental") (2 3 88 = 0 "Non_governmental"), gen(sec_govt)
label var sec_govt "nearest secondary school type, 1=Governmental; 0=Non_governmental"

//recode Q3_05_1:do children in your household attend primary school?1= yes; 0= no
recode Q3_05_1 (1 = 1 "yes") (2 = 0 "no"), gen(attend_pri_govt)
label var attend_pri_govt "children in your hh attend primary (gov)school? 1= yes; 0= no"


//recode Q3_05_2:do children in your household attend secondary school?1= yes; 0= no
recode Q3_05_2 (1 = 1 "yes") (2 = 0 "no"), gen(attend_sec_govt)
label var attend_sec_govt "children in your hh attend secondary (gov)school? 1= yes; 0= no"

********************
***HEALTH***********
********************

//Use Q4_02_* to check the distance for each household to the nearest health facilities
codebook Q4_02_1 Q4_02_2 Q4_02_3 Q4_02_4 Q4_02_5

egen countmiss = rowmiss(Q4_02_*)
sum Q4_02_* if countmiss == 1

//Create househould level indicator for sufficient services
// If one household cannot arrive at all three health facilities in 10 minutes, it is marginalized.
generate hlth_svc_dist = 0
replace hlth_svc_dist = 1 if Q4_02_1 < 10 | Q4_02_2 < 10 | Q4_02_3 < 10
label var hlth_svc_dist "Can the household drive to any of the nearest health facilities in 10 min?"

egen countmiss1 = rowmiss(Q4_02_1 Q4_02_2 Q4_02_3)
replace hlth_svc_dist =. if countmiss1 >= 2

codebook Q4_10
recode Q4_10 (1 = 1 "yes") (2 = 0 "no"), gen(hlth_vul_diarr)

drop countmiss countmiss1

******************************
***WATER & SANITATION*********
******************************


//Based on the UN 20 definitions about marginalization, we choose to address the vulnerable group
// "Gaza residents without access to sanitation or water" in this case.

//create vulnerability indicator: Gaza residents without access to sanitation or water
gen gaza_vul = 0
replace gaza_vul = 1 if gaza ==1 & (Q2_03_3 ==2 | Q2_03_4 ==2)

// Service provision: if your household connected to the pipe water network or piped sewage system
gen water_sani_svc = 0
replace water_sani_svc = 1 if gaza ==1 & (Q6_10 ==1 | Q7_8 ==1)

**************************************
***SERIVCE FOR DISABLED PPL***********
**************************************

//Create household level indicator for access to waste collection and electricity and public transport
// If one household doesn't have access to waste collection and electricity and public transport, it is marginalized.
generate access_svc = 0
replace access_svc = 1 if Q2_03_1 == 1 & Q2_03_5 == 1 & Q2_03_9 == 1
label var access_svc "Does the household have access to waste collection or electricity grid, or public transport?"

********************
***MERGE***********
********************

merge 1:1 hhid using "/Users/panwen/Desktop/LGPA Data Final/marginalization.dta"
drop _merge

//Get the hh weights from the hh analytical dataset
merge 1:1 hhid using "/Users/panwen/Desktop/LGPA Data Final/LGPA_analytical_household.dta"
drop _merge hhmemb bottom_40_west_bank bottom_40_gaza regions rural lgu_size distance_wall_hh area_c_dum_hh acc_imp_wat acc_imp_san acc_pav_roa Gender_hhhead poor

rename Q1_07 LGU_Name
rename Q1_08 LGU_ID
rename Q1_06 Governorate

//generate the education services sufficiency index
gen pri_edu_svc = 0
replace pri_edu_svc =1 if Q3_02_1 <= 10
label var pri_edu_svc "average mins from the nearest Primary School from your house <= 10mins"

gen sec_edu_svc = 0
replace sec_edu_svc =1 if Q3_02_2 <= 15 
label var sec_edu_svc "average mins from the nearest secondary School from your house <= 15mins"

//Put disability into consideration
recode Q12_8 (1 = 1 "yes") (2 = 0 "no"), gen(hlth_vul_disab)
//8.11% of households claim that there is at least one member in his household with disability.


// Create person weights using the number of the people in the household
gen person_weight = survey_weight * num_ppl

//aggregate hh data to lgu level
 collapse (mean) pri_edu_svc sec_edu_svc Q3_02_1 Q3_02_2 pri_govt sec_govt attend_pri_govt attend_sec_govt edu_vul_neet hlth_vul_age hlth_svc_dist hlth_vul_diarr gaza_vul water_sani_svc hlth_vul_disab access_svc (first) LGU_Name Governorate [pweight = person_weight], by(LGU_ID)

***********************
***EDUCATION***********
***********************

//rename the education services sufficiency index
rename Q3_02_1 pri_edu_svc_dist
label var pri_edu_svc_dist "average mins from the nearest Primary School from your house in this LGU"

rename Q3_02_2 sec_edu_svc_dist
label var sec_edu_svc_dist "average mins from the nearest Secondary School from your house in this LGU"

label var pri_govt "% of individuals nearest primary school type is governmental in this LGU"
label var sec_govt "% of individuals nearest secondary school type is governmental in this LGU"
label var attend_pri_govt "% of individuals attend primary (gov)school in this LGU"
label var attend_sec_govt "% of individuals attend secondary (gov)school in this LGU"
label var pri_edu_svc "% of individuals's nearest primary school is within 10mins in this LGU"
label var sec_edu_svc "% of individuals's nearest secondary school is within 15mins in this LGU"
label var edu_vul_neet "% of individuals are vulnerable members"

//calculate the gap between education service sufficiency and margunalization index
gen pri_edu_gap =  edu_vul_neet - pri_edu_svc
gen sec_edu_gap =  edu_vul_neet - sec_edu_svc

label var pri_edu_gap "service gap for primary education"
label var sec_edu_gap "service gap for secondary education"


********************
***HEALTH***********
********************

//Create indicator for health gap by hlth_vul_age - hlth_svc_dist
generate hlth_gap_lgu =  hlth_vul_age - hlth_svc_dist

//If the value is positive, then generally more attention should be put with greater amount of resources in this LGU.
//If it is negative, it has sufficient health facilities to take care of vulnerable groups.

/relabel all variables
label var LGU_ID "LGU_ID"
label var Governorate "Governorate ID"
label var hlth_svc_dist "% of individuals in this LGU can drive to any of the nearest health facilities in 10 min"
label var hlth_vul_age "% of individuals in this LGU are under 15 or above 60"
label var hlth_vul_diarr "% of individuals in this LGU have member experienced severe diarrhea"
label var hlth_gap_lgu "% of individuals in this LGU are marginalized and have no sufficient health services"

******************************
***WATER & SANITATION*********
******************************

//Calculate the gap between water&sanitation service sufficiency and margunalization index (Gaza residents without access to sanitation or water)
gen water_sani_gap = gaza_vul - water_sani_svc

//Label all the index
label var gaza_vul "% of Gaza households without access to sanitation or water"
label var water_sani_svc "% of household connected to the pipe water network or piped sewage system"
label var water_sani_gap "the gap between water and sanitation service provision and vulnerable group in Gaza"

**************************************
***SERIVCE FOR DISABLED PPL***********
**************************************
generate access_gap_lgu = hlth_vul_disab - access_svc 


label var LGU_ID "LGU ID"
label var LGU_Name "LGU Name"
label var Governorate "Governorate ID"
label var hlth_vul_disab "% of individuals in this LGU have member with disability"
label var access_svc "% of individuals in this LGU have access to waste collection or electricity grid, or public transport"
label var access_gap_lgu "% of disabled individuals in this LGU are marginalized and have no sufficient service access"


order LGU_Name LGU_ID Governorate pri_edu_svc_dist sec_edu_svc_dist pri_govt sec_govt attend_pri_govt attend_sec_govt edu_vul_neet pri_edu_svc sec_edu_svc hlth_vul_age hlth_svc_dist hlth_vul_diarr gaza_vul water_sani_svc hlth_vul_disab access_svc pri_edu_gap sec_edu_gap hlth_gap_lgu water_sani_gap access_gap_lgu


save Final_dataset, replace

export excel using "/Users/panwen/Desktop/LGPA Data Final/Final_dataset.xlsx", firstrow(variables)







