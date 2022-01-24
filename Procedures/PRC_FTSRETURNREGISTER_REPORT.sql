--EXEC PRC_FTSRETURNREGISTER_REPORT '2021-04-01','2022-01-31','15','14','EMS0000005',378
--EXEC PRC_FTSRETURNREGISTER_REPORT '2021-04-01','2022-01-31','','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSRETURNREGISTER_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSRETURNREGISTER_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSRETURNREGISTER_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/**********************************************************************************************************************************************************************************************************
Written by : Debashis Talukder On 18/01/2022
Module	   : Return Register.Refer: 0024605
**********************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX)

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
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId FROM tbl_master_employee WHERE emp_contactId IN('+@EMPID+')'
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

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSRETURNREGISTER_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSRETURNREGISTER_REPORT
			(
			  USERID INT,
			  SEQ INT,
			  USER_ID BIGINT,
			  EMPID NVARCHAR(100) NULL,
			  EMPCODE NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  CONTACTNO NVARCHAR(50) NULL,
			  REPORTTO NVARCHAR(300) NULL,
			  RPTTODESG NVARCHAR(50) NULL,
			  SHOP_TYPE NVARCHAR(10),
			  SHOP_CODE NVARCHAR(100) NULL,
			  SHOP_NAME NVARCHAR(4000) NULL,
			  SHOPCONTACTNO NVARCHAR(100) NULL,
			  BRANCHDESC NVARCHAR(300),
			  ENTITYCODE NVARCHAR(600) NULL,
			  SHOP_ADDRESS NVARCHAR(MAX) NULL,
			  PP_NAME NVARCHAR(300) NULL,
			  DD_NAME NVARCHAR(300) NULL,
			  RETURNDATE NVARCHAR(10),
			  RETURNNO NVARCHAR(200) NULL,
			  PRODUCT_NAME NVARCHAR(1000),
			  QUANTITY DECIMAL(18,2) NULL,
			  RATE DECIMAL(18,2) NULL,
			  AMOUNT DECIMAL(18,2) NULL
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSRETURNREGISTER_REPORT (SEQ)
		END
	DELETE FROM FTSRETURNREGISTER_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	SET @Strsql='INSERT INTO FTSRETURNREGISTER_REPORT(USERID,SEQ,USER_ID,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,SHOPCONTACTNO,'
	SET @Strsql+='BRANCHDESC,ENTITYCODE,SHOP_ADDRESS,PP_NAME,DD_NAME,RETURNDATE,RETURNNO,PRODUCT_NAME,QUANTITY,RATE,AMOUNT) '
	SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,ROW_NUMBER() OVER(ORDER BY EMP.emp_uniqueCode) AS SEQ,USR.USER_ID,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ST.ID AS STATEID,ST.state AS STATE,DESG.DEG_ID,'
	SET @Strsql+='DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,RPTTO.RPTTODESG,SHOP.SHOP_TYPE,SHOP.SHOP_CODE,SHOP.SHOP_NAME,SHOP.Shop_Owner_Contact AS SHOPCONTACTNO,'
	SET @Strsql+='BR.branch_description AS BRANCHDESC,SHOP.ENTITYCODE,SHOP.Address AS SHOP_ADDRESS,SHOPPP.Shop_Name AS PP_NAME,SHOPDD.Shop_Name AS DD_NAME,CONVERT(NVARCHAR(10),RETH.RETURN_DATE_TIME,105) AS RETURNDATE,'
	SET @Strsql+='RETH.RETURN_ID AS RETURNNO,RETD.PRODUCT_NAME,RETD.QTY,RETD.RATE,RETD.TOTAL_PRICE '
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
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL '
	SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT USERID,cnt_internalId,LOGGEDINDATE FROM('
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS LOGGEDINDATE '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+=') LOGINLOGOUT) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,VISITDATE FROM('
	SET @Strsql+='SELECT SHOPACT.User_Id,SHOPACT.Shop_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITDATE '
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+=') AA) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND SHOPACT.User_Id=ATTEN.USERID AND ATTEN.LOGGEDINDATE=SHOPACT.VISITDATE '	
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT DISTINCT shop.Shop_Code,shop.Shop_CreateUser,shop.Shop_Name,shop.Address,shop.Shop_Owner_Contact,shop.assigned_to_pp_id,shop.assigned_to_dd_id,shop.Type,shop.EntityCode,'
	SET @Strsql+='CASE WHEN shop.TYPE=1 THEN ''Shop'' WHEN shop.TYPE=2 THEN ''PP'' WHEN shop.TYPE=3 THEN ''New Party'' WHEN shop.TYPE=4 THEN ''DD'' WHEN shop.TYPE=5 THEN ''Diamond'' '
	SET @Strsql+='WHEN shop.TYPE=6 THEN ''Stockist'' WHEN shop.TYPE=7 THEN ''Chemist'' WHEN shop.TYPE=8 THEN ''Doctor'' WHEN shop.TYPE=999 THEN ''Meeting'' END AS SHOP_TYPE,'
	SET @Strsql+='shop.Pincode,CITY.CITY_NAME,shop.CLUSTER,shop.Alt_MobileNo1,shop.Shop_Owner_Email2 '
	SET @Strsql+='FROM tbl_Master_shop shop '
	SET @Strsql+='LEFT OUTER JOIN TBL_MASTER_CITY CITY ON shop.Shop_City=CITY.city_id '
	SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id AND SHOP.Shop_Code=SHOPACT.Shop_Id '
	SET @Strsql+='LEFT OUTER JOIN('
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	SET @Strsql+='INNER JOIN FSMAPIRUBYFOODORDERRETURN RETH ON USR.USER_ID=RETH.USER_ID AND SHOP.Shop_Code=RETH.SHOP_ID '
	SET @Strsql+='INNER JOIN FSMAPIRUBYFOODORDERRETURNDET RETD ON RETH.ID=RETD.HEADID AND RETH.USER_ID=RETD.USER_ID AND RETH.SHOP_ID=RETD.SHOP_ID AND RETH.RETURN_ID=RETD.RETURN_ID '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),RETH.RETURN_DATE_TIME,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @STATEID<>''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
	IF @DESIGNID<>''
		SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DESG.DEG_ID) '
	IF @EMPID<>''
		SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT

	SET NOCOUNT OFF
END