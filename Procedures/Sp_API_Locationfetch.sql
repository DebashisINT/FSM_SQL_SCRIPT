--EXEC Sp_API_Locationfetch @user_id=11722,@from_date

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_API_Locationfetch]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_API_Locationfetch] AS'  
 END 
 GO

ALTER  Proc  [dbo].[Sp_API_Locationfetch]
(
@user_id int =NULL,
@from_date varchar(50)=NULL,
@to_date varchar(50) =NULL,
@date_span int =NULL
) --WITH ENCRYPTION
As
/****************************************************************************************************************
1.0			TANMOY		20-01-2020		SEND EXTRA OUTPUT metting_attended
2.0			TANMOY		09-12-2020		SEND EXTRA OUTPUT StaticDistance
****************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @visit_distance NVARCHAR(10)

	SET @visit_distance=(SELECT TOP(1)StaticDistance FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE CAST(Work_datetime AS DATE) BETWEEN @from_date AND @to_date AND User_Id=@user_id)

	if(isnull(@date_span,0) =0)
		BEGIN
			SELECT DISTINCT location_name,Lat_visit as latitude,Long_visit as longitude,distance_covered,Stime as last_update_time,SDate as [date]
			,shops_covered, @from_date as frmdt,@to_date as todt,FORMAT(Sdate,'hh:mm tt') as onlytime
			--REV 1.0 START metting_attended AS
			, meeting_attended
			--REV 1.0 END
			--REV 2.0 START
			,CONVERT(NVARCHAR(10),isnull(@visit_distance,'')) AS visit_distance
			--REV 2.0 end
			,ISNULL(network_status,'') network_status,ISNULL(battery_percentage,'') battery_percentage
			from tbl_trans_shopuser WITH(NOLOCK) 
			where cast(SDate as date) BETWEEN @from_date and @to_date
			and User_Id=@user_id
			UNION  ALL
			SELECT DISTINCT location_name,Lat_visit as latitude,Long_visit as longitude,distance_covered,Stime as last_update_time,SDate as [date]
			,shops_covered, @from_date as frmdt,@to_date as todt,FORMAT(Sdate,'hh:mm tt') as onlytime
			--REV 1.0 START metting_attended AS
			, meeting_attended
			--REV 1.0 END
			--REV 2.0 START
			,CONVERT(NVARCHAR(10),isnull(@visit_distance,'')) AS visit_distance
			--REV 2.0 end
			,ISNULL(network_status,'') network_status,ISNULL(battery_percentage,'') battery_percentage
			from TBL_TRANS_SHOPUSER_ARCH WITH(NOLOCK) 
			where cast(SDate as date) between @from_date and @to_date
			and User_Id=@user_id
			order by SDate 
		END
	ELSE
		BEGIN
			SELECT DISTINCT location_name,Lat_visit as latitude,Long_visit as longitude,distance_covered,Stime as last_update_time,SDate as [date]
			,shops_covered,DateAdd(DAY,-30,convert(date,GETDATE())) as frmdt,convert(date,GETDATE()) as todt 
			,FORMAT(Sdate,'hh:mm tt') as onlytime
			--REV 1.0 START metting_attended AS
			, meeting_attended
			--REV 1.0 END
			--REV 2.0 START
			,CONVERT(NVARCHAR(10),isnull(@visit_distance,'')) AS visit_distance
			--REV 2.0 end
			,ISNULL(network_status,'') network_status,ISNULL(battery_percentage,'') battery_percentage
			 from tbl_trans_shopuser WITH(NOLOCK) 
			where cast(SDate as date) between  DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE())
			and User_Id=@user_id
			UNION ALL
			SELECT DISTINCT location_name,Lat_visit as latitude,Long_visit as longitude,distance_covered,Stime as last_update_time,SDate as [date]
			,shops_covered,DateAdd(DAY,-30,convert(date,GETDATE())) as frmdt,convert(date,GETDATE()) as todt 
			,FORMAT(Sdate,'hh:mm tt') as onlytime
			--REV 1.0 START  metting_attended AS
			, meeting_attended
			--REV 1.0 end
			--REV 2.0 START
			,CONVERT(NVARCHAR(10),isnull(@visit_distance,'')) AS visit_distance
			--REV 2.0 end
			,ISNULL(network_status,'') network_status,ISNULL(battery_percentage,'') battery_percentage
			 from TBL_TRANS_SHOPUSER_ARCH WITH(NOLOCK) 
			where cast(SDate as date) between  DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE())
			and User_Id=@user_id
			order by SDate 
		END

	SET NOCOUNT OFF
END