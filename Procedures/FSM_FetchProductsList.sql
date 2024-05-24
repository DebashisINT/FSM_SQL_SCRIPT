

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FSM_FetchProductsList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FSM_FetchProductsList] AS' 
END
GO

ALTER  Procedure [dbo].[FSM_FetchProductsList]
(
	@Products nvarchar(MAX)='',
	@User_id int=null
)
AS
/*================================================================================================================================================================
	Written by Sanchita	V.0.39			28/02/2023      FSM >> Product Master : Listing - Implement Show Button. Refer: 25709
	Rev 1.0		Sanchita	V2.0.46		11/03/2024		FSM Product Master - Search, Filter not working. Converted to Linq. Mantis: 27307
	Rev 2.0		Priti	    V2.0.47		21/05/2024		New column shall be implemented in Product Master. Mantis: 0027463
==================================================================================================================================================================*/
BEGIN
	DECLARE @DSql NVARCHAR(MAX)

	-- Rev 1.0
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FSMProduct_Master') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FSMProduct_Master
		(
			USERID int, sProducts_ID bigint,	sProducts_Code varchar(80),	sProducts_Name varchar(100),	sProducts_Description nvarchar(max),
			sProducts_Type char(1),	sProducts_TypeFull varchar(100),	ProductClass_Code int,	ProductClass_Name varchar(100),	
			sProducts_GlobalCode varchar(30),	sProducts_TradingLot int,	sProducts_TradingLotUnit int,	sProducts_QuoteCurrency int,
			sProducts_QuoteLot int,	sProducts_QuoteLotUnit int,	sProducts_DeliveryLot int,	sProducts_DeliveryLotUnit int,	
			sProducts_Color int,	sProducts_Size int,	sProducts_CreateUser int,	sProducts_CreateTime datetime,	sProducts_ModifyUser int,
			sProducts_ModifyTime datetime,	HSNCODE varchar(50),	Brand_Name varchar(50),	sProduct_IsInventory varchar(10),	Is_ServiceItem varchar(10),
			sProduct_IsCapitalGoods varchar(10),	sInv_MainAccount varchar(50),	sRet_MainAccount varchar(50),	
			pInv_MainAccount varchar(50),	pRet_MainAccount varchar(50)
			,sProduct_Status varchar(50)
		)
		CREATE NONCLUSTERED INDEX IX1 ON FSMProduct_Master (sProducts_ID)
	END
	DELETE FROM FSMProduct_Master WHERE USERID=@User_id
	-- End of Rev 1.0
	
	SET @DSql = ''

	-- Rev 1.0
	SET @DSql = 'INSERT INTO FSMProduct_Master '
	-- End of Rev 1.0
	SET @DSql += 'SELECT '+convert(varchar(50),@User_id) +',MP.sProducts_ID ,MP.sProducts_Code ,MP.sProducts_Name ,MP.sProducts_Description ,MP.sProducts_Type ,'
	SET @DSql += 'CASE WHEN MP.sProducts_Type =''A'' THEN ''Raw Material'' WHEN MP.sProducts_Type =''B'' THEN ''Work-In-Process'' WHEN  MP.sProducts_Type =''C'' THEN ''Finished Goods'' END AS sProducts_TypeFull '
	SET @DSql += ',MP.ProductClass_Code ,MPC.ProductClass_Name ,MP.sProducts_GlobalCode,MP.sProducts_TradingLot, MP.sProducts_TradingLotUnit,MP.sProducts_QuoteCurrency ,MP.sProducts_QuoteLot, '
    SET @DSql += 'MP.sProducts_QuoteLotUnit, MP.sProducts_DeliveryLot, MP.sProducts_DeliveryLotUnit ,MP.sProducts_Color ,MP.sProducts_Size,MP.sProducts_CreateUser ,MP.sProducts_CreateTime'
	SET @DSql += ',MP.sProducts_ModifyUser ,MP.sProducts_ModifyTime ,case ISNULL(MP.sProducts_HsnCode,'''')when '''' then ISNULL(SERVICE_CATEGORY_CODE,'''')else MP.sProducts_HsnCode end  HSNCODE '
	SET @DSql += ',Brand_Name ,case sProduct_IsInventory when 1 then ''Yes'' else ''No'' end sProduct_IsInventory '
	SET @DSql += ',case Is_ServiceItem when 1 then ''Yes'' else ''No'' end Is_ServiceItem ,case sProduct_IsCapitalGoods  when 1 then ''Yes'' else ''No'' end sProduct_IsCapitalGoods '
	SET @DSql += ',sInv_MainAccount,sRet_MainAccount,pInv_MainAccount,pRet_MainAccount '
	--Rev 2.0
	SET @DSql += ',case when sProduct_Status=''A'' then ''Active'' when sProduct_Status=''D'' then ''Dormant''   end as sProduct_Status'
	--Rev 2.0 End
	SET @DSql += ' FROM Master_sProducts MP '
	SET @DSql += 'left join Master_ProductClass MPC '
	SET @DSql += 'on MP.ProductClass_Code=MPC.ProductClass_ID  left outer join TBL_MASTER_SERVICE_TAX sac on '
	SET @DSql += 'MP.sProducts_serviceTax=sac.TAX_ID '
    SET @DSql += 'left outer join tbl_master_brand brand on MP.sProducts_Brand=brand.Brand_Id '
	IF (@Products <>'')
	BEGIN
		SET @Products = '''' + replace(@Products,',',''',''')  + ''''
		SET @DSql += 'where MP.sProducts_ID in ('+@Products+')'
	END
	SET @DSql += 'order by MP.sProducts_ID desc '

	--select @DSql
	Exec sp_executesql @Dsql
END
GO