/* Project investigating the impact of medicaid expansion on preventable hospitalization rates among
Arkansas 18-64. 

Code: Robert Schuldt
Email: rschuldt@uams.edu

*/

libname ar '**************Project\Data';

proc import datafile = "********************ata\arfips.xlsx"
dbms = xlsx out = counties replace;
run;

data counties_prep;
	set counties;
		MAILCNTY = upcase(county);
run;

proc sort data = counties_prep;
by MAILCNTY;
run;
%include '********************** Macros\infile macros\sort.sas';
/*initial pull in of the data and generate a random Key for each of the records*/




data inpatient;
	set ar.young_inv_all_ages;
	where ADMTDATE ne "00000000";
		adms_dt = input(ADMTDATE, yymmdd8.);
		rename DRG = DRG1;
		drg4 = substr(hdrg, 2, 3);
		
	test = substr(ADMTDATE, 1, 4);
		
		if _AGE lt 18 then delete;
		if _AGE gt 64 then delete;
		/*change for splitting pop*/
		

	run;



proc sort data = inpatient;
by MAILCNTY;
run;

data inpatient_county;
merge inpatient (in = a) counties_prep (in = b);
by MAILCNTY;
if a;

run;
/* We only lose about 9 observations with missing county information*/

/*SO PROUD OF THIS RANDOM ID GENERATOR REMEMBER THIS*/
proc plan seed=32329;
   factors randomID=9000000 / noprint;
   output out=randomID randomID nvals=(1000000 to 9999999);
   run;
   quit;
data inpatient2;
	merge inpatient_county (in = a) randomid (keep = randomid);
	if a;
	run;

PROC FREQ data = inpatient2;
 TABLES randomID / noprint out=keylist;
RUN;
PROC PRINT;
 WHERE count ge 2;
RUN; 
/*We are missing some admission dates that are miscoded as "0000000" so I am eliminating these observations*/
	title "Miscoded Admission Dates Check";
proc freq data = ar.young_inv;
table admtdate;
where admtdate = '00000000';
run;

proc freq data = ar.young_inv;
table SRCEPAY1 SRCEADMT TYPEADMT;
run;
/*We only have 9 observations that are miscoded so no big deal*/


proc contents data = inpatient_county position out = var_list;
run;
/* Check if arkansas data has all variables we need

make a small report on the data, age, etc, descriptive data

Must seperate ICD9 and ICD10 coding
*/

proc import datafile = '***************************OSSWALK'
dbms = xlsx out = mdc replace;
run;

data mdc_crosswalk;
	set mdc;

	drg = ms_drg;
run;
%sort(mdc_crosswalk, DRG)

data split;
 set inpatient2;
if (ADMTDATE = .) then delete;
run;
/*Prepare the data for the PQI programs*/
%macro icd(setdata, value, year);
data &setdata;
	set split;
	where adms_dt &value '01OCT2015'd and test = "&year";
	
	drop county;

	rename randomid = key;

	AGE = _AGE;

/* Recoding the Race variable to match what we need*/
race1 = race;
race = .;	
	%let r1 = RACE1;
	%let r = race;
	if &r1= 4  then &r = 1;
	if &r1 = 3 then &r = 2;
	if ETHNICTY = 1 then &r = 3;
	if &r1 = 2 then &r = 4;
	if &r1 = 1 then &r = 5;
	if &r1 = 5 or &r1 = 6 then &r = 6;

/*Now must code for Sex of patient*/

	if GENDER = "M" then SEX = 1;
		else SEX = 2;

/*Payor*/
	PAY1 = 6;
	if SRCEPAY1 = "M" or  SRCEPAY1 = "1" then PAY1 = 1;
	if SRCEPAY1 = "D" or  SRCEPAY1 = "2" then PAY1 = 2;		
	if SRCEPAY1 = "I" or SRCEPAY1 = "5" or  SRCEPAY1 ="B" or SRCEPAY1 ="S" or SRCEPAY1 ="E" or SRCEPAY1 = "7" or SRCEPAY1 = "6" then PAY1 = 3;
	if SRCEPAY1 = "P" or SRCEPAY1 = "8" then Pay1 = 4; */
	if SRCEPAY1 = "Z" then PAY1 = 5;
	if SRCEPAY1 = " " then PAY1 = .;
	
	
	Pay2 = .;
/*Patient locations*/
	PSTCO = fips;

/* I do no thave hosp ID*/
HOSPID = .;
/* Used this freq to check our discharges

proc freq data = inpatient;
table _Status;
run;

*/

/*Patient disposition*/
	
	DISP = 5;	

	if _STATUS= 1 then DISP = 1;
	if _Status = 2 then DIS = 2;
	if _Status = 3 then DISP = 3;
	if _status = 4 then DISP = 4; 
	if _status = 6 then DISP = 6;
	if _status = 7 then DISP = 7;
	if _status = 20 then DISP = 20;

/* MISSING vars that are required to be added to program, but not neccesary */
   MORT30 = .;

   DNR = .;

   DISCWT = .;
/* Admission type*/

   if TYPEADMT = '1' then  ATYPE = 1 ;
   if TYPEADMT = '2'  then ATYPE = 2 ;
   if TYPEADMT = '3'  then ATYPE = 3 ;
   if TYPEADMT = '4'  then ATYPE = 4 ;
   if TYPEADMT = '5'  then ATYPE = 5 ;
   if TYPEADMT = '9'  then ATYPE = 6 ;
/* Admission Source*/

   if SRCEADMT = '1' then ASOURCE = 5;
   if SRCEADMT = 'E' then asource = 1;
   if SRCEADMT = '4' then asource = 2;
   if SRCEADMT = '2' or SRCEADMT= '5' or SRCEADMT= '6' or SRCEADMT = 'D' or SRCEADMT= 'F' then asource = 3;
   if SRCEADMT = '8' then asource = 4;
   if SRCEADMT = '3' or SRCEADMT = '9' or SRCEADMT= '7' then asource = 5;

/*Length of stay*/

   LOS = _LOS;
 	if _LOS = . then LOS = _LOS_;

/* DRG*/
	  length drg  3;

   if DRG1 ne " " and substr(DRG1, 1, 1) ne 'S' then drg = DRG1;
   if DRG3 ne " " and substr(DRG3, 1, 1) ne 'S' then drg = DRG3;
   if DRG4 ne ' ' and substr(DRG4, 1, 1) ne 'S' then drg = DRG4;
	
   DRGVER = 25;
/* Diagnosis*/

   array dw1 (9) ADMTDIAG DIAG1 DIAG2 DIAG3 DIAG4 DIAG5 DIAG6 DIAG7 DIAG8;
   array dw2 (9) $ DX1 DX2 DX3 DX4 DX5 DX6 DX7 DX8 DX9;

   	do s = 1 to 9;
		ds = '     ';
		dw2(s) = dw1(s);
		
	end;


DXPOA1 = '1';

array dp (8) $ DXPOA2-DXPOA9;
	do i = 1 to 8; 
		dp(i) = '0';
	end;


array dw3 (9) ADMTDIAG DIAG1 DIAG2 DIAG3 DIAG4 DIAG5 DIAG6 DIAG7 DIAG8 ;
array c (9) count1-count9;
	do h = 1 to 9;
		if dw3(h) ne " " then c(h) = 1;
	end;

NDX = sum(of count1-count9);

/*Procedure codes */

	array pr (*)  PROC1 PROC2 PROC3 PROC4 PROC5 PROC6 PROC7 PROC8 PROC9 PROC10 PROC11 PROC12
					PROC13 PROC14 PROC15 PROC16 PROC17 PROC18 PROC19 PROC20 PROC21;
	array pk (*) $ PR1 - PR21;
		do k = 1 to 21;
			if pr(k) ne " " then pk(k) = pr(k);
		end;

	array pc (*) PROC1 PROC2 PROC3 PROC4 PROC5 PROC6 PROC7 PROC8 PROC9 PROC10 PROC11 PROC12
					PROC13 PROC14 PROC15 PROC16 PROC17 PROC18 PROC19 PROC20 PROC21;
	array pcc (*) prc1 - prc21;
		do y = 1 to 21;
			if pc(y) ne " " then pcc(y) = 1;
		end;


NPR = sum( of prc1-prc21);


if SRCEADMT = '4' then POINTOFORIGINUB04 = 1;
if SRCEADMT = '5' then POINTOFORIGINUB04 = 1;
if atype = 4 then POINTOFORIGINUB04 = 1;
if SRCEADMT = '6' then POINTOFORIGINUB04= 1;

/* Year of admission*/

YEAR = 	&year;
DQTR = qtr(adms_dt);

run;

%sort(&setdata ,drg)


data &setdata;
	merge &setdata (in = a) mdc_crosswalk (in = b);
	by drg;
	if a;
	
run;
%mend icd;

%icd(ar.icd92011, lt, 2011)
%icd(ar.icd92012, lt, 2012)
%icd(ar.icd92013, lt, 2013)
%icd(ar.icd92014, lt, 2014)
%icd(ar.icd92015, lt, 2015)
%icd(ar.icd102015, gt, 2015)
%icd(ar.icd102016, gt, 2016)
%icd(ar.icd102017, gt, 2017)

/*Now that I have split the dates of ICD 9 and ICD10 codes I can start to run the PQI
software that I using from AHRQ to generate preventable hospitalizations and must initialize the controls*/

/*NOW I HAVE RUN PQI ON ALL THE FILES*/

/* PQI CONTROL FILE */

/*ID the year I want to work with*/
%let pat_file = icd92013;
%let year = 2013;


%let pathway_pr = *************************PQI_SAS_V602_201707_QI_SOFTWARE\PQI\Programs ;
/*Select the program startig with Control*/
%include "&pathway_pr.\PQI_ALL_CONTROL.SAS";
/*Now I do the same with the format*/
%include "&pathway_pr.\PQI_ALL_FORMATS.SAS";
/*Now I do measures*/
%include "&pathway_pr.\PQI_ALL_MEASURES.SAS";


/*ID the year I want to work with now for icd10*/
%let pat_file = icd102017;
%let year = 2017;


%let pathway_pr = Z:\DATA\Urban League Project\PQI\PQI Software\PQI_SAS_V701_2017_12_QI_SOFTWARE\PQI_SAS_V701_2017_12_QI_SOFTWARE\PQI\Programs ;
/*Select the program startig with Control*/
%include "&pathway_pr.\PQI_ALL_CONTROL.SAS";
/*Now I do the same with the format*/
%include "&pathway_pr.\PQI_ALL_FORMATS.SAS";
/*Now I do measures*/
%include "&pathway_pr.\PQI_ALL_MEASURES.SAS";



proc freq data = ar.icd92013;
table race;
run;
