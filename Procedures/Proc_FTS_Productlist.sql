--EXEC Proc_FTS_Productlist '',''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_Productlist]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_Productlist] AS' 
END
GO

ALTER PROCEDURE  [dbo].[Proc_FTS_Productlist]
(
@user_id NVARCHAR(50)=NULL,
@last_updated_date NVARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************
1.0					20-11-2020		Tanmoy		null value check in watt
2.0		v2.0.37		07-12-2022		Debashis	A new field added.Row: 773
***************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @sqlfetch VARCHAR(10)='1'
	DECLARE @sql NVARCHAR(MAX)

	IF(isnull(@last_updated_date,'') <>'')
		BEGIN
			IF EXISTS(SELECT sProducts_Code FROM Master_sProducts WHERE (CAST(sProducts_CreateTime AS DATE)=CAST(@last_updated_date AS DATE) 
			OR CAST(sProducts_ModifyTime AS DATE)=CAST(@last_updated_date AS DATE)))
				SET @sqlfetch='1'
			ELSE
				SET @sqlfetch='0'
		END

	SET @sql='SELECT COUNT(0) FROM Master_sProducts AS masprod '
	IF(@sqlfetch='0')
		SET @sql +='WHERE CAST(sProducts_CreateTime AS DATE)=CAST('''+@last_updated_date+''' AS DATE)'
	EXEC sp_ExecuteSQL @sql 

	--Rev 2.0 &&A new field sProduct_MRP is added
	SET @sql='SELECT sProducts_ID AS id,sProducts_Brand AS brand_id,masprod.ProductClass_Code AS category_id,sProducts_Size AS watt_id,brnd.Brand_Name AS brand,cls.ProductClass_Name AS category,
	ISNULL(msize.Size_Name,''Not Applicable'') AS watt,masprod.sProducts_Name AS product_name,CAST(ISNULL(masprod.sProduct_MRP,0.00) AS DECIMAL(18,2)) AS product_mrp_show
	FROM Master_sProducts AS masprod
	INNER JOIN tbl_master_brand brnd ON masprod.sProducts_Brand=brnd.Brand_Id 
	INNER JOIN Master_ProductClass AS cls ON masprod.ProductClass_Code=cls.ProductClass_ID
	LEFT OUTER JOIN Master_Size AS msize ON masprod.sProducts_Size=msize.Size_ID '

	IF(@sqlfetch='0')
		SET @sql +='WHERE CAST(sProducts_CreateTime AS DATE)=CAST('''+@last_updated_date+''' AS DATE)'
	EXEC sp_ExecuteSQL @sql

	SET NOCOUNT OFF
END