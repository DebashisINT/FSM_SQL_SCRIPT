
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_SaleRateLock]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_SaleRateLock] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_SaleRateLock]
(
@SaleRateLockID BIGINT = NULL,
@CustomerID	VARCHAR(100) = NULL,
@ProductID	BIGINT = NULL,
@DiscSalesPrice	DECIMAL(18,2) = NULL,
@ApprovedBy	BIGINT = NULL,
@ValidFrom	VARCHAR(50) = NULL, 
@ValidUpto	VARCHAR(50) = NULL,
@MinSalePrice DECIMAL(18,2) = NULL,
@Disc DECIMAL(18,2) = NULL,
@Action VARCHAR(50),
@FixedRate DECIMAL(18,2)=NULL,
@SCHEME NVARCHAR(500)=NULL,
@StateID NVARCHAR(10)=NULL,
@UDT_RATELIST  UDT_SALESLOK READONLY,
@UDT_PRODUCTRATE UDT_ProductRate READONLY
) 
--WITH ENCRYPTION
AS 
/************************************************************************************************ *
		1.0		v2.0.6		TANMOY		14-01-2020		Created.
	2.0		v2.0.7		TANMOY		19-01-2020		INSERT INTO PRODUCT RATE FROM EXCEL
	3.0		v2.0.42		PRITI		01-08-2023		0026649: Four new columns are required in the excel template of "Sale rate lock" module.
	4.0		v2.0.43		Sanchita	12-10-2023		Sale Rate Lock is deleting previous rate of other products if import with new item. Mantis: 26892
*************************************************************************************************/
BEGIN
	IF(@Action = 'Insert')
	BEGIN
		CREATE TABLE #TEMP_PRODUCT
		(
		--ID BIGINT IDENTITY(1,1),
		PROD_ID NVARCHAR(100)
		)

		CREATE TABLE #TEMP_SHOP
		(
		--ID BIGINT IDENTITY(1,1),
		SHOPID NVARCHAR(100)
		)

		DECLARE @PROD NVARCHAR(100)='',@SHOP NVARCHAR(100)=''
		set @PROD=(SELECT TOP(1)convert(nvarchar(100),Product) FROM @UDT_RATELIST)
		set @SHOP=(select TOP(1)convert(nvarchar(100),Entity) FROM @UDT_RATELIST)

		--select top(1) * from @UDT_RATELIST
		--SELECT @PROD,@SHOP
		
		--IF @PROD='0'
		--BEGIN
		--	INSERT INTO #TEMP_PRODUCT
		--	SELECT convert(nvarchar(10),sProducts_ID) FROM Master_sProducts
		--END
		--ELSE
		--BEGIN
			INSERT INTO #TEMP_PRODUCT
			SELECT Product FROM @UDT_RATELIST
		--END

		--IF @SHOP='0'
		--BEGIN
		--	INSERT INTO #TEMP_SHOP
		--	SELECT Shop_Code FROM tbl_Master_shop
		--END
		--ELSE
		--BEGIN
			INSERT INTO #TEMP_SHOP
			SELECT Entity FROM @UDT_RATELIST
		--END

		DECLARE @FLAG BIT=1

		--IF @SHOP='0' AND @PROD='0'
		--	BEGIN
		--		IF((select DBO.GET_MINSALESPRICEENTITYWISE(0,0,@ValidFrom))>0)
		--			BEGIN
		--				SET @FLAG=0
		--				SELECT '-11' AS Insertmsg	
		--			END
		--			ELSE IF((select DBO.GET_MINSALESPRICEENTITYWISE(0,0,@ValidUpto))>0)
		--			BEGIN
		--				SET @FLAG=0
		--				SELECT '-11' AS Insertmsg	
		--			END
		--			ELSE
		--			BEGIN
		--				DECLARE @PROD_IDS NVARCHAR(100),@SOP_IDS NVARCHAR(100)
		--				DECLARE SHOP_CURSORS CURSOR FOR
		--					SELECT SHOPID FROM #TEMP_SHOP
		--					OPEN SHOP_CURSORS
		--					FETCH NEXT FROM SHOP_CURSORS INTO @SOP_IDS
		--					WHILE @@FETCH_STATUS=0
		--						BEGIN
		--							IF((select DBO.GET_MINSALESPRICEENTITYWISE(@SOP_IDS,0,@ValidFrom))>0)
		--							BEGIN
		--								SET @FLAG=0
		--								SELECT '-11' AS Insertmsg	
		--								BREAK
		--							END
		--							ELSE IF((select DBO.GET_MINSALESPRICEENTITYWISE(@SOP_IDS,0,@ValidUpto))>0)
		--							BEGIN
		--								SET @FLAG=0
		--								SELECT '-11' AS Insertmsg	
		--								BREAK
		--							END
		--							FETCH NEXT FROM SHOP_CURSORS INTO @SOP_IDS
		--						END
		--					CLOSE SHOP_CURSORS
		--					DEALLOCATE SHOP_CURSORS

							
		--					DECLARE PROD_CURSORS CURSOR FOR
		--					SELECT PROD_ID FROM #TEMP_PRODUCT
		--					OPEN PROD_CURSORS
		--					FETCH NEXT FROM PROD_CURSORS INTO @PROD_IDS
		--					WHILE @@FETCH_STATUS=0
		--					BEGIN
		--					IF((select DBO.GET_MINSALESPRICEENTITYWISE(0,@PROD_IDS,@ValidFrom))>0)
		--						BEGIN
		--							SET @FLAG=0
		--							SELECT '-11' AS Insertmsg	
		--							BREAK
		--						END
		--						ELSE IF((select DBO.GET_MINSALESPRICEENTITYWISE(0,@PROD_IDS,@ValidUpto))>0)
		--						BEGIN
		--							SET @FLAG=0
		--							SELECT '-11' AS Insertmsg	
		--							BREAK
		--						END
		--					FETCH NEXT FROM PROD_CURSORS INTO @PROD_IDS
		--					END
		--					CLOSE PROD_CURSORS
		--					DEALLOCATE PROD_CURSORS
		--			END
		--		END
		--ELSE
		--	BEGIN
		--		DECLARE @PROD_ID NVARCHAR(100),@SOP_ID NVARCHAR(100)
		--		DECLARE PROD_CURSOR CURSOR FOR
		--		SELECT PROD_ID FROM #TEMP_PRODUCT
		--		OPEN PROD_CURSOR
		--		FETCH NEXT FROM PROD_CURSOR INTO @PROD_ID
		--		WHILE @@FETCH_STATUS=0
		--			BEGIN
		--					DECLARE SHOP_CURSOR CURSOR FOR
		--					SELECT SHOPID FROM #TEMP_SHOP
		--					OPEN SHOP_CURSOR
		--					FETCH NEXT FROM SHOP_CURSOR INTO @SOP_ID
		--					WHILE @@FETCH_STATUS=0
		--						BEGIN
		--							IF((select DBO.GET_MINSALESPRICEENTITYWISE(@SOP_ID,@PROD_ID,@ValidFrom))>0)
		--							BEGIN
		--								SET @FLAG=0
		--								SELECT '-11' AS Insertmsg	
		--								BREAK
		--							END
		--							ELSE IF((select DBO.GET_MINSALESPRICEENTITYWISE(@SOP_ID,@PROD_ID,@ValidUpto))>0)
		--							BEGIN
		--								SET @FLAG=0
		--								SELECT '-11' AS Insertmsg	
		--								BREAK
		--							END
		--							FETCH NEXT FROM SHOP_CURSOR INTO @SOP_ID
		--						END
		--					CLOSE SHOP_CURSOR
		--					DEALLOCATE SHOP_CURSOR
		--				FETCH NEXT FROM PROD_CURSOR INTO @PROD_ID
		--			END
		--		CLOSE PROD_CURSOR
		--		DEALLOCATE PROD_CURSOR
		--	END


		DECLARE @PROD_IDS VARCHAR(50)='',@SOP_IDS VARCHAR(200)=''

		IF(@PROD='0')
		BEGIN
		   IF(@SHOP='0')
		   BEGIN

		   IF((select DBO.GET_MINSALESPRICEENTITYWISE(0,0,@ValidFrom))>0)
			BEGIN
				SET @FLAG=0
				SELECT '-11' AS Insertmsg	
				
			END
			ELSE IF((select DBO.GET_MINSALESPRICEENTITYWISE(0,0,@ValidUpto))>0)
			BEGIN
				SET @FLAG=0
				SELECT '-11' AS Insertmsg	
				
			END
		   
		   END
		   ELSE
		   BEGIN
		    DECLARE SHOP_CURSORS CURSOR FOR
			SELECT SHOPID FROM #TEMP_SHOP
			OPEN SHOP_CURSORS
			FETCH NEXT FROM SHOP_CURSORS INTO @SOP_IDS
			WHILE @@FETCH_STATUS=0
				BEGIN
					IF((select DBO.GET_MINSALESPRICEENTITYWISE(@SOP_IDS,0,@ValidFrom))>0)
					BEGIN
						SET @FLAG=0
						SELECT '-11' AS Insertmsg	
						BREAK
					END
					ELSE IF((select DBO.GET_MINSALESPRICEENTITYWISE(@SOP_IDS,0,@ValidUpto))>0)
					BEGIN
						SET @FLAG=0
						SELECT '-11' AS Insertmsg	
						BREAK
					END
					FETCH NEXT FROM SHOP_CURSORS INTO @SOP_IDS
				END
			CLOSE SHOP_CURSORS
			DEALLOCATE SHOP_CURSORS

		   END

		END
		ELSE
		BEGIN

		 IF(@SHOP='0')
		   BEGIN

		    DECLARE PROD_CURSORS CURSOR FOR
			SELECT PROD_ID FROM #TEMP_PRODUCT
			OPEN PROD_CURSORS
			FETCH NEXT FROM PROD_CURSORS INTO @PROD_IDS
			WHILE @@FETCH_STATUS=0
			BEGIN
			IF((select DBO.GET_MINSALESPRICEENTITYWISE(0,@PROD_IDS,@ValidFrom))>0)
				BEGIN
					SET @FLAG=0
					SELECT '-11' AS Insertmsg	
					BREAK
				END
				ELSE IF((select DBO.GET_MINSALESPRICEENTITYWISE(0,@PROD_IDS,@ValidUpto))>0)
				BEGIN
					SET @FLAG=0
					SELECT '-11' AS Insertmsg	
					BREAK
				END
			FETCH NEXT FROM PROD_CURSORS INTO @PROD_IDS
			END
			CLOSE PROD_CURSORS
			DEALLOCATE PROD_CURSORS
		   
		   END
		   ELSE
		   BEGIN
		    DECLARE @PROD_ID NVARCHAR(100),@SOP_ID NVARCHAR(100)
			DECLARE PROD_CURSOR CURSOR FOR
			SELECT PROD_ID FROM #TEMP_PRODUCT
			OPEN PROD_CURSOR
			FETCH NEXT FROM PROD_CURSOR INTO @PROD_ID
			WHILE @@FETCH_STATUS=0
				BEGIN
						DECLARE SHOP_CURSOR CURSOR FOR
						SELECT SHOPID FROM #TEMP_SHOP
						OPEN SHOP_CURSOR
						FETCH NEXT FROM SHOP_CURSOR INTO @SOP_ID
						WHILE @@FETCH_STATUS=0
							BEGIN
								IF((select DBO.GET_MINSALESPRICEENTITYWISE(@SOP_ID,@PROD_ID,@ValidFrom))>0)
								BEGIN
									SET @FLAG=0
									SELECT '-11' AS Insertmsg	
									BREAK
								END
								ELSE IF((select DBO.GET_MINSALESPRICEENTITYWISE(@SOP_ID,@PROD_ID,@ValidUpto))>0)
								BEGIN
									SET @FLAG=0
									SELECT '-11' AS Insertmsg	
									BREAK
								END
								FETCH NEXT FROM SHOP_CURSOR INTO @SOP_ID
							END
						CLOSE SHOP_CURSOR
						DEALLOCATE SHOP_CURSOR
					FETCH NEXT FROM PROD_CURSOR INTO @PROD_ID
				END
			CLOSE PROD_CURSOR
			DEALLOCATE PROD_CURSOR

		   END

		END


		IF @FLAG=1
		BEGIN
				INSERT INTO FTS_trans_SaleRateLock(CustomerID,ProductID,DiscSalesPrice,FixedRate,ApprovedBy,ApprovedOn,ValidFrom,ValidUpto,MinSalePrice,Disc,SCHEME)
				SELECT Entity,convert(bigint,Product),@DiscSalesPrice,@FixedRate,@ApprovedBy,GETDATE(),@ValidFrom,@ValidUpto,@MinSalePrice,@Disc,@SCHEME FROM  @UDT_RATELIST
				
				SELECT '1' AS Insertmsg
		END


		--DECLARE @Product_ID VARCHAR(200)='',@EntityID VARCHAR(100)=''

		----BEGIN TRAN
		----	BEGIN TRY
		--		DECLARE RT_CURSOR CURSOR FOR
		--		SELECT Entity,Product FROM @UDT_RATELIST
		--		OPEN RT_CURSOR
		--		FETCH NEXT FROM RT_CURSOR INTO @EntityID,@Product_ID
		--		WHILE @@FETCH_STATUS=0
		--			BEGIN

		--				IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = @EntityID AND convert(nvarchar(10),ProductID) = @Product_ID AND (CONVERT(SMALLDATETIME,ValidFrom,120) Between @ValidFrom AND @ValidUpto))
		--				BEGIN
		--					--ROLLBACK TRAN
		--					SELECT '-11' AS Insertmsg	
		--					BREAK
		--				END
		--				ELSE IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = @EntityID AND convert(nvarchar(10),ProductID) = @Product_ID AND (CONVERT(SMALLDATETIME,ValidUpto,120) Between @ValidFrom AND @ValidUpto))
		--				BEGIN
		--					--ROLLBACK TRAN
						
		--					SELECT '-12' AS Insertmsg	
		--					BREAK
		--				END
		--				ELSE IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = '0' AND convert(nvarchar(10),ProductID) = @Product_ID AND (CONVERT(SMALLDATETIME,ValidFrom,120) Between @ValidFrom AND @ValidUpto))
		--				BEGIN
		--					--ROLLBACK TRAN
		--					SELECT '-13' AS Insertmsg	
		--					BREAK
		--				END
		--				ELSE IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = '0' AND convert(nvarchar(10),ProductID) = @Product_ID AND (CONVERT(SMALLDATETIME,ValidUpto,120) Between @ValidFrom AND @ValidUpto))
		--				BEGIN
		--					--ROLLBACK TRAN
		--					SELECT '-14' AS Insertmsg	
		--					BREAK
		--				END
		--				ELSE IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = @EntityID AND ProductID = 0 AND (CONVERT(SMALLDATETIME,ValidFrom,120) Between @ValidFrom AND @ValidUpto))
		--				BEGIN
		--					--ROLLBACK TRAN
		--					SELECT '-15' AS Insertmsg	
		--					BREAK
		--				END
		--				ELSE IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = @EntityID AND ProductID = 0 AND (CONVERT(SMALLDATETIME,ValidUpto,120) Between @ValidFrom AND @ValidUpto))
		--				BEGIN
		--					--ROLLBACK TRAN
		--					SELECT '-16' AS Insertmsg	
		--					BREAK
		--				END
		--				ELSE IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = '0' AND ProductID = 0 AND (CONVERT(SMALLDATETIME,ValidFrom,120) Between @ValidFrom AND @ValidUpto))
		--				BEGIN
		--					--ROLLBACK TRAN
		--					SELECT '-17' AS Insertmsg	
		--					BREAK
		--				END
		--				ELSE IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = '0' AND ProductID = 0 AND (CONVERT(SMALLDATETIME,ValidUpto,120) Between @ValidFrom AND @ValidUpto))
		--				BEGIN
		--					--ROLLBACK TRAN
		--					SELECT '-18' AS Insertmsg	
		--					BREAK
		--				END
		--				ELSE
		--				BEGIN
		--					INSERT INTO FTS_trans_SaleRateLock(CustomerID,ProductID,DiscSalesPrice,FixedRate,ApprovedBy,ApprovedOn,ValidFrom,ValidUpto,MinSalePrice,Disc)
		--					VALUES(@EntityID,convert(bigint,@Product_ID),@DiscSalesPrice,@FixedRate,@ApprovedBy,GETDATE(),@ValidFrom,@ValidUpto,@MinSalePrice,@Disc) 

		--					--SELECT '1' AS Insertmsg
		--				END

		--				FETCH NEXT FROM RT_CURSOR INTO @EntityID,@Product_ID
		--			END
		--		CLOSE RT_CURSOR
		--		DEALLOCATE RT_CURSOR
			--	SELECT '1' AS Insertmsg
				--COMMIT TRAN
		--	END TRY
		--BEGIN CATCH
		--ROLLBACK TRAN
		----SELECT '-110' AS Insertmsg
		--END CATCH
		DROP TABLE #TEMP_SHOP
		DROP TABLE #TEMP_PRODUCT
	END
	IF(@Action = 'GetSaleRateLockDetails')
	BEGIN
		SELECT	SaleRateLockID,CustomerID,cust.Name AS CustName,ProductID,Products_Name,DiscSalesPrice,ISNULL(FixedRate,0) AS FixedRate,
			(CONVERT(VARCHAR(10),ValidFrom,121) +' '+ CONVERT(VARCHAR(8),ValidFrom,108)) AS ValidFrom,
			(CONVERT(VARCHAR(10),ValidUpto,121) +' '+ CONVERT(VARCHAR(8),ValidUpto,108)) AS ValidUpto,
			MinSalePrice,Disc,IsInUse,tsr.Scheme
		FROM FTS_trans_SaleRateLock tsr	
		LEFT OUTER JOIN v_SaleRateLock_customerDetails cust ON tsr.CustomerID = cust.cnt_internalid
		LEFT OUTER JOIN v_Product_SaleRateLock srl ON tsr.ProductID = srl.sProductsID
		WHERE (SaleRateLockID = @SaleRateLockID OR @SaleRateLockID IS NULL)
	END
	
	IF(@Action = 'update')
	BEGIN
		DECLARE @cnt BIGINT
		
		DECLARE @PRODs NVARCHAR(100)='',@SHOPs NVARCHAR(100)=''
		set @PRODs=(SELECT TOP(1)convert(nvarchar(100),Product) FROM @UDT_RATELIST)
		set @SHOPs=(select TOP(1)convert(nvarchar(100),Entity) FROM @UDT_RATELIST)

		DECLARE @_Fromdt DATETIME
		DECLARE @_Todt DATETIME
		DECLARE @_CustomerID VARCHAR(10) 
		DECLARE @_ProductID	BIGINT
		SELECT @_Fromdt = ValidFrom,@_Todt = ValidUpto,@_CustomerID = @CustomerID, @_ProductID = @ProductID
		FROM FTS_trans_SaleRateLock WHERE SaleRateLockID = @SaleRateLockID
		IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE CustomerID = @CustomerID AND ProductID = @ProductID AND (CONVERT(SMALLDATETIME,ValidFrom,120) = CONVERT(SMALLDATETIME,@ValidFrom,120 )) AND (CONVERT(SMALLDATETIME,ValidUpto,120) = CONVERT(SMALLDATETIME,@ValidUpto,120 )))
		BEGIN
			UPDATE FTS_trans_SaleRateLock
				SET CustomerID = @SHOPs,ProductID = @PRODs,DiscSalesPrice= @DiscSalesPrice,FixedRate=@FixedRate,ApprovedBy = @ApprovedBy,
					ApprovedOn = GETDATE(),MinSalePrice = @MinSalePrice,
					Disc = @Disc,SCHEME=@SCHEME
				WHERE SaleRateLockID = @SaleRateLockID
			SELECT '13265' AS Insertmsg	
		END
		ELSE
		BEGIN
			SELECT @cnt = COUNT(*) FROM FTS_trans_SaleRateLock WHERE CustomerID = @CustomerID AND ProductID = @ProductID AND
			((ValidFrom >= CONVERT(SMALLDATETIME,@ValidFrom,120)   AND ValidFrom <= CONVERT(SMALLDATETIME,@ValidUpto,120)) OR  (ValidUpto >= CONVERT(SMALLDATETIME,@ValidFrom,120)   AND ValidUpto <= CONVERT(SMALLDATETIME,@ValidUpto,120)) AND SaleRateLockID != @SaleRateLockID)
			IF(@cnt = 0)
			BEGIN
				UPDATE FTS_trans_SaleRateLock
				SET		CustomerID = @SHOPs,ProductID = @PRODs,DiscSalesPrice= @DiscSalesPrice,FixedRate=@FixedRate,ApprovedBy = @ApprovedBy,
						ApprovedOn = GETDATE(),ValidFrom = @ValidFrom,ValidUpto = @ValidUpto,MinSalePrice = @MinSalePrice,
						Disc = @Disc,SCHEME=@SCHEME
				WHERE SaleRateLockID = @SaleRateLockID
				SELECT '1952' AS Insertmsg
			END
			ELSE IF(@cnt = 1)
			BEGIN
				--UPDATE FTS_trans_SaleRateLock
				--SET		CustomerID = @CustomerID,ProductID = @ProductID,DiscSalesPrice= @DiscSalesPrice,ApprovedBy = @ApprovedBy,
				--		ApprovedOn = GETDATE(),MinSalePrice = @MinSalePrice,ValidFrom = @ValidFrom,ValidUpto = @ValidUpto,
				--		Disc = @Disc
				--WHERE SaleRateLockID = @SaleRateLockID
				--SELECT '10012' AS Insertmsg
				SELECT '-11' AS Insertmsg
				--SELECT '-1123' AS Insertmsg	
			END
			ELSE IF(@cnt > 1)
			BEGIN
				SELECT '-11' AS Insertmsg	
			END
			
		END
	END
	IF(@Action = 'delete')
	BEGIN
		IF EXISTS(SELECT 1 FROM FTS_trans_SaleRateLock WHERE SaleRateLockID = @SaleRateLockID AND  IsInUse = 1)
		BEGIN
			SELECT '-998' AS Insertmsg
		END
		ELSE 
		BEGIN
			DELETE FROM FTS_trans_SaleRateLock
			WHERE SaleRateLockID = @SaleRateLockID
			SELECT '-999' AS Insertmsg
		END

	END

	IF(@Action = 'GetImportData')
	BEGIN
		DECLARE @STATE_NAME NVARCHAR(300)
		SET @STATE_NAME=(SELECT state FROM tbl_master_state WHERE id=@StateID)
		--	Code	Description	Category	Brand	Price to Distributor	Price to Retailer
		--IND001	BP-1-BUTTER SCOTCH-5000 ML	Gallon	ROLLICK	  324.00 	  405 

		select @STATE_NAME AS STATE,sProducts_Code AS Code,sProducts_Name AS Description,
		--Rev 3.0
 0.00 AS 'Price to Super',
		--Rev 3.0 End
		0.00 AS 'Price to Distributor','0.00' AS 'Price to Retailer' 
		--Rev 3.0
		,0.0000 AS 'Qty per Unit (Distributor)',0.0000 AS 'Scheme Qty (For Distributor)',0.00 AS 'Effective Price'
		--Rev 3.0 End
		from Master_sProducts
		
	END

	IF(@Action = 'InsertImportData')
	BEGIN
		
		DECLARE @STATE_ID BIGINT

		SET @STATE_ID=(SELECT TOP(1)ST.ID FROM tbl_master_state ST
		INNER JOIN @UDT_PRODUCTRATE TMP ON TMP.[STATE]=ST.state)

		INSERT INTO FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE_LOG (PRODUCT_ID,DD_PRICE,SHOP_PRICE,STATE_ID
		--Rev 3.0
		,SUPER_PRICE,QTY_UNIT_DISTRIBUTOR,SCHEME_QTY_DISTRIBUTOR,EFFECTIVE_PRICE
		--Rev 3.0 End
		)
		SELECT PRODUCT_ID,DD_PRICE,SHOP_PRICE,STATE_ID 
		--Rev 3.0 
		,SUPER_PRICE,QTY_UNIT_DISTRIBUTOR,SCHEME_QTY_DISTRIBUTOR,EFFECTIVE_PRICE
		--Rev 3.0 End
		FROM FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE WHERE STATE_ID=@STATE_ID

	-- Rev 4.0
		--DELETE FROM FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE WHERE STATE_ID=@STATE_ID
		DELETE FROM FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE  WHERE STATE_ID=@STATE_ID AND
			EXISTS(SELECT sProducts_ID FROM @UDT_PRODUCTRATE TEMP inner join Master_sProducts pro on TEMP.Description=pro.sProducts_Name
			WHERE sProducts_ID=FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE.PRODUCT_ID )
		-- End of Rev 4.0

		INSERT INTO FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE(PRODUCT_ID,DD_PRICE,SHOP_PRICE,STATE_ID
		--Rev 3.0 
		,SUPER_PRICE,QTY_UNIT_DISTRIBUTOR,SCHEME_QTY_DISTRIBUTOR,EFFECTIVE_PRICE
		--Rev 3.0 End
		)
		select sProducts_ID,[Price to Distributor],[Price to Retailer],ST.ID AS STATE_ID 
		--Rev 3.0 
		,[Price to Super],[Qty per Unit (Distributor)],[Scheme Qty (For Distributor)],[Effective Price]
		--Rev 3.0 End
		from @UDT_PRODUCTRATE  TEMP
		inner join Master_sProducts pro on TEMP.Description=pro.sProducts_Name
		INNER JOIN tbl_master_state ST ON ST.state=TEMP.[STATE] 
		

	END
END
GO
