--EXEC PRC_APIPRODUCTRATE @user_id=11984,@shop_id='11706_1655632679764'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIPRODUCTRATE]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIPRODUCTRATE] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIPRODUCTRATE]
(
@user_id BIGINT=NULL,
@shop_id NVARCHAR(100)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0					TANMOY			27-12-2019		CREATE SP FRO PRODUCT RATE
2.0					TANMOY			14-02-2020		SHOW PRODUCT STOCK WAREHOUSE WISE  AND PRODUCT UNIT
3.0					TANMOY			25-02-2020		add two seetings isStockShow,isRateShow
4.0		v2.0.41		DEBASHIS		08-08-2023		Api response not coming.Now Products have been filtered on State.
													Refer: 0026694
5.0		v2.0.41		DEBASHIS		21-08-2023		Some new columns have been added.Row: 865
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @DATE DATETIME=(CAST(CONVERT(VARCHAR(16),GETDATE(), 120) AS DATETIME))
	--Rev 3.0 Start
	DECLARE @isStockShow BIT
	DECLARE @isRateShow BIT=1
	--Rev 4.0
	DECLARE @SHOP_STATE INT
	--End of Rev 4.0
	--Rev 3.0 End
	--SELECT CONVERT(NVARCHAR(30),ProductID) AS product_id,CONVERT(NVARCHAR(30),DiscSalesPrice) AS rate,FixedRate,MinSalePrice,Disc ,CustomerID
	--FROM FTS_trans_SaleRateLock WHERE  ValidFrom <=@DATE AND ValidUpto>=@DATE
	--AND CustomerID=@shop_id

	--DECLARE @SHOP_ID VARCHAR(50)='2098_1577976445785'

	--Rev 3.0 Start
	IF(SELECT type FROM tbl_Master_shop WHERE Shop_Code=@shop_id)=4
	SET @isStockShow=1
	ELSE
	SET @isStockShow=0
	--Rev 3.0 End

	--Rev 4.0
	SET @SHOP_STATE=(SELECT TOP(1)adds.add_state FROM tbl_master_address adds 
					INNER JOIN tbl_master_user USR ON USR.user_contactId=adds.add_cntId 
					WHERE adds.add_addressType='Office' AND USR.user_id=@user_id)
	
	SELECT * INTO #TMPSPLPRODMAST FROM Master_sProducts WHERE EXISTS(SELECT PRODUCT_ID FROM FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE
	WHERE sProducts_ID=PRODUCT_ID AND STATE_ID=@SHOP_STATE)
	--End of Rev 4.0

	SELECT CONVERT(NVARCHAR(30),sProducts_ID) AS product_id,sProducts_Name,
	CONVERT(NVARCHAR(30),DBO.GET_MINSALESPRICEENTITYWISE(@shop_id,sProducts_ID,@DATE)) AS rate,
	CONVERT(NVARCHAR(30),dbo.GET_STOCKPRODUCTWISE(@shop_id,sProducts_ID,@DATE)) AS stock_amount
	,UOM.UOM_Name as stock_unit,
	--Rev 3.0 Start
	@isStockShow AS isStockShow,@isRateShow AS isRateShow, 
	--Rev 3.0 End
	--Rev 5.0
	SPLRATE.QTY_UNIT_DISTRIBUTOR AS Qty_per_Unit,SPLRATE.SCHEME_QTY_DISTRIBUTOR AS Scheme_Qty,SPLRATE.EFFECTIVE_PRICE AS Effective_Rate
	--End of Rev 5.0
	--Rev 4.0
	--FROM Master_sProducts PROD
	FROM #TMPSPLPRODMAST PROD
	--End of Rev 4.0
	--LEFT OUTER JOIN Master_ProductClass CLS ON CLS.ProductClass_ID=PROD.ProductClass_Code
	LEFT OUTER JOIN Master_UOM UOM ON UOM.UOM_ID=PROD.sProducts_TradingLotUnit
	--Rev 5.0
	LEFT OUTER JOIN FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE SPLRATE ON PROD.sProducts_ID=SPLRATE.PRODUCT_ID AND SPLRATE.STATE_ID=@SHOP_STATE
	--End of Rev 5.0
	--select * from Master_UOM where UOM_Name='bag'
	--Rev 4.0
	DROP TABLE #TMPSPLPRODMAST
	--End of Rev 4.0

	SET NOCOUNT OFF
END