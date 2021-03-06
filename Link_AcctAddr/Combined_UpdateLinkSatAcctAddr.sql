/*
	Combined_UpdateLinkSatAcctAddr.sql

	Michael McRae
	August 19, 2014
	
	Rework of UpdateLinkAcctAddr_WORKING.sql
	This must run *after* Hub_Account and Hub_Address and Hub_Person have all been updated.
*/
INSERT INTO sym_vault1.Link_Acct_Addr(HUB_ACCT_SQN, HUB_ADDR_SQN, LINK_ACCT_ADDR_RSRC)
SELECT DISTINCTROW C.HUB_ACCT_SQN, B.HUB_ADDR_SQN, 'EASE' AS LINK_ACCT_ADDR_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Address B
		ON A.STREET = B.STREET AND A.CITY = B.CITY AND A.STATE = B.STATE AND A.ZIPCODE = B.ZIPCODE
	JOIN sym_vault1.Hub_Account C
		ON A.PARENTACCOUNT = C.ACCT_NUM
	LEFT JOIN sym_vault1.Link_Acct_Addr D
		ON C.HUB_ACCT_SQN = D.HUB_ACCT_SQN
	LEFT JOIN sym_vault1.Sat_LinkAcctAddr_Effectivity E
		ON D.LINK_ACCT_ADDR_SQN = E.LINK_ACCT_ADDR_SQN
WHERE (D.HUB_ACCT_SQN IS NULL OR (E.END_DATE IS NULL AND B.HUB_ADDR_SQN <> D.HUB_ADDR_SQN)) AND A.ORDINAL = 0;
	

/*
	UpdateSatLinkAcctAddr_Effectivity.sql

	Michael McRae
	August 19, 2014
	
	Hub_Acct_SQN is the driving key in this Link for detecting
	new Links.

	A row in Link is only added if an Account's Address is different
	from the current Link between an Account and Address.

	Insert into Satellite the LinkAcctAddr_SQN for that Link for any
	Links not already in Satellite(thus getting the Link which was added
	due to being different from the Account's current Link).

	After any new Links are added to the Sat, set the END_DATE
	for current/effective Links which are no longer current i.e.
	their Hub_Addr_SQN refers to an Address in Hub_Address which
	is no longer the Address in SYM.NAME.
*/
/*
	If this is the first time we're seeing this Link, insert it into
	the Satellite.
*/
INSERT INTO sym_vault1.Sat_LinkAcctAddr_Effectivity(LINK_ACCT_ADDR_SQN)
SELECT A.LINK_ACCT_ADDR_SQN
FROM sym_vault1.Link_Acct_Addr A
	LEFT JOIN sym_vault1.Sat_LinkAcctAddr_Effectivity B
		ON A.LINK_ACCT_ADDR_SQN = B.LINK_ACCT_ADDR_SQN
WHERE B.LINK_ACCT_ADDR_SQN IS NULL;
/*
	Update the End Date in Sat for Links which are no longer current
*/
UPDATE sym_vault1.Sat_LinkAcctAddr_Effectivity A
	JOIN sym_vault1.Link_Acct_Addr B
		ON A.LINK_ACCT_ADDR_SQN = B.LINK_ACCT_ADDR_SQN
	JOIN sym_vault1.Hub_Account C
		ON B.HUB_ACCT_SQN = C.HUB_ACCT_SQN
	JOIN sym_vault1.Hub_Address D
		ON B.HUB_ADDR_SQN = D.HUB_ADDR_SQN
	JOIN SYM.NAME E
		ON C.ACCT_NUM = E.PARENTACCOUNT
SET END_DATE = NOW()
WHERE A.END_DATE IS NULL AND (D.STREET <> E.STREET OR D.CITY <> E.CITY OR D.STATE <> E.STATE)
		AND E.ORDINAL = 0;