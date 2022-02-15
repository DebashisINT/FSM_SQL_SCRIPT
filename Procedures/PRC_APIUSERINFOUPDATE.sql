IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIUSERINFOUPDATE]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIUSERINFOUPDATE] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIUSERINFOUPDATE]
(
@Action NVARCHAR(100),
@USER_ID BIGINT,
@UPDATED_NAME NVARCHAR(500)=NULL,
@UPDATED_FIRST_NAME NVARCHAR(500)=NULL,
@UPDATED_MIDDLE_NAME NVARCHAR(500)=NULL,
@UPDATED_LAST_NAME NVARCHAR(500)=NULL,
@UPDATED_BY_USER_ID BIGINT=NULL,
@UPDATION_DATE_TIME NVARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written by : Debashis Talukder on 15/02/2022
Module	   : Update User Information.Row : 645
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
	SET NOCOUNT OFF
END