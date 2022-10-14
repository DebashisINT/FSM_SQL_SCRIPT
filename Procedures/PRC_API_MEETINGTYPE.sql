--EXEC PRC_API_MEETINGTYPE @user_id=378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_API_MEETINGTYPE]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_API_MEETINGTYPE] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_API_MEETINGTYPE]
(
@user_id BIGINT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0			TANMOY			20-01-2020		CREATE SP FRO METTING LIST
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	SELECT CAST(MEETING_ID AS NVARCHAR(10)) AS type_id,MEETING_NAME AS type_text FROM FTS_MEETING_TYPE WITH(NOLOCK) WHERE ISACTIVE=1

	SET NOCOUNT OFF
END
