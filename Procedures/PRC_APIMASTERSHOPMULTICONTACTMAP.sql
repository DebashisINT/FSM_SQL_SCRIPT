IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIMASTERSHOPMULTICONTACTMAP]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIMASTERSHOPMULTICONTACTMAP] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_APIMASTERSHOPMULTICONTACTMAP]
(
@ACTION NVARCHAR(20),
@session_token NVARCHAR(MAX)=NULL,
@user_id NVARCHAR(50)=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 10/01/2023
Module	   : Add mutiple contact for a Shop.Refer: Row:783 to 785
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='ADD'
		BEGIN
			BEGIN TRAN
				BEGIN TRY
					IF NOT EXISTS(SELECT SHPCON.SHOP_CODE FROM MASTERSHOPMULTICONTACTMAP SHPCON WITH(NOLOCK) 
					INNER JOIN @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct) ON SHPCON.SHOP_CODE=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
					AND SHPCON.User_Id=@user_id)
						BEGIN
							INSERT INTO MASTERSHOPMULTICONTACTMAP(USER_ID,SHOP_CODE,CONTACT_SERIAL1,CONTACT_NAME1,CONTACT_NUMBER1,CONTACT_EMAIL1,CONTACT_DOA1,CONTACT_SERIAL2,CONTACT_NAME2,
							CONTACT_NUMBER2,CONTACT_EMAIL2,CONTACT_DOA2,CONTACT_SERIAL3,CONTACT_NAME3,CONTACT_NUMBER3,CONTACT_EMAIL3,CONTACT_DOA3,CONTACT_SERIAL4,CONTACT_NAME4,CONTACT_NUMBER4,
							CONTACT_EMAIL4,CONTACT_DOA4,CONTACT_SERIAL5,CONTACT_NAME5,CONTACT_NUMBER5,CONTACT_EMAIL5,CONTACT_DOA5,CONTACT_SERIAL6,CONTACT_NAME6,CONTACT_NUMBER6,CONTACT_EMAIL6,
							CONTACT_DOA6,CREATED_USER,CREATE_DATE)
	
							SELECT DISTINCT @user_id,
							XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_serial1/text())[1]','int'),
							XMLproduct.value('(contact_name1/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number1/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email1/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa1/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial2/text())[1]','int'),
							XMLproduct.value('(contact_name2/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number2/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email2/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa2/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial3/text())[1]','int'),
							XMLproduct.value('(contact_name3/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number3/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email3/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa3/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial4/text())[1]','int'),
							XMLproduct.value('(contact_name4/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number4/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email4/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa4/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial5/text())[1]','int'),
							XMLproduct.value('(contact_name5/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number5/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email5/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa5/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial6/text())[1]','int'),
							XMLproduct.value('(contact_name6/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number6/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email6/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa6/text())[1]','DATETIME'),
							@user_id,GETDATE()
							FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
							INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')
							WHERE NOT EXISTS(SELECT SHPCON.SHOP_CODE FROM MASTERSHOPMULTICONTACTMAP SHPCON WITH(NOLOCK) WHERE SHPCON.SHOP_CODE=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
							AND SHPCON.User_Id=@user_id)

							SELECT DISTINCT @user_id,
							XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_serial1/text())[1]','int'),
							XMLproduct.value('(contact_name1/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number1/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email1/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa1/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial2/text())[1]','int'),
							XMLproduct.value('(contact_name2/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number2/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email2/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa2/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial3/text())[1]','int'),
							XMLproduct.value('(contact_name3/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number3/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email3/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa3/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial4/text())[1]','int'),
							XMLproduct.value('(contact_name4/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number4/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email4/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa4/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial5/text())[1]','int'),
							XMLproduct.value('(contact_name5/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number5/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email5/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa5/text())[1]','DATETIME'),
							XMLproduct.value('(contact_serial6/text())[1]','int'),
							XMLproduct.value('(contact_name6/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_number6/text())[1]','NVARCHAR(100)'),
							XMLproduct.value('(contact_email6/text())[1]','NVARCHAR(300)'),
							XMLproduct.value('(contact_doa6/text())[1]','DATETIME'),
							@user_id,GETDATE(),'Success' AS STRMESSAGE
							FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
							INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')
							WHERE EXISTS(SELECT SHPCON.SHOP_CODE FROM MASTERSHOPMULTICONTACTMAP SHPCON WITH(NOLOCK) WHERE SHPCON.SHOP_CODE=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
							AND SHPCON.User_Id=@user_id)
						END
				COMMIT TRAN
			END TRY

			BEGIN CATCH
				ROLLBACK TRAN
				SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage
			END CATCH
		END
	IF @ACTION='EDIT'
		BEGIN
			IF EXISTS(SELECT SHPCON.SHOP_CODE FROM MASTERSHOPMULTICONTACTMAP SHPCON WITH(NOLOCK) 
			INNER JOIN @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct) ON SHPCON.SHOP_CODE=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
			AND SHPCON.User_Id=@user_id)
				BEGIN
					UPDATE SHPCON SET CONTACT_SERIAL1=XMLproduct.value('(contact_serial1/text())[1]','INT'),
					CONTACT_NAME1=XMLproduct.value('(contact_name1/text())[1]','NVARCHAR(300)'),
					CONTACT_NUMBER1=XMLproduct.value('(contact_number1/text())[1]','NVARCHAR(100)'),
					CONTACT_EMAIL1=XMLproduct.value('(contact_email1/text())[1]','NVARCHAR(300)'),
					CONTACT_DOA1=XMLproduct.value('(contact_doa1/text())[1]','DATETIME'),
					CONTACT_SERIAL2=XMLproduct.value('(contact_serial2/text())[1]','INT'),
					CONTACT_NAME2=XMLproduct.value('(contact_name2/text())[1]','NVARCHAR(300)'),
					CONTACT_NUMBER2=XMLproduct.value('(contact_number2/text())[1]','NVARCHAR(100)'),
					CONTACT_EMAIL2=XMLproduct.value('(contact_email2/text())[1]','NVARCHAR(300)'),
					CONTACT_DOA2=XMLproduct.value('(contact_doa2/text())[1]','DATETIME'),
					CONTACT_SERIAL3=XMLproduct.value('(contact_serial3/text())[1]','INT'),
					CONTACT_NAME3=XMLproduct.value('(contact_name3/text())[1]','NVARCHAR(300)'),
					CONTACT_NUMBER3=XMLproduct.value('(contact_number3/text())[1]','NVARCHAR(100)'),
					CONTACT_EMAIL3=XMLproduct.value('(contact_email3/text())[1]','NVARCHAR(300)'),
					CONTACT_DOA3=XMLproduct.value('(contact_doa3/text())[1]','DATETIME'),
					CONTACT_SERIAL4=XMLproduct.value('(contact_serial4/text())[1]','INT'),
					CONTACT_NAME4=XMLproduct.value('(contact_name4/text())[1]','NVARCHAR(300)'),
					CONTACT_NUMBER4=XMLproduct.value('(contact_number4/text())[1]','NVARCHAR(100)'),
					CONTACT_EMAIL4=XMLproduct.value('(contact_email4/text())[1]','NVARCHAR(300)'),
					CONTACT_DOA4=XMLproduct.value('(contact_doa4/text())[1]','DATETIME'),
					CONTACT_SERIAL5=XMLproduct.value('(contact_serial5/text())[1]','INT'),
					CONTACT_NAME5=XMLproduct.value('(contact_name5/text())[1]','NVARCHAR(300)'),
					CONTACT_NUMBER5=XMLproduct.value('(contact_number5/text())[1]','NVARCHAR(100)'),
					CONTACT_EMAIL5=XMLproduct.value('(contact_email5/text())[1]','NVARCHAR(300)'),
					CONTACT_DOA5=XMLproduct.value('(contact_doa5/text())[1]','DATETIME'),
					CONTACT_SERIAL6=XMLproduct.value('(contact_serial6/text())[1]','INT'),
					CONTACT_NAME6=XMLproduct.value('(contact_name6/text())[1]','NVARCHAR(300)'),
					CONTACT_NUMBER6=XMLproduct.value('(contact_number6/text())[1]','NVARCHAR(100)'),
					CONTACT_EMAIL6=XMLproduct.value('(contact_email6/text())[1]','NVARCHAR(300)'),
					CONTACT_DOA6=XMLproduct.value('(contact_doa6/text())[1]','DATETIME'),
					MODIFIED_USER=@user_id,MODIFIED_DATE=GETDATE()
					FROM MASTERSHOPMULTICONTACTMAP SHPCON
					INNER JOIN @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  
					ON SHPCON.SHOP_CODE=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') AND SHPCON.USER_ID=@user_id

					SELECT DISTINCT @user_id,
					XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(contact_serial1/text())[1]','int'),
					XMLproduct.value('(contact_name1/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_number1/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(contact_email1/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_doa1/text())[1]','DATETIME'),
					XMLproduct.value('(contact_serial2/text())[1]','int'),
					XMLproduct.value('(contact_name2/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_number2/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(contact_email2/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_doa2/text())[1]','DATETIME'),
					XMLproduct.value('(contact_serial3/text())[1]','int'),
					XMLproduct.value('(contact_name3/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_number3/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(contact_email3/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_doa3/text())[1]','DATETIME'),
					XMLproduct.value('(contact_serial4/text())[1]','int'),
					XMLproduct.value('(contact_name4/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_number4/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(contact_email4/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_doa4/text())[1]','DATETIME'),
					XMLproduct.value('(contact_serial5/text())[1]','int'),
					XMLproduct.value('(contact_name5/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_number5/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(contact_email5/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_doa5/text())[1]','DATETIME'),
					XMLproduct.value('(contact_serial6/text())[1]','int'),
					XMLproduct.value('(contact_name6/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_number6/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(contact_email6/text())[1]','NVARCHAR(300)'),
					XMLproduct.value('(contact_doa6/text())[1]','DATETIME'),
					@user_id,GETDATE(),'Success' AS STRMESSAGE
					FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
					INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')
					WHERE EXISTS(SELECT SHPCON.SHOP_CODE FROM MASTERSHOPMULTICONTACTMAP SHPCON WITH(NOLOCK) WHERE SHPCON.SHOP_CODE=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
					AND SHPCON.User_Id=@user_id)
				END
		END
	IF @ACTION='FETCHDATA'
		BEGIN
			SELECT USER_ID AS user_id,SHOP_CODE AS shop_id,CONTACT_SERIAL1 AS contact_serial1,ISNULL(CONTACT_NAME1,'') AS contact_name1,ISNULL(CONTACT_NUMBER1,'') AS contact_number1,
			ISNULL(CONTACT_EMAIL1,'') AS contact_email1,CONVERT(NVARCHAR(10),CONTACT_DOA1,105) AS contact_doa1,CONTACT_SERIAL2 AS contact_serial2,ISNULL(CONTACT_NAME2,'') AS contact_name2,
			ISNULL(CONTACT_NUMBER2,'') AS contact_number2,ISNULL(CONTACT_EMAIL2,'') AS contact_email2,ISNULL(CONVERT(NVARCHAR(10),CONTACT_DOA2,105),'') AS contact_doa2,CONTACT_SERIAL3 AS contact_serial3,
			ISNULL(CONTACT_NAME3,'') AS contact_name3,ISNULL(CONTACT_NUMBER3,'') AS contact_number3,ISNULL(CONTACT_EMAIL3,'') AS contact_email3,ISNULL(CONVERT(NVARCHAR(10),CONTACT_DOA3,105),'') AS contact_doa3,
			CONTACT_SERIAL4 AS contact_serial4,ISNULL(CONTACT_NAME4,'') AS contact_name4,ISNULL(CONTACT_NUMBER4,'') AS contact_number4,ISNULL(CONTACT_EMAIL4,'') AS contact_email4,
			ISNULL(CONVERT(NVARCHAR(10),CONTACT_DOA4,105),'') AS contact_doa4,CONTACT_SERIAL5 AS contact_serial5,ISNULL(CONTACT_NAME5,'') AS contact_name5,ISNULL(CONTACT_NUMBER5,'') AS contact_number5,
			ISNULL(CONTACT_EMAIL5,'') AS contact_email5,ISNULL(CONVERT(NVARCHAR(10),CONTACT_DOA5,105),'') AS contact_doa5,CONTACT_SERIAL6 AS contact_serial6,ISNULL(CONTACT_NAME6,'') AS contact_name6,
			ISNULL(CONTACT_NUMBER6,'') AS contact_number6,ISNULL(CONTACT_EMAIL6,'') AS contact_email6,ISNULL(CONVERT(NVARCHAR(10),CONTACT_DOA6,105),'') AS contact_doa6 
			FROM MASTERSHOPMULTICONTACTMAP WHERE USER_ID=@user_id
		END

	SET NOCOUNT OFF
END