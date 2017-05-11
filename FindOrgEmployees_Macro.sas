/*Create original list of Employee ID's to search on*/
data work.dim_EMP_ID_LST;
	input EMP_ID_LST $10.;
	datalines;
XYZ123
ABC456
;

/*Create a macro to extract only teammates that roll up to 
  specific executives. This macro takes the executives
  and searches the target data set to return any teammate 
  that has either person that has them
  populated in the SUPV_EMP_ID variable. The new list of
  Employee ID's is populated and the search begins again. The
  search is completed when there are no additional Employee ID's
  are pulled in (complete this task by comparing two
  variable values one before the search and one after the
  search. When the two values are equal, then the search
  is complete).*/
%let i=0;

/*Number of Employee ID's in dim_EMP_ID_LST table to start*/
%let j=2;
	
%MACRO FINDORGEMP();
	%do %until (&i. = &j.) ;
%let i=&j.;

	/*Create macro list of Employee ID's*/
	proc sql noprint;
		select cats("'",EMP_ID_LST,"'")
		into: alist separated by ","
		from work.dim_EMP_ID_LST;
	quit;

	/*Filter population to Employee ID's that are populated
	  in the SUPV_EMP_ID variable*/
	proc sql;
		create table work.test01 as
		select
			a.EMP_ID as EMP_ID_LST
		from work.src_emp_data as a
		where SUPV_EMP_ID in (&alist.);
	quit;

	/*Update Employee ID list to include all values 
	  returned in search*/
	data dim_EMP_ID_LST;
		set dim_EMP_ID_LST
			test01;
	run;

	/*Sort ascending order and remove duplicate values*/
	proc sort data=work.dim_EMP_ID_LST nodupkey; by EMP_ID_LST; run;

	/*Update macro variable j with count of Employee ID's in
	  refreshed list*/
	proc sql noprint;
		select count(EMP_ID_LST)
		into: j
		from work.dim_EMP_ID_LST;
	quit;

%end;
/*Print i and j to log to validate count*/
%put &i. &j.;
%MEND;

/*Run the macro*/
%FINDORGEMP();
