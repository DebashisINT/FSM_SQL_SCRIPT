IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_UserGroups_Helper]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_UserGroups_Helper] AS'  
END 
GO 

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER  Procedure [dbo].[PROC_UserGroups_Helper]
	@grp_id int = null,
	@mode nvarchar(200)
AS
/**************************************************************************************************************************************************************************
1.0		Pratik			v2.0.28			18-04-2022		Add Rights CanAssign for module CRM - Enquiry
															Refer: 24832
2.0		Sanchita		2.0.38			28/01/2022		Bulk modification feature is required in Parties menu. Refer: 25609
3.0		Sanchita		V2.0.44			19/02/2023		Beat related tab will be added in the security roles of Parties. Mantis: 27080
****************************************************************************************************************************************************************************/
BEGIN
	IF @mode = 'FetchAllGroups'
	BEGIN
		Select grp_id, grp_name
		from tbl_master_userGroup;
	END
	
	ELSE IF @mode = 'GetTranAccessByGroup'
	BEGIN
		Select MenuId = CAST(acc_menuId as INT), CanAdd = CAST(IsNull(acc_add, 0) as bit), CanEdit = CAST(IsNull(acc_edit, 0) as bit), 
		CanDelete = CAST(IsNull(acc_delete, 0) as bit), CanView = CAST(IsNull(acc_can_view, 0) as bit)
		, CanIndustry = CAST(IsNull(acc_industry, 0) as bit)
		, CanCreateActivity = CAST(IsNull(acc_create_activity, 0) as bit)
		, CanContactPerson = CAST(IsNull(acc_contact_person, 0) as bit)
		, CanHistory = CAST(IsNull(acc_history, 0) as bit)
		, CanAddUpdateDocuments = CAST(IsNull(acc_addupdate_documents, 0) as bit)
		, CanMembers = CAST(IsNull(acc_members, 0) as bit)
		, CanOpeningAddUpdate = CAST(IsNull(acc_opening_addupdate, 0) as bit)
		, CanAssetDetails = CAST(IsNull(acc_asset_details, 0) as bit)
		, CanExport = CAST(IsNull(acc_Export, 0) as bit)
		, CanPrint = CAST(IsNull(acc_Print, 0) as bit)
		,CanBudget= CAST(IsNull(acc_Budget, 0) as bit)
		,CanAssignbranch= CAST(IsNull(acc_Branchassign, 0) as bit)
		,Cancancelassignmnt=CAST(IsNull(acc_cancelassign, 0) as bit)
		,CanReassign=CAST(IsNull(acc_CanReassignActivity, 0) as bit)
		,CanClose=CAST(IsNull(acc_can_close, 0) as bit)
		,CanSpecialEdit=CAST(IsNull(acc_SpecialEdit, 0) as bit)
		,CanCancel=CAST(IsNull(acc_cancel, 0) as bit)
		--rev 1.0
		,CanAssign = CAST(IsNull(acc_CanAssignActivity, 0) as BIT)
		--End of rev 1.0
		-- Rev 2.0
		,CanBulkUpdate = CAST(IsNull(acc_CanBulkUpdate, 0) as BIT)
		-- End of Rev 2.0
		-- Rev 3.0
		,CanReassignedBeatParty = CAST(IsNull(acc_CanReassignedBeatParty, 0) as BIT)
		,CanReassignedBeatPartyLog = CAST(IsNull(acc_CanReassignedBeatPartyLog, 0) as BIT)
		,CanReassignedAreaRouteBeat = CAST(IsNull(acc_CanReassignedAreaRouteBeat, 0) as BIT)
		,CanReassignedAreaRouteBeatLog = CAST(IsNull(acc_CanReassignedAreaRouteBeatLog, 0) as BIT)
		-- End of Rev 3.0
		from tbl_trans_access
		where acc_userGroupId = @grp_id;
	END
	
	ELSE IF @mode = 'GetGroupTaggedUsers'
	BEGIN
		SELECT UserId = CAST([user_id] as INT), UserName = [user_name], UserGroupId = CAST(user_group as INT)
		FROM tbl_master_user
		WHERE user_group = @grp_id;
	END
END
GO