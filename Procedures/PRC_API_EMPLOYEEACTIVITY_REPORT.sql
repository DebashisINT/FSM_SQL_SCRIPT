--EXEC PRC_API_EMPLOYEEACTIVITY_REPORT '','2022-01-08','2022-01-14',378,'',''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_API_EMPLOYEEACTIVITY_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_API_EMPLOYEEACTIVITY_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_API_EMPLOYEEACTIVITY_REPORT]
(
@Employee NVARCHAR(max)=null,
@FROMDATE NVARCHAR(50)=NULL,
@TODATE NVARCHAR(50)=NULL,
@LOGIN_ID BIGINT,
@stateID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : TANMOY GHOSH  on 28/03/2019 CHANGE 07/05/19 ADD EMPLOYEE ID
Module	   : Employee Activity Report for Track
1.0			v2.0.11		Debashis	12/05/2020		FTS reports with more fields.Refer: 0022323
2.0			v2.0.11		Debashis	26/05/2020		Employee Activity report is not generating.Now solved.Refer: 0022370
3.0			v2.0.13		Debashis	24/06/2020		Branch column required in the various FSM reports.Refer: 0022610
4.0			v2.0.24		Debashis	30/07/2021		Employee Activity Employee Activity Details This report shall not be showing distance subtotal of Visit /Revisit.
													Refer: 0024198
5.0			v2.0.26		Debashis	12/01/2022		District/Cluster/Pincode fields are required in some of the reports.Refer: 0024575
6.0			v2.0.26		Debashis	13/01/2022		Alternate phone no. 1 & alternate email fields are required in some of the reports.Refer: 0024577
7.0			v2.0.26		Debashis	24/01/2022		Reports > Employee Tracking > Employee Activity, Unable to generate report, system is getting logout.Refer: 0024636
8.0			v2.0.30		Debashis	01/06/2022		While generating the Employee Activity Report for 7 days, system getting logged out.Now solved.Refer: 0024921
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @sqlStrTable NVARCHAR(MAX),@Strsql NVARCHAR(MAX),@sqlStateStrTable NVARCHAR(MAX)

	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @Employee <> ''
		BEGIN
			SET @Employee = REPLACE(''''+@Employee+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT USER_ID from TBL_MASTER_USER where USER_CONTACTID in('+@Employee+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
-------------------------------STATE----------------------------------------------------
	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#STATE_LIST') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #STATE_LIST
	CREATE TABLE #STATE_LIST (STATE_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @stateID <> ''
		BEGIN
			SET @stateID = REPLACE(''''+@stateID+'''',',',''',''')
			SET @sqlStateStrTable=''
			SET @sqlStateStrTable=' INSERT INTO #STATE_LIST SELECT id from tbl_master_state where id in('+@stateID+')'
			EXEC SP_EXECUTESQL @sqlStateStrTable
		END

---------------------------------DESIGNATION-------------------------------------
	--Rev 1.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
	--End of Rev 1.0
		DROP TABLE #DESIGNATION_LIST
		CREATE TABLE #DESIGNATION_LIST (deg_id INT)
		CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
		IF @DESIGNID <> ''
			BEGIN
				SET @DESIGNID=REPLACE(@DESIGNID,'''','')
				SET @sqlStrTable=''
				SET @sqlStrTable=' INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation where deg_id in('+@DESIGNID+')'
				EXEC SP_EXECUTESQL @sqlStrTable
			END

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSACTIVITY_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSACTIVITY_REPORT
			(
			  SEQ INT,
			  State_name NVARCHAR(100) NULL,
			  --Rev 3.0
			  BRANCHDESC NVARCHAR(300),
			  --End of Rev 3.0
			  --Rev 8.0
			  --Designation NVARCHAR(100) NULL,
			  --Employee_Name NVARCHAR(100) NULL,
			  --SHOP_NAME NVARCHAR(100) NULL,
			  Designation NVARCHAR(300) NULL,
			  Employee_Name NVARCHAR(300) NULL,
			  SHOP_NAME NVARCHAR(300) NULL,
			  --End of Rev 8.0
			  --Rev 5.0
			  SHOP_DISTRICT NVARCHAR(50) NULL,
			  SHOP_PINCODE NVARCHAR(120) NULL,
			  SHOP_CLUSTER NVARCHAR(500) NULL,
			  --End of Rev 5.0
			  --Rev 1.0
			  ENTITYCODE NVARCHAR(600) NULL,
			  --End of Rev 1.0
			  SHOP_TYPE NVARCHAR(50) NULL,
			  --Rev 7.0
			  --MOBILE_NO NVARCHAR(10) NULL,
			  MOBILE_NO NVARCHAR(100) NULL,
			  --End of Rev 7.0
			  --Rev 6.0
			  ALT_MOBILENO1 NVARCHAR(40) NULL,
			  SHOP_OWNER_EMAIL2 NVARCHAR(300) NULL,
			  --End of Rev 6.0
			  LOCATION NVARCHAR(MAX) NULL,
			  VISIT_TIME DATETIME NULL,
			  DURATION NVARCHAR(50) NULL,
			  DISTANCE DECIMAL(18,2),
			  VISIT_TYPE NVARCHAR(100) NULL,
			  --Rev 1.0
			  REMARKS NVARCHAR(2000) NULL,
			  --End of Rev 1.0
			  USER_ID BIGINT,
			  LOGIN_ID BIGINT,
			  Employee_ID NVARCHAR(100) NULL 
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSACTIVITY_REPORT (USER_ID,VISIT_TIME,LOGIN_ID)
		END
	DELETE FROM FTSACTIVITY_REPORT WHERE LOGIN_ID=@LOGIN_ID

	--Rev 5.0 && Added three new fields as SHOP_DISTRICT,SHOP_PINCODE & SHOP_CLUSTER
	--Rev 6.0 && Added two new fields as ALT_MOBILENO1 & SHOP_OWNER_EMAIL2
    SET @Strsql='INSERT INTO FTSACTIVITY_REPORT '
	--Rev 1.0
	--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY Visit_Time) AS SEQ,T.state,T.deg_designation,T.user_name,T.Shop_Name, '
	--SET @Strsql+='T.Shop_Type,T.Mobile_No,T.Location,T.Visit_Time,T.Duration,T.Distance,T.Visit_Type,T.User_Id,T.login_id,T.Employee_ID FROM ( '
	--SET @Strsql+='SELECT mstShp.Shop_Name,SHPTYP.Name AS Shop_Type,mstShp.Shop_Owner_Contact AS Mobile_No, '
	--Rev 3.0
	--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY Visit_Time) AS SEQ,T.state,T.deg_designation,T.user_name,T.Shop_Name,T.ENTITYCODE,'
	SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY Visit_Time) AS SEQ,T.state,T.BRANCHDESC,T.deg_designation,T.user_name,T.Shop_Name,T.SHOP_DISTRICT,T.SHOP_PINCODE,T.SHOP_CLUSTER,T.ENTITYCODE,'
	--End of Rev 3.0
	--Rev 6.0
	--SET @Strsql+='T.Shop_Type,T.Mobile_No,T.Location,T.Visit_Time,T.Duration,T.Distance,T.Visit_Type,T.REMARKS,T.User_Id,T.login_id,T.Employee_ID FROM ('
	SET @Strsql+='T.Shop_Type,T.Mobile_No,T.ALT_MOBILENO1,T.SHOP_OWNER_EMAIL2,T.Location,T.Visit_Time,T.Duration,T.Distance,T.Visit_Type,T.REMARKS,T.User_Id,T.login_id,T.Employee_ID FROM ('
	--End of Rev 6.0
	SET @Strsql+='SELECT mstShp.Shop_Name,MSTSHP.ENTITYCODE,SHPTYP.Name AS Shop_Type,mstShp.Shop_Owner_Contact AS Mobile_No,'
	--End of Rev 1.0
	--Rev 4.0
	--SET @Strsql+='mstShp.Address as Location,shpAvtv.visited_time AS Visit_Time,shpAvtv.spent_duration AS Duration,ISNULL(shpAvtv.distance_travelled,0) AS Distance,'
	SET @Strsql+='mstShp.Address as Location,shpAvtv.visited_time AS Visit_Time,shpAvtv.spent_duration AS Duration,0 AS Distance,'
	--End of Rev 4.0
	--Rev 1.0
	--SET @Strsql+='CASE WHEN shpAvtv.is_Newshopadd=1 THEN ''New'' ELSE ''Re-Visit'' END AS Visit_Type,shpAvtv.User_Id,'+str(@LOGIN_ID)+' as login_id ,  '
	SET @Strsql+='CASE WHEN shpAvtv.is_Newshopadd=1 THEN ''New'' ELSE ''Re-Visit'' END AS Visit_Type,shpAvtv.REMARKS,shpAvtv.User_Id,'+str(@LOGIN_ID)+' as login_id , '
	--End of Rev 1.0
	--Rev 2.0
	--SET @Strsql+='CNT.cnt_firstName+'' ''+CNT.cnt_middleName+'' ''+CNT.cnt_lastName AS user_name,'
	SET @Strsql+='ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+(CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.cnt_lastName,'''') AS user_name,'
	--End of Rev 2.0
	--Rev 3.0
	--SET @Strsql+='MS.state,MS.id AS STATE_ID,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID '
	SET @Strsql+='MS.state,MS.id AS STATE_ID,BR.branch_description AS BRANCHDESC,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID,'
	--End of Rev 3.0
	--Rev 5.0
	SET @Strsql+='CITY.CITY_NAME AS SHOP_DISTRICT,mstShp.Pincode AS SHOP_PINCODE,mstShp.CLUSTER AS SHOP_CLUSTER,'
	--End of Rev 5.0
	--Rev 6.0
	SET @Strsql+='mstShp.Alt_MobileNo1,mstShp.Shop_Owner_Email2 '
	--End of Rev 6.0
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit shpAvtv '
	SET @Strsql+='INNER JOIN tbl_Master_shop mstShp on mstShp.Shop_Code=shpAvtv.Shop_Id '
	SET @Strsql+='INNER JOIN tbl_shoptype SHPTYP ON SHPTYP.TypeId=mstShp.type '
	SET @Strsql+='INNER JOIN TBL_MASTER_USER MU ON MU.user_id=shpAvtv.User_Id '
	SET @Strsql+='INNER JOIN tbl_master_address MA ON MA.add_cntId=MU.user_contactId and MA.add_addressType=''Office'' ' 
    SET @Strsql+='INNER JOIN tbl_master_state MS ON MS.ID=MA.add_state  '
    SET @Strsql+='INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId = MU.user_contactId '
	--Rev 3.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	--End of Rev 3.0
    SET @Strsql+='INNER JOIN ( select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from  '
    SET @Strsql+='tbl_trans_employeeCTC as cnt '
    SET @Strsql+='left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation  '
    SET @Strsql+='group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null )N  '
    SET @Strsql+='on  N.emp_cntId=MU.user_contactId '
	--Rev 5.0
	SET @Strsql+='LEFT OUTER JOIN TBL_MASTER_CITY CITY ON mstShp.Shop_City=CITY.city_id '
	--End of Rev 5.0
	SET @Strsql+='UNION ALL '
	--Rev 1.0
	--SET @Strsql+='SELECT '''' AS Shop_name,'''' AS Shop_Type,'''' AS Mobile_No,location_name AS Location,SDate AS Visit_Time,'''' AS Distance, '
	--SET @Strsql+='distance_covered AS Distance,'''' AS Visit_Type,TSA.User_id,'+str(@LOGIN_ID)+' as login_id,CNT.cnt_firstName+'' ''+CNT.cnt_middleName+'' ''+CNT.cnt_lastName AS user_name,  '
	SET @Strsql+='SELECT '''' AS Shop_name,'''' AS ENTITYCODE,'''' AS Shop_Type,'''' AS Mobile_No,location_name AS Location,SDate AS Visit_Time,'''' AS Distance,'
	SET @Strsql+='distance_covered AS Distance,'''' AS Visit_Type,'''' AS REMARKS,TSA.User_id,'+str(@LOGIN_ID)+' AS login_id,'
	--Rev 2.0
	--CNT.cnt_firstName+'' ''+CNT.cnt_middleName+'' ''+CNT.cnt_lastName AS user_name,'
	SET @Strsql+='ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+(CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.cnt_lastName,'''') AS user_name,'
	--End of Rev 2.0
	--End of Rev 1.0
	--Rev 3.0
	--SET @Strsql+='MS.state,MS.id AS STATE_ID,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID  FROM TBL_TRANS_SHOPUSER_ARCH TSA '
	SET @Strsql+='MS.state,MS.id AS STATE_ID,BR.branch_description AS BRANCHDESC,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID,'
	--Rev 5.0
	SET @Strsql+=''''' AS SHOP_DISTRICT,'''' AS SHOP_PINCODE,'''' AS SHOP_CLUSTER,'	
	--End of Rev 5.0
	--Rev 6.0
	SET @Strsql+=''''' AS Alt_MobileNo1,'''' AS Shop_Owner_Email2 '
	--End of Rev 6.0
	SET @Strsql+='FROM TBL_TRANS_SHOPUSER_ARCH TSA '
	--End of Rev 3.0
	SET @Strsql+='INNER JOIN TBL_MASTER_USER MU ON MU.user_id=TSA.User_Id '
    SET @Strsql+='INNER JOIN tbl_master_address MA ON MA.add_cntId=MU.user_contactId  and MA.add_addressType=''Office'' '
    SET @Strsql+='INNER JOIN tbl_master_state MS ON MS.ID=MA.add_state '
	SET @Strsql+='INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId = MU.user_contactId '
	--Rev 3.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	--End of Rev 3.0
    SET @Strsql+='INNER JOIN ( select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from '
	SET @Strsql+='tbl_trans_employeeCTC as cnt left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation '
	SET @Strsql+='group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null )N '
	SET @Strsql+='on  N.emp_cntId=MU.user_contactId '
	SET @Strsql+=') AS T WHERE ISNULL(T.User_id,'''')<>'''' AND CONVERT(NVARCHAR(10),T.Visit_Time,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',23) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',23) '
	IF(ISNULL(@Employee,'')<>'')
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=cast(T.User_id as nvarchar(100)))  '
    IF(ISNULL(@stateID,'')<>'')
		SET @Strsql+=' AND EXISTS (SELECT STATE_ID from #STATE_LIST AS ST WHERE ST.STATE_ID=cast(T.STATE_ID as nvarchar(100)))   '
	 IF(ISNULL(@DESIGNID,'')<>'')
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DES WHERE DES.deg_id=cast(T.deg_id as nvarchar(100)))   '
    SET @Strsql+='ORDER BY T.Visit_Time  '
	--select @Strsql
	exec sp_executesql @Strsql
	
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATE_LIST
	DROP TABLE #DESIGNATION_LIST

	SET NOCOUNT OFF
 END