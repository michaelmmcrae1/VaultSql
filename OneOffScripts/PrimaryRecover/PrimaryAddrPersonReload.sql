/*
	PrimaryAddrPersonReload.sql

	Michael McRae
	August 13, 2014


	
*/
truncate sym_vault1.Hub_Address;

truncate sym_vault1.Hub_Person;


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
WHERE A.SSN <> '' AND A.SSN <> '000000000' AND A.ORDINAL = 0
		AND D.SSN IS NULL;