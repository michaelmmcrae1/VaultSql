/*
	UpdateLinkAcctLoan_WORKING.sql

	Michael McRae
	June 23, 2014

	Joins SYM.NAME to Hub_Address on address info to connect address to ADDRESS_SQN. Joins with Hub_Account
	on Account # and Ordinal to connect ACCT_SQN.

	Hub_Addresses only contains addresses of accounts with ordinal = 0, but WHERE ORDINAL = 0
	is needed here as well, otherwise we get more than one address for an account, if there is an address
	associated with a joint on an account and also associated with a primary on a separate account.
*/
INSERT INTO sym_vault1.Link_Acct_Loan(ACCT_SQN, LOAN_SQN, LINK_ACCT_LOAN_RSRC)
SELECT A.HUB_ACCT_SQN, B.HUB_LOAN_SQN, 'EASE' AS LINK_ACCT_LOAN_RSRC
FROM sym_vault1.Hub_Account A
	JOIN sym_vault1.Hub_Loan B
		ON A.ACCT_NUM = B.PARENT_ACCT
	LEFT JOIN sym_vault1.Link_Acct_Loan C
		ON A.HUB_ACCT_SQN = C.ACCT_SQN AND B.HUB_LOAN_SQN = C.LOAN_SQN
WHERE C.ACCT_SQN IS NULL AND C.LOAN_SQN IS NULL;