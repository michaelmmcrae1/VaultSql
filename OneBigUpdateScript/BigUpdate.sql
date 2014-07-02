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
WHERE B.ACCT_NUM IS NULL AND A.CLOSEDATE = '0000-00-00';


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
	does not match the BRANCH in SYM.ACCOUNT.

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

UPDATE sym_vault1.Sat_Account_Closed A
	JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
	JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET END_DATE = IF(A.BRANCH <> C.BRANCH, NOW(), null)
WHERE C.BRANCH <> A.BRANCH AND END_DATE IS NULL;

/*
	To update the closedate of those Accounts which are closed.
*/
UPDATE sym_vault1.Sat_Account_Closed A
	INNER JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
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
WHERE C.SSN IS NULL;

/*
	UpdateSatPersonName.sql

	Michael McRae
	June 23, 2014

	Joins Hub_Person, NAME on SSN to find names of SSN's. Inserts TITLE,FIRST,MIDDLE,LAST
	asssociated with SSN, and connected HUB_PERSON_SQN, into Sat_Person_Name
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

	NOTE - This update script takes 100+ seconds to complete... WAY MORE than other Link Update
	scripts (~4 seconds). Not sure why.
*/
INSERT INTO sym_vault1.Link_Addr_Person(ADDR_SQN, PERSON_SQN, LINK_ADDR_PERSON_RSRC)
SELECT DISTINCTROW C.HUB_ADDRESS_SQN, A.HUB_PERSON_SQN, 'EASE' AS LINK_ADDR_PERSON_RSRC
FROM sym_vault1.Hub_Person A
	JOIN SYM.NAME B
		ON A.SSN = B.SSN
	JOIN sym_vault1.Hub_Address C
		ON B.STREET = C.STREET AND B.STATE = C.STATE AND B.ZIPCODE = C.ZIPCODE
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