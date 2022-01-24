--EXEC PRC_APICHECKSHOPDUPLICATERECORDS 'DUPLICATEPHNO',11986,'6868242408'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APICHECKSHOPDUPLICATERECORDS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APICHECKSHOPDUPLICATERECORDS] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APICHECKSHOPDUPLICATERECORDS]
(
@ACTION NVARCHAR(20),
@user_id BIGINT=NULL,
@SHOPPHNO NVARCHAR(100)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************
Written By : Debashis Talukder On 02/11/2021
Purpose : For Shop Duplicate Records check.
****************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='DUPLICATEPHNO'
		BEGIN
			IF EXISTS(SELECT Shop_Owner_Contact FROM tbl_Master_shop WHERE Shop_Owner_Contact=@SHOPPHNO)
				SELECT 1
		END

	SET NOCOUNT OFF
END