SELECT PARENTACCOUNT, ORDINAL, TITLE, FIRST, MIDDLE, LAST, SUFFIX
FROM SYM.NAME
WHERE SSN = '002661184';

/*
-- This shows that the current Link_Acct_Person is an accurate model
SELECT * FROM sym_vault1.Link_Acct_Person A
	JOIN sym_vault1.Hub_Person B
		ON A.PERSON_SQN = B.HUB_PERSON_SQN
WHERE B.SSN = '002661184';
*/