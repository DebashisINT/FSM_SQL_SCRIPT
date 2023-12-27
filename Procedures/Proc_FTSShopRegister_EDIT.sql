IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTSShopRegister_EDIT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTSShopRegister_EDIT] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_FTSShopRegister_EDIT]
(
@session_token  NVARCHAR(MAX),
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
@added_date NVARCHAR(MAX) =NULL,
@assigned_to_pp_id NVARCHAR(MAX) =NULL,
@assigned_to_dd_id  NVARCHAR(MAX) =NULL,
@amount NVARCHAR(100)=NULL,
--1.0 Rev start
@family_member_dob datetime =NULL,
@addtional_dob datetime =NULL,
@addtional_doa datetime =NULL,
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
--7.0 Rev Start
,@model_id NVARCHAR(10)=NULL,
@primary_app_id NVARCHAR(10)=NULL,
@secondary_app_id NVARCHAR(10)=NULL,
@lead_id NVARCHAR(10)=NULL,
@funnel_stage_id NVARCHAR(10)=NULL,
@stage_id NVARCHAR(10)=NULL,
@booking_amount NVARCHAR(30)=NULL
--7.0 Rev End
--8.0 Rev Start
,@PartyType_id NVARCHAR(10)=NULL
--8.0 Rev End
--9.0 Rev Start
,@entity_id NVARCHAR(10)=NULL
,@party_status_id NVARCHAR(10)=NULL
--9.0 Rev End
--10.0 Rev Start
,@retailer_id NVARCHAR(10)=NULL
,@dealer_id NVARCHAR(10)=NULL
,@beat_id NVARCHAR(10)=NULL
--10.0 Rev End
--11.0 Rev Start
,@assigned_to_shop_id NVARCHAR(100)=NULL
--11.0 Rev End
--12.0 Rev Start
,@actual_address NVARCHAR(100)=NULL
--12.0 Rev End
--Rev 14.0
,@agency_name NVARCHAR(100)=NULL
,@lead_contact_number NVARCHAR(100)=NULL,
--End of Rev 14.0
--Rev 15.0
@project_name NVARCHAR(max)=NULL,
@landline_number NVARCHAR(100)=NULL,
--End of Rev 15.0
--Rev 16.0
@alternateNoForCustomer NVARCHAR(100)=NULL,
@whatsappNoForCustomer NVARCHAR(100)=NULL,
--End of Rev 16.0
--Rev 18.0
@shopStatusUpdate BIT=NULL,
--End of Rev 18.0
--Rev 19.0
@GSTN_Number NVARCHAR(100)=NULL,
--End of Rev 19.0
--Rev 20.0
@isUpdateAddressFromShopMaster BIT=0,
--End of Rev 20.0
--Rev 21.0
@shop_firstName VARCHAR(200)=NULL,
@shop_lastName VARCHAR(200)=NULL,
@crm_companyID INT=NULL,
@crm_jobTitle VARCHAR(500)=NULL,
@crm_typeID INT=NULL,
@crm_statusID INT=NULL,
@crm_sourceID INT=NULL,
@crm_referenceID NVARCHAR(200)=NULL,
@crm_referenceID_type VARCHAR(50)=NULL,
@crm_stage_ID INT=NULL,
@assign_to INT=NULL,
@saved_from_status VARCHAR(100)=NULL
--End of Rev 21.0
) --WITH ENCRYPTION
As
/************************************************************************************************************************************************
1.0					TANMOY			31-12-2019			EDIT EXTER FIELD FOR MORE DETAILS AND INSER NEW TABLE WITHE HEADER ID
2.0					TANMOY			01-06-2019			EDIT EXTRA DETAILS INTO ANOTHER TABLE FOR DECTOR
3.0					TANMOY			14-05-2020			STORE EXTRA DETAILS INTO SHOP
4.0					TANMOY			25-05-2020			STORE EXTRA DETAILS INTO SHOP
5.0					TANMOY			29-05-2020			Update from Mobile shop set Entity_Status=1
6.0					TANMOY			30-05-2020			City undate from area id only for mobile create shop
7.0					TANMOY			09-06-2020			UPDATE EXTAR COLUMN
8.0					TANMOY			23-06-2020			INSERT Party Type Id
9.0					INDRANIL		15-02-2021			INSERT Entity Type Id and Party status id
10.0				INDRANIL		18-02-2021			INSERT Retailer id,Dealer id,Beat id
11.0				INDRANIL		19-02-2021			INSERT assigned_to_shop_id
12.0				INDRANIL		19-03-2021			INSERT actual_address
13.0	v2.0.25		Debashis		23-09-2021			Condition added for Shop_Image.
14.0	v2.0.26		Debashis		09-12-2021			Two fields added as Agency_Name & Lead_Contact_Number.
15.0	v2.0.26		Debashis		19-01-2022			Two fields added as Project_Name & Landline_Number.
16.0	v2.0.27		Debashis		10-02-2022			Two fields added as AlternateNoForCustomer & WhatsappNoForCustomer.Refer: 639,642 & 643
17.0	v2.0.28		Debashis		24-03-2022			UPDATE ADDRESS - API CALL FROM APP IS MAKING BLANK TBL_MASTER_SHOP FOR FEW FIELDS 
														LIKE 'ENTITY CODE'. There may be some more fields that to be coditional with ISNULL CHECK.
														Refer: 0024762
18.0	v2.0.28		Debashis		18-04-2022			New parameter added as @shopStatusUpdate.Refer: 682
19.0	v2.0.35		Debashis		02-11-2022			New Parameter added.Row: 753 to 759
20.0	v2.0.42		Debashis		06-10-2023			New Parameter added.Row: 873 & 874
21.0	v2.0.43		Debashis		22-12-2023			Some new parameters have been added.Row: 893,894,896 & 897
************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	--IF ISNULL(@Entered_by,'')=''
	--BEGIN
	--	SET @Entered_by=@user_id
	--	SET @Entity_Status=1
	--	IF ISNULL(@CityId,'')=''
	--	BEGIN
	--	SET @CityId=(SELECT TOP(1)city_id FROM TBL_MASTER_AREA WHERE area_id=@AreaId)
	--	END
		
	--END
	IF  ISNULL(@Entered_by,'')=''
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


	--Rev 7.0 Start
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
	--Rev 7.0 End
	--Rev 8.0 Start
	IF ISNUMERIC(@PartyType_id)=0
	BEGIN
		SET @PartyType_id=0;
	END
	--Rev 8.0 End

	declare @currentdate  datetime=NULL
	set @currentdate=GETDATE();

	if(isnull(@amount,'')='')
	BEGIN
		set @amount=0
	END

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


	--if EXISTS(select  [Shop_CreateUser]  from [tbl_Master_shop] where [Shop_CreateUser]=@user_id and Shop_Code=@shop_id)

	--BEGIN
	declare @StateID  varchar(50)=NULL
	set @StateID=(select  top 1 stat.id  from tbl_master_pinzip as pin WITH(NOLOCK) 
	inner join tbl_master_city as cty WITH(NOLOCK) on cty.city_id=pin.city_id  
	inner join tbl_master_state as stat WITH(NOLOCK) on stat.id=cty.state_id where pin.pin_code=@pin_code)


	if(isnull(@StateID,'')='')
	BEGIN
		set @StateID=(
		select  top 1 STAT.id as [state]
		FROM tbl_master_user as usr WITH(NOLOCK) 

		--LEFT OUTER JOIN tbl_master_contact  as cont WITH(NOLOCK) on usr.user_contactId=cont.cnt_internalId

		LEFT OUTER JOIN #TEMPCONTACT cont ON usr.user_contactId=cont.cnt_internalId

		LEFT OUTER  JOIN (
				SELECT   add_cntId,add_state,add_city,add_country,add_pin,add_address1  FROM  tbl_master_address WITH(NOLOCK) where add_addressType='Office'
				)S on S.add_cntId=cont.cnt_internalId
		--LEFT OUTER JOIN tbl_master_pinzip as pinzip on pinzip.pin_id=S.add_pin
		LEFT OUTER JOIN tbl_master_state as STAT WITH(NOLOCK) on STAT.id=S.add_state
		where usr.user_id=@user_id)
	END

	--Rev 13.0
	IF @shop_image='' OR @shop_image IS NULL
		BEGIN
	--End of Rev 13.0
			--Rev 17.0
			--UPDATE  [tbl_Master_shop] SET [Shop_Name]=@shop_name,[Address]=@address,[Pincode]=@pin_code,[Shop_Lat]=@shop_lat,[Shop_Long]=@shop_long         
			--,[Shop_Owner]=@owner_name,[Shop_Owner_Email]=@owner_email,[Shop_Owner_Contact]=@owner_contact_no,[type]=@type,dob=@dob,stateId=@StateID
			----Rev 13.0
			----,date_aniversary=@date_aniversary,[Shop_Image]=@shop_image,assigned_to_pp_id=@assigned_to_pp_id,assigned_to_dd_id=@assigned_to_dd_id
			--,date_aniversary=@date_aniversary,assigned_to_pp_id=@assigned_to_pp_id,assigned_to_dd_id=@assigned_to_dd_id
			----End of Rev 13.0
			--,Amount=@amount
			----Rev 3.0 Start
			--,EntityCode=@EntityCode,Entity_Location=@Entity_Location,Alt_MobileNo=@Alt_MobileNo,Entity_Status=@Entity_Status,Entity_Type=@Entity_Type,
			--ShopOwner_PAN=@ShopOwner_PAN,ShopOwner_Aadhar=@ShopOwner_Aadhar,Remarks=@EntityRemarks,Area_id=@AreaId,Shop_City=@CityId
			----Rev 3.0 End
			----Rev 4.0 Start
			--,LastUpdated_By=@Entered_by,LastUpdated_On=GETDATE()
			----Rev 4.0 End
			----Rev 7.0 Start
			--,Model_id=@model_id,Primary_id=@primary_app_id,Secondary_id=@secondary_app_id,Lead_id=@lead_id,FunnelStage_id=@funnel_stage_id,
			--Stage_id=@stage_id,Booking_amount=@booking_amount
			----Rev 7.0 End
			----Rev 8.0 Start
			--,PartyType_id=@PartyType_id
			----Rev 8.0 End
			----Rev 9.0 Start
			--,Entity_Id=@entity_id,Party_status_id=@party_status_id
			----Rev 9.0 End
			----Rev 10.0 Start
			--,retailer_id=@retailer_id,dealer_id=@dealer_id,beat_id=@beat_id
			----Rev 10.0 End
			----Rev 11.0 Start
			--,assigned_to_shop_id=@assigned_to_shop_id
			----Rev 11.0 End
			----Rev 12.0 Start
			--,actual_address=@actual_address
			----Rev 12.0 End
			----Rev 14.0
			--,Agency_Name=@agency_name,Lead_Contact_Number=@lead_contact_number
			----End of Rev 14.0
			----Rev 15.0
			--,Project_Name=@project_name,Landline_Number=@landline_number
			----End of Rev 15.0
			----Rev 16.0
			--,AlternateNoForCustomer=@alternateNoForCustomer,WhatsappNoForCustomer=@whatsappNoForCustomer
			----End of Rev 16.0
			-- where Shop_Code=@shop_id
			 
			 UPDATE [tbl_Master_shop] WITH(TABLOCK) SET [Shop_Name]=CASE WHEN @shop_name IS NULL OR @shop_name='' THEN Shop_Name ELSE @shop_name END,
			 [Address]=CASE WHEN @address IS NULL OR @address='' THEN [Address] ELSE @address END,
			 [Pincode]=CASE WHEN @pin_code IS NULL OR @pin_code='' THEN [Pincode] ELSE @pin_code END,
			 [Shop_Lat]=CASE WHEN @shop_lat IS NULL OR @shop_lat='' THEN [Shop_Lat] ELSE @shop_lat END,
			 [Shop_Long]=CASE WHEN @shop_long IS NULL OR @shop_long='' THEN [Shop_Long] ELSE @shop_long END,
			 [Shop_Owner]=CASE WHEN @owner_name IS NULL OR @owner_name='' THEN [Shop_Owner] ELSE @owner_name END,
			 [Shop_Owner_Email]=CASE WHEN @owner_email IS NULL OR @owner_email='' THEN [Shop_Owner_Email] ELSE @owner_email END,
			 [Shop_Owner_Contact]=CASE WHEN @owner_contact_no IS NULL OR @owner_contact_no='' THEN [Shop_Owner_Contact] ELSE @owner_contact_no END,
			 [type]=CASE WHEN @type IS NULL OR @type='' THEN [type] ELSE @type END,
			 dob=CASE WHEN @dob IS NULL OR @dob='' THEN [dob] ELSE @dob END,
			 stateId=CASE WHEN @StateID IS NULL OR @StateID='' THEN [stateId] ELSE @StateID END,
			 date_aniversary=CASE WHEN @date_aniversary IS NULL OR @date_aniversary='' THEN [date_aniversary] ELSE @date_aniversary END,
			 assigned_to_pp_id=CASE WHEN @assigned_to_pp_id IS NULL OR @assigned_to_pp_id='' THEN [assigned_to_pp_id] ELSE @assigned_to_pp_id END,
			 assigned_to_dd_id=CASE WHEN @assigned_to_dd_id IS NULL OR @assigned_to_dd_id='' THEN [assigned_to_dd_id] ELSE @assigned_to_dd_id END,
			 Amount=CASE WHEN @amount IS NULL OR @amount='' THEN [Amount] ELSE @amount END,
			 EntityCode=CASE WHEN @EntityCode IS NULL OR @EntityCode='' THEN EntityCode ELSE @EntityCode END,
			 Entity_Location=CASE WHEN @Entity_Location IS NULL OR @Entity_Location='' THEN Entity_Location ELSE @Entity_Location END,
			 Alt_MobileNo=CASE WHEN @Alt_MobileNo IS NULL OR @Alt_MobileNo='' THEN [Alt_MobileNo] ELSE @Alt_MobileNo END,
			 Entity_Status=CASE WHEN @Entity_Status IS NULL OR @Entity_Status='' THEN [Entity_Status] ELSE @Entity_Status END,
			 Entity_Type=CASE WHEN @Entity_Type IS NULL OR @Entity_Type='' THEN [Entity_Type] ELSE @Entity_Type END,
			 ShopOwner_PAN=CASE WHEN @ShopOwner_PAN IS NULL OR @ShopOwner_PAN='' THEN [ShopOwner_PAN] ELSE @ShopOwner_PAN END,
			 ShopOwner_Aadhar=CASE WHEN @ShopOwner_Aadhar IS NULL OR @ShopOwner_Aadhar='' THEN [ShopOwner_Aadhar] ELSE @ShopOwner_Aadhar END,
			 Remarks=CASE WHEN @EntityRemarks IS NULL OR @EntityRemarks='' THEN [Remarks] ELSE @EntityRemarks END,
			 Area_id=CASE WHEN @AreaId IS NULL OR @AreaId='' THEN [Area_id] ELSE @AreaId END,
			 Shop_City=CASE WHEN @CityId IS NULL OR @CityId='' THEN [Shop_City] ELSE @CityId END,
			 LastUpdated_By=CASE WHEN @Entered_by IS NULL OR @Entered_by='' THEN [LastUpdated_By] ELSE @Entered_by END,LastUpdated_On=GETDATE(),
			 Model_id=CASE WHEN @model_id IS NULL OR @model_id=0 THEN [Model_id] ELSE @model_id END,
			 Primary_id=CASE WHEN @primary_app_id IS NULL OR @primary_app_id=0 THEN [Primary_id] ELSE @primary_app_id END,
			 Secondary_id=CASE WHEN @secondary_app_id IS NULL OR @secondary_app_id=0 THEN [Secondary_id] ELSE @secondary_app_id END,
			 Lead_id=CASE WHEN @lead_id IS NULL OR @lead_id=0 THEN [Lead_id] ELSE @lead_id END,
			 FunnelStage_id=CASE WHEN @funnel_stage_id IS NULL OR @funnel_stage_id='' THEN [FunnelStage_id] ELSE @funnel_stage_id END,
			 Stage_id=CASE WHEN @stage_id IS NULL OR @stage_id='' THEN [Stage_id] ELSE @stage_id END,
			 Booking_amount=@booking_amount,
			 PartyType_id=CASE WHEN @PartyType_id IS NULL OR @PartyType_id=0 THEN [PartyType_id] ELSE @PartyType_id END,
			 Entity_Id=CASE WHEN @entity_id IS NULL OR @entity_id='' THEN [Entity_Id] ELSE @entity_id END,
			 Party_status_id=CASE WHEN @party_status_id IS NULL OR @party_status_id='' THEN [Party_Status_id] ELSE @party_status_id END,
			 retailer_id=CASE WHEN @retailer_id IS NULL OR @retailer_id='' THEN [retailer_id] ELSE @retailer_id END,
			 dealer_id=CASE WHEN @dealer_id IS NULL OR @dealer_id='' THEN [dealer_id] ELSE @dealer_id END,
			 beat_id=CASE WHEN @beat_id IS NULL OR @beat_id='' THEN [beat_id] ELSE @beat_id END,
			 assigned_to_shop_id=CASE WHEN @assigned_to_shop_id IS NULL OR @assigned_to_shop_id='' THEN [assigned_to_shop_id] ELSE @assigned_to_shop_id END,
			 actual_address=CASE WHEN @actual_address IS NULL OR @actual_address='' THEN [actual_address] ELSE @actual_address END,
			 Agency_Name=CASE WHEN @agency_name IS NULL OR @agency_name='' THEN [Agency_Name] ELSE @agency_name END,
			 Lead_Contact_Number=CASE WHEN @lead_contact_number IS NULL OR @lead_contact_number='' THEN [Lead_Contact_Number] ELSE @lead_contact_number END,
			 Project_Name=CASE WHEN @project_name IS NULL OR @project_name='' THEN [Project_Name] ELSE @project_name END,
			 Landline_Number=CASE WHEN @landline_number IS NULL OR @landline_number='' THEN [Landline_Number] ELSE @landline_number END,
			 AlternateNoForCustomer=CASE WHEN @alternateNoForCustomer IS NULL OR @alternateNoForCustomer='' THEN [AlternateNoForCustomer] ELSE @alternateNoForCustomer END,
			 WhatsappNoForCustomer=CASE WHEN @whatsappNoForCustomer IS NULL OR @whatsappNoForCustomer='' THEN [WhatsappNoForCustomer] ELSE @whatsappNoForCustomer END,
			 --Rev 18.0
			 ShopStatusUpdate=CASE WHEN @shopStatusUpdate IS NULL OR @shopStatusUpdate='' THEN [ShopStatusUpdate] ELSE @shopStatusUpdate END,
			 --End of Rev 18.0
			 --Rev 19.0
			 GSTN_Number=CASE WHEN @GSTN_Number IS NULL OR @GSTN_Number='' THEN [GSTN_Number] ELSE @GSTN_Number END,
			 --End of Rev 19.0
			 --Rev 20.0
			 isUpdateAddressFromShopMaster=CASE WHEN @isUpdateAddressFromShopMaster IS NULL OR @isUpdateAddressFromShopMaster=0 THEN [ShopStatusUpdate] ELSE @isUpdateAddressFromShopMaster END,
			 --End of Rev 20.0
			 --Rev 21.0
			 Shop_FirstName=CASE WHEN @shop_firstName IS NULL OR @shop_firstName='' THEN Shop_FirstName ELSE @shop_firstName END,
			 Shop_LastName=CASE WHEN @shop_lastName IS NULL OR @shop_lastName='' THEN Shop_LastName ELSE @shop_lastName END,
			 Shop_CRMCompID=CASE WHEN @crm_companyID IS NULL OR @crm_companyID=0 THEN Shop_CRMCompID ELSE @crm_companyID END,
			 Shop_JobTitle=CASE WHEN @crm_jobTitle IS NULL OR @crm_jobTitle='' THEN Shop_JobTitle ELSE @crm_jobTitle END,
			 Shop_CRMTypeID=CASE WHEN @crm_typeID IS NULL OR @crm_typeID=0 THEN Shop_CRMTypeID ELSE @crm_typeID END,
			 Shop_CRMStatusID=CASE WHEN @crm_statusID IS NULL OR @crm_statusID=0 THEN Shop_CRMStatusID ELSE @crm_statusID END,
			 Shop_CRMSourceID=CASE WHEN @crm_sourceID IS NULL OR @crm_sourceID=0 THEN Shop_CRMSourceID ELSE @crm_sourceID END,
			 Shop_CRMReferenceID=CASE WHEN @crm_referenceID IS NULL OR @crm_referenceID='' THEN Shop_CRMReferenceID ELSE @crm_referenceID END,
			 Shop_CRMReferenceType=CASE WHEN @crm_referenceID_type IS NULL OR @crm_referenceID_type='' THEN Shop_CRMReferenceType ELSE @crm_referenceID_type END,
			 Shop_CRMStageID=CASE WHEN @crm_stage_ID IS NULL OR @crm_stage_ID=0 THEN Shop_CRMStageID ELSE @crm_stage_ID END,
			 Shop_CreateUser=CASE WHEN @assign_to IS NULL OR @assign_to='' THEN Shop_CreateUser ELSE @assign_to END,
			 saved_from_status=CASE WHEN @saved_from_status IS NULL OR @saved_from_status='' THEN saved_from_status ELSE @saved_from_status END
			 --End of Rev 21.0
			 where Shop_Code=@shop_id
			 --End of Rev 17.0
	--Rev 13.0
		END
	ELSE IF @shop_image<>'' OR @shop_image IS NOT NULL
		BEGIN
			 --Rev 17.0
			--UPDATE [tbl_Master_shop] SET [Shop_Name]=@shop_name,[Address]=@address,[Pincode]=@pin_code,[Shop_Lat]=@shop_lat,[Shop_Long]=@shop_long,
			--[Shop_Owner]=@owner_name,[Shop_Owner_Email]=@owner_email,[Shop_Owner_Contact]=@owner_contact_no,[type]=@type,dob=@dob,stateId=@StateID,
			--date_aniversary=@date_aniversary,[Shop_Image]=@shop_image,assigned_to_pp_id=@assigned_to_pp_id,assigned_to_dd_id=@assigned_to_dd_id,Amount=@amount,
			--EntityCode=@EntityCode,
			--Entity_Location=@Entity_Location,Alt_MobileNo=@Alt_MobileNo,Entity_Status=@Entity_Status,Entity_Type=@Entity_Type,
			--ShopOwner_PAN=@ShopOwner_PAN,ShopOwner_Aadhar=@ShopOwner_Aadhar,Remarks=@EntityRemarks,Area_id=@AreaId,Shop_City=@CityId,
			--LastUpdated_By=@Entered_by,LastUpdated_On=GETDATE(),
			--Model_id=@model_id,Primary_id=@primary_app_id,Secondary_id=@secondary_app_id,Lead_id=@lead_id,FunnelStage_id=@funnel_stage_id,
			--Stage_id=@stage_id,Booking_amount=@booking_amount,PartyType_id=@PartyType_id,Entity_Id=@entity_id,Party_status_id=@party_status_id,
			--retailer_id=@retailer_id,dealer_id=@dealer_id,beat_id=@beat_id,assigned_to_shop_id=@assigned_to_shop_id,actual_address=@actual_address
			----Rev 14.0
			--,Agency_Name=@agency_name,Lead_Contact_Number=@lead_contact_number
			----End of Rev 14.0
			----Rev 15.0
			--,Project_Name=@project_name,Landline_Number=@landline_number
			----End of Rev 15.0
			----Rev 16.0
			--,AlternateNoForCustomer=@alternateNoForCustomer,WhatsappNoForCustomer=@whatsappNoForCustomer
			----End of Rev 16.0
			--WHERE Shop_Code=@shop_id
			UPDATE [tbl_Master_shop] WITH(TABLOCK) SET [Shop_Name]=CASE WHEN @shop_name IS NULL OR @shop_name='' THEN Shop_Name ELSE @shop_name END,
			[Address]=CASE WHEN @address IS NULL OR @address='' THEN [Address] ELSE @address END,
			[Pincode]=CASE WHEN @pin_code IS NULL OR @pin_code='' THEN [Pincode] ELSE @pin_code END,
			[Shop_Lat]=CASE WHEN @shop_lat IS NULL OR @shop_lat='' THEN [Shop_Lat] ELSE @shop_lat END,
			[Shop_Long]=CASE WHEN @shop_long IS NULL OR @shop_long='' THEN [Shop_Long] ELSE @shop_long END,
			[Shop_Owner]=CASE WHEN @owner_name IS NULL OR @owner_name='' THEN [Shop_Owner] ELSE @owner_name END,
			[Shop_Owner_Email]=CASE WHEN @owner_email IS NULL OR @owner_email='' THEN [Shop_Owner_Email] ELSE @owner_email END,
			[Shop_Owner_Contact]=CASE WHEN @owner_contact_no IS NULL OR @owner_contact_no='' THEN [Shop_Owner_Contact] ELSE @owner_contact_no END,
			[type]=CASE WHEN @type IS NULL OR @type='' THEN [type] ELSE @type END,
			dob=CASE WHEN @dob IS NULL OR @dob='' THEN [dob] ELSE @dob END,
			stateId=CASE WHEN @StateID IS NULL OR @StateID='' THEN [stateId] ELSE @StateID END,
			date_aniversary=CASE WHEN @date_aniversary IS NULL OR @date_aniversary='' THEN [date_aniversary] ELSE @date_aniversary END,
			[Shop_Image]=@shop_image,
			assigned_to_pp_id=CASE WHEN @assigned_to_pp_id IS NULL OR @assigned_to_pp_id='' THEN [assigned_to_pp_id] ELSE @assigned_to_pp_id END,
			assigned_to_dd_id=CASE WHEN @assigned_to_dd_id IS NULL OR @assigned_to_dd_id='' THEN [assigned_to_dd_id] ELSE @assigned_to_dd_id END,
			Amount=CASE WHEN @amount IS NULL OR @amount='' THEN [Amount] ELSE @amount END,
			EntityCode=CASE WHEN @EntityCode IS NULL OR @EntityCode='' THEN EntityCode ELSE @EntityCode END,
			Entity_Location=CASE WHEN @Entity_Location IS NULL OR @Entity_Location='' THEN Entity_Location ELSE @Entity_Location END,
			Alt_MobileNo=CASE WHEN @Alt_MobileNo IS NULL OR @Alt_MobileNo='' THEN [Alt_MobileNo] ELSE @Alt_MobileNo END,
			Entity_Status=CASE WHEN @Entity_Status IS NULL OR @Entity_Status='' THEN [Entity_Status] ELSE @Entity_Status END,
			Entity_Type=CASE WHEN @Entity_Type IS NULL OR @Entity_Type='' THEN [Entity_Type] ELSE @Entity_Type END,
			ShopOwner_PAN=CASE WHEN @ShopOwner_PAN IS NULL OR @ShopOwner_PAN='' THEN [ShopOwner_PAN] ELSE @ShopOwner_PAN END,
			ShopOwner_Aadhar=CASE WHEN @ShopOwner_Aadhar IS NULL OR @ShopOwner_Aadhar='' THEN [ShopOwner_Aadhar] ELSE @ShopOwner_Aadhar END,
			Remarks=CASE WHEN @EntityRemarks IS NULL OR @EntityRemarks='' THEN [Remarks] ELSE @EntityRemarks END,
			Area_id=CASE WHEN @AreaId IS NULL OR @AreaId='' THEN [Area_id] ELSE @AreaId END,
			Shop_City=CASE WHEN @CityId IS NULL OR @CityId='' THEN [Shop_City] ELSE @CityId END,
			LastUpdated_By=CASE WHEN @Entered_by IS NULL OR @Entered_by='' THEN [LastUpdated_By] ELSE @Entered_by END,LastUpdated_On=GETDATE(),
			Model_id=CASE WHEN @model_id IS NULL OR @model_id=0 THEN [Model_id] ELSE @model_id END,
			Primary_id=CASE WHEN @primary_app_id IS NULL OR @primary_app_id=0 THEN [Primary_id] ELSE @primary_app_id END,
			Secondary_id=CASE WHEN @secondary_app_id IS NULL OR @secondary_app_id=0 THEN [Secondary_id] ELSE @secondary_app_id END,
			Lead_id=CASE WHEN @lead_id IS NULL OR @lead_id=0 THEN [Lead_id] ELSE @lead_id END,
			FunnelStage_id=CASE WHEN @funnel_stage_id IS NULL OR @funnel_stage_id='' THEN [FunnelStage_id] ELSE @funnel_stage_id END,
			Stage_id=CASE WHEN @stage_id IS NULL OR @stage_id='' THEN [Stage_id] ELSE @stage_id END,
			Booking_amount=@booking_amount,
			PartyType_id=CASE WHEN @PartyType_id IS NULL OR @PartyType_id=0 THEN [PartyType_id] ELSE @PartyType_id END,
			Entity_Id=CASE WHEN @entity_id IS NULL OR @entity_id='' THEN [Entity_Id] ELSE @entity_id END,
			Party_status_id=CASE WHEN @party_status_id IS NULL OR @party_status_id='' THEN [Party_Status_id] ELSE @party_status_id END,
			retailer_id=CASE WHEN @retailer_id IS NULL OR @retailer_id='' THEN [retailer_id] ELSE @retailer_id END,
			dealer_id=CASE WHEN @dealer_id IS NULL OR @dealer_id='' THEN [dealer_id] ELSE @dealer_id END,
			beat_id=CASE WHEN @beat_id IS NULL OR @beat_id='' THEN [beat_id] ELSE @beat_id END,
			assigned_to_shop_id=CASE WHEN @assigned_to_shop_id IS NULL OR @assigned_to_shop_id='' THEN [assigned_to_shop_id] ELSE @assigned_to_shop_id END,
			actual_address=CASE WHEN @actual_address IS NULL OR @actual_address='' THEN [actual_address] ELSE @actual_address END,
			Agency_Name=CASE WHEN @agency_name IS NULL OR @agency_name='' THEN [Agency_Name] ELSE @agency_name END,
			Lead_Contact_Number=CASE WHEN @lead_contact_number IS NULL OR @lead_contact_number='' THEN [Lead_Contact_Number] ELSE @lead_contact_number END,
			Project_Name=CASE WHEN @project_name IS NULL OR @project_name='' THEN [Project_Name] ELSE @project_name END,
			Landline_Number=CASE WHEN @landline_number IS NULL OR @landline_number='' THEN [Landline_Number] ELSE @landline_number END,
			AlternateNoForCustomer=CASE WHEN @alternateNoForCustomer IS NULL OR @alternateNoForCustomer='' THEN [AlternateNoForCustomer] ELSE @alternateNoForCustomer END,
			WhatsappNoForCustomer=CASE WHEN @whatsappNoForCustomer IS NULL OR @whatsappNoForCustomer='' THEN [WhatsappNoForCustomer] ELSE @whatsappNoForCustomer END,
			--Rev 18.0
			ShopStatusUpdate=CASE WHEN @shopStatusUpdate IS NULL OR @shopStatusUpdate='' THEN [ShopStatusUpdate] ELSE @shopStatusUpdate END,
			--End of Rev 18.0
			--Rev 19.0
			 GSTN_Number=CASE WHEN @GSTN_Number IS NULL OR @GSTN_Number='' THEN [GSTN_Number] ELSE @GSTN_Number END,
			 --End of Rev 19.0
			 --Rev 20.0
			 isUpdateAddressFromShopMaster=CASE WHEN @isUpdateAddressFromShopMaster IS NULL OR @isUpdateAddressFromShopMaster=0 THEN [ShopStatusUpdate] ELSE @isUpdateAddressFromShopMaster END,
			 --End of Rev 20.0
			 --Rev 21.0
			 Shop_FirstName=CASE WHEN @shop_firstName IS NULL OR @shop_firstName='' THEN Shop_FirstName ELSE @shop_firstName END,
			 Shop_LastName=CASE WHEN @shop_lastName IS NULL OR @shop_lastName='' THEN Shop_LastName ELSE @shop_lastName END,
			 Shop_CRMCompID=CASE WHEN @crm_companyID IS NULL OR @crm_companyID=0 THEN Shop_CRMCompID ELSE @crm_companyID END,
			 Shop_JobTitle=CASE WHEN @crm_jobTitle IS NULL OR @crm_jobTitle='' THEN Shop_JobTitle ELSE @crm_jobTitle END,
			 Shop_CRMTypeID=CASE WHEN @crm_typeID IS NULL OR @crm_typeID=0 THEN Shop_CRMTypeID ELSE @crm_typeID END,
			 Shop_CRMStatusID=CASE WHEN @crm_statusID IS NULL OR @crm_statusID=0 THEN Shop_CRMStatusID ELSE @crm_statusID END,
			 Shop_CRMSourceID=CASE WHEN @crm_sourceID IS NULL OR @crm_sourceID=0 THEN Shop_CRMSourceID ELSE @crm_sourceID END,
			 Shop_CRMReferenceID=CASE WHEN @crm_referenceID IS NULL OR @crm_referenceID='' THEN Shop_CRMReferenceID ELSE @crm_referenceID END,
			 Shop_CRMReferenceType=CASE WHEN @crm_referenceID_type IS NULL OR @crm_referenceID_type='' THEN Shop_CRMReferenceType ELSE @crm_referenceID_type END,
			 Shop_CRMStageID=CASE WHEN @crm_stage_ID IS NULL OR @crm_stage_ID=0 THEN Shop_CRMStageID ELSE @crm_stage_ID END,
			 Shop_CreateUser=CASE WHEN @assign_to IS NULL OR @assign_to='' THEN Shop_CreateUser ELSE @assign_to END,
			 saved_from_status=CASE WHEN @saved_from_status IS NULL OR @saved_from_status='' THEN saved_from_status ELSE @saved_from_status END
			 --End of Rev 21.0
			WHERE Shop_Code=@shop_id
			 --End of Rev 17.0
		END
	--End of Rev 13.0

	--Rev 18.0
	IF @shopStatusUpdate=0
		UPDATE [tbl_Master_shop] WITH(TABLOCK) SET Entity_Status=0 WHERE Shop_Code=@shop_id
	--End of Rev 18.0

	 IF(ISNULL(@stage_id,'')<>'')
		BEGIN
			INSERT INTO FTS_STAGEMAP WITH(TABLOCK) (SHOP_ID,STAGE_ID,USER_ID,UPDATE_DATE)
			VALUES (@shop_id,@stage_id,@Entered_by,GETDATE())
		END


	if(@@ROWCOUNT)>0
		BEGIN
			   select 
					'200' as returncode,@shop_id as shop_id,@session_token as session_token,@shop_name as shop_name,@address as address,@pin_code as pin_code
					,@shop_lat as shop_lat,@shop_long as shop_long,@owner_name as owner_name,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email
				   ,@user_id as user_id,@address  as address,@pin_code as pin_code,@shop_lat  as shop_lat,@shop_long  as shop_long,@owner_name as owner_name
				   ,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email,@type as [type],@dob as dob,@assigned_to_dd_id as assigned_to_dd_id
				   ,@assigned_to_pp_id as assigned_to_pp_id,@date_aniversary  as date_aniversary
				   --Rev 14.0
				   ,@agency_name AS agency_name,@lead_contact_number AS lead_contact_number
				   --End of Rev 14.0
				   --Rev 15.0
				   ,@project_name AS project_name,@landline_number AS landline_number
				   --End of Rev 15.0
				   --Rev 16.0
				   ,@alternateNoForCustomer AS alternateNoForCustomer,@whatsappNoForCustomer AS whatsappNoForCustomer,
				   --End of Rev 16.0
				   --Rev 18.0
				   @shopStatusUpdate AS shopStatusUpdate
				   --End of Rev 18.0
		END


	DECLARE @SHOPID BIGINT
	SET @SHOPID=(SELECT SHOP_ID FROM tbl_Master_shop WITH(NOLOCK) WHERE Shop_Code=@shop_id)
	--1.0 Rev start
	UPDATE FTS_ShopMoreDetails WITH(TABLOCK) SET FamilyMember_DOB=@family_member_dob,Addtional_DOB=@addtional_dob,Addtional_DOA=@addtional_doa,Director_Name=@director_name,
	KeyPerson_Name=@key_person_name,phone_no=@phone_no,Update_Date=GETDATE() WHERE SHOP_ID=@SHOPID
	--1.0 Rev End

	--2.0 Rev start
	UPDATE FTS_DOCTOR_DETAILS WITH(TABLOCK) SET FAMILY_MEMBER_DOB=@DOC_FAMILY_MEMBER_DOB,SPECIALIZATION=@SPECIALIZATION,AVG_PATIENT_PER_DAY=@AVG_PATIENT_PER_DAY,CATEGORY=@CATEGORY,
	DOC_ADDRESS=@DOC_ADDRESS,PINCODE=@DOC_PINCODE,DEGREE=@DEGREE,IsChamberSameHeadquarter=@IsChamberSameHeadquarter,
	Remarks=@Remarks,CHEMIST_NAME=@CHEMIST_NAME,CHEMIST_ADDRESS=@CHEMIST_ADDRESS,CHEMIST_PINCODE=@CHEMIST_PINCODE,ASSISTANT_NAME=@ASSISTANT_NAME,ASSISTANT_CONTACT_NO=@ASSISTANT_CONTACT_NO,
	ASSISTANT_DOB=@ASSISTANT_DOB,ASSISTANT_DOA=@ASSISTANT_DOA,ASSISTANT_FAMILY_DOB=@ASSISTANT_FAMILY_DOB,UPDATE_USER=@user_id,UPDATE_DATE=GETDATE()	WHERE SHOP_ID=@SHOPID
	--2.0 Rev End
	
	


	--END
	--ELSE

	--select '202' as returncode
	SET NOCOUNT OFF
END
GO