IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIUSERINFOUPDATE]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIUSERINFOUPDATE] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIUSERINFOUPDATE]
(
@Action NVARCHAR(100),
@USER_ID BIGINT=NULL,
@UPDATED_NAME NVARCHAR(500)=NULL,
@UPDATED_FIRST_NAME NVARCHAR(500)=NULL,
@UPDATED_MIDDLE_NAME NVARCHAR(500)=NULL,
@UPDATED_LAST_NAME NVARCHAR(500)=NULL,
@UPDATED_BY_USER_ID BIGINT=NULL,
@UPDATION_DATE_TIME NVARCHAR(50)=NULL,
--Rev 1.0
@USERINTERNALID NVARCHAR(100)=NULL,
@USERNEWLOGINID NVARCHAR(50)=NULL,
@OTHERID NVARCHAR(300)=NULL
--End of Rev 1.0
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written by : Debashis Talukder on 15/02/2022
Module	   : Update User Information.Row : 645
1.0		v2.0.27		Debashis	08-03-2022		New Action added.Row No: 666 & 667
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @Action='UPDATEUSERNAME'
		BEGIN
			IF EXISTS(SELECT USER_ID FROM tbl_master_user WHERE USER_ID=@USER_ID)
				BEGIN
					UPDATE tbl_master_user SET user_name=@UPDATED_NAME,LastModifyUser=@UPDATED_BY_USER_ID,LastModifyDate=@UPDATION_DATE_TIME WHERE USER_ID=@USER_ID

					UPDATE CNT SET cnt_firstName=@UPDATED_FIRST_NAME,cnt_middleName=@UPDATED_MIDDLE_NAME,cnt_lastName=@UPDATED_LAST_NAME FROM TBL_MASTER_CONTACT CNT
					INNER JOIN tbl_master_user USR ON CNT.cnt_internalId=USR.user_contactId
					WHERE USR.USER_ID=@USER_ID AND CNT.cnt_contactType='EM'

					SELECT USER_ID,user_name FROM tbl_master_user WHERE USER_ID=@USER_ID
				END
		END
	--Rev 1.0
	IF @Action='UPDATEUSERLOGINID'
		BEGIN
			IF EXISTS(SELECT USER_ID FROM tbl_master_user WHERE USER_ID=@USER_ID)
				BEGIN
					IF EXISTS(SELECT USER_ID FROM tbl_master_user WHERE user_loginId=@USERNEWLOGINID)
						SELECT 'Duplicate' AS STRMESSAGE
					IF NOT EXISTS(SELECT USER_ID FROM tbl_master_user WHERE user_loginId=@USERNEWLOGINID)
						BEGIN
							UPDATE tbl_master_user SET user_loginId=@USERNEWLOGINID WHERE USER_ID=@USER_ID
							
							SELECT 'Unique' AS STRMESSAGE
						END
				END
		END
	IF @Action='UPDATEUSEROTHERID'
		BEGIN
			IF EXISTS(SELECT cnt_internalId FROM tbl_master_contact WHERE cnt_internalId=@USERINTERNALID)
				BEGIN
					UPDATE tbl_master_contact SET cnt_OtherID=@OTHERID WHERE cnt_internalId=@USERINTERNALID

					UPDATE tbl_master_employee SET cnt_OtherID=@OTHERID WHERE emp_contactId=@USERINTERNALID

					SELECT 'Update' AS STRMESSAGE
				END
		END
	--End of Rev 1.0
	SET NOCOUNT OFF
END