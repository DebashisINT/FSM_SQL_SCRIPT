IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSHORIZONTALATTENDANCESUMMARY_FETCH]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSHORIZONTALATTENDANCESUMMARY_FETCH] AS'  
 END 
 GO 

--EXEC PRC_FTSHORIZONTALATTENDANCESUMMARY_FETCH @FROM_DATE='2020-11-10',@TO_DATE='2021-03-02',@EMPID='EMJ0000001'
ALTER PROCEDURE [dbo].[PRC_FTSHORIZONTALATTENDANCESUMMARY_FETCH]
(
@FROM_DATE NVARCHAR(10)=NULL,
@TO_DATE NVARCHAR(10)=NULL,
@EMPID NVARCHAR(MAX) =NULL,
@Emp_code NVARCHAR(100)=NULL,
-- Rev 1.0
@BRANCHID NVARCHAR(MAX)=NULL,
-- End of Rev 1.0
@Userid bigint=null
)
AS
/**************************************************************************************************************************************
1.0		V2.0.41		Sanchita	19/07/2023		Add Branch parameter in MIS -> Performance Summary report. Refer: 26135
***************************************************************************************************************************************/
BEGIN
	DECLARE @sqlStrTable NVARCHAR(MAX)
	DECLARE @sqlStr NVARCHAR(MAX)

	--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Userid)=1)
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
		
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHRS 
			where EMPCODE IS NULL OR EMPCODE=@empcodes  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHRS a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 

		END
	--End of Rev 3.0
	-- Rev 1.0
	IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
		DROP TABLE #BRANCH_LIST
	CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

	IF @BRANCHID<>''
		BEGIN
			SET @sqlStrTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @sqlStrTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	-- End of Rev 1.0


	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
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
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Userid)=1)
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT
			INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
			WHERE cnt_contactType IN('EM')
		END
		ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
		END


	SET @sqlStr=''
	SET @sqlStr+=' SELECT EmpCode,EMP_NAME,LoginID,Department,user_id,LOGGEDIN,LOGEDOUT,ATTEN_STATUS , '
	SET @sqlStr+=' RIGHT(''0'' + CAST(CAST(duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(duration AS VARCHAR) % 60 AS VARCHAR),2) AS duration_HR,duration AS duration_MIN '
	SET @sqlStr+=' ,cnt_internalId '
	-- Rev 1.0
	 SET @sqlStr+=' ,Branch '
	-- End of Rev 1.0
	SET @sqlStr+=' FROM ( '
	SET @sqlStr+=' SELECT CNT.cnt_UCC AS EmpCode, '
	SET @sqlStr+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')='''' THEN '''' ELSE ISNULL(CNT.cnt_middleName,'''')+'' '' END +ISNULL(CNT.cnt_lastName,'''') AS EMP_NAME '
	SET @sqlStr+=' ,usr.user_loginId AS LoginID,cost_description AS Department,USR.user_id '
	SET @sqlStr+=' ,RIGHT(CONVERT(VARCHAR, CAST(LOGGEDIN AS DATETIME), 100),7) AS LOGGEDIN,RIGHT(CONVERT(VARCHAR, CAST(LOGEDOUT AS DATETIME), 100),7) AS LOGEDOUT, '
				   
	SET @sqlStr+=' CASE WHEN ISNULL(LOGGEDIN,'''')<>'''' THEN  ATTEN_STATUS ELSE '
	SET @sqlStr+=' CASE WHEN (SELECT FORMAT(CAST('''+@FROM_DATE+''' AS DATE), ''dddd''))=''Sunday'' THEN ''Weekly Off'' ELSE ''Not Logged In'' END END AS ATTEN_STATUS, '
	SET @sqlStr+=' CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @sqlStr+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS duration '
	SET @sqlStr+=' ,CNT.cnt_internalId '
	-- Rev 1.0
	SET @sqlStr+=' , BR.branch_description as Branch '
	-- End of Rev 1.0
	SET @sqlStr+='  FROM tbl_master_user USR '
	SET @sqlStr+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @sqlStr+=' INNER JOIN TBL_TRANS_EMPLOYEECTC CTC ON CTC.emp_cntId=CNT.cnt_internalId '
	SET @sqlStr+=' LEFT OUTER JOIN tbl_master_costCenter DEPT ON CTC.emp_Department=DEPT.cost_id AND DEPT.cost_costCenterType=''Department'' '
	-- Rev 1.0
	SET @sqlStr+='INNER JOIN tbl_master_branch BR ON CTC.emp_branch=BR.branch_id '
	IF @BRANCHID<>''
		SET @sqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.BRANCH_ID) '
	-- End of Rev 1.0
	SET @sqlStr+=' LEFT OUTER JOIN ( '
	SET @sqlStr+=' SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,ATTEN_STATUS FROM( '
	SET @sqlStr+=' SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT, '
	SET @sqlStr+=' CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime, '
	SET @sqlStr+=' CASE WHEN Isonleave=''false'' THEN ''Present'' ELSE ''Absent'' END AS ATTEN_STATUS '
	SET @sqlStr+=' FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @sqlStr+=' INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id  '
	SET @sqlStr+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TO_DATE+''',120) AND USR.user_inactive=''N'' '
	SET @sqlStr+=' AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '
	
	SET @sqlStr+=' UNION ALL '
				   
	SET @sqlStr+=' SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime, '
	SET @sqlStr+=' CASE WHEN Isonleave=''false'' THEN ''Present'' ELSE ''Absent'' END AS ATTEN_STATUS '
	SET @sqlStr+=' FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @sqlStr+=' INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id  '
	SET @sqlStr+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TO_DATE+''',120) '
	SET @sqlStr+=' AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' AND USR.user_inactive=''N'' '
	SET @sqlStr+=' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '
	SET @sqlStr+=' ) LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,ATTEN_STATUS) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	IF @EMPID <> ''
	BEGIN
		SET @sqlStr+=' WHERE EXISTS (SELECT TMP.emp_contactId FROM #EMPLOYEE_LIST TMP WHERE TMP.emp_contactId= CNT.cnt_internalId) '
	END
	SET @sqlStr+=' ) T '

	EXEC SP_EXECUTESQL @sqlStr

	--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Userid)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	--End of Rev 3.0
END