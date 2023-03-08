IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_OPENAPI_PRODUCTDETAILS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_OPENAPI_PRODUCTDETAILS] AS' 
END
GO
ALTER PROC [dbo].[PRC_OPENAPI_PRODUCTDETAILS]
(
@ACTION VARCHAR(500)=NULL,
@ORDERCODE NVARCHAR(100)=NULL,
@ProductCode  NVARCHAR(500)=NULL,
@session_token NVARCHAR(MAX)=NULL,
@Uniquecont int=0,
@SearchKey NVARCHAR(MAX)=NULL
)
AS
/*************************************************************************************************************************
Written by Priti for V2.0.39 on 08/03/2023 - Implement Open API for Product Master
******************************************************************************************************************************/
BEGIN
    SET NOCOUNT ON
	declare @sql NVARCHAR(MAX)=''
	declare @topcount NVARCHAR(100)=@Uniquecont
	
	IF(@ACTION='GetHeaderProductDetails')
	BEGIN
		SELECT sProducts_Code ProductsCode,sProducts_Name ProductsName,sProducts_Description ProductsDescription, ISNULL(STK_MASTER_UOM.UOM_NAME, '') AS STKUOMNAME,
		ISNULL(SALES_MASTER_UOM.UOM_NAME, '') AS SALESUOMNAME,ISNULL(PRODUCTCLASS_NAME,'') CLASSCODE,ISNULL(BRAND_NAME,'') BRANDNAME
		FROM Master_sProducts 
		LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCT_STOCKUOM = STK_MASTER_UOM.UOM_ID 
		LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID
		LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE
		LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND
		where sProducts_Code=@ProductCode
		

	END
	Else IF(@ACTION='GetProductDetails')
	BEGIN
		
	    IF(isnull(@Uniquecont,0)<>0)
		BEGIN
				set @sql=' SELECT top '+@topcount+' sProducts_Code ProductsCode,sProducts_Name ProductsName,sProducts_Description ProductsDescription, ISNULL(STK_MASTER_UOM.UOM_NAME, '''') AS STKUOMNAME, '
				set @sql+='ISNULL(SALES_MASTER_UOM.UOM_NAME, '''') AS SALESUOMNAME,ISNULL(PRODUCTCLASS_NAME,'''') CLASSCODE,ISNULL(BRAND_NAME,'''') BRANDNAME '
				set @sql+='FROM Master_sProducts '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCT_STOCKUOM = STK_MASTER_UOM.UOM_ID '
				set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID '
				set @sql+='LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE '
				set @sql+='LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND '
				set @sql+='where (sProducts_Code like ''%'+@SearchKey+'%'') or (sProducts_Name like ''%'+@SearchKey+'%'')'

				--select  @sql
				EXEC SP_EXECUTESQL @sql
		
		END
		ELSE
		BEGIN
			set @sql='SELECT sProducts_Code ProductsCode,sProducts_Name ProductsName,sProducts_Description ProductsDescription, ISNULL(STK_MASTER_UOM.UOM_NAME,'' '') AS STKUOMNAME, '
			set @sql+='ISNULL(SALES_MASTER_UOM.UOM_NAME, '''') AS SALESUOMNAME,ISNULL(PRODUCTCLASS_NAME,'''') CLASSCODE,ISNULL(BRAND_NAME,'''') BRANDNAME '
			set @sql+='FROM Master_sProducts ' 
			set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCT_STOCKUOM = STK_MASTER_UOM.UOM_ID  '
			set @sql+='LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID '
			set @sql+='LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE '
			set @sql+='LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND '
			set @sql+='where (sProducts_Code like ''%'+@SearchKey+'%'') or (sProducts_Name like ''%'+@SearchKey+'%'')'

			--select  @sql
			EXEC SP_EXECUTESQL @sql
		END	
		
	END
	Else IF(@ACTION='GetProductMasterHeaderCredentials')
	BEGIN		
		select * from OPENAPI_CONFIG where MODULE_NAME='PRODUCT MASTER' and  GUID='01360645-267C-4690-ABC5-A3D66B300B87'	
	END
	SET NOCOUNT OFF
END	