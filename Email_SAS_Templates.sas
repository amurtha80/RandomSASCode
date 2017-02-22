/* -------------------------------------------------------------------
   Basic email wtih no attachments
   ------------------------------------------------------------------- */
FILENAME outbox EMAIL from=("andy.murtha@suntrust.com")
  to=("andy.murtha@suntrust.com")
  /*cc=("theresam@uab.edu")*/
  Subject = "An automatic email sent from SAS";

data _null_;
  file outbox;
  put "Your report is now available online."
  / / "Thank you and have a great day."
  / / " "
  / / "Sincerely,"
  / / "Theresa McVie"
  / / " "
  / / "This is an automated email sent by SAS on behalf of Andy Murtha";
run;



/* -------------------------------------------------------------------
   Basic email with an attachment(s)
   ------------------------------------------------------------------- */
/*Create data for report*/
data one;
  INPUT NAME $ 1-10 SEX $ 12 AGE Height WEIGHT;
  datalines;
STEVE M 41 74 170
ROCKY M 42 68 166
KURT M 39 72 167
DEBORAH F 30 66 124
JACQUELINE F 33 66 115
;
run;

/*Create rtf file to be emailed via SAS*/
ods rtf file = "\\your target filepath\filepath subfolder\report1_&SYSDATE..rtf";
proc freq data=one;
  title "First Example Report";
  tables sex;
run;
ods rtf close;

/*Begin email code*/
FILENAME outbox2 EMAIL from=("andy.murtha@suntrust.com")
  to=("andy.murtha@suntrust.com")
  Subject = "An email with attachment sent from SAS"
  Attach = \\your target filepath\filepath subfolder\report1_&SYSDATE..rtf";

data _null_;
  file outbox2;
  put "Please see attached for your daily report."
  / / "Thank you and have a great day."
  / / " "
  / / "Sincerely,"
  / / "Theresa McVie"
  / / " "
  / / "This is an automated email sent by SAS on behalf of Andy Murtha";
run;



/* -------------------------------------------------------------------
   Email that sends datasets as html report output
   ------------------------------------------------------------------- */
FILENAME outbox3 EMAIL
 to=('andy.murtha@suntrust.com')
 /* Overrides value in */
 /* filename statement */

 cc=('andy.murtha@suntrust.com')
 subject="2014 Credit Risk Oversight Audit - Rate Override Report"
 content_type="text/HTML";
ODS LISTING CLOSE;
ODS HTML BODY= outbox STYLE=styles.minimal;
TITLE 'Credit Risk Oversight - Rate Override (Booked Apps) Report';
PROC REPORT DATA=proj_dir.res_RO_OVERRIDE_SUMM;
  COLUMN app_aprv_product_code prm_product_name count app_aprv_amt;
RUN;
QUIT;
TITLE;

TITLE 'Credit Risk Oversight - Rate Override (All Apps) Report';
PROC REPORT DATA=proj_dir.res_RO_ALL_SUMM;
  COLUMN app_aprv_product_code prm_product_name count app_aprv_amt;
RUN;
QUIT;
TITLE;
ODS HTML CLOSE;
ODS LISTING;



/* -------------------------------------------------------------------
   Sample Email Macro
   ------------------------------------------------------------------- */
/* Macro to send an e-mail with an attachment */
/* Parameters:
pMail: e-mail address of the addressee
pCcmail: e-mail address of the addressee for copy
pSubject: e-mail subject
pAttach: name, path and extension of the attached file
pContents: e-mail contents */

%MACRO EMail(pMail,pCcmail,pSubject,pAttach,pContents);
FILENAME mymail EMAIL "NULL"
  TO=&pMail
  CC=&pCcmail
  SUBJECT="&pSubject"
  ATTACH="&pAttach";

DATA _NULL_;
  FILE mymail;
  PUT "&pContents";
RUN;
%MEND;



/* -------------------------------------------------------------------
   Additional sample code for emailing reports - Conditional emails
   If a user needs to have a condition to where an email may/may not
   be generated depending on that condition (ex. if no exceptions than
   no report will be emailed)
   ------------------------------------------------------------------- */
/* Sample Conditional code to determine if email will be sent) */
%let send_email = 0;  * WHEN 0 EMAIL WILL NOT BE SENT. WHEN 1 EMAIL WILL BE SENT;

data _null_;
  set mydata;
  if x = 1 then do;
    call symput('send_email',1);
    stop; * LEAVE THE DATASTEP AS SOON AS WE DECIDE AN EMAIL SHOULD BE SENT;
  end;
run;

/* Email macro based on the prior conditional statement */
%macro send_email;
  %if &send_email eq 1 %then %do;
    filename outbox email 'dan.xxxxx@zz.com';
    data _null_;
      file outbox to=("dan.xxxxx@zzcom") subject="Email test";
      put "Email test from SAS program";
      put " ";
    run;
  %end;
%mend;
%send_email;



/* -------------------------------------------------------------------
   Additional sample code for emailing reports - PROC PRINT
   ------------------------------------------------------------------- */
options ls=130;
filename outbox4 EMAIL TO=('andy.murtha@suntrust.com')
     SUBJECT="Input Deposit Files - &report" CONTENT_TYPE="text/html" ;
ods listing close;
ods html body=mail style=Template;
proc print data=jim.report l u noobs;
var  day count balance;
by source_file source;
id source_file source;
format balance count comma18.;
label day = 'Run Date'
     source = 'Deposit Source'
     Source_file = 'Input File'
     count = 'Number Of Records'
     Balance = 'Balance';
     title1 'LCR Deposit Files Received From DIME';
     title2 ' ';
     title3 "&report";
     run;
     ods html close;
     ods listing;
run;



/* -------------------------------------------------------------------
   Additional sample code for emailing reports - PROC PRINT
   ------------------------------------------------------------------- */
options ls=130;
filename outbox5 EMAIL TO=('andy.murtha@suntrust.com')
     SUBJECT="LCR Denominator Run-Off Totals - &report" CONTENT_TYPE="text/html" ;
ods listing close;
ods html body=mail style=Template;
proc print data=rep2 l u noobs;
sum bal runoff;
var Retail_Wholesale source group Runoff_Factor Bal Runoff;
format bal runoff comma18.;
label Retail_Wholesale = 'Retail Or Wholesale?'
     source = 'Source'
     group = 'Category'
     Runoff_Factor = 'Runoff'
     Bal = 'Balance'
     Runoff ='Total Runoff';
     title1 'LCR Denominator Run-Off Totals';
     title2 'For Deposits and TPG';
     title3 "&report";
     run;
     ods html close;
     ods listing;
run;
