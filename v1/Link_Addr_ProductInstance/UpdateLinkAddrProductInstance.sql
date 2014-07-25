/*
	UpdateLinkAddrProductInstance.sql

	Michael McRae
	July 23, 2014

	Takes addresses from SYM.NAME (only where Type = 0, 2, or 3 -- which are in eDocs for primary,
	mailing only, and alternate mailing respectively. This way we aren't getting all the random addresses
	of whoever happens to be on an account -- we are only looking at specific fields marked as relevant addresses.
	Hooray!
	
	~takes about 16 seconds
	-- is DISTINCT necessary for this?
*/
SELECT
	C.HUB_ADDRESS_SQN, B.HUB_PRODUCT_INSTANCE_SQN, 'EASE'
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT
	JOIN sym_vault1.Hub_Address C
		ON A.STREET = C.STREET AND A.CITY = C.CITY AND A.STATE = C.STATE AND A.ZIPCODE = C.ZIPCODE
	LEFT JOIN sym_vault1.Link_Addr_ProductInstance D
		ON C.HUB_ADDRESS_SQN = D.ADDR_SQN AND B.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE (A.TYPE = 0 OR A.TYPE = 2 OR A.TYPE = 3) AND D.ADDR_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL
		