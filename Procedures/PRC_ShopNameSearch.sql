IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_ShopNameSearch]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_ShopNameSearch] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_ShopNameSearch]  
(
@USER_ID BIGINT=0,
@SearchKey varchaR(50) =''
)
AS
/*******************************************************************************************************************************************************************************************
1.0		v2.0.31		Pratik  	29-06-2022		On demand product search for "Quotation Details"
********************************************************************************************************************************************************************************************/
BEGIN
		select top(10)Shop_Name,Shop_Code from tbl_Master_shop
		where (Shop_Name like '%' + @SearchKey + '%') 
END