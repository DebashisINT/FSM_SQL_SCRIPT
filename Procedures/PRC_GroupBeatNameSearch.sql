IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_GroupBeatNameSearch]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_GroupBeatNameSearch] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_GroupBeatNameSearch]  
(
@USER_ID BIGINT=0,
@SearchKey varchaR(50) ='',
@OldGroupBeatId INT=0
)  
AS
/*******************************************************************************************************************************************************************************************
1.0			v2.0.32		Pratik		23-08-2022		Group Beat name search
********************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	select top 10 cast(ID as varchar(20)) ID,[NAME],CODE from fsm_groupbeat beat
	where (([NAME] like '%'+@SearchKey+'%') or (CODE like '%'+@SearchKey+'%')) AND ID<>@OldGroupBeatId
		
END