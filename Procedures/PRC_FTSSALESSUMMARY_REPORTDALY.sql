--EXEC PRC_FTSSALESSUMMARY_REPORTDALY '2021-12-01','2021-12-31','','','',11706

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSSALESSUMMARY_REPORTDALY]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSSALESSUMMARY_REPORTDALY] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSSALESSUMMARY_REPORTDALY]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.13		Debashis	24/06/2020		Branch column required in the various FSM reports.Refer: 0022610
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #STATEID_LIST
	CREATE TABLE #STATEID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
	IF @STATEID <> ''
		BEGIN
			SET @STATEID=REPLACE(@STATEID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #STATEID_LIST SELECT id from tbl_master_state where id in('+@STATEID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	
	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DESIGNID <> ''
		BEGIN
			SET @DESIGNID=REPLACE(@DESIGNID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation where deg_id in('+@DESIGNID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
	(
		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		--Rev 1.0
		cnt_branchid INT,
		--End of Rev 1.0
		cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	--Rev 1.0
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	--End of Rev 1.0
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSSALESDETAILSDAYWISE_REPORT') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTSSALESDETAILSDAYWISE_REPORT
		(
		USERID INT,
		SEQ	INT,
		user_id	INT,
		cnt_internalId NVARCHAR(100) NULL,
		Employeename NVARCHAR(300) NULL,
		login_date	DATE,
		login_time	DATETIME,
		logout_time	DATETIME,
		duration NVARCHAR(10),
		state NVARCHAR(50) NULL,
		--Rev 1.0
		BRANCHDESC NVARCHAR(300),
		--End of Rev 1.0
		STATEID	INT,
		UserLogin NVARCHAR(50),
		Designation	NVARCHAR(50) NULL,
		deg_id INT,
		REPORTTO NVARCHAR(300) NULL,
		ATTEN_STATUS NVARCHAR(10),
		WORK_LEAVE_TYPE	NVARCHAR(2000) NULL,
		GPS_INACTIVE_DURATION NVARCHAR(50) NULL,
		IDEAL_TIME	NVARCHAR(50) NULL,
		IDEALTIME_CNT INT,
		UNDERTIME NVARCHAR(50) NULL,
		LATE_CNT NVARCHAR(10),
		shop_visited INT,
		Ordervalue	DECIMAL(38,2),
		collectionvalue	DECIMAL(38,2),
		cnt_UCC	NVARCHAR(100) NULL,
		Total_Hrs_Worked NVARCHAR(50) NULL
		)
		CREATE NONCLUSTERED INDEX IX14 ON FTSSALESDETAILSDAYWISE_REPORT (SEQ)
	END
	DELETE FROM FTSSALESDETAILSDAYWISE_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	SET @Strsql=' INSERT INTO FTSSALESDETAILSDAYWISE_REPORT'
	SET @Strsql+=' SELECT '+STR(@USERID)+' AS USERID ,ROW_NUMBER() OVER(ORDER BY cnt_internalId) AS SEQ,user_id,cnt_internalId,Employeename,login_date,login_time,logout_time, '--,Mintime,Maxtime
	SET @Strsql+=' RIGHT(''0'' + CAST(CAST(duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(duration AS VARCHAR) % 60 AS VARCHAR),2) AS duration,'
	--Rev 1.0
	--SET @Strsql+=' state,STATEID,UserLogin,Designation,deg_id,REPORTTO,ATTEN_STATUS,WORK_LEAVE_TYPE, '
	SET @Strsql+='state,BRANCHDESC,STATEID,UserLogin,Designation,deg_id,REPORTTO,ATTEN_STATUS,WORK_LEAVE_TYPE,'
	--End of Rev 1.0
	SET @Strsql+=' CASE WHEN GPS_Inactive_duration=''00:00'' THEN NULL ELSE GPS_Inactive_duration END as GPS_INACTIVE_DURATION, '
	SET @Strsql+=' IDEAL_TIME,convert(varchar(10),IDEALTIME_CNT) as IDEALTIME_CNT,'
	SET @Strsql+=' CASE WHEN WORK_TIME>0 THEN RIGHT(''0'' + CAST(CAST(WORK_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(WORK_TIME AS VARCHAR) % 60 AS VARCHAR),2) ELSE ''0'' END AS UNDERTIME, '
	SET @Strsql+=' LATE_CNT,ISNULL(shop_visited,0) AS shop_visited ,ISNULL(Ordervalue,0) AS Ordervalue,ISNULL(collectionvalue,0) AS collectionvalue,cnt_UCC, '
	SET @Strsql+=' CASE WHEN Total_Hrs_Worked>0 THEN RIGHT(''0'' + CAST(CAST(Total_Hrs_Worked AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(Total_Hrs_Worked AS VARCHAR) % 60 AS VARCHAR),2) ELSE ''Not Logged out'' END AS Total_Hrs_Worked '	
	SET @Strsql+='  FROM ( '
	SET @Strsql+=' SELECT shop_visited,Ordervalue,collectionvalue, '
	SET @Strsql+=' T.Mintime,T.Maxtime,USR.user_id ,CONT.cnt_UCC,CONT.cnt_internalId,cont.cnt_firstName+'' ''+cont.cnt_lastName as Employeename,LOginDate as login_date,T.LOGGEDIN as login_time,T.LOGEDOUT as logout_time,  '
	SET @Strsql+=' CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) ' 
	SET @Strsql+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS duration,  '
	--Rev 1.0
	--SET @Strsql+=' STAT.state,STAT.id AS STATEID,USR.user_loginId as UserLogin,N.deg_designation as Designation,N.deg_id,RPTTO.REPORTTO,T.ATTEN_STATUS,  '
	SET @Strsql+=' STAT.state,BR.branch_description AS BRANCHDESC,STAT.id AS STATEID,USR.user_loginId AS UserLogin,N.deg_designation AS Designation,N.deg_id,RPTTO.REPORTTO,T.ATTEN_STATUS,'
	--End of Rev 1.0
	SET @Strsql+=' CASE WHEN T.ATTEN_STATUS=''At Work'' THEN (SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(WRKACT.WrkActvtyDescription)) From tbl_fts_UserAttendanceLoginlogout AS ATTEN  '
	SET @Strsql+=' INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=ATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID AND CAST(T.SDate AS DATE)=CAST(ATTEN.Work_datetime AS DATE)  '
	SET @Strsql+=' INNER JOIN tbl_attendance_worktype ATTENWRKTYP ON ATTENWRKTYP.UserID=ATTEN.User_Id AND ATTEN.Id=ATTENWRKTYP.attendanceid   '
	SET @Strsql+=' INNER JOIN tbl_FTS_WorkActivityList WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID  '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120)  AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	SET @Strsql+=' AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' GROUP BY WRKACT.WrkActvtyDescription FOR XML PATH('''')), 1, 1, ''''),'''')) WHEN T.ATTEN_STATUS=''On Leave'' THEN  '
	SET @Strsql+=' ( '
	SET @Strsql+=' SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(LTYP.LeaveType)) From tbl_fts_UserAttendanceLoginlogout AS ATTEN   '
	SET @Strsql+=' INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=ATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID  '
	SET @Strsql+=' INNER JOIN tbl_FTS_Leavetype LTYP ON LTYP.Leave_Id=ATTEN.Leave_Type  '
	SET @Strsql+=' WHERE (CONVERT(NVARCHAR(10),Leave_FromDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	SET @Strsql+=' OR  CONVERT(NVARCHAR(10),Leave_ToDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120))  '
	SET @Strsql+=' AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' GROUP BY LTYP.LeaveType FOR XML PATH('''')), 1, 1, ''''),'''')) END AS WORK_LEAVE_TYPE,  '
	SET @Strsql+=' RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR) % 60 AS VARCHAR),2) AS GPS_Inactive_duration,  ' 
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS Total_Hrs_Worked,'
	SET @Strsql+=' CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)  '
	SET @Strsql+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)>0  THEN T.WORK_TIME  '
	SET @Strsql+=' -(CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT)  +CAST(DATEPART(MINUTE,ISNULL(T.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @Strsql+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT)  +CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)) ELSE T.WORK_TIME '
	SET @Strsql+=' -(CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(''23:59:00'',''00:00:00'')) * 60) AS FLOAT)  +CAST(DATEPART(MINUTE,ISNULL(''23:59:00'',''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)  '
	SET @Strsql+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(T.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT)  +CAST(DATEPART(MINUTE,ISNULL(T.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)) END AS WORK_TIME, '
	SET @Strsql+=' RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR) % 60 AS VARCHAR),2) AS IDEAL_TIME,  convert(INT,isnull(IDEAL_TIME/30,0)) AS IDEALTIME_CNT,  '
	SET @Strsql+=' CASE WHEN LTCNT.LATE_CNT=''Y'' THEN ''Late'' WHEN LTCNT.LATE_CNT=''L'' THEN ''On Leave'' ELSE ''On Time'' END AS LATE_CNT  from tbl_master_user as USR  '
	SET @Strsql+=' INNER JOIN (  '
	SET @Strsql+=' SELECT CONVERT(VARCHAR(15),CAST(MIN(A.Login_datetime) AS TIME),100) AS Mintime,CONVERT(VARCHAR(15),CAST(MAX(A.Logout_datetime) AS TIME),100) AS Maxtime,''At Work'' AS ATTEN_STATUS, '
	SET @Strsql+=' SA.User_id,MIN(A.Login_datetime) AS SDate,CAST(SA.SDate AS DATE) AS LOginDate,MIN(A.Login_datetime) AS LOGGEDIN,MAX(A.Logout_datetime) AS LOGEDOUT,MAX(EMPWHD.WORK_TIME) AS WORK_TIME '
	SET @Strsql+=' FROM TBL_TRANS_SHOPUSER_ARCH SA   '
	SET @Strsql+=' INNER JOIN tbl_fts_UserAttendanceLoginlogout A ON A.User_Id=SA.User_Id AND CAST(SA.SDate AS DATE)=CAST(A.Work_datetime AS DATE) AND A.Isonleave=''false''  '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id AND USR.user_inactive=''N''  '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId   '
	SET @Strsql+=' INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=CNT.cnt_internalId  '
	SET @Strsql+=' INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours   '
	SET @Strsql+=' INNER JOIN(  SELECT DISTINCT hourId,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EndTime),''00:00:00'')) * 60) AS FLOAT)  '
	SET @Strsql+=' + CAST(DATEPART(MINUTE,ISNULL(MIN(EndTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)   - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(BeginTime),''00:00:00'')) * 60) AS FLOAT)   '
	SET @Strsql+=' + CAST(DATEPART(MINUTE,ISNULL(MIN(BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS WORK_TIME FROM tbl_EmpWorkingHoursDetails GROUP BY hourId) EMPWHD ON EMPWHD.hourId=EMPWH.Id   '
	SET @Strsql+=' WHERE SA.LoginLogout=1  AND CONVERT(NVARCHAR(10),SA.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  GROUP BY SA.User_id,SA.LoginLogout, '
	SET @Strsql+=' CAST(SA.SDate AS DATE)  UNION ALL  SELECT CONVERT(VARCHAR(15),CAST(MIN(A.Login_datetime) AS TIME),100) AS Mintime,CONVERT(VARCHAR(15),CAST(MAX(A.Logout_datetime) AS TIME),100) AS Maxtime, '
	SET @Strsql+=' ''On Leave'' AS ATTEN_STATUS,  SA.User_id,MIN(A.Login_datetime) AS SDate,CAST(SA.SDate AS DATE) AS LOginDate, '
	SET @Strsql+=' MIN(A.Login_datetime) AS LOGGEDIN,MAX(A.Logout_datetime) AS LOGEDOUT,MAX(EMPWHD.WORK_TIME) AS WORK_TIME FROM TBL_TRANS_SHOPUSER_ARCH SA  '
	SET @Strsql+=' INNER JOIN tbl_fts_UserAttendanceLoginlogout A ON A.User_Id=SA.User_Id AND CAST(SA.SDate AS DATE)=CAST(A.Work_datetime AS DATE) AND A.Isonleave=''true''  '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id AND USR.user_inactive=''N''  '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId  '
	SET @Strsql+=' INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=CNT.cnt_internalId  '
	SET @Strsql+=' INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours  '
	SET @Strsql+=' INNER JOIN('
	SET @Strsql+=' SELECT DISTINCT hourId,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EndTime),''00:00:00'')) * 60) AS FLOAT)  + CAST(DATEPART(MINUTE,ISNULL(MIN(EndTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)  '
	SET @Strsql+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(BeginTime),''00:00:00'')) * 60) AS FLOAT)  + CAST(DATEPART(MINUTE,ISNULL(MIN(BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS WORK_TIME FROM tbl_EmpWorkingHoursDetails GROUP BY hourId) EMPWHD ON  '
	SET @Strsql+=' EMPWHD.hourId=EMPWH.Id   WHERE SA.LoginLogout=0  AND CONVERT(NVARCHAR(10),SA.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)   '
	SET @Strsql+=' GROUP BY SA.User_id,SA.LoginLogout,CAST(SA.SDate AS DATE)  )T ON USR.user_id=T.User_Id  '
	SET @Strsql+=' LEFT OUTER JOIN (  '
	SET @Strsql+=' SELECT USERID,LATE_CNT,LOGGEDIN FROM( SELECT A.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,  '
	SET @Strsql+=' CASE WHEN A.Isonleave=''TRUE'' THEN ''L'' WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL((Login_datetime),''00:00:00'')) * 60) AS FLOAT)  '
	SET @Strsql+=' + CAST(DATEPART(MINUTE,ISNULL((Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)>  CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT)  '
	SET @Strsql+=' +  CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) + MIN(EMPWHD.Grace) THEN ''Y'' ELSE ''N'' END LATE_CNT  FROM tbl_fts_UserAttendanceLoginlogout AS A  '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id  '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT EMP ON EMP.cnt_internalId=USR.user_contactId  '
	SET @Strsql+=' INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.cnt_internalId  '
	SET @Strsql+=' INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours  '
	SET @Strsql+=' INNER JOIN(  SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id  '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND A.Login_datetime IS NOT NULL  '
	SET @Strsql+=' AND A.Logout_datetime IS NULL GROUP BY A.User_Id,A.Login_datetime,A.Isonleave) A ) LTCNT ON LTCNT.USERID=USR.user_id AND CAST(T.SDATE AS DATE)=CAST(LTCNT.LOGGEDIN AS DATE)  '
	SET @Strsql+=' LEFT JOIN #TEMPCONTACT as CONT on USR.user_contactId=CONT.cnt_internalId '
	--Rev 1.0
	SET @Strsql+='LEFT OUTER JOIN tbl_master_branch BR ON CONT.cnt_branchid=BR.branch_id '
	--End of Rev 1.0
	SET @Strsql+=' LEFT OUTER JOIN ( '
	SET @Strsql+=' SELECT add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' )S on S.add_cntId=CONT.cnt_internalId   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state  '
	SET @Strsql+=' INNER JOIN (  '
	SET @Strsql+=' select cnt.emp_cntId,desg.deg_designation,deg_id,MAx(emp_id) as emp_id from tbl_trans_employeeCTC as cnt   '
	SET @Strsql+=' INNER JOIN tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation group by emp_cntId,desg.deg_designation,desg.deg_id )N ON USR.user_contactId= N.emp_cntId  '
	SET @Strsql+=' LEFT OUTER JOIN ( '
	SET @Strsql+=' SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO  '
	SET @Strsql+=' FROM tbl_master_employee EMP   '
	SET @Strsql+=' INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo   '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId   '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId ) RPTTO ON RPTTO.emp_cntId=CONT.cnt_internalId  '
	SET @Strsql+=' LEFT OUTER JOIN ( '
	SET @Strsql+=' SELECT GPS.User_Id,GPS.GPsDate,CNT.cnt_internalId,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(GPS.Duration,''00:00:00'')) * 60)) AS FLOAT)  '
	SET @Strsql+=' +CAST(SUM(DATEPART(MINUTE,ISNULL(GPS.Duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS GPS_Inactive_duration FROM tbl_FTS_GPSSubmission GPS  '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=GPS.User_Id  '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId  WHERE  '
	SET @Strsql+=' CONVERT(NVARCHAR(10),GPS.GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120)  AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	SET @Strsql+=' GROUP BY GPS.User_Id,CNT.cnt_internalId,GPS.GPsDate) GPSSM ON GPSSM.cnt_internalId=USR.user_contactId and cast(GPSSM.GPsDate as date)=LOginDate  '
	SET @Strsql+=' LEFT OUTER JOIN ( '
	SET @Strsql+=' SELECT user_id,SUM(IDEAL_TIME) AS IDEAL_TIME,CAST(start_ideal_date_time AS DATE) AS start_ideal_date_time FROM( '
	SET @Strsql+=' SELECT user_id,start_ideal_date_time,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(end_ideal_date_time,''00:00:00'')) * 60) AS FLOAT)  '
	SET @Strsql+=' + CAST(DATEPART(MINUTE,ISNULL(end_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)  '
	SET @Strsql+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(start_ideal_date_time,''00:00:00'')) * 60) AS FLOAT)  '
	SET @Strsql+=' + CAST(DATEPART(MINUTE,ISNULL(start_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME FROM FTS_Ideal_Loaction   '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) ) IDLE  '
	SET @Strsql+=' GROUP BY user_id,CAST(start_ideal_date_time AS DATE)) IDEALLOACTION  '
	SET @Strsql+=' ON IDEALLOACTION.user_id=USR.user_id AND CAST(T.SDATE AS DATE)=CAST(IDEALLOACTION.start_ideal_date_time AS DATE)  '
	SET @Strsql+=' LEFT OUTER JOIN ( '
	SET @Strsql+=' SELECT User_Id,Sum(shop_visited) AS shop_visited,datea FROM( '
	SET @Strsql+=' SELECT SHOPACT.User_Id,COUNT(SHOPACT.Shop_Id) AS shop_visited,cast(SHOPACT.visited_time as date)as datea FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id  '
	SET @Strsql+=' INNER JOIN (  '
	SET @Strsql+=' SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false''  '
	SET @Strsql+=' AND CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	SET @Strsql+=' )ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105)  '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	SET @Strsql+=' AND SHOPACT.Is_Newshopadd=1  '
	SET @Strsql+=' GROUP BY SHOPACT.User_Id,cast(SHOPACT.visited_time as date)  '
	SET @Strsql+=' UNION ALL  '
	SET @Strsql+=' SELECT SHOPACT.User_Id,COUNT(SHOPACT.Shop_Id) AS shop_visited,cast(visited_time as date)  FROM tbl_trans_shopActivitysubmit SHOPACT  '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id  '
	SET @Strsql+=' INNER JOIN (  '
	SET @Strsql+=' SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false''  '
	SET @Strsql+=' AND CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+=' GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105)  '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+=' AND SHOPACT.Is_Newshopadd=0 GROUP BY SHOPACT.User_Id,cast(visited_time as date)) SHOPACT GROUP BY SHOPACT.User_Id,SHOPACT.datea  '
	SET @Strsql+=' ) SHOPACST ON SHOPACST.User_Id=USR.user_id AND SHOPACST.datea=LOginDate '
	SET @Strsql+=' LEFT OUTER JOIN ( '
	SET @Strsql+=' SELECT ORDH.userID,SUM(ISNULL(Ordervalue,0)) AS Ordervalue,CAST(ORDH.Orderdate AS DATE) AS ORDDATE FROM tbl_trans_fts_Orderupdate ORDH  '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID  '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	SET @Strsql+=' GROUP BY ORDH.userID,CAST(ORDH.Orderdate AS DATE) '
	SET @Strsql+=' ) ORDHEAD ON USR.user_id=ORDHEAD.userID AND ORDHEAD.ORDDATE=LOginDate '
	SET @Strsql+=' LEFT OUTER JOIN ( '
	SET @Strsql+=' SELECT COLLEC.user_id,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue,CAST(COLLEC.collection_date AS DATE) AS COLDATE FROM tbl_FTS_collection COLLEC '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id  '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+=' GROUP BY COLLEC.user_id,CAST(COLLEC.collection_date AS DATE)  '
	SET @Strsql+=' ) COLLEC ON COLLEC.user_id=USR.user_id AND COLLEC.COLDATE=LOginDate  '
	SET @Strsql+=' WHERE LOginDate between '''+@FROMDATE+'''  AND '''+@TODATE+'''  '
	IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
		SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=STAT.id) '
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=N.deg_id) '
	ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CONT.cnt_internalId) '
	ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=STAT.id) '
			SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CONT.cnt_internalId) '
		END
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=N.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CONT.cnt_internalId) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=STAT.id) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=N.deg_id) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=STAT.id) '
			SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=N.deg_id) '
			SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CONT.cnt_internalId) '
		END
	SET @Strsql+='GROUP BY T.Mintime,T.Maxtime,USR.user_id,cont.cnt_firstName,T.LOGEDOUT,T.LOGGEDIN,T.WORK_TIME,GPSSM.GPS_Inactive_duration,IDEALLOACTION.IDEAL_TIME,LTCNT.LATE_CNT,  '
	SET @Strsql+='cont.cnt_lastName,T.SDate,LOginDate,STAT.state,USR.user_loginId,  N.deg_designation,RPTTO.REPORTTO,T.ATTEN_STATUS,shop_visited,Ordervalue,collectionvalue,cnt_UCC,STAT.id '
	SET @Strsql+=',N.deg_id,CONT.cnt_internalId,BR.branch_description '
	SET @Strsql+=') TAB   ORDER BY TAB.login_date  '

  --SELECT  @Strsql
  EXEC SP_EXECUTESQL @Strsql

  DROP TABLE #DESIGNATION_LIST
  DROP TABLE #EMPLOYEE_LIST
  DROP TABLE #STATEID_LIST
  DROP TABLE #TEMPCONTACT

  SET NOCOUNT OFF
END