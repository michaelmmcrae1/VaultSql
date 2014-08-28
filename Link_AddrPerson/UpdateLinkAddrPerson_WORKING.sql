/*
	==== Consider Eliminating This, since we have Link_Acct_Addr and Link_Acct_Person... this just makes it
	confusing =======
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