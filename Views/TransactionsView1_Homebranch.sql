/*
	Mihcael McRae
	July 21, 2014

	Find Transactions that were done on Home Banking {Home Branch - SOURCE_CODE = 'H'}
	Transactions done on Home Branch also will always have BRANCH = 0 (if BRANCH is not null)
*/
SELECT
    *
FROM
    sym_vault1.Hub_Transaction
WHERE
    SOURCE_CODE = 'H';