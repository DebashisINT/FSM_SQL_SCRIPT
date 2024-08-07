IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APITRANSFERSHOPSUBMITDATA]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APITRANSFERSHOPSUBMITDATA] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_APITRANSFERSHOPSUBMITDATA]
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder On 21/10/2022
Module	   : Transfer Shop Submit Data from new table to old table.
1.0		v2.0.40		Debashis	14-07-2023		Last Visit date in Shop Master should be updated through scheduler from Today Data table as Deadlock was occured while
												UPDATE Statement executed on tbl_Master_shop table.Now it has been taken care of.Refer: 0026581
2.0		v2.0.43		Debashis	11/12/2023		Data fetch from FSM_ITC_MIRROR DB and moved to FSM_ITC DB.Refer: 0027094
3.0		v2.0.44		Debashis	05/02/2024		total_visit_count and last_visit_date fields value should be fetched from tbl_master_shop instead of previous logic.
												Refer: 0027177
4.0		v2.0.45		Debashis	03/04/2024		Some new fields have been added.Row: 915
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	
	--Rev 1.0
	SELECT Shop_Id,MAX(visited_time) VISITDTTIME INTO #TMPVISITDTTIME FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WITH(NOLOCK)
	--Rev 3.0
	--WHERE CAST(Createddate AS DATE)=CAST(GETDATE() AS DATE)
	--End of Rev 3.0
	GROUP BY Shop_Id

	UPDATE MS SET Lastvisit_date=T.VISITDTTIME
	FROM [tbl_Master_shop] MS
	INNER JOIN #TMPVISITDTTIME T ON MS.Shop_Code=T.Shop_Id
	--End of Rev 1.0
	--Rev 3.0
	SELECT Shop_Id,total_visit_count INTO #TMPVISITCOUNT FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WITH(NOLOCK)

	UPDATE MS SET total_visitcount=T.total_visit_count
	FROM [tbl_Master_shop] MS
	INNER JOIN #TMPVISITCOUNT T ON MS.Shop_Code=T.Shop_Id
	--End of Rev 3.0

	--Rev 2.0
	--INSERT INTO tbl_trans_shopActivitysubmit
	--(User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,LATITUDE,LONGITUDE,REMARKS,
	--MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,CheckIn_Time,CheckIn_Address,CheckOut_Time,
	--CheckOut_Address,start_timestamp,device_model,battery,net_status,net_type,android_version,Revisit_Code)

	--SELECT User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,
	--LATITUDE,LONGITUDE,REMARKS,MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,
	--CheckIn_Time,CheckIn_Address,CheckOut_Time,CheckOut_Address,start_timestamp,device_model,battery,net_status,net_type,android_version,Revisit_Code
	--FROM Trans_ShopActivitySubmit_TodayData WHERE CAST(Createddate AS DATE)<CAST(GETDATE() AS DATE)

	--DELETE FROM Trans_ShopActivitySubmit_TodayData WHERE CAST(Createddate AS DATE)<CAST(GETDATE() AS DATE)
	--Rev 4.0 && Added some fields as SHOPACT_LAT,SHOPACT_LONG & SHOPACT_ADDRESS
	INSERT INTO tbl_trans_shopActivitysubmit
	(User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,LATITUDE,LONGITUDE,REMARKS,
	MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,CheckIn_Time,CheckIn_Address,CheckOut_Time,
	CheckOut_Address,start_timestamp,device_model,battery,net_status,net_type,android_version,Revisit_Code,SHOPACT_LAT,SHOPACT_LONG,SHOPACT_ADDRESS)

	SELECT User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,LATITUDE,LONGITUDE,REMARKS,
	MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,CheckIn_Time,CheckIn_Address,CheckOut_Time,CheckOut_Address,
	start_timestamp,device_model,battery,net_status,net_type,android_version,Revisit_Code,SHOPACT_LAT,SHOPACT_LONG,SHOPACT_ADDRESS
	FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WHERE CAST(Createddate AS DATE)<CAST(GETDATE() AS DATE)

	DELETE FROM [FSM_ITC_MIRROR]..Trans_ShopActivitySubmit_TodayData WHERE CAST(Createddate AS DATE)<CAST(GETDATE() AS DATE)
	--End of Rev 2.0

	--Rev 1.0
	DROP TABLE #TMPVISITDTTIME
	--End of Rev 1.0
	--Rev 3.0
	DROP TABLE #TMPVISITCOUNT
	--End of Rev 3.0

	SET NOCOUNT OFF
END
GO