DM LOG 'CLEAR' LOG;

**************************************************************************************************
PROJECT:        REGULATION W - DATA INTEGRITY ANALYSIS / PRIMARY KEY-FOREIGN KEY SEARCH
AUTHOR:         ANDY MURTHA
VERSION:        1.0 (03/04/2014)

VER MODS:       1.0 (03/04/2014) Script includes multiple macros that are run to find
                                 a primary key - foreign key relationship between any
                                 two tables. User will need to enter in all variables
								 into marcos based off of the two tables provided.
**************************************************************************************************;

OPTIONS COMPRESS=YES;

/*** !!!IMPORTANT!!! ***/
/*** CHANGE PATH ACCRODING TO THE FILE SYSTEM ON TARGET MACHINE ***/

%LET OutFileNum = 1;
%LET StatsNum = 1;
%LET PATH=C:\Users\amurtha\Desktop\SAS Test Output\;
libname test 'C:\Users\amurtha\Documents\My SAS Files\Code Library\SAS Programming 1 - Essentials\ECPRG1\';
libname output 'C:\Users\amurtha\Desktop\SAS Test Output\';


****************************************************************************************

MACRO LOADING

****************************************************************************************;

/*************************************************************/
/*** AREA  :  RUN MACRO FILE                               ***/
/*** PURPOSE: Loading all MACROs into program memory for   ***/
/***          running primary key - foreign key analysis   ***/
/*** INPUT :  Game Codes - PriKey_ForKey_Macros.sas        ***/
/*************************************************************/

%INCLUDE "&PATH.\PriKey_ForKey_Macros.sas";



****************************************************************************************

TEST EXECUTION

****************************************************************************************;

/*************************************************************/
/*** AREA  :  PRIMARY KEY - FOREIGN KEY ANALYSIS SCRIPT    ***/
/*** PURPOSE: Running all macros in specifi order to       ***/
/***          complete primary key - foreign key analysis  ***/
/*** INPUT :  2 base files, SAS datasets                   ***/
/*** OUTPUT:  Match Scoring File,                          ***/
/***          Multiple Matched PK/FK Output Files          ***/
/*************************************************************/


/*** The three step process below helps to create an output table with the selected 
     variables that have a potential to have a PK/FK relationship, including all records 
     from the dataset.  This is repeated for both datasets. ***/
%POTENTIALPKFK(output, test, Profile_compare, Customer, tmp_tbl1_varmatch, test01);
%POTENTIALPKFK(output, test, Profile_compare, Customer_type, tmp_tbl2_varmatch, test02);

/*** Create  merged dataset with the potentially matched variables based on data type, 
     length, etc. ***/
%POSVARMATCH(output, Profile_compare, pos_varmatch);

/* data _null_; */
    /* DO UNTIL last.NAME; */
      /* set output.pos_varmatch end=NAME; */
        /*** LOOP THESE UNTIL THEY HAVE GONE THROUGH THE ENTIRE pos_varmatch FILE ***/
        %VARMATCHOUT(output, INPUT1, INPUT2, varmatch_out||&OutFileNum., NAME, NAME2);
        &OutFileNum. = &OutFileNum. + 1;
    /* OUTPUT; (?) */
    /* STOP; */
/* run; */

/* data _null_; */
    /* DO UNTIL &StatsNum. = &OutFileNum.; */
      /* set output.pos_varmatch end=NAME; */
        /*** LOOP THESE UNTIL THEY HAVE GONE THROUGH THE ENTIRE pos_varmatch FILE ***/
        %VARMATCHSTATS(output, INPUT, VARMTCH1, VARMTCH2, varmatch_stats);
		&StatsNum. = &StatsNum. + 1;
    /* OUTPUT; (?) */
    /* STOP; */
/* run; */
