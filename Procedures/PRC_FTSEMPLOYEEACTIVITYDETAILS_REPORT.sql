--EXEC PRC_FTSEMPLOYEEACTIVITYDETAILS_REPORT '','2024-01-02','2024-01-02','','',378,'119'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSEMPLOYEEACTIVITYDETAILS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSEMPLOYEEACTIVITYDETAILS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSEMPLOYEEACTIVITYDETAILS_REPORT]
(
@Employee NVARCHAR(MAX)=NULL,
@FROMDATE NVARCHAR(50)=NULL,
@TODATE NVARCHAR(50)=NULL,
@stateID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@USERID BIGINT,
--Rev 3.0
@BRANCHID NVARCHAR(MAX)=NULL
--Rev 3.0 End
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder On 11/03/2021
Module	   : Employee Activity Details Report for Track.Refer: 0023846
1.0					22-04-2021		TANMOY			Electrician type and Electrician name  correction Ref:0023987
2.0		v2.0.24		30-07-2021		Debashis		Employee Activity Employee Activity Details This report shall not be showing distance subtotal of Visit /Revisit.
													Refer: 0024198
3.0	    V2.0.42		20/07/2023      Priti	        Branch Parameter is required for various FSM reports.Refer:0026135
4.0		V2.0.44		05/01/2023		Debashis		EMPLOYEE ACTIVITY DETAILS Report issue in PRIYANKA ENTERPRISES.Refer: 0027149
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @sqlStrTable NVARCHAR(MAX),@Strsql NVARCHAR(MAX),@sqlStateStrTable NVARCHAR(MAX)

	--Rev 3.0
	 IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
		DROP TABLE #BRANCH_LIST
	 CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
	 CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)
     IF @BRANCHID<>''
		BEGIN
			SET @sqlStrTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @sqlStrTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
	  END
	  --Rev 3.0 End
---------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @Employee <> ''
		BEGIN
			SET @Employee = REPLACE(''''+@Employee+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId FROM tbl_master_employee WHERE emp_contactId IN('+@Employee+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
-------------------------------STATE----------------------------------------------------
	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
		DROP TABLE #STATEID_LIST
	CREATE TABLE #STATEID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
	IF @STATEID <> ''
		BEGIN
			SET @STATEID=REPLACE(@STATEID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable='INSERT INTO #STATEID_LIST SELECT id FROM tbl_master_state WHERE id IN('+@STATEID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

---------------------------------DESIGNATION-------------------------------------
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DESIGNID <> ''
		BEGIN
			SET @DESIGNID=REPLACE(@DESIGNID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable='INSERT INTO #DESIGNATION_LIST SELECT deg_id FROM tbl_master_designation WHERE deg_id IN('+@DESIGNID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(			
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSEMPLOYEEACTIVITYDETAILS_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSEMPLOYEEACTIVITYDETAILS_REPORT
			(
			  LOGIN_ID BIGINT,
			  SEQ BIGINT,
			  STATE_NAME NVARCHAR(300) NULL,
			  BRANCHDESC NVARCHAR(300),
			  DESIGNATION NVARCHAR(100) NULL,
			  PCUSTNAME NVARCHAR(300),
			  CUSTCODE NVARCHAR(300),
			  CUSTNAME NVARCHAR(300),
			  CUSTTYPE NVARCHAR(100),
			  ENTITYTYPE NVARCHAR(300),
			  USER_ID BIGINT,
			  EMPCODE NVARCHAR(100),
			  EMPID NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  SHOP_NAME NVARCHAR(300) NULL,
			  ENTITYCODE NVARCHAR(600) NULL,
			  SHOP_TYPE NVARCHAR(100) NULL,
			  MOBILE_NO NVARCHAR(20) NULL,
			  LOCATION NVARCHAR(MAX) NULL,
			  VISIT_DATETIME DATETIME NULL,
			  VISITDATE NVARCHAR(10) NULL,
			  VISITTIME NVARCHAR(10) NULL,
			  DURATION NVARCHAR(50) NULL,
			  DISTANCE DECIMAL(18,2),
			  VISIT_TYPE NVARCHAR(100) NULL,
			  REMARKS NVARCHAR(2000) NULL
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSEMPLOYEEACTIVITYDETAILS_REPORT (SEQ)
		END
	DELETE FROM FTSEMPLOYEEACTIVITYDETAILS_REPORT WHERE LOGIN_ID=@USERID


    SET @Strsql='INSERT INTO FTSEMPLOYEEACTIVITYDETAILS_REPORT(LOGIN_ID,SEQ,STATE_NAME,BRANCHDESC,DESIGNATION,PCUSTNAME,CUSTCODE,CUSTNAME,CUSTTYPE,ENTITYTYPE,USER_ID,EMPCODE,EMPID,EMPNAME,SHOP_NAME,'
	SET @Strsql+='ENTITYCODE,SHOP_TYPE,MOBILE_NO,LOCATION,VISIT_DATETIME,VISITDATE,VISITTIME,DURATION,DISTANCE,VISIT_TYPE,REMARKS) '
	SET @Strsql+='SELECT '+STR(@USERID)+' AS LOGIN_ID,ROW_NUMBER() OVER(ORDER BY T.VISIT_DATETIME) AS SEQ,T.STATE,T.BRANCHDESC,T.DEG_DESIGNATION,T.PCUSTNAME,T.CUSTCODE,T.CUSTNAME,T.CUSTTYPE,T.ENTITYTYPE,'
	SET @STRSQL+='T.USER_ID,T.EMPCODE,T.EMPLOYEE_ID,T.EMPNAME,T.SHOP_NAME,T.ENTITYCODE,T.SHOP_TYPE,T.MOBILE_NO,T.LOCATION,T.VISIT_DATETIME,T.VISITDATE,T.VISITTIME,T.DURATION,T.DISTANCE,T.VISIT_TYPE,T.REMARKS '
	SET @STRSQL+='FROM ('
	SET @Strsql+='SELECT mstShp.Shop_Name,MSTSHP.ENTITYCODE,SHPTYP.Name AS Shop_Type,mstShp.Shop_Owner_Contact AS Mobile_No,mstShp.Address AS Location,shpAvtv.visited_time AS VISIT_DATETIME,'
	SET @Strsql+='CONVERT(NVARCHAR(10),shpAvtv.visited_time,105) AS VISITDATE,CONVERT(VARCHAR(8),CAST(shpAvtv.visited_time AS TIME),108) AS VISITTIME,shpAvtv.spent_duration AS Duration,'
	--Rev 2.0
	--SET @Strsql+='ISNULL(shpAvtv.distance_travelled,0) AS Distance,CASE WHEN shpAvtv.is_Newshopadd=1 THEN ''New'' ELSE ''Re-Visit'' END AS Visit_Type,shpAvtv.REMARKS,shpAvtv.User_Id,CNT.cnt_internalId AS EMPCODE,'
	SET @Strsql+='0 AS Distance,CASE WHEN shpAvtv.is_Newshopadd=1 THEN ''New'' ELSE ''Re-Visit'' END AS Visit_Type,shpAvtv.REMARKS,shpAvtv.User_Id,CNT.cnt_internalId AS EMPCODE,'
	--End of Rev 2.0
	SET @Strsql+='ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+(CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.cnt_lastName,'''') AS EMPNAME,'
	SET @Strsql+='MS.state,MS.id AS STATE_ID,BR.branch_description AS BRANCHDESC,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID, '
	--Rev 1.0 Start
	--SET @Strsql+='SHOPDD.Shop_Name AS PCUSTNAME, '
	SET @Strsql+='CASE WHEN mstShp.type=1 THEN SHOPDD.Shop_Name WHEN mstShp.type=4 THEN SHOPPP.shop_name WHEN mstShp.type=11 THEN SHOPCUS.shop_name ELSE '''' END AS PCUSTNAME, '
	--Rev 1.0 End
	SET @Strsql+='SHOP.CUSTTYPE,SHOP.Shop_Code AS CUSTCODE,'
	SET @Strsql+='SHOP.Shop_Name AS CUSTNAME,CASE WHEN SHOP.CUSTTYPE=''Entity'' THEN SHOP.ENTITY ELSE '''' END AS ENTITYTYPE '
	--Rev 3.0
	SET @Strsql+=',BR.branch_id as branch_id '	
	--Rev 3.0 End
	SET @Strsql+=' FROM tbl_trans_shopActivitysubmit shpAvtv '
	SET @Strsql+='INNER JOIN tbl_Master_shop mstShp ON mstShp.Shop_Code=shpAvtv.Shop_Id '
	SET @Strsql+='INNER JOIN tbl_shoptype SHPTYP ON SHPTYP.TypeId=mstShp.type '
	SET @Strsql+='INNER JOIN TBL_MASTER_USER MU ON MU.user_id=shpAvtv.User_Id '
	SET @Strsql+='INNER JOIN tbl_master_address MA ON MA.add_cntId=MU.user_contactId and MA.add_addressType=''Office'' ' 
    SET @Strsql+='INNER JOIN tbl_master_state MS ON MS.ID=MA.add_state '
    SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId = MU.user_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
    SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAx(emp_id) AS emp_id,desg.deg_id '
    SET @Strsql+='FROM tbl_trans_employeeCTC AS cnt '
    SET @Strsql+='LEFT OUTER JOIN tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation '
    SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil HAVING emp_effectiveuntil IS NULL)N '
    SET @Strsql+='ON N.emp_cntId=MU.user_contactId '
	SET @Strsql+='LEFT OUTER JOIN ('
	--Rev 1.0 Start
	--SET @Strsql+='SELECT DISTINCT MS.Shop_Code,MS.Shop_CreateUser,MS.Shop_Name,MS.Address,MS.Shop_Owner_Contact,MS.assigned_to_pp_id,MS.assigned_to_dd_id,MS.type,MS.EntityCode,'
	SET @Strsql+='SELECT DISTINCT MS.Shop_Code,MS.Shop_CreateUser,MS.Shop_Name,MS.Address,MS.Shop_Owner_Contact,MS.assigned_to_pp_id,MS.assigned_to_shop_id,MS.assigned_to_dd_id,MS.type,MS.EntityCode,'
	--Rev 1.0 End
	SET @Strsql+='CASE WHEN TYPE=1 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.retailer_id) '
	SET @Strsql+='WHEN TYPE=2 THEN ''Company Name'' '
	--Rev 1.0 Start
	--SET @Strsql+='WHEN TYPE=4 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.dealer_id) WHEN TYPE=11 THEN ''Electrician'' END AS CUSTTYPE,'
	SET @Strsql+='WHEN TYPE=4 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.dealer_id) ELSE (SELECT STYPD.Name FROM TBL_SHOPTYPE STYPD WHERE STYPD.TypeId=MS.TYPE) END AS CUSTTYPE,'
	--Rev 1.0 End
	SET @Strsql+='ENT.ENTITY,CASE WHEN MS.type=11 THEN MS.Shop_Name ELSE '''' END AS ELECTRICIAN,'
	SET @Strsql+='CASE WHEN MS.type=11 THEN MS.Address ELSE '''' END AS ELECTRICIANADD,'
	SET @Strsql+='CASE WHEN MS.type=11 THEN MS.Shop_Owner_Contact ELSE '''' END AS ELECTRICIANMOB '
	SET @Strsql+='FROM tbl_Master_shop MS '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EN.ENTITY,MSTSHP.Shop_Code FROM FSM_ENTITY EN '
	SET @Strsql+='INNER JOIN tbl_Master_shop MSTSHP ON EN.ID=MSTSHP.Entity_Id '
	SET @Strsql+=') ENT ON MS.Shop_Code=ENT.Shop_Code '
	SET @Strsql+=') SHOP ON SHOP.Shop_Code=shpAvtv.Shop_Id '
	SET @Strsql+='LEFT OUTER JOIN(SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A) SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	--Rev 1.0 Start
	SET @Strsql+='LEFT OUTER JOIN(SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A) SHOPPP ON SHOP.assigned_to_PP_id=SHOPPP.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN(SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_shop_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A) SHOPCUS ON SHOP.assigned_to_shop_id=SHOPCUS.Shop_Code '
	--Rev 1.0 End
	--Rev 4.0
	IF @BRANCHID<>''
		SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCH_LIST AS F WHERE F.Branch_Id=BR.branch_id) '
	--End of Rev 4.0
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT '''' AS Shop_name,'''' AS ENTITYCODE,'''' AS Shop_Type,'''' AS Mobile_No,location_name AS Location,SDate AS VISIT_DATETIME,CONVERT(NVARCHAR(10),TSA.SDate,105) AS VISITDATE,'
	SET @Strsql+='CONVERT(VARCHAR(8),CAST(TSA.SDate AS TIME),108) AS VISITTIME,'''' AS Duration,distance_covered AS Distance,'''' AS Visit_Type,'''' AS REMARKS,TSA.User_id,CNT.cnt_internalId AS EMPCODE,'
	SET @Strsql+='ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+(CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.cnt_lastName,'''') AS EMPNAME,'
	SET @Strsql+='MS.state,MS.id AS STATE_ID,BR.branch_description AS BRANCHDESC,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID,'''' AS PCUSTNAME,'''' AS CUSTTYPE,'''' AS CUSTCODE,'''' AS CUSTNAME,'
	SET @Strsql+=''''' AS ENTITYTYPE  '  
	--Rev 3.0
	SET @Strsql+=',BR.branch_id as branch_id '	
	--Rev 3.0 End	
	SET @Strsql+=' FROM TBL_TRANS_SHOPUSER_ARCH TSA '
	SET @Strsql+='INNER JOIN TBL_MASTER_USER MU ON MU.user_id=TSA.User_Id '
    SET @Strsql+='INNER JOIN tbl_master_address MA ON MA.add_cntId=MU.user_contactId  and MA.add_addressType=''Office'' '
    SET @Strsql+='INNER JOIN tbl_master_state MS ON MS.ID=MA.add_state '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId = MU.user_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
    SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAx(emp_id) AS emp_id,desg.deg_id '
	SET @Strsql+='FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation AS desg ON desg.deg_id=cnt.emp_Designation '
	SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil IS NULL)N '
	SET @Strsql+='ON N.emp_cntId=MU.user_contactId '
	--Rev 4.0
	IF @BRANCHID<>''
		SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCH_LIST AS F WHERE F.Branch_Id=BR.branch_id) '
	--End of Rev 4.0
	SET @Strsql+=') AS T WHERE ISNULL(T.User_id,'''')<>'''' AND CONVERT(NVARCHAR(10),T.VISIT_DATETIME,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @Employee<>''
		SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=T.EMPCODE) '
    IF @stateID<>''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=T.STATE_ID) '
	IF @DESIGNID<>''
		SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=T.deg_id) '
	--Rev 4.0
	----Rev 3.0
	--IF @BRANCHID<>''
	--	SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCH_LIST AS F WHERE F.Branch_Id=T.branch_id) '
 --   --Rev 3.0 End
	--End of Rev 4.0
	--SELECT @Strsql
	EXEC sp_executesql @Strsql
	
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #TEMPCONTACT
	--Rev 3.0
    DROP TABLE #BRANCH_LIST
    --Rev 3.0 End


	SET NOCOUNT OFF
 END
 GO