IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_Common]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_Common] AS'  
END 
GO 

ALTER  Procedure [dbo].[Proc_Common]
	@userid int = null,
	@usergroupid int = null,
	@url nvarchar(500) = null,
	@mode nvarchar(200)
AS
/**************************************************************************************************************************************************************************
1.0		Pratik			v2.0.28			18-04-2022		Add Rights CanAssign for module CRM - Enquiry
															Refer: 24832
2.0		Sanchita		2.0.38			28/01/2022		Bulk modification feature is required in Parties menu. Refer: 25609
3.0		Sanchita		V2.0.44			19/02/2023		Beat related tab will be added in the security roles of Parties. Mantis: 27080
4.0		Sanchita		V2.0.47			30/05/2024		Mass Delete related tabs will be added in the security roles of Parties. Mantis: 27489
****************************************************************************************************************************************************************************/
BEGIN
	IF @mode = 'GetUserRightsForPage'
	BEGIN
		SELECT CanEdit = CAST(IsNull(ta.acc_edit, 0) as BIT), CanDelete = CAST(IsNull(ta.acc_delete, 0) as BIT),
		CanAdd = CAST(IsNull(ta.acc_add, 0) as BIT), CanView = CAST(IsNull(ta.acc_can_view, 0) as BIT),
		CanIndustry = CAST(IsNull(ta.acc_industry, 0) as BIT),
		CanCreateActivity = CAST(IsNull(ta.acc_create_activity, 0) as BIT),
		CanContactPerson = CAST(IsNull(ta.acc_contact_person, 0) as BIT),
		CanHistory = CAST(IsNull(ta.acc_history, 0) as BIT),
		CanAddUpdateDocuments = CAST(IsNull(ta.acc_addupdate_documents, 0) as BIT),
		CanMembers = CAST(IsNull(ta.acc_members, 0) as BIT),
		CanOpeningAddUpdate = CAST(IsNull(ta.acc_opening_addupdate, 0) as BIT),
		CanAssetDetails = CAST(IsNull(ta.acc_asset_details, 0) as BIT),
		CanExport = CAST(IsNull(ta.acc_Export, 0) as BIT),
		CanPrint = CAST(IsNull(ta.acc_Print, 0) as BIT),
		
		CanBudget = CAST(IsNull(ta.acc_Budget, 0) as BIT),
		CanAssignbranch = CAST(IsNull(ta.acc_Branchassign, 0) as BIT),
		Cancancelassignmnt = CAST(IsNull(ta.acc_cancelassign, 0) as BIT),
			CanReassign = CAST(IsNull(ta.acc_CanReassignActivity, 0) as BIT),
			CanClose = CAST(IsNull(ta.acc_can_close, 0) as BIT),
			CanSpecialEdit= CAST(IsNull(ta.acc_SpecialEdit, 0) as BIT)
			,CanCancel=CAST(IsNull(acc_cancel, 0) as bit)
		--rev 1.0
		,CanAssign = CAST(IsNull(ta.acc_CanAssignActivity, 0) as BIT)
		--End of rev 1.0
		-- Rev 2.0
		,CanBulkUpdate = CAST(IsNull(ta.acc_CanBulkUpdate, 0) as BIT)
		-- End of Rev 2.0
		-- Rev 3.0
		,CanReassignedBeatParty = CAST(IsNull(ta.acc_CanReassignedBeatParty, 0) as BIT)
		,CanReassignedBeatPartyLog = CAST(IsNull(ta.acc_CanReassignedBeatPartyLog, 0) as BIT)
		,CanReassignedAreaRouteBeat = CAST(IsNull(ta.acc_CanReassignedAreaRouteBeat, 0) as BIT)
		,CanReassignedAreaRouteBeatLog = CAST(IsNull(ta.acc_CanReassignedAreaRouteBeatLog, 0) as BIT)
		-- End of Rev 3.0
		-- Rev 4.0
		,CanMassDelete = CAST(IsNull(ta.acc_MassDelete, 0) as BIT)
		,CanMassDeleteDownloadImport = CAST(IsNull(ta.acc_MassDeleteDownloadImport, 0) as BIT)
		-- End of Rev 4.0
		FROM tbl_trans_access ta
		INNER JOIN tbl_trans_menu tm ON CAST(ta.acc_menuId as INT) = CAST(mnu_Id as INT)
		WHERE ta.acc_userGroupId = @usergroupid and tm.mnu_menuLink = @url;
	END
END
GO