/*
	UpdateAcctShareShareT.sql

	Michael McRae
	July 1, 2014

	This is a 3-way link between Account,Share, and Share_Transaction. One way to view it: Given an Account, this will
	will show all Shares for that account, and all Share transactions for each loan on that account.
*/
INSERT INTO sym_vault1.Link_Acct_Share_ShareT(ACCT_SQN, SHARE_SQN, SHARET_SQN, LINK_ACCT_SHARE_SHARET_RSRC)
SELECT A.HUB_ACCT_SQN, B.HUB_SHARE_SQN, C.HUB_SHARE_TRANSACTION_SQN, 'EASE' AS LINK_ACCT_SHARE_SHARET_RSRC
FROM sym_vault1.Hub_Account A
	JOIN sym_vault1.Hub_Share B
		ON A.ACCT_NUM = B.PARENT_ACCT
	JOIN sym_vault1.Hub_Share_Transaction C
		ON B.PARENT_ACCT = C.PARENT_ACCT AND B.SHARE_ID = C.SHARE_ID
	LEFT JOIN sym_vault1.Link_Acct_Share_ShareT D
		ON A.HUB_ACCT_SQN = D.ACCT_SQN AND B.HUB_SHARE_SQN = D.SHARE_SQN
			AND C.HUB_SHARE_TRANSACTION_SQN = D.SHARET_SQN
WHERE D.ACCT_SQN IS NULL AND D.SHARE_SQN IS NULL AND D.SHARET_SQN IS NULL;