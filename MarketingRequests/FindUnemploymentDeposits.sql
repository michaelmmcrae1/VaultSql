/*
	FindUnemploymentDeposits.sql

	Michael McRae
	August 18, 2014

	This SQL script looks for Transactions with DESCRIPTION LIKE '%REGEX%'
	It is looking for "UI" - Unemployment Insurance, and "insurance". Could be
	better if I knew what the description should look like for unemployment deposits.

	Hub_Transaction must be updated before this runs (for it to find newest ones).
	
	Currently only using '%UI %' and 'IDES' REGEX
*/
SELECT D.FIRST AS 'FIRST', D.MIDDLE AS 'MIDDLE', D.LAST AS 'LAST', H.STREET AS 'STREET', H.CITY AS 'CITY', H.STATE AS 'STATE', H.ZIPCODE AS 'ZIPCODE',
		A.PARENT_ACCT AS 'ACCOUNT', A.CATEGORY AS 'SHARE/LOAN', A.ID AS 'ID', A.POST_DATE AS 'POST_DATE',
		A.DESCRIPTION AS 'DESCRIP', A.BALANCE_CHANGE AS 'BALANCE_CHANGE'
FROM sym_vault1.Hub_Transaction A
	JOIN sym_vault1.Link_Person_Transaction B
		ON A.HUB_TRANSACTION_SQN = B.HUB_TRANSACTION_SQN
	JOIN sym_vault1.Hub_Person C
		ON B.HUB_PERSON_SQN = C.HUB_PERSON_SQN
	JOIN sym_vault1.Sat_Person_Name D
		ON C.HUB_PERSON_SQN = D.HUB_PERSON_SQN
	JOIN sym_vault1.Hub_Account E
		ON A.PARENT_ACCT = E.ACCT_NUM
	JOIN sym_vault1.Link_Acct_Addr F
		ON E.HUB_ACCT_SQN = F.HUB_ACCT_SQN
	JOIN sym_vault1.Sat_LinkAcctAddr_Effectivity G
		ON F.LINK_ACCT_ADDR_SQN = G.LINK_ACCT_ADDR_SQN
	JOIN sym_vault1.Hub_Address H
		ON F.HUB_ADDR_SQN = H.HUB_ADDR_SQN
WHERE D.END_DATE IS NULL AND G.END_DATE IS NULL AND CATEGORY = 'S' AND (TELLER_NUM = 907 OR TELLER_NUM = 922)
	AND (DESCRIPTION LIKE '%UI %' OR DESCRIPTION LIKE 'IDES') AND A.POST_DATE >= '2014-08-20'
	AND BALANCE_CHANGE > 0
INTO OUTFILE '/tmp/20140821ui_deposits.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'