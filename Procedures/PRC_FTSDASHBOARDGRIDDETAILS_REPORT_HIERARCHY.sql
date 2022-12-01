--EXEC PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY '2018-12-24','','','EMP0000002','AT_WORK','Detail',378
--EXEC PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY '2019-01-07','15','','','AT_WORK','Summary','A',378
--EXEC PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY '2019-01-04','','','','AT_WORK','Detail','A',7,378
--EXEC PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY '2019-01-04','','','','AT_WORK','Detail','A',378
--EXEC PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY '2018-12-24','','65','EMP0000002','VISIT','Detail','A',0,378
--EXEC PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY '2019-01-04','','','','VISITTODAY','Detail','A',378
--EXEC PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY '2019-01-04','15','','EMP0000002','PENDING7DAYS','Detail','A',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY]
(
@TODAYDATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@ACTION NVARCHAR(20),
@RPTTYPE NVARCHAR(20),
@HIERARCHY NVARCHAR(1)=NULL,
--@DAYCOUNT INT=0,
@USERID INT
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 24/12/2018
Module	   : Dashboard Grid Details
1.0	V2.0.37		Sanchita	01-12-2022		FSM Dashboard : NEW tab shall be implemented "Team Visit - Hierarchy & Channel Wise" after the 'Team Visit' Tab
												Refer: 25468
												NEW SP WRITTEN
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX),@FROMDATE_7 NVARCHAR(10),@FROMDATE_15 NVARCHAR(10),@FROMDATE_30 NVARCHAR(10),@PREVIOUSDATE NVARCHAR(10)

	-- Rev 1.0
	DECLARE @EMPCODE NVARCHAR(50)=NULL,@CHCIRSECTYPE NVARCHAR(MAX)
	DECLARE @IsShowOnlyDSTLInDashboard NVARCHAR(100)=''
	SET @IsShowOnlyDSTLInDashboard=(SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsShowOnlyDSTLInDashboard')
	-- End of Rev 1.0

	SET @PREVIOUSDATE=DATEADD(DAY, -1, CONVERT(DATE, @TODAYDATE)) 
	--SET @FROMDATE=DATEADD(DAY, -(@DAYCOUNT-1), DATEADD(DAY, -1, CONVERT(DATE, @TODAYDATE)))
	SET @FROMDATE_7=DATEADD(DAY, -6, DATEADD(DAY, -1, CONVERT(DATE, @TODAYDATE)))
	SET @FROMDATE_15=DATEADD(DAY, -14, DATEADD(DAY, -1, CONVERT(DATE, @TODAYDATE)))
	SET @FROMDATE_30=DATEADD(DAY, -29, DATEADD(DAY, -1, CONVERT(DATE, @TODAYDATE)))

	-- Rev 1.0
	SET @EMPCODE= (select top 1 user_contactId FROM tbl_master_user WHERE user_id=@USERID )
	SET @CHCIRSECTYPE=(SELECT STRING_AGG(EP_CH_ID, ', ') AS List_Channel FROM Employee_ChannelMap where EP_EMP_CONTACTID=@EMPCODE GROUP BY EP_EMP_CONTACTID)

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		--DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		

		IF OBJECT_ID('tempdb..#EMPHR') IS NOT NULL
			DROP TABLE #EMPHR
		CREATE TABLE #EMPHR
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)

		IF OBJECT_ID('tempdb..#EMPHR_EDIT') IS NOT NULL
			DROP TABLE #EMPHR_EDIT
		CREATE TABLE #EMPHR_EDIT
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)
		
		--Rev 14.0 && WITH (NOLOCK) has been added in all tables
		INSERT INTO #EMPHR
		SELECT DISTINCT EMPCODE,RPTTOEMPCODE FROM(
		SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') AS RPTTOEMPCODE 
		FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
		LEFT OUTER JOIN tbl_master_employee TME WITH(NOLOCK) ON TME.emp_id=CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		UNION ALL
		SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') AS RPTTOEMPCODE 
		FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
		LEFT OUTER JOIN tbl_master_employee TME WITH(NOLOCK) ON TME.emp_id= CTC.emp_deputy WHERE emp_effectiveuntil IS NULL
		) EMPHRS
	
		;with cte as(select	
		EMPCODE,RPTTOEMPCODE
		from #EMPHR 
		where EMPCODE IS NULL OR EMPCODE=@empcode  
		union all
		select	
		a.EMPCODE,a.RPTTOEMPCODE
		from #EMPHR a
		join cte b
		on a.RPTTOEMPCODE = b.EMPCODE
		) 
		INSERT INTO #EMPHR_EDIT
		select EMPCODE,RPTTOEMPCODE  from cte 

	END
	-- End of Rev 1.0

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
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
	
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
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

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSHOP') AND TYPE IN (N'U'))
		DROP TABLE #TEMPSHOP
	CREATE TABLE #TEMPSHOP
	(
	USER_ID INT,SHOP_CODE NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS,VISITAGE INT,EMPCODE NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,LASTVISIT DATETIME
	)
	CREATE NONCLUSTERED INDEX IX ON #TEMPSHOP(EMPCODE ASC)
	
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
	
	-- Rev 1.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	SET @SqlStrTable=''
	SET @SqlStrTable='INSERT INTO #TEMPCONTACT '
	SET @SqlStrTable+='SELECT CNT.cnt_internalId,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT CNT WITH (NOLOCK) '
	SET @SqlStrTable+='INNER JOIN tbl_master_employee EMP WITH (NOLOCK) ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStrTable+=' INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE '

	SET @SqlStrTable+='INNER JOIN ( '
	SET @SqlStrTable+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH (NOLOCK) '
	SET @SqlStrTable+='LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation '
	SET @SqlStrTable+='WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation IN(''DS'',''TL'') '
	SET @SqlStrTable+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStrTable+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
	
	SET @SqlStrTable+='WHERE CNT.cnt_contactType IN(''EM'') '
	SET @SqlStrTable+=' AND EXISTS (SELECT LC.EP_CH_ID FROM Employee_ChannelMap LC WITH (NOLOCK) WHERE EP_CH_ID in ('+@CHCIRSECTYPE+') and CNT.cnt_internalId=LC.EP_EMP_CONTACTID)  '
	
	--SELECT @SqlStrTable
	EXEC SP_EXECUTESQL @SqlStrTable
	-- End of Rev 1.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY
			(
			  USERID INT,
			  ACTION NVARCHAR(20),
			  RPTTYPE NVARCHAR(20),
			  SEQ INT,
			  EMPCODE NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  VISITCNT INT,
			  EMPCNT INT,
			  REPORTTO NVARCHAR(300) NULL,
			  SHOPASSIGN INT,
			  DISTANCE_COVERED DECIMAL(18,2),
			  SHOPS_VISITED INT,
			  LAST7DAYVISIT DECIMAL(18,2),
			  LAST15DAYVISIT DECIMAL(18,2),
			  LAST30DAYVISIT DECIMAL(18,2),
			  PENDINGVISIT7DAYS INT,
			  SHOP_CODE NVARCHAR(100),
			  SHOP_NAME NVARCHAR(100),
			  SHOP_TYPE NVARCHAR(10),
			  SHOPLOCATION NVARCHAR(500),
			  LASTVISIT NVARCHAR(10),
			  VISITAGE INT,
			  SHOPCONTACT NVARCHAR(50),
			  VERIFIED NVARCHAR(50),
			  VISITED_TIME NVARCHAR(30),
			  SPENT_DURATION NVARCHAR(20),
			  VISIT_TYPE NVARCHAR(20)
			)
			CREATE NONCLUSTERED INDEX IX ON FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY (SEQ)
		END
	DELETE FROM FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY WHERE USERID=@USERID AND ACTION=@ACTION AND RPTTYPE=@RPTTYPE 

	SET @Strsql=''
	IF @ACTION='AT_WORK' AND @RPTTYPE='Summary'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY(USERID,ACTION,RPTTYPE,SEQ,STATEID,STATE,DEG_ID,DESIGNATION,VISITCNT,EMPCNT) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AT_WORK'' AS ACTION,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,STATEID,STATE,DEG_ID,DESIGNATION,SUM(ISNULL(VISITCNT,0)) AS VISITCNT,COUNT(DESIGNATION) AS EMPCNT '
			SET @Strsql+='FROM( '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,SHOPACT.shop_visited AS VISITCNT,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT User_Id FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY User_Id)ATTEN ON ATTEN.User_Id=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(DISTINCT SHOPACT.Shop_Id) AS shop_visited FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+=') AS DB '
			IF @STATEID<>''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='GROUP BY STATEID,STATE,DEG_ID,DESIGNATION '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	IF @ACTION='AT_WORK' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,SHOPASSIGN,DISTANCE_COVERED,SHOPS_VISITED,LAST7DAYVISIT,LAST15DAYVISIT,LAST30DAYVISIT,PENDINGVISIT7DAYS) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AT_WORK'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,'
			SET @Strsql+='SHOPASSIGN,DISTANCE_COVERED,SHOPS_VISITED,ROUND(LAST7DAYVISIT/7,0) AS LAST7DAYVISIT,ROUND(LAST15DAYVISIT/15,0) AS LAST15DAYVISIT,ROUND(LAST30DAYVISIT/30,0) AS LAST30DAYVISIT,'
			SET @Strsql+='CASE WHEN (SHOPASSIGN-LAST7DAYVISIT)<0 THEN 0 ELSE (SHOPASSIGN-LAST7DAYVISIT) END AS PENDINGVISIT7DAYS FROM( '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO,ISNULL(SHOPASSIGN,0) AS SHOPASSIGN,ISNULL(DISTANCE_COVERED,0) AS DISTANCE_COVERED,ISNULL(SHOPACT.shop_visited,0) AS Shops_Visited, '
			--SET @Strsql+='ISNULL(PREVSHOP.LASTDAYVISIT,0) AS LASTDAYVISIT '
			SET @Strsql+='CAST(ISNULL(PREVSHOP_7.LAST7DAYVISIT,0) AS DECIMAL(18,2)) AS LAST7DAYVISIT,CAST(ISNULL(PREVSHOP_15.LAST15DAYVISIT,0) AS DECIMAL(18,2)) AS LAST15DAYVISIT,CAST(ISNULL(PREVSHOP_30.LAST30DAYVISIT,0) AS DECIMAL(18,2)) AS LAST30DAYVISIT '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT User_Id FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY User_Id)ATTEN ON ATTEN.User_Id=USR.user_id '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SHOP.Shop_CreateUser,CNT.cnt_internalId,COUNT(SHOP.Shop_Code) AS SHOPASSIGN FROM tbl_Master_shop SHOP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOP.Shop_CreateUser '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOP.Shop_CreateTime,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SHOP.Shop_CreateUser,CNT.cnt_internalId) SHOP ON SHOP.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id,SUM(CAST(DISTANCE_COVERED AS DECIMAL(18,2))) AS DISTANCE_COVERED FROM tbl_trans_shopuser '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY User_Id) SHOPUSR ON SHOPUSR.user_id=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.total_visit_count) AS shop_visited FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(DISTINCT SHOPACT.Shop_Id) AS LAST7DAYVISIT FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@PREVIOUSDATE+''',120) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE_7+''',120) AND CONVERT(NVARCHAR(10),'''+@PREVIOUSDATE+''',120) '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) PREVSHOP_7 ON PREVSHOP_7.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(DISTINCT SHOPACT.Shop_Id) AS LAST15DAYVISIT FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE_15+''',120) AND CONVERT(NVARCHAR(10),'''+@PREVIOUSDATE+''',120) '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) PREVSHOP_15 ON PREVSHOP_15.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(DISTINCT SHOPACT.Shop_Id) AS LAST30DAYVISIT FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE_30+''',120) AND CONVERT(NVARCHAR(10),'''+@PREVIOUSDATE+''',120) '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) PREVSHOP_30 ON PREVSHOP_30.cnt_internalId=CNT.cnt_internalId '
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--IF @HIERARCHY<>'A'
			--	SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			--IF @DESIGNID<>''
			--	SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DESG.DEG_ID) '
			IF @HIERARCHY<>'A' AND @DESIGNID=''
				SET @Strsql+='WHERE RPTTO.user_id='+STR(@USERID)+' '
			IF @DESIGNID<>'' AND @HIERARCHY='A'
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DESG.DEG_ID) '
			IF @HIERARCHY<>'A' AND @DESIGNID<>''
				BEGIN
					SET @Strsql+='WHERE RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DESG.DEG_ID) '
				END
			SET @Strsql+=') AS DB '
			IF @STATEID<>''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	IF @ACTION='VISIT' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO #TEMPSHOP(USER_ID,VISITAGE,EMPCODE,LASTVISIT) '
			SET @Strsql+='SELECT SHOP.Shop_CreateUser,DATEDIFF(DAY,MAX(CAST(SHOP.Lastvisit_date AS DATE)),CONVERT(DATE,'''+@TODAYDATE+''')) AS VISITAGE,CNT.cnt_internalId,MAX(SHOP.Lastvisit_date) AS LASTVISIT '
			SET @Strsql+='FROM tbl_Master_shop SHOP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOP.Shop_CreateUser '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId ' 
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOP.Shop_CreateTime,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @EMPID<>''
				SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
			SET @Strsql+='GROUP BY SHOP.Shop_CreateUser,CNT.cnt_internalId '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,SHOP_NAME,SHOPLOCATION,LASTVISIT,VISITAGE,SHOPCONTACT,VERIFIED) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''VISIT'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,'
			SET @Strsql+='SHOP_NAME,SHOPLOCATION,LASTVISIT,VISITAGE,SHOPCONTACT,VERIFIED FROM( '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO,SHOP.SHOP_NAME,SHOP.SHOPLOCATION,SHOP.LASTVISIT,SHOP.VISITAGE,SHOP.SHOPCONTACT,SHOP.VERIFIED '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT SHOP.Shop_Name,SHOP.Address AS SHOPLOCATION,SHOP.Shop_CreateUser,SHOP.Shop_Owner_Contact AS SHOPCONTACT,CASE WHEN SHOP.VerifiedOTP IS NULL THEN ''No'' ELSE ''Yes'' END VERIFIED,'
			SET @Strsql+='S.VISITAGE,CNT.cnt_internalId,CONVERT(NVARCHAR(10),S.LASTVISIT,105) AS LASTVISIT FROM tbl_Master_shop SHOP '
			SET @Strsql+='INNER JOIN #TEMPSHOP S ON S.USER_ID=SHOP.Shop_CreateUser '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=S.EMPCODE '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOP.Shop_CreateTime,120)=CONVERT(NVARCHAR(10),S.LASTVISIT,120) '
			SET @Strsql+=') SHOP ON SHOP.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			IF @EMPID<>''
				SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
			IF @DESIGNID<>''
				SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DESG.DEG_ID) '
			SET @Strsql+=') AS DB '
			IF @STATEID<>''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	IF @ACTION='VISITTODAY' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,SHOP_NAME,SHOP_TYPE,SHOPLOCATION,SHOPCONTACT,VISITED_TIME,SPENT_DURATION,VISIT_TYPE) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''VISITTODAY'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,'
			SET @Strsql+='SHOP_NAME,SHOP_TYPE,SHOPLOCATION,SHOPCONTACT,VISITED_TIME,SPENT_DURATION,VISIT_TYPE FROM( '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO,SHOP.SHOP_NAME,SHOP.SHOP_TYPE,SHOP.SHOPLOCATION,SHOP.SHOPCONTACT,SHOP.VISIT_TYPE,'
			SET @Strsql+='REPLACE(REPLACE(SHOP.VISITED_TIME,''AM'','' AM''),''PM'','' PM'') AS VISITED_TIME,'
			SET @Strsql+='RIGHT(''0'' + CAST(CAST(CASE WHEN SHOP.spent_duration=0 THEN 0 ELSE SHOP.spent_duration END AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(CASE WHEN SHOP.spent_duration=0 THEN 0 ELSE SHOP.spent_duration END AS VARCHAR) % 60 AS VARCHAR),2) AS SPENT_DURATION '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT SHOP.Shop_Name,SHOP.Address AS SHOPLOCATION,SHOP.Shop_CreateUser,SHOP.Shop_Owner_Contact AS SHOPCONTACT,'
			SET @Strsql+='CNT.cnt_internalId,'
			--CASE WHEN (SHOP.assigned_to_pp_id IS NULL OR SHOP.assigned_to_pp_id='''') THEN ''Shop'' ELSE ''PP'' END AS SHOP_TYPE,'
			SET @Strsql+='CASE WHEN SHOP.TYPE=1 THEN ''Shop'' WHEN SHOP.TYPE=2 THEN ''PP'' WHEN SHOP.TYPE=3 THEN ''New Party'' WHEN SHOP.TYPE=4 THEN ''DD'' END AS SHOP_TYPE,'
			SET @Strsql+='CONVERT(VARCHAR(15),CAST(SHOPACT.visited_time as TIME),100) AS VISITED_TIME,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(CONVERT(varchar(5),SHOPACT.spent_duration, 108),''00:00:00'')) * 60)) AS FLOAT) + '
			SET @Strsql+='CAST(SUM(DATEPART(MINUTE,ISNULL(CONVERT(varchar(5),SHOPACT.spent_duration, 108),''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS spent_duration, '
			SET @Strsql+='CASE WHEN SHOPACT.Is_Newshopadd=1 THEN ''New'' ELSE ''Re-Visit'' END AS VISIT_TYPE '
			SET @Strsql+='FROM tbl_Master_shop SHOP '
			SET @Strsql+='INNER JOIN tbl_trans_shopActivitysubmit SHOPACT ON SHOP.Shop_CreateUser=SHOPACT.User_Id AND SHOP.Shop_Code=SHOPACT.Shop_Id '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOP.Shop_CreateUser '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId ' 
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SHOP.Shop_Name,SHOP.Address,SHOP.Shop_CreateUser,SHOP.Shop_Owner_Contact,CNT.cnt_internalId,SHOP.TYPE,SHOPACT.visited_time,SHOPACT.Is_Newshopadd '
			SET @Strsql+=') SHOP ON SHOP.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			IF @EMPID<>''
				SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
			IF @DESIGNID<>''
				SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DESG.DEG_ID) '
			SET @Strsql+=') AS DB '
			IF @STATEID<>''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	IF @ACTION='PENDING7DAYS' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO #TEMPSHOP(USER_ID,SHOP_CODE,VISITAGE,EMPCODE) '
			SET @Strsql+='SELECT SHOP.Shop_CreateUser,SHOP.SHOP_CODE,DATEDIFF(DAY,MAX(CAST(SHOP.Lastvisit_date AS DATE)),CONVERT(DATE,'''+@TODAYDATE+''')) AS VISITAGE,CNT.cnt_internalId '
			SET @Strsql+='FROM tbl_Master_shop SHOP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOP.Shop_CreateUser '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId ' 
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOP.Shop_CreateTime,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @EMPID<>''
				SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
			SET @Strsql+='GROUP BY SHOP.Shop_CreateUser,SHOP.SHOP_CODE,CNT.cnt_internalId '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDGRIDDETAILS_REPORT_HIERARCHY(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,SHOP_CODE,SHOP_NAME,SHOP_TYPE,SHOPLOCATION,SHOPCONTACT,VISITED_TIME,VISITAGE) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''PENDING7DAYS'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY VISITED_TIME) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,'
			SET @Strsql+='REPORTTO,SHOP_CODE,SHOP_NAME,SHOP_TYPE,SHOPLOCATION,SHOPCONTACT,VISITED_TIME,VISITAGE FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') '
			SET @Strsql+='AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO,SHOP.SHOP_CODE,SHOP.SHOP_NAME,SHOP.SHOP_TYPE,SHOP.SHOPLOCATION,'
			SET @Strsql+='SHOP.SHOPCONTACT,REPLACE(REPLACE(SHOP.VISITED_TIME,''AM'','' AM''),''PM'','' PM'') AS VISITED_TIME,TSHOP.VISITAGE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') '
			SET @Strsql+='AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT USR.user_id,SHOP.Shop_Code,SHOP.Shop_Name,SHOP.Address AS SHOPLOCATION,SHOP.Shop_CreateUser,SHOP.Shop_Owner_Contact AS SHOPCONTACT,CNT.cnt_internalId,'
			SET @Strsql+='CASE WHEN SHOP.TYPE=1 THEN ''Shop'' WHEN SHOP.TYPE=2 THEN ''PP'' WHEN SHOP.TYPE=3 THEN ''New Party'' WHEN SHOP.TYPE=4 THEN ''DD'' END AS SHOP_TYPE,'
			SET @Strsql+='MAX(CONVERT(NVARCHAR(10),SHOP.Lastvisit_date,105)+'' ''+CONVERT(VARCHAR(15),CAST(SHOP.Lastvisit_date as TIME),100)) AS VISITED_TIME '
			SET @Strsql+='FROM tbl_Master_shop SHOP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOP.Shop_CreateUser '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOP.Shop_CreateTime,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY USR.user_id,SHOP.Shop_Code,SHOP.Shop_Name,SHOP.Address,SHOP.Shop_CreateUser,SHOP.Shop_Owner_Contact,CNT.cnt_internalId,SHOP.TYPE '
			SET @Strsql+=') SHOP ON SHOP.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN #TEMPSHOP TSHOP ON TSHOP.EMPCODE=CNT.cnt_internalId AND TSHOP.USER_ID=USR.user_id AND TSHOP.SHOP_CODE=SHOP.Shop_Code '
			SET @Strsql+='WHERE NOT EXISTS(SELECT SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE_7+''',120) AND CONVERT(NVARCHAR(10),'''+@PREVIOUSDATE+''',120) '
			SET @Strsql+='AND SHOP.Shop_Code=SHOPACT.Shop_Id AND SHOP.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			IF @EMPID<>''
				SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
			IF @DESIGNID<>''
				SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DESG.DEG_ID) '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.ID) '
			SET @Strsql+=') AS DB '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	DROP TABLE #TEMPSHOP
END