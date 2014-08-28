/*
	DeleteDupAcctAddrWithNullEndDate.sql

	Michael McRae
	August 21, 2014

	There was a previous error in the Sat_Effectivity update script. It caused
	multiple of the same HUB_ACCT_SQN - HUB_ADDR_SQN to be added to the Satellite,
	with END_DATE = NULL.

	This deletes the Duplicates of HUB_ACCT_SQN - HUB_ADDR_SQN with END_DATE NULL
	from Link_Acct_Addr, but not from Sat_Effectivity. To delete ones in Sat_Effectivity
	ust delete rows in Sat_Effectivity that don't join to any Link_Acct_Addr_SQN in Link.
*/
DELETE A FROM sym_vault1.Link_Acct_Addr A
	JOIN sym_vault1.Sat_LinkAcctAddr_Effectivity B
		ON A.LINK_ACCT_ADDR_SQN = B.LINK_ACCT_ADDR_SQN
	JOIN sym_vault1.Link_Acct_Addr C
		ON A.HUB_ACCT_SQN = C.HUB_ACCT_SQN AND A.HUB_ADDR_SQN = C.HUB_ADDR_SQN
WHERE A.LINK_ACCT_ADDR_SQN > C.LINK_ACCT_ADDR_SQN AND B.END_DATE IS NULL