--EXEC PRC_FTSATTENDANCEREGISTER_REPORT 'API','2018-04-05','2018-12-05','Summary',378
--EXEC PRC_FTSATTENDANCEREGISTER_REPORT 'PORTAL','2018-04-01','2018-12-04','Summary',378
--EXEC PRC_FTSATTENDANCEREGISTER_REPORT 'PORTAL','2018-12-24','2018-12-24','Detail',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSATTENDANCEREGISTER_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSATTENDANCEREGISTER_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSATTENDANCEREGISTER_REPORT]
(
@MODULETYPE NVARCHAR(50)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@ACTION NVARCHAR(50)=NULL,
@USERID INT=0
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 05/12/2018
Module	   : Attendance Register
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX)

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
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	IF @MODULETYPE='PORTAL' AND @ACTION IN('Summary','Detail')
		BEGIN
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSATTENDANCEREGISTER_REPORT') AND TYPE IN (N'U'))
			BEGIN
				CREATE TABLE FTSATTENDANCEREGISTER_REPORT
				(
				  USERID INT,
				  SEQ INT,
				  USRID INT,
				  ACTION NVARCHAR(50),
				  MODULETYPE NVARCHAR(50),
				  EMPCODE NVARCHAR(10) NULL,
				  EMPNAME NVARCHAR(100) NULL,
				  AT_WORK INT,
				  ON_LEAVE INT,
				  LATE_CNT INT,
				  CONTACTNO NVARCHAR(50),
				  RPTTOINTERNALID NVARCHAR(10) NULL,
				  EMP_REPORTTO INT,
				  RPTTOUSERID INT,
				  REPORTTO NVARCHAR(100) NULL,
				  DATE NVARCHAR(10),
				  LOGGEDIN NVARCHAR(50),
				  LOGEDOUT NVARCHAR(50),
				  STATUS NVARCHAR(50)
				)
				CREATE NONCLUSTERED INDEX IX1 ON FTSATTENDANCEREGISTER_REPORT (USERID)
			END
			DELETE FROM FTSATTENDANCEREGISTER_REPORT WHERE USERID=@USERID AND ACTION=@ACTION AND MODULETYPE=@MODULETYPE
		END

	SET @Strsql=''
	IF @MODULETYPE='API' AND @ACTION='Summary'
		BEGIN
			SET @Strsql='SELECT * FROM ('
			SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='CASE WHEN SUM(ATTENLILO.AT_WORK) IS NULL THEN 0 ELSE SUM(ATTENLILO.AT_WORK) END AS AT_WORK,CASE WHEN SUM(ATTENLILO.ON_LEAVE) IS NULL THEN 0 ELSE SUM(ATTENLILO.ON_LEAVE) END AS ON_LEAVE, '
			SET @Strsql+='COUNT(LATE_CNT) AS LATE_CNT,USR.user_loginId AS CONTACTNO,RPTTO.cnt_internalId,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(DISTINCT Isonleave) ELSE 0 END AS AT_WORK,CASE WHEN Isonleave=''true'' THEN COUNT(DISTINCT Isonleave) ELSE 0 END AS ON_LEAVE '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN (SELECT A.User_Id AS USERID,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS Login_datetime,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS BeginTime,'
			SET @Strsql+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) THEN COUNT(0) '
			SET @Strsql+='ELSE 0 END AS LATE_CNT FROM tbl_fts_UserAttendanceLoginlogout A '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
			SET @Strsql+='INNER JOIN(SELECT DISTINCT hourId,BeginTime FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY A.User_Id) ATTEN ON ATTEN.USERID=USR.user_id '
			SET @Strsql+='WHERE RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='AND USR.user_inactive=''N'' '
			SET @Strsql+='GROUP BY USR.user_id,CNT.cnt_internalId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_loginId,RPTTO.cnt_internalId,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO) AS ATTENREG '
			SET @Strsql+='ORDER BY AT_WORK DESC '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='SELECT USRID,EMPCODE,EMPNAME,DATE AS DATE,'
			SET @Strsql+='REPLACE(REPLACE(CONVERT(VARCHAR(15),CAST(RIGHT(''0'' + CAST(CAST(LOGGEDIN AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(LOGGEDIN AS VARCHAR) % 60 AS VARCHAR),2) AS TIME),100),''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,'
			SET @Strsql+='REPLACE(REPLACE(CONVERT(VARCHAR(15),CAST(RIGHT(''0'' + CAST(CAST(LOGEDOUT AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(LOGEDOUT AS VARCHAR) % 60 AS VARCHAR),2) AS TIME),100),''AM'','' AM''),''PM'','' PM'') AS LOGEDOUT,'
			SET @Strsql+='STATUS,CONTACTNO,RPTTOID,RPTTOCODE,REPORTTO FROM('
			SET @Strsql+='SELECT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ATTEN.TODAYDATE AS DATE,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS LOGGEDIN,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS LOGEDOUT,'
			SET @Strsql+='CASE WHEN ATTEN.STATUS IS NULL THEN ''Not Logged In'' ELSE ATTEN.STATUS END AS STATUS,USR.user_loginId AS CONTACTNO,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT ATTEN.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT,'
			SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' WHEN Isonleave=''true'' THEN ''On Leave'' END STATUS,CNT.cnt_internalId,CAST(ATTEN.Work_datetime AS DATE) AS TODAYDATE '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,Isonleave,CAST(ATTEN.Work_datetime AS DATE)) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND CONVERT(NVARCHAR(10),ATTEN.TODAYDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120)  AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND USR.user_inactive=''N'' '
			SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ATTEN.TODAYDATE,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT,ATTEN.STATUS,USR.user_loginId,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
			SET @Strsql+=') AS ATTEN ORDER BY ATTEN.EMPCODE,ATTEN.DATE '
			--SELECT @Strsql
			EXEC (@Strsql)
		END
	ELSE IF @MODULETYPE='PORTAL'
		BEGIN
			IF @ACTION='Summary'
				BEGIN
					SET @Strsql='INSERT INTO FTSATTENDANCEREGISTER_REPORT(USERID,SEQ,ACTION,MODULETYPE,USRID,EMPCODE,EMPNAME,AT_WORK,ON_LEAVE,LATE_CNT,CONTACTNO,RPTTOINTERNALID,EMP_REPORTTO,RPTTOUSERID,REPORTTO) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY AT_WORK DESC) AS SEQ,''Summary'' AS ACTION,''PORTAL'' AS MODULETYPE,* FROM ('
					SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					SET @Strsql+='CASE WHEN SUM(ATTENLILO.AT_WORK) IS NULL THEN 0 ELSE SUM(ATTENLILO.AT_WORK) END AS AT_WORK,CASE WHEN SUM(ATTENLILO.ON_LEAVE) IS NULL THEN 0 ELSE SUM(ATTENLILO.ON_LEAVE) END AS ON_LEAVE, '
					SET @Strsql+='COUNT(LATE_CNT) AS LATE_CNT,USR.user_loginId AS CONTACTNO,RPTTO.cnt_internalId,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(DISTINCT Isonleave) ELSE 0 END AS AT_WORK,CASE WHEN Isonleave=''true'' THEN COUNT(DISTINCT Isonleave) ELSE 0 END AS ON_LEAVE '
					SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL '
					SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
					SET @Strsql+='LEFT OUTER JOIN (SELECT A.User_Id AS USERID,'
					SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS Login_datetime,'
					SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS BeginTime,'
					SET @Strsql+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
					SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) THEN COUNT(0) '
					SET @Strsql+='ELSE 0 END AS LATE_CNT FROM tbl_fts_UserAttendanceLoginlogout A '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id '
					SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
					SET @Strsql+='INNER JOIN(SELECT DISTINCT hourId,BeginTime FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='GROUP BY A.User_Id) ATTEN ON ATTEN.USERID=USR.user_id '
					SET @Strsql+='WHERE RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+='AND USR.user_inactive=''N'' '
					SET @Strsql+='GROUP BY USR.user_id,CNT.cnt_internalId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_loginId,RPTTO.cnt_internalId,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO) AS ATTENREG '
					SET @Strsql+='ORDER BY AT_WORK DESC '
					--SELECT @Strsql
					EXEC (@Strsql)
				END
			ELSE IF @ACTION='Detail'
				BEGIN
					SET @Strsql=''
					SET @Strsql='INSERT INTO FTSATTENDANCEREGISTER_REPORT(USERID,SEQ,ACTION,MODULETYPE,USRID,EMPCODE,EMPNAME,DATE,LOGGEDIN,LOGEDOUT,STATUS,CONTACTNO,EMP_REPORTTO,RPTTOINTERNALID,RPTTOUSERID,REPORTTO) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY ATTEN.EMPCODE,ATTEN.DATE) AS SEQ,''Detail'' AS ACTION,''PORTAL'' AS MODULETYPE,USRID,EMPCODE,EMPNAME,CONVERT(VARCHAR(10),DATE,105) AS DATE,'
					SET @Strsql+='REPLACE(REPLACE(CONVERT(VARCHAR(15),CAST(RIGHT(''0'' + CAST(CAST(LOGGEDIN AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(LOGGEDIN AS VARCHAR) % 60 AS VARCHAR),2) AS TIME),100),''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,'
					SET @Strsql+='REPLACE(REPLACE(CONVERT(VARCHAR(15),CAST(RIGHT(''0'' + CAST(CAST(LOGEDOUT AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(LOGEDOUT AS VARCHAR) % 60 AS VARCHAR),2) AS TIME),100),''AM'','' AM''),''PM'','' PM'') AS LOGEDOUT,'
					SET @Strsql+='STATUS,CONTACTNO,RPTTOID,RPTTOCODE,RPTTOUSERID,REPORTTO FROM('
					SET @Strsql+='SELECT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ATTEN.TODAYDATE AS DATE,'
					SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS LOGGEDIN,'
					SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS LOGEDOUT,'
					SET @Strsql+='CASE WHEN ATTEN.STATUS IS NULL THEN ''Not Logged In'' ELSE ATTEN.STATUS END AS STATUS,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
					SET @Strsql+='FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					--SET @Strsql+='LEFT OUTER JOIN (SELECT ATTEN.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT,'
					--SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' WHEN Isonleave=''true'' THEN ''On Leave'' END STATUS,CNT.cnt_internalId,ATTEN.Work_datetime AS TODAYDATE '
					--SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
					--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
					--SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,Isonleave,ATTEN.Work_datetime) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
					SET @Strsql+='INNER JOIN (SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,STATUS,MAX(TODAYDATE) AS TODAYDATE FROM('
					SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,'
					SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' WHEN Isonleave=''true'' THEN ''On Leave'' END STATUS,ATTEN.Work_datetime AS TODAYDATE '
					SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
					SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave,ATTEN.Work_datetime '
					SET @Strsql+='UNION ALL '
					SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT,CNT.cnt_internalId,'
					SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' WHEN Isonleave=''true'' THEN ''On Leave'' END STATUS,ATTEN.Work_datetime AS TODAYDATE '
					SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
					SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave,ATTEN.Work_datetime '
					SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,STATUS) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
					SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND CONVERT(NVARCHAR(10),ATTEN.TODAYDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120)  AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND USR.user_inactive=''N'' '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ATTEN.TODAYDATE,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT,ATTEN.STATUS,USR.user_loginId,RPTTO.user_id,RPTTO.emp_reportTo,'
					SET @Strsql+='RPTTO.cnt_internalId,RPTTO.REPORTTO '
					SET @Strsql+=') AS ATTEN ORDER BY ATTEN.EMPCODE,ATTEN.DATE '
					--SELECT @Strsql
					EXEC (@Strsql)
				END
		END
	DROP TABLE #TEMPCONTACT
END