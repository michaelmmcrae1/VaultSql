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

	Finds HUB_ACCT_SQN, and associated Account Number, not already in Sat_Account_Closed. Uses the Account Number to join with
	SYM.ACCOUNT to find the current BRANCH of these Accounts.
*/
INSERT INTO Sat_Account_Closed(HUB_ACCT_SQN, BRANCH)
SELECT D.HUB_ACCT_SQN, BRANCH FROM SYM.ACCOUNT C JOIN
(SELECT A.HUB_ACCT_SQN, A.ACCT_NUM FROM Hub_Account A
LEFT JOIN
Sat_Account_Closed B
ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
WHERE B.HUB_ACCT_SQN IS NULL) D
ON C.ACCOUNTNUMBER = D.ACCT_NUM;
/*
	To update the closedate of those Accounts which are closed.
*/
UPDATE sym_vault1.Sat_Account_Closed A
	INNER JOIN sym_vault1.Hub_Account B
		ON A.HUB_ACCT_SQN = B.HUB_ACCT_SQN
	INNER JOIN SYM.ACCOUNT C
		ON B.ACCT_NUM = C.ACCOUNTNUMBER
SET END_DATE = IF(C.CLOSEDATE <> '0000-00-00', C.CLOSEDATE, null);



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

	Hub_Addresses only contains addresses of accounts with ordinal = 0, but WHERE ORDINAL = 0
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

	NOTE - This update script takes 120+ seconds to complete... WAY MORE than other Link Update
	scripts (~4.5 seconds). Not sure why.

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
		






