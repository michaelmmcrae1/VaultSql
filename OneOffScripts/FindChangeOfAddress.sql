/*
	FindChangeOfAddress.sql

	Michael McRae
	August 18, 2014

	Joins SYM.NAME with Link_Acct_Addr on HUB_ACCT_SQN
	Selects rows where SYM.NAME's address (STREET,CITY,STATE,ZIPCODE) do not
	match the address of the Hub_Addr_Sqn connected to the Hub_Acct_Sqn.
*/
SELECT B.ACCT_NUM, F.SSN, A.STREET, A.CITY, A.STATE, A.ZIPCODE, NOW() AS 'CURRENT_DATE'
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM AND A.ORDINAL = 0
	JOIN sym_vault1.Link_Acct_Addr C
		ON B.HUB_ACCT_SQN = C.HUB_ACCT_SQN
	JOIN sym_vault1.Hub_Address D
		ON C.HUB_ADDR_SQN = D.HUB_ADDR_SQN
	JOIN sym_vault1.Link_Acct_Person E
		ON C.HUB_ACCT_SQN = E.HUB_ACCT_SQN
	JOIN sym_vault1.Hub_Person F
		ON E.HUB_PERSON_SQN = F.HUB_PERSON_SQN
WHERE (A.STREET <> D.STREET OR A.CITY <> D.CITY OR A.STATE <> D.STATE OR A.ZIPCODE <> D.ZIPCODE)
		AND (A.STREET <> '' OR A.CITY <> '' OR A.STATE <> '' OR A.ZIPCODE <> '');

/*
INTO OUTFILE '/tmp/new_address.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';