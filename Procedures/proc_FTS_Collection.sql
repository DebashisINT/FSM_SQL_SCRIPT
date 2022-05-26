IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[proc_FTS_Collection]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [proc_FTS_Collection] AS' 
END
GO

ALTER PROCEDURE [dbo].[proc_FTS_Collection]
(
@user_id varchar(100)=NULL,
@shop_id varchar(100)=NULL,
@collection varchar(100)=NULL,
@collection_id varchar(100)=NULL,
@collection_date varchar(100)=NULL,
@bill_id varchar(100)=NULL,
--Rev 1.0 Start
@payment_id varchar(100)=NULL,
@instrument_no varchar(100)=NULL,
@bank varchar(200)=NULL,
@remarks varchar(500)=NULL
--Rev 1.0 End
--REV 2.0
,@patient_no  varchar(15)=NULL,
@patient_name NVARCHAR(200)=NULL,
@patient_address NVARCHAR(500)=NULL,
--END OF REV 2.0
--Rev 3.0
@Hospital NVARCHAR(200)=NULL,
@Email_Address NVARCHAR(300)=NULL,
--Rev 4.0
@order_id NVARCHAR(400)=NULL
--End of Rev 4.0
--End of Rev 3.0
) --WITH ENCRYPTION
AS
/************************************************************************************************
1.0					Tanmoy		30-11-2020		ADD NEW COLUMN IN COLLECTION
2.0					TANMOY		10-04-2021		Extra patient details insert
3.0		v2.0.26		Debashis	10-01-2022		Enhancement done for Row No. 603
4.0		v2.0.30		Debashis	26-05-2022		Order Number added for Row No. 688
*************************************************************************************************/
BEGIN
	declare  @ColllectionUniqueId bigint

	IF NOT EXISTS(select  user_id  from tbl_FTS_collection where collection_id=@collection_id)
		BEGIN
			insert into tbl_FTS_collection
			 (collection_id,
			user_id,
			shop_id,
			collection,
			collection_date
			--Rev 1.0 Start
			,Payment_id,
			Instrument_no,
			Bank,
			Remarks
			--Rev 1.0 End
			--REV 2.0
			,PATIENT_PHONE_NO,PATIENT_NAME,PATIENT_ADDRESS,
			--END OF REV 2.0
			--Rev 3.0
			HOSPITAL,EMAIL_ADDRESS
			--End of Rev 3.0
			)
			values
			(
			@collection_id,
			@user_id,
			@shop_id,
			@collection,
			@collection_date
			--Rev 1.0 Start
			,@payment_id,
			@instrument_no,
			@bank,
			@remarks
			--Rev 1.0 End
			--REV 2.0
			,@patient_no,@patient_name,@patient_address,
			--END OF REV 2.0
			--Rev 3.0
			@Hospital,@Email_Address
			--End of Rev 3.0
			)

			SET @ColllectionUniqueId=SCOPE_IDENTITY()

			--WHILE (@collection=0 OR NOT EXISTS(select * from tbl_FTS_BillingDetails b
			--inner join tbl_trans_fts_Orderupdate o on b.OrderCode= o.OrderCode
			--WHERE Shop_Code=@shop_id and Invoice_Unpaid>0))
			--BEGIN

			--DECLARE @unapid NUMERIC(18,2),@BillingId VARCHAR(250),@INVOICE_NUMBER VARCHAR(250)

			--select top 1 @unapid=Invoice_Unpaid,@BillingId=BillingId,@INVOICE_NUMBER=bill_id from tbl_FTS_BillingDetails b
			--inner join tbl_trans_fts_Orderupdate o on b.OrderCode= o.OrderCode
			--WHERE Shop_Code=@shop_id and Invoice_Unpaid>0 order by invoice_date desc 


			--if(@collection<@unapid)
			--BEGIN

			UPDATE tbl_FTS_BillingDetails SET Invoice_Unpaid=Invoice_Unpaid-@collection WHERE bill_id=@bill_id
			--SET @collection=0
			--Rev 4.0 && A new column has been added as ORDER_NUMBER
			insert  into tbl_FTS_collection_invoicewise
			 (collection_id,
			user_id,
			shop_id,
			collection,
			collection_date,INVOICE_NUMBER,ORDER_NUMBER)
			values
			(
			@collection_id,
			@user_id,
			@shop_id,
			@collection,
			@collection_date,@bill_id,@order_id
			)

			--END
			--ELSE
			--BEGIN
			--UPDATE tbl_FTS_BillingDetails SET Invoice_Unpaid=0 WHERE BillingId=@BillingId
			--SET @collection=@collection-@unapid

			--insert  into tbl_FTS_collection_invoicewise
			-- (collection_id,
			--user_id,
			--shop_id,
			--collection,
			--collection_date,INVOICE_NUMBER)
			--values
			--(
			--@collection_id,
			--@user_id,
			--@shop_id,
			--@unapid,
			--@collection_date,
			--@INVOICE_NUMBER
			--)
			--END


			--END



			if(@@ROWCOUNT>0)
			--select @user_id as user_id,@shop_id as shop_id,@collection as collection


			select user_id, collcton.shop_id,collection,shp.Shop_Name,shp.Shop_Owner,shp.Shop_Owner_Contact from tbl_FTS_collection as collcton   
			inner join tbl_Master_shop as shp on collcton.shop_id=shp.Shop_Code
			where collcton.Collecpk_Id=@ColllectionUniqueId


		END
END