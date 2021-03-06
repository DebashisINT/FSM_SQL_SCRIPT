--EXEC PRC_FTSTEAMVISITATTENDANCESUMMARY_FETCH '2022-02-20','2022-02-28','','EMS0000812','',378
--EXEC PRC_FTSTEAMVISITATTENDANCESUMMARY_FETCH '2022-02-20','2022-02-28','','','1,4',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTEAMVISITATTENDANCESUMMARY_FETCH]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTEAMVISITATTENDANCESUMMARY_FETCH] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_FTSTEAMVISITATTENDANCESUMMARY_FETCH]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@BRANCHID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@CHANNELID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 04/03/2022
Module	   : Team Visit Attendance Summary.Refer: 0024720
1.0		v2.0.28		Debashis	25/03/2022		FSM : Team Visit report and Employee Attendance report Chages required:
												'Total Days absent' should be calculated (Total working days - (minus) Total Days Present).Refer: 0024763
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

	IF OBJECT_ID('tempdb..#CHANNEL_LIST') IS NOT NULL
		DROP TABLE #CHANNEL_LIST
	CREATE TABLE #CHANNEL_LIST (CH_ID BIGINT)

	IF @CHANNELID <> ''
		BEGIN
			SET @CHANNELID=REPLACE(@CHANNELID,'''','')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #CHANNEL_LIST SELECT CH_ID FROM Employee_Channel WHERE CH_ID IN('+@CHANNELID+')'
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
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT
			INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
			WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
		END

	SET @SqlStr=''
	SET @SqlStr='SELECT BR.BRANCH_ID,BR.BRANCH_DESCRIPTION,USR.USER_ID AS USERID,CNT.cnt_internalId AS EMPCODE,EMP.emp_uniqueCode AS EMPID,'
	SET @SqlStr+='ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')='''' THEN '''' ELSE ISNULL(CNT.cnt_middleName,'''')+'' '' END +ISNULL(CNT.cnt_lastName,'''') AS EMPNAME,'
	SET @SqlStr+='CASE WHEN ISNULL(DAYSTTIME,'''')<>'''' THEN  ''Present'' ELSE '
	SET @SqlStr+='CASE WHEN (SELECT FORMAT(CAST('''+@FROMDATE+''' AS DATE), ''dddd''))=''Sunday'' THEN ''Weekly Off'' ELSE ''Not Logged In'' END END AS ATTEN_STATUS,'
	SET @SqlStr+=''+LTRIM(RTRIM(STR(@TOTALDAYS)))+' AS TOTWORKINGDAYS '
	SET @SqlStr+='FROM tbl_master_employee EMP '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @SqlStr+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @SqlStr+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @SqlStr+='INNER JOIN ( '
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN ('
	--Rev 1.0
	--SET @SqlStr+='SELECT EC.ch_id,EC.ch_Channel AS CHANNEL,ECM.EP_EMP_CONTACTID FROM Employee_Channel EC '
	--SET @SqlStr+='INNER JOIN Employee_ChannelMap ECM ON EC.ch_id=ECM.EP_CH_ID '
	SET @SqlStr+='SELECT EC.ch_id,ECM.EP_EMP_CONTACTID FROM Employee_Channel EC '
	SET @SqlStr+='INNER JOIN Employee_ChannelMap ECM ON EC.ch_id=ECM.EP_CH_ID '
	SET @SqlStr+='GROUP BY EC.ch_id,ECM.EP_EMP_CONTACTID '
	--End of Rev 1.0
	SET @SqlStr+=') CH ON CNT.cnt_internalId=CH.EP_EMP_CONTACTID '
	SET @SqlStr+='LEFT OUTER JOIN ('
	SET @SqlStr+='SELECT USERID,(DAYSTTIME) AS DAYSTTIME,(DAYENDTIME) AS DAYENDTIME FROM('
	SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,(CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108)) AS DAYSTTIME,NULL AS DAYENDTIME '
	SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND WHERE ISSTART=1 '
	SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @SqlStr+='UNION ALL '
	SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,NULL AS DAYSTTIME,(CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108)) AS DAYENDTIME '
	SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND WHERE ISEND=1 '
	SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @SqlStr+=') DAYSTEND '
	SET @SqlStr+=') DAYSTARTEND ON DAYSTARTEND.USERID=USR.user_id '
	SET @SqlStr+='WHERE DESG.deg_designation IN(''DS'',''TL'') '
	IF @BRANCHID<>''
		SET @SqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.branch_id) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	IF @CHANNELID<>''
		SET @SqlStr+='AND EXISTS (SELECT ch_id FROM #CHANNEL_LIST AS CHN WHERE CHN.ch_id=CH.CH_ID) '

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	DROP TABLE #BRANCH_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT
	DROP TABLE #CHANNEL_LIST

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END

	SET NOCOUNT OFF
END