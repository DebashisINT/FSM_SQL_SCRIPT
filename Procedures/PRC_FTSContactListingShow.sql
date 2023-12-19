IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSContactListingShow]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSContactListingShow] AS'  
END 
GO

--exec PRC_FTSContactListingShow @ACTION='GETLISTINGDATA', @IS_PAGELOAD='', @USERID='378',@CONTACTSFROM='', @FROMDATE='2023-12-12',@TODATE='2023-12-12'

ALTER PROCEDURE [dbo].[PRC_FTSContactListingShow]
(
@ACTION NVARCHAR(500)=NULL,
@IS_PAGELOAD NVARCHAR(100)=NULL,
@USERID INT=NULL,
@CONTACTSFROM NVARCHAR(500)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL
)
 
AS
/****************************************************************************************************************************************************************************
Written by Sanchita on 23-11-2023 for V2.0.43	A new design page is required as Contact (s) under CRM menu. 
												Refer: 27034
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX)

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'CRM_CONTACT_LISTING') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE CRM_CONTACT_LISTING
		(
			USERID INT,
			SEQ INT,
			Shop_Code varchar(100),
			Shop_FirstName NVARCHAR(500) NULL,
			Shop_LastName NVARCHAR(500) NULL,
			Shop_Owner_Contact NVARCHAR(100) NULL,
			Shop_Owner_Email NVARCHAR(300) NULL,
			Shop_Address NVARCHAR(max) NULL,
			Shop_DOB NVARCHAR(50) NULL,
			Shop_date_aniversary NVARCHAR(50) NULL,
			Shop_CompanyName NVARCHAR(200) NULL,
			Shop_JobTitle NVARCHAR(500) NULL,
			Shop_CreateUserName ntext NULL,
			Shop_TypeName NVARCHAR(200) NULL,
			Shop_StatusName NVARCHAR(200) NULL,
			Shop_SourceName NVARCHAR(200) NULL,
			Shop_ReferenceName NVARCHAR(200) NULL,
			Shop_StageName NVARCHAR(200) NULL,
			Shop_Remarks NVARCHAR(max) NULL,
			Shop_Amount Decimal(18,2) NULL,
			Shop_NextFollowupDate NVARCHAR(50) NULL,
			Shop_Entity_Status VARCHAR(10) NULL
		)
		CREATE NONCLUSTERED INDEX IX1 ON CRM_CONTACT_LISTING (SEQ)
	END
		

	IF(@ACTION='GETLISTINGDATA')
	BEGIN
		if(@IS_PAGELOAD <> 'is_pageload')
		BEGIN
			set @CONTACTSFROM = ''''+ replace(@CONTACTSFROM,',',''',''') + ''''

			DELETE FROM CRM_CONTACT_LISTING WHERE USERID=@USERID
			
			IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
				DROP TABLE #TEMPCONTACT
			CREATE TABLE #TEMPCONTACT
				(
					cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_UCC NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				)
			CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
 
 			SET @Strsql=' INSERT INTO CRM_CONTACT_LISTING (USERID, SEQ, Shop_Code, Shop_FirstName, Shop_LastName, Shop_Owner_Contact, '
			SET @Strsql+=' Shop_Owner_Email, Shop_Address, Shop_DOB, Shop_date_aniversary, Shop_CompanyName, Shop_JobTitle, '
			SET @Strsql+=' Shop_CreateUserName, Shop_TypeName, Shop_StatusName, Shop_SourceName, Shop_ReferenceName, Shop_StageName, '
			SET @Strsql+=' Shop_Remarks, Shop_Amount, Shop_NextFollowupDate, Shop_Entity_Status) '
			SET @Strsql+=' select '+STR(@USERID)+',ROW_NUMBER() OVER(ORDER BY SH.Shop_CreateTime) AS SEQ,SH.Shop_Code, SH.Shop_FirstName, '
			SET @Strsql+=' SH.Shop_LastName, SH.Shop_Owner_Contact, SH.Shop_Owner_Email, SH.Address, CONVERT(NVARCHAR(10),SH.DOB,105), CONVERT(NVARCHAR(10),SH.date_aniversary,105), '
			SET @Strsql+=' ISNULL(COMP.COMPANY_NAME,''''), SH.Shop_JobTitle, USR.user_name, TYP.TYPE_NAME, STAT.STATUS_NAME, SRC.SOURCE_NAME, '
			SET @Strsql+=' REF.REF_NAME AS REFERENCE_NAME, STG.STAGE_NAME, SH.Remarks, SH.Amount, CONVERT(NVARCHAR(10),SH.Shop_NextFollowupDate,105), '
			SET @Strsql+=' (CASE WHEN SH.Entity_Status=1 THEN ''Yes'' else ''No'' END ) '
			SET @Strsql+=' FROM TBL_MASTER_SHOP SH '
			SET @Strsql+=' LEFT OUTER JOIN CRM_CONTACT_COMPANY COMP ON SH.Shop_CRMCompID=COMP.COMPANY_ID '
			SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_USER USR ON SH.Shop_CreateUser=USR.USER_ID '
			SET @Strsql+=' LEFT OUTER JOIN CRM_CONTACT_TYPE TYP ON SH.Shop_CRMTypeID = TYP.TYPE_ID '
			SET @Strsql+=' LEFT OUTER JOIN CRM_CONTACT_STATUS STAT ON SH.Shop_CRMStatusID = STAT.STATUS_ID '
			SET @Strsql+=' LEFT OUTER JOIN CRM_CONTACT_SOURCE SRC ON SH.Shop_CRMSourceID = SRC.SOURCE_ID '
			--SET @Strsql+=' LEFT OUTER JOIN CRM_CONTACT_REFERENCE REF ON SH.Shop_CRMReferenceID = REF.REFERENCE_ID '
			--SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_USER REF ON SH.Shop_CRMReferenceID = REF.user_contactId '
			SET @Strsql+=' LEFT OUTER JOIN '
			SET @Strsql+=' (SELECT user_contactId REF_ID, USER_NAME REF_NAME FROM  TBL_MASTER_USER U '
			SET @Strsql+=' UNION ALL '
			SET @Strsql+=' SELECT SHOP_CODE AS REF_ID, SHOP_NAME AS REF_NAME FROM TBL_MASTER_SHOP ) REF ON SH.Shop_CRMReferenceID = REF.REF_ID '
			SET @Strsql+=' LEFT OUTER JOIN CRM_CONTACT_STAGE STG ON SH.Shop_CRMStageID = STG.STAGE_ID '
			SET @Strsql+=' WHERE SH.ISFROMCRM=1 AND CONVERT(DATE,SH.Shop_CreateTime)>='''+@FROMDATE+''' AND CONVERT(DATE,SH.Shop_CreateTime)<='''+@TODATE+'''  '


			--SELECT @Strsql

			EXEC SP_EXECUTESQL @Strsql

			drop table #TEMPCONTACT
		END
	END
	ELSE IF(@ACTION='GetDropdownBindData')
	begin
		-- Company
		SELECT '0' AS CompanyId,'-- Select --' AS CompanyName
		UNION ALL
		SELECT convert(nvarchar(10),COMPANY_ID) as CompanyId, COMPANY_NAME as CompanyName from CRM_CONTACT_COMPANY where IsActive=1 order by CompanyId

		-- Assign To
		SELECT '0' AS AssignToId,'-- Select --' AS AssignToName
		UNION ALL
		SELECT convert(nvarchar(10),user_id) as AssignToId ,user_name as AssignToName FROM tbl_master_user WHERE user_inactive='N' order by AssignToId

		-- Type
		SELECT '0' AS TypeId,'-- Select --' AS TypeName
		UNION ALL
		SELECT convert(nvarchar(10),TYPE_ID) as TypeId ,TYPE_NAME as TypeName FROM CRM_CONTACT_TYPE WHERE IsActive=1 order by TypeId

		-- Status
		SELECT '0' AS StatusId,'-- Select --' AS StatusName
		UNION ALL
		SELECT convert(nvarchar(10),STATUS_ID) as StatusId ,STATUS_NAME as StatusName FROM CRM_CONTACT_STATUS WHERE IsActive=1 order by StatusId

		-- Source
		SELECT '0' AS SourceId,'-- Select --' AS SourceName
		UNION ALL
		SELECT convert(nvarchar(10),SOURCE_ID) as SourceId ,SOURCE_NAME as SourceName FROM CRM_CONTACT_SOURCE WHERE IsActive=1 order by SourceId

		-- Stage
		SELECT '0' AS StageId,'-- Select --' AS StageName
		UNION ALL
		SELECT convert(nvarchar(10),STAGE_ID) as StageId ,STAGE_NAME as StageName FROM CRM_CONTACT_STAGE WHERE IsActive=1 order by StageId

		-- Reference
		--SELECT '0' AS ReferenceId,'-- Select --' AS ReferenceName
		--UNION ALL
		--SELECT user_id as ReferenceId ,user_name as ReferenceName FROM tbl_master_user WHERE user_inactive='N' order by ReferenceId

		

	end
	ELSE IF(@ACTION='GetContactFrom')
	begin
		SELECT EnqID, EnquiryFromDesc from tbl_master_EnquiryFrom order by EnqID
	end
	ELSE IF(@ACTION='GETTOTALCONTACTSCOUNT')
	begin
		DECLARE @TotalContacts INT = 0

		IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'CRM_CONTACT_LISTING') AND TYPE IN (N'U'))
		BEGIN
			SET @TotalContacts = (SELECT COUNT(0) FROM CRM_CONTACT_LISTING WHERE USERID=@USERID)
		END

		SELECT @TotalContacts AS cnt_TotalContacts

	end
END
GO