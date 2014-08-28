/*
	UpdateSatAcctSSN.sql
	
	Michael McRae
	August 25, 2014

	Keeps track of the SSN of Primary Account holder in SYM.NAME for each Account.
*/
-- Add SSN Of Account which is not currently in Sat
INSERT INTO sym_vault2.S_Account_SSN(H_ACCT_SQN, SSN)
SELECT B.H_ACCT_SQN, A.SSN
FROM SYM.NAME A
	JOIN sym_vault2.H_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM AND A.ORDINAL = 0
	LEFT JOIN sym_vault2.S_Account_SSN C
		ON B.H_ACCT_SQN = C.H_ACCT_SQN
WHERE C.H_ACCT_SQN IS NULL;
-- Add new SSN of Account
INSERT INTO sym_vault2.S_Account_SSN(H_ACCT_SQN, SSN)
SELECT B.H_ACCT_SQN, A.SSN
FROM SYM.NAME A
	JOIN sym_vault2.H_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM AND A.ORDINAL = 0
	JOIN sym_vault2.S_Account_SSN C
		ON B.H_ACCT_SQN = C.H_ACCT_SQN
WHERE A.SSN <> C.SSN AND C.END_DATE IS NULL;
-- set END_DATE = NOW() for out-of-date SSN for Account
UPDATE sym_vault2.S_Account_SSN A
	JOIN sym_vault2.H_Account B
		ON A.H_ACCT_SQN = B.H_ACCT_SQN
	JOIN SYM.NAME C
		ON B.ACCT_NUM = C.PARENTACCOUNT AND C.ORDINAL = 0
SET END_DATE = NOW()
WHERE C.SSN <> A.SSN AND A.END_DATE IS NULL;