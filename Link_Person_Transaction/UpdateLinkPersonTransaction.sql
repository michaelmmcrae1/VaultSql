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