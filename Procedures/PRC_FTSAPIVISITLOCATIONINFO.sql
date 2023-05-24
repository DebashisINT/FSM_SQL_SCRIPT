IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPIVISITLOCATIONINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPIVISITLOCATIONINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSAPIVISITLOCATIONINFO]
(
@ACTION NVARCHAR(50)
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 17/05/2023
Purpose : For Visit Location Informations.
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='VISITLOCATIONLIST'
		BEGIN
			SELECT Id AS id,Visit_Location AS visit_location FROM FTS_Visit_Location
		END

	SET NOCOUNT OFF
END