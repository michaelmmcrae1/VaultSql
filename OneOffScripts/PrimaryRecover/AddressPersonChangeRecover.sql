/*
	AddressPersonChangeRecover.sql

	Michael McRae
	August 13

	After deleting/reloading Hub_Address and Hub_Person, THIS script should bring back

	Link_Person_ProductInstance
	Link_Person_Transaction
	Link_Addr_Person
	Link_Acct_Person
	Sat_Person_Name

	to normal/full content... These should be the only tables that also need to be reloaded
	after Hub_Address and Hub_Person are reloaded
*/

truncate sym_vault1.Link_Person_ProductInstance;

truncate sym_vault1.Link_Person_Transaction;

truncate sym_vault1.Link_Addr_Person;

truncate sym_vault1.Link_Acct_Person;

truncate sym_vault1.Sat_Person_Name;


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


/*
	UpdateLinkPersonTransaction.sql

	Michael McRae
	July 29, 2014

	This update depends on Link_Person_ProductInstance having captured an
	accurate relationship between Person and ProductInstance

	Connects a Transaction to a ProductInstance then Connects, through Link_Person_
	ProductInstance, to a Person_SQN. This will work as long as the correct people are
	connected to each share, and each loan i.e. as long as Link_Person_ProductInstance is correct.

	NOTE - all people on an Account are connected to a Share on that Account, but not
		necessarily the case for Loans on that Account.
	Takes ~60 sec...
*/
INSERT INTO sym_vault1.Link_Person_Transaction(HUB_PERSON_SQN, HUB_TRANSACTION_SQN, LINK_PERSON_TRANSACTION_RSRC)
SELECT
	C.HUB_PERSON_SQN, A.HUB_TRANSACTION_SQN, 'EASE'
FROM sym_vault1.Hub_Transaction A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENT_ACCT = B.PARENT_ACCT AND A.ID = B.ID AND A.CATEGORY = B.CATEGORY
	JOIN sym_vault1.Link_Person_ProductInstance C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
	LEFT JOIN sym_vault1.Link_Person_Transaction D
		ON C.HUB_PERSON_SQN = D.HUB_PERSON_SQN AND A.HUB_TRANSACTION_SQN = D.HUB_TRANSACTION_SQN
WHERE D.HUB_PERSON_SQN IS NULL AND D.HUB_TRANSACTION_SQN IS NULL;


/*
	UpdateLinkAddrPerson_WORKING.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Person, NAME, and Hub_Address to find address associated with an SSN.
	Currently taking 100+ seconds... Not sure why
*/
INSERT INTO sym_vault1.Link_Addr_Person(HUB_ADDR_SQN, HUB_PERSON_SQN, LINK_ADDR_PERSON_RSRC)
SELECT DISTINCTROW C.HUB_ADDR_SQN, A.HUB_PERSON_SQN, 'EASE' AS LINK_ADDR_PERSON_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Address C
		ON B.STREET = C.STREET AND B.CITY = C.CITY AND B.STATE = C.STATE AND B.ZIPCODE = C.ZIPCODE
	LEFT JOIN sym_vault1.Link_Addr_Person D
		ON C.HUB_ADDR_SQN = D.HUB_ADDR_SQN AND A.HUB_PERSON_SQN = D.HUB_PERSON_SQN
	JOIN sym_vault1.Hub_Account E
		ON B.PARENTACCOUNT = E.ACCT_NUM
WHERE D.HUB_ADDR_SQN IS NULL AND D.HUB_PERSON_SQN IS NULL AND B.ORDINAL = 0;


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
	UpdateSatPersonName.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Person, NAME on SSN to find names of SSN's. Inserts TITLE,FIRST,MIDDLE,LAST
	asssociated with SSN, and connected HUB_PERSON_SQN, into Sat_Person_Name
	
	Only adds Names of Hub_Sqn when Hub_Sqn is not already in... not really tracking
	changes in a Hub_Sqn's name
*/
INSERT INTO sym_vault1.Sat_Person_Name(HUB_PERSON_SQN, TITLE, FIRST, MIDDLE, LAST, SUFFIX)
SELECT DISTINCTROW A.HUB_PERSON_SQN, B.TITLE, B.FIRST, B.MIDDLE, B.LAST, B.SUFFIX
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	LEFT JOIN sym_vault1.Sat_Person_Name C
		ON A.HUB_PERSON_SQN = C.HUB_PERSON_SQN
	JOIN sym_vault1.Hub_Account D
		ON B.PARENTACCOUNT = D.ACCT_NUM
WHERE C.HUB_PERSON_SQN IS NULL AND B.ORDINAL = 0;