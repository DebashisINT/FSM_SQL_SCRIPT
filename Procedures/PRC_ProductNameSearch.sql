IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_ProductNameSearch]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_ProductNameSearch] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_ProductNameSearch]  
(
@USER_ID BIGINT=0,
@SearchKey varchaR(50) =''
)
AS
/*******************************************************************************************************************************************************************************************
1.0		v2.0.30		Pratik  	24-05-2022		On demand product search for "Stock Position Report"
********************************************************************************************************************************************************************************************/
BEGIN
		select top(10)sProducts_ID,sProducts_Code,sProducts_Name,sProducts_Description from Master_sProducts
		where (sProducts_Name like '%' + @SearchKey + '%') or  (sProducts_Code like '%' + @SearchKey + '%')
END
