--EXEC PRC_APIITCDAYWISESHOP @user_id=11986,@from_date='',@to_date='',@date_span=30,@Action=0

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIITCDAYWISESHOP]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIITCDAYWISESHOP] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIITCDAYWISESHOP]
(
@user_id INT=NULL,
@from_date NVARCHAR(50)=NULL,
@to_date NVARCHAR(50)=NULL,
@date_span INT=NULL,
@Action INT=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 19/10/2022
Module	   : ITC Daywise Shop Visit.Refer:Row:749
1.0		v2.0.36		Debashis	08/11/2022		Daywiseshop/ITCRecords days updation to 45 days.Refer: 0025436
2.0		v2.0.43		Debashis	13/12/2023		DB schema name was wrong in ITC Daywiseshop.Refer: 0027100
3.0		v2.0.44		Debashis	02/01/2024		Daywiseshop/ITCRecords for this api there is currently 45 days data limit considering to return list in api.
												Need to modify this 45 days to 16Days.Refer: 0027108
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF(@Action=0)
		BEGIN
			IF(ISNULL(@date_span,0) =0)
				BEGIN
					SELECT SUM(totcount) AS totcount,SUM(avgshop) AS avgshop FROM(
					SELECT ISNULL(COUNT(Shop_Id),0) AS totcount,ISNULL(AVG(ISNULL(total_visit_count,0)),0) AS avgshop FROM [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
					WHERE visited_date BETWEEN @from_date AND @to_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					UNION ALL
					--Rev 2.0
					--SELECT ISNULL(COUNT(Shop_Id),0) AS totcount,ISNULL(AVG(ISNULL(total_visit_count,0)),0) AS avgshop FROM Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
					--WHERE visited_date BETWEEN @from_date AND @to_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					SELECT ISNULL(COUNT(Shop_Id),0) AS totcount,ISNULL(AVG(ISNULL(total_visit_count,0)),0) AS avgshop FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
					WHERE visited_date BETWEEN @from_date AND @to_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					--End of Rev 2.0
					) SHPACT

					SELECT DISTINCT [date] FROM(
					SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date] FROM [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
					WHERE visited_date BETWEEN @from_date AND @to_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					UNION ALL
					--Rev 2.0
					--SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date] FROM Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
					--WHERE visited_date BETWEEN @from_date AND @to_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date] FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
					WHERE visited_date BETWEEN @from_date AND @to_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					--End of Rev 2.0
					) SHPACT

					SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date],CAST(lastactivty.Shop_Id AS VARCHAR(50)) AS shopid,
					CAST(spent_duration AS VARCHAR(50)) AS duration_spent,shop.Shop_Name AS shop_name,shop.Address AS shop_address,visited_date AS visited_date,
					ISNULL(device_model,'') AS device_model,ISNULL(android_version,'') AS android_version,ISNULL(battery,'') AS battery,ISNULL(net_status,'') AS net_status,ISNULL(net_type,'') AS net_type,
					ISNULL(CheckIn_Time,'') AS in_time,ISNULL(CheckOut_Time,'') AS out_time,ISNULL(start_timestamp,'') AS start_timestamp,
					ISNULL(CheckIn_Address,'') AS in_location,ISNULL(CheckOut_Address,'') AS out_location,
					ISNULL(lastactivty.Revisit_Code,'') AS [Key],ISNULL(lastactivty.Ordernottaken_Status,'') AS shop_revisit_status,ISNULL(lastactivty.Ordernottaken_Remarks,'') AS shop_revisit_remarks,
					CONVERT(NVARCHAR(10),ISNULL(lastactivty.Pros_Id,'')) AS pros_id,CONVERT(NVARCHAR(10),ISNULL(lastactivty.Updated_by,'')) AS updated_by,
					ISNULL(CAST(lastactivty.Updated_on AS date),'') AS updated_on,ISNULL(lastactivty.Agency_Name,'') AS agency_name,
					ISNULL(lastactivty.Approximate_1st_Billing_Value,0.00) AS approximate_1st_billing_value
					FROM [tbl_trans_shopActivitysubmit] AS lastactivty WITH(NOLOCK) 
					INNER JOIN tbl_Master_shop AS shop WITH(NOLOCK) ON shop.Shop_Code=lastactivty.Shop_Id
					WHERE visited_date BETWEEN @from_date AND @to_date AND User_Id=@user_id AND ISNULL(lastactivty.ISMEETING,0)=0
					UNION ALL
					SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date],CAST(lastactivty.Shop_Id AS VARCHAR(50)) AS shopid,
					CAST(spent_duration AS VARCHAR(50)) AS duration_spent,shop.Shop_Name AS shop_name,shop.Address AS shop_address,visited_date AS visited_date,
					ISNULL(device_model,'') AS device_model,ISNULL(android_version,'') AS android_version,ISNULL(battery,'') AS battery,ISNULL(net_status,'') AS net_status,ISNULL(net_type,'') AS net_type,
					ISNULL(CheckIn_Time,'') AS in_time,ISNULL(CheckOut_Time,'') AS out_time,ISNULL(start_timestamp,'') AS start_timestamp,
					ISNULL(CheckIn_Address,'') AS in_location,ISNULL(CheckOut_Address,'') AS out_location,
					ISNULL(lastactivty.Revisit_Code,'') AS [Key],ISNULL(lastactivty.Ordernottaken_Status,'') AS shop_revisit_status,ISNULL(lastactivty.Ordernottaken_Remarks,'') AS shop_revisit_remarks,
					CONVERT(NVARCHAR(10),ISNULL(lastactivty.Pros_Id,'')) AS pros_id,CONVERT(NVARCHAR(10),ISNULL(lastactivty.Updated_by,'')) AS updated_by,
					ISNULL(CAST(lastactivty.Updated_on AS date),'') AS updated_on,ISNULL(lastactivty.Agency_Name,'') AS agency_name,
					ISNULL(lastactivty.Approximate_1st_Billing_Value,0.00) AS approximate_1st_billing_value
					--Rev 2.0
					--FROM Trans_ShopActivitySubmit_TodayData AS lastactivty WITH(NOLOCK) 
					FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData AS lastactivty WITH(NOLOCK) 
					--End of Rev 2.0
					INNER JOIN tbl_Master_shop AS shop WITH(NOLOCK) ON shop.Shop_Code=lastactivty.Shop_Id
					WHERE visited_date BETWEEN @from_date AND @to_date AND User_Id=@user_id AND ISNULL(lastactivty.ISMEETING,0)=0
				END
			ELSE
				BEGIN
					SELECT SUM(totcount) AS totcount,SUM(avgshop) AS avgshop FROM(
					SELECT ISNULL(COUNT(Shop_Id),0) AS totcount,ISNULL(AVG(ISNULL(total_visit_count,0)),0) AS avgshop FROM [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
					--Rev 1.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-30,convert(date,GETDATE())) AND convert(date,GETDATE())
					--Rev 3.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-45,convert(date,GETDATE())) AND convert(date,GETDATE())
					WHERE visited_date BETWEEN DateAdd(DAY,-16,convert(date,GETDATE())) AND convert(date,GETDATE())
					--End of Rev 3.0
					--End of Rev 1.0
					AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					UNION ALL
					--Rev 2.0
					--SELECT ISNULL(COUNT(Shop_Id),0) AS totcount,ISNULL(AVG(ISNULL(total_visit_count,0)),0) AS avgshop FROM Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
					----Rev 1.0
					----WHERE visited_date BETWEEN DateAdd(DAY,-30,convert(date,GETDATE())) AND convert(date,GETDATE())
					--WHERE visited_date BETWEEN DateAdd(DAY,-45,convert(date,GETDATE())) AND convert(date,GETDATE())
					SELECT ISNULL(COUNT(Shop_Id),0) AS totcount,ISNULL(AVG(ISNULL(total_visit_count,0)),0) AS avgshop FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
					--Rev 3.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-45,convert(date,GETDATE())) AND convert(date,GETDATE())
					WHERE visited_date BETWEEN DateAdd(DAY,-16,convert(date,GETDATE())) AND convert(date,GETDATE())
					--End of Rev 3.0
					--End of Rev 2.0
					--End of Rev 1.0
					AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					) SHPACT

					SELECT DISTINCT [date] FROM(
					SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date] FROM [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
					--Rev 1.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-30,convert(date,GETDATE())) AND convert(date,GETDATE())
					--Rev 3.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-45,convert(date,GETDATE())) AND convert(date,GETDATE())
					WHERE visited_date BETWEEN DateAdd(DAY,-16,convert(date,GETDATE())) AND convert(date,GETDATE())
					--End of Rev 3.0
					--End of Rev 1.0
					AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					UNION ALL
					--Rev 2.0
					--SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date] FROM Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
					----Rev 1.0
					----WHERE visited_date BETWEEN DateAdd(DAY,-30,convert(date,GETDATE())) AND convert(date,GETDATE())
					--WHERE visited_date BETWEEN DateAdd(DAY,-45,convert(date,GETDATE())) AND convert(date,GETDATE())
					SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date] FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
					--Rev 3.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-45,convert(date,GETDATE())) AND convert(date,GETDATE())
					WHERE visited_date BETWEEN DateAdd(DAY,-16,convert(date,GETDATE())) AND convert(date,GETDATE())
					--End of Rev 3.0
					--End of Rev 2.0
					--End of Rev 1.0
					AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
					) SHPACT

					SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date],CAST(lastactivty.Shop_Id AS VARCHAR(50)) AS shopid,
					CAST(spent_duration AS VARCHAR(50)) AS duration_spent,shop.Shop_Name AS shop_name,shop.Address AS shop_address,visited_date AS visited_date,ISNULL(device_model,'') AS device_model,
					ISNULL(android_version,'') AS android_version,ISNULL(battery,'') AS battery,ISNULL(net_status,'') AS net_status,ISNULL(net_type,'') AS net_type,ISNULL(CheckIn_Time,'') AS in_time,
					ISNULL(CheckOut_Time,'') AS out_time,ISNULL(start_timestamp,'') AS start_timestamp,ISNULL(CheckIn_Address,'') AS in_location,ISNULL(CheckOut_Address,'') AS out_location,
					ISNULL(lastactivty.Revisit_Code,'') AS [Key],ISNULL(lastactivty.Ordernottaken_Status,'') AS shop_revisit_status,ISNULL(lastactivty.Ordernottaken_Remarks,'') AS shop_revisit_remarks,
					CONVERT(NVARCHAR(10),ISNULL(lastactivty.Pros_Id,'')) AS pros_id,CONVERT(NVARCHAR(10),ISNULL(lastactivty.Updated_by,'')) AS updated_by,
					ISNULL(CAST(lastactivty.Updated_on AS date),'') AS updated_on,ISNULL(lastactivty.Agency_Name,'') AS agency_name,
					ISNULL(lastactivty.Approximate_1st_Billing_Value,0.00) AS approximate_1st_billing_value
					FROM [tbl_trans_shopActivitysubmit] AS lastactivty WITH(NOLOCK) 
					INNER JOIN tbl_Master_shop AS shop WITH(NOLOCK) ON shop.Shop_Code=lastactivty.Shop_Id
					--Rev 1.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-30,convert(date,GETDATE())) AND convert(date,GETDATE())
					--Rev 3.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-45,convert(date,GETDATE())) AND convert(date,GETDATE())
					WHERE visited_date BETWEEN DateAdd(DAY,-16,convert(date,GETDATE())) AND convert(date,GETDATE())
					--End of Rev 3.0
					--End of Rev 1.0
					AND User_Id=@user_id AND ISNULL(lastactivty.ISMEETING,0)=0
					UNION ALL
					SELECT DISTINCT CAST(visited_date AS VARCHAR(50)) AS [date],CAST(lastactivty.Shop_Id AS VARCHAR(50)) AS shopid,
					CAST(spent_duration AS VARCHAR(50)) AS duration_spent,shop.Shop_Name AS shop_name,shop.Address AS shop_address,visited_date AS visited_date,ISNULL(device_model,'') AS device_model,
					ISNULL(android_version,'') AS android_version,ISNULL(battery,'') AS battery,ISNULL(net_status,'') AS net_status,ISNULL(net_type,'') AS net_type,ISNULL(CheckIn_Time,'') AS in_time,
					ISNULL(CheckOut_Time,'') AS out_time,ISNULL(start_timestamp,'') AS start_timestamp,ISNULL(CheckIn_Address,'') AS in_location,ISNULL(CheckOut_Address,'') AS out_location,
					ISNULL(lastactivty.Revisit_Code,'') AS [Key],ISNULL(lastactivty.Ordernottaken_Status,'') AS shop_revisit_status,ISNULL(lastactivty.Ordernottaken_Remarks,'') AS shop_revisit_remarks,
					CONVERT(NVARCHAR(10),ISNULL(lastactivty.Pros_Id,'')) AS pros_id,CONVERT(NVARCHAR(10),ISNULL(lastactivty.Updated_by,'')) AS updated_by,
					ISNULL(CAST(lastactivty.Updated_on AS date),'') AS updated_on,ISNULL(lastactivty.Agency_Name,'') AS agency_name,
					ISNULL(lastactivty.Approximate_1st_Billing_Value,0.00) AS approximate_1st_billing_value
					--Rev 2.0
					--FROM Trans_ShopActivitySubmit_TodayData AS lastactivty WITH(NOLOCK) 
					FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData AS lastactivty WITH(NOLOCK) 
					--End of Rev 2.0
					INNER JOIN tbl_Master_shop AS shop WITH(NOLOCK) ON shop.Shop_Code=lastactivty.Shop_Id
					--Rev 1.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-30,convert(date,GETDATE())) AND convert(date,GETDATE())
					--Rev 3.0
					--WHERE visited_date BETWEEN DateAdd(DAY,-45,convert(date,GETDATE())) AND convert(date,GETDATE())
					WHERE visited_date BETWEEN DateAdd(DAY,-16,convert(date,GETDATE())) AND convert(date,GETDATE())
					--End of Rev 3.0
					--End of Rev 1.0
					AND User_Id=@user_id AND ISNULL(lastactivty.ISMEETING,0)=0
				END
		END
	IF(@Action=1)
		BEGIN
			SELECT CAST(Shop_Id AS VARCHAR(50)) AS shopid,CAST(spent_duration AS VARCHAR(50)) AS duration_spent FROM [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
			WHERE visited_date=@from_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
			UNION ALL
			--Rev 2.0
			--SELECT CAST(Shop_Id AS VARCHAR(50)) AS shopid,CAST(spent_duration AS VARCHAR(50)) AS duration_spent FROM Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
			--WHERE visited_date=@from_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
			SELECT CAST(Shop_Id AS VARCHAR(50)) AS shopid,CAST(spent_duration AS VARCHAR(50)) AS duration_spent FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WITH(NOLOCK) 
			WHERE visited_date=@from_date AND User_Id=@user_id AND ISNULL(ISMEETING,0)=0
			--End of Rev 2.0
		END

	SET NOCOUNT OFF
END
GO