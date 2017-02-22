%MACRO EXPORTTBL;

  /* -------------------------------------------------------------------
     Provides the user to export the sample table that contains the 
     attributes of each variable and the first five samples of that 
     variable for each dataset.  The export macro will output the
     specific dataset to a worksheet with the dataset name to an excel
     workbook.
     ------------------------------------------------------------------- */

  PROC EXPORT DATA=WORK.tmp_tbl_contents02     
              OUTFILE="[Drive:\filename].xlsb"       /***Enter OUTFILE Excel Name Here***/
              DBMS=EXCELCS REPLACE;
              SHEET="&&DS&I.";
	      SERVER='&SERVERNAME';
  RUN; 

%MEND;


**************************************************************************************************;


%MACRO CRE8SAMPLETBL;

  /* -------------------------------------------------------------------
     Provides the user to a sample table that contains the 
     attributes of each variable and the first five samples of that 
     variable for each dataset.
     ------------------------------------------------------------------- */

  /*PROC DATASETS LIBRARY=WORK NODETAILS NOLIST;*/
  /*  DELETE temp01 temp02 tmp_tbl_contents01 tmp_tbl_contents02;*/
  /*RUN;*/

  %let recno = 0;
  %put &recno;

  /* -------------------------------------------------------------------
     Allows user to obtain the first five records of every variable
     of each dataset in the CDM library
     ------------------------------------------------------------------- */

  DATA WORK.temp01;
    SET [LIBNAME].&&DS&I (OBS=5)end=last;            /***UPDATE THE LIBNAME IN THIS STATEMENT***/
      IF LAST THEN CALL SYMPUT('recno', LEFT(_N_));
  RUN;
  %put &recno;


  PROC TRANSPOSE DATA=WORK.temp01 OUT=WORK.temp02;
    VAR _ALL_;
  RUN;


  PROC SORT DATA=WORK.temp02; BY _NAME_; RUN;


  /* -------------------------------------------------------------------
     Build contents file to populate data on fields contained in table 1
     ------------------------------------------------------------------- */

  PROC CONTENTS ORDER=casecollate
                DATA=[LIBNAME].&&DS&I                /***UPDATE THE LIBNAME IN THIS STATEMENT***/
	   	OUT=WORK.tmp_tbl_contents01 (KEEP=LIBNAME MEMNAME NAME TYPE)
  		NOPRINT;
  RUN;


  /* -------------------------------------------------------------------
     Sort tmp_tbl_contents by variable name
     ------------------------------------------------------------------- */


  PROC SORT DATA=WORK.tmp_tbl_contents01; by NAME; RUN;


  /* -------------------------------------------------------------------
     Merge the attributes table with the table containing the first
     five samples of each variable
     ------------------------------------------------------------------- */

  DATA WORK.tmp_tbl_contents02;
    MERGE WORK.tmp_tbl_contents01 (IN=A) WORK.temp02 (IN=B RENAME=(_NAME_=NAME _LABEL_=LABEL));
    BY NAME;
    IF A AND B THEN OUTPUT;
  RUN;


  /* -------------------------------------------------------------------
     Rename the labels for the variables that contain the samples of 
     each variable
     ------------------------------------------------------------------- */

  %if &recno GT 0 %then %do;
    PROC DATASETS LIBRARY=WORK NODETAILS NOLIST;
      MODIFY tmp_tbl_contents02;
  
      RENAME COL1=SAMPLE1;
      RENAME COL2=SAMPLE2;
      RENAME COL3=SAMPLE3;
      RENAME COL4=SAMPLE4;
      RENAME COL5=SAMPLE5;
      LABEL SAMPLE1='Sample_1';
      LABEL SAMPLE2='Sample_2';
      LABEL SAMPLE3='Sample_3';
      LABEL SAMPLE4='Sample_4';
      LABEL SAMPLE5='Sample_5';
    QUIT;
  %end;


  /* -------------------------------------------------------------------
     Using PROC FORMAT to allow the end user to know the data type
     description instead of viewing the data type code
     ------------------------------------------------------------------- */

  PROC FORMAT; 						
    VALUE _EG_VARTYPE 1="Numeric" 2="Character" OTHER="Unknown";
  RUN;


  DATA WORK.tmp_tbl_contents02;
    SET WORK.tmp_tbl_contents02;
    FORMAT TYPE _EG_VARTYPE;
  RUN;


  /* -------------------------------------------------------------------
     Test code to determine if the non-character variables will actually
     print out/export out to a file (YES)
     ------------------------------------------------------------------- */


  /*  PROC PRINT DATA=WORK.tmp_tbl_contents02;  */  
  /*    FORMAT TYPE _EG_VARTYPE.;*/
  /*  RUN;*/


%MEND;


**************************************************************************************************;


  /* -------------------------------------------------------------------
     Leveraged From:
     SUGI 27 - Coder's Corner
     Paper 84-27
     "Using the contents of PROC CONTENTS to perform multiple operations across a SAS
      Data Library"
     Subrahmanyam Pilli, Luai Alzoubi, Kent Nassen
      Pfizer Global Research & Development, Ann Arbor, MI
     http://www2.sas.com/proceedings/sugi27/p084-27.pdf
     ------------------------------------------------------------------- */


OPTIONS NOCENTER DATE MPRINT MLOGIC SYMBOLGEN;
%LET NUMRX=2; *used to create dummy treatment groups;


%MACRO LIBDATA;


  /* -------------------------------------------------------------------
     Use these three lines of code only if you want to create
     separate copyfrom and copy to folders.
     ------------------------------------------------------------------- */
  /* Use as many libname statements as you like */
  /*LIBNAME copyfrom ''; *update libname location;*/
  /*LIBNAME copyto''; *update libname location;*/


  /* Get contents for datasets (from one of the libraries), save result
     in an output data set */
  PROC CONTENTS DATA=[LIBNAME]._ALL_ MEMTYPE=data      /***UPDATE THE LIBNAME IN THIS STATEMENT***/
    OUT=OUT NOPRINT;
  RUN;


  /* Sort prior to selecting unique data set names */
  PROC SORT DATA=OUT; BY MEMNAME NAME; RUN;


  /* Select unique data set names, remove unneeded datasets */
  DATA A;
    SET OUT;
    BY MEMNAME NAME;
	/*IF MEMNAME IN ('','','') *Comment out because we want all datasets; */
	/*THEN DELETE; *Delete the datasets you do not need, comment out because we want all datasets; */

	/* Because each variable in a dataset produces an observation in
	   the output dataset, we need to remove the duplicate MEMNAMEs */
    IF FIRST.MEMNAME;
  RUN;


  /* Create data set names as macro variables & get total number of 
     data sets */
  DATA _NULL_;
    SET A END=LAST;
	BY MEMNAME NAME;
	/* Create a macro variable like DS1 with the value of MEMNAME */
	CALL SYMPUT('DS' || LEFT(_N_), TRIM(MEMNAME));


	/* Create a macro variable for the total number of datsets */
	IF LAST THEN CALL SYMPUT('TOTAL', LEFT(_N_));
  RUN;


  /* Enter in actual macro code within DO loop to complete task(s) */
  %DO i=1 %TO 4;                                     /***4 used for testing, update to &TOTAL post-testing***/
    %CRE8SAMPLETBL;
    %EXPORTTBL;
  %END;

%MEND LIBDATA;


/* Call the Macro */

%LIBDATA;
