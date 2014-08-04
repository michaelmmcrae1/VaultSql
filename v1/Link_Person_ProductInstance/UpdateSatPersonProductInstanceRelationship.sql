/*
	UpdateSatPersonTypeProductInstance.sql

	Michael McRae
	July 25, 2014

	Connects a person in NAME to that Account's ProductInstances, and gets the TYPE in NAME... this signifies
	the "relationship" the person has with a ProductInstance (at least for Shares?)
*/
-- INSERT INTO Sat_Person_ProductInstance_Relationship(LINK_PERSON_PRODUCTINSTANCE_SQN, TYPE)
SELECT
	C.LINK_PERSON_PRODUCTINSTANCE_SQN, A.TYPE
FROM SYM.NAME A
	JOIN Hub_Person B
		ON A.SSN = B.SSN
	JOIN Link_Person_ProductInstance C
		ON B.HUB_PERSON_SQN = C.HUB_PERSON_SQN
	JOIN Hub_Product_Instance D
		ON C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
		AND A.PARENTACCOUNT = D.PARENT_ACCT
	LEFT JOIN Sat_Person_ProductInstance_Relationship E
		ON C.LINK_PERSON_PRODUCTINSTANCE_SQN = E.LINK_PERSON_PRODUCTINSTANCE_SQN
		AND A.TYPE = E.TYPE
WHERE E.LINK_PERSON_PRODUCTINSTANCE_SQN IS NULL AND E.TYPE IS NULL;
	