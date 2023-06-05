IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPIQRCODEIMAGEINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPIQRCODEIMAGEINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSAPIQRCODEIMAGEINFO]
(
@ACTION NVARCHAR(50),
@USER_ID BIGINT=NULL,
@PathImage NVARCHAR(500)=NULL,
@BaseURL NVARCHAR(500)=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 01/06/2023
Purpose : For QR Code Image Save API.Row: 845 to 847
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='SAVEQRCODEIMAGE'
		BEGIN
			IF NOT EXISTS(SELECT USERID FROM FSMQRCODEIMAGEINFO WHERE USERID=@USER_ID)
				BEGIN
					INSERT INTO FSMQRCODEIMAGEINFO(USERID,QRCODEIMAGEPATH,CREATE_USER,CREATE_DATE)
					SELECT @USER_ID,@PathImage,@USER_ID,GETDATE()

					SELECT ISNULL(QRCODEIMAGEPATH,'') AS qr_img_link FROM FSMQRCODEIMAGEINFO WHERE USERID=@USER_ID AND QRCODEIMAGEPATH=@PathImage
				END
		END
	ELSE IF @ACTION='FETCHQRCODEIMAGE'
		BEGIN
			SELECT ISNULL(QRCODEIMAGEPATH,'') AS qr_img_link FROM FSMQRCODEIMAGEINFO WHERE USERID=@USER_ID
		END
	ELSE IF @ACTION='DELETEQRCODEIMAGE'
		BEGIN
			SELECT ISNULL(QRCODEIMAGEPATH,'') AS qr_img_link FROM FSMQRCODEIMAGEINFO WHERE USERID=@USER_ID
			DELETE FROM FSMQRCODEIMAGEINFO WHERE USERID=@USER_ID
		END

	SET NOCOUNT OFF
END