IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_PRODUCTSPECIALPRICE_LIST]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_PRODUCTSPECIALPRICE_LIST] AS' 
END
GO
ALTER PROCEDURE [dbo].[PRC_PRODUCTSPECIALPRICE_LIST]
(
@COMPANYID NVARCHAR(20),
@FINYEAR NVARCHAR(12),
@Products NVARCHAR(MAX),
@USERID INT ,
@ACTION NVARCHAR(200)
) --WITH ENCRYPTION
As
/*****************************************************************************************************************************************
Written by : Priti Roy ON 02/04/2024
Module	   : New Price Upload module shall be implemented named as Special Price Upload.Refer: 0027292

**************************************************************************************************************************/
BEGIN

	SET NOCOUNT ON
	Declare @sql NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#Product_List') IS NOT NULL
		DROP TABLE #Product_List
	CREATE TABLE #Product_List (Product_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Product_Id ON #Product_List (Product_Id ASC)
		IF @Products<>'0'
		BEGIN
			SET @sql='INSERT INTO #Product_List select sProducts_ID from Master_sProducts where sProducts_ID in ('+@Products+')'
			EXEC SP_EXECUTESQL @sql
			
		END	

		else
		Begin
			SET @sql='INSERT INTO #Product_List select sProducts_ID from Master_sProducts '
			EXEC SP_EXECUTESQL @sql
		End


	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'PRODUCTSPECIALPRICELIST') AND TYPE IN (N'U'))
		BEGIN
			Create table PRODUCTSPECIALPRICELIST
			(SEQ INT,
			USERID BIGINT,
			SlNo bigint,
			SPECIALPRICEID bigint,
			BRANCH_ID bigint,
			BRANCH Varchar(200),
			PRODUCT_ID bigint,
			PRODUCTCODE varchar(80),
			PRODUCTNAME varchar(100),
			SPECIALPRICE NUMERIC(18,2)

			)

		CREATE NONCLUSTERED INDEX IX1PF_PURREGPROD_RPT ON PRODUCTSPECIALPRICELIST (SEQ)
	END
	DELETE FROM PRODUCTSPECIALPRICELIST where USERID=@USERID


	IF @ACTION='ALL'
	BEGIN
			INSERT INTO PRODUCTSPECIALPRICELIST(SEQ ,USERID ,SlNo,SPECIALPRICEID ,BRANCH_ID ,BRANCH ,PRODUCT_ID ,PRODUCTCODE ,PRODUCTNAME ,SPECIALPRICE )

		
			SELECT ROW_NUMBER() OVER (ORDER BY ID DESC),@USERID,ROW_NUMBER() OVER (ORDER BY ID DESC) SlNo,ID,MB.BRANCH_ID,branch_description,sProducts_ID,PRODUCT_CODE,sProducts_Name,SPECIAL_PRICE 
			FROM PRODUCT_SPECIAL_PRICE_BRANCHWISE PSPB
			INNER JOIN tbl_master_branch MB ON MB.BRANCH_ID=PSPB.BRANCH_ID
			INNER JOIN Master_sProducts  MP ON MP.sProducts_Code=PSPB.PRODUCT_CODE

			where EXISTS (select Product_Id from #Product_List as PL where PL.Product_Id=PSPB.PRODUCT_ID)	

		--WHERE ISNULL(TSO.ISPROJECTORDER,0)=0
		--and CAST(Order_Date AS DATE) BETWEEN @FROMDATE AND @TODATE 
		--and Order_CompanyID=@COMPANYID and Order_FinYear=@FINYEAR
		--AND EXISTS (select Branch_Id from #Branch_List as BR where BR.Branch_Id=Order_BranchId)	
	END

	

	DROP TABLE #Product_List
	SET NOCOUNT OFF
END
GO