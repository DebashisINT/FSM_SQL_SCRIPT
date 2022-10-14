IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_MIS_ApiShopUserLogin]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_MIS_ApiShopUserLogin] AS'  
END 
GO

ALTER PROCEDURE [dbo].[Proc_MIS_ApiShopUserLogin]
(
@userName NVARCHAR(MAX),
@password NVARCHAR(MAX),
@SessionToken NVARCHAR(MAX)=NULL,
@ImeiNo NVARCHAR(MAX)=NULL,
@company_name NVARCHAR(MAX)=NULL,
@Weburl NVARCHAR(MAX)=NULL,
@Company NVARCHAR(MAX)=NULL,
@version_name NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @val NVARCHAR(MAX)
	DECLARE  @UserId  int
	DECLARE  @Cnt_Id  NVARCHAR(100)
	DECLARE  @User_Type NVARCHAR(MAX)
	DECLARE @branchid int

	DECLARE @InternalID NVARCHAR(50)
	DECLARE @Imeiuser NVARCHAR(100)=NULL
	DECLARE @Imeiexists NVARCHAR(100)=NULL
	DECLARE @attendancecount int=0
	DECLARE @Isattendance NVARCHAR(50)='false'
	DECLARE @add_attendence_time NVARCHAR(50)=''

	set @UserId=(select user_id  from  tbl_master_user as usr WITH(NOLOCK) where  user_loginId=@userName   and user_password=@password and user_inactive='N')
	set @InternalID=(select  user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@UserId)
	set @Imeiuser=(select Imei_No  from tbl_User_IMEI usimei WITH(NOLOCK) where userid=@UserId)
	set @Imeiexists=(select top 1 UserId  from tbl_User_IMEI usimei WITH(NOLOCK) where Imei_No=@ImeiNo order by Id desc)

	SELECT  top 1 cast(user_id as varchar(50)) as [user_id],cnt_firstName+' '+cnt_lastName  as name,phf.phf_phoneNumber as phone_number,addr.add_address1,eml_email as email 
	,@ImeiNo as imeino
	,ver.AppVersionHistory_Number as version_name
	,@Weburl  +saladdr.ProfileImage as profile_image
	,saladdr.Address as [address]
	,saladdr.countryId  as country 
	,saladdr.City as city
	,saladdr.stateid as [state]
	,saladdr.Pincode as pincode
	,'200' as success
	FROM tbl_master_user as usr WITH(NOLOCK)
	LEFT OUTER JOIN [Master_AppVersionUsages] ver WITH(NOLOCK) on  usr.user_id=ver.UserId
	LEFT OUTER JOIN tbl_master_contact  as cont WITH(NOLOCK) on usr.user_contactId=cont.cnt_internalId
	LEFT OUTER JOIN tbl_master_address as addr WITH(NOLOCK) on addr.add_cntId= usr.user_contactId 
	LEFT OUTER JOIN tbl_master_phonefax as phf WITH(NOLOCK) on phf.phf_cntId= usr.user_contactId 
	LEFT OUTER JOIN tbl_master_email as eml WITH(NOLOCK) on eml.eml_internalId= usr.user_contactId 
	LEFT OUTER JOIN tbl_salesman_address as saladdr WITH(NOLOCK) on usr.user_id= saladdr.UserId 
	where user_loginId=@userName  and user_password=@password
	order by  phf.Isdefault desc

	SET NOCOUNT OFF
END