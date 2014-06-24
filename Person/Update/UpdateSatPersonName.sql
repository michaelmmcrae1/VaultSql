/*
	Michael McRae
	June 20, 2014

	Joins Hub_Person and SYM.NAME on Account# and Ordinal to find name associated with Hub_Person_SQN
	Then joins with Sat_Person_Name to find HUB_PERSON_SQN not already in Sat_Person_Name. Inserts
	missing HUB_PERSON_SQN and associated name into Sat_Person_Name.

	NOTE - Assumes that Hub_Person contains the most up to date unique list of names
	i.e. Hub_Person should be updated before Sat_Person_Name is updated
*/

INSERT INTO sym_vault1.Sat_Person_Name(HUB_PERSON_SQN, TITLE, FIRST, MIDDLE, LAST, SUFFIX)
SELECT A.HUB_PERSON_SQN, B.TITLE, B.FIRST, B.MIDDLE, B.LAST, B.SUFFIX
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ORDINAL = B.ORDINAL
	LEFT JOIN sym_vault1.Sat_Person_Name G
		ON A.HUB_PERSON_SQN = G.HUB_PERSON_SQN
WHERE G.HUB_PERSON_SQN IS NULL;