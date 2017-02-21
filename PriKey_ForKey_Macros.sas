**************************************************************************************************;
%MACRO POTENTIALPKFK(LIB1, LIB2, IN1, IN2, OUT1, OUT2);

  /* Sort dataset by NAME for eventual temp table output for potential MACRO run */
  proc sort data=&LIB1..&IN1.; by NAME; run;

  /* Output LIBNAME, MEMNAME AND NAME TO temp dataset 1 */
  data &LIB1..&OUT1. (keep=LIBNAME MEMNAME NAME);
    set &LIB1..&IN1.;
      by NAME;
      if first.NAME;
  run;

  /* The three step process below helps to create an output table with the selected variables 
     that have a potential to have a PK/FK relationship, including all records from the dataset */
  proc sql noprint;
    select trim(left(NAME)), count(*)
      into :list separated by ' ', :nlist
      from &LIB1..&OUT1.;
  quit;

  %put list contains >&list<;
  %put number of names=%trim(&nlist);

  data &LIB1..&OUT2.;
    set &LIB2..&IN2. (keep=&list);
  run;

%MEND;


**************************************************************************************************;

/* Create  merged dataset with the potentially matched variables based on data type, length, 
   etc. */

%MACRO POSVARMATCH(LIB1, IN1, OUT1)

  data &LIB1..&OUT1. (keep= NAME NAME2);
    set &LIB1..&IN1.;
  run;

%MEND;


**************************************************************************************************;

 /* This Macro will take the various combinations of variables that are potential matches and run
    a left join to determine the number of matches between the first and second varible of that
    potential match */
%MACRO VARMATCHOUT(FLDR, INPUT1, INPUT2, OUTPUT, VARMTCH1, VARMTCH2);

  proc sql noprint;
    create table &FLDR..&OUTPUT. As
	select a.&VARMTCH1., b.&VARMTCH2.
	  from &FLDR..&INPUT1. (keep=&VARMTCH1.) As a
	  left join &FLDR..&INPUT2. (keep=&VARMTCH2.) As b
	    on a.&VARMTCH1.=b.&VARMTCH2.;
  quit;
%MEND;

/* Procedural code used to build the above MACRO */ 
/*proc sql noprint;*/
/*  create table output.varmatch_out As*/
/*  select a.Customer_Type_ID, b.Customer_Type_ID As Customer_Type_ID2*/
/*    from output.test01 (keep=Customer_Type_ID) As a*/
/*    left join output.test02 (keep=Customer_Type_ID) As b*/
/*      on a.Customer_Type_ID=b.Customer_Type_ID;*/
/*quit;*/


**************************************************************************************************;

 /* This Macro will take the output results ffrom the variable match output file(s) and return the 
    percentage match between the two variables */ 
%MACRO VARMATCHSTATS(FLDR, INPUT, VARMTCH1, VARMTCH2, OUTPUT);
  
  proc sql noprint;
    create table &FLDR..&OUTPUT. As
	select count(&VARMTCH1.) As &VARMTCH1., count(&VARMTCH2.) As &VARMTCH2.,
	  ((count(&VARMTCH2.)/count(&VARMTCH1))*100) As Percentage_Match
      from &FLDR..&INPUT.;
  quit;
%MEND;

**************************************************************************************************;


%MACRO APPENDSTATS(LIB1, BASE1, IN1)

  proc append base=&LIB1..&BASE1. data=&LIB1..&IN1.;
  run;

 %MEND

**************************************************************************************************;

/* Procedural code used to build the above MACRO */
/*proc sql noprint;*/
/*  create table output.varmatch_stats As*/
/*  select count(Customer_Type_ID) As Customer_Type_ID, count(Customer_Type_ID2) As Customer_Type_ID2,*/
/*    ((count(Customer_Type_ID2)/count(Customer_Type_ID))*100) As Percentage_Match*/
/*  from output.varmatch_out;*/
/*quit;*/
