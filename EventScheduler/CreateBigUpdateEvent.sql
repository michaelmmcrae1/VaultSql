delimiter $$

CREATE EVENT sym_vault1.EVENT01_UpdateSymVault1FromSYM
	ON SCHEDULE
		EVERY 1 DAY
		STARTS '2014-07-09 06:15:00'
		ON COMPLETION PRESERVE
DO
BEGIN
/*
	UpdateHubAccount.sql

	Michael McRae
	June 19, 2014

	Joins SYM.ACCOUNT and Hub_Account on Account Number. Finds those which are not already in
	Hub_Account, and inserts them. Only adds Account Numbers without a closedate (i.e. CLOSEDATE = '0000-00-00')
*/
INSERT INTO sym_vault1.Hub_Account(ACCT_NUM, OPEN_DATE, HUB_ACCT_RSRC)
SELECT ACCOUNTNUMBER, OPENDATE, 'EASE' AS HUB_ACCT_RSRC
FROM SYM.ACCOUNT A
	LEFT JOIN sym_vault1.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
WHERE B.ACCT_NUM IS NULL AND A.CLOSEDATE = '0000-00-00' AND A.ACCOUNTNUMBER >= '0000000260';


/*
	UpdateSatAcctClosed.sql

	Michael McRae
	June 20, 2014

	Finds HUB_ACCT_SQN, and associated Account Number, not already in Sat_Account_Closed. Then uses the Account Number to join with
	SYM.ACCOUNT to find the current BRANCH of these Accounts.
*/
INSERT INTO Sat_Account_Closed(ACCT_SQN, BRANCH)
SELECT B.HUB_ACCT_SQN, A.BRANCH
FROM SYM.ACCOUNT A
	JOIN sym_vault1.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	LEFT JOIN sym_vault1.Sat_Account_Closed C
		ON B.HUB_ACCT_SQN = C.ACCT_SQN
WHERE C.ACCT_SQN IS NULL;


/*
	UpdateSatBranchChange_WORKING.sql

	Michael McRae
	June 30, 2014

	First, inserts a new record into Sat_Account_Closed with the new branch connected with it.

	Second, set the END_DATE to NOW() for rows in Sat_Account_Closed where the current BRANCH
	does not match the BRANCH in SYM.ACCOUNT and the END_DATE is null.

	The most recent row for a certain HUB_ACCT_SQN is the one with an END_DATE of null. This is
	the row is the focus when this table is updated.
*/
INSERT INTO sym_vault1.Sat_Account_Closed(ACCT_SQN, BRANCH, START_DATE)
SELECT D.ACCT_SQN, C.BRANCH, D.START_DATE
FROM sym_vault1.Hub_Account B
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
	JOIN sym_vault1.Sat_Account_Closed D
		ON B.HUB_ACCT_SQN = D.ACCT_SQN
WHERE D.BRANCH <> C.BRANCH AND D.END_DATE IS NULL;

UPDATE sym_vault1.Sat_Account_Closed A
	JOIN sym_vault1.Hub_Account B
		ON A.ACCT_SQN = B.HUB_ACCT_SQN
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET A.END_DATE = NOW()
WHERE C.BRANCH <> A.BRANCH AND A.END_DATE IS NULL;

/*
	To update the closedate of those Accounts which are closed.
*/
UPDATE sym_vault1.Sat_Account_Closed A
	INNER JOIN sym_vault1.Hub_Account B
		ON A.ACCT_SQN = B.HUB_ACCT_SQN
	INNER JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET END_DATE = C.CLOSEDATE
WHERE C.CLOSEDATE <> '0000-00-00' AND A.END_DATE IS NULL;


/*
	UpdateHubAddress.sql

	Michael McRae
	June 20, 2014

	Joins Hub_Account, SYM.NAME to find unique (DISTINCTROW) addresses of accounts that are still open.
	Left Joins with Hub_Address to find Addresses not already in Hub_Address, and inserts them.

	NOTE - Does not select an address if it is all blank i.e. at least one of STREET,CITY,STATE,ZIPCODE must
		contain some characters
*/
INSERT INTO sym_vault1.Hub_Address(STREET, CITY, STATE, ZIPCODE, HUB_ADDRESS_RSRC)
SELECT DISTINCTROW A.STREET, A.CITY, A.STATE, A.ZIPCODE, 'EASE' AS HUB_ADDRESS_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Address C
		ON A.STREET = C.STREET AND A.CITY = C.CITY AND A.STATE = C.STATE AND A.ZIPCODE = C.ZIPCODE
WHERE C.STREET IS NULL AND C.CITY IS NULL AND C.STATE IS NULL AND C.ZIPCODE IS NULL AND A.ORDINAL = 0
		AND (A.STREET <> '' OR A.CITY <> '' OR A.STATE <> '' OR A.ZIPCODE <> '')
		AND !(A.STREET = '1900 52ND AVENUE' AND A.CITY = 'MOLINE') AND !(A.STREET = '1900 52ND AVE' AND A.CITY = 'MOLINE');
	

/*
	UpdateHubPerson.sql

	Michael McRae
	June 23, 2014

	GROUP BY SSN from previous UpdateHubPerson script was behaving unexpectedly.

	This finds unique humans by selecting distinct SSN's. This leaves out about 900 entries,
	with no SSN in the system, representing about 700 accounts, but is very accurate for 
	the remaining ~50,000 individuals.
*/
INSERT INTO sym_vault1.Hub_Person(SSN, HUB_PERSON_RSRC)
SELECT DISTINCT A.SSN, 'EASE' AS HUB_PERSON_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Person C
		ON A.SSN = C.SSN
WHERE C.SSN IS NULL AND A.SSN <> '' AND A.SSN <> '000000000';

/*
	UpdateSatPersonName.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Person, NAME on SSN to find names of SSN's. Inserts TITLE,FIRST,MIDDLE,LAST
	asssociated with SSN, and connected HUB_PERSON_SQN, into Sat_Person_Name
*/
INSERT INTO sym_vault1.Sat_Person_Name(PERSON_SQN, TITLE, FIRST, MIDDLE, LAST, SUFFIX)
SELECT DISTINCTROW A.HUB_PERSON_SQN, B.TITLE, B.FIRST, B.MIDDLE, B.LAST, B.SUFFIX
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	LEFT JOIN sym_vault1.Sat_Person_Name G
		ON A.HUB_PERSON_SQN = G.PERSON_SQN
WHERE G.PERSON_SQN IS NULL;


/*
	UpdateLinkAcctAddr_WORKING.sql

	Michael McRae
	June 23, 2014

	Joins SYM.NAME to Hub_Address on address info to connect address to ADDRESS_SQN. Joins with Hub_Account
	on Account # and Ordinal to connect ACCT_SQN.

	Hub_Address only contains addresses of accounts with ordinal = 0, but WHERE ORDINAL = 0
	is needed here as well, otherwise we get more than one address for an account, if there is an address
	associated with a joint on an account and also associated with a primary on a separate account.
*/
INSERT INTO sym_vault1.Link_Acct_Addr(ACCT_SQN, ADDR_SQN, LINK_ACCT_ADDR_RSRC)
SELECT DISTINCTROW C.HUB_ACCT_SQN, B.HUB_ADDRESS_SQN, 'EASE' AS Link_Acct_Addr_RSRC
FROM SYM.NAME A
	JOIN Hub_Address B
		ON A.STREET = B.STREET AND A.CITY = B.CITY AND A.STATE = B.STATE AND A.ZIPCODE = B.ZIPCODE
	JOIN Hub_Account C
		ON A.PARENTACCOUNT = C.ACCT_NUM
	LEFT JOIN Link_Acct_Addr D
		ON C.HUB_ACCT_SQN = D.ACCT_SQN AND B.HUB_ADDRESS_SQN = D.ADDR_SQN
WHERE D.ACCT_SQN IS NULL AND D.ADDR_SQN IS NULL AND A.ORDINAL = 0;


/*
	UpdateLinkAcctPerson_WORKING.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Account, NAME, Hub_Person with SSN and Account Number. Shows a relationship between
	an Account and an Individual. One individual may have multiple accounts, and one account may have
	multiple individuals.
*/
INSERT INTO Link_Acct_Person(ACCT_SQN, PERSON_SQN, LINK_ACCT_PERSON_RSRC)
SELECT DISTINCTROW A.HUB_ACCT_SQN, C.HUB_PERSON_SQN, 'EASE' AS LINK_ACCT_PERSON_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.NAME B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	JOIN sym_vault1.Hub_Person C
		ON B.SSN = C.SSN
	LEFT JOIN sym_vault1.Link_Acct_Person D
		ON A.HUB_ACCT_SQN = D.ACCT_SQN AND C.HUB_PERSON_SQN = D.PERSON_SQN
WHERE D.ACCT_SQN IS NULL AND D.PERSON_SQN IS NULL;


/*
	UpdateLinkAddrPerson_WORKING.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Person, NAME, and Hub_Address to find address associated with an SSN.
	Currently taking 100+ seconds... Not sure why
*/
INSERT INTO sym_vault1.Link_Addr_Person(ADDR_SQN, PERSON_SQN, LINK_ADDR_PERSON_RSRC)
SELECT DISTINCTROW C.HUB_ADDRESS_SQN, A.HUB_PERSON_SQN, 'EASE' AS LINK_ADDR_PERSON_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Address C
		ON B.STREET = C.STREET AND B.CITY = C.CITY AND B.STATE = C.STATE AND B.ZIPCODE = C.ZIPCODE
	LEFT JOIN sym_vault1.Link_Addr_Person D
		ON C.HUB_ADDRESS_SQN = D.ADDR_SQN AND A.HUB_PERSON_SQN = D.PERSON_SQN
WHERE D.ADDR_SQN IS NULL AND D.PERSON_SQN IS NULL;


/*
	UpdateProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Adds entries from SYM.SAVINGS to Hub_Product_Instance which are not already there. Specifies 'S' for Share
	Because these Product Instances will only be from SYM.SAVINGS -- which is a share. Needs PRODUCT_CATEGORY
	for 'SHARE' because product instances from SYM.LOAN may have the same Parentaccount,ID
*/
INSERT INTO sym_vault1.Hub_Product_Instance(PARENT_ACCT, ID, CATEGORY, HUB_PRODUCT_INSTANCE_RSRC)
SELECT B.PARENTACCOUNT, B.ID, 'S' AS CATEGORY, 'EASE' AS HUB_PRODUCT_INSTANCE_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.SAVINGS B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.ID AND CATEGORY = 'S'
WHERE C.PARENT_ACCT IS NULL AND C.ID IS NULL AND C.CATEGORY IS NULL;


/*
	UpdateProductInstance_LOAN.sql

	Michael McRae
	July 7, 2014

	Adds entries from SYM.LOAN to Hub_Product_Instance which are not already there. Specifies 'L' for Loan
	Because these Product Instances will only be from SYM.LOAN. Needs PRODUCT_TYPE
	of 'LOAN' because product instances from SYM.LOAN may have the same Parentaccount,ID
*/
INSERT INTO sym_vault1.Hub_Product_Instance(PARENT_ACCT, ID, CATEGORY, HUB_PRODUCT_INSTANCE_RSRC)
SELECT B.PARENTACCOUNT, B.ID, 'L' AS CATEGORY, 'EASE' AS HUB_PRODUCT_INSTANCE_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.LOAN B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.ID AND C.CATEGORY = 'L'
WHERE C.PARENT_ACCT IS NULL AND C.ID IS NULL AND C.CATEGORY IS NULL;


/*
	UpdateLinkAddrProductInstance.sql

	Michael McRae
	July 9, 2014

	Joins Hub_Product_Instance with SYM.NAME on Parent Account. Joins with Hub_Address to only get addresses which
	are not blank and to connect HUB_ADDR_SQN to HUB_PRODUCTINSTANCE_SQN. Only look at a record in SYM.NAME with ORDINAL=0,
	so we only look at addresses of primary account holder.
*/
INSERT INTO sym_vault1.Link_Addr_ProductInstance(ADDR_SQN, PRODUCTINSTANCE_SQN, LINK_ADDR_PRODUCTINSTANCE_RSRC)
SELECT C.HUB_ADDRESS_SQN, A.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_ADDR_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product_Instance A
	JOIN SYM.NAME B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND B.ORDINAL = 0
	JOIN sym_vault1.Hub_Address C
		ON B.STREET = C.STREET AND B.CITY = C.CITY AND B.STATE = C.STATE AND B.ZIPCODE = C.ZIPCODE
	LEFT JOIN sym_vault1.Link_Addr_ProductInstance D
		ON C.HUB_ADDRESS_SQN = D.ADDR_SQN AND A.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE D.ADDR_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;


/*
	UpdateLinkProductProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Creates a link between an instance of a Product, and a Product. Useful to see what type of Product
	a Product Instance is, or to see how many of a given Product there are.
*/
INSERT INTO sym_vault1.Link_Product_ProductInstance(PRODUCT_SQN, PRODUCTINSTANCE_SQN, LINK_PRODUCT_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PRODUCT_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product A
	JOIN SYM.SAVINGS B
		ON A.TYPE = B.TYPE AND A.CATEGORY = 'S'
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.ID AND C.CATEGORY = 'S'
	LEFT JOIN Link_Product_ProductInstance D
		ON A.HUB_PRODUCT_SQN = D.PRODUCT_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE D.PRODUCT_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;


/*
	UpdateLinkProductProductInstance_LOAN.sql

	Michael McRae
	July 7, 2014

	Creates a link between an instance of a Product, and a Product. Useful to see what type of Product
	a Product Instance is, or to see how many of a given Product there are.
*/
INSERT INTO sym_vault1.Link_Product_ProductInstance(PRODUCT_SQN, PRODUCTINSTANCE_SQN, LINK_PRODUCT_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PRODUCT_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product A
	JOIN SYM.LOAN B
		ON A.TYPE = B.TYPE AND A.CATEGORY = 'L'
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.ID AND C.CATEGORY = 'L'
	LEFT JOIN Link_Product_ProductInstance D
		ON A.HUB_PRODUCT_SQN = D.PRODUCT_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE D.PRODUCT_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;


/*
	UpdateLinkPersonProductInstance_PRIMARY.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from Primary Account holders. Connects Loan Product instances with a Person.
	This script only connects primary members to a product.

	Matches ProductInstance to Account by PARENT_ACCT = PARENTACCOUNT, only with ORDINAL=0 [primary account holder in SYM.NAME]
	Connects the SSN of that PARENTACCOUNT to the ProductInstance

	Takes ~20 seconds ...
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT B.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PERSON_PRODUCTINSTANCE_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Person B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON A.PARENTACCOUNT = C.PARENT_ACCT AND A.ORDINAL = 0
	JOIN sym_vault1.Hub_Account D
		ON A.PARENTACCOUNT = D.ACCT_NUM
	LEFT JOIN sym_vault1.Link_Person_ProductInstance F
		ON B.HUB_PERSON_SQN = F.PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = F.PRODUCTINSTANCE_SQN
WHERE F.PERSON_SQN IS NULL AND F.PRODUCTINSTANCE_SQN IS NULL;


/*
	UpdateHubTransaction_LOAN.sql

	Michael McRae
	July 8, 2014

	Assumes LoanTransaction only gets new transactions(deltas) [what if it is null... need something for that]. Loads
	The primary key of a unique LoanTransaction, and 'L' into Hub_Transaction. Left joins so it only adds those
	not already in Hub_Transaction.
*/
INSERT INTO sym_vault1.Hub_Transaction(PARENT_ACCT, ID, CATEGORY, SEQUENCE_NUM, POST_DATE, ACTIVITY_DATE, TELLER_NUM, CONSOLE_NUM, BRANCH, DESCRIPTION, ACTION_CODE, SOURCE_CODE,
				BALANCE_CHANGE, INTEREST, NEW_BALANCE, HUB_TRANSACTION_RSRC)
SELECT PARENTACCOUNT, PARENTID, 'L' AS CATEGORY, SEQUENCENUMBER, POSTDATE, ACTIVITYDATE, USERNUMBER, CONSOLENUMBER, A.BRANCH, A.DESCRIPTION, ACTIONCODE, SOURCECODE,
				BALANCECHANGE, A.INTEREST, NEWBALANCE, 'EASE' AS HUB_TRANSACTION_RSRC
FROM SYM.LOANTRANSACTION A
	JOIN sym_vault1.Hub_Account C
		ON A.PARENTACCOUNT = C.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Transaction B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.PARENTID = B.ID AND A.SEQUENCENUMBER = B.SEQUENCE_NUM AND B.CATEGORY = 'L'
WHERE B.PARENT_ACCT IS NULL AND B.ID IS NULL AND B.SEQUENCE_NUM IS NULL AND A.COMMENTCODE = 0;


/*
	UpdateHubTransaction_SHARE.sql

	Michael McRae
	July 8, 2014

	Assumes SaingsTransaction only gets new transactions(deltas) [what if it is null... need something for that]. Loads
	The primary key of a unique SAVINGSTRANSACTION, and 'S' into Hub_Transaction. Left joins so it only adds those
	not already in Hub_Transaction.
*/
INSERT INTO sym_vault1.Hub_Transaction(PARENT_ACCT, ID, CATEGORY, SEQUENCE_NUM, POST_DATE, ACTIVITY_DATE, TELLER_NUM, CONSOLE_NUM, BRANCH, DESCRIPTION, ACTION_CODE, SOURCE_CODE,
				BALANCE_CHANGE, INTEREST, NEW_BALANCE, HUB_TRANSACTION_RSRC)
SELECT PARENTACCOUNT, PARENTID, 'S' AS CATEGORY, SEQUENCENUMBER, POSTDATE, ACTIVITYDATE, USERNUMBER, CONSOLENUMBER, A.BRANCH, A.DESCRIPTION, ACTIONCODE, SOURCECODE,
				BALANCECHANGE, A.INTEREST, NEWBALANCE, 'EASE' AS HUB_TRANSACTION_RSRC
FROM SYM.SAVINGSTRANSACTION A
	JOIN sym_vault1.Hub_Account C
		ON A.PARENTACCOUNT = C.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Transaction B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.PARENTID = B.ID AND A.SEQUENCENUMBER = B.SEQUENCE_NUM AND B.CATEGORY = 'S'
WHERE B.PARENT_ACCT IS NULL AND B.ID IS NULL AND B.SEQUENCE_NUM IS NULL AND A.COMMENTCODE = 0;


/*
	UpdateHubTeller.sql

	Michael McRae
	July 9, 2014

	Finds USERNUMBER - which is our TELLER_NUM - from SYM.USERS and inserts those not already in Hub_Teller
*/
INSERT INTO sym_vault1.Hub_Teller(TELLER_NUM, HUB_TELLER_RSRC)
SELECT A.USERNUMBER, 'EASE' AS HUB_TELLER_RSRC
FROM SYM.USERS A
	LEFT JOIN sym_vault1.Hub_Teller B
		ON A.USERNUMBER = B.TELLER_NUM
WHERE B.TELLER_NUM IS NULL;

/*
	Inserts Teller_SQN and Description associated with Teller_SQN into Sat_Teller_Description, if that Teller_SQN
	is not already in the table
*/
INSERT INTO sym_vault1.Sat_Teller_Description(TELLER_SQN, DESCRIPTION)
SELECT A.HUB_TELLER_SQN, B.NAME
FROM sym_vault1.Hub_Teller A
	JOIN SYM.USERS B
		ON A.TELLER_NUM = B.USERNUMBER
LEFT JOIN sym_vault1.Sat_Teller_Description C
		ON A.HUB_TELLER_SQN = C.TELLER_SQN
WHERE C.TELLER_SQN IS NULL;

/*
	Updates change of Description associated with already-added Teller_SQN in Sat_Teller_Description
*/
INSERT INTO sym_vault1.Sat_Teller_Description(TELLER_SQN, DESCRIPTION)
SELECT C.TELLER_SQN, B.NAME
FROM sym_vault1.Hub_Teller A
	JOIN SYM.USERS B
		ON A.TELLER_NUM = B.NUMBER
	JOIN sym_vault1.Sat_Teller_Description C
		ON A.HUB_TELLER_SQN = C.TELLER_SQN
WHERE C.DESCRIPTION <> B.NAME AND C.END_DATE IS NULL;

UPDATE sym_vault1.Sat_Teller_Description A
	JOIN sym_vault1.Hub_Teller B
		ON A.TELLER_SQN = B.HUB_TELLER_SQN
	JOIN SYM.USERS C
		ON B.TELLER_NUM = C.USERNUMBER
SET A.END_DATE = NOW()
WHERE A.DESCRIPTION <> C.NAME AND A.END_DATE IS NULL;


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

/*
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

===================================================================
*/
/*
	UpdateBlobSYMTransaction.sql

	Michael McRae
	July 11, 2014

	Be sure to only run this once a day. It's baasically just a copy/slow build of all Transactions sent from SYM. Except...
	I include a CATEGORY field to specify a Loan transaction or a Share transaction. This Table will also contain all comments which is nice because
	currently I'm just ignoring those when I load Hub_Transaction
*/


INSERT INTO sym_vault1.Blob_SYM_Transaction(PARENTACCOUNT,
 PARENTID, CATEGORY,
 BALSEGCOUNT,
 COMMENTCODE,
 TRANSFERCODE,
 ADJUSTMENTCODE,
 REGECODE,
 REGDCHECKCODE,
 REGDTRANSFERCODE,
 VOIDCODE,
 SUBACTIONCODE,
 SEQUENCENUMBER,
 EFFECTIVEDATE,
 POSTDATE,
 POSTTIME,
 USERNUMBER,
 USEROVERRIDE,
 SECURITYLEVELS,
 DESCRIPTION,
 ACTIONCODE,
 SOURCECODE,
 BALANCECHANGE,
 INTEREST,
 NEWBALANCE,
 FEEAMOUNT,
 ESCROWAMOUNT,
 LASTTRANDATE,
 MATURITYLOANDUEDATE,
 COMMENT,
 BRANCH,
 CONSOLENUMBER,
 BATCHSEQUENCE,
 SALESTAXAMOUNT,
 ACTIVITYDATE,
 BILLEDFEEAMOUNT,
 PROCESSORUSER,
 MEMBERBRANCH,
 PREVAVAILBALANCE,
 SUBSOURCE,
 CONFIRMATIONSEQ,
 MICRACCTNUM,
 MICRRT,
 RECURRINGTRAN,
 FEEEXMTCRTSYAMT,
 ESCROWUNPAIDBALCHG,
 ESCROWAPPLIEDBALCHG,
 UNAPPLIEDPARTIALPMTCHG,
 FEECOUNTBY,
 LATECHGWAIVEDAMT,
 LATECHGUNPAIDCHGAMT,
 PREVLATECHGDATE,
 PREVLATECHGACCRUED,
 LATECHGFIELDSVALID,
 BALSEGID1,
 BALSEGPMTCHANGEDATE1,
 INTEFFECTDATE,
 BALSEGPREVFIRSTPMTDATE1)
SELECT PARENTACCOUNT,
 PARENTID, 'L' AS CATEGORY,
 BALSEGCOUNT,
 COMMENTCODE,
 TRANSFERCODE,
 ADJUSTMENTCODE,
 REGECODE,
 REGDCHECKCODE,
 REGDTRANSFERCODE,
 VOIDCODE,
 SUBACTIONCODE,
 SEQUENCENUMBER,
 EFFECTIVEDATE,
 POSTDATE,
 POSTTIME,
 USERNUMBER,
 USEROVERRIDE,
 SECURITYLEVELS,
 DESCRIPTION,
 ACTIONCODE,
 SOURCECODE,
 BALANCECHANGE,
 INTEREST,
 NEWBALANCE,
 FEEAMOUNT,
 ESCROWAMOUNT,
 LASTTRANDATE,
 MATURITYLOANDUEDATE,
 COMMENT,
 BRANCH,
 CONSOLENUMBER,
 BATCHSEQUENCE,
 SALESTAXAMOUNT,
 ACTIVITYDATE,
 BILLEDFEEAMOUNT,
 PROCESSORUSER,
 MEMBERBRANCH,
 PREVAVAILBALANCE,
 SUBSOURCE,
 CONFIRMATIONSEQ,
 MICRACCTNUM,
 MICRRT,
 RECURRINGTRAN,
 FEEEXMTCRTSYAMT,
 ESCROWUNPAIDBALCHG,
 ESCROWAPPLIEDBALCHG,
 UNAPPLIEDPARTIALPMTCHG,
 FEECOUNTBY,
 LATECHGWAIVEDAMT,
 LATECHGUNPAIDCHGAMT,
 PREVLATECHGDATE,
 PREVLATECHGACCRUED,
 LATECHGFIELDSVALID,
 BALSEGID1,
 BALSEGPMTCHANGEDATE1,
 INTEFFECTDATE,
 BALSEGPREVFIRSTPMTDATE1
FROM SYM.LOANTRANSACTION;
	


INSERT INTO sym_vault1.Blob_SYM_Transaction(PARENTACCOUNT,
 PARENTID, CATEGORY,
 BALSEGCOUNT,
 COMMENTCODE,
 TRANSFERCODE,
 ADJUSTMENTCODE,
 REGECODE,
 REGDCHECKCODE,
 REGDTRANSFERCODE,
 VOIDCODE,
 SUBACTIONCODE,
 SEQUENCENUMBER,
 EFFECTIVEDATE,
 POSTDATE,
 POSTTIME,
 USERNUMBER,
 USEROVERRIDE,
 SECURITYLEVELS,
 DESCRIPTION,
 ACTIONCODE,
 SOURCECODE,
 BALANCECHANGE,
 INTEREST,
 NEWBALANCE,
 FEEAMOUNT,
 ESCROWAMOUNT,
 LASTTRANDATE,
 MATURITYLOANDUEDATE,
 COMMENT,
 BRANCH,
 CONSOLENUMBER,
 BATCHSEQUENCE,
 SALESTAXAMOUNT,
 ACTIVITYDATE,
 BILLEDFEEAMOUNT,
 PROCESSORUSER,
 MEMBERBRANCH,
 PREVAVAILBALANCE,
 SUBSOURCE,
 CONFIRMATIONSEQ,
 MICRACCTNUM,
 MICRRT,
 RECURRINGTRAN,
 FEEEXMTCRTSYAMT,
 ESCROWUNPAIDBALCHG,
 ESCROWAPPLIEDBALCHG,
 UNAPPLIEDPARTIALPMTCHG,
 FEECOUNTBY,
 LATECHGWAIVEDAMT,
 LATECHGUNPAIDCHGAMT,
 PREVLATECHGDATE,
 PREVLATECHGACCRUED,
 LATECHGFIELDSVALID,
 BALSEGID1,
 BALSEGPMTCHANGEDATE1,
 INTEFFECTDATE,
 BALSEGPREVFIRSTPMTDATE1)
SELECT PARENTACCOUNT,
 PARENTID, 'S' AS CATEGORY,
 BALSEGCOUNT,
 COMMENTCODE,
 TRANSFERCODE,
 ADJUSTMENTCODE,
 REGECODE,
 REGDCHECKCODE,
 REGDTRANSFERCODE,
 VOIDCODE,
 SUBACTIONCODE,
 SEQUENCENUMBER,
 EFFECTIVEDATE,
 POSTDATE,
 POSTTIME,
 USERNUMBER,
 USEROVERRIDE,
 SECURITYLEVELS,
 DESCRIPTION,
 ACTIONCODE,
 SOURCECODE,
 BALANCECHANGE,
 INTEREST,
 NEWBALANCE,
 FEEAMOUNT,
 ESCROWAMOUNT,
 LASTTRANDATE,
 MATURITYLOANDUEDATE,
 COMMENT,
 BRANCH,
 CONSOLENUMBER,
 BATCHSEQUENCE,
 SALESTAXAMOUNT,
 ACTIVITYDATE,
 BILLEDFEEAMOUNT,
 PROCESSORUSER,
 MEMBERBRANCH,
 PREVAVAILBALANCE,
 SUBSOURCE,
 CONFIRMATIONSEQ,
 MICRACCTNUM,
 MICRRT,
 RECURRINGTRAN,
 FEEEXMTCRTSYAMT,
 ESCROWUNPAIDBALCHG,
 ESCROWAPPLIEDBALCHG,
 UNAPPLIEDPARTIALPMTCHG,
 FEECOUNTBY,
 LATECHGWAIVEDAMT,
 LATECHGUNPAIDCHGAMT,
 PREVLATECHGDATE,
 PREVLATECHGACCRUED,
 LATECHGFIELDSVALID,
 BALSEGID1,
 BALSEGPMTCHANGEDATE1,
 INTEFFECTDATE,
 BALSEGPREVFIRSTPMTDATE1
FROM SYM.SAVINGSTRANSACTION;

END $$

delimiter ;