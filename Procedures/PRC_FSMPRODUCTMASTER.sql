IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMPRODUCTMASTER]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMPRODUCTMASTER] AS' 
END
GO
ALTER PROC PRC_FSMPRODUCTMASTER
(
	@ACTION VARCHAR(500)=NULL,
	@ID BIGINT=NULL,
	@USER_ID BIGINT=NULL,
	@PRODID INT = NULL,
	@IS_PAGELOAD varchar(10)=null,
	@ProductCode VARCHAR(100)=NULL,
	@ProductName VARCHAR(100)=NULL,
	@ProductMRP DECIMAL(18,2)=0,
	@ProductPrice DECIMAL(18,2)=0,
	@ProductClass VARCHAR(10)=0,
	@ProductStrength VARCHAR(10)=0,
	@ProductUnit VARCHAR(10)=0,
	@ProductBrand VARCHAR(10)=0,
	@ProductStatus VARCHAR(10)=0,
	@FromDate NVARCHAR(10)=NULL,
	@ToDate NVARCHAR(10)=NULL,
	@IMPORT_TABLE UDT_ImportProductMaster READONLY,
	@RETURN_VALUE BIGINT=0 OUTPUT
)
AS
/*************************************************************************************************************************
Written by	Sanchita	13-03-2024 for V2.0.46	New Product Module shall be implemented for ITC. Refer: 27289
******************************************************************************************************************************/
BEGIN

	IF(@ACTION='GETLISTDATA')
	BEGIN
		---- ProductClass 0 ---
		select '0' as ProductClassId,'Select' as	ProductClassName
		union all
		SELECT ProductClass_ID AS ProductClassId , TRIM(ProductClass_Name) AS ProductClassName FROM Master_ProductClass 
		-------------

		---- ProductStrength 1 ---
		select '0' as ProductStrengthId,'Select' as	ProductStrengthName
		union all
		SELECT Size_ID AS ProductStrengthId , Size_Name AS ProductStrengthName FROM Master_Size
		-------------

		---- ProductUnit 2 ---
		select '0' as ProductUnitId,'Select' as	ProductUnitName
		union all
		SELECT UOM_ID AS ProductUnitId , UOM_Name AS ProductUnitName FROM Master_UOM
		-------------

		---- ProductBrand 3 ---
		select '0' as ProductBrandId,'Select' as	ProductBrandName
		union all
		SELECT Brand_Id AS ProductBrandId , Brand_Name AS ProductBrandName FROM tbl_master_brand
		-------------

		---- ProductStatus 4 ---
		select 1 as ProductStatusId,'Active' as	ProductStatusName
		union all
		SELECT 0 AS ProductStatusId , 'Dormant' AS ProductStatusName
		-------------
	END
	ELSE IF(@ACTION='GETPRODUCTMASTERLISTDATA')
	BEGIN
		DECLARE @DSql NVARCHAR(MAX)

		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_ProductMasterList') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTS_ProductMasterList
			(
				USERID int, sProducts_ID bigint,	sProducts_Code varchar(80),	sProducts_Name varchar(100),	sProducts_Description nvarchar(max),
				ProductClass_Code int,	ProductClass_Name varchar(100),	 Brand_Id int,	Brand_Name varchar(50), 	Size_Name varchar(30),
				sProduct_Price decimal(18,5), sProduct_MRP decimal(18,5),sProduct_Status varchar(15), UOM_Name nvarchar(200)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTS_ProductMasterList (sProducts_ID)
		END
		DELETE FROM FTS_ProductMasterList WHERE USERID=@User_id
		
		if(@IS_PAGELOAD = '1')
		BEGIN
			
			SET @DSql = ''

			SET @DSql = 'INSERT INTO FTS_ProductMasterList '
			SET @DSql += 'SELECT '+convert(varchar(50),@USER_ID) +',MP.sProducts_ID ,MP.sProducts_Code ,MP.sProducts_Name ,MP.sProducts_Description ,'
			SET @DSql += 'MP.ProductClass_Code ,MPC.ProductClass_Name ,MP.sProducts_Brand,  brand.Brand_Name, Size.Size_Name, isnull(MP.sProduct_Price,0) sProduct_Price, isnull(MP.sProduct_MRP,0) sProduct_MRP,  '
			SET @DSql += '(CASE WHEN  MP.sProduct_Status=''A'' THEN ''Active'' ELSE ''Dormant'' END) sProduct_Status , UOM.UOM_Name '
			SET @DSql += 'FROM Master_sProducts MP '
			SET @DSql += 'left join Master_ProductClass MPC '
			SET @DSql += 'on MP.ProductClass_Code=MPC.ProductClass_ID  left outer join TBL_MASTER_SERVICE_TAX sac on '
			SET @DSql += 'MP.sProducts_serviceTax=sac.TAX_ID '
			SET @DSql += 'left outer join tbl_master_brand brand on MP.sProducts_Brand=brand.Brand_Id '
			SET @DSql += 'left outer join Master_Size Size on MP.sProducts_Size=Size.Size_Id '
			SET @DSql += 'left outer join Master_UOM UOM on MP.sProducts_TradingLotUnit=UOM.UOM_ID '
			--IF (@Products <>'')
			--BEGIN
			--	SET @Products = '''' + replace(@Products,',',''',''')  + ''''
			--	SET @DSql += 'where MP.sProducts_ID in ('+@Products+')'
			--END
			SET @DSql += 'order by MP.sProducts_ID desc '

			--select @DSql
			Exec sp_executesql @Dsql
		END
	END
	ELSE IF(@ACTION='ADDPRODUCT')
	BEGIN
		IF NOT EXISTS(SELECT * FROM Master_sProducts WHERE sProducts_Code=@ProductCode)
		BEGIN
			BEGIN TRY
			BEGIN TRANSACTION
				INSERT INTO Master_sProducts (sProducts_Code,	sProducts_Name,	sProducts_Description, sProducts_Type, ProductClass_Code,
					sProducts_Brand,	sProducts_Size, sProduct_Price, sProduct_MRP, sProduct_Status, sProducts_TradingLotUnit,
					sProducts_CreateUser, sProducts_CreateTime)
				VALUES (@ProductCode, @ProductName, '', 0, @ProductClass, @ProductBrand, @ProductStrength, @ProductPrice,
					@ProductMRP, (CASE WHEN @ProductStatus=1 THEN 'A' ELSE 'D' END) , @ProductUnit, @USER_ID, GETDATE() )

				set @PRODID=@@IDENTITY;


				SET @DSql = ''
				SET @DSql = 'INSERT INTO FTS_ProductMasterList '
				SET @DSql += 'SELECT '+convert(varchar(50),@USER_ID) +',MP.sProducts_ID ,MP.sProducts_Code ,MP.sProducts_Name ,MP.sProducts_Description ,'
				SET @DSql += 'MP.ProductClass_Code ,MPC.ProductClass_Name ,MP.sProducts_Brand,  brand.Brand_Name, Size.Size_Name, isnull(MP.sProduct_Price,0) sProduct_Price, isnull(MP.sProduct_MRP,0) sProduct_MRP,  '
				SET @DSql += '(CASE WHEN  MP.sProduct_Status=''A'' THEN ''Active'' ELSE ''Dormant'' END) sProduct_Status , UOM.UOM_Name '
				SET @DSql += 'FROM Master_sProducts MP '
				SET @DSql += 'left join Master_ProductClass MPC '
				SET @DSql += 'on MP.ProductClass_Code=MPC.ProductClass_ID  left outer join TBL_MASTER_SERVICE_TAX sac on '
				SET @DSql += 'MP.sProducts_serviceTax=sac.TAX_ID '
				SET @DSql += 'left outer join tbl_master_brand brand on MP.sProducts_Brand=brand.Brand_Id '
				SET @DSql += 'left outer join Master_Size Size on MP.sProducts_Size=Size.Size_Id '
				SET @DSql += 'left outer join Master_UOM UOM on MP.sProducts_TradingLotUnit=UOM.UOM_ID '
				SET @DSql += 'where MP.sProducts_ID = '+@PRODID
				Exec sp_executesql @Dsql

				SET @RETURN_VALUE=@PRODID;
			COMMIT TRANSACTION
			END TRY

			BEGIN CATCH

			ROLLBACK TRANSACTION
			
				set @RETURN_VALUE='-10'
				
			END CATCH
		END
		ELSE
		BEGIN
			SET @RETURN_VALUE='-1';
		END
	END
	ELSE IF(@ACTION='EDITPRODUCT')
	BEGIN
		SELECT sProducts_Code,	sProducts_Name,	sProducts_Description, sProducts_Type, ProductClass_Code,
					sProducts_Brand,	isnull(sProducts_Size,0) sProducts_Size, isnull(sProduct_Price,0) sProduct_Price, 
					sProduct_MRP, (CASE WHEN sProduct_Status='A' THEN 1 ELSE 0 END) sProduct_Status, sProducts_TradingLotUnit
		from Master_sProducts where sProducts_ID=@PRODID
	END
	ELSE IF(@ACTION='UPDATEPRODUCT')
	BEGIN
		UPDATE Master_sProducts SET sProducts_Name=@ProductName,	sProducts_Description=@ProductName, ProductClass_Code=@ProductClass,
					sProducts_Brand=@ProductBrand,	sProducts_Size=@ProductStrength, sProduct_Price=@ProductPrice, 
					sProduct_MRP=@ProductMRP, sProduct_Status=(CASE WHEN @ProductStatus='1' THEN 'A' ELSE 'D' END) , 
					sProducts_TradingLotUnit = @ProductUnit
		from Master_sProducts where sProducts_ID=@PRODID

		DELETE FROM FTS_ProductMasterList WHERE sProducts_ID = @PRODID

		INSERT INTO FTS_ProductMasterList 
		SELECT convert(varchar(50),@USER_ID) ,MP.sProducts_ID ,MP.sProducts_Code ,MP.sProducts_Name ,MP.sProducts_Description ,
		MP.ProductClass_Code ,MPC.ProductClass_Name ,MP.sProducts_Brand,  brand.Brand_Name, Size.Size_Name, isnull(MP.sProduct_Price,0) sProduct_Price, isnull(MP.sProduct_MRP,0) sProduct_MRP,  
		(CASE WHEN  MP.sProduct_Status='A' THEN 'Active' ELSE 'Dormant' END) sProduct_Status , UOM.UOM_Name 
		FROM Master_sProducts MP 
		left join Master_ProductClass MPC 
		on MP.ProductClass_Code=MPC.ProductClass_ID  left outer join TBL_MASTER_SERVICE_TAX sac on 
		MP.sProducts_serviceTax=sac.TAX_ID 
		left outer join tbl_master_brand brand on MP.sProducts_Brand=brand.Brand_Id 
		left outer join Master_Size Size on MP.sProducts_Size=Size.Size_Id 
		left outer join Master_UOM UOM on MP.sProducts_TradingLotUnit=UOM.UOM_ID 
		where MP.sProducts_ID = +@PRODID
		
		SET @RETURN_VALUE='1';
	END
	ELSE IF(@ACTION='DELETEPRODUCT')
	BEGIN
		-- CHECK TRANSACTION EXISTS
		--BEGIN

			-- SET @RETURN_VALUE='-1';
		-- END
		-- ELSE
		-- BEGIN
			DELETE FROM  Master_sProducts where sProducts_ID=@PRODID

			SET @DSql = ''
			SET @DSql = 'DELETE FROM FTS_ProductMasterList WHERE sProducts_ID = '+@PRODID
			Exec sp_executesql @Dsql

			SET @RETURN_VALUE='1';
		-- END
	END
	IF(@ACTION='IMPORTPRODUCT')
	BEGIN

		DECLARE @ItemCode [nvarchar](100) , @ItemName [nvarchar](100), @ItemClass [nvarchar](100), @ItemBrand [nvarchar](50), 
				@ItemStrangth [nvarchar](50), @ItemPrice [decimal](18,5) , @ItemMRP [decimal](18,5), @ItemStatus [nvarchar](15), @ItemUnit [nvarchar](200)
		DECLARE @ItemClassid INT, @ItemBrandId INT, @ItemStrangthId INT, @ItemUnitId INT

		DECLARE DB_CURSOR CURSOR FOR
		 SELECT [Item Code],[Item Name],[Item Class/Category],[Item Brand],[Item Strangth],[Item Price], [Item MRP],[Item Status], [Item Unit] 
		 FROM @IMPORT_TABLE where [Item Code] is not NULL
		 OPEN DB_CURSOR
		 FETCH NEXT FROM DB_CURSOR INTO @ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, @ItemStatus, @ItemUnit 
		 WHILE @@FETCH_STATUS=0
		 begin
				SET @ItemClassid = ISNULL( (SELECT ProductClass_ID  FROM Master_ProductClass where TRIM(ProductClass_Name)=TRIM(@ItemClass) ) ,0)
				SET @ItemBrandId = ISNULL( (SELECT Brand_Id  FROM tbl_master_brand where TRIM(Brand_Name)=TRIM(@ItemBrand) ),0)
				SET @ItemStrangthId = ISNULL( (SELECT Size_ID FROM Master_Size where TRIM(Size_Name)=TRIM(@ItemStrangth)  ),0)
				SET @ItemUnitId = ISNULL( (SELECT UOM_ID FROM Master_UOM where TRIM(UOM_Name)=TRIM(@ItemUnit) ),0)

				--- VALIDATIONS\\\\\\\
				IF NOT EXISTS (SELECT 1 FROM Master_sProducts WHERE sProducts_Code=@ItemCode)
				BEGIN
					IF @ItemClassid<>0
					BEGIN
						IF @ItemBrandId<>0
						BEGIN
							IF @ItemStrangthId<>0
							BEGIN
								IF @ItemUnitId<>0
								BEGIN
									IF @ItemPrice>0 AND @ItemMRP>0
									BEGIN
										INSERT INTO Master_sProducts (sProducts_Code,	sProducts_Name,	sProducts_Description, sProducts_Type, ProductClass_Code,
										sProducts_Brand,	sProducts_Size, sProduct_Price, sProduct_MRP, sProduct_Status, sProducts_TradingLotUnit,
										sProducts_CreateUser, sProducts_CreateTime)
										VALUES (@ItemCode, @ItemName, '', 0, @ItemClassid, @ItemBrandId, @ItemStrangthId, @ItemPrice,
											@ItemMRP, (CASE WHEN @ItemStatus='Active' THEN 'A' ELSE 'D' END) , @ItemUnitId, @USER_ID, GETDATE() )


										INSERT INTO FTS_PRODUCTMASTERIMPORTLOG
											([ItemCode] ,[ItemName] ,[ItemClass], [ItemBrand] ,[ItemStrangth] ,[ItemPrice] ,[ItemMRP] ,
											[ItemStatus] ,[ItemUnit] ,	[ImportStatus] ,[ImportMsg] ,[ImportDate],[CreateUser])
										SELECT 
											@ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, 
											@ItemStatus, @ItemUnit ,'Sucess','Sucess',GETDATE(),@User_Id 
									END
									ELSE
									BEGIN
										INSERT INTO FTS_PRODUCTMASTERIMPORTLOG
											([ItemCode] ,[ItemName] ,[ItemClass], [ItemBrand] ,[ItemStrangth] ,[ItemPrice] ,[ItemMRP] ,
											[ItemStatus] ,[ItemUnit] ,	[ImportStatus] ,[ImportMsg] ,[ImportDate],[CreateUser])
										SELECT 
											@ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, 
											@ItemStatus, @ItemUnit,'Faild','Item Price AND Item MRP should be greater than zero.',GETDATE(),@User_Id 
											--FROM @IMPORT_TABLE temp where [Item Code]=@ItemCode

									END
								END
								ELSE
								BEGIN
									INSERT INTO FTS_PRODUCTMASTERIMPORTLOG
										([ItemCode] ,[ItemName] ,[ItemClass], [ItemBrand] ,[ItemStrangth] ,[ItemPrice] ,[ItemMRP] ,
										[ItemStatus] ,[ItemUnit] ,	[ImportStatus] ,[ImportMsg] ,[ImportDate],[CreateUser])
									SELECT 
										@ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, 
										@ItemStatus, @ItemUnit,'Faild','Invalid Item Unit.',GETDATE(),@User_Id 
										--FROM @IMPORT_TABLE temp where [Item Code]=@ItemCode

								END
							END
							ELSE
							BEGIN
								INSERT INTO FTS_PRODUCTMASTERIMPORTLOG
									([ItemCode] ,[ItemName] ,[ItemClass], [ItemBrand] ,[ItemStrangth] ,[ItemPrice] ,[ItemMRP] ,
									[ItemStatus] ,[ItemUnit] ,	[ImportStatus] ,[ImportMsg] ,[ImportDate],[CreateUser])
								SELECT 
									@ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, 
									@ItemStatus, @ItemUnit,'Faild','Invalid Item Strangth.',GETDATE(),@User_Id 
									--FROM @IMPORT_TABLE temp where [Item Code]=@ItemCode

							END
						END
						ELSE
						BEGIN
							INSERT INTO FTS_PRODUCTMASTERIMPORTLOG
								([ItemCode] ,[ItemName] ,[ItemClass], [ItemBrand] ,[ItemStrangth] ,[ItemPrice] ,[ItemMRP] ,
								[ItemStatus] ,[ItemUnit] ,	[ImportStatus] ,[ImportMsg] ,[ImportDate],[CreateUser])
							SELECT 
								@ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, 
								@ItemStatus, @ItemUnit,'Faild','Invalid Item Brand.',GETDATE(),@User_Id 
								---FROM @IMPORT_TABLE temp where [Item Code]=@ItemCode

						END
					END
					ELSE
					BEGIN
						INSERT INTO FTS_PRODUCTMASTERIMPORTLOG
							([ItemCode] ,[ItemName] ,[ItemClass], [ItemBrand] ,[ItemStrangth] ,[ItemPrice] ,[ItemMRP] ,
							[ItemStatus] ,[ItemUnit] ,	[ImportStatus] ,[ImportMsg] ,[ImportDate],[CreateUser])
						SELECT 
							@ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, 
							@ItemStatus, @ItemUnit,'Faild','Invalid Item Class/Category.',GETDATE(),@User_Id 
							--FROM @IMPORT_TABLE temp where [Item Code]=@ItemCode

					END
				END
				ELSE
				BEGIN
					INSERT INTO FTS_PRODUCTMASTERIMPORTLOG
						([ItemCode] ,[ItemName] ,[ItemClass], [ItemBrand] ,[ItemStrangth] ,[ItemPrice] ,[ItemMRP] ,
						[ItemStatus] ,[ItemUnit] ,	[ImportStatus] ,[ImportMsg] ,[ImportDate],[CreateUser])
					SELECT 
						@ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, 
						@ItemStatus, @ItemUnit,'Faild','Item Code already Exists.',GETDATE(),@User_Id 
						--FROM @IMPORT_TABLE temp where [Item Code]=@ItemCode

				END
		 FETCH NEXT FROM DB_CURSOR INTO @ItemCode, @ItemName, @ItemClass, @ItemBrand, @ItemStrangth, @ItemPrice, @ItemMRP, @ItemStatus, @ItemUnit 
		 END

		 CLOSE DB_CURSOR
		 DEALLOCATE DB_CURSOR
	END
	IF @ACTION='GETPRODUCTIMPORTLOG'
	BEGIN
		SELECT distinct logs.ItemCode, logs.ItemName, logs.ItemClass, logs.ItemBrand, logs.ItemStrangth, logs.ItemPrice, logs.ItemMRP, 
			logs.ItemStatus, logs.ItemUnit, logs.ImportStatus, logs.ImportMsg,logs.ImportDate,U.user_name as UpdatedBy 
			FROM FTS_PRODUCTMASTERIMPORTLOG AS logs 
		INNER JOIN TBL_MASTER_USER U ON U.USER_ID=logs.CreateUser
		WHERE CAST(logs.ImportDate AS DATE) BETWEEN @FromDate AND @ToDate
		ORDER BY logs.ImportDate DESC
	END
END
GO