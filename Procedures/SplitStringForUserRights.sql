IF NOT EXISTS (SELECT * FROM sys.objects  WHERE  object_id = OBJECT_ID(N'[dbo].[SplitStringForUserRights]') AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' )) 
 BEGIN 
 EXEC('CREATE FUNCTION [dbo].[SplitStringForUserRights]() RETURNS DECIMAL(18,2) AS BEGIN RETURN 0 END')  
 END 
 GO 

ALTER FUNCTION [dbo].[SplitStringForUserRights]
(    
      @Input NVARCHAR(MAX),
      @IdDelimiter CHAR(1),
      @ValueDelimiter CHAR(1),
      @MainSplitDelimiter CHAR(1)
)
RETURNS @Output TABLE (
      MenuId INT,
      Has_Add_Rights bit,
      Has_Modify_Rights bit,
      Has_Delete_Rights bit,
      Has_View_Rights bit,
       Has_Industry_Rights bit,       
       Has_CreateActivity_Rights bit,
      Has_ContactPerson_Rights bit,
      Has_History_Rights bit,
      Has_AddUpdateDocuments_Rights bit,
       Has_Members_Rights bit,
        Has_OpeningAddUpdate_Rights bit,
       Has_AssetDetails_Rights bit,
       Has_Export_Rights bit,
       Has_Print_Rights bit,
	   Has_Budget_Rights bit,
	   Has_Branchassign_Rights bit,
	   Has_Cancelassignmnt_Rights bit,
	     Has_CanReassignActivity_Rights bit,
		  Has_Close_Rights bit,
		  Has_SpecialEdit_Rights bit,
		  Has_Cancel_Rights bit
		  --rev 1.0
		  ,Has_CanAssignActivity bit
		  --End of rev 1.0
		  -- Rev 2.0
		  ,Has_CanBulkUpdate bit
		  -- End of Rev 2.0
		  -- Rev 3.0
		  ,Has_CanReassignedBeatParty bit
		  ,Has_CanReassignedBeatPartyLog bit
		  ,Has_CanReassignedAreaRouteBeat bit
		  ,Has_CanReassignedAreaRouteBeatLog bit
		  -- End of Rev 3.0
)
AS
/**************************************************************************************************************************************************************************
1.0		Pratik			v2.0.28			18-04-2022		Add Rights CanAssign for module CRM - Enquiry
															Refer: 24832
2.0		Sanchita		2.0.38			28/01/2022		Bulk modification feature is required in Parties menu. Refer: 25609
3.0		Sanchita		V2.0.44			19/02/2023		Beat related tab will be added in the security roles of Parties. Mantis: 27080
****************************************************************************************************************************************************************************/
BEGIN
      DECLARE @StartIndex INT, @EndIndex INT, @CheckVal NVARCHAR(MAX)
      DECLARE @MenuId INT, @Value NVARCHAR(1000), @TempValue NVARCHAR(1000)
      DECLARE @Has_Add_Rights BIT, @Has_Modify_Rights BIT, @Has_Delete_Rights BIT, @Has_View_Rights BIT, @Has_Industry_Rights BIT
	  DECLARE @Has_CreateActivity_Rights BIT,  @Has_ContactPerson_Rights BIT, @Has_History_Rights BIT, @Has_AddUpdateDocuments_Rights BIT, @Has_Members_Rights BIT, @Has_OpeningAddUpdate_Rights BIT, @Has_AssetDetails_Rights BIT
     DECLARE @Has_Export_Rights bit,@Has_Print_Rights bit,@Has_Budget_Rights bit,@Has_Branchassign_Rights bit,@Has_Cancelassignmnt_Rights bit, @Has_CanReassignActivity_Rights bit, 
     @Has_Close_Rights bit,@Has_SpecialEdit_Rights BIT,@Has_Cancel_Rights bit
	 -- Rev 2.0 [ @Has_BulkUpdate bit added ]
	 --rev 1.0
	 ,@Has_CanAssignActivity bit, @Has_CanBulkUpdate bit
	 --End of rev 1.0
	 -- Rev 3.0
	 ,@Has_CanReassignedBeatParty bit, @Has_CanReassignedBeatPartyLog bit,@Has_CanReassignedAreaRouteBeat bit, @Has_CanReassignedAreaRouteBeatLog bit
	 -- End of Rev 3.0

      SET @StartIndex = 1
      IF SUBSTRING(@Input, LEN(@Input) - 1, LEN(@Input)) <> @MainSplitDelimiter
      BEGIN
            SET @Input = @Input + @MainSplitDelimiter
      END
 
      WHILE CHARINDEX(@MainSplitDelimiter, @Input) > 0
      BEGIN
            SET @EndIndex = CHARINDEX(@MainSplitDelimiter, @Input)
            SET @CheckVal = RTRIM(LTRIM(SUBSTRING(@Input, @StartIndex, @EndIndex - 1)))
			IF @CheckVal IS NOT NULL AND @CheckVal <> ''
			BEGIN
				IF SUBSTRING(@CheckVal, LEN(@CheckVal) - 1, LEN(@CheckVal)) <> @IdDelimiter
				BEGIN
					SET @CheckVal = @CheckVal + @IdDelimiter
				END
				SET @MenuId = CAST(RTRIM(LTRIM(SUBSTRING(@CheckVal, 1, (CHARINDEX(@IdDelimiter, @CheckVal)) - 1))) as INT)
				SET @CheckVal = SUBSTRING(@CheckVal, (CHARINDEX(@IdDelimiter, @CheckVal)) + 1, LEN(@CheckVal))
				SET @Value = RTRIM(LTRIM(SUBSTRING(@CheckVal, 1, (CHARINDEX(@IdDelimiter, @CheckVal)) - 1)))
				
				SET @Has_Add_Rights = 0;
				SET @Has_Modify_Rights = 0;
				SET @Has_Delete_Rights = 0;
				SET @Has_View_Rights = 0;
				SET @Has_Industry_Rights = 0
				
				SET @Has_CreateActivity_Rights= 0;
				SET @Has_ContactPerson_Rights= 0;
				SET @Has_History_Rights= 0;
				SET @Has_AddUpdateDocuments_Rights= 0;
				SET @Has_Members_Rights= 0;
				SET @Has_OpeningAddUpdate_Rights= 0;
				SET @Has_AssetDetails_Rights= 0;
				SET @Has_Export_Rights = 0;
				SET @Has_Print_Rights = 0;
				SET @Has_Budget_Rights = 0;
				SET @Has_Branchassign_Rights = 0;
				SET @Has_Cancelassignmnt_Rights = 0;
				SET @Has_CanReassignActivity_Rights = 0;
					SET @Has_Close_Rights = 0;
					set @Has_SpecialEdit_Rights=0; --Added by Sam on 14092017
					set @Has_Cancel_Rights=0; --added by subhabrata on 19-09-2017
				--rev 1.0
				SET @Has_CanAssignActivity=0;
				--End of rev 1.0
				-- Rev 2.0
				SET @Has_CanBulkUpdate=0;
				-- End of Rev 2.0
				-- Rev 3.0
				SET @Has_CanReassignedBeatParty=0;
				SET @Has_CanReassignedBeatPartyLog=0;
				SET @Has_CanReassignedAreaRouteBeat=0;
				SET @Has_CanReassignedAreaRouteBeatLog=0;
				-- End of Rev 3.0
				IF SUBSTRING(@Value, LEN(@Value) - 1, LEN(@Value)) <> @ValueDelimiter
				BEGIN
					SET @Value = @Value + @ValueDelimiter
				END
				
				WHILE CHARINDEX(@ValueDelimiter, @Value) > 0
				BEGIN
					SET @TempValue = RTRIM(LTRIM(SUBSTRING(@Value, 1, (CHARINDEX(@ValueDelimiter, @Value)) - 1)))
					
					IF @TempValue IS NOT NULL AND @TempValue <> ''
					BEGIN
						IF @TempValue = '1'
						BEGIN
							SET @Has_Add_Rights = 1;
						END						
						ELSE IF @TempValue = '2'
						BEGIN
						SET @Has_View_Rights = 1;						
						END
						ELSE IF @TempValue = '3'
						BEGIN
						SET @Has_Modify_Rights = 1;							
						END
						ELSE IF @TempValue = '4'						
						BEGIN							
							SET @Has_Delete_Rights = 1;
						END						
						ELSE IF @TempValue = '5'
						BEGIN
							SET @Has_CreateActivity_Rights = 1;
						END
						ELSE IF @TempValue = '6'
						BEGIN
							SET @Has_Industry_Rights = 1;
						END
						ELSE IF @TempValue = '7'
						BEGIN
							SET @Has_ContactPerson_Rights = 1;
						END
						ELSE IF @TempValue = '8'
						BEGIN
							SET @Has_History_Rights = 1;
						END
						ELSE IF @TempValue = '9'
						BEGIN
							SET @Has_AddUpdateDocuments_Rights = 1;
						END
						ELSE IF @TempValue = '10'
						BEGIN
							SET @Has_Members_Rights = 1;
						END
						ELSE IF @TempValue = '11'
						BEGIN
							SET @Has_OpeningAddUpdate_Rights = 1;
						END
						ELSE IF @TempValue = '12'
						BEGIN
							SET @Has_AssetDetails_Rights = 1;
						END
						ELSE IF @TempValue = '13'
						BEGIN
							SET @Has_Export_Rights = 1;
						END
						ELSE IF @TempValue = '14'
						BEGIN
							SET @Has_Print_Rights = 1;
						END

							ELSE IF @TempValue = '15'
						BEGIN
							SET @Has_Budget_Rights = 1;
						END
						ELSE IF @TempValue = '16'
						BEGIN
							SET @Has_Branchassign_Rights = 1;
						END

						ELSE IF @TempValue = '17'
						BEGIN
							SET @Has_Cancelassignmnt_Rights = 1;
						END
							ELSE IF @TempValue = '18'
						BEGIN
							SET @Has_CanReassignActivity_Rights = 1;
						END
							ELSE IF @TempValue = '19'
						BEGIN
							SET @Has_Close_Rights = 1;
						END
						    ELSE IF @TempValue = '20'
						BEGIN
							SET @Has_SpecialEdit_Rights = 1;
						END
							ELSE IF @TempValue = '21'
						BEGIN
							set @Has_Cancel_Rights=1;
						END
						--rev 1.0
						ELSE IF @TempValue = '22'
						BEGIN
							set @Has_CanAssignActivity=1;
						END
						--End of rev 1.0
						--rev 2.0
						ELSE IF @TempValue = '25'
						BEGIN
							set @Has_CanBulkUpdate=1;
						END
						--End of rev 2.0
						-- Rev 3.0
						ELSE IF @TempValue = '26'
						BEGIN
							set @Has_CanReassignedBeatParty=1;
						END
						ELSE IF @TempValue = '27'
						BEGIN
							set @Has_CanReassignedBeatPartyLog=1;
						END
						ELSE IF @TempValue = '28'
						BEGIN
							set @Has_CanReassignedAreaRouteBeat=1;
						END
						ELSE IF @TempValue = '29'
						BEGIN
							set @Has_CanReassignedAreaRouteBeatLog=1;
						END
						-- End of Rev 3.0
						
					END
					
					SET @Value = SUBSTRING(@Value, (CHARINDEX(@ValueDelimiter, @Value)) + 1, LEN(@Value))
				END
				
				INSERT INTO @Output(MenuId, Has_Add_Rights, Has_Modify_Rights, Has_Delete_Rights, Has_View_Rights, Has_Industry_Rights,
				Has_CreateActivity_Rights,Has_ContactPerson_Rights,Has_History_Rights,
				Has_AddUpdateDocuments_Rights,Has_Members_Rights,
				Has_OpeningAddUpdate_Rights,Has_AssetDetails_Rights,
				Has_Export_Rights,Has_Print_Rights,Has_Budget_Rights,
				Has_Branchassign_Rights,Has_Cancelassignmnt_Rights,
				Has_CanReassignActivity_Rights,Has_Close_Rights,Has_SpecialEdit_Rights,Has_Cancel_Rights
				-- Rev 2.0 [Has_CanBulkUpdate and @Has_CanBulkUpdate added]
				--rev 1.0
				,Has_CanAssignActivity, Has_CanBulkUpdate
				-- Rev 3.0
				,Has_CanReassignedBeatParty, Has_CanReassignedBeatPartyLog, Has_CanReassignedAreaRouteBeat, Has_CanReassignedAreaRouteBeatLog
				-- End of Rev 3.0
				)
				--End of rev 1.0
				VALUES (@MenuId, @Has_Add_Rights, @Has_Modify_Rights, @Has_Delete_Rights, @Has_View_Rights, @Has_Industry_Rights,
				@Has_CreateActivity_Rights,@Has_ContactPerson_Rights,@Has_History_Rights,
				@Has_AddUpdateDocuments_Rights,@Has_Members_Rights,
				@Has_OpeningAddUpdate_Rights,@Has_AssetDetails_Rights,@Has_Export_Rights,@Has_Print_Rights,@Has_Budget_Rights,
				@Has_Branchassign_Rights,@Has_Cancelassignmnt_Rights,@Has_CanReassignActivity_Rights,
				@Has_Close_Rights,@Has_SpecialEdit_Rights,@Has_Cancel_Rights
				--rev 1.0
				,@Has_CanAssignActivity, @Has_CanBulkUpdate
				-- Rev 3.0
				,@Has_CanReassignedBeatParty, @Has_CanReassignedBeatPartyLog, @Has_CanReassignedAreaRouteBeat, @Has_CanReassignedAreaRouteBeatLog
				-- End of Rev 3.0
				);
				--End of rev 1.0
			END
           
            SET @Input = SUBSTRING(@Input, @EndIndex + 1, LEN(@Input))
      END
 
      RETURN
END
GO