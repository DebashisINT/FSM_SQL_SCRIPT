IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIGPSLOCATIONTRACK]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIGPSLOCATIONTRACK] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_APIGPSLOCATIONTRACK]
(
@ACTION NVARCHAR(50),
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/*************************************************************************************************************************************************************
Written by : Debashis Talukder ON 20/02/2023
Module	   : GPS Location update by lists.Refer: Row:813
*************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='ADDGPSLOCATION'
		BEGIN
			IF OBJECT_ID('tempdb..#TEMPGPS') IS NOT NULL
				DROP TABLE #TEMPGPS
			CREATE TABLE #TEMPGPS([GPs_Id] NVARCHAR(MAX),[GPsDate] DATETIME,[Gps_OffTime] NVARCHAR(10),[Gps_on_Time] NVARCHAR(10),[Duration] NVARCHAR(10),[User_Id] BIGINT)
			BEGIN TRAN
				BEGIN TRY					
					INSERT INTO #TEMPGPS([GPs_Id],[GPsDate],[Gps_OffTime],[Gps_on_Time],[Duration],[User_Id])
					SELECT 
					XMLproduct.value('(gps_id/text())[1]','nvarchar(MAX)'),
					XMLproduct.value('(date/text())[1]','datetime'),
					XMLproduct.value('(gps_off_time/text())[1]','nvarchar(10)'),
					XMLproduct.value('(gps_on_time/text())[1]','nvarchar(10)'),
					XMLproduct.value('(duration/text())[1]','nvarchar(10)'),
					XMLproduct.value('(user_id/text())[1]','bigint')
					FROM
					@JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
					WHERE NOT EXISTS(SELECT gps_id FROM tbl_FTS_GPSSubmission WHERE [GPs_Id]=XMLproduct.value('(gps_id/text())[1]','nvarchar(MAX)'))

					IF NOT EXISTS(SELECT GPS.GPs_Id FROM tbl_FTS_GPSSubmission GPS WITH(NOLOCK) 
					INNER JOIN #TEMPGPS A ON GPS.GPs_Id=A.GPs_Id AND GPS.User_Id=A.User_Id)
						BEGIN
							INSERT INTO tbl_FTS_GPSSubmission([GPs_Id],[GPsDate],[Gps_OffTime],[Gps_on_Time],[Duration],[User_Id])
							SELECT [GPs_Id],[GPsDate],[Gps_OffTime],[Gps_on_Time],[Duration],[User_Id] FROM #TEMPGPS

							SELECT [GPs_Id],[GPsDate],[Gps_OffTime],[Gps_on_Time],[Duration],[User_Id],'Success' AS STRMESSAGE
							FROM #TEMPGPS A
							WHERE EXISTS(SELECT gps_id FROM tbl_FTS_GPSSubmission GPS WITH(NOLOCK) WHERE GPS.[GPs_Id]=A.GPs_Id AND GPS.User_Id=A.User_Id)
						END
					COMMIT TRAN
				END TRY

				BEGIN CATCH					
					ROLLBACK TRAN
					SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage
				END CATCH
			
			DROP TABLE #TEMPGPS
		END

	SET NOCOUNT OFF
END