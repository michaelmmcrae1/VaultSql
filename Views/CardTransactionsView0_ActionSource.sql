/*
	Mihcael McRae
	July 21, 2014

	Take Transactions Source Code = G {Credit/Debit Card} from sym_vault1.Hub_Transaction. It is ambigous
	*where* these card transactions occurred, but we are sure that they are Credit or Debit card transactions
	for now.

	We need the ATM dialog to know more about *where* these transactions occurred.
*/
SELECT 
    *
FROM
    sym_vault1.Hub_Transaction
WHERE
    SOURCE_CODE = 'G'