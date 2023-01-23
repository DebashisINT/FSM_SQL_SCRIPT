IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSDailyAccountabilityTracker]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSDailyAccountabilityTracker] AS' 
END
GO

--EXEC PRC_FTSDailyAccountabilityTracker @USERID=378,@FROMDATE='2021-01-23',@TODATE='2021-08-03'

ALTER PROCEDURE [dbo].[PRC_FTSDailyAccountabilityTracker]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
)  
AS
/****************************************************************************************************************************************************************************
1.0					Tanmoy		11-05-2021		Remove space between name and surname
2.0					Tanmoy		05-08-2021		ADD EXTRA COLUMN
3.0		v2.0.38		Sanchita	12-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	DECLARE @EMPID1 NVARCHAR(MAX)
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
	
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
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

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID1 = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID1+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	-- Rev 3.0
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
	-- End of Rev 3.0

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
	(
		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_branchid INT,
		cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	-- Rev 3.0
	--INSERT INTO #TEMPCONTACT
	
	--SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	
	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT CNT '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
	END
	SET @Strsql+=' WHERE cnt_contactType IN (''EM'') '
	exec sp_executesql @Strsql
	-- End of Rev 3.0
	
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSDAILYACCOUNTABILITYTRACKER_REPORT') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTSDAILYACCOUNTABILITYTRACKER_REPORT
		(
		USERID int NULL,
		SEQ int NULL,
		DATE DATE,
		Doctors_Visited NVARCHAR(500),
		TopicOfDiscussion NVARCHAR(500),
		Doctors_Phone NVARCHAR(500),
		Doctors_PhoneTopicOfDiscussion NVARCHAR(500),
		DoctorsWhatsApp NVARCHAR(500),
		DoctorsWhatsApp_TopicOfDiscussion NVARCHAR(500),
		DoctorsOthers NVARCHAR(500),
		DoctorsOthers_TopicOfDiscussion NVARCHAR(500),
		DoctorLead NVARCHAR(500),
		DoctorSamplePickedUp NVARCHAR(500),
		DoctorSamplePickedUp_TopicOfDiscussion NVARCHAR(500),
		DoctorSampleActual NVARCHAR(500),
		DoctorSampleActual_TopicOfDiscussion NVARCHAR(500),
		Employee NVARCHAR(500),
		OrderAmount DECIMAL(18,2),
		InvAmount DECIMAL(18,2),
		DoctorLabAmountRec NVARCHAR(500),
		CollectionAmt DECIMAL(18,2),
		)
		CREATE NONCLUSTERED INDEX IX14 ON FTSDAILYACCOUNTABILITYTRACKER_REPORT (SEQ)
	END
	DELETE FROM FTSDAILYACCOUNTABILITYTRACKER_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	SET @Strsql=' INSERT INTO FTSDAILYACCOUNTABILITYTRACKER_REPORT (USERID,SEQ,DATE,Doctors_Visited,TopicOfDiscussion,Doctors_Phone,Doctors_PhoneTopicOfDiscussion,DoctorsWhatsApp, '
	SET @Strsql+=' DoctorsWhatsApp_TopicOfDiscussion,DoctorsOthers,DoctorsOthers_TopicOfDiscussion,DoctorSamplePickedUp,DoctorSamplePickedUp_TopicOfDiscussion, '
	SET @Strsql+=' DoctorSampleActual,DoctorSampleActual_TopicOfDiscussion,Employee,OrderAmount,InvAmount,DoctorLabAmountRec,CollectionAmt)'
	SET @Strsql+=' SELECT '+STR(@USERID)+' AS USERID ,ROW_NUMBER() OVER(ORDER BY DATE) AS SEQ,* FROM ( '
	SET @Strsql+=' select visited_date AS DATE,Shop_Name AS Doctors_Visited ,activty.REMARKS AS TopicOfDiscussion,'''' AS Doctors_Phone,'''' AS Doctors_PhoneTopicOfDiscussion, '
	SET @Strsql+=' '''' AS DoctorsWhatsApp ,'''' AS DoctorsWhatsApp_TopicOfDiscussion,'''' AS DoctorsOthers ,'''' AS DoctorsOthers_TopicOfDiscussion '
	SET @Strsql+=' ,'''' AS DoctorSamplePickedUp,'''' AS DoctorSamplePickedUp_TopicOfDiscussion,'''' AS DoctorSampleActual,'''' AS DoctorSampleActual_TopicOfDiscussion '

	SET @Strsql+=' ,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+ '' ''+ISNULL(CNT.cnt_lastName,'''') AS Employee,0 as Ordervalue,0 as invoice_amount,'''' as Collection_ShopName,0  Collection_Amount '

	SET @Strsql+=' from tbl_trans_shopActivitysubmit activty '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHP ON activty.Shop_Id=SHP.Shop_Code '
	SET @Strsql+=' INNER JOIN tbl_Master_user usr ON activty.User_Id=usr.User_Id '

	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=usr.user_contactId '

	SET @Strsql+=' WHERE SHP.type in (1,4,999) '
	SET @Strsql+=' and visited_date between '''+@FROMDATE+'''  AND '''+@TODATE+'''  '
	IF @EMPID1<>''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=usr.user_contactId) '
	END

	SET @Strsql+=' union all '

	SET @Strsql+=' select Activity_Date,'''','''',Shop_Name AS Doctors_Phone,activty.ActivitySubject,'''','''','''','''','''','''','''','''' '
	
	SET @Strsql+=' ,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+ '' ''+ISNULL(CNT.cnt_lastName,'''') AS Employee,0,0,'''',0 '

	SET @Strsql+=' from FTS_SalesActivity activty '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHP ON activty.Party_Code=SHP.Shop_Code '
	SET @Strsql+=' INNER JOIN tbl_Master_user usr ON activty.Created_by=usr.User_Id '

	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=usr.user_contactId '

	SET @Strsql+=' where Activityid in (1) '-- and SHP.type=8
	SET @Strsql+=' and Activity_Date between '''+@FROMDATE+'''  AND '''+@TODATE+'''  '
	IF @EMPID1<>''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=usr.user_contactId) '
	END

	SET @Strsql+=' union all '

	SET @Strsql+=' select Activity_Date,'''','''','''','''',Shop_Name,activty.ActivitySubject,'''','''','''','''','''','''' '
	
	SET @Strsql+=' ,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+ '' ''+ISNULL(CNT.cnt_lastName,'''') AS Employee,0,0,'''',0 '

	SET @Strsql+=' from FTS_SalesActivity activty '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHP ON activty.Party_Code=SHP.Shop_Code '
	SET @Strsql+=' INNER JOIN tbl_Master_user usr ON activty.Created_by=usr.User_Id '

	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=usr.user_contactId '

	SET @Strsql+=' where Typeid in (8) '--and SHP.type=8
	SET @Strsql+=' and Activity_Date between '''+@FROMDATE+'''  AND '''+@TODATE+'''  '
	IF @EMPID1<>''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=usr.user_contactId) '
	END

	SET @Strsql+=' union all '

	SET @Strsql+=' select Activity_Date,'''','''','''','''','''','''',Shop_Name,activty.ActivitySubject,'''','''','''','''' '
	
	SET @Strsql+=' ,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+ '' ''+ISNULL(CNT.cnt_lastName,'''') AS Employee,0,0,'''',0 '
	
	SET @Strsql+=' from FTS_SalesActivity activty '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHP ON activty.Party_Code=SHP.Shop_Code '
	SET @Strsql+=' INNER JOIN tbl_Master_user usr ON activty.Created_by=usr.User_Id '

	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=usr.user_contactId '

	SET @Strsql+=' where Typeid not in (1,2,3,8) ' --and SHP.type=8
	SET @Strsql+=' and Activity_Date between '''+@FROMDATE+'''  AND '''+@TODATE+'''  '
	IF @EMPID1<>''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=usr.user_contactId) '
	END

	SET @Strsql+=' union all '

	SET @Strsql+=' select CAST(Orderdate AS DATE),'''','''','''','''','''','''','''','''',Shop_Name,ordr.Remarks,'''','''' '
	
	SET @Strsql+=' ,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+ '' ''+ISNULL(CNT.cnt_lastName,'''') AS Employee,ordr.Ordervalue,0,'''',0 '

	SET @Strsql+=' from tbl_trans_fts_Orderupdate ordr '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHP ON ordr.Shop_Code=SHP.Shop_Code '
	SET @Strsql+=' INNER JOIN tbl_Master_user usr ON ordr.userID=usr.User_Id '

	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=usr.user_contactId '

	SET @Strsql+=' WHERE SHP.type in (1,4) '
	SET @Strsql+=' and CAST(Orderdate AS DATE) between '''+@FROMDATE+'''  AND '''+@TODATE+'''  '
	IF @EMPID1<>''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=usr.user_contactId) '
	END

	SET @Strsql+=' union all '

	SET @Strsql+=' select CAST(invoice_date AS DATE),'''','''','''','''','''','''','''','''','''','''',Shop_Name,bill.Remarks '
	
	SET @Strsql+=' ,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+ '' ''+ISNULL(CNT.cnt_lastName,'''') AS Employee,0,bill.invoice_amount,'''',0 '
	
	SET @Strsql+=' from tbl_FTS_BillingDetails bill '
	SET @Strsql+=' INNER JOIN tbl_trans_fts_Orderupdate ordr ON bill.OrderCode=ordr.OrderCode '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHP ON ordr.Shop_Code=SHP.Shop_Code '
	SET @Strsql+=' INNER JOIN tbl_Master_user usr ON bill.User_Id=usr.User_Id '

	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=usr.user_contactId '

	SET @Strsql+=' WHERE CAST(invoice_date AS DATE) between '''+@FROMDATE+'''  AND '''+@TODATE+'''  '
	IF @EMPID1<>''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=usr.user_contactId) '
	END

	--SET @Strsql+=' AND SHP.type in (1,4,999) ) T '	
	SET @Strsql+=' AND SHP.type in (1,4,999) '


	SET @Strsql+=' union all '
	SET @Strsql+=' select CAST(collection_date AS DATE),'''','''','''','''','''','''','''','''','''','''','''','''' '	
	SET @Strsql+=' ,ISNULL(CNT.cnt_firstName,'''')+'' ''+ISNULL(CNT.cnt_middleName,'''')+ '' ''+ISNULL(CNT.cnt_lastName,'''') AS Employee,0,0 '	
	SET @Strsql+=' ,SHP.Shop_name,coll.collection'
	SET @Strsql+=' from tbl_FTS_collection coll '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHP ON coll.shop_id=SHP.Shop_Code '
	SET @Strsql+=' INNER JOIN tbl_Master_user usr ON coll.User_Id=usr.User_Id '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=usr.user_contactId '
	SET @Strsql+=' WHERE CAST(collection_date AS DATE) between '''+@FROMDATE+'''  AND '''+@TODATE+'''  '
	IF @EMPID1<>''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=usr.user_contactId) '
	END
	SET @Strsql+=' AND SHP.type in (1,4,999) ) T '	
	--SELECT  @Strsql
  EXEC SP_EXECUTESQL @Strsql
   

  DROP TABLE #DESIGNATION_LIST
  DROP TABLE #EMPLOYEE_LIST
  DROP TABLE #STATEID_LIST
  DROP TABLE #TEMPCONTACT
  -- Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 3.0

  exec PRC_FTSDailyAccountabilityTrackerCount @FROMDATE,@TODATE,@STATEID,@DESIGNID,@EMPID,@USERID

	--SELECT * FROM tbl_shoptype

	--select * from FTS_Activity

	--select * from FTS_SalesActivity
END