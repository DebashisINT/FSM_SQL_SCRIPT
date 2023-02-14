
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_OrderProductManage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_OrderProductManage] AS' 
END
GO
ALTER Proc [dbo].[Proc_FTS_OrderProductManage]
@OrderID int,
@Action varchar(100)=NULL,
@Prod_ID int=NULL,
@Prod_Qty decimal(18,2)=NULL,
@Prod_Rate decimal(18,2)=NULL,
@OrderProd_Id int=NULL,
@Prod_Mrp decimal(18,2)=NULL,
@Prod_Discount decimal(18,2)=NULL
As
/*********************************************************************************************************************************************
1.0	    v2.0.39		PRITI 	    07/02/2023		0025604:Enhancement Required in the Order Summary Report
*******************************************************************************************************************************************/

Begin
If(@Action='Delete')
BEGIN


delete  from tbl_FTs_OrderdetailsProduct where Order_ID=@OrderID and   Order_ProdId=@OrderProd_Id
if(@@ROWCOUNT>0)
BEGIN


update  a set a.Ordervalue=b.total from tbl_trans_fts_Orderupdate as a
inner join
(select  sum(Product_Price) as total ,Order_ID from tbl_FTs_OrderdetailsProduct where Order_ID=@OrderID group by Order_ID)b on a.OrderId=b.Order_ID 
where   OrderId=@OrderID
END
END

Else If(@Action='Update')
BEGIN

Update tbl_FTs_OrderdetailsProduct set Product_Qty=@Prod_Qty,Product_Rate=@Prod_Rate,Product_Price=@Prod_Qty*@Prod_Rate 
--Rev 1.0
,ORDER_MRP=@Prod_Mrp,ORDER_DISCOUNT=@Prod_Discount
--Rev 1.0 End
where Order_ID=@OrderID and  Order_ProdId=@OrderProd_Id
if(@@ROWCOUNT>0)
BEGIN


update  a set a.Ordervalue=b.total from tbl_trans_fts_Orderupdate as a
inner join
(select  sum(Product_Price) as total ,Order_ID from tbl_FTs_OrderdetailsProduct where Order_ID=@OrderID group by Order_ID)b on a.OrderId=b.Order_ID 
where   OrderId=@OrderID
END

END

Else If(@Action='Edit')
BEGIN

select  Product_Qty,Product_Rate ,Product_Price,Product_Id,Order_ProdId,Order_ID
---Rev 1.0
,ORDER_MRP Product_MRP,ORDER_DISCOUNT Product_Discount 
---Rev 1.0 End
from tbl_FTs_OrderdetailsProduct where Order_ID=@OrderID and Order_ProdId=@OrderProd_Id

END
--Rev 1.0
Else If(@Action='ProductIdWiseMrpDiscount')
BEGIN
	select sProduct_MRP,sProducts_Discount from Master_sProducts where sProducts_ID=@Prod_ID
END
--Rev 1.0 End
End
