IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIDELETEATTENDANCEINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIDELETEATTENDANCEINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIDELETEATTENDANCEINFO]
(
@ACTION NVARCHAR(50),
@USER_ID BIGINT=NULL,
@LEAVE_APPLY_DATE NVARCHAR(20)=NULL,
@ISONLEAVE NVARCHAR(10)=NULL,
--Rev 1.0
@ISLEAVEDELETE NCHAR(1)=NULL
--End of Rev 1.0
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 31/05/2022
Purpose : For Clear Attendance.Row: 689
1.0		v2.0.32		Debashis	09/08/2022		New table has been added.Row: 730
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='DELETELEAVEATTENDANCE'
		BEGIN
			DELETE FROM tbl_attendance_worktype WITH(TABLOCK) WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM tbl_attendance_Route WITH(TABLOCK) WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM FTS_Attendance_Target WITH(TABLOCK) WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE Attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM tbl_attendance_RouteShop WITH(TABLOCK) WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM FTS_Attendance_Target_Statewise WITH(TABLOCK) WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE Attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			--Rev 1.0
			IF @ISLEAVEDELETE='1'
				BEGIN
					DELETE FROM FTS_USER_LEAVEAPPLICATION WITH(TABLOCK) WHERE EXISTS (SELECT ATTEN.User_Id FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH(NOLOCK) 
					WHERE ATTEN.User_Id=FTS_USER_LEAVEAPPLICATION.USER_ID AND ATTEN.User_Id=@USER_ID AND CAST(ATTEN.Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE)) 
					AND FTS_USER_LEAVEAPPLICATION.LEAVE_START_DATE=@LEAVE_APPLY_DATE
				END
			--End of Rev 1.0

			DELETE FROM tbl_fts_UserAttendanceLoginlogout WITH(TABLOCK) WHERE User_Id=@user_id AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE

			IF NOT EXISTS(SELECT User_Id FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE User_Id=@user_id AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)
				SELECT 1
		END

	SET NOCOUNT OFF
END