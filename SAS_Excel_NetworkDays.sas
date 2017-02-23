/*Come up with number of business days between two dates that
  includes banking holidays. First define the bank holidays during
  the testing period. Then determine how many vacation days were
  taken by the employee during the year when accounting for weekends
  and holidays.*/
data work.dim_bankholidays;
	input holidaydate mmddyy10.;
	datalines;
01/01/2016
01/18/2016
02/15/2016
05/30/2016
07/04/2016
09/05/2016
10/10/2016
11/11/2016
11/24/2016
12/26/2016
;

options cmplib = _null_;



/*Next create the user defined function NETWORKDAYS, similar to the
  Excel function networkdays.*/
proc fcmp  outlib=work.myfuncs.dates;
  function networkdays(d1,d2,holidayDataset $,dateColumn $);
 
    /* make sure the start date < end date */
    start_date = min(d1,d2);
    end_date = max(d1,d2);
 
    /* read holiday data into array */
    /* array will resize as necessary */
    array holidays[1] / nosymbols; 
    if (not missing(holidayDataset) and exist(holidayDataset)) then
        rc = read_array(holidayDataset, holidays, dateColumn);
    else put "NOTE: networkdays(): No Holiday data considered"; 
 
    /* INTCK computes transitions from one day to the next */
    /* To include the start date, if it is a weekday, then */
    /*  make the start date one day earlier.               */
    if (1 < weekday(start_date)< 7) then 
       calc_start_date = start_date-1; 
    else 
       calc_start_date = start_date;
    diff = intck('WEEKDAY', calc_start_date, end_date);
    do i = 1 to dim(holidays);
      if (1 < weekday(holidays[i])< 7) and
         (start_date <= holidays[i] <= end_date) then
            diff = diff - 1; 
    end; 
    return(diff);
  endsub; 
run; quit;



/*Declare the function library*/
options cmplib=(work.myfuncs);



/*Determine the number of business days that were taken by each
  employee during 2016*/
data work.tbl_test01_2016vacadays;
	set work.src_trader_2016vaca;

	NumVacaDays = networkdays(FirstDay, LastDay, "work.dim_bankholidays", "holidaydate");
run;

