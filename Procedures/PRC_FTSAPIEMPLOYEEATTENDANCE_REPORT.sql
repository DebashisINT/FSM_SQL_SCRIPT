--EXEC PRC_FTSAPIEMPLOYEEATTENDANCE_REPORT 2096

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPIEMPLOYEEATTENDANCE_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPIEMPLOYEEATTENDANCE_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSAPIEMPLOYEEATTENDANCE_REPORT]
(
--Rev 3.0
@ASONDATE NVARCHAR(10)=NULL,
--End of Rev 3.0
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 20/02/2019
Module	   : Employee Attendance for API
1.0		v17.0.0		22/02/2019		Debashis		Implemented Heirarchy in any reports. Refer: Heirarchy in any reports.
2.0		v18.0.0		23/02/2019		Debashis		Status has been changed. Refer mail:FTS Attendance report output
3.0		v2.0.8		02/03/2020		Debashis		Alarm Attendance report.Refer: 0021861
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX),@LOGINEMPCODE NVARCHAR(50)

	SET @LOGINEMPCODE=(SELECT USER_CONTACTID FROM TBL_MASTER_USER WHERE USER_ID=@USERID)

	SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE INTO #EMPHR FROM tbl_trans_employeeCTC CTC LEFT OUTER JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO

	;WITH CTE AS(SELECT	EMPCODE FROM #EMPHR WHERE EMPCODE IS NULL OR EMPCODE=@LOGINEMPCODE
	UNION ALL
	SELECT A.EMPCODE FROM #EMPHR A
	JOIN CTE B
	ON A.RPTTOEMPCODE = B.EMPCODE
	) 
	SELECT DISTINCT TMU.USER_CONTACTID AS EMPCODE INTO #EMPLOYEEHRLIST FROM CTE 
	INNER JOIN TBL_MASTER_USER TMU ON CTE.EMPCODE=TMU.USER_CONTACTID

	--Rev 1.0
	--INSERT INTO #EMPLOYEEHRLIST SELECT emp_contactId FROM tbl_master_employee EMP INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo 
	--WHERE EMPCTC.emp_cntId=@LOGINEMPCODE
	--End of Rev 1.0

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TMPMASTEMPLOYEE') AND TYPE IN (N'U'))
		DROP TABLE #TMPMASTEMPLOYEE
	CREATE TABLE #TMPMASTEMPLOYEE(EMP_ID NUMERIC(18, 0) NOT NULL,EMP_UNIQUECODE VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,EMP_CONTACTID NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPMASTEMPLOYEE (EMP_CONTACTID ASC)

	INSERT INTO #TMPMASTEMPLOYEE SELECT EMP_ID,EMP_UNIQUECODE,EMP_CONTACTID FROM tbl_master_employee WHERE EXISTS(SELECT emp_contactId FROM #EMPLOYEEHRLIST WHERE EMPCODE=emp_contactId)

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

	SET @Strsql=''
	SET @Strsql='SELECT EMPUSRID,ROW_NUMBER() OVER(ORDER BY EMPNAME) AS SEQ,CONTACTNO,STATEID,STATE,EMPCODE,EMPNAME,EMPID,LOGGEDIN,ATTEN_STATUS,DEG_ID,DESIGNATION,RPTTOUSRID,RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG '
	SET @Strsql+='FROM( '
	SET @Strsql+='SELECT USR.USER_ID AS EMPUSRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ST.ID AS STATEID,'
	SET @Strsql+='ST.state AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.RPTTOUSRID,RPTTO.RPTTOEMPCODE,RPTTO.REPORTTO,RPTTO.RPTTODESGID,RPTTO.RPTTODESG,EMP.emp_uniqueCode AS EMPID, '
	--Rev 2.0
	--SET @Strsql+='REPLACE(REPLACE(LOGGEDIN,''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,ATTEN_STATUS '
	SET @Strsql+='REPLACE(REPLACE(LOGGEDIN,''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,'
	SET @Strsql+='CASE WHEN (ATTEN.LATE_CNT=0 AND ATTEN.ATTEN_STATUS=''At Work'') THEN ''At Work'' WHEN (ATTEN.LATE_CNT=0 AND ATTEN.ATTEN_STATUS=''On Leave'') THEN ''On Leave'' '
	SET @Strsql+='WHEN ATTEN.LATE_CNT=1 THEN ''Late'' ELSE ''Not Login'' END AS ATTEN_STATUS '
	--End of Rev 2.0
	SET @Strsql+='FROM #TMPMASTEMPLOYEE EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	--Rev 2.0
	--SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='LEFT OUTER JOIN ('
	--End of Rev 2.0
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId,MIN(CONVERT(VARCHAR(15),CAST(ATTEN.Login_datetime AS TIME),100)) AS LOGGEDIN, '
	SET @Strsql+='CASE WHEN ATTEN.Isonleave=''false'' THEN ''At Work'' ELSE ''On Leave'' END AS ATTEN_STATUS,'
	--Rev 2.0
	SET @Strsql+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL((Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL((Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + '
	SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) + MIN(EMPWHD.Grace) THEN 1 ELSE 0 END LATE_CNT '
	--End of Rev 2.0
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--Rev 2.0
	SET @Strsql+='INNER JOIN #TMPMASTEMPLOYEE EMP ON EMP.emp_contactId=USR.user_contactId '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
	SET @Strsql+='INNER JOIN('
	SET @Strsql+='SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
	--End of Rev 2.0
	--Rev 3.0
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
	IF @ASONDATE=''
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
	ELSE IF @ASONDATE<>''
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) = CONVERT(NVARCHAR(10),'''+@ASONDATE+''',120) '
	--End of Rev 3.0
	--Rev 2.0
	--SET @Strsql+='AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave '
	SET @Strsql+='AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave,ATTEN.Login_datetime '
	--End of Rev 2.0
	SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT USR.USER_ID AS RPTTOUSRID,EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS RPTTOEMPCODE,'
	--Rev 1.0
	--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG FROM #TMPMASTEMPLOYEE EMP '
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG '
	SET @Strsql+='FROM tbl_master_employee EMP '
	--End of Rev 1.0
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+=') AS DB '
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #TEMPCONTACT
	DROP TABLE #EMPHR
	DROP TABLE #EMPLOYEEHRLIST
	DROP TABLE #TMPMASTEMPLOYEE

	SET NOCOUNT OFF
END