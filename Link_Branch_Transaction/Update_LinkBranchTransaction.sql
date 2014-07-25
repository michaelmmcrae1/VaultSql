/*
	Update_LinkBranchTransaction.sql
	
	Michael McRae
	July 21, 2014

	Connects a Branch to a Transaction by connecting Branch_SQN to Transaction_SQN from
	Hub_Branch and Hub_Transaction. This can help identify foot-traffic, and ATM usage. 
	Transactions with BRANCH = 0 can be a variety of things, but with TELLER_NUM = 898 it is either ATM usage
	or Card usage or ?something else?
*/
INSERT INTO sym_vault1.Link_Branch_Transaction(BRANCH_SQN, TRANSACTION_SQN, LINK_BRANCH_TRANSACTION_RSRC)
SELECT A.HUB_BRANCH_SQN, B.HUB_TRANSACTION_SQN, 'EASE' AS LINK_BRANCH_TRANSACTION_RSRC
FROM sym_vault1.Hub_Branch A
	JOIN sym_vault1.Hub_Transaction B
		ON A.BRANCH_NUM = B.BRANCH
LEFT JOIN sym_vault1.Link_Branch_Transaction C
	ON A.HUB_BRANCH_SQN = C.BRANCH_SQN AND B.HUB_TRANSACTION_SQN = C.TRANSACTION_SQN
WHERE C.BRANCH_SQN IS NULL AND C.TRANSACTION_SQN IS NULL