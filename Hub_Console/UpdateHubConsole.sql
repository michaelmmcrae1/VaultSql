/*
	UpdateHubConsole.sql

	Michael McRae
	July 9, 2014

	Takes DISTINCT CONSOLE_NUMs from Hub_Transaction and adds them to Hub_Console. Left joins
	so we only add CONSOLE_NUM not already in Hub_Console.
*/
INSERT INTO sym_vault1.Hub_Console(CONSOLE_NUM, HUB_CONSOLE_RSRC)
SELECT DISTINCT A.CONSOLE_NUM, 'EASE' AS HUB_CONSOLE_RSRC
FROM sym_vault1.Hub_Transaction A
	LEFT JOIN sym_vault1.Hub_Console B
		ON A.CONSOLE_NUM = B.CONSOLE_NUM
WHERE B.CONSOLE_NUM IS NULL;