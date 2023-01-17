--EXEC PRC_FTSCUSTOMERVISITDETAILS_REPORT '2021-02-01','2021-03-31','','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSCUSTOMERVISITDETAILS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSCUSTOMERVISITDETAILS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSCUSTOMERVISITDETAILS_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 31/03/2021
Module	   : Employee Performance Details.Refer: 0023862
1.0			TANMOY			22-04-2021			Electrician type and Electrician name  correction Ref:0023987
2.0		v2.0.38		Sanchita	12-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX),@isRevisitTeamDetail NVARCHAR(100)

	SELECT @isRevisitTeamDetail=[Value] FROM fts_app_config_settings WHERE [Key]='isRevisitTeamDetail' AND [Description]='Revisit from Team Details in Portal'

	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
		DROP TABLE #STATEID_LIST
	CREATE TABLE #STATEID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
	IF @STATEID <> ''
		BEGIN
			SET @STATEID=REPLACE(@STATEID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable='INSERT INTO #STATEID_LIST SELECT id from tbl_master_state WHERE ID IN('+@STATEID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DESIGNID <> ''
		BEGIN
			SET @DESIGNID=REPLACE(@DESIGNID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable='INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation WHERE deg_id IN('+@DESIGNID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee WHERE emp_contactId IN('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	-- Rev 2.0
	DECLARE @user_contactId NVARCHAR(15)
	SELECT @user_contactId=user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@USERID

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		CREATE TABLE #EMPHR
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)

		CREATE TABLE #EMPHR_EDIT
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)
		
		INSERT INTO #EMPHR
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
		FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
		;with cte as(select	
		EMPCODE,RPTTOEMPCODE
		from #EMPHR 
		where EMPCODE IS NULL OR EMPCODE=@user_contactId  
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
	-- End of Rev 2.0

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	-- Rev 2.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT CNT '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
	END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
	exec sp_executesql @Strsql
	-- End of Rev 2.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSCUSTOMERVISITDETAILS_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSCUSTOMERVISITDETAILS_REPORT
			(
			  USERID INT,
			  SEQ INT,
			  LOGIN_DATETIMEORDBY NVARCHAR(10),
			  WORK_DATE NVARCHAR(10),
			  LOGGEDIN NVARCHAR(100) NULL,
			  LOGEDOUT NVARCHAR(100) NULL,
			  CONTACTNO NVARCHAR(50) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  BRANCHDESC NVARCHAR(300),
			  OFFICE_ADDRESS NVARCHAR(300),
			  ATTEN_STATUS NVARCHAR(20),
			  EMPCODE NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  EMPID NVARCHAR(100) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  DATEOFJOINING NVARCHAR(10),
			  REPORTTO NVARCHAR(300) NULL,
			  RPTTODESG NVARCHAR(50) NULL,
			  CUSTTYPE NVARCHAR(100),
			  ENTITYTYPE NVARCHAR(300) NULL,
			  CUSTNAME NVARCHAR(300) NULL,
			  GPTPLNAME NVARCHAR(300) NULL,
			  COMPNAME NVARCHAR(300) NULL,
			  SHOPADDRESS NVARCHAR(500) NULL,
			  CHECKIN_TIME NVARCHAR(100) NULL,
			  CHECKIN_ADDRESS NVARCHAR(500) NULL,
			  CHECKOUT_TIME NVARCHAR(100) NULL,
			  CHECKOUT_ADDRESS NVARCHAR(500) NULL,
			  TOTTIMESPENT NVARCHAR(100) NULL,			  
			  VISITREMARKS NVARCHAR(1000),
			  MEETINGREMARKS NVARCHAR(1000),
			  VISITPURPOSE NVARCHAR(1000)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSCUSTOMERVISITDETAILS_REPORT (SEQ)
		END
	DELETE FROM FTSCUSTOMERVISITDETAILS_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	SET @Strsql='INSERT INTO FTSCUSTOMERVISITDETAILS_REPORT(USERID,SEQ,LOGIN_DATETIMEORDBY,WORK_DATE,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,BRANCHDESC,OFFICE_ADDRESS,ATTEN_STATUS,EMPCODE,EMPNAME,'
	SET @Strsql+='EMPID,DEG_ID,DESIGNATION,DATEOFJOINING,REPORTTO,RPTTODESG,CUSTTYPE,ENTITYTYPE,CUSTNAME,GPTPLNAME,COMPNAME,SHOPADDRESS,CHECKIN_TIME,CHECKIN_ADDRESS,CHECKOUT_TIME,CHECKOUT_ADDRESS,'
	SET @Strsql+='TOTTIMESPENT,VISITREMARKS,MEETINGREMARKS,VISITPURPOSE) '
	SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY LOGIN_DATETIMEORDBY) AS SEQ,LOGIN_DATETIMEORDBY,LOGIN_DATETIME,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,'
	SET @Strsql+='BRANCHDESC,OFFICE_ADDRESS,ATTEN_STATUS,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,DATEOFJOINING,REPORTTO,RPTTODESG,CUSTTYPE,ENTITYTYPE,CUSTNAME,GPTPLNAME,COMPNAME,SHOPADDRESS,CHECKIN_TIME,'
	SET @Strsql+='CHECKIN_ADDRESS,CHECKOUT_TIME,CHECKOUT_ADDRESS,TOTTIMESPENT,VISITREMARKS,MEETINGREMARKS,CASE WHEN CUSTNAME<>''Meeting'' THEN VISITREMARKS ELSE MEETINGREMARKS END AS VISITPURPOSE '
	SET @Strsql+='FROM('
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ST.ID AS STATEID,ST.state AS STATE,BR.branch_description AS BRANCHDESC,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	SET @Strsql+='USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,RPTTO.RPTTODESG,Login_datetimeORDBY,LOGIN_DATETIME,ATTEN.LOGGEDIN AS LOGGEDIN,ATTEN.LOGEDOUT AS LOGEDOUT,'
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,ATTEN_STATUS,'	
	--Rev 1.0 Start
	--SET @Strsql+='SHOP.CUSTTYPE,SHOP.Shop_Code AS CUSTCODE,SHOP.Shop_Name AS CUSTNAME,SHOP.Address AS SHOPADDRESS,SHOP.Shop_Owner_Contact AS CUSTMOB,SHOPPP.Shop_Name AS COMPNAME, '
	SET @Strsql+='SHOP.CUSTTYPE,SHOP.Shop_Code AS CUSTCODE,SHOP.Shop_Name AS CUSTNAME,SHOP.Address AS SHOPADDRESS,SHOP.Shop_Owner_Contact AS CUSTMOB,SHOPCUS.Shop_Name AS COMPNAME,'
	--Rev 1.0 End
	SET @Strsql+='SHOP.ELECTRICIANADD,SHOP.ELECTRICIANMOB,SHOPDD.Shop_Name AS GPTPLNAME,SHOPDD.Address AS GPTPLADD,SHOPDD.Shop_Owner_Contact AS GPTPLMOB,SHOP.ELECTRICIAN,'
	SET @Strsql+='CASE WHEN SHOP.CUSTTYPE=''Entity'' THEN SHOP.ENTITY ELSE '''' END AS ENTITYTYPE,SHOPACT.VISITREMARKS,SHOPACT.MEETINGREMARKS,SHOPACT.CHECKIN_TIME,SHOPACT.CHECKIN_ADDRESS,SHOPACT.CHECKOUT_TIME,'	
	SET @Strsql+='SHOPACT.CHECKOUT_ADDRESS,SHOPACT.TOTTIMESPENT FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,Login_datetimeORDBY,ATTEN_STATUS FROM('
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetimeORDBY,CASE WHEN Isonleave=''false'' THEN ''At Work'' ELSE ''On Leave'' END AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL '
	SET @Strsql+='AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120),ATTEN.Work_Address,ATTEN.Isonleave '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetimeORDBY,CASE WHEN Isonleave=''false'' THEN ''At Work'' ELSE ''On Leave'' END AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL '
	SET @Strsql+='AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120),ATTEN.Work_Address,ATTEN.Isonleave '
	SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,Login_datetimeORDBY,ATTEN_STATUS '
	SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,SUM(NEWSHOP_VISITED) AS NEWSHOP_VISITED,SUM(RE_VISITED) AS RE_VISITED,SUM(TOTMETTING) AS TOTMETTING,SPENT_DURATION,SUM(DISTANCE_TRAVELLED) AS DISTANCE_TRAVELLED,'
	SET @Strsql+='VISITED_TIME,SHPVISITTIME,VISITTYPE,VISITREMARKS,MEETINGREMARKS,MEETING_ADDRESS,CHECKIN_TIME,CHECKIN_ADDRESS,CHECKOUT_TIME,CHECKOUT_ADDRESS,'
	SET @Strsql+='RIGHT(''0'' + CAST((DATEDIFF(SS,CheckIn_Time,CheckOut_Time)) / 3600 AS VARCHAR),2) + '':'' + '
	SET @Strsql+='RIGHT(''0'' + CAST(((DATEDIFF(SS,CheckIn_Time,CheckOut_Time)) / 60) % 60 AS VARCHAR),2) + '':'' + '
	SET @Strsql+='RIGHT(''0'' + CAST((DATEDIFF(SS,CheckIn_Time,CheckOut_Time)) % 60 AS VARCHAR),2) AS TOTTIMESPENT FROM('
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,COUNT(SHOPACT.Shop_Id) AS NEWSHOP_VISITED,0 AS RE_VISITED,0 AS TOTMETTING,SPENT_DURATION,'
	SET @Strsql+='SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITED_TIME,CONVERT(VARCHAR(8),CAST(SHOPACT.visited_time AS TIME),108) AS SHPVISITTIME,'
	SET @Strsql+='''New Visit'' AS VISITTYPE,SHOPACT.REMARKS AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS MEETING_ADDRESS,SHOPACT.CheckIn_Time,SHOPACT.CheckIn_Address,SHOPACT.CheckOut_Time,SHOPACT.CheckOut_Address '
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.Is_Newshopadd=1 '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.VISITED_TIME,SPENT_DURATION,SHOPACT.REMARKS,SHOPACT.CheckIn_Time,SHOPACT.CheckIn_Address,SHOPACT.CheckOut_Time,SHOPACT.CheckOut_Address '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.Shop_Id) AS RE_VISITED,0 AS TOTMETTING,SPENT_DURATION,'
	SET @Strsql+='SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITED_TIME,CONVERT(VARCHAR(8),CAST(SHOPACT.visited_time AS TIME),108) AS SHPVISITTIME,'
	SET @Strsql+='''ReVisit'' AS VISITTYPE,SHOPACT.REMARKS AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS MEETING_ADDRESS,SHOPACT.CheckIn_Time,SHOPACT.CheckIn_Address,SHOPACT.CheckOut_Time,SHOPACT.CheckOut_Address '
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.Is_Newshopadd=0 AND SHOPACT.ISMEETING=0 '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.VISITED_TIME,SPENT_DURATION,SHOPACT.REMARKS,SHOPACT.CheckIn_Time,SHOPACT.CheckIn_Address,SHOPACT.CheckOut_Time,SHOPACT.CheckOut_Address '
	--MEETING
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,0 AS RE_VISITED,COUNT(SHOPACT.Shop_Id) AS TOTMETTING,SPENT_DURATION,0 AS DISTANCE_TRAVELLED,'
	SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITED_TIME,CONVERT(VARCHAR(8),CAST(SHOPACT.visited_time AS TIME),108) AS SHPVISITTIME,''Meeting'' AS VISITTYPE,'''' AS VISITREMARKS,'
	SET @Strsql+='SHOPACT.REMARKS AS MEETINGREMARKS,SHOPACT.MEETING_ADDRESS,SHOPACT.CheckIn_Time,SHOPACT.CheckIn_Address,SHOPACT.CheckOut_Time,SHOPACT.CheckOut_Address FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.ISMEETING=1 AND SHOPACT.MEETING_TYPEID IS NOT NULL '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,SHOPACT.VISITED_TIME,SPENT_DURATION,SHOPACT.REMARKS,SHOPACT.MEETING_ADDRESS,SHOPACT.CheckIn_Time,SHOPACT.CheckIn_Address,SHOPACT.CheckOut_Time,SHOPACT.CheckOut_Address '
	SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId,Shop_Id,VISITED_TIME,SHPVISITTIME,VISITTYPE,VISITREMARKS,SPENT_DURATION,MEETINGREMARKS,MEETING_ADDRESS,CHECKIN_TIME,CHECKIN_ADDRESS,CHECKOUT_TIME,CHECKOUT_ADDRESS '
	SET @Strsql+=') SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=SHOPACT.VISITED_TIME '
	SET @Strsql+='LEFT OUTER JOIN ('
	--Rev 1.0 Start
	--SET @Strsql+='SELECT DISTINCT MS.Shop_Code,MS.Shop_CreateUser,MS.Shop_Name,MS.Address,MS.Shop_Owner_Contact,MS.assigned_to_pp_id,MS.assigned_to_dd_id,MS.type,MS.EntityCode,'
	SET @Strsql+='SELECT DISTINCT MS.Shop_Code,MS.Shop_CreateUser,MS.Shop_Name,MS.Address,MS.Shop_Owner_Contact,MS.assigned_to_pp_id,MS.assigned_to_dd_id,MS.assigned_to_shop_id,MS.type,MS.EntityCode,'
	--Rev 1.0 END
	SET @Strsql+='CASE WHEN TYPE=1 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.retailer_id) '
	SET @Strsql+='WHEN TYPE=2 THEN ''Company Name'' '
	--Rev 1.0 Start
	--SET @Strsql+='WHEN TYPE=4 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.dealer_id)  END AS CUSTTYPE,'
	SET @Strsql+='WHEN TYPE=4 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.dealer_id) ELSE (SELECT STYPD.Name FROM TBL_SHOPTYPE STYPD WHERE STYPD.TypeId=MS.TYPE) END AS CUSTTYPE,'
	--Rev 1.0 END
	SET @Strsql+='ENT.ENTITY,CASE WHEN MS.type=11 THEN MS.Shop_Name ELSE '''' END AS ELECTRICIAN,'
	SET @Strsql+='CASE WHEN MS.type=11 THEN MS.Address ELSE '''' END AS ELECTRICIANADD,'
	SET @Strsql+='CASE WHEN MS.type=11 THEN MS.Shop_Owner_Contact ELSE '''' END AS ELECTRICIANMOB '
	SET @Strsql+='FROM tbl_Master_shop MS '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EN.ENTITY,MSTSHP.Shop_Code FROM FSM_ENTITY EN '
	SET @Strsql+='INNER JOIN tbl_Master_shop MSTSHP ON EN.ID=MSTSHP.Entity_Id '
	SET @Strsql+=') ENT ON MS.Shop_Code=ENT.Shop_Code '
	SET @Strsql+=') SHOP ON SHOP.Shop_Code=SHOPACT.Shop_Id '
	SET @Strsql+='LEFT OUTER JOIN('
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A ) SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code ' 
	SET @Strsql+='LEFT OUTER JOIN(SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A ) SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	--Rev 1.0 Start
	SET @Strsql+='LEFT OUTER JOIN(SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_shop_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A ) SHOPCUS ON SHOP.assigned_to_shop_id=SHOPCUS.Shop_Code '
	--Rev 1.0 End
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ST.ID AS STATEID,ST.state AS STATE,BR.branch_description AS BRANCHDESC,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	SET @Strsql+='USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,RPTTO.RPTTODESG,LOGIN_DATETIMEORDBY,LOGIN_DATETIME,ATTEN.LOGGEDIN AS LOGGEDIN,ATTEN.LOGEDOUT AS LOGEDOUT,'
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,ATTEN_STATUS,'''' AS CUSTTYPE,'''' AS CUSTCODE,'
	SET @Strsql+=''''' AS CUSTNAME,'''' AS SHOPADDRESS,'''' AS CUSTMOB,'''' AS COMPNAME,'''' AS ELECTRICIANADD,'''' AS ELECTRICIANMOB,'''' AS GPTPLNAME,'''' AS GPTPLADD,'''' AS GPTPLMOB,'''' AS ELECTRICIAN,'
	SET @Strsql+=''''' AS ENTITYTYPE,'''' AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS CHECKIN_TIME,'''' AS CHECKIN_ADDRESS,'''' AS CHECKOUT_TIME,'''' AS CHECKOUT_ADDRESS,'''' AS TOTTIMESPENT '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL '
	SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,Login_datetimeORDBY,ATTEN_STATUS FROM('
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetimeORDBY,''On Leave'' AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL '
	SET @Strsql+='AND Isonleave=''true'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetimeORDBY,''On Leave'' AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL '
	SET @Strsql+='AND Isonleave=''true'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) '
	SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,Login_datetimeORDBY,ATTEN_STATUS '
	SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	SET @Strsql+=') AS DB '
	IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
		SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
		SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
	ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
		SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
	ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
		END
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
		END
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	-- Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 2.0


	SET NOCOUNT OFF
END