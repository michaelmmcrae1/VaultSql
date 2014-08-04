SELECT
	A.ACCOUNTNUMBER, A.OPENDATE, C.STREET, C.CITY, C.STATE, C.ZIPCODE
FROM SYM.ACCOUNT A
	LEFT JOIN sym_vault1.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	JOIN SYM.NAME C
		ON A.ACCOUNTNUMBER = C.PARENTACCOUNT
WHERE B.ACCT_NUM IS NULL AND C.CITY = 'GENESEO' OR C.ZIPCODE = 61254 AND A.OPENDATE > '2014-07-25'
		AND A.CLOSEDATE = '0000-00-00' AND A.ACCOUNTNUMBER >= '0000000260'