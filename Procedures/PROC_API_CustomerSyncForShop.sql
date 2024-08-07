IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_API_CustomerSyncForShop]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_API_CustomerSyncForShop] AS' 
END
GO

--exec [Sp_ApiShopRegister]  'lmeeawunipwxqc3xl43k25i5','504','','','','','','','','',''

ALTER  Proc [dbo].[PROC_API_CustomerSyncForShop]
(
@session_token  varchar(MAX)=NULL,
@user_id  varchar(MAX)=NULL,
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
@added_date datetime =NULL,
@assigned_to_pp_id varchar(MAX) =NULL,
@assigned_to_dd_id  varchar(MAX) =NULL,
@amount varchar(100)=NULL,
@family_member_dob datetime =NULL,
@addtional_dob datetime =NULL,
@addtional_doa datetime =NULL,
@director_name varchar(MAX) =NULL,
@key_person_name  varchar(MAX) =NULL,
@phone_no varchar(100)=NULL,
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
,@EntityCode NVARCHAR(100)=NULL,
@Entity_Location NVARCHAR(MAX)=NULL,
@Alt_MobileNo NVARCHAR(15)=NULL,
@Entity_Status INT=NULL,
@Entity_Type INT=NULL,
@ShopOwner_PAN NVARCHAR(15)=NULL,
@ShopOwner_Aadhar NVARCHAR(20)=NULL,
@EntityRemarks NVARCHAR(500)=NULL,
@AreaId NVARCHAR(10) =NULL,
@City NVARCHAR(100)=NULL
,@Entered_by NVARCHAR(10)=NULL
,@model_id NVARCHAR(10)=NULL,
@primary_app_id NVARCHAR(10)=NULL,
@secondary_app_id NVARCHAR(10)=NULL,
@lead_id NVARCHAR(10)=NULL,
@funnel_stage_id NVARCHAR(10)=NULL,
@stage_id NVARCHAR(10)=NULL,
@booking_amount NVARCHAR(30)=NULL
,@PartyType_id NVARCHAR(10)=NULL
,@entity_id NVARCHAR(10)=NULL
,@party_status_id NVARCHAR(10)=NULL
,@retailer_id NVARCHAR(10)=NULL
,@dealer_id NVARCHAR(10)=NULL
,@beat_id NVARCHAR(10)=NULL
,@assigned_to_shop_id NVARCHAR(100)=NULL
,@CityId NVARCHAR(100)=NULL,
@IsServicePoint INT=0
)  
As
/************************************************************************************************************************************************
1.0			TANMOY			17-03-2021		Create Procedure			
************************************************************************************************************************************************/
Begin
	--declare @CityId nvarchar(10)
	set @CityId=(select city_id from tbl_master_city where city_name=@City)

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
	
	IF ISNUMERIC(@PartyType_id)=0
	BEGIN
		SET @PartyType_id=0;
	END	

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


	IF ISNULL(@shop_name,'')<>''
	BEGIN
	IF ISNULL(@EntityCode,'')<>''
	BEGIN
	IF ISNULL(@owner_name,'')<>''
	BEGIN
	IF ISNULL(@address,'')<>''
	BEGIN
	IF ISNULL(@pin_code,'')<>''
	BEGIN
	IF ISNULL(@owner_contact_no,'')<>''
	BEGIN
	if EXISTS(select user_id from tbl_master_user where user_id=@user_id)
		BEGIN
			if NOT EXISTS(select Shop_ID from [tbl_Master_shop] where Shop_Code=@shop_id  )
				BEGIN
					if NOT EXISTS(select Shop_ID from [tbl_Master_shop] where Shop_Owner_Contact=@owner_contact_no and Shop_CreateUser=@user_id )
						BEGIN
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

							INSERT INTO [tbl_Master_shop] ([Shop_Name],[Address],[Pincode],[Shop_Lat],[Shop_Long],[Shop_Owner],[Shop_Owner_Email],[Shop_Owner_Contact],[Shop_CreateUser]
									   ,[Shop_CreateTime],[type],dob,date_aniversary,[Shop_Image],Shop_Code,total_visitcount,Lastvisit_date,isAddressUpdated,assigned_to_pp_id
										,assigned_to_dd_id,stateId,Amount,EntityCode,Entity_Location,Alt_MobileNo,Entity_Status,Entity_Type,ShopOwner_PAN,ShopOwner_Aadhar,Remarks,Area_id,Shop_City
										,Entered_By,Entered_On,Model_id,Primary_id,Secondary_id,Lead_id,FunnelStage_id,Stage_id,Booking_amount,PartyType_id,Entity_Id,Party_Status_id
										,retailer_id,dealer_id,beat_id,assigned_to_shop_id,IsServicePoint
										
										)
								 VALUES (@shop_name,@address,@pin_code,@shop_lat,@shop_long,@owner_name,@owner_email,@owner_contact_no,@user_id,@added_date,@type,@dob,@date_aniversary
										,@shop_image,@shop_id,1,@added_date,1,@assigned_to_pp_id,@assigned_to_dd_id,@StateID,@amount,@EntityCode,@Entity_Location,@Alt_MobileNo,@Entity_Status,
										@Entity_Type,@ShopOwner_PAN,@ShopOwner_Aadhar,@EntityRemarks,@AreaId,@CityId,@Entered_by,GETDATE(),@model_id,@primary_app_id,@secondary_app_id,@lead_id,@funnel_stage_id,@stage_id,@booking_amount
										,@PartyType_id,@entity_id,@party_status_id,@retailer_id,@dealer_id,@beat_id,@assigned_to_shop_id,@IsServicePoint
										)

							SET @COUNT=SCOPE_IDENTITY();

							IF(ISNULL(@stage_id,'')<>'')
							BEGIN
								INSERT INTO FTS_STAGEMAP(SHOP_ID,STAGE_ID,USER_ID,UPDATE_DATE)
								VALUES (@shop_id,@stage_id,@Entered_by,GETDATE())
							END


							if(@@ROWCOUNT)>0
								BEGIN
									INSERT INTO [tbl_trans_shopActivitysubmit] ([User_Id],[Shop_Id],visited_date,visited_time,spent_duration,total_visit_count,Createddate,Is_Newshopadd)
									values(@user_id,@shop_id,cast(@added_date as date),@added_date,'00:00:00',1,@added_date,1)

									select '200' as returncode,@shop_id as shop_id,@session_token as session_token,@shop_name as shop_name,@address as address,@pin_code as pin_code
									,@shop_lat as shop_lat,@shop_long as shop_long,@owner_name as owner_name,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email
									,@user_id as user_id,@address  as address,@pin_code as pin_code,@shop_lat  as shop_lat,@shop_long  as shop_long,@owner_name as owner_name
									,@owner_contact_no  as owner_contact_no,@owner_email  as owner_email,@type as [type],@dob as dob,@date_aniversary  as date_aniversary

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
							select '210' as returncode
						END
				END
			ELSE
				BEGIN
					select '209' as returncode
				END
		END
	ELSE
		BEGIN
			select '208' as returncode
		END
		END
	ELSE
		BEGIN
			select '207' as returncode
		END
		END
	ELSE
		BEGIN
			select '206' as returncode
		END
		END
	ELSE
		BEGIN
			select '205' as returncode
		END
		END
	ELSE
		BEGIN
			select '204' as returncode
		END
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
END
GO