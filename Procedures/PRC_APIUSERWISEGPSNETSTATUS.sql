IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIUSERWISEGPSNETSTATUS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIUSERWISEGPSNETSTATUS] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIUSERWISEGPSNETSTATUS]
(
@SESSION_TOKEN NVARCHAR(MAX)=NULL,
@USER_ID NVARCHAR(50)=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION 
AS
/**********************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 22/09/2022
Purpose : For User Wise GPS Status API.Row: 743
**********************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
		
	INSERT INTO FSMUSERWISEGPSNETSTATUS (USER_ID,DATE_TIME,GPS_SERVICE_STATUS,NETWORK_STATUS,CREATE_DATE)
    SELECT @USER_ID	,
	XMLproduct.value('(date_time/text())[1]','datetime'),
	XMLproduct.value('(gps_service_status/text())[1]','nvarchar(200)'),
	XMLproduct.value('(network_status/text())[1]','nvarchar(200)'),
	GETDATE()
	FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)		
	WHERE NOT EXISTS(SELECT ID FROM FSMUSERWISEGPSNETSTATUS WHERE DATE_TIME=XMLproduct.value('(date_time/text())[1]','datetime') AND USER_ID=@USER_ID)

	IF EXISTS(SELECT ID FROM FSMUSERWISEGPSNETSTATUS  
	INNER JOIN 	@JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  ON DATE_TIME=XMLproduct.value('(date_time/text())[1]','datetime') WHERE USER_ID=@USER_ID)
		SELECT 1

	SET NOCOUNT OFF
END