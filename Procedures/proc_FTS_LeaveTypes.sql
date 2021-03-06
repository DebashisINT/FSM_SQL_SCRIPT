--EXEC proc_FTS_LeaveTypes 'LeaveList','2020-01-01','2020-12-01',11773

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[proc_FTS_LeaveTypes]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [proc_FTS_LeaveTypes] AS' 
END
GO

ALTER PROCEDURE [dbo].[proc_FTS_LeaveTypes]
(
@Action VARCHAR(50)=NULL,
@from_date VARCHAR(50)=NULL,
@to_date VARCHAR(50)=NULL,
@User_id VARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.30		Debashis	27/05/2022		From the BreezeFSM App, leave record is showing on applied date instead of leave start date.Refer: 0024915
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF(@Action='WorkTypes')
		BEGIN
			SELECT Leave_Id AS id,LeaveType AS type_name FROM tbl_FTS_Leavetype WHERE IsActive=1
		END
	ELSE IF(@Action='LeaveList')
		BEGIN
			--select CONVERT(VARCHAR(20),Id) id,
			--CONVERT(VARCHAR(10),Leave_FromDate,120) from_date,
			--CONVERT(VARCHAR(10),Leave_ToDate,120) to_date,
			--LeaveType leave_type,
			--ISNULL(LeaveReason,'') [desc] 
			--from tbl_fts_UserAttendanceLoginlogout
			--INNER JOIN tbl_FTS_Leavetype ON Leave_Id=Leave_Type
			-- where user_id=@user_id and 
			--cast(Work_datetime as date)>=cast(@from_date as date) and cast(Work_datetime as date)<=cast(@to_date as date)
			--and isonleave='true' AND Logout_datetime IS NULL
			--and isonleave='true' AND Logout_datetime IS NULL

			SELECT CONVERT(VARCHAR(20),Id) id,CONVERT(VARCHAR(10),LEAVE_START_DATE,120) from_date,CONVERT(VARCHAR(10),LEAVE_END_DATE,120) to_date,LeaveType leave_type,ISNULL(LEAVE_REASON,'') [desc],
			CASE WHEN ISNULL(CURRENT_STATUS,'')='PENDING' then 'Pending' WHEN CURRENT_STATUS='APPROVE' THEN 'Approved' ELSE 'Rejected' END status
			FROM FTS_USER_LEAVEAPPLICATION
			INNER JOIN tbl_FTS_Leavetype ON Leave_Id=Leave_Type
			WHERE user_id=@user_id  
			--Rev 1.0
			--AND cast(CREATED_DATE as date)>=cast(@from_date as date) and cast(CREATED_DATE as date)<=cast(@to_date as date)
			AND CAST(FTS_USER_LEAVEAPPLICATION.LEAVE_START_DATE AS date)>=CAST(@from_date AS date) AND CAST(FTS_USER_LEAVEAPPLICATION.LEAVE_START_DATE AS date)<=CAST(@to_date AS date)
			--End of Rev 1.0
		END

	SET NOCOUNT OFF
END