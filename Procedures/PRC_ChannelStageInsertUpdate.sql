IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_ChannelStageInsertUpdate]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_ChannelStageInsertUpdate] AS'  
 END 
 GO 

ALTER PROCEDURE [PRC_ChannelStageInsertUpdate]
(
@chnlID Int=0,
@Stagelist NVARCHAR(MAX)=NULL,
@USER_ID BIGINT=NULL
) 
AS
/***********************************************************************************
1.0			v2.0.32			Pratik		10-08-2022			CREATE PROCEDURE
************************************************************************************/
BEGIN
	
	DECLARE @SQLSTRTABLE NVARCHAR(MAX)
	IF OBJECT_ID('TEMPDB..#Stagelist') IS NOT NULL
		DROP TABLE #Stagelist
	CREATE TABLE #Stagelist (Stage NVARCHAR(10) COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS)
	CREATE NONCLUSTERED INDEX Stage ON #Stagelist (Stage ASC)
	IF @Stagelist<>''
	BEGIN
		SET @Stagelist = REPLACE(''''+@Stagelist+'''',',',''',''')
		SET @SQLSTRTABLE=''
		SET @SQLSTRTABLE=' Insert Into #Stagelist select StageID from FTS_Stage WHERE StageID IN('+@Stagelist+')'
		EXEC SP_EXECUTESQL @SQLSTRTABLE
	END
	IF NOT EXISTS(SELECT * FROM FTS_ChannelDSTypeMap WHERE ChannelId=@chnlID)
	BEGIN
		INSERT INTO FTS_ChannelDSTypeMap (ChannelId,StageID,CREATEDBY,CREATEDON)
		SELECT @chnlID,Stage,@USER_ID,GETDATE() FROM #Stagelist
	END
	ELSE
	BEGIN

		DELETE FROM FTS_ChannelDSTypeMap WHERE ChannelId=@chnlID

		INSERT INTO FTS_ChannelDSTypeMap (ChannelId,StageID,CREATEDBY,CREATEDON)
		SELECT @chnlID,Stage,@USER_ID,GETDATE() FROM #Stagelist
	END
	
	DROP TABLE #Stagelist
END


GO
