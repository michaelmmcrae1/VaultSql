/*
	UpdateLinkPersonProductInstance_PRIMARY.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from Primary Account holders. Connects Loan Product instances with a Person.
	This script only connects primary members to a product.

	Takes ~20 seconds ...
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT B.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PERSON_PRODUCTINSTANCE_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Person B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON A.PARENTACCOUNT = C.PARENT_ACCT
	JOIN SYM.ACCOUNT D
		ON A.PARENTACCOUNT = D.ACCOUNTNUMBER
	LEFT JOIN sym_vault1.Link_Person_ProductInstance F
		ON B.HUB_PERSON_SQN = F.PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = F.PRODUCTINSTANCE_SQN
WHERE A.ORDINAL = 0 AND D.CLOSEDATE = '0000-00-00' AND F.PERSON_SQN IS NULL AND F.PRODUCTINSTANCE_SQN IS NULL;