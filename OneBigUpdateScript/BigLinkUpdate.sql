/*
	BigLinkUpdate.sql

	August 20, 2014
	Link_Acct_Addr and Sat_LinkAcctAddr_Effectivity was repeatedly adding 1 row...
	An issue related to one Address being on more than one Account?


*/


/*
	UpdateLinkAcctPerson_WORKING.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Account, NAME, Hub_Person with SSN and Account Number. Shows a relationship between
	an Account and an Individual. One individual may have multiple accounts, and one account may have
	multiple individuals.
*/
INSERT INTO sym_vault1.Link_Acct_Person(HUB_ACCT_SQN, HUB_PERSON_SQN, LINK_ACCT_PERSON_RSRC)
SELECT DISTINCTROW A.HUB_ACCT_SQN, C.HUB_PERSON_SQN, 'EASE' AS LINK_ACCT_PERSON_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.NAME B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	JOIN sym_vault1.Hub_Person C
		ON B.SSN = C.SSN
	LEFT JOIN sym_vault1.Link_Acct_Person D
		ON A.HUB_ACCT_SQN = D.HUB_ACCT_SQN AND C.HUB_PERSON_SQN = D.HUB_PERSON_SQN
WHERE D.HUB_ACCT_SQN IS NULL AND D.HUB_PERSON_SQN IS NULL AND B.ORDINAL = 0;


/*
	Combined_UpdateLinkSatAcctAddr.sql

	Michael McRae
	August 19, 2014
	
	Rework of UpdateLinkAcctAddr_WORKING.sql
	This must run *after* Hub_Account and Hub_Address and Hub_Person have all been updated.

	A connection of HUB_ACCT_SQN and HUB_ADDR_SQN is inserted if one of the following is true:
		1. There is no reference to the Hub_Acct_SQN in the Link yet
		2. The current/effective Link for that HUB_ACCT_SQN is connected to a different HUB_ADDR_SQN
*/
INSERT INTO sym_vault1.Link_Acct_Addr(HUB_ACCT_SQN, HUB_ADDR_SQN, LINK_ACCT_ADDR_RSRC)
SELECT DISTINCTROW C.HUB_ACCT_SQN, B.HUB_ADDR_SQN, 'EASE' AS LINK_ACCT_ADDR_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Address B
		ON A.STREET = B.STREET AND A.CITY = B.CITY AND A.STATE = B.STATE AND A.ZIPCODE = B.ZIPCODE
	JOIN sym_vault1.Hub_Account C
		ON A.PARENTACCOUNT = C.ACCT_NUM
	LEFT JOIN sym_vault1.Link_Acct_Addr D
		ON C.HUB_ACCT_SQN = D.HUB_ACCT_SQN
	LEFT JOIN sym_vault1.Sat_LinkAcctAddr_Effectivity E
		ON D.LINK_ACCT_ADDR_SQN = E.LINK_ACCT_ADDR_SQN
WHERE (D.HUB_ACCT_SQN IS NULL OR (E.END_DATE IS NULL AND B.HUB_ADDR_SQN <> D.HUB_ADDR_SQN)) AND A.ORDINAL = 0;
/*
	UpdateSatLinkAcctAddr_Effectivity.sql

	Michael McRae
	August 19, 2014
	
	Hub_Acct_SQN is the driving key in this Link for detecting
	new Links.

	A row in Link is only added if an Account's Address is different
	from the current/effective Link between an Account and Address.

	Insert into Satellite the LinkAcctAddr_SQN for that Link for any
	Links not already in Satellite(thus getting the Link which was added
	due to being different from the Account's current Link).

	After any new Links are added to the Sat, set the END_DATE
	for current/effective Links which are no longer current i.e.
	their Hub_Addr_SQN refers to an Address in Hub_Address which
	is no longer the Address in SYM.NAME.
*/
/*
	If this is the first time we're seeing this Link, insert it into
	the Satellite.
*/
INSERT INTO sym_vault1.Sat_LinkAcctAddr_Effectivity(LINK_ACCT_ADDR_SQN)
SELECT A.LINK_ACCT_ADDR_SQN
FROM sym_vault1.Link_Acct_Addr A
	LEFT JOIN sym_vault1.Sat_LinkAcctAddr_Effectivity B
		ON A.LINK_ACCT_ADDR_SQN = B.LINK_ACCT_ADDR_SQN
WHERE B.LINK_ACCT_ADDR_SQN IS NULL;
/*
	Update the End Date in Sat for Links which are no longer current
*/
UPDATE sym_vault1.Sat_LinkAcctAddr_Effectivity A
	JOIN sym_vault1.Link_Acct_Addr B
		ON A.LINK_ACCT_ADDR_SQN = B.LINK_ACCT_ADDR_SQN
	JOIN sym_vault1.Hub_Account C
		ON B.HUB_ACCT_SQN = C.HUB_ACCT_SQN
	JOIN sym_vault1.Hub_Address D
		ON B.HUB_ADDR_SQN = D.HUB_ADDR_SQN
	JOIN SYM.NAME E
		ON C.ACCT_NUM = E.PARENTACCOUNT
SET END_DATE = NOW()
WHERE A.END_DATE IS NULL AND (D.STREET <> E.STREET OR D.CITY <> E.CITY OR D.STATE <> E.STATE OR D.ZIPCODE <> E.ZIPCODE)
		AND E.ORDINAL = 0;


/*
	Rework_UpdateProductProductInstance.sql
	
	Michael McRae
	August 20, 2014
	
	Creates a link between an instance of a Product, and a Product. Useful to see what type of Product
	a Product Instance is, or to see how many of a given Product there are. Utilizes Sat_ProductInstance_Type
	to connect a Product Instance to a Product.
	
	*NOTE*
	Doesn't use any SYM tables. Needs Hub_Product and Hub_ProductInstance + Satellites to be updated first.
	At some point this could be like Link_Acct_Addr where it utilizes an Effectivity Satellite, because
	A ProductInstance can be of a certain Product at one point but change types (maybe?).
*/
INSERT INTO sym_vault1.Link_Product_ProductInstance(HUB_PRODUCT_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PRODUCT_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PRODUCT_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.CATEGORY = B.CATEGORY
	JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
	LEFT JOIN Link_Product_ProductInstance D
		ON A.HUB_PRODUCT_SQN = D.HUB_PRODUCT_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_PRODUCT_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL AND C.END_DATE IS NULL
		AND A.TYPE = C.TYPE;


/*
	UpdateLinkPersonProductInstance.sql

	Michael McRae
	August 13, 2014

	Links Primary Account holders to all ProductInstances on that Account

	Does NOT bother with Trustees, beneficiaries; only connects Hub_Person SSNs to a ProductInstance
	and Hub_Person only contains SSN's from SYM.NAME WHERE ORDINAL = 0 {Primary Account Holder}

	Still need ORDINAL = 0 here in case someone is Primary on one account, but then is on another account
	as a Joint, Trustee or something. We just want that Account# where they are Primary to link to
	ParentAccount of ProductInstance
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(HUB_PERSON_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT DISTINCT A.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT
	LEFT JOIN Link_Person_ProductInstance D
		ON A.HUB_PERSON_SQN = D.HUB_PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_PERSON_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL AND B.ORDINAL = 0;