/*
	ListAccountsAndProductSameDate.sql

	Grab accounts, people on that account, and all Shares and Loans which were
	opened on that Account the SAME DAY that the account was opened

	NOTE: sends output to a .csv file on the svdhcumysql(10.1.100.50) machine
*/
SELECT
	D.ACCT_NUM, A.SSN, C.CATEGORY, C.ID, E.TYPE, D.OPEN_DATE INTO OUTFILE '/tmp/results.csv'
FROM Hub_Person A
	JOIN Link_Person_ProductInstance B
		ON A.HUB_PERSON_SQN = B.HUB_PERSON_SQN
	JOIN Hub_Product_Instance C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.HUB_PRODUCT_INSTANCE_SQN
	JOIN Sat_ProductInstance_Type E
		ON C.HUB_PRODUCT_INSTANCE_SQN = E.HUB_PRODUCT_INSTANCE_SQN
	JOIN Hub_Account D
		ON C.PARENT_ACCT = D.ACCT_NUM
WHERE D.OPEN_DATE = C.OPEN_DATE AND E.END_DATE IS NULL