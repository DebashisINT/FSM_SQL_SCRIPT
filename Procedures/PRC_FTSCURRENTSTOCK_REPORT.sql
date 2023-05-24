IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSCURRENTSTOCK_REPORT]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSCURRENTSTOCK_REPORT] AS'  
END 
GO

--EXEC PRC_FTSCURRENTSTOCK_REPORT @ACTION='LIST',@FROMDATE='2023-05-01',@TODATE='2023-05-20',@USERID=378
ALTER PROCEDURE [dbo].[PRC_FTSCURRENTSTOCK_REPORT]
(
@ACTION NVARCHAR(100)=NULL,
@CURRENTSTKID int=0,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@SHOPID NVARCHAR(MAX)=NULL,
--@USERLIST NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT=0
)  
AS
/**************************************************************************************************************************************************************************** 
1.0			v2.0.11		Debashis	12/05/2020		FTS reports with more fields.Refer: 0022323
2.0			v2.0.40		Priti	    18/05/2023		0026136: Modification in CURRENT STOCK REGISTER report
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	--DECLARE @isRevisitTeamDetail NVARCHAR(100)
	--SELECT @isRevisitTeamDetail=[Value] FROM fts_app_config_settings WHERE [Key]='isRevisitTeamDetail' AND [Description]='Revisit from Team Details in Portal'
	if (@ACTION='LIST')
	Begin
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
	


	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSCURRENTSTOCK_REPORT') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTSCURRENTSTOCK_REPORT
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
		  CURRENTSTKDATE NVARCHAR(10) NULL,
		  CURRENTSTKID BIGINT,
		  CURRENTSTKNO NVARCHAR(60) NULL,
		  PRODUCT NVARCHAR(500) NULL,
		  QUANTITY DECIMAL(10,2),
		  PPName NVARCHAR(100) NULL,
		  DDName NVARCHAR(100) NULL,
		  Employee_ID NVARCHAR(100) NULL,
		  --Rev 2.0
		  IS_IMAGE BIT
		  --Rev 2.0 End
		)
		CREATE NONCLUSTERED INDEX IX1 ON FTSCURRENTSTOCK_REPORT (SEQ)
	END
	DELETE FROM FTSCURRENTSTOCK_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	
	SET @Strsql='INSERT INTO FTSCURRENTSTOCK_REPORT(USERID,SEQ,EMPCODE,EMPNAME,BRANCHDESC,SHOPNAME,ENTITYCODE,ADDRESS,CONTACT,SHOPTYPE,CURRENTSTKDATE,CURRENTSTKID,CURRENTSTKNO,PRODUCT,QUANTITY,PPName,DDName,Employee_ID,IS_IMAGE) '

	SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY CONVERT(NVARCHAR(10),CSTKHEAD.Stock_date,105),CSTKHEAD.Stock_Code) AS SEQ,EMP.emp_contactId AS EMPCODE,'

	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='BR.branch_description AS BRANCHDESC,SHOP.SHOP_NAME AS SHOPNAME,SHOP.ENTITYCODE,'
	SET @Strsql+='SHOP.ADDRESS,SHOP.SHOP_OWNER_CONTACT AS CONTACT,STYPS.NAME AS SHOPTYPE,CONVERT(NVARCHAR(10),CSTKHEAD.Stock_date,105) AS CURRENTSTKDATE,CSTKHEAD.CurrentStockId AS CURRENTSTKID,CSTKHEAD.Stock_Code AS CURRENTSTKNO,'
	SET @Strsql+='PROD.sProducts_Name AS PRODUCT,CSTKDET.Product_Qty AS QUANTITY,SHOPPP.Shop_Name AS ''PPName'',SHOPPP.Shop_Name AS ''DDName'',CNT.cnt_UCC, '
	--Rev 2.0
	SET @Strsql+=' (case when StkImg.IMG_CNT >0 then 1 else 0 end) AS IS_IMAGE '
    --Rev 2.0 End
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	
	SET @Strsql+='INNER JOIN FTS_TransCurrentStock CSTKHEAD ON CSTKHEAD.userID=USR.user_id '
	SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_Code=CSTKHEAD.Shop_Code '
	SET @Strsql+='INNER JOIN tbl_shoptype STYPS ON STYPS.SHOP_TYPEID=SHOP.TYPE '

	SET @Strsql+='INNER JOIN FTS_CurrentStockProduct CSTKDET ON CSTKHEAD.CurrentStockId=CSTKDET.CurrentStock_ID '
	SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=CSTKDET.Product_Id '
	SET @Strsql+='INNER JOIN tbl_master_state STATE ON STATE.ID=SHOP.STATEID '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '

	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	--Rev 2.0
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT COUNT(0) IMG_CNT,  A.USERID,A.STOCK_CODE FROM FSMCURRENTSTOCKIMAGEMAPINFO A group by USERID,STOCK_CODE'
	SET @Strsql+=') StkImg ON StkImg.USERID=CSTKHEAD.userID  and StkImg.STOCK_CODE=CSTKHEAD.Stock_Code'
	 --Rev 2.0 End
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),CSTKHEAD.Stock_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @STATEID <> ''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SHOP.STATEID) '
	IF @SHOPID <> ''
		SET @Strsql+='AND EXISTS (SELECT Shop_ID FROM #SHOPID_LIST AS SP WHERE SP.Shop_ID=SHOP.Shop_ID) '
	ELSE IF @EMPID<>''
		SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=EMP.emp_contactId) '
	SET @Strsql=@Strsql+'ORDER BY CONVERT(NVARCHAR(10),CSTKHEAD.Stock_date,105),CSTKHEAD.Stock_Code'
	EXEC SP_EXECUTESQL @Strsql
	--select @Strsql
	DROP TABLE #SHOPID_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT
	End

	Else if (@ACTION='LOADIMAGE')
	BEGIN
		DECLARE @Stock_Code nvarchar(100)=null,@user_ID bigint=0
		select @Stock_Code=Stock_Code,@user_ID=userID from FTS_TransCurrentStock  where CurrentStockId=@CURRENTSTKID 

		select ID,isnull(STOCKIMAGEPATH1,'')STOCKIMAGEPATH1,isnull(STOCKIMAGEPATH2,'')STOCKIMAGEPATH2 from FSMCURRENTSTOCKIMAGEMAPINFO  where STOCK_CODE=@Stock_Code and USERID=@user_ID
	END



	SET NOCOUNT OFF
END 
