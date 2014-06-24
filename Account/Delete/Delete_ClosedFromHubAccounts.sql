/*
	Michael McRae
	June 20, 2014

	Deletes Accounts from Hub_Account which have been closed. SYM.ACCOUNT contains CLOSEDATE which is the
	date when an account closes. If CLOSEDATE = '0000-00-00' i.e. there is no close date, then an Account
	is still open. Otherwise, it has been closed.

*/

DELETE FROM sym_vault1.Hub_Account
WHERE ACCT_NUM IN
	(SELECT ACCOUNTNUMBER FROM SYM.ACCOUNT
		WHERE CLOSEDATE <> '0000-00-00');