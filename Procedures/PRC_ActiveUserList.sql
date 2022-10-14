IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_ActiveUserList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_ActiveUserList] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_ActiveUserList]
AS
BEGIN
	SET NOCOUNT ON

	select Convert(Nvarchar(10),user_id) as User_ID,user_name as User_Name,
	user_loginId as User_LoginID,user_contactId as InternalID from tbl_master_user WITH(NOLOCK) where user_inactive='N'

	SET NOCOUNT OFF
END