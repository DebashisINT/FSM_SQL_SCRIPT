
-- exec PRC_SendTeamVisitReportAUtomail_DIS
-- EXEC PRC_FTSTEAMVISITATTENDANCE_REPORT_AUTOMAIL '2022-10-05','2022-10-10','122','','',378,1



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_SendTeamVisitReportAUtomail_DIS]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_SendTeamVisitReportAUtomail_DIS] AS'  
END 
GO

ALTER PROCEDURE [dbo].[PRC_SendTeamVisitReportAUtomail_DIS]
AS
/***************************************************************************************************************************************************
Written by : Sanchita on 20/05/2022. Auto Mail Feature for ITC Live
***************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

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
		set @FromDate =  DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -1, GETDATE())))
		set @ToDate =  convert(date, dateadd(DAY,-1,GETDATE()))
		set @ReportToDate =  convert(varchar, dateadd(DAY,-1,GETDATE()),105)
	end

	declare db_cursor_mail cursor for
	--SELECT Branch_Id, Branch_Description, EMAILID FROM FSM_ITC..TBL_VisitDetailsAutomail_DIS_TEST TV where EMAILID<>'' 
	SELECT Branch_Id, Branch_Description, EMAILID FROM FSM_ITC..TBL_VisitDetailsAutomail_DIS TV where EMAILID<>'' -- and id=12
	open db_cursor_mail
	fetch next from db_cursor_mail into @BranchId, @Branch, @Emailid
	while @@FETCH_STATUS=0
	begin

		-------------- Team Visit Report ---------------------
		DECLARE @sqlMailQry NVARCHAR(MAX)
		set @sqlMailQry = 'EXEC PRC_FTSTEAMVISITATTENDANCE_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE='''+@ToDate+''',@BRANCHID='''+@BranchId+''',@USERID=378,@SENDTOMAIL=1 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from EMPLOYEEATTENDANCE_MAIL)>0
		begin
			set @SubjectText = 'Team Visit Report_'+ @ReportToDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for Team Visit Report_'+ @ReportToDate
			set @filename = 'Team Visit Report_'+ @ReportToDate+'.csv'

			set @sqlQry = 'select * from FSM_ITC..EMPLOYEEATTENDANCE_MAIL '
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
			@query_result_width = 15000,
			@query_result_header=1;
		end

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'EMPLOYEEATTENDANCE_MAIL') AND TYPE IN (N'U'))
			DROP TABLE EMPLOYEEATTENDANCE_MAIL
		-----------END Team Visit Report -----------------------


		---------------- DS Visit Details_  -------------------

		set @sqlMailQry = 'EXEC PRC_FTSDSVISITDETAILS_REPORT_AUTOMAIL @FROMDATE='''+@FromDate+''',@TODATE='''+@ToDate+''',@BRANCHID='''+@BranchId+''',@USERID=378 '
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from FTSDSVISITDETAILS_REPORT_AUTOMAIL)>1
		begin
			set @SubjectText = 'DS Visit Details_'+ @ReportToDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for DS Visit Details__'+ @ReportToDate
			set @filename = 'DS Visit Details_'+ @ReportToDate+'.csv'

			--set @sqlQry = 'select ''Branch'',	''Circle'',	''AE ID'',	''WD ID'',	''DS ID'',	''DS Name'',	''DS Type'',	''Visit Date'',	''Outlets Mapped(Added)'',
			--			''Outlets Re-Visited'',	''Distance Travelled(Km.Mtr)'',	''Total time spent in the market(HH:MM)'',	''Day Start(HH:MM)'',
			--			''Day End(HH:MM)'',	''Avg time spent in OL(CFT-New&Revisit)(HH:MM)'' 
			--			union
			--			select BRANCHDESC AS Branch,CIRCLE AS Circle,HREPORTTOUID AS [AE ID],REPORTTOUID as [WD ID],EMPID as [DS ID],
			--			EMPNAME as [DS Name],DSTYPE as [DS Type], LOGIN_DATETIME as [Visit Date], convert(varchar(10), OUTLETSMAPPED) as [Outlets Mapped(Added)],
			--			convert(varchar(10),RE_VISITED) as [Outlets Re-Visited],convert(varchar(10),DISTANCE_TRAVELLED) as [Distance Travelled(Km.Mtr)],
			--			AVGTIMESPENTINMARKET as [Total time spent in the market(HH:MM)]	, DAYSTTIME as [Day Start(HH:MM)], DAYENDTIME as [Day End(HH:MM)],
			--			AVGSPENTDURATION as [Avg time spent in OL(CFT-New&Revisit)(HH:MM)] from FSM_ITC..FTSDSVISITDETAILS_REPORT_AUTOMAIL '
			set @sqlQry = 'select BRANCHDESC AS Branch,CIRCLE AS Circle,HREPORTTOUID AS [AE ID],REPORTTOUID as [WD ID],EMPID as [DS ID],
						EMPNAME as [DS Name],DSTYPE as [DS Type], LOGIN_DATETIME as [Visit Date], convert(varchar(10), OUTLETSMAPPED) as [Outlets Mapped(Added)],
						convert(varchar(10),RE_VISITED) as [Outlets Re-Visited],convert(varchar(10),DISTANCE_TRAVELLED) as [Distance Travelled(Km.Mtr)],
						AVGTIMESPENTINMARKET as [Total time spent in the market(HH:MM)]	, DAYSTTIME as [Day Start(HH:MM)], DAYENDTIME as [Day End(HH:MM)],
						AVGSPENTDURATION as [Avg time spent in OL(CFT-New&Revisit)(HH:MM)] from FSM_ITC..FTSDSVISITDETAILS_REPORT_AUTOMAIL '

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
			@query_result_width = 15000,
			@query_result_header=1;
		end
		---------------- End of DS Visit Details_  -------------------


		---------------- User Logout Status  -------------------

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'USER_LOGOUT_STATUS') AND TYPE IN (N'U'))
			DROP TABLE USER_LOGOUT_STATUS

		--set @sqlMailQry = 'select * into USER_LOGOUT_STATUS from (select ''Branch'' [Branch],	''Reported to'' [Reported to],	''User Login ID'' [User Login ID],	''Designation'' [Designation],	''User Group'' [User Group],	''Day End'' [Day End] union all '
		--set @sqlMailQry += 'select BR.branch_description [Branch], URepTo.user_name [Reported to],U.user_loginid [User Login ID],DG.deg_designation [Designation], '
		--set @sqlMailQry += '	G.grp_name [User Group] '
		--set @sqlMailQry += ',(case when (SELECT top 1 USER_ID  FROM FSM_ITC..FSMUSERWISEDAYSTARTEND WHERE USER_ID=DST.USER_ID AND convert(date,startenddate)=CONVERT(date, DATEADD(day,-1,getdate())) '
		--set @sqlMailQry += '	and ISEND=1 and remarks<>''''  ) is not null then ''0'' else ''1'' end) [Day End] '
		--set @sqlMailQry += ' from FSM_ITC..FSMUSERWISEDAYSTARTEND DST inner join tbl_master_user U on DST.USER_ID=U.user_id '
		--set @sqlMailQry += '	inner join tbl_master_branch BR on U.user_branchid=BR.branch_id '
		--set @sqlMailQry += '	inner join tbl_trans_employeeCTC CTC on CTC.emp_cntId=U.user_contactId '
		--set @sqlMailQry += '	inner join tbl_master_designation DG on DG.deg_id=ctc.emp_Designation '
		--set @sqlMailQry += '	inner join tbl_master_userGroup G on U.user_group = G.grp_id '
		--set @sqlMailQry += '	inner join tbl_master_employee ERepTo on ERepTo.emp_id=CTC.emp_reportTo '
		--set @sqlMailQry += '	inner join tbl_master_user URepTo on URepTo.user_contactId=ERepTo.emp_contactId '
		--set @sqlMailQry += ' where convert(date,DST.STARTENDDATE)= CONVERT(date, DATEADD(day,-1,getdate())) AND G.grp_name=''FIELD-USER'' and ISEND=1 '
		--set @sqlMailQry += '	and BR.branch_id in ('+@BranchId+')) A '
		--set @sqlMailQry += ' ORDER BY [User Login ID]  '
		set @sqlMailQry = 'select BR.branch_description [Branch], URepTo.user_name [Reported to],U.user_loginid [User Login ID],DG.deg_designation [Designation], '
		set @sqlMailQry += '	G.grp_name [User Group] '
		set @sqlMailQry += ',(case when (SELECT top 1 USER_ID  FROM FSM_ITC..FSMUSERWISEDAYSTARTEND WHERE USER_ID=DST.USER_ID AND convert(date,startenddate)=CONVERT(date, DATEADD(day,-1,getdate())) '
		set @sqlMailQry += '	and ISEND=1 and remarks<>''''  ) is not null then ''0'' else ''1'' end) [Day End] into USER_LOGOUT_STATUS '
		set @sqlMailQry += ' from FSM_ITC..FSMUSERWISEDAYSTARTEND DST inner join tbl_master_user U on DST.USER_ID=U.user_id '
		set @sqlMailQry += '	inner join tbl_master_branch BR on U.user_branchid=BR.branch_id '
		set @sqlMailQry += '	inner join tbl_trans_employeeCTC CTC on CTC.emp_cntId=U.user_contactId '
		set @sqlMailQry += '	inner join tbl_master_designation DG on DG.deg_id=ctc.emp_Designation '
		set @sqlMailQry += '	inner join tbl_master_userGroup G on U.user_group = G.grp_id '
		set @sqlMailQry += '	inner join tbl_master_employee ERepTo on ERepTo.emp_id=CTC.emp_reportTo '
		set @sqlMailQry += '	inner join tbl_master_user URepTo on URepTo.user_contactId=ERepTo.emp_contactId '
		set @sqlMailQry += ' where convert(date,DST.STARTENDDATE)= CONVERT(date, DATEADD(day,-1,getdate())) AND G.grp_name=''FIELD-USER'' and ISEND=1 '
		set @sqlMailQry += '	and BR.branch_id in ('+@BranchId+') ORDER BY DST.USER_ID  '
		
		EXEC SP_EXECUTESQL @sqlMailQry

		if (select count(0) from USER_LOGOUT_STATUS)>1
		begin
			set @SubjectText = 'User Logout Status_'+ @ReportToDate+ ' - for ' + ltrim(rtrim(@Branch))
			set @bodyText = 'Please find attached excel file for User Logout Status_'+ @ReportToDate
			set @filename = 'User Logout Status_'+ @ReportToDate+'.csv'

			set @sqlQry = 'select * from FSM_ITC..USER_LOGOUT_STATUS '
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
			@query_result_width = 15000,
			@query_result_header=1;
		end

		---------------- End of User Logout Status  -------------------

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
		-----------END QUALIFIED ATTENDANCE REPORT -----------------------

		fetch next from db_cursor_mail into @BranchId, @Branch, @Emailid
	end
	close db_cursor_mail
	deallocate db_cursor_mail


	SET NOCOUNT OFF
	

END
go
