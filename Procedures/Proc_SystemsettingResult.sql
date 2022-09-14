IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_SystemsettingResult]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_SystemsettingResult] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_SystemsettingResult]
(
@VariableName NVARCHAR(200)=null
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder On 14/09/2022
Module	   : Userwise branch detection facility shall be available in the login session as like ERP.Refer: 0025209
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

		SELECT [Value] AS Variable_Value FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]=@VariableName AND IsActive=1
	
	SET NOCOUNT OFF
END