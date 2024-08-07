IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_AutoMailReportOutletMaster]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_AutoMailReportOutletMaster] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_AutoMailReportOutletMaster]
AS
/***************************************************************************************************************************************************
Written by : Sanchita on 20/05/2022. Auto Mail Feature for ITC Live
***************************************************************************************************************************************************/
BEGIN
	SET ANSI_WARNINGS off
	SET NOCOUNT ON

	DECLARE @tab char(1) = CHAR(9), @BranchId VARCHAR(4000), @Branch VARCHAR(500), @Emailid VARCHAR(4000), @sqlQry VARCHAR(4000), @FromDate varchar(10), @ToDate varchar(10),
			@SubjectText varchar(200), @bodyText varchar(200), @filename varchar(200), @ReportToDate varchar(10)
			,@sqlMailQry NVARCHAR(4000), @filenameXLS varchar(200), @filenameZIP varchar(200)
	DECLARE @ExportSQL nvarchar(4000);

	
	------ Outlet Master Report  -------------------
	declare db_cursor_mail_VD cursor for
	SELECT Branch_Id, Branch_description,EMAILID FROM FSM_ITC..TBL_OutletMasterAutomail_ALL TV where EMAILID<>'' --and Branch_Description in ('WBHO')
	open db_cursor_mail_VD
	fetch next from db_cursor_mail_VD into @BranchId, @Branch, @Emailid
	while @@FETCH_STATUS=0
	begin

		set @sqlMailQry = 'EXEC PRC_FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL @BRANCHID='''+@BranchId+''',@USERID=378, @ISPAGELOAD=1 '
		EXEC SP_EXECUTESQL @sqlMailQry


		if (select count(0) from FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL)>1--
		begin

			set @SubjectText = 'Outlet Master Report for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for Outlet Outlet Master Report_for ' + ltrim(rtrim(@Branch))
			--set @filename = 'Outlet Master Report_for ' + ltrim(rtrim(@Branch))+'.RAR'
			set @filenameXLS = 'C:\Outlet_Master_Report_for_' + ltrim(rtrim(@Branch))+'.xls'
			set @filenameZIP = 'C:\Outlet_Master_Report_for_' + ltrim(rtrim(@Branch))+'.zip'

			
			IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL_FINAL') AND TYPE IN (N'U'))
				DROP TABLE FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL_FINAL

			CREATE TABLE FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL_FINAL
			(
			  BRANCHDESC VARCHAR(300),
			  HREPORTTOUID VARCHAR(100),
			  REPORTTOUID VARCHAR(100),
			  EMPID VARCHAR(100) NULL,
			  EMPNAME VARCHAR(300) NULL,
			  GENDERDESC VARCHAR(100),
			  OUTLETID VARCHAR(100),
			  OUTLETNAME VARCHAR(5000),
			  OUTLETADDRESS VARCHAR(1000),
			  OUTLETCONTACT VARCHAR(100),
			  OUTLETLAT VARCHAR(1000),
			  OUTLETLANG VARCHAR(1000),
			  LASTVISITDATE VARCHAR(100),
			  LASTVISITTIME VARCHAR(100),
			  LASTVISITEDBY VARCHAR(200),
			  OUTLETSTATUS	VARCHAR(10)
			)
			
			
			INSERT INTO FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL_FINAL
			select BRANCHDESC ,HREPORTTOUID ,REPORTTOUID ,EMPID , EMPNAME, GENDERDESC ,OUTLETID , OUTLETNAME , OUTLETADDRESS , OUTLETCONTACT , 
				OUTLETLAT, OUTLETLANG, LASTVISITDATE , LASTVISITTIME ,LASTVISITEDBY , OUTLETSTATUS from FSM_ITC..FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL
				

			-- create .XLS file	
			SET @ExportSQL = 'EXEC ..xp_cmdshell ''bcp " select ''''Branch'''',''''AE ID'''',''''WD ID'''',''''DS/TL ID'''',''''DS/TL Name'''',''''Gender'''',''''Outlet ID'''',''''Outlet Name'''',''''Outlet Address'''',''''Outlet Contact No.'''',''''Latitude'''',''''Longitude'''', ''''Last Visit Date'''', ''''Last Visit Time'''', ''''Last Visited By'''', ''''Status'''' union all select * from FSM_ITC..FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL_FINAL" queryout "'+@filenameXLS+'" -c -Udeb1 -PurJeHPFAobka7L -S3.111.12.83,1480'' '
			Exec(@ExportSQL)

			-- zip the .XLS file
			SET @ExportSQL = 'exec master..xp_cmdshell ''powershell Compress-Archive -Path '+@filenameXLS+' -DestinationPath '+@filenameZIP+' '' '
			EXEC (@ExportSQL);
			

			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'BreezeERP Profile',  
			@recipients = @Emailid,  
			@body = @bodyText,  
			@subject = @SubjectText, 
			@file_attachments = @filenameZIP; -- @filename
			--@query = @sqlQry ,
			--@attach_query_result_as_file = 1,
			--@query_attachment_filename=@filename,
			--@query_result_separator=@tab,
			--@query_result_no_padding=1,
			--@query_result_width = 30000,
			--@query_result_header=1;
		end

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL') AND TYPE IN (N'U'))
			DROP TABLE FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL_FINAL') AND TYPE IN (N'U'))
			DROP TABLE FTSEMPLOYEEOUTLETMASTER_REPORT_AUTOMAIL_FINAL				


		SET @ExportSQL = ' EXEC xp_cmdshell ''DEL "'+@filenameXLS+'" '' '
		Exec(@ExportSQL)

		SET @ExportSQL = ' EXEC xp_cmdshell ''DEL "'+@filenameZIP+'" '' '
		Exec(@ExportSQL)

		-- There will be a delay of 1mins after each mail e sent. This time is given so that the mail goes to users mailbox first and then the processing for the next branch starts.
		-- This is done to resolve SQL Server Agent Database Log error 
		-- "The mail could not be sent to the recipients because of the mail server failure. (Sending Mail using Account 3 (2024-02-20T03:47:10). Exception Message: Cannot send mails to mail server. (The operation has timed out.).)"
		WAITFOR DELAY '00:01:00'; 

		fetch next from db_cursor_mail_VD into @BranchId, @Branch, @Emailid
	end
	close db_cursor_mail_VD
	deallocate db_cursor_mail_VD
	------ End of Outlet Master Report  -------------------


	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON
	

END
GO