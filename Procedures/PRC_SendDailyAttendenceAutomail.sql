
-- exec PRC_SendDailyAttendenceAutomail

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_SendDailyAttendenceAutomail]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_SendDailyAttendenceAutomail] AS'  
END 
GO

ALTER PROCEDURE [dbo].[PRC_SendDailyAttendenceAutomail]
AS
/***************************************************************************************************************************************************
Written by : Sanchita on 20/05/2022. Auto Mail Feature for ITC Live
***************************************************************************************************************************************************/
BEGIN
	DECLARE @tab char(1) = CHAR(9), @Branch nvarchar(500), @Emailid nvarchar(max), @sqlQry nvarchar(max)


	declare db_cursor cursor for
	select Branch_description, EMAILID from TBL_DailyAttendenceAutomail where EMAILID<>'' 	open db_cursor
	fetch next from db_cursor into @Branch, @Emailid
	while @@FETCH_STATUS=0
	begin

		set @sqlQry = 'select BR.branch_description [BRANCH], EMP_RPTO.emp_uniqueCode [WD Code], format(getdate(),''dd/MM/yyyy'') [Date],  CH.ch_Channel  [Channel Type(DS/TL)], '
		set @sqlQry += 'isnull(FS.Stage,'''') [DS Type], EMP.emp_uniqueCode [DS ID/TL ID], '
		set @sqlQry += 'CONT.cnt_firstName+cnt_middleName+cnt_lastName [DS/TL Name] , '
		set @sqlQry += '(case when (select top 1 STARTENDDATE from FSM_ITC..FSMUSERWISEDAYSTARTEND where user_id=USR.user_id and convert(date,STARTENDDATE)=convert(date,getdate()) ) is not null '
		set @sqlQry += 'then ''1'' else ''0'' end) [Attedance Marked] '
						set @sqlQry += 'from FSM_ITC..tbl_trans_employeeCTC CTC '
						set @sqlQry += 'inner join FSM_ITC..tbl_master_designation desig on CTC.emp_Designation = desig.deg_id '
						set @sqlQry += 'inner join FSM_ITC..tbl_master_employee EMP on EMP.emp_contactId=CTC.emp_cntId '
						set @sqlQry += 'inner join FSM_ITC..tbl_master_contact CONT on CONT.cnt_UCC=EMP.emp_uniqueCode '
						set @sqlQry += 'left outer join FSM_ITC..Employee_ChannelMap CHMAP on CHMAP.EP_EMP_CONTACTID=CTC.emp_cntId '
						set @sqlQry += 'left outer join FSM_ITC..Employee_Channel CH on CH.ch_id=CHMAP.EP_CH_ID '
						set @sqlQry += 'inner join FSM_ITC..tbl_master_employee EMP_RPTO on EMP_RPTO.emp_id=CTC.emp_reportTo '
						set @sqlQry += 'inner join FSM_ITC..tbl_master_user USR on USR.user_contactid = CTC.emp_cntId '
						set @sqlQry += 'inner join FSM_ITC..tbl_master_branch BR on BR.branch_id = CTC.emp_branch '
						set @sqlQry += 'left outer join FSM_ITC..FTS_Stage FS on FS.StageID=USR.FaceRegTypeID '
		set @sqlQry += 'where desig.deg_designation in (''DS'',''TL'') and USR.user_inactive=''N'' '
		set @sqlQry += 'and BR.branch_description = ''' + @Branch +''''

		EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'BreezeERP',  
		@recipients = @Emailid,  
		@body = 'Please find the attached file with Last Backup Details.',  
		@subject = 'CSV File attached with Last Backup Details.' ,  
		@query = @sqlQry ,

		@attach_query_result_as_file = 1,
		@query_attachment_filename='filename1.csv',
		@query_result_separator=@tab,
		@query_result_no_padding=1


		fetch next from db_cursor into @Branch, @Emailid
	end
	close db_cursor
	deallocate db_cursor


	
	

END
go
