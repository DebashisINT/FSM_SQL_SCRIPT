--exec PRC_APIshoptype @Action='UserCheck',@UserID=11708

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIshoptype]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIshoptype] AS' 
END
GO

ALTER PROCEDURE  [dbo].[PRC_APIshoptype]
(
@User_id BIGINT=NULL
) --WITH ENCRYPTION
AS
/******************************************************************************************************
1.0		24-06-2020		Tanmoy		Shop type show user wise
2.0		07-07-2021		Tanmoy		ADD EXTRA TWO PARAMETERS
******************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	SELECT Name AS shoptype_name,CONVERT(NVARCHAR(10),TypeId) AS shoptype_id,
	CONVERT(INT,CurrentStockEnable) AS CurrentStockEnable,
	CONVERT(INT,CompetitorStockEnable) AS CompetitorStockEnable
	 FROM tbl_shoptype TYP WITH(NOLOCK) 
	INNER JOIN FTS_UserPartyCreateAccess MAP WITH(NOLOCK) ON MAP.Shop_TypeId=TYP.TypeId
	WHERE IsActive=1 AND MAP.User_Id=@User_id order by TypeId
	
	SET NOCOUNT OFF
END