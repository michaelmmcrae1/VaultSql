/*
	Michael McRae
	June 20, 2014

	Finds the Account # and Ordinal of unique individuals (Persons). Joins this list with current list
	in Hub_Person, to find those not already in Hub_Person. (WHERE G.PARENT_ACCT IS NULL i.e. where there
	isn't a match)

	NOTE - Records a name as long as at least one field from [TITLE,FIRST,MIDDLE,LAST,SUFFIX] has content in it.
	So yes, there may just be a "Mr." or just a "Jim" but it's unlikely.
*/

-- more accurate because we're grouping by SSN for those who have an SSN in the system
-- WITH GROUP BY SSN
INSERT INTO sym_vault1.Hub_Person(PARENT_ACCT, ORDINAL, HUB_PERSON_RSRC)
SELECT F.PARENTACCOUNT, F.ORDINAL, F.HUB_PERSON_RSRC FROM
(SELECT A.PARENTACCOUNT, A.ORDINAL, 'EASE' AS HUB_PERSON_RSRC 
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
WHERE A.SSN <> '' AND A.SSN <> '000000000'
	AND (A.TITLE <> '' OR A.FIRST <> '' OR A.MIDDLE <> '' OR A.LAST <> '' OR A.SUFFIX <> '')
GROUP BY A.SSN) F
	LEFT JOIN sym_vault1.Hub_Person G
		ON F.PARENTACCOUNT = G.PARENT_ACCT AND F.ORDINAL = G.ORDINAL
WHERE G.PARENT_ACCT IS NULL;


-- fallback if there is no SSN in system.
-- WITHOUT GROUP BY SSN
INSERT INTO sym_vault1.Hub_Person(PARENT_ACCT, ORDINAL, HUB_PERSON_RSRC)
SELECT F.PARENTACCOUNT, F.ORDINAL, F.HUB_PERSON_RSRC FROM
(SELECT A.PARENTACCOUNT, A.ORDINAL, 'EASE' AS HUB_PERSON_RSRC
FROM SYM.NAME A
	JOIN sym_vault1.Hub_Account B
		ON A.PARENTACCOUNT = B.ACCT_NUM
WHERE (SSN = '' OR SSN = '000000000') 
	AND (A.TITLE <> '' OR A.FIRST <> '' OR A.MIDDLE <> '' OR A.LAST <> '' OR A.SUFFIX <> '')) F
	LEFT JOIN sym_vault1.Hub_Person G
		ON F.PARENTACCOUNT = G.PARENT_ACCT AND F.ORDINAL = G.ORDINAL
WHERE G.PARENT_ACCT IS NULL;