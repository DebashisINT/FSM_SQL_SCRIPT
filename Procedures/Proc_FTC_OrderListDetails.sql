IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTC_OrderListDetails]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTC_OrderListDetails] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_FTC_OrderListDetails]
(
@shop_id varchar(60)=NULL,
@user_id varchar(60)=NULL,
@order_id varchar(60)=NULL
) --WITH ENCRYPTION
AS
BEGIN

select  OrderCode as order_id,convert(varchar(50),isnull(count(OrderId),0)) as total_orderlist_count  from  tbl_trans_fts_Orderupdate ordr where Shop_Code=@shop_id group by OrderCode


select  OrderId as order_id,Shop_Code as shop_id, OrderCode  as id,convert(varchar(100),Ordervalue ) as amount,Order_Description as description,
convert(varchar(50),cast(Orderdate  as date)) as date 
,cast(ordr.Collectionvalue as varchar(100)) as collection

from  tbl_trans_fts_Orderupdate ordr 
where  userID=@user_id  and Shop_Code=@shop_id
 
order  by OrderId  desc


select  masprod.sProducts_ID as id,masprod.sProducts_Brand as   brand_id,masprod.ProductClass_Code as category_id,masprod.sProducts_Size as watt_id   
,brnd.Brand_Name as brand
,cls.ProductClass_Name as category
,msize.Size_Name as watt
,masprod.sProducts_Name as product_name
,ordrprod.Order_ID 
,ordrprod.Product_Qty as qty
,ordrprod.Product_Price as total_price
,ordrprod.Product_Rate as rate
from  tbl_FTs_OrderdetailsProduct ordrprod 
INNER JOIN   Master_sProducts as masprod on ordrprod.Product_Id= masprod.sProducts_ID
INNER JOIN tbl_master_brand brnd on masprod.sProducts_Brand=brnd.Brand_Id 
INNER JOIN Master_ProductClass as cls on masprod.ProductClass_Code=cls.ProductClass_ID
INNER JOIN Master_Size as msize on masprod.sProducts_Size=msize.Size_ID
where  User_Id=@user_id  and Shop_Code=@shop_id
order  by masprod.sProducts_Name  


END
