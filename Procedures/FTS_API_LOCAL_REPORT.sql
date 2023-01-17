--EXEC FTS_API_LOCAL_REPORT '15,27,28,29,20,26,16,17,23,3,13,11,18,5,6,24','','113,119,62,121,111,136,112','2019-05-01','2019-05-31',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FTS_API_LOCAL_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FTS_API_LOCAL_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[FTS_API_LOCAL_REPORT]
(
@StateID NVARCHAR(MAX)=NULL,
@Employee NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@FROM_DATE NVARCHAR(50)=NULL,
@TO_DATE NVARCHAR(50)=NULL,
@LOGIN_ID BIGINT
)WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : TANMOY GHOSH  on 08/04/2019
Module	   : Visited Location Report for office staf Track
1.0		v30.0.0		Debashis	31/05/2019		Salesman with Supervisor tracking report enhancement.Refer: 0020251 & 0020239
2.0		v2.0.38		Sanchita	12-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @sqlStrTable NVARCHAR(MAX),@Strsql NVARCHAR(MAX),@sqlStateStrTable NVARCHAR(MAX)
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #EMPLOYEE_LIST
	--Rev 1.0
	--CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NUMERIC(10,0))
	--End of Rev 1.0
	IF @Employee <> ''
		BEGIN
			SET @Employee = REPLACE(''''+@Employee+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT USER_ID from TBL_MASTER_USER where USER_CONTACTID in('+@Employee+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
-------------------------------STATE----------------------------------------------------
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #STATE_LIST
	--Rev 1.0
	--CREATE TABLE #STATE_LIST (STATE_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	CREATE TABLE #STATE_LIST (STATE_ID int)
	--End of Rev 1.0
	IF @stateID <> ''
		BEGIN
			SET @stateID = REPLACE(''''+@stateID+'''',',',''',''')
			SET @sqlStateStrTable=''
			SET @sqlStateStrTable=' INSERT INTO #STATE_LIST SELECT id from tbl_master_state where id in('+@stateID+')'
			EXEC SP_EXECUTESQL @sqlStateStrTable
		END

---------------------------------DESIGNATION-------------------------------------

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
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
	
	-- Rev 2.0
	DECLARE @user_contactId NVARCHAR(15)
	SELECT @user_contactId=user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@LOGIN_ID

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
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
	-- End of Rev 2.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSLOCATION_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSLOCATION_REPORT
			(
			  SEQ INT,
			  State_name NVARCHAR(100) NULL,
			  --Rev 1.0
			  SHOP_OWNER_NAME NVARCHAR(100) NULL,
			  SHOP_OWNER_CONTACT NVARCHAR(100) NULL,
			  --End of Rev 1.0
			  Designation NVARCHAR(100) NULL,
			  Employee_Name NVARCHAR(100) NULL,
			  --Rev 1.0
			  --VISIT_TIME DATETIME NULL,
			  VISITFROMDATE NVARCHAR(20) NULL,
			  VISITTODATE NVARCHAR(20) NULL,
			  TOTAL_HRS_WORKED NVARCHAR(50) NULL,
			  --End of Rev 1.0
			  LOCATION NVARCHAR(MAX) NULL,
			  -- Rev 2.0
			  --SHOPE_NAME NVARCHAR(100) null,
			  --SHOPE_TYPE NVARCHAR(50) NULL,
			  SHOP_NAME NVARCHAR(100) null,
			  SHOP_TYPE NVARCHAR(50) NULL,
			  -- End of Rev 2.0
			  ADDRESS NVARCHAR(MAX) NULL,
			  USER_ID BIGINT,
			  LOGIN_ID BIGINT,
			  --Rev 1.0
			  NOOFDATEVISIT INT
			  --End of Rev 1.0
			  -- Rev 2.0
			  ,ENTITYCODE NVARCHAR(100) NULL
			  -- End of Rev 2.0
			)
			--Rev 1.0
			--CREATE NONCLUSTERED INDEX IX1 ON FTSLOCATION_REPORT (USER_ID,VISIT_TIME,LOGIN_ID)
			CREATE NONCLUSTERED INDEX IX1 ON FTSLOCATION_REPORT (SEQ)
			--End of Rev 1.0
		END
		DELETE FROM FTSLOCATION_REPORT WHERE LOGIN_ID=@LOGIN_ID

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
	(
	cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	-- Rev 2.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON cnt.cnt_internalId=HRY.EMPCODE    '
	END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
	EXEC SP_EXECUTESQL @Strsql
	-- End of Rev 2.0

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSTATE') AND TYPE IN (N'U'))
		DROP TABLE #TEMPSTATE
	CREATE TABLE #TEMPSTATE
	(
	cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	STATE_ID NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	STATE_NAME NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	)
	CREATE NONCLUSTERED INDEX IX_STATEID ON #TEMPSTATE(cnt_internalId,STATE_ID ASC)
	INSERT INTO #TEMPSTATE
	SELECT   add_cntId,STAT.ID,STAT.state  FROM  tbl_master_address AS S
	LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state where add_addressType='Office' 


	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPDESI') AND TYPE IN (N'U'))
		DROP TABLE #TEMPDESI
	CREATE TABLE #TEMPDESI
	(
	cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DES_ID NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DES_NAME NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	)
	CREATE NONCLUSTERED INDEX IX_DESIID ON #TEMPDESI(cnt_internalId,DES_ID ASC)
	INSERT INTO #TEMPDESI
	select cnt.emp_cntId,desg.deg_id,desg.deg_designation  from tbl_trans_employeeCTC as cnt 
	left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil
	having emp_effectiveuntil is null 

	--Rev 1.0
	--SET @Strsql='INSERT INTO FTSLOCATION_REPORT '
	--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY sdate) AS SEQ,T.state,T.deg_designation,T.user_name,T.SDATE,T.location_name,T.Shop_Name,T.Name,T.Address,T.user_id,'+STR(@LOGIN_ID)+' FROM '

	--SET @Strsql+='(SELECT  SHP.Shop_Name,SHP.Address,LOC.location_name,CNT.cnt_firstName+'' ''+CNT.cnt_middleName+'' ''+CNT.cnt_lastName AS user_name,LOC.SDate , '
	--SET @Strsql+='N.DES_NAME AS deg_designation,STAT.STATE_NAME AS state,STYP.Name,ISNULL(STAT.STATE_ID,0) as STATE_ID,N.DES_ID AS deg_id,USR.user_id  '
	--SET @Strsql+='FROM TBL_TRANS_SHOPUSER_ARCH  LOC LEFT OUTER JOIN tbl_Master_shop SHP ON LOC.location_name=SHP.Address '--SHP.Shop_Lat=LOC.Lat_visit AND SHP.Shop_Long=LOC.Long_visit  '
	--SET @Strsql+='AND LOC.User_Id=SHP.Shop_CreateUser INNER JOIN tbl_master_user AS USR ON USR.user_id= LOC.User_Id  '
	--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId = USR.user_contactId  '
	--SET @Strsql+='LEFT OUTER JOIN tbl_shoptype STYP ON STYP.shop_typeId=SHP.type  '
	--SET @Strsql+='INNER JOIN #TEMPDESI N on  N.cnt_internalId=USR.user_contactId '
	--SET @Strsql+='LEFT OUTER JOIN #TEMPSTATE STAT ON STAT.cnt_internalId=USR.user_contactId ) T  '

	----SET @Strsql+='(SELECT  SHP.Shop_Name,SHP.Address,LOC.location_name,USR.user_name,LOC.SDate , N.deg_designation,STAT.state,STYP.Name,ISNULL(STAT.id,0) as STATE_ID,N.deg_id,USR.user_id  FROM tbl_Master_shop SHP '
	----SET @Strsql+='RIGHT OUTER JOIN TBL_TRANS_SHOPUSER_ARCH  LOC  '
	----SET @Strsql+='ON SHP.Shop_Lat=LOC.Lat_visit AND SHP.Shop_Long=LOC.Long_visit  AND LOC.User_Id=SHP.Shop_CreateUser '
	----SET @Strsql+='INNER JOIN tbl_master_user AS USR ON USR.user_id= LOC.User_Id   '
	----SET @Strsql+='INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId = USR.user_contactId '
	----SET @Strsql+='LEFT OUTER JOIN tbl_shoptype STYP ON STYP.shop_typeId=SHP.type '
	----SET @Strsql+='INNER JOIN '
	----SET @Strsql+='( '
	----SET @Strsql+='select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from '
	----SET @Strsql+='tbl_trans_employeeCTC as cnt '
	----SET @Strsql+='left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation '
	----SET @Strsql+='group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null '
	----SET @Strsql+=')N '
	----SET @Strsql+='on  N.emp_cntId=USR.user_contactId '
	----SET @Strsql+='LEFT OUTER  JOIN ( '
	----SET @Strsql+='SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office''  '
	----SET @Strsql+=')S on S.add_cntId=CNT.cnt_internalId '
	----SET @Strsql+='LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state '
	----SET @Strsql+=') T '

	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),T.sdate,23) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',23) AND CONVERT(NVARCHAR(10),'''+@TO_DATE+''',23) '
	
	--IF(ISNULL(@Employee,'')<>'')
	--	SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=cast(T.User_id as nvarchar(100)))  '
	--IF(ISNULL(@stateID,'')<>'')
	--	SET @Strsql+=' AND EXISTS (SELECT STATE_ID from #STATE_LIST AS ST WHERE ST.STATE_ID=cast(T.STATE_ID as nvarchar(100)))   '
	--	IF(ISNULL(@DESIGNID,'')<>'')
	--	SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DES WHERE DES.deg_id=cast(T.deg_id as nvarchar(100)))   '
	--SET @Strsql+='ORDER BY T.SDATE '
	SET @Strsql=''
	-- Rev 2.0
	--SET @Strsql='INSERT INTO FTSLOCATION_REPORT(LOGIN_ID,SEQ,State_name,Designation,Employee_Name,VISITFROMDATE,VISITTODATE,TOTAL_HRS_WORKED,LOCATION,SHOPE_NAME,SHOP_OWNER_NAME,SHOP_OWNER_CONTACT,SHOPE_TYPE,ADDRESS,USER_ID,NOOFDATEVISIT) '
	SET @Strsql='INSERT INTO FTSLOCATION_REPORT(LOGIN_ID,SEQ,State_name,Designation,Employee_Name,VISITFROMDATE,VISITTODATE,TOTAL_HRS_WORKED,LOCATION,SHOP_NAME,SHOP_OWNER_NAME,SHOP_OWNER_CONTACT,SHOP_TYPE,ADDRESS,USER_ID,NOOFDATEVISIT,ENTITYCODE) '
	-- End of Rev 2.0
	SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@LOGIN_ID)))+' AS LOGIN_ID,ROW_NUMBER() OVER(ORDER BY T.FROMDATE) AS SEQ,T.state,T.deg_designation,T.user_name,'
	SET @Strsql+='T.FROMDATE+'' ''+REPLACE(REPLACE(T.FROMTIME,''AM'','' AM''),''PM'','' PM'') AS FDATETIME,T.TODATE+'' ''+REPLACE(REPLACE(T.TOTIME,''AM'','' AM''),''PM'','' PM'') AS TDATETIME,'
	SET @Strsql+='RIGHT(''0'' + CAST(CAST(T.TOTAL_HRS_WORKED AS VARCHAR)/ 60 AS VARCHAR),2) + '':'' +RIGHT(''0'' + CAST(CAST(T.TOTAL_HRS_WORKED AS VARCHAR) % 60 AS VARCHAR),2) AS TOTAL_HRS_WORKED,'
	-- Rev 2.0
	--SET @Strsql+='T.location_name,T.Shop_Name,T.Shop_Owner,T.Shop_Owner_Contact,T.Name,T.Address,T.user_id,T.CNT FROM '
	SET @Strsql+='T.location_name,T.Shop_Name,T.Shop_Owner,T.Shop_Owner_Contact,T.Name,T.Address,T.user_id,T.CNT, T.EntityCode FROM '
	-- End of Rev 2.0
	SET @Strsql+='('
	SET @Strsql+='SELECT SHP.Shop_Name,SHP.Address,LOC.location_name,SHP.Shop_Owner,SHP.Shop_Owner_Contact,CNT.cnt_firstName+'' ''+CNT.cnt_middleName+'' ''+CNT.cnt_lastName AS user_name,'
	SET @Strsql+='CONVERT(NVARCHAR(10),LOC.FDATE,105) AS FROMDATE,CONVERT(NVARCHAR(10),LOC.TDATE,105) AS TODATE,CONVERT(NVARCHAR(15),CAST(LOC.FDATE AS TIME),100) AS FROMTIME,CONVERT(NVARCHAR(15),CAST(LOC.TDATE AS TIME),100) AS TOTIME,'
	SET @Strsql+='N.DES_NAME AS deg_designation,STAT.STATE_NAME AS state,STYP.Name,ISNULL(STAT.STATE_ID,0) as STATE_ID,N.DES_ID AS deg_id,USR.user_id,'
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(LOC.TDATE,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(LOC.TDATE,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(LOC.FDATE,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(LOC.FDATE,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS TOTAL_HRS_WORKED,'
	-- Rev 2.0
	--SET @Strsql+='SUM(LOC.CNT) AS CNT '
	SET @Strsql+='SUM(LOC.CNT) AS CNT, SHP.EntityCode  '
	-- End of Rev 2.0
	SET @Strsql+='FROM tbl_Master_shop SHP '
	SET @Strsql+='INNER JOIN '
	SET @Strsql+='('
	SET @Strsql+='SELECT User_Id,CAST(SDATE AS DATE) AS SDATE,MIN(SDate) AS FDATE,MAX(SDate) AS TDATE,COUNT(SDATE) AS CNT,location_name FROM TBL_TRANS_SHOPUSER_ARCH '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),sdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TO_DATE+''',120) '
	SET @Strsql+='GROUP BY User_Id,CAST(SDATE AS DATE),location_name '
	SET @Strsql+=') LOC ON SHP.Address=LOC.location_name AND LOC.User_Id=SHP.Shop_CreateUser '
	SET @Strsql+='INNER JOIN tbl_master_user AS USR ON USR.user_id= LOC.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId = USR.user_contactId '
	SET @Strsql+='LEFT OUTER JOIN tbl_shoptype STYP ON STYP.shop_typeId=SHP.type '
	SET @Strsql+='INNER JOIN #TEMPDESI N ON N.cnt_internalId=USR.user_contactId '
	SET @Strsql+='INNER JOIN #TEMPSTATE STAT ON STAT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),LOC.sdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TO_DATE+''',120) '
	IF @Employee<>''
		SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=USR.User_id) '
	IF @stateID<>''
		SET @Strsql+='AND EXISTS (SELECT STATE_ID from #STATE_LIST AS ST WHERE ST.STATE_ID=STAT.STATE_ID) '
	IF @DESIGNID<>''
		SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DES WHERE DES.deg_id=N.DES_ID)   '
	SET @Strsql+='GROUP BY SHP.Shop_Name,SHP.Address,LOC.location_name,SHP.Shop_Owner,SHP.Shop_Owner_Contact,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,N.DES_NAME,STAT.STATE_NAME,STYP.Name,'
	-- Rev 2.0
	--SET @Strsql+='STAT.STATE_ID,LOC.FDATE,LOC.TDATE,N.DES_ID,USR.user_id '
	SET @Strsql+='STAT.STATE_ID,LOC.FDATE,LOC.TDATE,N.DES_ID,USR.user_id,EntityCode '
	-- End of Rev 2.0
	SET @Strsql+=') T '
	SET @Strsql+='ORDER BY T.user_name,T.FROMDATE '
	--End of Rev 1.0
	EXEC sp_executesql @Strsql
	--select (@Strsql)
	
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATE_LIST
	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #TEMPDESI
	DROP TABLE #TEMPSTATE
	DROP TABLE #TEMPCONTACT	
	-- Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@LOGIN_ID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 2.0
	SET NOCOUNT OFF
END