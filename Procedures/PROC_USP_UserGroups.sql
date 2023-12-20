IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_USP_UserGroups]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_USP_UserGroups] AS'  
END 
GO 
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER  Procedure [dbo].[PROC_USP_UserGroups]
	@grp_id int out,
	@grp_segmentId int,
	@grp_name varchar(50) = null,
	@CreateUser int = null,
	@LastModifyUser int = null,
	@UserGroupRights NVARCHAR(MAX) = NULL,
	@ResultStat bit OUTPUT,
	@ResultText varchar(100) OUTPUT,
	@mode nvarchar(200)
AS
/**************************************************************************************************************************************************************************
1.0		Pratik			v2.0.28			18-04-2022		Add Rights CanAssign for module CRM - Enquiry
															Refer: 24832
2.0		Sanchita		2.0.38			28/01/2022		Bulk modification feature is required in Parties menu. Refer: 25609
3.0		Sanchita		V2.0.44			19/02/2023		Beat related tab will be added in the security roles of Parties. Mantis: 27080
****************************************************************************************************************************************************************************/
BEGIN
	IF @mode = 'INSERT'
	BEGIN
		BEGIN TRANSACTION;
		
		IF (SELECT COUNT(grp_id) FROM tbl_master_userGroup WHERE grp_name = @grp_name) > 0
		BEGIN
			SET @grp_id = 0;
			SET @ResultStat = 0;
			SET @ResultText = 'Group name already exists';
			ROLLBACK TRANSACTION;
			RETURN;
		END
		
		INSERT INTO tbl_master_userGroup(grp_segmentId, grp_name, CreateDate, CreateUser)
		VALUES (@grp_segmentId, @grp_name, GETDATE(), @CreateUser);
		
		IF @@ROWCOUNT > 0
		BEGIN
			SET @grp_id = SCOPE_IDENTITY();
			
			IF @UserGroupRights IS NOT NULL AND @UserGroupRights <> ''
			BEGIN
				INSERT INTO tbl_trans_access (acc_userGroupId, acc_menuId, acc_view, acc_edit, acc_delete,
				                              acc_add, acc_can_view, CreateDate, CreateUser,acc_industry,
				                              acc_create_activity,acc_contact_person,acc_history,
				                              acc_addupdate_documents,acc_members,acc_opening_addupdate,acc_asset_details,
				                              acc_Export,acc_Print,acc_Budget,acc_Branchassign,acc_cancelassign,acc_CanReassignActivity,acc_can_close,acc_cancel
											  -- Rev 2.0 [acc_CanBulkUpdate added]
											  --rev 1.0
											  ,acc_CanAssignActivity, acc_CanBulkUpdate
											  -- Rev 3.0
											  ,acc_CanReassignedBeatParty, acc_CanReassignedBeatPartyLog, acc_CanReassignedAreaRouteBeat, acc_CanReassignedAreaRouteBeatLog
											  -- End of Rev 3.0
											  )
											  --End of rev 1.0
											  
				SELECT @grp_id, MenuId, 'All', Has_Modify_Rights, Has_Delete_Rights, Has_Add_Rights, Has_View_Rights,  
				GETDATE(), @CreateUser, Has_Industry_Rights,
				Has_CreateActivity_Rights,
				Has_ContactPerson_Rights,
				Has_History_Rights,
				Has_AddUpdateDocuments_Rights,
				Has_Members_Rights,
				Has_OpeningAddUpdate_Rights,
				Has_AssetDetails_Rights,Has_Export_Rights,Has_Print_Rights
				,Has_Budget_Rights,Has_Branchassign_Rights,Has_Cancelassignmnt_Rights,Has_CanReassignActivity_Rights,Has_Close_Rights,
				Has_Cancel_Rights
				-- Rev 2.0 [Has_CanBulkUpdate added]
				--rev 1.0
				,Has_CanAssignActivity, Has_CanBulkUpdate 
				--End of rev 1.0
				-- Rev 3.0
				,Has_CanReassignedBeatParty, Has_CanReassignedBeatPartyLog, Has_CanReassignedAreaRouteBeat, Has_CanReassignedAreaRouteBeatLog
				-- End of Rev 3.0
				 FROM [dbo].[SplitStringForUserRights](@UserGroupRights, '^', '|', '_');
				
				IF @@ROWCOUNT <= 0
				BEGIN
					SET @grp_id = 0;
					SET @ResultStat = 0;
					SET @ResultText = 'Group creation failed!';
					ROLLBACK TRANSACTION;
					RETURN;
				END
			END
			
			SET @ResultStat = 1;
			SET @ResultText = 'Group created successfully.';
			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			SET @grp_id = 0;
			SET @ResultStat = 0;
			SET @ResultText = 'Group creation failed!';
			ROLLBACK TRANSACTION;
		END
	END

	--@grp_name=   model.grp_name='Administrator'
 --@grp_segmentId=	model.grp_segmentId='1'
 --@UserGroupRights=	model.UserGroupRights= 'wholepagerightdetail'
 --@mode=	model.mode='UPdate'
 --@grp_id=	 model.grp_id='25'
	--select * from tbl_trans_access where acc_usergroupid=25
	ELSE IF @mode = 'UPDATE'
	BEGIN
		BEGIN TRANSACTION;
		
		IF (SELECT COUNT(grp_id) FROM tbl_master_userGroup WHERE grp_name = @grp_name and grp_id <> @grp_id) > 0
		BEGIN
			SET @ResultStat = 0;
			SET @ResultText = 'Group name already exists!';
			ROLLBACK TRANSACTION;
			RETURN;
		END
		
		UPDATE tbl_master_userGroup
		SET grp_name = @grp_name,
			LastModifyDate = GETDATE(),
			LastModifyUser = @LastModifyUser
		WHERE grp_id = @grp_id;
		
		IF @@ROWCOUNT > 0
		BEGIN
			IF (SELECT COUNT(acc_id) FROM tbl_trans_access WHERE acc_userGroupId = @grp_id) > 0
			BEGIN
				DELETE FROM tbl_trans_access WHERE acc_userGroupId = @grp_id;
				
				IF @@ROWCOUNT <= 0
				BEGIN
					SET @ResultStat = 0;
					SET @ResultText = 'Group updation failed!';
					ROLLBACK TRANSACTION;
					RETURN;
				END
			END
			
			IF @UserGroupRights IS NOT NULL AND @UserGroupRights <> ''
			BEGIN
				INSERT INTO tbl_trans_access (acc_userGroupId, acc_menuId, acc_view, acc_edit, acc_delete,
				                              acc_add, acc_can_view, CreateDate, CreateUser,acc_industry,
				                                acc_create_activity,acc_contact_person,acc_history,
				                              acc_addupdate_documents,acc_members,acc_opening_addupdate,acc_asset_details,acc_Export,acc_Print,
											  acc_Budget,acc_Branchassign,acc_cancelassign,acc_CanReassignActivity,acc_can_close,acc_SpecialEdit,acc_cancel
											  -- Rev 2.0 [acc_CanBulkUpdate added]
											  --rev 1.0
											  ,acc_CanAssignActivity, acc_CanBulkUpdate
											  -- Rev 3.0
											  ,acc_CanReassignedBeatParty, acc_CanReassignedBeatPartyLog, acc_CanReassignedAreaRouteBeat, acc_CanReassignedAreaRouteBeatLog
											  -- End of Rev 3.0
											  )
											  --End of rev 1.0
				SELECT @grp_id, MenuId, 'All', Has_Modify_Rights, Has_Delete_Rights, Has_Add_Rights, Has_View_Rights,  
				GETDATE(), @CreateUser, Has_Industry_Rights,
				Has_CreateActivity_Rights,
				Has_ContactPerson_Rights,
				Has_History_Rights,
				Has_AddUpdateDocuments_Rights,
				Has_Members_Rights,
				Has_OpeningAddUpdate_Rights,
				Has_AssetDetails_Rights,Has_Export_Rights,Has_Print_Rights
				,Has_Budget_Rights,Has_Branchassign_Rights,Has_Cancelassignmnt_Rights,Has_CanReassignActivity_Rights,
				Has_Close_Rights,Has_SpecialEdit_Rights,Has_Cancel_Rights
				-- Rev 2.0 [Has_CanBulkUpdate added]
				--rev 1.0
				,Has_CanAssignActivity, Has_CanBulkUpdate
				--End of rev 1.0
				-- Rev 3.0
				,Has_CanReassignedBeatParty, Has_CanReassignedBeatPartyLog, Has_CanReassignedAreaRouteBeat, Has_CanReassignedAreaRouteBeatLog
				-- End of Rev 3.0
				 FROM [dbo].[SplitStringForUserRights](@UserGroupRights, '^', '|', '_');
				
				IF @@ROWCOUNT <= 0
				BEGIN
					SET @ResultStat = 0;
					SET @ResultText = 'Group updation failed!';
					ROLLBACK TRANSACTION;
					RETURN;
				END
			END
			
			SET @ResultStat = 1;
			SET @ResultText = 'Group updated successfully.';
			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			SET @ResultStat = 0;
			SET @ResultText = 'Group updation failed!';
			ROLLBACK TRANSACTION;
		END	
	END
	
	ELSE IF @mode = 'DELETE'
	BEGIN
		BEGIN TRANSACTION;
		
		IF (select COUNT([user_id]) from tbl_master_user where user_group = @grp_id) > 0
		BEGIN
			SET @ResultStat = 0;
			SET @ResultText = 'This group is associted with the users.';
			ROLLBACK TRANSACTION;
			RETURN;
		END
		
		IF (SELECT COUNT(acc_id) FROM tbl_trans_access WHERE acc_userGroupId = @grp_id) > 0
		BEGIN
			DELETE FROM tbl_trans_access WHERE acc_userGroupId = @grp_id;
			
			IF @@ROWCOUNT <= 0
			BEGIN
				SET @ResultStat = 0;
				SET @ResultText = 'Group deletion failed!';
				ROLLBACK TRANSACTION;
				RETURN;
			END
		END
		
		DELETE FROM tbl_master_userGroup WHERE grp_id = @grp_id;
		
		IF @@ROWCOUNT > 0
		BEGIN
			SET @ResultStat = 1;
			SET @ResultText = 'Group deleted successfully!';
			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			SET @ResultStat = 0;
			SET @ResultText = 'Group deletion failed!';
			ROLLBACK TRANSACTION;
		END
	END
END
GO