/*
	UpdateLinkProductProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Creates a link between an instance of a Product, and a Product. Useful to see what type of Product
	a Product Instance is, or to see how many of a given Product there are.
*/
INSERT INTO sym_vault1.Link_Product_ProductInstance(PRODUCT_SQN, PRODUCTINSTANCE_SQN, LINK_PRODUCT_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PRODUCT_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product A
	JOIN SYM.SAVINGS B
		ON A.TYPE = B.TYPE AND A.CATEGORY = 'S'
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.ID AND C.CATEGORY = 'S'
	LEFT JOIN Link_Product_ProductInstance D
		ON A.HUB_PRODUCT_SQN = D.PRODUCT_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE D.PRODUCT_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;
