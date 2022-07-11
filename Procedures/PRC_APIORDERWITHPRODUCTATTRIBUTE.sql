IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIORDERWITHPRODUCTATTRIBUTE]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIORDERWITHPRODUCTATTRIBUTE] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIORDERWITHPRODUCTATTRIBUTE]
(
@ACTION NVARCHAR(20),
@user_id BIGINT=NULL,
@order_id NVARCHAR(100)=NULL,
@shop_id NVARCHAR(100)=NULL,
@order_date DATETIME=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************
Written By : Debashis Talukder On 02/09/2021
Purpose : For New Order.
1.0		v2.0.31		Debashis	06/07/2022		A new column added as RATE.Row: 710
2.0		v2.0.31		Debashis	11/07/2022		A new column added as RATE.Row: 712
****************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @HEADERID BIGINT

	IF @ACTION='INSERTDATA'
		BEGIN
			INSERT INTO ORDERPRODUCTATTRIBUTE(USER_ID,ORDER_ID,ORDER_DATE,SHOP_ID)
			SELECT @user_id,@order_id,@order_date,@shop_id

			SET @HEADERID=SCOPE_IDENTITY();

			--Rev 1.0 && A new column added as RATE
			INSERT INTO ORDERPRODUCTATTRIBUTEDET(ID,USER_ID,ORDER_ID,PRODUCT_ID,PRODUCT_NAME,GENDER,SIZE,QTY,COLOR_ID,RATE)
			SELECT @HEADERID,@user_id,@order_id,
			XMLproduct.value('(product_id/text())[1]','BIGINT') AS product_id,
			XMLproduct.value('(product_name/text())[1]','NVARCHAR(300)') AS product_name,
			XMLproduct.value('(gender/text())[1]','NVARCHAR(30)') AS gender,
			XMLproduct.value('(size/text())[1]','NVARCHAR(20)') AS size,
			XMLproduct.value('(qty/text())[1]','DECIMAL(18,2)') AS qty,
			XMLproduct.value('(color_id/text())[1]','NVARCHAR(100)') AS color_id,
			--Rev 1.0
			XMLproduct.value('(rate/text())[1]','DECIMAL(18,2)') AS rate
			--End of Rev 1.0
			FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
			INNER JOIN Master_sProducts MP ON MP.sProducts_ID=XMLproduct.value('(product_id/text())[1]','BIGINT')

			SELECT @HEADERID,@user_id,@order_id,
			XMLproduct.value('(product_id/text())[1]','BIGINT') AS product_id,
			XMLproduct.value('(product_name/text())[1]','NVARCHAR(300)') AS product_name,
			XMLproduct.value('(gender/text())[1]','NVARCHAR(30)') AS gender,
			XMLproduct.value('(size/text())[1]','NVARCHAR(20)') AS size,
			XMLproduct.value('(qty/text())[1]','DECIMAL(18,2)') AS qty,
			XMLproduct.value('(color_id/text())[1]','NVARCHAR(100)') AS color_id 
			FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
		END
	IF @ACTION='FETCHDATA'
		BEGIN
			SELECT Gender_ID AS gender_id,Gender_Name AS gender FROM Master_Gender MG

			SELECT sProducts_ID AS product_id,sProducts_Name AS product_name,MG.Gender_Name AS product_for_gender FROM Master_sProducts MP
			INNER JOIN Mapping_ProductGender MPG ON MPG.Products_ID=MP.sProducts_ID
			INNER JOIN Master_Gender MG ON MG.Gender_ID=MPG.Gender_ID

			SELECT MC.Color_ID AS color_id,MC.Color_Name AS color_name,MPC.Products_ID AS product_id FROM Master_Color MC
			INNER JOIN Mapping_ProductColor MPC ON MC.Color_ID=MPC.Color_ID

			SELECT MS.Size_Name AS size,MPS.Products_ID AS product_id FROM Master_Size MS
			INNER JOIN Mapping_ProductSize MPS ON MS.Size_ID=MPS.Size_ID
		END
	IF @ACTION='SHOPDETAILS'
		BEGIN
			SELECT Shop_Name,Shop_Code AS shop_id,Shop_Owner AS owner_name,Shop_Owner_Contact AS PhoneNumber FROM tbl_Master_shop MS
			INNER JOIN ORDERPRODUCTATTRIBUTE OAH ON MS.Shop_Code=OAH.SHOP_ID
			WHERE OAH.USER_ID=@user_id

			SELECT ORDER_ID AS order_id,ORDER_DATE AS order_date,SHOP_ID FROM ORDERPRODUCTATTRIBUTE OAH
			WHERE OAH.USER_ID=@user_id

			SELECT DISTINCT OAH.ORDER_ID AS order_id,OAD.PRODUCT_ID AS product_id,OAD.PRODUCT_NAME AS product_name,OAD.GENDER AS gender FROM ORDERPRODUCTATTRIBUTE OAH
			INNER JOIN ORDERPRODUCTATTRIBUTEDET OAD ON OAH.ORDER_ID=OAD.ORDER_ID
			WHERE OAH.USER_ID=@user_id

			SELECT OAH.ORDER_ID AS order_id,OAD.SIZE AS size,OAD.QTY AS qty,OAD.COLOR_ID AS color_id,OAD.PRODUCT_ID AS product_id FROM ORDERPRODUCTATTRIBUTE OAH
			INNER JOIN ORDERPRODUCTATTRIBUTEDET OAD ON OAH.ORDER_ID=OAD.ORDER_ID
			WHERE OAH.USER_ID=@user_id
		END
	IF @ACTION='ORDERDETAILS'
		BEGIN
			--Rev 2.0 && A new field added as RATE
			SELECT H.USER_ID AS user_id,H.ORDER_ID AS order_id,D.PRODUCT_ID AS product_id,D.PRODUCT_NAME AS product_name,D.GENDER AS gender,D.SIZE AS size,CAST(D.QTY AS INT) AS qty,
			CONVERT(NVARCHAR(10),H.ORDER_DATE,120) AS order_date,H.shop_id,C.Color_ID AS color_id,C.COLOR_NAME AS color_name,CAST(1 AS BIT) AS isUploaded,D.RATE AS rate FROM ORDERPRODUCTATTRIBUTE H
			INNER JOIN ORDERPRODUCTATTRIBUTEDET D ON H.ID=D.ID
			INNER JOIN (SELECT C.Color_ID,C.COLOR_CODE,C.COLOR_NAME,MAPPC.Products_ID FROM Master_Color C
			INNER JOIN Mapping_ProductColor MAPPC ON C.Color_ID=MAPPC.Color_ID) C ON D.PRODUCT_ID=C.Products_ID AND D.COLOR_ID=CAST(C.Color_ID AS nvarchar(100))
			WHERE H.USER_ID=@user_id
		END

	SET NOCOUNT OFF
END