/*
	UpdateSatProductInstanceType.sql
	
	Michael McRae
	July 11, 2014

	Adds rows into Sat_ProductInstance_Type when there's a new ProductInstance in Hub_Product_Instance.
	Adds new row when the Type changes of a PRODUCTINSTANCE_SQN.
	Sets END_DATE to NOW() of previous row when the Type changes of PRODUCTINSTANCE_SQN
*/
-- Finds New LOAN ProductInstances and adds HUB_SQN and Type to Sat_ProductInstance_Type
INSERT INTO sym_vault1.Sat_ProductInstance_Type(PRODUCTINSTANCE_SQN, TYPE)
SELECT B.HUB_PRODUCT_INSTANCE_SQN, A.TYPE
FROM SYM.LOAN A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.ID = B.ID AND B.CATEGORY = 'L'
	LEFT JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.PRODUCTINSTANCE_SQN
WHERE C.PRODUCTINSTANCE_SQN IS NULL;
-- For SYM.SAVINGS
INSERT INTO sym_vault1.Sat_ProductInstance_Type(PRODUCTINSTANCE_SQN, TYPE)
SELECT B.HUB_PRODUCT_INSTANCE_SQN, A.TYPE
FROM SYM.SAVINGS A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.ID = B.ID AND B.CATEGORY = 'S'
	LEFT JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.PRODUCTINSTANCE_SQN
WHERE C.PRODUCTINSTANCE_SQN IS NULL;


/*
	Add new row to Sat_ProductInstance_Type with updated TYPE when the TYPE in LOAN/SAVINGS is different from current
	TYPE in Sat_ProductInstance_Type for the associated Hub_Product_Instance_SQN
*/
INSERT INTO sym_vault1.Sat_ProductInstance_Type(PRODUCTINSTANCE_SQN, TYPE)
SELECT B.HUB_PRODUCT_INSTANCE_SQN, A.TYPE
FROM SYM.LOAN A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.ID = B.ID AND B.CATEGORY = 'L'
	JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.PRODUCTINSTANCE_SQN
WHERE A.TYPE <> C.TYPE AND C.END_DATE IS NULL;
-- For SYM.SAVINGS
INSERT INTO sym_vault1.Sat_ProductInstance_Type(PRODUCTINSTANCE_SQN, TYPE)
SELECT B.HUB_PRODUCT_INSTANCE_SQN, A.TYPE
FROM SYM.SAVINGS A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.ID = B.ID AND B.CATEGORY = 'S'
	JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.PRODUCTINSTANCE_SQN
WHERE A.TYPE <> C.TYPE AND C.END_DATE IS NULL;


/*
	Set END_DATE = NOW() on row in Sat_ProductInstance_Type where TYPE has since changed
*/
UPDATE sym_vault1.Sat_ProductInstance_Type A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PRODUCTINSTANCE_SQN = B.HUB_PRODUCT_INSTANCE_SQN
	JOIN SYM.LOAN C
		ON B.PARENT_ACCT = C.PARENTACCOUNT AND B.ID = C.ID AND B.CATEGORY = 'L'
SET A.END_DATE = NOW()
WHERE A.TYPE <> C.TYPE AND A.END_DATE IS NULL;
-- For SYM.SAVINGS
UPDATE sym_vault1.Sat_ProductInstance_Type A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PRODUCTINSTANCE_SQN = B.HUB_PRODUCT_INSTANCE_SQN
	JOIN SYM.SAVINGS C
		ON B.PARENT_ACCT = C.PARENTACCOUNT AND B.ID = C.ID AND B.CATEGORY = 'S'
SET A.END_DATE = NOW()
WHERE A.TYPE <> C.TYPE AND A.END_DATE IS NULL;
