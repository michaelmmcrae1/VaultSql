/*
	UpdateSatAcctType.sql

	Michael McRae
	July 28, 2014

	Keeps a record of an Account#'s changing Type.
	Inserts new Hub_Acct_sqn and Type when Hub_Acct_Sqn is not already in
	Sat_Account_Type.
	As Type changes in SYM.ACCOUNT, update Sat_Account_Type to track these changes

	Sat_Account_Type row where END_DATE IS NULL is current Type of an Account
*/
INSERT INTO sym_vault1.Sat_Account_Type(HUB_ACCT_SQN, TYPE)
SELECT
	B.HUB_ACCT_SQN, A.TYPE
FROM SYM.ACCOUNT A
	JOIN sym_vault1.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	LEFT JOIN sym_vault1.Sat_Account_Type D
		ON B.HUB_ACCT_SQN = D.HUB_ACCT_SQN
WHERE D.HUB_ACCT_SQN IS NULL;

INSERT INTO sym_vault1.Sat_Account_Type(HUB_ACCT_SQN, TYPE)
SELECT
	B.HUB_ACCT_SQN, A.TYPE
FROM SYM.ACCOUNT A
	JOIN sym_vault1.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	JOIN sym_vault1.Sat_Account_Closed C
		ON B.HUB_ACCT_SQN = C.HUB_ACCT_SQN
	JOIN sym_vault1.Sat_Account_Type D
		ON B.HUB_ACCT_SQN = D.HUB_ACCT_SQN
WHERE A.TYPE <> D.TYPE AND D.END_DATE IS NULL AND C.END_DATE IS NULL;

UPDATE sym_vault1.Sat_Account_Type A
	JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET A.END_DATE = NOW()
WHERE A.TYPE <> C.TYPE AND A.END_DATE IS NULL;