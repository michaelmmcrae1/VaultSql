/*
	UpdateLinkAcctShare.sql

	Michael Mcrae
	July 1, 2014

	Joins Hub_Account and Hub_Share with ACCT_NUM = PARENT_ACCT to connect an account with a share.
	Left joins with Link_Acct_Share to only insert those not already in the table.
*/
INSERT INTO sym_vault1.Link_Acct_Share(ACCT_SQN, SHARE_SQN, LINK_ACCT_SHARE_RSRC)
SELECT A.HUB_ACCT_SQN, B.HUB_SHARE_SQN, 'EASE' AS LINK_ACCT_SHARE_RSRC
FROM sym_vault1.Hub_Account A
	JOIN sym_vault1.Hub_Share B
		ON A.ACCT_NUM = B.PARENT_ACCT
	LEFT JOIN sym_vault1.Link_Acct_Share C
		ON A.HUB_ACCT_SQN = C.ACCT_SQN AND B.HUB_SHARE_SQN = C.SHARE_SQN
WHERE C.ACCT_SQN IS NULL AND C.SHARE_SQN IS NULL;