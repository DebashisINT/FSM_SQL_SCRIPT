IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_OrderSummaryDetailsBind]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_OrderSummaryDetailsBind] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_FTS_OrderSummaryDetailsBind]
(
@OrderID INT
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.26		Debashis	24/01/2022		Paitent Details has been added.Refer: 0024580
2.0	    v2.0.39		PRITI 	    07/02/2023		0025604:Enhancement Required in the Order Summary Report

****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	--Rev 1.0 && A new field MRP has been added
	select Order_ProdId,Product_Id,Product_Qty,Product_Rate,Product_Price,ordprod.Shop_code,shp.Shop_Name,mprod.sProducts_Name,Order_ID,MRP
	--Rev 2.0	
	,ORDER_MRP Product_MRP,ORDER_DISCOUNT Product_Discount
	--Rev 2.0	End
	from tbl_FTs_OrderdetailsProduct as ordprod
	inner join Master_sProducts as mprod on ordprod.Product_Id=mprod.sProducts_ID
	inner join tbl_Master_shop as shp on shp.Shop_Code=ordprod.Shop_code
	where Order_ID=@OrderID

	SET NOCOUNT OFF
END