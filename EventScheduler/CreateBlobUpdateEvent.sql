delimiter $$

CREATE EVENT sym_vault1.EVENT02_UpdateBlobFromSYM
	ON SCHEDULE
		EVERY 1 DAY
		STARTS '2014-07-29 19:15:00'
		ON COMPLETION PRESERVE
DO
BEGIN


INSERT INTO sym_vault1.Blob_SYM_Transaction(PARENTACCOUNT,
 PARENTID, CATEGORY,
 BALSEGCOUNT,
 COMMENTCODE,
 TRANSFERCODE,
 ADJUSTMENTCODE,
 REGECODE,
 REGDCHECKCODE,
 REGDTRANSFERCODE,
 VOIDCODE,
 SUBACTIONCODE,
 SEQUENCENUMBER,
 EFFECTIVEDATE,
 POSTDATE,
 POSTTIME,
 USERNUMBER,
 USEROVERRIDE,
 SECURITYLEVELS,
 DESCRIPTION,
 ACTIONCODE,
 SOURCECODE,
 BALANCECHANGE,
 INTEREST,
 NEWBALANCE,
 FEEAMOUNT,
 ESCROWAMOUNT,
 LASTTRANDATE,
 MATURITYLOANDUEDATE,
 COMMENT,
 BRANCH,
 CONSOLENUMBER,
 BATCHSEQUENCE,
 SALESTAXAMOUNT,
 ACTIVITYDATE,
 BILLEDFEEAMOUNT,
 PROCESSORUSER,
 MEMBERBRANCH,
 PREVAVAILBALANCE,
 SUBSOURCE,
 CONFIRMATIONSEQ,
 MICRACCTNUM,
 MICRRT,
 RECURRINGTRAN,
 FEEEXMTCRTSYAMT,
 ESCROWUNPAIDBALCHG,
 ESCROWAPPLIEDBALCHG,
 UNAPPLIEDPARTIALPMTCHG,
 FEECOUNTBY,
 LATECHGWAIVEDAMT,
 LATECHGUNPAIDCHGAMT,
 PREVLATECHGDATE,
 PREVLATECHGACCRUED,
 LATECHGFIELDSVALID,
 BALSEGID1,
 BALSEGPMTCHANGEDATE1,
 INTEFFECTDATE,
 BALSEGPREVFIRSTPMTDATE1)
SELECT PARENTACCOUNT,
 PARENTID, 'L' AS CATEGORY,
 BALSEGCOUNT,
 COMMENTCODE,
 TRANSFERCODE,
 ADJUSTMENTCODE,
 REGECODE,
 REGDCHECKCODE,
 REGDTRANSFERCODE,
 VOIDCODE,
 SUBACTIONCODE,
 SEQUENCENUMBER,
 EFFECTIVEDATE,
 POSTDATE,
 POSTTIME,
 USERNUMBER,
 USEROVERRIDE,
 SECURITYLEVELS,
 DESCRIPTION,
 ACTIONCODE,
 SOURCECODE,
 BALANCECHANGE,
 INTEREST,
 NEWBALANCE,
 FEEAMOUNT,
 ESCROWAMOUNT,
 LASTTRANDATE,
 MATURITYLOANDUEDATE,
 COMMENT,
 BRANCH,
 CONSOLENUMBER,
 BATCHSEQUENCE,
 SALESTAXAMOUNT,
 ACTIVITYDATE,
 BILLEDFEEAMOUNT,
 PROCESSORUSER,
 MEMBERBRANCH,
 PREVAVAILBALANCE,
 SUBSOURCE,
 CONFIRMATIONSEQ,
 MICRACCTNUM,
 MICRRT,
 RECURRINGTRAN,
 FEEEXMTCRTSYAMT,
 ESCROWUNPAIDBALCHG,
 ESCROWAPPLIEDBALCHG,
 UNAPPLIEDPARTIALPMTCHG,
 FEECOUNTBY,
 LATECHGWAIVEDAMT,
 LATECHGUNPAIDCHGAMT,
 PREVLATECHGDATE,
 PREVLATECHGACCRUED,
 LATECHGFIELDSVALID,
 BALSEGID1,
 BALSEGPMTCHANGEDATE1,
 INTEFFECTDATE,
 BALSEGPREVFIRSTPMTDATE1
FROM SYM.LOANTRANSACTION;
	


INSERT INTO sym_vault1.Blob_SYM_Transaction(PARENTACCOUNT,
 PARENTID, CATEGORY,
 BALSEGCOUNT,
 COMMENTCODE,
 TRANSFERCODE,
 ADJUSTMENTCODE,
 REGECODE,
 REGDCHECKCODE,
 REGDTRANSFERCODE,
 VOIDCODE,
 SUBACTIONCODE,
 SEQUENCENUMBER,
 EFFECTIVEDATE,
 POSTDATE,
 POSTTIME,
 USERNUMBER,
 USEROVERRIDE,
 SECURITYLEVELS,
 DESCRIPTION,
 ACTIONCODE,
 SOURCECODE,
 BALANCECHANGE,
 INTEREST,
 NEWBALANCE,
 FEEAMOUNT,
 ESCROWAMOUNT,
 LASTTRANDATE,
 MATURITYLOANDUEDATE,
 COMMENT,
 BRANCH,
 CONSOLENUMBER,
 BATCHSEQUENCE,
 SALESTAXAMOUNT,
 ACTIVITYDATE,
 BILLEDFEEAMOUNT,
 PROCESSORUSER,
 MEMBERBRANCH,
 PREVAVAILBALANCE,
 SUBSOURCE,
 CONFIRMATIONSEQ,
 MICRACCTNUM,
 MICRRT,
 RECURRINGTRAN,
 FEEEXMTCRTSYAMT,
 ESCROWUNPAIDBALCHG,
 ESCROWAPPLIEDBALCHG,
 UNAPPLIEDPARTIALPMTCHG,
 FEECOUNTBY,
 LATECHGWAIVEDAMT,
 LATECHGUNPAIDCHGAMT,
 PREVLATECHGDATE,
 PREVLATECHGACCRUED,
 LATECHGFIELDSVALID,
 BALSEGID1,
 BALSEGPMTCHANGEDATE1,
 INTEFFECTDATE,
 BALSEGPREVFIRSTPMTDATE1)
SELECT PARENTACCOUNT,
 PARENTID, 'S' AS CATEGORY,
 BALSEGCOUNT,
 COMMENTCODE,
 TRANSFERCODE,
 ADJUSTMENTCODE,
 REGECODE,
 REGDCHECKCODE,
 REGDTRANSFERCODE,
 VOIDCODE,
 SUBACTIONCODE,
 SEQUENCENUMBER,
 EFFECTIVEDATE,
 POSTDATE,
 POSTTIME,
 USERNUMBER,
 USEROVERRIDE,
 SECURITYLEVELS,
 DESCRIPTION,
 ACTIONCODE,
 SOURCECODE,
 BALANCECHANGE,
 INTEREST,
 NEWBALANCE,
 FEEAMOUNT,
 ESCROWAMOUNT,
 LASTTRANDATE,
 MATURITYLOANDUEDATE,
 COMMENT,
 BRANCH,
 CONSOLENUMBER,
 BATCHSEQUENCE,
 SALESTAXAMOUNT,
 ACTIVITYDATE,
 BILLEDFEEAMOUNT,
 PROCESSORUSER,
 MEMBERBRANCH,
 PREVAVAILBALANCE,
 SUBSOURCE,
 CONFIRMATIONSEQ,
 MICRACCTNUM,
 MICRRT,
 RECURRINGTRAN,
 FEEEXMTCRTSYAMT,
 ESCROWUNPAIDBALCHG,
 ESCROWAPPLIEDBALCHG,
 UNAPPLIEDPARTIALPMTCHG,
 FEECOUNTBY,
 LATECHGWAIVEDAMT,
 LATECHGUNPAIDCHGAMT,
 PREVLATECHGDATE,
 PREVLATECHGACCRUED,
 LATECHGFIELDSVALID,
 BALSEGID1,
 BALSEGPMTCHANGEDATE1,
 INTEFFECTDATE,
 BALSEGPREVFIRSTPMTDATE1
FROM SYM.SAVINGSTRANSACTION;

END $$

delimiter ;