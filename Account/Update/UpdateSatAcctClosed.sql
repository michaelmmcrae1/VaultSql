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