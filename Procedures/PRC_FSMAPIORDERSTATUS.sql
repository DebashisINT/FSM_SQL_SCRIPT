IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMAPIORDERSTATUS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMAPIORDERSTATUS] AS' 
END
GO
ALTER PROCEDURE [dbo].[PRC_FSMAPIORDERSTATUS]
(
@USER_ID BIGINT=NULL
) --WITH ENCRYPTION
AS
/*************************************************************************************************************************************
Written by : Debashis Talukder ON 17/09/2024
Module	   : Order Status fetch.Refer: Row: 978
*************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	
	SELECT OrderCode AS Order_Code,ORDERSTATUS AS OrderStatus,CONVERT(NVARCHAR(10),Orderdate,120)+' '+CONVERT(NVARCHAR(8),CAST(Orderdate AS TIME),108) AS Order_date 
	FROM tbl_trans_fts_Orderupdate WHERE userID=@USER_ID

	SET NOCOUNT OFF
END
GO