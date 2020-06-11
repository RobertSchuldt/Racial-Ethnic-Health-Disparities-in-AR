/* Working on combining the different years of data with the PQI information

This macro program will combine all the population data and SES data with the PQI data that 
was calculated from the ADH inpatient data sets from the AHRQ PQI program*/

libname p '*******';


proc import datafile= '*****************levels by race.csv'
dbms = csv out = pop_levels replace;
run;

data pop_read;
	set pop_levels;

	FIPSTCO = put(stco, z5.);

run;

data Community;
	set p.community;
	rename f00002 = FIPSTCO;
	run;


data p.measure2015_ex;
	set p.measure2015_1
		p.measure2015_2;
		run;



%macro pqi(year, year2);

data pqi;
	set p.measure&year;
	if RACECAT = 1 or RACECAT = 2;
	

	
	if TAPQ90 = . then TAPQ90 = 0; 
	if TAPQ91 = . then TAPQ91 = 0;
	if TAPQ92 = . then TAPQ92 = 0;
	run;

proc sql;
create table pqi1 as
select *,
sum(TAPQ90) as pqi_overall,
sum(TAPQ91) as pqi_acute,
sum(TAPQ92) as pqi_chronic
from pqi
group by FIPSTCO, RACECAT;
quit;

proc sql;
create table pqi2 as
select *,
sum(TAPQ90) as state_pqi_overall,
sum(TAPQ91) as state_pqi_acute,
sum(TAPQ92) as state_pqi_chronic
from pqi1
group by RACECAT;
quit;

	proc sort data = pqi2;
	by FIPSTCO;
	run;

data pop;
	set pop_read;
keep FIPSTCO total_black_&year2 total_white_&year2;
run;

data pop_clean;
	set pop;
rename total_black_&year2 = black_pop;
rename  total_white_&year2 = white_pop;

run;


proc sql;
create table pop_clean1 as
select *,
sum(black_pop) as state_black,
sum(white_pop) as state_white
from pop_clean;
quit;



proc sort data = pop_clean1;
by FIPSTCO;
run;

data ses;
	set p.ses;
	if year = &year2;

data Community;
	set p.community;
	if year = &year2;
	rename f00002 = FIPSTCO;
	run;

proc sort data = ses;
by fipstco;
run;

proc sql;
create table ready_&year2 as
select *
from pqi2 a, 
pop_clean1 b,
ses c,
community d
where a.fipstco = b.fipstco and
a.fipstco = c.fipstco and
a.fipstco = d.fipstco
;
quit;




data pqi_ready_&year;
	set ready_&year2;

	if RACECAT = 2 then overall_pqi_overall = (pqi_overall/black_pop)*100;
	if RACECAT = 1 then overall_pqi_overall= (pqi_overall/white_pop)*100;

	if RACECAT = 2 then overall_pqi_acute = (pqi_acute/black_pop)*100;
	if RACECAT = 1 then overall_pqi_acute = (pqi_acute/white_pop)*100;

	if RACECAT = 2 then overall_pqi_chronic = (pqi_chronic/black_pop)*100;
	if RACECAT = 1 then overall_pqi_chronic = (pqi_chronic/white_pop)*100;



	if SEXCAT = 2 then female = 1;
		else female = 0;

run;

%mend;

%pqi(2011, 2011);
%pqi(2012, 2012);
%pqi(2013, 2013);
%pqi(2014, 2014);
%pqi(2015, 2015);
%pqi(2016, 2016);
%pqi(2017, 2017);




data pqi_rates;
	set pqi_ready_2011
	pqi_ready_2012
	pqi_ready_2013
	pqi_ready_2014
	pqi_ready_2015
	pqi_ready_2016
	pqi_ready_2017;

	 if RACECAT = 2 then state_black_pqi_overall = (state_pqi_overall/state_black)*100;
	 if RACECAT = 1 then state_white_pqi_overall = (state_pqi_overall/state_white)*100;

	 if RACECAT = 2 then state_black_pqi_acute = (state_pqi_acute/state_black)*100;
	if RACECAT = 1 then state_white_pqi_acute = (state_pqi_acute/state_white)*100;

	 if RACECAT = 2 then state_black_pqi_chronic = (state_pqi_chronic/state_black)*100;
	if RACECAT = 1 then state_white_pqi_chronic = (state_pqi_chronic/state_white)*100;

run;


libname ar 'Z:\DATA\Urban League Project\Data';

data check_insurance;
	set 
	ar.icd92011
	ar.icd92012
	ar.icd92013
	ar.icd92014
	ar.icd92015
	ar.icd102015
	ar.icd102016
	ar.icd102017;
	
	keep key race pay1 year _age black white medicare medicaid  private nocharge other _NOC;

		if race = 1 then white = 1;
		else white = 0;

	if race = 2 then black = 1;
		else black = 0;



	 if pay1 = 1 then medicare = 1; else medicare = 0;
	 if pay1 = 2 then medicaid = 1; else medicaid =  0;
	if pay1=3 then private = 1 ; else private = 0;
	
	 if pay1 = 5 then nocharge = 1; else  nocharge = 0;
	 if pay1=6 then other = 1; else other =0;

	

run;
 

proc sort data = check_insurance;
by key year ;
run;

proc sort data = pqi_rates;
by key year ;
run;

data p.pqi_rates_selfpay;
merge pqi_rates (in =a) check_insurance (in = b);
by key year;
if a; 
if b;
run;

proc sort data = p.pqi_rates_selfpay;
by year;
run;

proc freq data = p.pqi_rates_selfpay;
table state_pqi_overall;
by year;
run;


data tableau;
	set p.pqi_rates_noselfpay;
	keep year state_black_pqi_overall 
	state_white_pqi_overall
medicare medicaid private nocharge other
	state_black_pqi_acute
	state_white_pqi_acute 
	state_black_pqi_chronic
	state_white_pqi_chronic ;


	run;


	proc sort data = pqi_rates;
	by year;
	run;
proc freq data = pqi_rates ;
table state_black_pqi_overall;
by year;
run;
