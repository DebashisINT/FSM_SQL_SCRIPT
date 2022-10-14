IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_RouteList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_RouteList] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_FTS_RouteList]
(
@User_Id NVARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	select distinct 'Route '+(Pincode) as Routename ,Pincode from tbl_Master_shop WITH(NOLOCK) 
	where  Shop_CreateTime between  DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE()) and Shop_CreateUser=@User_Id

	select Pincode,Shop_Code as shop_id,Address  as shop_address,Shop_Name  as shop_name,Shop_Owner_Contact as shop_contact_no  
	from tbl_Master_shop WITH(NOLOCK) where Shop_CreateTime between  DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE()) and Shop_CreateUser=@User_Id

	SET NOCOUNT OFF
END