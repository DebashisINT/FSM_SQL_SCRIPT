IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_UpdatesProduct]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_UpdatesProduct] AS'  
 END 
 GO


ALTER PROCEDURE [dbo].[Sp_UpdatesProduct] 
	@ProductId int,
	@ProductCode varchar(50) = null,
	@ProductName varchar(100) = null,
	-- Rev 4.0
	--@ProductDescription varchar(500) = null,
	@ProductDescription nvarchar(max) = null,
	-- End of Rev 4.0
	@ProductType varchar(10) = null,
	@ProductClassCode varchar(50) = null,
	@ProductGlobalCode varchar(50) = null,
	@ProductTradingLot int = null,
	@productTradingLotUnit int = null,
	@ProductQuoteCurrency decimal(18,2) = null,
	@ProductQuoteLot int = null,
	@productQuoteLotUnit int = null,
	@ProductDeliveryLot int = null,
	@ProductDeliveryLotUnit int = null,
	@ProductColor int = null,
	@ProductSize int = null,
	@ModifyUser int = null ,
	-- Add By Sam on 25102016 
	@sProducts_SizeApplicable bit=null,
	@sProducts_ColorApplicable bit=null,
	--Added By Debjyoti on 30122016
	@ProductBarCodeType int =null,
	@sProducts_barCode varchar(50)=null,
	--Added By Debjyoti on 04-01-2017
	@sProducts_isInventory bit=null,
	@sProduct_Stockvaluation varchar(5)=null,
	@sProduct_SalePrice numeric(18,0)=null,
	@sProduct_MinSalePrice numeric(18,0)= null,
	@sProduct_PurPrice numeric(18,0)=null,
	@BusinessFurtherness bit=null,--added by :Subhabrata on 03-07-2017
	-- Rev 3.0
	--@sProduct_MRP numeric(18,0)=null,
	@sProduct_MRP numeric(18,5)=null,
	-- End of Rev 3.0
	@sProduct_StockUOM int=null,
	@sProduct_MinLvl numeric(18,2)=null,
	@sProduct_reOrderLvl numeric(18,2)=null,
	@sProduct_NegativeStock varchar(5)=null,
	@sProduct_TaxSchemeSale int = null,
	@sProduct_TaxSchemePur int=null,
	@sProduct_TaxScheme int=null,
	@sProduct_AutoApply bit = null,
	@sProduct_ImagePath varchar(200)=null,
	@ProdComponent varchar(1000) = null ,
	@sProduct_Status varchar(5)=null,
	@sProducts_HsnCode varchar(10) = null,
	@sProducts_serviceTax int=null,
	@sProduct_quantity numeric(18,5)=null,
	@packing_quantity  numeric(18,5)=null,
	@packing_saleUOM int=null,
	@sProducts_isInstall bit = null,
	@sProducts_Brand int =null,
	@sProducts_isCapitalGoods bit = null,
	@sProducts_IsOldUnit bit = null,
	@sInv_MainAccount varchar(50)=null,
	@sRet_MainAccount varchar(50)=null,
	@pInv_MainAccount varchar(50)=null,
	@pRet_MainAccount varchar(50)=null,
	@sProducts_tdsCode int=null,
	@reorder_qty numeric (18,4)=null,--Added by Arindam on 11-07-2018
	-- Rev 2.0
	@ProductColorNew varchar(max) = null,
	@ProductSizeNew varchar(max) = null,
	@ProductGenderNew varchar(max) = null,
	-- End of Rev 2.0
	@sProducts_IsServiceItem bit = null
	-- Rev 3.0
	,@sProducts_Discount numeric(18,5)=null
	-- End of Rev 3.0
AS
/*************************************************************************************************
Written By : Jitendra on 10/01/2018
1.0		Jitendra			v1.0.70			11/01/2018		New field added 'Is_ServiceItem'
2.0		Sanchita			v2.0.26			07/09/2021		Gender, Size, Colour drop down multi selection field required under Product Attribute in Product Master in FSM
															Refer: 24299
3.0		Sanchita			v2.0.37			02-12-2022		MRP' and Discount' entering facility required in Product Master. Refer: 25469, 25470
4.0		Sanchita			V2.0.38			20-01-2023		Need to increase the length of the Description field of Product Master. Refer: 25603
***************************************************************************************************/ 
BEGIN

	--Update industry map table before update product master
	declare @ProductCodeold varchar(50) = null
	select @ProductCodeold=sProducts_Code from Master_sProducts where sProducts_ID=@ProductId
	if(@ProductCode != @ProductCodeold)
	 begin
		update Master_IndustryMap set IndustryMap_EntityID=@ProductCode where IndustryMap_EntityID=@ProductCodeold 
	end
	
	---get ProductSaleScheme and product PurchaseScheme Old value
	declare @purSchemeOld int=null
	declare @saleSchemeOld int = null
	select @purSchemeOld=sProduct_TaxSchemePur,@saleSchemeOld=sProduct_TaxSchemeSale from Master_sProducts where sProducts_ID=@ProductId
	
 
	
	
	UPDATE Master_sProducts 
	SET sProducts_Code = UPPER(@ProductCode)
		,sProducts_Name = UPPER(@ProductName)
		,sProducts_Description = @ProductDescription
		,sProducts_Type = @ProductType
		,ProductClass_Code = @ProductClassCode
		,sProducts_GlobalCode = @ProductGlobalCode
		,sProducts_TradingLot = @ProductTradingLot
		,sProducts_TradingLotUnit = @productTradingLotUnit
		,sProducts_QuoteCurrency = @ProductQuoteCurrency
		,sProducts_QuoteLot = @ProductQuoteLot
		,sProducts_QuoteLotUnit = @productTradingLotUnit--@productQuoteLotUnit
		,sProducts_DeliveryLot = @ProductDeliveryLot
		,sProducts_DeliveryLotUnit = @ProductDeliveryLotUnit
		,sProducts_Color = @ProductColor
		,sProducts_Size = @ProductSize
		,sProducts_ModifyUser = @ModifyUser
		,sProducts_ModifyTime = GETDATE(),
		sProducts_SizeApplicable=@sProducts_SizeApplicable,
		sProducts_ColorApplicable=@sProducts_ColorApplicable,
		sProducts_barCodeType=@ProductBarCodeType,
		sProducts_barCode=@sProducts_barCode,
		sProduct_IsInventory=@sProducts_isInventory,
		sProduct_Stockvaluation=@sProduct_Stockvaluation,
		sProduct_SalePrice=@sProduct_SalePrice,
		sProduct_MinSalePrice=@sProduct_MinSalePrice,
		sProduct_PurPrice=@sProduct_PurPrice,
		sProduct_MRP=@sProduct_MRP,
		sProduct_StockUOM=@sProduct_StockUOM,
		sProduct_MinLvl=@sProduct_MinLvl,
		sProduct_reOrderLvl=@sProduct_reOrderLvl,
		sProduct_NegativeStock=@sProduct_NegativeStock,
		sProduct_TaxSchemeSale=@sProduct_TaxSchemeSale,
		sProduct_TaxSchemePur=@sProduct_TaxSchemePur,
		sProduct_TaxScheme=@sProduct_TaxScheme,
		sProduct_AutoApply=@sProduct_AutoApply,
		sProduct_ImagePath=@sProduct_ImagePath,
		sProduct_Status=@sProduct_Status,
		sProducts_HsnCode=@sProducts_HsnCode,
		sProducts_serviceTax=@sProducts_serviceTax,
		sProducts_isInstall=@sProducts_isInstall,
		sProducts_Brand=@sProducts_Brand,
		sProduct_IsCapitalGoods=@sProducts_isCapitalGoods,
		sProducts_IsOldUnit=@sProducts_IsOldUnit,
		sInv_MainAccount=@sInv_MainAccount,
		sRet_MainAccount=@sRet_MainAccount,
		pInv_MainAccount=@pInv_MainAccount,
		pRet_MainAccount=@pRet_MainAccount,
		FurtheranceToBusiness=@BusinessFurtherness,
		Is_ServiceItem=@sProducts_IsServiceItem,
		Reorder_Quantity=@reorder_qty
		-- Rev 3.0
		, sProducts_Discount = @sProducts_Discount
		-- End of Rev 3.0
	WHERE sProducts_ID = @ProductId
	
	
	--Update Tds Code @sProducts_tdsCode
	if exists ( select 1 from tbl_master_productTdsMap where sProducts_ID=@ProductId)
		update tbl_master_productTdsMap set TDSTCS_ID=@sProducts_tdsCode where  sProducts_ID=@ProductId
	else
	  insert into tbl_master_productTdsMap (sProducts_ID,TDSTCS_ID) values(@ProductId,@sProducts_tdsCode)
	  
	--Update Packing details
	update tbl_master_product_packingDetails set sProduct_quantity=@sProduct_quantity,sProduct_SaleUom=@productTradingLotUnit,packing_quantity=@packing_quantity,packing_saleUOM=@packing_saleUOM where packing_sProductId=@ProductId
	
	-- Rev 2.0
	DECLARE @sqlStrTable NVARCHAR(MAX)

	if exists ( select 1 from Mapping_ProductSize where Products_ID=@ProductId )
		delete from Mapping_ProductSize WHERE Products_ID=@ProductId
	
	IF(@ProductSizeNew is not null and @ProductSizeNew<>'')
	BEGIN	
		
		IF OBJECT_ID('tempdb..#ProductSizeNew') IS NOT NULL
			DROP TABLE #ProductSizeNew
		CREATE TABLE #ProductSizeNew (Size_ID BIGINT)	
		
		set @ProductSizeNew = REPLACE(''''+@ProductSizeNew+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #ProductSizeNew select Size_ID from Master_Size where Size_ID in('+@ProductSizeNew+')'
		EXEC SP_EXECUTESQL @sqlStrTable

		INSERT INTO Mapping_ProductSize
			SELECT @ProductId,Size_ID,@ModifyUser,SYSDATETIME(),@ModifyUser,SYSDATETIME() FROM #ProductSizeNew
			
		--INSERT INTO Mapping_ProductSize(Products_ID, Size_ID, CreateUser, CreateTime) 
		--	VALUES(@ProductId,@ProductSizeNew,@ModifyUser,SYSDATETIME())
		
		
	END

	if exists ( select 1 from Mapping_ProductColor where Products_ID=@ProductId )
			DELETE FROM Mapping_ProductColor WHERE Products_ID=@ProductId

	IF(@ProductColorNew Is not null and @ProductColorNew<>'' )
	BEGIN
		--INSERT INTO Mapping_ProductColor(Products_ID, Color_ID, CreateUser, CreateTime) 
		--		VALUES(@ProductId,@ProductColorNew,@ModifyUser,SYSDATETIME())

		IF OBJECT_ID('tempdb..#ProductColorNew') IS NOT NULL
			DROP TABLE #ProductColorNew
		CREATE TABLE #ProductColorNew (Color_ID BIGINT)	
		
		set @ProductColorNew = REPLACE(''''+@ProductColorNew+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #ProductColorNew select Color_ID from Master_Color where Color_ID in('+@ProductColorNew+')'
		EXEC SP_EXECUTESQL @sqlStrTable

		INSERT INTO Mapping_ProductColor
			SELECT @ProductId,Color_ID,@ModifyUser,SYSDATETIME(),@ModifyUser,SYSDATETIME() FROM #ProductColorNew
			

	END


	if exists ( select 1 from Mapping_ProductGender where Products_ID=@ProductId )
		delete from Mapping_ProductGender WHERE Products_ID=@ProductId

	IF(@ProductGenderNew Is not null and @ProductGenderNew<>'')
	BEGIN
		IF OBJECT_ID('tempdb..#ProductGenderNew') IS NOT NULL
			DROP TABLE #ProductGenderNew
		CREATE TABLE #ProductGenderNew (Gender_ID BIGINT)	
		
		set @ProductGenderNew = REPLACE(''''+@ProductGenderNew+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #ProductGenderNew select Gender_ID from Master_Gender where Gender_ID in('+@ProductGenderNew+')'
		EXEC SP_EXECUTESQL @sqlStrTable

		INSERT INTO Mapping_ProductGender
			SELECT @ProductId,Gender_ID,@ModifyUser,SYSDATETIME(),@ModifyUser,SYSDATETIME() FROM #ProductGenderNew

		--INSERT INTO Mapping_ProductGender(Products_ID, Gender_ID, CreateUser, CreateTime) 
		--	VALUES(@ProductId,@ProductGenderNew,@ModifyUser,SYSDATETIME())
	END
	-- End of Rev 2.0

	---Update tbl_trans_ProductTaxRate table with respect to new scheme
	 
	--declare @taxRateCode int = null
	--declare @taxRateScheme varchar(100) = null 
	 
	--delete from tbl_trans_ProductTaxRate where prodId=@ProductId
	--if(@saleSchemeOld !=@sProduct_TaxSchemeSale)
	--begin
	--select @taxRateCode=TaxRates_TaxCode,@taxRateScheme=TaxRatesSchemeName from Config_TaxRates where TaxRates_ID=@sProduct_TaxSchemeSale
	--insert into tbl_trans_ProductTaxRate (TaxRates_TaxCode,TaxRatesSchemeName,prodId) values(@taxRateCode,@taxRateScheme,@ProductId)
	--end
 
 --   if(@purSchemeOld !=@sProduct_TaxSchemePur)
	--begin
	--select @taxRateCode=TaxRates_TaxCode,@taxRateScheme=TaxRatesSchemeName from Config_TaxRates where TaxRates_ID=@sProduct_TaxSchemePur
	--insert into tbl_trans_ProductTaxRate (TaxRates_TaxCode,TaxRatesSchemeName,prodId) values(@taxRateCode,@taxRateScheme,@ProductId)
	--end
	---Update tbl_trans_ProductTaxRate table End Here
	
	
	-- Product Component Insert Start here 

if exists (select 1 from tbl_master_ProdComponent where Product_id=@ProductId)  
    begin  
    delete from tbl_master_ProdComponent where Product_id=@ProductId  
    end  
  
--- insert one by one   
 DECLARE @counter INT    
 DECLARE @intFlag INT     
 declare @singleName varchar(50)  
 SET @intFlag = 1;       
 SET @counter = (SELECT COUNT(pn) FROM dbo.GetSplit(',', @ProdComponent))    
     
 WHILE (@intFlag <= @counter)    
 BEGIN    
 set @singleName=(  select T.s from (select row_number() over (order by pn asc) as Row, s from dbo.GetSplit(',',@ProdComponent)) T where T.Row=@intFlag);  
     
   if(ltrim(rtrim(@singleName))!='')  
  begin  
  insert into tbl_master_ProdComponent (Product_id,Component_prodId) values(@ProductId,@singleName)  
  end  
   SET @intFlag = @intFlag + 1 ;    
end   
-- Product Component Insert End here 
END
GO