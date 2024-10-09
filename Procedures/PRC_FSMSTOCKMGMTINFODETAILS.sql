IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMSTOCKMGMTINFODETAILS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMSTOCKMGMTINFODETAILS] AS' 
END
GO

ALTER PROCEDURE  [dbo].[PRC_FSMSTOCKMGMTINFODETAILS]
(
@ACTION NVARCHAR(50),
@USER_ID BIGINT=NULL,
@STOCK_SHOPCODE NVARCHAR(200)=NULL,
@STOCK_PRODUCTID BIGINT=NULL,
@SUBMITTED_QTY DECIMAL(18,2)=NULL
) --WITH ENCRYPTION
AS
/************************************************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 30/09/2024
Module	   : Product Stock Management Details.Refer: Row: 982 & 984
************************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='FETCHALLSTOCK'
		BEGIN
			SELECT STOCK_SHOPCODE AS stock_shopcode,ISNULL(STOCK_SHOPENTITYCODE,'') AS stock_shopentitycode,STOCK_PRODUCTID AS stock_productid,STOCK_PRODUCTNAME AS stock_productname,
			CAST(STOCK_PRODUCTQTY AS DECIMAL(18,2)) AS stock_productqty,CAST(STOCK_PRODUCTBALQTY AS DECIMAL(18,2)) AS stock_productbalqty
			FROM FSM_MASTER_CURRENTSTOCK
		END
	IF @ACTION='UPDATEPRODBALSTOCK'
		BEGIN
			IF EXISTS(SELECT * FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_SHOPCODE=@STOCK_SHOPCODE AND STOCK_PRODUCTID=@STOCK_PRODUCTID)
				BEGIN
					UPDATE FSM_MASTER_CURRENTSTOCK SET STOCK_PRODUCTBALQTY=CAST(STOCK_PRODUCTBALQTY AS DECIMAL(18,2))-@SUBMITTED_QTY
					WHERE STOCK_SHOPCODE=@STOCK_SHOPCODE AND STOCK_PRODUCTID=@STOCK_PRODUCTID

					SELECT 1
				END
		END

	SET NOCOUNT OFF
END
GO