data test;
input name $ ID $;
datalines;
Tommy 1
Andy 2
Daniel 3
Bing 4
;
RUN;

data test2;
input ID $ ACCT $ ACCT_TYPE $;
datalines;
1 123 LST
1 234 LST
1 345 DEP
2 456 LST
2 567 LST
3 678 DEP
3 789 BRK
3 890 LST
4 111 LST
;
RUN;


/*Method #1*/
PROC SQL;
CREATE TABLE TEST3 AS 
SELECT
TEST.NAME
,TEST.ID
,LST.ACCT
,LST.ACCT_TYPE
/*Looking for records that only have this account type and also people
	who only have this account type*/
FROM WORK.TEST
	LEFT JOIN WORK.TEST2 LST
	ON LST.ID = TEST.ID 
	AND LST.ACCT_TYPE = 'LST'
LEFT JOIN WORK.TEST2 NOLST
	ON NOLST.ID = TEST.ID
	AND NOLST.ACCT_TYPE ^= 'LST'
	WHERE NOLST.ID IS NULL
;
QUIT; 


/*Method #2*/
PROC SQL;
CREATE TABLE TEST3 AS 
SELECT
TEST.NAME
,TEST.ID
,LST.ACCT
,LST.ACCT_TYPE
FROM WORK.TEST
	LEFT JOIN WORK.TEST2 LST
	ON LST.ID = TEST.ID 
GROUP BY TEST.ID
/*Looking for records that only have this account type and also people
	who only have this account type*/
HAVING (LST.ACCT_TYPE = 'LST' AND COUNT(DISTINCT TEST2.ACCT_TYPE) =1) 
	;
QUIT;
