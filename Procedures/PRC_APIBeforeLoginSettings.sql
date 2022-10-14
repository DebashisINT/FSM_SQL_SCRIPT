--EXEC PRC_APIBeforeLoginSettings @userName='8336901708',@password='mpcBb4q+5Dj/igo5ESszqw=='

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIBeforeLoginSettings]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIBeforeLoginSettings] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIBeforeLoginSettings]
(
@userName nvarchar(100),
@password nvarchar(max)
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @Isattendance BIT =0
	DECLARE @UserId BIGINT
	IF EXISTS (SELECT user_id FROM tbl_master_user AS usr WITH(NOLOCK) WHERE user_loginId=@userName and user_password=@password and user_inactive='N')
	BEGIN
			SET @UserId=(SELECT user_id FROM tbl_master_user AS usr WITH(NOLOCK) WHERE user_loginId=@userName and user_password=@password and user_inactive='N')

			IF EXISTS(SELECT User_Id FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE User_Id=@UserId and Login_datetime IS NOT NULL
			AND CAST(Login_datetime AS DATE)=CAST(GETDATE() AS DATE))
			BEGIN
				set @Isattendance=1
			END

		SELECT ISNULL(@Isattendance,0) AS isAddAttendence,ISNULL(isFingerPrintMandatoryForAttendance,0) AS isFingerPrintMandatoryForAttendance,
		ISNULL(isFingerPrintMandatoryForVisit,0) AS isFingerPrintMandatoryForVisit,ISNULL(isSelfieMandatoryForAttendance,0) AS isSelfieMandatoryForAttendance
		FROM tbl_master_user AS usr WITH(NOLOCK) WHERE user_loginId=@userName and user_password=@password and user_inactive='N'
	END

	SET NOCOUNT OFF
END