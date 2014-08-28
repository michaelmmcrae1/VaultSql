/*
	UpdateSatAcctAddr.sql
	
	Michael McRae
	August 25, 2014

	Keeps track of the STREET,CITY,STATE,ADDRESS of Primary Account holder in SYM.NAME for each Account.
*/
-- Add Acct_Num, Address Of Account which is not currently in Sat
INSERT INTO sym_vault2.S_Account_Address(H_ACCT_SQN, STREET, CITY, STATE, ZIPCODE)
SELECT B.H_ACCT_SQN, A.STREET, A.CITY, A.STATE, A.ZIPCODE
FROM SYM.NAME A
	JOIN sym_vault2.H_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM AND A.ORDINAL = 0
	LEFT JOIN sym_vault2.S_Account_Address C
		ON B.H_ACCT_SQN = C.H_ACCT_SQN
WHERE C.H_ACCT_SQN IS NULL;
-- Add new Address of Account
INSERT INTO sym_vault2.S_Account_Address(H_ACCT_SQN, STREET, CITY, STATE, ZIPCODE)
SELECT B.H_ACCT_SQN, A.STREET, A.CITY, A.STATE, A.ZIPCODE
FROM SYM.NAME A
	JOIN sym_vault2.H_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM AND A.ORDINAL = 0
	JOIN sym_vault2.S_Account_Address C
		ON B.H_ACCT_SQN = C.H_ACCT_SQN
WHERE (A.STREET <> C.STREET OR A.CITY <> C.CITY OR A.STATE <> C.STATE OR A.ZIPCODE <> C.ZIPCODE)
		AND C.END_DATE IS NULL;
-- set END_DATE = NOW() for out-of-date Address for Account
UPDATE sym_vault2.S_Account_Address A
	JOIN sym_vault2.H_Account B
		ON A.H_ACCT_SQN = B.H_ACCT_SQN
	JOIN SYM.NAME C
		ON B.ACCT_NUM = C.PARENTACCOUNT AND C.ORDINAL = 0
SET END_DATE = NOW()
WHERE (A.STREET <> C.STREET OR A.CITY <> C.CITY OR A.STATE <> C.STATE OR A.ZIPCODE <> C.ZIPCODE)
		AND A.END_DATE IS NULL;