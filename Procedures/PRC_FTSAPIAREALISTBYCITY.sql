IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPIAREALISTBYCITY]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPIAREALISTBYCITY] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSAPIAREALISTBYCITY]
(
@ACTION NVARCHAR(50),
@USER_ID BIGINT=NULL,
@CITY_ID BIGINT=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 17/05/2023
Purpose : For Area Location Informations.
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @STATE BIGINT

	IF @ACTION='AreaListByCity'
		BEGIN
			SET @STATE=(SELECT TOP(1)add_state FROM tbl_master_address ADRS
						INNER JOIN tbl_master_user USR ON USR.USER_CONTACTID=ADRS.add_cntId
						where ADRS.add_addressType='Office' AND USR.USER_ID=@USER_ID)


			SELECT CONVERT(NVARCHAR(10),AREA.area_id) AS area_location_id,AREA.area_name AS area_location_name,ISNULL(AREA.Lattitude,'0.00') AS area_lat,ISNULL(AREA.Longitude,'0.00') AS area_long
			FROM tbl_master_area AREA
			INNER JOIN tbl_master_city CTY ON AREA.city_id=CTY.city_id 
			WHERE CTY.state_id=@STATE AND CTY.city_id=@CITY_ID AND AREA.area_name IS NOT NULL 
			ORDER BY area_name
		END

	SET NOCOUNT OFF
END