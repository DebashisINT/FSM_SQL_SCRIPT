IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSActivityDetails_List]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSActivityDetails_List] AS'  
END 
GO 

--EXEC PRC_FTSActivityDetails_List @FROMDATE='2020-05-22',@TODATE='2020-09-21',@USERID=378
ALTER PROCEDURE [dbo].[PRC_FTSActivityDetails_List]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT,
@DesigId NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0			Tanmoy		14-09-2020			Create sp
2.0			Sanchita	02-02-2023		v2.0.38		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
													then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)


	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
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
	
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
	BEGIN
		SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
		EXEC SP_EXECUTESQL @sqlStrTable
	END

	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
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
	
	-- Rev 2.0
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
	-- End of Rev 2.0
	
	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
	DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
	(
		cnt_internalId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_firstName NVARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_middleName NVARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_lastName NVARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_ucc NVARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		USER_ID BIGINT,
		-- Rev 2.0 [ existing issue solved]
		--Contact_no nvarchar(20)
		Contact_no nvarchar(50)
		-- End of Rev 2.0
	)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	-- Rev 2.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id,USR.user_loginId FROM TBL_MASTER_CONTACT CNT
	--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE cnt_contactType IN('EM')
	
	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id,USR.user_loginId FROM TBL_MASTER_CONTACT CNT '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId ' 
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
		END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
	exec sp_executesql @Strsql
	-- End of Rev 2.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_ActivityDetailsReport') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTS_ActivityDetailsReport
			(
			SEQ BIGINT,
			USERID BIGINT,
			ActivityCode NVARCHAR(100),
			Party_Code NVARCHAR(100),
			Activity_Date NVARCHAR(10),
			Activity_Time NVARCHAR(10),
			ContactName NVARCHAR(500),
			ActivitySubject NVARCHAR(MAX),
			ActivityDetails NVARCHAR(MAX),
			Assignto NVARCHAR(300),
			Duration NVARCHAR(10),
			Due_Date NVARCHAR(10),
			Due_Time NVARCHAR(10),
			CREATED_DATE DATETIME,
			CREATE_BY NVARCHAR(300),
			MODIFIED_BY NVARCHAR(300),
			MODIFIED_DATE DATETIME,
			ActivityName NVARCHAR(200),
			ActivityTypeName NVARCHAR(200),
			PriorityName NVARCHAR(200),
			Shop_Name NVARCHAR(300),
			Address NVARCHAR(MAX),
			Shop_Owner NVARCHAR(200),
			Shop_Owner_Contact NVARCHAR(15),
			Product_Name NVARCHAR(MAX)
			)
		END

	delete from FTS_ActivityDetailsReport where USERID=@USERID

	SET @Strsql=' '

	SET @Strsql+=' INSERT INTO FTS_ActivityDetailsReport '
	SET @Strsql+=' SELECT ROW_NUMBER() OVER(ORDER BY HEAD.Activity_Date DESC) AS SEQ,'''+STR(@USERID)+''',HEAD.ActivityCode,HEAD.Party_Code,CONVERT(NVARCHAR(10),HEAD.Activity_Date,105), '
	SET @Strsql+=' RIGHT(CONVERT(VARCHAR,HEAD.Activity_Date, 100), 7),HEAD.ContactName,HEAD.ActivitySubject, '
	SET @Strsql+=' HEAD.ActivityDetails, '
	SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''')+'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS Assignto, '
	SET @Strsql+=' CONVERT(NVARCHAR(10),HEAD.Duration,108),CONVERT(NVARCHAR(10),HEAD.Duedate,105),RIGHT(CONVERT(VARCHAR,HEAD.Duedate, 100), 7),HEAD.Created_date, '
	SET @Strsql+=' ISNULL(CREAT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CREAT.cnt_middleName,'''')<>'''' THEN ISNULL(CREAT.cnt_middleName,'''')  '
	SET @Strsql+=' +'' '' ELSE '''' END +ISNULL(CREAT.cnt_lastName,'''') AS CREATE_BY, '
	SET @Strsql+=' ISNULL(UPDATED.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(UPDATED.cnt_middleName,'''')<>'''' THEN ISNULL(UPDATED.cnt_middleName,'''')  '
	SET @Strsql+=' +'' '' ELSE '''' END +ISNULL(UPDATED.cnt_lastName,'''') AS Modified_by, '
	SET @Strsql+=' HEAD.Modified_date,ACTV.ActivityName,TYP.ActivityTypeName,PROTY.PriorityName,SHOP.Shop_Name, '
	SET @Strsql+=' SHOP.Address,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact '
	SET @Strsql+=' ,STUFF( '
    SET @Strsql+=' (SELECT '','' + t1.sProducts_Description '
    SET @Strsql+=' FROM Master_sProducts t1 '
	SET @Strsql+=' inner join FTS_ActivityProducts map on t1.sProducts_ID = map.ProdId '
    SET @Strsql+=' WHERE t1.sProducts_ID = map.ProdId and map.ActivityId=HEAD.ID '
	SET @Strsql+=' AND map.Party_Code=HEAD.Party_Code '
    SET @Strsql+=' FOR XML PATH ('''')) '
    SET @Strsql+=' , 1, 1, '''') as Product '
	SET @Strsql+=' FROM FTS_SalesActivity HEAD '
	SET @Strsql+=' LEFT OUTER JOIN FTS_Activity ACTV ON HEAD.Activityid=ACTV.Id '
	SET @Strsql+=' LEFT OUTER JOIN FTS_ActivityType TYP ON HEAD.Typeid=TYP.Id '
	SET @Strsql+=' LEFT OUTER JOIN FTS_Priority PROTY ON HEAD.Priorityid=PROTY.Id '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_Code=HEAD.Party_Code '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CREAT ON HEAD.Created_by=CREAT.USER_ID '
	SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT UPDATED ON HEAD.Modified_by=UPDATED.USER_ID '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON HEAD.Assignto=CNT.USER_ID '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),HEAD.Activity_Date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '	
	--IF @STATEID<>''
	--	SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SAT.id) '
	IF @EMPID<>''
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	--IF @DesigId<>''
	--	SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '

	SET @Strsql+=' ORDER BY HEAD.Activity_Date   '

	EXEC SP_EXECUTESQL @Strsql
	--SELECT @Strsql


	DROP TABLE #TEMPCONTACT
	DROP TABLE #STATEID_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #DESIGNATION_LIST
	-- Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 2.0

	SET NOCOUNT OFF
END
