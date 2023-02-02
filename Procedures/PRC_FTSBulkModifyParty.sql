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
******************************************************************************************************************************/
BEGIN
	DECLARE @Strsql NVARCHAR(MAX)

	IF @ACTION='BulkUpdate'
		BEGIN
			declare @i bigint=1
			declare @user_id bigint=NULL
			declare @ShopTypeid bigint=null
			DECLARE @ShopCode NVARCHAR(max)=null
			DECLARE @Retailer NVARCHAR(500)=null
			DECLARE @Party_Status NVARCHAR(500)=null
			DECLARE @Retailer_ID bigint=null
			DECLARE @Party_Status_ID bigint=null

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
 END
 GO