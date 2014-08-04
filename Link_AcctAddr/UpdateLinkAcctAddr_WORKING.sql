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
WHERE D.ACCT_SQN IS NULL AND D.ADDR_SQN IS NULL AND (A.ORDINAL = 0 OR A.TYPE = 2 OR A.TYPE = 3);