
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_sProductDetailsById]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_sProductDetailsById] AS' 
END
GO



ALTER PROCEDURE [dbo].[Sp_sProductDetailsById]   
 @ProductId int  
AS 
/*************************************************************************************************
Written By : Jitendra on 10/01/2018
1.0		Jitendra			v1.0.70			11/01/2018		New field added 'Is_ServiceItem'
2.0		Indranil			v1.0.74			10-05-2018		Lite popup added for main account
3.0		Arindam				V1.0.078		11/07/2018		New field added 'Reorder_Quantity' and select
4.0		Sanchita			v2.0.26			07/09/2021		Gender, Size, Colour drop down multi selection field required under Product Attribute in Product Master in FSM
															Refer: 24299
5.0		Sanchita			v2.0.37			02-12-2022		MRP' and Discount' entering facility required in Product Master. Refer: 25469, 25470
6.0		Sanchita			V2.0.43			06-11-2023		On demand search is required in Product Master & Projection Entry. Mantis: 26858
***************************************************************************************************/ 
BEGIN  
 SELECT sProducts_ID  
     ,sProducts_Code  
     ,sProducts_Name  
     ,sProducts_Description  
     ,sProducts_Type   
     ,CASE WHEN sProducts_Type ='A' THEN 'Raw Material'   
     WHEN  sProducts_Type ='B' THEN 'Work-In-Process'    
     WHEN  sProducts_Type ='C' THEN 'Finished Goods' END AS sProducts_TypeFull  
     ,ProductClass_Code  
     ,sProducts_GlobalCode  
     ,sProducts_TradingLot  
     ,sProducts_TradingLotUnit  
     ,sProducts_QuoteCurrency  
           ,sProducts_QuoteLot,sProducts_QuoteLotUnit  
     ,sProducts_DeliveryLot  
     ,sProducts_DeliveryLotUnit  
           ,sProducts_Color,sProducts_Size  
     ,sProducts_CreateUser  
     ,sProducts_CreateTime  
     ,sProducts_ModifyUser  
     ,sProducts_ModifyTime  
     ,sProducts_SizeApplicable  
     ,sProducts_ColorApplicable  
     ,sProducts_barCodeType  
     ,sProducts_barCode  
     ,sProduct_IsInventory  
     ,sProduct_Stockvaluation  
     ,sProduct_SalePrice  
     ,sProduct_MinSalePrice  
     ,sProduct_PurPrice  
     ,sProduct_MRP  
     ,sProduct_StockUOM  
     ,sProduct_MinLvl  
     ,sProduct_reOrderLvl  
     ,sProduct_NegativeStock  
     ,sProduct_TaxSchemeSale  
     ,sProduct_TaxSchemePur  
     ,sProduct_TaxScheme  
     ,sProduct_AutoApply  
     ,sProduct_ImagePath  
     , Rtrim(STUFF((SELECT ',' + Convert(varchar,Component_prodId,500) FROM tbl_master_ProdComponent WHERE Product_id =@ProductId FOR XML PATH ('')),1,1,'')) as 'ProductComponent'  
     ,sProduct_Status
     ,sProducts_HsnCode
     ,sProducts_serviceTax
  ,isnull((select sProduct_quantity from tbl_master_product_packingDetails where packing_sProductId=@ProductId),0)sProduct_quantity
    ,isnull((select packing_quantity from tbl_master_product_packingDetails where packing_sProductId=@ProductId),0)packing_quantity
     ,isnull((select packing_saleUOM from tbl_master_product_packingDetails where packing_sProductId=@ProductId),0)packing_saleUOM
     ,sProducts_isInstall,sProducts_Brand,sProduct_IsCapitalGoods
     --,ISNULL((select TDSTCS_ID from tbl_master_productTdsMap where sProducts_ID=@ProductId),0)TDSTCS_ID
     ,isnull(sProducts_IsOldUnit,0)sProducts_IsOldUnit,
     sInv_MainAccount,
	sRet_MainAccount,
	pInv_MainAccount,
	pRet_MainAccount,
	Reorder_Quantity,
	FurtheranceToBusiness,Is_ServiceItem
	,MASI.MainAccount_Name sInv_MainAccount_Name --2.0
	,MASR.MainAccount_Name sRet_MainAccount_Name --2.0
	,MAPI.MainAccount_Name pInv_MainAccount_Name --2.0
	,MAPR.MainAccount_Name pRet_MainAccount_Name --2.0
	,case when exists(select 1 from Trans_AccountsLedger where AccountsLedger_MainAccountID=MASI.MainAccount_AccountCode) then 1 else 0 end MasiExists --2.0
	,case when exists(select 1 from Trans_AccountsLedger where AccountsLedger_MainAccountID=MASR.MainAccount_AccountCode) then 1 else 0 end MASRExists --2.0
	,case when exists(select 1 from Trans_AccountsLedger where AccountsLedger_MainAccountID=MAPI.MainAccount_AccountCode) then 1 else 0 end MAPIExists --2.0
	,case when exists(select 1 from Trans_AccountsLedger where AccountsLedger_MainAccountID=MAPR.MainAccount_AccountCode) then 1 else 0 end MAPRExists --2.0
	-- Rev 4.0
	,STUFF((SELECT ',' + CONVERT(NVARCHAR(10),t1.Color_ID) FROM Mapping_ProductColor t1 WHERE t1.Products_ID=@ProductId
              FOR XML PATH ('')) , 1, 1, '') as ColorNew

	,STUFF((SELECT ',' + CONVERT(NVARCHAR(10),t2.Size_ID) FROM Mapping_ProductSize t2 WHERE t2.Products_ID=@ProductId
              FOR XML PATH ('')) , 1, 1, '') as SizeNew

	,STUFF((SELECT ',' + CONVERT(NVARCHAR(10),t3.Gender_ID) FROM Mapping_ProductGender t3 WHERE t3.Products_ID=@ProductId
              FOR XML PATH ('')) , 1, 1, '') as GenderNew
	

	--,isnull(PC.Color_ID,0) AS ColorNew,isnull(PS.Size_ID,0) AS SizeNew , isnull(PG.Gender_ID,0) AS GenderNew 
	-- End of Rev 4.0
	-- Rev 5.0
	, sProducts_Discount 
	-- End of Rev 5.0
	-- Rev 6.0
	,STUFF((SELECT ',' + CONVERT(NVARCHAR(10),MC.Color_Name) FROM Mapping_ProductColor t1 inner join Master_Color MC on T1.Color_ID=MC.Color_ID
		WHERE t1.Products_ID=@ProductId
              FOR XML PATH ('')) , 1, 1, '') as ColorNew_Desc
	, BR.Brand_Name as Brand_Desc
	-- End of Rev 6.0
 FROM dbo.Master_sProducts  
 LEFT JOIN Master_MainAccount MASI ON MASI.MainAccount_AccountCode=sInv_MainAccount
 LEFT JOIN Master_MainAccount MASR ON MASR.MainAccount_AccountCode=sRet_MainAccount
 LEFT JOIN Master_MainAccount MAPI ON MAPI.MainAccount_AccountCode=pInv_MainAccount
 LEFT JOIN Master_MainAccount MAPR ON MAPR.MainAccount_AccountCode=pRet_MainAccount
 -- Rev 4.0
 LEFT JOIN  Mapping_ProductGender PG on Master_sProducts.sProducts_ID = PG.Products_ID
 LEFT JOIN  Mapping_ProductColor PC on Master_sProducts.sProducts_ID = PC.Products_ID
 LEFT JOIN  Mapping_ProductSize PS on Master_sProducts.sProducts_ID = PS.Products_ID
 -- End of Rev 4.0
 -- Rev 6.0
 LEFT OUTER JOIN tbl_master_brand BR ON Master_sProducts.sProducts_Brand=BR.Brand_Id
 -- End of Rev 6.0

 WHERE sProducts_ID = @ProductId 
END
GO