

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_UPDATEORDERSTATUS_LISTING]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_UPDATEORDERSTATUS_LISTING] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_UPDATEORDERSTATUS_LISTING]
(
@Employee_id varchar(MAX)=NULL,
@start_date  varchar(MAX)=NULL,
@end_date  varchar(MAX)=NULL,
@stateID varchar(MAX)=NULL,
@shop_id  varchar(MAX)=NULL,
@LOGIN_ID BIGINT=null,
@BRANCHID NVARCHAR(MAX)=NULL,
@UPDATESTATUS NVARCHAR(200)=NULL
) 
---WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Priti Roy ON 23/09/2024
0027698: Customization work of New Order Status Update module
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @SQL NVARCHAR(MAX)=NULL,@sqlEmpStrTable NVARCHAR(MAX),@sqlShopStrTable NVARCHAR(MAX),@sqlStateStrTable NVARCHAR(MAX)
	
	--DECLARE @isRevisitTeamDetail NVARCHAR(100)
	--SELECT @isRevisitTeamDetail=[Value] FROM fts_app_config_settings WHERE [Key]='isRevisitTeamDetail' AND [Description]='Revisit from Team Details in Portal'
	
	DECLARE @SqlStrTable NVARCHAR(MAX)
	
	----------------------------------EMPLOYEE---------------------------
	
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @Employee_id <> ''
		BEGIN
			SET @Employee_id = REPLACE(''''+@Employee_id+'''',',',''',''')
			SET @sqlEmpStrTable=''
			SET @sqlEmpStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@Employee_id+')'
			EXEC SP_EXECUTESQL @sqlEmpStrTable
		END
     
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
	 
	-------------------------------STATE----------------------------------------------------
	
	IF OBJECT_ID('tempdb..#STATE_LIST') IS NOT NULL
	
		DROP TABLE #STATE_LIST
	CREATE TABLE #STATE_LIST (STATE_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @stateID <> ''
		BEGIN
			SET @stateID = REPLACE(''''+@stateID+'''',',',''',''')
			SET @sqlStateStrTable=''
			SET @sqlStateStrTable=' INSERT INTO #STATE_LIST SELECT id from tbl_master_state where id in('+@stateID+')'
			EXEC SP_EXECUTESQL @sqlStateStrTable
		END

	----------------------------------SHOP-------------------------------------------------------
	
	IF OBJECT_ID('tempdb..#SHOP_LIST') IS NOT NULL
	
		DROP TABLE #SHOP_LIST
	CREATE TABLE #SHOP_LIST (SHOP_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @shop_id <> ''
		BEGIN
			SET @shop_id = REPLACE(''''+@shop_id+'''',',',''',''')
			SET @sqlShopStrTable=''
			SET @sqlShopStrTable=' INSERT INTO #SHOP_LIST SELECT SHOP_ID from tbl_Master_shop where SHOP_ID in('+@shop_id+')'
			EXEC SP_EXECUTESQL @sqlShopStrTable
		END


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
	
	SET @SQL=''
	SET @SQL='SELECT shop.Shop_Code as shop_id,Shop_Name as shop_name,SHOP.ENTITYCODE,shop.Address as [address],shop.Pincode as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,'
	
	SET @SQL+='Shop_City,Shop_Owner as owner_name,Shop_WebSite,Shop_Owner_Email as owner_email,Shop_Owner_Contact as owner_contact_no,'
	
	SET @SQL+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EmployeeName,'
	SET @SQL+='BR.branch_description AS BRANCHDESC,typs.Name AS Shoptype,shop.type,ordr.Ordervalue AS order_amount,stat.state as [State],'
	
	SET @SQL+='Convert(varchar(100),ordr.Orderdate,103) as date,ordr.Collectionvalue as collection,ordr.Order_Description,ordr.OrderCode,ordr.OrderId,ordr.OrderId,ordr.Patient_Name,ordr.Patient_Phone_No,'
	SET @SQL+='ordr.Patient_Address,ordr.Hospital,ordr.Email_Address,ordr.ORDERSTATUS, cast(usr.user_id as int)as USERID '
	


	SET @SQL+='from tbl_Master_shop as shop '
	
	--IF @isRevisitTeamDetail='0'
	--	BEGIN
			SET @SQL+='INNER JOIN tbl_master_user usr on shop.Shop_CreateUser=usr.user_id '
			SET @SQL+='INNER JOIN tbl_master_contact CNT on CNT.cnt_internalId=usr.user_contactId '
			
			SET @SQL+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
			
			SET @SQL+='INNER JOIN tbl_shoptype  as typs on typs.shop_typeId=shop.type '
			SET @SQL+='INNER JOIN tbl_trans_fts_Orderupdate ordr on ordr.Shop_Code=shop.Shop_Code '
		--END
	--ELSE IF @isRevisitTeamDetail='1'
	--	BEGIN
	--		SET @SQL+='INNER JOIN tbl_trans_fts_Orderupdate ordr ON ordr.Shop_Code=shop.Shop_Code '
	--		SET @SQL+='INNER JOIN tbl_master_user usr ON ordr.userID=usr.user_id '
	--		SET @SQL+='INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=usr.user_contactId '
			
	--		SET @SQL+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
			
	--		SET @SQL+='INNER JOIN tbl_shoptype typs ON typs.shop_typeId=shop.type '
	--	END
	
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
		BEGIN
		SET @SQL+='INNER JOIN #EMPHR_EDIT EMPHR ON EMPHR.EMPCODE=CNT.cnt_internalId '
		END
	
	SET @SQL+='LEFT OUTER  JOIN (
	SELECT add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' 
	)S on S.add_cntId=CNT.cnt_internalId
	LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state
	where usr.user_id  is not null	'

	
	IF @BRANCHID<>''
		SET @SQL+='AND EXISTS (SELECT Branch_Id FROM #BRANCH_LIST AS F WHERE F.Branch_Id=BR.branch_id) '

	if(isnull(@Employee_id,'')<>'')

		SET @SQL+=' AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST WHERE emp_contactId=cnt_internalId) '
	if(isnull(@shop_id,'')<>'')
	
		SET @SQL+='  AND EXISTS (SELECT SHOP_ID FROM #SHOP_LIST WHERE SHOP_ID=shop.Shop_ID) ' 
	if(isnull(@stateID,'')<>'')
	
		SET @SQL+=' AND EXISTS (SELECT STATE_ID FROM #STATE_LIST WHERE STATE_ID=STAT.id) '
	if(isnull(@start_date,'')<>'')
		SET  @SQL+='  and  cast(ordr.Orderdate  as date)>='''+@start_date+'''' 
	if(isnull(@end_date,'')<>'')
		SET  @SQL+='  and  cast(ordr.Orderdate  as date)<='''+@end_date+'''' 

	if(isnull(@UPDATESTATUS,'')<>'Select' and isnull(@UPDATESTATUS,'')<>'')
	SET  @SQL+='  and  ordr.ORDERSTATUS='''+@UPDATESTATUS+'''' 
		

	EXEC SP_EXECUTESQL @SQL

--select @SQL
	DROP TABLE #STATE_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #SHOP_LIST
	
	DROP TABLE #BRANCH_LIST
	
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHR
	END


	SET NOCOUNT ON
END