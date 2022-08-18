IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_DeleteAttendanceLeve]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_DeleteAttendanceLeve] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_DeleteAttendanceLeve]
(
@ACTION NVARCHAR(50),
@USER_ID BIGINT=NULL
--@LEAVE_APPLY_DATE NVARCHAR(20)=NULL
--@ISONLEAVE NVARCHAR(10)=NULL,
----Rev 1.0
--@ISLEAVEDELETE NCHAR(1)=NULL
----End of Rev 1.0
) WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Pratik Ghosh On 18/08/2022
Purpose : For Clear Attendance from portal.refer: 25116
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='DELETELEAVEATTENDANCE'
		BEGIN
			DELETE FROM tbl_attendance_worktype WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) )
			--AND Isonleave=@ISONLEAVE)

			DELETE FROM tbl_attendance_Route WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) )
			--AND Isonleave=@ISONLEAVE)

			DELETE FROM FTS_Attendance_Target WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE Attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) )
			--AND Isonleave=@ISONLEAVE)

			DELETE FROM tbl_attendance_RouteShop WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) )
			--AND Isonleave=@ISONLEAVE)

			DELETE FROM FTS_Attendance_Target_Statewise WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE Attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) )
			--AND Isonleave=@ISONLEAVE)

			--Rev 1.0
			--IF @ISLEAVEDELETE='1'
			--	BEGIN
			--		DELETE FROM FTS_USER_LEAVEAPPLICATION WHERE EXISTS (SELECT ATTEN.User_Id FROM tbl_fts_UserAttendanceLoginlogout ATTEN WHERE ATTEN.User_Id=FTS_USER_LEAVEAPPLICATION.USER_ID 
			--		AND ATTEN.User_Id=@USER_ID AND CAST(ATTEN.Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE)) AND FTS_USER_LEAVEAPPLICATION.LEAVE_START_DATE=@LEAVE_APPLY_DATE
			--	END
			--End of Rev 1.0
			DELETE FROM FTS_USER_LEAVEAPPLICATION WHERE EXISTS (SELECT ATTEN.User_Id FROM tbl_fts_UserAttendanceLoginlogout ATTEN WHERE ATTEN.User_Id=FTS_USER_LEAVEAPPLICATION.USER_ID 
					AND ATTEN.User_Id=@USER_ID AND CAST(ATTEN.Work_datetime AS DATE)=CAST(GETDATE() AS DATE)) AND CAST(FTS_USER_LEAVEAPPLICATION.LEAVE_START_DATE as DATE)=CAST(GETDATE() as Date)

			DELETE FROM tbl_fts_UserAttendanceLoginlogout WHERE User_Id=@user_id AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) 
			--AND Isonleave=@ISONLEAVE

			IF NOT EXISTS(SELECT * FROM tbl_fts_UserAttendanceLoginlogout WHERE User_Id=@user_id AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) ) SELECT 1
			--AND Isonleave=@ISONLEAVE)
				
		END

	SET NOCOUNT OFF
END