START TRANSACTION;

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
INSERT INTO Sat_Account_Closed(HUB_ACCT_SQN, BRANCH)
SELECT B.HUB_ACCT_SQN, A.BRANCH
FROM SYM.ACCOUNT A
	JOIN sym_vault1.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	LEFT JOIN sym_vault1.Sat_Account_Closed C
		ON B.HUB_ACCT_SQN = C.HUB_ACCT_SQN
WHERE C.HUB_ACCT_SQN IS NULL;
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
INSERT INTO sym_vault1.Sat_Account_Closed(HUB_ACCT_SQN, BRANCH, START_DATE)
SELECT D.HUB_ACCT_SQN, C.BRANCH, D.START_DATE
FROM sym_vault1.Hub_Account B
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
	JOIN sym_vault1.Sat_Account_Closed D
		ON B.HUB_ACCT_SQN = D.HUB_ACCT_SQN
WHERE D.BRANCH <> C.BRANCH AND D.END_DATE IS NULL;
/*
	To update the END_DATE of Sat_Account_Closed's previous ACCT - BRANCH relationship
*/
UPDATE sym_vault1.Sat_Account_Closed A
	JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET A.END_DATE = NOW()
WHERE C.BRANCH <> A.BRANCH AND A.END_DATE IS NULL;
/*
	To update the closedate of those Accounts which are closed.
*/
UPDATE sym_vault1.Sat_Account_Closed A
	INNER JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
	INNER JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET END_DATE = C.CLOSEDATE
WHERE C.CLOSEDATE <> '0000-00-00' AND A.END_DATE IS NULL;

/*
	UpdateSatAcctType.sql

	Michael McRae
	July 28, 2014

	Keeps a record of an Account#'s changing Type.
	Inserts new Hub_Acct_sqn and Type when Hub_Acct_Sqn is not already in
	Sat_Account_Type.
	As Type changes in SYM.ACCOUNT, update Sat_Account_Type to track these changes

	Sat_Account_Type row where END_DATE IS NULL is current Type of an Account
*/
INSERT INTO sym_vault1.Sat_Account_Type(HUB_ACCT_SQN, TYPE)
SELECT
	B.HUB_ACCT_SQN, A.TYPE
FROM SYM.ACCOUNT A
	JOIN sym_vault1.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	LEFT JOIN sym_vault1.Sat_Account_Type D
		ON B.HUB_ACCT_SQN = D.HUB_ACCT_SQN
WHERE D.HUB_ACCT_SQN IS NULL;

INSERT INTO sym_vault1.Sat_Account_Type(HUB_ACCT_SQN, TYPE)
SELECT
	B.HUB_ACCT_SQN, A.TYPE
FROM SYM.ACCOUNT A
	JOIN sym_vault1.Hub_Account B
		ON A.ACCOUNTNUMBER = B.ACCT_NUM
	JOIN sym_vault1.Sat_Account_Closed C
		ON B.HUB_ACCT_SQN = C.HUB_ACCT_SQN
	JOIN sym_vault1.Sat_Account_Type D
		ON B.HUB_ACCT_SQN = D.HUB_ACCT_SQN
WHERE A.TYPE <> D.TYPE AND D.END_DATE IS NULL AND C.END_DATE IS NULL;
-- 
UPDATE sym_vault1.Sat_Account_Type A
	JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET A.END_DATE = NOW()
WHERE A.TYPE <> C.TYPE AND A.END_DATE IS NULL;


/*
	UpdateHubAddress.sql

	Michael McRae
	June 20, 2014

	Joins Hub_Account, SYM.NAME to find unique (DISTINCTROW) addresses of accounts that are still open.
	Left Joins with Hub_Address to find Addresses not already in Hub_Address, and inserts them.

	NOTE - Does not select an address if it is all blank i.e. at least one of STREET,CITY,STATE,ZIPCODE must
		contain some characters
*/
INSERT INTO sym_vault1.Hub_Address(STREET, CITY, STATE, ZIPCODE, HUB_ADDR_RSRC)
SELECT DISTINCTROW A.STREET, A.CITY, A.STATE, A.ZIPCODE, 'EASE' AS HUB_ADDR_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Address C
		ON A.STREET = C.STREET AND A.CITY = C.CITY AND A.STATE = C.STATE AND A.ZIPCODE = C.ZIPCODE
WHERE C.STREET IS NULL AND C.CITY IS NULL AND C.STATE IS NULL AND C.ZIPCODE IS NULL AND A.ORDINAL = 0
		AND (A.STREET <> '' OR A.CITY <> '' OR A.STATE <> '' OR A.ZIPCODE <> '');
	

/*
	UpdateHubPerson.sql

	Michael McRae
	July 23, 2014

	Takes every SSN from SYM.NAME as long as it's not a Mailing row {TYPE <> 2 AND TYPE <> 3}
	and inserts them into Hub_Person.

	Only takes Persons from Accounts which are still open {END_DATE IS NULL in Sat_Account_Closed}
*/
INSERT INTO sym_vault1.Hub_Person(SSN, HUB_PERSON_RSRC)
SELECT
	DISTINCT A.SSN, 'EASE'
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Person D
		ON A.SSN = D.SSN
WHERE A.SSN <> '' AND A.SSN <> '000000000' AND A.SSN <> '111111111' AND A.SSN <> '222222222' AND A.ORDINAL = 0
		AND D.SSN IS NULL;
/*
	UpdateSatPersonName.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Person, NAME on SSN to find names of SSN's. Inserts TITLE,FIRST,MIDDLE,LAST
	asssociated with SSN, and connected HUB_PERSON_SQN, into Sat_Person_Name
	
	Only adds Names of Hub_Sqn when Hub_Sqn is not already in... not really tracking
	changes in a Hub_Sqn's name -- because there are conflicting FIRST,MIDDLE,LAST per
	SSN within SYM.NAME i.e. SSN 1234 can be primary on two accounts, and in one account
	it's JIM,M,SMITH and in another it's JIM,MICHAEL,SMITH or any other variation which
	makes it appear that one SSN has two different names.
*/
INSERT INTO sym_vault1.Sat_Person_Name(HUB_PERSON_SQN, TITLE, FIRST, MIDDLE, LAST, SUFFIX)
SELECT DISTINCTROW A.HUB_PERSON_SQN, B.TITLE, B.FIRST, B.MIDDLE, B.LAST, B.SUFFIX
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Account C
		ON B.PARENTACCOUNT = C.ACCT_NUM
	LEFT JOIN sym_vault1.Sat_Person_Name D
		ON A.HUB_PERSON_SQN = D.HUB_PERSON_SQN
WHERE D.HUB_PERSON_SQN IS NULL AND B.ORDINAL = 0;


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
INSERT INTO sym_vault1.Sat_Teller_Description(HUB_TELLER_SQN, DESCRIPTION)
SELECT A.HUB_TELLER_SQN, B.NAME
FROM sym_vault1.Hub_Teller A
	JOIN SYM.USERS B
		ON A.TELLER_NUM = B.USERNUMBER
LEFT JOIN sym_vault1.Sat_Teller_Description C
		ON A.HUB_TELLER_SQN = C.HUB_TELLER_SQN
WHERE C.HUB_TELLER_SQN IS NULL;
/*
	Updates change of Description associated with already-added Teller_SQN in Sat_Teller_Description
*/
INSERT INTO sym_vault1.Sat_Teller_Description(HUB_TELLER_SQN, DESCRIPTION)
SELECT C.HUB_TELLER_SQN, B.NAME
FROM sym_vault1.Hub_Teller A
	JOIN SYM.USERS B
		ON A.TELLER_NUM = B.NUMBER
	JOIN sym_vault1.Sat_Teller_Description C
		ON A.HUB_TELLER_SQN = C.HUB_TELLER_SQN
WHERE C.DESCRIPTION <> B.NAME AND C.END_DATE IS NULL;
-- sets END_DATE = NOW() for Description that no longer applies
UPDATE sym_vault1.Sat_Teller_Description A
	JOIN sym_vault1.Hub_Teller B
		ON A.HUB_TELLER_SQN = B.HUB_TELLER_SQN
	JOIN SYM.USERS C
		ON B.TELLER_NUM = C.USERNUMBER
SET A.END_DATE = NOW()
WHERE A.DESCRIPTION <> C.NAME AND A.END_DATE IS NULL;


/*
	UpdateProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Adds entries from SYM.SAVINGS to Hub_Product_Instance which are not already there. Specifies 'S' for Share
	Because these Product Instances will only be from SYM.SAVINGS -- which is a share. Needs CATEGORY
	for 'SHARE' because product instances from SYM.LOAN may have the same Parentaccount,ID
*/
INSERT INTO sym_vault1.Hub_Product_Instance(PARENT_ACCT, ID, CATEGORY, OPEN_DATE, HUB_PRODUCT_INSTANCE_RSRC)
SELECT B.PARENTACCOUNT, B.ID, 'S' AS CATEGORY, B.OPENDATE, 'EASE' AS HUB_PRODUCT_INSTANCE_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.SAVINGS B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.ID AND C.CATEGORY = 'S'
WHERE C.PARENT_ACCT IS NULL AND C.ID IS NULL;
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
WHERE C.PARENT_ACCT IS NULL AND C.ID IS NULL;
/*
	UpdateSatProductInstanceType.sql
	
	Michael McRae
	July 11, 2014

	Adds rows into Sat_ProductInstance_Type when there's a new ProductInstance in Hub_Product_Instance.
	Adds new row when the Type changes of a PRODUCTINSTANCE_SQN.
	Sets END_DATE to NOW() of previous row when the Type changes of PRODUCTINSTANCE_SQN
*/
-- Finds New LOAN ProductInstances and adds HUB_SQN and Type to Sat_ProductInstance_Type
INSERT INTO sym_vault1.Sat_ProductInstance_Type(HUB_PRODUCT_INSTANCE_SQN, TYPE)
SELECT B.HUB_PRODUCT_INSTANCE_SQN, A.TYPE
FROM SYM.LOAN A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.ID = B.ID AND B.CATEGORY = 'L'
	LEFT JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
WHERE C.HUB_PRODUCT_INSTANCE_SQN IS NULL;
-- For SYM.SAVINGS
INSERT INTO sym_vault1.Sat_ProductInstance_Type(HUB_PRODUCT_INSTANCE_SQN, TYPE)
SELECT B.HUB_PRODUCT_INSTANCE_SQN, A.TYPE
FROM SYM.SAVINGS A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.ID = B.ID AND B.CATEGORY = 'S'
	LEFT JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
WHERE C.HUB_PRODUCT_INSTANCE_SQN IS NULL;
/*
	Add new row to Sat_ProductInstance_Type with updated TYPE when the TYPE in LOAN/SAVINGS is different from current
	TYPE in Sat_ProductInstance_Type for the associated Hub_Product_Instance_SQN
*/
INSERT INTO sym_vault1.Sat_ProductInstance_Type(HUB_PRODUCT_INSTANCE_SQN, TYPE)
SELECT B.HUB_PRODUCT_INSTANCE_SQN, A.TYPE
FROM SYM.LOAN A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.ID = B.ID AND B.CATEGORY = 'L'
	JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
WHERE A.TYPE <> C.TYPE AND C.END_DATE IS NULL;
-- For SYM.SAVINGS
INSERT INTO sym_vault1.Sat_ProductInstance_Type(HUB_PRODUCT_INSTANCE_SQN, TYPE)
SELECT B.HUB_PRODUCT_INSTANCE_SQN, A.TYPE
FROM SYM.SAVINGS A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.ID = B.ID AND B.CATEGORY = 'S'
	JOIN sym_vault1.Sat_ProductInstance_Type C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
WHERE A.TYPE <> C.TYPE AND C.END_DATE IS NULL;
/*
	Set END_DATE = NOW() on row in Sat_ProductInstance_Type where TYPE has since changed
*/
UPDATE sym_vault1.Sat_ProductInstance_Type A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.HUB_PRODUCT_INSTANCE_SQN = B.HUB_PRODUCT_INSTANCE_SQN
	JOIN SYM.LOAN C
		ON B.PARENT_ACCT = C.PARENTACCOUNT AND B.ID = C.ID AND B.CATEGORY = 'L'
SET A.END_DATE = NOW()
WHERE A.TYPE <> C.TYPE AND A.END_DATE IS NULL;
-- For SYM.SAVINGS
UPDATE sym_vault1.Sat_ProductInstance_Type A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.HUB_PRODUCT_INSTANCE_SQN = B.HUB_PRODUCT_INSTANCE_SQN
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
INSERT INTO sym_vault1.Sat_ProductInstance_Closed(HUB_PRODUCT_INSTANCE_SQN, CLOSE_DATE)
SELECT A.HUB_PRODUCT_INSTANCE_SQN, B.CLOSEDATE
FROM sym_vault1.Hub_Product_Instance A
	JOIN SYM.LOAN B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ID = B.ID AND A.CATEGORY = 'L' AND B.CLOSEDATE <> '0000-00-00'
	LEFT JOIN sym_vault1.Sat_ProductInstance_Closed C
		ON A.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
WHERE C.HUB_PRODUCT_INSTANCE_SQN IS NULL;
-- from SYM.SAVINGS
INSERT INTO sym_vault1.Sat_ProductInstance_Closed(HUB_PRODUCT_INSTANCE_SQN, CLOSE_DATE)
SELECT A.HUB_PRODUCT_INSTANCE_SQN, B.CLOSEDATE
FROM sym_vault1.Hub_Product_Instance A
	JOIN SYM.SAVINGS B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ID = B.ID AND A.CATEGORY = 'S' AND B.CLOSEDATE <> '0000-00-00'
	LEFT JOIN sym_vault1.Sat_ProductInstance_Closed C
		ON A.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
WHERE C.HUB_PRODUCT_INSTANCE_SQN IS NULL;


/*
	UpdateHubHomePhoneNum.sql

	Michael McRae
	July 21, 2014

	Selects DISTINCT home phone numbers from SYM.NAME and inserts them into Hub_Home_Phone if
	they are not already in the table. Only takes Phone Numbers for Primary {ORDINAL = 0}
*/
INSERT INTO Hub_Home_Phone(NUMBER, HUB_HOME_PHONE_RSRC)
SELECT DISTINCT A.HOMEPHONE, 'EASE' AS HUB_HOME_PHONE_RSRC
FROM SYM.NAME A
	LEFT JOIN Hub_Home_Phone B
		ON A.HOMEPHONE = B.NUMBER
WHERE B.NUMBER IS NULL AND A.HOMEPHONE <> '' AND A.ORDINAL = 0;


/*
	UpdateHubCard.sql

	Michael McRae
	July 21, 2014

	Takes primary key from SYM.CARD {Parentaccount, Ordinal} and inserts into Hub_Card. Left joins with
	Sat_ProductInstance_Closed so that it only selects those with Parentaccount NOT closed.
*/
INSERT INTO Hub_Card(PARENT_ACCT, ORDINAL, NUMBER, SAV_ID, CHK_ID, CREDIT_ID, HUB_CARD_RSRC)
SELECT DISTINCTROW A.PARENTACCOUNT, A.ORDINAL, A.NUMBER, A.SAVID, A.CHKID, A.CREDITCARDID, 'EASE' AS HUB_CARD_RSRC
FROM SYM.CARD A
	JOIN Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT
	LEFT JOIN Sat_ProductInstance_Closed C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
	LEFT JOIN Hub_Card D
		ON A.PARENTACCOUNT = D.PARENT_ACCT AND A.ORDINAL = D.ORDINAL
WHERE STATUS = 1 AND D.PARENT_ACCT IS NULL AND D.ORDINAL IS NULL
		AND C.HUB_PRODUCT_INSTANCE_SQN IS NULL;
/*
	UpdateSatCardStatus.sql

	Michael McRae
	July 21, 2014

	Updates Sat_Card_Status:
	1. Adds reference, status when a new Card appears into Hub_Card from SYM.CARD
	2. Inserts new row when the status of a Card changes {shown in SYM.NAME}
	3. Updates END_DATE = NOW() for previous Status of a card.
*/
INSERT INTO Sat_Card_Status(HUB_CARD_SQN, STATUS)
SELECT A.HUB_CARD_SQN, B.STATUS
FROM Hub_Card A
	JOIN SYM.CARD B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ORDINAL = B.ORDINAL
	LEFT JOIN Sat_Card_Status C
		ON A.HUB_CARD_SQN = C.HUB_CARD_SQN
WHERE C.HUB_CARD_SQN IS NULL;
-- insert HUB_CARD_SQN with changed Status
INSERT INTO Sat_Card_Status(HUB_CARD_SQN, STATUS)
SELECT A.HUB_CARD_SQN, B.STATUS
FROM Hub_Card A
	JOIN SYM.CARD B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ORDINAL = B.ORDINAL
	JOIN Sat_Card_Status C
		ON A.HUB_CARD_SQN = C.HUB_CARD_SQN
WHERE C.STATUS <> B.STATUS AND C.END_DATE IS NULL;
-- set END_DATE = NOW() for Status which no longer applies
UPDATE Sat_Card_Status A
	JOIN Hub_Card B
		ON A.HUB_CARD_SQN = B.HUB_CARD_SQN
	JOIN SYM.CARD C
		ON B.PARENT_ACCT = C.PARENTACCOUNT AND B.ORDINAL = C.ORDINAL
SET A.END_DATE = NOW()
WHERE A.STATUS <> C.STATUS AND A.END_DATE IS NULL;













/*
	Begin Link updates
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
WHERE A.END_DATE IS NULL AND (D.STREET <> E.STREET OR D.CITY <> E.CITY OR D.STATE <> E.STATE)
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




/*
	=============================================================================
	=============================================================================
	=============================================================================
	=============================================================================
	These three Link_ Transaction Updates should only run after the Java program which handles Transactions +
	Comments has already run
*/
/*
	UpdateLinkTransactionComment.sql

	Michael McRae
	July 25, 2014

	Combines a Transaction from Hub_Transaction and a Transaction Comment from Hub_Transaction_Comment
	Connects them on HUB_TRANSACTION_SQN.
	It is a 1 to Many relationship with one HUB_TRANSACTION_SQN having multiple Comments, but one each comment only connects
	to 1 Transaction.
*/
INSERT INTO Link_Transaction_Comment(HUB_TRANSACTION_SQN, HUB_TRANSACTION_COMMENT_SQN, LINK_TRANSACTION_COMMENT_RSRC)
SELECT
	A.HUB_TRANSACTION_SQN, B.HUB_TRANSACTION_COMMENT_SQN, 'EASE'
FROM Hub_Transaction A
	JOIN Hub_Transaction_Comment B
		ON A.HUB_TRANSACTION_SQN = B.HUB_TRANSACTION_SQN
	LEFT JOIN Link_Transaction_Comment C
		ON A.HUB_TRANSACTION_SQN = C.HUB_TRANSACTION_SQN AND B.HUB_TRANSACTION_COMMENT_SQN = C.HUB_TRANSACTION_COMMENT_SQN
WHERE C.HUB_TRANSACTION_SQN IS NULL AND C.HUB_TRANSACTION_COMMENT_SQN IS NULL;


/*
	Update_LinkBranchTransaction.sql
	
	Michael McRae
	July 21, 2014

	Connects a Branch to a Transaction by connecting Branch_SQN to Transaction_SQN from
	Hub_Branch and Hub_Transaction. This can help identify foot-traffic, and ATM usage. 
	
	Transactions with BRANCH = 0 can be a variety of things, but with TELLER_NUM = 898 it is either ATM usage
	or Card usage or ?something else?
*/
INSERT INTO sym_vault1.Link_Branch_Transaction(HUB_BRANCH_SQN, HUB_TRANSACTION_SQN, LINK_BRANCH_TRANSACTION_RSRC)
SELECT A.HUB_BRANCH_SQN, B.HUB_TRANSACTION_SQN, 'EASE' AS LINK_BRANCH_TRANSACTION_RSRC
FROM sym_vault1.Hub_Branch A
	JOIN sym_vault1.Hub_Transaction B
		ON A.BRANCH_NUM = B.BRANCH
	LEFT JOIN sym_vault1.Link_Branch_Transaction C
		ON A.HUB_BRANCH_SQN = C.HUB_BRANCH_SQN AND B.HUB_TRANSACTION_SQN = C.HUB_TRANSACTION_SQN
WHERE C.HUB_BRANCH_SQN IS NULL AND C.HUB_TRANSACTION_SQN IS NULL;


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


COMMIT;