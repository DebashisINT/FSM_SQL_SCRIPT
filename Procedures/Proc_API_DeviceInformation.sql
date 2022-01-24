IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_API_DeviceInformation]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_API_DeviceInformation] AS' 
END
GO
ALTER PROCEDURE [dbo].[Proc_API_DeviceInformation]
(
@user_id bigint =null
) --WITH ENCRYPTION
AS
/****************************************************************************************************************
1.0			Debashis	03-01-2022		Added two new fields as Available_Storage & Total_Storage
****************************************************************************************************************/
BEGIN
	--Rev 1.0 && Added two new fields as Available_Storage & Total_Storage
	select DeviceInformation_Code id,DATE date_time,BATTERY_STATUS battery_status,BATTERY_PERCENTAGE battery_percentage,
	NETWORK_TYPE network_type,MOBILE_NETWORK_TYPE mobile_network_type,DEVICE_MODEL device_model,ANDROID_VERSION android_version,AVAILABLE_STORAGE AS Available_Storage, 
	TOTAL_STORAGE AS Total_Storage FROM FTS_DeviceInformation where USER_ID=@user_id
	UNION ALL
	select DeviceInformation_Code id,DATE date_time,BATTERY_STATUS battery_status,BATTERY_PERCENTAGE battery_percentage,
	NETWORK_TYPE network_type,MOBILE_NETWORK_TYPE mobile_network_type,DEVICE_MODEL device_model,ANDROID_VERSION android_version,AVAILABLE_STORAGE AS Available_Storage, 
	TOTAL_STORAGE AS Total_Storage from FTS_DeviceInformation_Arch where USER_ID=@user_id
END