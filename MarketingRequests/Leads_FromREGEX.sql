/*
	Leads_FromREGEX.sql

	Michael McRae
	August 14, 2014

	Finds Transactions matching various Regexes -- the purpose is to find Transactions associated with other
	Financial Instituions. Joins Transactions to many tables... to connect to a Person's SSN, name,
	and their address.

	Sends the result into a .CSV file (on the Ubuntu machine in /tmp/).
*/
SELECT
	D.SSN, E.FIRST, E.MIDDLE, E.LAST, G.STREET, G.CITY, G.STATE, G.ZIPCODE, A.PARENT_ACCT, A.ID, A.CATEGORY, A.POST_DATE, A.DESCRIPTION, A.BALANCE_CHANGE
FROM sym_vault1.Hub_Transaction A
	JOIN sym_vault1.Hub_Product_Instance B
		ON A.PARENT_ACCT = B.PARENT_ACCT AND A.ID = B.ID AND A.CATEGORY = B.CATEGORY
	JOIN sym_vault1.Link_Person_ProductInstance C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
	JOIN sym_vault1.Hub_Person D
		ON C.HUB_PERSON_SQN = D.HUB_PERSON_SQN
	JOIN sym_vault1.Sat_Person_Name E
		ON D.HUB_PERSON_SQN = E.HUB_PERSON_SQN AND E.END_DATE IS NULL
	JOIN sym_vault1.Link_Addr_Person F
		ON D.HUB_PERSON_SQN = F.HUB_PERSON_SQN
	JOIN sym_vault1.Hub_Address G
		ON F.HUB_ADDR_SQN = G.HUB_ADDR_SQN
WHERE DESCRIPTION LIKE '%BANK OF AM%' OR DESCRIPTION LIKE '%BK OF AM%' OR DESCRIPTION LIKE '%Wells Fargo%' OR DESCRIPTION LIKE '%Ford Fin%'
		OR DESCRIPTION LIKE '%IHMV%' OR DESCRIPTION LIKE '%DUTRACK%' OR DESCRIPTION LIKE '%DUPAGE%'
		OR DESCRIPTION LIKE '%DISCOVER%' OR DESCRIPTION LIKE '%AM EXPR%'
INTO OUTFILE '/tmp/leads.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'

