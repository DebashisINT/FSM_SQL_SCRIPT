IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_OPENAPI_PRODUCTDETAILS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_OPENAPI_PRODUCTDETAILS] AS' 
END
GO
ALTER PROC [dbo].[PRC_OPENAPI_PRODUCTDETAILS]
(
@ACTION VARCHAR(500)=NULL,
@ORDERCODE NVARCHAR(100)=NULL,
@ProductCode  NVARCHAR(500)=NULL,
@session_token NVARCHAR(MAX)=NULL,
@Uniquecont int=0,
@SearchKey NVARCHAR(MAX)=NULL,
@user_id varchar(50)=NULL,
@JsonXML XML=NULL
)
AS
/*************************************************************************************************************************
Written by Priti for V2.0.39 on 08/03/2023 - Implement Open API for Product Master  
Create Open API For Product Master refer Mantis:25872

******************************************************************************************************************************/
BEGIN
    SET NOCOUNT ON
	declare @sql NVARCHAR(MAX)=''
	declare @topcount NVARCHAR(100)=@Uniquecont
	Declare @SalesUnitID int=0,@PurchaseUnitID int=0,@SalesUnit nvarchar(500)='',@PurchaseUnit  nvarchar(500)='',@ProductName nvarchar(500)='',@Description nvarchar(500)=''
	,@MRP decimal(18,2) =0,@Discount decimal(18,2) =0
	IF(@ACTION='GetHeaderProductDetails')
	BEGIN
		SELECT sProducts_Code ProductsCode,sProducts_Name ProductsName,sProducts_Description ProductsDescription, ISNULL(STK_MASTER_UOM.UOM_NAME, '') AS STKUOMNAME,
		ISNULL(SALES_MASTER_UOM.UOM_NAME, '') AS SALESUOMNAME,ISNULL(PRODUCTCLASS_NAME,'') CLASSCODE,ISNULL(BRAND_NAME,'') BRANDNAME
		FROM Master_sProducts 
		LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCT_STOCKUOM = STK_MASTER_UOM.UOM_ID 
		LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID
		LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE
		LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND
		where sProducts_Code=@ProductCode
		

	END
	Else IF(@ACTION='GetProductDetails')
	BEGIN
		
	    IF(isnull(@Uniquecont,0)<>0)
		BEGIN
				IF(isnull(@SearchKey,0)<>'')
				Begin
					set @sql=' SELECT top '+@topcount+' sProducts_Code ProductsCode,sProducts_Name ProductsName,sProducts_Description ProductsDescription, ISNULL(STK_MASTER_UOM.UOM_NAME,'' '') AS PURCHASEUOMNAME, '
				set @sql+='ISNULL(SALES_MASTER_UOM.UOM_NAME, '''') AS SALESUOMNAME,ISNULL(PRODUCTCLASS_NAME,'''') CLASSCODE,ISNULL(BRAND_NAME,'''') BRANDNAME '
				set @sql+=',case when  sProduct_Status=''A'' then ''Active'' else ''Dormant'' end STATUS ,CAST(isnull(sProduct_MRP,0) AS DECIMAL(18,2))MRP,CAST(isnull(sProducts_Discount,0)AS DECIMAL(18,2))DISCOUNT '
				set @sql+=',Color_Name COLOR,Size_Name SIZE,Gender_Name GENDER,sProduct_quantity PRODUCTQTY,MASTER_UOM_ProductUom.UOM_Name PRODUCTUOM,packing_quantity PACKINGQTY,MASTERpacking_saleUOM.UOM_Name PACKINGUOM '
				set @sql+='FROM Master_sProducts ' 
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.sProducts_DeliveryLotUnit = STK_MASTER_UOM.UOM_ID  '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID '
				set @sql+='LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE '
				set @sql+='LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductColor ON Mapping_ProductColor.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Color ON Master_Color.Color_ID=Mapping_ProductColor.Color_ID '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductSize ON Mapping_ProductSize.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Size ON Master_Size.Size_ID=Mapping_ProductSize.Size_ID '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductGender ON Mapping_ProductGender.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Gender ON Master_Gender.Gender_ID=Mapping_ProductGender.Gender_ID '
				set @sql+='LEFT OUTER JOIN tbl_master_product_packingDetails on packing_sProductId=sProducts_ID '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS MASTER_UOM_ProductUom ON DBO.tbl_master_product_packingDetails.sProduct_SaleUom = MASTER_UOM_ProductUom.UOM_ID  '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS MASTERpacking_saleUOM ON DBO.tbl_master_product_packingDetails.packing_saleUOM = MASTERpacking_saleUOM.UOM_ID  '
					set @sql+='where (sProducts_Code like ''%'+@SearchKey+'%'') or (sProducts_Name like ''%'+@SearchKey+'%'')'

					--select  @sql
					EXEC SP_EXECUTESQL @sql
				End
				else
				Begin
					set @sql=' SELECT top '+@topcount+' sProducts_Code ProductsCode,sProducts_Name ProductsName,sProducts_Description ProductsDescription, ISNULL(STK_MASTER_UOM.UOM_NAME,'' '') AS PURCHASEUOMNAME, '
				set @sql+='ISNULL(SALES_MASTER_UOM.UOM_NAME, '''') AS SALESUOMNAME,ISNULL(PRODUCTCLASS_NAME,'''') CLASSCODE,ISNULL(BRAND_NAME,'''') BRANDNAME '
				set @sql+=',case when  sProduct_Status=''A'' then ''Active'' else ''Dormant'' end STATUS ,CAST(isnull(sProduct_MRP,0) AS DECIMAL(18,2))MRP,CAST(isnull(sProducts_Discount,0)AS DECIMAL(18,2))DISCOUNT '
				set @sql+=',Color_Name COLOR,Size_Name SIZE,Gender_Name GENDER,sProduct_quantity PRODUCTQTY,MASTER_UOM_ProductUom.UOM_Name PRODUCTUOM,packing_quantity PACKINGQTY,MASTERpacking_saleUOM.UOM_Name PACKINGUOM '
				set @sql+='FROM Master_sProducts ' 
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.sProducts_DeliveryLotUnit = STK_MASTER_UOM.UOM_ID  '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID '
				set @sql+='LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE '
				set @sql+='LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductColor ON Mapping_ProductColor.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Color ON Master_Color.Color_ID=Mapping_ProductColor.Color_ID '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductSize ON Mapping_ProductSize.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Size ON Master_Size.Size_ID=Mapping_ProductSize.Size_ID '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductGender ON Mapping_ProductGender.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Gender ON Master_Gender.Gender_ID=Mapping_ProductGender.Gender_ID '
				set @sql+='LEFT OUTER JOIN tbl_master_product_packingDetails on packing_sProductId=sProducts_ID '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS MASTER_UOM_ProductUom ON DBO.tbl_master_product_packingDetails.sProduct_SaleUom = MASTER_UOM_ProductUom.UOM_ID  '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS MASTERpacking_saleUOM ON DBO.tbl_master_product_packingDetails.packing_saleUOM = MASTERpacking_saleUOM.UOM_ID  '
						--set @sql+='where (sProducts_Code like ''%'+@SearchKey+'%'') or (sProducts_Name like ''%'+@SearchKey+'%'')'

					--select  @sql
					EXEC SP_EXECUTESQL @sql
				End
		END
		ELSE
		BEGIN
			IF(isnull(@SearchKey,0)<>'')
			Begin
				set @sql='SELECT sProducts_Code ProductsCode,sProducts_Name ProductsName,sProducts_Description ProductsDescription, ISNULL(STK_MASTER_UOM.UOM_NAME,'' '') AS PURCHASEUOMNAME, '
				set @sql+='ISNULL(SALES_MASTER_UOM.UOM_NAME, '''') AS SALESUOMNAME,ISNULL(PRODUCTCLASS_NAME,'''') CLASSCODE,ISNULL(BRAND_NAME,'''') BRANDNAME '
				set @sql+=',case when  sProduct_Status=''A'' then ''Active'' else ''Dormant'' end STATUS ,CAST(isnull(sProduct_MRP,0) AS DECIMAL(18,2))MRP,CAST(isnull(sProducts_Discount,0)AS DECIMAL(18,2))DISCOUNT '
				set @sql+=',Color_Name COLOR,Size_Name SIZE,Gender_Name GENDER,sProduct_quantity PRODUCTQTY,MASTER_UOM_ProductUom.UOM_Name PRODUCTUOM,packing_quantity PACKINGQTY,MASTERpacking_saleUOM.UOM_Name PACKINGUOM '
				set @sql+='FROM Master_sProducts ' 
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.sProducts_DeliveryLotUnit = STK_MASTER_UOM.UOM_ID  '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID '
				set @sql+='LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE '
				set @sql+='LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductColor ON Mapping_ProductColor.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Color ON Master_Color.Color_ID=Mapping_ProductColor.Color_ID '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductSize ON Mapping_ProductSize.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Size ON Master_Size.Size_ID=Mapping_ProductSize.Size_ID '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductGender ON Mapping_ProductGender.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Gender ON Master_Gender.Gender_ID=Mapping_ProductGender.Gender_ID '
				set @sql+='LEFT OUTER JOIN tbl_master_product_packingDetails on packing_sProductId=sProducts_ID '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS MASTER_UOM_ProductUom ON DBO.tbl_master_product_packingDetails.sProduct_SaleUom = MASTER_UOM_ProductUom.UOM_ID  '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS MASTERpacking_saleUOM ON DBO.tbl_master_product_packingDetails.packing_saleUOM = MASTERpacking_saleUOM.UOM_ID  '

				set @sql+='where (sProducts_Code like ''%'+@SearchKey+'%'') or (sProducts_Name like ''%'+@SearchKey+'%'')'
				--select  @sql
				EXEC SP_EXECUTESQL @sql
			End
			Else
			Begin
				set @sql='SELECT sProducts_Code ProductsCode,sProducts_Name ProductsName,sProducts_Description ProductsDescription, ISNULL(STK_MASTER_UOM.UOM_NAME,'' '') AS PURCHASEUOMNAME, '
				set @sql+='ISNULL(SALES_MASTER_UOM.UOM_NAME, '''') AS SALESUOMNAME,ISNULL(PRODUCTCLASS_NAME,'''') CLASSCODE,ISNULL(BRAND_NAME,'''') BRANDNAME '
				set @sql+=',case when  sProduct_Status=''A'' then ''Active'' else ''Dormant'' end STATUS ,CAST(isnull(sProduct_MRP,0) AS DECIMAL(18,2))MRP,CAST(isnull(sProducts_Discount,0)AS DECIMAL(18,2))DISCOUNT '
				set @sql+=',Color_Name COLOR,Size_Name SIZE,Gender_Name GENDER,sProduct_quantity PRODUCTQTY,MASTER_UOM_ProductUom.UOM_Name PRODUCTUOM,packing_quantity PACKINGQTY,MASTERpacking_saleUOM.UOM_Name PACKINGUOM '
				set @sql+='FROM Master_sProducts ' 
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.sProducts_DeliveryLotUnit = STK_MASTER_UOM.UOM_ID  '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID '
				set @sql+='LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE '
				set @sql+='LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductColor ON Mapping_ProductColor.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Color ON Master_Color.Color_ID=Mapping_ProductColor.Color_ID '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductSize ON Mapping_ProductSize.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Size ON Master_Size.Size_ID=Mapping_ProductSize.Size_ID '
				set @sql+='LEFT OUTER JOIN  Mapping_ProductGender ON Mapping_ProductGender.Products_ID=sProducts_ID '
				set @sql+='LEFT OUTER JOIN  Master_Gender ON Master_Gender.Gender_ID=Mapping_ProductGender.Gender_ID '
				set @sql+='LEFT OUTER JOIN tbl_master_product_packingDetails on packing_sProductId=sProducts_ID '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS MASTER_UOM_ProductUom ON DBO.tbl_master_product_packingDetails.sProduct_SaleUom = MASTER_UOM_ProductUom.UOM_ID  '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS MASTERpacking_saleUOM ON DBO.tbl_master_product_packingDetails.packing_saleUOM = MASTERpacking_saleUOM.UOM_ID  '
				--set @sql+='where (sProducts_Code like ''%'+@SearchKey+'%'') or (sProducts_Name like ''%'+@SearchKey+'%'')'
				--select  @sql
				EXEC SP_EXECUTESQL @sql
			End
		END	
		
	END
	Else IF(@ACTION='GetProductMasterHeaderCredentials')
	BEGIN		
		select * from OPENAPI_CONFIG where MODULE_NAME='PRODUCT MASTER' and  GUID='01360645-267C-4690-ABC5-A3D66B300B87'	
	END
	Else IF(@ACTION='InsertProductDetails')
	BEGIN		
		BEGIN TRAN
		BEGIN TRY
			DECLARE	CurProduct CURSOR FOR 
			select 
			XMLproduct.value('(ProductCode/text())[1]','nvarchar(300)'),XMLproduct.value('(ProductName/text())[1]','nvarchar(300)'),XMLproduct.value('(Description/text())[1]','nvarchar(500)')
			,XMLproduct.value('(SalesUnit/text())[1]','nvarchar(500)'),XMLproduct.value('(PurchaseUnit/text())[1]','nvarchar(500)')	,XMLproduct.value('(MRP/text())[1]','decimal(18,2)')
			,XMLproduct.value('(Discount/text())[1]','nvarchar(100)')				
			from @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct) 
			OPEN CurProduct
			FETCH NEXT FROM CurProduct INTO @ProductCode,@ProductName,@Description,@SalesUnit,@PurchaseUnit,@MRP,@Discount
			WHILE @@FETCH_STATUS=0
			BEGIN

			select @SalesUnitID=UOM_ID from Master_UOM where UOM_Name=@SalesUnit
			select @PurchaseUnitID=UOM_ID from Master_UOM where UOM_Name=@PurchaseUnit
		
			if Not exists (select 'Y' from Master_sProducts where sProducts_Code=@ProductCode)
			Begin
				insert into Master_sProducts(sProducts_Code,sProducts_Name,sProducts_Description,sProducts_TradingLot,sProducts_TradingLotUnit,sProducts_QuoteCurrency,
				sProducts_QuoteLot,sProducts_QuoteLotUnit,sProducts_DeliveryLot,sProducts_DeliveryLotUnit,sProducts_CreateUser,sProducts_CreateTime,sProduct_IsInventory,sProduct_Status
				,sProduct_NegativeStock,sProduct_MRP,sProducts_Discount
				)
				select  @ProductCode,@ProductName,@Description,1,@SalesUnitID,1,1,@SalesUnitID,1,@PurchaseUnitID,@user_id,GETDATE(),1,'A','W',@MRP,@Discount

			end
			FETCH NEXT FROM CurProduct INTO @ProductCode,@ProductName,@Description,@SalesUnit,@PurchaseUnit,@MRP,@Discount
			END
			CLOSE CurProduct
			DEALLOCATE CurProduct	

			SELECT 'Success' AS STRMESSAGE

		
		COMMIT TRAN
		END TRY
		BEGIN CATCH
		ROLLBACK TRAN
		SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage
		END CATCH
	END


	SET NOCOUNT OFF


END	