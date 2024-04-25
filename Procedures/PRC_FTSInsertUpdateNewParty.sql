IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSInsertUpdateNewParty]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSInsertUpdateNewParty] AS' 
END
GO

--exec PRC_FTSInsertUpdateNewParty @ACTION='Details'

ALTER PROCEDURE [dbo].[PRC_FTSInsertUpdateNewParty]
(
@ACTION NVARCHAR(500),
@user_id BIGINT=NULL,
@Shop_Name NVARCHAR(300)=NULL,
@Address NVARCHAR(MAX)=NULL,
@Pincode NVARCHAR(15)=NULL,
@Shop_Lat NVARCHAR(MAX)=NULL,
@Shop_Long NVARCHAR(MAX)=NULL,
@Shop_City INT=NULL,
@Shop_Owner NVARCHAR(300)=NULL,
@Shop_WebSite NVARCHAR(300)=NULL,
@Shop_Owner_Email NVARCHAR(300)=NULL,
@Shop_Owner_Contact NVARCHAR(20)=NULL,
@dob DATETIME=NULL,
@date_aniversary DATETIME=NULL,
@ShopType INT=NULL,
@Shop_Image NVARCHAR(MAX)=NULL,
@total_visitcount INT=NULL,
@Lastvisit_date DATETIME=NULL,
@isAddressUpdated INT=NULL,
@assigned_to_pp_id NVARCHAR(100)=NULL,
@assigned_to_dd_id NVARCHAR(100)=NULL,
@stateId NVARCHAR(50)=NULL,
@OTPCode NVARCHAR(100)=NULL,
@VerifiedOTP INT=0,
@AssignTo INT=NULL,
@Amount DECIMAL(18,2)=0,
@OLD_CreateUser BIGINT=NULL,
@EntityCode NVARCHAR(300)=NULL,
@Entity_Location NVARCHAR(MAX)=NULL,
@Alt_MobileNo NVARCHAR(15)=NULL,
@Entity_Status INT=0,
@Entity_Type BIGINT=NULL,
@ShopOwner_PAN NVARCHAR(15)=NULL,
@ShopOwner_Aadhar NVARCHAR(20)=NULL,
-- Rev 17.0
--@ShopCode nvarchar(100)=null,
@ShopCode nvarchar(max)=null,
-- End of Rev 17.0
@Remarks NVARCHAR(500)=NULL,
@CountryId NVARCHAR(50)=NULL,
@Area_id nvarchar(10)=null,
@CraetedUser_id BIGINT=NULL,

@retailer_id NVARCHAR(50)=NULL,
@dealer_id NVARCHAR(50)=NULL,
@Entity NVARCHAR(50)=NULL,
@PartyStatus NVARCHAR(50)=NULL,
@GroupBeat NVARCHAR(50)=NULL,
@AccountHolder NVARCHAR(200)=NULL,
@BankName NVARCHAR(200)=NULL,
@AccountNo NVARCHAR(50)=NULL,
@IFSCCode NVARCHAR(50)=NULL,
@UPIID NVARCHAR(50)=NULL,
@assigned_to_shop_id NVARCHAR(100)=NULL,
--rev 8.0
@GSTN_NUMBER NVARCHAR(200)=NULL,
@Trade_Licence_Number NVARCHAR(200)=NULL,
@Cluster NVARCHAR(150)=NULL,
@Alt_MobileNo1 NVARCHAR(50)=NULL,
@Shop_Owner_Email2 NVARCHAR(250)=NULL
--End of rev 8.0
-- Rev 12.0
,@SearchKey nvarchar(max) = NULL
-- End of Rev 12.0
-- Rev 9.0
,@RETURN_VALUE nvarchar(50)=NULL OUTPUT
-- Ebd of Rev 9.0
) 
AS
/******************************************************************************************************************************
1.0			Tanmoy		08-05-2020			create sp
2.0			Tanmoy		22-05-2020			Insert dd_code and add  @ACTION='DeleteParty'
3.0			Tanmoy		25-05-2020			Add new column 
4.0			Tanmoy		17-08-2020			@ACTION='Details' add Inactive user and active user
5.0			Tanmoy		20-08-2020			@ACTION='Details' add Inactive user and active user WITH USER_ID
6.0			Tanmoy		22-02-2021			@ACTION='InsertShop,UpdateShop' add update extra column
7.0			Tanmoy		29-07-2021			@ACTION='Edit' add update extra column
8.0			Pratik		06-01-2022			@ACTION='InsertShop,UpdateShop,EditShop' add extra columns
9.0			Sanchita	13-01-2022			Auto Code for Party Code in Shop Master. refer : Mantis Issue 24603
10.0		Pratik		19-08-2022			Code for get all group Beat. refer : Mantis Issue 25133
11.0		Sanchita	04-01-2022			A new feature required as "Re-assigned Area/Route/Beat. refer: 25545
12.0		Sanchita	04-01-2022			A new feature required as "Re-assigned Area/Route/Beat. Resolved reported issue. refer: 25545
13.0		v2.0.38		Sanchita	19-01-2023		In shop Master Table, the field shall be updated 'dealer_id=0' if no dealer type is 
													selected while creating/editing Shop. Refer: 25593
14.0		v2.0.38		Sanchita	27-01-2023		Bulk modification feature is required in Parties menu. Refer: 25609
15.0		v2.0.38		Sanchita	27-01-2023		Assign to DD is not showing while making shop from Portal. Refer: 25606
16.0		V2.0.41		Sanchita	05-06-2023		Inactive DD/PP is showing in the Assign to PP/DD list while creating any Shop. Refer: 26262
17.0		V2.0.46		Sanchita	12-04-2024		0027348: FSM: Master > Contact > Parties [Delete Facility]
******************************************************************************************************************************/
BEGIN
	DECLARE @SHOP_CODE NVARCHAR(100)
	set @Lastvisit_date =GETDATE()
	IF @ACTION='Details'
	BEGIN
		SELECT '0' AS ID,'Select' AS Name
		UNION ALL
		SELECT TypeId AS ID,Name FROM tbl_shoptype WHERE IsActive=1

		SELECT '0' AS Shop_Code,'Select' AS Shop_Name
		--UNION ALL
		--SELECT Shop_Code,Shop_Name FROM tbl_Master_shop WHERE type=2

		SELECT '0' AS TypeID,'Select' AS TypeName
		UNION ALL
		SELECT convert(nvarchar(10),TypeID),TypeName FROM Master_OutLetType WHERE IsActive=1


		SELECT '0' AS UserID,'Select' AS username
		UNION ALL
		SELECT convert(nvarchar(10),user_id) as UserID ,user_name as username FROM tbl_master_user WHERE user_inactive='N' order by username

		select '0' as StateID,'Select' as	StateName
		--UNION ALL
		--SELECT convert(nvarchar(10),id) as StateID,state as StateName FROM tbl_master_state where countryid=1 order by StateName

		select '0' as cou_id,'Select' as	cou_country
		UNION ALL
		select convert(nvarchar(10),cou_id) as  cou_id,cou_country from tbl_master_country

	
		SELECT convert(nvarchar(10),user_id) as UserID ,user_name+'('+user_loginid+')' as username FROM tbl_master_user WHERE user_inactive='Y' order by username

		
		SELECT convert(nvarchar(10),user_id) as UserID ,user_name+'('+user_loginid+')' as username FROM tbl_master_user WHERE user_inactive='N' order by username

		EXEC PRC_PARTYSTATUS @ACTION='GETLIST' --8
		EXEC PRC_ENTITYLIST @ACTION='GETLIST'--9
		EXEC Prc_SubType @action='RetailerList'--10
		EXEC Prc_SubType @action='DDList'--11
		EXEC Prc_SubType @action='BeatList',@user_id='378'--12
		--Rev 10.0
		EXEC Prc_SubType @action='BeatListAll'--13
		--End of Rev 10.0
		-- Rev 11.0
		--SELECT convert(nvarchar(10),user_id) as UserID ,user_name+'('+user_loginid+')' as username FROM tbl_master_user u WHERE user_inactive='N'
		--and exists(select user_id from FSM_GROUPBEAT_USERMAP where user_id =u.user_id) order by username

		SELECT convert(nvarchar(10),user_id) as UserID ,user_name+'('+user_loginid+')' as username FROM tbl_master_user order by username

		SELECT convert(nvarchar(10),user_id) as UserID ,user_name+'('+user_loginid+')' as username FROM tbl_master_user WHERE user_inactive='N' order by username
		-- End of Rev 11.0
		-- Rev 15.0
		--select '0' as StateID_BulkModify,'Select' as StateName_BulkModify
		--UNION ALL
		SELECT convert(nvarchar(10),id) as StateID_BulkModify,state as StateName_BulkModify FROM tbl_master_state where countryid=1 order by StateName_BulkModify
		-- End of Rev 15.0
	END

	IF @ACTION='InsertShop'
	BEGIN

		SET @SHOP_CODE=(CAST(@user_id AS varchar(20)) + '_' + cast((CAST(DATEDIFF(SECOND,'1970-01-01',getdate()) AS bigint) * 1155)+1 AS varchar(20)) )

		-- Rev 9.0 [ Generate Auto Party Code for Nordusk]
		DECLARE @IsAutoCodificationRequired nvarchar(100) = '0', 
				@shoptypeName nvarchar(50)  = '', @shoptypePrefix nvarchar(10) = '',
				@StateUniqueCode nvarchar(20) = '',@State varchar(50)='',
				@DocNoPrefix nvarchar(10) = '', @LastNumber bigint = 0, @EntityCodeAuto nvarchar(100)='', 
				@TotalLength bigint=0, @PrefixLength bigint=0, @ErrorText varchar(200)=''

		IF EXISTS(SELECT * FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsAutoCodificationRequired')
		BEGIN
			set @IsAutoCodificationRequired = (SELECT top 1 Value FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsAutoCodificationRequired')
		END

						
		if(@IsAutoCodificationRequired='1')
		begin
			Set @shoptypeName = (SELECT TOP 1 isnull(name,'') from tbl_shoptype WHERE shop_typeid=@shoptype )

			if(@shoptypeName='Shop')
				set @shoptypePrefix = 'RT'
			else if(@shoptypeName='Prime Partner')
				set @shoptypePrefix = 'PP'
			else if(@shoptypeName='Distributor')
				set @shoptypePrefix = 'DD'

			set @StateUniqueCode = (select top 1 isnull(StateUniqueCode,'') from tbl_master_state where countryId=1 and id=@StateID)
			set @State = (select top 1 isnull(state,'') from tbl_master_state where countryId=1 and id=@StateID)

			if(@shoptypePrefix <> '' and @StateUniqueCode<>'')
			begin
				IF NOT EXISTS(select * from tbl_ShopAutoDocnoLastvalue where ShopType=@shoptypePrefix and StateCode=@StateUniqueCode)
				Begin 
					insert into tbl_ShopAutoDocnoLastvalue (ShopName,ShopType,State,StateCode,LastNumber,TotalLength) values(@shoptypeName,@shoptypePrefix,@State,@StateUniqueCode,0,9)
				end

				set @LastNumber = (SELECT top 1 isnull(LastNumber,0) from  tbl_ShopAutoDocnoLastvalue where ShopType=@shoptypePrefix and StateCode=@StateUniqueCode )
				set @TotalLength = (SELECT top 1 isnull(TotalLength,0) from  tbl_ShopAutoDocnoLastvalue where ShopType=@shoptypePrefix and StateCode=@StateUniqueCode )

				if(@LastNumber >= 0)
				begin

					set @PrefixLength = LEN( (ltrim(rtrim(@StateUniqueCode))+ltrim(rtrim(@shoptypePrefix))) )

					set @EntityCodeAuto = ltrim(rtrim(@StateUniqueCode))+ltrim(rtrim(@shoptypePrefix))+ REPLICATE('0',(@TotalLength-@PrefixLength)-LEN(convert(varchar(50),@LastNumber+1))) + convert(varchar(50),@LastNumber+1) 

					update tbl_ShopAutoDocnoLastvalue set LastNumber = @LastNumber+1 where ShopType=@shoptypePrefix and StateCode=@StateUniqueCode 

					set @EntityCode = @EntityCodeAuto

				end
				else
				begin
					set @ErrorText = '205'  --Invalid Last Number
				end
			end
			else
			begin
				if(@shoptypePrefix = '' or @shoptypePrefix is null )
				begin
					set @ErrorText = '206'  --Invalid Shop Type
				end
				else if(@StateUniqueCode='' or @StateUniqueCode is null)
				begin
					set @ErrorText =  '207'  --Invalid State Code
				end
			end
		end

		if(@IsAutoCodificationRequired='0' or (@IsAutoCodificationRequired='1' and @EntityCodeAuto<>'' ) )
		BEGIN
		-- End of Rev 9.0

			INSERT INTO tbl_Master_shop
			(Shop_Code,Shop_Name,Address,Pincode,Shop_Lat,Shop_Long,Shop_City,Shop_Owner,Shop_WebSite,Shop_Owner_Email,Shop_Owner_Contact,dob,date_aniversary,
			type,Shop_CreateUser,Shop_CreateTime,Shop_Image,total_visitcount,Lastvisit_date,isAddressUpdated,assigned_to_pp_id,assigned_to_dd_id,
			stateId,OTPCode,VerifiedOTP,AssignTo,Amount,OLD_CreateUser,EntityCode,Entity_Location,Alt_MobileNo,Entity_Status,Entity_Type,ShopOwner_PAN,ShopOwner_Aadhar,
			Remarks,Area_id,Entered_By,Entered_On,
			retailer_id,dealer_id,Entity_Id,Party_Status_id,beat_id,account_holder,bank_name,account_no,ifsc,upi_id,assigned_to_shop_id
			--rev 8.0
			,GSTN_NUMBER,Trade_Licence_Number,Cluster,Alt_MobileNo1,Shop_Owner_Email2
			--End of rev 8.0
			)

			VALUES(@SHOP_CODE,@Shop_Name,@Address,@Pincode,@Shop_Lat,@Shop_Long,@Shop_City,@Shop_Owner,@Shop_WebSite,@Shop_Owner_Email,@Shop_Owner_Contact,@dob,@date_aniversary,
			@ShopType,@user_id,GETDATE(),@Shop_Image,@total_visitcount,@Lastvisit_date,@isAddressUpdated,@assigned_to_pp_id,@assigned_to_dd_id,
			@stateId,@OTPCode,@VerifiedOTP,@AssignTo,@Amount,@OLD_CreateUser,@EntityCode,@Entity_Location,@Alt_MobileNo,@Entity_Status,@Entity_Type,@ShopOwner_PAN,@ShopOwner_Aadhar,@Remarks,@Area_id,
			@CraetedUser_id,GETDATE(),
			-- Rev 13.0
			--@retailer_id,@dealer_id,@Entity,@PartyStatus,@GroupBeat,@AccountHolder,@BankName,@AccountNo,@IFSCCode,@UPIID,@assigned_to_shop_id
			isnull(@retailer_id,0),isnull(@dealer_id,0),@Entity,@PartyStatus,@GroupBeat,@AccountHolder,@BankName,@AccountNo,@IFSCCode,@UPIID,@assigned_to_shop_id
			-- End of Rev 13.0
			--rev 8.0
			,@GSTN_NUMBER,@Trade_Licence_Number,@Cluster,@Alt_MobileNo1,@Shop_Owner_Email2
			--End of rev 8.0
			)
		-- Rev 9.0
		END
		
		IF(@IsAutoCodificationRequired='1')
		begin
			if(@ErrorText <> '')
				set @RETURN_VALUE =  @ErrorText
			else if(@EntityCodeAuto = '')
				set @RETURN_VALUE = '104'  -- Auto Code not generated
			else if(@EntityCodeAuto <> '')
				set @RETURN_VALUE =  @EntityCodeAuto
		end

		
		-- End of Rev 9.0
	END

	IF @ACTION='UpdateShop'
	BEGIN

		UPDATE tbl_Master_shop SET Shop_Name=@Shop_Name,Address=@Address,Pincode=@Pincode,Shop_Lat=@Shop_Lat,Shop_Long=@Shop_Long,Shop_City=@Shop_City,Shop_Owner=@Shop_Owner,
		Shop_WebSite=@Shop_WebSite,Shop_Owner_Email=@Shop_Owner_Email,Shop_Owner_Contact=@Shop_Owner_Contact,dob=@dob,date_aniversary=@date_aniversary,
		type=@ShopType,Shop_CreateUser=@user_id,Shop_Image=@Shop_Image,total_visitcount=@total_visitcount,isAddressUpdated=@isAddressUpdated,
		assigned_to_pp_id=@assigned_to_pp_id,assigned_to_dd_id=@assigned_to_dd_id,stateId=@stateId,OTPCode=@OTPCode,VerifiedOTP=@VerifiedOTP,AssignTo=@AssignTo,
		Amount=@Amount,OLD_CreateUser=@OLD_CreateUser,EntityCode=@EntityCode,Entity_Location=@Entity_Location,Alt_MobileNo=@Alt_MobileNo,Entity_Status=@Entity_Status,
		Entity_Type=@Entity_Type,ShopOwner_PAN=@ShopOwner_PAN,ShopOwner_Aadhar=@ShopOwner_Aadhar,Shop_ModifyUser=@user_id,Shop_ModifyTime=GETDATE(),
		Remarks=@Remarks,Area_id=@Area_id,LastUpdated_By=@CraetedUser_id,LastUpdated_On=GETDATE()		
		-- Rev 13.0
		--,retailer_id=@retailer_id,dealer_id=@dealer_id,Entity_Id=@Entity,Party_Status_id=@PartyStatus,beat_id=@GroupBeat,account_holder=@AccountHolder,bank_name=@BankName,
		,retailer_id=isnull(@retailer_id,0),dealer_id=isnull(@dealer_id,0),Entity_Id=@Entity,Party_Status_id=@PartyStatus,beat_id=@GroupBeat,account_holder=@AccountHolder,bank_name=@BankName,
		-- End of Rev 13.0
		account_no=@AccountNo,ifsc=@IFSCCode,upi_id=@UPIID,assigned_to_shop_id=@assigned_to_shop_id
		--rev 8.0
		,GSTN_NUMBER=@GSTN_NUMBER,Trade_Licence_Number=@Trade_Licence_Number,Cluster=@Cluster,Alt_MobileNo1=@Alt_MobileNo1,Shop_Owner_Email2=@Shop_Owner_Email2
		--End of rev 8.0
		-- Rev 14.0
		,IsShopModified=1
		-- End of Rev 14.0
		WHERE Shop_Code=@ShopCode 
	END

	IF @ACTION='ShopInactive'
	BEGIN
		IF ((SELECT Entity_Status FROM tbl_Master_shop WHERE Shop_Code=@ShopCode)=1)
		UPDATE tbl_Master_shop SET Entity_Status=0	WHERE Shop_Code=@ShopCode 
		ELSE 
		UPDATE tbl_Master_shop SET Entity_Status=1 WHERE Shop_Code=@ShopCode 

	END

	IF @ACTION='EditShop'
	BEGIN

		SELECT shop.Shop_Code,shop.Shop_Name,shop.Address,shop.Pincode,shop.Shop_Lat,shop.Shop_Long,shop.Shop_City,shop.Shop_Owner,shop.Shop_WebSite,shop.Shop_Owner_Email,shop.Shop_Owner_Contact,
		shop.dob,shop.date_aniversary,isnull(shop.type,0) as type,shop.Shop_CreateUser,shop.Shop_CreateTime,shop.Shop_Image,shop.total_visitcount,shop.Lastvisit_date,shop.isAddressUpdated,shop.assigned_to_pp_id,
		shop.assigned_to_dd_id,PP.shop_name as pp_name,
		isnull(shop.stateId,0) as stateId,shop.OTPCode,shop.VerifiedOTP,shop.AssignTo,shop.Amount,isnull(shop.OLD_CreateUser,0) as OLD_CreateUser,shop.EntityCode,shop.Entity_Location,shop.Alt_MobileNo,
		isnull(shop.Entity_Status,0) as Entity_Status,isnull(shop.Entity_Type,0) as Entity_Type,shop.ShopOwner_PAN,shop.ShopOwner_Aadhar,shop.Remarks,STAT.countryId,shop.Area_id
		,DD.shop_name as DD_name,shop.Party_Status_id,shop.party_status_reason,shop.retailer_id,shop.dealer_id,shop.beat_id,shop.account_holder,shop.account_no,
		shop.bank_name,shop.ifsc,shop.upi_id,shop.Entity_Id,shop.assigned_to_shop_id,assignedShop.Shop_Name as assignedShopName
		--Rev 7.0
		,oldUser.user_name as OldUserName,newUser.user_name as NewUserName
		--End of Rev 7.0
		--rev 8.0
		,shop.GSTN_NUMBER,shop.Trade_Licence_Number,shop.Cluster,shop.Alt_MobileNo1,shop.Shop_Owner_Email2
		--End of rev 8.0
		 FROM tbl_Master_shop shop
		LEFT OUTER JOIN tbl_Master_shop PP ON PP.SHOP_CODE=shop.assigned_to_pp_id and pp.type=2
		LEFT OUTER JOIN tbl_Master_shop DD ON DD.SHOP_CODE=shop.assigned_to_dd_id and DD.type=4
		LEFT OUTER JOIN tbl_Master_shop assignedShop ON assignedShop.SHOP_CODE=shop.assigned_to_shop_id and assignedShop.type=1
		LEFT OUTER JOIN tbl_master_state STAT ON STAT.id=shop.stateId 
		--Rev 7.0
		LEFT OUTER JOIN tbl_Master_user oldUser ON shop.OLD_CreateUser=oldUser.user_id
		LEFT OUTER JOIN tbl_Master_user newUser ON shop.Shop_CreateUser=newUser.user_id
		--End of Rev 7.0
		
		WHERE shop.Shop_Code=@ShopCode 

	END

	IF @ACTION='LasteEntityCodeStateWise'
	BEGIN

		SELECT top(1)EntityCode FROM tbl_Master_shop WHERE stateId=@stateId and type=@ShopType order by Shop_CreateTime desc

	END

	IF @ACTION='GetStateListCountryWise'
	BEGIN

		select '0' as StateID,'Select' as	StateName
		UNION ALL
		SELECT convert(nvarchar(10),id) as StateID,state as StateName FROM tbl_master_state where countryid=@CountryId order by StateName

	END

	IF @ACTION='GetCityListStateWise'
	BEGIN

		select '0' as CityID,'Select' as	CityName
		UNION ALL
		SELECT convert(nvarchar(10),city_id) as CityID,city_name as CityName FROM tbl_master_city where state_id=@stateId order by CityName

	END

	IF @ACTION='GetAreaListCityWise'
	BEGIN

		select '0' as AreaID,'Select' as	AreaName
		UNION ALL
		SELECT convert(nvarchar(10),area_id) as AreaID,area_name as AreaName FROM tbl_master_area where city_id=@Shop_City order by AreaName

	END

	IF @ACTION='DeleteParty'
	BEGIN
		-- Rev 17.0
		--IF ((SELECT count(0) FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=@ShopCode)>1)
		--BEGIN
		--	SELECT 'Can not delete use in another module.' as MSG
		--END
		--ELSE IF EXISTS(SELECT 1 FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=@ShopCode)
		--BEGIN
		--	SELECT 'Can not delete use in another module.' as MSG
		--END
		--ELSE
		--BEGIN
		--	DELETE FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=@ShopCode
		--	DELETE FROM TBL_MASTER_SHOP WHERE SHOP_CODE=@ShopCode
		--	SELECT 'Delete Succesfully.' as MSG
		--END

		DECLARE @SqlStrTable NVARCHAR(MAX), @Shop_Code_Del varchar(100), @deleted int, @notDeleted int

		BEGIN TRY
		BEGIN TRANSACTION
			
			IF OBJECT_ID('tempdb..#SHOPCODE_LIST') IS NOT NULL
					DROP TABLE #SHOPCODE_LIST
			CREATE TABLE #SHOPCODE_LIST (Shop_Code VARCHAR(100) NULL)
			CREATE NONCLUSTERED INDEX Shop_Code ON #SHOPCODE_LIST (Shop_Code ASC)

			IF @ShopCode<>''
			BEGIN
					
				SET @SqlStrTable=''
				SET @ShopCode= ''''+REPLACE(@ShopCode,',',''',''')+''''
				--SET @ShopCode=REPLACE(@ShopCode,'''','')
				SET @sqlStrTable='INSERT INTO #SHOPCODE_LIST SELECT Shop_Code FROM tbl_master_SHOP WHERE Shop_Code IN ('+@ShopCode+')'
				EXEC SP_EXECUTESQL @SqlStrTable
			END

			IF(SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [key]='ShopDeleteWithAllTransactions')=0
			begin
				
				SET @deleted = 0

				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Shop Deleted Succesfully', GETDATE(), @user_id FROM tbl_Master_shop WHERE EXISTS 
				(SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=tbl_Master_shop.Shop_Code)


				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Shop Code does not exists.', GETDATE(), @user_id FROM #SHOPCODE_LIST BTABLE 
				WHERE NOT EXISTS (SELECT [Shop_Code] FROM tbl_Master_shop WHERE [Shop_Code]=BTABLE.Shop_Code)


				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Can not delete use in another module.', GETDATE(), @user_id FROM #SHOPCODE_LIST PARTY
				WHERE EXISTS (SELECT Shop_Code FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=PARTY.Shop_Code)
				OR EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=PARTY.Shop_Code)
				OR EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=PARTY.Shop_Code)
				OR EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=PARTY.Shop_Code)


				DELETE FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Code FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM FSMITCORDERHEADER WHERE Shop_Id=tbl_Master_shop.Shop_Code)
				AND NOT EXISTS (SELECT Shop_Id FROM ORDERPRODUCTATTRIBUTE WHERE Shop_Id=tbl_Master_shop.Shop_Code)

				SELECT 'Delete Succesfully.' as MSG

				--------DECLARE CUR_SHOPDELETE CURSOR FOR 
				--------SELECT Shop_Code FROM #SHOPCODE_LIST
				--------OPEN CUR_SHOPDELETE 
				--------FETCH NEXT FROM CUR_SHOPDELETE INTO @Shop_Code_Del
				--------WHILE @@FETCH_STATUS=0
				--------BEGIN
				--------	IF ((SELECT count(0) FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=@Shop_Code_Del)>1)
				--------	BEGIN
				--------		SET @notDeleted = 1
				--------		--SELECT 'Can not delete use in another module.' as MSG
				--------	END
				--------	ELSE IF EXISTS(SELECT 1 FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=@Shop_Code_Del)
				--------	BEGIN
				--------		SET @notDeleted = 1
				--------		--SELECT 'Can not delete use in another module.' as MSG
				--------	END
				--------	-- Rev Sanchita
				--------	ELSE IF EXISTS(SELECT 1 FROM ORDERPRODUCTATTRIBUTE WHERE SHOP_ID=@Shop_Code_Del)
				--------	BEGIN
				--------		SET @notDeleted = 1
				--------		--SELECT 'Can not delete use in another module.' as MSG
				--------	END
				--------	-- End of Rev Sanchita
				--------	ELSE
				--------	BEGIN
				--------		DELETE FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=@Shop_Code_Del
				--------		DELETE FROM TBL_MASTER_SHOP WHERE SHOP_CODE=@Shop_Code_Del
				--------		SET @deleted = 1
				--------		--SELECT 'Delete Succesfully.' as MSG
				--------	END

				--------FETCH NEXT FROM CUR_SHOPDELETE INTO @Shop_Code_Del
				--------END
    -------- 			CLOSE CUR_SHOPDELETE
				--------DEALLOCATE CUR_SHOPDELETE

				--------SELECT 'Delete Succesfully.' as MSG
				----------IF @deleted = 1 AND @notDeleted = 1
				----------BEGIN
				----------	SELECT 'Party that are not used in other modules delete Succesfully.' as MSG
				----------END
				----------ELSE IF @deleted = 1 AND @notDeleted = 0
				----------BEGIN
				----------	SELECT 'Delete Succesfully.' as MSG
				----------END
				----------ELSE 
				----------BEGIN
				----------	SELECT 'Can not delete used in another module.' as MSG
				----------END
			END
			ELSE
			BEGIN

				IF OBJECT_ID('tempdb..#SHOPIMAGE_LIST') IS NOT NULL
					DROP TABLE #SHOPIMAGE_LIST
				CREATE TABLE #SHOPIMAGE_LIST (Shop_Image NVARCHAR(500) NULL)
				CREATE NONCLUSTERED INDEX Shop_Image ON #SHOPIMAGE_LIST (Shop_Image ASC)

				--IF OBJECT_ID('tempdb..#SHOPCODE_LIST') IS NOT NULL
				--	DROP TABLE #SHOPCODE_LIST
				--CREATE TABLE #SHOPCODE_LIST (Shop_Code VARCHAR(100) NULL)
				--CREATE NONCLUSTERED INDEX Shop_Code ON #SHOPCODE_LIST (Shop_Code ASC)

				--IF @ShopCode<>''
				--BEGIN
					
				--	SET @SqlStrTable=''
				--	SET @ShopCode= ''''+REPLACE(@ShopCode,',',''',''')+''''
				--	--SET @ShopCode=REPLACE(@ShopCode,'''','')
				--	SET @sqlStrTable='INSERT INTO #SHOPCODE_LIST SELECT Shop_Code FROM tbl_master_SHOP WHERE Shop_Code IN ('+@ShopCode+')'
				--	EXEC SP_EXECUTESQL @SqlStrTable
				--END


				--------DECLARE CUR_SHOPDELETE CURSOR FOR 
				--------SELECT Shop_Code FROM #SHOPCODE_LIST
				--------OPEN CUR_SHOPDELETE 
				--------FETCH NEXT FROM CUR_SHOPDELETE INTO @Shop_Code_Del
				--------WHILE @@FETCH_STATUS=0
				--------BEGIN
					
				--------	IF EXISTS(SELECT shop_code FROM TBL_MASTER_SHOP WHERE Shop_Code=@Shop_Code_Del)
				--------	BEGIN
					
				--------		DELETE FROM FTS_STAGEMAP WHERE [Shop_Id]=@Shop_Code_Del
					
				--------		DELETE FROM tbl_trans_shopActivitysubmit WHERE [Shop_Id]=@Shop_Code_Del
					
				--------		DELETE FROM tbl_trans_shopActivitysubmit_Archive WHERE [Shop_Id]=@Shop_Code_Del 

				--------		DELETE FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=@Shop_Code_Del
					
				--------		DELETE FROM tbl_FTs_OrderdetailsProduct WHERE Shop_code=@Shop_Code_Del

			
				--------		--SET @ORDER_CODE = (SELECT ORDER_CODE FROM FSMITCORDERHEADER WHERE SHOP_ID=@Shop_Code_Del)
				--------		DELETE FROM FSMITCORDERDETAIL WHERE EXISTS (SELECT ORDER_CODE FROM FSMITCORDERHEADER WHERE SHOP_ID=@Shop_Code_Del)
				--------		DELETE FROM FSMITCORDERHEADER WHERE SHOP_ID=@Shop_Code_Del

				--------		DELETE FROM ORDERPRODUCTATTRIBUTEDET WHERE EXISTS (SELECT ORDER_ID FROM ORDERPRODUCTATTRIBUTE WHERE SHOP_ID=@Shop_Code_Del)
				--------		DELETE FROM ORDERPRODUCTATTRIBUTE WHERE SHOP_ID=@Shop_Code_Del


				--------		--SET @SHOP_ID = (SELECT Shop_ID FROM TBL_MASTER_SHOP WHERE Shop_Code=@Shop_Code_Del)
				--------		DELETE FROM FTS_ShopMoreDetails WHERE EXISTS (SELECT Shop_ID FROM TBL_MASTER_SHOP WHERE Shop_Code=@Shop_Code_Del)
				--------		DELETE FROM FTS_DOCTOR_DETAILS  WHERE EXISTS (SELECT Shop_ID FROM TBL_MASTER_SHOP WHERE Shop_Code=@Shop_Code_Del)


				--------		IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = 'FSM_ITC_MIRROR')
				--------		BEGIN
				--------			IF (SELECT [VALUE] FROM FTS_APP_CONFIG_SETTINGS WHERE [KEY]='IsUpdateVisitDataInTodayTable' )=1
				--------			BEGIN
				--------				delete FROM FSM_ITC_MIRROR..Trans_ShopActivitySubmit_TodayData WHERE SHOP_ID=@Shop_Code_Del
				--------			END

				--------			delete FROM FSM_ITC_MIRROR..tbl_trans_shopActivitysubmit_Archive WHERE SHOP_ID=@Shop_Code_Del
				--------		END
				--------		ELSE
				--------		BEGIN
				--------			delete FROM tbl_trans_shopActivitysubmit_Archive WHERE SHOP_ID=@Shop_Code_Del
				--------		END
					
				--------		SET @SHOP_IMAGE = (SELECT TOP 1 Shop_Image FROM tbl_Master_shop WHERE Shop_Code=@Shop_Code_Del)
				--------		INSERT INTO #SHOPIMAGE_LIST (Shop_Image) VALUES(@SHOP_IMAGE)

				--------		DELETE FROM tbl_Master_shop WHERE Shop_Code=@Shop_Code_Del

						
				--------	END

				--------FETCH NEXT FROM CUR_SHOPDELETE INTO @Shop_Code_Del
				--------END
    -------- 			CLOSE CUR_SHOPDELETE
				--------DEALLOCATE CUR_SHOPDELETE

				DELETE FROM FTS_STAGEMAP WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=FTS_STAGEMAP.SHOP_ID)
					
				DELETE FROM tbl_trans_shopActivitysubmit WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_trans_shopActivitysubmit.SHOP_ID)
					
				DELETE FROM tbl_trans_shopActivitysubmit_Archive WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_trans_shopActivitysubmit_Archive.SHOP_ID)

				DELETE FROM tbl_trans_fts_Orderupdate WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_trans_fts_Orderupdate.Shop_Code)
					
				DELETE FROM tbl_FTs_OrderdetailsProduct WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_FTs_OrderdetailsProduct.Shop_Code)

			
				--SET @ORDER_CODE = (SELECT ORDER_CODE FROM FSMITCORDERHEADER WHERE SHOP_ID=@Shop_Code_Del)
				DELETE FROM FSMITCORDERDETAIL WHERE EXISTS (SELECT ORDER_CODE FROM FSMITCORDERHEADER H INNER JOIN #SHOPCODE_LIST B ON H.SHOP_ID=B.Shop_Code)
				DELETE FROM FSMITCORDERHEADER WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=FSMITCORDERHEADER.SHOP_ID)

				DELETE FROM ORDERPRODUCTATTRIBUTEDET WHERE EXISTS (SELECT ORDER_ID FROM ORDERPRODUCTATTRIBUTE H INNER JOIN #SHOPCODE_LIST B ON H.SHOP_ID=B.Shop_Code)
				DELETE FROM ORDERPRODUCTATTRIBUTE WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=ORDERPRODUCTATTRIBUTE.SHOP_ID)


				--SET @SHOP_ID = (SELECT Shop_ID FROM TBL_MASTER_SHOP WHERE Shop_Code=@Shop_Code_Del)
				DELETE FROM FTS_ShopMoreDetails WHERE EXISTS (SELECT SH.Shop_ID FROM TBL_MASTER_SHOP SH INNER JOIN #SHOPCODE_LIST B ON SH.Shop_Code=B.Shop_Code)
				DELETE FROM FTS_DOCTOR_DETAILS  WHERE EXISTS (SELECT SH.Shop_ID FROM TBL_MASTER_SHOP SH INNER JOIN #SHOPCODE_LIST B ON SH.Shop_Code=B.Shop_Code)


				IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = 'FSM_ITC_MIRROR')
				BEGIN
					IF (SELECT [VALUE] FROM FTS_APP_CONFIG_SETTINGS WHERE [KEY]='IsUpdateVisitDataInTodayTable' )=1
					BEGIN
						delete FROM FSM_ITC_MIRROR..Trans_ShopActivitySubmit_TodayData WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=FSM_ITC_MIRROR..Trans_ShopActivitySubmit_TodayData.SHOP_ID)
					END

					delete FROM FSM_ITC_MIRROR..tbl_trans_shopActivitysubmit_Archive WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=FSM_ITC_MIRROR..tbl_trans_shopActivitysubmit_Archive.SHOP_ID)
				END
				ELSE
				BEGIN
					delete FROM tbl_trans_shopActivitysubmit_Archive WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_trans_shopActivitysubmit_Archive.SHOP_ID)
				END
					
				--SET @SHOP_IMAGE = (SELECT TOP 1 Shop_Image FROM tbl_Master_shop WHERE Shop_Code=@Shop_Code_Del)
				INSERT INTO #SHOPIMAGE_LIST (Shop_Image) 
				SELECT distinct Shop_Image FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)

				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Shop Deleted Succesfully', GETDATE(), @user_id FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)

				INSERT INTO [FTS_BulkDeleteLog] ([Shop_Code], [Reason], [UpdateOn], [UpdatedBy])
				SELECT SHOP_CODE, 'Shop Code does not exists.', GETDATE(), @user_id FROM #SHOPCODE_LIST BTABLE WHERE NOT EXISTS (SELECT [Shop_Code] FROM tbl_Master_shop WHERE [Shop_Code]=BTABLE.Shop_Code)

				DELETE FROM tbl_Master_shop WHERE EXISTS (SELECT [Shop_Code] FROM #SHOPCODE_LIST WHERE [Shop_Code]=tbl_Master_shop.Shop_Code)


				SELECT 'Delete Succesfully.' as MSG, Shop_Image as SHOP_IMAGE FROM #SHOPIMAGE_LIST
			END

			IF OBJECT_ID('tempdb..#SHOPCODE_LIST') IS NOT NULL
					DROP TABLE #SHOPCODE_LIST
			IF OBJECT_ID('tempdb..#SHOPIMAGE_LIST') IS NOT NULL
					DROP TABLE #SHOPIMAGE_LIST

			COMMIT TRANSACTION
			
		END TRY

		BEGIN CATCH
			ROLLBACK TRANSACTION
			SELECT 'Error in Delte.' as MSG
		END CATCH
		-- End of Rev 17.0
	END

	IF @ACTION='GetddShopType'
	BEGIN
		-- Rev 12.0
		--IF @retailer_id='1'
		--select cast(id as varchar(20)) id , name from tbl_shoptypeDetails where isactive=1 and TYPE_ID=4 AND id=3
		--IF @retailer_id='2'
		--select cast(id as varchar(20)) id , name from tbl_shoptypeDetails where isactive=1 and TYPE_ID=4 AND id=4

		DECLARE @PARENT_ID bigint

		set @PARENT_ID = (select top 1 parent_id from tbl_shoptypeDetails where id=@retailer_id )

		select cast(id as varchar(20)) id , name from tbl_shoptypeDetails where isactive=1 and id=@PARENT_ID 

		-- End of Rev 12.0
	END

	IF @ACTION='GetElectricianShopType'
	BEGIN
		
		select cast(id as varchar(20)) id , name from tbl_shoptypeDetails where isactive=1 and TYPE_ID=1 AND id=2
	END

	-- Rev 12.0
	IF @ACTION='GetDDShop'
	BEGIN
		--set @ShopType = (select top 1 type_id from tbl_shoptypeDetails where id=@retailer_id)
		set @ShopType = (select top 1 id from tbl_shoptypeDetails where name='Distributor')

		select top(10)Shop_Code,Entity_Location,Replace(Shop_Name,'''','&#39;') as Shop_Name,EntityCode,Shop_Owner_Contact from tbl_Master_shop 
			-- Rev 16.0
			--where (type=@ShopType and Shop_Name like '%' + @SearchKey + '%' and isnull(dealer_id,0)=@dealer_id) 
			where Entity_Status=1 and (
				(type=@ShopType and Shop_Name like '%' + @SearchKey + '%' and isnull(dealer_id,0)=@dealer_id) 
			-- End of Rev 16.0
				or  (type=@ShopType and EntityCode like '%' + @SearchKey + '%' and isnull(dealer_id,0)=@dealer_id) 
				or (type=@ShopType and Shop_Owner_Contact like '%' + @SearchKey + '%' and isnull(dealer_id,0)=@dealer_id)
				)
	END
	-- End of Rev 12.0
	-- Rev 16.0
	IF @ACTION='GetPPShop'
	BEGIN
		--set @ShopType = (select top 1 id from tbl_shoptypeDetails where name='Distributor')
		set @ShopType = 2

		select top(10)Shop_Code,Entity_Location,Replace(Shop_Name,'''','&#39;') as Shop_Name,EntityCode,Shop_Owner_Contact from tbl_Master_shop 
			where Entity_Status=1 and (
				(type=@ShopType and Shop_Name like '%' + @SearchKey + '%') 
				or  (type=@ShopType and EntityCode like '%' + @SearchKey + '%' ) 
				or (type=@ShopType and Shop_Owner_Contact like '%' + @SearchKey + '%' )
				)
	END
	-- End of Rev 16.0
	-- Rev 17.0
	IF @ACTION='GetMassDeleteShopList'
	BEGIN
		DECLARE @Strsql NVARCHAR(MAX)

		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USER_ID)		
			CREATE TABLE #EMPHR
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
		
			INSERT INTO #EMPHR
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHR 
			where EMPCODE IS NULL OR EMPCODE=@empcode  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHR a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 

		END

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
			DROP TABLE #TEMPCONTACT
			CREATE TABLE #TEMPCONTACT
			(
				cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_ucc NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				USER_ID BIGINT
			)
		CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
		INSERT INTO #TEMPCONTACT
		SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id FROM TBL_MASTER_CONTACT CNT
		INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE cnt_contactType IN('EM')
		
		SET @Strsql=''

		SET @Strsql+=' select top(20) shop.Shop_Code, shop.Entity_Location, Replace(shop.Shop_Name,'''',''&#39;'') as Shop_Name, shop.EntityCode, '
		SET @Strsql+=' shop.Shop_Owner_Contact, shoptype.Name as ShopType_Name '
		SET @Strsql+=' from tbl_Master_shop shop '
		SET @Strsql+=' LEFT OUTER JOIN tbl_shoptype shoptype ON shoptype.shop_typeId=shop.[type] '

		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
			SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE    '
		END

		SET @Strsql+=' where (shop.Shop_Name like ''%'+ @SearchKey +'%'') '
		SET @Strsql+=' or  (shop.EntityCode like ''%'+ @SearchKey +'%'' ) '
		SET @Strsql+=' or (shop.Shop_Owner_Contact like ''%'+ @SearchKey +'%'' ) '
		EXEC SP_EXECUTESQL @Strsql
		
		--select @Strsql

		DROP TABLE #TEMPCONTACT
	END
	-- End of Rev 17.0
END
GO