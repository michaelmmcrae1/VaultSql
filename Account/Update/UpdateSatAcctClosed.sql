/*
	Michael McRae
	June 20, 2014

	Finds HUB_ACCT_SQN, and associated Account Number, not already in Sat_Account_Closed. Uses the Account Number to join with
	SYM.ACCOUNT to find the current BRANCH of these Accounts.
*/

INSERT INTO Sat_Account_Closed(HUB_ACCT_SQN, BRANCH)
SELECT D.HUB_ACCT_SQN, BRANCH FROM SYM.ACCOUNT C JOIN
(SELECT A.HUB_ACCT_SQN, A.ACCT_NUM FROM Hub_Account A
LEFT JOIN
Sat_Account_Closed B
ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
WHERE B.HUB_ACCT_SQN IS NULL) D
ON C.ACCOUNTNUMBER = D.ACCT_NUM;

/*

	To update the closedate of those Accounts which are closed.
*/

UPDATE sym_vault1.Sat_Account_Closed A
	INNER JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
	INNER JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET END_DATE = IF(C.CLOSEDATE <> '0000-00-00', C.CLOSEDATE, null);
