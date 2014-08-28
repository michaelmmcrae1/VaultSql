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
