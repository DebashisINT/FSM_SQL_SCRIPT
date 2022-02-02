--EXEC PRC_APIUSERIMEICLEAR

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIUSERIMEICLEAR]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIUSERIMEICLEAR] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIUSERIMEICLEAR]
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 02/02/2022
Purpose : For User IMEI Clear.
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DELETE FROM tbl_User_IMEI WHERE EXISTS(SELECT USR.USER_ID FROM tbl_master_user USR WHERE tbl_User_IMEI.UserId=USR.USER_ID AND IsIMEICheck=0)

	SET NOCOUNT OFF
END