IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LEDGERVALUEMISMATCH_REPORT_AUTOMAIL]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LEDGERVALUEMISMATCH_REPORT_AUTOMAIL] AS' 
END
GO
-- EXEC PRC_LEDGERVALUEMISMATCH_REPORT_AUTOMAIL

ALTER Proc [dbo].[PRC_LEDGERVALUEMISMATCH_REPORT_AUTOMAIL]
(
	@CLIENT_DBNAME NVARCHAR(500) = ''  -- select DB1,CLIENT_NAME from BREEZE_CLIENT_DETAILS where TYPE_OF_PRODUCT in ('FSM','Attendance System - FSM') 
)
As
/************************************************************************************************************************************************************
	Written by Sanchita
************************************************************************************************************************************************************/
Begin
	DECLARE @FROMDATE DATE, @TODATE DATE,@sqlStrTable NVARCHAR(MAX), @COMPANYID varchar(10), @FinYear varchar(10)
	DECLARE @SubjectText varchar(200), @bodyText varchar(200), @filename varchar(200), @ReportToDate varchar(10), 
			@Emailid nvarchar(max), @sqlQry nvarchar(max), @tab char(1) = CHAR(9)

	CREATE TABLE master..temDatabaseName
	(
		SLNO int,
		CLIENT_NAME nvarchar(500),
		DBNAME nvarchar(500),
	)

	INSERT INTO master..temDatabaseName (CLIENT_NAME, DBNAME) VALUES('EVAC Engineering Projects Pvt Ltd.', 'EVAC')
	INSERT INTO master..temDatabaseName (CLIENT_NAME, DBNAME) VALUES('Tubes & Pipes (India) Pvt Ltd', 'EVTUBE2223')
	INSERT INTO master..temDatabaseName (CLIENT_NAME, DBNAME) VALUES('Tubes & Pipes (India) Pvt Ltd', 'BRZ_EVTUBE2324')



	CREATE TABLE master..temFinYear
	(
		finyear_startdate DATE,
		finyear_enddate DATE
	)

	CREATE TABLE master..temLastSegment
	(
		ls_lastCompany varchar(10),
		ls_lastFinYear varchar(10)
	)



	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'master..tempMismatchData') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE master..tempMismatchData
			(
				SEQ BIGINT,
				CLIENT_NAME nvarchar(500),
				DBNAME nvarchar(500),
				TRAN_DATE NVARCHAR(10),
				DOC_NO NVARCHAR(50),
				BRANCHNAME NVARCHAR(300),
				DOC_TYPE NVARCHAR(80),
				--LEDGERDESC NVARCHAR(300),
				--DEBIT DECIMAL(38,2),
				--CREDIT DECIMAL(38,2),
				BALANCE DECIMAL(38,2)
			)
			CREATE NONCLUSTERED INDEX IX1 ON master..tempMismatchData (SEQ)
		END
	DELETE FROM master..tempMismatchData --WHERE USERID=@USERID

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'master..tempusercount') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE master..tempusercount
			(
				SEQ BIGINT,
				CLIENT_NAME nvarchar(500),
				DBNAME nvarchar(500),
				TRAN_DATE NVARCHAR(10),
				DOC_NO NVARCHAR(50),
				BRANCHNAME NVARCHAR(300),
				DOC_TYPE NVARCHAR(80),
				--LEDGERDESC NVARCHAR(300),
				--DEBIT DECIMAL(38,2),
				--CREDIT DECIMAL(38,2),
				BALANCE DECIMAL(38,2)
			)
			CREATE NONCLUSTERED INDEX IX1 ON master..tempusercount (DBNAME, SEQ)
		END
	DELETE FROM master..tempusercount --WHERE USERID=@USERID
	

	declare @DB_NAME varchar(MAX),@CLIENT_NAME NVARCHAR(500),@html nvarchar(MAX)
	DECLARE UOMMAIN_CURSOR CURSOR  
	LOCAL  FORWARD_ONLY  FOR  

	select DBNAME,CLIENT_NAME from master..temDatabaseName order by DBNAME
	OPEN UOMMAIN_CURSOR  
	FETCH NEXT FROM UOMMAIN_CURSOR INTO  @DB_NAME,@CLIENT_NAME
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		DELETE FROM master..temLastSegment
		DELETE FROM master..temFinYear

		SET @sqlStrTable = ''
		SET @sqlStrTable = 'INSERT INTO master..temLastSegment '
		SET @sqlStrTable += 'select top 1 ls_lastCompany,	ls_lastFinYear '
		SET @sqlStrTable += 'from   ['+@DB_NAME+'].[dbo].tbl_trans_LastSegment '
		SET @sqlStrTable += ' where ls_cntId in (select user_contactid from ['+@DB_NAME+'].[dbo].tbl_master_user where user_loginid=''Admin'') '
		EXEC SP_EXECUTESQL @sqlStrTable

		--SELECT * from master..temLastSegment
		SET @COMPANYID = (SELECT top 1 ls_lastCompany from master..temLastSegment)
		SET @FinYear = (SELECT top 1 ls_lastFinYear from master..temLastSegment)



		SET @sqlStrTable = ''
		SET @sqlStrTable = 'INSERT INTO master..temFinYear '
		SET @sqlStrTable += 'select CONVERT(date,finyear_startdate),CONVERT(date,FinYear_EndDate) '
		SET @sqlStrTable += 'from   ['+@DB_NAME+'].[dbo].Master_FinYear where FinYear_Code='''+@FinYear+''' '
		EXEC SP_EXECUTESQL @sqlStrTable
		
		--SELECT * from master..temFinYear
		SET @FROMDATE = (SELECT top 1 finyear_startdate from master..temFinYear)
		SET @TODATE = (SELECT top 1 finyear_enddate from master..temFinYear)


		
		SET @sqlStrTable = ''
		SET @sqlStrTable = 'INSERT INTO master..tempMismatchData(SEQ,CLIENT_NAME,DBNAME,TRAN_DATE,DOC_NO,BRANCHNAME,DOC_TYPE,BALANCE) '
		SET @sqlStrTable += 'SELECT ROW_NUMBER() OVER(ORDER BY CONVERT(NVARCHAR(10),TA.AccountsLedger_TransactionDate,105)) AS SEQ,'''+@CLIENT_NAME+''','''+@DB_NAME+''','
		SET @sqlStrTable += 'CONVERT(NVARCHAR(10),TA.AccountsLedger_TransactionDate,105) AS TRAN_DATE, '
		SET @sqlStrTable += 'ISNULL(TA.AccountsLedger_TransactionReferenceID,'''') AS DOC_NO,BR.BRANCH_DESCRIPTION, '
		SET @sqlStrTable += 'CASE WHEN TA.AccountsLedger_TransactionType IN(''POS'',''Sales_Invoice'') THEN ''Sales Invoice'' WHEN TA.AccountsLedger_TransactionType =''TransitSales_Invoice'' THEN ''Transit Sales Invoice'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType IN(''Purchase_Invoice'',''PurchaseInvoice_TDS'') THEN ''Purchase Invoice'' WHEN TA.AccountsLedger_TransactionType =''TransitPurchase_Invoice'' THEN ''Transit Purchase Invoice'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''Sale_Return'' THEN ''Sales Return'' WHEN TA.AccountsLedger_TransactionType=''Purchase_Return'' THEN ''Purchase Return'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''Purchase_Return_Manual'' THEN ''Purchase Return Manual'' WHEN TA.AccountsLedger_TransactionType=''Sale_Return_Manual'' THEN ''Sales Return Manual'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''Sale_Return_Normal'' THEN ''Sales Return Normal'' WHEN TA.AccountsLedger_TransactionType=''Undelivery_Sale_Return'' THEN ''Undelivery Sales Return'' ' 
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''Rate_Difference_Entry_Customer'' THEN ''Rate Difference Entry Customer'' WHEN TA.AccountsLedger_TransactionType=''Rate_Difference_Entry_Vendor'' '
		SET @sqlStrTable += 'THEN ''Rate Difference Entry Vendor''	WHEN TA.AccountsLedger_TransactionType=''AdvAdj'' THEN ''Advanced Adjusted'' WHEN TA.AccountsLedger_TransactionType=''POSOD'' THEN ''Advanced Against Sales Order'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''CustomerPayRec'' THEN ''Customer Receipt'' WHEN TA.AccountsLedger_TransactionType=''CustomerPayRec'' THEN ''Customer Payment'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''VendorPayRec'' THEN ''Vendor Receipt'' WHEN TA.AccountsLedger_TransactionType=''VendorPayRec'' THEN ''Vendor Payment'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''CN Customer'' THEN ''Credit Note Customer'' WHEN TA.AccountsLedger_TransactionType=''DN Customer'' THEN ''Debit Note Customer'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''CN Vendor'' THEN ''Credit Note Vendor'' WHEN TA.AccountsLedger_TransactionType=''DN Vendor'' THEN ''Debit Note Vendor'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''Contra'' THEN ''Contra Voucher'' WHEN TA.AccountsLedger_TransactionType=''Cash_Bank'' THEN ''Cash/Bank Voucher'' '
		SET @sqlStrTable += 'WHEN TA.AccountsLedger_TransactionType=''Journal'' THEN ''Journal Voucher'' ELSE '''' END AS DOC_TYPE,SUM(TA.AccountsLedger_AmountDr)-SUM(TA.AccountsLedger_AmountCr) AS BALANCE '
		SET @sqlStrTable += 'FROM ['+@DB_NAME+'].[dbo].Trans_AccountsLedger TA '
		SET @sqlStrTable += 'INNER JOIN ['+@DB_NAME+'].[dbo].TBL_MASTER_BRANCH BR ON TA.AccountsLedger_BranchId=BR.branch_id '
		SET @sqlStrTable += 'WHERE CONVERT(NVARCHAR(10),AccountsLedger_TransactionDate,120) BETWEEN '''+cast(@FROMDATE AS VARCHAR(10))+''' AND '''+CAST(@TODATE AS VARCHAR(10))+''' AND TA.AccountsLedger_CompanyID='''+@COMPANYID+''' '
		SET @sqlStrTable += 'GROUP BY CONVERT(NVARCHAR(10),TA.AccountsLedger_TransactionDate,105),TA.AccountsLedger_TransactionReferenceID,BR.branch_description,TA.AccountsLedger_TransactionType '
		SET @sqlStrTable += 'HAVING SUM(TA.AccountsLedger_AmountDr)-SUM(TA.AccountsLedger_AmountCr)<>0 '
		SET @sqlStrTable += ' UNION ALL '
		SET @sqlStrTable += 'SELECT 99999999 AS SEQ,'''+@CLIENT_NAME+''','''+@DB_NAME+''',NULL AS TRAN_DATE,''Total :'' AS DOC_NO,'''' AS BRANCH_DESCRIPTION,'''' AS DOC_TYPE,SUM(TA.AccountsLedger_AmountDr)-SUM(TA.AccountsLedger_AmountCr) AS BALANCE '
		SET @sqlStrTable += ' FROM ['+@DB_NAME+'].[dbo].Trans_AccountsLedger TA '
		SET @sqlStrTable += ' INNER JOIN ['+@DB_NAME+'].[dbo].TBL_MASTER_BRANCH BR ON TA.AccountsLedger_BranchId=BR.branch_id '
		SET @sqlStrTable += ' WHERE CONVERT(NVARCHAR(10),AccountsLedger_TransactionDate,120) BETWEEN '''+CAST(@FROMDATE AS VARCHAR(10))+''' AND '''+CAST(@TODATE AS VARCHAR(10))+''' AND TA.AccountsLedger_CompanyID='''+@COMPANYID+''' '
		--SET @sqlStrTable += ' HAVING SUM(TA.AccountsLedger_AmountDr)-SUM(TA.AccountsLedger_AmountCr)<>0 '
		
		--select  @sqlStrTable
		
		EXEC SP_EXECUTESQL @sqlStrTable
	FETCH NEXT FROM UOMMAIN_CURSOR INTO  @DB_NAME,@CLIENT_NAME
	END  
	CLOSE UOMMAIN_CURSOR  
	DEALLOCATE UOMMAIN_CURSOR  

	---SELECT * FROM master..tempMismatchData --ORDER BY DBNAME, SEQ


	DECLARE UOMMAIN_CURSOR1 CURSOR  
	LOCAL  FORWARD_ONLY  FOR 
	select DBNAME,CLIENT_NAME from master..temDatabaseName order by DBNAME
	OPEN UOMMAIN_CURSOR1  
	FETCH NEXT FROM UOMMAIN_CURSOR1 INTO  @DB_NAME,@CLIENT_NAME
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		IF (SELECT SUM(BALANCE) FROM master..tempMismatchData WHERE DBNAME=@DB_NAME AND SEQ='99999999')<>0  -- RECORD INSERT ONLY IF MISMATCH IS THERE
		BEGIN
			insert into master..tempusercount
			select * FROM master..tempMismatchData WHERE DBNAME=@DB_NAME
		END
		
		FETCH NEXT FROM UOMMAIN_CURSOR1 INTO  @DB_NAME,@CLIENT_NAME
	END
	CLOSE UOMMAIN_CURSOR1  
	DEALLOCATE UOMMAIN_CURSOR1  

	--select * from master..tempusercount
	--select * from master..tempusercount where SEQ='99999999'
	--select * from master..tempMismatchData where SEQ='99999999'
	--SELECT COUNT(0) FROM master..tempusercount
	
	IF (SELECT COUNT(0) FROM master..tempusercount)>0
	BEGIN
		-- send email ---
		set @ReportToDate =  convert(varchar, getdate(),105)
		set @Emailid = 'pijushk.bhattacharya@indusnet.co.in ; debashis.talukder@indusnet.co.in; goutamk.das@indusnet.co.in ; sanchita.saha@indusnet.co.in; priti.ghosh@indusnet.co.in; santanu.roy@indusnet.co.in'
		--set @Emailid = 'sanchita.saha@indusnet.co.in'
		set @SubjectText = 'EVAC Mismatch Detection REPORT AS ON '+ @ReportToDate
		set @bodyText = 'Please find attached excel file for EVAC Mismatch Detection REPORT AS ON '+ @ReportToDate
		set @filename = 'EVAC Mismatch Detection REPORT_'+ @ReportToDate+'.csv'

		set @sqlQry = 'SET NOCOUNT ON select * from master..tempusercount '
		--set @sqlQry = 'select 1 '
		--set @sqlQry = 'SELECT TOP 10 user_id FROM Honeywell..TBL_MASTER_USER '

		EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'BreezeERP',  
		@recipients = @Emailid,  
		@body = @bodyText,  
		@subject = @SubjectText ,  
		@query = @sqlQry ,
		--@execute_query_database='Honeywell',

		@attach_query_result_as_file = 1,
		@query_attachment_filename=@filename,
		@query_result_separator=@tab,
		@query_result_no_padding=1,
		@query_result_width = 15000;
		-- end send email ---
	END	
		--select * from master..tempusercount

	DROP TABLE master..temDatabaseName
	DROP TABLE master..tempMismatchData	
	DROP TABLE master..temFinYear
	drop table master..temLastSegment
	drop table master..tempusercount

END
GO