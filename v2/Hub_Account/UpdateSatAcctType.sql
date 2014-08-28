/*
	UpdateSatAcctType.sql

	Michael McRae
	August 25, 2014

	Keeps a record of an Account#'s changing Type.
	Inserts new Hub_Acct_sqn and Type when Hub_Acct_Sqn is not already in
	Sat_Account_Type.
	As Type changes in SYM.ACCOUNT, update Sat_Account_Type to track these changes

	Sat_Account_Type row where END_DATE IS NULL is current Type of an Account
*/
-- add ACTT_SQN and Type when H_ACCT_SQN not already in table
INSERT INTO sym_vault2.S_Account_Type(H_ACCT_SQN, TYPE)
SELECT
	B.H_ACCT_SQN, A.TYPE
FROM SYM.ACCOUNT A
	JOIN sym_vault2.H_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	LEFT JOIN sym_vault2.S_Account_Type D
		ON B.H_ACCT_SQN = D.H_ACCT_SQN
WHERE D.H_ACCT_SQN IS NULL;
-- add new Type
INSERT INTO sym_vault2.S_Account_Type(H_ACCT_SQN, TYPE)
SELECT
	B.H_ACCT_SQN, A.TYPE
FROM SYM.ACCOUNT A
	JOIN sym_vault2.H_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	JOIN sym_vault2.S_Account_Type C
		ON B.H_ACCT_SQN = D.H_ACCT_SQN
WHERE A.TYPE <> C.TYPE AND C.END_DATE IS NULL;
-- set END_DATE for outdated Types
UPDATE sym_vault2.S_Account_Type A
	JOIN sym_vault2.H_Account B
		ON A.H_ACCT_SQN = B.H_ACCT_SQN
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET A.END_DATE = NOW()
WHERE A.TYPE <> C.TYPE AND A.END_DATE IS NULL;