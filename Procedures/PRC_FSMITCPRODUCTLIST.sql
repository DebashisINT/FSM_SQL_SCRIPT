--EXEC Proc_FTS_Productlist '',''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMITCPRODUCTLIST]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMITCPRODUCTLIST] AS' 
END
GO

ALTER PROCEDURE  [dbo].[PRC_FSMITCPRODUCTLIST]
(
@ACTION NVARCHAR(30),
@USER_ID BIGINT=NULL
) --WITH ENCRYPTION
AS
/************************************************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 03/04/2024
Module	   : ITC Product Listing.Refer: 0027291 and Row: 909 & 910
************************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='GETPRODUCTLISTS'
		BEGIN
			--Rev 1.0
			IF (SELECT COUNT(0) FROM PRODUCT_BRANCH_MAP WHERE CHILDEMP_INTERNALID=@USERINTERNALID)>0
				BEGIN
			--End of Rev 1.0
					SELECT sProducts_ID AS product_id,MP.sProducts_Name AS product_name,sProducts_Brand AS brand_id,brnd.Brand_Name AS brand_name,PCLS.ProductClass_ID AS category_id,
					PCLS.ProductClass_Name AS category_name,sProducts_Size AS watt_id,ISNULL(MPSIZE.Size_Name,'Not Applicable') AS watt_name,UOM.UOM_Name AS UOM
					FROM Master_sProducts AS MP
					INNER JOIN Master_UOM UOM ON MP.sProducts_TradingLotUnit=UOM.UOM_ID
					INNER JOIN tbl_master_brand BRND ON MP.sProducts_Brand=BRND.Brand_Id
					INNER JOIN Master_ProductClass AS PCLS ON MP.ProductClass_Code=PCLS.ProductClass_ID
					--Rev 1.0
					INNER JOIN (SELECT PRODUCT_ID FROM PRODUCT_BRANCH_MAP MAP
					INNER JOIN tbl_master_user USR ON MAP.CHILDEMP_INTERNALID=USR.user_contactId AND USR.user_id=@USER_ID
					GROUP BY PRODUCT_ID) PBMAP ON MP.sProducts_ID=PBMAP.PRODUCT_ID
					--End of Rev 1.0
					LEFT OUTER JOIN Master_Size AS MPSIZE ON MP.sProducts_Size=MPSIZE.Size_ID
					WHERE MP.sProduct_Status<>'D'
			--Rev 1.0
				END
			ELSE IF (SELECT COUNT(0) FROM PRODUCT_BRANCH_MAP WHERE PARENTEMP_INTERNALID=@USERINTERNALID)>0
				BEGIN
					SELECT sProducts_ID AS product_id,MP.sProducts_Name AS product_name,sProducts_Brand AS brand_id,brnd.Brand_Name AS brand_name,PCLS.ProductClass_ID AS category_id,
					PCLS.ProductClass_Name AS category_name,sProducts_Size AS watt_id,ISNULL(MPSIZE.Size_Name,'Not Applicable') AS watt_name,UOM.UOM_Name AS UOM
					FROM Master_sProducts AS MP
					INNER JOIN Master_UOM UOM ON MP.sProducts_TradingLotUnit=UOM.UOM_ID
					INNER JOIN tbl_master_brand BRND ON MP.sProducts_Brand=BRND.Brand_Id
					INNER JOIN Master_ProductClass AS PCLS ON MP.ProductClass_Code=PCLS.ProductClass_ID
					INNER JOIN (SELECT PRODUCT_ID FROM PRODUCT_BRANCH_MAP MAP
					INNER JOIN tbl_master_user USR ON MAP.PARENTEMP_INTERNALID=USR.user_contactId AND USR.user_id=11984
					GROUP BY PRODUCT_ID) PBMAP ON MP.sProducts_ID=PBMAP.PRODUCT_ID
					LEFT OUTER JOIN Master_Size AS MPSIZE ON MP.sProducts_Size=MPSIZE.Size_ID
					WHERE MP.sProduct_Status<>'D'
				END
			ELSE
				BEGIN
					SELECT sProducts_ID AS product_id,MP.sProducts_Name AS product_name,sProducts_Brand AS brand_id,brnd.Brand_Name AS brand_name,PCLS.ProductClass_ID AS category_id,
					PCLS.ProductClass_Name AS category_name,sProducts_Size AS watt_id,ISNULL(MPSIZE.Size_Name,'Not Applicable') AS watt_name,UOM.UOM_Name AS UOM
					FROM Master_sProducts AS MP
					INNER JOIN Master_UOM UOM ON MP.sProducts_TradingLotUnit=UOM.UOM_ID
					INNER JOIN tbl_master_brand BRND ON MP.sProducts_Brand=BRND.Brand_Id
					INNER JOIN Master_ProductClass AS PCLS ON MP.ProductClass_Code=PCLS.ProductClass_ID
					INNER JOIN (SELECT PRODUCT_ID FROM PRODUCT_BRANCH_MAP MAP
					INNER JOIN #BRANCH_LIST BR ON MAP.BRANCH_ID=BR.Branch_Id
					GROUP BY PRODUCT_ID) PBMAP ON MP.sProducts_ID=PBMAP.PRODUCT_ID
					LEFT OUTER JOIN Master_Size AS MPSIZE ON MP.sProducts_Size=MPSIZE.Size_ID
					WHERE MP.sProduct_Status<>'D'
				END
			--End of Rev 1.0
			SELECT sProducts_ID AS product_id,MP.sProducts_Name AS product_name,sProducts_Brand AS brand_id,brnd.Brand_Name AS brand_name,PCLS.ProductClass_Code AS category_id,PCLS.ProductClass_Name AS category_name,
			sProducts_Size AS watt_id,ISNULL(MPSIZE.Size_Name,'Not Applicable') AS watt_name
			FROM Master_sProducts AS MP
			INNER JOIN tbl_master_brand BRND ON MP.sProducts_Brand=BRND.Brand_Id
			INNER JOIN Master_ProductClass AS PCLS ON MP.ProductClass_Code=PCLS.ProductClass_ID
			LEFT OUTER JOIN Master_Size AS MPSIZE ON MP.sProducts_Size=MPSIZE.Size_ID
			WHERE MP.sProduct_Status<>'D'
		END
	IF @ACTION='GETPRODUCTRATELISTS'
		BEGIN
			SELECT sProducts_ID AS product_id,CAST(ISNULL(MP.sProduct_MRP,0.00) AS DECIMAL(18,2)) AS mrp,CAST(ISNULL(MP.sProduct_Price,0.00) AS DECIMAL(18,2)) AS item_price,
			CAST(ISNULL(PSPB.SPECIAL_PRICE,0.00) AS DECIMAL(18,2)) AS specialRate
			FROM Master_sProducts AS MP
			LEFT OUTER JOIN PRODUCT_SPECIAL_PRICE_BRANCHWISE PSPB ON MP.sProducts_ID=PSPB.PRODUCT_ID
		END

	SET NOCOUNT OFF
END
GO