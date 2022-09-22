IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[proc_FTS_ShopTypeData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [proc_FTS_ShopTypeData] AS' 
END
GO

ALTER  Proc [proc_FTS_ShopTypeData]
@Action varchar(50)=NULL,
@User_id  varchar(50)=NULL
AS
/****************************************************************************************************************************************************************************
-- 1.0	Swatilekha	15/06/2022  Mantise Issue 0024948: Show All checkbox required for Shops report
-- 2.0	Sanchita	22-09-2022	V2.0.33		Show All option is not showing in the Shops Report. Refer: 25230
****************************************************************************************************************************************************************************/
BEGIN
	-- Rev 2.0
	--SELECT  Name, SHOP_TYPEID as ID,CAST(1 AS BIT) as IsChecked  FROM SHOPTYPEDATA WHERE SHOP_TYPEID IN  (2,4)
	--UNION ALL	
	--SELECT  Name, SHOP_TYPEID as ID,CAST(0 AS BIT) as IsChecked  FROM SHOPTYPEDATA WHERE SHOP_TYPEID IN (3,1,5)
	SELECT  Name, SHOP_TYPEID as ID,CAST(1 AS BIT) as IsChecked  FROM SHOPTYPEDATA WHERE [Name] IN  ('Prime Partner','Distributor')
	UNION ALL	
	SELECT  Name, SHOP_TYPEID as ID,CAST(0 AS BIT) as IsChecked  FROM SHOPTYPEDATA WHERE [Name] IN ('New Party','Shop','Show All')
	-- End of Rev 2.0
END
GO
