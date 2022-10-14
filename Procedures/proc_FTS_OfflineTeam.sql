-- proc_FTS_OfflineTeam @ACTION='ShopList',@UserID='378'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[proc_FTS_OfflineTeam]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [proc_FTS_OfflineTeam] AS' 
END
GO

ALTER PROCEDURE [dbo].[proc_FTS_OfflineTeam]
(
@ACTION VARCHAR(100)=NULL,
@UserID VARCHAR(100)=NULL,
@CITY_ID VARCHAR(100)=NULL,
@Weburl varchar(MAX)=NULL,
@DoctorDegree varchar(MAX)=NULL,
@Date VARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
1.0		v2.0.24		Tanmoy		12/08/2021		@ACTION='MemberList' add active user checking
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF(@ACTION='AreaList')
	BEGIN
		DECLARE @empcodeArea VARCHAR(50)=(select user_contactId from Tbl_master_user WITH(NOLOCK) where user_id=@userid)
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE INTO #EMPHRarea FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
		LEFT JOIN tbl_master_employee TME WITH(NOLOCK) on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL

		;with cte as(select	
		EMPCODE
		from #EMPHRarea 
		where EMPCODE IS NULL OR EMPCODE=@empcodeArea  
		union all
		select	
		a.EMPCODE
		from #EMPHRarea a
		join cte b
		on a.RPTTOEMPCODE = b.EMPCODE
		) 
		select user_id INTO #EMPLOYEELISTarea from cte 
		inner join tbl_master_user TMU WITH(NOLOCK) on cte.EMPCODE=TMU.user_contactId

		DECLARE @STATE_ID BIGINT=0
		DECLARE @USER_IDS BIGINT=0

		SET @STATE_ID=(SELECT state_id FROM tbl_master_city WITH(NOLOCK) WHERE city_id=@CITY_ID)


		--SELECt @USER_IDS
		SELECT CONVERT(VARCHAR(20),area_id) area_id,area_name,ISNULL(user_id,'') user_id FROM(
		SELECT area.area_id,area_name,		
		(select distinct 
			  STUFF((SELECT distinct ', ' + CAST(t1.Shop_CreateUser as VARCHAR(100))
					 from tbl_master_shop t1 WITH(NOLOCK) 
					 where t.[Area_id] = t1.[Area_id] and t.Area_id=area.Area_Id
						FOR XML PATH(''), TYPE
						).value('.', 'NVARCHAR(MAX)') 
					,1,2,'') department 
			from tbl_master_shop t WITH(NOLOCK) where area_id=area.area_id and 
			Shop_CreateUser in (select user_id from #EMPLOYEELISTarea)) user_id
		FROM tbl_master_area area WITH(NOLOCK) 
		WHERE city_id IN (SELECT city_id FROM tbl_master_city WITH(NOLOCK) WHERE state_id=@STATE_ID)

		) TBL WHERE user_id is not null

		drop table #EMPHRarea
		drop table #EMPLOYEELISTarea

	END
	ELSE IF(@ACTION='MemberList')
	BEGIN

		DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user WITH(NOLOCK) where user_id=@userid)
		
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
		CREATE TABLE #EMPLOYEELIST
		(
		USER_ID VARCHAR(50)
		)


		IF(ISNULL(@Date,'')='')
		BEGIN
		INSERT INTO #EMPHR
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
		LEFT JOIN tbl_master_employee TME WITH(NOLOCK) on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
		;with cte as(select	
		EMPCODE
		from #EMPHR 
		where EMPCODE IS NULL OR EMPCODE=@empcode  
		union all
		select	
		a.EMPCODE
		from #EMPHR a
		join cte b
		on a.RPTTOEMPCODE = b.EMPCODE
		) 
		INSERT INTO #EMPLOYEELIST
		select user_id  from cte 
		inner join tbl_master_user TMU WITH(NOLOCK) on cte.EMPCODE=TMU.user_contactId

		SELECT 
		convert(varchar(50),usr.USER_ID) user_id,
		case when usr.user_id=@userid then  usr.user_name +' (Me)' else  usr.user_name end user_name,
		convert(varchar(50),usr.user_loginId) contact_no,
		convert(varchar(50),usr2.USER_ID) super_id,
		usr2.user_name super_name
		FROM tbl_master_user USR WITH(NOLOCK) 
		LEFT JOIN (select distinct usr.user_id reportTo,cnt.emp_cntId from 
		tbl_trans_employeeCTC as cnt WITH(NOLOCK) 
		inner join tbl_master_employee emp WITH(NOLOCK) on emp.emp_id=cnt.emp_reportTo
		left join tbl_master_user usr WITH(NOLOCK) on usr.user_contactId=emp.emp_contactId
		where emp_effectiveuntil is null )N
		on USR.user_contactId= N.emp_cntId
		LEFT JOIN tbl_master_user usr2 WITH(NOLOCK) on usr2.user_id=n.reportTo
		where usr.user_id in (select user_id from #EMPLOYEELIST)
		--Rev 1.0
		and usr.user_inactive='N'
		--End of Rev 1.0
		END
		ELSE
		BEGIN
			INSERT INTO #EMPHR_EDIT
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
			LEFT JOIN tbl_master_employee TME WITH(NOLOCK) on TME.emp_id= CTC.emp_reportTO 
			WHERE emp_effectiveuntil IS NULL 
			AND CAST(ISNULL(CTC.LastModifyDate,CTC.CreateDate) AS DATEtime)>= CAST(@Date AS datetime)
			
			INSERT INTO #EMPHR
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
			LEFT JOIN tbl_master_employee TME WITH(NOLOCK) on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL		
		
			;with cte as(select	
			EMPCODE
			from #EMPHR 
			where EMPCODE IS NULL OR EMPCODE=@empcode  
			union all
			select	
			a.EMPCODE
			from #EMPHR a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 

			INSERT INTO #EMPLOYEELIST
			select user_id  from cte 
			inner join tbl_master_user TMU WITH(NOLOCK) on cte.EMPCODE=TMU.user_contactId
			where cte.EMPCODE in (select EMPCODE from #EMPHR_EDIT)

			SELECT 
			convert(varchar(50),usr.USER_ID) user_id,
			case when usr.user_id=@userid then  usr.user_name +' (Me)' else  usr.user_name end user_name,
			convert(varchar(50),usr.user_loginId) contact_no,
			convert(varchar(50),usr2.USER_ID) super_id,
			usr2.user_name super_name
			FROM tbl_master_user USR WITH(NOLOCK) 		
			LEFT JOIN (select distinct usr.user_id reportTo,cnt.emp_cntId from 
			tbl_trans_employeeCTC as cnt WITH(NOLOCK) 
			inner join tbl_master_employee emp WITH(NOLOCK) on emp.emp_id=cnt.emp_reportTo
			left join tbl_master_user usr WITH(NOLOCK) on usr.user_contactId=emp.emp_contactId
			where emp_effectiveuntil is null )N
			on USR.user_contactId= N.emp_cntId
			LEFT JOIN tbl_master_user usr2 WITH(NOLOCK) on usr2.user_id=n.reportTo
			where usr.user_id in (select user_id from #EMPLOYEELIST)
			--Rev 1.0
			and usr.user_inactive='N'
			--End of Rev 1.0
	END		
		
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHR
		DROP TABLE #EMPLOYEELIST

	END
	ELSE IF(@ACTION='ShopList')
	BEGIN

		DECLARE @empcodeSHop VARCHAR(50)=(select user_contactId from Tbl_master_user WITH(NOLOCK) where user_id=@userid)
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE INTO #EMPHRSHOP FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
		LEFT JOIN tbl_master_employee TME WITH(NOLOCK) on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL

		;with cte as(select	
		EMPCODE
		from #EMPHRSHOP 
		where  EMPCODE=@empcodeSHop  
		union all
		select	
		a.EMPCODE
		from #EMPHRSHOP a
		join cte b
		on a.RPTTOEMPCODE = b.EMPCODE
		) 
		select user_id INTO #EMPLOYEELISTSHOP from cte 
		inner join tbl_master_user TMU WITH(NOLOCK) on cte.EMPCODE=TMU.user_contactId
			
		IF(ISNULL(@Date,'')='')
			--select  cast(shop.Shop_ID as varchar(50))	as shop_Auto ,shop.Shop_Code as shop_id,	
			--shop.Shop_Name as shop_name,
			--Address as [shop_address],shop.Pincode as shop_pincode,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name
			--,Shop_WebSite,Shop_Owner_Email as owner_email	,Shop_Owner_Contact as shop_contact
			--,Shop_CreateUser,Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,@Weburl+Shop_Image as Shop_Image
			--,dob,date_aniversary,cast(typs.shop_typeId as varchar(50)) as shop_type,shop.type,total_visitcount as total_visit_count
			--,Lastvisit_date as last_visit_date,isAddressUpdated,isnull(assigned_to_pp_id,'') as assign_to_pp_id
			--,isnull(assigned_to_dd_id,'') as assign_to_dd_id,cast(isnull(VerifiedOTP,0) as bit) as is_otp_verified
			--,isnull(shop.Amount,0) as amount,DTLS.FamilyMember_DOB as family_member_dob,DTLS.Addtional_DOB as addtional_dob,
			--DTLS.Addtional_DOA as addtional_doa,isnull(DTLS.Director_Name,'') as director_name,isnull(DTLS.KeyPerson_Name,'') as key_person_name,
			--isnull(DTLS.phone_no,'') as phone_no,
			--DOCDTLS.FAMILY_MEMBER_DOB AS doc_family_member_dob,DOCDTLS.SPECIALIZATION AS specialization,DOCDTLS.AVG_PATIENT_PER_DAY AS average_patient_per_day,
			--DOCDTLS.CATEGORY AS category,DOCDTLS.DOC_ADDRESS AS doc_address,DOCDTLS.PINCODE AS doc_pincode,@DoctorDegree+DOCDTLS.DEGREE AS degree,
			--CASE WHEN DOCDTLS.IsChamberSameHeadquarter=1 THEN '1' ELSE '0' END AS is_chamber_same_headquarter,DOCDTLS.Remarks AS is_chamber_same_headquarter_remarks,
			--DOCDTLS.CHEMIST_NAME AS chemist_name,DOCDTLS.CHEMIST_ADDRESS AS chemist_address,DOCDTLS.CHEMIST_PINCODE AS chemist_pincode,
			--DOCDTLS.ASSISTANT_NAME AS assistant_name,DOCDTLS.ASSISTANT_CONTACT_NO AS assistant_contact_no,DOCDTLS.ASSISTANT_DOB AS assistant_dob,
			--DOCDTLS.ASSISTANT_DOA AS assistant_doa,DOCDTLS.ASSISTANT_FAMILY_DOB AS assistant_family_dob,shop.EntityCode as entity_code,
			--convert(nvarchar(10),shop.Area_id) as area_id
			----Rev 7.0 Start
			--,convert(nvarchar(10),shop.Model_id) as model_id,convert(nvarchar(10),shop.Primary_id) as primary_app_id,convert(nvarchar(10),shop.Secondary_id) as secondary_app_id
			--,convert(nvarchar(10),shop.Lead_id) as lead_id,convert(nvarchar(10),shop.FunnelStage_id) as funnel_stage_id,convert(nvarchar(10),shop.Stage_id) as stage_id,shop.Booking_amount
			----Rev 7.0 End
			----Rev 8.0 Start
			--,convert(nvarchar(10),shop.PartyType_id) as type_id,CONVERT(VARCHAR(50),Shop_CreateUser) user_id
			--,ISNULL(dd_shop.Shop_Name,'') as dd_name,shop.total_visitcount total_visited
			----Rev 8.0 End
			--from tbl_Master_shop as shop
			--INNER JOIN  tbl_master_user  usr on shop.Shop_CreateUser=usr.user_id 
			--INNER JOIN  tbl_shoptype  as typs on typs.shop_typeId=shop.type
			--LEFT OUTER JOIN FTS_ShopMoreDetails DTLS ON DTLS.SHOP_ID=shop.Shop_ID
			--LEFT OUTER JOIN FTS_DOCTOR_DETAILS DOCDTLS ON DOCDTLS.SHOP_ID=shop.Shop_ID	
			--LEFT JOIN (select Shop_Code,shop_name from tbl_Master_shop) dd_shop on dd_shop.Shop_Code=shop.assigned_to_dd_id

			--WHERE  shop.Shop_Code='378_1578494646142'
			-- AND shop.Entity_Status=1 

			-- UNION

			select  cast(shop.Shop_ID as varchar(50))	as shop_Auto ,shop.Shop_Code as shop_id,	
			shop.Shop_Name as shop_name,
			Address as [shop_address],shop.Pincode as shop_pincode,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name
			,Shop_WebSite,Shop_Owner_Email as owner_email	,Shop_Owner_Contact as shop_contact
			,Shop_CreateUser,Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,@Weburl+Shop_Image as Shop_Image
			,dob,date_aniversary,cast(typs.shop_typeId as varchar(50)) as shop_type,shop.type,total_visitcount as total_visit_count
			,CONVERT(VARCHAR(10), ISNULL(Lastvisit_date,GETDATE()), 120)  as last_visit_date,isAddressUpdated,isnull(assigned_to_pp_id,'') as assign_to_pp_id
			,isnull(assigned_to_dd_id,'') as assign_to_dd_id,cast(isnull(VerifiedOTP,0) as bit) as is_otp_verified
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
			,convert(nvarchar(10),shop.PartyType_id) as type_id,CONVERT(VARCHAR(50),Shop_CreateUser) user_id
			,ISNULL(dd_shop.Shop_Name,'') as dd_name,shop.total_visitcount total_visited
			--Rev 8.0 End
			from tbl_Master_shop as shop WITH(NOLOCK) 
			INNER JOIN  tbl_master_user  usr WITH(NOLOCK) on shop.Shop_CreateUser=usr.user_id 
			INNER JOIN  tbl_shoptype  as typs WITH(NOLOCK) on typs.shop_typeId=shop.type
			LEFT OUTER JOIN FTS_ShopMoreDetails DTLS WITH(NOLOCK) ON DTLS.SHOP_ID=shop.Shop_ID
			LEFT OUTER JOIN FTS_DOCTOR_DETAILS DOCDTLS WITH(NOLOCK) ON DOCDTLS.SHOP_ID=shop.Shop_ID	
			LEFT JOIN (select Shop_Code,shop_name from tbl_Master_shop WITH(NOLOCK)) dd_shop on dd_shop.Shop_Code=shop.assigned_to_dd_id
			WHERE usr.user_id in (select user_id from #EMPLOYEELISTSHOP)
			 AND shop.Entity_Status=1	--and shop.Shop_Code='12201_1597939946987'
			order  by Shop_ID  desc
		ELSE
			select  cast(shop.Shop_ID as varchar(50))	as shop_Auto ,shop.Shop_Code as shop_id,shop.Shop_Name as shop_name,
			Address as [shop_address],shop.Pincode as shop_pincode,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name
			,Shop_WebSite,Shop_Owner_Email as owner_email	,Shop_Owner_Contact as shop_contact
			,Shop_CreateUser,Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,@Weburl+Shop_Image as Shop_Image
			,dob,date_aniversary,cast(typs.shop_typeId as varchar(50)) as shop_type,shop.type,total_visitcount as total_visit_count
			,CONVERT(VARCHAR(10), ISNULL(Lastvisit_date,GETDATE()), 120)  as last_visit_date,isAddressUpdated,isnull(assigned_to_pp_id,'') as assign_to_pp_id
			,isnull(assigned_to_dd_id,'') as assign_to_dd_id,cast(isnull(VerifiedOTP,0) as bit) as is_otp_verified
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
			,convert(nvarchar(10),shop.PartyType_id) as type_id,CONVERT(VARCHAR(50),Shop_CreateUser) user_id
			,ISNULL(dd_shop.Shop_Name,'') as dd_name,shop.total_visitcount total_visited
			--Rev 8.0 End
			from tbl_Master_shop as shop WITH(NOLOCK) 
			INNER JOIN  tbl_master_user  usr WITH(NOLOCK) on shop.Shop_CreateUser=usr.user_id 
			INNER JOIN  tbl_shoptype  as typs WITH(NOLOCK) on typs.shop_typeId=shop.type
			LEFT OUTER JOIN FTS_ShopMoreDetails DTLS WITH(NOLOCK) ON DTLS.SHOP_ID=shop.Shop_ID
			LEFT OUTER JOIN FTS_DOCTOR_DETAILS DOCDTLS WITH(NOLOCK) ON DOCDTLS.SHOP_ID=shop.Shop_ID	
			LEFT JOIN (select Shop_Code,shop_name from tbl_Master_shop WITH(NOLOCK)) dd_shop on dd_shop.Shop_Code=shop.assigned_to_dd_id
			WHERE usr.user_id in (select user_id from #EMPLOYEELISTSHOP)
			 AND shop.Entity_Status=1 and CAST(ISNULL(Shop_ModifyTime,Shop_CreateTime) as datetime)>=cast(@Date as datetime)
			order  by Shop_ID  desc

			DROP TABLE #EMPHRSHOP
			DROP TABLE #EMPLOYEELISTSHOP
	END

	SET NOCOUNT OFF
END