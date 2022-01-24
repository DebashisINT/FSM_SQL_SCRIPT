IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_APIFaceImageDetection]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_APIFaceImageDetection] AS' 
END
GO

ALTER PROCEDURE [dbo].[PROC_APIFaceImageDetection]
(
--Rev 2.0
@Action NVARCHAR(100),
--End of Rev 2.0
@USER_ID BIGINT=NULL,
@PathImage NVARCHAR(500)=NULL,
--Rev 1.0
@RegisterDateTime DateTime=NULL,
--End of Rev 1.0
--Rev 2.0
@FaceRegTypeID BIGINT=NULL
--End of Rev 2.0
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 19/07/2021
Purpose : For FaceImageDetection/FaceImage API
1.0		v2.0.24		Debashis	05/08/2021		A new column added as Registration_Datetime.
2.0		v2.0.25		Debashis	13/12/2021		Two new parameters has been added.
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	--Rev 2.0
	IF @Action='FaceImageSave'
		BEGIN
	--End of Rev 2.0
			--Rev 1.0 && A new column added as Registration_Datetime
			UPDATE tbl_master_user SET FaceImage=@PathImage,isFaceRegistered=1,Registration_Datetime=@RegisterDateTime WHERE user_id=@USER_ID

			SELECT user_id,FaceImage,isFaceRegistered,CONVERT(NVARCHAR(10),Registration_Datetime,105)+CONVERT(VARCHAR(5),CAST(Registration_Datetime AS TIME),108) AS Registration_Datetime 
			FROM tbl_master_user WHERE user_id=@USER_ID
	--Rev 2.0
		END
	ELSE IF @Action='FaceRegTypeIDSave'
		BEGIN
			UPDATE tbl_master_user SET FaceRegTypeID=@FaceRegTypeID WHERE user_id=@USER_ID

			SELECT user_id,FaceRegTypeID FROM tbl_master_user WHERE user_id=@USER_ID
		END
	--End of Rev 2.0

	SET NOCOUNT OFF
END