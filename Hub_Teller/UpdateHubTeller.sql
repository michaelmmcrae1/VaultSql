/*
	UpdateHubTeller.sql

	Michael McRae
	July 9, 2014

	Finds USERNUMBER - which is our TELLER_NUM - from SYM.USERS and inserts those not already in Hub_Teller
*/
INSERT INTO sym_vault1.Hub_Teller(TELLER_NUM, HUB_TELLER_RSRC)
SELECT A.USERNUMBER, 'EASE' AS HUB_TELLER_RSRC
FROM SYM.USERS A
	LEFT JOIN sym_vault1.Hub_Teller B
		ON A.USERNUMBER = B.TELLER_NUM
WHERE B.TELLER_NUM IS NULL;

/*
	Inserts Teller_SQN and Description associated with Teller_SQN into Sat_Teller_Description, if that Teller_SQN
	is not already in the table
*/
INSERT INTO sym_vault1.Sat_Teller_Description(TELLER_SQN, DESCRIPTION)
SELECT A.HUB_TELLER_SQN, B.NAME
FROM sym_vault1.Hub_Teller A
	JOIN SYM.USERS B
		ON A.TELLER_NUM = B.USERNUMBER
LEFT JOIN sym_vault1.Sat_Teller_Description C
		ON A.HUB_TELLER_SQN = C.TELLER_SQN
WHERE C.TELLER_SQN IS NULL;

/*
	Updates change of Description associated with already-added Teller_SQN in Sat_Teller_Description
*/
INSERT INTO sym_vault1.Sat_Teller_Description(TELLER_SQN, DESCRIPTION)
SELECT C.TELLER_SQN, B.NAME
FROM sym_vault1.Hub_Teller A
	JOIN SYM.USERS B
		ON A.TELLER_NUM = B.NUMBER
	JOIN sym_vault1.Sat_Teller_Description C
		ON A.HUB_TELLER_SQN = C.TELLER_SQN
WHERE C.DESCRIPTION <> B.NAME AND C.END_DATE IS NULL;

UPDATE sym_vault1.Sat_Teller_Description A
	JOIN sym_vault1.Hub_Teller B
		ON A.TELLER_SQN = B.HUB_TELLER_SQN
	JOIN SYM.USERS C
		ON B.TELLER_NUM = C.USERNUMBER
SET A.DESCRIPTION = C.NAME
WHERE A.DESCRIPTION <> C.NAME AND A.END_DATE IS NULL;
