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
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	SET LOCK_TIMEOUT -1

	BEGIN TRAN
		BEGIN TRY
			DECLARE @Guid uniqueidentifier = NEWID()

			IF OBJECT_ID('tempdb..#TEMP_TABLE') IS NOT NULL
				DROP TABLE #TEMP_TABLE

			CREATE TABLE #TEMP_TABLE
			([User_Id] BIGINT,[Shop_Id] NVARCHAR(100),visited_date DATE,visited_time DATETIME,spent_duration NVARCHAR(100),total_visit_count INT,Createddate DATETIME,Is_Newshopadd BIT,
			distance_travelled DECIMAL(18,2),IsFirstVisit BIT,device_model NVARCHAR(200),android_version NVARCHAR(200),battery NVARCHAR(200),net_status NVARCHAR(200),net_type NVARCHAR(200),
			start_timestamp NVARCHAR(200))
			CREATE NONCLUSTERED INDEX IX1 ON #TEMP_TABLE(Shop_Id ASC,visited_date ASC)

			INSERT INTO #TEMP_TABLE([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled,IsFirstVisit,device_model,
			android_version,battery,net_status,net_type,start_timestamp)

			SELECT DISTINCT @user_id,
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
			WHERE NOT EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) WHERE SHPACT.shop_id=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
			AND SHPACT.visited_date=XMLproduct.value('(visited_date/text())[1]','date') AND SHPACT.User_Id=@user_id)
		 
			IF NOT EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) 
			INNER JOIN #TEMP_TABLE A ON SHPACT.Shop_Id=A.Shop_Id AND SHPACT.visited_date=A.visited_date
			WHERE SHPACT.User_Id=@user_id)
				BEGIN
					INSERT INTO Trans_ShopActivitySubmit_TodayData (ActivityId,[User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled,
					IsFirstVisit,device_model,android_version,battery,net_status,net_type,start_timestamp)
	
					SELECT @Guid,[User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd,distance_travelled,IsFirstVisit,device_model,android_version,
					battery,net_status,net_type,start_timestamp
					FROM #TEMP_TABLE

					SELECT A.[Shop_Id] AS shopid,A.total_visit_count,A.visited_time,A.visited_date,A.spent_duration,CAST(1 AS BIT) AS IsShopUpdate,'Success' AS STRMESSAGE
					FROM #TEMP_TABLE A
					INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=A.Shop_Id
					WHERE EXISTS(SELECT SHPACT.ActivityId FROM Trans_ShopActivitySubmit_TodayData SHPACT WITH(NOLOCK) WHERE SHPACT.shop_id=A.Shop_Id 
					AND SHPACT.visited_date=A.visited_date AND SHPACT.User_Id=@user_id)
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
		COMMIT TRAN
	END TRY

	BEGIN CATCH
		ROLLBACK TRAN
		SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage
	END CATCH

	DROP TABLE #TEMP_TABLE

	SET NOCOUNT OFF
END