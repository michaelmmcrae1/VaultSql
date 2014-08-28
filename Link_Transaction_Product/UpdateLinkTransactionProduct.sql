/*
	UpdateLinkTransactionProduct.sql

	Michael McRae
	August 20, 2014

	Implements a LEFT JOIN to avoid adding duplicates. But there are so many
	rows that the extra join may be time-expensive... Maybe there should be 
	some other way to make sure this only runs once.
*/
-- for Savings
INSERT INTO sym_vault1.Link_Product_ProductInstance(HUB_PRODUCT_SQN, HUB_PRODUCT_SQN, LINK_PRODUCT_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_TRANSACTION_SQN, C.HUB_PRODUCT_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product A
	JOIN sym_vault1.Hub_ProductInstance B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ID = B.ID AND A.CATEGORY = 'S';
	