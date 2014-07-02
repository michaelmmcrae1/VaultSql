/*
	UpdateHubShare.sql

	Michael McRae
	July 1, 2014

	Joins SYM.SAVINGS with Hub_Account to only get shares connected with accounts
	currently in Data Warehouse. Inserts PARENTACCOUNT,ID of shares into Hub_Share which
	are not already in the table.
*/
INSERT INTO sym_vault1.Hub_Share(PARENT_ACCT, SHARE_ID, HUB_SHARE_RSRC)
SELECT PARENTACCOUNT, ID, 'EASE' AS HUB_LOAN_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.SAVINGS B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Share C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.SHARE_ID
WHERE C.PARENT_ACCT IS NULL AND C.SHARE_ID IS NULL;