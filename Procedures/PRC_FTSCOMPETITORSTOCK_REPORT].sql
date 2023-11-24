IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSCOMPETITORSTOCK_REPORT]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSCOMPETITORSTOCK_REPORT] AS'  
END 
GO
--EXEC PRC_FTSCOMPETITORSTOCK_REPORT @FROMDATE='2021-06-01',@TODATE='2021-06-24',@USERID=378
ALTER PROCEDURE [dbo].[PRC_FTSCOMPETITORSTOCK_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@SHOPID NVARCHAR(MAX)=NULL,
--@USERLIST NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT 
)  
AS
/**************************************************************************************************************************************************************************** 
1.0			v2.0.11		Debashis	12/05/2020		FTS reports with more fields.Refer: 0022323
2.0			v2.0.43		Priti	22/11/2023	    Dashboard report issue(check in local Rubyfoods db).Refer:0027026
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	--DECLARE @isRevisitTeamDetail NVARCHAR(100)
	--SELECT @isRevisitTeamDetail=[Value] FROM fts_app_config_settings WHERE [Key]='isRevisitTeamDetail' AND [Description]='Revisit from Team Details in Portal'
	
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

	IF OBJECT_ID('tempdb..#SHOPID_LIST') IS NOT NULL
		DROP TABLE #SHOPID_LIST
	CREATE TABLE #SHOPID_LIST (Shop_ID INT)
	CREATE NONCLUSTERED INDEX IX1 ON #SHOPID_LIST (Shop_ID ASC)
	IF @SHOPID <> ''
		BEGIN
			SET @SHOPID=REPLACE(@SHOPID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #SHOPID_LIST SELECT Shop_ID from tbl_Master_shop where Shop_ID in('+@SHOPID+')'
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
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,ISNULL(cnt_UCC,'') FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSCOMPETITORSTOCK_REPORT') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTSCOMPETITORSTOCK_REPORT
		(
		  USERID INT,
		  SEQ INT,
		  EMPCODE NVARCHAR(100) NULL,
		  EMPNAME NVARCHAR(300) NULL,
		  BRANCHDESC NVARCHAR(300),
		  SHOPNAME NVARCHAR(100) NULL,
		  ENTITYCODE NVARCHAR(600) NULL,
		  ADDRESS NVARCHAR(MAX) NULL,
		  CONTACT NVARCHAR(100) NULL,
		  SHOPTYPE NVARCHAR(50) NULL,
		  COMPETITORSTKDATE NVARCHAR(10) NULL,
		  COMPETITORSTKID BIGINT,
		  COMPETITORSTKNO NVARCHAR(60) NULL,
		  PRODUCT NVARCHAR(500) NULL,
		  QUANTITY DECIMAL(10,2),
		  RATE DECIMAL(10,2),
		  STOCKVALUE DECIMAL(10,2),
		  PPName NVARCHAR(100) NULL,
		  DDName NVARCHAR(100) NULL,
		  Employee_ID NVARCHAR(100) NULL
		)
		CREATE NONCLUSTERED INDEX IX1 ON FTSCOMPETITORSTOCK_REPORT (SEQ)
	END
	DELETE FROM FTSCOMPETITORSTOCK_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	
	SET @Strsql='INSERT INTO FTSCOMPETITORSTOCK_REPORT(USERID,SEQ,EMPCODE,EMPNAME,BRANCHDESC,SHOPNAME,ENTITYCODE,ADDRESS,CONTACT,SHOPTYPE,COMPETITORSTKDATE,COMPETITORSTKID,COMPETITORSTKNO,PRODUCT,QUANTITY,RATE,STOCKVALUE,PPName,DDName,Employee_ID) '

	SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY CONVERT(NVARCHAR(10),CSTKHEAD.CompetitorStock_date,105),CSTKHEAD.CompetitorStock_Code) AS SEQ,EMP.emp_contactId AS EMPCODE,'

	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='BR.branch_description AS BRANCHDESC,SHOP.SHOP_NAME AS SHOPNAME,SHOP.ENTITYCODE,'
	SET @Strsql+='SHOP.ADDRESS,SHOP.SHOP_OWNER_CONTACT AS CONTACT,STYPS.NAME AS SHOPTYPE,CONVERT(NVARCHAR(10),CSTKHEAD.CompetitorStock_date,105) AS COMPETITORSTKDATE,CSTKHEAD.CompetitorStock_Id AS COMPETITORSTKID,CSTKHEAD.CompetitorStock_Code AS COMPETITORSTKNO,'
	SET @Strsql+='CSTKDET.Product_Name AS PRODUCT,CSTKDET.Product_Qty AS QUANTITY,CSTKDET.Product_MRP AS RATE,(CSTKDET.Product_Qty*CSTKDET.Product_MRP) AS STOCKVALUE,SHOPPP.Shop_Name AS ''PPName'','
	--Rev 2.0	
	--SET @Strsql+='SHOPPP.Shop_Name AS ''DDName'','
	SET @Strsql+='SHOPDD.Shop_Name AS ''DDName'','
	--Rev 2.0 End
	SET @Strsql+='CNT.cnt_UCC '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	
	SET @Strsql+='INNER JOIN FTS_CompetitorStock CSTKHEAD ON CSTKHEAD.user_id=USR.user_id '
	SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_Code=CSTKHEAD.Shop_Code '
	SET @Strsql+='INNER JOIN tbl_shoptype STYPS ON STYPS.SHOP_TYPEID=SHOP.TYPE '

	SET @Strsql+='INNER JOIN FTS_CompetitorStockProduct CSTKDET ON CSTKHEAD.CompetitorStock_Id=CSTKDET.CompetitorStock_Id '
	SET @Strsql+='INNER JOIN tbl_master_state STATE ON STATE.ID=SHOP.STATEID '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),CSTKHEAD.CompetitorStock_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @STATEID <> ''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SHOP.STATEID) '
	IF @SHOPID <> ''
		SET @Strsql+='AND EXISTS (SELECT Shop_ID FROM #SHOPID_LIST AS SP WHERE SP.Shop_ID=SHOP.Shop_ID) '
	ELSE IF @EMPID<>''
		SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=EMP.emp_contactId) '
	SET @Strsql=@Strsql+'ORDER BY CONVERT(NVARCHAR(10),CSTKHEAD.CompetitorStock_date,105),CSTKHEAD.CompetitorStock_Code'
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #SHOPID_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT

	SET NOCOUNT OFF
END 
GO