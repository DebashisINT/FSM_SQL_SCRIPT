IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SP_API_Getshoplists]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [SP_API_Getshoplists] AS' 
END
GO

ALTER PROCEDURE [dbo].[SP_API_Getshoplists]
(
@user_id NVARCHAR(50),
@session_token NVARCHAR(MAX)=NULL,
@Uniquecont int=NULL,
@Weburl NVARCHAR(MAX)=NULL,
@FromDate NVARCHAR(MAX)=NULL,
@Todate NVARCHAR(MAX)=NULL,
@DoctorDegree NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/************************************************************************************************************************************************
1.0		TANMOY					31-12-2019		show EXTER FIELD FOR MORE DETAILS 
2.0		TANMOY					06-01-2019		Show EXTRA DETAILS from ANOTHER TABLE FOR DECTOR
3.0		TANMOY					09-01-2019		Show SHOP USER Hierarchy WISE
4.0		TANMOY					12-05-2020		add new column entitycode
5.0		TANMOY					15-05-2020		add new column area_id
6.0		TANMOY					20-05-2020		active shop show in list
7.0		TANMOY					09-06-2020		extra column show in list
8.0		TANMOY					23-06-2020		extra column show in list
9.0		TANMOY					26-08-2020		null last_visit_date send create date
10.0	INDRANIL				15-02-2021		INSERT Entity Type Id and Party status id
11.0	INDRANIL				16-02-2021		Get retailer_id,dealer_id,beat_id
12.0	INDRANIL				17-02-2021		Get account_holder,account_no,bank_name,ifsc,upi_id
13.0	Debashis				19-01-2022		Four fields added as Project_Name,Landline_Number,Agency_Name & Lead_Contact_Number.
14.0	Debashis				10-02-2022		Two fields added as AlternateNoForCustomer & WhatsappNoForCustomer.Refer: 637
15.0	Debashis				01-06-2022		One field added as IsShopDuplicate.Row: 694
16.0	Debashis				17-06-2022		One field added as Purpose.Row: 704
17.0	Debashis				02-11-2022		New Parameter added.Row: 753 to 759
18.0	Debashis				16-06-2023		Shoplist/List -> parameter added_date value mismatch
												When fetching shops by using Shoplist/List this api a parameter associated with shop "added_date" 
												returning wrong result.Refer: 0026360
19.0	Debashis	v2.0.42		06-10-2023		New Parameter added.Row: 870 to 876
20.0	Debashis	v2.0.43		22-12-2023		Some new fields have been added.Row: 898
************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	declare @sql NVARCHAR(MAX)=''

	declare @topcount NVARCHAR(100)=@Uniquecont
	IF(isnull(@Uniquecont,0)<>0)
		BEGIN

			set @sql='select top  '+@topcount+' cast(shop.Shop_ID as varchar(50))	as shop_Auto,Shop_Code as shop_id,	Shop_Name as shop_name,  '
			set @sql+=' isnull(Address,'''') as [address],isnull(shop.Pincode,'''') as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name  '
			set @sql+=' ,Shop_WebSite,Shop_Owner_Email as owner_email,Shop_Owner_Contact as owner_contact_no '
			--Rev 18.0
			--set @sql+=' ,Shop_CreateUser,Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,'''+@Weburl+'''+ Shop_Image as Shop_Image,dob   '
			set @sql+=' ,Shop_CreateUser,Shop_CreateTime AS added_date,Shop_ModifyUser,Shop_ModifyTime,'''+@Weburl+'''+ Shop_Image as Shop_Image,dob   '
			--End of Rev 18.0
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
			--Rev 7.0 Start
			set @sql+=' ,convert(nvarchar(10),shop.Model_id) as model_id,convert(nvarchar(10),shop.Primary_id) as primary_app_id,convert(nvarchar(10),shop.Secondary_id) as secondary_app_id   '
			set @sql+=' ,convert(nvarchar(10),shop.Lead_id) as lead_id,convert(nvarchar(10),shop.FunnelStage_id) as funnel_stage_id,convert(nvarchar(10),shop.Stage_id) as stage_id,shop.Booking_amount  '
			--Rev 7.0 End
			--Rev 8.0 Start
			set @sql+=' ,convert(nvarchar(10),shop.PartyType_id) as type_id   '
			--Rev 8.0 End
			--Rev 10.0 Start
			set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.Entity_Id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.Entity_Id),'''') END as entity_id'
			set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.Party_Status_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.Party_Status_id),'''')  END as party_status_id'
			--Rev 10.0 End
			--Rev 11.0 Start
			set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.retailer_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.retailer_id),'''') END as retailer_id'
			set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.dealer_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.dealer_id),'''')  END as dealer_id'
			set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.beat_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.beat_id),'''')  END as beat_id'			
			--Rev 11.0 End
			--Rev 12.0 Start
			set @sql+=',ISNULL(account_holder,'''') as account_holder'
			set @sql+=',ISNULL(account_no,'''') as account_no'
			set @sql+=',ISNULL(bank_name,'''') as bank_name'
			set @sql+=',ISNULL(ifsc,'''') as ifsc_code'
			set @sql+=',ISNULL(upi_id,'''') as upi'
			set @sql+=',CASE WHEN ISNULL(convert(varchar(10),shop.assigned_to_shop_id),'''')=''0'' THEN '''' ELSE ISNULL(convert(varchar(10),shop.assigned_to_shop_id),'''')  END as assigned_to_shop_id,'
			--Rev 12.0 End
			--Rev 13.0
			set @sql+='shop.Project_Name AS project_name,shop.Landline_Number AS landline_number,shop.Agency_Name AS agency_name,shop.Lead_Contact_Number AS lead_contact_number,'
			--End of Rev 13.0
			--Rev 14.0
			set @sql+='shop.AlternateNoForCustomer AS alternateNoForCustomer,shop.WhatsappNoForCustomer AS whatsappNoForCustomer,'
			--End of Rev 14.0
			--Rev 15.0
			set @sql+='CAST(ISNULL(shop.IsShopDuplicate,0) AS BIT) AS isShopDuplicate,'
			--End of Rev 15.0
			--Rev 16.0
			set @sql+='ISNULL(shop.Purpose,'''') AS purpose,'
			--End of Rev 16.0
			--Rev 17.0
			set @sql+='ISNULL(shop.GSTN_Number,'''') AS GSTN_Number,ISNULL(shop.ShopOwner_PAN,'''') AS ShopOwner_PAN,'
			--End of Rev 17.0
			--Rev 19.0
			set @sql+='ISNULL(shop.FSSAILicNo,'''') AS FSSAILicNo,CAST(ISNULL(shop.isUpdateAddressFromShopMaster,0) AS BIT) AS isUpdateAddressFromShopMaster,'
			--End of Rev 19.0
			--Rev 20.0
			set @sql+='ISNULL(shop.Shop_FirstName,'''') AS shop_firstName,ISNULL(shop.Shop_LastName,'''') AS shop_lastName,ISNULL(CRMCOMP.COMPANY_NAME,'''') AS crm_companyName,shop.Shop_CRMCompID AS crm_companyID,'
			set @sql+='SHOP.Shop_JobTitle AS crm_jobTitle,ISNULL(CRMTYPE.TYPE_NAME,'''') AS crm_type,shop.Shop_CRMTypeID AS crm_typeID,shop.Shop_CRMStatusID AS crm_statusID,'
			set @sql+='ISNULL(CRMSTAT.STATUS_NAME,'''') AS crm_status,ISNULL(CRMSRC.SOURCE_NAME,'''') AS crm_source,shop.Shop_CRMSourceID AS crm_sourceID,'
			set @sql+='CASE WHEN shop.Shop_CRMReferenceType=''SHOP'' THEN shop.Shop_Name ELSE ISNULL(CRMCNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CRMCNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CRMCNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CRMCNT.CNT_LASTNAME,'''') END AS crm_reference,'
			set @sql+='shop.Shop_CRMReferenceID AS crm_referenceID,SHOP.Shop_CRMReferenceType AS crm_referenceID_type,ISNULL(CRMSTAG.STAGE_NAME,'''') AS crm_stage,shop.Shop_CRMStageID AS crm_stage_ID,'
			set @sql+='usr.user_name AS assign_to,shop.saved_from_status AS saved_from_status '
			--End of Rev 20.0
			set @sql+=' from tbl_Master_shop as shop WITH(NOLOCK)  '
			set @sql+=' INNER JOIN  tbl_master_user usr WITH(NOLOCK) on shop.Shop_CreateUser=usr.user_id   '
			set @sql+=' INNER JOIN  tbl_shoptype as typs WITH(NOLOCK) on typs.shop_typeId=shop.type   '
			set @sql+=' LEFT OUTER JOIN FTS_ShopMoreDetails DTLS WITH(NOLOCK) ON DTLS.SHOP_ID=shop.Shop_ID	 '
			set @sql+=' LEFT OUTER JOIN FTS_DOCTOR_DETAILS DOCDTLS WITH(NOLOCK) ON DOCDTLS.SHOP_ID=shop.Shop_ID  '
			--Rev 20.0
			----REV 3.0 START
			--set @sql+=' WHERE shop.user_id='+@user_id+'	  '
			set @sql+=' LEFT OUTER JOIN CRM_CONTACT_COMPANY CRMCOMP WITH(NOLOCK) ON shop.Shop_CRMCompID=CRMCOMP.COMPANY_ID AND CRMCOMP.IsActive=1 '
			set @sql+=' LEFT OUTER JOIN CRM_CONTACT_TYPE CRMTYPE WITH(NOLOCK) ON shop.Shop_CRMTypeID=CRMTYPE.TYPE_ID AND CRMTYPE.IsActive=1 '
			set @sql+=' LEFT OUTER JOIN CRM_CONTACT_STATUS CRMSTAT WITH(NOLOCK) ON shop.Shop_CRMStatusID=CRMSTAT.STATUS_ID AND CRMSTAT.IsActive=1 '
			set @sql+=' LEFT OUTER JOIN CRM_CONTACT_SOURCE CRMSRC WITH(NOLOCK) ON shop.Shop_CRMSourceID=CRMSRC.SOURCE_ID AND CRMSRC.IsActive=1 '
			set @sql+=' LEFT OUTER JOIN CRM_CONTACT_STAGE CRMSTAG WITH(NOLOCK) ON shop.Shop_CRMStageID=CRMSTAG.STAGE_ID AND CRMSTAG.IsActive=1 '
			set @sql+=' LEFT OUTER JOIN TBL_MASTER_CONTACT CRMCNT WITH(NOLOCK) ON shop.Shop_CRMReferenceID=CRMCNT.cnt_internalId AND CRMCNT.cnt_contactType=''EM'' AND SHOP.Shop_CRMReferenceType<>''SHOP'' '
			set @sql+=' WHERE CAST(usr.user_id AS VARCHAR)='''+@user_id+''' '
			--End of Rev 20.0
			--set @sql+=' WHERE usr.user_id IN (SELECT user_id FROM dbo.Get_UserReporthierarchy ('+@user_id+'))	'	
			--REV 3.0 END
			--REV 6.0 START
			set @sql+=' AND shop.Entity_Status=1 '
			--REV 6.0 END
			set @sql+=' order  by Shop_ID  desc' 
			--and  SessionToken='''+@session_token+''' 
			EXEC SP_EXECUTESQL @sql
			--select  @sql
		END
	ELSE
		BEGIN
			select cast(shop.Shop_ID as varchar(50)) as shop_Auto ,Shop_Code as shop_id,Shop_Name as shop_name,
			isnull(Address,'') as [address],isnull(shop.Pincode,'') as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name
			,Shop_WebSite,Shop_Owner_Email as owner_email	,Shop_Owner_Contact as owner_contact_no
			--Rev 18.0
			--,Shop_CreateUser,Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,@Weburl+Shop_Image as Shop_Image
			,Shop_CreateUser,Shop_CreateTime AS added_date,Shop_ModifyUser,Shop_ModifyTime,@Weburl+Shop_Image as Shop_Image
			--End of Rev 18.0
			,dob,date_aniversary,typs.Name as Shoptype,shop.type,(select count(0) from tbl_trans_shopActivitysubmit WITH(NOLOCK) where Shop_Id=shop.Shop_Code) + (select count(0) from tbl_trans_shopActivitysubmit_Archive WITH(NOLOCK) where Shop_Id=shop.Shop_Code) as total_visit_count
			,(SELECT ISNULL(ISNULL(MAX(visited_time),shop.Lastvisit_date),GETDATE()) from (
				SELECT visited_time,Shop_Id from tbl_trans_shopActivitysubmit WITH(NOLOCK) --where Shop_Id=shop.Shop_Code) 
				UNION
				select visited_time,Shop_Id from tbl_trans_shopActivitysubmit_Archive WITH(NOLOCK) -- where Shop_Id=shop.Shop_Code)
				)tbl where tbl.Shop_Id=shop.Shop_Code) as last_visit_date,
			isAddressUpdated,isnull(assigned_to_pp_id,'') as assigned_to_pp_id
			,isnull(assigned_to_dd_id,'') as assigned_to_dd_id,cast(isnull(VerifiedOTP,0) as bit) as is_otp_verified
			,isnull(shop.Amount,0) as amount,DTLS.FamilyMember_DOB as family_member_dob,DTLS.Addtional_DOB as addtional_dob,
			DTLS.Addtional_DOA as addtional_doa,isnull(DTLS.Director_Name,'') as director_name,isnull(DTLS.KeyPerson_Name,'') as key_person_name,
			isnull(DTLS.phone_no,'') as phone_no,
			DOCDTLS.FAMILY_MEMBER_DOB AS doc_family_member_dob,DOCDTLS.SPECIALIZATION AS specialization,DOCDTLS.AVG_PATIENT_PER_DAY AS average_patient_per_day,
			DOCDTLS.CATEGORY AS category,DOCDTLS.DOC_ADDRESS AS doc_address,DOCDTLS.PINCODE AS doc_pincode,@DoctorDegree+DOCDTLS.DEGREE AS degree,
			CASE WHEN DOCDTLS.IsChamberSameHeadquarter=1 THEN '1' ELSE '0' END AS is_chamber_same_headquarter,DOCDTLS.Remarks AS is_chamber_same_headquarter_remarks,
			DOCDTLS.CHEMIST_NAME AS chemist_name,DOCDTLS.CHEMIST_ADDRESS AS chemist_address,DOCDTLS.CHEMIST_PINCODE AS chemist_pincode,
			DOCDTLS.ASSISTANT_NAME AS assistant_name,DOCDTLS.ASSISTANT_CONTACT_NO AS assistant_contact_no,DOCDTLS.ASSISTANT_DOB AS assistant_dob,
			DOCDTLS.ASSISTANT_DOA AS assistant_doa,DOCDTLS.ASSISTANT_FAMILY_DOB AS assistant_family_dob,shop.EntityCode as entity_code,
			convert(nvarchar(10),shop.Area_id) as area_id
			--Rev 7.0 Start
			,convert(nvarchar(10),shop.Model_id) as model_id,convert(nvarchar(10),shop.Primary_id) as primary_app_id,convert(nvarchar(10),shop.Secondary_id) as secondary_app_id
			,convert(nvarchar(10),shop.Lead_id) as lead_id,convert(nvarchar(10),shop.FunnelStage_id) as funnel_stage_id,convert(nvarchar(10),shop.Stage_id) as stage_id,shop.Booking_amount
			--Rev 7.0 End
			--Rev 8.0 Start
			,convert(nvarchar(10),shop.PartyType_id) as type_id
			--Rev 8.0 End
			--Rev 10.0 Start
			,CASE WHEN ISNULL(convert(varchar(10),shop.Entity_Id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.Entity_Id),'') END as entity_id
			,CASE WHEN ISNULL(convert(varchar(10),shop.Party_Status_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.Party_Status_id),'')  END as party_status_id
			--Rev 10.0 End			
			--Rev 11.0 Start
			,CASE WHEN ISNULL(convert(varchar(10),shop.retailer_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.retailer_id),'') END as retailer_id
			,CASE WHEN ISNULL(convert(varchar(10),shop.dealer_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.dealer_id),'')  END as dealer_id
			,CASE WHEN ISNULL(convert(varchar(10),shop.beat_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.beat_id),'')  END as beat_id		
			--Rev 11.0 End
			--Rev 12.0 Start
			,ISNULL(account_holder,'') as account_holder
			,ISNULL(account_no,'') as account_no
			,ISNULL(bank_name,'') as bank_name
			,ISNULL(ifsc,'') as ifsc_code
			,ISNULL(upi_id,'') as upi
			--Rev 12.0 End
			,CASE WHEN ISNULL(convert(varchar(10),shop.assigned_to_shop_id),'')='0' THEN '' ELSE ISNULL(convert(varchar(10),shop.assigned_to_shop_id),'')  END as assigned_to_shop_id,
			--Rev 13.0
			shop.Project_Name AS project_name,shop.Landline_Number AS landline_number,shop.Agency_Name AS agency_name,shop.Lead_Contact_Number AS lead_contact_number,
			--End of Rev 13.0
			--Rev 14.0
			shop.AlternateNoForCustomer AS alternateNoForCustomer,shop.WhatsappNoForCustomer AS whatsappNoForCustomer, 
			--End of Rev 14.0
			--Rev 15.0
			CAST(ISNULL(shop.IsShopDuplicate,0) AS BIT) AS isShopDuplicate, 
			--End of Rev 15.0
			--Rev 16.0
			ISNULL(shop.Purpose,'') AS purpose, 
			--End of Rev 16.0
			--Rev 17.0
			ISNULL(shop.GSTN_Number,'') AS GSTN_Number,ISNULL(shop.ShopOwner_PAN,'') AS ShopOwner_PAN,
			--End of Rev 17.0
			--Rev 19.0
			ISNULL(shop.FSSAILicNo,'') AS FSSAILicNo,CAST(ISNULL(shop.isUpdateAddressFromShopMaster,0) AS BIT) AS isUpdateAddressFromShopMaster, 
			--End of Rev 19.0
			--Rev 20.0
			ISNULL(shop.Shop_FirstName,'') AS shop_firstName,ISNULL(shop.Shop_LastName,'') AS shop_lastName,ISNULL(CRMCOMP.COMPANY_NAME,'') AS crm_companyName,shop.Shop_CRMCompID AS crm_companyID,
			SHOP.Shop_JobTitle AS crm_jobTitle,ISNULL(CRMTYPE.TYPE_NAME,'') AS crm_type,shop.Shop_CRMTypeID AS crm_typeID,shop.Shop_CRMStatusID AS crm_statusID,
			ISNULL(CRMSTAT.STATUS_NAME,'') AS crm_status,ISNULL(CRMSRC.SOURCE_NAME,'') AS crm_source,shop.Shop_CRMSourceID AS crm_sourceID,
			CASE WHEN shop.Shop_CRMReferenceType='SHOP' THEN shop.Shop_Name ELSE ISNULL(CRMCNT.CNT_FIRSTNAME,'')+' '+ISNULL(CRMCNT.CNT_MIDDLENAME,'')+(CASE WHEN ISNULL(CRMCNT.CNT_MIDDLENAME,'')<>'' THEN ' ' ELSE '' END)+ISNULL(CRMCNT.CNT_LASTNAME,'') END AS crm_reference,
			shop.Shop_CRMReferenceID AS crm_referenceID,SHOP.Shop_CRMReferenceType AS crm_referenceID_type,ISNULL(CRMSTAG.STAGE_NAME,'') AS crm_stage,shop.Shop_CRMStageID AS crm_stage_ID,
			usr.user_name AS assign_to,shop.saved_from_status AS saved_from_status 
			--End of Rev 20.0
			from tbl_Master_shop as shop WITH(NOLOCK) 
			INNER JOIN  tbl_master_user usr WITH(NOLOCK) on shop.Shop_CreateUser=usr.user_id 
			INNER JOIN  tbl_shoptype  as typs WITH(NOLOCK) on typs.shop_typeId=shop.type
			LEFT OUTER JOIN FTS_ShopMoreDetails DTLS WITH(NOLOCK) ON DTLS.SHOP_ID=shop.Shop_ID
			LEFT OUTER JOIN FTS_DOCTOR_DETAILS DOCDTLS WITH(NOLOCK) ON DOCDTLS.SHOP_ID=shop.Shop_ID	
			--Rev 20.0
			LEFT OUTER JOIN CRM_CONTACT_COMPANY CRMCOMP WITH(NOLOCK) ON shop.Shop_CRMCompID=CRMCOMP.COMPANY_ID AND CRMCOMP.IsActive=1 
			LEFT OUTER JOIN CRM_CONTACT_TYPE CRMTYPE WITH(NOLOCK) ON shop.Shop_CRMTypeID=CRMTYPE.TYPE_ID AND CRMTYPE.IsActive=1 
			LEFT OUTER JOIN CRM_CONTACT_STATUS CRMSTAT WITH(NOLOCK) ON shop.Shop_CRMStatusID=CRMSTAT.STATUS_ID AND CRMSTAT.IsActive=1 
			LEFT OUTER JOIN CRM_CONTACT_SOURCE CRMSRC WITH(NOLOCK) ON shop.Shop_CRMSourceID=CRMSRC.SOURCE_ID AND CRMSRC.IsActive=1 
			LEFT OUTER JOIN CRM_CONTACT_STAGE CRMSTAG WITH(NOLOCK) ON shop.Shop_CRMStageID=CRMSTAG.STAGE_ID AND CRMSTAG.IsActive=1 
			LEFT OUTER JOIN TBL_MASTER_CONTACT CRMCNT WITH(NOLOCK) ON shop.Shop_CRMReferenceID=CRMCNT.cnt_internalId AND CRMCNT.cnt_contactType='EM' AND SHOP.Shop_CRMReferenceType<>'SHOP'
			--End of Rev 20.0
			--REV 3.0 START
			WHERE usr.user_id=@user_id
			--WHERE usr.user_id IN (SELECT user_id FROM dbo.Get_UserReporthierarchy (@user_id))
			--REV 3.0 END
			--REV 6.0 START
			 AND shop.Entity_Status=1	
			--REV 6.0 END
			order  by Shop_ID  desc
			 --and  SessionToken=@session_token
		END

	SET NOCOUNT OFF
END
GO