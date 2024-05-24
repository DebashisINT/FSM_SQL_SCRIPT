IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EmployeeDeleteBySelctName]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [EmployeeDeleteBySelctName] AS' 
END
GO

ALTER PROCEDURE [dbo].[EmployeeDeleteBySelctName]
@cnt_internalId  varchar(50),
@userID int =null
AS
/******************************************************************************************************************************************
1.0		Sanchita		v2.0.26					Three Master Modules required under Master > Other Masters - Channel. Section, Circle. Refer: 24646
2.0		PRITI           V2.0.47     13-05-2024   0027425: At the time of any Employee creation, the branch ID shall be updated in employee branch mapping table
*****************************************************************************************************************************************/
BEGIN
--declare @cnt_internalId varchar(50)
--SET @cnt_internalId=''
--select @cnt_internalId=ISNULL(cnt_internalId,'') from tbl_master_contact where cnt_id=@cnt_id

IF(@cnt_internalId <> '')
	BEGIN
		--set @cnt_internalId='1'
		/*CONTACT--------------*/
			--print '1'
			insert into tbl_master_contact_Log(cnt_id, cnt_internalId, cnt_branchid, cnt_accessLevel, cnt_addDate, cnt_modUserId, cnt_modDate, cnt_UCC, cnt_salutation, cnt_firstName, cnt_middleName, cnt_lastName, cnt_shortName, cnt_contactSource, cnt_contactType, cnt_legalStatus, cnt_referedBy, cnt_relation, cnt_contactStatus, cnt_speakLanguage, cnt_writeLanguage, cnt_dOB, cnt_maritalStatus, cnt_anniversaryDate, cnt_education, cnt_profession, cnt_jobResponsibility, cnt_organization, cnt_industry, cnt_designation, cnt_preferedContact, cnt_sex, cnt_UserAccess, cnt_RelationshipManager, cnt_salesRepresentative, CreateDate, CreateUser, LastModifyDate, LastModifyUser, cnt_LeadId, cnt_RegistrationDate, cnt_rating, cnt_reason, cnt_status, cnt_Lead_Stage, cnt_bloodgroup, WebLogIn, PassWord, LogModifyDate, LogModifyUser, LogStatus)
			select cnt_id, cnt_internalId, cnt_branchid, cnt_accessLevel, cnt_addDate, cnt_modUserId, cnt_modDate, cnt_UCC, cnt_salutation, cnt_firstName, cnt_middleName, cnt_lastName, cnt_shortName, cnt_contactSource, cnt_contactType, cnt_legalStatus, cnt_referedBy, cnt_relation, cnt_contactStatus, cnt_speakLanguage, cnt_writeLanguage, cnt_dOB, cnt_maritalStatus, cnt_anniversaryDate, cnt_education, cnt_profession, cnt_jobResponsibility, cnt_organization, cnt_industry, cnt_designation, cnt_preferedContact, cnt_sex, cnt_UserAccess, cnt_RelationshipManager, cnt_salesRepresentative, CreateDate, CreateUser, LastModifyDate, LastModifyUser, cnt_LeadId, cnt_RegistrationDate, cnt_rating, cnt_reason, cnt_status, cnt_Lead_Stage, cnt_bloodgroup, WebLogIn, PassWord,getdate(),@userId,'D' from tbl_master_contact where cnt_internalId=@cnt_internalId
			DELETE from	tbl_master_contact WHERE cnt_internalId=@cnt_internalId
		/*EMPLOYEE-------------*/
			--print '2'
			insert into tbl_master_employee_Log(emp_id, emp_uniqueCode, emp_contactId, emp_dateofJoining, emp_dateofLeaving, emp_replaceUser, emp_previousEmployer1, emp_AddressPrevEmployer1, emp_PANNoPrevEmployer1, emp_PreviousDesignation1, emp_JobResponsibility1, emp_joinpreviousEmployer1, emp_toPreviousEmployer1, emp_previousCTC1, emp_PreviousTaxableIncome1, emp_TDSPrevEmployer1, emp_previousEmployer2, emp_AddPrevEmployer2, emp_PANNoPrevEmployer2, emp_PreviousDesignation2, emp_JobResponsibility2, emp_joinpreviousEmployer2, emp_toPreviousEmployer2, emp_PreviousCTC2, emp_PreviousTaxableIncome2, emp_TDSPrevEmployer2, emp_ReasonLeaving, emp_NextEmployer, emp_AddNextEmployer, CreateDate, CreateUser, LastModifyDate, LastModifyUser, emp_din, emp_Replacement, emp_RepDate,emp_ReplacingTO, LogModifyDate, LogModifyUser, LogStatus)
			select emp_id, emp_uniqueCode, emp_contactId, emp_dateofJoining, emp_dateofLeaving, emp_replaceUser, emp_previousEmployer1, emp_AddressPrevEmployer1, emp_PANNoPrevEmployer1, emp_PreviousDesignation1, emp_JobResponsibility1, emp_joinpreviousEmployer1, emp_toPreviousEmployer1, emp_previousCTC1, emp_PreviousTaxableIncome1, emp_TDSPrevEmployer1, emp_previousEmployer2, emp_AddPrevEmployer2, emp_PANNoPrevEmployer2, emp_PreviousDesignation2, emp_JobResponsibility2, emp_joinpreviousEmployer2, emp_toPreviousEmployer2, emp_PreviousCTC2, emp_PreviousTaxableIncome2, emp_TDSPrevEmployer2, emp_ReasonLeaving, emp_NextEmployer, emp_AddNextEmployer, CreateDate, CreateUser, LastModifyDate, LastModifyUser, emp_din, emp_Replacement, emp_RepDate,emp_ReplacingTO,getdate(),@userId,'D' from tbl_master_employee where emp_contactId=@cnt_internalId
			DELETE from tbl_master_employee where emp_contactId=@cnt_internalId 
		/*ADDRESS--------------*/
			INSERT INTO  tbl_master_address_Log	(add_id, add_cntId, add_entity, add_addressType, add_address1, add_address2, add_address3, add_landMark, add_country, add_state, add_city, add_area, add_pin, add_activityId, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,add_status,add_StatusChangeDate,add_statusChangeReason, LogModifyDate, LogModifyUser, LogStatus)
			select add_id, add_cntId, add_entity, add_addressType, add_address1, add_address2, add_address3, add_landMark, add_country, add_state, add_city, add_area, add_pin, add_activityId, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,add_status,add_StatusChangeDate,add_statusChangeReason,getdate(),@userId,'D' from tbl_master_address where add_cntId=@cnt_internalId
			DELETE FROM tbl_master_address where add_cntId=@cnt_internalId
		/*PHONEFAX-------------*/
			INSERT INTO tbl_master_phonefax_Log (phf_id, phf_cntId, phf_entity, phf_type, phf_countryCode, phf_areaCode, phf_phoneNumber, phf_faxNumber, phf_extension, phf_Availablefrom, phf_AvailableTo, phf_SMSFacility, phf_IsDefault, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,phf_Status,phf_StatusChangeDate,phf_StatusChangeReason, LogModifyDate, LogModifyUser, LogStatus)
			SELECT phf_id, phf_cntId, phf_entity, phf_type, phf_countryCode, phf_areaCode, phf_phoneNumber, phf_faxNumber, phf_extension, phf_Availablefrom, phf_AvailableTo, phf_SMSFacility, phf_IsDefault, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,phf_Status,phf_StatusChangeDate,phf_StatusChangeReason,getdate(),@userId,'D' FROM tbl_master_phonefax WHERE phf_cntId=@cnt_internalId
			DELETE FROM tbl_master_phonefax WHERE phf_cntId=@cnt_internalId
		/*EMAIL----------------*/
		Select * from tbl_master_email
			INSERT INTO tbl_master_email_Log (eml_id, eml_internalId, eml_entity, eml_cntId, eml_type, eml_email, eml_ccEmail, eml_website, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,eml_status,eml_StatusChangeDate,eml_StatusChangeReason,eml_facility,LogModifyDate, LogModifyUser, LogStatus)
			SELECT eml_id, eml_internalId, eml_entity, eml_cntId, eml_type, eml_email, eml_ccEmail, eml_website, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,eml_status,eml_StatusChangeDate,eml_StatusChangeReason,eml_facility,getdate(),@userId,'D' FROM tbl_master_email WHERE eml_cntId=@cnt_internalId
			DELETE FROM tbl_master_email_Log WHERE eml_cntId=@cnt_internalId
		/*EDUCATION------------*/
			INSERT INTO tbl_master_educationProfessional_Log(edu_id, edu_internalId, edu_degree, edu_instName, edu_country, edu_state, edu_city, edu_courseFrom, edu_courseuntil, edu_courseResult, edu_percentage, edu_grade, edu_month_year, createuser, createdate, lastmodifyuser, lastmodifydate, LogModifyDate, LogModifyUser, LogStatus)
			SELECT edu_id, edu_internalId, edu_degree, edu_instName, edu_country, edu_state, edu_city, edu_courseFrom, edu_courseuntil, edu_courseResult, edu_percentage, edu_grade, edu_month_year, createuser, createdate, lastmodifyuser, lastmodifydate,getdate(),@userId,'D' FROM tbl_master_educationProfessional WHERE edu_internalId=@cnt_internalId
			DELETE FROM tbl_master_educationProfessional WHERE edu_internalId=@cnt_internalId 
		/*CONTACTEXCHANGE------*/
			INSERT INTO tbl_master_contactExchange_Log(crg_internalId, crg_cntID, crg_company, crg_exchange, crg_tcode, crg_regisDate, crg_businessCmmDate, crg_suspensionDate, crg_reasonforSuspension, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
			SELECT crg_internalId ,crg_cntID,crg_company  , crg_exchange,crg_tcode,crg_regisDate,  crg_businessCmmDate , crg_suspensionDate ,  crg_reasonforSuspension,CreateDate ,CreateUser,LastModifyDate,   LastModifyUser ,getdate(),@userId,'D' FROM tbl_master_contactExchange WHERE crg_cntID=@cnt_internalId
			DELETE FROM tbl_master_contactExchange WHERE crg_cntID=@cnt_internalId
		/*EMPLOYEE CTC---------*/
			INSERT INTO tbl_trans_employeeCTC_Log(emp_id, emp_cntId, emp_effectiveDate, emp_effectiveuntil, emp_Organization, emp_JobResponsibility, emp_Designation, emp_type, emp_Department, emp_reportTo, emp_deputy, emp_colleague, emp_workinghours, emp_currentCTC, emp_basic, emp_HRA, emp_CCA, emp_spAllowance, emp_childrenAllowance, emp_totalLeavePA, emp_PF, emp_medicalAllowance, emp_LTA, emp_convence, emp_mobilePhoneExp, emp_totalMedicalLeavePA, CreateDate, CreateUser, LastModifyDate, LastModifyUser, emp_LeaveSchemeAppliedFrom, emp_branch, LogModifyDate, LogModifyUser, LogStatus)
			select emp_id, emp_cntId, emp_effectiveDate, emp_effectiveuntil, emp_Organization, emp_JobResponsibility, emp_Designation, emp_type, emp_Department, emp_reportTo, emp_deputy, emp_colleague, emp_workinghours, emp_currentCTC, emp_basic, emp_HRA, emp_CCA, emp_spAllowance, emp_childrenAllowance, emp_totalLeavePA, emp_PF, emp_medicalAllowance, emp_LTA, emp_convence, emp_mobilePhoneExp, emp_totalMedicalLeavePA, CreateDate, CreateUser, LastModifyDate, LastModifyUser, emp_LeaveSchemeAppliedFrom, emp_branch,getdate(),@userId,'D' from tbl_trans_employeeCTC where emp_cntId=@cnt_internalId
			DELETE FROM tbl_trans_employeeCTC where emp_cntId=@cnt_internalId
		/*GROUP DETAILS--------*/
			INSERT INTO tbl_trans_group_Log(grp_id, grp_contactId, grp_groupMaster, grp_groupType, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
			SELECT grp_id, grp_contactId, grp_groupMaster, grp_groupType, CreateDate, CreateUser, LastModifyDate, LastModifyUser,getdate(),@userId,'D' FROM tbl_trans_group WHERE grp_contactId=@cnt_internalId
			DELETE FROM tbl_trans_group WHERE grp_contactId=@cnt_internalId
		/*DOCUMENT DETAILS-----*/
		/* document log commented because 	tbl_master_document_Log does not exists  Name: Debjyoti Date:07-12-2016*/
			--INSERT INTO tbl_master_document_Log(doc_id, doc_contactId, doc_documentTypeId, doc_documentName, doc_source, doc_buildingId, doc_Floor, doc_RoomNo, doc_CellNo, doc_FileNo, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
											--SELECT doc_id, doc_contactId, doc_documentTypeId, doc_documentName, doc_source, doc_buildingId, doc_Floor, doc_RoomNo, doc_CellNo, doc_FileNo, CreateDate, CreateUser, LastModifyDate, LastModifyUser,getdate(),@userId,'D' FROM tbl_master_document WHERE doc_contactId=@cnt_internalId
--select doc_id, doc_contactId, doc_documentTypeId, doc_documentName, doc_source, doc_buildingId, doc_Floor, doc_RoomNo, doc_CellNo, doc_FileNo, CreateDate, CreateUser, LastModifyDate, LastModifyUser from  tbl_master_document
			DELETE FROM tbl_master_document WHERE doc_contactId=@cnt_internalId
		/*DP DETAILS-----------*/
			INSERT INTO tbl_master_contactDPDetails_Log(dpd_id, dpd_cntId, dpd_accountType, dpd_dpCode, dpd_ClientId, dpd_POA, dpd_POAName, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
			select dpd_id, dpd_cntId, dpd_accountType, dpd_dpCode, dpd_ClientId, dpd_POA, dpd_POAName, CreateDate, CreateUser, LastModifyDate, LastModifyUser,getdate(),@userId,'D' from tbl_master_contactDPDetails where dpd_cntId=@cnt_internalId
			DELETE FROM tbl_master_contactDPDetails_Log where dpd_cntId=@cnt_internalId
		/*REMARKS DETAILS------*/
			INSERT INTO  tbl_master_contactRemarks_Log (id, rea_internalId, cat_id, rea_Remarks, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
			SELECT id, rea_internalId, cat_id, rea_Remarks, CreateDate, CreateUser, LastModifyDate, LastModifyUser,getdate(),@userId,'D' FROM tbl_master_contactRemarks WHERE rea_internalId=@cnt_internalId
			DELETE  FROM tbl_master_contactRemarks WHERE rea_internalId=@cnt_internalId
		/*HISTORY LOG----------*/
			INSERT INTO tbl_master_EmploymentHistory_Log(emp_id, emp_InternalId, emp_employerName, emp_employerAddress, emp_employerPhone, emp_employerFax, emp_employerEmail, emp_employerPan, emp_employerFrm, emp_employerTo, emp_jobResponsibility, emp_designation, emp_department, emp_ctc, emp_taxIncome, emp_tds, CreateUser, CreateDate, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
			SELECT emp_id, emp_InternalId, emp_employerName, emp_employerAddress, emp_employerPhone, emp_employerFax, emp_employerEmail, emp_employerPan, emp_employerFrm, emp_employerTo, emp_jobResponsibility, emp_designation, emp_department, emp_ctc, emp_taxIncome, emp_tds, CreateUser, CreateDate, LastModifyDate, LastModifyUser,getdate(),@userId,'D' FROM tbl_master_EmploymentHistory WHERE emp_InternalId=@cnt_internalId
			DELETE FROM tbl_master_EmploymentHistory WHERE emp_InternalId=@cnt_internalId
		/*CONATCT RELATIONSHIP-*/
			INSERT INTO tbl_master_contactFamilyRelationship_Log(femrel_id, femrel_cntId, femrel_contactType, femrel_memberName, femrel_relationId, femrel_DOB, femrel_bloodGroup, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
			SELECT femrel_id, femrel_cntId, femrel_contactType, femrel_memberName, femrel_relationId, femrel_DOB, femrel_bloodGroup, CreateDate, CreateUser, LastModifyDate, LastModifyUser,getdate(),@userId,'D' FROM tbl_master_contactFamilyRelationship WHERE femrel_cntId=@cnt_internalId
			DELETE FROM tbl_master_contactFamilyRelationship WHERE femrel_cntId=@cnt_internalId
		/*Bank Details---------*/
			INSERT INTO tbl_trans_contactBankDetails_Log(cbd_id, cbd_accountCategory, cbd_cntId, cbd_contactType, cbd_bankCode, cbd_accountNumber, cbd_accountType, cbd_accountName, CreateDate, CreateUser, LastModifyDate, LastModifyUser,cbd_Status,cbd_StatucChangeDate,cbd_StatusChangeReason,LogModifyDate, LogModifyUser, LogStatus)
			SELECT cbd_id, cbd_accountCategory, cbd_cntId, cbd_contactType, cbd_bankCode, cbd_accountNumber, cbd_accountType, cbd_accountName, CreateDate, CreateUser, LastModifyDate, LastModifyUser,cbd_Status,cbd_StatucChangeDate,cbd_StatusChangeReason,getdate(),@userId,'D' FROM tbl_trans_contactBankDetails WHERE cbd_cntId=@cnt_internalId
			DELETE FROM tbl_trans_contactBankDetails WHERE cbd_cntId=@cnt_internalId
		/*Registration----------*/
			INSERT INTO tbl_master_contactMembership_Log(crg_internalid, crg_cntId, crg_idprof, crg_memNumber, crg_memtype, crg_validityType, crg_memExpDate, crg_notes, CreateUser, CreateDate, LastModifyUser, LastModifyDate, LogModifyDate, LogModifyUser, LogStatus)
			SELECT crg_internalid, crg_cntId, crg_idprof, crg_memNumber, crg_memtype, crg_validityType, crg_memExpDate, crg_notes, CreateUser, CreateDate, LastModifyUser, LastModifyDate,getdate(),@userId,'D' FROM tbl_master_contactMembership WHERE crg_cntId=@cnt_internalId
						
			delete from tbl_master_contactMembership_Log WHERE crg_cntId=@cnt_internalId
			delete from tbl_master_contactRegistration_Log where crg_cntId=@cnt_internalId

			-- Rev 1.0
			delete from Employee_ChannelMap where EP_EMP_CONTACTID=@cnt_internalId
			delete from Employee_CircleMap where EP_EMP_CONTACTID=@cnt_internalId
			delete from Employee_SectionMap where EP_EMP_CONTACTID=@cnt_internalId
			-- End of Rev 1.0

			--REV 2.0
			DELETE FROM FTS_EmployeeBranchMap WHERE Emp_Contactid=@cnt_internalId
			--REV 2.0 END
	END
END






-- Last Modified Date :07-12-2016
-- Name: Devjyoti 
-- Reason : 
-- Back up bellow


--alter PROCEDURE [dbo].[EmployeeDeleteBySelctName]
--@cnt_internalId  varchar(50),
--@userID int =null
--AS
--BEGIN
----declare @cnt_internalId varchar(50)
----SET @cnt_internalId=''
----select @cnt_internalId=ISNULL(cnt_internalId,'') from tbl_master_contact where cnt_id=@cnt_id

--IF(@cnt_internalId <> '')
--	BEGIN
--		--set @cnt_internalId='1'
--		/*CONTACT--------------*/
--			print '1'
--			insert into tbl_master_contact_Log(cnt_id, cnt_internalId, cnt_branchid, cnt_accessLevel, cnt_addDate, cnt_modUserId, cnt_modDate, cnt_UCC, cnt_salutation, cnt_firstName, cnt_middleName, cnt_lastName, cnt_shortName, cnt_contactSource, cnt_contactType, cnt_legalStatus, cnt_referedBy, cnt_relation, cnt_contactStatus, cnt_speakLanguage, cnt_writeLanguage, cnt_dOB, cnt_maritalStatus, cnt_anniversaryDate, cnt_education, cnt_profession, cnt_jobResponsibility, cnt_organization, cnt_industry, cnt_designation, cnt_preferedContact, cnt_sex, cnt_UserAccess, cnt_RelationshipManager, cnt_salesRepresentative, CreateDate, CreateUser, LastModifyDate, LastModifyUser, cnt_LeadId, cnt_RegistrationDate, cnt_rating, cnt_reason, cnt_status, cnt_Lead_Stage, cnt_bloodgroup, WebLogIn, PassWord, LogModifyDate, LogModifyUser, LogStatus)
--			select cnt_id, cnt_internalId, cnt_branchid, cnt_accessLevel, cnt_addDate, cnt_modUserId, cnt_modDate, cnt_UCC, cnt_salutation, cnt_firstName, cnt_middleName, cnt_lastName, cnt_shortName, cnt_contactSource, cnt_contactType, cnt_legalStatus, cnt_referedBy, cnt_relation, cnt_contactStatus, cnt_speakLanguage, cnt_writeLanguage, cnt_dOB, cnt_maritalStatus, cnt_anniversaryDate, cnt_education, cnt_profession, cnt_jobResponsibility, cnt_organization, cnt_industry, cnt_designation, cnt_preferedContact, cnt_sex, cnt_UserAccess, cnt_RelationshipManager, cnt_salesRepresentative, CreateDate, CreateUser, LastModifyDate, LastModifyUser, cnt_LeadId, cnt_RegistrationDate, cnt_rating, cnt_reason, cnt_status, cnt_Lead_Stage, cnt_bloodgroup, WebLogIn, PassWord,getdate(),@userId,'D' from tbl_master_contact where cnt_internalId=@cnt_internalId
--			DELETE from	tbl_master_contact WHERE cnt_internalId=@cnt_internalId
--		/*EMPLOYEE-------------*/
--			print '2'
--			insert into tbl_master_employee_Log(emp_id, emp_uniqueCode, emp_contactId, emp_dateofJoining, emp_dateofLeaving, emp_replaceUser, emp_previousEmployer1, emp_AddressPrevEmployer1, emp_PANNoPrevEmployer1, emp_PreviousDesignation1, emp_JobResponsibility1, emp_joinpreviousEmployer1, emp_toPreviousEmployer1, emp_previousCTC1, emp_PreviousTaxableIncome1, emp_TDSPrevEmployer1, emp_previousEmployer2, emp_AddPrevEmployer2, emp_PANNoPrevEmployer2, emp_PreviousDesignation2, emp_JobResponsibility2, emp_joinpreviousEmployer2, emp_toPreviousEmployer2, emp_PreviousCTC2, emp_PreviousTaxableIncome2, emp_TDSPrevEmployer2, emp_ReasonLeaving, emp_NextEmployer, emp_AddNextEmployer, CreateDate, CreateUser, LastModifyDate, LastModifyUser, emp_din, emp_Replacement, emp_RepDate,emp_ReplacingTO, LogModifyDate, LogModifyUser, LogStatus)
--			select *,getdate(),@userId,'D' from tbl_master_employee where emp_contactId=@cnt_internalId
--			DELETE from tbl_master_employee where emp_contactId=@cnt_internalId 
--		/*ADDRESS--------------*/
--			INSERT INTO  tbl_master_address_Log	(add_id, add_cntId, add_entity, add_addressType, add_address1, add_address2, add_address3, add_landMark, add_country, add_state, add_city, add_area, add_pin, add_activityId, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,add_status,add_StatusChangeDate,add_statusChangeReason, LogModifyDate, LogModifyUser, LogStatus)
--			select *,getdate(),@userId,'D' from tbl_master_address where add_cntId=@cnt_internalId
--			DELETE FROM tbl_master_address where add_cntId=@cnt_internalId
--		/*PHONEFAX-------------*/
--			INSERT INTO tbl_master_phonefax_Log (phf_id, phf_cntId, phf_entity, phf_type, phf_countryCode, phf_areaCode, phf_phoneNumber, phf_faxNumber, phf_extension, phf_Availablefrom, phf_AvailableTo, phf_SMSFacility, phf_IsDefault, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,phf_Status,phf_StatusChangeDate,phf_StatusChangeReason, LogModifyDate, LogModifyUser, LogStatus)
--			SELECT *,getdate(),@userId,'D' FROM tbl_master_phonefax WHERE phf_cntId=@cnt_internalId
--			DELETE FROM tbl_master_phonefax WHERE phf_cntId=@cnt_internalId
--		/*EMAIL----------------*/
--		Select * from tbl_master_email
--			INSERT INTO tbl_master_email_Log (eml_id, eml_internalId, eml_entity, eml_cntId, eml_type, eml_email, eml_ccEmail, eml_website, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST,eml_status,eml_StatusChangeDate,eml_StatusChangeReason,eml_facility,LogModifyDate, LogModifyUser, LogStatus)
--			SELECT *,getdate(),@userId,'D' FROM tbl_master_email WHERE eml_cntId=@cnt_internalId
--			DELETE FROM tbl_master_email_Log WHERE eml_cntId=@cnt_internalId
--		/*EDUCATION------------*/
--			INSERT INTO tbl_master_educationProfessional_Log(edu_id, edu_internalId, edu_degree, edu_instName, edu_country, edu_state, edu_city, edu_courseFrom, edu_courseuntil, edu_courseResult, edu_percentage, edu_grade, edu_month_year, createuser, createdate, lastmodifyuser, lastmodifydate, LogModifyDate, LogModifyUser, LogStatus)
--			SELECT *,getdate(),@userId,'D' FROM tbl_master_educationProfessional WHERE edu_internalId=@cnt_internalId
--			DELETE FROM tbl_master_educationProfessional WHERE edu_internalId=@cnt_internalId 
--		/*CONTACTEXCHANGE------*/
--			INSERT INTO tbl_master_contactExchange_Log(crg_internalId, crg_cntID, crg_company, crg_exchange, crg_tcode, crg_regisDate, crg_businessCmmDate, crg_suspensionDate, crg_reasonforSuspension, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
--			SELECT crg_internalId ,crg_cntID,crg_company  , crg_exchange,crg_tcode,crg_regisDate,  crg_businessCmmDate , crg_suspensionDate ,  crg_reasonforSuspension,CreateDate ,CreateUser,LastModifyDate,   LastModifyUser ,getdate(),@userId,'D' FROM tbl_master_contactExchange WHERE crg_cntID=@cnt_internalId
--			DELETE FROM tbl_master_contactExchange WHERE crg_cntID=@cnt_internalId
--		/*EMPLOYEE CTC---------*/
--			INSERT INTO tbl_trans_employeeCTC_Log(emp_id, emp_cntId, emp_effectiveDate, emp_effectiveuntil, emp_Organization, emp_JobResponsibility, emp_Designation, emp_type, emp_Department, emp_reportTo, emp_deputy, emp_colleague, emp_workinghours, emp_currentCTC, emp_basic, emp_HRA, emp_CCA, emp_spAllowance, emp_childrenAllowance, emp_totalLeavePA, emp_PF, emp_medicalAllowance, emp_LTA, emp_convence, emp_mobilePhoneExp, emp_totalMedicalLeavePA, CreateDate, CreateUser, LastModifyDate, LastModifyUser, emp_LeaveSchemeAppliedFrom, emp_branch, LogModifyDate, LogModifyUser, LogStatus)
--			select emp_id, emp_cntId, emp_effectiveDate, emp_effectiveuntil, emp_Organization, emp_JobResponsibility, emp_Designation, emp_type, emp_Department, emp_reportTo, emp_deputy, emp_colleague, emp_workinghours, emp_currentCTC, emp_basic, emp_HRA, emp_CCA, emp_spAllowance, emp_childrenAllowance, emp_totalLeavePA, emp_PF, emp_medicalAllowance, emp_LTA, emp_convence, emp_mobilePhoneExp, emp_totalMedicalLeavePA, CreateDate, CreateUser, LastModifyDate, LastModifyUser, emp_LeaveSchemeAppliedFrom, emp_branch,getdate(),@userId,'D' from tbl_trans_employeeCTC where emp_cntId=@cnt_internalId
--			DELETE FROM tbl_trans_employeeCTC where emp_cntId=@cnt_internalId
--		/*GROUP DETAILS--------*/
--			INSERT INTO tbl_trans_group_Log(grp_id, grp_contactId, grp_groupMaster, grp_groupType, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
--			SELECT *,getdate(),@userId,'D' FROM tbl_trans_group WHERE grp_contactId=@cnt_internalId
--			DELETE FROM tbl_trans_group WHERE grp_contactId=@cnt_internalId
--		/*DOCUMENT DETAILS-----*/
--		/* document log commented because 	tbl_master_document_Log does not exists  */
--			--INSERT INTO tbl_master_document_Log(doc_id, doc_contactId, doc_documentTypeId, doc_documentName, doc_source, doc_buildingId, doc_Floor, doc_RoomNo, doc_CellNo, doc_FileNo, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
--											--SELECT doc_id, doc_contactId, doc_documentTypeId, doc_documentName, doc_source, doc_buildingId, doc_Floor, doc_RoomNo, doc_CellNo, doc_FileNo, CreateDate, CreateUser, LastModifyDate, LastModifyUser,getdate(),@userId,'D' FROM tbl_master_document WHERE doc_contactId=@cnt_internalId
----select doc_id, doc_contactId, doc_documentTypeId, doc_documentName, doc_source, doc_buildingId, doc_Floor, doc_RoomNo, doc_CellNo, doc_FileNo, CreateDate, CreateUser, LastModifyDate, LastModifyUser from  tbl_master_document
--			DELETE FROM tbl_master_document WHERE doc_contactId=@cnt_internalId
--		/*DP DETAILS-----------*/
--			INSERT INTO tbl_master_contactDPDetails_Log(dpd_id, dpd_cntId, dpd_accountType, dpd_dpCode, dpd_ClientId, dpd_POA, dpd_POAName, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
--			select dpd_id, dpd_cntId, dpd_accountType, dpd_dpCode, dpd_ClientId, dpd_POA, dpd_POAName, CreateDate, CreateUser, LastModifyDate, LastModifyUser,getdate(),@userId,'D' from tbl_master_contactDPDetails where dpd_cntId=@cnt_internalId
--			DELETE FROM tbl_master_contactDPDetails_Log where dpd_cntId=@cnt_internalId
--		/*REMARKS DETAILS------*/
--			INSERT INTO  tbl_master_contactRemarks_Log (id, rea_internalId, cat_id, rea_Remarks, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
--			SELECT *,getdate(),@userId,'D' FROM tbl_master_contactRemarks WHERE rea_internalId=@cnt_internalId
--			DELETE  FROM tbl_master_contactRemarks WHERE rea_internalId=@cnt_internalId
--		/*HISTORY LOG----------*/
--			INSERT INTO tbl_master_EmploymentHistory_Log(emp_id, emp_InternalId, emp_employerName, emp_employerAddress, emp_employerPhone, emp_employerFax, emp_employerEmail, emp_employerPan, emp_employerFrm, emp_employerTo, emp_jobResponsibility, emp_designation, emp_department, emp_ctc, emp_taxIncome, emp_tds, CreateUser, CreateDate, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
--			SELECT *,getdate(),@userId,'D' FROM tbl_master_EmploymentHistory WHERE emp_InternalId=@cnt_internalId
--			DELETE FROM tbl_master_EmploymentHistory WHERE emp_InternalId=@cnt_internalId
--		/*CONATCT RELATIONSHIP-*/
--			INSERT INTO tbl_master_contactFamilyRelationship_Log(femrel_id, femrel_cntId, femrel_contactType, femrel_memberName, femrel_relationId, femrel_DOB, femrel_bloodGroup, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LogModifyDate, LogModifyUser, LogStatus)
--			SELECT *,getdate(),@userId,'D' FROM tbl_master_contactFamilyRelationship WHERE femrel_cntId=@cnt_internalId
--			DELETE FROM tbl_master_contactFamilyRelationship WHERE femrel_cntId=@cnt_internalId
--		/*Bank Details---------*/
--			INSERT INTO tbl_trans_contactBankDetails_Log(cbd_id, cbd_accountCategory, cbd_cntId, cbd_contactType, cbd_bankCode, cbd_accountNumber, cbd_accountType, cbd_accountName, CreateDate, CreateUser, LastModifyDate, LastModifyUser,cbd_Status,cbd_StatucChangeDate,cbd_StatusChangeReason,LogModifyDate, LogModifyUser, LogStatus)
--			SELECT cbd_id, cbd_accountCategory, cbd_cntId, cbd_contactType, cbd_bankCode, cbd_accountNumber, cbd_accountType, cbd_accountName, CreateDate, CreateUser, LastModifyDate, LastModifyUser,cbd_Status,cbd_StatucChangeDate,cbd_StatusChangeReason,getdate(),@userId,'D' FROM tbl_trans_contactBankDetails WHERE cbd_cntId=@cnt_internalId
--			DELETE FROM tbl_trans_contactBankDetails WHERE cbd_cntId=@cnt_internalId
--		/*Registration----------*/
--			INSERT INTO tbl_master_contactMembership_Log(crg_internalid, crg_cntId, crg_idprof, crg_memNumber, crg_memtype, crg_validityType, crg_memExpDate, crg_notes, CreateUser, CreateDate, LastModifyUser, LastModifyDate, LogModifyDate, LogModifyUser, LogStatus)
--			SELECT *,getdate(),@userId,'D' FROM tbl_master_contactMembership WHERE crg_cntId=@cnt_internalId
			
--			--insert into tbl_master_contactRegistration_Log(crg_id, crg_cntId, crg_contactType, crg_type, crg_Number, crg_registrationAuthority, crg_place, crg_Date, crg_validDate, crg_verify, CreateDate, CreateUser, LastModifyDate, LastModifyUser, LastModifyDate_DLMAST, LogModifyDate, LogModifyUser, LogStatus)
--			--select *,getdate(),@userId,'D' FROM tbl_master_contactRegistration where crg_cntId=@cnt_internalId

--			delete from tbl_master_contactMembership_Log WHERE crg_cntId=@cnt_internalId
--			delete from tbl_master_contactRegistration_Log where crg_cntId=@cnt_internalId
--	END
--END

----select * from tbl_master_contactMembership_Log
----select * from	tbl_master_contact_Log
----select * from	tbl_master_employee_Log
----select * from	tbl_master_address_Log
----select * from	tbl_master_phonefax_Log
----select * from	tbl_master_email_Log
----select * from	tbl_master_educationProfessional_Log
----select * from	tbl_master_contactExchange_Log
----select * from	tbl_trans_employeeCTC_Log
----select * from	tbl_trans_group_Log
----select * from	tbl_master_document_Log
----select * from	tbl_master_contactDPDetails_Log
----select * from	tbl_master_contactRemarks_Log
----select * from	tbl_master_EmploymentHistory_Log
----select * from	tbl_master_contactFamilyRelationship_Log
----SELECT * FROM   tbl_trans_contactBankDetails_Log

----DELETE from	tbl_master_contact_Log
----DELETE from	tbl_master_employee_Log
----DELETE from	tbl_master_address_Log
----DELETE from	tbl_master_phonefax_Log
----DELETE from	tbl_master_email_Log
----DELETE from	tbl_master_educationProfessional_Log
----DELETE from	tbl_master_contactExchange_Log
----DELETE from	tbl_trans_employeeCTC_Log
----DELETE from	tbl_trans_group_Log
----DELETE from	tbl_master_document_Log
----DELETE from	tbl_master_contactDPDetails_Log
----DELETE from	tbl_master_contactRemarks_Log
----DELETE from	tbl_master_EmploymentHistory_Log
----DELETE from	tbl_master_contactFamilyRelationship_Log
----DELETE FROM   tbl_trans_contactBankDetails_Log
