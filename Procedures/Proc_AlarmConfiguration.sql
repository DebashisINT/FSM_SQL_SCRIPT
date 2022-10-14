--exec Proc_AlarmConfiguration @user_id=2098   1691

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_AlarmConfiguration]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_AlarmConfiguration] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_AlarmConfiguration]
(
@user_id NVARCHAR(50)
) --WITH ENCRYPTION
AS
/********************************************************************************************************************************************************
1.0			Tanmoy			27-12-2019				union for plan alarm
********************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	declare @DesignationID NVARCHAR(50)=NULL
	DECLARE @IsShowPlanDetails BIT
	DECLARE @SQL NVARCHAR(MAX)

	SET @IsShowPlanDetails=(SELECT IsShowPlanDetails FROM tbl_master_user WITH(NOLOCK) WHERE user_id=@user_id)

	SET @DesignationID=(
	select  N.deg_id from tbl_master_user as musr WITH(NOLOCK) 
	INNER JOIN tbl_master_contact CNT WITH(NOLOCK) ON CNT.cnt_internalId = musr.user_contactId
	INNER JOIN (
	select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from 
	tbl_trans_employeeCTC as cnt WITH(NOLOCK) 
	left outer join tbl_master_designation as desg WITH(NOLOCK) on desg.deg_id=cnt.emp_Designation
	group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null
	)N
	on  N.emp_cntId=musr.user_contactId 
	where musr.user_id=@user_id)

	SET @SQL=' '
	SET @SQL+=' select id,alarm_time_hours,alarm_time_mins,report_id,ReportName as report_title '
	SET @SQL+='from tbl_FTS_AlermSettings WITH(NOLOCK) '
	SET @SQL+='inner join tbl_FTs_Report_Alarmsettings WITH(NOLOCK) on report_id=ReportID '
	SET @SQL+='where DesignationID='''+@DesignationID+''' AND tbl_FTs_Report_Alarmsettings.TYPE=''DESG'' AND tbl_FTs_Report_Alarmsettings.ISACTIVE=1  '-- order by createddate desc

	IF @IsShowPlanDetails=1
		BEGIN
			SET @SQL+='UNION ALL '
			SET @SQL+='select id,alarm_time_hours,alarm_time_mins,report_id,ReportName as report_title '
			SET @SQL+='from tbl_FTS_AlermSettings WITH(NOLOCK) '
			SET @SQL+='inner join tbl_FTs_Report_Alarmsettings WITH(NOLOCK) on report_id=ReportID  '
			SET @SQL+=' WHERE tbl_FTs_Report_Alarmsettings.TYPE=''ALL'' AND tbl_FTs_Report_Alarmsettings.ISACTIVE=1 '
		END

		--SELECT @SQL
	EXEC SP_EXECUTESQL @SQL

	SET NOCOUNT OFF
END
