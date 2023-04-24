


--prc_ReimbursementApplication_Verified_InsertUpdate 'EMP0000002','5A33AF8C-8CC9-48F7-BE30-D4161C7ED1E4',1,6,8000

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_ReimbursementApplication_Verified_InsertUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_ReimbursementApplication_Verified_InsertUpdate] AS' 
END
GO
ALTER PROC [dbo].[prc_ReimbursementApplication_Verified_InsertUpdate]
(
	@USER_CONTACTID VARCHAR(50)=null,
	@APPLICATIONID uniqueidentifier,
	@APPRVD_DIST DECIMAL(18,2),
	@APPRVD_AMT DECIMAL(18,2),
	@APP_REJ_REMARKS VARCHAR(MAX)=null,
	-- Rev 2.0
	@CONF_REJ_REMARKS VARCHAR(MAX)='',
	-- End of Rev 2.0
	@IS_ApprovedReject int
) WITH ENCRYPTION

AS  
/****************************************************************************************************************************************************************************
Written by : Surojit on 01/02/2019
Module	   : Reimbursement List
Module Functionality : status=1 means approved,status=2 means reject
1.0		Pratik			18/11/2021		Updated logic for approved and reject amount. reffer to:Mantis 24481
2.0		Sanchita		V2.0.40		20-04-2023		In TRAVELLING ALLOWANCE -- Approve/Reject Page: One Coloumn('Confirm/Reject') required 
													before 'Approve/Reject' coloumn. refer: 25809		
****************************************************************************************************************************************************************************/
    SET NOCOUNT ON ;
    BEGIN TRY  
	DECLARE @MESSAGE VARCHAR(100) = '';
	DECLARE @ISUPDATE BIT = 0;
	DECLARE @COUNT INT = 0 ;
	--select * from FTS_Reimbursement_Application_Verified
	DECLARE @checkedforapproved INT = 0
	DECLARE @MESSAGEforapproved VARCHAR(100) = ''
	select @checkedforapproved=CASE WHEN DATEADD(d, (select CAST(isnull(Value,0) AS INT) from FTS_APP_CONFIG_SETTINGS 
									where [Key]='Allow_Approved_Lock_Days'), Createddate) < getdate() THEN 1 ELSE 0 END
	,@MESSAGEforapproved='Entered on: '+CONVERT(NVARCHAR(10),Createddate,105)+', Today is: '+CONVERT(NVARCHAR(10),getdate(),105)+'. You can approve/reject only on/after '
						+CONVERT(NVARCHAR(10),DATEADD(d, (select CAST(isnull(Value+1,0) AS INT) from FTS_APP_CONFIG_SETTINGS 
									where [Key]='Allow_Approved_Lock_Days'), Createddate),105)
									
									 from FTS_Reimbursement_Application 
	where ApplicationID=@APPLICATIONID ;

	-- Rev 2.0
	DECLARE @isExpenseFeatureAvailable VARCHAR(10)
	SET @isExpenseFeatureAvailable = (select [value] from FTS_APP_CONFIG_SETTINGS WHERE [Key]='isExpenseFeatureAvailable')
	-- End of Rev 2.0

	If(@checkedforapproved=1)
	BEGIN
		SELECT @COUNT = COUNT(*) FROM FTS_Reimbursement_Application_Verified WHERE ApplicationID = @APPLICATIONID;
		IF(@IS_ApprovedReject=1)
			BEGIN
				if(@COUNT = 0 )
					BEGIN

					INSERT INTO FTS_Reimbursement_Application_Verified													
					(ApplicationID,MapExpenseID,SubExpenseID,UserID,Date,StateID,Visit_type_id,Expence_type_id,Expence_type,Mode_of_travel,
					From_location,To_location,Amount,Total_distance, Remark,Start_date_time,End_date_time,Location,Hotel_name,Food_type,Fuel_typeId,Createddate,
					CreatedBy,status,UpdatedBy,UpdatedOn,Designation_ID) 
					select ApplicationID,MapExpenseID,SubExpenseID,UserID,Date,StateID,Visit_type_id,Expence_type_id,Expence_type,Mode_of_travel,From_location,To_location,@APPRVD_AMT,@APPRVD_DIST,
					@APP_REJ_REMARKS, Start_date_time,End_date_time,Location,Hotel_name,Food_type,Fuel_typeId,GETDATE(),CreatedBy,1,UpdatedBy,UpdatedOn,Designation_ID from FTS_Reimbursement_Application
					where ApplicationID = @APPLICATIONID;

					set @MESSAGE = 'Data Saved!';
					set @ISUPDATE = 1;

				END
					ELSE 
						BEGIN
							
							UPDATE FTS_Reimbursement_Application_Verified SET Amount = @APPRVD_AMT, Total_distance = @APPRVD_DIST,status=1,Remark=@APP_REJ_REMARKS WHERE ApplicationID = @APPLICATIONID;
							
							set @MESSAGE = 'Data Updated!';
							set @ISUPDATE = 1;
						END
			END
		-- Rev 2.0
		--ELSE
		ELSE IF(@IS_ApprovedReject=2) 
		-- End of Rev 2.0
			BEGIN
				if(@COUNT = 0 )
					BEGIN

						INSERT INTO FTS_Reimbursement_Application_Verified													
						(ApplicationID,MapExpenseID,SubExpenseID,UserID,Date,StateID,Visit_type_id,Expence_type_id,Expence_type,Mode_of_travel,
						From_location,To_location,Amount,Total_distance, Remark,Start_date_time,End_date_time,Location,Hotel_name,Food_type,Fuel_typeId,Createddate,
						CreatedBy,status,UpdatedBy,UpdatedOn,Designation_ID) 
						select ApplicationID,MapExpenseID,SubExpenseID,UserID,Date,StateID,Visit_type_id,Expence_type_id,Expence_type,Mode_of_travel,From_location,To_location,0,0,
						@APP_REJ_REMARKS, Start_date_time,End_date_time,Location,Hotel_name,Food_type,Fuel_typeId,GETDATE(),CreatedBy,2,UpdatedBy,UpdatedOn,Designation_ID from FTS_Reimbursement_Application
						where ApplicationID = @APPLICATIONID;

						set @MESSAGE = 'Data Saved!';
						set @ISUPDATE = 1;

					END
				ELSE 
				BEGIN
					--rev 1.0
					--UPDATE FTS_Reimbursement_Application_Verified SET Amount = @APPRVD_AMT, Total_distance = @APPRVD_DIST,status=2,UpdatedOn=GETDATE(),Remark=@APP_REJ_REMARKS 					
					UPDATE FTS_Reimbursement_Application_Verified SET Amount = 0, Total_distance = 0,status=2,UpdatedOn=GETDATE(),Remark=@APP_REJ_REMARKS 
					--End of rev 1.0
					WHERE ApplicationID = @APPLICATIONID;
					set @MESSAGE = 'Data Updated!';
					set @ISUPDATE = 1;
				END
			END
		-- Rev 2.0
		ELSE IF(@IS_ApprovedReject=3) 
			BEGIN
				IF (@isExpenseFeatureAvailable='1')
				BEGIN
					UPDATE FTS_Reimbursement_Application SET Confirm_Reimbursement=1, Conf_Rej_Remarks=@CONF_REJ_REMARKS 
								WHERE ApplicationID = @APPLICATIONID

					set @MESSAGE = 'Data Saved!';
					set @ISUPDATE = 1;
				END
			END
		-- End of Rev 2.0
	end
	ELSE
	BEGIN
	set @ISUPDATE = 0;
	set @MESSAGE = @MESSAGEforapproved;
	END
	SELECT @MESSAGE AS [Message],@ISUPDATE AS Success  ;
 END TRY 

    BEGIN CATCH 

        DECLARE @ErrorMessage NVARCHAR(4000) ; 
        DECLARE @ErrorSeverity INT ; 
        DECLARE @ErrorState INT ; 
        SELECT  @ErrorMessage = ERROR_MESSAGE() , 
                @ErrorSeverity = ERROR_SEVERITY() , 
                @ErrorState = ERROR_STATE() ; 
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState) ; 
    END CATCH ; 

    RETURN ; 

