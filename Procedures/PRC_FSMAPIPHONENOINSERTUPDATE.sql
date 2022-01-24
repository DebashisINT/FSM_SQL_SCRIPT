IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMAPIPHONENOINSERTUPDATE]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMAPIPHONENOINSERTUPDATE] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FSMAPIPHONENOINSERTUPDATE]
(
@ACTION NVARCHAR(100)=NULL,
@session_token NVARCHAR(MAX)=NULL,
@USER_ID NVARCHAR(50)=NULL,
@USER_CONTACTID NVARCHAR(50)=NULL,
@PHONE_NO NVARCHAR(500)=NULL,
@OLD_PHONE_NO NVARCHAR(500)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************
Written By : Debashis Talukder On 18/01/2022
Purpose : For Insert & Update Phone No.Row No: 611 & 612
****************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='INSERTPHNO'
		BEGIN
			INSERT INTO tbl_master_phonefax(phf_cntId,phf_entity,phf_type,phf_phoneNumber,CreateDate,CreateUser)
			SELECT @USER_CONTACTID,'employee','Office',@PHONE_NO,GETDATE(),@USER_ID

			SELECT phf_cntId,phf_entity,phf_type,phf_phoneNumber,CreateDate,CreateUser FROM tbl_master_phonefax WHERE phf_cntId=@USER_CONTACTID AND phf_entity='employee'
			AND phf_type='Office' AND phf_phoneNumber=@PHONE_NO
		END
	IF @ACTION='UPDATEPHNO'
		BEGIN
			UPDATE tbl_master_phonefax SET phf_phoneNumber=@PHONE_NO,LastModifyDate=GETDATE(),LastModifyUser=@USER_ID WHERE phf_cntId=@USER_CONTACTID AND phf_entity='employee' AND phf_type='Office' 
			AND phf_phoneNumber=@OLD_PHONE_NO

			SELECT phf_cntId,phf_entity,phf_type,phf_phoneNumber,CreateDate,CreateUser FROM tbl_master_phonefax WHERE phf_cntId=@USER_CONTACTID AND phf_entity='employee'
			AND phf_type='Office' AND phf_phoneNumber=@PHONE_NO
		END

	SET NOCOUNT OFF
END