--EXEC PRC_FTSORDERWITHPRODUCTATTRIBUTE_REPORT '2020-06-01','2022-07-31','','','',378
--EXEC PRC_FTSORDERWITHPRODUCTATTRIBUTE_REPORT '2020-06-01','2021-10-31','','','EMS0000005',11722

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSORDERWITHPRODUCTATTRIBUTE_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSORDERWITHPRODUCTATTRIBUTE_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSORDERWITHPRODUCTATTRIBUTE_REPORT]
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
Written by : Debashis Talukder on 19/10/2021
Module	   : Order Register List. Refer: 0024388
1.0		v2.0.31		Debashis	22/07/2022		Rate & Order Value column required in Order Register List report in FSM.Refer: 0025066
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX),@isRevisitTeamDetail NVARCHAR(100)
	SELECT @isRevisitTeamDetail=[Value] FROM fts_app_config_settings WHERE [Key]='isRevisitTeamDetail' AND [Description]='Revisit from Team Details in Portal'

	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
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
	
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
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

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
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
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE USER_ID=@USERID)=1)
		BEGIN
			DECLARE @empcodes NVARCHAR(50)=(SELECT user_contactId FROM Tbl_master_user WHERE USER_ID=@USERID)		
			CREATE TABLE #EMPHRS
			(
			EMPCODE NVARCHAR(50),
			RPTTOEMPCODE NVARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE NVARCHAR(50),
			RPTTOEMPCODE NVARCHAR(50)
			)
		
			INSERT INTO #EMPHRS(EMPCODE,RPTTOEMPCODE)
			SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') AS RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT OUTER JOIN tbl_master_employee TME ON TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;WITH cte AS(SELECT	
			EMPCODE,RPTTOEMPCODE FROM #EMPHRS 
			WHERE EMPCODE IS NULL OR EMPCODE=@empcodes  
			UNION ALL
			SELECT a.EMPCODE,a.RPTTOEMPCODE FROM #EMPHRS a
			INNER JOIN cte b ON a.RPTTOEMPCODE=b.EMPCODE
			)
			INSERT INTO #EMPHR_EDIT(EMPCODE,RPTTOEMPCODE)
			SELECT EMPCODE,RPTTOEMPCODE FROM cte
		END

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSORDERWITHPRODUCTATTRIBUTE_REPORT') AND TYPE IN (N'U'))
		BEGIN
			--Rev 1.0 && Added two columns as RATE DECIMAL(18,2) & TOTAMOUNT DECIMAL(18,2)
			CREATE TABLE FTSORDERWITHPRODUCTATTRIBUTE_REPORT
			(
			  USERID INT,
			  SEQ BIGINT,
			  EMPCODE NVARCHAR(100) NULL,
			  EMPID NVARCHAR(100) NULL,
			  EMPRID BIGINT,
			  EMPNAME NVARCHAR(300) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  BRANCHDESC NVARCHAR(300),
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  DATEOFJOINING NVARCHAR(10),
			  CONTACTNO NVARCHAR(50) NULL,
			  REPORTTO NVARCHAR(300) NULL,
			  RPTTODESG NVARCHAR(50) NULL,			  
			  OFFICE_ADDRESS NVARCHAR(300),
			  SHOP_TYPE NVARCHAR(10),
			  SHOP_CODE NVARCHAR(100),
			  SHOP_NAME NVARCHAR(300) NULL,
			  SHOPADDRESS NVARCHAR(500) NULL,
			  SHOP_CONTACT NVARCHAR(300) NULL,			  
			  PP_NAME NVARCHAR(300) NULL,
			  PPADDR_CONTACT NVARCHAR(300) NULL,
			  DD_NAME NVARCHAR(300) NULL,
			  DDADDR_CONTACT NVARCHAR(300) NULL,
			  ORDER_DATE NVARCHAR(10),
			  ORDER_NO NVARCHAR(200),
			  GENDER NVARCHAR(10),
			  PRODUCT_NAME NVARCHAR(300),
			  COLORRID BIGINT,
			  COLOR_NAME NVARCHAR(300),
			  SIZE NVARCHAR(300),
			  QUANTITY DECIMAL(38,2),
			  RATE DECIMAL(18,2),
			  TOTAMOUNT DECIMAL(18,2)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSORDERWITHPRODUCTATTRIBUTE_REPORT (SEQ)
		END
	DELETE FROM FTSORDERWITHPRODUCTATTRIBUTE_REPORT WHERE USERID=@USERID

	--Rev 1.0 && Added two columns as RATE & TOTAMOUNT
	SET @Strsql=''
	SET @Strsql='INSERT INTO FTSORDERWITHPRODUCTATTRIBUTE_REPORT(USERID,SEQ,EMPCODE,EMPID,EMPRID,EMPNAME,STATEID,STATE,BRANCHDESC,DEG_ID,DESIGNATION,DATEOFJOINING,CONTACTNO,REPORTTO,RPTTODESG,OFFICE_ADDRESS,'
	SET @Strsql+='SHOP_TYPE,SHOP_CODE,SHOP_NAME,SHOPADDRESS,SHOP_CONTACT,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,ORDER_DATE,ORDER_NO,GENDER,PRODUCT_NAME,COLORRID,COLOR_NAME,SIZE,QUANTITY,RATE,TOTAMOUNT) '
	SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,ROW_NUMBER() OVER(ORDER BY EMPCODE) AS SEQ,EMPCODE,EMPID,EMPRID,EMPNAME,STATEID,STATE,BRANCHDESC,DEG_ID,DESIGNATION,DATEOFJOINING,CONTACTNO,'
	SET @Strsql+='REPORTTO,RPTTODESG,OFFICE_ADDRESS,SHOP_TYPE,SHOP_CODE,SHOP_NAME,SHOPADDRESS,SHOP_CONTACT,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,ORDER_DATE,ORDER_ID,GENDER,PRODUCT_NAME,COLORRID,'
	SET @Strsql+='COLOR_NAME,SIZE,QTY,RATE,TOTAMOUNT FROM('
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ROW_NUMBER() OVER(PARTITION BY CNT.cnt_internalId ORDER BY CNT.cnt_internalId) AS EMPRID,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,BR.branch_description AS BRANCHDESC,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,'
	SET @Strsql+='CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,RPTTO.RPTTODESG,'
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,ISNULL(SHOP.SHOP_TYPE,''Meeting'') AS SHOP_TYPE,'
	SET @Strsql+='SHOP.Shop_Code,SHOP.Shop_Name,SHOP.Address AS SHOPADDRESS,SHOP.Shop_Owner_Contact AS SHOP_CONTACT,SHOPPP.Shop_Name AS PP_NAME,SHOPPP.Address+'' ''+SHOPPP.Shop_Owner_Contact AS PPADDR_CONTACT,'
	SET @Strsql+='SHOPDD.Shop_Name AS DD_NAME,SHOPDD.Address+'' ''+SHOPDD.Shop_Owner_Contact AS DDADDR_CONTACT,ORDHEAD.ORDER_DATE,ORDHEAD.ORDER_ID,ORDHEAD.GENDER,ORDHEAD.PRODUCT_NAME,'
	SET @Strsql+='ROW_NUMBER() OVER(PARTITION BY CNT.cnt_internalId,ORDHEAD.ORDDATE,ORDHEAD.COLOR_NAME ORDER BY CNT.cnt_internalId,ORDHEAD.ORDDATE,ORDHEAD.COLOR_NAME) AS COLORRID,ORDHEAD.COLOR_NAME,'
	SET @Strsql+='ORDHEAD.SIZE,ORDHEAD.QTY,ORDHEAD.RATE,ORDHEAD.TOTAMOUNT '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE USER_ID=@USERID)=1)
		SET @Strsql+='INNER JOIN #EMPHR_EDIT EMPHR ON EMPHR.EMPCODE=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT USERID,cnt_internalId,Login_datetime FROM( '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId,CAST(ATTEN.Work_datetime AS DATE) AS Login_datetime '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CAST(ATTEN.Work_datetime AS DATE) '
	SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	SET @Strsql+='LEFT OUTER JOIN ( '
	SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,visited_time FROM('
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,CAST(SHOPACT.visited_time AS date) AS visited_time '
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,CAST(SHOPACT.visited_time AS date) '
	SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId,Shop_Id,VISITED_TIME) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=SHOPACT.VISITED_TIME '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT DISTINCT Shop_Code,Shop_CreateUser,Shop_Name,Address,Shop_Owner_Contact,assigned_to_pp_id,assigned_to_dd_id,Type,'
	SET @Strsql+='CASE WHEN TYPE=1 THEN ''Shop'' WHEN TYPE=2 THEN ''PP'' WHEN TYPE=3 THEN ''New Party'' WHEN TYPE=4 THEN ''DD'' WHEN TYPE=5 THEN ''Diamond'' '
	SET @Strsql+='WHEN TYPE=6 THEN ''Stockist'' WHEN TYPE=7 THEN ''Chemist'' WHEN TYPE=8 THEN ''Doctor'' WHEN TYPE=999 THEN ''Meeting'' END AS SHOP_TYPE '
	SET @Strsql+='FROM tbl_Master_shop '
	IF @isRevisitTeamDetail='1'
		SET @Strsql+=') SHOP ON SHOP.Shop_Code=SHOPACT.Shop_Id '
	ELSE IF @isRevisitTeamDetail='0'
		SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id AND SHOP.Shop_Code=SHOPACT.Shop_Id '
	SET @Strsql+='LEFT OUTER JOIN('
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	SET @Strsql+='INNER JOIN (SELECT ORDH.USER_ID,ORDH.ORDER_ID,CONVERT(NVARCHAR(10),ORDH.ORDER_DATE,105) AS ORDER_DATE,CAST(ORDH.ORDER_DATE AS DATE) AS ORDDATE,ORDH.SHOP_ID,CNT.cnt_internalId,'
	SET @Strsql+='CASE WHEN (ORDD.GENDER=''M'' OR ORDD.GENDER=''Male'') THEN ''Male'' WHEN (ORDD.GENDER=''F'' OR ORDD.GENDER=''Female'') THEN ''Female'' WHEN ORDD.GENDER=''Men'' THEN ''Men'' '
	SET @Strsql+='WHEN ORDD.GENDER=''Women'' THEN ''Women'' END AS GENDER,ORDD.PRODUCT_ID,ORDD.PRODUCT_NAME,MC.COLOR_NAME,ORDD.SIZE,ORDD.QTY,ORDD.RATE,(ORDD.QTY*ORDD.RATE) AS TOTAMOUNT '
	SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE ORDH '
	SET @Strsql+='INNER JOIN ORDERPRODUCTATTRIBUTEDET ORDD ON ORDH.ID=ORDD.ID AND ORDH.USER_ID=ORDD.USER_ID AND ORDH.ORDER_ID=ORDD.ORDER_ID '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.USER_ID '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='LEFT OUTER JOIN Master_Color MC ON ORDD.COLOR_ID=CAST(MC.Color_ID AS nvarchar) '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+=') ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=ORDHEAD.ORDDATE AND ORDHEAD.SHOP_ID=SHOP.SHOP_CODE '
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
	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE USER_ID=@USERID)=1)
		BEGIN
			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END

	SET NOCOUNT OFF
END