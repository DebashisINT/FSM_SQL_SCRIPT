--EXEC PRC_FTSINVOICEREGISTER_REPORT '2022-07-01','2022-07-31','378','','',''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSINVOICEREGISTER_HIERARCHY_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSINVOICEREGISTER_HIERARCHY_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSINVOICEREGISTER_HIERARCHY_REPORT]
(
@FROM_DATE NVARCHAR(50)=NULL,
@TO_DATE NVARCHAR(50)=NULL,
@LOGIN_ID BIGINT,
@Employee NVARCHAR(max)=NULL,
@stateID NVARCHAR(MAX)=NULL,
@SHOPID NVARCHAR(MAX)=NULL,
--Rev 5.0
@BRANCHID NVARCHAR(MAX)=NULL
--End of Rev 5.0
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : TANMOY GHOSH  on 08/04/2019 UPDATE TANMOY 08-05-19 ADD EMPLOYEE ID 
Module	   : Order status 
1.0					TANMOY		05-12-2019		Invoice_Amount AMOUNT GET FROM	Product_TotalAmount
2.0					TANMOY		13-02-2020		ADD TWO COLUMN Invoice_Create_Date,Order_Create_Date
3.0		v2.0.11		Debashis	12/05/2020		FTS reports with more fields.Refer: 0022323
4.0		v2.0.24		Tanmoy		30/07/2021		Employee hierarchy wise filter
5.0		v2.0.32		Debashis	14/09/2022		Branch selection option is required on various reports.Refer: 0025198
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @sqlStrTable NVARCHAR(MAX),@Strsql NVARCHAR(MAX),@sqlStateStrTable NVARCHAR(MAX)
	
-------------------------------STATE----------------------------------------------------
	--Rev 3.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#STATE_LIST') IS NOT NULL
	--End of Rev 3.0
		DROP TABLE #STATE_LIST
	CREATE TABLE #STATE_LIST (STATE_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @stateID <> ''
		BEGIN
			SET @stateID = REPLACE(''''+@stateID+'''',',',''',''')
			SET @sqlStateStrTable=''
			SET @sqlStateStrTable=' INSERT INTO #STATE_LIST SELECT id from tbl_master_state where id in('+@stateID+')'
			EXEC SP_EXECUTESQL @sqlStateStrTable
		END
---------------------------------SHOP-------------------------------------
	--Rev 3.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#SHOPID_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#SHOPID_LIST') IS NOT NULL
	--End of Rev 3.0
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


	DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@LOGIN_ID)
	SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE INTO #EMPHR   FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO

	;with cte as(select	
	EMPCODE
	from #EMPHR 
	where EMPCODE IS NULL OR EMPCODE=@empcode  
	union all
	select	
	a.EMPCODE
	from #EMPHR a
	join cte b
	on a.RPTTOEMPCODE = b.EMPCODE
	) 

	select 
	* INTO #EMPLOYEELIST
	from cte 

	--Rev 3.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	--End of Rev 3.0
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @Employee <> ''
		BEGIN
			SET @Employee = REPLACE(''''+@Employee+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT USER_ID from TBL_MASTER_USER where USER_CONTACTID in('+@Employee+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
		ELSE
		BEGIN
		SET @Employee='Not Blank'
		INSERT INTO #EMPLOYEE_LIST
		SELECT * FROM #EMPLOYEELIST

		END

	--Rev 3.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSTATE') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPSTATE') IS NOT NULL
	--End of Rev 3.0
		DROP TABLE #TEMPSTATE
	CREATE TABLE #TEMPSTATE
	(
	cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	STATE_ID NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	STATE_NAME NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	)
	CREATE NONCLUSTERED INDEX IX_STATEID ON #TEMPSTATE(cnt_internalId,STATE_ID ASC)
	INSERT INTO #TEMPSTATE
	SELECT add_cntId,STAT.ID,STAT.state  FROM  tbl_master_address AS S
	LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state where add_addressType='Office' 

	--Rev 3.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPDESI') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPDESI') IS NOT NULL
	--End of Rev 3.0
		DROP TABLE #TEMPDESI
	CREATE TABLE #TEMPDESI
	(
	cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DES_ID NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DES_NAME NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	)
	CREATE NONCLUSTERED INDEX IX_DESIID ON #TEMPDESI(cnt_internalId,DES_ID ASC)
	INSERT INTO #TEMPDESI
	select cnt.emp_cntId,desg.deg_id,desg.deg_designation  from tbl_trans_employeeCTC as cnt 
	left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil
	having emp_effectiveuntil is null 

	--Rev 5.0
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
	--End of Rev 5.0

	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@LOGIN_ID)		
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
	--End of Rev 4.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'FTSINVOICEREGISTER_REPORT') AND TYPE IN (N'U'))
		BEGIN
			--Rev 5.0 &&Two new fields have been added as BRANCH_ID & BRANCHDESC
			CREATE TABLE FTSINVOICEREGISTER_REPORT
			(
			SEQ INT,
			LOGIN_ID BIGINT,
			USER_ID BIGINT,
			Employee_Name NVARCHAR(100),
			Shop_Name NVARCHAR(MAX),
			--Rev 3.0
			ENTITYCODE NVARCHAR(600) NULL,
			--End of Rev 3.0
			BRANCH_ID BIGINT,
			BRANCHDESC NVARCHAR(300),
			Address NVARCHAR(MAX),
			Contact NVARCHAR(20),
			Shop_Type NVARCHAR(50),
			Order_Number NVARCHAR(50),
			Order_Date NVARCHAR(10),
			Invoice_Number NVARCHAR(50),
			Invoice_Date NVARCHAR(10),
			PRODNAME NVARCHAR(300) NULL,
			Product_Qty DECIMAL(18,2),
			Product_Rate DECIMAL(18,2),
			Product_TotalAmount DECIMAL(18,2),
			Invoice_Amount DECIMAL(18,2),
			State_name NVARCHAR(100) NULL,
			Shop_ID BIGINT,
			PPName NVARCHAR(100) NULL,
			DDName NVARCHAR(100) NULL,
			Employee_ID NVARCHAR(100) NULL,
			Invoice_Create_Date DATETIME NULL,
			Order_Create_Date DATETIME NULL
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSINVOICEREGISTER_REPORT (SEQ)
		END
	DELETE FROM FTSINVOICEREGISTER_REPORT WHERE LOGIN_ID=@LOGIN_ID	
	SET @Strsql=''
	--Rev 3.0
	--SET @Strsql='INSERT INTO FTSINVOICEREGISTER_REPORT(SEQ,LOGIN_ID,USER_ID,Employee_Name,Shop_ID,Shop_Name,Address,Contact,Shop_Type,Order_Number,Order_Date,Invoice_Number,Invoice_Date,'
	--Rev 5.0
	--SET @Strsql='INSERT INTO FTSINVOICEREGISTER_REPORT(SEQ,LOGIN_ID,USER_ID,Employee_Name,Shop_ID,Shop_Name,ENTITYCODE,Address,Contact,Shop_Type,Order_Number,Order_Date,Invoice_Number,Invoice_Date,'
	SET @Strsql='INSERT INTO FTSINVOICEREGISTER_REPORT(SEQ,LOGIN_ID,USER_ID,Employee_Name,Shop_ID,Shop_Name,ENTITYCODE,BRANCH_ID,BRANCHDESC,Address,Contact,Shop_Type,Order_Number,Order_Date,'
	SET @Strsql+='Invoice_Number,Invoice_Date,'
	--End of Rev 5.0
	--End of Rev 3.0
	SET @Strsql+='PRODNAME,Product_Qty,Product_Rate,Product_TotalAmount,Invoice_Amount,State_name,PPName,DDName,Employee_ID, '
	--REV 2.0 START
	SET @Strsql+= ' Invoice_Create_Date,Order_Create_Date) '	
	--REV 2.0 END
	SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY T.invoice_date DESC) SEQ,'
	--Rev 3.0
	--SET @Strsql+=''+LTRIM(RTRIM(STR(@LOGIN_ID)))+' AS LOGIN_ID,T.User_Id,T.user_name as ''Employee_Name'',T.Shop_ID,T.Shop_Name AS ''Shop_Name'',T.Address,'
	--Rev 5.0
	--SET @Strsql+=''+LTRIM(RTRIM(STR(@LOGIN_ID)))+' AS LOGIN_ID,T.User_Id,T.user_name as ''Employee_Name'',T.Shop_ID,T.Shop_Name AS ''Shop_Name'',T.ENTITYCODE,T.Address,'
	SET @Strsql+=''+LTRIM(RTRIM(STR(@LOGIN_ID)))+' AS LOGIN_ID,T.User_Id,T.user_name as ''Employee_Name'',T.Shop_ID,T.Shop_Name AS ''Shop_Name'',T.ENTITYCODE,T.BRANCH_ID,T.BRANCHDESC,T.Address,'
	--End of Rev 5.0
	--End of Rev 3.0
	SET @Strsql+='T.Shop_Owner_Contact AS ''Contact'',T.Name AS ''Shop_Type'','
	SET @Strsql+='T.OrderCode AS ''Order_Number'',CONVERT(NVARCHAR(10),T.Orderdate,105) as Orderdate,T.invoice_no AS ''Invoice_Number'',CONVERT(NVARCHAR(10),T.invoice_date,105) AS ''Invoice_Date'',T.PRODNAME,T.Product_Qty,T.Product_Rate,T.Product_TotalAmount,'
	--REV 1.0 START
	--SET @Strsql+='CASE WHEN ROWID=1 THEN T.invoice_amount ELSE 0.00 END AS ''Invoice_Amount'', '
	SET @Strsql+='T.Product_TotalAmount AS ''Invoice_Amount'',  '
	--REV 1.0 END
	SET @Strsql+=' T.STATE_NAME,T.PPName,T.DDName,T.Employee_ID  '
	--REV 2.0 START
	SET @Strsql+=' ,T.Invoice_Create_Date,T.Orderdate FROM ( '
	--REV 2.0 END
	SET @Strsql+='SELECT ROW_NUMBER() OVER(PARTITION BY ftsbd.BillingId ORDER BY ftsbd.BillingId) AS ROWID,ftsbd.User_Id AS User_Id,BDP.PRODNAME,ms.Shop_ID,'
	--Rev 3.0
	--SET @Strsql+='MC.cnt_firstName+'' ''+MC.cnt_middleName+'' ''+cnt_lastName AS user_name,ms.Shop_Name,ms.Address,ftsbd.BillingId,'
	--Rev 5.0
	--SET @Strsql+='MC.cnt_firstName+'' ''+MC.cnt_middleName+'' ''+cnt_lastName AS user_name,ms.Shop_Name,MS.ENTITYCODE,ms.Address,ftsbd.BillingId,'
	SET @Strsql+='MC.cnt_firstName+'' ''+MC.cnt_middleName+'' ''+cnt_lastName AS user_name,ms.Shop_Name,MS.ENTITYCODE,BR.BRANCH_ID,BR.BRANCH_DESCRIPTION AS BRANCHDESC,ms.Address,ftsbd.BillingId,'
	--End of Rev 5.0
	--End of Rev 3.0
	SET @Strsql+='ms.shop_owner_contact,shptyp.Name,ordupdt.OrderCode,ftsbd.invoice_no,ftsbd.invoice_date,ordupdt.Orderdate,ftsbd.invoice_amount,BDP.Product_Qty,CAST(BDP.Product_Rate AS DECIMAL(18,2)) AS Product_Rate,'
	SET @Strsql+='CAST(BDP.Product_TotalAmount AS DECIMAL(18,2)) AS Product_TotalAmount,N.DES_NAME,N.DES_ID,STAT.STATE_ID,STAT.STATE_NAME,SHOPPP.Shop_Name AS ''PPName'',SHOPDD.Shop_Name AS ''DDName'',MC.cnt_UCC AS Employee_ID '
	--REV 2.0 START
	SET @Strsql+=' ,ftsbd.CreateDate AS  Invoice_Create_Date  '
	--REV 2.0 END
	SET @Strsql+='FROM tbl_FTS_BillingDetails ftsbd '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT BDP.Billing_ID,BDP.User_Id,MP.sProducts_Name AS PRODNAME,BDP.Product_Qty,BDP.Product_Rate,BDP.Product_TotalAmount FROM FTS_BillingdetailsProduct BDP '
	SET @Strsql+='INNER JOIN MASTER_SPRODUCTS MP ON MP.sProducts_ID=BDP.Product_Id '
	SET @Strsql+=') BDP ON BDP.Billing_ID=ftsbd.BillingId AND BDP.User_Id=ftsbd.User_Id '	
	SET @Strsql+='INNER JOIN tbl_master_user mu ON mu.user_id=ftsbd.User_Id '
	SET @Strsql+='LEFT OUTER JOIN tbl_trans_fts_Orderupdate ordupdt ON ordupdt.OrderCode=ftsbd.OrderCode '	
	SET @Strsql+='INNER JOIN tbl_Master_shop ms ON ms.Shop_Code=ordupdt.Shop_Code '
	SET @Strsql+='INNER JOIN tbl_master_contact MC ON MC.cnt_internalId=mu.user_contactId '
	--Rev 5.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON MC.cnt_branchid=BR.branch_id '
	--End of Rev 5.0
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT EMPHR ON EMPHR.EMPCODE=MC.cnt_internalId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN tbl_shoptype shptyp ON shptyp.shop_typeId=ms.type '
	SET @Strsql+='INNER JOIN #TEMPDESI N ON N.cnt_internalId=mu.user_contactId '
	SET @Strsql+='LEFT OUTER JOIN('
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPPP ON ms.assigned_to_pp_id=SHOPPP.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPDD ON ms.assigned_to_dd_id=SHOPDD.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN #TEMPSTATE STAT ON STAT.cnt_internalId=mu.user_contactId) T '

	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),T.invoice_date,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',23) AND CONVERT(NVARCHAR(10),'''+@TO_DATE+''',23) '
	IF(ISNULL(@Employee,'')<>'')
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=cast(T.User_Id as nvarchar(100))) '
	IF(ISNULL(@stateID,'')<>'')
		SET @Strsql+=' AND EXISTS (SELECT STATE_ID from #STATE_LIST AS ST WHERE ST.STATE_ID=cast(T.STATE_ID as nvarchar(100))) '
	IF @SHOPID <> ''
		SET @Strsql+='AND EXISTS (SELECT Shop_ID FROM #SHOPID_LIST AS SP WHERE SP.Shop_ID=T.Shop_ID) '
	--Rev 5.0
	IF @BRANCHID<>''
		SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=T.BRANCH_ID) '
	--End of Rev 5.0

	--SELECT @Strsql
	EXEC sp_executesql @Strsql
	
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATE_LIST
	DROP TABLE #SHOPID_LIST
	DROP TABLE #TEMPDESI
	DROP TABLE #TEMPSTATE

	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	--End of Rev 4.0
	--Rev 5.0
	DROP TABLE #BRANCH_LIST
	--End of Rev 5.0

	SET NOCOUNT OFF
END