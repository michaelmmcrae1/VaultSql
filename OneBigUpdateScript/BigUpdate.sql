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
		AND (A.STREET <> '' OR A.CITY <> '' OR A.STATE <> '' OR A.ZIPCODE <> '')
		AND !(A.STREET = '1900 52ND AVENUE' AND (A.CITY = 'MOLINE' OR A.CITY = 'ROCK ISLAND'));
	

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
WHERE A.SSN <> '' AND A.SSN <> '000000000' AND A.TYPE <> 2 AND A.TYPE <> 3
		AND D.SSN IS NULL;

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
	LEFT JOIN sym_vault1.Sat_Person_Name G
		ON A.HUB_PERSON_SQN = G.HUB_PERSON_SQN
WHERE G.HUB_PERSON_SQN IS NULL;


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
INSERT INTO sym_vault1.Link_Acct_Addr(HUB_ACCT_SQN, HUB_ADDR_SQN, LINK_ACCT_ADDR_RSRC)
SELECT DISTINCTROW C.HUB_ACCT_SQN, B.HUB_ADDR_SQN, 'EASE' AS Link_Acct_Addr_RSRC
FROM SYM.NAME A
	JOIN Hub_Address B
		ON A.STREET = B.STREET AND A.CITY = B.CITY AND A.STATE = B.STATE AND A.ZIPCODE = B.ZIPCODE
	JOIN Hub_Account C
		ON A.PARENTACCOUNT = C.ACCT_NUM
	LEFT JOIN Link_Acct_Addr D
		ON C.HUB_ACCT_SQN = D.HUB_ACCT_SQN AND B.HUB_ADDR_SQN = D.HUB_ADDR_SQN
WHERE D.HUB_ACCT_SQN IS NULL AND D.HUB_ADDR_SQN IS NULL AND A.ORDINAL = 0;


/*
	UpdateLinkAcctPerson_WORKING.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Account, NAME, Hub_Person with SSN and Account Number. Shows a relationship between
	an Account and an Individual. One individual may have multiple accounts, and one account may have
	multiple individuals.
*/
INSERT INTO Link_Acct_Person(HUB_ACCT_SQN, HUB_PERSON_SQN, LINK_ACCT_PERSON_RSRC)
SELECT DISTINCTROW A.HUB_ACCT_SQN, C.HUB_PERSON_SQN, 'EASE' AS LINK_ACCT_PERSON_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.NAME B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	JOIN sym_vault1.Hub_Person C
		ON B.SSN = C.SSN
	LEFT JOIN sym_vault1.Link_Acct_Person D
		ON A.HUB_ACCT_SQN = D.HUB_ACCT_SQN AND C.HUB_PERSON_SQN = D.HUB_PERSON_SQN
WHERE D.HUB_ACCT_SQN IS NULL AND D.HUB_PERSON_SQN IS NULL
		AND (B.ORDINAL = 0 OR B.TYPE <> 2 AND B.TYPE <> 3);


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
WHERE D.HUB_ADDR_SQN IS NULL AND D.HUB_PERSON_SQN IS NULL;


/*
	UpdateProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Adds entries from SYM.SAVINGS to Hub_Product_Instance which are not already there. Specifies 'S' for Share
	Because these Product Instances will only be from SYM.SAVINGS -- which is a share. Needs CATEGORY
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
	so we are only looking at addresses of primary account holder.
*/
INSERT INTO sym_vault1.Link_Addr_ProductInstance(HUB_ADDR_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_ADDR_PRODUCTINSTANCE_RSRC)
SELECT C.HUB_ADDR_SQN, A.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_ADDR_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product_Instance A
	JOIN SYM.NAME B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND B.ORDINAL = 0
	JOIN sym_vault1.Hub_Address C
		ON B.STREET = C.STREET AND B.CITY = C.CITY AND B.STATE = C.STATE AND B.ZIPCODE = C.ZIPCODE
	LEFT JOIN sym_vault1.Link_Addr_ProductInstance D
		ON C.HUB_ADDR_SQN = D.HUB_ADDR_SQN AND A.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_ADDR_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL;


/*
	UpdateLinkProductProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Creates a link between an instance of a Product, and a Product. Useful to see what type of Product
	a Product Instance is, or to see how many of a given Product there are.
*/
INSERT INTO sym_vault1.Link_Product_ProductInstance(HUB_PRODUCT_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PRODUCT_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PRODUCT_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product A
	JOIN SYM.SAVINGS B
		ON A.TYPE = B.TYPE AND A.CATEGORY = 'S'
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.ID AND C.CATEGORY = 'S'
	LEFT JOIN Link_Product_ProductInstance D
		ON A.HUB_PRODUCT_SQN = D.HUB_PRODUCT_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_PRODUCT_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL;


/*
	UpdateLinkProductProductInstance_LOAN.sql

	Michael McRae
	July 7, 2014

	Creates a link between an instance of a Product, and a Product. Useful to see what type of Product
	a Product Instance is, or to see how many of a given Product there are.
*/
INSERT INTO sym_vault1.Link_Product_ProductInstance(HUB_PRODUCT_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PRODUCT_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PRODUCT_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Product A
	JOIN SYM.LOAN B
		ON A.TYPE = B.TYPE AND A.CATEGORY = 'L'
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.ID AND C.CATEGORY = 'L'
	LEFT JOIN Link_Product_ProductInstance D
		ON A.HUB_PRODUCT_SQN = D.HUB_PRODUCT_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_PRODUCT_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL;


/*
	UpdateLinkPersonProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from SYM.NAME. Connects Share Product instances with a Person.
	It connects the primary account holder's SSN to the share, and any SSN that is not from a type = 3 or 2
	to a Share on that ParentAccount.

	Currently, this is connecting beneficiaries, any/all types of connection to a share. Maybe it should only be
	connecting certain kinds of connected people? (i.e. joint, spouse, etc.)
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(HUB_PERSON_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND C.CATEGORY = 'S'
	LEFT JOIN Link_Person_ProductInstance D
		ON A.HUB_PERSON_SQN = D.HUB_PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_PERSON_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL AND B.TYPE <> 2 AND B.TYPE <> 3;


/*
	UpdateLinkPersonProductInstance_LOAN.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from SYM.LOANNAME. Connects Loan Product instances with a Person.
	Specifies WHO besides Primary is on a Loan in SYM.LOANNAME, for each Loan.
	First script only connects non-primary members to the Loan, the second part connects the primary account
	holder's SSN to the loan.
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(HUB_PERSON_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.LOANNAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.PARENTID = C.ID AND C.CATEGORY = 'L'
	LEFT JOIN Link_Person_ProductInstance D
		ON A.HUB_PERSON_SQN = D.HUB_PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_PERSON_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL;
/*
	Add Primary from SYM.NAME to any and all Loans on an Account
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(HUB_PERSON_SQN, HUB_PRODUCT_INSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND C.CATEGORY = 'L'
	LEFT JOIN sym_vault1.Link_Person_ProductInstance D
		ON A.HUB_PERSON_SQN = D.HUB_PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.HUB_PRODUCT_INSTANCE_SQN
WHERE D.HUB_PERSON_SQN IS NULL AND D.HUB_PRODUCT_INSTANCE_SQN IS NULL AND B.ORDINAL = 0;


/*
	UpdateHubTransaction_LOAN.sql

	Michael McRae
	July 8, 2014

	Assumes LoanTransaction only gets new transactions(deltas) [what if it is null... need something for that]. Loads
	The primary key of a unique LoanTransaction, and 'L' into Hub_Transaction. Left joins so it only adds those
	not already in Hub_Transaction.
*/
/*
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
*/

/*
	UpdateHubTransaction_SHARE.sql

	Michael McRae
	July 8, 2014

	Assumes SaingsTransaction only gets new transactions(deltas) [what if it is null... need something for that]. Loads
	The primary key of a unique SAVINGSTRANSACTION, and 'S' into Hub_Transaction. Left joins so it only adds those
	not already in Hub_Transaction.
*/
/*
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
*/

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

UPDATE sym_vault1.Sat_Teller_Description A
	JOIN sym_vault1.Hub_Teller B
		ON A.HUB_TELLER_SQN = B.HUB_TELLER_SQN
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
	they are not already in the table.
*/
INSERT INTO Hub_Home_Phone(NUMBER, HUB_HOME_PHONE_RSRC)
SELECT DISTINCT A.HOMEPHONE, 'EASE' AS HUB_HOME_PHONE_RSRC
FROM SYM.NAME A
	LEFT JOIN Hub_Home_Phone B
		ON A.HOMEPHONE = B.NUMBER
WHERE B.NUMBER IS NULL AND A.HOMEPHONE <> '';


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
-- 
INSERT INTO Sat_Card_Status(HUB_CARD_SQN, STATUS)
SELECT A.HUB_CARD_SQN, B.STATUS
FROM Hub_Card A
	JOIN SYM.CARD B
		ON A.PARENT_ACCT = B.PARENTACCOUNT AND A.ORDINAL = B.ORDINAL
	JOIN Sat_Card_Status C
		ON A.HUB_CARD_SQN = C.HUB_CARD_SQN
WHERE C.STATUS <> B.STATUS AND C.END_DATE IS NULL;
-- 
UPDATE Sat_Card_Status A
	JOIN Hub_Card B
		ON A.HUB_CARD_SQN = B.HUB_CARD_SQN
	JOIN SYM.CARD C
		ON B.PARENT_ACCT = C.PARENTACCOUNT AND B.ORDINAL = C.ORDINAL
SET A.END_DATE = NOW()
WHERE A.STATUS <> C.STATUS AND A.END_DATE IS NULL;

/*
	=============================================================================
	=============================================================================
	=============================================================================
	=============================================================================
	These two Transaction Updates should only run after the Java program which handles Transactions +
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

/*
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