--EXEC Proc_ShopAssignmen @Action='DD',@state_id='15',@user_id=11986

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_ShopAssignmen]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_ShopAssignmen] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_ShopAssignmen]
(
@Action varchar(50)=NULL,
@state_id varchar(50)=NULL,
@user_id BIGINT=NULL
) --WITH ENCRYPTION
AS
BEGIN
	/************************************************************************************************
	1.0		Tanmoy		16-10-2019	@Action='DD' SEARCH BY SHOP CREATE USER
	2.0		Tanmoy		14-01-2020	@Action='pp' PP ALLOW TO SHOW TO ALL STATE AND STATE WISE
	3.0		Tanmoy		13-02-2020	@Action='pp' shop type show pp and stockist
	4.0		Tanmoy		23-07-2020	@Action='DD' IF @AllDDSHOW CHECKING
	5.0		Debashis	16-08-2021	@Action='DD' Added two new columns as Shop_Lat & Shop_Long
	6.0		Tanmoy		27-08-2021	@SQLEXC parameter length change
	************************************************************************************************/ 
	SET NOCOUNT ON

	DECLARE @DDSHOW NVARCHAR(10),@AllDDSHOW NVARCHAR(10)
	DECLARE @PPSHOW NVARCHAR(10)
	--Rev 6.0
	--DECLARE @SQLEXC NVARCHAR(500)
	DECLARE @SQLEXC NVARCHAR(MAX)
	--End of Rev 6.0
	select @DDSHOW=[Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isShowStateWiseAllDD'
	select @PPSHOW=[Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isShowAllPP'
	select @AllDDSHOW=[Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isShowAllDD'
	
	if(@Action='PP')
		BEGIN
		SET @SQLEXC=' '
			--SET @SQLEXC +='select  Shop_Code as assigned_to_pp_id ,Shop_Name as assigned_to_pp_authorizer_name,Shop_Owner_Contact as phn_no  from tbl_Master_shop   '
			--IF @PPSHOW<>'1'
			--BEGIN
			--SET @SQLEXC +='where stateid=@state_id   '
			--END
			----LEFT  OUTER  JOIN  tbl_salesman_address as addr on addr.UserId=tbl_Master_shop.Shop_CreateUser and addr.stateid=@state_id
			--SET @SQLEXC +='and type=2   '
			--SET @SQLEXC +='order by Shop_Name   '
			IF(@PPSHOW=0)
			select Shop_Code as assigned_to_pp_id ,Shop_Name as assigned_to_pp_authorizer_name,Shop_Owner_Contact as phn_no from tbl_Master_shop WITH(NOLOCK)
			where stateid IN (@state_id,0) 
			--REV Start 3.0
			and type in (2,6) 
			--REV end 3.0
			 order by Shop_Name   
			 ELSE
			 select Shop_Code as assigned_to_pp_id ,Shop_Name as assigned_to_pp_authorizer_name,Shop_Owner_Contact as phn_no from tbl_Master_shop WITH(NOLOCK)
			where-- stateid IN (@state_id,0) 
			--REV Start 3.0
			--and 
			type in (2,6) 
			--REV end 3.0
			 order by Shop_Name
			
		END
	else if(@Action='DD')
		BEGIN
			--Rev 5.0 && Added two new columns as Shop_Lat & Shop_Long
			SET @SQLEXC='select Shop_Code as assigned_to_dd_id , assigned_to_pp_id,Shop_Name as assigned_to_dd_authorizer_name ,Shop_Owner_Contact as phn_no,
			CASE WHEN ISNULL(convert(varchar(10),dealer_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),dealer_id),'''') end type_id,'
			SET @SQLEXC +='CASE WHEN Shop_Lat=''0'' OR Shop_Lat='''' THEN ''0'' ELSE Shop_Lat END AS dd_latitude,CASE WHEN Shop_Long=''0'' OR Shop_Long='''' THEN ''0'' ELSE Shop_Long END AS dd_longitude from tbl_Master_shop WITH(NOLOCK) '
			SET @SQLEXC +='where type=4 '
			IF ((SELECT IsUserwiseDistributer FROM TBL_MASTER_USER WITH(NOLOCK) WHERE USER_ID=@user_id)=0)
			BEGIN
				IF @AllDDSHOW<>'1'
				BEGIN
					SET @SQLEXC +=' AND stateid='''+@state_id+''' '

					IF @DDSHOW<>'1'
					BEGIN
						SET @SQLEXC +='AND Shop_CreateUser='+RTRIM(LTRIM(STR(@user_id)))+'  '
					END
				END
			END
			ELSE
			BEGIN
				SET @SQLEXC +=' AND Shop_Code IN (SELECT SHOP_CODE FROM FTS_EmployeeShopMap WITH(NOLOCK) WHERE USER_ID='+RTRIM(LTRIM(STR(@user_id)))+') '
			END
			--LEFT  OUTER  JOIN  tbl_salesman_address as addr on addr.UserId=tbl_Master_shop.Shop_CreateUser and addr.stateid=@state_id
			-- 
			SET @SQLEXC +=' order by Shop_Name  '

			exec sp_sqlexec @SQLEXC
			--select @SQLEXC
		END
	else if(@Action='Shop')
		BEGIN
			SET @SQLEXC='select  Shop_Code as assigned_to_shop_id , Shop_Name as name ,Shop_Owner_Contact as phn_no,
			CASE WHEN ISNULL(convert(varchar(10),retailer_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),retailer_id),'''') end type_id  from tbl_Master_shop WITH(NOLOCK) '
			SET @SQLEXC +='where type=1 '
			--SET @SQLEXC +=' AND stateid='''+@state_id+''' '
			SET @SQLEXC +='AND Shop_CreateUser='''+@user_id+'''  '
			SET @SQLEXC +=' order by Shop_Name  '

			exec sp_sqlexec @SQLEXC
		END

	SET NOCOUNT OFF
END