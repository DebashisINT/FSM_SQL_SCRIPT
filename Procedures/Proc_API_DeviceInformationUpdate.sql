IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_API_DeviceInformationUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_API_DeviceInformationUpdate] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_API_DeviceInformationUpdate]
(
@session_token varchar(MAX)=NULL,
@user_id varchar(50)=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION 
AS
/****************************************************************************************************************
1.0			TANMOY		19-08-2020		INSERT DEVICE INFORMATION
2.0			Debashis	03-01-2022		Added two new fields as Available_Storage & Total_Storage
****************************************************************************************************************/
BEGIN
	
	IF EXISTS (SELECT 1 FROM FTS_DeviceInformation WHERE CONVERT(NVARCHAR(10),DATE,120) < CONVERT(NVARCHAR(10),GETDATE(),120))
	BEGIN
		iNSERT INTO FTS_DeviceInformation_Arch
		SELECT * FROM FTS_DeviceInformation WHERE CONVERT(NVARCHAR(10),DATE,120) < CONVERT(NVARCHAR(10),GETDATE(),120)

		DELETE FROM FTS_DeviceInformation WHERE CONVERT(NVARCHAR(10),DATE,120) < CONVERT(NVARCHAR(10),GETDATE(),120)
	END

	--Rev 2.0 && Added two new fields as Available_Storage & Total_Storage
	INSERT INTO FTS_DeviceInformation (USER_ID,DeviceInformation_Code,DATE,BATTERY_STATUS,BATTERY_PERCENTAGE,NETWORK_TYPE,MOBILE_NETWORK_TYPE,DEVICE_MODEL,ANDROID_VERSION,AVAILABLE_STORAGE,
	TOTAL_STORAGE,CREATE_DATE)
    select @user_id	,
	XMLproduct.value('(id/text())[1]','nvarchar(100)'),
	XMLproduct.value('(date_time/text())[1]','datetime'),
	XMLproduct.value('(battery_status/text())[1]','nvarchar(500)'),
	XMLproduct.value('(battery_percentage/text())[1]','nvarchar(100)'),
	XMLproduct.value('(network_type/text())[1]','nvarchar(500)'),
	XMLproduct.value('(mobile_network_type/text())[1]','nvarchar(500)'),	
	XMLproduct.value('(device_model/text())[1]','nvarchar(500)'),
	XMLproduct.value('(android_version/text())[1]','nvarchar(500)'),
	XMLproduct.value('(Available_Storage/text())[1]','nvarchar(500)'),
	XMLproduct.value('(Total_Storage/text())[1]','nvarchar(500)'),
	GETDATE() 
	FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)		
	WHERE NOT EXISTS(select ID from [FTS_DeviceInformation] where DATE=XMLproduct.value('(date_time/text())[1]','datetime')	and User_Id=@user_id)

	select 1

END