OPTIONS SOURCE NOTES MLOGIC MPRINT SYMBOLGEN;

/*Get base date*/
*Use this &dte. instead of -->%LET codate='31May2014'd;
%let dte=%sysfunc(intnx(month,%sysfunc(today()),-1,e));
%put &dte.;


/*produce different formats of date*/
%LET rdate=053114;
%let rdate=%sysfunc(putn(&dte,mmddyyn6.));
%put &rdate.;

/* -------------------------------------------------------------------
   Find the last calendar day of the current and prior month
   ------------------------------------------------------------------- */
data _null_;
	t0=put(intnx('month',today(),0,'E'),mmddyy10.);
	call symput('t0',"'"||t0||"'");
	call symput('t1',"'"||put(intnx('month',input(t0,mmddyy10.),-1,'E'),mmddyy10.)||"'");
run;

%put &t0;
%put &t1;


/* ------------------------------------------------------------------
   Find the last business day of the prior calendar month
   MACRO: lastbusday
   PURPOSE: Create macrovariable that contains the user requested
   format of the last business day of the previous month
   DESCRIPTION: Creates SAS date value for the last business day
   or the previous month
   SAMPLE FOR MACRO:
		%lastbusday(date7.);
		%let mydate='&lastbusday'd;
		data _null_;
   		  put "My Date = &mydate";
		run;
   ------------------------------------------------------------------ */
%macro lastbusday(fmt);
  %global lastbusday;
    data _null_;
    my_today=today();
    end_mon=intnx('month',my_today-15,-1,'E');
      select (weekday(end_mon));
        when (7) end_mon=end_mon-1; /* Sat */
        when (1) end_mon=end_mon-2; /* Sun */
      otherwise;
      end;
    call symput("lastbusday",put(end_mon,&fmt));
  run;
%mend lastbusday;

%lastbusday(mmddyy10.);

%put &lastbusday;


/* ------------------------------------------------------------------
   ***************************END PROGRAM****************************
   ------------------------------------------------------------------ */
