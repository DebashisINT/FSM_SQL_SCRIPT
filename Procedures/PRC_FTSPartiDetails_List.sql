IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSPartiDetails_List]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSPartiDetails_List] AS' 
END
GO


--EXEC PRC_FTSPartiDetails_List '2020-05-01','2020-05-25','','',1
ALTER PROCEDURE [dbo].[PRC_FTSPartiDetails_List]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT ,
@IsReAssignedDate NVARCHAR(2)=NULL
)  
AS
/****************************************************************************************************************************************************************************
1.0			Tanmoy		07-05-2020					Create sp
2.0			Tanmoy		19-05-2020					ORDER BY DESC
3.0			Tanmoy		22-05-2020					Add extra column
4.0			Tanmoy		25-05-2020					Add Entered_on,Entered_by,Lastupdate_on,lastupdate_by
5.0			Tanmoy		26-08-2020					generate report Shop Create date or Re-assign Date
6.0			TANMOY		28/07/2021					employee hierarchy on Settings
7.0			Pratik		06-06-2022					Add Address,Pincode. refer: Mantis Issue 24928
8.0			Sanchita	04-11-2022		V2.0.36		Beat column required in various FSM reports. Refer: 25421
9.0			Sanchita	09-11-2022		V2.0.36		Alternate Contact 1, Alternate Email,GSTIN,Trade license,Group/Beat info is missing while modifying the Shop after import.
													Refer: 25433
10.0		Priti		03/05/2023      V2.0.47     0027407: "Party Status" - needs to add in the following reports.
11.0		Priti       18-11-2024      V2.0.49		A new Global settings required as WillShowLoanDetailsInParty.Mantis: 0027799
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	--Rev 6.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
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
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
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
		--End of Rev 6.0
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)


	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
			DROP TABLE #STATEID_LIST
	CREATE TABLE #STATEID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
	IF @STATEID <> ''
	BEGIN
		SET @STATEID=REPLACE(@STATEID,'''','')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #STATEID_LIST SELECT id from tbl_master_state where id in('+@STATEID+')'
		EXEC SP_EXECUTESQL @sqlStrTable
	END
	
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END


	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
		CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_ucc NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			USER_ID BIGINT
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id FROM TBL_MASTER_CONTACT CNT
	INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE cnt_contactType IN('EM')


	-- Rev 9.0 [ columns [Cluster],[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number] added ]
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_NewPartyDetailsReport') AND TYPE IN (N'U'))
	BEGIN
	CREATE TABLE FTS_NewPartyDetailsReport
	(
		USERID INT,
		SEQ BIGINT,
		ShopCode nvarchar(MAX),
		state NVARCHAR(MAX),
		StateHead NVARCHAR(MAX),
		StateHeadCode NVARCHAR(MAX),
		Supervisor NVARCHAR(MAX),
		SupervisorCode NVARCHAR(MAX),
		cnt_internalId NVARCHAR(MAX),
		EmpName NVARCHAR(MAX),
		EmpCode NVARCHAR(MAX),
		Designation NVARCHAR(MAX),
		PP_CODE NVARCHAR(MAX),
		PP_Name NVARCHAR(MAX),
		PP_LOCATION NVARCHAR(MAX),
		Outlet_Code NVARCHAR(MAX),
		Outlet_Name NVARCHAR(MAX),
		Outlet_ContactNo NVARCHAR(MAX),
		AlternateNo NVARCHAR(MAX),
		OutletLocation NVARCHAR(MAX),
		OutletStatus NVARCHAR(MAX),
		OutletSpecify	NVARCHAR(MAX),
		OwnerDOB DATETIME,
		OwnerAnniversary	DATETIME,
		PanCard NVARCHAR(MAX),
		AdhaarCard NVARCHAR(MAX),
		CreateDate DATETIME,
		DD_CODE NVARCHAR(100),
		DD_Name NVARCHAR(300),
		DD_LOCATION NVARCHAR(500),
		country NVARCHAR(300),
		city NVARCHAR(300),
		area NVARCHAR(300),
		Outlet_owner NVARCHAR(300),
		Outlet_type NVARCHAR(300),
		OutletLat NVARCHAR(100),
		OutletLong NVARCHAR(100),
		--Rev 4.0 Start
		CreateBy NVARCHAR(300),
		CreateOn DATETIME,
		UpdateBy NVARCHAR(300),
		UpdateOn DATETIME
		--Rev 4.0 End
		--rev 7.0
		,[Address] nvarchar(max)
		,Pincode nvarchar(50)
		--End of rev 7.0
		-- Rev 8.0
		,Beat varchar(500)
		-- End of Rev 8.0
		-- Rev 9.0
		,Cluster varchar(500)
		,Shop_Owner_Email2 varchar(300)
		,Alt_MobileNo1 varchar(40)
		,GSTN_NUMBER varchar(100)
		,Trade_Licence_Number varchar(100)
		-- End of Rev 9.0
		--Rev 10.0
		,PARTYSTATUS varchar(250) NULL
		--Rev 10.0 End

		--REV 11.0
		,BKT nvarchar(100)
		,TOTALOUTSTANDING NUMERIC(18,2)
		,POS NUMERIC(18,2)
		,ALLCHARGES NUMERIC(18,2)
		,TOTALCOLLECTABLE NUMERIC(18,2)
		,WORKABLE nvarchar(100)
		,PTPDATE DATETIME
		,PTPAMOUNT NUMERIC(18,2)
		,COLLECTIONDATE DATETIME
		,COLLECTIONAMOUNT  NUMERIC(18,2)
		,EMIAMOUNT NUMERIC(18,2)
		,RISK  nvarchar(100)
		,DISPOSITIONCODE nvarchar(200)
		,FINALSTATUS nvarchar(100)
		--REV 11.0 END

		)
	END

	delete from FTS_NewPartyDetailsReport where USERID=@USERID

	SET @Strsql=''

	SET @Strsql+=' INSERT INTO FTS_NewPartyDetailsReport  '
	SET @Strsql+=' SELECT  '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY shop.Shop_CreateTime DESC) AS SEQ,shop.shop_code,STAT.state,   '
	--SET @Strsql+='SATHED.cnt_firstName+'' ''+SATHED.cnt_middleName+'' ''+SATHED.cnt_lastName AS StateHead,SATHED.cnt_ucc as StateHeadCode,   '
	SET @Strsql+=' '' '' AS StateHead,'' '' as StateHeadCode,   '
	SET @Strsql+=' RPTTO.REPORTTO AS Supervisor,RPTTO.REPORTTO_ID AS SupervisorCode   '
	SET @Strsql+=' ,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EmpName,	'
	SET @Strsql+=' CNT.cnt_ucc AS EmpCode,DESG.deg_designation AS Designation,PP.EntityCode AS PP_CODE,PP.Shop_Name AS PP_Name,PP.Entity_Location AS PP_LOCATION,  '
	SET @Strsql+=' shop.EntityCode AS Outlet_Code,shop.Shop_Name AS Outlet_Name,shop.Shop_Owner_Contact AS Outlet_ContactNo,shop.Alt_MobileNo AS AlternateNo,   '
	SET @Strsql+=' shop.Entity_Location AS OutletLocation,CASE WHEN ISNULL(shop.Entity_Status,0)=0 THEN ''Inactive'' ELSE ''Active'' END AS OutletStatus,   '
	SET @Strsql+=' OutLetType.TypeName AS OutletSpecify,shop.dob AS OwnerDOB,shop.date_aniversary AS OwnerAnniversary,shop.ShopOwner_PAN AS PanCard,   ' 
	SET @Strsql+=' shop.ShopOwner_Aadhar AS AdhaarCard,shop.Shop_CreateTime  '
	SET @Strsql+=' ,DD.EntityCode AS DD_CODE,DD.Shop_Name AS DD_Name,DD.Entity_Location AS DD_LOCATION,CNTRY.cou_country,CTY.city_name,AREA.area_name,   '
	SET @Strsql+=' shop.Shop_Owner,shoptype.Name,shop.Shop_Lat,shop.Shop_Long    '
	--Rev 4.0 Start
	SET @Strsql+=' ,creat.user_name , shop.Entered_On,updt.user_name,shop.LastUpdated_On  '
	--Rev 4.0 End
	--Rev 7.0 
	SET @Strsql+=' ,shop.Address , shop.Pincode  '
	--End of Rev 7.0
	-- Rev 8.0
	SET @Strsql+=' ,BEAT.NAME as Beat  '
	-- End of Rev 8.0
	-- Rev 9.0
	SET @Strsql+=' ,shop.[Cluster],shop.[Shop_Owner_Email2],shop.[Alt_MobileNo1],shop.[GSTN_NUMBER],shop.[Trade_Licence_Number] '
	-- End of Rev 9.0

	--Rev 10.0
	SET @Strsql+=' ,ISNULL(PSTATUS.PARTYSTATUS,'''')PARTYSTATUS '
	--Rev 10.0 End


	--Rev 11.0
	SET @Strsql+=' ,shop.BKT,shop.TOTALOUTSTANDING,shop.POS,shop.ALLCHARGES,shop.TOTALCOLLECTABLE,shop.WORKABLE,shop.PTPDATE,shop.PTPAMOUNT,shop.COLLECTIONDATE,shop.COLLECTIONAMOUNT,shop.EMIAMOUNT,RISKNAME,code.DISPOSITIONCODE,FINALSTATUSNAME '
	--Rev 11.0 End

	SET @Strsql+=' FROM tbl_Master_shop shop   '
	IF @IsReAssignedDate='1'
	BEGIN
		SET @Strsql+=' INNER JOIN FTS_ShopReassignUserLog LOGS ON LOGS.SHOP_CODE=shop.Shop_Code '
	END

	--Rev 10.0
	SET @Strsql+='LEFT OUTER JOIN FSM_PARTYSTATUS PSTATUS ON SHOP.Party_Status_id=PSTATUS.ID '
	--Rev 10.0 End

	SET @Strsql+=' LEFT OUTER JOIN tbl_shoptype shoptype ON shoptype.shop_typeId=shop.type AND shoptype.IsActive=1  '
	SET @Strsql+=' LEFT OUTER JOIN tbl_Master_shop PP ON PP.Shop_Code=shop.assigned_to_pp_id   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_Master_shop DD ON DD.Shop_Code=shop.assigned_to_dd_id   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_state STAT ON STAT.id=shop.stateId   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_country CNTRY ON CNTRY.cou_id=STAT.countryId   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_area AREA ON AREA.area_id=shop.Area_id   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_city CTY ON CTY.city_id=shop.Shop_City   '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.USER_ID=shop.Shop_CreateUser    '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE    '
		END
	--Rev 4.0 Start
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_user creat ON creat.user_id=shop.Entered_By   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_user updt ON updt.user_id=shop.LastUpdated_By   '
	--Rev 4.0 End

	--SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDRS ON ADDRS.add_state=shop.stateId    '--AND add_addressType=''Office''
	--SET @Strsql+='LEFT OUTER JOIN tbl_trans_employeeCTC SHD ON SHD.emp_cntId=ADDRS.add_cntId and SHD.emp_Designation=112  '
	--SET @Strsql+='LEFT OUTER JOIN #TEMPCONTACT SATHED ON SATHED.cnt_internalId=SHD.emp_cntId   '
	--SET @Strsql+='LEFT OUTER JOIN (   '
	--SET @Strsql+='select CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_UCC,ADDRS.add_state   '
	--SET @Strsql+='from tbl_trans_employeeCTC ctc    '
	--SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDRS ON ADDRS.add_cntId=ctc.emp_cntId   '
	--SET @Strsql+='LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=ctc.emp_cntId   '
	--SET @Strsql+='WHERE emp_Designation=112) SATHED ON SATHED.add_state=SHOP.stateId   '
	SET @Strsql+=' LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,	  '
	SET @Strsql+=' CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,   '
	SET @Strsql+=' DESG.deg_designation AS RPTTODESG,CNT.cnt_ucc AS REPORTTO_ID FROM tbl_master_employee EMP	  '
	SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo		'
	SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId	'
	SET @Strsql+=' LEFT OUTER JOIN (	  '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt		'
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL	'
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId		'
	SET @Strsql+=' WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId   '
	SET @Strsql+=' LEFT OUTER JOIN (	   '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt		'
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL	 '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=CNT.cnt_internalId   '
	SET @Strsql+=' LEFT OUTER JOIN Master_OutLetType OutLetType ON OutLetType.TypeID=shop.Entity_Type AND OutLetType.IsActive=1   '
	-- Rev 8.0
	SET @Strsql+=' LEFT OUTER JOIN FSM_GROUPBEAT BEAT on shop.beat_id = BEAT.ID '
	-- End of Rev 8.0


	---REV 11.0
	SET @Strsql+='  LEFT OUTER JOIN FSM_LOANRISK on RISKID=shop.RISK
					LEFT OUTER JOIN FSM_LOANDISPOSITIONCODE code on code.DISPOSITIONID=shop.DISPOSITIONCODE
					LEFT OUTER JOIN FSM_LOANFINALSTATUS on FINALSTATUSID=shop.FINALSTATUS'

	---REV 11.0 END


	IF @IsReAssignedDate='1'
	BEGIN
		SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),LOGS.UPDATED_ON,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	END
	ELSE
	BEGIN
		SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),shop.Shop_CreateTime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	END
	IF @STATEID<>'' AND @EMPID=''
		SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=shop.stateId) '
	ELSE IF @STATEID='' AND @EMPID<>''
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	ELSE IF @STATEID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=shop.stateId) '
			SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
		END
	
		--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #TEMPCONTACT
	DROP TABLE #STATEID_LIST
	DROP TABLE #EMPLOYEE_LIST

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHR
	END
	SET NOCOUNT OFF
END