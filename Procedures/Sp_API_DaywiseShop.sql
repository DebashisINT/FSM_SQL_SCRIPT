--EXEC Sp_API_DaywiseShop @user_id=11706,@from_date='2022-10-01',@to_date='2022-10-14',@Action=0

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_API_DaywiseShop]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_API_DaywiseShop] AS' 
END
GO

ALTER PROCEDURE  [dbo].[Sp_API_DaywiseShop]
(
@user_id int =NULL,
@from_date NVARCHAR(50)=NULL,
@to_date NVARCHAR(50) =NULL,
@date_span int =NULL,
@Action  int=NULL
) --WITH ENCRYPTION
AS
/*********************************************************************************************************************************************************************
1.0					TANMOY		22-01-2020		ONLY SHOP SHOW ISMEETING=0 
2.0					TANMOY		24-06-2021		add new parameter
3.0					TANMOY		30-07-2021		Parameter name change
4.0		v2.0.26		Debashis	13-12-2021		Some new fields has been added.
5.0		v2.0.37		Debashis	10-01-2023		Some new fields have been added.Row: 787
6.0		v2.0.37		Debashis	21-04-2023		Added two new fields as DistFromProfileAddrKms & StationCode.Row: 821
7.0		v2.0.39		Debashis	06-06-2023		http://3.7.30.86:8072/API/Daywiseshop/Records [^]
												For the above api a list is coming as date_list->shop_list
												Under the above list a parameter comes as visited_date which now fetching value as
												2023-06-04T00:00:00,But it requires time along with the date such as 2023-06-06T10:30:41
												Refer: 0026299
8.0		v2.0.40		Debashis	20-06-2023		Added a new field as Is_Newshopadd.Row: 850
*********************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	if(@Action=0)
		BEGIN
			if(isnull(@date_span,0) =0)
				BEGIN
					select isnull(count(Shop_Id),0) as totcount ,isnull(AVG(isnull(total_visit_count,0)),0) as avgshop  from  [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
					where visited_date between @from_date and @to_date
					and User_Id=@user_id
					--REV 1.0 START
					AND ISNULL(ISMEETING,0)=0
					--REV 1.0 END

					select distinct cast(visited_date as varchar(50)) as [date]  from  [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
					where visited_date between @from_date and @to_date
					and User_Id=@user_id
					--REV 1.0 START
					AND ISNULL(ISMEETING,0)=0
					--REV 1.0 END


					select distinct cast(visited_date as varchar(50)) as [date],cast(lastactivty.Shop_Id as varchar(50)) as shopid,
					cast(spent_duration as varchar(50)) as duration_spent
					--Rev 7.0
					--,shop.Shop_Name as shop_name,shop.Address as shop_address,visited_date as visited_date
					,shop.Shop_Name as shop_name,shop.Address as shop_address,visited_time as visited_date
					--End of Rev 7.0
					,ISNULL(device_model,'') device_model,ISNULL(android_version,'') android_version,ISNULL(battery,'') battery,ISNULL(net_status,'') net_status,ISNULL(net_type,'') net_type
					,ISNULL(CheckIn_Time,'') in_time, ISNULL(CheckOut_Time,'') out_time,ISNULL(start_timestamp,'') start_timestamp
					,ISNULL(CheckIn_Address,'') in_location, ISNULL(CheckOut_Address,'') out_location
					,ISNULL(lastactivty.Revisit_Code,'') as [Key],ISNULL(lastactivty.Ordernottaken_Status,'') as shop_revisit_status,ISNULL(lastactivty.Ordernottaken_Remarks,'') as shop_revisit_remarks,
					--Rev 4.0
					CONVERT(NVARCHAR(10),ISNULL(lastactivty.Pros_Id,'')) AS pros_id,CONVERT(NVARCHAR(10),ISNULL(lastactivty.Updated_by,'')) AS updated_by,
					ISNULL(CAST(lastactivty.Updated_on AS date),'') AS updated_on,ISNULL(lastactivty.Agency_Name,'') AS agency_name,
					ISNULL(lastactivty.Approximate_1st_Billing_Value,0.00) AS approximate_1st_billing_value
					--End of Rev 4.0
					--Rev 5.0
					,lastactivty.Multi_Contact_Name AS multi_contact_name,lastactivty.Multi_Contact_Number AS multi_contact_number
					--End of Rev 5.0
					--Rev 6.0
					 ,lastactivty.DistFromProfileAddrKms AS distFromProfileAddrKms,lastactivty.StationCode AS stationCode
					 --End of Rev 6.0
					 --Rev 8.0
					 ,lastactivty.Is_Newshopadd
					 --End of Rev 8.0
					 from  [tbl_trans_shopActivitysubmit]  as lastactivty WITH(NOLOCK) 
					 INNER JOIN tbl_Master_shop as shop WITH(NOLOCK) on shop.Shop_Code=lastactivty.Shop_Id
					where visited_date between @from_date and @to_date
					and User_Id=@user_id
					--REV 1.0 START
					AND ISNULL(lastactivty.ISMEETING,0)=0
					--REV 1.0 END
				END
			ELSE
				BEGIN
					select isnull(count(Shop_Id),0) as totcount ,isnull(AVG(isnull(total_visit_count,0)),0) as avgshop  from  [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
					where visited_date between DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE())
					and User_Id=@user_id 
					--REV 1.0 START
					AND ISNULL(ISMEETING,0)=0
					--REV 1.0 END

					select distinct cast(visited_date as varchar(50)) as [date]  from  [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
					where visited_date between  DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE())
					and User_Id=@user_id
					--REV 1.0 START
					AND ISNULL(ISMEETING,0)=0
					--REV 1.0 END


					select distinct cast(visited_date as varchar(50)) as [date],cast(lastactivty.Shop_Id as varchar(50)) as shopid,
					cast(spent_duration as varchar(50)) as duration_spent
					--Rev 7.0
					--,shop.Shop_Name as shop_name,shop.Address as shop_address,visited_date as visited_date
					,shop.Shop_Name as shop_name,shop.Address as shop_address,visited_time as visited_date
					--End of Rev 7.0
					,ISNULL(device_model,'') device_model,ISNULL(android_version,'') android_version,ISNULL(battery,'') battery,ISNULL(net_status,'') net_status,ISNULL(net_type,'') net_type
					,ISNULL(CheckIn_Time,'') in_time, ISNULL(CheckOut_Time,'') out_time,ISNULL(start_timestamp,'') start_timestamp
					,ISNULL(CheckIn_Address,'') in_location, ISNULL(CheckOut_Address,'') out_location
					,ISNULL(lastactivty.Revisit_Code,'') as [Key],ISNULL(lastactivty.Ordernottaken_Status,'') as shop_revisit_status,ISNULL(lastactivty.Ordernottaken_Remarks,'') as shop_revisit_remarks,
					--Rev 4.0
					CONVERT(NVARCHAR(10),ISNULL(lastactivty.Pros_Id,'')) AS pros_id,CONVERT(NVARCHAR(10),ISNULL(lastactivty.Updated_by,'')) AS updated_by,
					ISNULL(CAST(lastactivty.Updated_on AS date),'') AS updated_on,ISNULL(lastactivty.Agency_Name,'') AS agency_name,
					ISNULL(lastactivty.Approximate_1st_Billing_Value,0.00) AS approximate_1st_billing_value
					--End of Rev 4.0
					--Rev 5.0
					,lastactivty.Multi_Contact_Name AS multi_contact_name,lastactivty.Multi_Contact_Number AS multi_contact_number
					--End of Rev 5.0
					--Rev 6.0
					 ,lastactivty.DistFromProfileAddrKms AS distFromProfileAddrKms,lastactivty.StationCode AS stationCode
					 --End of Rev 6.0
					 --Rev 8.0
					 ,lastactivty.Is_Newshopadd
					 --End of Rev 8..0
					 from  [tbl_trans_shopActivitysubmit]  as lastactivty WITH(NOLOCK) 
					 INNER JOIN tbl_Master_shop as shop WITH(NOLOCK) on shop.Shop_Code=lastactivty.Shop_Id
					where visited_date between  DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE())
					and User_Id=@user_id 
					--REV 1.0 START
					AND ISNULL(lastactivty.ISMEETING,0)=0
					--REV 1.0 END

				END
		END
	if(@Action=1)
		BEGIN
			select cast(Shop_Id as varchar(50)) as shopid,cast(spent_duration as varchar(50)) as duration_spent from  [tbl_trans_shopActivitysubmit] WITH(NOLOCK) 
			where visited_date=@from_date  and User_Id=@user_id 
			--REV 1.0 START
			AND ISNULL(ISMEETING,0)=0
			--REV 1.0 END
		END

	SET NOCOUNT OFF
END