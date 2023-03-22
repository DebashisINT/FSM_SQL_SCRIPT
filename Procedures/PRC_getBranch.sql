--Exec PRC_getBranch 1

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_getBranch]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_getBranch] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_getBranch]
(
	@ParentBranchID AS BIGINT
)  --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by Sanchita on 22/03/2023 for V2.0.39		Optimized Login by User "Admin".Refer: 0024716
****************************************************************************************************************************************************************************/
BEGIN
	Declare @strBranchList NVarchar(Max)
	
	IF OBJECT_ID('tempdb..#Branches') IS NOT NULL
		Drop Table #Branches
	CREATE TABLE #Branches
	(
		branch_id Varchar(100),
		branch_parentId Varchar(100)
	);
	CREATE NONCLUSTERED INDEX [IDXMGRID] ON [#Branches] ([branch_parentId])
	
	Insert into #Branches
	Select branch_id, branch_parentId from tbl_master_branch --where branch_parentId=@ParentBranchID

	
	;WITH Branches_Subtree(branch_id,branch_parentId, lvl)
	  AS
	  ( 
		-- Anchor Member (AM)
		SELECT branch_id,branch_parentId, 0
		FROM #Branches
		WHERE branch_parentId=@ParentBranchID

		UNION all
	    
		-- Recursive Member (RM)
		SELECT  b.branch_id,b.branch_parentId, bs.lvl+1
		FROM #Branches AS b
		  JOIN Branches_Subtree AS bs
			ON b.branch_parentId = bs.branch_id    
	  ) 
	Select @strBranchList=coalesce(@strBranchList + ', ', '') + Convert(varchar,branch_id) from tbl_master_branch 
	Where branch_id in (Select distinct branch_id FROM Branches_Subtree )

	select isnull(@strBranchList,'')+','

	Drop Table #Branches

END