/*
	Michael McRae
	June 23, 2014

	GROUP BY SSN from previous UpdateHubPerson script was behaving unexpectedly.

	This finds unique humans by selecting distinct SSN's. This leaves out about 900 entries,
	with no SSN in the system, representing about 700 accounts, but is very accurate for 
	the remaining ~50,000 individuals.
*/

INSERT INTO sym_vault1.Hub_Person(SSN, HUB_PERSON_RSRC)
SELECT DISTINCT A.SSN, 'EASE' AS HUB_PERSON_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Person C
		ON A.SSN = C.SSN
WHERE C.SSN IS NULL AND A.SSN <> '' AND A.SSN <> '000000000';