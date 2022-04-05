--EXEC PRC_FTSEMPLOYEEATTENDANCE_FETCH '2022-03-28','2022-04-04','1','EMB0000008',378
--EXEC PRC_FTSEMPLOYEEATTENDANCE_FETCH '2022-03-28','2022-04-04','1','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSEMPLOYEEATTENDANCE_FETCH]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSEMPLOYEEATTENDANCE_FETCH] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSEMPLOYEEATTENDANCE_FETCH]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@BRANCHID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 18/11/2021
Module	   : Employee Attendance.Refer: 0024461
1.0		v2.0.27		Debashis	01/03/2022		Enhancement done.Refer: 0024715
2.0		v2.0.28		Debashis	05/04/2022		EMPLOYEE ATTENDANCE report: the attendance is getting repeating line by line instead there are date wise column.
												Refer: 0024779 & 0024786
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @SqlStr NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
		DROP TABLE #BRANCH_LIST
	CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

	IF @BRANCHID<>''
		BEGIN
			SET @SqlStrTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @sqlStrTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)

	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId FROM tbl_master_employee WHERE emp_contactId IN('+@EMPID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@Userid)		
			CREATE TABLE #EMPHRS
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
		
			INSERT INTO #EMPHRS
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte as(SELECT	EMPCODE,RPTTOEMPCODE FROM #EMPHRS WHERE EMPCODE IS NULL OR EMPCODE=@empcodes  
			UNION ALL
			SELECT a.EMPCODE,a.RPTTOEMPCODE FROM #EMPHRS a
			JOIN cte b ON a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			SELECT EMPCODE,RPTTOEMPCODE FROM cte 
		END

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT
			INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
		END

	--Rev 2.0
	IF OBJECT_ID('tempdb..#TMPATTENDANCE') IS NOT NULL
		DROP TABLE #TMPATTENDANCE
	CREATE TABLE #TMPATTENDANCE
		(
		USERID BIGINT,
		LOGGEDIN NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		LOGEDOUT NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		DAYSTTIME NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		DAYENDTIME NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		cnt_branchid INT,
		Login_datetime NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS
		)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENDANCE(USERID,Login_datetime)

	IF OBJECT_ID('tempdb..#TMPATTENLOGOUT') IS NOT NULL
		DROP TABLE #TMPATTENLOGOUT
	CREATE TABLE #TMPATTENLOGOUT
		(
		USERID BIGINT,
		LOGGEDIN NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		LOGEDOUT NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		cnt_branchid INT,
		Login_datetime NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS
		)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENLOGOUT(USERID,Login_datetime)

	IF OBJECT_ID('tempdb..#TMPDAYLOGIN') IS NOT NULL
		DROP TABLE #TMPDAYLOGIN
	CREATE TABLE #TMPDAYLOGIN
		(
		USERID BIGINT,
		DAYSTTIME NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		DAYENDTIME NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		cnt_branchid INT,
		STARTENDDATE NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS
		)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPDAYLOGIN(USERID,STARTENDDATE)

	IF OBJECT_ID('tempdb..#TMPDAYLOGOUT') IS NOT NULL
		DROP TABLE #TMPDAYLOGOUT
	CREATE TABLE #TMPDAYLOGOUT
		(
		USERID BIGINT,
		DAYSTTIME NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		DAYENDTIME NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		cnt_branchid INT,
		STARTENDDATE NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS
		)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPDAYLOGOUT(USERID,STARTENDDATE)

	SET @SqlStr=''
	SET @SqlStr='INSERT INTO #TMPATTENDANCE(USERID,LOGGEDIN,LOGEDOUT,cnt_internalId,cnt_branchid,Login_datetime) '
	SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108) AS LOGGEDIN,'''' AS LOGEDOUT,CNT.cnt_internalId,CNT.cnt_branchid,'
	SET @SqlStr+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetime '
	SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @SqlStr+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	IF @BRANCHID<>''
		SET @SqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=CNT.cnt_branchid) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	SET @SqlStr=''
	SET @SqlStr='INSERT INTO #TMPATTENLOGOUT(USERID,LOGGEDIN,LOGEDOUT,cnt_internalId,cnt_branchid,Login_datetime) '
	SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,'''' AS LOGGEDIN,CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108) AS LOGEDOUT,CNT.cnt_internalId,CNT.cnt_branchid,'
	SET @SqlStr+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetime '
	SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @SqlStr+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
	IF @BRANCHID<>''
		SET @SqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=CNT.cnt_branchid) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	SET @SqlStr=''
	SET @SqlStr='INSERT INTO #TMPDAYLOGIN(USERID,DAYSTTIME,DAYENDTIME,cnt_internalId,cnt_branchid,STARTENDDATE) '
	SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108) AS DAYSTTIME,'''' AS DAYENDTIME,CNT.cnt_internalId,CNT.cnt_branchid,'
	SET @SqlStr+='CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) AS STARTENDDATE '
	SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND '
	SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=DAYSTEND.User_Id AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='WHERE ISSTART=1 '
	SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @BRANCHID<>''
		SET @SqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=CNT.cnt_branchid) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	SET @SqlStr=''
	SET @SqlStr='INSERT INTO #TMPDAYLOGOUT(USERID,DAYSTTIME,DAYENDTIME,cnt_internalId,cnt_branchid,STARTENDDATE) '
	SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,'''' AS DAYSTTIME,CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108) AS DAYENDTIME,CNT.cnt_internalId,CNT.cnt_branchid,'
	SET @SqlStr+='CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) AS STARTENDDATE '
	SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND '
	SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=DAYSTEND.User_Id AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='WHERE ISEND=1 '
	SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @BRANCHID<>''
		SET @SqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=CNT.cnt_branchid) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	UPDATE A SET A.LOGEDOUT=B.LOGEDOUT
	FROM #TMPATTENDANCE A
	INNER JOIN #TMPATTENLOGOUT B ON A.USERID=B.USERID AND A.cnt_internalId=B.cnt_internalId AND A.cnt_branchid=B.cnt_branchid AND A.Login_datetime=B.Login_datetime

	UPDATE A SET A.DAYSTTIME=B.DAYSTTIME
	FROM #TMPATTENDANCE A
	INNER JOIN #TMPDAYLOGIN B ON A.USERID=B.USERID AND A.cnt_internalId=B.cnt_internalId AND A.cnt_branchid=B.cnt_branchid AND A.Login_datetime=B.STARTENDDATE

	UPDATE A SET A.DAYENDTIME=B.DAYENDTIME
	FROM #TMPATTENDANCE A
	INNER JOIN #TMPDAYLOGOUT B ON A.USERID=B.USERID AND A.cnt_internalId=B.cnt_internalId AND A.cnt_branchid=B.cnt_branchid AND A.Login_datetime=B.STARTENDDATE
	--End of Rev 2.0

	SET @SqlStr=''
	SET @SqlStr+='SELECT BR.BRANCH_ID,BR.BRANCH_DESCRIPTION,USR.USER_ID AS USERID,CNT.cnt_internalId AS EMPCODE,EMP.emp_uniqueCode AS EMPID,'
	SET @SqlStr+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @SqlStr+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	--Rev 1.0
	--SET @SqlStr+='USR.user_loginId AS CONTACTNO,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT,DAYSTARTEND.DAYSTTIME,DAYSTARTEND.DAYENDTIME,RPTTO.REPORTTOID,RPTTO.REPORTTO,RPTTO.RPTTODESG,HRPTTO.HREPORTTOID,HRPTTO.HREPORTTO,'
	--SET @SqlStr+='HRPTTO.HRPTTODESG FROM tbl_master_employee EMP '
	--Rev 2.0
	--SET @SqlStr+='USR.user_loginId AS CONTACTNO,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT,DAYSTARTEND.DAYSTTIME,DAYSTARTEND.DAYENDTIME,RPTTO.REPORTTOID,RPTTO.REPORTTOUID,RPTTO.REPORTTO,RPTTO.RPTTODESG,HRPTTO.HREPORTTOID,'
	SET @SqlStr+='USR.user_loginId AS CONTACTNO,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT,ATTEN.DAYSTTIME,ATTEN.DAYENDTIME,RPTTO.REPORTTOID,RPTTO.REPORTTOUID,RPTTO.REPORTTO,RPTTO.RPTTODESG,HRPTTO.HREPORTTOID,'
	--End of Rev 2.0
	SET @SqlStr+='HRPTTO.HREPORTTOUID,HRPTTO.HREPORTTO,HRPTTO.HRPTTODESG FROM tbl_master_employee EMP '
	--End of Rev 1.0
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @SqlStr+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @SqlStr+='INNER JOIN ( '
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @SqlStr+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS REPORTTOID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	--Rev 1.0
	--SET @SqlStr+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @SqlStr+='DESG.deg_designation AS RPTTODESG,CNT.cnt_UCC AS REPORTTOUID FROM tbl_master_employee EMP '
	--End of Rev 1.0
	SET @SqlStr+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON DESG.emp_cntId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL '
	SET @SqlStr+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @SqlStr+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS HREPORTTOID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS HREPORTTO,'
	--Rev 1.0
	--SET @SqlStr+='DESG.deg_designation AS HRPTTODESG FROM tbl_master_employee EMP '
	SET @SqlStr+='DESG.deg_designation AS HRPTTODESG,CNT.cnt_UCC AS HREPORTTOUID FROM tbl_master_employee EMP '
	--End of Rev 1.0
	SET @SqlStr+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id'
	SET @SqlStr+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @SqlStr+='WHERE EMPCTC.emp_effectiveuntil IS NULL) HRPTTO ON HRPTTO.emp_cntId=RPTTO.REPORTTOID '
	--Rev 2.0
	--SET @SqlStr+='LEFT OUTER JOIN ( '
	--SET @SqlStr+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime FROM( '
	--SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime '
	--SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	--SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @SqlStr+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '
	--SET @SqlStr+='UNION ALL '
	--SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime '
	--SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	--SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @SqlStr+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
	--SET @SqlStr+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '
	--SET @SqlStr+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	--SET @SqlStr+='LEFT OUTER JOIN ('
	--SET @SqlStr+='SELECT USERID,MIN(DAYSTTIME) AS DAYSTTIME,MAX(DAYENDTIME) AS DAYENDTIME FROM('
	--SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108)) AS DAYSTTIME,NULL AS DAYENDTIME '
	--SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND WHERE ISSTART=1 '
	--SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @SqlStr+='GROUP BY DAYSTEND.User_Id '
	--SET @SqlStr+='UNION ALL '
	--SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,NULL AS DAYSTTIME,MAX(CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108)) AS DAYENDTIME '
	--SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND WHERE ISEND=1 '
	--SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @SqlStr+='GROUP BY DAYSTEND.User_Id '
	--SET @SqlStr+=') DAYSTEND GROUP BY USERID) DAYSTARTEND ON DAYSTARTEND.USERID=USR.user_id '
	SET @SqlStr+='LEFT OUTER JOIN ('
	SET @SqlStr+='SELECT USERID,LOGGEDIN,LOGEDOUT,DAYSTTIME,DAYENDTIME,cnt_internalId,cnt_branchid,Login_datetime FROM #TMPATTENDANCE '
	SET @SqlStr+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	--End of Rev 2.0
	--Rev 1.0
	--SET @SqlStr+='WHERE DESG.deg_designation=''DS'' '
	SET @SqlStr+='WHERE DESG.deg_designation IN(''DS'',''TL'') '
	--End of Rev 1.0
	IF @BRANCHID<>''
		SET @SqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.branch_id) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	
	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	DROP TABLE #BRANCH_LIST
	DROP TABLE #TEMPCONTACT
	DROP TABLE #EMPLOYEE_LIST

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	--Rev 2.0
	DROP TABLE #TMPATTENDANCE
	DROP TABLE #TMPATTENLOGOUT
	DROP TABLE #TMPDAYLOGIN
	DROP TABLE #TMPDAYLOGOUT
	--End of Rev 2.0
	
	SET NOCOUNT OFF
END