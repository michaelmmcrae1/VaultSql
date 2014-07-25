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