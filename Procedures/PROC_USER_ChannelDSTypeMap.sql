IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_USER_ChannelDSTypeMap]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_USER_ChannelDSTypeMap] AS' 
END
GO
ALTER PROC [PROC_USER_ChannelDSTypeMap]
(
@CHNLID VARCHAR(100)
)  
AS
/******************************************************************************************************************************
1.0		v2.0.32		Pratik		10-08-2022			CREATE SP 
******************************************************************************************************************************/
BEGIN
	select FS.StageID,FS.Stage,case when ISNULL(CDTM.ChannelId,'')='' then CAST(0 AS BIT) else CAST(1 AS BIT) END AS IsChecked
	from FTS_Stage as FS 
	LEFT OUTER JOIN FTS_ChannelDSTypeMap AS CDTM ON FS.StageID=CDTM.StageID
	where FS.StageID not in (select FDM.StageID from FTS_ChannelDSTypeMap as FDM where FDM.ChannelId<>@CHNLID)	
END