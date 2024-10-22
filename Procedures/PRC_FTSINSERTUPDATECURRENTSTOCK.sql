IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSINSERTUPDATECURRENTSTOCK]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSINSERTUPDATECURRENTSTOCK] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSINSERTUPDATECURRENTSTOCK]
(
	@ACTION NVARCHAR(500)=NULL,
	@IMPORT_TABLE udt_ImportCurrentStock READONLY,
	@user_id INT=NULL,
	@FromDate NVARCHAR(10)=NULL,
	@ToDate NVARCHAR(10)=NULL,
	@IS_PAGELOAD NVARCHAR(100)=NULL,
	@SearchKey nvarchar(max) = NULL,
	@STOCKID BIGINT=0,
	@BRANCHID BIGINT=0,
	@SHOPCODE VARCHAR(100)=NULL,
	@PRODUCTID BIGINT=0,
	@CURRENTSTOCKDATE DATETIME=NULL,
	@QUANTITY DECIMAL(18,4)=0,
	
	@RETURN_VALUE nvarchar(500)=NULL OUTPUT

) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************
Written by Sanchita

27724: Add, edit and delete rights shall be there in the Item Current Stock page
27707: In Item Current Stock there shall be a stock import option. The sample import file is attached.
***************************************************************************************************************************************/
BEGIN

	IF(@ACTION='GETLISTINGDATA')
	BEGIN
		DECLARE @Strsql NVARCHAR(MAX)

		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FSM_CURRENTSTOCK_LISTING') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FSM_CURRENTSTOCK_LISTING
			(
				USERID INT,
				SEQ INT,
				[STOCK_ID] [BIGINT] NULL,
				[BRANCH] [VARCHAR](500) NULL,
				[SHOPNAME] [NVARCHAR](500) NULL,
				[CODE] [NVARCHAR](50) NULL,
				[CONTACTNUMBER] [NVARCHAR](500) NULL,
				[SHOPTYPE] [VARCHAR](500) NULL,
				--[CURRENTSTOCKDATE] [VARCHAR](50) NULL,
				[CURRENTSTOCKDATE] DATETIME NULL,
				[PRODUCTCODE] [NVARCHAR](500) NULL,
				[PRODUCTNAME] [NVARCHAR](500) NULL,
				[QUANTITY] [DECIMAL](18,2) NULL,
				[QUANTITY_BAL] [DECIMAL](18,2) NULL,
				[CREATED_BY] [VARCHAR](200) NULL,
				--[CREATED_DATE] [VARCHAR](50) NULL,
				[CREATED_DATE] DATETIME NULL,
				[MODIFIED_BY] [VARCHAR](200) NULL,
				--[MODIFIED_DATE] [VARCHAR](50) NULL
				[MODIFIED_DATE] DATETIME NULL
			)
			CREATE NONCLUSTERED INDEX IX1 ON FSM_CURRENTSTOCK_LISTING (SEQ)
		END
		DELETE FROM FSM_CURRENTSTOCK_LISTING WHERE USERID=@user_id


		if(@IS_PAGELOAD <> 'is_pageload')
		BEGIN
			
			--SET @Strsql=' INSERT INTO FSM_CURRENTSTOCK_LISTING (USERID, SEQ, STOCK_ID, BRANCH, SHOPNAME, CODE, CONTACTNUMBER, SHOPTYPE, CURRENTSTOCKDATE, '
			--SET @Strsql+=' PRODUCTCODE, PRODUCTNAME, QUANTITY, QUANTITY_BAL, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE)'
			--SET @Strsql+=' select '+STR(@user_id)+',ROW_NUMBER() OVER(ORDER BY CSTOCK.CREATED_DATE DESC) AS SEQ, CSTOCK.STOCK_ID, '
			--SET @Strsql+=' CSTOCK.STOCK_BRANCODE, CSTOCK.STOCK_SHOPNAME, CSTOCK.STOCK_SHOPENTITYCODE, CSTOCK.STOCK_SHOPOWNERCONTACT, '
			--SET @Strsql+=' CSTOCK.STOCK_SHOPTYPE, CONVERT(VARCHAR(10),CSTOCK.STOCK_CURRENTDATE,105) STOCK_CURRENTDATE, '
			--SET @Strsql+=' CSTOCK.STOCK_PRODUCTCODE, CSTOCK.STOCK_PRODUCTNAME, CSTOCK.STOCK_PRODUCTQTY, CSTOCK.STOCK_PRODUCTBALQTY, '
			--SET @Strsql+=' USR_ADD.user_name , CONVERT(VARCHAR(10),CSTOCK.CREATED_DATE,105), USR_MOD.user_name, CONVERT(VARCHAR(10),CSTOCK.MODIFIED_DATE,105) '
			--SET @Strsql+=' FROM FSM_MASTER_CURRENTSTOCK CSTOCK '
			--SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_USER USR_ADD ON CSTOCK.CREATED_BY=USR_ADD.USER_ID '
			--SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_USER USR_MOD ON CSTOCK.MODIFIED_BY=USR_MOD.USER_ID '
			
			SET @Strsql=' INSERT INTO FSM_CURRENTSTOCK_LISTING (USERID, SEQ, STOCK_ID, BRANCH, SHOPNAME, CODE, CONTACTNUMBER, SHOPTYPE, CURRENTSTOCKDATE, '
			SET @Strsql+=' PRODUCTCODE, PRODUCTNAME, QUANTITY, QUANTITY_BAL, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE)'
			SET @Strsql+=' select '+STR(@user_id)+',ROW_NUMBER() OVER(ORDER BY CSTOCK.CREATED_DATE DESC) AS SEQ, CSTOCK.STOCK_ID, '
			SET @Strsql+=' CSTOCK.STOCK_BRANCODE, CSTOCK.STOCK_SHOPNAME, CSTOCK.STOCK_SHOPENTITYCODE, CSTOCK.STOCK_SHOPOWNERCONTACT, '
			SET @Strsql+=' CSTOCK.STOCK_SHOPTYPE, CSTOCK.STOCK_CURRENTDATE, '
			SET @Strsql+=' CSTOCK.STOCK_PRODUCTCODE, CSTOCK.STOCK_PRODUCTNAME, CSTOCK.STOCK_PRODUCTQTY, CSTOCK.STOCK_PRODUCTBALQTY, '
			SET @Strsql+=' USR_ADD.user_name , CSTOCK.CREATED_DATE, USR_MOD.user_name, CSTOCK.MODIFIED_DATE '
			SET @Strsql+=' FROM FSM_MASTER_CURRENTSTOCK CSTOCK '
			SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_USER USR_ADD ON CSTOCK.CREATED_BY=USR_ADD.USER_ID '
			SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_USER USR_MOD ON CSTOCK.MODIFIED_BY=USR_MOD.USER_ID '
			
			--SELECT @Strsql

			EXEC SP_EXECUTESQL @Strsql

			
		END
	END

	IF @ACTION='IMPORTCURRENTSTOCK'
	BEGIN
		DECLARE @Branch [varchar](500) , @ShopName [nvarchar](500) , @Code [nvarchar](500) ,
				@ContactNumber [nvarchar](500) , @Shoptype [varchar](500) ,@CurrentStockDateImp [datetime] ,
				@ProductCode [nvarchar](500) , @ProductName [nvarchar](500) , @QuantityImp [decimal](18,4) 

		DECLARE @BRANCHIDImp BIGINT=0, @PRODUCTIDImp BIGINT=0, @shop_typeId INT=0, @shopCodeImp varchar(100)='', 
				@EntityCode nvarchar(100)='', @shopttypeID int=0, @Shop_Name NVARCHAR(1000)='', @type int=0,
				@sProducts_Name varchar(100)='', @STOCK_ID BIGINT=0,
				@OLDQTY [decimal](18,4), @OLDBALQTY [decimal](18,4), @QTY [decimal](18,4)
				

		DECLARE DB_CURSOR CURSOR FOR
		SELECT Branch, ShopName, Code, ContactNumber, Shoptype, CurrentStockDate, ProductCode, ProductName, Quantity
						FROM @IMPORT_TABLE where ProductCode is not NULL
		OPEN DB_CURSOR
		FETCH NEXT FROM DB_CURSOR INTO @Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp, 
										@ProductCode, @ProductName, @QuantityImp
		WHILE @@FETCH_STATUS=0
		BEGIN
			
			SET @BRANCHIDImp = (SELECT TOP 1 branch_id FROM tbl_master_branch WHERE branch_code=@Branch)

			SET @shopCodeImp = (SELECT Shop_Code FROM tbl_Master_shop WHERE Shop_Owner_Contact=@ContactNumber)
			SET @EntityCode = (SELECT EntityCode FROM tbl_Master_shop WHERE Shop_Owner_Contact=@ContactNumber)
			SET @Shop_Name = (SELECT SHOP_NAME FROM tbl_Master_shop WHERE Shop_Owner_Contact=@ContactNumber )
			SET @type = (SELECT type FROM TBL_MASTER_SHOP WHERE Shop_Owner_Contact=@ContactNumber )
			SET @shopttypeID = (select shop_typeId from tbl_shoptype where Name=@Shoptype)

			SET @PRODUCTIDImp = (SELECT sProducts_ID FROM Master_sProducts WHERE sProducts_Code=@ProductCode)
			set @sProducts_Name = (SELECT sProducts_Name FROM Master_sProducts WHERE sProducts_Code=@ProductCode)


			IF(@BRANCHIDImp IS NOT NULL AND @BRANCHIDImp <> 0)
			BEGIN
				IF(@shopCodeImp IS NOT NULL AND TRIM(@shopCodeImp)<>'')
				BEGIN
					IF(@Code IS NULL OR TRIM(@Code)='' OR TRIM(@Code)=TRIM(@EntityCode))
					BEGIN
						if (@Shop_Name IS NULL OR TRIM(@Shop_Name)='' OR TRIM(@Shop_Name)=TRIM(@ShopName))
						BEGIN
							IF(@Shoptype IS NULL OR trim(@Shoptype)='' OR @shopttypeID=@type)
							BEGIN
								IF(@PRODUCTIDImp IS NOT NULL AND @PRODUCTIDImp<>0)
								BEGIN
									IF(@ProductName IS NULL OR @ProductName='' OR @ProductName=@sProducts_Name)
									BEGIN

										IF (@QuantityImp IS NOT NULL AND @QuantityImp>0)
										BEGIN
											
											IF(@CurrentStockDateImp>= convert(date, getdate()))
											BEGIN
												IF NOT EXISTS(SELECT 1 FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_SHOPCODE=@shopCodeImp AND STOCK_PRODUCTID=@PRODUCTIDImp )
												BEGIN

													SET @STOCK_ID = ISNULL((SELECT MAX(STOCK_ID) FROM FSM_MASTER_CURRENTSTOCK),0) + 1

													INSERT INTO FSM_MASTER_CURRENTSTOCK (
															[STOCK_ID], [STOCK_BRANCHID], [STOCK_BRANCODE], [STOCK_SHOPCODE], [STOCK_SHOPNAME], 
															[STOCK_SHOPENTITYCODE], [STOCK_SHOPOWNERCONTACT],[STOCK_SHOPTYPE],
															[STOCK_CURRENTDATE], [STOCK_PRODUCTID], [STOCK_PRODUCTCODE], [STOCK_PRODUCTNAME], [STOCK_PRODUCTQTY], 
															[STOCK_PRODUCTBALQTY], [CREATED_BY], [CREATED_DATE], [MODIFIED_BY], [MODIFIED_DATE]
														)
															VALUES(@STOCK_ID, @BRANCHIDImp, @Branch, @shopCodeImp, @ShopName, @EntityCode, @ContactNumber, @Shoptype , @CurrentStockDateImp, 
															@PRODUCTIDImp, @ProductCode, @sProducts_Name, @QuantityImp, @QuantityImp,
															@user_id,GETDATE(), NULL, NULL	
														)


														INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
															[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
														VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
																@ProductCode, @ProductName, @QuantityImp,'Success', 'Success', GETDATE(), @user_id)
												END
												ELSE
												BEGIN
													
													SET @OLDQTY = (SELECT STOCK_PRODUCTQTY FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_SHOPCODE=@shopCodeImp AND STOCK_PRODUCTID=@PRODUCTIDImp )
													SET @OLDBALQTY = (SELECT STOCK_PRODUCTBALQTY FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_SHOPCODE=@shopCodeImp AND STOCK_PRODUCTID=@PRODUCTIDImp )

													IF ( @OLDQTY=@OLDBALQTY OR @QuantityImp>=@OLDBALQTY)
													BEGIN
														set @QTY = @QuantityImp-@OLDQTY

														UPDATE FSM_MASTER_CURRENTSTOCK SET
																[STOCK_BRANCHID]=@BRANCHIDImp, [STOCK_BRANCODE]=@Branch, [STOCK_SHOPCODE]=@shopCodeImp, [STOCK_SHOPNAME]=@ShopName, 
																[STOCK_SHOPENTITYCODE]=@EntityCode, [STOCK_SHOPOWNERCONTACT]=@ContactNumber,[STOCK_SHOPTYPE]=@Shoptype,
																[STOCK_CURRENTDATE]=@CurrentStockDateImp, [STOCK_PRODUCTID]=@PRODUCTIDImp, [STOCK_PRODUCTCODE]=@ProductCode, 
																[STOCK_PRODUCTNAME]=@sProducts_Name, [STOCK_PRODUCTQTY]=[STOCK_PRODUCTQTY]+@QTY, 
																[STOCK_PRODUCTBALQTY]=[STOCK_PRODUCTBALQTY]+@QTY, [MODIFIED_BY]=@user_id, [MODIFIED_DATE]=GETDATE()
														WHERE STOCK_SHOPCODE=@shopCodeImp AND STOCK_PRODUCTID=@PRODUCTIDImp

														INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
															[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
														VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
																@ProductCode, @ProductName, @QuantityImp,'Success', 'Update Success', GETDATE(), @user_id)
													END
													ELSE
													BEGIN
														INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
															[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
														VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
																@ProductCode, @ProductName, @QuantityImp,'Failed', 'Quantity given is less than Balance Quantity.', GETDATE(), @user_id)

													END
												END

											END
											ELSE
											BEGIN
												INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
													[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
												VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
														@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Current Stock Date.', GETDATE(), @user_id)

											END
										END
										ELSE
										BEGIN
											INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
												[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
											VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
													@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Product Quantity.', GETDATE(), @user_id)

										END
										
									END
									ELSE
									BEGIN
										INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
											[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
										VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
												@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Product Name.', GETDATE(), @user_id)
									END
								END
								ELSE
								BEGIN
									INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
										[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
									VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
											@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Product Code.', GETDATE(), @user_id)
								END
							END
							ELSE
							BEGIN
								INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
									[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
								VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
										@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Shop Type.', GETDATE(), @user_id)
							END
						END
						ELSE
						BEGIN
							INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
								[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
							VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
									@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Shop Name.', GETDATE(), @user_id)
						END
					END
					ELSE
					BEGIN
						INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
							[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
						VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
								@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Shop Code.', GETDATE(), @user_id)
					END
				END
				ELSE
				BEGIN
					INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
						[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
					VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
							@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Shop Owner Contact.', GETDATE(), @user_id)
				END
			END
			ELSE
			BEGIN
				INSERT INTO [FSM_MASTER_CURRENTSTOCK_LOG] ([Branch], [ShopName], [Code], [ContactNumber], [Shoptype], [CurrentStockDate], 
					[ProductCode], [ProductName], [Quantity], [ImportStatus], [ImportMsg], [ImportDate], [CreateUser])
				VALUES (@Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
						@ProductCode, @ProductName, @QuantityImp,'Failed', 'Invalid Branch.', GETDATE(), @user_id)
			END


			FETCH NEXT FROM DB_CURSOR INTO @Branch, @ShopName, @Code, @ContactNumber, @Shoptype,@CurrentStockDateImp,
				@ProductCode, @ProductName, @QuantityImp
		END

		close db_cursor
		deallocate db_cursor

		SELECT DISTINCT logs.* FROM FSM_MASTER_CURRENTSTOCK_LOG AS logs
		INNER JOIN @IMPORT_TABLE temp ON logs.[ContactNumber] =temp.[ContactNumber] 

	END
	IF @ACTION='SHOWIMPORTLOG'
	BEGIN
		SELECT DISTINCT LOGS.[Branch], LOGS.[ShopName], LOGS.[Code], LOGS.[ContactNumber], LOGS.[Shoptype], CONVERT(NVARCHAR(10),LOGS.[CurrentStockDate],105) as CurrentStockDate, 
						LOGS.[ProductCode], LOGS.[ProductName], LOGS.[Quantity], LOGS.[ImportStatus], LOGS.[ImportMsg], 
						CONVERT(NVARCHAR(10),LOGS.[ImportDate],105) as ImportDate, LOGS.[CreateUser]

		FROM FSM_MASTER_CURRENTSTOCK_LOG LOGS 
		inner join @IMPORT_TABLE temp ON 
		LOGS.[Branch]=temp.Branch AND LOGS.[ShopName]=temp.ShopName AND LOGS.[Code]=temp.Code AND LOGS.[ContactNumber]=TEMP.ContactNumber 
		AND LOGS.[Shoptype]=TEMP.Shoptype AND LOGS.[CurrentStockDate]=TEMP.CurrentStockDate AND LOGS.[ProductCode]=TEMP.ProductCode 
		AND LOGS.[ProductName]=TEMP.ProductName AND LOGS.[Quantity]=TEMP.Quantity

	END
	ELSE IF (@Action='GETCRMCONTACTIMPORTLOG')
	BEGIN
		SELECT LOGS.[Branch], LOGS.[ShopName], LOGS.[Code], LOGS.[ContactNumber], LOGS.[Shoptype], LOGS.[CurrentStockDate], 
						LOGS.[ProductCode], LOGS.[ProductName], LOGS.[Quantity]
						, LOGS.[ImportStatus], LOGS.[ImportMsg], 
						CONVERT(NVARCHAR(10),LOGS.[ImportDate],105) as ImportDate, LOGS.[CreateUser]

		FROM FSM_MASTER_CURRENTSTOCK_LOG LOGS 
		WHERE convert(date, LOGS.ImportDate) BETWEEN @FromDate AND @ToDate
		ORDER BY LOGS.ImportDate DESC

	END
	ELSE IF (@Action='GETDROPDOWNBINDDATA')
	BEGIN
		SELECT '0' AS branch_id, '' AS branch_description, '' AS branch_code
		UNION ALL
		SELECT CONVERT(VARCHAR(10),branch_id) branch_id, branch_description, CONVERT(VARCHAR(10),branch_code) branch_code FROM tbl_master_branch BR 
			WHERE EXISTS (SELECT * FROM tbl_trans_employeeCTC WHERE emp_branch=BR.branch_id ) 
			ORDER BY branch_code

	END
	ELSE IF (@Action='GETSHOPLIST')
	BEGIN
		
		SET @Strsql=''

		SET @Strsql+=' select top(10) shop.Shop_Code SHOP_CODE, Replace(shop.Shop_Name,'''',''&#39;'') as SHOP_NAME, shop.EntityCode ENTITYCODE,  '
		SET @Strsql+=' shoptype.Name SHOPTYPENAME, shop.Shop_Owner_Contact SHOP_OWNER_CONTACT from tbl_Master_shop shop '
		SET @Strsql+=' LEFT OUTER JOIN tbl_shoptype shoptype ON shoptype.shop_typeId=shop.[type] '

		--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		--BEGIN
		--	SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE    '
		--END

		SET @Strsql+=' where (shop.Shop_Name like ''%'+ @SearchKey +'%'') '
		SET @Strsql+=' or  (shop.EntityCode like ''%'+ @SearchKey +'%'' ) '
		SET @Strsql+=' or  (shop.type like ''%'+ @SearchKey +'%'' ) '
		SET @Strsql+=' or (shop.Shop_Owner_Contact like ''%'+ @SearchKey +'%'' ) '
		EXEC SP_EXECUTESQL @Strsql

	END
	ELSE IF (@Action='ADDCURRENTSTOCK')
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

			IF NOT EXISTS(SELECT 1 FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_SHOPCODE=@SHOPCODE AND STOCK_PRODUCTID=@PRODUCTID )
			BEGIN

				SET @STOCK_ID = ISNULL((SELECT MAX(STOCK_ID) FROM FSM_MASTER_CURRENTSTOCK),0) + 1

				SET @Branch = (SELECT TOP 1 branch_code  FROM tbl_master_branch WHERE branch_id =@BRANCHID)

				SET @ContactNumber = (SELECT Shop_Owner_Contact FROM tbl_Master_shop WHERE Shop_Code=@SHOPCODE)
				SET @EntityCode = (SELECT EntityCode FROM tbl_Master_shop WHERE Shop_Code=@SHOPCODE )
				SET @Shop_Name = (SELECT SHOP_NAME FROM tbl_Master_shop WHERE Shop_Code=@SHOPCODE )
				SET @type = (SELECT type FROM TBL_MASTER_SHOP WHERE Shop_Code=@SHOPCODE )
				SET @Shoptype = (select  Name from tbl_shoptype where shop_typeId=@type)

				SET @ProductCode= (SELECT sProducts_Code FROM Master_sProducts WHERE sProducts_ID=@PRODUCTID)
				set @sProducts_Name = (SELECT sProducts_Name FROM Master_sProducts WHERE sProducts_ID=@PRODUCTID)

				INSERT INTO FSM_MASTER_CURRENTSTOCK (
						[STOCK_ID], [STOCK_BRANCHID], [STOCK_BRANCODE], [STOCK_SHOPCODE], [STOCK_SHOPNAME], 
						[STOCK_SHOPENTITYCODE], [STOCK_SHOPOWNERCONTACT],[STOCK_SHOPTYPE],
						[STOCK_CURRENTDATE], [STOCK_PRODUCTID], [STOCK_PRODUCTCODE], [STOCK_PRODUCTNAME], [STOCK_PRODUCTQTY], 
						[STOCK_PRODUCTBALQTY], [CREATED_BY], [CREATED_DATE], [MODIFIED_BY], [MODIFIED_DATE]
					)
						VALUES(@STOCK_ID, @BRANCHID, @Branch, @SHOPCODE, @Shop_Name, @EntityCode, @ContactNumber, @Shoptype , @CURRENTSTOCKDATE, 
						@PRODUCTID, @ProductCode, @sProducts_Name, @QUANTITY, @QUANTITY,
						@user_id,GETDATE(), NULL, NULL	
					)

				SET @RETURN_VALUE = 'Success'

			END
			ELSE
			BEGIN
				SET @RETURN_VALUE = 'Duplicate'
			END

		COMMIT TRANSACTION
		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			set @RETURN_VALUE='Error in Add.'
		
		END CATCH
	END
	ELSE IF (@Action='EDITCURRENTSTOCK')
	BEGIN
		SELECT STOCK_BRANCHID, STOCK_SHOPCODE, STOCK_PRODUCTID, STOCK_CURRENTDATE, STOCK_PRODUCTQTY, STOCK_PRODUCTNAME, STOCK_SHOPNAME 
		FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_ID=@STOCKID

	END
	ELSE IF (@Action='MODIFYCURRENTSTOCK')
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

			IF EXISTS(SELECT 1 FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_SHOPCODE=@SHOPCODE AND STOCK_PRODUCTID=@PRODUCTID AND STOCK_ID<>@STOCKID )
			BEGIN
				SET @RETURN_VALUE = 'Duplicate'
			END
			ELSE
			BEGIN
				SET @OLDQTY = (SELECT isnull(STOCK_PRODUCTQTY,0) FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_ID=@STOCKID )
				SET @OLDBALQTY = (SELECT isnull(STOCK_PRODUCTBALQTY,0) FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_ID=@STOCKID )

				IF ( @OLDQTY=@OLDBALQTY OR @QUANTITY>=@OLDBALQTY)
				BEGIN
					SET @Branch = (SELECT TOP 1 branch_code  FROM tbl_master_branch WHERE branch_id =@BRANCHID)

					SET @ContactNumber = (SELECT Shop_Owner_Contact FROM tbl_Master_shop WHERE Shop_Code=@SHOPCODE)
					SET @EntityCode = (SELECT EntityCode FROM tbl_Master_shop WHERE Shop_Code=@SHOPCODE )
					SET @Shop_Name = (SELECT SHOP_NAME FROM tbl_Master_shop WHERE Shop_Code=@SHOPCODE )
					SET @type = (SELECT type FROM TBL_MASTER_SHOP WHERE Shop_Code=@SHOPCODE )
					SET @Shoptype = (select  Name from tbl_shoptype where shop_typeId=@type)

					SET @ProductCode= (SELECT sProducts_Code FROM Master_sProducts WHERE sProducts_ID=@PRODUCTID)
					set @sProducts_Name = (SELECT sProducts_Name FROM Master_sProducts WHERE sProducts_ID=@PRODUCTID)


					set @QTY = @QUANTITY-@OLDQTY

					UPDATE FSM_MASTER_CURRENTSTOCK SET
							[STOCK_BRANCHID]=@BRANCHID, [STOCK_BRANCODE]=@Branch, [STOCK_SHOPCODE]=@SHOPCODE, [STOCK_SHOPNAME]=@Shop_Name, 
							[STOCK_SHOPENTITYCODE]=@EntityCode, [STOCK_SHOPOWNERCONTACT]=@ContactNumber,[STOCK_SHOPTYPE]=@Shoptype,
							[STOCK_CURRENTDATE]=@CURRENTSTOCKDATE, [STOCK_PRODUCTID]=@PRODUCTID, [STOCK_PRODUCTCODE]=@ProductCode, 
							[STOCK_PRODUCTNAME]=@sProducts_Name, [STOCK_PRODUCTQTY]=[STOCK_PRODUCTQTY]+@QTY, 
							[STOCK_PRODUCTBALQTY]=[STOCK_PRODUCTBALQTY]+@QTY, [MODIFIED_BY]=@user_id, [MODIFIED_DATE]=GETDATE()
					WHERE STOCK_ID=@STOCKID

					SET @RETURN_VALUE = 'Success'
				END
				ELSE
				BEGIN
					SET @RETURN_VALUE = 'Quantity cannot be less than Blanace Quantity.'
				END
			END
			

		COMMIT TRANSACTION
		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			set @RETURN_VALUE='Error in Edit.'
		
		END CATCH
	END
	ELSE IF (@Action='DELETECURRENTSTOCK')
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

			IF EXISTS(SELECT 1 FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_ID=@STOCKID )
			BEGIN
				
				SET @OLDQTY = (SELECT isnull(STOCK_PRODUCTQTY,0) FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_ID=@STOCKID )
				SET @OLDBALQTY = (SELECT isnull(STOCK_PRODUCTBALQTY,0) FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_ID=@STOCKID )

				IF @OLDQTY=@OLDBALQTY
				BEGIN
					DELETE FROM FSM_MASTER_CURRENTSTOCK WHERE STOCK_ID=@STOCKID
					set @RETURN_VALUE='Delete Succesfully.'

					IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FSM_CURRENTSTOCK_LISTING') AND TYPE IN (N'U'))
					BEGIN
						DELETE FROM FSM_CURRENTSTOCK_LISTING WHERE STOCK_ID=@STOCKID
					END
				END
				ELSE
				BEGIN
					set @RETURN_VALUE='Transaction Exists. Cannot Delete.'
				END
			END
			
			

		COMMIT TRANSACTION
		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			set @RETURN_VALUE='Error in Edit.'
		
		END CATCH
	END
END
go

