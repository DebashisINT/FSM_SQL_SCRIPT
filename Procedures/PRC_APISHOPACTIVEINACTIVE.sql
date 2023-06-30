--EXEC PRC_APISHOPACTIVEINACTIVE @USERID=11984

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APISHOPACTIVEINACTIVE]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APISHOPACTIVEINACTIVE] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APISHOPACTIVEINACTIVE]
(
@USERID BIGINT,
@session_token NVARCHAR(MAX)=NULL,
@Weburl NVARCHAR(MAX)=NULL,
@DoctorDegree NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 30/06/2023
Module	   : Shop Inactive Lists.Refer: Row: 852
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	SELECT CAST(shop.Shop_ID AS NVARCHAR(50)) AS shop_Auto,Shop_Code AS shop_id,Shop_Name AS shop_name,
	ISNULL(Address,'') AS [address],ISNULL(shop.Pincode,'') AS pin_code,Shop_Lat AS shop_lat,Shop_Long AS shop_long,Shop_City,Shop_Owner AS owner_name,
	Shop_WebSite,Shop_Owner_Email AS owner_email,Shop_Owner_Contact AS owner_contact_no,Shop_CreateUser,Shop_CreateTime AS added_date,Shop_ModifyUser,Shop_ModifyTime,
	@Weburl+Shop_Image AS Shop_Image,dob,date_aniversary,typs.Name AS Shoptype,shop.type,
	(SELECT COUNT(0) from tbl_trans_shopActivitysubmit WITH(NOLOCK) WHERE Shop_Id=shop.Shop_Code) + 
	(SELECT COUNT(0) from tbl_trans_shopActivitysubmit_Archive WITH(NOLOCK) WHERE Shop_Id=shop.Shop_Code) AS total_visit_count,
	(SELECT ISNULL(ISNULL(MAX(visited_time),shop.Lastvisit_date),GETDATE()) FROM (
	SELECT visited_time,Shop_Id from tbl_trans_shopActivitysubmit WITH(NOLOCK)
	UNION
	SELECT visited_time,Shop_Id from tbl_trans_shopActivitysubmit_Archive WITH(NOLOCK)
	)tbl WHERE tbl.Shop_Id=shop.Shop_Code) AS last_visit_date,isAddressUpdated,ISNULL(assigned_to_pp_id,'') AS assigned_to_pp_id,
	ISNULL(assigned_to_dd_id,'') AS assigned_to_dd_id,CAST(ISNULL(VerifiedOTP,0) AS BIT) AS is_otp_verified,
	ISNULL(shop.Amount,0) AS amount,DTLS.FamilyMember_DOB AS family_member_dob,DTLS.Addtional_DOB AS addtional_dob,
	DTLS.Addtional_DOA AS addtional_doa,ISNULL(DTLS.Director_Name,'') AS director_name,ISNULL(DTLS.KeyPerson_Name,'') AS key_person_name,ISNULL(DTLS.phone_no,'') AS phone_no,
	DOCDTLS.FAMILY_MEMBER_DOB AS doc_family_member_dob,DOCDTLS.SPECIALIZATION AS specialization,DOCDTLS.AVG_PATIENT_PER_DAY AS average_patient_per_day,
	DOCDTLS.CATEGORY AS category,DOCDTLS.DOC_ADDRESS AS doc_address,DOCDTLS.PINCODE AS doc_pincode,@DoctorDegree+DOCDTLS.DEGREE AS degree,
	CASE WHEN DOCDTLS.IsChamberSameHeadquarter=1 THEN '1' ELSE '0' END AS is_chamber_same_headquarter,DOCDTLS.Remarks AS is_chamber_same_headquarter_remarks,
	DOCDTLS.CHEMIST_NAME AS chemist_name,DOCDTLS.CHEMIST_ADDRESS AS chemist_address,DOCDTLS.CHEMIST_PINCODE AS chemist_pincode,
	DOCDTLS.ASSISTANT_NAME AS assistant_name,DOCDTLS.ASSISTANT_CONTACT_NO AS assistant_contact_no,DOCDTLS.ASSISTANT_DOB AS assistant_dob,
	DOCDTLS.ASSISTANT_DOA AS assistant_doa,DOCDTLS.ASSISTANT_FAMILY_DOB AS assistant_family_dob,shop.EntityCode AS entity_code,CONVERT(NVARCHAR(10),shop.Area_id) AS area_id,
	CONVERT(NVARCHAR(10),shop.Model_id) AS model_id,CONVERT(NVARCHAR(10),shop.Primary_id) AS primary_app_id,CONVERT(NVARCHAR(10),shop.Secondary_id) AS secondary_app_id,
	CONVERT(NVARCHAR(10),shop.Lead_id) AS lead_id,CONVERT(NVARCHAR(10),shop.FunnelStage_id) AS funnel_stage_id,CONVERT(NVARCHAR(10),shop.Stage_id) AS stage_id,shop.Booking_amount,
	CONVERT(NVARCHAR(10),shop.PartyType_id) as type_id,
	CASE WHEN ISNULL(CONVERT(NVARCHAR(10),shop.Entity_Id),'')='0' THEN '' ELSE ISNULL(CONVERT(NVARCHAR(10),shop.Entity_Id),'') END AS entity_id,
	CASE WHEN ISNULL(CONVERT(NVARCHAR(10),shop.Party_Status_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.Party_Status_id),'')  END AS party_status_id,
	CASE WHEN ISNULL(CONVERT(NVARCHAR(10),shop.retailer_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.retailer_id),'') END AS retailer_id,
	CASE WHEN ISNULL(CONVERT(NVARCHAR(10),shop.dealer_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.dealer_id),'')  END AS dealer_id,
	CASE WHEN ISNULL(CONVERT(NVARCHAR(10),shop.beat_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.beat_id),'')  END AS beat_id,
	ISNULL(account_holder,'') AS account_holder,ISNULL(account_no,'') AS account_no,ISNULL(bank_name,'') AS bank_name,ISNULL(ifsc,'') AS ifsc_code,ISNULL(upi_id,'') AS upi,
	CASE WHEN ISNULL(CONVERT(NVARCHAR(10),shop.assigned_to_shop_id),'')='0' THEN '' ELSE ISNULL(CONVERT(NVARCHAR(10),shop.assigned_to_shop_id),'')  END AS assigned_to_shop_id,
	shop.Project_Name AS project_name,shop.Landline_Number AS landline_number,shop.Agency_Name AS agency_name,shop.Lead_Contact_Number AS lead_contact_number,
	shop.AlternateNoForCustomer AS alternateNoForCustomer,shop.WhatsappNoForCustomer AS whatsappNoForCustomer,CAST(ISNULL(shop.IsShopDuplicate,0) AS BIT) AS isShopDuplicate, 
	ISNULL(shop.Purpose,'') AS purpose,ISNULL(shop.GSTN_Number,'') AS GSTN_Number,ISNULL(shop.ShopOwner_PAN,'') AS ShopOwner_PAN
	FROM tbl_Master_shop AS shop WITH(NOLOCK) 
	INNER JOIN tbl_master_user usr WITH(NOLOCK) ON shop.Shop_CreateUser=usr.user_id 
	INNER JOIN tbl_shoptype AS typs WITH(NOLOCK) ON typs.shop_typeId=shop.type
	LEFT OUTER JOIN FTS_ShopMoreDetails DTLS WITH(NOLOCK) ON DTLS.SHOP_ID=shop.Shop_ID
	LEFT OUTER JOIN FTS_DOCTOR_DETAILS DOCDTLS WITH(NOLOCK) ON DOCDTLS.SHOP_ID=shop.Shop_ID	
	WHERE usr.user_id=@USERID AND shop.Entity_Status=0
	ORDER BY Shop_ID DESC

	SET NOCOUNT OFF
END