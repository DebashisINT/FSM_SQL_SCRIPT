--exec [Proc_Route_Login] 11986

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_Route_Login]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_Route_Login] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_Route_Login]
(
@UserID varchar(50)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.37		22-12-2022		Debashis	A new table introduced.Row: 781
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT 'Route '+(Pincode) as Routename ,Pincode from tbl_Master_shop WITH(NOLOCK) 
	INNER JOIN tbl_fts_UserAttendanceLoginlogout AS loginlogout WITH(NOLOCK) ON tbl_Master_shop.Shop_CreateUser=loginlogout.User_Id
	INNER JOIN tbl_attendance_Route AS attenroute WITH(NOLOCK) on loginlogout.Id=attenroute.attendanceid and tbl_Master_shop.Pincode=attenroute.RouteID
	where 
	cast(Work_datetime as date)=convert(date,GETDATE())  and loginlogout.User_Id=@UserId 
	UNION ALL 
	SELECT 'Other' as Routename,'' as Pincode 
	FROM tbl_fts_UserAttendanceLoginlogout AS loginlogout WITH(NOLOCK) 
	INNER JOIN tbl_attendance_Route as attenroute WITH(NOLOCK) ON loginlogout.Id=attenroute.attendanceid 
	where  cast(loginlogout.Work_datetime as date)=convert(date,GETDATE()) and  loginlogout.User_Id=@UserId and attenroute.RouteID like '%~Other'
	UNION ALL 
	select distinct 'Sales Visit' as Routename, SR.SHOPPIN as Pincode from FTS_SHOP_REVISIT SR WITH(NOLOCK) 
	INNER JOIN tbl_master_user MU WITH(NOLOCK) ON MU.user_loginId=CONVERT(varchar(50),SR.LOGIN_ID)
	WHERE MU.user_id=@UserId and cast(SR.REVISITDATE as date)=cast(getdate() as date)

	select Pincode,Shop_Code as shop_id,Address  as shop_address,Shop_Name  as shop_name,Shop_Owner_Contact as shop_contact_no   
	from tbl_Master_shop WITH(NOLOCK) 
	INNER JOIN tbl_fts_UserAttendanceLoginlogout as loginlogout WITH(NOLOCK) on tbl_Master_shop.Shop_CreateUser=loginlogout.User_Id
	INNER JOIN tbl_attendance_Route as attenroute WITH(NOLOCK) on loginlogout.Id=attenroute.attendanceid and tbl_Master_shop.Pincode=attenroute.RouteID
	INNER JOIN tbl_attendance_RouteShop as routeshp WITH(NOLOCK) on loginlogout.Id=routeshp.attendanceid and routeshp.ShopID=tbl_Master_shop.Shop_Code
	where   cast(Work_datetime as date)=convert(date,GETDATE()) and loginlogout.User_Id=@UserId
	UNION ALL
	select routeshp.RouteID as Pincode,'Other' as shop_id,'' as  shop_address,'Other'  shop_name,'' as shop_contact_no   
	from tbl_fts_UserAttendanceLoginlogout as loginlogout WITH(NOLOCK) 
	INNER JOIN tbl_attendance_Route as attenroute WITH(NOLOCK) on loginlogout.Id=attenroute.attendanceid
	INNER JOIN tbl_attendance_RouteShop as routeshp WITH(NOLOCK) on loginlogout.Id=routeshp.attendanceid and  attenroute.RouteID=routeshp.RouteID 
	where cast(Work_datetime as date)=convert(date,GETDATE()) and loginlogout.User_Id=@UserId and routeshp.ShopID like '%~New~%'

	select WrkActvtyDescription as name,WorkActivityID as id from tbl_FTS_WorkActivityList WITH(NOLOCK) 
	INNER JOIN tbl_attendance_worktype as wrktype WITH(NOLOCK) on tbl_FTS_WorkActivityList.WorkActivityID=wrktype.worktypeID 
	INNER JOIN tbl_fts_UserAttendanceLoginlogout as loginlogout WITH(NOLOCK) on wrktype.attendanceid=loginlogout.Id
	where cast(Work_datetime as date)=convert(date,GETDATE()) and loginlogout.User_Id=@UserId

	SELECT SHOPPIN as Pincode,CONVERT(VARCHAR(50),MS.Shop_Code) AS 'shop_id',SR.SHOP_ADDRESS AS 'shop_address',SR.SHOP_NAME AS 'shop_name', CONVERT(VARCHAR(50),SR.SHOP_CONTACT) AS 'shop_contact_no'
	FROM FTS_SHOP_REVISIT SR WITH(NOLOCK) 
	INNER JOIN tbl_master_user MU WITH(NOLOCK) ON MU.user_loginId=CONVERT(varchar(50),SR.LOGIN_ID)
	INNER JOIN tbl_Master_shop MS WITH(NOLOCK) ON MS.Shop_ID=SR.SHOP_ID
	WHERE MU.user_id=@UserId and cast(SR.REVISITDATE as date)=cast(getdate() as date)

	--Rev 1.0
	SELECT ISNULL(loginlogout.JointVisitTeam_MemberName,'') AS JointVisitSelectedUserName,JointVisitTeam_Member_User_ID,ISNULL(MEMP.emp_uniqueCode,'') AS JointVisit_Employee_Code,
	MEMP.emp_contactId FROM tbl_fts_UserAttendanceLoginlogout loginlogout
	LEFT OUTER JOIN tbl_master_user JUSR ON loginlogout.JointVisitTeam_Member_User_ID=JUSR.user_id
	INNER JOIN tbl_master_employee MEMP ON JUSR.user_contactId=MEMP.emp_contactId
	WHERE loginlogout.User_Id=@UserID and cast(Work_datetime as date)=convert(date,GETDATE())
	AND Logout_datetime IS NULL
	--End of Rev 1.0

	SET NOCOUNT OFF
END