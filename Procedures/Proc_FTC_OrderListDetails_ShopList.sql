--EXEC [Proc_FTC_OrderListDetails_ShopList] 11986,''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTC_OrderListDetails_ShopList]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTC_OrderListDetails_ShopList] AS'  
 END 
 GO 
 
ALTER PROCEDURE [dbo].[Proc_FTC_OrderListDetails_ShopList]
(
@user_id varchar(60)=NULL,
@Date varchar(60)=NULL
) --WITH ENCRYPTION
AS
/********************************************************************************************************************************************
1.0					Tanmoy      18-11-2019      change Order_ProdId as id and sProducts_ID as PRODID
2.0		v2.0.26		Debashis	29-12-2021		Enhancement done for Row No. 598
3.0		v2.0.26		Debashis	10-01-2022		Enhancement done for Row No. 608
4.0		v2.0.38		Debashis	23-01-2023		Enhancement done for Row No. 806
5.0		v2.0.43		Debashis	03-01-2023		Product not showing Under Order.Now solved.Refer: 0027148
********************************************************************************************************************************************/
BEGIN

	DECLARE @SQL NVARCHAR(MAX)

	SET @SQL='select  OrderCode as order_id,convert(varchar(50),isnull(count(OrderId),0)) as total_orderlist_count  from 
	 tbl_trans_fts_Orderupdate ordr
			group by OrderCode,userID,ORDERDATE
			having userID='+@user_id+' ' 
 
	if(ISNULL(@Date,'')<>'')
			SET @SQL +=' and  CONVERT(NVARCHAR(10),ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@Date+''',120) AND CONVERT(NVARCHAR(10),'''+@Date+''',120)'

	EXEC SP_EXECUTESQL @SQL

	--Rev 2.0 && A new column Scheme_Amount have been added.
	--Rev 3.0 &&Two new columns added as HOSPITAL & EMAIL_ADDRESS
	SET @SQL='
		select SHOP.Shop_Code as SHOPID,SHOP.Shop_Name as NAME, SHOP.SHOP_OWNER_CONTACT AS CONTACT,SHOP.Address as ADDRESS,
		SHOP.Pincode as PINCODE,SHOP.Shop_Lat as LATITUDE,SHOP.Shop_Long as LONGITUDE,
		ORDHEAD.ORDERDATE ORDDATE,ORDHEAD.OrderId AS ORDID,ORDHEAD.ORDERCODE AS ORDRNO
		,isnull(ORDHEAD.Ordervalue,0) as order_amount,Latitude,Longitude
		,isnull(PATIENT_PHONE_NO,'''') as PATIENT_PHONE_NO,isnull(PATIENT_NAME,'''') as PATIENT_NAME,isnull(PATIENT_ADDRESS,'''') as PATIENT_ADDRESS,
		ISNULL(ORDHEAD.Scheme_Amount,0) AS scheme_amount,ORDHEAD.HOSPITAL AS Hospital,ORDHEAD.EMAIL_ADDRESS AS Email_Address
		FROM tbl_Master_shop AS SHOP
		INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code
		where ORDHEAD.userID='+@user_id+''

	if(ISNULL(@Date,'')<>'')
		SET @SQL +='
		and  CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@Date+''',120) AND CONVERT(NVARCHAR(10),'''+@Date+''',120)'
		SET @SQL +='ORDER BY ORDHEAD.ORDERDATE'

	EXEC SP_EXECUTESQL @SQL


	--Rev 2.0 && Three new columns Scheme_Qty,Scheme_Rate & Total_Scheme_Price has been added.
	--Rev 3.0 && A new column added as MRP
	--Rev 4.0 && Two new columns added as order_mrp & order_discount
		SET @SQL=''
		--Rev 1.0 Start
		SET @SQL+='SELECT  ORDHEAD.Shop_Code as SHOPID,Order_ProdId as id, '
		--Rev 5.0
		--SET @SQL+='PROD.sProducts_ID as PRODID,PROD.sProducts_Brand as   brand_id,PROD.ProductClass_Code as category_id,PROD.sProducts_Size as watt_id   '
		SET @SQL+='PROD.sProducts_ID as PRODID,PROD.sProducts_Brand as   brand_id,PROD.ProductClass_Code as category_id,ISNULL(PROD.sProducts_Size,0) as watt_id   '
		--End of Rev 5.0
		--Rev 1.0 End
		SET @SQL+=',brnd.Brand_Name as brand  '
		SET @SQL+=',cls.ProductClass_Name as category   '
		SET @SQL+=',msize.Size_Name as watt   '
		SET @SQL+=',PROD.sProducts_Name as product_name  '
		SET @SQL+=',ORDDET.Order_ID   '
		SET @SQL+=',ORDDET.Product_Qty as qty  '
		SET @SQL+=',ORDDET.Product_Price as total_price  '
		SET @SQL+=',ORDDET.Product_Rate as rate,'
		SET @SQL+='ISNULL(ORDDET.Scheme_Qty,0.00) AS scheme_qty,ISNULL(ORDDET.Scheme_Rate,0.00) AS scheme_rate,ISNULL(ORDDET.Total_Scheme_Price,0.00) AS total_scheme_price,ISNULL(ORDDET.MRP,0.00) AS MRP,'
		SET @SQL+='ISNULL(ORDDET.ORDER_MRP,0.00) AS order_mrp,ISNULL(ORDDET.ORDER_DISCOUNT,0.00) AS order_discount '
		SET @SQL+='FROM tbl_trans_fts_Orderupdate as ORDHEAD	'
		SET @SQL+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID	'
		SET @SQL+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.Product_Id	'
		SET @SQL+='INNER JOIN tbl_master_brand brnd on PROD.sProducts_Brand=brnd.Brand_Id	'
		SET @SQL+='INNER JOIN Master_ProductClass as cls on PROD.ProductClass_Code=cls.ProductClass_ID	'
		--Rev 5.0
		--SET @SQL+='INNER JOIN Master_Size as msize on PROD.sProducts_Size=msize.Size_ID	'
		SET @SQL+='LEFT OUTER JOIN Master_Size as msize on PROD.sProducts_Size=msize.Size_ID	'
		--End of Rev 5.0
		SET @SQL+='where  User_Id='+@user_id+' '
	if(ISNULL(@Date,'')<>'')
		SET @SQL +='
		and  CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@Date+''',120) AND CONVERT(NVARCHAR(10),'''+@Date+''',120)'
		SET @SQL +='  order  by PROD.sProducts_Name  '

	EXEC SP_EXECUTESQL @SQL


END
GO