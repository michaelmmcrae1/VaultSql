/*
	UpdateLinkAddrProductInstance.sql

	Michael McRae
	July 9, 2014

	Joins Hub_Product_Instance with SYM.NAME on Parent Account. Joins with Hub_Address to only get addresses which
	are not blank and to connect HUB_ADDR_SQN to HUB_PRODUCTINSTANCE_SQN. Only look at a record in SYM.NAME with ORDINAL=0,
	so we are only looking at addresses of primary account holder.
*/
INSERT INTO sym_vault1.Link_Addr_ProductInstance(HUB_ADDR_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_ADDR_PRODUCTINSTANCE_RSRC)
SELECT DISTINCT C.HUB_ADDR_SQN, A.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_ADDR_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product_Instance A
	JOIN SYM.NAME B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND B.ORDINAL = 0
	JOIN sym_vault1.Hub_Address C
		ON B.STREET = C.STREET AND B.CITY = C.CITY AND B.STATE = C.STATE AND B.ZIPCODE = C.ZIPCODE
	LEFT JOIN sym_vault1.Link_Addr_ProductInstance D
		ON C.HUB_ADDR_SQN = D.HUB_ADDR_SQN AND A.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_ADDR_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL;