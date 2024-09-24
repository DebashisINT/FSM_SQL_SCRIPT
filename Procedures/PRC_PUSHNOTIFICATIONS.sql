

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_PUSHNOTIFICATIONS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_PUSHNOTIFICATIONS] AS' 
END
GO
ALTER Proc [dbo].[PRC_PUSHNOTIFICATIONS]
@Action varchar(100)=NULL,
@USERID int=0,
@MobileNO nvarchar(50)=NULL
As
/*********************************************************************************************************************************************
Written by : Priti Roy ON 23/09/2024
0027698: Customization work of New Order Status Update module
*******************************************************************************************************************************************/

Begin
Declare @user_contactId nvarchar(100)='', @emp_reportTo int=0,@emp_contactId nvarchar(100)=''

If(@Action='GETDATA')
BEGIN
	
	select @user_contactId=user_contactId from tbl_master_user  where user_id=@USERID
	select @emp_reportTo=emp_reportTo from tbl_trans_employeeCTC where emp_cntId=@user_contactId
	select @emp_contactId=emp_contactId from tbl_master_employee  where emp_id=@emp_reportTo
	



	select user_id,user_loginId,user_name from tbl_master_user  where user_id=@USERID
	Union All
	select user_id,user_loginId,user_name from tbl_master_user where user_contactId=@emp_contactId

	select JSONFILE_NAME, PROJECT_NAME from FSM_CONFIG_FIREBASENITIFICATION WHERE ID=1
	
END
else If(@Action='GETDEVICETOKEN')
BEGIN
	select  device_token,musr.user_name,musr.user_id  from tbl_master_user as musr 
	inner join tbl_FTS_devicetoken as token on musr.user_id=token.UserID  
	where musr.user_loginId=@MobileNO and musr.user_inactive='N'
end

End
