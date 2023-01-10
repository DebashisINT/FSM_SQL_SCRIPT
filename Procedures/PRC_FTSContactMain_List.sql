
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSContactMain_List]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSContactMain_List] AS' 
END
GO


 --EXEC PRC_FTSContactMain_List @REQUESTTYPE1='Salesman/Agents', @ALLUSERCNTID='EMB0000002,EMV0000001,EMG0000001',
	--@HDNISDMSFEATUREON='False', @USERBRANCHHIERARCHY ='119,118,120,121,123,126,122,124,125,127,1', @USERID='378'

ALTER PROCEDURE [dbo].[PRC_FTSContactMain_List]
(
@REQUESTTYPE1 NVARCHAR(500)=NULL,
@ALLUSERCNTID NVARCHAR(MAX)=NULL,
@HDNISDMSFEATUREON NVARCHAR(50)=NULL,
@USERBRANCHHIERARCHY NVARCHAR(MAX)=NULL,
@USERID INT =NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
New SP		Sanchita	v2.0.36			10-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" then data in portal shall be populated based on Hierarchy Only.
													Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	set @ALLUSERCNTID = replace(@ALLUSERCNTID,',',''',''')

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_Newid=@USERID)=1)
	BEGIN
		DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
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
		
		INSERT INTO #EMPHR
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'''') RPTTOEMPCODE 
		FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
		;with cte as(select	
		EMPCODE,RPTTOEMPCODE
		from #EMPHR 
		where EMPCODE IS NULL OR EMPCODE=@empcode  
		union all
		select	
		a.EMPCODE,a.RPTTOEMPCODE
		from #EMPHR a
		join cte b
		on a.RPTTOEMPCODE = b.EMPCODE
		) 
		INSERT INTO #EMPHR_EDIT
		select EMPCODE,RPTTOEMPCODE  from cte 

	END

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
		CREATE TABLE #TEMPCONTACT
		(
			[cnt_id] [int] NOT NULL,
			[cnt_internalId] [varchar](10) NOT NULL,
			[cnt_branchid] [int] NOT NULL,
			[cnt_accessLevel] [numeric](10, 0) NULL,
			[cnt_addDate] [datetime] NULL,
			[cnt_modUserId] [int] NULL,
			[cnt_modDate] [datetime] NULL,
			[cnt_UCC] [varchar](80) NULL,
			[cnt_salutation] [int] NULL,
			[cnt_firstName] [varchar](150) NOT NULL,
			[cnt_middleName] [varchar](50) NULL,
			[cnt_lastName] [varchar](50) NULL,
			[cnt_shortName] [varchar](80) NULL,
			[cnt_contactSource] [numeric](10, 0) NULL,
			[cnt_contactType] [varchar](50) NULL,
			[cnt_legalStatus] [numeric](10, 0) NULL,
			[cnt_referedBy] [varchar](100) NULL,
			[cnt_relation] [int] NULL,
			[cnt_contactStatus] [int] NULL,
			[cnt_speakLanguage] [varchar](50) NULL,
			[cnt_writeLanguage] [varchar](50) NULL,
			[cnt_dOB] [datetime] NULL,
			[cnt_maritalStatus] [int] NULL,
			[cnt_anniversaryDate] [datetime] NULL,
			[cnt_education] [int] NULL,
			[cnt_profession] [int] NULL,
			[cnt_jobResponsibility] [int] NULL,
			[cnt_organization] [varchar](150) NULL,
			[cnt_industry] [int] NULL,
			[cnt_designation] [numeric](18, 0) NULL,
			[cnt_preferedContact] [varchar](50) NULL,
			[cnt_sex] [tinyint] NULL,
			[cnt_UserAccess] [nvarchar](500) NULL,
			[cnt_RelationshipManager] [varchar](50) NULL,
			[cnt_salesRepresentative] [varchar](50) NULL,
			[CreateDate] [datetime] NULL,
			[CreateUser] [int] NULL,
			[LastModifyDate] [datetime] NULL,
			[LastModifyUser] [int] NULL,
			[cnt_LeadId] [varchar](50) NULL,
			[cnt_RegistrationDate] [datetime] NULL,
			[cnt_rating] [tinyint] NULL,
			[cnt_reason] [varchar](400) NULL,
			[cnt_status] [varchar](50) NULL,
			[cnt_Lead_Stage] [int] NULL,
			[cnt_bloodgroup] [varchar](50) NULL,
			[LastModifyDate_DLMAST] [varchar](20) NULL,
			[LastLoginDateTime] [datetime] NULL,
			[WebLogIn] [char](3) NULL,
			[PassWord] [varchar](50) NULL,
			[cnt_clienttype] [varchar](20) NULL,
			[cnt_Custodian] [char](10) NULL,
			[cnt_SettlementMode] [char](1) NULL,
			[cnt_ContractDeliveryMode] [char](1) NULL,
			[cnt_DirectTMClient] [char](1) NULL,
			[cnt_RelationshipWithDirector] [char](1) NULL,
			[cnt_DirectorID] [char](10) NULL,
			[cnt_DirectorClientRelation] [tinyint] NULL,
			[cnt_HasOtherAccount] [char](1) NULL,
			[cnt_FamilyGroupCode] [char](10) NULL,
			[cnt_GroupSettlementMode] [char](1) NULL,
			[cnt_STPProvider] [char](1) NULL,
			[cnt_FundManagerID] [char](10) NULL,
			[cnt_tradingCode] [char](10) NULL,
			[cnt_SpecialCategory] [varchar](50) NULL,
			[cnt_RiskCategory] [varchar](25) NULL,
			[cnt_CompanyID] [varchar](10) NULL,
			[cnt_InPersonVerificationDone] [char](1) NULL,
			[cnt_InPersonVerificationDate] [datetime] NULL,
			[cnt_InPersonVerificationBy] [varchar](10) NULL,
			[cnt_VerifcationRemarks] [varchar](150) NULL,
			[cnt_OtherBOCode] [varchar](20) NULL,
			[cnt_PEP] [tinyint] NULL,
			[cnt_PlaceOfIncorporation] [varchar](100) NULL,
			[cnt_BusinessComncDate] [datetime] NULL,
			[cnt_OtherOccupation] [varchar](100) NULL,
			[cnt_nationality] [int] NULL,
			[cnt_IsCreditHold] [bit] NULL,
			[cnt_CreditDays] [int] NULL,
			[cnt_CreditLimit] [money] NULL,
			[Is_Active] [bit] NOT NULL,
			[Statustype] [varchar](5) NULL,
			[CNT_GSTIN] [varchar](15) NULL,
			[cnt_AssociatedEmp] [nvarchar](15) NULL,
			[cnt_mainAccount] [varchar](50) NULL,
			[cnt_subAccount] [varchar](50) NULL,
			[cnt_IdType] [int] NOT NULL,
			[cnt_PrintNameToCheque] [varchar](200) NULL,
			[cnt_EntityType] [varchar](2) NULL,
			[AccountGroupID] [int] NOT NULL,
			[cnt_OtherID] [varchar](300) NOT NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	
	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT CNT.cnt_id,CNT.cnt_internalId,CNT.cnt_branchid,CNT.cnt_accessLevel,CNT.cnt_addDate,CNT.cnt_modUserId,CNT.cnt_modDate,CNT.cnt_UCC,CNT.cnt_salutation,CNT.cnt_firstName'
	SET @Strsql+=' ,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_shortName,CNT.cnt_contactSource,CNT.cnt_contactType,CNT.cnt_legalStatus,CNT.cnt_referedBy,CNT.cnt_relation,CNT.cnt_contactStatus'
	SET @Strsql+=' ,CNT.cnt_speakLanguage,CNT.cnt_writeLanguage,CNT.cnt_dOB,CNT.cnt_maritalStatus,CNT.cnt_anniversaryDate,CNT.cnt_education,CNT.cnt_profession,CNT.cnt_jobResponsibility'
	SET @Strsql+=' ,CNT.cnt_organization,CNT.cnt_industry,CNT.cnt_designation,CNT.cnt_preferedContact,CNT.cnt_sex,CNT.cnt_UserAccess,CNT.cnt_RelationshipManager,CNT.cnt_salesRepresentative'
	SET @Strsql+=' ,CNT.CreateDate,CNT.CreateUser,CNT.LastModifyDate,CNT.LastModifyUser,CNT.cnt_LeadId,CNT.cnt_RegistrationDate,CNT.cnt_rating,CNT.cnt_reason,CNT.cnt_status,CNT.cnt_Lead_Stage'
	SET @Strsql+=' ,CNT.cnt_bloodgroup,CNT.LastModifyDate_DLMAST,CNT.LastLoginDateTime,CNT.WebLogIn,CNT.PassWord,CNT.cnt_clienttype,CNT.cnt_Custodian,CNT.cnt_SettlementMode,CNT.cnt_ContractDeliveryMode'
	SET @Strsql+=' ,CNT.cnt_DirectTMClient,CNT.cnt_RelationshipWithDirector,CNT.cnt_DirectorID,CNT.cnt_DirectorClientRelation,CNT.cnt_HasOtherAccount,CNT.cnt_FamilyGroupCode,CNT.cnt_GroupSettlementMode'
	SET @Strsql+=' ,CNT.cnt_STPProvider,CNT.cnt_FundManagerID,CNT.cnt_tradingCode,CNT.cnt_SpecialCategory,CNT.cnt_RiskCategory,CNT.cnt_CompanyID,CNT.cnt_InPersonVerificationDone,CNT.cnt_InPersonVerificationDate'
	SET @Strsql+=' ,CNT.cnt_InPersonVerificationBy,CNT.cnt_VerifcationRemarks,CNT.cnt_OtherBOCode,CNT.cnt_PEP ,CNT.cnt_PlaceOfIncorporation,CNT.cnt_BusinessComncDate,CNT.cnt_OtherOccupation'
	SET @Strsql+=' ,CNT.cnt_nationality,CNT.cnt_IsCreditHold,CNT.cnt_CreditDays,CNT.cnt_CreditLimit,CNT.Is_Active,CNT.Statustype,CNT.CNT_GSTIN,CNT.cnt_AssociatedEmp,CNT.cnt_mainAccount'
	SET @Strsql+=' ,CNT.cnt_subAccount,CNT.cnt_IdType,CNT.cnt_PrintNameToCheque,CNT.cnt_EntityType,CNT.AccountGroupID,CNT.cnt_OtherID'
	SET @Strsql+=' FROM TBL_MASTER_CONTACT CNT '
	--SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE    '
	END
	--SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
	--select @Strsql
	EXEC SP_EXECUTESQL @Strsql

	set @Strsql = ''

	if (@REQUESTTYPE1 = 'Customer/Client')
    BEGIN
            --DataSet CntId = oDBEngine.PopulateData('user_contactid', 'tbl_master_user', ' user_id in(' + HttpContext.Current.Session['userchildHierarchy'] + ')');
            --for (int i = 0; i < CntId.Tables[0].Rows.Count; i++)
            --{
            --    if (i == 0)
            --    {
            --        AllUserCntId = Convert.ToString(CntId.Tables[0].Rows[i]['user_contactid']);
            --    }
            --    else
            --    {
            --        AllUserCntId += ',' + Convert.ToString(CntId.Tables[0].Rows[i]['user_contactid']);
            --    }

            --}


            SET @Strsql =  'select * from (select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin, (select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select top 1 ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +;''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,'''' AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select top 1 ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status, Case #TEMPCONTACT.Statustype when ''A'' then ''Active'' when ''D'' then ''Dormant'' END as Activetype,  tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where (#TEMPCONTACT.cnt_branchid in (select branch_id from tbl_master_branch) or #TEMPCONTACT.cnt_RelationShipManager in (''' + @ALLUSERCNTID + ''') or #TEMPCONTACT.cnt_salesrepresentative in (''' + @ALLUSERCNTID + ''')) and cnt_contactType= ''CL'' ) as D order by CrDate desc ';


    END
	ELSE IF (@REQUESTTYPE1 = 'Franchisee')
    BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                            ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join  tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''FR%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

    END
	ELSE IF (@REQUESTTYPE1 = 'Salesman/Agents')
    BEGIN
            --DataSet CntId = oDBEngine.PopulateData('user_contactid', 'tbl_master_user', ' user_id in(' + HttpContext.Current.Session['userchildHierarchy'] + ')');
            --for (int i = 0; i < CntId.Tables[0].Rows.Count; i++)
            --{
            --    if (i == 0)
            --    {
            --        AllUserCntId = ''''' + Convert.ToString(CntId.Tables[0].Rows[i]['user_contactid']) + ''''';
            --    }
            --    else
            --    {
            --        AllUserCntId += ','''' + Convert.ToString(CntId.Tables[0].Rows[i]['user_contactid']) + ''''';
            --    }
            --}

            if (UPPER(@HDNISDMSFEATUREON) = 'TRUE')
            BEGIN
                SET @Strsql =  'select * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select  top 1 ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''AG%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ') and #TEMPCONTACT.cnt_AssociatedEmp in (''' + @ALLUSERCNTID + ''')) as D order by CrDate desc';
            END
            else
            BEGIN
                SET @Strsql =  'select * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select  top 1 ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                                            ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                                        ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                                        ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                                        ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''AG%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';
            END
    END
    ELSE IF (@REQUESTTYPE1 = 'OtherEntity')
    BEGIN
            SET @Strsql =  'select *  from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                            ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id  inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''XC%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

    END
	ELSE IF (@REQUESTTYPE1 = 'Salesman/Agents')
    BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 phf_phoneNumber from tbl_master_phonefax where ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                            ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''RC%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

        END
        ELSE IF (@REQUESTTYPE1 = 'Data Vendor')
        BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                            ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join  tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''DV%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

        END
        ELSE IF (@REQUESTTYPE1 = 'Vendor')
        BEGIN
            SET @Strsql =  'select * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''VR%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

        END
        ELSE IF (@REQUESTTYPE1 = 'Partner')
        BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join  tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''PR%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

        END
        ELSE IF (@REQUESTTYPE1 = 'Consultant')
        BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''CS%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

        END
        ELSE IF (@REQUESTTYPE1 = 'Share Holder')
        BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''SH%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

        END
        ELSE IF (@REQUESTTYPE1 = 'Creditors')
        BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''CR%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

        END
        ELSE IF (@REQUESTTYPE1 = 'Debtor')
        BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate ' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''DR%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

    END
    ELSE IF (@REQUESTTYPE1 = 'Lead managers')
    BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''LM%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

    END
    ELSE IF (@REQUESTTYPE1 = 'Book Runners')
    BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''BS%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

    END
	ELSE IF (@REQUESTTYPE1 = 'Companies-Listed')
    BEGIN
            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                    ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''LC%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';
    END
	ELSE IF (@REQUESTTYPE1 =  'Relationship Partners')
    BEGIN

            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>''''  and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                        ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''RA%'' and #TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';

        END
        ELSE IF (@REQUESTTYPE1 = 'Transporter')
        BEGIN
            SET @Strsql =  'select * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,case when tbl_master_branch.branch_description is null then ''ALL'' else  tbl_master_branch.branch_description end AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select  top 1 ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Lead'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate ' +
                    ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT left JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_internalId like ''TR%'' and (#TEMPCONTACT.cnt_branchid in(' + @USERBRANCHHIERARCHY + ') or #TEMPCONTACT.cnt_branchid =0)) as D order by CrDate desc';

        END
        --   //For Leads
        ELSE IF (@REQUESTTYPE1 = 'Lead')
        BEGIN
            --string userbranchHierarchy = Convert.ToString(Session['userbranchHierarchy']);

            SET @Strsql =  'select  * from(select #TEMPCONTACT.cnt_id AS cnt_Id,'''' as CRG_TCODE,cnt_gstin gstin,(select top 1 crg_number  from tbl_master_contactRegistration where crg_type=''Pancard'' and crg_cntid=#TEMPCONTACT.cnt_internalId) as PanNumber,#TEMPCONTACT.cnt_internalId AS Id,(select top 1 ISNULL(phf_countryCode, '''') + '' '' + ISNULL(phf_areaCode, '''') + '' '' +ISNULL(phf_phoneNumber,'''') from tbl_master_phonefax where phf_phoneNumber is not null and LTRIM(RTRIM(phf_phoneNumber)) <>'''' and #TEMPCONTACT.cnt_internalid=phf_cntId) as phf_phoneNumber,(select top 1  ISNULL(eml_email,'''') from tbl_master_email where eml_email is not null and LTRIM(RTRIM(eml_email)) <>'''' and ltrim(rtrim(eml_type))=''official'' and #TEMPCONTACT.cnt_internalid=eml_cntId) as eml_email,(select ISNULL(con.cnt_firstName, '''') + '' '' + ISNULL(con.cnt_middleName, '''') + '' '' + ISNULL(con.cnt_lastName, '''') +''[''+con.cnt_shortname+'']'' from #TEMPCONTACT con,#TEMPCONTACT con1 where con.cnt_internalId=con1.cnt_referedBy and con1.cnt_internalId=#TEMPCONTACT.cnt_internalId) AS Reference,tbl_master_branch.branch_description AS BranchName,ISNULL(cnt_firstName, '''') + '' '' + ISNULL(cnt_middleName, '''') + '' '' + ISNULL(cnt_lastName, '''') AS Name,#TEMPCONTACT.cnt_UCC as Code,(select  top 1 ISNULL(contact.cnt_firstName, '''') + '' '' + ISNULL(contact.cnt_middleName, '''') + '' '' + ISNULL(contact.cnt_lastName, '''') +''[''+contact.cnt_shortname+'']'' AS Name from #TEMPCONTACT contact,tbl_trans_contactInfo info where contact.cnt_internalId=info.Rep_partnerid and info.cnt_internalId=#TEMPCONTACT.cnt_internalId and info.ToDate is null) as RM,case #TEMPCONTACT.cnt_Lead_Stage when 1 then ''Due'' when 2 then ''Opportunity'' when 3 then ''Sales/Pipeline'' when 4 then ''Converted'' when 5 then ''Lost'' End as Status,tbl_master_contactstatus.cntstu_contactStatus,case when #TEMPCONTACT.lastmodifydate is null then  #TEMPCONTACT.createdate else #TEMPCONTACT.lastmodifydate end as CrDate' +
                    ' ,(Select user_name from tbl_master_user where user_id=#TEMPCONTACT.CreateUser)as EnterBy,' +
                    ' CONVERT(VARCHAR(11),#TEMPCONTACT.LastModifyDate, 105) + '' '' + CONVERT(VARCHAR(8), #TEMPCONTACT.LastModifyDate, 108) as ModifyDateTime,' +
                    ' (Select user_name from tbl_master_user where user_id=#TEMPCONTACT.LastModifyUser)as ModifyUser' +
                    ' from #TEMPCONTACT INNER JOIN tbl_master_branch ON #TEMPCONTACT.cnt_branchid = tbl_master_branch.branch_id inner join tbl_master_contactstatus on #TEMPCONTACT.cnt_contactStatus=tbl_master_contactstatus.cntstu_id where  cnt_contactType= ''LD'' and #TEMPCONTACT.cnt_branchid in (' + @USERBRANCHHIERARCHY + ')) as D order by CrDate desc';


    END

	--select @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #TEMPCONTACT
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHR
	END

	SET NOCOUNT OFF
END


