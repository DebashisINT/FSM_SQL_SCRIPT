IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_AutoMailReportRPAGroupTypeWise]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_AutoMailReportRPAGroupTypeWise] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_AutoMailReportRPAGroupTypeWise]
AS
/***************************************************************************************************************************************************
Written by : Sanchita on 20/05/2022. Auto Mail Feature for ITC Live
***************************************************************************************************************************************************/
BEGIN
	SET ANSI_WARNINGS off
	SET NOCOUNT ON

	DECLARE @tab char(1) = CHAR(9), @BranchId nvarchar(max), @Branch nvarchar(500), @Emailid nvarchar(max), @sqlQry nvarchar(max), @FromDate varchar(10), @ToDate varchar(10),
			@SubjectText varchar(200), @bodyText varchar(200), @filename varchar(200), @ReportToDate varchar(10), @ReportFromDate varchar(10)
			,@sqlMailQry NVARCHAR(MAX)

	-- REPORT WILL GO FOR ONLY ONE DAY , I.E. (CURRENT DATE - 1)				
	--if(day(getdate()) = 1)
	--begin
	--	-- first day of Previous Month to last day of previous month
	--	set @FromDate =  convert(date, DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0))
	--	set @ToDate =  convert(date, DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0)))
	--	set @ReportToDate =  convert(varchar, DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0)),105)
	--end
	--else
	--begin
	--	-- first day of Current Month to Previus day of current date
	--	set @FromDate =  DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -1, GETDATE())))
	--	set @ToDate =  convert(date, dateadd(DAY,-1,GETDATE()))
	--	set @ReportToDate =  convert(varchar, dateadd(DAY,-1,GETDATE()),105)
	--end

	set @FromDate =  convert(date, DATEADD(DAY, -2, GETDATE()))
	set @ToDate =  convert(date, DATEADD(DAY, -1, GETDATE()))
	set @ReportToDate =  convert(varchar, DATEADD(DAY, -1, GETDATE()),105)
	set @ReportFromDate =  convert(varchar,  convert(date, DATEADD(DAY, -2, GETDATE())) ,105)

	declare db_cursor_mail cursor for
	SELECT STRING_AGG(Branch_Id, ', ') WITHIN GROUP (ORDER BY Branch_Id ) AS Branch_Id, 'ALLBRANCH',EMAILID 
			FROM FSM_ITC..TBL_VisitDetailsAutomail_withDSSummary_ALL TV where EMAILID<>'' --and Branch_Description='WBHO'
			GROUP BY EMAILID
	open db_cursor_mail
	fetch next from db_cursor_mail into @BranchId, @Branch, @Emailid
	while @@FETCH_STATUS=0
	begin

		---------------- Team Visit Report ---------------------
		set @sqlMailQry = 'EXEC PRC_FTSTEAMVISITATTENDANCE_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE='''+@ToDate+''',@BRANCHID='''+@BranchId+''',@USERID=378,@SENDTOMAIL=1 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from EMPLOYEEATTENDANCE_MAIL)>0
		begin
			set @SubjectText = 'Team Visit Report_'+ @ReportToDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for Team Visit Report_'+ @ReportToDate
			set @filename = 'Team Visit Report_'+ @ReportToDate+'.csv'

			set @sqlQry = 'select * from FSM_ITC..EMPLOYEEATTENDANCE_MAIL '
			
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'BreezeERP Profile',  
			@recipients = @Emailid,  
			@body = @bodyText,  
			@subject = @SubjectText ,  
			@query = @sqlQry ,

			@attach_query_result_as_file = 1,
			@query_attachment_filename=@filename,
			@query_result_separator=@tab,
			@query_result_no_padding=1,
			@query_result_width = 15000,
			@query_result_header=1;
		end

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'EMPLOYEEATTENDANCE_MAIL') AND TYPE IN (N'U'))
			DROP TABLE EMPLOYEEATTENDANCE_MAIL
		-------------END Team Visit Report -----------------------


		------------------ DS Visit Details_  [BLOCK MOVED DOWN]  -------------------

		--set @FromDate = '2023-10-20'


		set @sqlMailQry = 'EXEC PRC_FTSDSVISITDETAILS_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE='''+@ToDate+''',@BRANCHID='''+@BranchId+''',@USERID=378, @ISPAGELOAD=1 '
		--set @sqlMailQry = 'EXEC PRC_FTSDSVISITDETAILS_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE=''2022-10-10'',@BRANCHID='''+@BranchId+''',@USERID=378 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from FTSDSVISITDETAILS_REPORT_AUTOMAIL)>1--
		begin

		--select * from FTSDSVISITDETAILS_REPORT_AUTOMAIL

			set @SubjectText = 'DS Visit Details_'+ @ReportToDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for DS Visit Details__'+ @ReportToDate
			set @filename = 'DS Visit Details_'+ @ReportToDate+'.csv'

			--set @sqlQry = 'select BRANCHDESC AS Branch,CIRCLE AS Circle,HREPORTTOUID AS [AE ID],REPORTTOUID as [WD ID],EMPID as [DS ID],
			--			replace(EMPNAME,''  '','' '') as [DS Name],DSTYPE as [DS Type], LOGIN_DATETIME as [Visit Date], convert(varchar(10), OUTLETSMAPPED) as [Outlets Mapped(Added)],
			--			convert(varchar(10),RE_VISITED) as [Outlets Re-Visited],convert(varchar(10),DISTANCE_TRAVELLED) as [Distance Travelled(Km.Mtr)],
			--			AVGTIMESPENTINMARKET as [Total time spent in the market(HH:MM)]	, isnull( DAYSTTIME,'''') as [Day Start(HH:MM)], isnull(DAYENDTIME,'''') as [Day End(HH:MM)],
			--			isnull(AVGSPENTDURATION,'''') as [Avg time spent in OL(CFT-New&Revisit)(HH:MM)] from FSM_ITC..FTSDSVISITDETAILS_REPORT_AUTOMAIL '

			set @sqlQry = 'select BRANCHDESC AS Branch,CIRCLE AS Circle,HREPORTTOUID AS [AE ID],REPORTTOUID as [WD ID],EMPID as [DS ID],
				replace(EMPNAME,''  '','' '') as [DS Name], GENDERDESC as [Gender],DSTYPE as [DS Type], LOGIN_DATETIME as [Visit Date], 
				convert(varchar(10), OUTLETSMAPPED) as [Outlets Mapped(Added)],
				convert(varchar(10),RE_VISITED) as [Outlets Re-Visited], QUALIFIEDPRESENT as [Qualified],ATTENDANCE as [Present/Absent],
				convert(varchar(10),DISTANCE_TRAVELLED) as [Distance Travelled(Km.Mtr)],
				AVGTIMESPENTINMARKET as [Total time spent in the market(HH:MM)]	, isnull( DAYSTTIME,'''') as [Day Start(HH:MM)], isnull(DAYENDTIME,'''') as [Day End(HH:MM)],
				SALE_VALUE as [Sale Value], isnull(AVGSPENTDURATION,'''') as [Avg time spent in OL(CFT-New&Revisit)(HH:MM)] from FSM_ITC..FTSDSVISITDETAILS_REPORT_AUTOMAIL'

			--set @sqlQry = 'SELECT TOP 10 * FROM FSM_ITC..TBL_MASTER_USER '

			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'BreezeERP Profile',  
			@recipients = @Emailid,  
			@body = @bodyText,  
			@subject = @SubjectText ,  
			@query = @sqlQry ,

			@attach_query_result_as_file = 1,
			@query_attachment_filename=@filename,
			@query_result_separator=@tab,
			@query_result_no_padding=1,
			@query_result_width = 30000,
			@query_result_header=1;
		end

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'FTSDSVISITDETAILS_REPORT_AUTOMAIL') AND TYPE IN (N'U'))
			DROP TABLE FTSDSVISITDETAILS_REPORT_AUTOMAIL
		------------------ End of DS Visit Details_  -------------------

		-------------- QUALIFIED ATTENDANCE REPORT ---------------------
		--DECLARE @sqlMailQry NVARCHAR(MAX)
		set @sqlMailQry = 'EXEC PRC_FTSQUALIFIEDATTENDANCE_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE='''+@ToDate+''',@BRANCHID='''+@BranchId+''',@USERID=378 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from EMPLOYEEATTENDANCE_MAILQA)>0
		begin
			set @SubjectText = 'Qualified Attendance Report_'+ @ReportToDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for Qualified Attendance Report_'+ @ReportToDate
			set @filename = 'Qualified Attendance Report_'+ @ReportToDate+'.csv'

			set @sqlQry = 'select * from FSM_ITC..EMPLOYEEATTENDANCE_MAILQA '
			
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'BreezeERP Profile',  
			--@profile_name = 'BreezeERP',  
			@recipients = @Emailid,  
			@body = @bodyText,  
			@subject = @SubjectText ,  
			@query = @sqlQry ,

			@attach_query_result_as_file = 1,
			@query_attachment_filename=@filename,
			@query_result_separator=@tab,
			@query_result_no_padding=1,
			@query_result_width = 15000,
			@query_result_header=1;
		end

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'EMPLOYEEATTENDANCE_MAILQA') AND TYPE IN (N'U'))
			DROP TABLE EMPLOYEEATTENDANCE_MAILQA
		-----------END QUALIFIED ATTENDANCE REPORT -----------------------

		-------------- DS SUMMARY REPORT ---------------------
		--set @sqlMailQry = 'EXEC PRC_FTSDSSUMMARY_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE='''+@ToDate+''',@BRANCHID='''+@BranchId+''',@USERID=378 '
		set @sqlMailQry = 'EXEC PRC_FTSDSSUMMARY_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE='''+@FromDate+''',@BRANCHID='''+@BranchId+''',@USERID=378 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from FTSDSSUMMARY_REPORT_AUTOMAIL)>0
		begin
			set @SubjectText = 'DS Summary Report_'+ @ReportFromDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for DS Summary Report_'+ @ReportFromDate
			set @filename = 'DS Summary Report_'+ @ReportFromDate+'.csv'

			set @sqlQry = 'select BRANCHDESC as Branch,HREPORTTOUID as [AE ID], REPORTTOUID as [WD ID], EMPID as [DS/TL ID], 
				EMPNAME as [DS/TL Name], GENDERDESC as Gender, DATERANGE as [From-To Date], OUTLETSMAPPED as [Outlets Mapped], 
				NEWSHOP_VISITED as [New Outlet Visit], RE_VISITED as [Outlets Re-Visited], TOTAL_VISIT as [Total Outlets Visited], 
				ISNULL(SALE_VALUE,0) as [Sale Value],DISTANCE_TRAVELLED as [Distance Travelled(Km.Mtr)], AVGTIMESPENTINMARKET as [Avg time spent in the market(HH:MM)], 
				ISNULL(AVGSPENTDURATION,'''') as [Avg time spent in OL(CFT-Customer Facing Time)(HH:MM)]  
				from FSM_ITC..FTSDSSUMMARY_REPORT_AUTOMAIL '
			
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'BreezeERP Profile',  
			--@profile_name = 'BreezeERP',  
			@recipients = @Emailid,  
			@body = @bodyText,  
			@subject = @SubjectText ,  
			@query = @sqlQry ,

			@attach_query_result_as_file = 1,
			@query_attachment_filename=@filename,
			@query_result_separator=@tab,
			@query_result_no_padding=1,
			@query_result_width = 15000,
			@query_result_header=1;
		end

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'FTSDSSUMMARY_REPORT_AUTOMAIL') AND TYPE IN (N'U'))
			DROP TABLE FTSDSSUMMARY_REPORT_AUTOMAIL
		-----------END DS SUMMARY REPORT -----------------------

		-------------- DS SUMMARY REPORT [ONLY PREVIOUS DAY] ---------------------
		set @sqlMailQry = 'EXEC PRC_FTSDSSUMMARY_REPORT_AUTOMAIL @FROMDATE='''+@ToDate+''',@TODATE='''+@ToDate+''',@BRANCHID='''+@BranchId+''',@USERID=378 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from FTSDSSUMMARY_REPORT_AUTOMAIL)>0
		begin
			set @SubjectText = 'DS Summary Report_'+ @ReportToDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for DS Summary Report_'+ @ReportToDate
			set @filename = 'DS Summary Report_'+ @ReportToDate+'.csv'

			set @sqlQry = 'select BRANCHDESC as Branch,HREPORTTOUID as [AE ID], REPORTTOUID as [WD ID], EMPID as [DS/TL ID], 
				EMPNAME as [DS/TL Name], GENDERDESC as Gender, DATERANGE as [From-To Date], OUTLETSMAPPED as [Outlets Mapped], 
				NEWSHOP_VISITED as [New Outlet Visit], RE_VISITED as [Outlets Re-Visited], TOTAL_VISIT as [Total Outlets Visited], 
				ISNULL(SALE_VALUE,0) as [Sale Value],DISTANCE_TRAVELLED as [Distance Travelled(Km.Mtr)], AVGTIMESPENTINMARKET as [Avg time spent in the market(HH:MM)], 
				ISNULL(AVGSPENTDURATION,'''') as [Avg time spent in OL(CFT-Customer Facing Time)(HH:MM)]  
				from FSM_ITC..FTSDSSUMMARY_REPORT_AUTOMAIL '
			
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'BreezeERP Profile',  
			--@profile_name = 'BreezeERP',  
			@recipients = @Emailid,  
			@body = @bodyText,  
			@subject = @SubjectText ,  
			@query = @sqlQry ,

			@attach_query_result_as_file = 1,
			@query_attachment_filename=@filename,
			@query_result_separator=@tab,
			@query_result_no_padding=1,
			@query_result_width = 15000,
			@query_result_header=1;
		end

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'FTSDSSUMMARY_REPORT_AUTOMAIL') AND TYPE IN (N'U'))
			DROP TABLE FTSDSSUMMARY_REPORT_AUTOMAIL
		-----------END DS SUMMARY REPORT [ONLY PREVIOUS DAY] -----------------------

		fetch next from db_cursor_mail into @BranchId, @Branch, @Emailid
	end
	close db_cursor_mail
	deallocate db_cursor_mail


	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON
	

END
GO