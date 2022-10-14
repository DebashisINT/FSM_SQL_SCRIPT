--exec PRC_APIshoptype @Action='UserCheck',@UserID=11708

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_AllAPIshoptype]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_AllAPIshoptype] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_AllAPIshoptype]
(
@User_id BIGINT=NULL
) --WITH ENCRYPTION
AS
/******************************************************************************************************
1.0		07-07-2021		Tanmoy		ADD EXTRA TWO PARAMETERS
******************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	SELECT Name AS shoptype_name,CONVERT(NVARCHAR(10),TypeId) AS shoptype_id,
	CONVERT(INT,CurrentStockEnable) AS CurrentStockEnable,
	CONVERT(INT,CompetitorStockEnable) AS CompetitorStockEnable
	FROM tbl_shoptype TYP WITH(NOLOCK) 
	WHERE IsActive=1 order by TypeId
	
	SET NOCOUNT OFF
END