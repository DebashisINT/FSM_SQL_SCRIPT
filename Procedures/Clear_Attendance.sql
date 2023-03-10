IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Clear_Attendance]') AND TYPE in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Clear_Attendance] AS' 
END
GO

ALTER PROCEDURE [dbo].[Clear_Attendance] 
(
@from varchar(15)=null,
@to varchar(15)=null,
@user_id varchar(25)=null
)
as
/*********************************************************************************************************************************************
Rev 1.0		Sanchita		10/03/2023		V2.0.39		Clear Attendance will clear the leave from all the tables for a particular employee
														Refer: 25728
*********************************************************************************************************************************************/
begin


			   DECLARE @StartDate AS DATETIME
			   DECLARE @EndDate AS DATETIME
				DECLARE @CurrentDate AS DATETIME
				DECLARE @count_i bigint=0
				SET @StartDate = cast(@from as DATE)
				SET @EndDate =	cast(@to as DATE)
				  --GETDATE()
				SET @CurrentDate = @StartDate

				WHILE (cast(@CurrentDate as date) <= cast(@EndDate as date))
				BEGIN

					delete from tbl_attendance_worktype where attendanceid in ( select id from tbl_fts_UserAttendanceLoginlogout where User_Id=@user_id and cast(Work_datetime as date)=cast(@CurrentDate as date))
					delete from tbl_attendance_Route where attendanceid in ( select id from tbl_fts_UserAttendanceLoginlogout where User_Id=@user_id and cast(Work_datetime as date)=cast(@CurrentDate as date))
					delete from FTS_Attendance_Target where Attendanceid in ( select id from tbl_fts_UserAttendanceLoginlogout where User_Id=@user_id and cast(Work_datetime as date)=cast(@CurrentDate as date))
					delete from tbl_attendance_RouteShop where attendanceid in ( select id from tbl_fts_UserAttendanceLoginlogout where User_Id=@user_id and cast(Work_datetime as date)=cast(@CurrentDate as date))
					delete from FTS_Attendance_Target_Statewise where Attendanceid in ( select id from tbl_fts_UserAttendanceLoginlogout where User_Id=@user_id and cast(Work_datetime as date)=cast(@CurrentDate as date))
					delete from tbl_fts_UserAttendanceLoginlogout where User_Id=@user_id and cast(Work_datetime as date)=cast(@CurrentDate as date)
					-- Rev 1.0
					delete from FTS_USER_LEAVEAPPLICATION where User_Id=@user_id and cast(CREATED_DATE as date)=cast(@CurrentDate as date)
					-- End of Rev 1.0

					SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate); /*increment current date*/

				END
end