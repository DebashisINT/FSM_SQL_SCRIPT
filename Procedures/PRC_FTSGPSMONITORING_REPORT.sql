--EXEC [PRC_FTSGPSMONITORING_REPORT] 'API','2018-12-01','2018-12-05','0','Summary',378
--EXEC PRC_FTSGPSMONITORING_REPORT 'PORTAL','2018-12-03','2018-12-06','0','Summary',378
--EXEC PRC_FTSGPSMONITORING_REPORT 'PORTAL','2018-12-03','2018-12-06','0','Detail',378
--EXEC [PRC_FTSGPSMONITORING_REPORT] 'API','2018-12-07','2018-12-07','378','Summary',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSGPSMONITORING_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSGPSMONITORING_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSGPSMONITORING_REPORT]
(
@MODULETYPE NVARCHAR(50)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@USERLIST NVARCHAR(MAX)=NULL,
@ACTION NVARCHAR(50)=NULL,
@USERID INT=0
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 29/11/2018
Module	   : GPS Monitoring
REV NO.		DATE			VERSION			DEVELOPER			CHANGES										           	INSTRUCTED BY
-------		----			-------			---------			-------											        -------------					
1.0			03-12-2018		V 1.0.70		SUDIP PAL			Minus value showing									
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#USERID_LIST') AND TYPE IN (N'U'))
		DROP TABLE #USERID_LIST
	CREATE TABLE #USERID_LIST (user_id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #USERID_LIST (user_id ASC)
	IF @USERLIST <> ''
		BEGIN
			SET @USERLIST=REPLACE(@USERLIST,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #USERID_LIST SELECT user_id from tbl_master_user where user_id in('+@USERLIST+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	
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
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSGPSMONITORING_REPORT') AND TYPE IN (N'U'))
			BEGIN
				CREATE TABLE FTSGPSMONITORING_REPORT
				(
				  USERID INT,
				  USRID INT,
				  ACTION NVARCHAR(50),
				  MODULETYPE NVARCHAR(50),
				  USERNAME NVARCHAR(80) NULL,
				  DATE NVARCHAR(10),
				  CONTACTNO NVARCHAR(50) NULL,
				  ACTIVE_HRS NVARCHAR(50) NULL,
				  INACTIVE_HRS NVARCHAR(50) NULL,
				  IDLE_PERCENTAGE NVARCHAR(50) NULL,
				  GPS_OFF_TIME NVARCHAR(50) NULL,
				  GPS_ON_TIME NVARCHAR(50) NULL,
				  DURATION NVARCHAR(50) NULL
				)
				CREATE NONCLUSTERED INDEX IX1 ON FTSGPSMONITORING_REPORT (USERID)
			END
			DELETE FROM FTSGPSMONITORING_REPORT WHERE USERID=@USERID AND ACTION=@ACTION AND MODULETYPE=@MODULETYPE
		END

	SET @Strsql=''
	IF @MODULETYPE='API' AND @ACTION='Summary'
		BEGIN
			SET @Strsql='SELECT USRID,cnt_internalId,name,contact_no,RIGHT(''0'' + CAST(CAST(CASE WHEN active_hrs=0 THEN 1 ELSE active_hrs END AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(CASE WHEN active_hrs=0 THEN 1 ELSE active_hrs END AS VARCHAR) % 60 AS VARCHAR),2) AS active_hrs,'
			SET @Strsql+='RIGHT(''0'' + CAST(CAST(CASE WHEN inactive_hrs=0 THEN 1 ELSE inactive_hrs END AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(CASE WHEN inactive_hrs=0 THEN 1 ELSE inactive_hrs END AS VARCHAR) % 60 AS VARCHAR),2) AS inactive_hrs,ROUND(idle_percentage,2) AS idle_percentage FROM( '
			SET @Strsql+='SELECT USRID,cnt_internalId,name,contact_no,SUM(active_hrs) AS active_hrs,inactive_hrs,SUM(idle_percentage) AS idle_percentage,RPTTOID,emp_reportTo,user_id,REPORTTO FROM('
			SET @Strsql+='SELECT USR.user_id AS USRID,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS name,USR.user_loginId AS contact_no,'
			--SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			--SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS active_hrs,'
			SET @Strsql+='active_hrs,GPSSM.Duration AS inactive_hrs,'
			--SET @Strsql+='CASE WHEN (CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) + '
			--SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) + '
			--SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT))=0 THEN 1 ELSE '
			--SET @Strsql+='(CAST(GPSSM.Duration AS FLOAT)/ (CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 60) '
			--SET @Strsql+='AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) '
			--SET @Strsql+='+CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT))) * 100 END AS idle_percentage, '
			SET @Strsql+='CASE WHEN active_hrs=0 THEN 1 ELSE (CAST(GPSSM.Duration AS FLOAT)/active_hrs) * 100 END AS idle_percentage,'
			SET @Strsql+='RPTTO.cnt_internalId AS RPTTOID,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO '
			--SET @Strsql+='FROM tbl_master_user USR '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			--SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT FROM tbl_fts_UserAttendanceLoginlogout '
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			----Ref 1.o added having MAX(Logout_datetime) is not null
			--SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime as date) HAVING MAX(Logout_datetime) IS NOT NULL) AS ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			----Ref 1.o added having MAX(Logout_datetime) is not null	
			--SET @Strsql+='INNER JOIN ('
			--SET @Strsql+='SELECT USERID,SUM(active_hrs) AS active_hrs FROM( '
			--SET @Strsql+='SELECT User_Id AS USERID,CAST(CONVERT(VARCHAR,Min(Work_datetime),102) AS DATETIME)  as login_date,Min(Work_datetime) as login_time,Max(Work_datetime) as logout_date,MAX(Work_datetime) as logout_time,'
			--SET @Strsql+='CAST(CAST(ISNULL(CAST((MAX(DATEPART(HOUR,ISNULL(Work_datetime,''00:00:00'')) * 60)) AS FLOAT) +CAST(MAX(DATEPART(MINUTE,ISNULL(Work_datetime,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100))  AS FLOAT) - '
			--SET @Strsql+='CAST(CAST(ISNULL(CAST((MIN(DATEPART(HOUR,ISNULL(Work_datetime,''00:00:00'')) * 60)) AS FLOAT) +CAST(MIN(DATEPART(MINUTE,ISNULL(Work_datetime,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100))  AS FLOAT) AS active_hrs '
		    --SET @Strsql +='CONVERT(varchar(5),(MAX(Work_datetime)-MIN(Work_datetime)), 108) AS active_hrs '
			--SET @Strsql +='CAST(CONVERT(varchar(10),(MAX(Work_datetime)-MIN(Work_datetime)), 108) AS VARCHAR(100)) AS active_hrs '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT USERID,CAST(CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(active_hrs,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(active_hrs,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS active_hrs FROM( '
			SET @Strsql+='SELECT User_Id AS USERID, CONVERT(varchar(5),(MAX(Work_datetime)-MIN(Work_datetime)), 108) AS active_hrs '		
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE) HAVING MAX(Logout_datetime) IS NOT NULL '
			SET @Strsql+=') BB GROUP BY USERID '
			SET @Strsql+=') AS ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='INNER JOIN (SELECT User_Id,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(Duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(Duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS Duration '
			SET @Strsql+='FROM tbl_FTS_GPSSubmission WHERE CONVERT(NVARCHAR(10),GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) GROUP BY User_Id) GPSSM ON GPSSM.User_Id=USR.user_id '
			--IF (@USERLIST<>'' AND @USERLIST<>'0')
				--SET @Strsql+='WHERE EXISTS (SELECT user_id FROM #USERID_LIST AS US WHERE US.user_id=USR.USER_ID) '
			SET @Strsql+='WHERE RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+=') AS AAA GROUP BY USRID,cnt_internalId,name,contact_no,inactive_hrs,RPTTOID,emp_reportTo,user_id,REPORTTO '
			SET @Strsql+=') GPSSUMMARY ORDER BY USRID '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='SELECT USRID,name,date,gps_off_time,gps_on_time,RIGHT(''0'' + CAST(duration / 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(duration % 60 AS VARCHAR),2) AS duration FROM( '
			SET @Strsql+='SELECT USR.user_id AS USRID,USR.user_name AS name,CONVERT(NVARCHAR(10),GPSSM.GPsDate,120) AS date,GPSSM.Gps_OffTime AS gps_off_time,GPSSM.Gps_on_Time AS gps_on_time, '
			SET @Strsql+='CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(GPSSM.Duration,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(GPSSM.Duration,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS duration '
			--SET @Strsql+='FROM tbl_master_user USR '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			--SET @Strsql+='INNER JOIN tbl_FTS_GPSSubmission GPSSM ON GPSSM.User_Id=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT User_Id,GPsDate,Gps_OffTime,Gps_on_Time,Duration FROM tbl_FTS_GPSSubmission '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) GROUP BY User_Id,GPsDate,Gps_OffTime,Gps_on_Time,Duration) GPSSM ON GPSSM.User_Id=USR.user_id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),GPSSM.GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			--IF (@USERLIST<>'' AND @USERLIST<>'0')
			--	SET @Strsql+='AND EXISTS (SELECT user_id FROM #USERID_LIST AS US WHERE US.user_id=USR.USER_ID) '
			--SET @Strsql+='AND USR.USER_ID='+STR(@USERID)+' '
			SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+=') AS GPSDET ORDER BY USRID '
			--SELECT @Strsql
			EXEC (@Strsql)
		END
	ELSE IF @MODULETYPE='PORTAL'
		BEGIN
			IF @ACTION='Summary'
				BEGIN
					SET @Strsql='INSERT INTO FTSGPSMONITORING_REPORT(USERID,USRID,ACTION,MODULETYPE,USERNAME,CONTACTNO,ACTIVE_HRS,INACTIVE_HRS,IDLE_PERCENTAGE) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,USRID,''Summary'' AS ACTION,''PORTAL'' AS MODULETYPE,name,contact_no,RIGHT(''0'' + CAST(CAST(active_hrs AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(active_hrs AS VARCHAR) % 60 AS VARCHAR),2) AS active_hrs,'
					SET @Strsql+='RIGHT(''0'' + CAST(CAST(inactive_hrs AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(inactive_hrs AS VARCHAR) % 60 AS VARCHAR),2) AS inactive_hrs,ROUND(idle_percentage,2) AS idle_percentage FROM( '
					SET @Strsql+='SELECT USRID,cnt_internalId,name,contact_no,SUM(active_hrs) AS active_hrs,inactive_hrs,SUM(idle_percentage) AS idle_percentage,RPTTOID,emp_reportTo,user_id,REPORTTO FROM('
					SET @Strsql+='SELECT USR.user_id AS USRID,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS name,USR.user_loginId AS contact_no,'
					--SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
					--SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS active_hrs,'
					SET @Strsql+='active_hrs,GPSSM.Duration AS inactive_hrs,'
					--SET @Strsql+='CASE WHEN (CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) + '
					--SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) + '
					--SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT))=0 THEN 1 ELSE '
					--SET @Strsql+='(CAST(GPSSM.Duration AS FLOAT)/ (CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 60) '
					--SET @Strsql+='AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) '
					--SET @Strsql+='+CAST(DATEPART(MINUTE,ISNULL(ATTENLILO.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT))) * 100 END AS idle_percentage, '
					SET @Strsql+='CASE WHEN active_hrs=0 THEN 1 ELSE (CAST(GPSSM.Duration AS FLOAT)/active_hrs) * 100 END AS idle_percentage,'
					SET @Strsql+='RPTTO.cnt_internalId AS RPTTOID,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO '
					SET @Strsql+='FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					--SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT FROM tbl_fts_UserAttendanceLoginlogout '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime as date) HAVING MAX(Logout_datetime) IS NOT NULL) AS ATTENLILO ON ATTENLILO.USERID=USR.user_id '
					SET @Strsql+='INNER JOIN ('
					SET @Strsql+='SELECT USERID,SUM(active_hrs) AS active_hrs FROM( '
					SET @Strsql+='SELECT User_Id AS USERID,CAST(CONVERT(VARCHAR,Min(Work_datetime),102) AS DATETIME)  as login_date,Min(Work_datetime)  as login_time,Max(Work_datetime) as logout_date,MAX(Work_datetime) as logout_time,'
					SET @Strsql+='CAST(CAST(ISNULL(CAST((MAX(DATEPART(HOUR,ISNULL(Work_datetime,''00:00:00'')) * 60)) AS FLOAT) +CAST(MAX(DATEPART(MINUTE,ISNULL(Work_datetime,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100))  AS FLOAT) - '
					SET @Strsql+='CAST(CAST(ISNULL(CAST((MIN(DATEPART(HOUR,ISNULL(Work_datetime,''00:00:00'')) * 60)) AS FLOAT) +CAST(MIN(DATEPART(MINUTE,ISNULL(Work_datetime,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100))  AS FLOAT) AS active_hrs '
					SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE) HAVING MAX(Logout_datetime) IS NOT NULL '
					SET @Strsql+=') BB GROUP BY USERID '
					SET @Strsql+=') AS ATTENLILO ON ATTENLILO.USERID=USR.user_id '
					SET @Strsql+='INNER JOIN (SELECT User_Id,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(Duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(Duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS Duration '
					SET @Strsql+='FROM tbl_FTS_GPSSubmission WHERE CONVERT(NVARCHAR(10),GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) GROUP BY User_Id) GPSSM ON GPSSM.User_Id=USR.user_id '
					SET @Strsql+='WHERE RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+=') AS AAA GROUP BY USRID,cnt_internalId,name,contact_no,inactive_hrs,RPTTOID,emp_reportTo,user_id,REPORTTO '
					SET @Strsql+=') GPSSUMMARY ORDER BY USRID '
					--SELECT @Strsql
					EXEC (@Strsql)
				END
			ELSE IF @ACTION='Detail'
				BEGIN
					SET @Strsql=''
					SET @Strsql='INSERT INTO FTSGPSMONITORING_REPORT(USERID,USRID,ACTION,MODULETYPE,USERNAME,DATE,GPS_OFF_TIME,GPS_ON_TIME,DURATION) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,USRID,''Detail'' AS ACTION,''PORTAL'' AS MODULETYPE,name,date,gps_off_time,gps_on_time,RIGHT(''0'' + CAST(duration / 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(duration % 60 AS VARCHAR),2) AS duration FROM( '
					SET @Strsql+='SELECT USR.user_id AS USRID,USR.user_name AS name,CONVERT(NVARCHAR(10),GPSSM.GPsDate,120) AS date,GPSSM.Gps_OffTime AS gps_off_time,GPSSM.Gps_on_Time AS gps_on_time, '
					SET @Strsql+='CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(GPSSM.Duration,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(GPSSM.Duration,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS duration '
					SET @Strsql+='FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					--SET @Strsql+='INNER JOIN tbl_FTS_GPSSubmission GPSSM ON GPSSM.User_Id=USR.user_id '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='INNER JOIN (SELECT User_Id,GPsDate,Gps_OffTime,Gps_on_Time,Duration FROM tbl_FTS_GPSSubmission '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) GROUP BY User_Id,GPsDate,Gps_OffTime,Gps_on_Time,Duration) GPSSM ON GPSSM.User_Id=USR.user_id '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),GPSSM.GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					IF (@USERLIST<>'' AND @USERLIST<>'0')
						SET @Strsql+='AND EXISTS (SELECT user_id FROM #USERID_LIST AS US WHERE US.user_id=USR.USER_ID) '
					SET @Strsql+=') AS GPSDET ORDER BY USRID '
					--SELECT @Strsql
					EXEC (@Strsql)
				END
		END
	DROP TABLE #TEMPCONTACT
	DROP TABLE #USERID_LIST
END