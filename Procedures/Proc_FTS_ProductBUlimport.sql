
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_ProductBUlimport]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_ProductBUlimport] AS' 
END
GO



ALTER PROC [Proc_FTS_ProductBUlimport]
	@PRODUCTIMPORT  UDT_FTS_PRODUCT READONLY,
	@user_Id varchar(50)
AS
/********************************************************************************************************************************
Rev 1.0		V2.0.40		09-05-2023		Sanchita		Product MRP & Discount percentage import facility required while importing Product Master
														Refer: 25785
********************************************************************************************************************************/
BEGIN
	BEGIN TRAN
	BEGIN TRY
		Create table #tblprod 
		(
			RowId int,
			Product_CODE varchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS,
			Product_NAME  varchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS,
			Product_CLASS  varchar(MAX)  ,
			Product_BRAND  varchar(MAX)  ,
			Product_SIZE  varchar(MAX)  ,
			-- Rev 1.0
			Product_MRP decimal(18,2) ,
			Product_DISCOUNT decimal(18,2)
			-- End of Rev 1.0
		)

		Create table #tblprod1 
		(
			RowNumberRank int,
			RowId int,
			Product_CODE varchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS,
			Product_NAME  varchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS,
			Product_CLASS  varchar(MAX)  ,
			Product_BRAND  varchar(MAX)  ,
			Product_SIZE  varchar(MAX) ,
			-- Rev 1.0
			Product_MRP decimal(18,2) ,
			Product_DISCOUNT decimal(18,2)
			-- End of Rev 1.0
		)

		declare @prodclass varchar(MAX)
		declare @prodbrand varchar(MAX)
		declare @prodsize varchar(MAX)
		declare @prodcode varchar(MAX)
		declare @Reason varchar(MAX)
		declare @StatusID int
		declare @Status varchar(MAX)
		-- Rev 1.0
		declare @Product_MRP decimal(18,2)
		declare @Product_DISCOUNT decimal(18,2)
		-- End of Rev 1.0

		insert into #tblprod select Row_number() over(order by Product_CODE) as RowId,Product_CODE ,
		Product_NAME ,
		Product_CLASS ,
		Product_BRAND ,
		Product_SIZE 
		-- Rev 1.0
		,Product_MRP, Product_DISCOUNT 
		-- End of Rev 1.0
		from @PRODUCTIMPORT


		declare @i int=1
		declare @rowindex int=1
		set @rowindex=(select count(RowId) from #tblprod)

	-----------------------------------Start Loop basis of hash table-------------------------------

	while(@i<=@rowindex)

	BEGIN
		-- Rev 1.0
		--select @prodclass=Product_CLASS,@prodbrand=Product_BRAND,@prodsize=Product_SIZE ,@prodcode=Product_CODE  from #tblprod where RowId=@i
		select @prodclass=Product_CLASS,@prodbrand=Product_BRAND,@prodsize=Product_SIZE ,@prodcode=Product_CODE
			,@Product_MRP=ISNULL(Product_MRP,0), @Product_DISCOUNT=ISNULL(Product_DISCOUNT,0)	from #tblprod where RowId=@i
		-- End of Rev 1.0

		-----------------------------------Check product code mandatory or not---------------------------
		IF  (isnull(@prodcode,'')='')
		BEGIN

			INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
				Product_NAME ,
				Product_CLASS,
				Product_BRAND,
				Product_SIZE, 
				status,
				StatusName,
				Reason,CreateDate,
				UserID
				-- Rev 1.0
				,Product_MRP, Product_DISCOUNT
				-- End of Rev 1.0
			)
			select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,0,'Failure','Product Code Blank',GETDATE(),@user_Id 
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT 
			-- End of Rev 1.0
			from #tblprod where RowId=@i

			delete  from #tblprod where RowId=@i

		END

		-----------------------------------Check product class mandatory or not---------------------------

		ELSE IF  (isnull(@prodclass,'')='')
		BEGIN

			INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
			Product_NAME ,
			Product_CLASS,
			Product_BRAND,
			Product_SIZE, 
			status,
			StatusName,
			Reason,CreateDate,
			UserID,Currentproduct
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT
			-- End of Rev 1.0
			)
			select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,0,'Failure','Product Class Blank',GETDATE(),@user_Id,1 
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT
			-- End of Rev 1.0
			from #tblprod where RowId=@i

			delete  from #tblprod where RowId=@i

		END


		-----------------------------------Check product Brand mandatory or not---------------------------

		ELSE IF  (isnull(@prodbrand,'')='')
		BEGIN

			INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
			Product_NAME ,
			Product_CLASS,
			Product_BRAND,
			Product_SIZE, 
			status,
			StatusName,
			Reason,CreateDate,
			UserID,Currentproduct
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT
			-- End of Rev 1.0
			)
			select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,0,'Failure','Product Brand Blank',GETDATE(),@user_Id,1 
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT
			-- End of Rev 1.0
			from #tblprod where RowId=@i

			delete  from #tblprod where RowId=@i

		END
		-----------------------------------Check product size mandatory or not---------------------------
		ELSE IF  (isnull(@prodsize,'')='')
		BEGIN
			INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
			Product_NAME ,
			Product_CLASS,
			Product_BRAND,
			Product_SIZE, 
			status,
			StatusName,
			Reason,CreateDate,
			UserID,Currentproduct
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT
			-- End of Rev 1.0
			)
			select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,0,'Failure','Product Strength Blank',GETDATE(),@user_Id,1 
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT
			-- End of Rev 1.0
			from #tblprod where RowId=@i

			delete  from #tblprod where RowId=@i

		END

		-- Rev 1.0
		-----------------------------------Check valid Product MRP---------------------------
		ELSE IF  (isnull(@Product_MRP,0)<0 or isnull(@Product_MRP,0)>99999999.99)
		BEGIN
			INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
			Product_NAME ,
			Product_CLASS,
			Product_BRAND,
			Product_SIZE, 
			status,
			StatusName,
			Reason,CreateDate,
			UserID,Currentproduct
			,Product_MRP, Product_DISCOUNT
			)
			select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,0,'Failure','Product MRP Invalid',GETDATE(),@user_Id,1 
			,Product_MRP, Product_DISCOUNT
			from #tblprod where RowId=@i

			delete  from #tblprod where RowId=@i

		END

		-----------------------------------Check product size mandatory or not---------------------------
		ELSE IF  (isnull(@Product_DISCOUNT,0)<0 or isnull(@Product_DISCOUNT,0)>100)
		BEGIN
			INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
			Product_NAME ,
			Product_CLASS,
			Product_BRAND,
			Product_SIZE, 
			status,
			StatusName,
			Reason,CreateDate,
			UserID,Currentproduct
			,Product_MRP, Product_DISCOUNT
			)
			select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,0,'Failure','Product Discount Invalid',GETDATE(),@user_Id,1 
			,Product_MRP, Product_DISCOUNT
			from #tblprod where RowId=@i

			delete  from #tblprod where RowId=@i

		END
		-- End of Rev 1.0
		-----------------------------------Check product code Unique or not---------------------------

		--ELSE IF  EXISTS(select  sProducts_ID  from Master_sProducts where sProducts_Code=@prodcode)

		--BEGIN

		--INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
		--Product_NAME ,
		--Product_CLASS,
		--Product_BRAND,
		--Product_SIZE, 
		--status,
		--StatusName,
		--Reason,CreateDate,
		--UserID,Currentproduct
		--)

		----select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,0,'Failure','Duplicate Product Code',GETDATE(),@user_Id,1 from #tblprod where RowId=@i
		--select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,1,'Success','Product Code Updated',GETDATE(),@user_Id,1 from #tblprod where RowId=@i

		----delete  from #tblprod where RowId=@i

		--END
		ELSE
		BEGIN
			-----------------------------------Save into Log table---------------------------
			INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
			Product_NAME ,
			Product_CLASS,
			Product_BRAND,
			Product_SIZE, 
			status,
			StatusName,
			Reason,CreateDate,
			UserID,Currentproduct
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT
			-- End of Rev 1.0
			)

			select Product_CODE ,Product_NAME ,Product_CLASS,Product_BRAND ,Product_SIZE,1,'Success','Success',GETDATE(),@user_Id,1 
			-- Rev 1.0
			,isnull(Product_MRP,0), isnull(Product_DISCOUNT,0)
			-- End of Rev 1.0
			from #tblprod where RowId=@i
			
			-----------------------------------Class Code---------------------------
			IF EXISTS(select  ProductClass_Code  from Master_ProductClass where ProductClass_Name=@prodclass)
			BEGIN
				SET @prodclass=(select  ProductClass_ID  from Master_ProductClass where ProductClass_Name=@prodclass)
			END
			ELSE
			BEGIN
				insert into Master_ProductClass (ProductClass_Code,
				ProductClass_Name,
				ProductClass_Description,ProductClass_CreateUser)
				VALUES(@prodclass,@prodclass,@prodclass,@user_Id)

				SET @prodclass=cast(SCOPE_IDENTITY() as varchar(500))

			END

			-----------------------------------Brand ID---------------------------
			IF EXISTS(select  Brand_Id  from tbl_master_brand where Brand_Name=@prodbrand)
			BEGIN
				SET @prodbrand=(select  Brand_Id  from tbl_master_brand where Brand_Name=@prodbrand)
			END
			ELSE
			BEGIN
				insert into tbl_master_brand (Brand_Name,
				Brand_IsActive,
				Brand_CreateUser)
				VALUES(@prodbrand,1,@user_Id)

				SET @prodbrand=cast(SCOPE_IDENTITY() as varchar(500))
			END

			-----------------------------------Size/Strength Code---------------------------
			IF EXISTS(select  Size_ID  from Master_Size where Size_Name=@prodsize)
			BEGIN
				SET @prodsize=(select  Size_ID  from Master_Size where Size_Name=@prodsize)
			END
			ELSE
			BEGIN
				insert into Master_Size (Size_Name,
				Size_Description,
				Size_CreateUser)
				VALUES(@prodsize,@prodsize,@user_Id)

				SET @prodsize=cast(SCOPE_IDENTITY() as varchar(500))
			END

			------------Update table ---------------------
			UPDATE #tblprod set 

			Product_CLASS =@prodclass,
			Product_BRAND =@prodbrand,
			Product_SIZE=@prodsize
			where RowId=@i
		END







		SET @i=@i+1

		END

		-----------------------------------Insert Into main table---------------------------


		INSERT INTO  #tblprod1 
		select  *  from (
		select ROW_NUMBER() OVER(PARTITION BY Product_CODE  ORDER BY RowId) AS RowNumberRank,* from #tblprod
		)T where T.RowNumberRank=1

		MERGE Master_sProducts bi
		USING  #tblprod1 as ms 
		ON bi.sProducts_Code =ms.Product_CODE	

		WHEN MATCHED THEN
		  UPDATE
		  SET

		  bi.sProducts_Name=ms.Product_NAME,
		  bi.sProducts_Description=ms.Product_NAME,
		  bi.sProducts_Brand=ms.Product_BRAND,
		   bi.ProductClass_Code=ms.Product_CLASS,
		  bi.sProducts_Size=ms.Product_SIZE,
		  bi.sProducts_ModifyUser=@user_Id,
		  bi.sProducts_ModifyTime=GETDATE()
		  -- Rev 1.0
		 ,bi.sProduct_MRP=isnull(@Product_MRP,0), bi.sProducts_Discount=isnull(@Product_DISCOUNT ,0)
		 -- End of Rev 1.0
 
		  WHEN NOT MATCHED BY TARGET THEN
  
		INSERT  (sProducts_Code,sProducts_Name,sProducts_Description,sProducts_Brand,ProductClass_Code,sProducts_Size,sProduct_Stockvaluation,
			Is_ServiceItem,sProduct_IsInventory,sProducts_Type,sProducts_TradingLot,sProducts_TradingLotUnit,sProducts_QuoteCurrency,sProducts_QuoteLot
			,sProducts_QuoteLotUnit,sProducts_DeliveryLot,sProducts_DeliveryLotUnit,sProducts_CreateUser,sProducts_CreateTime
			 -- Rev 1.0
			 ,sProduct_MRP, sProducts_Discount 
			 -- End of Rev 1.0
			)

			VALUES
		   (

				ms.Product_CODE ,ms.Product_NAME ,ms.Product_NAME,ms.Product_BRAND ,
				ms.Product_CLASS ,
				ms.Product_SIZE,'A' ,0 ,1 ,0,1,1,1,1,23,1,1,@user_Id,GETDATE()
				-- Rev 1.0
				,isnull(ms.Product_MRP,0), isnull(ms.Product_DISCOUNT,0)
				-- End of Rev 1.0
			);








		--INSERT INTO Master_sProducts(sProducts_Code,sProducts_Name,sProducts_Description,sProducts_Brand,ProductClass_Code,sProducts_Size,sProduct_Stockvaluation,
		--Is_ServiceItem,sProduct_IsInventory,sProducts_Type,sProducts_TradingLot,sProducts_TradingLotUnit,sProducts_QuoteCurrency,sProducts_QuoteLot
		--,sProducts_QuoteLotUnit,sProducts_DeliveryLot,sProducts_DeliveryLotUnit,sProducts_CreateUser,sProducts_CreateTime

		--)

		--select  Product_CODE ,Product_NAME ,Product_NAME,Product_BRAND ,
		--		Product_CLASS ,
		--		Product_SIZE,'A' ,0 ,1 ,0,1,1,1,1,23,1,1,@user_Id,GETDATE()
		--		from  #tblprod


	



		drop  table  #tblprod
		drop  table  #tblprod1
	COMMIT TRAN		

	END TRY

	BEGIN CATCH
	ROLLBACK

		-----------------------------------Save into Log table if error occurs---------------------------
		INSERT INTO tbl_FTS_ProductLOg (Product_CODE ,
			Product_NAME ,
			Product_CLASS,
			Product_BRAND,
			Product_SIZE, 
			status,
			StatusName,
			Reason,
			CreateDate,
			UserID,
			Currentproduct
			-- Rev 1.0
			,Product_MRP, Product_DISCOUNT 
			-- End of Rev 1.0
		)

		select Product_CODE ,
		Product_NAME ,
		Product_CLASS ,
		Product_BRAND ,

		Product_SIZE ,

		2,
		'ERROR',
		ERROR_MESSAGE(),
		GETDATE(),
		@user_Id,1
		-- Rev 1.0
		,Product_MRP, Product_DISCOUNT 
		-- End of Rev 1.0
		from @PRODUCTIMPORT
	END CATCH


	select  Product_CODE  as CODE,
	Product_NAME as NAME,
	Product_CLASS as CLASS,
	Product_BRAND as BRAND,
	Product_SIZE as STRENGTH, 
	-- Rev 1.0
	Product_MRP as MRP, Product_DISCOUNT as DISCOUNT ,
	-- End of Rev 1.0
	StatusName as STATUS,Reason  as REASON from tbl_FTS_ProductLOg where Currentproduct=1

	update tbl_FTS_ProductLOg  set Currentproduct=0


END		