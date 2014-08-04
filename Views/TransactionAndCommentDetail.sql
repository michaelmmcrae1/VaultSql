/*
	TransactionAndCommentDetail.sql

	Uses Link_Transaction_Comment, but places detail for a Transaction and a Comment
	in place of SQN numbers -- so we  can see the detail instead of jumping around from
	table to table
*/
SELECT
	PARENT_ACCT, ID, CATEGORY, DESCRIPTION, COMMENT
FROM Link_Transaction_Comment A
	JOIN Hub_Transaction B
		ON A.HUB_TRANSACTION_SQN = B.HUB_TRANSACTION_SQN
	JOIN Hub_Transaction_Comment C
		ON A.HUB_TRANSACTION_COMMENT_SQN = C.HUB_TRANSACTION_COMMENT_SQN
