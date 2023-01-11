
-- exec PRC_SendQualifiedAttendanceAUtomail_ALL
-- EXEC PRC_FTSQUALIFIEDATTENDANCE_REPORT_AUTOMAIL '2022-11-01','2022-11-13','1,118,120,121,122,123,124,125,126,127,128,129,130','','',378
-- select * from EMPLOYEEATTENDANCE_MAILQA
-- File attachment or query results size exceeds allowable value of 1000000 bytes.


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_SendQualifiedAttendanceAUtomail_ALL]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_SendQualifiedAttendanceAUtomail_ALL] AS'  
END 
GO

ALTER PROCEDURE [dbo].[PRC_SendQualifiedAttendanceAUtomail_ALL]
AS
/***************************************************************************************************************************************************
Written by : Sanchita on 20/05/2022. Auto Mail Feature for ITC Live
***************************************************************************************************************************************************/
BEGIN
	DECLARE @tab char(1) = CHAR(9), @BranchId nvarchar(max), @Branch nvarchar(500), @Emailid nvarchar(max), @sqlQry nvarchar(max), @FromDate varchar(10), @ToDate varchar(10),
			@SubjectText varchar(200), @bodyText varchar(200), @filename varchar(200), @ReportToDate varchar(10)

	--set @Emailid = 'sanchita.saha@indusnet.co.in'
	--set @Branch = '122'
	--set @FromDate = DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -1, GETDATE())))
	--set @ToDate =  convert(date, dateadd(DAY,-1,GETDATE()))
	--set @ReportToDate = convert(varchar, dateadd(DAY,-1,GETDATE()),105)
	if(day(getdate()) = 1)
	begin
		-- first day of Previous Month to last day of previous month
		set @FromDate =  convert(date, DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0))
		set @ToDate =  convert(date, DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0)))
		set @ReportToDate =  convert(varchar, DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0)),105)
	end
	else
	begin
		-- first day of Current Month to Previus day of current date
		set @FromDate = DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -1, GETDATE())))
		set @ToDate = convert(date, dateadd(DAY,-1,GETDATE()))
		set @ReportToDate =  convert(varchar, dateadd(DAY,-1,GETDATE()),105)
	end

	declare db_cursor_mail cursor for
	--select  STRING_AGG(branch_id, ',') WITHIN GROUP (ORDER BY branch_id ) AS BranchId, 'ALL','sanchita.saha@indusnet.co.in; priti.ghosh@indusnet.co.in ' 
	--SELECT STRING_AGG(Branch_Id, ', ') WITHIN GROUP (ORDER BY Branch_Id ) AS Branch_Id, 'ALLBRANCH',EMAILID 
	--		FROM FSM_ITC..TBL_VisitDetailsAutomail_ALL_TEST TV where EMAILID<>'' GROUP BY EMAILID
	SELECT STRING_AGG(Branch_Id, ', ') WITHIN GROUP (ORDER BY Branch_Id ) AS Branch_Id, 'ALLBRANCH',EMAILID 
			FROM TBL_VisitDetailsAutomail_ALL_TEST TV where EMAILID<>'' GROUP BY EMAILID
	open db_cursor_mail
	fetch next from db_cursor_mail into @BranchId, @Branch, @Emailid
	while @@FETCH_STATUS=0
	begin

		-------------- Team Visit Report ---------------------
		DECLARE @sqlMailQry NVARCHAR(MAX)
		set @sqlMailQry = 'EXEC PRC_FTSQUALIFIEDATTENDANCE_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE='''+@ToDate+''',@BRANCHID='''+@BranchId+''',@USERID=378 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from EMPLOYEEATTENDANCE_MAILQA)>0
		begin
			set @SubjectText = 'Qualified Attendance Report_'+ @ReportToDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for Qualified Attendance Report_'+ @ReportToDate
			set @filename = 'Qualified Attendance Report_'+ @ReportToDate+'.csv'

			set @sqlQry = 'select * from FSM_ITC..EMPLOYEEATTENDANCE_MAILQA '
			--set @sqlQry = 'SELECT TOP 10 * FROM FSM_ITC..TBL_MASTER_USER '

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
		-----------END Team Visit Report -----------------------


		

		fetch next from db_cursor_mail into @BranchId, @Branch, @Emailid
	end
	close db_cursor_mail
	deallocate db_cursor_mail


	
	

END
go
