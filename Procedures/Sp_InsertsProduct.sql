IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_InsertsProduct]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_InsertsProduct] AS'  
 END 
 GO 

 
ALTER PROCEDURE [dbo].[Sp_InsertsProduct]
	@ProductCode varchar(80) = null,
	@ProductName varchar(100) = null,
	@ProductDescription varchar(500) = null,
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
	@ProductCreateUser int = null,
	-- Add By Sam on 25102016 
	@sProducts_SizeApplicable bit=null,
	@sProducts_ColorApplicable bit=null,
	--Added By Debjyoti on 30122016
	@ProductBarCodeType int =null,
	@sProducts_barCode varchar(50)=null,
	--Added by Debjyoti on 04012016
	@sProductsIsInventory bit=null,
	@BusinessFurtherness bit=null,--added by :Subhabrata on 03-07-2017
	@sProduct_Stockvaluation varchar(10) = null,
	@sProduct_SalePrice decimal(18,5)=null,
	@sProduct_MinSalePrice decimal(18,5)=null,
	@sProduct_PurPrice numeric(18,5) = null,
	@sProduct_MRP numeric(18,5)=null,
	-- Rev 3.0
	@sProducts_Discount numeric(18,5)=null,
	-- End of Rev 3.0
	@sProduct_StockUOM int =null,
	@sProduct_MinLvl numeric(18,2)= null,
	@sProduct_reOrderLvl numeric(18,2)=null,
	@sProduct_NegativeStock varchar(5)= null,
	@sProduct_TaxSchemeSale int = null,
	@sProduct_TaxSchemePur int = null,
	@sProduct_TaxScheme int=null,
	@sProduct_AutoApply bit=null,
	@sProduct_ImagePath varchar(200)=null,
	@ProdComponent varchar(1000) = null ,
	@prodId int = null,
	@sProduct_Status varchar(5)=null,
	@sProducts_HsnCode varchar(10) = null,
	@sProducts_serviceTax int=null,
	@sProduct_quantity numeric(18,5)=null,
	@packing_quantity  numeric(18,5)=null,
	@packing_saleUOM int=null,
	@sProducts_isInstall bit = null,
	@sProducts_Brand int = null,
	@sProducts_isCapitalGoods bit = null,
	@sProducts_tdsCode int = null,
	@Finyear nvarchar(20)=null,
	@sProducts_IsOldUnit bit=null,
	@sInv_MainAccount varchar(50)= null,
	@sRet_MainAccount varchar(50)=null,
	@pInv_MainAccount varchar(50)=null,
	@pRet_MainAccount varchar(50)=null,
	@sProducts_IsServiceItem bit = null,
	@reorder_qty numeric (18,4)=null,--Added by Arindam on 11-07-2018
	-- Rev 2.0
	@ProductColorNew varchar(max) = null,
	@ProductSizeNew varchar(max) = null,
	@ProductGenderNew varchar(max) = null,
	-- End of Rev 2.0
	@ReturnValue nvarchar (50)=null output
AS
/*************************************************************************************************
Written By : Jitendra on 10/01/2018
1.0		Jitendra			v1.0.70			11/01/2018		New field added 'Is_ServiceItem'
1.0		Arindam				V1.0.078		11/07/2018		New field added 'Reorder_Quantity' and Insert
2.0		Sanchita			v2.0.26			07/09/2021		Gender, Size, Colour drop down multi selection field required under Product Attribute in Product Master in FSM
															Refer: 24299
3.0		Sanchita			v2.0.37			02-12-2022		MRP' and Discount' entering facility required in Product Master. Refer: 25469, 25470
***************************************************************************************************/ 
BEGIN
	INSERT INTO Master_sProducts(
					sProducts_Code
				    ,sProducts_Name
					,sProducts_Description
					,sProducts_Type
					,ProductClass_Code
					,sProducts_GlobalCode
					,sProducts_TradingLot
					,sProducts_TradingLotUnit
					,sProducts_QuoteCurrency
					,sProducts_QuoteLot
					,sProducts_QuoteLotUnit
					,sProducts_DeliveryLot
					,sProducts_DeliveryLotUnit
					,sProducts_Color
					,sProducts_Size
					,sProducts_CreateUser
					,sProducts_CreateTime,sProducts_SizeApplicable,sProducts_ColorApplicable
					,sProducts_barCodeType,sProducts_barCode
					,sProduct_IsInventory,sProduct_Stockvaluation,sProduct_SalePrice,sProduct_MinSalePrice
					,sProduct_PurPrice,sProduct_MRP,sProduct_StockUOM,sProduct_MinLvl,sProduct_reOrderLvl
					,sProduct_NegativeStock,sProduct_TaxSchemeSale,sProduct_TaxSchemePur,sProduct_TaxScheme,sProduct_AutoApply
					,sProduct_ImagePath,sProduct_Status
					,sProducts_HsnCode,sProducts_serviceTax
					,sProducts_isInstall,sProducts_Brand,sProduct_IsCapitalGoods,sProducts_IsOldUnit
					,sInv_MainAccount,sRet_MainAccount,pInv_MainAccount,pRet_MainAccount,FurtheranceToBusiness,Is_ServiceItem,Reorder_Quantity
					-- Rev 3.0
					,sProducts_Discount
					-- End of Rev 3.0
					) VALUES(
											UPPER(@ProductCode)
											,UPPER(@ProductName)
											,@ProductDescription
											,@ProductType
											,@ProductClassCode
											,@ProductGlobalCode
											,@ProductTradingLot
											,@productTradingLotUnit
											,@ProductQuoteCurrency
											,@ProductQuoteLot
											,@productTradingLotUnit--,@productQuoteLotUnit
											,@ProductDeliveryLot
											,@ProductDeliveryLotUnit
											,@ProductColor
											,@ProductSize
											,@ProductCreateUser
											,GETDATE(),@sProducts_SizeApplicable,@sProducts_ColorApplicable
											,@ProductBarCodeType,@sProducts_barCode
											,@sProductsIsInventory,@sProduct_Stockvaluation,@sProduct_SalePrice,@sProduct_MinSalePrice
											,@sProduct_PurPrice,@sProduct_MRP,@sProduct_StockUOM,@sProduct_MinLvl,@sProduct_reOrderLvl
											,@sProduct_NegativeStock,@sProduct_TaxSchemeSale,@sProduct_TaxSchemePur,@sProduct_TaxScheme,@sProduct_AutoApply
											,@sProduct_ImagePath,@sProduct_Status
											,@sProducts_HsnCode,@sProducts_serviceTax
											,@sProducts_isInstall,@sProducts_Brand,@sProducts_isCapitalGoods,@sProducts_IsOldUnit
											,@sInv_MainAccount,@sRet_MainAccount,@pInv_MainAccount,@pRet_MainAccount,@BusinessFurtherness,@sProducts_IsServiceItem,@reorder_qty
											-- Rev 3.0
											,@sProducts_Discount 
											-- End of Rev 3.0
											)
											
											
											
										
											
-- Product Component Insert Start here 
set @prodId=@@IDENTITY;

--Insert into TDS table

insert into tbl_master_productTdsMap(sProducts_ID,TDSTCS_ID) values(@prodId,@sProducts_tdsCode) 

	-- Rev 2.0
	DECLARE @sqlStrTable NVARCHAR(MAX)

	if exists ( select 1 from Mapping_ProductSize where Products_ID=@prodId )
		delete from Mapping_ProductSize WHERE Products_ID=@prodId
	
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
			SELECT @prodId,Size_ID,@PRODUCTCREATEUSER,SYSDATETIME(),null,null FROM #ProductSizeNew
			
		
	END

	if exists ( select 1 from Mapping_ProductColor where Products_ID=@prodId )
			DELETE FROM Mapping_ProductColor WHERE Products_ID=@prodId

	IF(@ProductColorNew Is not null and @ProductColorNew<>'' )
	BEGIN

		IF OBJECT_ID('tempdb..#ProductColorNew') IS NOT NULL
			DROP TABLE #ProductColorNew
		CREATE TABLE #ProductColorNew (Color_ID BIGINT)	
		
		set @ProductColorNew = REPLACE(''''+@ProductColorNew+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #ProductColorNew select Color_ID from Master_Color where Color_ID in('+@ProductColorNew+')'
		EXEC SP_EXECUTESQL @sqlStrTable

		INSERT INTO Mapping_ProductColor
			SELECT @prodId,Color_ID,@PRODUCTCREATEUSER,SYSDATETIME(),null,null FROM #ProductColorNew
			

	END


	if exists ( select 1 from Mapping_ProductGender where Products_ID=@prodId )
		delete from Mapping_ProductGender WHERE Products_ID=@prodId

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
			SELECT @prodId,Gender_ID,@PRODUCTCREATEUSER,SYSDATETIME(),null,null FROM #ProductGenderNew

	END
	-- End of Rev 2.0

set @ReturnValue= CAST(@prodId as varchar(50))
--Insert into packingDetails table 
	insert into tbl_master_product_packingDetails (packing_sProductId,sProduct_quantity,sProduct_SaleUom,packing_quantity,packing_saleUOM) values(@prodId,@sProduct_quantity,@productTradingLotUnit,@packing_quantity,@packing_saleUOM)	
	--End Here 	


if exists (select 1 from tbl_master_ProdComponent where Product_id=@prodId)  
    begin  
    delete from tbl_master_ProdComponent where Product_id=@prodId  
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
  insert into tbl_master_ProdComponent (Product_id,Component_prodId) values(@prodId,@singleName)  
  end  
   SET @intFlag = @intFlag + 1 ;    
end   
-- Product Component Insert End here 

	
---Update Scheme
 declare @taxRate int=null
 declare @schemeName varchar(100)=null	
-- Set Sale Scheme   
 if(@sProduct_TaxSchemeSale !=0)
 begin
  select @taxRate=TaxRates_TaxCode,@schemeName=TaxRatesSchemeName from Config_TaxRates where TaxRates_ID=@sProduct_TaxSchemeSale
  
  --insert into tbl_trans_ProductTaxRate (TaxRates_TaxCode,TaxRatesSchemeName,prodId) values(@taxRate,@schemeName,@prodId)
 End

-- Set Purchase Scheme
 if(@sProduct_TaxSchemePur !=0)
 begin
  select @taxRate=TaxRates_TaxCode,@schemeName=TaxRatesSchemeName from Config_TaxRates where TaxRates_ID=@sProduct_TaxSchemePur
  
  --insert into tbl_trans_ProductTaxRate (TaxRates_TaxCode,TaxRatesSchemeName,prodId) values(@taxRate,@schemeName,@prodId)
 End
											
--Update Scheme End Here	


---Update is_active_warehouse

if(@sProductsIsInventory=1)
begin
	if exists(select 1 from Master_sProducts where sProduct_IsInventory=1 and is_active_warehouse=1)
	   begin
	   update Master_sProducts set is_active_warehouse=1 where sProducts_id=@prodId
	   end
end
	
	--------------------Jitendra- (Adding Product in Stock Table)---------------------------------
	DECLARE @cmp_InternalId nvarchar(20)
	DECLARE db_cursorserial CURSOR FOR  
           select cmp_InternalId from tbl_master_company
           OPEN db_cursorserial   
           FETCH NEXT FROM db_cursorserial INTO @cmp_InternalId   

           WHILE @@FETCH_STATUS = 0   
           BEGIN   
           IF NOT EXISTS(Select * from Trans_Stock Where Stock_ProductID=@prodId and Stock_FinYear=@Finyear and stock_company=@cmp_InternalId)
			 BEGIN
				INSERT INTO [Trans_Stock]
						   ([Stock_Company]
						   ,[Stock_FinYear]
						   ,[Stock_ProductID]						   
						   ,[Stock_In]						  
						   ,[Stock_ModifiedDate]
						   )
					 VALUES
						   (@cmp_InternalId
						   ,@Finyear
						   ,@prodId						   
						   ,0
						   ,GetDate()
						   )
				declare @transStockId int
				set @transStockId=@@IDENTITY
                --Insert blank row in stock branch warehouse, Otherwise product will not come in opening form 
    --             insert Into Trans_StockBranchWarehouse (
				--		StockBranchWarehouse_StockId,StockBranchWarehouse_BranchId,StockBranchWarehouse_CompanyId,StockBranchWarehouse_FinYear,
				--		StockBranchWarehouse_WarehouseId,StockBranchWarehouse_StockIn,StockBranchWarehouse_StockOut,Stock_IN_Out
				--		 )
				--			values 
				--			   (@transStockId,0,@cmp_InternalId,@Finyear,0,0,0,'IN')
				
				--declare @StockBranchWarehouse_Id int
				--set @StockBranchWarehouse_Id=@@IDENTITY			                 
    --             ---Insert Into detail table
    --             insert Into Trans_StockBranchWarehouseDetails ( 
				--StockBranchWarehouse_Id,StockBranchWarehouseDetail_WarehouseId,StockBranchWarehouseDetail_ProductId,Doc_Type,
				--StockBranchWarehouseDetail_BranchId,StockBranchWarehouseDetail_CompanyId,StockBranchWarehouseDetail_FinYear,
				--Stock_OpeningRate,Stock_OpeningValue
				--)
				--values
				--(@StockBranchWarehouse_Id,0,@prodId,'OP',0,@cmp_InternalId,@Finyear,0,0
				--)
                 
                 
   
			 END
           FETCH NEXT FROM db_cursorserial INTO @cmp_InternalId
            END
            CLOSE db_cursorserial   
            DEALLOCATE db_cursorserial 
	
	------------------------------------------------------
	
	
										
END
go