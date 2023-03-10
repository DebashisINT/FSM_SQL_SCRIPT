IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SP_API_GetshopMasterlists]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [SP_API_GetshopMasterlists] AS' 
END
GO

/* Written by Sanchita for V2.0.39 on 03/03/2023 - Implement Open API for Shop Master

POSTMAN HIT CREDENTIALS

https://localhost:44395/API/ShopMasterAPI/List

HEADERS
Content-Type : application/json
account-id : 31331/55454854
api-key : AAAAZj4rINg:APA91bHmnhpJuY6068fHwK3RFHPdWAEWkljlkjlkjklEwQ39jf8xzSm2IFDMwifn9e_A6AY8EYWmnP5IVFyJVyFmgv555dsdsemofko53fYEcJUsbpMYMxinjnzcTdOHQwfSfbenM_tzr


BODY
{
    "session_token":"",
    "user_id":"378",
    "Uniquecont":"0"
}

RAW - JSON

*/

ALTER PROCEDURE [dbo].[SP_API_GetshopMasterlists]
(
@ACTION NVARCHAR(500),
@user_id NVARCHAR(50)='',
@session_token NVARCHAR(MAX)='',
@Uniquecont int=0,
@Weburl NVARCHAR(MAX)='',
@FromDate NVARCHAR(MAX)='',
@Todate NVARCHAR(MAX)='',
@DoctorDegree NVARCHAR(MAX)='',
@OPENAPI_CLIENTNAME NVARCHAR(200)='',
@MODULE_NAME NVARCHAR(200)=''
) --WITH ENCRYPTION
AS
/************************************************************************************************************************************************
Written by Sanchita for Open API - Shop Master - on 03/03/2023	for V2.0.39
************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	declare @sql NVARCHAR(MAX)=''

	IF(@ACTION='GETLIST')
	BEGIN
		declare @topcount NVARCHAR(100)=@Uniquecont
		IF(isnull(@Uniquecont,0)<>0)
		BEGIN

			set @sql='select top  '+@topcount+' cast(shop.Shop_ID as varchar(50))	as shop_Auto,Shop_Code as shop_id,	Shop_Name as shop_name,  '
		END
		ELSE
		BEGIN
			set @sql='select cast(shop.Shop_ID as varchar(50))	as shop_Auto,Shop_Code as shop_id,	Shop_Name as shop_name,  '
		END
	
		set @sql+=' isnull(Address,'''') as [address],isnull(shop.Pincode,'''') as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name  '
		set @sql+=' ,Shop_WebSite,Shop_Owner_Email as owner_email,Shop_Owner_Contact as owner_contact_no   '
		set @sql+=' ,Shop_CreateUser,Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,'''+@Weburl+'''+ Shop_Image as Shop_Image,dob   '
		set @sql+=' ,date_aniversary,typs.Name as Shoptype,shop.type,(select count(0) from tbl_trans_shopActivitysubmit WITH(NOLOCK) where Shop_Id=shop.Shop_Code) + (select count(0) from tbl_trans_shopActivitysubmit_Archive WITH(NOLOCK) where Shop_Id=shop.Shop_Code) as total_visit_count, '
		set @sql+=' (SELECT ISNULL(ISNULL(MAX(visited_time),shop.Lastvisit_date),GETDATE()) from ('
		set @sql+=' SELECT visited_time,Shop_Id from tbl_trans_shopActivitysubmit WITH(NOLOCK) '--where Shop_Id=shop.Shop_Code) 
		set @sql+=' UNION ALL '
		set @sql+=' select visited_time,Shop_Id from tbl_trans_shopActivitysubmit_Archive WITH(NOLOCK) '-- where Shop_Id=shop.Shop_Code)
		set @sql+=' )tbl where tbl.Shop_Id=shop.Shop_Code) AS last_visit_date '--Lastvisit_date as last_visit_date  '
		set @sql+=' ,isAddressUpdated,isnull(assigned_to_pp_id,'''') as assigned_to_pp_id,isnull(assigned_to_dd_id,'''') as assigned_to_dd_id  '
		set @sql+=' ,cast(isnull(VerifiedOTP,0) as bit) as is_otp_verified,isnull(shop.Amount,0) as amount  '
		set @sql+=' ,DTLS.FamilyMember_DOB as family_member_dob,DTLS.Addtional_DOB as addtional_dob,  '
		set @sql+=' DTLS.Addtional_DOA as addtional_doa,isnull(DTLS.Director_Name,'''') as director_name,isnull(DTLS.KeyPerson_Name,'''') as key_person_name,   '
		set @sql+=' isnull(DTLS.phone_no,'''') as phone_no,   '
		set @sql+=' DOCDTLS.FAMILY_MEMBER_DOB AS doc_family_member_dob,DOCDTLS.SPECIALIZATION AS specialization,DOCDTLS.AVG_PATIENT_PER_DAY AS average_patient_per_day,  '
		set @sql+=' DOCDTLS.CATEGORY AS category,DOCDTLS.DOC_ADDRESS AS doc_address,DOCDTLS.PINCODE AS doc_pincode,'''+@DoctorDegree+'''+DOCDTLS.DEGREE AS degree,  '
		set @sql+=' CASE WHEN DOCDTLS.IsChamberSameHeadquarter=1 THEN ''1'' ELSE ''0'' END AS is_chamber_same_headquarter,DOCDTLS.Remarks AS is_chamber_same_headquarter_remarks,  '
		set @sql+=' DOCDTLS.CHEMIST_NAME AS chemist_name,DOCDTLS.CHEMIST_ADDRESS AS chemist_address,DOCDTLS.CHEMIST_PINCODE AS chemist_pincode,   '
		set @sql+=' DOCDTLS.ASSISTANT_NAME AS assistant_name,DOCDTLS.ASSISTANT_CONTACT_NO AS assistant_contact_no,DOCDTLS.ASSISTANT_DOB AS assistant_dob,   '
		set @sql+=' DOCDTLS.ASSISTANT_DOA AS assistant_doa,DOCDTLS.ASSISTANT_FAMILY_DOB AS assistant_family_dob,shop.EntityCode as entity_code,convert(nvarchar(10),shop.Area_id) as area_id  '
		set @sql+=' ,convert(nvarchar(10),shop.Model_id) as model_id,convert(nvarchar(10),shop.Primary_id) as primary_app_id,convert(nvarchar(10),shop.Secondary_id) as secondary_app_id   '
		set @sql+=' ,convert(nvarchar(10),shop.Lead_id) as lead_id,convert(nvarchar(10),shop.FunnelStage_id) as funnel_stage_id,convert(nvarchar(10),shop.Stage_id) as stage_id,shop.Booking_amount  '
		set @sql+=' ,convert(nvarchar(10),shop.PartyType_id) as type_id   '
		set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.Entity_Id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.Entity_Id),'''') END as entity_id'
		set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.Party_Status_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.Party_Status_id),'''')  END as party_status_id'
		set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.retailer_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.retailer_id),'''') END as retailer_id'
		set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.dealer_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.dealer_id),'''')  END as dealer_id'
		set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.beat_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.beat_id),'''')  END as beat_id'			
		set @sql+=',ISNULL(account_holder,'''') as account_holder'
		set @sql+=',ISNULL(account_no,'''') as account_no'
		set @sql+=',ISNULL(bank_name,'''') as bank_name'
		set @sql+=',ISNULL(ifsc,'''') as ifsc_code'
		set @sql+=',ISNULL(upi_id,'''') as upi'
		set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.assigned_to_shop_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.assigned_to_shop_id),'''')  END as assigned_to_shop_id,'
		set @sql+='shop.Project_Name AS project_name,shop.Landline_Number AS landline_number,shop.Agency_Name AS agency_name,shop.Lead_Contact_Number AS lead_contact_number,'
		set @sql+='shop.AlternateNoForCustomer AS alternateNoForCustomer,shop.WhatsappNoForCustomer AS whatsappNoForCustomer,'
		set @sql+='CAST(ISNULL(shop.IsShopDuplicate,0) AS BIT) AS isShopDuplicate,'
		set @sql+='ISNULL(shop.Purpose,'''') AS purpose,'
		set @sql+='ISNULL(shop.GSTN_Number,'''') AS GSTN_Number,ISNULL(shop.ShopOwner_PAN,'''') AS ShopOwner_PAN '
		set @sql+=' from tbl_Master_shop as shop WITH(NOLOCK)  '
		set @sql+=' INNER JOIN  tbl_master_user usr WITH(NOLOCK) on shop.Shop_CreateUser=usr.user_id   '
		set @sql+=' INNER JOIN  tbl_shoptype as typs WITH(NOLOCK) on typs.shop_typeId=shop.type   '
		set @sql+=' LEFT OUTER JOIN FTS_ShopMoreDetails DTLS WITH(NOLOCK) ON DTLS.SHOP_ID=shop.Shop_ID	 '
		set @sql+=' LEFT OUTER JOIN FTS_DOCTOR_DETAILS DOCDTLS WITH(NOLOCK) ON DOCDTLS.SHOP_ID=shop.Shop_ID  '
		set @sql+=' WHERE usr.user_id='+@user_id+'	  '
		set @sql+=' AND shop.Entity_Status=1	  '
		set @sql+=' order  by Shop_ID  desc' 
		EXEC SP_EXECUTESQL @sql
	END
	
	IF(@ACTION='GETKEY')
	BEGIN
		
		SELECT OPENAPI_KEY, OPENAPI_ACCOUNTID FROM OPENAPI_CONFIG WHERE OPENAPI_CLIENTNAME='FSM_ITC' AND MODULE_NAME='SHOP MASTER' AND ACTIVE=1
	END
		
	SET NOCOUNT OFF
END