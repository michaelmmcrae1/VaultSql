/*
	AccountBranch_AddressView01.sql

	Michael McRae
	July 21, 2014

	Connects an account to it's current branch, and then to an account's address' Geocordinates.
	I.E. - Useful for facts like "this is where Accounts who primarily use Branch 8(or whatever) live"
*/
SELECT A.ACCT_NUM, B.BRANCH, D.LNG, D.LAT
FROM Hub_Account A
	JOIN Sat_Account_Closed B
		ON A.HUB_ACCT_SQN = B.ACCT_SQN AND B.END_DATE IS NULL
	JOIN Link_Acct_Addr C
		ON A.HUB_ACCT_SQN = C.ACCT_SQN
	JOIN Stage_Bing_AddressLngLat D
		ON C.ADDR_SQN = D.ADDR_SQN