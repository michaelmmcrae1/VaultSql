/*
	UpdateLinkPersonProductInstance_PRIMARY.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from Primary Account holders. Connects Loan Product instances with a Person.
	This script connects all persons on account in SYM.NAME to a product Instance on that Account.

	Matches ProductInstance to Account by PARENT_ACCT = PARENTACCOUNT, NOT only with ORDINAL=0 [primary account holder in SYM.NAME]
	Connects the SSN of that PARENTACCOUNT to the ProductInstance

	Takes ~20 seconds ...
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(HUB_PERSON_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT B.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PERSON_PRODUCTINSTANCE_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Person B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON A.PARENTACCOUNT = C.PARENT_ACCT
	JOIN sym_vault1.Hub_Account D
		ON A.PARENTACCOUNT = D.ACCT_NUM
	LEFT JOIN sym_vault1.Link_Person_ProductInstance F
		ON B.HUB_PERSON_SQN = F.HUB_PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = F.HUB_PRODUCT_INSTANCE_SQN
WHERE F.PERSON_SQN IS NULL AND F.PRODUCTINSTANCE_SQN IS NULL AND A.TYPE <> 2 AND A.TYPE <> 3;