IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIWHATSAPPMSGINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIWHATSAPPMSGINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIWHATSAPPMSGINFO]
(
@ACTION NVARCHAR(50),
@USER_ID BIGINT=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 01/08/2023
Purpose : WhatsApp Message Information.Row: 860
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='SAVELIST'
		BEGIN
			INSERT INTO FSMWHATSAPPMSGINFO(USERID,SHOP_ID,SHOP_NAME,CONTACTNO,ISNEWSHOP,MSGDATE,MSGTIME,ISWHATSAPPSENT,WHATSAPPSENTMSG,CREATE_USER,CREATE_DATE)
			SELECT @USER_ID,
			XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
			XMLproduct.value('(shop_name/text())[1]','NVARCHAR(4000)'),
			XMLproduct.value('(contactNo/text())[1]','NVARCHAR(100)'),
			XMLproduct.value('(isNewShop/text())[1]','BIT'),
			XMLproduct.value('(date/text())[1]','date'),
			XMLproduct.value('(time/text())[1]','NVARCHAR(20)'),
			XMLproduct.value('(isWhatsappSent/text())[1]','BIT'),
			XMLproduct.value('(whatsappSentMsg/text())[1]','NVARCHAR(500)'),
			@USER_ID,GETDATE()
			FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
			INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')

			SELECT @USER_ID,
			XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
			XMLproduct.value('(shop_name/text())[1]','NVARCHAR(4000)'),
			XMLproduct.value('(contactNo/text())[1]','NVARCHAR(100)'),
			XMLproduct.value('(isNewShop/text())[1]','BIT'),
			XMLproduct.value('(date/text())[1]','date'),
			XMLproduct.value('(time/text())[1]','NVARCHAR(20)'),
			XMLproduct.value('(isWhatsappSent/text())[1]','BIT'),
			XMLproduct.value('(whatsappSentMsg/text())[1]','NVARCHAR(500)')
			FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
			WHERE EXISTS(SELECT WMI.USERID FROM FSMWHATSAPPMSGINFO WMI WITH(NOLOCK) WHERE WMI.SHOP_ID=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
			AND WMI.USERID=@USER_ID)
		END
	ELSE IF @ACTION='FETCHLIST'
		BEGIN
			SELECT USERID AS user_id,SHOP_ID AS shop_id,SHOP_NAME AS shop_name,CONTACTNO AS contactNo,ISNEWSHOP AS isNewShop,CONVERT(NVARCHAR(10),MSGDATE,105) AS date,MSGTIME AS time,
			ISWHATSAPPSENT AS isWhatsappSent,WHATSAPPSENTMSG AS whatsappSentMsg FROM FSMWHATSAPPMSGINFO WHERE USERID=@USER_ID
		END

	SET NOCOUNT OFF
END