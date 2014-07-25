/*
	DeleteDupTransactions.sql

	Michael McRae
	July 25, 2014

	Deletes rows in Hub_Transaction which have duplicate PARENT_ACCT,ID,SEQUENCE_NUM,POST_DATE
	-- which mean that they are duplicate records of the same transaction.

	This deletes all except for the transaction row with the lowest primary key HUB_TRANSACTION_SQN
*/
DELETE A
FROM Hub_Transaction A
	JOIN Hub_Transaction B
		ON A.PARENT_ACCT = B.PARENT_ACCT AND A.ID = B.ID
			AND A.SEQUENCE_NUM = B.SEQUENCE_NUM AND A.POST_DATE = B.POST_DATE
WHERE A.HUB_TRANSACTION_SQN > B.HUB_TRANSACTION_SQN