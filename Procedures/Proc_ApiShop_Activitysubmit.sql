IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_ApiShop_Activitysubmit]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_ApiShop_Activitysubmit] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[Proc_ApiShop_Activitysubmit]
(
@session_token NVARCHAR(MAX)=NULL,
@user_id NVARCHAR(50)=NULL,
--Rev 7.0
@isnewShop INT=NULL,
--End of Rev 7.0
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/*****************************************************************************************************************************************
1.0					Tanmoy		14-02-2020		add visit remarks 
2.0					Indranil	                Distance ,IsFirstShop,IsOutside column added
3.0					Indranil				    Same day visit allowed for different user
4.0					Debashis	06-12-2021		Added Five fields as "Pros_Id,Updated_by,Updated_on,Agency_Name,Approximate_1st_Billing_Value"
												for RowNo: 576(From "FTS App API doc v1.0" Google sheet)
5.0					Debashis	12-01-2022		Last Visit Date is not getting updated in shop list.
												- It should be updated in case of New Visit then visit date will be updated.
												- And In case of Revisit, the last visit date shall be updated for the shop.
												Now it has been taken care off.Refer: 0024614
6.0					Debashis	07-12-2022		One global settings should be inttrodued for Multivisit module.Refer: 0025493
7.0					Debashis	22-12-2022		When user create a shop, From user-end we send extra input 1 or 0.Added New Shop =1.
												Refer: 0025529 & Row: 781
8.0		v2.0.37		Debashis	10/01/2023		Some new fields have been added.Row: 786
*****************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	BEGIN TRAN
		BEGIN TRY
			 DECLARE @datenew datetime=GETDATE()
			 DECLARE @OUTSTATION_DISTANCE DECIMAL(18,2)=(select value from FTS_APP_CONFIG_SETTINGS where [key]='OutStationDitance')
			 --Rev 6.0
			 DECLARE @MultipleVisitEnable NVARCHAR(100)=(SELECT VALUE FROM FTS_APP_CONFIG_SETTINGS WHERE [key]='isMultipleVisitEnable')
			 IF @MultipleVisitEnable='0'
				BEGIN
			 --End of Rev 6.0
					 INSERT INTO tbl_trans_shopActivitysubmit ([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count
					 ,Createddate,Is_Newshopadd,distance_travelled
					 --Rev 1.0 Start
					 ,REMARKS
					 --Rev 1.0 End
					 --Rev 2.0 Start
					 ,IsFirstVisit,IsOutStation,Outstation_Distance
					 --Rev 2.0 End
					 ,early_revisit_reason,device_model,android_version,battery,net_status,net_type
					 ,CheckIn_Time
					 ,CheckOut_Time
					 ,start_timestamp
					 ,CheckIn_Address,CheckOut_Address
					 ,Revisit_Code
					 --Rev 4.0
					 ,Pros_Id,Updated_by,Updated_on,Agency_Name,Approximate_1st_Billing_Value
					 --End of Rev 4.0
					 --Rev 8.0
					 ,Multi_Contact_Name,Multi_Contact_Number
					 --End of Rev 8.0
					 )
	
					SELECT DISTINCT @user_id,
					XMLproduct.value('(shop_id/text())[1]','nvarchar(100)')	,
					XMLproduct.value('(visited_date/text())[1]','date')	,
					XMLproduct.value('(visited_time/text())[1]','datetime'),
					XMLproduct.value('(spent_duration/text())[1]','nvarchar(100)')	,
					XMLproduct.value('(total_visit_count/text())[1]','int')	
					,@datenew
					,0
					,XMLproduct.value('(distance_travelled/text())[1]','decimal(18,2)')	
					--Rev 1.0 Start
					,XMLproduct.value('(feedback/text())[1]','varchar(100)')	
					--Rev 1.0 End
					--Rev 2.0 Start
					,
					case when XMLproduct.value('(isFirstShopVisited/text())[1]','varchar(40)')='true' then  1 else 0 end	,
					case when XMLproduct.value('(distanceFromHomeLoc/text())[1]','decimal(18,2)')>=@OUTSTATION_DISTANCE	 then  1 else 0 end,
					XMLproduct.value('(distanceFromHomeLoc/text())[1]','decimal(18,2)')	,

					--Rev 2.0 End
					XMLproduct.value('(early_revisit_reason/text())[1]','varchar(100)')
					,XMLproduct.value('(device_model/text())[1]','varchar(100)')
					,XMLproduct.value('(android_version/text())[1]','varchar(100)')
					,XMLproduct.value('(battery/text())[1]','varchar(100)')
					,XMLproduct.value('(net_status/text())[1]','varchar(100)')
					,XMLproduct.value('(net_type/text())[1]','varchar(100)')
					,XMLproduct.value('(in_time/text())[1]','varchar(100)')
					,XMLproduct.value('(out_time/text())[1]','varchar(100)')
					,XMLproduct.value('(start_timestamp/text())[1]','varchar(100)')
					,XMLproduct.value('(in_location/text())[1]','varchar(100)')
					,XMLproduct.value('(out_location/text())[1]','varchar(100)')
					,XMLproduct.value('(shop_revisit_uniqKey/text())[1]','varchar(100)')
					--Rev 4.0
					,XMLproduct.value('(pros_id/text())[1]','bigint')
					,XMLproduct.value('(updated_by/text())[1]','bigint')
					,XMLproduct.value('(updated_on/text())[1]','datetime')
					,XMLproduct.value('(agency_name/text())[1]','varchar(500)')
					,XMLproduct.value('(approximate_1st_billing_value/text())[1]','decimal(18,2)')
					--End of Rev 4.0
					--Rev 8.0
					,XMLproduct.value('(multi_contact_name/text())[1]','nvarchar(300)')
					,XMLproduct.value('(multi_contact_number/text())[1]','nvarchar(100)')
					--End of Rev 8.0

					from
					@JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  
					inner join tbl_Master_shop on Shop_Code=XMLproduct.value('(shop_id/text())[1]','nvarchar(MAX)')	
					WHERE NOT EXISTS(select ActivityId from  tbl_trans_shopActivitysubmit where  shop_id=XMLproduct.value('(shop_id/text())[1]','nvarchar(100)') and visited_date=XMLproduct.value('(visited_date/text())[1]','date') and User_Id=@user_id)

					UPDATE TTSAS SET spent_duration=XMLproduct.value('(spent_duration/text())[1]','nvarchar(100)') ,
					distance_travelled=XMLproduct.value('(distance_travelled/text())[1]','nvarchar(100)')
					,REMARKS=XMLproduct.value('(feedback/text())[1]','varchar(100)')
					,early_revisit_reason=XMLproduct.value('(early_revisit_reason/text())[1]','varchar(100)')
					,device_model=XMLproduct.value('(device_model/text())[1]','varchar(100)')
					,android_version=XMLproduct.value('(android_version/text())[1]','varchar(100)')
					,battery=XMLproduct.value('(battery/text())[1]','varchar(100)')
					,net_status=XMLproduct.value('(net_type/text())[1]','varchar(100)')
					,net_type=XMLproduct.value('(net_type/text())[1]','varchar(100)')
					,CheckIn_Time=XMLproduct.value('(in_time/text())[1]','varchar(100)')
					,CheckOut_Time=XMLproduct.value('(out_time/text())[1]','varchar(100)')
					,start_timestamp=XMLproduct.value('(start_timestamp/text())[1]','varchar(100)')
					,CheckIn_Address=XMLproduct.value('(in_location/text())[1]','varchar(100)')
					,CheckOut_Address=XMLproduct.value('(out_location/text())[1]','varchar(100)')
					,Revisit_Code=XMLproduct.value('(shop_revisit_uniqKey/text())[1]','varchar(100)')
					--Rev 4.0
					,Pros_Id=XMLproduct.value('(pros_id/text())[1]','bigint')
					,Updated_by=XMLproduct.value('(updated_by/text())[1]','bigint')
					,Updated_on=XMLproduct.value('(updated_on/text())[1]','datetime')
					,Agency_Name=XMLproduct.value('(agency_name/text())[1]','varchar(500)')
					,Approximate_1st_Billing_Value=XMLproduct.value('(approximate_1st_billing_value/text())[1]','decimal(18,2)')
					--End of Rev 4.0
					--Rev 8.0
					,Multi_Contact_Name=XMLproduct.value('(multi_contact_name/text())[1]','nvarchar(300)')
					,Multi_Contact_Number=XMLproduct.value('(multi_contact_number/text())[1]','nvarchar(100)')
					--End of Rev 8.0
					from tbl_trans_shopActivitysubmit TTSAS
					INNER JOIN 	@JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  
					ON shop_id=XMLproduct.value('(shop_id/text())[1]','nvarchar(100)')	 and visited_date=XMLproduct.value('(visited_date/text())[1]','date')
					and spent_duration='00:00:00'
			--Rev 6.0
				END
			ELSE IF @MultipleVisitEnable='1'
				BEGIN
					--Rev 7.0
					IF @isnewShop=0
						BEGIN
					--End of Rev 7.0
							INSERT INTO tbl_trans_shopActivitysubmit ([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled
							,REMARKS,IsFirstVisit,IsOutStation,Outstation_Distance,early_revisit_reason,device_model,android_version,battery,net_status,net_type,CheckIn_Time,CheckOut_Time
							,start_timestamp,CheckIn_Address,CheckOut_Address,Revisit_Code,Pros_Id,Updated_by,Updated_on,Agency_Name,Approximate_1st_Billing_Value
							--Rev 8.0
							,Multi_Contact_Name,Multi_Contact_Number
							--End of Rev 8.0
							)
	
							SELECT DISTINCT @user_id,
							XMLproduct.value('(shop_id/text())[1]','nvarchar(100)')	,
							XMLproduct.value('(visited_date/text())[1]','date')	,
							XMLproduct.value('(visited_time/text())[1]','datetime'),
							XMLproduct.value('(spent_duration/text())[1]','nvarchar(100)')	,
							XMLproduct.value('(total_visit_count/text())[1]','int')	
							,@datenew,0
							,XMLproduct.value('(distance_travelled/text())[1]','decimal(18,2)')	
							,XMLproduct.value('(feedback/text())[1]','varchar(100)'),
							case when XMLproduct.value('(isFirstShopVisited/text())[1]','varchar(40)')='true' then  1 else 0 end	,
							case when XMLproduct.value('(distanceFromHomeLoc/text())[1]','decimal(18,2)')>=@OUTSTATION_DISTANCE	 then  1 else 0 end,
							XMLproduct.value('(distanceFromHomeLoc/text())[1]','decimal(18,2)')	,
							XMLproduct.value('(early_revisit_reason/text())[1]','varchar(100)')
							,XMLproduct.value('(device_model/text())[1]','varchar(100)')
							,XMLproduct.value('(android_version/text())[1]','varchar(100)')
							,XMLproduct.value('(battery/text())[1]','varchar(100)')
							,XMLproduct.value('(net_status/text())[1]','varchar(100)')
							,XMLproduct.value('(net_type/text())[1]','varchar(100)')
							,XMLproduct.value('(in_time/text())[1]','varchar(100)')
							,XMLproduct.value('(out_time/text())[1]','varchar(100)')
							,XMLproduct.value('(start_timestamp/text())[1]','varchar(100)')
							,XMLproduct.value('(in_location/text())[1]','varchar(100)')
							,XMLproduct.value('(out_location/text())[1]','varchar(100)')
							,XMLproduct.value('(shop_revisit_uniqKey/text())[1]','varchar(100)')
							,XMLproduct.value('(pros_id/text())[1]','bigint')
							,XMLproduct.value('(updated_by/text())[1]','bigint')
							,XMLproduct.value('(updated_on/text())[1]','datetime')
							,XMLproduct.value('(agency_name/text())[1]','varchar(500)')
							,XMLproduct.value('(approximate_1st_billing_value/text())[1]','decimal(18,2)')
							--Rev 8.0
							,XMLproduct.value('(multi_contact_name/text())[1]','nvarchar(300)')
							,XMLproduct.value('(multi_contact_number/text())[1]','nvarchar(100)')
							--End of Rev 8.0
							from
							@JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
							INNER JOIN tbl_Master_shop on Shop_Code=XMLproduct.value('(shop_id/text())[1]','nvarchar(MAX)')	
					--Rev 7.0
						END
					ELSE IF @isnewShop=1
						BEGIN
					--End of Rev 7.0
							UPDATE TTSAS SET spent_duration=XMLproduct.value('(spent_duration/text())[1]','nvarchar(100)') ,
							distance_travelled=XMLproduct.value('(distance_travelled/text())[1]','nvarchar(100)')
							,REMARKS=XMLproduct.value('(feedback/text())[1]','varchar(100)')
							,early_revisit_reason=XMLproduct.value('(early_revisit_reason/text())[1]','varchar(100)')
							,device_model=XMLproduct.value('(device_model/text())[1]','varchar(100)')
							,android_version=XMLproduct.value('(android_version/text())[1]','varchar(100)')
							,battery=XMLproduct.value('(battery/text())[1]','varchar(100)')
							,net_status=XMLproduct.value('(net_type/text())[1]','varchar(100)')
							,net_type=XMLproduct.value('(net_type/text())[1]','varchar(100)')
							,CheckIn_Time=XMLproduct.value('(in_time/text())[1]','varchar(100)')
							,CheckOut_Time=XMLproduct.value('(out_time/text())[1]','varchar(100)')
							,start_timestamp=XMLproduct.value('(start_timestamp/text())[1]','varchar(100)')
							,CheckIn_Address=XMLproduct.value('(in_location/text())[1]','varchar(100)')
							,CheckOut_Address=XMLproduct.value('(out_location/text())[1]','varchar(100)')
							,Revisit_Code=XMLproduct.value('(shop_revisit_uniqKey/text())[1]','varchar(100)')
							,Pros_Id=XMLproduct.value('(pros_id/text())[1]','bigint')
							,Updated_by=XMLproduct.value('(updated_by/text())[1]','bigint')
							,Updated_on=XMLproduct.value('(updated_on/text())[1]','datetime')
							,Agency_Name=XMLproduct.value('(agency_name/text())[1]','varchar(500)')
							,Approximate_1st_Billing_Value=XMLproduct.value('(approximate_1st_billing_value/text())[1]','decimal(18,2)')
							--Rev 8.0
							,Multi_Contact_Name=XMLproduct.value('(multi_contact_name/text())[1]','nvarchar(300)')
							,Multi_Contact_Number=XMLproduct.value('(multi_contact_number/text())[1]','nvarchar(100)')
							--End of Rev 8.0
							from tbl_trans_shopActivitysubmit TTSAS
							INNER JOIN @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct) 
							ON shop_id=XMLproduct.value('(shop_id/text())[1]','nvarchar(100)') AND visited_date=XMLproduct.value('(visited_date/text())[1]','date')
					--Rev 7.0
							--and spent_duration='00:00:00'
							AND USER_ID=@user_id
						END
					--End of Rev 7.0
				END
			--End of Rev 6.0

			--Rev 5.0
			UPDATE MS SET Lastvisit_date=XMLproduct.value('(visited_date/text())[1]','date')
			FROM [tbl_Master_shop] MS
			INNER JOIN 	@JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  
			ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','nvarchar(100)')
			--End of Rev 5.0

			select
			XMLproduct.value('(shop_id/text())[1]','nvarchar(MAX)')	as shopid,
			XMLproduct.value('(total_visit_count/text())[1]','int')	as total_visit_count,
			XMLproduct.value('(visited_time/text())[1]','datetime')	as visited_time,
			XMLproduct.value('(visited_date/text())[1]','date')	as visited_date,
			XMLproduct.value('(spent_duration/text())[1]','varchar(50)') as spent_duration
			FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)

		COMMIT TRAN
	END TRY
	--END


	--END


	BEGIN CATCH
	ROLLBACK TRAN
	END CATCH

	SET NOCOUNT OFF
END