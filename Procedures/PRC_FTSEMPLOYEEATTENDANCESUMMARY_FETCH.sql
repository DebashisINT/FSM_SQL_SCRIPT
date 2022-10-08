--EXEC PRC_FTSEMPLOYEEATTENDANCESUMMARY_FETCH '2021-11-14','2021-11-16','1','EMB0000017,EMP0000020',378
--EXEC PRC_FTSEMPLOYEEATTENDANCESUMMARY_FETCH '2021-11-14','2021-11-16','1','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSEMPLOYEEATTENDANCESUMMARY_FETCH]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSEMPLOYEEATTENDANCESUMMARY_FETCH] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_FTSEMPLOYEEATTENDANCESUMMARY_FETCH]
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
Module	   : Employee Attendance Summary.Refer: 0024461
1.0		v2.0.27		Debashis	03/03/2022		Enhancement done.Refer: 0024715
2.0		v2.0.33		Debashis	09/10/2022		Code optimized.Refer: 0025331
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @SqlStr NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX),@DAYCOUNT INT,@TOTALDAYS AS INT,@FIRSTDATEOFMONTH DATETIME,@CURRENTDATEOFMONTH DATETIME

	SELECT @FIRSTDATEOFMONTH = @FROMDATE
	SELECT @CURRENTDATEOFMONTH = @TODATE

	;WITH CTE AS (SELECT 1 AS DAYID,@FIRSTDATEOFMONTH AS FROMDATE,DATENAME(DW, @FIRSTDATEOFMONTH) AS DAYNAME
	UNION ALL
	SELECT CTE.DAYID + 1 AS DAYID,DATEADD(D, 1 ,CTE.FROMDATE),DATENAME(DW, DATEADD(D, 1 ,CTE.FROMDATE)) AS DAYNAME
	FROM CTE
	WHERE DATEADD(D,1,CTE.FROMDATE) <= @CURRENTDATEOFMONTH
	)
	SELECT FROMDATE AS SUNDAYDATE,DAYNAME INTO #TMPSHOWSUNDAY
	FROM CTE
	WHERE DAYNAME IN ('Sunday')
	OPTION (MAXRECURSION 1000)

	SELECT @DAYCOUNT=DATEDIFF(D, @FROMDATE, @TODATE) +1

	SET @TOTALDAYS=(SELECT @DAYCOUNT-COUNT(DAYNAME) FROM #TMPSHOWSUNDAY)

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

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(SELECT user_contactId FROM Tbl_master_user WHERE user_id=@USERID)		
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
		
			--Rev 2.0 && WITH (NOLOCK) has been added in all tables
			INSERT INTO #EMPHRS
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC WITH (NOLOCK)
			LEFT JOIN tbl_master_employee TME WITH (NOLOCK) ON TME.emp_id= CTC.emp_reportTO 
			WHERE emp_effectiveuntil IS NULL
		
			;with cte as(SELECT	EMPCODE,RPTTOEMPCODE FROM #EMPHRS WHERE EMPCODE IS NULL OR EMPCODE=@empcodes  
			UNION ALL
			SELECT a.EMPCODE,a.RPTTOEMPCODE FROM #EMPHRS a
			JOIN cte b ON a.RPTTOEMPCODE = b.EMPCODE
			)
			INSERT INTO #EMPHR_EDIT
			SELECT EMPCODE,RPTTOEMPCODE FROM cte 
		END

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
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
			--Rev 2.0 && WITH (NOLOCK) has been added in all tables
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WITH (NOLOCK)
			INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
			WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			--Rev 2.0 && WITH (NOLOCK) has been added in all tables
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WITH (NOLOCK) 
			WHERE cnt_contactType IN('EM')
		END

	--Rev 2.0
	IF OBJECT_ID('tempdb..#TMPATTENLOGINOUT') IS NOT NULL
		DROP TABLE #TMPATTENLOGINOUT
	CREATE TABLE #TMPATTENLOGINOUT
	(USERID BIGINT,LOGGEDIN NVARCHAR(10),LOGEDOUT NVARCHAR(10),cnt_internalId NVARCHAR(10),Login_datetime NVARCHAR(10),ATTEN_STATUS NVARCHAR(20))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENLOGINOUT(USERID,cnt_internalId,Login_datetime)

	SET @SqlStr=''
	SET @SqlStr='INSERT INTO #TMPATTENLOGINOUT(USERID,LOGGEDIN,LOGEDOUT,cnt_internalId,Login_datetime,ATTEN_STATUS) '
	SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @SqlStr+='CASE WHEN Isonleave=''false'' THEN ''Present'' ELSE ''Absent'' END AS ATTEN_STATUS '
	SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_id=ATTEN.User_Id '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND USR.user_inactive=''N'' '
	SET @SqlStr+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @SqlStr+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '	
	SET @SqlStr+='UNION ALL '				   
	SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @SqlStr+='CASE WHEN Isonleave=''false'' THEN ''Present'' ELSE ''Absent'' END AS ATTEN_STATUS '
	SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_id=ATTEN.User_Id '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @SqlStr+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' AND USR.user_inactive=''N'' '
	SET @SqlStr+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	IF OBJECT_ID('tempdb..#TMPATTENNOTLOGINOUT') IS NOT NULL
		DROP TABLE #TMPATTENNOTLOGINOUT
	CREATE TABLE #TMPATTENNOTLOGINOUT
	(USERID BIGINT,cnt_internalId NVARCHAR(10),Login_datetime NVARCHAR(10))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENNOTLOGINOUT(USERID,cnt_internalId,Login_datetime)

	SET @SqlStr=''
	SET @SqlStr='INSERT INTO #TMPATTENNOTLOGINOUT(USERID,cnt_internalId,Login_datetime) '
	SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime '
	SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_id=ATTEN.User_Id '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @SqlStr+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' AND USR.user_inactive=''N'' '
	SET @SqlStr+='AND NOT EXISTS(SELECT DAYSTEND.User_Id FROM FSMUSERWISEDAYSTARTEND DAYSTEND WITH (NOLOCK) WHERE ATTEN.User_Id=DAYSTEND.USER_ID AND ISEND=0) '
	SET @SqlStr+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) '

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr
	--End of Rev 2.0

	--Rev 2.0 && WITH (NOLOCK) has been added in all tables
	SET @SqlStr=''
	SET @SqlStr='SELECT BR.BRANCH_ID,BR.BRANCH_DESCRIPTION,USR.USER_ID AS USERID,CNT.cnt_internalId AS EMPCODE,EMP.emp_uniqueCode AS EMPID,'
	SET @SqlStr+='ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')='''' THEN '''' ELSE ISNULL(CNT.cnt_middleName,'''')+'' '' END +ISNULL(CNT.cnt_lastName,'''') AS EMPNAME,'
	SET @SqlStr+='ATTEN.LOGGEDIN,ATTEN.LOGEDOUT,CASE WHEN ISNULL(LOGGEDIN,'''')<>'''' THEN  ATTEN_STATUS ELSE '
	SET @SqlStr+='CASE WHEN (SELECT FORMAT(CAST('''+@FROMDATE+''' AS DATE), ''dddd''))=''Sunday'' THEN ''Weekly Off'' ELSE ''Not Logged In'' END END AS ATTEN_STATUS,'
	SET @SqlStr+=''+LTRIM(RTRIM(STR(@TOTALDAYS)))+' AS TOTWORKINGDAYS,ISNULL(NOLOGOUT.NOTLOGOUTDAYS,0) AS NOTLOGOUTDAYS '
	SET @SqlStr+='FROM tbl_master_employee EMP WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN tbl_master_branch BR WITH (NOLOCK) ON CNT.cnt_branchid=BR.branch_id '
	SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN tbl_master_address ADDR WITH (NOLOCK) ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @SqlStr+='INNER JOIN tbl_master_state ST WITH (NOLOCK) ON ST.id=ADDR.add_state '
	SET @SqlStr+='INNER JOIN ( '
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH (NOLOCK) '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @SqlStr+='LEFT OUTER JOIN ('
	SET @SqlStr+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,ATTEN_STATUS FROM('
	--Rev 2.0
	--SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	--SET @SqlStr+='CASE WHEN Isonleave=''false'' THEN ''Present'' ELSE ''Absent'' END AS ATTEN_STATUS '
	--SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	--SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
	--SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND USR.user_inactive=''N'' '
	--SET @SqlStr+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '	
	--SET @SqlStr+='UNION ALL '				   
	--SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	--SET @SqlStr+='CASE WHEN Isonleave=''false'' THEN ''Present'' ELSE ''Absent'' END AS ATTEN_STATUS '
	--SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	--SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
	--SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @SqlStr+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' AND USR.user_inactive=''N'' '
	--SET @SqlStr+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '
	SET @SqlStr+='SELECT USERID,LOGGEDIN,LOGEDOUT,cnt_internalId,Login_datetime,ATTEN_STATUS FROM #TMPATTENLOGINOUT '
	--End of Rev 2.0
	SET @SqlStr+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,ATTEN_STATUS) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	SET @SqlStr+='LEFT OUTER JOIN ('
	SET @SqlStr+='SELECT USERID,COUNT(Login_datetime) AS NOTLOGOUTDAYS,cnt_internalId FROM('
	--Rev 2.0
	--SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime '
	--SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	--SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
	--SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @SqlStr+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' AND USR.user_inactive=''N'' '
	--SET @SqlStr+='AND NOT EXISTS(SELECT DAYSTEND.User_Id FROM FSMUSERWISEDAYSTARTEND DAYSTEND WHERE ATTEN.User_Id=DAYSTEND.USER_ID AND ISEND=0) '
	--SET @SqlStr+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) '
	SET @SqlStr+='SELECT USERID,cnt_internalId,Login_datetime FROM #TMPATTENNOTLOGINOUT '
	--End of Rev 2.0
	SET @SqlStr+=') NLD GROUP BY USERID,cnt_internalId) NOLOGOUT ON NOLOGOUT.cnt_internalId=CNT.cnt_internalId AND NOLOGOUT.USERID=USR.user_id '
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
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END
	--Rev 2.0
	DROP TABLE #TMPATTENLOGINOUT
	DROP TABLE #TMPATTENNOTLOGINOUT
	DROP TABLE #TMPSHOWSUNDAY
	--End of Rev 2.0

	SET NOCOUNT OFF
END