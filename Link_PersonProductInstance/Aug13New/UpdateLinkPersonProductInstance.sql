/*
	UpdateLinkPersonProductInstance.sql

	Michael McRae
	August 13, 2014

	Links Primary Account holders to all ProductInstances on that Account

	Does NOT bother with Trustees, beneficiaries; only connects Hub_Person SSNs to a ProductInstance
	and Hub_Person only contains SSN's from SYM.NAME WHERE ORDINAL = 0 {Primary Account Holder}

	Still need ORDINAL = 0 here in case someone is Primary on one account, but then is on another account
	as a Joint, Trustee or something. We just want that Account# where they are Primary to link to
	ParentAccount of ProductInstance
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(HUB_PERSON_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT DISTINCT A.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT
	LEFT JOIN Link_Person_ProductInstance D
		ON A.HUB_PERSON_SQN = D.HUB_PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_PERSON_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL AND B.ORDINAL = 0;