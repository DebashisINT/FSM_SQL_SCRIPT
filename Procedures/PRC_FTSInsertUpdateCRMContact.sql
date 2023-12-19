IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSInsertUpdateCRMContact]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSInsertUpdateCRMContact] AS'  
END 
GO

--exec PRC_FTSInsertUpdateCRMContact @USERID='378',@CONTACTSFROM='', @FROMDATE='2023-11-19',@TODATE='2023-11-23'

ALTER PROCEDURE [dbo].[PRC_FTSInsertUpdateCRMContact]
(
	@ACTION NVARCHAR(500)=NULL,
	@ShopCode VARCHAR(100)=NULL,
	@FirstName NVARCHAR(500)=NULL,
	@LastName NVARCHAR(500)=NULL,
	@PhoneNo NVARCHAR(100)=NULL,
	@Email NVARCHAR(300)=NULL,
	@Address NVARCHAR(MAX)=NULL,
	@DOB DATETIME = NULL,
	@Anniversarydate DATETIME=NULL,
	@JobTitle NVARCHAR(500)=NULL,
	@CompanyId INT=0,
	@AssignedTo INT=0,
	@TypeId INT=0,
	@StatusId INT=0,
	@SourceId INT=0,
	@ReferenceId NVARCHAR(100)=NULL,
	@StageId INT=0,
	@Remarks NVARCHAR(MAX)=NULL,
	@ExpSalesValue DECIMAL(18,2)=NULL,
	@NextFollowDate DATETIME=NULL,
	@Active BIT=NULL,
	@Lastvisit_date DATETIME=NULL,
	@EntityCode NVARCHAR(300)=NULL,
	@ShopType INT=NULL,
	@user_id INT=NULL,
	@SearchKey varchaR(500) ='',
	@FromDate NVARCHAR(10)=NULL,
	@ToDate NVARCHAR(10)=NULL,
	@IMPORT_TABLE UDT_ImportCRMContact READONLY,
	@RETURN_VALUE nvarchar(500)=NULL OUTPUT
)
 
AS
/****************************************************************************************************************************************************************************
Written by Sanchita on 23-11-2023 for V2.0.43	A new design page is required as Contact (s) under CRM menu. 
												Refer: 27034
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX), @Shop_Name nvarchar(4000)
	DECLARE @SHOP_CODE NVARCHAR(100)
	Declare @ReferenceContactId nvarchar(100) = '', @ReferenceType VARCHAR(50)=''
	
	set @Lastvisit_date =GETDATE()

	
	IF(@ACTION='ADDCRMCONTACT')
	BEGIN
		SET @SHOP_CODE=(CAST(@user_id AS varchar(20)) + '_' + cast((CAST(DATEDIFF(SECOND,'1970-01-01',getdate()) AS bigint) * 1155)+1 AS varchar(20)) )
		SET @Shop_Name = TRIM(@FirstName)+' '+TRIM(isnull(@LastName,''))

		SET @ReferenceType = ''
		SET @ReferenceContactId = ''

		IF(@ReferenceId IS NOT NULL AND @ReferenceId<>'')
		BEGIN
			SET @ReferenceContactId = (SELECT top 1 user_contactId from tbl_master_user where user_contactId=@ReferenceId )

			IF(@ReferenceContactId IS NOT NULL AND @ReferenceContactId<>'')
			BEGIN	
				SET @ReferenceType = 'USER'
			END
			ELSE
			BEGIN
				SET @ReferenceContactId = (SELECT top 1 SHOP_CODE from tbl_Master_shop where SHOP_CODE=@ReferenceId )
				IF(@ReferenceContactId IS NOT NULL AND @ReferenceContactId<>'')
				BEGIN
					SET @ReferenceType = 'SHOP'
				END
			END
		END

		INSERT INTO tbl_Master_shop
			(Shop_Code,Shop_Name,Shop_Owner_Contact,Shop_Owner_Email, Address, dob, date_aniversary, Shop_JobTitle, 
				Shop_CRMCompID, Shop_CreateUser, Shop_CRMTypeID, Shop_CRMStatusID, Shop_CRMSourceID, Shop_CRMReferenceID,
				Shop_CRMStageID, Remarks, Amount, Shop_NextFollowupDate, Entity_Status, ISFROMCRM, Shop_CreateTime,
				Shop_FirstName, Shop_LastName, Shop_CRMReferenceType
			)

			VALUES(@SHOP_CODE,@Shop_Name,@PhoneNo, @Email, @Address, @DOB, @Anniversarydate, @JobTitle,
				@CompanyId, @AssignedTo, @TypeId, @StatusId, @SourceId, @ReferenceContactId, 
				@StageId, @Remarks, @ExpSalesValue, @NextFollowDate, @Active, 1, GETDATE(), @FirstName, @LastName, @ReferenceType
			)

		set @RETURN_VALUE =  @SHOP_CODE

	END
	IF(@ACTION='EDITCRMCONTACT')
	BEGIN
		SET @Strsql = ''
		SET @Strsql=' select SH.Shop_Code, SH.Shop_FirstName, '
		SET @Strsql+=' SH.Shop_LastName, SH.Shop_Owner_Contact, SH.Shop_Owner_Email, SH.Address, SH.DOB, SH.date_aniversary, '
		SET @Strsql+=' SH.Shop_CRMCompID, SH.Shop_JobTitle, SH.Shop_CreateUser, USR.user_name, SH.Shop_CRMTypeID, SH.Shop_CRMStatusID, '
		SET @Strsql+=' SH.Shop_CRMSourceID, SH.Shop_CRMReferenceID, REF.REF_NAME REFERENCE_NAME, SH.Shop_CRMStageID, SH.Remarks, '
		SET @Strsql+=' SH.Amount, SH.Shop_NextFollowupDate, SH.Entity_Status FROM TBL_MASTER_SHOP SH '
		SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_USER USR ON SH.Shop_CreateUser=USR.USER_ID '
		--SET @Strsql+=' LEFT OUTER JOIN CRM_CONTACT_REFERENCE REF ON SH.Shop_CRMReferenceID = REF.REFERENCE_ID '
		SET @Strsql+=' LEFT OUTER JOIN '
		SET @Strsql+=' (SELECT user_contactId REF_ID, USER_NAME REF_NAME FROM  TBL_MASTER_USER U '
			SET @Strsql+=' UNION ALL '
			SET @Strsql+=' SELECT SHOP_CODE AS REF_ID, SHOP_NAME AS REF_NAME FROM TBL_MASTER_SHOP ) REF ON SH.Shop_CRMReferenceID = REF.REF_ID '
		SET @Strsql+=' WHERE SH.ISFROMCRM=1 AND SH.SHOP_CODE= '''+@ShopCode +''' '

		EXEC SP_EXECUTESQL @Strsql
	END
	IF(@ACTION='MODIFYCRMCONTACT')
	BEGIN
		
		SET @Shop_Name = TRIM(@FirstName)+' '+TRIM(@LastName)

		IF(@ReferenceId IS NOT NULL AND @ReferenceId<>'')
		BEGIN
			SET @ReferenceContactId = (SELECT top 1 user_contactId from tbl_master_user where user_contactId=@ReferenceId )

			IF(@ReferenceContactId IS NOT NULL AND @ReferenceContactId<>'')
			BEGIN	
				SET @ReferenceType = 'USER'
			END
			ELSE
			BEGIN
				SET @ReferenceContactId = (SELECT top 1 SHOP_CODE from tbl_Master_shop where SHOP_CODE=@ReferenceId )
				IF(@ReferenceContactId IS NOT NULL AND @ReferenceContactId<>'')
				BEGIN
					SET @ReferenceType = 'SHOP'
				END
			END
		END
		
		UPDATE tbl_Master_shop SET Shop_Name=@Shop_Name, Shop_Owner_Contact=@PhoneNo, Shop_Owner_Email=@Email, Address=@Address, 
			dob=@DOB, date_aniversary=@Anniversarydate, Shop_JobTitle=@JobTitle, Shop_CRMCompID=@CompanyId, Shop_CreateUser=@AssignedTo, 
			Shop_CRMTypeID=@TypeId, Shop_CRMStatusID=@StatusId, Shop_CRMSourceID=@SourceId, Shop_CRMReferenceID=@ReferenceContactId,
			Shop_CRMStageID=@StageId, Remarks=@Remarks, Amount=@ExpSalesValue, Shop_NextFollowupDate=@NextFollowDate, 
			Entity_Status=@Active, Shop_ModifyTime=GETDATE(), Shop_ModifyUser=@user_id, 
			Shop_FirstName=@FirstName, Shop_LastName=@LastName, Shop_CRMReferenceType=@ReferenceType
			WHERE ISFROMCRM=1 AND Shop_Code=@ShopCode

	END
	IF @ACTION='DELETECRMCONTACT'
	BEGIN
		--IF ((SELECT count(0) FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=@ShopCode)>1)
		--BEGIN
		--	SELECT 'Can not delete use in another module.' as MSG
		--END
		--ELSE IF EXISTS(SELECT 1 FROM tbl_trans_fts_Orderupdate WHERE Shop_Code=@ShopCode)
		--BEGIN
		--	SELECT 'Can not delete use in another module.' as MSG
		--END
		--ELSE
		--BEGIN
			--DELETE FROM tbl_trans_shopActivitysubmit WHERE Shop_Id=@ShopCode
			DELETE FROM TBL_MASTER_SHOP WHERE Shop_Code=@ShopCode and ISFROMCRM=1
			SELECT 'Delete Succesfully.' as MSG
		--END
	END
	IF @ACTION='GETREFERENCELIST'
	BEGIN
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USER_ID)		
			CREATE TABLE #EMPHRS
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
		
			INSERT INTO #EMPHRS
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHRS 
			where EMPCODE IS NULL OR EMPCODE=@empcodes  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHRS a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 

		END
		
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
			select top(10) U.user_contactId AS REF_ID, Replace(U.user_name,'''','&#39;') as REF_NAME, U.user_loginId AS REF_PHONE from tbl_Master_user U
			INNER JOIN #EMPHR_EDIT ON user_contactId=EMPCODE
			INNER JOIN tbl_master_employee E ON E.emp_contactId = U.user_contactId
			where (U.user_inactive='N' and U.user_name like '%'+@SearchKey+'%') or  (U.user_inactive='N' and U.user_loginId like '%'+@SearchKey+'%')
					or  (U.user_inactive='N' and E.emp_uniqueCode like '%'+@SearchKey+'%')
			UNION ALL
			SELECT TOP 10 Shop_Code REF_ID, Shop_Name REF_NAME, Shop_Owner_Contact as REF_PHONE FROM TBL_MASTER_SHOP WHERE ISFROMCRM=1 AND Entity_Status=1 
			AND (Shop_Name LIKE '%'+@SearchKey+'%' OR Shop_Owner_Contact LIKE '%'+@SearchKey+'%' )
			
			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END
		ELSE
		BEGIN
			select top(10) U.user_contactId AS REF_ID, Replace(U.user_name,'''','&#39;') AS REF_NAME, U.user_loginId AS REF_PHONE from tbl_Master_user U
			INNER JOIN tbl_master_employee E ON E.emp_contactId = U.user_contactId
			where (U.user_inactive='N' and U.user_name like '%'+@SearchKey+'%') or  (U.user_inactive='N' and U.user_loginId like '%'+@SearchKey+'%')
				or  (U.user_inactive='N' and E.emp_uniqueCode like '%'+@SearchKey+'%')
			UNION ALL
			SELECT TOP 10 Shop_Code REF_ID, Shop_Name REF_NAME, Shop_Owner_Contact as REF_PHONE FROM TBL_MASTER_SHOP WHERE ISFROMCRM=1 AND Entity_Status=1 
			AND (Shop_Name LIKE '%'+@SearchKey+'%' OR Shop_Owner_Contact LIKE '%'+@SearchKey+'%' )
		END
	END
	IF @ACTION='IMPORTCONTACT'
	BEGIN
		declare @i bigint=1
		DECLARE @FirstName1 NVARCHAR(500)
		DECLARE @LastName1 NVARCHAR(500)=NULL
		DECLARE @Phone1 NVARCHAR(500)
		DECLARE @Email1 NVARCHAR(500)=NULL
		DECLARE @Address1 NVARCHAR(500)=NULL
		DECLARE @DateofBirth1 NVARCHAR(500)=null
		DECLARE @DateofAnniversary1 NVARCHAR(500)=null
		DECLARE @Company1 NVARCHAR(500)=null
		DECLARE @JobTitle1 NVARCHAR(500)=NULL
		DECLARE @AssignTo1 NVARCHAR(500)=null
		DECLARE @Type1 NVARCHAR(500)=null
		DECLARE @Status1 NVARCHAR(500)=null
		DECLARE @Source1 NVARCHAR(500)=null
		DECLARE @Reference1 NVARCHAR(500)=null
		DECLARE @Stages1 NVARCHAR(500)=null
		DECLARE @Remarks1 NVARCHAR(500)=NULL
		DECLARE @ExpectedSalesValue1 DECIMAL(18,2)=null
		DECLARE @NextfollowUpDate1 NVARCHAR(500)=null
		DECLARE @Active1 NVARCHAR(500)=null

		DECLARE @CompanyID1 INT
		DECLARE @AssignToID1 INT
		DECLARE @TypeID1 INT
		DECLARE @StatusID1 INT
		DECLARE @SourceID1 INT
		DECLARE @ReferenceID1 VARCHAR(100)
		DECLARE @StagesID1 INT
		DECLARE @ReferenceType1 VARCHAR(10)=''
		DECLARE @ActiveVal bit = 0;

		DECLARE DB_CURSOR CURSOR FOR
		SELECT [FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], 
						[AssignTo], [Type], [Status], [Source], [Reference], 
						[Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active] FROM @IMPORT_TABLE where [FirstName] is not NULL
		OPEN DB_CURSOR
		FETCH NEXT FROM DB_CURSOR INTO @FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
								@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
								@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1
		WHILE @@FETCH_STATUS=0
		BEGIN
			SET @CompanyID1 = (SELECT [COMPANY_ID] FROM CRM_CONTACT_COMPANY WHERE [COMPANY_NAME]=ISNULL(@Company1,''))
			SET @AssignToID1 = (SELECT user_id FROM TBL_MASTER_USER WHERE user_loginId=ISNULL(@AssignTo1,'') )
			SET @TypeID1 = (SELECT [TYPE_ID] FROM CRM_CONTACT_TYPE WHERE [TYPE_NAME]=ISNULL(@Type1,'') )
			SET @StatusID1 = (SELECT [STATUS_ID] FROM CRM_CONTACT_STATUS WHERE [STATUS_NAME]=ISNULL(@Status1,'') )
			SET @SourceID1 = (SELECT [SOURCE_ID] FROM CRM_CONTACT_SOURCE WHERE [SOURCE_NAME]=ISNULL(@Source1,'') )
			
			IF ISNULL(@Source1,'')='Reference'
			BEGIN
				SET @ReferenceID1 = (SELECT user_contactId FROM TBL_MASTER_USER WHERE user_loginId=ISNULL(@Reference1,'') )
			
				IF(ISNULL(@ReferenceID1,'')<>'')
				BEGIN
					SET @ReferenceType1 = 'USER'
				END
				ELSE
				BEGIN
					SET @ReferenceID1 = (SELECT SHOP_CODE FROM TBL_MASTER_SHOP WHERE Shop_Owner_Contact=ISNULL(@Reference1,'') )
					SET @ReferenceType1 = 'SHOP'
				END
			END
			ELSE
			BEGIN
				SET @Reference1 = ''
			END

			SET @StagesID1 = (SELECT STAGE_ID FROM CRM_CONTACT_STAGE WHERE STAGE_NAME=ISNULL(@Stages1,'') )

			if(@Active1='Yes')
				set @Active1 = 1;
			else
				set @Active1 = 0;

			IF (TRIM(ISNULL(@Phone1,''))<>'' AND LEFT(TRIM(ISNULL(@Phone1,'')),1)<>'0' AND LEN(TRIM(ISNULL(@Phone1,'')))=10 )
			BEGIN  -- 1
				IF TRIM(ISNULL(@Status1,''))='' OR (TRIM(ISNULL(@Status1,''))<>'' AND ISNULL(@StatusID1,'')<>'')
				BEGIN -- 2
				
					IF TRIM(ISNULL(@Company1,''))='' OR (TRIM(ISNULL(@Company1,''))<>'' AND ISNULL(@CompanyID1,'')<>'')
					BEGIN-- 3
						IF TRIM(ISNULL(@AssignTo1,''))<>''
						BEGIN -- 4
							IF TRIM(ISNULL(@AssignTo1,''))<>'' AND ISNULL(@AssignToID1,'')<>''
							BEGIN -- 5
								IF TRIM(ISNULL(@Type1,''))='' OR (TRIM(ISNULL(@Type1,''))<>'' AND ISNULL(@TypeID1,'')<>'')
								BEGIN  -- 6
									IF TRIM(ISNULL(@Status1,''))='' OR (TRIM(ISNULL(@Status1,''))<>'' AND ISNULL(@StatusID1,'')<>'')
									BEGIN  -- 7
										IF TRIM(ISNULL(@Source1,''))='' OR (TRIM(ISNULL(@Source1,''))<>'' AND ISNULL(@SourceID1,'')<>'')
										BEGIN -- 8
											IF TRIM(ISNULL(@Reference1,''))='' OR (TRIM(ISNULL(@Reference1,''))<>'' AND ISNULL(@ReferenceID1,'')<>'')
											BEGIN  -- 9
												IF TRIM(ISNULL(@Stages1,''))='' OR (TRIM(ISNULL(@Stages1,''))<>'' AND ISNULL(@StagesID1,'')<>'')
												BEGIN  -- 10
													IF ( @ExpectedSalesValue1>=0 AND @ExpectedSalesValue1<=999999999999999.99 ) 
													BEGIN -- 11
														IF ( 
															(@DateofBirth1 IS NULL OR ISNULL(@DateofBirth1,'')='' OR (ISNULL(@DateofBirth1,'')<>'' AND CONVERT(DATE,@DateofBirth1)<=GETDATE()) )
															AND (@DateofAnniversary1 IS NULL OR ISNULL(@DateofAnniversary1,'')='' OR (ISNULL(@DateofAnniversary1,'')<>'' AND CONVERT(DATE,@DateofAnniversary1)<=GETDATE()) )
															AND (@NextfollowUpDate1 IS NULL OR ISNULL(@NextfollowUpDate1,'')='' OR (ISNULL(@NextfollowUpDate1,'')<>'' AND CONVERT(DATE,@NextfollowUpDate1)>GETDATE()) ) 
															)
														BEGIN -- 12
															SET @SHOP_CODE=CAST(@user_id AS varchar(20)) + '_' + cast((CAST(DATEDIFF(SECOND,'1970-01-01',getdate()) AS bigint) * 1155)+@i AS varchar(20))
															SET @Shop_Name = TRIM(@FirstName1)+' '+TRIM(isnull(@LastName1,''))

															IF NOT EXISTS(SELECT SHOP_CODE FROM TBL_MASTER_SHOP 
																WHERE TRIM(Shop_FirstName)=TRIM(@FirstName1) AND TRIM(Shop_LastName)=TRIM(@LastName1) AND TRIM(Shop_Owner_Contact)=TRIM(@Phone1) 
																AND  TRIM(Shop_Owner_Email)=TRIM(@Email1) AND TRIM([Address])=TRIM(@Address1) 
																AND CONVERT(DATE,dob)=CONVERT(DATE,@DateofBirth1) 
																AND CONVERT(DATE,date_aniversary)=CONVERT(DATE,@DateofAnniversary1) AND Shop_CRMCompID=ISNULL(@CompanyID1,0) 
																AND TRIM(Shop_JobTitle)=TRIM(@JobTitle1) AND Shop_CreateUser=ISNULL(@AssignToID1,0) 
																AND Shop_CRMTypeID=ISNULL(@TypeID1,0) AND Shop_CRMStatusID=ISNULL(@StatusID1,0) 
																AND Shop_CRMSourceID=ISNULL(@SourceID1,0) AND Shop_CRMReferenceID=ISNULL(@ReferenceID1,0)
																AND Shop_CRMStageID=ISNULL(@StagesID1,0) AND TRIM(Remarks)=TRIM(@Remarks1) AND Amount=@ExpectedSalesValue1 
																AND CONVERT(DATE,Shop_NextFollowupDate)=CONVERT(DATE,@NextfollowUpDate1) )
															BEGIN  -- 13
																INSERT INTO tbl_Master_shop
																(Shop_Code,Shop_Name,Shop_Owner_Contact,Shop_Owner_Email, Address, dob, date_aniversary, Shop_JobTitle, 
																	Shop_CRMCompID, Shop_CreateUser, Shop_CRMTypeID, Shop_CRMStatusID, Shop_CRMSourceID, Shop_CRMReferenceID,
																	Shop_CRMStageID, Remarks, Amount, Shop_NextFollowupDate, Entity_Status, ISFROMCRM, Shop_CreateTime,
																	Shop_FirstName, Shop_LastName, Shop_CRMReferenceType
																)

																VALUES(@SHOP_CODE,@Shop_Name,@Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @JobTitle1,
																	ISNULL(@CompanyID1,0), ISNULL(@AssignToID1,0), ISNULL(@TypeId1,0), ISNULL(@StatusId1,0), ISNULL(@SourceId1,0), 
																	ISNULL(@ReferenceID1,0), ISNULL(@StagesID1,0), @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, 
																	@Active1, 1, GETDATE(), @FirstName1, @LastName1, @ReferenceType1
																)
												

																INSERT INTO FTS_CRMContactImportLog
																	([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
																	[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
																	[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

																VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
																	@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
																	@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
																	'Sucess','Sucess',GETDATE(), @User_Id )
															END -- 13
															ELSE
															BEGIN
																INSERT INTO FTS_CRMContactImportLog
																([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
																[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
																[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

																VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
																@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
																@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
																'Failed','Record already exists.',GETDATE(), @User_Id )
															END -- 13
														END -- 12
														ELSE
														BEGIN
															INSERT INTO FTS_CRMContactImportLog
															([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
															[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
															[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

															VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
															@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
															@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
															'Failed','Date of Birth and Date of Anniversary should be within current date and Next follow up Date should be after current date.',GETDATE(), @User_Id )
														END -- 12
													END -- 11
													ELSE
													BEGIN
														INSERT INTO FTS_CRMContactImportLog
														([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
														[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
														[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

														VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
														@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
														@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
														'Failed','Invalid Expcted Sales value.',GETDATE(), @User_Id )
													END -- 11
												
												END -- 10
												ELSE
												BEGIN
													INSERT INTO FTS_CRMContactImportLog
														([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
														[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
														[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

													VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
														@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
														@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
														'Failed','Invalid Stage.',GETDATE(), @User_Id )
												END -- 10
											END --9
											ELSE
											BEGIN
												INSERT INTO FTS_CRMContactImportLog
													([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
													[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
													[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

												VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
													@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
													@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
													'Failed','Invalid Reference Name.',GETDATE(), @User_Id )
											END -- 9
										END -- 8
										ELSE
										BEGIN
											INSERT INTO FTS_CRMContactImportLog
												([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
												[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
												[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

											VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
												@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
												@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
												'Failed','Invalid Source.',GETDATE(), @User_Id )
										END  --8
									END -- 7
									ELSE
									BEGIN
										INSERT INTO FTS_CRMContactImportLog
											([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
											[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
											[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

										VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
											@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
											@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
											'Failed','Invalid Status.',GETDATE(), @User_Id )
									END  -- 7
								END -- 6
								ELSE
								BEGIN
									INSERT INTO FTS_CRMContactImportLog
										([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
										[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
										[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

									VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
										@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
										@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
										'Failed','Invalid Type.',GETDATE(), @User_Id )
								END  --6
							END  -- 5
							ELSE
							BEGIN
								INSERT INTO FTS_CRMContactImportLog
									([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
									[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
									[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

								VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
									@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
									@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
									'Failed','Invalid Assign To.',GETDATE(), @User_Id )
							END-- 5
						END  -- 4
						ELSE
						BEGIN
							INSERT INTO FTS_CRMContactImportLog
								([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
								[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
								[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

							VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
								@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
								@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
								'Failed','Assign To not given.',GETDATE(), @User_Id )
						END-- 4

					END --3
					ELSE
					BEGIN
						INSERT INTO FTS_CRMContactImportLog
							([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
							[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
							[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

						VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
							@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
							@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
							'Failed','Invalid Company',GETDATE(), @User_Id )
					END -- 3
				END -- 2
				ELSE
				BEGIN
					INSERT INTO FTS_CRMContactImportLog
					([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
					[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
					[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

					VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
							@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
							@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
							'Failed','Invalid Status',GETDATE(), @User_Id )
				END -- 2
			END -- 1
			ELSE
			BEGIN
				INSERT INTO FTS_CRMContactImportLog
				([FirstName], [LastName], [Phone], [Email], [Address], [DateofBirth], [DateofAnniversary], [Company], [JobTitle], [AssignTo], [Type],
				[Status], [Source], [Reference], [Stages], [Remarks], [ExpectedSalesValue], [NextfollowUpDate], [Active], 
				[ImportStatus], [ImportMsg], [ImportDate], [CreateUser] )

				VALUES(@FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
				@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
				@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1,
				'Failed','Phone number cannot be blank or start with zero and should be of 10 digits.',GETDATE(), @User_Id )
			END -- 1

			SET @i=@i+1
			
			FETCH NEXT FROM DB_CURSOR INTO @FirstName1, @LastName1, @Phone1, @Email1, @Address1, @DateofBirth1, @DateofAnniversary1, @Company1, @JobTitle1, 
							@AssignTo1, @Type1, @Status1, @Source1, @Reference1, 
							@Stages1, @Remarks1, @ExpectedSalesValue1, @NextfollowUpDate1, @Active1
			
		END

		close db_cursor
		deallocate db_cursor

		SELECT logs.* FROM FTS_CRMContactImportLog AS logs
		INNER JOIN @IMPORT_TABLE temp ON logs.[FirstName] =temp.[FirstName] 

	END
	IF @ACTION='SHOWIMPORTLOG'
	BEGIN
		select distinct logs.[FirstName], logs.[LastName], logs.[Phone], logs.[Email], logs.[Address], CONVERT(NVARCHAR(10),logs.[DateofBirth],105) DateofBirth, 
				CONVERT(NVARCHAR(10),logs.[DateofAnniversary],105) [DateofAnniversary], 
				logs.[Company], logs.[JobTitle], logs.[AssignTo], logs.[Type], logs.[Status], logs.[Source], logs.[Reference], logs.[Stages], 
				logs.[Remarks], logs.[ExpectedSalesValue], CONVERT(NVARCHAR(10),logs.[NextfollowUpDate],105) [NextfollowUpDate], 
				(case when logs.[Active]=1 then 'Yes' else 'No' end) Active , logs.[ImportStatus], logs.[ImportMsg], CONVERT(NVARCHAR(10),logs.[ImportDate],105) [ImportDate], 
				logs.[CreateUser] 
		from FTS_CRMContactImportLog as logs 
		inner join @IMPORT_TABLE temp ON 
		logs.[FirstName]=temp.[FirstName] AND logs.[LastName]=temp.[LastName] AND logs.[Phone]=temp.[Phone] AND logs.[Email]=temp.[Email] AND 
		logs.[Address]=temp.[Address] AND convert(date,logs.[DateofBirth])=convert(date,temp.[DateofBirth])  
		AND convert(date,logs.[DateofAnniversary])=convert(date,temp.[DateofAnniversary]) AND 
		logs.[Company]=temp.[Company] AND logs.[JobTitle]=temp.[JobTitle] AND logs.[AssignTo]=temp.[AssignTo] AND logs.[Type]=temp.[Type] AND
		logs.[Status]=temp.[Status] AND logs.[Source]=temp.[Source] AND logs.[Reference]=temp.[Reference] AND logs.[Stages]=temp.[Stages] AND 
		logs.[Remarks]=temp.[Remarks] AND logs.[ExpectedSalesValue]=temp.[ExpectedSalesValue] 
		AND convert(date, logs.[NextfollowUpDate])=convert(date,temp.[NextfollowUpDate])

	END
	ELSE IF (@Action='GETCRMCONTACTIMPORTLOG')
	BEGIN
		SELECT logs.[FirstName], logs.[LastName], logs.[Phone], logs.[Email], logs.[Address], CONVERT(NVARCHAR(10),logs.[DateofBirth],105) DateofBirth, 
				CONVERT(NVARCHAR(10),logs.[DateofAnniversary],105) [DateofAnniversary], 
				logs.[Company], logs.[JobTitle], logs.[AssignTo], logs.[Type], logs.[Status], logs.[Source], logs.[Reference], logs.[Stages], 
				logs.[Remarks], logs.[ExpectedSalesValue], CONVERT(NVARCHAR(10),logs.[NextfollowUpDate],105) [NextfollowUpDate], 
				logs.[Active]
			FROM FTS_CRMContactImportLog logs
			WHERE convert(date, ImportDate) BETWEEN @FromDate AND @ToDate
			ORDER BY ImportDate DESC
	END
END
GO