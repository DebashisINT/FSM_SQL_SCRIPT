IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APISHOPATTACHMENTIMAGEINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APISHOPATTACHMENTIMAGEINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APISHOPATTACHMENTIMAGEINFO]
(
@ACTION NVARCHAR(100),
@USER_ID BIGINT=NULL,
@SHOP_ID NVARCHAR(100)=NULL,
@AttachmentImage1 NVARCHAR(500)=NULL,
@AttachmentImage2 NVARCHAR(500)=NULL,
@AttachmentImage3 NVARCHAR(500)=NULL,
@AttachmentImage4 NVARCHAR(500)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 09/11/2022
Module	   : API for Save Images in Shop Master.Refer: Row: 761 to 765
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
		
		IF @ACTION='SAVEATTACHMENTIMAGE1'
			BEGIN
				UPDATE tbl_Master_shop SET AttachmentImage1=@AttachmentImage1 WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID

				SELECT Shop_Code,Shop_CreateUser,AttachmentImage1 FROM tbl_Master_shop WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID AND AttachmentImage1=@AttachmentImage1
			END
		IF @ACTION='SAVEATTACHMENTIMAGE2'
			BEGIN
				UPDATE tbl_Master_shop SET AttachmentImage2=@AttachmentImage2 WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID

				SELECT Shop_Code,Shop_CreateUser,AttachmentImage2 FROM tbl_Master_shop WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID AND AttachmentImage2=@AttachmentImage2
			END
		IF @ACTION='SAVEATTACHMENTIMAGE3'
			BEGIN
				UPDATE tbl_Master_shop SET AttachmentImage3=@AttachmentImage3 WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID

				SELECT Shop_Code,Shop_CreateUser,AttachmentImage3 FROM tbl_Master_shop WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID AND AttachmentImage3=@AttachmentImage3
			END
		IF @ACTION='SAVEATTACHMENTIMAGE4'
			BEGIN
				UPDATE tbl_Master_shop SET AttachmentImage4=@AttachmentImage4 WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID

				SELECT Shop_Code,Shop_CreateUser,AttachmentImage4 FROM tbl_Master_shop WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID AND AttachmentImage4=@AttachmentImage4
			END
		IF @ACTION='FETCHATTACHMENTIMAGES'
			BEGIN
				SELECT Shop_Code,Shop_CreateUser,AttachmentImage1 AS attachment_image1,AttachmentImage2 AS attachment_image2,AttachmentImage3 AS attachment_image3,AttachmentImage4 AS attachment_image4 
				FROM tbl_Master_shop WHERE Shop_CreateUser=@USER_ID AND Shop_Code=@SHOP_ID
			END

	SET NOCOUNT OFF
END