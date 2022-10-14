IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_UserLoginMIS]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_UserLoginMIS] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[Proc_UserLoginMIS]
(
@userName NVARCHAR(MAX),
@password NVARCHAR(MAX),
@Imei_no NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF EXISTS(select user_id from tbl_master_user WITH(NOLOCK) where user_loginId=@userName and user_password=@password)
		BEGIN
			select cont.cnt_firstName+' '+cont.cnt_lastName as UserName,usr.user_id as UserId,usr.user_name,brnch.branch_description as Branch 
			from tbl_master_user as usr WITH(NOLOCK) 
			INNER JOIN tbl_master_contact as cont WITH(NOLOCK) on usr.user_contactId=cont.cnt_internalId
			INNER JOIN tbl_master_branch as brnch WITH(NOLOCK) on usr.user_branchId=brnch.branch_id
			where user_loginId=@userName and user_password=@password 
		END
	
	SET NOCOUNT OFF
END