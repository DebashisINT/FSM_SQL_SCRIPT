--EXEC PRC_FTSTARGETVSACHIEVEMENTDETAILS_REPORT 'FEB','EMS0000012',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTARGETVSACHIEVEMENTDETAILS_REPORT]') AND TYPE in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTARGETVSACHIEVEMENTDETAILS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTARGETVSACHIEVEMENTDETAILS_REPORT]
(
@MONTH NVARCHAR(3)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 07/02/2019
Module	   : Target Vs Achievement Details
1.0		v15.0.0		18/02/2019		Debashis		As peer discuss with pijush da, 
													1. Select Top 1 shop As descending order from master table with Assign To, if Null then chose Shop_Create_user.
													2. Now Shop can insert PP And DD both TYPE.
													FkEmployeeCounterType with 5 and 6.
													Now joining condition will FkEmployeeTargetSetteingID 
													5 - FOR PP
													6 - FOR DD . Refer mail: Employee Target modification
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX),@MONTHNAME NVARCHAR(3),@MONTHNO INT=0,@FROMDATE NVARCHAR(10),@TODATE NVARCHAR(10),@NOOFDAYS INT

	SET @MONTHNAME=@MONTH
	SET @MONTHNO=DATEPART(MM,@MONTHNAME+'01 1900')
	SET @FROMDATE=CONVERT(VARCHAR(10),DATEADD(MONTH, CONVERT(INT,@MONTHNO) - 1, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)),120)
	SET @TODATE=CONVERT(VARCHAR(10),DATEADD(DAY, -1, DATEADD(MONTH, CONVERT(INT,@MONTHNO), DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0))),120)
	SET @NOOFDAYS=(SELECT DATEDIFF(DD,@FROMDATE,@TODATE)+1)

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
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSTARGETVSACHIEVEMENTDETAILS_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSTARGETVSACHIEVEMENTDETAILS_REPORT
			(
			  USERID INT,
			  SEQ INT,
			  RPTTYPE NVARCHAR(10),
			  EMPCODE NVARCHAR(100) NULL,
			  EMPID NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  CONTACTNO NVARCHAR(50) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  SHOP_TYPE NVARCHAR(20),
			  SHOP_NAME NVARCHAR(100),
			  TGT_ORDERVALUE DECIMAL(38,2),
			  ACHV_ORDERVALUE DECIMAL(38,2),
			  TGT_COLLECTION DECIMAL(38,2),
			  ACHV_COLLECTION DECIMAL(38,2)
			)
			CREATE NONCLUSTERED INDEX IX ON FTSTARGETVSACHIEVEMENTDETAILS_REPORT (SEQ)
		END
	DELETE FROM FTSTARGETVSACHIEVEMENTDETAILS_REPORT WHERE USERID=@USERID 

	SET @Strsql=''
	SET @Strsql='INSERT INTO FTSTARGETVSACHIEVEMENTDETAILS_REPORT(USERID,SEQ,RPTTYPE,EMPCODE,EMPID,EMPNAME,CONTACTNO,STATEID,STATE,SHOP_TYPE,SHOP_NAME,TGT_ORDERVALUE,ACHV_ORDERVALUE,TGT_COLLECTION,ACHV_COLLECTION) '
	SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,ROW_NUMBER() OVER(ORDER BY SHOP_NAME) AS SEQ,''Details'' AS RPTTYPE,EMPCODE,EMPID,EMPNAME,CONTACTNO,STATEID,STATE,SHOP_TYPE,SHOP_NAME,'
	SET @Strsql+='TGT_ORDERVALUE,ACHV_ORDERVALUE,TGT_COLLECTION,ACHV_COLLECTION '
	SET @Strsql+='FROM('
	SET @Strsql+='SELECT EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='USR.user_loginId AS CONTACTNO,ST.ID AS STATEID,ST.STATE AS STATE,SHOP_TYPE,SHOP_NAME,ISNULL(EMPTGTSET.OrderValue,0) AS TGT_ORDERVALUE,ISNULL(EMPTGTSET.CollectionValue,0) AS TGT_COLLECTION,'	
	SET @Strsql+='ISNULL(ORDHEAD.Ordervalue,0) AS ACHV_ORDERVALUE,ISNULL(COLLEC.collectionvalue,0) AS ACHV_COLLECTION FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ('
	--Rev 1.0
	--SET @Strsql+='SELECT DISTINCT Shop_Code,Shop_CreateUser,Shop_Name,Address,Shop_Owner_Contact,assigned_to_pp_id,assigned_to_dd_id,CONVERT(NVARCHAR(10),Shop_CreateTime,105) AS Shop_CreateTime,Type, '
	SET @Strsql+='SELECT DISTINCT Shop_Code,CASE WHEN AssignTo IS NOT NULL THEN AssignTo ELSE Shop_CreateUser END AS USERID,Shop_Name,Address,Shop_Owner_Contact,assigned_to_pp_id,assigned_to_dd_id,CONVERT(NVARCHAR(10),Shop_CreateTime,105) AS Shop_CreateTime,Type, '
	--End of Rev 1.0
	SET @Strsql+='CASE WHEN TYPE=1 THEN ''Shop'' WHEN TYPE=2 THEN ''PP'' WHEN TYPE=3 THEN ''New Party'' WHEN TYPE=4 THEN ''DD'' END AS SHOP_TYPE FROM tbl_Master_shop '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Shop_CreateTime,120) <= CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--Rev 1.0
	--SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id '
	SET @Strsql+=') SHOP ON SHOP.USERID=USR.user_id '
	--End of Rev 1.0
	SET @Strsql+='LEFT OUTER JOIN(SELECT ETSH.EmployeeCode,NewCounter,Revisit,ETSD.Shop_Code,'
	SET @Strsql+='CASE WHEN ETSH.FKEmployeesCounterType=4 THEN ETSH.OrderValue ELSE ETSD.OrderValue END AS OrderValue,'
	SET @Strsql+='CASE WHEN ETSH.FKEmployeesCounterType=4 THEN ETSH.Collection ELSE ETSD.CollectionValue END AS CollectionValue '
	SET @Strsql+='FROM tbl_FTS_EmployeesTargetSetting ETSH '
	SET @Strsql+='INNER JOIN tbl_FTS_EmployeesTargetSettingCounterTarget ETSD ON ETSD.EmployeeCode=ETSH.EmployeeCode '
	--Rev 1.0
	SET @Strsql+='AND ETSH.EmployeeTargetSettingID=ETSD.FKEmployeeTargetSettingID '
	--End of Rev 1.0
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODATE+''',120) BETWEEN CONVERT(NVARCHAR(10),FromDate,120) AND CONVERT(NVARCHAR(10),ToDate,120) '
	SET @Strsql+=') EMPTGTSET ON EMPTGTSET.EmployeeCode=CNT.cnt_internalId AND SHOP.Shop_Code=EMPTGTSET.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT ORDH.userID,ORDH.Shop_Code,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue FROM tbl_trans_fts_Orderupdate ORDH '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY ORDH.userID,ORDH.Shop_Code,CNT.cnt_internalId '
	SET @Strsql+=') ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId AND SHOP.Shop_Code=ORDHEAD.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT COLLEC.user_id,COLLEC.shop_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue FROM tbl_FTS_collection COLLEC '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY COLLEC.user_id,COLLEC.shop_id,CNT.cnt_internalId '
	SET @Strsql+=') COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId AND SHOP.Shop_Code=COLLEC.shop_id '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS RPTTOEMPCODE,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='WHERE RPTTO.RPTTOEMPCODE IS NOT NULL '
	SET @Strsql+=') AS DB '
	IF @EMPID<>''
		SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
	SET @Strsql+='ORDER BY SHOP_NAME '
	SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT
END