


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSCustomerDetails_List]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSCustomerDetails_List] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSCustomerDetails_List]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT =NULL,
@DesigId NVARCHAR(MAX)=NULL,
@DeptId NVARCHAR(MAX)=NULL
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		Tanmoy		11-06-2020			Create sp
2.0		Tanmoy		05-03-2021			Add extra column
3.0		Debashis	30-09-2021		Master - Contact - Parties and Master - Contact - Customer Details.Refer: 0024384
4.0		Sanchita	v2.0.36			10-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" then data in portal shall be populated based on Hierarchy Only.
													Refer: 25504
5.0		PRITI		V2.0.39			13-02-2023		0025663:Last Visit fields shall be available in Outlet Reports
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	-- Rev 4.0
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
		-- End of Rev 4.0

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

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DesigId <> ''
		BEGIN
			SET @DesigId=REPLACE(@DesigId,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation where deg_id in('+@DesigId+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DEPARTMENT_LIST') AND TYPE IN (N'U'))
		DROP TABLE #DEPARTMENT_LIST
	CREATE TABLE #DEPARTMENT_LIST (DEPT_ID INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DEPARTMENT_LIST (DEPT_ID ASC)
	IF @DeptId <> ''
		BEGIN
			SET @DeptId=REPLACE(@DeptId,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #DEPARTMENT_LIST SELECT cost_id from tbl_master_costCenter where cost_id in('+@DeptId+')'
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
	-- Rev 4.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id FROM TBL_MASTER_CONTACT CNT
	--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE cnt_contactType IN('EM')

	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id FROM TBL_MASTER_CONTACT CNT '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE    '
	END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '

	--select @Strsql

	EXEC SP_EXECUTESQL @Strsql
	-- end of Rev 4.0

	--REV 5.0
	--NOT REQUIRED CREATE TABLE STATEMENT DUE TO MVC PAGE RenderAction CALL THE TABLE IN PAGE LOAD.IF ANY FIELD ADD OR DELETE THEN NEED DROP TABLE AS WELL AS NEW CREATE TABLE STATEMENT IN MIGRATION SHEET.
	
	--IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_CustomerDetailsReport') AND TYPE IN (N'U'))
	--BEGIN
	----Rev Debashis && Increase the field length of ContactNo from NVARCHAR(20) to NVARCHAR(100)
	--CREATE TABLE FTS_CustomerDetailsReport
	--(
	--	USERID BIGINT,
	--	SEQ	BIGINT,
	--	shop_code NVARCHAR(100),
	--	Shop_CreateTime	DATETIME,
	--	cnt_internalId NVARCHAR(100),
	--	EmpCode	NVARCHAR(100),
	--	Employee NVARCHAR(300),
	--	Supervisor NVARCHAR(300),
	--	Designation	NVARCHAR(300),
	--	DEPARTMENT NVARCHAR(300),
	--	CustomerName NVARCHAR(300),
	--	CustomerAddress	NVARCHAR(500),
	--	ContactNo NVARCHAR(100),
	--	MailId NVARCHAR(100),
	--	Model NVARCHAR(300),
	--	PrimaryApplication NVARCHAR(300),
	--	SecondaryApplication NVARCHAR(300),
	--	BookingAmount DECIMAL(18,2),
	--	LeadType NVARCHAR(300),
	--	Stage NVARCHAR(300),
	--	FunnelStage	NVARCHAR(300),
	--	Feedback NVARCHAR(500),
	--	deg_id NVARCHAR(10),
	--	emp_Department NVARCHAR(10),
	--	stateId NVARCHAR(10),
	--	Party_Type NVARCHAR(300),
	--	DD_Type NVARCHAR(300),
	--	Shop_Type NVARCHAR(300),
	--	Entity_Type NVARCHAR(300),
	--	Party_Status NVARCHAR(300),
	--	Group_Beat NVARCHAR(300),
	--	Account_Holder NVARCHAR(300),
	--	Bank_Name NVARCHAR(300),
	--	Account_No NVARCHAR(300),
	--	IFSC_Code NVARCHAR(300),
	--	UPI_ID NVARCHAR(300),
	--	Type NVARCHAR(300),
	--	Assoc_Customer NVARCHAR(300),
	--	--Rev 3.0 
	--	STATE_NAME NVARCHAR(200),
	--	DISTRICT NVARCHAR(200),
	--	--End of Rev 3.0 
	--REV 5.0
	--	LASTVISITDATE NVARCHAR(100),	
	--	LASTVISITTIME NVARCHAR(100),	
	--	LASTVISITEDBY NVARCHAR(200)
	--REV 5.0 END

	--	)
	--END
	--REV 5.0 END
	DELETE FROM FTS_CustomerDetailsReport where USERID=@USERID

	SET @Strsql=''

	SET @Strsql+=' INSERT INTO FTS_CustomerDetailsReport '	
	SET @Strsql+=' SELECT  '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY shop.Shop_CreateTime DESC) AS SEQ,shop.shop_code,shop.Shop_CreateTime ,  '
	SET @Strsql+=' CNT.cnt_internalId,CNT.cnt_ucc AS EmpCode,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EmpName,	 '
	SET @Strsql+=' RPTTO.REPORTTO AS Supervisor ,DESG.deg_designation AS Designation,DEPT.cost_description AS DEPARTMENT,   '
	SET @Strsql+=' shop.Shop_Name AS CustomerName,shop.Address as CustomerAddress,shop.Shop_Owner_Contact AS ContactNo ,shop.Shop_Owner_Email AS MailId,   '
	SET @Strsql+=' mdl.sProducts_Name as Model,primry.PrimaryApplication,scndry.SecondaryApplication,shop.Booking_amount AS BookingAmount,LEAD.LeadType,   '
	SET @Strsql+=' Stg.Stage,FUNLStg.FunnelStage, shop.Remarks AS Feedback,DESG.deg_id,CTC.emp_Department,shop.stateId   '
	SET @Strsql+=' ,shoptype.Name Party_Type'
	SET @Strsql+=' ,shopTypeDetails.Name DD_Type'
	SET @Strsql+=' ,shopTypeDetails1.Name Shop_Type'
	SET @Strsql+=' ,ENTITY.ENTITY Entity_Type'
	SET @Strsql+=' ,PARTYSTATUS.PARTYSTATUS Party_Status'
	SET @Strsql+=' ,GROUPBEAT.NAME Group_Beat'
	SET @Strsql+=' ,shop.account_holder account_holder'
	SET @Strsql+=' ,shop.account_no account_no'
	SET @Strsql+=' ,shop.bank_name bank_name'
	SET @Strsql+=' ,shop.ifsc ifsc'
	SET @Strsql+=' ,shop.upi_id upi_id'
	--Rev 2.0 Start
	SET @Strsql+=' ,case when shop.type=1 then shopTypeDetails1.Name when shop.type=4 then shopTypeDetails.Name else '''' end as Type'
	SET @Strsql+=' ,case when shop.type=1 then shopdd.shop_name when shop.type=4 then shoppp.shop_name when shop.type=11 then shopcus.shop_name else '''' end as Assoc_Customer'
	--End of Rev 2.0


	--Rev 3.0
	SET @Strsql+=' ,ST.state,cty.city_name'
	--End of Rev 3.0
	--Rev 5.0
	SET @Strsql+=' ,CONVERT(NVARCHAR(10),shop.Lastvisit_date,105)Lastvisitdate,CONVERT(NVARCHAR(10),shop.Lastvisit_date,108)LASTVISITTIME,UserTBl.user_name user_name'
	--End of Rev 5.0
	SET @Strsql+=' FROM tbl_Master_shop shop   '
	SET @Strsql+=' LEFT OUTER JOIN TBL_SHOPTYPEDETAILS shopTypeDetails ON shopTypeDetails.Id=shop.dealer_id	  '
	SET @Strsql+=' LEFT OUTER JOIN TBL_SHOPTYPEDETAILS shopTypeDetails1 ON shopTypeDetails1.Id=shop.retailer_id	  '
	SET @Strsql+=' LEFT OUTER JOIN FSM_ENTITY ENTITY ON ENTITY.Id=shop.Entity_Id	  '
	SET @Strsql+=' LEFT OUTER JOIN FSM_PARTYSTATUS PARTYSTATUS ON PARTYSTATUS.Id=shop.Party_Status_id	  '
	SET @Strsql+=' LEFT OUTER JOIN FSM_GROUPBEAT GROUPBEAT ON GROUPBEAT.Id=shop.beat_id	  '
	SET @Strsql+=' LEFT OUTER JOIN tbl_shoptype shoptype ON shoptype.shop_typeId=shop.type AND shoptype.IsActive=1 
	'
	--REV 5.0 START
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_user UserTBl ON CAST(UserTBl.user_id AS INT)=shop.Shop_CreateUser   		'
	--REV 5.0	END
	-- Rev 4.0
	--SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.USER_ID=shop.Shop_CreateUser    '
	
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.USER_ID=shop.Shop_CreateUser    '
	end
	else
	begin
		SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.USER_ID=shop.Shop_CreateUser    '
	end

	-- End of Rev 4.0
	SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId    '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department''   '
	SET @Strsql+=' LEFT OUTER JOIN FTS_LeadType LEAD ON LEAD.LeadTypeID=shop.Lead_id     '
	SET @Strsql+=' LEFT OUTER JOIN FTS_Stage Stg ON Stg.StageID=shop.Stage_id    '
	SET @Strsql+=' LEFT OUTER JOIN FTS_FunnelStage FUNLStg ON FUNLStg.FunnelStageID=shop.FunnelStage_id    '
	SET @Strsql+=' LEFT OUTER JOIN FTS_PrimaryApplication primry ON primry.ID=shop.Primary_id    '
	SET @Strsql+=' LEFT OUTER JOIN FTS_SecondaryApplication scndry ON scndry.ID=shop.Secondary_id   '
	SET @Strsql+=' LEFT OUTER JOIN master_sproducts mdl ON mdl.sProducts_ID=shop.Model_id    '
	--Rev 2.0 Start
	SET @Strsql+=' LEFT OUTER JOIN tbl_Master_shop shopdd ON shop.assigned_to_dd_id=shopdd.shop_code and shopdd.type=4 '
	SET @Strsql+=' LEFT OUTER JOIN tbl_Master_shop shoppp ON shop.assigned_to_pp_id=shoppp.shop_code and shoppp.type=2 '
	SET @Strsql+=' LEFT OUTER JOIN tbl_Master_shop shopcus ON shop.assigned_to_shop_id=shopcus.shop_code and shopcus.type=1 '
	--End of Rev 2.0
	--Rev 3.0
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office''   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state    '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_city cty ON cty.city_id=ADDR.add_city    '
	--End of Rev 3.0
	SET @Strsql+=' LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,	   '
	SET @Strsql+=' CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,    '
	SET @Strsql+=' DESG.deg_designation AS RPTTODESG,CNT.cnt_ucc AS REPORTTO_ID FROM tbl_master_employee EMP	  '
	SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo		'
	
	-- Rev 4.0
	--SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId	  '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId    '
	end
	else
	begin
		SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId    '
	end
	-- End of Rev 4.0
	
	SET @Strsql+=' LEFT OUTER JOIN (	    '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt		'
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL	  '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId		'
	SET @Strsql+=' WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId   '
	SET @Strsql+=' LEFT OUTER JOIN (	   '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt		'
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL	 '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=CNT.cnt_internalId  '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),shop.Shop_CreateTime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)  '
	IF @STATEID<>''
		SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=shop.stateId) '
	IF @EMPID<>''
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	IF @DesigId<>''
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '
	IF @DeptId<>''
		SET @Strsql+=' AND EXISTS (SELECT DEPT_ID from #DEPARTMENT_LIST AS DPTR WHERE DPTR.DEPT_ID=CTC.emp_Department) '	
	
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #TEMPCONTACT
	DROP TABLE #STATEID_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #DEPARTMENT_LIST
	-- Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHR
	END
	-- End of Rev 4.0

	SET NOCOUNT OFF
END
