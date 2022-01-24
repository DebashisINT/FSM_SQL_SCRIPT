IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_API_DaywiseShop]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_API_DaywiseShop] AS' 
END
GO

--EXEC Sp_API_DaywiseShop @user_id=2417,@from_date='2020-01-22',@to_date='2020-01-22',@Action=1
ALTER PROCEDURE  [dbo].[Sp_API_DaywiseShop]
(
@user_id int =NULL,
@from_date varchar(50)=NULL,
@to_date varchar(50) =NULL,
@date_span int =NULL,
@Action  int=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************
1.0					TANMOY		22-01-2020		ONLY SHOP SHOW ISMEETING=0 
2.0					TANMOY		24-06-2021		add new parameter
3.0					TANMOY		30-07-2021		Parameter name change
4.0		v2.0.26		Debashis	13-12-2021		Some new fields has been added.
****************************************************************************************************************************************/
BEGIN

	if(@Action=0)
	BEGIN
		if(isnull(@date_span,0) =0)
			BEGIN
				select   isnull(count(Shop_Id),0) as totcount ,isnull(AVG(isnull(total_visit_count,0)),0) as avgshop  from  [tbl_trans_shopActivitysubmit] 
				where visited_date between @from_date and @to_date
				and User_Id=@user_id
				--REV 1.0 START
				AND ISNULL(ISMEETING,0)=0
				--REV 1.0 END

				select    distinct cast(visited_date as varchar(50)) as [date]  from  [tbl_trans_shopActivitysubmit] 
				where visited_date between @from_date and @to_date
				and User_Id=@user_id
				--REV 1.0 START
				AND ISNULL(ISMEETING,0)=0
				--REV 1.0 END


				select    distinct cast(visited_date as varchar(50)) as [date],cast(lastactivty.Shop_Id as varchar(50)) as shopid,
				cast(spent_duration as varchar(50)) as duration_spent
				,shop.Shop_Name as shop_name,shop.Address as shop_address,visited_date as visited_date
				,ISNULL(device_model,'') device_model,ISNULL(android_version,'') android_version,ISNULL(battery,'') battery,ISNULL(net_status,'') net_status,ISNULL(net_type,'') net_type
				,ISNULL(CheckIn_Time,'') in_time, ISNULL(CheckOut_Time,'') out_time,ISNULL(start_timestamp,'') start_timestamp
				,ISNULL(CheckIn_Address,'') in_location, ISNULL(CheckOut_Address,'') out_location
				,ISNULL(lastactivty.Revisit_Code,'') as [Key],ISNULL(lastactivty.Ordernottaken_Status,'') as shop_revisit_status,ISNULL(lastactivty.Ordernottaken_Remarks,'') as shop_revisit_remarks,
				--Rev 4.0
				CONVERT(NVARCHAR(10),ISNULL(lastactivty.Pros_Id,'')) AS pros_id,CONVERT(NVARCHAR(10),ISNULL(lastactivty.Updated_by,'')) AS updated_by,
				ISNULL(CAST(lastactivty.Updated_on AS date),'') AS updated_on,ISNULL(lastactivty.Agency_Name,'') AS agency_name,
				ISNULL(lastactivty.Approximate_1st_Billing_Value,0.00) AS approximate_1st_billing_value
				--End of Rev 4.0
				 from  [tbl_trans_shopActivitysubmit]  as lastactivty
				 inner  join  tbl_Master_shop as shop  on shop.Shop_Code=lastactivty.Shop_Id
				where visited_date between @from_date and @to_date
				and User_Id=@user_id
				--REV 1.0 START
				AND ISNULL(lastactivty.ISMEETING,0)=0
				--REV 1.0 END
			END
		ELSE
			BEGIN
				select   isnull(count(Shop_Id),0) as totcount ,isnull(AVG(isnull(total_visit_count,0)),0) as avgshop  from  [tbl_trans_shopActivitysubmit] 
				where visited_date between DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE())
				and User_Id=@user_id 
				--REV 1.0 START
				AND ISNULL(ISMEETING,0)=0
				--REV 1.0 END

				select    distinct cast(visited_date as varchar(50)) as [date]  from  [tbl_trans_shopActivitysubmit] 
				where visited_date between  DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE())
				and User_Id=@user_id
				--REV 1.0 START
				AND ISNULL(ISMEETING,0)=0
				--REV 1.0 END


				select distinct cast(visited_date as varchar(50)) as [date],cast(lastactivty.Shop_Id as varchar(50)) as shopid,
				cast(spent_duration as varchar(50)) as duration_spent
				,shop.Shop_Name as shop_name,shop.Address as shop_address,visited_date as visited_date
				,ISNULL(device_model,'') device_model,ISNULL(android_version,'') android_version,ISNULL(battery,'') battery,ISNULL(net_status,'') net_status,ISNULL(net_type,'') net_type
				,ISNULL(CheckIn_Time,'') in_time, ISNULL(CheckOut_Time,'') out_time,ISNULL(start_timestamp,'') start_timestamp
				,ISNULL(CheckIn_Address,'') in_location, ISNULL(CheckOut_Address,'') out_location
				,ISNULL(lastactivty.Revisit_Code,'') as [Key],ISNULL(lastactivty.Ordernottaken_Status,'') as shop_revisit_status,ISNULL(lastactivty.Ordernottaken_Remarks,'') as shop_revisit_remarks,
				--Rev 4.0
				CONVERT(NVARCHAR(10),ISNULL(lastactivty.Pros_Id,'')) AS pros_id,CONVERT(NVARCHAR(10),ISNULL(lastactivty.Updated_by,'')) AS updated_by,
				ISNULL(CAST(lastactivty.Updated_on AS date),'') AS updated_on,ISNULL(lastactivty.Agency_Name,'') AS agency_name,
				ISNULL(lastactivty.Approximate_1st_Billing_Value,0.00) AS approximate_1st_billing_value
				--End of Rev 4.0
				 from  [tbl_trans_shopActivitysubmit]  as lastactivty
				 inner  join  tbl_Master_shop as shop  on shop.Shop_Code=lastactivty.Shop_Id
				where visited_date between  DateAdd(DAY,-30,convert(date,GETDATE())) and convert(date,GETDATE())
				and User_Id=@user_id 
				--REV 1.0 START
				AND ISNULL(lastactivty.ISMEETING,0)=0
				--REV 1.0 END

			END
	END
	if(@Action=1)
	BEGIN
		select  cast(Shop_Id as varchar(50)) as shopid,cast(spent_duration as varchar(50)) as duration_spent from  [tbl_trans_shopActivitysubmit]
		where visited_date=@from_date  and User_Id=@user_id 
		--REV 1.0 START
		AND ISNULL(ISMEETING,0)=0
		--REV 1.0 END
	END
END
