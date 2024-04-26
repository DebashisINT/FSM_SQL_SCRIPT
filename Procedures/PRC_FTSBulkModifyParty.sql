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
@BULKMODIFYPARTY_TABLE UDT_BULKMODIFYPARTY READONLY,
-- Rev 1.0
@BULKDELETEPARTY_TABLE UDT_BULKDELETEPARTY READONLY
-- End of Rev 1.0
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

				
				INSERT INTO [FTS_BULKDELETELOG] ([SHOP_ID], [REASON], [UPDATEON], [UPDATEDBY])
				SELECT SHOP_ID, 'Shop Deleted Succesfully', GETDATE(), @CreateUser_Id FROM tbl_Master_shop SHOP WHERE 
				EXISTS (SELECT [SHOP_ID] FROM @BULKDELETEPARTY_TABLE WHERE [SHOP_ID]=SHOP.SHOP_ID)
				AND NOT EXISTS (SELECT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=SHOP.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=SHOP.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=SHOP.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=SHOP.Shop_Code)


				INSERT INTO [FTS_BULKDELETELOG] ([SHOP_ID], [REASON], [UPDATEON], [UPDATEDBY])
				SELECT SHOP_ID, 'Shop Code does not exists.', GETDATE(), @CreateUser_Id FROM @BULKDELETEPARTY_TABLE BTABLE 
				WHERE NOT EXISTS (SELECT [Shop_ID] FROM tbl_Master_shop WHERE [Shop_ID]=BTABLE.SHOP_ID)


				INSERT INTO [FTS_BULKDELETELOG] ([SHOP_ID], [REASON], [UPDATEON], [UPDATEDBY])
				SELECT SHOP_ID, 'Can not delete. Used in another module.', GETDATE(), @CreateUser_Id FROM 
				tbl_Master_shop SHOP WHERE EXISTS 
				(SELECT [SHOP_ID] FROM @BULKDELETEPARTY_TABLE WHERE [SHOP_ID]=SHOP.SHOP_ID)
				and
				(
				EXISTS (SELECT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=SHOP.Shop_code)
				OR EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=SHOP.Shop_code)
				OR EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=SHOP.Shop_code)
				OR EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=SHOP.Shop_code)
				)
				

				UPDATE USR SET USR.user_ShopStatus=1 FROM TBL_MASTER_USER USR INNER JOIN TBL_MASTER_SHOP SH ON USR.user_id=SH.Shop_CreateUser
				WHERE EXISTS (SELECT [SHOP_ID] FROM @BULKDELETEPARTY_TABLE WHERE [SHOP_ID]=SH.Shop_ID)
				AND NOT EXISTS (SELECT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=SH.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=SH.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=SH.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=SH.Shop_Code)


				DELETE from tbl_Master_shop
				WHERE EXISTS (SELECT [SHOP_ID] FROM @BULKDELETEPARTY_TABLE WHERE [SHOP_ID]=tbl_Master_shop.Shop_ID)
				AND NOT EXISTS (SELECT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=tbl_Master_shop.Shop_Code)

				SELECT 'Delete Succesfully.' as MSG
				
			END
			ELSE
			BEGIN
			
				IF OBJECT_ID('tempdb..#SHOPIMAGE_LIST') IS NOT NULL
						DROP TABLE #SHOPIMAGE_LIST
					CREATE TABLE #SHOPIMAGE_LIST (Shop_Image NVARCHAR(500) NULL)
					CREATE NONCLUSTERED INDEX Shop_Image ON #SHOPIMAGE_LIST (Shop_Image ASC)


				DELETE from FTS_STAGEMAP WHERE EXISTS 
				(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.[Shop_Code]=FTS_STAGEMAP.SHOP_ID)
					
				DELETE from tbl_trans_shopActivitysubmit WHERE EXISTS 
				(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.[Shop_Code]=tbl_trans_shopActivitysubmit.SHOP_ID)

				DELETE from tbl_trans_shopActivitysubmit_Archive WHERE EXISTS 
				(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.[Shop_Code]=tbl_trans_shopActivitysubmit_Archive.SHOP_ID)

				DELETE from tbl_trans_fts_Orderupdate WHERE EXISTS 
				(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.[Shop_Code]=tbl_trans_fts_Orderupdate.Shop_Code)
					
				DELETE from tbl_FTs_OrderdetailsProduct WHERE EXISTS 
				(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.[Shop_Code]=tbl_FTs_OrderdetailsProduct.Shop_Code)
				
			
				--SET @ORDER_CODE = (SELECT ORDER_CODE FROM FSMITCORDERHEADER WHERE SHOP_ID=@Shop_Code_Del)
				DELETE from FSMITCORDERDETAIL WHERE EXISTS
				(SELECT H.ORDER_CODE FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID INNER JOIN FSMITCORDERHEADER H ON H.SHOP_ID=SH.Shop_Code 
				WHERE H.ORDER_CODE = FSMITCORDERDETAIL.ORDER_CODE)
				

				DELETE from FSMITCORDERHEADER WHERE EXISTS 
				(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.[Shop_Code]=FSMITCORDERHEADER.SHOP_ID)

				
				DELETE from ORDERPRODUCTATTRIBUTEDET WHERE EXISTS 
				(SELECT H.ORDER_ID FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID INNER JOIN ORDERPRODUCTATTRIBUTE H ON H.SHOP_ID=SH.Shop_Code 
				WHERE H.ORDER_ID = ORDERPRODUCTATTRIBUTEDET.ORDER_ID)


				DELETE from ORDERPRODUCTATTRIBUTE WHERE EXISTS 
				(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.Shop_Code = ORDERPRODUCTATTRIBUTE.SHOP_ID)
				

				--SET @SHOP_ID = (SELECT Shop_ID FROM TBL_MASTER_SHOP WHERE Shop_Code=@Shop_Code_Del)
				DELETE from FTS_ShopMoreDetails WHERE EXISTS 
				(SELECT SH.Shop_ID FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.Shop_ID WHERE SH.Shop_ID=FTS_ShopMoreDetails.SHOP_ID)


				DELETE from FTS_DOCTOR_DETAILS  WHERE EXISTS 
				(SELECT SH.Shop_ID FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.Shop_ID WHERE SH.Shop_ID=FTS_DOCTOR_DETAILS.SHOP_ID)


				IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = 'FSM_ITC_MIRROR')
				BEGIN
					IF (SELECT [VALUE] FROM FTS_APP_CONFIG_SETTINGS WHERE [KEY]='IsUpdateVisitDataInTodayTable' )=1
					BEGIN
						DELETE from FSM_ITC_MIRROR..Trans_ShopActivitySubmit_TodayData WHERE EXISTS 
						(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.Shop_Code = FSM_ITC_MIRROR..Trans_ShopActivitySubmit_TodayData.SHOP_ID)
					END

					DELETE from FSM_ITC_MIRROR..tbl_trans_shopActivitysubmit_Archive WHERE EXISTS 
					(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.Shop_Code = FSM_ITC_MIRROR..tbl_trans_shopActivitysubmit_Archive.SHOP_ID)
				END
				ELSE
				BEGIN
					DELETE from tbl_trans_shopActivitysubmit_Archive WHERE EXISTS 
					(SELECT SH.Shop_Code FROM TBL_MASTER_SHOP SH INNER JOIN @BULKDELETEPARTY_TABLE B ON SH.Shop_ID=B.SHOP_ID WHERE SH.Shop_Code = tbl_trans_shopActivitysubmit_Archive.SHOP_ID)
					
				END
					
				--SET @SHOP_IMAGE = (SELECT TOP 1 Shop_Image FROM tbl_Master_shop WHERE Shop_Code=@Shop_Code_Del)
				INSERT INTO #SHOPIMAGE_LIST (Shop_Image) 
				SELECT distinct Shop_Image FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_ID] FROM @BULKDELETEPARTY_TABLE WHERE [Shop_ID]=tbl_Master_shop.Shop_ID)

				INSERT INTO [FTS_BULKDELETELOG] ([SHOP_ID], [REASON], [UPDATEON], [UPDATEDBY])
				SELECT SHOP_ID, 'Shop Deleted Succesfully', GETDATE(), @CreateUser_Id FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_ID] FROM @BULKDELETEPARTY_TABLE WHERE [Shop_ID]=tbl_Master_shop.Shop_ID)

				INSERT INTO [FTS_BULKDELETELOG] ([SHOP_ID], [REASON], [UPDATEON], [UPDATEDBY])
				SELECT SHOP_ID, 'Shop Code does not exists.', GETDATE(), @CreateUser_Id FROM @BULKDELETEPARTY_TABLE BTABLE WHERE NOT EXISTS (SELECT [Shop_ID] FROM tbl_Master_shop WHERE [Shop_ID]=BTABLE.Shop_ID)


				UPDATE USR SET USR.user_ShopStatus=1 FROM TBL_MASTER_USER USR INNER JOIN TBL_MASTER_SHOP SH ON USR.user_id=SH.Shop_CreateUser
				WHERE EXISTS (SELECT [Shop_ID] FROM @BULKDELETEPARTY_TABLE WHERE [Shop_ID]=SH.Shop_ID)


				DELETE from tbl_Master_shop WHERE EXISTS (SELECT [Shop_ID] FROM @BULKDELETEPARTY_TABLE WHERE [Shop_ID]=tbl_Master_shop.Shop_ID)

				SELECT 'Delete Succesfully.' as MSG, Shop_Image as SHOP_IMAGE FROM #SHOPIMAGE_LIST
			END


			COMMIT TRANSACTION
			
		END TRY

		BEGIN CATCH
			ROLLBACK TRANSACTION
			SELECT 'Error in Delte.' as MSG
		END CATCH
	END

	IF @ACTION='GetMassDeletePartyLog'
	BEGIN
		SELECT logs.Shop_ID,logs.Reason,logs.UpdateOn,u.user_name UpdatedBy FROM [FTS_BulkDeleteLog] AS logs 
		INNER JOIN TBL_MASTER_USER U ON U.USER_ID=logs.UpdatedBy
		WHERE CAST(logs.UpdateOn AS DATE) BETWEEN @FromDate AND @ToDate
		ORDER BY logs.UpdateOn DESC
	END
	-- End of Rev 1.0
 END
 GO