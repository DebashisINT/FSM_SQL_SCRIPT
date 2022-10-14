IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIBEATDETAILSINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIBEATDETAILSINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIBEATDETAILSINFO]
(
@ACTION NVARCHAR(20),
@USER_ID BIGINT=NULL,
@BEAT_DATE DATETIME=NULL,
@BEAT_ID BIGINT=NULL,
@SessionToken NVARCHAR(100)=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 09/08/2022
Purpose : For Beat Information.Row 723 & 724
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='BEATDETLIST'
		BEGIN
			SELECT ATTEN.USER_ID,BH.ID AS beat_id,BH.NAME AS beat_name FROM FSM_GROUPBEAT BH WITH(NOLOCK) 
			INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN WITH(NOLOCK) ON BH.ID=ATTEN.BEAT_ID
			WHERE ATTEN.USER_ID=@USER_ID AND CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),@BEAT_DATE,120)
			AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL
		END
	IF @ACTION='UPDATEBEAT'
		BEGIN
			IF EXISTS(SELECT USER_ID FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE USER_ID=@USER_ID AND CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),@BEAT_DATE,120))
				BEGIN
					UPDATE tbl_fts_UserAttendanceLoginlogout WITH(TABLOCK) SET Beat_ID=@BEAT_ID
					WHERE USER_ID=@USER_ID AND CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),@BEAT_DATE,120)
					AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL 

					SELECT ATTEN.USER_ID,BH.ID AS updated_beat_id,BH.NAME AS beat_name FROM FSM_GROUPBEAT BH WITH(NOLOCK) 
					INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN WITH(NOLOCK) ON BH.ID=ATTEN.BEAT_ID
					WHERE ATTEN.USER_ID=@USER_ID AND CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),@BEAT_DATE,120)
					AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL 
				END
		END

	SET NOCOUNT OFF
END