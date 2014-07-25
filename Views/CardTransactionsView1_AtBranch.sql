/*
	Mihcael McRae
	July 21, 2014

	Find Transactions which occur at a branch. This is based on
	the assumption(fact?) that all Card or remote transactions have BRANCH = 0 or Source_Code = 'G'
	so we eliminate those with Branch of 0 or Source_Code of 'G'

Note:
	!(BRANCH OF 0 OR SOURCE OF 'G') == !BRANCH OF 0 AND !SOURCE OF 'G'
*/
SELECT 
    *
FROM
    sym_vault1.Hub_Transaction
WHERE
    BRANCH <> 0 AND SOURCE_CODE <> 'G'