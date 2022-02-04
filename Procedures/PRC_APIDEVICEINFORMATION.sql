--EXEC PRC_APIDEVICEINFORMATION 'DEVICEINFO',11984

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIDEVICEINFORMATION]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIDEVICEINFORMATION] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIDEVICEINFORMATION]
(
@ACTION NVARCHAR(20),
@USER_ID BIGINT=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 28/01/2022
Purpose : For User wise Device Information.Row 628
1.0		v2.0.27		Debashis	04-02-2022		A new Action has been added.Row No: 633
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,ISNULL(cnt_UCC,'') FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	IF @ACTION='DEVICEINFO'
		BEGIN
			SELECT USR.user_id AS user_id_for_token,ISNULL(CNT.CNT_FIRSTNAME,'')+' '+ISNULL(CNT.CNT_MIDDLENAME,'')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'')<>'' THEN ' ' ELSE '' END)+ISNULL(CNT.CNT_LASTNAME,'') AS user_name_for_token,
			DT.device_token,DT.device_type
			FROM tbl_FTS_devicetoken DT
			INNER JOIN tbl_master_user USR ON DT.UserID=USR.user_id
			INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId
			WHERE USR.user_id=@USER_ID
		END
	--Rev 1.0
	IF @ACTION='IMEICLEAR'
		BEGIN
			IF EXISTS(SELECT UserId FROM tbl_User_IMEI WHERE UserId=@USER_ID)
				BEGIN
					SELECT UserId FROM tbl_User_IMEI WHERE UserId=@USER_ID

					DELETE FROM tbl_User_IMEI WHERE UserId=@USER_ID
				END
		END
	--End of Rev 1.0

	DROP TABLE #TEMPCONTACT

	SET NOCOUNT OFF
END