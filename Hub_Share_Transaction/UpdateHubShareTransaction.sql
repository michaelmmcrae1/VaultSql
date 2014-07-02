/*
	Michael McRae
	July 1, 2014

	From the SYM dump, SYM.SAVINGSTRANSACTION contains all transaction in the past day. I take the primary
	key from that table and load it into Hub_Share_Transaction. Each day, they should all be unique - it only
	sends new ones that happened the day before.
	
	I still do a left join to make sure I'm not adding the same ones twice in the same day -- if I make a mistake
	and run the script twice. Could be removed in the future if this script is automated and guaranteed to only run once in a day.

	This only takes records with a 0 COMMENTCODE because I don't want to keep the Comments associated with transactions in
	Hub_Share_Transaction - those comments go into Hub_ShareT_Comment
*/

INSERT INTO sym_vault1.Hub_Share_Transaction(PARENT_ACCT, SHARE_ID, SEQUENCE_NUM, POST_DATE)
SELECT PARENTACCOUNT, PARENTID, SEQUENCENUMBER, POSTDATE
FROM SYM.SAVINGSTRANSACTION A
	LEFT JOIN sym_vault1.Hub_Share_Transaction B
		ON A.PARENTACCOUNT = B.PARENT_ACCT AND A.PARENTID = B.SHARE_ID
			AND A.SEQUENCENUMBER = B.SEQUENCE_NUM AND A.POSTDATE = B.POST_DATE
WHERE A.COMMENTCODE = 0 AND B.PARENT_ACCT IS NULL AND B.SHARE_ID IS NULL
	AND B.POST_DATE IS NULL;