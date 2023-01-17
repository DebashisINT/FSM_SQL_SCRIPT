--EXEC PRC_FTSEMPLOYEEACTIVITYSTATUS_REPORT 'EMS0000001,EMS0000005','2021-01-01','2021-01-18','','',0,'','Summary',378
--EXEC PRC_FTSEMPLOYEEACTIVITYSTATUS_REPORT '','2019-03-01','2021-03-31','','',11735,'2021-01-05','Details',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSEMPLOYEEACTIVITYSTATUS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSEMPLOYEEACTIVITYSTATUS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSEMPLOYEEACTIVITYSTATUS_REPORT]
(
@EMPCODE NVARCHAR(MAX)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@USERID BIGINT=NULL,
@VISITDATE NVARCHAR(10)=NULL,
@REPORTTYPE NVARCHAR(10),
@LOGINID BIGINT
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder On 19/01/2021
Module	   : Employee Activity Status Report.Refer: 0023555
1.0		v2.0.38		Sanchita	12-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (EMPUSER_ID NUMERIC(10,0))
	IF @EMPCODE<>''
		BEGIN
			SET @EMPCODE = REPLACE(''''+@EMPCODE+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT USER_ID FROM TBL_MASTER_USER WHERE USER_CONTACTID IN('+@EMPCODE+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END
-------------------------------STATE----------------------------------------------------
	IF OBJECT_ID('tempdb..#STATE_LIST') IS NOT NULL
		DROP TABLE #STATE_LIST
	CREATE TABLE #STATE_LIST (STATE_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @STATEID<>''
		BEGIN
			SET @STATEID = REPLACE(''''+@STATEID+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #STATE_LIST SELECT id FROM tbl_master_state WHERE ID IN('+@STATEID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

---------------------------------DESIGNATION-------------------------------------
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DESIGNID<>''
		BEGIN
			SET @DESIGNID=REPLACE(@DESIGNID,'''','')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #DESIGNATION_LIST SELECT deg_id FROM tbl_master_designation WHERE DEG_ID IN('+@DESIGNID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END
	
	-- Rev 1.0
	DECLARE @user_contactId NVARCHAR(15)
	SELECT @user_contactId=user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@USERID

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
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
		where EMPCODE IS NULL OR EMPCODE=@user_contactId  
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
	-- End of Rev 1.0

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_UCC NVARCHAR(80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	-- Rev 1.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_branchid,cnt_UCC,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT cnt_internalId,cnt_branchid,cnt_UCC,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT CNT '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
	END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
	exec sp_executesql @Strsql
	-- End of Rev 1.0
	
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSEMPLOYEEACTIVITYSTATUS_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSEMPLOYEEACTIVITYSTATUS_REPORT
			(
			  SEQ INT,
			  LOGINID INT,
			  REPORTTYPE NVARCHAR(10),
			  USERID BIGINT,
			  USERLOGINID NVARCHAR(50) NULL,
			  EMPLOYEE_ID NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  STATE_NAME NVARCHAR(100) NULL,
			  DESIGNATION NVARCHAR(100) NULL,
			  BRANCHDESC NVARCHAR(300),
			  SHOP_NAME NVARCHAR(2000) NULL,
			  ENTITYCODE NVARCHAR(600) NULL,
			  SHOP_TYPE NVARCHAR(50) NULL,
			  MOBILE_NO NVARCHAR(20) NULL,
			  VISITLOCATION NVARCHAR(MAX) NULL,
			  VISIT_DATETIME NVARCHAR(30) NULL,
			  VISIT_TIME_ORDBY NVARCHAR(30) NULL,
			  DURATION NVARCHAR(50) NULL,
			  DISTANCE DECIMAL(18,2),
			  VISIT_TYPE NVARCHAR(100) NULL,
			  LOGGEDIN NVARCHAR(10) NULL,
			  LOGEDOUT NVARCHAR(10) NULL,
			  ACTIVITYCNT INT NULL,
			  REMARKS NVARCHAR(2000) NULL			 
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSEMPLOYEEACTIVITYSTATUS_REPORT (LOGINID,VISIT_DATETIME,USERLOGINID)
		END
	DELETE FROM FTSEMPLOYEEACTIVITYSTATUS_REPORT WHERE LOGINID=@LOGINID AND REPORTTYPE=@REPORTTYPE

	SET @Strsql=''
	IF @REPORTTYPE='Summary'
		BEGIN
			SET @Strsql='INSERT INTO FTSEMPLOYEEACTIVITYSTATUS_REPORT(SEQ,LOGINID,REPORTTYPE,USERID,VISIT_DATETIME,VISIT_TIME_ORDBY,EMPNAME,USERLOGINID,STATE_NAME,DESIGNATION,EMPLOYEE_ID,LOGGEDIN,LOGEDOUT,ACTIVITYCNT) '
			SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY T.user_name,T.Visit_Time_ORDBY) AS SEQ,'+LTRIM(RTRIM(STR(@LOGINID)))+' AS LOGINID,'''+@REPORTTYPE+''' AS REPORTTYPE,T.USER_ID,'
			SET @Strsql+='CONVERT(NVARCHAR(10),T.Visit_Time,105) AS VISIT_DATETIME,T.VISIT_TIME_ORDBY,T.USER_NAME AS EMPNAME,T.user_loginId AS USERLOGINID,T.STATE,T.DEG_DESIGNATION,T.EMPLOYEE_ID,T.LOGGEDIN,'
			SET @Strsql+='T.LOGEDOUT,COUNT(CONVERT(NVARCHAR(10),T.Visit_Time,105)) AS ACTIVITYCNT FROM ('
			SET @Strsql+='SELECT mstShp.Shop_Name,MSTSHP.ENTITYCODE,SHPTYP.Name AS Shop_Type,mstShp.Shop_Owner_Contact AS Mobile_No,mstShp.Address AS Location,shpAvtv.visited_time AS Visit_Time,'
			SET @Strsql+='CONVERT(NVARCHAR(10),shpAvtv.visited_time,120) AS Visit_Time_ORDBY,shpAvtv.spent_duration AS Duration,ISNULL(shpAvtv.distance_travelled,0) AS Distance,'
			SET @Strsql+='CASE WHEN shpAvtv.is_Newshopadd=1 THEN ''New'' ELSE ''Re-Visit'' END AS Visit_Type,shpAvtv.REMARKS,shpAvtv.User_Id,'
			SET @Strsql+='MU.user_loginId,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+(CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.cnt_lastName,'''') AS user_name,'
			SET @Strsql+='MS.state,MS.id AS STATE_ID,BR.branch_description AS BRANCHDESC,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT '
			SET @Strsql+='FROM tbl_trans_shopActivitysubmit shpAvtv '
			SET @Strsql+='INNER JOIN tbl_Master_shop mstShp on mstShp.Shop_Code=shpAvtv.Shop_Id '
			SET @Strsql+='INNER JOIN tbl_shoptype SHPTYP ON SHPTYP.TypeId=mstShp.type '
			SET @Strsql+='INNER JOIN TBL_MASTER_USER MU ON MU.user_id=shpAvtv.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_address MA ON MA.add_cntId=MU.user_contactId and MA.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state MS ON MS.ID=MA.add_state '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=MU.user_contactId '
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT FROM('
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id '
			SET @Strsql+=') LOGINLOGOUT GROUP BY USERID) ATTEN ON ATTEN.USERID=MU.user_id '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAx(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation '
			SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil HAVING emp_effectiveuntil IS NULL)N ON N.emp_cntId=MU.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),shpAvtv.visited_time,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			IF @EMPCODE<>''
				SET @Strsql+='AND EXISTS (SELECT EMPUSER_ID FROM #EMPLOYEE_LIST AS EMP WHERE EMP.EMPUSER_ID=MU.user_id) '
			IF @stateID<>''
				SET @Strsql+='AND EXISTS (SELECT STATE_ID FROM #STATE_LIST AS ST WHERE ST.STATE_ID=MS.ID) '
			 IF @DESIGNID<>''
				SET @Strsql+='AND EXISTS (SELECT deg_id FROM #DESIGNATION_LIST AS DES WHERE DES.deg_id=N.deg_id) '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT '''' AS Shop_name,'''' AS ENTITYCODE,'''' AS Shop_Type,'''' AS Mobile_No,location_name AS Location,SDate AS Visit_Time,CONVERT(NVARCHAR(10),SDate,120) AS Visit_Time_ORDBY,'
			SET @Strsql+=''''' AS Duration,distance_covered AS Distance,'''' AS Visit_Type,'''' AS REMARKS,TSA.User_id,MU.user_loginId,'
			SET @Strsql+='ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+(CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.cnt_lastName,'''') AS user_name,'
			SET @Strsql+='MS.state,MS.id AS STATE_ID,BR.branch_description AS BRANCHDESC,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT '
			SET @Strsql+='FROM TBL_TRANS_SHOPUSER_ARCH TSA '
			SET @Strsql+='INNER JOIN TBL_MASTER_USER MU ON MU.user_id=TSA.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_address MA ON MA.add_cntId=MU.user_contactId  and MA.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state MS ON MS.ID=MA.add_state '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=MU.user_contactId '
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT FROM('
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id '
			SET @Strsql+=') LOGINLOGOUT GROUP BY USERID) ATTEN ON ATTEN.USERID=MU.user_id '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation AS desg ON desg.deg_id=cnt.emp_Designation '
			SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil HAVING emp_effectiveuntil IS NULL)N ON N.emp_cntId=MU.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),TSA.SDate,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			IF @EMPCODE<>''
				SET @Strsql+='AND EXISTS (SELECT EMPUSER_ID FROM #EMPLOYEE_LIST AS EMP WHERE EMP.EMPUSER_ID=MU.User_Id) '
			IF @stateID<>''
				SET @Strsql+='AND EXISTS (SELECT STATE_ID FROM #STATE_LIST AS ST WHERE ST.STATE_ID=MS.ID) '
			 IF @DESIGNID<>''
				SET @Strsql+='AND EXISTS (SELECT deg_id FROM #DESIGNATION_LIST AS DES WHERE DES.deg_id=N.deg_id) '
			SET @Strsql+=') AS T '
			SET @Strsql+='GROUP BY T.VISIT_TIME_ORDBY,CONVERT(NVARCHAR(10),T.VISIT_TIME,105),T.USER_ID,T.USER_NAME,T.USER_LOGINID,T.STATE,T.DEG_DESIGNATION,T.EMPLOYEE_ID,T.LOGGEDIN,T.LOGEDOUT '
		END
	ELSE IF @REPORTTYPE='Details'
		BEGIN
			SET @Strsql='INSERT INTO FTSEMPLOYEEACTIVITYSTATUS_REPORT(SEQ,LOGINID,REPORTTYPE,USERID,EMPLOYEE_ID,USERLOGINID,EMPNAME,STATE_NAME,DESIGNATION,BRANCHDESC,SHOP_NAME,ENTITYCODE,SHOP_TYPE,MOBILE_NO,'
			SET @Strsql+='VISITLOCATION,VISIT_DATETIME,VISIT_TIME_ORDBY,DURATION,DISTANCE,VISIT_TYPE,REMARKS) '
			SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY T.Visit_Time) AS SEQ,'+LTRIM(RTRIM(STR(@LOGINID)))+' AS LOGINID,'''+@REPORTTYPE+''' AS REPORTTYPE,T.USER_ID,T.EMPLOYEE_ID,T.USER_LOGINID,T.USER_NAME AS EMPNAME,T.STATE,'
			SET @Strsql+='T.DEG_DESIGNATION,T.BRANCHDESC,T.SHOP_NAME,T.ENTITYCODE,T.SHOP_TYPE,T.MOBILE_NO,T.LOCATION,CONVERT(NVARCHAR(10),T.Visit_Time,105)+'' ''+CONVERT(VARCHAR(5),CAST(T.Visit_Time AS TIME),108) AS VISIT_DATETIME,'
			SET @Strsql+='T.VISIT_TIME_ORDBY,T.DURATION,T.DISTANCE,T.VISIT_TYPE,T.REMARKS FROM ('
			SET @Strsql+='SELECT mstShp.Shop_Name,MSTSHP.ENTITYCODE,SHPTYP.Name AS Shop_Type,mstShp.Shop_Owner_Contact AS Mobile_No,mstShp.Address AS Location,shpAvtv.visited_time AS Visit_Time,'
			SET @Strsql+='CONVERT(NVARCHAR(10),shpAvtv.visited_time,120) AS VISIT_TIME_ORDBY,shpAvtv.spent_duration AS Duration,ISNULL(shpAvtv.distance_travelled,0) AS Distance,'
			SET @Strsql+='CASE WHEN shpAvtv.is_Newshopadd=1 THEN ''New'' ELSE ''Re-Visit'' END AS Visit_Type,shpAvtv.REMARKS,shpAvtv.User_Id,'
			SET @Strsql+='MU.user_loginId,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+(CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.cnt_lastName,'''') AS user_name,'
			SET @Strsql+='MS.state,MS.id AS STATE_ID,BR.branch_description AS BRANCHDESC,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID '
			SET @Strsql+='FROM tbl_trans_shopActivitysubmit shpAvtv '
			SET @Strsql+='INNER JOIN tbl_Master_shop mstShp on mstShp.Shop_Code=shpAvtv.Shop_Id '
			SET @Strsql+='INNER JOIN tbl_shoptype SHPTYP ON SHPTYP.TypeId=mstShp.type '
			SET @Strsql+='INNER JOIN TBL_MASTER_USER MU ON MU.user_id=shpAvtv.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_address MA ON MA.add_cntId=MU.user_contactId and MA.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state MS ON MS.ID=MA.add_state '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=MU.user_contactId '
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAx(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation '
			SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil HAVING emp_effectiveuntil IS NULL)N ON N.emp_cntId=MU.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),shpAvtv.visited_time,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT '''' AS Shop_name,'''' AS ENTITYCODE,'''' AS Shop_Type,'''' AS Mobile_No,location_name AS Location,SDate AS Visit_Time,CONVERT(NVARCHAR(10),SDate,120) AS VISIT_TIME_ORDBY,'
			SET @Strsql+=''''' AS Duration,distance_covered AS Distance,'''' AS Visit_Type,'''' AS REMARKS,TSA.User_id,MU.user_loginId,'
			SET @Strsql+='ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+(CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.cnt_lastName,'''') AS user_name,'
			SET @Strsql+='MS.state,MS.id AS STATE_ID,BR.branch_description AS BRANCHDESC,N.deg_designation,N.deg_id,CNT.cnt_UCC AS Employee_ID '
			SET @Strsql+='FROM TBL_TRANS_SHOPUSER_ARCH TSA '
			SET @Strsql+='INNER JOIN TBL_MASTER_USER MU ON MU.user_id=TSA.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_address MA ON MA.add_cntId=MU.user_contactId  and MA.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state MS ON MS.ID=MA.add_state '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=MU.user_contactId '
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation AS desg ON desg.deg_id=cnt.emp_Designation '
			SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil HAVING emp_effectiveuntil IS NULL)N ON N.emp_cntId=MU.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),TSA.SDate,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+=') AS T '
			SET @Strsql+='WHERE CAST(T.USER_ID AS NVARCHAR(20))='''+LTRIM(RTRIM(STR(@USERID)))+''' AND T.VISIT_TIME_ORDBY='''+@VISITDATE+''' '
		END
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATE_LIST
	DROP TABLE #TEMPCONTACT

	-- Rev 1.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 1.0

	SET NOCOUNT OFF
END