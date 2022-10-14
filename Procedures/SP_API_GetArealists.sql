IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SP_API_GetArealists]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [SP_API_GetArealists] AS' 
END
GO

ALTER PROCEDURE [dbo].[SP_API_GetArealists]
(
@user_id NVARCHAR(50)=NULL,
@city_id NVARCHAR(20)=NULL,
@creater_user_id NVARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
/************************************************************************************************************************************************
1.0			TANMOY			15-05-2020			Create SP
2.0			TANMOY			02-06-2020			Area list show shop area and user wise
3.0                  INDRANIL            05-06-2020                 Area will filter with state id instead of city id .
************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF ISNULL(@user_id,'')<>''
		BEGIN
			DECLARE @state_id bigint=(select state_id from tbl_master_city WITH(NOLOCK) where city_id=@city_id)
			SELECT DISTINCT area_id,area_name  FROM (
			SELECT convert(NVARCHAR(20),ara.area_id) AS area_id,ara.area_name FROM tbl_master_area ara WITH(NOLOCK) 
			INNER JOIN TBL_MASTER_SHOP SHOP WITH(NOLOCK) ON SHOP.Area_id=ara.area_id
			WHERE shop.stateId=@state_id AND SHOP.Shop_CreateUser=@user_id
			) A ORDER BY A.area_name 
		END
	ELSE
		BEGIN
			SELECT convert(NVARCHAR(20),area_id) AS area_id,area_name FROM tbl_master_area WITH(NOLOCK) WHERE city_id=@city_id ORDER BY area_name
		END

	SET NOCOUNT OFF
END