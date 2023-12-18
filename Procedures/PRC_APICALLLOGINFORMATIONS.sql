IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APICALLLOGINFORMATIONS]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APICALLLOGINFORMATIONS] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_APICALLLOGINFORMATIONS]
(
@ACTION NVARCHAR(20),
@USERID INT=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 18/12/2023
Purpose : For Call Log API.Row: 888 to 889
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

		IF @ACTION='CALLLOGLISTSAVE'
			BEGIN
				INSERT INTO FSMCALLHISTORYLIST(USERID,SHOP_ID,CALL_NUMBER,CALL_DATE,CALL_TIME,CALL_DATE_TIME,CALL_TYPE,CALL_DURATION_SEC,CALL_DURATION,CREATED_BY,CREATED_DATE)
				SELECT @USERID,
				XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
				XMLproduct.value('(call_number/text())[1]','NVARCHAR(20)'),
				XMLproduct.value('(call_date/text())[1]','NVARCHAR(10)'),
				XMLproduct.value('(call_time/text())[1]','NVARCHAR(10)'),
				XMLproduct.value('(call_date_time/text())[1]','datetime'),
				XMLproduct.value('(call_type/text())[1]','NVARCHAR(50)'),
				XMLproduct.value('(call_duration_sec/text())[1]','NVARCHAR(10)'),
				XMLproduct.value('(call_duration/text())[1]','NVARCHAR(20)'),
				@USERID,GETDATE()
				FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
				INNER JOIN tbl_Master_shop WITH(NOLOCK) ON Shop_Code=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)')

				SELECT @USERID,
				XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)'),
				XMLproduct.value('(call_number/text())[1]','NVARCHAR(20)'),
				XMLproduct.value('(call_date/text())[1]','NVARCHAR(10)'),
				XMLproduct.value('(call_time/text())[1]','NVARCHAR(10)'),
				XMLproduct.value('(call_date_time/text())[1]','datetime'),
				XMLproduct.value('(call_type/text())[1]','NVARCHAR(50)'),
				XMLproduct.value('(call_duration_sec/text())[1]','NVARCHAR(10)'),
				XMLproduct.value('(call_duration/text())[1]','NVARCHAR(20)'),
				@USERID,GETDATE()
				FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)
				WHERE EXISTS(SELECT CALLHIST.USERID FROM FSMCALLHISTORYLIST CALLHIST WITH(NOLOCK) WHERE CALLHIST.shop_id=XMLproduct.value('(shop_id/text())[1]','NVARCHAR(100)') 
				AND CALLHIST.USERID=@USERID)
			END
		ELSE IF @ACTION='CALLLOGLIST'
			BEGIN
				SELECT USERID,SHOP_ID AS shop_id,CALL_NUMBER AS call_number,CALL_DATE AS call_date,CALL_TIME AS call_time,CALL_DATE_TIME AS call_date_time,CALL_TYPE AS call_type,CALL_DURATION_SEC AS call_duration_sec,
				CALL_DURATION AS call_duration,CAST(1 AS BIT) AS isUploaded FROM FSMCALLHISTORYLIST
				WHERE USERID=@USERID
			END
											   
	SET NOCOUNT OFF
END
GO