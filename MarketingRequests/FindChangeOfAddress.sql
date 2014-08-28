/*
	FindChangeOfAddress.sql

	Michael McRae
	August 18, 2014

	Joins SYM.NAME with Link_Acct_Addr on HUB_ACCT_SQN
	Selects rows where SYM.NAME's address (STREET,CITY,STATE,ZIPCODE) do not
	match the address of the Hub_Addr_Sqn connected to the Hub_Acct_Sqn.

	This requires Hub_Address, Hub_Person, and Hub_Account to be updated before
	this runs. But it must run before Link_Acct_Addr and Sat_LinkAcctAddr are updated
*/
SELECT DISTINCTROW C.HUB_ACCT_SQN, G.SSN, B.STREET, B.CITY, B.STATE, B.ZIPCODE, 'EASE' AS LINK_ACCT_ADDR_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Address B
		ON A.STREET = B.STREET AND A.CITY = B.CITY AND A.STATE = B.STATE AND A.ZIPCODE = B.ZIPCODE
	JOIN sym_vault1.Hub_Account C
		ON A.PARENTACCOUNT = C.ACCT_NUM
	JOIN sym_vault1.Link_Acct_Person F
		ON C.HUB_ACCT_SQN = F.HUB_ACCT_SQN
	JOIN sym_vault1.Hub_Person G
		ON F.HUB_PERSON_SQN = G.HUB_PERSON_SQN
	LEFT JOIN sym_vault1.Link_Acct_Addr D
		ON C.HUB_ACCT_SQN = D.HUB_ACCT_SQN
	LEFT JOIN sym_vault1.Sat_LinkAcctAddr_Effectivity E
		ON D.LINK_ACCT_ADDR_SQN = E.LINK_ACCT_ADDR_SQN
WHERE (D.HUB_ACCT_SQN IS NULL OR (E.END_DATE IS NULL AND B.HUB_ADDR_SQN <> D.HUB_ADDR_SQN)) AND A.ORDINAL = 0
INTO OUTFILE '/tmp/20140821new_address.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';