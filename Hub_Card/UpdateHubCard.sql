/*
	UpdateHubCard.sql

	Michael McRae
	July 21, 2014

	Takes primary key from SYM.CARD {Parentaccount, Ordinal} and inserts into Hub_Card. Left joins with
	Sat_ProductInstance_Closed so that it only selects those with Parentaccount NOT closed.
*/
INSERT INTO Hub_Card(PARENT_ACCT, ORDINAL, NUMBER, SAV_ID, CHK_ID, CREDIT_ID, HUB_CARD_RSRC)
SELECT DISTINCTROW A.PARENTACCOUNT, A.ORDINAL, A.NUMBER, A.SAVID, A.CHKID, A.CREDITCARDID, 'EASE' AS HUB_CARD_RSRC
FROM SYM.CARD A
	JOIN Hub_Product_Instance B
		ON A.PARENTACCOUNT = B.PARENT_ACCT
	LEFT JOIN Sat_ProductInstance_Closed C
		ON B.HUB_PRODUCT_INSTANCE_SQN = C.PRODUCTINSTANCE_SQN
	LEFT JOIN Hub_Card D
		ON A.PARENTACCOUNT = D.PARENT_ACCT AND A.ORDINAL = D.ORDINAL
WHERE STATUS = 1 AND D.PARENT_ACCT IS NULL AND D.ORDINAL IS NULL
		AND C.PRODUCTINSTANCE_SQN IS NULL;