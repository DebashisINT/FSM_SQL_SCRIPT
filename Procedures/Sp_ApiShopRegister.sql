IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_ApiShopRegister]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_ApiShopRegister] AS' 
END
GO

--exec [Sp_ApiShopRegister]  'lmeeawunipwxqc3xl43k25i5','504','','','','','','','','',''

ALTER PROCEDURE [dbo].[Sp_ApiShopRegister]
(
@session_token  NVARCHAR(MAX)=NULL,
@user_id  NVARCHAR(MAX),
@shop_name  NVARCHAR(MAX)=NULL,
@address  NVARCHAR(MAX)=NULL,
@pin_code  NVARCHAR(MAX)=NULL,
@shop_lat  NVARCHAR(MAX)=NULL,
@shop_long  NVARCHAR(MAX)=NULL,
@owner_name  NVARCHAR(MAX)=NULL,
@owner_contact_no  NVARCHAR(MAX)=NULL,
@owner_email  NVARCHAR(MAX)=NULL,
@shop_image  NVARCHAR(MAX)=NULL,
@type int =NULL,
@dob NVARCHAR(MAX) =NULL,
@date_aniversary NVARCHAR(MAX) =NULL,
@shop_id NVARCHAR(MAX) =NULL,
@error NVARCHAR(MAX) =NULL,
@added_date DATETIME =NULL,
@assigned_to_pp_id NVARCHAR(MAX) =NULL,
@assigned_to_dd_id  NVARCHAR(MAX) =NULL,
@amount NVARCHAR(100)=NULL,
--1.0 Rev start
@family_member_dob DATETIME =NULL,
@addtional_dob DATETIME =NULL,
@addtional_doa DATETIME =NULL,
@director_name NVARCHAR(MAX) =NULL,
@key_person_name  NVARCHAR(MAX) =NULL,
@phone_no NVARCHAR(100)=NULL,
--1.0 Rev End
--2.0 Rev Start
@DOC_FAMILY_MEMBER_DOB DATETIME=NULL,
@SPECIALIZATION NVARCHAR(200)=NULL,
@AVG_PATIENT_PER_DAY NVARCHAR(10)=NULL,
@CATEGORY NVARCHAR(100)=NULL,
@DOC_ADDRESS NVARCHAR(500)=NULL,
@DOC_PINCODE NVARCHAR(10)=NULL,
@DEGREE NVARCHAR(MAX)=NULL,
@IsChamberSameHeadquarter NVARCHAR(5)=NULL,
@Remarks NVARCHAR(500)=NULL,
@CHEMIST_NAME NVARCHAR(300) =NULL,
@CHEMIST_ADDRESS NVARCHAR(500)=NULL,
@CHEMIST_PINCODE NVARCHAR(10)=NULL,
@ASSISTANT_NAME NVARCHAR(300)=NULL,
@ASSISTANT_CONTACT_NO NVARCHAR(20)=NULL,
@ASSISTANT_DOB DATETIME=NULL,
@ASSISTANT_DOA DATETIME=NULL,
@ASSISTANT_FAMILY_DOB DATETIME=NULL
--2.0 Rev End
--3.0 Rev Start
,@EntityCode NVARCHAR(100)=NULL,
@Entity_Location NVARCHAR(MAX)=NULL,
@Alt_MobileNo NVARCHAR(15)=NULL,
@Entity_Status INT=NULL,
@Entity_Type INT=NULL,
@ShopOwner_PAN NVARCHAR(15)=NULL,
@ShopOwner_Aadhar NVARCHAR(20)=NULL,
@EntityRemarks NVARCHAR(500)=NULL,
@AreaId NVARCHAR(10) =NULL,
@CityId NVARCHAR(10)=NULL
--3.0 Rev End
--4.0 Rev Start
,@Entered_by NVARCHAR(10)=NULL
--4.0 Rev End
--8.0 Rev Start
,@model_id NVARCHAR(10)=NULL,
@primary_app_id NVARCHAR(10)=NULL,
@secondary_app_id NVARCHAR(10)=NULL,
@lead_id NVARCHAR(10)=NULL,
@funnel_stage_id NVARCHAR(10)=NULL,
@stage_id NVARCHAR(10)=NULL,
@booking_amount NVARCHAR(30)=NULL
--8.0 Rev End
--9.0 Rev Start
,@PartyType_id NVARCHAR(10)=NULL
--9.0 Rev End
--10.0 Rev Start
,@entity_id NVARCHAR(10)=NULL
,@party_status_id NVARCHAR(10)=NULL
--10.0 Rev End
--11.0 Rev Start
,@retailer_id NVARCHAR(10)=NULL
,@dealer_id NVARCHAR(10)=NULL
,@beat_id NVARCHAR(10)=NULL
--11.0 Rev End
--12.0 Rev Start
,@assigned_to_shop_id NVARCHAR(100)=NULL
--12.0 Rev End
--13.0 Rev Start
,@actual_address NVARCHAR(100)=NULL
--13.0 Rev End
--14.0 Rev Start
,@competitor_img varBINARY(max)=NULL
--14.0 Rev End
--15.0 Rev Start
,@shop_revisit_uniqKey NVARCHAR(200)=NULL
--15.0 Rev End
--Rev 16.0
,@agency_name NVARCHAR(100)=NULL
,@lead_contact_number NVARCHAR(100)=NULL,
--End of Rev 16.0
--Rev 17.0
@project_name NVARCHAR(max)=NULL,
@landline_number NVARCHAR(100)=NULL,
--End of Rev 17.0
--Rev 18.0
@alternateNoForCustomer NVARCHAR(100)=NULL,
@whatsappNoForCustomer NVARCHAR(100)=NULL,
--End of Rev 18.0
--Rev 19.0
@isShopDuplicate BIT=NULL,
--End of Rev 19.0
--Rev 20.0
@purpose NVARCHAR(MAX)=NULL,
--End of Rev 20.0
--Rev 22.0
@GSTN_Number NVARCHAR(100)=NULL
--End of Rev 22.0
) --WITH ENCRYPTION
AS
/********************************************************************************************************************************************************************************
1.0			TANMOY			31-12-2019			ADD EXTER FIELD FOR MORE DETAILS AND INSER NEW TABLE WITHE HEADER ID
2.0			TANMOY			06-01-2019			STORE EXTRA DETAILS INTO ANOTHER TABLE FOR DECTOR
3.0			TANMOY			14-05-2020			STORE EXTRA DETAILS INTO SHOP
4.0			TANMOY			25-05-2020			STORE Entered by and Entered ON
5.0			TANMOY			29-05-2020			Shop create from APP set Entity_Status=1 
6.0			TANMOY			30-05-2020			City insert from areaid only for mobile create shop
7.0			TANMOY			05-06-2020			Cityid and AreaId ISNUMERIC check
8.0			TANMOY			09-06-2020			INSERT EXTAR COLUMN
9.0			TANMOY			23-06-2020			INSERT Party Type Id
10.0		INDRANIL		15-02-2021			INSERT Entity Type Id and Party status id
11.0		INDRANIL		15-02-2021			INSERT Entity Retailer id,Dealer id,Beat id
12.0		INDRANIL		15-02-2021			INSERT assigned_to_shop_id
13.0		INDRANIL		19-03-2021			INSERT actual_address
14.0		Tanmoy			19-03-2021			INSERT competitor_img
15.0		Tanmoy			24-06-2021			INSERT revisit Code
16.0		Debashis		09-12-2021			Two fields added as Agency_Name & Lead_Contact_Number.
17.0		Debashis		19-01-2022			Two fields added as Project_Name & Landline_Number.
18.0		Debashis		10-02-2022			Two fields added as AlternateNoForCustomer & WhatsappNoForCustomer.Refer: 638,640 & 641
19.0		Debashis		01-06-2022			One field added as IsShopDuplicate.Row: 691,692 & 693
20.0		Debashis		17-06-2022			One field added as Purpose.Row: 701,702 & 703
21.0		Debashis		11-07-2022			A new setting implemented.Row: 713
22.0		Debashis		02-11-2022			New Parameter added.Row: 753 to 759
23.0		Debashis		05-06-2023			Shop Submit (New Visit + ReVisit) data shall be updated in a table 'Trans_ShopActivitySubmit_TodayData' instead of table 
												'tbl_trans_shopActivitysubmit' based on setting 'IsUpdateVisitDataInTodayTable' (Global) Bydefault=No
												If = Yes then New Visit + ReVisit data shall be stored in 'Trans_ShopActivitySubmit_TodayData', And through a Offline 
												Scheduler Data shall be moved to 'tbl_trans_shopActivitysubmit' table.
												If = No then New Visit + ReVisit data shall be stored directly in 'tbl_trans_shopActivitysubmit' table.Refer: 0026237
24.0		Debashis		07-07-2023			Shoplist/AddShop updation based on IsUpdateVisitDataInTodayTable Settings.Refer: 0026527
********************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF ISNULL(@Entered_by,'')=''
	BEGIN
		SET @Entered_by=@user_id
		SET @Entity_Status=1
		IF ISNUMERIC(@AreaId)=1
		BEGIN
			IF ISNUMERIC(@CityId)=0
			BEGIN
				SET @CityId=(SELECT TOP(1)city_id FROM TBL_MASTER_AREA WITH(NOLOCK) WHERE area_id=@AreaId)
			END
		END
		ELSE
		BEGIN
			SET @AreaId=NULL
			SET @CityId=NULL
		END
	END

	--Rev 8.0 Start
	IF ISNUMERIC(@model_id)=0
	BEGIN
		SET @model_id=0;
	END
	IF ISNUMERIC(@primary_app_id)=0
	BEGIN
		SET @primary_app_id=0;
	END
	IF ISNUMERIC(@secondary_app_id)=0
	BEGIN
		SET @secondary_app_id=0;
	END
	IF ISNUMERIC(@lead_id)=0
	BEGIN
		SET @lead_id=0;
	END
	IF ISNUMERIC(@funnel_stage_id)=0
	BEGIN
		SET @funnel_stage_id=0;
	END
	IF ISNUMERIC(@stage_id)=0
	BEGIN
		SET @stage_id=0;
	END
	IF ISNUMERIC(@booking_amount)=0
	BEGIN
		SET @booking_amount=0;
	END
	--Rev 8.0 End

	--Rev 9.0 Start
	IF ISNUMERIC(@PartyType_id)=0
	BEGIN
		SET @PartyType_id=0;
	END	
	--Rev 9.0 End

	declare @currentdate  datetime=NULL
	DECLARE @COUNT BIGINT
	declare @StateID  varchar(50)=NULL
	set @currentdate=GETDATE();
	if(isnull(@amount,'')='')
		BEGIN
			set @amount=0
		END

	if(isnull(@added_date,'') ='')
		BEGIN
		set @added_date=GETDATE()
		END
	--Rev 21.0
	DECLARE @IgnoreNumberCheckwhileShopCreation BIT
	SET @IgnoreNumberCheckwhileShopCreation=(SELECT IgnoreNumberCheckwhileShopCreation FROM tbl_master_user WITH(NOLOCK) WHERE USER_ID=@user_id)
	--End of Rev 21.0
	--Rev 23.0
	DECLARE @IsUpdateVisitDataInTodayTable NVARCHAR(100)
	SET @IsUpdateVisitDataInTodayTable=(SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsUpdateVisitDataInTodayTable')
	--End of Rev 23.0

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId FROM TBL_MASTER_CONTACT WITH (NOLOCK)
	WHERE cnt_contactType IN('EM')

	if EXISTS(select  user_id  from tbl_master_user WITH(NOLOCK) where user_id=@user_id)
		BEGIN
			if NOT EXISTS(select  Shop_ID  from [tbl_Master_shop] WITH(NOLOCK) where Shop_Code=@shop_id)
				BEGIN
					--Rev 21.0
					IF @IgnoreNumberCheckwhileShopCreation=1
						BEGIN
							set @StateID=(select  top 1 stat.id  from tbl_master_pinzip as pin WITH(NOLOCK) 
							inner join tbl_master_city as cty WITH(NOLOCK) on cty.city_id=pin.city_id  
							inner join tbl_master_state as stat WITH(NOLOCK) on stat.id=cty.state_id where pin.pin_code=@pin_code)
							if(isnull(@StateID,'')='')
								BEGIN
									set @StateID=(
									select  top 1 STAT.id as [state]
									FROM tbl_master_user as usr WITH(NOLOCK) 									
									--LEFT OUTER JOIN tbl_master_contact  as cont WITH(NOLOCK) on usr.user_contactId=cont.cnt_internalId
									LEFT OUTER JOIN #TEMPCONTACT CONT ON usr.user_contactId=cont.cnt_internalId
									LEFT OUTER JOIN (
											SELECT add_cntId,add_state,add_city,add_country,add_pin,add_address1  FROM  tbl_master_address WITH(NOLOCK) where add_addressType='Office'
											)S on S.add_cntId=cont.cnt_internalId
									LEFT OUTER JOIN tbl_master_state as STAT WITH(NOLOCK) on STAT.id=S.add_state
									where usr.user_id=@user_id)
								END
							--Rev 22.0 && A new field added as GSTN_Number
							INSERT INTO [tbl_Master_shop] ([Shop_Name],[Address],[Pincode],[Shop_Lat],[Shop_Long],[Shop_Owner],[Shop_Owner_Email],[Shop_Owner_Contact],[Shop_CreateUser]
									   ,[Shop_CreateTime],[type],dob,date_aniversary,[Shop_Image],Shop_Code,total_visitcount,Lastvisit_date,isAddressUpdated,assigned_to_pp_id
										,assigned_to_dd_id,stateId,Amount,EntityCode,Entity_Location,Alt_MobileNo,Entity_Status,Entity_Type,ShopOwner_PAN,ShopOwner_Aadhar,Remarks,Area_id,Shop_City
										,Entered_By,Entered_On,Model_id,Primary_id,Secondary_id,Lead_id,FunnelStage_id,Stage_id,Booking_amount,PartyType_id,Entity_Id,Party_Status_id,retailer_id
										,dealer_id,beat_id,assigned_to_shop_id,actual_address,competitor_img,Agency_Name,Lead_Contact_Number
										,Project_Name,Landline_Number,AlternateNoForCustomer,WhatsappNoForCustomer,IsShopDuplicate,Purpose,GSTN_Number
										)
								 VALUES (@shop_name,@address,@pin_code,@shop_lat,@shop_long,@owner_name,@owner_email,@owner_contact_no,@user_id,@added_date,@type,@dob,@date_aniversary
										,@shop_image,@shop_id,1,@added_date,1,@assigned_to_pp_id,@assigned_to_dd_id,@StateID,@amount,@EntityCode,@Entity_Location,@Alt_MobileNo,@Entity_Status,
										@Entity_Type,@ShopOwner_PAN,@ShopOwner_Aadhar,@EntityRemarks,@AreaId,@CityId,@Entered_by,GETDATE(),@model_id,@primary_app_id,@secondary_app_id,@lead_id,
										@funnel_stage_id,@stage_id,@booking_amount,@PartyType_id,@entity_id,@party_status_id,@retailer_id,@dealer_id,@beat_id,@assigned_to_shop_id,@actual_address,
										@competitor_img,@agency_name,@lead_contact_number,@project_name,@landline_number,@alternateNoForCustomer,@whatsappNoForCustomer,@isShopDuplicate,@purpose,
										@GSTN_Number)

							SET @COUNT=SCOPE_IDENTITY();

							IF(ISNULL(@stage_id,'')<>'')
							BEGIN
								INSERT INTO FTS_STAGEMAP (SHOP_ID,STAGE_ID,USER_ID,UPDATE_DATE)
								VALUES (@shop_id,@stage_id,@Entered_by,GETDATE())
							END


							if(@@ROWCOUNT)>0
								BEGIN
									--Rev 23.0
									IF @IsUpdateVisitDataInTodayTable='0'
										BEGIN
									--End of Rev 23.0
											INSERT INTO [tbl_trans_shopActivitysubmit] ([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd
											,Revisit_Code
											)
											values(@user_id,@shop_id,cast(@added_date as date),@added_date,'00:00:00',1,@added_date,1
											,@shop_revisit_uniqKey
											)
											--Rev 22.0 && Two new fields added as ShopOwner_PAN & GSTN_Number
											select '200' as returncode,@shop_id as shop_id,@session_token as session_token,@shop_name as shop_name,@address as address,@pin_code as pin_code
											,@shop_lat as shop_lat,@shop_long as shop_long,@owner_name as owner_name,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email
											,@user_id as user_id,@address  as address,@pin_code as pin_code,@shop_lat  as shop_lat,@shop_long  as shop_long,@owner_name as owner_name
											,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email,@type as [type],@dob as dob,@date_aniversary  as date_aniversary,
											@agency_name AS agency_name,@lead_contact_number AS lead_contact_number,@project_name AS project_name,@landline_number AS landline_number,
											@alternateNoForCustomer,@whatsappNoForCustomer,@isShopDuplicate,@purpose,@ShopOwner_PAN,@GSTN_Number
									--Rev 23.0
										END
									ELSE IF @IsUpdateVisitDataInTodayTable='1'
										BEGIN
									--Rev 24.0
									--		INSERT INTO [Trans_ShopActivitySubmit_TodayData] WITH(TABLOCK) ([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,
									--		Createddate,Is_Newshopadd,Revisit_Code)
									--		values(@user_id,@shop_id,cast(@added_date as date),@added_date,'00:00:00',1,@added_date,1,@shop_revisit_uniqKey)
									--End of Rev 24.0
											select '200' as returncode,@shop_id as shop_id,@session_token as session_token,@shop_name as shop_name,@address as address,@pin_code as pin_code
											,@shop_lat as shop_lat,@shop_long as shop_long,@owner_name as owner_name,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email
											,@user_id as user_id,@address  as address,@pin_code as pin_code,@shop_lat  as shop_lat,@shop_long  as shop_long,@owner_name as owner_name
											,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email,@type as [type],@dob as dob,@date_aniversary  as date_aniversary,
											@agency_name AS agency_name,@lead_contact_number AS lead_contact_number,@project_name AS project_name,@landline_number AS landline_number,
											@alternateNoForCustomer,@whatsappNoForCustomer,@isShopDuplicate,@purpose,@ShopOwner_PAN,@GSTN_Number
										END
									--End of Rev 23.0									

									INSERT INTO FTS_ShopMoreDetails (SHOP_ID,FamilyMember_DOB,Addtional_DOB,Addtional_DOA,Director_Name,KeyPerson_Name,phone_no,Create_date)
									VALUES (@COUNT,@family_member_dob,@addtional_dob,@addtional_doa,@director_name,@key_person_name,@phone_no,GETDATE())

									INSERT INTO FTS_DOCTOR_DETAILS (SHOP_ID,FAMILY_MEMBER_DOB,SPECIALIZATION,AVG_PATIENT_PER_DAY,CATEGORY,DOC_ADDRESS,PINCODE,DEGREE,IsChamberSameHeadquarter,
									Remarks,CHEMIST_NAME,CHEMIST_ADDRESS,CHEMIST_PINCODE,ASSISTANT_NAME,ASSISTANT_CONTACT_NO,ASSISTANT_DOB,ASSISTANT_DOA,ASSISTANT_FAMILY_DOB,CREATE_DATE,CREATE_USER)
									VALUES (@COUNT,@DOC_FAMILY_MEMBER_DOB,@SPECIALIZATION,@AVG_PATIENT_PER_DAY,@CATEGORY,@DOC_ADDRESS,@DOC_PINCODE,@DEGREE,@IsChamberSameHeadquarter,@Remarks,@CHEMIST_NAME,
											@CHEMIST_ADDRESS,@CHEMIST_PINCODE,@ASSISTANT_NAME,@ASSISTANT_CONTACT_NO,@ASSISTANT_DOB,@ASSISTANT_DOA,@ASSISTANT_FAMILY_DOB,GETDATE(),@user_id)
								END
						END
					ELSE
						BEGIN
					--End of Rev 21.0
							if NOT EXISTS(select  Shop_ID  from [tbl_Master_shop] WITH(NOLOCK) where Shop_Owner_Contact=@owner_contact_no and Shop_CreateUser=@user_id )
								BEGIN
									set @StateID=(select  top 1 stat.id  from tbl_master_pinzip as pin WITH(NOLOCK) 
									inner join tbl_master_city as cty WITH(NOLOCK) on cty.city_id=pin.city_id  
									inner join tbl_master_state as stat WITH(NOLOCK) on stat.id=cty.state_id where pin.pin_code=@pin_code)
									if(isnull(@StateID,'')='')
										BEGIN
											set @StateID=(
											select  top 1 STAT.id as [state]
											FROM tbl_master_user as usr WITH(NOLOCK)
											--LEFT OUTER JOIN tbl_master_contact  as cont WITH(NOLOCK) on usr.user_contactId=cont.cnt_internalId
											LEFT OUTER JOIN #TEMPCONTACT CONT ON usr.user_contactId=cont.cnt_internalId
											LEFT OUTER  JOIN (
													SELECT   add_cntId,add_state,add_city,add_country,add_pin,add_address1 FROM tbl_master_address WITH(NOLOCK) where add_addressType='Office'
													)S on S.add_cntId=cont.cnt_internalId
											--LEFT OUTER JOIN tbl_master_pinzip as pinzip on pinzip.pin_id=S.add_pin
											LEFT OUTER JOIN tbl_master_state as STAT WITH(NOLOCK) on STAT.id=S.add_state
											where usr.user_id=@user_id)
										END

									--Rev 16.0 @@Two fields added as Agency_Name & Lead_Contact_Number
									--Rev 17.0 @@Two fields added as Project_Name & Landline_Number
									--Rev 18.0 @@Two fields added as AlternateNoForCustomer & WhatsappNoForCustomer
									--Rev 19.0 @@One field added as IsShopDuplicate
									--Rev 20.0 @@One field added as Purpose
									--Rev 22.0 && A new field added as GSTN_Number
									INSERT INTO [tbl_Master_shop] ([Shop_Name],[Address],[Pincode],[Shop_Lat],[Shop_Long],[Shop_Owner],[Shop_Owner_Email],[Shop_Owner_Contact],[Shop_CreateUser]
											   ,[Shop_CreateTime],[type],dob,date_aniversary,[Shop_Image],Shop_Code,total_visitcount,Lastvisit_date,isAddressUpdated,assigned_to_pp_id
												,assigned_to_dd_id,stateId,Amount,EntityCode,Entity_Location,Alt_MobileNo,Entity_Status,Entity_Type,ShopOwner_PAN,ShopOwner_Aadhar,Remarks,Area_id,Shop_City
												--Rev 4.0 Start
												,Entered_By,Entered_On
												--Rev 4.0 End
												--Rev 8.0 Start
												,Model_id,Primary_id,Secondary_id,Lead_id,FunnelStage_id,Stage_id,Booking_amount
												--Rev 8.0 End
												--Rev 9.0 Start
												,PartyType_id
												--Rev 9.0 End
												--Rev 10.0 Start
												,Entity_Id
												,Party_Status_id
												--Rev 10.0 End
												--Rev 11.0 Start
												,retailer_id
												,dealer_id
												,beat_id
												--Rev 11.0 End
												--Rev 12.0 Start
												,assigned_to_shop_id
												--Rev 12.0 End
												--Rev 13.0 Start
												,actual_address
												--Rev 13.0 End
												,competitor_img
												,Agency_Name,Lead_Contact_Number
												,Project_Name,Landline_Number,AlternateNoForCustomer,WhatsappNoForCustomer,IsShopDuplicate,Purpose,GSTN_Number
												)
										 VALUES (@shop_name,@address,@pin_code,@shop_lat,@shop_long,@owner_name,@owner_email,@owner_contact_no,@user_id,@added_date,@type,@dob,@date_aniversary
												,@shop_image,@shop_id,1,@added_date,1,@assigned_to_pp_id,@assigned_to_dd_id,@StateID,@amount,@EntityCode,@Entity_Location,@Alt_MobileNo,@Entity_Status,
												@Entity_Type,@ShopOwner_PAN,@ShopOwner_Aadhar,@EntityRemarks,@AreaId,@CityId
												--Rev 4.0 Start
												,@Entered_by,GETDATE()
												--Rev 4.0 End
												--Rev 8.0 Start
												,@model_id,@primary_app_id,@secondary_app_id,@lead_id,@funnel_stage_id,@stage_id,@booking_amount
												--Rev 8.0 End
												--Rev 9.0 Start
												,@PartyType_id
												--Rev 9.0 End
												--Rev 10.0 Start
												,@entity_id
												,@party_status_id
												--Rev 10.0 End
												--Rev 11.0 Start
												,@retailer_id
												,@dealer_id
												,@beat_id
												--Rev 11.0 End
												--Rev 12.0 Start
												,@assigned_to_shop_id
												--Rev 12.0 End
												--Rev 13.0 Start
												,@actual_address
												--Rev 13.0 End
												,@competitor_img
												,@agency_name,@lead_contact_number
												,@project_name,@landline_number,@alternateNoForCustomer,@whatsappNoForCustomer,@isShopDuplicate,@purpose,@GSTN_Number
												)

									SET @COUNT=SCOPE_IDENTITY();

									IF(ISNULL(@stage_id,'')<>'')
									BEGIN
										INSERT INTO FTS_STAGEMAP (SHOP_ID,STAGE_ID,USER_ID,UPDATE_DATE)
										VALUES (@shop_id,@stage_id,@Entered_by,GETDATE())
									END


									if(@@ROWCOUNT)>0
										BEGIN
											--Rev 23.0
											IF @IsUpdateVisitDataInTodayTable='0'
												BEGIN
											--End of Rev 23.0
													INSERT INTO [tbl_trans_shopActivitysubmit] ([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd
													,Revisit_Code
													)
													values(@user_id,@shop_id,cast(@added_date as date),@added_date,'00:00:00',1,@added_date,1
													,@shop_revisit_uniqKey
													)

													--Rev 16.0 @@Two fields added as Agency_Name & Lead_Contact_Number
													--Rev 17.0 @@Two fields added as Project_Name & Landline_Number
													--Rev 18.0 @@Two fields added as AlternateNoForCustomer & WhatsappNoForCustomer
													--Rev 19.0 @@One field added as IsShopDuplicate
													--Rev 20.0 @@One field added as Purpose
													--Rev 22.0 && Two new fields added as ShopOwner_PAN & GSTN_Number
													select '200' as returncode,@shop_id as shop_id,@session_token as session_token,@shop_name as shop_name,@address as address,@pin_code as pin_code
													,@shop_lat as shop_lat,@shop_long as shop_long,@owner_name as owner_name,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email
													,@user_id as user_id,@address  as address,@pin_code as pin_code,@shop_lat  as shop_lat,@shop_long  as shop_long,@owner_name as owner_name
													,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email,@type as [type],@dob as dob,@date_aniversary  as date_aniversary,
													@agency_name AS agency_name,@lead_contact_number AS lead_contact_number,@project_name AS project_name,@landline_number AS landline_number,
													@alternateNoForCustomer,@whatsappNoForCustomer,@isShopDuplicate,@purpose,@ShopOwner_PAN,@GSTN_Number
											--Rev 23.0
												END
											ELSE IF @IsUpdateVisitDataInTodayTable='1'
												BEGIN
											--Rev 24.0
											--		INSERT INTO [Trans_ShopActivitySubmit_TodayData] WITH(TABLOCK) ([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,
											--		Createddate,Is_Newshopadd,Revisit_Code)
											--		values(@user_id,@shop_id,cast(@added_date as date),@added_date,'00:00:00',1,@added_date,1,@shop_revisit_uniqKey)
											--End of Rev 24.0
													select '200' as returncode,@shop_id as shop_id,@session_token as session_token,@shop_name as shop_name,@address as address,@pin_code as pin_code
													,@shop_lat as shop_lat,@shop_long as shop_long,@owner_name as owner_name,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email
													,@user_id as user_id,@address  as address,@pin_code as pin_code,@shop_lat  as shop_lat,@shop_long  as shop_long,@owner_name as owner_name
													,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email,@type as [type],@dob as dob,@date_aniversary  as date_aniversary,
													@agency_name AS agency_name,@lead_contact_number AS lead_contact_number,@project_name AS project_name,@landline_number AS landline_number,
													@alternateNoForCustomer,@whatsappNoForCustomer,@isShopDuplicate,@purpose,@ShopOwner_PAN,@GSTN_Number
												END
											----End of Rev 23.0											

											--1.0 Rev start
											INSERT INTO FTS_ShopMoreDetails (SHOP_ID,FamilyMember_DOB,Addtional_DOB,Addtional_DOA,Director_Name,KeyPerson_Name,phone_no,Create_date)
											VALUES (@COUNT,@family_member_dob,@addtional_dob,@addtional_doa,@director_name,@key_person_name,@phone_no,GETDATE())
											--1.0 Rev End

											--2.0 Rev start
											INSERT INTO FTS_DOCTOR_DETAILS (SHOP_ID,FAMILY_MEMBER_DOB,SPECIALIZATION,AVG_PATIENT_PER_DAY,CATEGORY,DOC_ADDRESS,PINCODE,DEGREE,IsChamberSameHeadquarter,
											Remarks,CHEMIST_NAME,CHEMIST_ADDRESS,CHEMIST_PINCODE,ASSISTANT_NAME,ASSISTANT_CONTACT_NO,ASSISTANT_DOB,ASSISTANT_DOA,ASSISTANT_FAMILY_DOB,CREATE_DATE,CREATE_USER)
											VALUES (@COUNT,@DOC_FAMILY_MEMBER_DOB,@SPECIALIZATION,@AVG_PATIENT_PER_DAY,@CATEGORY,@DOC_ADDRESS,@DOC_PINCODE,@DEGREE,@IsChamberSameHeadquarter,@Remarks,@CHEMIST_NAME,
													@CHEMIST_ADDRESS,@CHEMIST_PINCODE,@ASSISTANT_NAME,@ASSISTANT_CONTACT_NO,@ASSISTANT_DOB,@ASSISTANT_DOA,@ASSISTANT_FAMILY_DOB,GETDATE(),@user_id)
											--2.0 Rev End
										END
								END
							ELSE
								BEGIN
									select '203' as returncode
								END
						--Rev 21.0
						END
						--End of Rev 21.0
				END
			ELSE
				BEGIN
					select '203' as returncode
				END
		END
	ELSE
		BEGIN
			select '202' as returncode
		END

	DROP TABLE #TEMPCONTACT
	
	SET NOCOUNT OFF
END