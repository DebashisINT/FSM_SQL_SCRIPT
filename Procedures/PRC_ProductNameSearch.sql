IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_ProductNameSearch]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_ProductNameSearch] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_ProductNameSearch]  
(
@USER_ID BIGINT=0,
@SearchKey varchaR(50) ='',
-- Rev 2.0
@Action nvarchar(max)=''
-- End of Rev 2.0
)
AS
/*******************************************************************************************************************************************************************************************
1.0		v2.0.30		Pratik  	24-05-2022		On demand product search for "Stock Position Report"
2.0		V2.0.43		Sanchita	06-11-2023		On demand search is required in Product Master & Projection Entry. Mantis: 26858
********************************************************************************************************************************************************************************************/
BEGIN
		-- Rev 2.0
		IF(@action='SearchByColor')
		BEGIN
			 select top 10 Color_ID, Color_Name from Master_Color where Color_Name LIKE '%'+@SearchKey+'%' 
		END
		ELSE IF(@action='SearchByBrand')
		BEGIN
			 select top 10 Brand_Id ,Brand_Name from tbl_master_brand where Brand_IsActive=1 AND Brand_Name LIKE '%'+@SearchKey+'%'
		END
		ELSE
		BEGIN
		-- End of Rev 2.0
			select top(10)sProducts_ID,sProducts_Code,sProducts_Name,sProducts_Description from Master_sProducts
			where (sProducts_Name like '%' + @SearchKey + '%') or  (sProducts_Code like '%' + @SearchKey + '%')
	   -- Rev 2.0
	   END
	   -- End of Rev 2.0
	
END
GO