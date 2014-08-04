/*
	UpdateLinkTransactionComment.sql

	Michael McRae
	July 25, 2014

	Combines a Transaction from Hub_Transaction and a Transaction Comment from Hub_Transaction_Comment
	Connects them on HUB_TRANSACTION_SQN.
	It is a 1 to Many relationship with one HUB_TRANSACTION_SQN having multiple Comments, but one each comment only connects
	to 1 Transaction.
*/
INSERT INTO Link_Transaction_Comment(HUB_TRANSACTION_SQN, HUB_TRANSACTION_COMMENT_SQN, LINK_TRANSACTION_COMMENT_RSRC)
SELECT
	A.HUB_TRANSACTION_SQN, B.HUB_TRANSACTION_COMMENT_SQN, 'EASE'
FROM Hub_Transaction A
	JOIN Hub_Transaction_Comment B
		ON A.HUB_TRANSACTION_SQN = B.HUB_TRANSACTION_SQN
	LEFT JOIN Link_Transaction_Comment C
		ON A.HUB_TRANSACTION_SQN = C.HUB_TRANSACTION_SQN AND B.HUB_TRANSACTION_COMMENT_SQN = C.HUB_TRANSACTION_COMMENT_SQN
WHERE C.HUB_TRANSACTION_SQN IS NULL AND C.HUB_TRANSACTION_COMMENT_SQN IS NULL;