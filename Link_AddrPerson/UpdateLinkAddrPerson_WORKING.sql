/*
	Michael McRae
	June 23, 2014

	Joins Hub_Person, NAME, and Hub_Address to find address associated with an SSN.

	NOTE - This update script takes 100+ seconds... WAY MORE than other Link Update scripts (~4 seconds). Not sure why.

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
		