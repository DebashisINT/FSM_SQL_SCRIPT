IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIInsertLoginImage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIInsertLoginImage] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIInsertLoginImage]
(
@userName NVARCHAR(100),
@password NVARCHAR(max),
@IMAGE_NAME NVARCHAR(500)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @USER_ID BIGINT

	IF EXISTS (select user_id from tbl_master_user as usr WITH(NOLOCK) where user_loginId=@userName and user_password=@password and user_inactive='N')
	BEGIN
		SET @USER_ID=(select user_id from tbl_master_user as usr WITH(NOLOCK) where user_loginId=@userName and user_password=@password and user_inactive='N')

		INSERT INTO FTS_LoginImage WITH(TABLOCK)(USER_ID,IMAGE_NAME,Login_DATE)
		VALUES (@USER_ID,@IMAGE_NAME,GETDATE())
	END

	SET NOCOUNT OFF
END