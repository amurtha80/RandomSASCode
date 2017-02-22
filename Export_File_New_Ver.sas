/* ------------------------------------------------------------------
   Export Report out to file (Excel Ex.) with datestamp
  	YYYYMMDD Format - As of date the report was run
   ------------------------------------------------------------------ */

/*Get date (assuming report was run on current date*/
%LET file_dt = %SYSFUNC(PUTN(%sysevalf(%SYSFUNC(TODAY())),yymmdd8.));

/*Run proc export with macro &file_dt in destination file name*/
PROC EXPORT DATA=projdir.outfile     
	    /***Enter OUTFILE Excel Name Here***/
	    OUTFILE='/insert your filepath here/Project Folder/Project Subfolder/Project File &file_dt..xls'
            DBMS=xls REPLACE;
            SHEET="Sheet1";
RUN;



/* ------------------------------------------------------------------
   Export Report out to file (Excel 2003 Ex.) with most current version
  	-If no prior file with same name, then version = "v01"
	-If a prior version exists, then version = "v(n+1)"
   ------------------------------------------------------------------ */

/*Example that reads the names of the files in the target directory*/
data myfiles;
  keep filename;
  
  length fref $8 filename $80; 
  rc = filename(fref, '\\insert your filepath here\mytargetdirectory'); 

  if rc = 0 then 
    do; 
      did = dopen(fref); 
      rc = filename(fref); 
    end;
  else
    do;
      length msg $200.; 
      msg = sysmsg(); 
      put msg=; 
      did = .;
    end;

  if did <= 0 then 
    putlog 'ERR' 'OR: Unable to open directory.';

  dnum = dnum(did);

  do i = 1 to dnum; 
    filename = dread(did, i); 
    /* If this entry is a file, then output. */ 
    fid = mopen(did, filename); 
    if fid > 0 then 
      output; 
  end;

  rc = dclose(did);

run;

proc sort data=myfiles; by filename; run;
proc print data=myfiles; run;


/*Start with 1st version of document (v01) and iterate until you do not
  find a match. if there is not a match to the first version of the 
  document, then the document is the first version). 

  This will not complete above version "v09"!!! If you have that many
  versions then you may need to revise your methodology for version
  control ;) */

%LET i=1;
%LET filenm=yourexcelfilename v0&i..xls

proc sql noprint;
  select count(obs)
    into: numobs
    from myfiles
  ;
quit;

k=0;
%do while k=0
  %do j=1 to &numobs;
    data _null_;
      set myfiles;

      if &filenm=filename then
        &i=&i+1;
      else k=1;      

      Where obs=j;
    run;
    
    j+1;      
    %put &i;
    %put &filenm;
  end;
end;



/* Ray's code to determine if there is a file in the account that matches the target file*/
%let dir='your target directory/directory subfolder/BOTS Match'; 
options mlogic symbolgen; 
/* Macro to Create a directory */ 
%macro CheckandCreateDir(dir); 
/*options noxwait;*/ 
%local rc fileref ; 
%let rc =%sysfunc(filename(fileref,&dir)) ; 
%if  %sysfunc(fexist(&fileref))%then  
%put The directory "&dir" already exists ; 
%else 
%do; 
%sysexec mkdir "&dir"; %if &sysrc eq 0 
%then %put The directory &dir has been created. ; 
%else %put There was a problem while creating the directory &dir; 
%end; 
%mend CheckandCreateDir ; 
%CheckandCreateDir(dir=/your filepath here/filepath subfolder/BOTS Matched) ;    
%*   <==  your directory specification goes here ;
