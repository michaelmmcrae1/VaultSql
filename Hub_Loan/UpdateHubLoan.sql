/*
	Michael Mcrae
	July 1, 2014

	Joins Hub_Account with SYM.LOAN to only look at those loans for accounts already in Data Warehouse.
	Takes Loan info (PARENTACCOUNT, ID) from SYM.LOAN not already in Hub_Loan and inserts
	it into Hub_Loan.

*/

INSERT INTO sym_vault1.Hub_Loan(PARENT_ACCT, LOAN_ID, HUB_LOAN_RSRC)
SELECT PARENTACCOUNT, ID, 'EASE' AS HUB_LOAN_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.LOAN B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Loan C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.LOAN_ID
WHERE C.PARENT_ACCT IS NULL AND C.LOAN_ID IS NULL;