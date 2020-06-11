/* Creating our PQI rates using the raw population data from the PQI software formating files
I will be calculating the county level population rates by year for the state of Arkansas

Author: Robert Schuldt
Date 6/5/2020

*/

Libname p '*************************roject\Publication Data';

%let path = **********************************;
proc import datafile = "&path.\population.xls"
DBMS = xls out = population replace;
run;

data ark;
	set population;
	fips = put(stco, z5.);
	state_id = substr(fips, 1, 2);
	if state_id ne "05" then delete;

	rename E = y_2011;
	rename F = y_2012;
	rename G = y_2013;
	rename H = y_2014;
	rename I = y_2015;
	rename J = y_2016;
	rename K = y_2017;

	run;

%let r = black;
data &r._pop;
	set ark;
	if R = 2;
	if AG gt 13 then delete;
	if AG lt 5 then delete;
	run;


proc sql;
create table year_sums_&r as
select *,
sum(y_2011) as total_&r._2011,
sum(y_2012) as total_&r._2012,
sum(y_2013) as total_&r._2013,
sum(y_2014) as total_&r._2014,
sum(y_2015) as total_&r._2015,
sum(y_2016) as total_&r._2016,
sum(y_2017) as total_&r._2017
from &r._pop
group by fips;

quit;
