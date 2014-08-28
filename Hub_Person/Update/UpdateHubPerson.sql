/*
	UpdateHubPerson.sql

	Michael McRae
	July 23, 2014

	Takes every SSN from SYM.NAME as long as it's not a Mailing row {TYPE <> 2 AND TYPE <> 3}
	and inserts them into Hub_Person.

	Only takes Persons from Accounts which are still open {END_DATE IS NULL in Sat_Account_Closed}
*/
INSERT INTO sym_vault1.Hub_Person(SSN, HUB_PERSON_RSRC)
SELECT
	DISTINCT A.SSN, 'EASE'
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Person D
		ON A.SSN = D.SSN
WHERE A.SSN <> '' AND A.SSN <> '000000000' AND A.ORDINAL = 0
		AND D.SSN IS NULL;