--EXEC [proc_FTS_CollectionList] @user_id=11713,@Action='AllCollection'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[proc_FTS_CollectionList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [proc_FTS_CollectionList] AS' 
END
GO

ALTER PROCEDURE [dbo].[proc_FTS_CollectionList]
(
@user_id varchar(100)=NULL,
@shop_id varchar(100)=NULL,
@collection varchar(100)=NULL,
@collection_id varchar(100)=NULL,
@collection_date varchar(100)=NULL,
@weburl varchar(100)=NULL,
@Action varchar(100)=NULL,
@url NVARCHAR(MAX)=''
) --WITH ENCRYPTION
AS
/************************************************************************************************
1.0					Tanmoy		30-11-2020		ADD NEW COLUMN for @Action='AllCollection'
2.0					Debashis	20-09-2021		@Action='AllCollection' has been rectified.
3.0		v2.0.26		Debashis	10-01-2022		Enhancement done for Row No. 605
*************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @SQL NVARCHAR(MAX)
	IF(ISNULL(@Action,'')='' )
		BEGIN
			SET @SQL='SELECT ISNULL(COUNT(collection_id),0) AS countcollection FROM tbl_FTS_collection where shop_id='''+@shop_id+''' and user_id='+@user_id+' '
			IF(ISNULL(@collection_date,'')<>'')
				SET @SQL+='AND CAST(collection_date as date)='''+@collection_date+''' '
			EXEC sp_ExecuteSQL @SQL

			SET @SQL='SELECT collection_id,user_id,shop_id,collection,
			CONVERT(VARCHAR(60),CAST(collection_date AS DATE)) AS collection_date FROM tbl_FTS_collection where shop_id='''+@shop_id+''' and user_id='+@user_id+' '
			IF(ISNULL(@collection_date,'')<>'')
				SET @SQL+=' and cast(collection_date as date)='''+@collection_date+''' '
			EXEC sp_ExecuteSQL @SQL
		END
	ELSE if(isnull(@Action,'')='AllCollection' )
		BEGIN
		SET @SQL='SELECT ISNULL(COUNT(collection_id),0) AS countcollection FROM tbl_FTS_collection where user_id='+@user_id+' '
		IF(ISNULL(@collection_date,'')<>'')
			SET @SQL+='AND CAST(collection_date as date)='''+@collection_date+''''
		EXEC sp_ExecuteSQL @SQL
		--Rev 2.0
		--SET  @SQL='
		--Select  coll.collection_id,
		--coll.user_id,
		--coll.shop_id,
		--coll.collection,
		--shp.Shop_Name as shop_name,
		--shp.Address as address ,
		--shp.Pincode as pin_code ,
		--Shop_Lat as  shop_lat ,
		--Shop_Long as shop_long,
		----convert(varchar(60),cast(coll.collection_date  as date))  as collection_date
		--coll.collection_date '

		----Rev 1.0 Start
		--SET @SQL+=',coll.Payment_id as payment_id,coll.Instrument_No as instrument_no,coll.Bank as bank,coll.Remarks as remarks,'''+ISNULL(@url,'''')+'''+coll.DocumentName as doc '
		--SET @SQL+=',INV.INVOICE_NUMBER as bill_id,INV.ORDER_NUMBER as order_id 	 '
		----Rev 1.0 End
		----Rev 2.0 Start
		--SET @SQL+=',isnull(coll.PATIENT_PHONE_NO,'''') as patient_no,isnull(coll.PATIENT_NAME,'''') as patient_name,isnull(coll.PATIENT_ADDRESS,'''') as patient_address '
		----Rev 2.0 End
		-- SET @SQL+=' from tbl_FTS_collection as coll
		--inner join tbl_Master_shop as shp on   coll.shop_id=shp.Shop_Code 
		--LEFT OUTER JOIN tbl_FTS_collection_invoicewise INV ON coll.collection_id=INV.collection_id

		--where coll.user_id='+@user_id+''
		-- if(isnull(@collection_date,'')<>'')
		--SET @SQL+=' and cast(coll.collection_date as date)='''+@collection_date+''''

		--Exec sp_ExecuteSQL @SQL
		--Rev 3.0 &&Two new columns added as HOSPITAL & EMAIL_ADDRESS
		SET @SQL='SELECT coll.user_id,coll.shop_id,coll.collection,REPLACE(CONVERT(NVARCHAR(11),coll.collection_date,106),'' '',''-'') AS date,CONVERT(NVARCHAR(8),coll.collection_date,108) AS only_time,'
		SET @SQL+='coll.collection_id,shp.Shop_Name AS shop_name,shp.Address AS address,shp.Pincode AS pin_code,shp.Shop_Lat AS shop_lat,shp.Shop_Long AS shop_long,ISNULL(coll.Payment_id,'''') AS payment_id,'
		SET @SQL+='ISNULL(coll.Instrument_No,'''') AS instrument_no,ISNULL(coll.Bank,'''') AS bank,ISNULL(coll.Remarks,'''') AS feedback,'''+ISNULL(@url,'''')+'''+ISNULL(coll.DocumentName,'''') AS file_path,'
		SET @SQL+='ISNULL(INV.INVOICE_NUMBER,'''') AS bill_id,ISNULL(INV.ORDER_NUMBER,'''') AS order_id,ISNULL(coll.PATIENT_PHONE_NO,'''') AS patient_no,ISNULL(coll.PATIENT_NAME,'''') AS patient_name,'
		SET @SQL+='ISNULL(coll.PATIENT_ADDRESS,'''') AS patient_address,coll.HOSPITAL AS Hospital,coll.EMAIL_ADDRESS AS Email_Address,CAST(1 AS BIT) AS isUploaded FROM tbl_FTS_collection AS coll '
		SET @SQL+='INNER JOIN tbl_Master_shop AS shp ON coll.shop_id=shp.Shop_Code '
		SET @SQL+='LEFT OUTER JOIN tbl_FTS_collection_invoicewise INV ON coll.collection_id=INV.collection_id '
		SET @SQL+='WHERE coll.user_id='+@user_id+' '
		IF(ISNULL(@collection_date,'')<>'')
			SET @SQL+='AND CAST(coll.collection_date AS DATE)='''+@collection_date+''' '
		EXEC sp_ExecuteSQL @SQL
		--End of Rev 2.0

		END
	ELSE if(isnull(@Action,'')='InvoiceList' )
		BEGIN
			select  BillingId,User_Id,bill_id,invoice_no,CONVERT(VARCHAR(10),invoice_date,120) invoice_date,invoice_amount,bill.OrderCode,bill.Remarks,
			Invoice_Unpaid,ISNULL(invoice_amount,0)-ISNULL(Invoice_Unpaid,0) paid_amt,'' billing_image
			from tbl_FTS_BillingDetails bill
			INNER JOIN tbl_trans_fts_Orderupdate  orders on bill.OrderCode=orders.OrderCode
			WHERE User_Id=@user_id and Shop_Code=@shop_id and Invoice_Unpaid>0

			select Billing_ID,BillingProd_Id,sProducts_Name,bra.Brand_Name,bra.Brand_Id,
			cls.ProductClass_Name,cls.ProductClass_ID,Size_ID,Size_Name,Product_Qty,
			Product_Rate,Product_TotalAmount
			from FTS_BillingdetailsProduct invPro
			INNER JOIN Master_sProducts pro on invPro.BillingProd_Id=pro.sProducts_ID
			LEFT Join tbl_master_brand bra on bra.Brand_Id=pro.sProducts_Brand
			LEFT JOIN Master_ProductClass cls on cls.ProductClass_ID=pro.ProductClass_Code
			INNER JOIN Master_Size as msize on PRO.sProducts_Size=msize.Size_ID
			where Billing_ID in (select BillingId from tbl_FTS_BillingDetails bill
			INNER JOIN tbl_trans_fts_Orderupdate  orders on bill.OrderCode=orders.OrderCode
			WHERE User_Id=@user_id and Shop_Code=@shop_id and Invoice_Unpaid>0)
		END
	ELSE if(isnull(@Action,'')='InvoiceListReport' )
		BEGIN
			IF(ISNULL(@collection_date,'')='')
				BEGIN
					select shop.Shop_Code shop_id,shop_name,ISNULL(amt,0) total_amount,isnull(unpaid,0) total_bal,ISNULL(amt,0)-ISNULL(unpaid,0) total_collection,
					CASE WHEN ISNULL(@weburl,'')='' THEN '' ELSE ISNULL(@weburl,'')+Shop_Image END Shop_Image
					from tbl_Master_shop shop 
					left join (select SUM(ISNULL(invoice_amount,0)) amt,SUM(ISNULL(Invoice_Unpaid,0)) unpaid,Shop_Code
					from tbl_FTS_BillingDetails bill
					left join tbl_trans_fts_Orderupdate orders
					on  bill.OrderCode=orders.OrderCode
					group by Shop_Code) tbl on tbl.Shop_Code=shop.Shop_Code
					WHERE shop.Shop_CreateUser=@user_id 
				END
			ELSE
				BEGIN
					select shop.Shop_Code shop_id,shop_name,ISNULL(amt,0) total_amount,isnull(unpaid,0) total_bal,ISNULL(amt,0)-ISNULL(unpaid,0) total_collection,
					CASE WHEN ISNULL(@weburl,'')='' THEN '' ELSE ISNULL(@weburl,'')+Shop_Image END Shop_Image
					from tbl_Master_shop shop 
					left join (select SUM(ISNULL(invoice_amount,0)) amt,SUM(ISNULL(Invoice_Unpaid,0)) unpaid,Shop_Code
					from tbl_FTS_BillingDetails bill
					left join tbl_trans_fts_Orderupdate orders
					on  bill.OrderCode=orders.OrderCode where cast(invoice_date as date)=cast(@collection_date as date)
					group by Shop_Code) tbl on tbl.Shop_Code=shop.Shop_Code
					WHERE shop.Shop_CreateUser=@user_id 
				END
		END
	ELSE if(isnull(@Action,'')='CollectionListReport' )
		BEGIN
			DECLARE @today_paid numeric(18,2),@today_pending numeric(18,2),@total_paid numeric(18,2),@total_pending  numeric(18,2),
			@today_total numeric(18,2),@total numeric(18,2)
			SET @today_paid=(select sum(collection) from tbl_FTS_collection_Invoicewise 
			where cast(collection_date as date)=cast(getdate() as date) and user_id=@user_id)
			SET @total_paid=(select sum(collection) from tbl_FTS_collection_Invoicewise where user_id=@user_id)

			set @today_total=(select SUM(isnull(invoice_amount,0)) from tbl_FTS_BillingDetails 
			where cast(invoice_date as date)=cast(getdate() as date) and user_id=@user_id )
			set @total=(select SUM(isnull(invoice_amount,0)) from tbl_FTS_BillingDetails 
			where  user_id=@user_id )

			select ISNULL(@today_paid,0) today_paid,
			ISNULL(@total_paid,0) total_paid,
			ISNULL(@today_total,0)-ISNULL(@today_paid,0) today_pending,
			ISNULL(@total,0)-ISNULL(@total_paid,0) total_pending
		END
	
	SET NOCOUNT OFF
END