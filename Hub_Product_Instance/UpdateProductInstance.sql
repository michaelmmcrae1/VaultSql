/*
	UpdateProductInstance.sql

	Michael McRae
	July 7, 2014

	Adds entries from SYM.SAVINGS to Hub_Product_Instance which are not already there. Specifies 'SHARE'
	Because these Product Instances will only be from SYM.SAVINGS -- which is a share. Needs PRODUCT_TYPE
	for 'SHARE' because product instances from SYM.LOAN may have the same Parentaccount,ID
*/
INSERT INTO sym_vault1.Hub_Product_Instance(PARENT_ACCT, PRODUCT_ID, PRODUCT_TYPE, HUB_PRODUCT_INSTANCE_RSRC)
SELECT PARENTACCOUNT, ID, 'SHARE' AS PRODUCT_TYPE, 'EASE' AS HUB_PRODUCT_INSTANCE_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.SAVINGS B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.PRODUCT_ID AND PRODUCT_TYPE = 'SHARE'
WHERE C.PARENT_ACCT IS NULL AND C.PRODUCT_ID IS NULL AND PRODUCT_TYPE IS NULL;
