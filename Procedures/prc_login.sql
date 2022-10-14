IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_login]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_login] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[prc_login]
(
@username NVARCHAR(max),
@password NVARCHAR(max)
) --WITH ENCRYPTION
AS
	SET NOCOUNT ON

	if((select count(0) from tbl_mASTER_USER WITH(NOLOCK) where user_loginid=@username and user_password=@password ) > 0)
		BEGIN
			DECLARE @userid bigint
			DECLARE @userbranchid bigint
			DECLARE @usercontactid NVARCHAR(max)
			DECLARE @LastCompany NVARCHAR(max)
			DECLARE @LastFY NVARCHAR(max)
			DECLARE @user_group bigint 
			DECLARE @str NVARCHAR(1000)

			select @userid=user_id,@userbranchid=user_branchid ,@usercontactid=user_contactId,@user_group=user_group from tbl_mASTER_USER WITH(NOLOCK) where user_loginid=@username and user_password=@password;
			select @LastCompany=ls_lastCompany,@LastFY=ls_lastFinYear from tbl_trans_LastSegment WITH(NOLOCK) where ls_cntid=@usercontactid;

			WITH CTE1 
			AS(
			SELECT cast(branch_id as nvarchar(20))branch_id,branch_description,branch_parentId, 1 RecursiveCallNumber  FROM tbl_master_Branch WITH(NOLOCK) WHERE branch_id=@userbranchid
			UNION ALL
			SELECT cast(E.branch_id as Nvarchar(20)),E.branch_description,E.branch_parentId,RecursiveCallNumber+1 RecursiveCallNumber FROM tbl_master_Branch E WITH(NOLOCK) 
			INNER JOIN CTE1 ON E.branch_parentId=CTE1.branch_id)
			SELECT @str= coalesce(@str + ', ', '') +cast(branch_id as varchar(50)) FROM CTE1;
			select @userid UserId,@username UserName, @userbranchid UserBranch,@LastCompany CompanyId,@LastFY FinYear,@str BranchHierarchy

			SELECT branch_id FROM tbl_master_branch WITH(NOLOCK) 
			WHERE branch_parentId=(SELECT branch_parentId FROM tbl_master_branch where branch_id=@userbranchid and branch_parentId<>0);
 
		END 
	SET NOCOUNT OFF
        --public  int UserId { get; set; }
        --public  string UserName { get; set; }
        --public  int UserBranch { get; set; }
        --public  string CompanyId { get; set; }
        --public  string BranchHierarchy { get; set; }
