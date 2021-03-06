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
@ISONLEAVE NVARCHAR(10)=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 31/05/2022
Purpose : For Clear Attendance.Row: 689
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='DELETELEAVEATTENDANCE'
		BEGIN
			DELETE FROM tbl_attendance_worktype WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM tbl_attendance_Route WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM FTS_Attendance_Target WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE Attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM tbl_attendance_RouteShop WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM FTS_Attendance_Target_Statewise WHERE EXISTS (SELECT id FROM tbl_fts_UserAttendanceLoginlogout WHERE Attendanceid=ID AND User_Id=@USER_ID 
			AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)

			DELETE FROM tbl_fts_UserAttendanceLoginlogout WHERE User_Id=@user_id AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE

			IF NOT EXISTS(SELECT * FROM tbl_fts_UserAttendanceLoginlogout WHERE User_Id=@user_id AND CAST(Work_datetime AS DATE)=CAST(@LEAVE_APPLY_DATE AS DATE) AND Isonleave=@ISONLEAVE)
				SELECT 1
		END

	SET NOCOUNT OFF
END