IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTSShopRegister_EDIT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTSShopRegister_EDIT] AS' 
END
GO

ALTER  Proc [dbo].[Proc_FTSShopRegister_EDIT]
(
@session_token  varchar(MAX),
@user_id  varchar(MAX),
@shop_name  varchar(MAX)=NULL,
@address  varchar(MAX)=NULL,
@pin_code  varchar(MAX)=NULL,
@shop_lat  varchar(MAX)=NULL,
@shop_long  varchar(MAX)=NULL,
@owner_name  varchar(MAX)=NULL,
@owner_contact_no  varchar(MAX)=NULL,
@owner_email  varchar(MAX)=NULL,
@shop_image  nvarchar(MAX)=NULL,
@type int =NULL,
@dob varchar(MAX) =NULL,
@date_aniversary varchar(MAX) =NULL,
@shop_id varchar(MAX) =NULL,
@error varchar(MAX) =NULL,
@added_date varchar(MAX) =NULL,
@assigned_to_pp_id varchar(MAX) =NULL,
@assigned_to_dd_id  varchar(MAX) =NULL,
@amount varchar(100)=NULL,
--1.0 Rev start
@family_member_dob datetime =NULL,
@addtional_dob datetime =NULL,
@addtional_doa datetime =NULL,
@director_name varchar(MAX) =NULL,
@key_person_name  varchar(MAX) =NULL,
@phone_no varchar(100)=NULL,
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
@whatsappNoForCustomer NVARCHAR(100)=NULL
--End of Rev 16.0
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
************************************************************************************************************************************************/
BEGIN
	
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
				SET @CityId=(SELECT TOP(1)city_id FROM TBL_MASTER_AREA WHERE area_id=@AreaId)
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


	--if EXISTS(select  [Shop_CreateUser]  from [tbl_Master_shop] where [Shop_CreateUser]=@user_id and Shop_Code=@shop_id)

	--BEGIN
	declare @StateID  varchar(50)=NULL
	set @StateID=(select  top 1 stat.id  from tbl_master_pinzip as pin  inner join tbl_master_city as cty  on cty.city_id=pin.city_id  inner join tbl_master_state as stat on stat.id=cty.state_id where pin.pin_code=@pin_code)


	if(isnull(@StateID,'')='')
	BEGIN
		set @StateID=(
		select  top 1 STAT.id as [state]
		FROM tbl_master_user as usr
		LEFT OUTER JOIN tbl_master_contact  as cont on usr.user_contactId=cont.cnt_internalId
		LEFT OUTER  JOIN (
				SELECT   add_cntId,add_state,add_city,add_country,add_pin,add_address1  FROM  tbl_master_address  where add_addressType='Office'
				)S on S.add_cntId=cont.cnt_internalId
		--LEFT OUTER JOIN tbl_master_pinzip as pinzip on pinzip.pin_id=S.add_pin
		LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state
		where usr.user_id=@user_id)
	END

	--Rev 13.0
	IF @shop_image='' OR @shop_image IS NULL
		BEGIN
	--End of Rev 13.0
			UPDATE  [tbl_Master_shop] SET [Shop_Name]=@shop_name,[Address]=@address,[Pincode]=@pin_code,[Shop_Lat]=@shop_lat,[Shop_Long]=@shop_long         
			,[Shop_Owner]=@owner_name,[Shop_Owner_Email]=@owner_email,[Shop_Owner_Contact]=@owner_contact_no,[type]=@type,dob=@dob,stateId=@StateID
			--Rev 13.0
			--,date_aniversary=@date_aniversary,[Shop_Image]=@shop_image,assigned_to_pp_id=@assigned_to_pp_id,assigned_to_dd_id=@assigned_to_dd_id
			,date_aniversary=@date_aniversary,assigned_to_pp_id=@assigned_to_pp_id,assigned_to_dd_id=@assigned_to_dd_id
			--End of Rev 13.0
			,Amount=@amount
			--Rev 3.0 Start
			,EntityCode=@EntityCode,Entity_Location=@Entity_Location,Alt_MobileNo=@Alt_MobileNo,Entity_Status=@Entity_Status,Entity_Type=@Entity_Type,
			ShopOwner_PAN=@ShopOwner_PAN,ShopOwner_Aadhar=@ShopOwner_Aadhar,Remarks=@EntityRemarks,Area_id=@AreaId,Shop_City=@CityId
			--Rev 3.0 End
			--Rev 4.0 Start
			,LastUpdated_By=@Entered_by,LastUpdated_On=GETDATE()
			--Rev 4.0 End
			--Rev 7.0 Start
			,Model_id=@model_id,Primary_id=@primary_app_id,Secondary_id=@secondary_app_id,Lead_id=@lead_id,FunnelStage_id=@funnel_stage_id,
			Stage_id=@stage_id,Booking_amount=@booking_amount
			--Rev 7.0 End
			--Rev 8.0 Start
			,PartyType_id=@PartyType_id
			--Rev 8.0 End
			--Rev 9.0 Start
			,Entity_Id=@entity_id,Party_status_id=@party_status_id
			--Rev 9.0 End
			--Rev 10.0 Start
			,retailer_id=@retailer_id,dealer_id=@dealer_id,beat_id=@beat_id
			--Rev 10.0 End
			--Rev 11.0 Start
			,assigned_to_shop_id=@assigned_to_shop_id
			--Rev 11.0 End
			--Rev 12.0 Start
			,actual_address=@actual_address
			--Rev 12.0 End
			--Rev 14.0
			,Agency_Name=@agency_name,Lead_Contact_Number=@lead_contact_number
			--End of Rev 14.0
			--Rev 15.0
			,Project_Name=@project_name,Landline_Number=@landline_number
			--End of Rev 15.0
			--Rev 16.0
			,AlternateNoForCustomer=@alternateNoForCustomer,WhatsappNoForCustomer=@whatsappNoForCustomer
			--End of Rev 16.0
			 where Shop_Code=@shop_id
	--Rev 13.0
		END
	ELSE IF @shop_image<>'' OR @shop_image IS NOT NULL
		BEGIN
			UPDATE [tbl_Master_shop] SET [Shop_Name]=@shop_name,[Address]=@address,[Pincode]=@pin_code,[Shop_Lat]=@shop_lat,[Shop_Long]=@shop_long,
			[Shop_Owner]=@owner_name,[Shop_Owner_Email]=@owner_email,[Shop_Owner_Contact]=@owner_contact_no,[type]=@type,dob=@dob,stateId=@StateID,
			date_aniversary=@date_aniversary,[Shop_Image]=@shop_image,assigned_to_pp_id=@assigned_to_pp_id,assigned_to_dd_id=@assigned_to_dd_id,Amount=@amount,
			EntityCode=@EntityCode,Entity_Location=@Entity_Location,Alt_MobileNo=@Alt_MobileNo,Entity_Status=@Entity_Status,Entity_Type=@Entity_Type,
			ShopOwner_PAN=@ShopOwner_PAN,ShopOwner_Aadhar=@ShopOwner_Aadhar,Remarks=@EntityRemarks,Area_id=@AreaId,Shop_City=@CityId,
			LastUpdated_By=@Entered_by,LastUpdated_On=GETDATE(),
			Model_id=@model_id,Primary_id=@primary_app_id,Secondary_id=@secondary_app_id,Lead_id=@lead_id,FunnelStage_id=@funnel_stage_id,
			Stage_id=@stage_id,Booking_amount=@booking_amount,PartyType_id=@PartyType_id,Entity_Id=@entity_id,Party_status_id=@party_status_id,
			retailer_id=@retailer_id,dealer_id=@dealer_id,beat_id=@beat_id,assigned_to_shop_id=@assigned_to_shop_id,actual_address=@actual_address
			--Rev 14.0
			,Agency_Name=@agency_name,Lead_Contact_Number=@lead_contact_number
			--End of Rev 14.0
			--Rev 15.0
			,Project_Name=@project_name,Landline_Number=@landline_number
			--End of Rev 15.0
			--Rev 16.0
			,AlternateNoForCustomer=@alternateNoForCustomer,WhatsappNoForCustomer=@whatsappNoForCustomer
			--End of Rev 16.0
			WHERE Shop_Code=@shop_id
		END
	--End of Rev 13.0

	 IF(ISNULL(@stage_id,'')<>'')
		BEGIN
			INSERT INTO FTS_STAGEMAP(SHOP_ID,STAGE_ID,USER_ID,UPDATE_DATE)
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
				   ,@alternateNoForCustomer AS alternateNoForCustomer,@whatsappNoForCustomer AS whatsappNoForCustomer
				   --End of Rev 16.0
		END


	DECLARE @SHOPID BIGINT
	SET @SHOPID=(SELECT SHOP_ID FROM tbl_Master_shop WHERE Shop_Code=@shop_id)
	--1.0 Rev start
	UPDATE FTS_ShopMoreDetails SET FamilyMember_DOB=@family_member_dob,Addtional_DOB=@addtional_dob,Addtional_DOA=@addtional_doa,Director_Name=@director_name,
	KeyPerson_Name=@key_person_name,phone_no=@phone_no,Update_Date=GETDATE() WHERE SHOP_ID=@SHOPID
	--1.0 Rev End

	--2.0 Rev start
	UPDATE FTS_DOCTOR_DETAILS SET FAMILY_MEMBER_DOB=@DOC_FAMILY_MEMBER_DOB,SPECIALIZATION=@SPECIALIZATION,AVG_PATIENT_PER_DAY=@AVG_PATIENT_PER_DAY,CATEGORY=@CATEGORY,
	DOC_ADDRESS=@DOC_ADDRESS,PINCODE=@DOC_PINCODE,DEGREE=@DEGREE,IsChamberSameHeadquarter=@IsChamberSameHeadquarter,
	Remarks=@Remarks,CHEMIST_NAME=@CHEMIST_NAME,CHEMIST_ADDRESS=@CHEMIST_ADDRESS,CHEMIST_PINCODE=@CHEMIST_PINCODE,ASSISTANT_NAME=@ASSISTANT_NAME,ASSISTANT_CONTACT_NO=@ASSISTANT_CONTACT_NO,
	ASSISTANT_DOB=@ASSISTANT_DOB,ASSISTANT_DOA=@ASSISTANT_DOA,ASSISTANT_FAMILY_DOB=@ASSISTANT_FAMILY_DOB,UPDATE_USER=@user_id,UPDATE_DATE=GETDATE()	WHERE SHOP_ID=@SHOPID
	--2.0 Rev End
	
	


	--END
	--ELSE

	--select '202' as returncode

END