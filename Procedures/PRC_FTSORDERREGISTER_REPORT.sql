IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSORDERREGISTER_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSORDERREGISTER_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSORDERREGISTER_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@SHOPID NVARCHAR(MAX)=NULL,
--@USERLIST NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT ,
--Rev 9.0
@BRANCHID NVARCHAR(MAX)=NULL,
--Rev 9.0 End
-- Rev 10.0
@SHOWMRP INT=0,
@SHOWDISCOUNT INT=0
-- End of Rev 10.0
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 27/11/2018 CHANGE TANMOY GHOSH 07/05/2019 NEW ADD PP NAME AND DD NAME 08/05/19 ADD EMPLOYEE ID
Module	   : FTS Order Register 
1.0		v2.0.11		Debashis	12/05/2020		FTS reports with more fields.Refer: 0022323
2.0		v2.0.12		Debashis	11/06/2020		Order taken by another user which is not showing in Order Summary report.Now solved.Refer: 0022479
3.0		v2.0.13		Debashis	24/06/2020		Branch column required in the various FSM reports.Refer: 0022610
4.0		v2.0.24		Tanmoy		30/07/2021		Employee hierarchy wise filter
5.0		v2.0.26		Pratik		05/01/2022		Scheme Qty, Scheme Rate, Scheme Value columns required in Order Register report.Refer: 	0024593
6.0		v2.0.26		Debashis	10/01/2022		DD name column is showing PP name in Order Register report.Refer: 0024607
7.0		v2.0.38		Debashis	03/01/2023		Quantity value up to 3 digit after decimal need to be incorporated in the Order related Reports.Refer: 0025365
8.0		v2.0.39		Debashis	07/02/2023		Order Register Report is not working.Increased the field length of SHOPNAME.Refer: 0025651
9.0		V2.0.42		Priti	    19/07/2023      Branch Parameter is required for various FSM reports.Refer:0026135
10.0	V2.0.46		10.0    19/07/2023      027345: Two checkbox required in parameter for Order register report.
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	--Rev 2.0
	DECLARE @isRevisitTeamDetail NVARCHAR(100)
	SELECT @isRevisitTeamDetail=[Value] FROM fts_app_config_settings WHERE [Key]='isRevisitTeamDetail' AND [Description]='Revisit from Team Details in Portal'
	--End of Rev 2.0

	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
	--End of Rev 1.0
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

	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#SHOPID_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#SHOPID_LIST') IS NOT NULL
	--End of Rev 1.0
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

	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#USERID_LIST') AND TYPE IN (N'U'))
	--	DROP TABLE #USERID_LIST
	--CREATE TABLE #USERID_LIST (user_id INT)
	--CREATE NONCLUSTERED INDEX IX1 ON #USERID_LIST (user_id ASC)
	--IF @USERLIST <> ''
	--	BEGIN
	--		SET @USERLIST=REPLACE(@USERLIST,'''','')
	--		SET @sqlStrTable=''
	--		SET @sqlStrTable=' INSERT INTO #USERID_LIST SELECT user_id from tbl_master_user where user_id in('+@USERLIST+')'
	--		EXEC SP_EXECUTESQL @sqlStrTable
	--	END

	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
     --Rev 9.0
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
	  --Rev 9.0 End
	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--Rev 3.0
			cnt_branchid INT,
			--End of Rev 3.0
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	--Rev 3.0
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,ISNULL(cnt_UCC,'') FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')	
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,ISNULL(cnt_UCC,'') FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	--End of Rev 3.0

	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
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
	--End of Rev 4.0
	
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSORDERREGISTER_REPORT') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTSORDERREGISTER_REPORT
		(
		  USERID INT,
		  SEQ INT,
		  --SALESMAN NVARCHAR(80) NULL,
		  EMPCODE NVARCHAR(100) NULL,
		  EMPNAME NVARCHAR(300) NULL,
		  --Rev 3.0
		  BRANCHDESC NVARCHAR(300),
		  --End of Rev 3.0
		  --Rev 8.0
		  --SHOPNAME NVARCHAR(100) NULL,
		  SHOPNAME NVARCHAR(500) NULL,
		  --End of Rev 8.0
		  --Rev 1.0
		  ENTITYCODE NVARCHAR(600) NULL,
		  --End of Rev 1.0
		  ADDRESS NVARCHAR(MAX) NULL,
		  CONTACT NVARCHAR(100) NULL,
		  SHOPTYPE NVARCHAR(50) NULL,
		  ORDDATE NVARCHAR(10) NULL,
		  ORDID BIGINT,
		  ORDRNO NVARCHAR(60) NULL,
		  PRODUCT NVARCHAR(500) NULL,
		  --Rev 7.0
		  --QUANTITY DECIMAL(10,0),
		  QUANTITY DECIMAL(18,3),
		  --End of Rev 7.0
		  RATE DECIMAL(18,2),
		  ORDVALUE DECIMAL(18,2),
		  PPName NVARCHAR(100) NULL,
		  DDName NVARCHAR(100) NULL,
		  Employee_ID NVARCHAR(100) NULL,
		  Scheme_Qty DECIMAL(18,2),
		  Scheme_Rate DECIMAL(18,2),
		  Total_Scheme_Price DECIMAL(18,2),
		  -- Rev 10.0
		  MRP DECIMAL(18,2),
		  DISCOUNT DECIMAL(18,2)
		  -- End of Rev 10.0
		)
		CREATE NONCLUSTERED INDEX IX1 ON FTSORDERREGISTER_REPORT (SEQ)
	END
	DELETE FROM FTSORDERREGISTER_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	--SET @Strsql='INSERT INTO FTSORDERREGISTER_REPORT(USERID,SEQ,SALESMAN,SHOPNAME,ADDRESS,CONTACT,SHOPTYPE,ORDDATE,ORDID,ORDRNO,PRODUCT,QUANTITY,RATE,ORDVALUE) '
	--SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,105),ORDHEAD.ORDERCODE) AS SEQ,USR.USER_NAME AS SALESMAN,SHOP.SHOP_NAME AS SHOPNAME,'
	--Rev 1.0
	--SET @Strsql='INSERT INTO FTSORDERREGISTER_REPORT(USERID,SEQ,EMPCODE,EMPNAME,SHOPNAME,ADDRESS,CONTACT,SHOPTYPE,ORDDATE,ORDID,ORDRNO,PRODUCT,QUANTITY,RATE,ORDVALUE,PPName,DDName,Employee_ID) '
	--Rev 3.0
	--SET @Strsql='INSERT INTO FTSORDERREGISTER_REPORT(USERID,SEQ,EMPCODE,EMPNAME,SHOPNAME,ENTITYCODE,ADDRESS,CONTACT,SHOPTYPE,ORDDATE,ORDID,ORDRNO,PRODUCT,QUANTITY,RATE,ORDVALUE,PPName,DDName,Employee_ID) '
	--rev 0.5
	--SET @Strsql='INSERT INTO FTSORDERREGISTER_REPORT(USERID,SEQ,EMPCODE,EMPNAME,BRANCHDESC,SHOPNAME,ENTITYCODE,ADDRESS,CONTACT,SHOPTYPE,ORDDATE,ORDID,ORDRNO,PRODUCT,QUANTITY,RATE,ORDVALUE,PPName,DDName,Employee_ID) '
	-- Rev 10.0
	--SET @Strsql='INSERT INTO FTSORDERREGISTER_REPORT(USERID,SEQ,EMPCODE,EMPNAME,BRANCHDESC,SHOPNAME,ENTITYCODE,ADDRESS,CONTACT,SHOPTYPE,ORDDATE,ORDID,ORDRNO,PRODUCT,QUANTITY,RATE,ORDVALUE,PPName,DDName,Employee_ID,Scheme_Qty,Scheme_Rate,Total_Scheme_Price) '
	SET @Strsql='INSERT INTO FTSORDERREGISTER_REPORT(USERID,SEQ,EMPCODE,EMPNAME,BRANCHDESC,SHOPNAME,ENTITYCODE,ADDRESS,CONTACT,SHOPTYPE,ORDDATE,ORDID,ORDRNO,PRODUCT,QUANTITY,RATE,ORDVALUE,PPName,DDName,Employee_ID,Scheme_Qty,Scheme_Rate,Total_Scheme_Price,MRP,DISCOUNT) '
	-- End of Rev 10.0
	--End of rev 0.5
	--End of Rev 3.0
	 --End of Rev 1.0
	SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,105),ORDHEAD.ORDERCODE) AS SEQ,EMP.emp_contactId AS EMPCODE,'
	--Rev 1.0
	--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,SHOP.SHOP_NAME AS SHOPNAME,'
	--Rev 3.0
	--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,SHOP.SHOP_NAME AS SHOPNAME,SHOP.ENTITYCODE,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='BR.branch_description AS BRANCHDESC,SHOP.SHOP_NAME AS SHOPNAME,SHOP.ENTITYCODE,'
	--End of Rev 3.0
	--End of Rev 1.0
	SET @Strsql+='SHOP.ADDRESS,SHOP.SHOP_OWNER_CONTACT AS CONTACT,STYPS.NAME AS SHOPTYPE,CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,105) AS ORDDATE,ORDHEAD.OrderId AS ORDID,ORDHEAD.ORDERCODE AS ORDRNO,'
	--rev 0.5
	--SET @Strsql+='PROD.sProducts_Name AS PRODUCT,ORDDET.Product_Qty AS QUANTITY,ORDDET.Product_Rate AS RATE,(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,SHOPPP.Shop_Name AS ''PPName'',SHOPPP.Shop_Name AS ''DDName'',CNT.cnt_UCC '
	--Rev 6.0
	--SET @Strsql+='PROD.sProducts_Name AS PRODUCT,ORDDET.Product_Qty AS QUANTITY,ORDDET.Product_Rate AS RATE,(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,SHOPPP.Shop_Name AS ''PPName'',SHOPPP.Shop_Name AS ''DDName'',CNT.cnt_UCC,ORDDET.Scheme_Qty,ORDDET.Scheme_Rate,ORDDET.Total_Scheme_Price '
	SET @Strsql+='PROD.sProducts_Name AS PRODUCT,ORDDET.Product_Qty AS QUANTITY,ORDDET.Product_Rate AS RATE,(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,SHOPPP.Shop_Name AS ''PPName'','
	SET @Strsql+='SHOPDD.Shop_Name AS ''DDName'',CNT.cnt_UCC,ORDDET.Scheme_Qty,ORDDET.Scheme_Rate,ORDDET.Total_Scheme_Price '
	--End of Rev 6.0
	--SET @Strsql+=',ORDDET.Scheme_Qty,ORDDET.Scheme_Rate,ORDDET.Total_Scheme_Price'
	--End of rev 0.5
	--SET @Strsql+='FROM tbl_Master_shop AS SHOP '
	--SET @Strsql+='INNER JOIN tbl_master_user USR ON SHOP.SHOP_CREATEUSER=USR.USER_ID '
	-- Rev 10.0
	IF(@SHOWMRP=1)
		SET @Strsql+=' ,ORDDET.ORDER_MRP '
	ELSE
		SET @Strsql+=' ,0 AS ORDER_MRP '

	IF(@SHOWDISCOUNT=1)
		SET @Strsql+=' ,ORDDET.ORDER_DISCOUNT '
	ELSE
		SET @Strsql+=' ,0 AS ORDER_DISCOUNT '
	-- End of Rev 10.0
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	--Rev 3.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	--End of Rev 3.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT EMPHR ON EMPHR.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	--Rev 2.0
	IF @isRevisitTeamDetail='0'
		BEGIN
	--End of Rev 2.0
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_shoptype STYPS ON STYPS.SHOP_TYPEID=SHOP.TYPE '
			SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code '
	--Rev 2.0
		END
	ELSE IF @isRevisitTeamDetail='1'
		BEGIN
			SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.userID=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_Code=ORDHEAD.Shop_Code '
			SET @Strsql+='INNER JOIN tbl_shoptype STYPS ON STYPS.SHOP_TYPEID=SHOP.TYPE '
		END
	--End of Rev 2.0
	SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
	SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.Product_Id '
	SET @Strsql+='INNER JOIN tbl_master_state STATE ON STATE.ID=SHOP.STATEID '
	--SET @Strsql+='LEFT OUTER JOIN tbl_Master_shop MSP ON shop.Shop_Code=MSP.assigned_to_pp_id '
	--SET @Strsql+='LEFT OUTER JOIN tbl_Master_shop MSD ON shop.Shop_Code=MSD.assigned_to_dd_id '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @STATEID <> ''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SHOP.STATEID) '
	IF @SHOPID <> ''
		SET @Strsql+='AND EXISTS (SELECT Shop_ID FROM #SHOPID_LIST AS SP WHERE SP.Shop_ID=SHOP.Shop_ID) '
	--IF @USERLIST <> ''
	--	SET @Strsql+='AND EXISTS (SELECT user_id FROM #USERID_LIST AS US WHERE US.user_id=USR.USER_ID) '
	ELSE IF @EMPID<>''
		SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=EMP.emp_contactId) '

    --Rev 9.0
	IF @BRANCHID<>''
		SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCH_LIST AS F WHERE F.Branch_Id=BR.branch_id) '
    --Rev 9.0 End


	SET @Strsql=@Strsql+'ORDER BY CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,105),ORDHEAD.ORDERCODE'
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #SHOPID_LIST
	DROP TABLE #STATEID_LIST
	--DROP TABLE #USERID_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT

	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHR
	END
	--End of Rev 4.0
	--Rev 9.0
	DROP TABLE #BRANCH_LIST
	--Rev 9.0 End


	SET NOCOUNT OFF
END 
GO