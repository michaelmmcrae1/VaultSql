/*
	UpdateLinkAcctAddr_WORKING.sql

	Michael McRae
	August 18, 2014 (modified date)

	Uses SYM.NAME to connect Hub_Acct_Sqn with Hub_Addr_Sqn. Connects only on ORDINAL = 0.

	Hub_Address only contains addresses of accounts with ordinal = 0, but WHERE ORDINAL = 0
	is needed here as well, otherwise we get more than one address for an account, if there is an address
	associated with a joint on an account and also associated with a primary on a separate account.
*/
INSERT INTO sym_vault1.Link_Acct_Addr(HUB_ACCT_SQN, HUB_ADDR_SQN, LINK_ACCT_ADDR_RSRC)
SELECT DISTINCTROW C.HUB_ACCT_SQN, B.HUB_ADDR_SQN, 'EASE' AS LINK_ACCT_ADDR_RSRC
FROM SYM.NAME A
	JOIN Hub_Address B
		ON A.STREET = B.STREET AND A.CITY = B.CITY AND A.STATE = B.STATE AND A.ZIPCODE = B.ZIPCODE
	JOIN Hub_Account C
		ON A.PARENTACCOUNT = C.ACCT_NUM
	LEFT JOIN Link_Acct_Addr D
		ON C.HUB_ACCT_SQN = D.HUB_ACCT_SQN AND B.HUB_ADDR_SQN = D.HUB_ADDR_SQN
WHERE D.HUB_ACCT_SQN IS NULL AND D.HUB_ADDR_SQN IS NULL AND A.ORDINAL = 0;