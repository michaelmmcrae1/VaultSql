/*
	UpdateHubTransaction_SHARE.sql

	Michael McRae
	July 8, 2014

	Assumes SaingsTransaction only gets new transactions(deltas) [what if it is null... need something for that]. Loads
	The primary key of a unique SAVINGSTRANSACTION, and 'S' into Hub_Transaction. Left joins so it only adds those
	not already in Hub_Transaction.
*/
INSERT INTO sym_vault1.Hub_Transaction(PARENT_ACCT, ID, CATEGORY, SEQUENCE_NUM, POST_DATE, HUB_TRANSACTION_RSRC)
SELECT PARENTACCOUNT, PARENTID, 'S' AS CATEGORY, SEQUENCENUMBER, POSTDATE, 'EASE' AS HUB_TRANSACTION_RSRC
FROM SYM.SAVINGSTRANSACTION A
	LEFT JOIN sym_vault1.Hub_Transaction B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.PARENTID = B.ID AND A.SEQUENCENUMBER = B.SEQUENCE_NUM
		AND B.CATEGORY = 'S'
WHERE B.PARENT_ACCT IS NULL AND B.ID IS NULL AND B.SEQUENCE_NUM IS NULL AND A.COMMENTCODE = 0;