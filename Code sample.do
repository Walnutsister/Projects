
clear
capture log close
set more off
set logtype text

log using hwk2WEN.txt, replace 

*load the prepared data;
use hmk2.dta, clear

* keep those individuals that define the sample; 
* if listed first, then obs coded 1;
tab sex
keep if sex == 1

tab race
keep if race == 1

tab racesing
keep if racesing == 1

tab racesingd
keep if racesingd == 10

keep if age>=40 & age<=49
count if age == .
tab age

* define independent variable based on educd;
keep if educd != .
egen educd_grp = group(educd)
table educd, c(mean educd_grp sd educd_grp)

*define the 21 education groups; 
gen edyrs = .
replace edyrs =  0 if inlist(educd_grp,1,2,3) 
replace edyrs = educd_grp - 3 if edyrs == . 
label var edyrs "Years of formal education completed"

*notice we have 21 groups this way; 
table educd, c(mean edyrs sd edyrs)

* define independent variable a second way based on higrad;
keep if higrade != .
egen higrade_grp = group(higrade)
table higrade, c(mean higrade_grp sd higrade_grp)

*define the 21 education groups based on highest grade; 
gen hiyrs = .
replace hiyrs =  0 if inlist(higrade_grp,1,2,3) 
replace hiyrs = higrade_grp - 3 if hiyrs == .
label var hiyrs "Years of high grade"

*notice we have 21 groups using highest grade; 
table higrade, c(mean hiyrs sd hiyrs)

* just keep the variables you will need including the two defintions of rhs variable; 
keep hiyrs edyrs inctot wkswork1

* define (log weekly wages); 
* weekly wages;
* define those who did not work as missing;
* get inflation from 1980 to 2003 from the bls; 
* http://www.bls.gov/data/inflation_calculator.htm; 
gen weekytot = (inctot/wkswork1) * 2.2338

* log of weekly wages; 
gen lnweekytot = log(weekytot) 

* ensure you only keep observations with non missing values; 
keep if lnweekytot != . & hiyrs != . & edyrs != . 

* calculate CEF for each year of school; 
egen cef_edu = mean(lnweekytot), by(edyrs)
label var cef_edu "log of weekly earnings (edyrs)"
egen cef_hi = mean(lnweekytot), by(hiyrs)
label var cef_hi "log of weekly earnings (hiyrs)"

*the measures are identical; 
reg cef_edu cef_hi 
sum cef_edu cef_hi 

*these measures are essentially identical so just use the cef_hi one for the regressions;
*here is the graph using the higrade variable; 
sort hiyrs
graph twoway connected cef_hi hiyrs, yscale(range(5.8 7.2)) ylabel(5.8(0.2)7.2) xlabel(0(2)20) 
graph export hmk2_fig1.png, replace 

*this is the answer to the nova question; 
*variance of cef; 
egen hi_tag = tag(hi)
sum cef_hi
dis r(sd)^2

*variance of error; 
gen e = lnweekytot - cef_hi 
sum e if hi_tag == 1
dis r(sd)^2

*V(y) = V(E(y|x)) + V(y-E(y|x)); 
dis .06049261+ .41867925

*total variance of the outcome variable;
sum lnweekytot
dis r(sd)^2

*you can see that the variance of the outcome equals the variance of the CEF;
*plus the variance of the error term; 
*in particular, we did not use a regression or specific function form for the CEF;

*do the regression on the raw data; 
reg lnweekytot hiyrs, robust

*count the number of observations at each high grade level;
gen obs = 1
egen count_hi = total(obs), by(hiyrs) 

*only keep cef at each education level; 
duplicates drop cef_hi, force
*do the regression on the cdfs; 
*use aweights to properly weight each category with the number of original obs in it; 
*this will give you correct esimates;
reg cef_hi hiyrs [aweight=count_hi], robust

*another way to see this is the table; 
table hiyrs, c(mean count_hi)
