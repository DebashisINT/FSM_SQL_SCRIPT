

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTS_Branch]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTS_Branch] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTS_Branch]
(
@Action NVARCHAR(50)=NULL,
@StateId nvarchar(MAX)=NULL
) 
--WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : PRITI on 19-05-2023. Refer: 
0026145: Modification in the ‘Configure Travelling Allowance’ page.
****************************************************************************************************************************************************************************/
BEGIN

	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	CREATE TABLE #StateID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #StateID_LIST (State_Id ASC)

	IF(@Action='AllBranch')
	BEGIN
			--SELECT A.BRANCH_ID,A.BRANCH_DESCRIPTION AS CODE FROM TBL_MASTER_BRANCH A

			IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#StateID_LIST') AND TYPE IN (N'U'))
			DROP TABLE #StateID_LIST


		
		--SELECT A.BRANCH_ID,A.BRANCH_DESCRIPTION AS CODE FROM TBL_MASTER_BRANCH A
		-- WHERE EXISTS (SELECT id from tbl_master_state state where id in(8,28,16)  and state.id=A.branch_state)
		IF @StateId <> ''
		BEGIN
			SET @StateId=REPLACE(@StateId,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #StateID_LIST SELECT id from tbl_master_state where id in('+@StateId+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		if(isnull(@StateId,'')<>'')
		BEGIN
			SET @Strsql='SELECT A.BRANCH_ID,A.BRANCH_DESCRIPTION AS CODE FROM TBL_MASTER_BRANCH A '		
			SET  @Strsql +='  WHERE EXISTS (select State_Id from #StateID_LIST state where state.State_Id=A.branch_state)'
			SET  @Strsql +='  order by BRANCH_DESCRIPTION'
		END
		Else
		Begin
			 select 0 as BRANCH_ID,'' as CODE 
		End

		EXEC SP_EXECUTESQL @Strsql
	End
	SET NOCOUNT OFF
END