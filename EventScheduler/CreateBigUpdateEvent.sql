delimiter $$

CREATE EVENT sym_vault1.EVENT_UpdateSymVault1FromSYM
	ON SCHEDULE
		EVERY 1 DAY
		STARTS '2014-07-04 07:00:00'
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
SET END_DATE = IF(A.BRANCH <> C.BRANCH, NOW(), null)
WHERE C.BRANCH <> A.BRANCH AND END_DATE IS NULL;

/*
	To update the closedate of those Accounts which are closed.
*/
UPDATE sym_vault1.Sat_Account_Closed A
	INNER JOIN sym_vault1.Hub_Account B
		ON A.ACCT_SQN = B.HUB_ACCT_SQN
	INNER JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET END_DATE = IF(C.CLOSEDATE <> '0000-00-00', C.CLOSEDATE, null)
WHERE A.END_DATE IS NULL;


/*
	UpdateHubAddress.sql

	Michael McRae
	June 20, 2014

	Joins Hub_Account, SYM.NAME to find unique (DISTINCTROW) addresses of accounts that are still open.
	Left Joins with Hub_Address to find Addresses not already in Hub_Address, and inserts them.

	NOTE - Selects blank address as a unique address as well.
*/
INSERT INTO sym_vault1.Hub_Address(STREET, CITY, STATE, ZIPCODE, HUB_ADDRESS_RSRC)
SELECT DISTINCTROW A.STREET, A.CITY, A.STATE, A.ZIPCODE, 'EASE' AS HUB_ADDRESS_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
	LEFT JOIN sym_vault1.Hub_Address C
		ON A.STREET = C.STREET AND A.CITY = C.CITY AND A.STATE = C.STATE AND A.ZIPCODE = C.ZIPCODE
WHERE C.STREET IS NULL AND C.CITY IS NULL AND C.STATE IS NULL AND C.ZIPCODE IS NULL AND A.ORDINAL = 0;
-- (A.STREET <> '' OR A.CITY <> '' OR A.STATE <> '' OR A.ZIPCODE <> '')
	

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
	UpdateShareTransaction.sql

	Michael McRae
	July 1, 2014

	From the SYM dump, SYM.SAVINGSTRANSACTION contains all transaction in the past day. I take the primary
	key from that table and load it into Hub_Share_Transaction. Each day, they should all be unique - it only
	sends new ones that happened the day before.
	
	I still do a left join to make sure I'm not adding the same ones twice in the same day -- if I make a mistake
	and run the script twice. Could be removed in the future if this script is automated and guaranteed to only run once in a day.

	This only takes records with a 0 COMMENTCODE because I don't want to keep the Comments associated with transactions in
	Hub_Share_Transaction - those comments may go into a Hub_ShareT_Comment
*/
INSERT INTO sym_vault1.Hub_Share_Transaction(PARENT_ACCT, SHARE_ID, SEQUENCE_NUM, POST_DATE)
SELECT PARENTACCOUNT, PARENTID, SEQUENCENUMBER, POSTDATE
FROM SYM.SAVINGSTRANSACTION A
	LEFT JOIN sym_vault1.Hub_Share_Transaction B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.PARENTID = B.SHARE_ID
			AND A.SEQUENCENUMBER = B.SEQUENCE_NUM AND A.POSTDATE = B.POST_DATE
WHERE A.COMMENTCODE = 0 AND B.PARENT_ACCT IS NULL AND B.SHARE_ID IS NULL
	AND B.POST_DATE IS NULL;


/*
	UpdateLoanTransaction.sql

	Michael McRae
	July 1, 2014

	From the SYM dump, SYM.LOANTRANSACTION contains all transaction in the past day. I take the primary
	key from that table and load it into Hub_Loan_Transaction. Each day, they should all be unique - Symitar only
	sends new ones that happened the day before.
	
	I still do a left join to make sure I'm not adding the same ones twice in the same day -- just in case I make a mistake
	and run the script twice. Could be removed in the future if this script is automated and guaranteed to only run once in a day.

	This only takes records with a 0 COMMENTCODE because I don't want to keep the Comments associated with transactions in
	Hub_Loan_Transaction - those comments may go into a Hub_LoanT_Comment
*/
INSERT INTO sym_vault1.Hub_Loan_Transaction(PARENT_ACCT, LOAN_ID, SEQUENCE_NUM, POST_DATE)
SELECT PARENTACCOUNT, PARENTID, SEQUENCENUMBER, POSTDATE
FROM SYM.LOANTRANSACTION A
	LEFT JOIN sym_vault1.Hub_Loan_Transaction B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.PARENTID = B.LOAN_ID
			AND A.SEQUENCENUMBER = B.SEQUENCE_NUM AND A.POSTDATE = B.POST_DATE
WHERE A.COMMENTCODE = 0 AND B.PARENT_ACCT IS NULL AND B.LOAN_ID IS NULL
	AND B.POST_DATE IS NULL;


/*
	UpdateHubLoan.sql

	Michael Mcrae
	July 1, 2014

	Joins Hub_Account with SYM.LOAN to only look at those loans for accounts already in Data Warehouse.
	Takes Loan info (PARENTACCOUNT,ID) from SYM.LOAN not already in Hub_Loan and inserts
	it into Hub_Loan.
*/
INSERT INTO sym_vault1.Hub_Loan(PARENT_ACCT, LOAN_ID, HUB_LOAN_RSRC)
SELECT PARENTACCOUNT, ID, 'EASE' AS HUB_LOAN_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.LOAN B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Loan C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.LOAN_ID
WHERE C.PARENT_ACCT IS NULL AND C.LOAN_ID IS NULL;


/*
	UpdateHubShare.sql

	Michael McRae
	July 1, 2014

	Joins SYM.SAVINGS with Hub_Account to only get shares connected with accounts
	currently in Data Warehouse. Inserts PARENTACCOUNT,ID of shares into Hub_Share which
	are not already in the table.
*/
INSERT INTO sym_vault1.Hub_Share(PARENT_ACCT, SHARE_ID, HUB_SHARE_RSRC)
SELECT PARENTACCOUNT, ID, 'EASE' AS HUB_LOAN_RSRC
FROM sym_vault1.Hub_Account A
	JOIN SYM.SAVINGS B
		ON A.ACCT_NUM = B.PARENTACCOUNT
	LEFT JOIN sym_vault1.Hub_Share C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.ID = C.SHARE_ID
WHERE C.PARENT_ACCT IS NULL AND C.SHARE_ID IS NULL;


/*
	UpdateLinkAcctLoan_WORKING.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Loan to Hub_Account on ACCT_NUM with PARENT_ACCT to connect Acct# with
	Loan identifier (PARENT_ACCT,LOAN_ID). 
	Left joins with Link_Acct_Loan to only add those not already in.

*/
INSERT INTO sym_vault1.Link_Acct_Loan(ACCT_SQN, LOAN_SQN, LINK_ACCT_LOAN_RSRC)
SELECT A.HUB_ACCT_SQN, B.HUB_LOAN_SQN, 'EASE' AS LINK_ACCT_LOAN_RSRC
FROM sym_vault1.Hub_Account A
	JOIN sym_vault1.Hub_Loan B
		ON A.ACCT_NUM = B.PARENT_ACCT
	LEFT JOIN sym_vault1.Link_Acct_Loan C
		ON A.HUB_ACCT_SQN = C.ACCT_SQN AND B.HUB_LOAN_SQN = C.LOAN_SQN
WHERE C.ACCT_SQN IS NULL AND C.LOAN_SQN IS NULL;


/*
	UpdateLinkAcctShare.sql

	Michael Mcrae
	July 1, 2014

	Joins Hub_Account and Hub_Share with ACCT_NUM = PARENT_ACCT to connect an account with a share.
	Left joins with Link_Acct_Share to only insert those not already in the table.
*/
INSERT INTO sym_vault1.Link_Acct_Share(ACCT_SQN, SHARE_SQN, LINK_ACCT_SHARE_RSRC)
SELECT A.HUB_ACCT_SQN, B.HUB_SHARE_SQN, 'EASE' AS LINK_ACCT_SHARE_RSRC
FROM sym_vault1.Hub_Account A
	JOIN sym_vault1.Hub_Share B
		ON A.ACCT_NUM = B.PARENT_ACCT
	LEFT JOIN sym_vault1.Link_Acct_Share C
		ON A.HUB_ACCT_SQN = C.ACCT_SQN AND B.HUB_SHARE_SQN = C.SHARE_SQN
WHERE C.ACCT_SQN IS NULL AND C.SHARE_SQN IS NULL;


/*
	UpdateLinkAcctLoanLoanT.sql

	Michael McRae
	July 1, 2014

	This is a 3-way link between Account,Loan, and Loan_Transaction. One way to view it: Given an Account, this will
	will show all Loans for that account, and all Loan transactions for each loan on that account.
*/
INSERT INTO sym_vault1.Link_Acct_Loan_LoanT(ACCT_SQN, LOAN_SQN, LOANT_SQN, LINK_ACCT_LOAN_LOANT_RSRC)
SELECT A.HUB_ACCT_SQN, B.HUB_LOAN_SQN, C.HUB_LOAN_TRANSACTION_SQN, 'EASE' AS LINK_ACCT_LOAN_LOANT_RSRC
FROM sym_vault1.Hub_Account A
	JOIN sym_vault1.Hub_Loan B
		ON A.ACCT_NUM = B.PARENT_ACCT
	JOIN sym_vault1.Hub_Loan_Transaction C
		ON B.PARENT_ACCT = C.PARENT_ACCT AND B.LOAN_ID = C.LOAN_ID
	LEFT JOIN sym_vault1.Link_Acct_Loan_LoanT D
		ON A.HUB_ACCT_SQN = D.ACCT_SQN AND B.HUB_LOAN_SQN = D.LOAN_SQN
			AND C.HUB_LOAN_TRANSACTION_SQN = D.LOANT_SQN
WHERE D.ACCT_SQN IS NULL AND D.LOAN_SQN IS NULL AND D.LOANT_SQN IS NULL;


/*
	UpdateLinkAcctShareShareT.sql

	Michael McRae
	July 1, 2014

	This is a 3-way link between Account,Share, and Share_Transaction. One way to view it: Given an Account, this will
	will show all Shares for that account, and all Share transactions for each loan on that account.
*/
INSERT INTO sym_vault1.Link_Acct_Share_ShareT(ACCT_SQN, SHARE_SQN, SHARET_SQN, LINK_ACCT_SHARE_SHARET_RSRC)
SELECT A.HUB_ACCT_SQN, B.HUB_SHARE_SQN, C.HUB_SHARE_TRANSACTION_SQN, 'EASE' AS LINK_ACCT_SHARE_SHARET_RSRC
FROM sym_vault1.Hub_Account A
	JOIN sym_vault1.Hub_Share B
		ON A.ACCT_NUM = B.PARENT_ACCT
	JOIN sym_vault1.Hub_Share_Transaction C
		ON B.PARENT_ACCT = C.PARENT_ACCT AND B.SHARE_ID = C.SHARE_ID
	LEFT JOIN sym_vault1.Link_Acct_Share_ShareT D
		ON A.HUB_ACCT_SQN = D.ACCT_SQN AND B.HUB_SHARE_SQN = D.SHARE_SQN
			AND C.HUB_SHARE_TRANSACTION_SQN = D.SHARET_SQN
WHERE D.ACCT_SQN IS NULL AND D.SHARE_SQN IS NULL AND D.SHARET_SQN IS NULL;


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
WHERE C.PARENT_ACCT IS NULL AND C.ID IS NULL AND C.CATEGORY IS NULL
		AND B.CLOSEDATE = '0000-00-00';


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
WHERE C.PARENT_ACCT IS NULL AND C.ID IS NULL AND C.CATEGORY IS NULL
		AND B.CLOSEDATE = '0000-00-00';


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
	UpdateLinkPersonProductInstance_SHARE.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from SYM.SAVINGSNAME. Connects Share Product instances with a Person.
	This script only connects non-primary members to the Share, it does not also connect the primary account
	holder's SSN to the share.

	Currently, this is connecting beneficiaries, any/all types of connection to a share. Maybe it should only be
	connecting certain kinds of connected people? (i.e. joint, spouse, etc.)
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT A.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PRODUCT_PRODUCTINSTANCE_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.SAVINGSNAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON B.PARENTACCOUNT = C.PARENT_ACCT AND B.PARENTID = C.ID AND C.CATEGORY = 'S'
	LEFT JOIN Link_Person_ProductInstance D
		ON A.HUB_PERSON_SQN = D.PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = D.PRODUCTINSTANCE_SQN
WHERE D.PERSON_SQN IS NULL AND D.PRODUCTINSTANCE_SQN IS NULL;


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


/*
	UpdateLinkPersonProductInstance_PRIMARY.sql

	Michael McRae
	July 7, 2014

	Updates Link_Person_ProductInstance from Primary Account holders. Connects Loan Product instances with a Person.
	This script only connects primary members to a product.

	Takes ~20 seconds ...
*/
INSERT INTO sym_vault1.Link_Person_ProductInstance(PERSON_SQN, PRODUCTINSTANCE_SQN, LINK_PERSON_PRODUCTINSTANCE_RSRC)
SELECT B.HUB_PERSON_SQN, C.HUB_PRODUCT_INSTANCE_SQN, 'EASE' AS LINK_PERSON_PRODUCTINSTANCE_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Person B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Product_Instance C
		ON A.PARENTACCOUNT = C.PARENT_ACCT
	JOIN SYM.ACCOUNT D
		ON A.PARENTACCOUNT = D.ACCOUNTNUMBER
	LEFT JOIN sym_vault1.Link_Person_ProductInstance F
		ON B.HUB_PERSON_SQN = F.PERSON_SQN AND C.HUB_PRODUCT_INSTANCE_SQN = F.PRODUCTINSTANCE_SQN
WHERE A.ORDINAL = 0 AND D.CLOSEDATE = '0000-00-00' AND F.PERSON_SQN IS NULL AND F.PRODUCTINSTANCE_SQN IS NULL;

END $$

delimiter ;