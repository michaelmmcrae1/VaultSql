/*
	AfterTransactionCommentUpdate.sql
*/


/*
	=============================================================================
	=============================================================================
	=============================================================================
	=============================================================================
	These three Link_ Transaction Updates should only run after the Java program which handles Transactions +
	Comments has already run
*/
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


/*
	Update_LinkBranchTransaction.sql
	
	Michael McRae
	July 21, 2014

	Connects a Branch to a Transaction by connecting Branch_SQN to Transaction_SQN from
	Hub_Branch and Hub_Transaction. This can help identify foot-traffic, and ATM usage. 
	
	Transactions with BRANCH = 0 can be a variety of things, but with TELLER_NUM = 898 it is either ATM usage
	or Card usage or ?something else?
*/
INSERT INTO sym_vault1.Link_Branch_Transaction(HUB_BRANCH_SQN, HUB_TRANSACTION_SQN, LINK_BRANCH_TRANSACTION_RSRC)
SELECT A.HUB_BRANCH_SQN, B.HUB_TRANSACTION_SQN, 'EASE' AS LINK_BRANCH_TRANSACTION_RSRC
FROM sym_vault1.Hub_Branch A
	JOIN sym_vault1.Hub_Transaction B
		ON A.BRANCH_NUM = B.BRANCH
	LEFT JOIN sym_vault1.Link_Branch_Transaction C
		ON A.HUB_BRANCH_SQN = C.HUB_BRANCH_SQN AND B.HUB_TRANSACTION_SQN = C.HUB_TRANSACTION_SQN
WHERE C.HUB_BRANCH_SQN IS NULL AND C.HUB_TRANSACTION_SQN IS NULL;


/*
	UpdateLinkPersonTransaction.sql

	Michael McRae
	July 29, 2014

	This update depends on Link_Person_ProductInstance having captured an
	accurate relationship between Person and ProductInstance

	Connects a Transaction to a ProductInstance then Connects, through Link_Person_
	ProductInstance, to a Person_SQN. This will work as long as the correct people are
	connected to each share, and each loan i.e. as long as Link_Person_ProductInstance is correct.

	NOTE - all people on an Account are connected to a Share on that Account, but not
		necessarily the case for Loans on that Account.
	Takes ~60 sec...
*/
INSERT INTO sym_vault1.Link_Person_Transaction(HUB_PERSON_SQN, HUB_TRANSACTION_SQN, LINK_PERSON_TRANSACTION_RSRC)
SELECT
	C.HUB_PERSON_SQN, A.HUB_TRANSACTION_SQN, 'EASE'
FROM sym_vault1.Hub_Transaction A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENT_ACCT = B.PARENT_ACCT AND A.ID = B.ID AND A.CATEGORY = B.CATEGORY
	JOIN sym_vault1.Link_Person_ProductInstance C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
	LEFT JOIN sym_vault1.Link_Person_Transaction D
		ON C.HUB_PERSON_SQN = D.HUB_PERSON_SQN AND A.HUB_TRANSACTION_SQN = D.HUB_TRANSACTION_SQN
WHERE D.HUB_PERSON_SQN IS NULL AND D.HUB_TRANSACTION_SQN IS NULL;