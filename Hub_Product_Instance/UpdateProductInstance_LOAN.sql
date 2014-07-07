/*
	UpdateProductInstance_LOAN.sql

	Michael McRae
	July 7, 2014

	Adds entries from SYM.LOAN to Hub_Product_Instance which are not already there. Specifies 'L' for Loan
	Because these Product Instances will only be from SYM.LOAN. Needs PRODUCT_TYPE
	of 'LOAN' because product instances from SYM.LOAN may have the same Parentaccount,ID
*/
INSERT INTO sym_vault1.Hub_Product_Instance(PARENT_ACCT, PRODUCT_ID, PRODUCT_CATEGORY, HUB_PRODUCT_INSTANCE_RSRC)
SELECT B.PARENTACCOUNT, B.ID, 'L' AS PRODUCT_CATEGORY, 'EASE' AS HUB_PRODUCT_INSTANCE_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.LOAN B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.PRODUCT_ID AND PRODUCT_CATEGORY = 'L'
WHERE C.PARENT_ACCT IS NULL AND C.PRODUCT_ID IS NULL AND PRODUCT_CATEGORY IS NULL
		AND B.CLOSEDATE = '0000-00-00';
