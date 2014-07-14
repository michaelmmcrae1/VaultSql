/*
	UpdateSatProductInstanceClosed.sql
	
	Michael McRae
	July 11, 2014

	Finds ProductInstance in SYM.LOAN which has CLOSEDATE <> '0000-00-00' i.e. has closed, and inserts the closedate
	and associated HUB_PRODUCT_INSTANCE_SQN into Sat_ProductInstance_Closed. ProductInstance cannot be opened after it
	is closed - so this is a one time thing. Either a ProductInstance_SQN is in the table -- and thus it is closed -- or
	it is not in the table and thus it remains open.
*/
-- from SYM.LOAN
INSERT INTO sym_vault1.Sat_ProductInstance_Closed(PRODUCTINSTANCE_SQN, CLOSE_DATE)
SELECT A.HUB_PRODUCT_INSTANCE_SQN, B.CLOSEDATE
FROM sym_vault1.Hub_Product_Instance A
	JOIN SYM.LOAN B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ID = B.ID AND A.CATEGORY = 'L' AND B.CLOSEDATE <> '0000-00-00'
	LEFT JOIN sym_vault1.Sat_ProductInstance_Closed C
		ON A.HUB_PRODUCT_INSTANCE_SQN = C.PRODUCTINSTANCE_SQN
WHERE C.PRODUCTINSTANCE_SQN IS NULL;
-- from SYM.SAVINGS
INSERT INTO sym_vault1.Sat_ProductInstance_Closed(PRODUCTINSTANCE_SQN, CLOSE_DATE)
SELECT A.HUB_PRODUCT_INSTANCE_SQN, B.CLOSEDATE
FROM sym_vault1.Hub_Product_Instance A
	JOIN SYM.SAVINGS B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ID = B.ID AND A.CATEGORY = 'S' AND B.CLOSEDATE <> '0000-00-00'
	LEFT JOIN sym_vault1.Sat_ProductInstance_Closed C
		ON A.HUB_PRODUCT_INSTANCE_SQN = C.PRODUCTINSTANCE_SQN
WHERE C.PRODUCTINSTANCE_SQN IS NULL;