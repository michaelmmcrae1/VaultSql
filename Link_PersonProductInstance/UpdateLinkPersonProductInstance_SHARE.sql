/*
	UpdateLinkPersonProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from SYM.NAME. Connects Share Product instances with a Person.
	It connects the primary account holder's SSN to the share, and any SSN that is not from a type = 3 or 2
	to a Share on that ParentAccount.

	Currently, this is connecting beneficiaries, any/all types of connection to a share. Maybe it should only be
	connecting certain kinds of connected people? (i.e. joint, spouse, etc.)
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND C.CATEGORY = 'S'
	LEFT JOIN Link_Person_ProductInstance D
		ON A.HUB_PERSON_SQN = D.HUB_PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.PERSON_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL AND B.TYPE <> 2 AND B.TYPE <> 3;