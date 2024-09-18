--EXEC PRC_APIOfflineProductRate @user_id=11984

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIOfflineProductRate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIOfflineProductRate] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIOfflineProductRate]
(
@user_id BIGINT=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		TANMOY			28-05-2020		CREATE SP FRO OFFLINE PRODUCT RATE
2.0		TANMOY			02-06-2020		STATE_ID GET FROM USER OFFICE ADDRESS
3.0		DEBASHIS		04-08-2023		ProductList/OfflineProductRate api response not coming.Now Products have been filtered on State.
										Refer: 0026668
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @DATE DATETIME=(CAST(CONVERT(VARCHAR(16),GETDATE(), 120) AS DATETIME))
	
	DECLARE @isStockShow BIT
	DECLARE @isRateShow BIT=1
	DECLARE @SHOP_STATE NVARCHAR(500)
	DECLARE @shop_id NVARCHAR(100)
	declare @SHOP_TYPE nvarchar(250)

	--REV 2.0 START
	--SET @SHOP_STATE=(SELECT TOP(1)STAT.id FROM tbl_FTS_userhomeaddress HOME INNER JOIN tbl_master_state STAT ON STAT.state=HOME.State where HOME.UserID=@user_id )

	SET @SHOP_STATE=(select TOP(1)adds.add_state from tbl_master_address adds 
					INNER JOIN tbl_master_user USR ON USR.user_contactId=adds.add_cntId 
					where adds.add_addressType='Office' AND USR.user_id=@user_id)
	--REV 2.0 END

	SET @shop_id=(select top(1)Shop_Code from tbl_master_shop where stateId=@SHOP_STATE and type=4 and Shop_CreateUser=@user_id)
	
	IF(SELECT type FROM tbl_Master_shop WHERE Shop_Code=@shop_id)=4
	SET @isStockShow=1
	ELSE
	SET @isStockShow=0
	--Rev 3.0
	SELECT * INTO #TMPPRODMAST FROM Master_sProducts WHERE EXISTS(SELECT PRODUCT_ID FROM FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE
	WHERE sProducts_ID=PRODUCT_ID AND STATE_ID=@SHOP_STATE)

	CREATE NONCLUSTERED INDEX IX1 ON #TMPPRODMAST(sProducts_ID)
	--End of Rev 3.0

	SELECT CONVERT(NVARCHAR(30),sProducts_ID) AS product_id,sProducts_Name,
	CONVERT(NVARCHAR(30),DBO.GET_MINSALESPRICEENTITYWISEOFFLINE('1',@SHOP_STATE,sProducts_ID)) as rate1,
	'0' AS rate2,'0' AS rate3,
	CONVERT(NVARCHAR(30),DBO.GET_MINSALESPRICEENTITYWISEOFFLINE('4',@SHOP_STATE,sProducts_ID)) as rate4,
	'0' AS rate5,
	CONVERT(NVARCHAR(30),dbo.GET_STOCKPRODUCTWISE(@shop_id,sProducts_ID,@DATE)) as stock_amount
	,UOM.UOM_Name as stock_unit,	
	@isStockShow AS isStockShow,@isRateShow AS isRateShow
	--Rev 3.0
	--FROM Master_sProducts PROD
	FROM #TMPPRODMAST PROD
	--End of Rev 3.0
	--LEFT OUTER JOIN Master_ProductClass CLS ON CLS.ProductClass_ID=PROD.ProductClass_Code
	LEFT OUTER JOIN Master_UOM UOM ON UOM.UOM_ID=PROD.sProducts_TradingLotUnit
	
	--select * from Master_UOM where UOM_Name='bag'
	--Rev 3.0
	DROP TABLE #TMPPRODMAST
	--End of Rev 3.0

	SET NOCOUNT OFF
END
GO