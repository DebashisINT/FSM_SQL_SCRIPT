IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_ApiShopUserLogout]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_ApiShopUserLogout] AS' 
END
GO

ALTER PROCEDURE [dbo].[Sp_ApiShopUserLogout]
(
@user_id NVARCHAR(MAX),
@latitude NVARCHAR(MAX)=NUL,
@longitude NVARCHAR(MAX)=NUL,
@SessionToken NVARCHAR(MAX)=NULL,
@logout_time NVARCHAR(MAX)=NULL,
@location_name NVARCHAR(MAX)=NULL,
@Autologout NVARCHAR(10)=NULL,
@distance NVARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
/*******************************************************************************************************************************************
1.0		TANMOY GHOSH		29-01-2020					UniqueKey CREATE LOGIC CHANGE ADD MILISECOND
2.0		Debashis			26-04-2023		V2.0.46		Added a new field as user_ShopStatus.Row: 927
3.0		Debashis			29-04-2024		V2.0.47		user_shopstatus updation process update.Refer: 0027418
*******************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @InternalID NVARCHAR(50)
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @val NVARCHAR(MAX)
	DECLARE @datefetch DATETIME 

	--if(isnull(@Autologout,'0')='0')

	--SET @datefetch  =CAST(GETDATE() AS datetime2(0))
	--else
	SET @datefetch=@logout_time
	SET @InternalID=(select user_contactId from tbl_master_user WITH(NOLOCK) WHERE user_id=@user_id)
	--1.0 REV START
	--set @SessionToken=right(@SessionToken,10)+convert(varchar(100),@datefetch,109)
	SET @SessionToken=right(@SessionToken,10)+convert(varchar(100),@datefetch,109)+'_'+CONVERT(NVARCHAR(13),REPLACE(REPLACE(CAST(getdate() as time),':',''),'.',''))
	--1.0 REV END
	--Rev Debashis
	DECLARE @IsDatatableUpdateForDashboardAttendanceTab NVARCHAR(100)
	SELECT @IsDatatableUpdateForDashboardAttendanceTab=[Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsDatatableUpdateForDashboardAttendanceTab'
	--End of Rev Debashis

	--Rev 2.0
	--Rev 3.0
	--UPDATE tbl_master_user SET user_ShopStatus=0 WHERE user_id=@user_id AND user_ShopStatus=1
	--End of Rev 3.0
	--End of Rev 2.0

	UPDATE tbl_master_user SET SessionToken=NULL,user_status=0 WHERE user_id=@user_id

	IF(@@ROWCOUNT>0)
		BEGIN
			IF NOT EXISTS(SELECT VisitId FROM tbl_trans_shopuser WITH(NOLOCK) WHERE SDate =@logout_time and User_Id=@user_id and location_name=@location_name)
				BEGIN
					IF EXISTS(SELECT VisitId FROM tbl_trans_shopuser WITH(NOLOCK) WHERE CAST(SDate as date) =cast(@logout_time as date) and User_Id=@user_id)
					BEGIN
						INSERT INTO tbl_trans_shopuser ([User_Id],Lat_visit,Long_visit,sdate,Createddate,location_name,LoginLogout,distance_covered)
						VALUES(@user_id,@latitude,@longitude,@logout_time,@datefetch,@location_name,0,@distance)
					END
				END
			IF EXISTS(SELECT User_Id FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE User_Id=@user_id and Login_datetime is not null and cast(Login_datetime as date)=cast(@datefetch as date))
				BEGIN
					DECLARE @isonleave NVARCHAR(50)=(SELECT TOP 1 Isonleave FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE User_Id=@user_id AND Login_datetime IS NOT NULL 
					AND CAST(Login_datetime AS DATE)=CAST(@datefetch AS DATE) ORDER BY Id)
					
					INSERT INTO tbl_fts_UserAttendanceLoginlogout (User_Id,Login_datetime,Logout_datetime,Latitude,Longitude,Work_datetime,Isonleave) 
					VALUES(@user_id,null,@datefetch,@latitude,@longitude,@datefetch,@isonleave)
				END

			--------------------------Attendane Main table Synchronization------------------------------------------

			--Rev Debashis
			IF @IsDatatableUpdateForDashboardAttendanceTab='1'
				BEGIN
			--End of Rev Debashis
					INSERT INTO tbl_EmpAttendanceDetails (UniqueKey,Emp_InternalId,LogTime)values(@SessionToken,@InternalID,@datefetch)

					IF NOT EXISTS(SELECT Emp_InternalId FROM tbl_Employee_Attendance WITH(NOLOCK) WHERE CONVERT(DATE,Att_Date)=CONVERT(DATE,@datefetch) AND Emp_InternalId=@InternalID)
						BEGIN
							INSERT INTO tbl_Employee_Attendance (UniqueKey,Emp_InternalId,Att_Date,In_Time,Out_Time,UpdatedBy,UpdatedOn,YYMM,Emp_status,Remarks)
							VALUES (@SessionToken,@InternalID,@datefetch,@datefetch,NULL,@user_id,@datefetch,
							RIGHT(DATEPART(yy,@datefetch),2)+RIGHT('00' + CAST(DATEPART(mm, @datefetch) AS varchar(2)), 2),'P','')
						END
					ELSE
						BEGIN
							UPDATE tbl_Employee_Attendance SET Out_Time=@datefetch WHERE CONVERT(DATE,Att_Date)=convert(date,@datefetch) and Emp_InternalId=@InternalID
						END
					IF NOT EXISTS(SELECT Emp_InternalId FROM tbl_EmpWiseAttendanceStatus WITH(NOLOCK) WHERE Emp_InternalId=@InternalID)
						BEGIN
							INSERT INTO tbl_EmpWiseAttendanceStatus (UniqueKey,Emp_InternalId,YYMM)
							VALUES(@SessionToken,@InternalID,right(datepart(yy,@datefetch),2)+ RIGHT('00' + CAST(DATEPART(mm, @datefetch) AS varchar(2)), 2))
						END
			--Rev Debashis
				END
			--End of Rev Debashis
			--set @val='P'
			--set @SQL ='update tbl_fts_userWiseAttendanceStatus set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''''

			--EXEC sp_ExecuteSql @SQL

			--------------------------End  Attendane Main table Synchronization------------------------------------------

			select  'success' as output
		END

	SET NOCOUNT OFF
END
GO