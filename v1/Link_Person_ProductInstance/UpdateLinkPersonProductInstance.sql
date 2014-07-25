/*
	UpdateLinkPersonProductInstance.sql

	Michael McRae
	July 23, 2014

	Connects a Person from SYM.NAME to a ProductInstance
	Every person on an account in SYM.NAME {not mail rows}, will be somehow connected to a share. But this is not the case
	for Loans. Only the primary, and whoever is listed in SYM.LOANNAME are on a Loan together.
*/
/*
	Connects rows in SYM.NAME on an account with any Shares on that account, as long as the SYM.NAME row
	is not a mailing address {2 or 3}
*/
-- INSERT INTO sym_vault1.Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT
	DISTINCTROW C.HUB_PERSON_SQN, B.HUB_PRODUCT_INSTANCE_SQN, 'EASE'
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT
	JOIN sym_vault1.Hub_Person C
		ON A.SSN = C.SSN
	LEFT JOIN sym_vault1.Link_Person_ProductInstance D
		ON C.HUB_PERSON_SQN = D.PERSON_SQN AND B.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE A.TYPE <> 2 AND A.TYPE <> 3 AND B.CATEGORY = 'S'
		AND D.PERSON_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;
/*
	Connects persons to a Loan on an account... Primary is automatically and
	only those in LOANNAME are also connected to a Loan on an account
*/
-- INSERT INTO Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT
	C.HUB_PERSON_SQN, B.HUB_PRODUCT_INSTANCE_SQN, 'EASE'
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT
	JOIN sym_vault1.Hub_Person C
		ON A.SSN = C.SSN
	LEFT JOIN sym_vault1.Link_Person_ProductInstance D
		ON C.HUB_PERSON_SQN = D.PERSON_SQN AND B.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE A.ORDINAL = 0 AND B.CATEGORY = 'L' AND D.PERSON_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;
-- also adds those in SYM.LOANNAME, which contains Persons on a Loan, not including primary of Account
-- INSERT INTO Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT
	C.HUB_PERSON_SQN, B.HUB_PRODUCT_INSTANCE_SQN, 'EASE'
FROM SYM.LOANNAME A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT
	JOIN sym_vault1.Hub_Person C
		ON A.SSN = C.SSN
	LEFT JOIN sym_vault1.Link_Person_ProductInstance D
		ON C.HUB_PERSON_SQN = D.PERSON_SQN AND B.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE B.CATEGORY = 'S' AND D.PERSON_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;

