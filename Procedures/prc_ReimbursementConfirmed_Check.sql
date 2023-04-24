IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_ReimbursementConfirmed_Check]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_ReimbursementConfirmed_Check] AS' 
END
GO

ALTER PROCEDURE [dbo].[prc_ReimbursementConfirmed_Check]
(
@ACTION NVARCHAR(200)=NULL,
@APPLICATIONID_LIST NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Sanchita on 24/04/2023		for		V2.0.40		
In TRAVELLING ALLOWANCE -- Approve/Reject Page: One Coloumn('Confirm/Reject') required before 'Approve/Reject' coloumn.
'Confirm/Reject' function will be working same as 'Approve/Reject' Function. refer: 25809
****************************************************************************************************************************************************************************/
BEGIN
	
	IF(@ACTION='CONFIRMED_CHECK')
	BEGIN
		DECLARE @ApplId NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

		SET @ApplId = ''''+REPLACE(@APPLICATIONID_LIST,'|',''',''')+''''

		SET @sqlStrTable = ''
		SET @sqlStrTable='SELECT COUNT(0) CNT_NOTCONF FROM FTS_Reimbursement_Application WHERE ApplicationID IN ('+@ApplId+') AND isnull(Confirm_Reimbursement,0)=0 '
		EXEC SP_EXECUTESQL @sqlStrTable

	END
END