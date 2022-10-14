IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_UserHomeaddress]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_UserHomeaddress] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_FTS_UserHomeaddress]
(
@user_id NVARCHAR(50)=NULL,
@latitude NVARCHAR(300)=NULL,
@longitude NVARCHAR(300)=NULL,
@address NVARCHAR(400)=NULL,
@city NVARCHAR(100)=NULL,
@state NVARCHAR(100)=NULL,
@pincode NVARCHAR(100)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF EXISTS(select HomeLocID from tbl_FTS_userhomeaddress WITH(NOLOCK) where UserID=@user_id)
		BEGIN
			UPDATE tbl_FTS_userhomeaddress WITH(TABLOCK) set Latitude=@latitude,Longitude=@longitude,Address=@address,City=@city,State=@state,Pincode=@pincode where UserID=@user_id
		END
	ELSE
		BEGIN
			INSERT INTO tbl_FTS_userhomeaddress WITH(TABLOCK) (UserID,Latitude,Longitude,Address,City,State,Pincode,CreatedDate)
			values(@user_id,@latitude,@longitude,@address,@city,@state,@pincode,GETDATE())
		END
	if(@@RowCount>0)
		BEGIN
			SELECT 1
		END

	SET NOCOUNT OFF
END