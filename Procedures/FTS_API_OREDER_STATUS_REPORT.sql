--EXEC FTS_API_OREDER_STATUS_REPORT '2021-01-01','2022-01-12','','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FTS_API_OREDER_STATUS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FTS_API_OREDER_STATUS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[FTS_API_OREDER_STATUS_REPORT]
(
@FROM_DATE NVARCHAR(50)=NULL,
@TO_DATE NVARCHAR(50)=NULL,
@LOGIN_ID BIGINT,
@Employee NVARCHAR(max)=NULL,
@stateID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@REPORT_BY NVARCHAR(10)
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : TANMOY GHOSH  on 08/04/2019 UPDATE TANMOY 08-05-19 ADD EMPLOYEE ID 
Module	   : Order status 
update Tanmoy Search change by order date or invoice date wise dynanic

1.0					TANMOY		13-02-2020		ADD TWO COLUMN Invoice_CreateDate,Order_CreateDate
2.0		v2.0.11		Debashis	12/05/2020		FTS reports with more fields.Refer: 0022323
3.0		v2.0.13		Debashis	24/06/2020		Branch column required in the various FSM reports.Refer: 0022610
4.0		v2.0.24		Tanmoy		30/07/2021		Employee hierarchy wise filter
5.0		v2.0.26		Debashis	12/01/2022		District/Cluster/Pincode fields are required in some of the reports.Refer: 0024575
6.0		v2.0.26		Debashis	13/01/2022		Sub Type field required in some of the reports.Refer: 0024576
7.0		v2.0.26		Debashis	13/01/2022		Alternate phone no. 1 & alternate email fields are required in some of the reports.Refer: 0024577
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @sqlStrTable NVARCHAR(MAX),@Strsql NVARCHAR(MAX),@sqlStateStrTable NVARCHAR(MAX)
	
	--Rev 2.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	--End of Rev 2.0
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @Employee <> ''
		BEGIN
			SET @Employee = REPLACE(''''+@Employee+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT USER_ID from TBL_MASTER_USER where USER_CONTACTID in('+@Employee+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END


-------------------------------STATE----------------------------------------------------
	--Rev 2.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#STATE_LIST') IS NOT NULL
	--End of Rev 2.0
		DROP TABLE #STATE_LIST
	CREATE TABLE #STATE_LIST (STATE_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @stateID <> ''
		BEGIN
			SET @stateID = REPLACE(''''+@stateID+'''',',',''',''')
			SET @sqlStateStrTable=''
			SET @sqlStateStrTable=' INSERT INTO #STATE_LIST SELECT id from tbl_master_state where id in('+@stateID+')'
			EXEC SP_EXECUTESQL @sqlStateStrTable
		END

---------------------------------DESIGNATION-------------------------------------
	--Rev 2.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
	--End of Rev 2.0
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

	--Rev 2.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSTATE') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPSTATE') IS NOT NULL
	--End of Rev 2.0
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

	--Rev 2.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPDESI') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPDESI') IS NOT NULL
	--End of Rev 2.0
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

	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@LOGIN_ID)		
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


	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'FTS_ORDER_STATUS_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTS_ORDER_STATUS_REPORT
			(
			SEQ INT,
			LOGIN_ID BIGINT,
			USER_ID BIGINT,
			Employee_Name NVARCHAR(100),
			Shop_Name NVARCHAR(MAX),
			--Rev 2.0
			ENTITYCODE NVARCHAR(600) NULL,
			--End of Rev 2.0
			Address NVARCHAR(MAX),
			--Rev 2.0
			--Contact NVARCHAR(20),
			Contact NVARCHAR(100),
			--End of Rev 2.0
			--Rev 7.0
			ALT_MOBILENO1 NVARCHAR(40) NULL,
			SHOP_OWNER_EMAIL2 NVARCHAR(300) NULL,
			--End of Rev 7.0
			Shop_Type NVARCHAR(50),
			--Rev 6.0
			SubType NVARCHAR(500),
			--End of Rev 6.0
			Order_Date DATE,
			Order_Number NVARCHAR(50),
			Order_Value DECIMAL(18,2),
			Invoice_Number NVARCHAR(50),
			Invoice_Date DATETIME,
			Delivered_Value DECIMAL(18,2),
			OrderId BIGINT,
			State_name NVARCHAR(100) NULL,
			--Rev 5.0
			SHOP_DISTRICT NVARCHAR(50) NULL,
			SHOP_PINCODE NVARCHAR(120) NULL,
			SHOP_CLUSTER NVARCHAR(500) NULL,
			--End of Rev 5.0
			--Rev 3.0
			BRANCHDESC NVARCHAR(300),
			--End of Rev 3.0
			PPName NVARCHAR(100) NULL,
			DDName NVARCHAR(100) NULL,
			Employee_ID NVARCHAR(100) NULL,
			BillingId NVARCHAR(100) NULL,
			Invoice_CreateDate DATETIME NULL,
			Order_CreateDate DATETIME NULL
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTS_ORDER_STATUS_REPORT (SEQ,LOGIN_ID)
		END
	DELETE FROM FTS_ORDER_STATUS_REPORT WHERE LOGIN_ID=@LOGIN_ID	

	--Rev 5.0 && Added two new fields as SHOP_DISTRICT,SHOP_PINCODE & SHOP_CLUSTER
	SET @Strsql=' '
	SET @Strsql+='INSERT INTO FTS_ORDER_STATUS_REPORT '	
	SET @Strsql+='SELECT '
	IF(@REPORT_BY='0')
		BEGIN
			SET @Strsql+=' ROW_NUMBER() OVER(ORDER BY T.Orderdate DESC), '
		END
	ELSE IF(@REPORT_BY='1')
		BEGIN
			SET @Strsql+=' ROW_NUMBER() OVER(ORDER BY T.invoice_date DESC), '
		END
	--Rev 2.0
	--SET @Strsql+=' '+str(@LOGIN_ID)+',T.User_Id,T.user_name as ''Employee_Name'',T.Shop_Name AS ''Shop_Name'',T.Address, '
	SET @Strsql+=' '+str(@LOGIN_ID)+',T.User_Id,T.user_name as ''Employee_Name'',T.Shop_Name AS ''Shop_Name'',T.ENTITYCODE,T.Address, '
	--End of Rev 2.0
	--Rev 6.0
	--SET @Strsql+='T.Shop_Owner_Contact AS ''Contact'',T.Name AS ''Shop_Type'',T.Orderdate, '
	--Rev 7.0
	--SET @Strsql+='T.Shop_Owner_Contact AS ''Contact'',T.Name AS ''Shop_Type'',T.SubType,T.Orderdate, '
	SET @Strsql+='T.Shop_Owner_Contact AS ''Contact'',T.ALT_MOBILENO1,T.SHOP_OWNER_EMAIL2,T.Name AS ''Shop_Type'',T.SubType,T.Orderdate, '
	--End of Rev 7.0
	--End of Rev 6.0
	SET @Strsql+='T.OrderCode AS ''Order_Number'', CASE WHEN ROWID=1 THEN T.Ordervalue ELSE 0.00 END AS ''Order_Value'',T.invoice_no AS ''Invoice_Number'', '
	--Rev 3.0
	--SET @Strsql+='T.invoice_date AS ''Invoice_Date'',T.invoice_amount AS ''Delivered_Value'' , T.OrderId,T.STATE_NAME,T.PPName,T.DDName,T.Employee_ID,T.BillingId  '
	--Rev 5.0
	--SET @Strsql+='T.invoice_date AS ''Invoice_Date'',T.invoice_amount AS ''Delivered_Value'' , T.OrderId,T.STATE_NAME,T.BRANCHDESC,T.PPName,T.DDName,T.Employee_ID,T.BillingId  '
	SET @Strsql+='T.invoice_date AS ''Invoice_Date'',T.invoice_amount AS ''Delivered_Value'' , T.OrderId,T.STATE_NAME,T.SHOP_DISTRICT,T.SHOP_PINCODE,T.SHOP_CLUSTER,T.BRANCHDESC,T.PPName,T.DDName,'
	SET @Strsql+='T.Employee_ID,T.BillingId  '
	--End of Rev 5.0
	--End of Rev 3.0
	--REV 1.0 START
	SET @Strsql+=' ,T.Invoice_CreateDate,T.Orderdate FROM ( '
	--REV 1.0 END
	SET @Strsql+='SELECT ROW_NUMBER() OVER(PARTITION BY ordupdt.OrderCode ORDER BY ordupdt.OrderCode) AS ROWID,ordupdt.userID AS User_Id, '
	--Rev 2.0
	--SET @Strsql+='MC.cnt_firstName+'' ''+MC.cnt_middleName+'' ''+cnt_lastName AS user_name,ms.Shop_Name,ms.Address,ordupdt.OrderId, '
	--Rev 3.0
	--SET @Strsql+='MC.cnt_firstName+'' ''+MC.cnt_middleName+'' ''+cnt_lastName AS user_name,ms.Shop_Name,MS.ENTITYCODE,ms.Address,ordupdt.OrderId, '
	SET @Strsql+='ISNULL(MC.CNT_FIRSTNAME,'''')+'' ''+ISNULL(MC.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(MC.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(MC.CNT_LASTNAME,'''') AS user_name,'
	SET @Strsql+='ms.Shop_Name,MS.ENTITYCODE,ms.Address,ordupdt.OrderId,'
	--End of Rev 3.0
	--End of Rev 2.0
	SET @Strsql+='ms.shop_owner_contact,shptyp.Name,ordupdt.Orderdate,ordupdt.OrderCode,ordupdt.Ordervalue,ftsbd.invoice_no,ftsbd.invoice_date,ftsbd.invoice_amount, '
	--Rev 3.0
	--SET @Strsql+='N.DES_NAME,N.DES_ID,STAT.STATE_ID,STAT.STATE_NAME,SHOPPP.Shop_Name AS ''PPName'',SHOPDD.Shop_Name AS ''DDName'',MC.cnt_UCC AS Employee_ID,ftsbd.BillingId  '
	SET @Strsql+='N.DES_NAME,N.DES_ID,STAT.STATE_ID,STAT.STATE_NAME,BR.branch_description AS BRANCHDESC,SHOPPP.Shop_Name AS ''PPName'',SHOPDD.Shop_Name AS ''DDName'',MC.cnt_UCC AS Employee_ID,ftsbd.BillingId '
	--End of Rev 3.0
	--REV 1.0 START
	SET @Strsql+=' ,ftsbd.CreateDate AS Invoice_CreateDate,'
	--REV 1.0 END
	--Rev 5.0
	SET @Strsql+='CITY.CITY_NAME AS SHOP_DISTRICT,MS.Pincode AS SHOP_PINCODE,MS.CLUSTER AS SHOP_CLUSTER,'
	--End of Rev 5.0
	--Rev 6.0
	SET @Strsql+='(SELECT ISNULL(STUFF((SELECT '','' + typsd.Name FROM tbl_shoptypeDetails AS typsd '
	SET @Strsql+='WHERE shptyp.shop_typeId=typsd.TYPE_ID '
	SET @Strsql+='ORDER BY typsd.Name FOR XML PATH('''')), 1, 1, ''''),'''')) AS SubType,'
	--End of Rev 6.0
	--Rev 7.0
	SET @Strsql+='ms.Alt_MobileNo1,ms.Shop_Owner_Email2 '
	--End of Rev 7.0
	SET @Strsql+='FROM tbl_trans_fts_Orderupdate ordupdt '
	SET @Strsql+='LEFT OUTER JOIN tbl_FTS_BillingDetails ftsbd ON ordupdt.OrderCode=ftsbd.OrderCode '
	SET @Strsql+='INNER JOIN tbl_Master_shop ms ON ms.Shop_Code=ordupdt.Shop_Code INNER JOIN tbl_master_user mu ON mu.user_id=ordupdt.userID '
	SET @Strsql+='INNER JOIN tbl_master_contact MC ON MC.cnt_internalId=mu.user_contactId  '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT EMPHR ON EMPHR.EMPCODE=MC.cnt_internalId '
		END
	--End of Rev 4.0
	--Rev 3.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON MC.cnt_branchid=BR.branch_id '
	--End of Rev 3.0
	SET @Strsql+='INNER JOIN tbl_shoptype shptyp ON shptyp.shop_typeId=ms.type '
	SET @Strsql+='INNER JOIN #TEMPDESI N on  N.cnt_internalId=mu.user_contactId '
	--Rev 5.0
	SET @Strsql+='LEFT OUTER JOIN TBL_MASTER_CITY CITY ON MS.Shop_City=CITY.city_id '
	--End of Rev 5.0
	--SET @Strsql+='LEFT OUTER JOIN tbl_Master_shop MSP ON MS.Shop_Code=MSP.assigned_to_pp_id '
	--SET @Strsql+='LEFT OUTER JOIN tbl_Master_shop MSD on MS.Shop_Code=MSD.assigned_to_dd_id '
	SET @Strsql+='LEFT OUTER JOIN('
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPPP ON ms.assigned_to_pp_id=SHOPPP.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPDD ON ms.assigned_to_dd_id=SHOPDD.Shop_Code '

	SET @Strsql+='LEFT OUTER JOIN #TEMPSTATE STAT ON STAT.cnt_internalId=mu.user_contactId) T  WHERE  '
	IF(@REPORT_BY='0')
		BEGIN
			SET @Strsql+='  CONVERT(NVARCHAR(10),T.Orderdate,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',23) AND CONVERT(NVARCHAR(10),'''+@TO_DATE+''',23)  '
		END
	ELSE IF(@REPORT_BY='1')
		BEGIN
			SET @Strsql+='  CONVERT(NVARCHAR(10),T.invoice_date,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',23) AND CONVERT(NVARCHAR(10),'''+@TO_DATE+''',23)  '
		END
	IF(ISNULL(@Employee,'')<>'')
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=cast(T.User_Id as nvarchar(100)))  '
	IF(ISNULL(@stateID,'')<>'')
		SET @Strsql+=' AND EXISTS (SELECT STATE_ID from #STATE_LIST AS ST WHERE ST.STATE_ID=cast(T.STATE_ID as nvarchar(100)))   '
	IF(ISNULL(@DESIGNID,'')<>'')
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DES WHERE DES.deg_id=cast(T.DES_ID as nvarchar(100)))   '
	--	IF(@REPORT_BY='0')
	--	BEGIN
	--		SET @Strsql+=' ORDER BY T.Orderdate DESC' 
	--	END
	--ELSE IF(@REPORT_BY='1')
	--	BEGIN
	--		SET @Strsql+=' ORDER BY T.invoice_date DESC' 
	--	END
	
	 --ISNULL(CONVERT(NVARCHAR(50),T.User_Id),'' '')<>'' ''  AND
	exec sp_executesql @Strsql
	--select @Strsql
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATE_LIST
	DROP TABLE #DESIGNATION_LIST

	DROP TABLE #TEMPDESI
	DROP TABLE #TEMPSTATE
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHR
	END
	--End of Rev 4.0

	SET NOCOUNT OFF
END