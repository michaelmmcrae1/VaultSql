/*
	Michael McRae
	June 19, 2014

	Joins SYM.ACCOUNT and Hub_Account on Account Number. Finds those which are not already in
	Hub_Account, and inserts them. Only adds Account Numbers without a closedate (i.e. CLOSEDATE = '0000-00-00')
*/
INSERT INTO sym_vault2.Hub_Account(ACCT_NUM, OPEN_DATE, RSRC)
SELECT ACCOUNTNUMBER, OPENDATE, 'EASE' AS RSRC
FROM SYM.ACCOUNT A
	LEFT JOIN sym_vault2.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
WHERE B.ACCT_NUM IS NULL AND A.CLOSEDATE = '0000-00-00' AND A.ACCOUNTNUMBER >= '0000000260';