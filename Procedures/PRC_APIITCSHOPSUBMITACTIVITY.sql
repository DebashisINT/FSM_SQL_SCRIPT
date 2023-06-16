IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIITCSHOPSUBMITACTIVITY]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIITCSHOPSUBMITACTIVITY] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_APIITCSHOPSUBMITACTIVITY]
(
@session_token NVARCHAR(MAX)=NULL,
@user_id NVARCHAR(50)=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 19/10/2022
Module	   : ITC Shop Visit & Syncronization.Refer: 0025362,0025375 & Row:748
1.0		v2.0.38		Debashis	20-03-2023		Visit & Revisit data of ITC are not sync in Trans_ShopActivitySubmit_TodayData table.
												Temporary table was not working while using in different sessions and went to Deadlock situation.So to over come that situation
												used Global Temporary table instead of Temporary table and resolved the issue.Refer: 0025740
2.0		v2.0.39		Debashis	04-04-2023		Visit & Revisit data of ITC are not sync in Trans_ShopActivitySubmit_TodayData table due to Deadlock.
												Now it has been taken care of.Refer: 0025776
3.0		v2.0.40		Debashis	25-05-2023		When Shopsubmission/ITCShopVisited this revisit/visit sync api is called tbl_Master_shop -> Lastvisit_date this column 
												should also update with specific date-time.Refer: 0026228
4.0		v2.0.40		Debashis	16-06-2023		Shopsubmission/ITCShopVisited
												Case : If IsUpdateVisitDataInTodayTable this settings is true then with Addshop api the data insert in both tbl_Master_shop & 
												Trans_ShopActivitySubmit_TodayData table.
												At app logout Shopsubmission/ITCShopVisited this api is called with some updated data for the shop & needs to be updated in 
												Trans_ShopActivitySubmit_TodayData this table through Shopsubmission/ITCShopVisited this api.Refer: 0026359
****************************************************************************************************************************************************************************/
BEGIN
	--Rev 2.0
	--SET NOCOUNT ON
	SET NOCOUNT, XACT_ABORT ON
	--End of Rev 2.0

	SET LOCK_TIMEOUT -1

	BEGIN TRAN
		BEGIN TRY
			DECLARE @Guid uniqueidentifier = NEWID()

			--Rev 1.0
			--IF OBJECT_ID('tempdb..#TEMP_TABLE') IS NOT NULL
			--	DROP TABLE #TEMP_TABLE

			--CREATE TABLE #TEMP_TABLE
			--([User_Id] BIGINT,[Shop_Id] NVARCHAR(100),visited_date DATE,visited_time DATETIME,spent_duration NVARCHAR(100),total_visit_count INT,Createddate DATETIME,Is_Newshopadd BIT,
			--distance_travelled DECIMAL(18,2),IsFirstVisit BIT,device_model NVARCHAR(200),android_version NVARCHAR(200),battery NVARCHAR(200),net_status NVARCHAR(200),net_type NVARCHAR(200),
			--start_timestamp NVARCHAR(200))
			--CREATE NONCLUSTERED INDEX IX1 ON #TEMP_TABLE(Shop_Id ASC,visited_date ASC)

			--INSERT INTO #TEMP_TABLE([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled,IsFirstVisit,device_model,
			--android_version,battery,net_status,net_type,start_timestamp)
			--Rev 2.0
			--IF OBJECT_ID('tempdb..##TEMP_TABLE') IS NOT NULL
			--	DROP TABLE ##TEMP_TABLE

			--CREATE TABLE ##TEMP_TABLE
			--([User_Id] BIGINT,[Shop_Id] NVARCHAR(100),visited_date DATE,visited_time DATETIME,spent_duration NVARCHAR(100),total_visit_count INT,Createddate DATETIME,Is_Newshopadd BIT,
			--distance_travelled DECIMAL(18,2),IsFirstVisit BIT,device_model NVARCHAR(200),android_version NVARCHAR(200),battery NVARCHAR(200),net_status NVARCHAR(200),net_type NVARCHAR(200),
			--start_timestamp NVARCHAR(200))
			--CREATE NONCLUSTERED INDEX IX1 ON ##TEMP_TABLE(Shop_Id ASC,visited_date ASC)

			--INSERT INTO ##TEMP_TABLE([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled,IsFirstVisit,device_model,
			--android_version,battery,net_status,net_type,start_timestamp)
			----End of Rev 1.0

			--SELECT DISTINCT @user_id,
			--XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
			--XMLproduct.value('(visited_date/text())[1]','date'),
			--XMLproduct.value('(visited_time/text())[1]','datetime'),
			--XMLproduct.value('(spent_duration/text())[1]','NVARCHAR(100)'),
			--XMLproduct.value('(total_visit_count/text())[1]','int'),
			--GETDATE(),0,XMLproduct.value('(distance_travelled/text())[1]','decimal(18,2)'),
			--CASE WHEN XMLproduct.value('(isFirstShopVisited/text())[1]','NVARCHAR(40)')='true' THEN  1 ELSE 0 END,
			--XMLproduct.value('(device_model/text())[1]','NVARCHAR(100)'),
			--XMLproduct.value('(android_version/text())[1]','NVARCHAR(100)'),
			--XMLproduct.value('(battery/text())[1]','NVARCHAR(100)'),
			--XMLproduct.value('(net_status/text())[1]','NVARCHAR(100)'),
			--XMLproduct.value('(net_type/text())[1]','NVARCHAR(100)'),
			--XMLproduct.value('(start_timestamp/text())[1]','NVARCHAR(100)')
			--FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
			--INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')
			--WHERE NOT EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) WHERE SHPACT.shop_id=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
			--AND SHPACT.visited_date=XMLproduct.value('(visited_date/text())[1]','date') AND SHPACT.User_Id=@user_id)
			--End of Rev 2.0
			
			--Rev 1.0
			--IF NOT EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) 
			--INNER JOIN #TEMP_TABLE A ON SHPACT.Shop_Id=A.Shop_Id AND SHPACT.visited_date=A.visited_date
			--WHERE SHPACT.User_Id=@user_id)
			--Rev 2.0
			--IF NOT EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) 
			--INNER JOIN ##TEMP_TABLE A ON SHPACT.Shop_Id=A.Shop_Id AND SHPACT.visited_date=A.visited_date
			--WHERE SHPACT.User_Id=@user_id)
			IF NOT EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) 
			INNER JOIN @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct) ON SHPACT.shop_id=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
			AND SHPACT.visited_date=XMLproduct.value('(visited_date/text())[1]','date') AND SHPACT.User_Id=@user_id)
			--End of Rev 2.0
			--End of Rev 1.0
				BEGIN
					INSERT INTO Trans_ShopActivitySubmit_TodayData (ActivityId,[User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled,
					IsFirstVisit,device_model,android_version,battery,net_status,net_type,start_timestamp)
					
					--Rev 1.0
					--SELECT @Guid,[User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled,IsFirstVisit,device_model,android_version,
					--battery,net_status,net_type,start_timestamp
					--FROM #TEMP_TABLE

					--SELECT A.[Shop_Id] AS shopid,A.total_visit_count,A.visited_time,A.visited_date,A.spent_duration,CAST(1 AS BIT) AS IsShopUpdate,'Success' AS STRMESSAGE
					--FROM #TEMP_TABLE A
					--INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=A.Shop_Id
					--WHERE EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) WHERE SHPACT.shop_id=A.Shop_Id 
					--AND SHPACT.visited_date=A.visited_date AND SHPACT.User_Id=@user_id)
					--Rev 2.0
					--SELECT @Guid,[User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled,IsFirstVisit,device_model,android_version,
					--battery,net_status,net_type,start_timestamp
					--FROM ##TEMP_TABLE

					--SELECT A.[Shop_Id] AS shopid,A.total_visit_count,A.visited_time,A.visited_date,A.spent_duration,CAST(1 AS BIT) AS IsShopUpdate,'Success' AS STRMESSAGE
					--FROM ##TEMP_TABLE A
					--INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=A.Shop_Id
					--WHERE EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) WHERE SHPACT.shop_id=A.Shop_Id 
					--AND SHPACT.visited_date=A.visited_date AND SHPACT.User_Id=@user_id)
					----End of Rev 1.0
					SELECT DISTINCT @Guid,@user_id,
					XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(visited_date/text())[1]','date'),
					XMLproduct.value('(visited_time/text())[1]','datetime'),
					XMLproduct.value('(spent_duration/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(total_visit_count/text())[1]','int'),
					GETDATE(),0,XMLproduct.value('(distance_travelled/text())[1]','decimal(18,2)'),
					CASE WHEN XMLproduct.value('(isFirstShopVisited/text())[1]','NVARCHAR(40)')='true' THEN  1 ELSE 0 END,
					XMLproduct.value('(device_model/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(android_version/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(battery/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(net_status/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(net_type/text())[1]','NVARCHAR(100)'),
					XMLproduct.value('(start_timestamp/text())[1]','NVARCHAR(100)')
					FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
					INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')

					SELECT
					XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')	AS shopid,
					XMLproduct.value('(total_visit_count/text())[1]','int')	AS total_visit_count,
					XMLproduct.value('(visited_time/text())[1]','datetime')	AS visited_time,
					XMLproduct.value('(visited_date/text())[1]','date')	AS visited_date,
					XMLproduct.value('(spent_duration/text())[1]','NVARCHAR(50)') AS spent_duration,
					CAST(1 AS BIT) AS IsShopUpdate,'Success' AS STRMESSAGE
					FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
					WHERE EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) WHERE SHPACT.shop_id=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
					AND SHPACT.visited_date=XMLproduct.value('(visited_date/text())[1]','date') AND SHPACT.User_Id=@user_id)
					--End of Rev 2.0
					UNION ALL
					SELECT
					XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')	AS shopid,
					XMLproduct.value('(total_visit_count/text())[1]','int')	AS total_visit_count,
					XMLproduct.value('(visited_time/text())[1]','datetime')	AS visited_time,
					XMLproduct.value('(visited_date/text())[1]','date')	AS visited_date,
					XMLproduct.value('(spent_duration/text())[1]','NVARCHAR(50)') AS spent_duration,
					CAST(0 AS BIT) AS IsShopUpdate,'Success' AS STRMESSAGE
					FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
					WHERE NOT EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) WHERE SHPACT.shop_id=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
					AND SHPACT.visited_date=XMLproduct.value('(visited_date/text())[1]','date') AND SHPACT.User_Id=@user_id)
				END
			--Rev 4.0
			ELSE
				BEGIN
					UPDATE TDSHS SET spent_duration=XMLproduct.value('(spent_duration/text())[1]','nvarchar(100)') ,
					distance_travelled=XMLproduct.value('(distance_travelled/text())[1]','nvarchar(100)')
					,REMARKS=XMLproduct.value('(feedback/text())[1]','varchar(500)')
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
					FROM tbl_trans_shopActivitysubmit TDSHS
					INNER JOIN 	@JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  
					ON TDSHS.Shop_Id=XMLproduct.value('(shop_id/text())[1]','nvarchar(100)') AND TDSHS.visited_date=XMLproduct.value('(visited_date/text())[1]','date')
					AND TDSHS.spent_duration='00:00:00' AND TDSHS.User_Id=@user_id

					SELECT
					XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')	AS shopid,
					'Updated' AS STRMESSAGE
					FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
					WHERE EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) WHERE SHPACT.shop_id=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
					AND SHPACT.visited_date=XMLproduct.value('(visited_date/text())[1]','date') AND SHPACT.User_Id=@user_id)
				END
			--End of Rev 4.0
				--Rev 3.0
				UPDATE MS SET Lastvisit_date=XMLproduct.value('(visited_date/text())[1]','date')
				FROM [tbl_Master_shop] MS
				INNER JOIN 	@JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  
				ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','nvarchar(100)')
				--End of Rev 3.0
		COMMIT TRAN
	END TRY

	BEGIN CATCH
		ROLLBACK TRAN
		SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage
	END CATCH

	--Rev 1.0
	--DROP TABLE #TEMP_TABLE
	--Rev 2.0
	--DROP TABLE ##TEMP_TABLE
	--End of Rev 2.0
	--End of Rev 1.0

	SET NOCOUNT OFF
END