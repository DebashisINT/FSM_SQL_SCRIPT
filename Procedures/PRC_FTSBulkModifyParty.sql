IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSBulkModifyParty]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSBulkModifyParty] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSBulkModifyParty]
(
@CreateUser_Id NVARCHAR(10)=NULL,
@ACTION NVARCHAR(200)=NULL,
@STATE NVARCHAR(max) = NULL,
@FromDate NVARCHAR(10)=NULL,
@ToDate NVARCHAR(10)=NULL,
@BULKMODIFYPARTY_TABLE UDT_BULKMODIFYPARTY READONLY
) 
AS
/******************************************************************************************************************************
Written by Sanchita for V2.0.38		24-01-2023	Bulk modification feature is required in Parties menu. Refer: 25609
1.0		Sanchita	23/04/2024		V2.0.47		Master > Contact > Parties : Mass Deletion option, Select File option shall be available. Mantis: 27373
******************************************************************************************************************************/
BEGIN
	DECLARE @Strsql NVARCHAR(MAX)
	-- Rev 1.0
	declare @i bigint=1
	declare @user_id bigint=NULL
	declare @ShopTypeid bigint=null
	DECLARE @ShopCode NVARCHAR(max)=null
	DECLARE @Retailer NVARCHAR(500)=null
	DECLARE @Party_Status NVARCHAR(500)=null
	DECLARE @Retailer_ID bigint=null
	DECLARE @Party_Status_ID bigint=null
	-- End of Rev 1.0

	IF @ACTION='BulkUpdate'
		BEGIN
			-- Rev 1.0
			--declare @i bigint=1
			--declare @user_id bigint=NULL
			--declare @ShopTypeid bigint=null
			--DECLARE @ShopCode NVARCHAR(max)=null
			--DECLARE @Retailer NVARCHAR(500)=null
			--DECLARE @Party_Status NVARCHAR(500)=null
			--DECLARE @Retailer_ID bigint=null
			--DECLARE @Party_Status_ID bigint=null

			SET @i = 1
			-- End of Rev 1.0

			DECLARE DB_CURSOR CURSOR FOR
			SELECT [Shop_Code],isnull([Retailer],''),isnull([Party_Status],'') FROM @BULKMODIFYPARTY_TABLE 
				where [Shop_Code] is not NULL --and isnull([Retailer],'')<>'' and isnull([Party_Status],'')<>''
			OPEN DB_CURSOR
			FETCH NEXT FROM DB_CURSOR INTO @ShopCode,@Retailer,@Party_Status 
			WHILE @@FETCH_STATUS=0
				begin
					IF exists (select * from tbl_master_shop where shop_code=@ShopCode)
						BEGIN
							--set @Retailer_ID = (select top 1 shop_id from tbl_master_shop where Shop_Name=@Retailer)
							set @Retailer_ID = ( select top 1 ID from tbl_shoptypeDetails where Name=@Retailer )
							set @Party_Status_ID = (select top 1 ID from FSM_PARTYSTATUS where PARTYSTATUS=@Party_Status)

							--if ( @Retailer<>'' and not exists(select top 1 shop_id from tbl_master_shop where Shop_Name=@Retailer) )
							if ( @Retailer<>'' and not exists(select top 1 ID from tbl_shoptypeDetails where Name=@Retailer) )
								begin
									INSERT INTO FTS_BulkModifyLog ([Shop_Code], [Shop_Name], [Shop_Type], [Shop_Owner_Contact], [State], [Entitycode], 
										[Retailer], [Party_Status], [Status], [Reason], [UpdateOn], [UpdatedBy])
				
									select S.Shop_Code,S.Shop_Name,SType.Name,S.Shop_Owner_Contact,ST.state,S.EntityCode,@Retailer Retailer_ID,@Party_Status Party_Status_id,
									'Failed','Invalid Retailer',GETDATE(),@CreateUser_Id from tbl_master_shop S
									left outer join tbl_master_state ST on S.stateId=ST.id
									left outer join tbl_master_shop SR on S.retailer_id=SR.Shop_ID
									left outer join FSM_PARTYSTATUS PS on S.Party_Status_id=PS.ID
									left outer join tbl_shoptype SType on S.type=Stype.shop_typeId
									where S.Shop_Code=@ShopCode

								end
							else if ( @Party_Status<>'' and not exists(select top 1 ID from FSM_PARTYSTATUS where PARTYSTATUS=@Party_Status) )
								begin
									INSERT INTO FTS_BulkModifyLog ([Shop_Code], [Shop_Name], [Shop_Type], [Shop_Owner_Contact], [State], [Entitycode], 
										[Retailer], [Party_Status], [Status], [Reason], [UpdateOn], [UpdatedBy])
				
									select S.Shop_Code,S.Shop_Name,Stype.Name,S.Shop_Owner_Contact,ST.state,S.EntityCode,@Retailer Retailer_ID,@Party_Status Party_Status_id,
									'Failed','Invalid Party Status',GETDATE(),@CreateUser_Id from tbl_master_shop S
									left outer join tbl_master_state ST on S.stateId=ST.id
									left outer join tbl_master_shop SR on S.retailer_id=SR.Shop_ID
									left outer join FSM_PARTYSTATUS PS on S.Party_Status_id=PS.ID
									left outer join tbl_shoptype SType on S.type=Stype.shop_typeId
									where S.Shop_Code=@ShopCode
								end
							else if ( @Party_Status='' and @Retailer='' )
								begin
									INSERT INTO FTS_BulkModifyLog ([Shop_Code], [Shop_Name], [Shop_Type], [Shop_Owner_Contact], [State], [Entitycode], 
										[Retailer], [Party_Status], [Status], [Reason], [UpdateOn], [UpdatedBy])
				
									select S.Shop_Code,S.Shop_Name,SType.Name,S.Shop_Owner_Contact,ST.state,S.EntityCode,@Retailer Retailer_ID,@Party_Status Party_Status_id,
									'Failed','Blank Retailer and Party Status',GETDATE(),@CreateUser_Id from tbl_master_shop S
									left outer join tbl_master_state ST on S.stateId=ST.id
									left outer join tbl_master_shop SR on S.retailer_id=SR.Shop_ID
									left outer join FSM_PARTYSTATUS PS on S.Party_Status_id=PS.ID
									left outer join tbl_shoptype SType on S.type=Stype.shop_typeId
									where S.Shop_Code=@ShopCode
								end
							else
								begin
									
									if (@Retailer <>'')
										update tbl_Master_shop set retailer_id=@Retailer_ID where Shop_Code=@ShopCode

									if (@Party_Status_ID <>'')
										update tbl_Master_shop set Party_Status_id=@Party_Status_ID where Shop_Code=@ShopCode

									INSERT INTO FTS_BulkModifyLog ([Shop_Code], [Shop_Name], [Shop_Type], [Shop_Owner_Contact], [State], [Entitycode], 
											[Retailer], [Party_Status], [Status], [Reason], [UpdateOn], [UpdatedBy])
				
									select S.Shop_Code,S.Shop_Name,SType.Name,S.Shop_Owner_Contact,ST.state,S.EntityCode,@Retailer Retailer_ID,@Party_Status Party_Status_id,
									'Sucess','Sucess',GETDATE(),@CreateUser_Id from tbl_master_shop S
									left outer join tbl_master_state ST on S.stateId=ST.id
									left outer join tbl_master_shop SR on S.retailer_id=SR.Shop_ID
									left outer join FSM_PARTYSTATUS PS on S.Party_Status_id=PS.ID
									left outer join tbl_shoptype SType on S.type=Stype.shop_typeId
									where S.Shop_Code=@ShopCode
								end
																
						END
					ELSE
						BEGIN
							INSERT INTO FTS_BulkModifyLog ([Shop_Code], [Shop_Name], [Shop_Type], [Shop_Owner_Contact], [State], [Entitycode], 
									[Retailer], [Party_Status], [Status], [Reason], [UpdateOn], [UpdatedBy])
				
							select S.Shop_Code,S.Shop_Name,SType.Name,S.Shop_Owner_Contact,ST.state,S.EntityCode,@Retailer Retailer_ID,@Party_Status Party_Status_id,
							'Failed','Invalid Shop Code',GETDATE(),@CreateUser_Id from tbl_master_shop S
							left outer join tbl_master_state ST on S.stateId=ST.id
							left outer join tbl_master_shop SR on S.retailer_id=SR.Shop_ID
							left outer join FSM_PARTYSTATUS PS on S.Party_Status_id=PS.ID
							left outer join tbl_shoptype SType on S.type=Stype.shop_typeId
							where S.Shop_Code=@ShopCode
						END

					FETCH NEXT FROM DB_CURSOR INTO @ShopCode,@Retailer,@Party_Status

				end

			close db_cursor
			deallocate db_cursor

			SELECT logs.* FROM FTS_BulkModifyLog AS logs
			INNER JOIN @BULKMODIFYPARTY_TABLE temp ON logs.[Shop_Code] =temp.[Shop_Code]
		END

	IF @ACTION='FetchDataStatewise'
		BEGIN
			set @STATE = replace(@STATE,'[','')
			set @STATE = replace(@STATE,']','')
			set @STATE = replace(@STATE,'"','''')

			SET @Strsql=''
			SET @Strsql+=' select S.Shop_Code,S.Shop_Name,SType.Name Shop_Type,S.Shop_Owner_Contact,ST.state,S.EntityCode,StypeDet.Name Retailer,PS.PARTYSTATUS Party_Status from tbl_master_shop S '
			SET @Strsql+=' left outer join tbl_master_state ST on S.stateId=ST.id '
			SET @Strsql+=' left outer join tbl_master_shop SR on S.retailer_id=SR.Shop_ID '
			SET @Strsql+=' left outer join FSM_PARTYSTATUS PS on S.Party_Status_id=PS.ID '
			SET @Strsql+=' left outer join tbl_shoptype SType on S.type=Stype.shop_typeId '
			SET @Strsql+=' left outer join tbl_shoptypeDetails StypeDet on S.retailer_id=StypeDet.Id '
			SET @Strsql+=' where S.stateId in ('+@STATE+') '
			exec sp_executesql @Strsql
			
		END
	IF @ACTION='GetBulkModifyPartyLog'
		BEGIN
			SELECT logs.Shop_Code,logs.Shop_Name,logs.Shop_Type,logs.Shop_Owner_Contact,logs.State,logs.Entitycode,
				logs.Retailer, logs.Party_Status,logs.Status,logs.Reason,logs.UpdateOn,u.user_name UpdatedBy FROM FTS_BulkModifyLog AS logs 
			INNER JOIN TBL_MASTER_USER U ON U.USER_ID=logs.UpdatedBy
			WHERE CAST(logs.UpdateOn AS DATE) BETWEEN @FromDate AND @ToDate
			ORDER BY logs.UpdateOn DESC
		END

	-- Rev 1.0
	IF @ACTION='BulkDelete'
	BEGIN
		SET @i = 1
		DECLARE @deleted INT

		BEGIN TRY
		BEGIN TRANSACTION

			IF(SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [key]='ShopDeleteWithAllTransactions')=0
			begin
				
				SET @deleted = 0

				
				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Shop Deleted Succesfully', GETDATE(), @CreateUser_Id FROM tbl_Master_shop WHERE EXISTS 
				(SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=tbl_Master_shop.Shop_Code)


				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Shop Code does not exists.', GETDATE(), @CreateUser_Id FROM @BULKMODIFYPARTY_TABLE BTABLE 
				WHERE NOT EXISTS (SELECT [Shop_Code] FROM tbl_Master_shop WHERE [Shop_Code]=BTABLE.Shop_Code)


				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Can not delete use in another module.', GETDATE(), @CreateUser_Id FROM @BULKMODIFYPARTY_TABLE PARTY
				WHERE EXISTS (SELECT Shop_Code FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=PARTY.Shop_Code)
				OR EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=PARTY.Shop_Code)
				OR EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=PARTY.Shop_Code)
				OR EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=PARTY.Shop_Code)


				DELETE FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=tbl_Master_shop.Shop_Code)

				SELECT 'Delete Succesfully.' as MSG

				--DECLARE CUR_SHOPDELETE CURSOR FOR 
				--SELECT Shop_Code FROM #SHOPCODE_LIST
				--OPEN CUR_SHOPDELETE 
				--FETCH NEXT FROM CUR_SHOPDELETE INTO @Shop_Code_Del
				--WHILE @@FETCH_STATUS=0
				--BEGIN
				--	IF ((SELECT count(0) FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=@Shop_Code_Del)>1)
				--	BEGIN
				--		SET @notDeleted = 1
				--		--SELECT 'Can not delete use in another module.' as MSG
				--	END
				--	ELSE IF EXISTS(SELECT 1 FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=@Shop_Code_Del)
				--	BEGIN
				--		SET @notDeleted = 1
				--		--SELECT 'Can not delete use in another module.' as MSG
				--	END
				--	ELSE
				--	BEGIN
				--		DELETE FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=@Shop_Code_Del
				--		DELETE FROM TBL_MASTER_SHOP WHERE SHOP_CODE=@Shop_Code_Del
				--		SET @deleted = 1
				--		--SELECT 'Delete Succesfully.' as MSG
				--	END

				--FETCH NEXT FROM CUR_SHOPDELETE INTO @Shop_Code_Del
				--END
	   --  		CLOSE CUR_SHOPDELETE
				--DEALLOCATE CUR_SHOPDELETE

				--IF @deleted = 1 AND @notDeleted = 1
				--BEGIN
				--	SELECT 'Party that are not used in other modules delete Succesfully.' as MSG
				--END
				--ELSE IF @deleted = 1 AND @notDeleted = 0
				--BEGIN
				--	SELECT 'Delete Succesfully.' as MSG
				--END
				--ELSE 
				--BEGIN
				--	SELECT 'Can not delete used in another module.' as MSG
				--END
			END
			ELSE
			BEGIN
			
				IF OBJECT_ID('tempdb..#SHOPIMAGE_LIST') IS NOT NULL
						DROP TABLE #SHOPIMAGE_LIST
					CREATE TABLE #SHOPIMAGE_LIST (Shop_Image NVARCHAR(500) NULL)
					CREATE NONCLUSTERED INDEX Shop_Image ON #SHOPIMAGE_LIST (Shop_Image ASC)


				DELETE FROM FTS_STAGEMAP WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=FTS_STAGEMAP.SHOP_ID)
					
				DELETE FROM tbl_trans_shopActivitysubmit WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_trans_shopActivitysubmit.SHOP_ID)
					
				DELETE FROM tbl_trans_shopActivitysubmit_Archive WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_trans_shopActivitysubmit_Archive.SHOP_ID)

				DELETE FROM tbl_trans_fts_Orderupdate WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_trans_fts_Orderupdate.Shop_Code)
					
				DELETE FROM tbl_FTs_OrderdetailsProduct WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_FTs_OrderdetailsProduct.Shop_Code)

			
				--SET @ORDER_CODE = (SELECT ORDER_CODE FROM FSMITCORDERHEADER WHERE SHOP_ID=@Shop_Code_Del)
				DELETE FROM FSMITCORDERDETAIL WHERE EXISTS (SELECT ORDER_CODE FROM FSMITCORDERHEADER H INNER JOIN @BULKMODIFYPARTY_TABLE B ON H.SHOP_ID=B.Shop_Code)
				DELETE FROM FSMITCORDERHEADER WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=FSMITCORDERHEADER.SHOP_ID)

				DELETE FROM ORDERPRODUCTATTRIBUTEDET WHERE EXISTS (SELECT ORDER_ID FROM ORDERPRODUCTATTRIBUTE H INNER JOIN @BULKMODIFYPARTY_TABLE B ON H.SHOP_ID=B.Shop_Code)
				DELETE FROM ORDERPRODUCTATTRIBUTE WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=ORDERPRODUCTATTRIBUTE.SHOP_ID)


				--SET @SHOP_ID = (SELECT Shop_ID FROM TBL_MASTER_SHOP WHERE Shop_Code=@Shop_Code_Del)
				DELETE FROM FTS_ShopMoreDetails WHERE EXISTS (SELECT SH.Shop_ID FROM TBL_MASTER_SHOP SH INNER JOIN @BULKMODIFYPARTY_TABLE B ON SH.Shop_Code=B.Shop_Code)
				DELETE FROM FTS_DOCTOR_DETAILS  WHERE EXISTS (SELECT SH.Shop_ID FROM TBL_MASTER_SHOP SH INNER JOIN @BULKMODIFYPARTY_TABLE B ON SH.Shop_Code=B.Shop_Code)


				IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = 'FSM_ITC_MIRROR')
				BEGIN
					IF (SELECT [VALUE] FROM FTS_APP_CONFIG_SETTINGS WHERE [KEY]='IsUpdateVisitDataInTodayTable' )=1
					BEGIN
						delete FROM FSM_ITC_MIRROR..Trans_ShopActivitySubmit_TodayData WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=FSM_ITC_MIRROR..Trans_ShopActivitySubmit_TodayData.SHOP_ID)
					END

					delete FROM FSM_ITC_MIRROR..tbl_trans_shopActivitysubmit_Archive WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=FSM_ITC_MIRROR..tbl_trans_shopActivitysubmit_Archive.SHOP_ID)
				END
				ELSE
				BEGIN
					delete FROM tbl_trans_shopActivitysubmit_Archive WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_trans_shopActivitysubmit_Archive.SHOP_ID)
				END
					
				--SET @SHOP_IMAGE = (SELECT TOP 1 Shop_Image FROM tbl_Master_shop WHERE Shop_Code=@Shop_Code_Del)
				INSERT INTO #SHOPIMAGE_LIST (Shop_Image) 
				SELECT distinct Shop_Image FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)

				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Shop Deleted Succesfully', GETDATE(), @CreateUser_Id FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)

				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Shop Code does not exists.', GETDATE(), @CreateUser_Id FROM @BULKMODIFYPARTY_TABLE BTABLE WHERE NOT EXISTS (SELECT [Shop_Code] FROM tbl_Master_shop WHERE [Shop_Code]=BTABLE.Shop_Code)

				DELETE FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_Code] FROM @BULKMODIFYPARTY_TABLE WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)

				SELECT 'Delete Succesfully.' as MSG, Shop_Image as SHOP_IMAGE FROM #SHOPIMAGE_LIST
			END

			
		
			--SELECT logs.* FROM FTS_BulkDeleteLog AS logs
			--INNER JOIN @BULKMODIFYPARTY_TABLE temp ON logs.[Shop_Code] =temp.[Shop_Code]

			COMMIT TRANSACTION
			
		END TRY

		BEGIN CATCH
			ROLLBACK TRANSACTION
			SELECT 'Error in Delte.' as MSG
		END CATCH
	END

	IF @ACTION='GetMassDeletePartyLog'
	BEGIN
		SELECT logs.Shop_Code,logs.Reason,logs.UpdateOn,u.user_name UpdatedBy FROM [FTS_BulkDeleteLog] AS logs 
		INNER JOIN TBL_MASTER_USER U ON U.USER_ID=logs.UpdatedBy
		WHERE CAST(logs.UpdateOn AS DATE) BETWEEN @FromDate AND @ToDate
		ORDER BY logs.UpdateOn DESC
	END
	-- End of Rev 1.0
 END
 GO