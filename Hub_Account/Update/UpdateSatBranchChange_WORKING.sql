/*
	Michael McRae
	June 30, 2014

	First, inserts a new record into Sat_Account_Closed with the new branch connected with it.

	Second, set the END_DATE to NOW() for rows in Sat_Account_Closed where the current BRANCH
	does not match the BRANCH in SYM.ACCOUNT.

	The most recent row for a certain HUB_ACCT_SQN is the one with an END_DATE of null. This is
	the row is the focus when this table is updated.
*/
INSERT INTO sym_vault1.Sat_Account_Closed(HUB_ACCT_SQN, BRANCH, START_DATE)
SELECT D.HUB_ACCT_SQN, C.BRANCH, D.START_DATE
FROM sym_vault1.Hub_Account B
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
	JOIN sym_vault1.Sat_Account_Closed D
		ON B.HUB_ACCT_SQN = D.HUB_ACCT_SQN
WHERE D.BRANCH <> C.BRANCH;

UPDATE sym_vault1.Sat_Account_Closed A
	JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET END_DATE = IF(A.BRANCH <> C.BRANCH, NOW(), null)
WHERE C.BRANCH <> A.BRANCH AND END_DATE IS NULL;