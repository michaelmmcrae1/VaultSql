


/*
	UpdateLinkPersonProductInstance_LOAN.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from SYM.LOANNAME. Connects Loan Product instances with a Person.
	This script only connects non-primary members to the Loan, it does not also connect the primary account
	holder's SSN to the loan.
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.LOANNAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.PARENTID = C.ID AND C.CATEGORY = 'L'
	LEFT JOIN Link_Person_ProductInstance D
		ON A.HUB_PERSON_SQN = D.PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE D.PERSON_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;

