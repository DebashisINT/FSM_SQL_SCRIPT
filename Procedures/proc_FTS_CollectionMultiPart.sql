IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[proc_FTS_CollectionMultiPart]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [proc_FTS_CollectionMultiPart] AS' 
END
GO

ALTER PROC [dbo].[proc_FTS_CollectionMultiPart]
(
@user_id varchar(100)=NULL,
@shop_id varchar(100)=NULL,
@collection varchar(100)=NULL,
@collection_id varchar(100)=NULL,
@collection_date varchar(100)=NULL,
@bill_id varchar(100)=NULL,
@payment_id varchar(100)=NULL,
@instrument_no varchar(100)=NULL,
@bank varchar(200)=NULL,
@remarks varchar(500)=NULL,
@order_id NVARCHAR(100)=NULL,
@docName NVARCHAR(MAX)=NULL,
--REV 2.0
@patient_no  varchar(15)=NULL,
@patient_name NVARCHAR(200)=NULL,
@patient_address NVARCHAR(500)=NULL,
--END OF REV 2.0
--Rev 3.0
@Hospital NVARCHAR(200)=NULL,
@Email_Address NVARCHAR(300)=NULL
--End of Rev 3.0
) --WITH ENCRYPTION
AS
/************************************************************************************************
1.0					Tanmoy		30-11-2020			CREATE PROCEDURE
2.0					TANMOY		10-04-2021			Extra patient details insert
3.0		v2.0.26		Debashis	10-01-2022		Enhancement done for Row No. 604
*************************************************************************************************/
BEGIN
	declare  @ColllectionUniqueId bigint

	IF NOT EXISTS(select  user_id  from tbl_FTS_collection where collection_id=@collection_id)
	BEGIN
		--Rev 3.0 &&Two new columns added as HOSPITAL & EMAIL_ADDRESS
		insert into tbl_FTS_collection (collection_id,user_id,shop_id,collection,collection_date,Payment_id,Instrument_no,Bank,Remarks,DocumentName
		,PATIENT_PHONE_NO,PATIENT_NAME,PATIENT_ADDRESS,HOSPITAL,EMAIL_ADDRESS
		)
		values(@collection_id,@user_id,@shop_id,@collection,@collection_date,@payment_id,@instrument_no,@bank,@remarks,@docName
		,@patient_no,@patient_name,@patient_address,@Hospital,@Email_Address
		)

		SET @ColllectionUniqueId=SCOPE_IDENTITY()

		UPDATE tbl_FTS_BillingDetails SET Invoice_Unpaid=Invoice_Unpaid-@collection WHERE bill_id=@bill_id
		insert  into tbl_FTS_collection_invoicewise (collection_id,user_id,shop_id,collection,collection_date,INVOICE_NUMBER,ORDER_NUMBER)
		values(@collection_id,@user_id,@shop_id,@collection,@collection_date,@bill_id,@order_id)

		if(@@ROWCOUNT>0)
		select user_id, collcton.shop_id,collection,shp.Shop_Name,shp.Shop_Owner,shp.Shop_Owner_Contact from tbl_FTS_collection as collcton   
		inner join tbl_Master_shop as shp on collcton.shop_id=shp.Shop_Code
		where collcton.Collecpk_Id=@ColllectionUniqueId
	END
END