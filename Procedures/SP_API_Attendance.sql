--exec [SP_API_Attendance]  '0','','2019-08-01','2019-08-31'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SP_API_Attendance]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [SP_API_Attendance] AS' 
END
GO

ALTER PROCEDURE [dbo].[SP_API_Attendance]
(
@user_id NVARCHAR(50),
@session_token NVARCHAR(MAX)=NULL,
@start_date NVARCHAR(MAX)=NULL,
@end_date NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v28.0.0		Debashis	24/05/2019		Employee summary report is showing the attendance time which is also required in Attendance list report.
												Refer: Fwd: Attendance Report mismatch

2.0					Tanmoy		22/08/2019		Add Attendance type, Work/Leave type, Undertime, GPS Inactive Duration, Idle Time, Idle Time Count Column
												
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @logindate datetime=NULL
	DECLARE @logoutdate datetime=NULL
	DECLARE @logintime NVARCHAR(50)=NULL
	DECLARE @logouttime NVARCHAR(50)=NULL
	DECLARE @duration NVARCHAR(50)=NULL
	--if exists()
	--if(isnull(@start_date,'') ='' and isnull(@end_date,'')='')
	--	BEGIN
	--		declare @Sql nvarchar(MAX)

	--		select (select  Min(SDate)  from tbl_trans_shopuser where LoginLogout=1 and  User_Id=T.User_id and convert(date,SDate) =T.login_date)  as login_time, 
	--		(select  MAX(SDate)  from tbl_trans_shopuser where LoginLogout=0 and  User_Id=T.User_id and   convert(date,SDate) =T.login_date ) as logout_time ,
	--		User_id,T.login_date
	--		,(select FORMAT( Min(SDate),'hh:mm tt')   from tbl_trans_shopuser where LoginLogout=1  and User_Id=T.User_id and   convert(date,SDate) =T.login_date ) as Mintime
	--		,(select FORMAT( MAX(SDate),'hh:mm tt')  from tbl_trans_shopuser where LoginLogout=0  and User_Id=T.User_id  and convert(date,SDate) =T.login_date ) as Maxtime
	--		,(select FORMAT(Min(visited_time),'hh:mm tt')   from tbl_trans_shopActivitysubmit where User_Id=T.User_id and visited_date=T.login_date) as Minvisittime
	--		,(select FORMAT(Max(visited_time),'hh:mm tt')   from tbl_trans_shopActivitysubmit where User_Id=T.User_id and visited_date=T.login_date) as Maxvisittime
	--		,(select convert(varchar(5),DateDiff(s,  (select  Min(SDate)  from tbl_trans_shopuser where LoginLogout=1 and  User_Id=T.User_id  and convert(date,SDate) =T.login_date)
	--		,(select MAX(SDate)  from tbl_trans_shopuser where LoginLogout=0 and  User_Id=T.User_id  and convert(date,SDate) =T.login_date ))%86400/3600)+':'
	--		+convert(varchar(5),DateDiff(s,  (select  Min(SDate)  from tbl_trans_shopuser where LoginLogout=1 and  User_Id=T.User_id  and convert(date,SDate) =T.login_date )
	--		,(select MAX(SDate)  from tbl_trans_shopuser where LoginLogout=0 and  User_Id=T.User_id  and convert(date,SDate) =T.login_date ))%3600/60)+':'
	--		+convert(varchar(5),(DateDiff(s,  (select  MIn(SDate)  from tbl_trans_shopuser where LoginLogout=1 and  User_Id=T.User_id  and convert(date,SDate) =T.login_date )
	--		,(select  MAX(SDate)  from tbl_trans_shopuser where LoginLogout=0 and  User_Id=T.User_id and convert(date,SDate) =T.login_date ))%60))  )  as duration
	--		from
	--		(
	--		select User_id,convert(date,SDate) as login_date,SDate as Date 
	--		from tbl_trans_shopuser 
	--		where   convert(date,SDate) between  DateAdd(DAY,-15,convert(date,GETDATE())) and convert(date,GETDATE())
	--		)T group  by T.login_date,User_id order  by T.login_date desc
	--	END
	--ELSE
		BEGIN
			DECLARE @SqlSTR NVARCHAR(MAX)

			IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
				DROP TABLE #TEMPCONTACT
			CREATE TABLE #TEMPCONTACT
				(
					cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				)
			CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WITH(NOLOCK) WHERE cnt_contactType IN('EM')

			 SET @SqlSTR='SELECT Mintime,Maxtime,user_id,Employeename,login_date,login_time,logout_time, '
			 SET @SqlSTR+='RIGHT(''0'' + CAST(CAST(duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(duration AS VARCHAR) % 60 AS VARCHAR),2) AS duration,state,UserLogin,Designation,REPORTTO,ATTEN_STATUS,  '
			 SET @SqlSTR+='WORK_LEAVE_TYPE,CASE WHEN GPS_Inactive_duration=''00:00'' THEN NULL ELSE GPS_Inactive_duration END as GPS_INACTIVE_DURATION,IDEAL_TIME,convert(varchar(10),IDEALTIME_CNT) as IDEALTIME_CNT,  '
			 SET @SqlSTR+='CASE WHEN WORK_TIME>0 THEN RIGHT(''0'' + CAST(CAST(WORK_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(WORK_TIME AS VARCHAR) % 60 AS VARCHAR),2) ELSE ''0'' END AS UNDERTIME,LATE_CNT   '
			 SET @SqlSTR+='FROM (  '
			 SET @SqlSTR+='SELECT T.Mintime,T.Maxtime,USR.user_id ,cont.cnt_firstName+'' ''+cont.cnt_lastName as Employeename,LOginDate as login_date,T.LOGGEDIN as login_time,T.LOGEDOUT as logout_time,  '
			 SET @SqlSTR+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			 SET @SqlSTR+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS duration, '
			 SET @SqlSTR+='STAT.state,USR.user_loginId as UserLogin,N.deg_designation as Designation,RPTTO.REPORTTO,T.ATTEN_STATUS,'			
			 SET @SqlSTR+='CASE WHEN T.ATTEN_STATUS=''At Work'' THEN (SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(WRKACT.WrkActvtyDescription)) From tbl_fts_UserAttendanceLoginlogout AS ATTEN WITH(NOLOCK) '
			 SET @SqlSTR+='INNER JOIN tbl_master_user MUSR WITH(NOLOCK) ON MUSR.USER_ID=ATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID AND CAST(T.SDate AS DATE)=CAST(ATTEN.Work_datetime AS DATE) '
			 SET @SqlSTR+='INNER JOIN tbl_attendance_worktype ATTENWRKTYP WITH(NOLOCK) ON ATTENWRKTYP.UserID=ATTEN.User_Id AND ATTEN.Id=ATTENWRKTYP.attendanceid '
			 SET @SqlSTR+='INNER JOIN tbl_FTS_WorkActivityList WRKACT WITH(NOLOCK) ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@start_date+''',120) '
			 SET @SqlSTR+='AND CONVERT(NVARCHAR(10),'''+@end_date+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' GROUP BY WRKACT.WrkActvtyDescription FOR XML PATH('''')), 1, 1, ''''),'''')) '
			 SET @SqlSTR+='WHEN T.ATTEN_STATUS=''On Leave'' THEN (SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(LTYP.LeaveType)) From tbl_fts_UserAttendanceLoginlogout AS ATTEN WITH(NOLOCK) '
			 SET @SqlSTR+='INNER JOIN tbl_master_user MUSR WITH(NOLOCK) ON MUSR.USER_ID=ATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
			 SET @SqlSTR+='INNER JOIN tbl_FTS_Leavetype LTYP WITH(NOLOCK) ON LTYP.Leave_Id=ATTEN.Leave_Type WHERE (CONVERT(NVARCHAR(10),Leave_FromDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@start_date+''',120) AND CONVERT(NVARCHAR(10),'''+@end_date+''',120) '
			 SET @SqlSTR+='OR '
			 SET @SqlSTR+='CONVERT(NVARCHAR(10),Leave_ToDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@start_date+''',120) AND CONVERT(NVARCHAR(10),'''+@end_date+''',120)) '
			 SET @SqlSTR+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' GROUP BY LTYP.LeaveType FOR XML PATH('''')), 1, 1, ''''),'''')) END AS WORK_LEAVE_TYPE,'			
			 SET @SqlSTR+='RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR) % 60 AS VARCHAR),2) AS GPS_Inactive_duration,'
			 SET @SqlSTR+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			 SET @SqlSTR+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)>0 '
			 SET @SqlSTR+='THEN T.WORK_TIME-(CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+CAST(DATEPART(MINUTE,ISNULL(T.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)) ELSE T.WORK_TIME-(CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(''23:59:00'',''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+CAST(DATEPART(MINUTE,ISNULL(''23:59:00'',''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)) END AS WORK_TIME,'			
			 SET @SqlSTR+='RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR) % 60 AS VARCHAR),2) AS IDEAL_TIME,'
			 SET @SqlSTR+='CONVERT(INT,isnull(IDEAL_TIME/30,0)) AS IDEALTIME_CNT,CASE WHEN LTCNT.LATE_CNT=''Y'' THEN ''Late'' WHEN LTCNT.LATE_CNT=''L'' THEN ''On Leave'' ELSE ''On Time'' END AS LATE_CNT '
			 SET @SqlSTR+='FROM tbl_master_user as USR WITH(NOLOCK) '			
			 SET @SqlSTR+='INNER JOIN ('
			 SET @SqlSTR+='SELECT CONVERT(VARCHAR(15),CAST(MIN(A.Login_datetime) AS TIME),100) AS Mintime,CONVERT(VARCHAR(15),CAST(MAX(A.Logout_datetime) AS TIME),100) AS Maxtime,''At Work'' AS ATTEN_STATUS,'
			 SET @SqlSTR+='SA.User_id,MIN(A.Login_datetime) AS SDate,CAST(SA.SDate AS DATE) AS LOginDate,MIN(A.Login_datetime) AS LOGGEDIN,MAX(A.Logout_datetime) AS LOGEDOUT,MAX(EMPWHD.WORK_TIME) AS WORK_TIME FROM TBL_TRANS_SHOPUSER_ARCH SA WITH(NOLOCK) '
			 SET @SqlSTR+='INNER JOIN tbl_fts_UserAttendanceLoginlogout A WITH(NOLOCK) ON A.User_Id=SA.User_Id AND CAST(SA.SDate AS DATE)=CAST(A.Work_datetime AS DATE) AND A.Isonleave=''false'' '
			 SET @SqlSTR+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=A.User_Id AND USR.user_inactive=''N'' '
			 SET @SqlSTR+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			 SET @SqlSTR+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMPCTC.emp_cntId=CNT.cnt_internalId '
			 SET @SqlSTR+='INNER JOIN tbl_EmpWorkingHours EMPWH WITH(NOLOCK) ON EMPWH.Id=EMPCTC.emp_workinghours '
			 SET @SqlSTR+='INNER JOIN('
			 SET @SqlSTR+='SELECT DISTINCT hourId,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EndTime),''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+ CAST(DATEPART(MINUTE,ISNULL(MIN(EndTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			 SET @SqlSTR+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(BeginTime),''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+ CAST(DATEPART(MINUTE,ISNULL(MIN(BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS WORK_TIME FROM tbl_EmpWorkingHoursDetails WITH(NOLOCK) GROUP BY hourId) EMPWHD ON EMPWHD.hourId=EMPWH.Id  '
			 SET @SqlSTR+='WHERE SA.LoginLogout=1 '
			 SET @SqlSTR+='AND CONVERT(NVARCHAR(10),SA.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@start_date+''',120) AND CONVERT(NVARCHAR(10),'''+@end_date+''',120) '
			 SET @SqlSTR+='GROUP BY SA.User_id,SA.LoginLogout,CAST(SA.SDate AS DATE) '
			 SET @SqlSTR+='UNION ALL '
			 SET @SqlSTR+='SELECT CONVERT(VARCHAR(15),CAST(MIN(A.Login_datetime) AS TIME),100) AS Mintime,CONVERT(VARCHAR(15),CAST(MAX(A.Logout_datetime) AS TIME),100) AS Maxtime,''On Leave'' AS ATTEN_STATUS,'
			 SET @SqlSTR+='SA.User_id,MIN(A.Login_datetime) AS SDate,CAST(SA.SDate AS DATE) AS LOginDate,MIN(A.Login_datetime) AS LOGGEDIN,MAX(A.Logout_datetime) AS LOGEDOUT,MAX(EMPWHD.WORK_TIME) AS WORK_TIME FROM TBL_TRANS_SHOPUSER_ARCH SA WITH(NOLOCK) '
			 SET @SqlSTR+='INNER JOIN tbl_fts_UserAttendanceLoginlogout A WITH(NOLOCK) ON A.User_Id=SA.User_Id AND CAST(SA.SDate AS DATE)=CAST(A.Work_datetime AS DATE) AND A.Isonleave=''true'' ' 
			 SET @SqlSTR+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=A.User_Id AND USR.user_inactive=''N'' '
			 SET @SqlSTR+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			 SET @SqlSTR+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMPCTC.emp_cntId=CNT.cnt_internalId '
			 SET @SqlSTR+='INNER JOIN tbl_EmpWorkingHours EMPWH WITH(NOLOCK) ON EMPWH.Id=EMPCTC.emp_workinghours '
			 SET @SqlSTR+='INNER JOIN('
			 SET @SqlSTR+='SELECT DISTINCT hourId,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EndTime),''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+ CAST(DATEPART(MINUTE,ISNULL(MIN(EndTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			 SET @SqlSTR+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(BeginTime),''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+ CAST(DATEPART(MINUTE,ISNULL(MIN(BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS WORK_TIME FROM tbl_EmpWorkingHoursDetails WITH(NOLOCK) GROUP BY hourId) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			 SET @SqlSTR+='WHERE SA.LoginLogout=0 '
			 SET @SqlSTR+='AND CONVERT(NVARCHAR(10),SA.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@start_date+''',120) AND CONVERT(NVARCHAR(10),'''+@end_date+''',120) '
			 SET @SqlSTR+='GROUP BY SA.User_id,SA.LoginLogout,CAST(SA.SDate AS DATE) '
			 SET @SqlSTR+=')T ON USR.user_id=T.User_Id '			
			 SET @SqlSTR+='LEFT OUTER JOIN ('
			 SET @SqlSTR+='SELECT USERID,LATE_CNT,LOGGEDIN FROM('
			 SET @SqlSTR+='SELECT A.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,'
			 SET @SqlSTR+='CASE WHEN A.Isonleave=''TRUE'' THEN ''L'' WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL((Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL((Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
			 SET @SqlSTR+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + '
			 SET @SqlSTR+='CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) + MIN(EMPWHD.Grace) THEN ''Y'' ELSE ''N'' END LATE_CNT '
			 SET @SqlSTR+='FROM tbl_fts_UserAttendanceLoginlogout AS A WITH(NOLOCK) '
			 SET @SqlSTR+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=A.User_Id '
			 SET @SqlSTR+='INNER JOIN #TEMPCONTACT EMP ON EMP.cnt_internalId=USR.user_contactId '
			 SET @SqlSTR+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMPCTC.emp_cntId=EMP.cnt_internalId '
			 SET @SqlSTR+='INNER JOIN tbl_EmpWorkingHours EMPWH WITH(NOLOCK) ON EMPWH.Id=EMPCTC.emp_workinghours '
			 SET @SqlSTR+='INNER JOIN('
			 SET @SqlSTR+='SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails WITH(NOLOCK)) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			 SET @SqlSTR+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@start_date+''',120) AND CONVERT(NVARCHAR(10),'''+@end_date+''',120) '
			 SET @SqlSTR+='AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL '
			 SET @SqlSTR+='GROUP BY A.User_Id,A.Login_datetime,A.Isonleave) A ) LTCNT ON LTCNT.USERID=USR.user_id AND CAST(T.SDATE AS DATE)=CAST(LTCNT.LOGGEDIN AS DATE) '			
			 SET @SqlSTR+='LEFT JOIN #TEMPCONTACT as CONT on USR.user_contactId=CONT.cnt_internalId '
			 SET @SqlSTR+='LEFT OUTER JOIN (SELECT add_cntId,add_state FROM tbl_master_address WITH(NOLOCK) where add_addressType=''Office'')S on S.add_cntId=CONT.cnt_internalId '
			 SET @SqlSTR+='LEFT OUTER JOIN tbl_master_state as STAT WITH(NOLOCK) on STAT.id=S.add_state '
			 SET @SqlSTR+='INNER JOIN (select cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id from tbl_trans_employeeCTC as cnt WITH(NOLOCK) '
			 SET @SqlSTR+='INNER JOIN tbl_master_designation as desg WITH(NOLOCK) on desg.deg_id=cnt.emp_Designation group by emp_cntId,desg.deg_designation )N ON USR.user_contactId= N.emp_cntId '
			 SET @SqlSTR+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
			 SET @SqlSTR+='FROM tbl_master_employee EMP WITH(NOLOCK)  '
			 SET @SqlSTR+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo '
			 SET @SqlSTR+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			 SET @SqlSTR+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_contactId=EMP.emp_contactId ) RPTTO ON RPTTO.emp_cntId=CONT.cnt_internalId '			
			 SET @SqlSTR+='LEFT OUTER JOIN (SELECT GPS.User_Id,GPS.GPsDate,CNT.cnt_internalId,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(GPS.Duration,''00:00:00'')) * 60)) AS FLOAT) '
			 SET @SqlSTR+='+CAST(SUM(DATEPART(MINUTE,ISNULL(GPS.Duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS GPS_Inactive_duration FROM tbl_FTS_GPSSubmission GPS WITH(NOLOCK) '
			 SET @SqlSTR+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=GPS.User_Id '
			 SET @SqlSTR+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			 SET @SqlSTR+='WHERE CONVERT(NVARCHAR(10),GPS.GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@start_date+''',120) '
			 SET @SqlSTR+='AND CONVERT(NVARCHAR(10),'''+@end_date+''',120) GROUP BY GPS.User_Id,CNT.cnt_internalId,GPS.GPsDate) GPSSM ON GPSSM.cnt_internalId=USR.user_contactId AND cast(GPSSM.GPsDate as date)=LOginDate '
			 SET @SqlSTR+='LEFT OUTER JOIN (SELECT user_id,SUM(IDEAL_TIME) AS IDEAL_TIME,CAST(start_ideal_date_time AS DATE) AS start_ideal_date_time FROM('
			 SET @SqlSTR+='SELECT user_id,start_ideal_date_time,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(end_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+ CAST(DATEPART(MINUTE,ISNULL(end_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(start_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) '
			 SET @SqlSTR+='+ CAST(DATEPART(MINUTE,ISNULL(start_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME FROM FTS_Ideal_Loaction WITH(NOLOCK) '
			 SET @SqlSTR+='WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@start_date+''',120) AND CONVERT(NVARCHAR(10),'''+@end_date+''',120) ) IDLE GROUP BY user_id,CAST(start_ideal_date_time AS DATE)) '
			 SET @SqlSTR+='IDEALLOACTION ON IDEALLOACTION.user_id=USR.user_id AND CAST(T.SDATE AS DATE)=CAST(IDEALLOACTION.start_ideal_date_time AS DATE) '			
			 SET @SqlSTR+='WHERE LOginDate between '''+@start_date+'''  AND '''+@end_date+''' '
			 IF(ISNULL(@user_id,'0')<>'0')
				SET @SqlSTR+=' AND USR.user_id='+@user_id+' '
			 SET @SqlSTR+=' GROUP BY T.Mintime,T.Maxtime,USR.user_id,cont.cnt_firstName,T.LOGEDOUT,T.LOGGEDIN,T.WORK_TIME,GPSSM.GPS_Inactive_duration,IDEALLOACTION.IDEAL_TIME,LTCNT.LATE_CNT,'
			 SET @SqlSTR+=' cont.cnt_lastName,T.SDate,LOginDate,STAT.state,USR.user_loginId,N.deg_designation,RPTTO.REPORTTO,T.ATTEN_STATUS '
			 SET @SqlSTR+=' ) TAB ORDER BY TAB.login_date '
		
			--SELECT @SqlSTR
			EXEC sp_executeSQL @SqlSTR

			DROP TABLE #TEMPCONTACT
		END

	SET NOCOUNT OFF
END