**************************************************************************************************;
*
*  SAS - Find PK/FK relationship between two random tables
*  Author: Andy Murtha
*  Version 1.1
*  Date:   04/09/2014
*
*  STEPS FOR DETERMINING POTENTIAL OCCURANCE PK/FK RELATIONSHIP
*  1.  Import the two random tables provided by data group into temp datasets
*  2.  Sort the two temp datasets by the following criteria;
*	   A.  TYPE
*	   B.  LENGTH
*	   C.  FORMAT
*	   D.  FORMATL
*  3.  Perform join on two temp datasets by the criteria listed in step 2. This will find 
*	   records that are similar in datatype to each other for potential PK/FK matching.
*      ***NOTE*** If variables from source that are PK/FK relationships do not have correct
*	   type, length, etc., between themselves (due to data integrity issues), then this script
*	   will not return the results anticipated
*  4.  Sort the joined variable dataset by variable name
*  5.  Create a temporary table to pull in the observations related to the potential PK/FK
*      variables
*  6.  Create a second temporary table to pull in the observations related to the potential
*      PK/FK variables
*  7.  Sort both potential variable match (w/ observations) temp tables by variable name again
*  8.  Create temporary merged dataset with the potential variable matches based on STEP 3,
*      while only retaining the following two variables, VARIABLE1 and VARIABLE2
*  9.  Count the number of potential matches in the temporary merged dataset
*  10. Run a macro %DO loop from 1 to the number of potential matches in the temporary merged
*      dataset.  This loop will conduct the following tasks
*      A.	Create an output file for each potential match that completes a left join between
*           the observations of both potnetial matching variables
*      B.   Create an output file for each potnetial match that calculates the percentage
*           of matching results for that corresponding record of potential matching variables
*  11. Display list report of results from the percentage match output file in descending order
*  12. Clean up all temporary tables and kill program
*
*  (CHANGE LOG BELOW CODE)
**************************************************************************************************;


/* -------------------------------------------------------------------
   HEADER PROGRAM CODE
   ------------------------------------------------------------------- */
DM LOG 'CLEAR' LOG;
OPTIONS COMPRESS=YES NOCENTER DATE MPRINT MLOGIC SYMBOLGEN;

/* -------------------------------------------------------------------
   LIBNAME DEFINITIONS
   ------------------------------------------------------------------- */
LIBNAME test '';		/***Update LIBNAME location here***/
LIBNAME output '';		/***Update LIBNAME location here***/

**************************************************************************************************;

/* -------------------------------------------------------------------
   STEP 1: Import the two random tables provided by data group into
   temp datasets
   ------------------------------------------------------------------- */
PROC CONTENTS ORDER=casecollate
              DATA=test.input_tbl01
              OUT=output.tmp_tbl01(KEEP=LIBNAME MEMNAME NAME TYPE LENGTH VARNUM LABEL FORMAT FORMATL FORMATD)
			  NOPRINT;
RUN;

PROC CONTENTS ORDER=casecollate
              DATA=test.input_tbl02
			  OUT=output.tmp_tbl02(KEEP=LIBNAME MEMNAME NAME TYPE LENGTH VARNUM LABEL FORMAT FORMATL FORMATD)
			  NOPRINT;
RUN;


/* -------------------------------------------------------------------
   STEP 2: Sort the two temp datasets by the following criteria;
	   A.  TYPE
	   B.  LENGTH
	   C.  FORMAT
	   D.  FORMATL
   ------------------------------------------------------------------- */
PROC SORT DATA=output.tmp_tbl01; BY TYPE LENGTH FORMAT FORMATL; RUN;
PROC SORT DATA=output.tmp_tbl02; BY TYPE LENGTH FORMAT FORMATL; RUN;


/* -------------------------------------------------------------------
   STEP 3: Perform join on two temp datasets by the criteria listed in  
   step 2. This will find records that are similar in datatype to each 
   other for potential PK/FK matching. ***NOTE*** If variables from 
   source that are PK/FK relationships do not have correct type, 
   length, etc., between themselves (due to data integrity issues), 
   then this script will not return the results anticipated
   ------------------------------------------------------------------- */
PROC SQL;
  CREATE TABLE output.var_compare AS
    SELECT b.*, c.LIBNAME AS LIBNAME2, c.MEMNAME AS MEMNAME2, c.NAME AS NAME2, c.TYPE AS TYPE2,
	c.LENGTH AS LENGTH2, c.VARNUM AS VARNUM2, c.LABEL AS LABEL2, c.FORMAT AS FORMAT2,
    c.FORMATL AS FORMATL2, c.FORMATD AS FORMATD2 
      FROM output.tmp_tbl01 As b, output.tmp_tbl02 As c
      WHERE (b.type=c.type AND b.length=c.length AND b.format=c.format);
QUIT; 


/* -------------------------------------------------------------------
   STEP 4: Sort the joined variable dataset by variable name
   ------------------------------------------------------------------- */
PROC SORT DATA=output.Profile_compare; BY NAME; RUN;


/* -------------------------------------------------------------------
   STEP 5: Create a temporary table to pull in the observations 
   related to the potential PK/FK variables
   ------------------------------------------------------------------- */
DATA output.tmp_varmatch01 (KEEP=LIBNAME MEMNAME NAME);
  SET output.var_compare;
    BY NAME;
    IF first.NAME;
RUN;


/* -------------------------------------------------------------------
   Three step process to output a test table with selected variables 
   and all records from that dataset
   ------------------------------------------------------------------- */
PROC SQL NOPRINT;
  SELECT trim(LEFT(NAME)), count(*)
    INTO :list separated by ' ', :nlist
    FROM output.tmp_varmatch01;
QUIT;

%PUT list contains >&list<;
%PUT number of names=%trim(&nlist);

DATA output.test01;
  SET test.input_tbl01 (KEEP=&list);
RUN;


/* -------------------------------------------------------------------
   STEP 6: Create a second temporary table to pull in the observations  
   related to the potential PK/FK variables
   ------------------------------------------------------------------- */
DATA output.tmp_varmatch02 (KEEP=LIBNAME MEMNAME NAME2);
  SET output.var_compare;
    BY NAME2;
	IF first.NAME2;
RUN;

/* -------------------------------------------------------------------
   Three step process to output a test table with selected variables 
   and all records from that dataset 
   ------------------------------------------------------------------- */
PROC SQL NOPRINT;
  SELECT trim(LEFT(NAME2)), count(*)
    INTO :list separated by ' ', :nlist
    FROM output.tmp_varmatch02;
QUIT;

%PUT list contains >&list<;
%PUT number of names=%trim(&nlist);

DATA output.test02;
  SET test.input_tbl02 (KEEP=&list);
RUN;


/* -------------------------------------------------------------------
   STEP 7: Sort both potential variable match (w/ observations) temp 
   tables by variable name again
   ------------------------------------------------------------------- */
PROC SORT DATA=output.test01; BY NAME; RUN;
PROC SORT DATA=output.test02; BY NAME2; RUN;


/* -------------------------------------------------------------------
   STEP 8: Create temporary merged dataset with the potential variable 
   matches based on STEP 3, while only retaining the following two 
   variables, VARIABLE1 and VARIABLE2
   ------------------------------------------------------------------- */
/* Sort dataset by NAME for eventual temp table output for potential MACRO run */
PROC SORT DATA=output.var_compare; BY NAME2; RUN;

/* Create temporary merge dataset with potential matched variables based on data type, length, etc */
DATA output.pos_varmatch (KEEP= NAME NAME2);
  SET output.var_compare;
RUN;
	

/* -------------------------------------------------------------------
   STEP 9: Count the number of potential matches in the temporary 
   merged dataset
   ------------------------------------------------------------------- */
  DATA _NULL_;
    SET output.pos_varmatch END=LAST;
	BY NAME NAME2;
	/* Create a macro variable like DS1 with the value of NAME */
	CALL SYMPUT('N1' || LEFT(_N_), TRIM(NAME));
	CALL SYMPUT('N2' || LEFT(_N_), TRIM(NAME2));

	/* Create a macro variable for the total number of potential matches */
	IF LAST THEN CALL SYMPUT('TOTAL', LEFT(_N_));
  RUN;


/* -------------------------------------------------------------------
   STEP 10: Run a macro %DO loop from 1 to the number of potential 
   matches in the temporary merged dataset.  This loop will conduct 
   the following tasks:
       A.	Create an output file for each potential match that 
            completes a left join between the observations of both 
            potnetial matching variables
       B.   Create an output file for each potnetial match that 
            calculates the percentage of matching results for that 
            corresponding record of potential matching variables
   ------------------------------------------------------------------- */
%DO i=1 %TO &TOTAL.;
  %VARMATCHOUT;
  %VARMATCHSTATS;
%END;

/* -------------------------------------------------------------------
   END PROGRAM
   ------------------------------------------------------------------- */

**************************************************************************************************;

%MACRO VARMATCHOUT; 
  PROC SQL NOPRINT;
    CREATE TABLE output.varmatch_&&N1&I As
    SELECT a.&&N1&I, b.&&N2&I
      FROM output.test01 (keep=&&N1&I) As a
      LEFT JOIN output.test02 (keep=&&N2&I) As b
        ON a.&&N1&I=b.&&N2&I;
  QUIT;

%MEND

/* %MACRO VARMATCHSTATS(BASE1, BASE2, INPUT1, OUTDIR, OUTPUT1, OUTPUT2, VARMTCH1, VARMTCH2) */ 
PROC SQL NOPRINT;
  CREATE TABLE output.varmatch_stats As
  SELECT count(Customer_Type_ID) As Customer_Type_ID, count(Customer_Type_ID2) As Customer_Type_ID2,
    ((count(Customer_Type_ID2)/count(Customer_Type_ID))*100) As Percentage_Match
  FROM output.varmatch_out;
QUIT;

/* %MEND */

/* -------------------------------------------------------------------
   Remapping of table names

   Customer					input_tbl01
   Customer_Type			input_tbl02
   Customer_Profile			tmp_tbl01
   Customer_Type_Profile	tmp_tbl02
   Profile_Compare			var_compare
   tmp_tbl1_varmatch		tmp_varmatch01
   tmp_tbl2_varmatch		tmp_varmatch02
   varmatch_out				match_output
   varmatch_stats			match_stats

   ------------------------------------------------------------------- */
