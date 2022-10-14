IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_ReportConfirm]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_ReportConfirm] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_ReportConfirm]
(
@user_id varchar(50),
@report_time varchar(50),
@view_time varchar(50),
@alarm_id varchar(50),
@report_id varchar(50)
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	insert into tbl_FTS_ReviewReportConfirm WITH(TABLOCK)(user_id,report_time,view_time,alarm_id,report_id,CreatedDate)
	values(@user_id,@report_time,@view_time,@alarm_id,@report_id,GETDATE())

	If(@@ROWCOUNT>0)
	select 'success'

	SET NOCOUNT OFF
END