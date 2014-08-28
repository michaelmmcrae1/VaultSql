/*
	Rework_UpdateProductProductInstance.sql
	
	Michael McRae
	August 20, 2014
	
	Creates a link between an instance of a Product, and a Product. Useful to see what type of Product
	a Product Instance is, or to see how many of a given Product there are. Utilizes Sat_ProductInstance_Type
	to connect a Product Instance to a Product.
	
	*NOTE*
	Doesn't use any SYM tables. Needs Hub_Product and Hub_ProductInstance to be updated first.
	At some point this could be like Link_Acct_Addr where it utilizes an Effectivity Satellite, because
	A ProductInstance can be of a certain Product at one point but change types (maybe?).
*/
INSERT INTO sym_vault1.Link_Product_ProductInstance(HUB_PRODUCT_SQN, HUB_PRODUCTINSTANCE_SQN, LINK_PRODUCT_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PRODUCT_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.CATEGORY = B.CATEGORY
	JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
	LEFT JOIN Link_Product_ProductInstance D
		ON A.HUB_PRODUCT_SQN = D.PRODUCT_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE D.PRODUCT_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL AND C.END_DATE IS NULL
		AND A.TYPE = C.TYPE;
