IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APISENDAUTOMAILINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APISENDAUTOMAILINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APISENDAUTOMAILINFO]
--WITH ENCRYPTION
AS
/****************************************************************************************************************
Written By : Debashis Talukder On 03/04/2024
Purpose : For Send Auto Mail.Row: 913
****************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	SELECT ID,AUTOMAIL_SENDING_EMAIL AS automail_sending_email,AUTOMAIL_SENDING_PASS AS automail_sending_pass,RECIPIENT_EMAIL_IDS AS recipient_email_ids FROM FSMAPIAUTOMAIL

	SET NOCOUNT OFF
END
GO