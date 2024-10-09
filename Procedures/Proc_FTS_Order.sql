IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_Order]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_Order] AS' 
END
GO
ALTER PROCEDURE [dbo].[Proc_FTS_Order]
(
@user_id varchar(50)=NULL,
@SessionToken varchar(MAX)=NULL,
@order_amount varchar(50)=NULL,
@order_id varchar(60)=NULL,
@description varchar(MAX)=NULL,
@Shop_Id varchar(60)=NULL,
@Collection  varchar(60)=NULL,
@order_date datetime=NULL,
@Product_List XML=NULL,
@Lat  varchar(50)=NULL,
@Long  varchar(50)=NULL,
@Order_Address  varchar(MAX)=NULL,
@Remarks NVARCHAR(MAX)=NULL,
@signatureName NVARCHAR(MAX)=NULL,
--REV 2.0
@patient_no  varchar(15)=NULL,
@patient_name NVARCHAR(200)=NULL,
@patient_address NVARCHAR(500)=NULL,
--END OF REV 2.0
--Rev 3.0
@Scheme_Amount DECIMAL(18,2)=NULL,
--End of Rev 3.0
--Rev 4.0
@Hospital NVARCHAR(200)=NULL,
@Email_Address NVARCHAR(300)=NULL,
--End of Rev 4.0
--Rev 7.0
@OrderStatus NVARCHAR(100)=NULL
--End of Rev 7.0
) --WITH ENCRYPTION
As
/*************************************************************************************************************************************
1.0					TANMOY		14-02-2020		Product stock out in stock table
2.0					TANMOY		10-04-2021		Extra patient details insert
3.0		v2.0.26		Debashis	29-12-2021		Enhancement done for Row No. 597
4.0		v2.0.26		Debashis	10-01-2022		Enhancement done for Row No. 606 & 607
5.0		v2.0.33		Debashis	13-10-2022		Product_Qty length has been increased.Refer: 25368
6.0		v2.0.38		Debashis	23-01-2023		Enhancement done for Row No. 805
7.0		v2.0.49		Debashis	17-09-2024		Enhancement done for Row No. 977
*************************************************************************************************************************************/
BEGIN

	BEGIN TRAN
		BEGIN TRY
			if(@Collection ='')
			BEGIN
			set @Collection=0
			END
			declare  @OrderUniqueId bigint
			--Rev 7.0
			DECLARE @IsRetailOrderStatusRequired NCHAR(1)=''
			--End of Rev 7.0

			IF NOT EXISTS(select Ordervalue  from tbl_trans_fts_Orderupdate where OrderCode=@order_id)
			BEGIN

			--UPDATE  tbl_trans_fts_Orderupdate set Ordervalue=@order_amount ,Order_Description=@description ,Latitude=@Lat ,Longitude =@Long ,Order_Address=@Order_Address
			--where OrderCode=@order_id and Shop_Code=@Shop_Id
			--SET @OrderUniqueId=(select OrderId  from tbl_trans_fts_Orderupdate where OrderCode=@order_id and userID=@user_id)
			--END
			--ELSE
			--BEGIN

			--Rev 3.0 && A new column Scheme_Amount have been added.
			--Rev 4.0 &&Two new columns added as HOSPITAL & EMAIL_ADDRESS
			--Rev 7.0 &&A new column added as ORDERSTATUS
			INSERT INTO tbl_trans_fts_Orderupdate (Shop_Code,OrderCode,Ordervalue,Order_Description,Orderdate,userID,Collectionvalue,Latitude,Longitude,Order_Address,Remarks
							,PATIENT_PHONE_NO,PATIENT_NAME,PATIENT_ADDRESS,Scheme_Amount,HOSPITAL,EMAIL_ADDRESS,ORDERSTATUS)
			values (@Shop_Id,@order_id,@order_amount,@description,@order_date,@user_id,isnull(@Collection,0),@Lat,@Long,@Order_Address,@Remarks,@patient_no,@patient_name,@patient_address,@Scheme_Amount,
							@Hospital,@Email_Address,@OrderStatus)

			SET @OrderUniqueId=SCOPE_IDENTITY()
			--Rev 7.0
			SET @IsRetailOrderStatusRequired=(SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsRetailOrderStatusRequired' AND IsActive=1)
			IF @IsRetailOrderStatusRequired='1'
				BEGIN
					INSERT INTO FSM_ORDERUPDATESTAUSLOG(ORDERSTAUSLOG_ID,SHOP_CODE,ORDER_CODE,ORDER_VALUE,ORDER_DESCRIPTION,ORDER_DATE,USERID,ORDER_STATUS,[ACTION],CREATEDBY,CREATEDON)
					SELECT @OrderUniqueId,@Shop_Id,@order_id,@order_amount,@description,@order_date,@user_id,'Ordered','I',@user_id,GETDATE()
				END
			--End of Rev 7.0
			END

			if(@@ROWCOUNT>0)
				BEGIN
					--Rev 3.0 && Three new columns Scheme_Qty,Scheme_Rate & Total_Scheme_Price has been added.
					--Rev 4.0 && A new column added as MRP
					--Rev 5.0 && Column size increase from XMLproduct.value('(qty/text())[1]','decimal(18,2)')	to XMLproduct.value('(qty/text())[1]','decimal(18,3)')
					--Rev 6.0 && Two new columns added as order_mrp & order_discount
					INSERT  INTO  tbl_FTs_OrderdetailsProduct (Order_ID,Product_Id,Product_Qty,Product_Rate,Product_Price,Scheme_Qty,Scheme_Rate,Total_Scheme_Price,MRP,ORDER_MRP,ORDER_DISCOUNT,Shop_code,User_Id)
					select distinct @OrderUniqueId,
					XMLproduct.value('(id/text())[1]','bigint')	,
					XMLproduct.value('(qty/text())[1]','decimal(18,3)')	,
					XMLproduct.value('(rate/text())[1]','decimal(18,2)')	,
					XMLproduct.value('(total_price/text())[1]','decimal(18,2)'),
					XMLproduct.value('(scheme_qty/text())[1]','decimal(18,2)'),
					XMLproduct.value('(scheme_rate/text())[1]','decimal(18,2)'),
					XMLproduct.value('(total_scheme_price/text())[1]','decimal(18,2)'),
					XMLproduct.value('(MRP/text())[1]','decimal(18,2)'),
					XMLproduct.value('(order_mrp/text())[1]','decimal(18,2)'),
					XMLproduct.value('(order_discount/text())[1]','decimal(18,2)')
					,@Shop_Id,@user_id
					FROM  @Product_List.nodes('/root/data')AS TEMPTABLE(XMLproduct)   

					--select cast(@user_id as varchar(50)) as user_id,
					--       @order_id  as order_id,
					--    cast(@order_amount  as varchar(50))  as order_amount,
					--     @description  as  decription
					--SELECT * FROM tbl_trans_fts_Orderupdate
					--SELECT * FROM FTS_WarehouseWiseProductStock
					DECLARE @WAREHOUSE_ID BIGINT

					SET @WAREHOUSE_ID = (SELECT WH.WAREHOUSE_ID FROM FTS_MASTER_WAREHOUSE WH INNER JOIN FTS_WarehouseDetails DET ON WH.WAREHOUSE_ID=DET.WAREHOUSE_ID WHERE DET.SHOP_CODE=@Shop_Id)

					INSERT INTO FTS_WarehouseWiseProductStock (WAREHOUSE_ID,PRODUCT_ID,OUT_QTY,DOC_ID,DOC_TYPE,IN_OUT_TYPE,DOCUMENT_DATE,CREATED_ON,CREATED_BY)
					select distinct @WAREHOUSE_ID,
					XMLproduct.value('(id/text())[1]','bigint')	,
					XMLproduct.value('(qty/text())[1]','decimal(18,2)')	,
					@order_id,
					'ORDER',
					'OUT',
					@order_date,
					GETDATE(),
					@user_id
					FROM  @Product_List.nodes('/root/data')AS TEMPTABLE(XMLproduct)  

					INSERT INTO FTS_WarehouseWiseProductStock_Log (WAREHOUSE_ID,PRODUCT_ID,OUT_QTY,DOC_ID,DOC_TYPE,IN_OUT_TYPE,DOCUMENT_DATE,CREATED_ON,CREATED_BY)
					select distinct @WAREHOUSE_ID,
					XMLproduct.value('(id/text())[1]','bigint')	,
					XMLproduct.value('(qty/text())[1]','decimal(18,2)')	,
					@order_id,
					'ORDER',
					'OUT',
					@order_date,
					GETDATE(),
					@user_id
					FROM  @Product_List.nodes('/root/data')AS TEMPTABLE(XMLproduct)  

					IF ISNULL(@signatureName,'')<>''
					BEGIN
						INSERT INTO FTS_OrderSignatureMap
						VALUES(@OrderUniqueId,@signatureName)

					END


					select  orderup.userID as user_id,orderup.Ordervalue as order_amount,orderup.Order_Description as  decription ,orderup.OrderCode as order_id
					,shp.Shop_Name,shp.Shop_Owner_Contact,shp.Shop_Owner
					from tbl_trans_fts_Orderupdate as orderup inner join tbl_Master_shop as shp on orderup.Shop_Code=shp.Shop_Code
					where orderup.OrderId=@OrderUniqueId
				END

			COMMIT TRAN
		END TRY

	BEGIN CATCH
	ROLLBACK TRAN
	END CATCH

END
GO