IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIDASHBOARDANALYTICS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIDASHBOARDANALYTICS] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIDASHBOARDANALYTICS]
(
@ACTION NVARCHAR(50),
@USERID BIGINT,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 24/04/2023
Module	   : API Dashboard Analytics
1.0		v2.0.39		Debashis	17/05/2023		using this api party not visited list return required.Refer: 0026150
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='PARTYNOTVISITLIST'
		BEGIN
			SELECT USER_ID,shop_name,shop_id,shop_Type,shop_TypeName,last_visited_date,last_order_date FROM(
			SELECT ORDHEAD.userID AS USER_ID,SHOP.Shop_Name AS shop_name,SHOP.Shop_Code AS shop_id,SHOP.type AS shop_Type,SHOPTYPE.Name AS shop_TypeName,
			MAX(CONVERT(NVARCHAR(10),SHOP.Lastvisit_date,120)) AS last_visited_date,MAX(CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120)) AS last_order_date
			FROM tbl_Master_shop AS SHOP
			INNER JOIN tbl_shoptype SHOPTYPE ON SHOP.TYPE=SHOPTYPE.shop_typeId
			INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code
			GROUP BY ORDHEAD.userID,SHOP.Shop_Name,SHOP.Shop_Code,SHOP.type,SHOPTYPE.Name
			) SHPVISIT
			WHERE SHPVISIT.USER_ID=@USERID
			--Rev 1.0
			--AND SHPVISIT.last_visited_date BETWEEN @FROMDATE AND @TODATE
			AND SHPVISIT.last_visited_date NOT BETWEEN @FROMDATE AND @TODATE
			--End of Rev 1.0
		END

	SET NOCOUNT OFF
END