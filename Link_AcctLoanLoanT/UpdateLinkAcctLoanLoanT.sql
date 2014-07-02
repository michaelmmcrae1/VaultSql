/*
	UpdateAcctLoanLoanT.sql

	Michael McRae
	July 1, 2014

	This is a 3-way link between Account,Loan, and Loan_Transaction. One way to view it: Given an Account, this will
	will show all Loans for that account, and all Loan transactions for each loan on that account.
*/
INSERT INTO sym_vault1.Link_Acct_Loan_LoanT(ACCT_SQN, LOAN_SQN, LOANT_SQN, LINK_ACCT_LOAN_LOANT_RSRC)
SELECT A.HUB_ACCT_SQN, B.HUB_LOAN_SQN, C.HUB_LOAN_TRANSACTION_SQN, 'EASE' AS LINK_ACCT_LOAN_LOANT_RSRC
FROM sym_vault1.Hub_Account A
	JOIN sym_vault1.Hub_Loan B
		ON A.ACCT_NUM = B.PARENT_ACCT
	JOIN sym_vault1.Hub_Loan_Transaction C
		ON B.PARENT_ACCT = C.PARENT_ACCT AND B.LOAN_ID = C.LOAN_ID
	LEFT JOIN sym_vault1.Link_Acct_Loan_LoanT D
		ON A.HUB_ACCT_SQN = D.ACCT_SQN AND B.HUB_LOAN_SQN = D.LOAN_SQN
			AND C.HUB_LOAN_TRANSACTION_SQN = D.LOANT_SQN
WHERE D.ACCT_SQN IS NULL AND D.LOAN_SQN IS NULL AND D.LOANT_SQN IS NULL;