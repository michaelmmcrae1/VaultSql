SELECT count(*)
FROM SYM.NAME A
	JOIN SYM.ACCOUNT B
		ON A.PARENTACCOUNT = B.ACCOUNTNUMBER
WHERE (SSN IS NULL OR SSN = '' OR SSN = '000000000') AND CLOSEDATE = '0000-00-00';