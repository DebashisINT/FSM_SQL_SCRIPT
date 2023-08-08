
-- EXEC PRC_Send_FTSPERFORMANCESUMMARYMTD_AUTOMIL
-- EXEC PRC_FTSPERFORMANCESUMMARYMTD_REPORT_AUTOMIL @MONTH='JUL', @YEARS='2023', @USERID=378


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_Send_FTSPERFORMANCESUMMARYMTD_AUTOMIL]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_Send_FTSPERFORMANCESUMMARYMTD_AUTOMIL] AS'  
END 
GO

ALTER PROCEDURE [dbo].[PRC_Send_FTSPERFORMANCESUMMARYMTD_AUTOMIL]
AS
/***************************************************************************************************************************************************
Written by : Sanchita on 04/07/2023. Perofrmance Summary push mail configuration required for Honeywell. Refer: 26478
***************************************************************************************************************************************************/
BEGIN
	SET ANSI_WARNINGS off
	SET NOCOUNT ON

	DECLARE @tab char(1) = CHAR(9), @BranchId nvarchar(max), @Branch nvarchar(500), @Emailid nvarchar(max), @sqlQry nvarchar(max),
		-- @FromDate varchar(10), @ToDate varchar(10),
			@CurrentMonth varchar(10), @CurrentYear varchar(10),
			@SubjectText varchar(200), @bodyText varchar(200), @filename varchar(200), @ReportToDate varchar(10)

	--set @Emailid = 'sanchita.saha@indusnet.co.in'
	--set @Branch = '122'

	if(day(getdate()) = 1)
	begin
		-- first day of Previous Month to last day of previous month
		--set @FromDate =  convert(date, DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0))
		--set @ToDate =  convert(date, DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0)))
		set @CurrentMonth = format(getdate(),'MMM')
		set @CurrentYear = year(getdate())
		set @ReportToDate =  convert(varchar, DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0)),105)
	end
	else
	begin
		-- first day of Current Month to Previus day of current date
		--SET @FromDate = format(getdate(),'yyyy-MM')+'-01'
		--set @ToDate = format( dateadd(day,-1,getdate()),'yyyy-MM-dd')
		set @CurrentMonth = format(getdate(),'MMM')
		set @CurrentYear = year(getdate())
		set @ReportToDate = convert(varchar, format( dateadd(day,-1,getdate()),'dd-MM-yyyy') , 105)
	end

	
	declare db_cursor_mail cursor for
	select EMAILID from Honeywell.[dbo].TBL_PERFORMANCESUMMARYMTDAutomail
	open db_cursor_mail
	--fetch next from db_cursor_mail into @BranchId, @Branch, @Emailid
	fetch next from db_cursor_mail into @Emailid
	while @@FETCH_STATUS=0
	begin

		-------------- Team Visit Report ---------------------
		DECLARE @sqlMailQry NVARCHAR(MAX)
		set @sqlMailQry = 'EXEC Honeywell.[dbo].PRC_FTSPERFORMANCESUMMARYMTD_REPORT_AUTOMIL @MONTH='''+@CurrentMonth+''',@YEARS='''+@CurrentYear+''',@USERID=378 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from Honeywell.[dbo].PERFORMANCESUMMARY_MTD_MAIL)>0
		begin
			set @SubjectText = 'PERFORMANCE SUMMARY(MTD) REPORT AS ON '+ @ReportToDate
			set @bodyText = 'Please find attached excel file for PERFORMANCE SUMMARY(MTD) REPORT AS ON '+ @ReportToDate
			set @filename = 'PERFORMANCE SUMMARY MTD REPORT_'+ @ReportToDate+'.csv'

			set @sqlQry = 'SET NOCOUNT ON select * from Honeywell..PERFORMANCESUMMARY_MTD_MAIL '
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
		end

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'PERFORMANCESUMMARY_MTD_MAIL') AND TYPE IN (N'U'))
			DROP TABLE Honeywell..PERFORMANCESUMMARY_MTD_MAIL
		-----------END Team Visit Report -----------------------


		--fetch next from db_cursor_mail into @BranchId, @Branch, @Emailid
		fetch next from db_cursor_mail into @Emailid
	end
	close db_cursor_mail
	deallocate db_cursor_mail

	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON
	

END
go
