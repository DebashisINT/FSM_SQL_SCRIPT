IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSDOCTORACTIVITY_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSDOCTORACTIVITY_REPORT] AS' 
END
GO

--EXEC PRC_FTSDOCTORACTIVITY_REPORT @USERID=735,@FROMDATE='01-01-2020',@TODATE='13-01-2020'

ALTER PROCEDURE [dbo].[PRC_FTSDOCTORACTIVITY_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.6		TANMOY	13-01-2020		REPORT FOR DOCTOR ACTIVITY 
2.0		v2.0.38		Sanchita	12-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX),@SQL NVARCHAR(MAX)

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

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
			DROP TABLE #TEMPCONTACT
		CREATE TABLE #TEMPCONTACT
			(
				cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
				USER_ID BIGINT
			)
		CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
		-- Rev 2.0
		--INSERT INTO #TEMPCONTACT
		--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,USR.user_id FROM TBL_MASTER_CONTACT CNT
		--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE cnt_contactType IN('EM')

		SET @Strsql=''
		SET @Strsql+=' INSERT INTO #TEMPCONTACT '
		SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,USR.user_id FROM TBL_MASTER_CONTACT CNT '
		SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
		END
		SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
		exec sp_executesql @Strsql
		-- End of Rev 2.0


	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSDOCTORACTIVITY_REPORT') AND TYPE IN (N'U'))
			BEGIN
				CREATE TABLE FTSDOCTORACTIVITY_REPORT
				(
				  USERID INT,
				  SEQ INT,
				  ACTIVITY_DATE NVARCHAR(10),
				  EMPCODE NVARCHAR(100) NULL,
				  EMPLOYEE_NAME NVARCHAR(300) NULL,
				  STATE_NAME NVARCHAR(100) NULL,
				  STATE_ID INT NULL,
				  DESIGNATION NVARCHAR(50) NULL,
				  REPORT_TO NVARCHAR(100) NULL,
				  DOCTOR_NAME NVARCHAR(300) NULL,
				  SHOP_TYPE NVARCHAR(50),
				  SHOP_CODE NVARCHAR(100),
				  DOC_ACTIVITYID NVARCHAR(100) NULL,
				  DOC_REMARKS NVARCHAR(500) NULL,
				  PRESCRIBER NVARCHAR(10) NULL,
				  QTY_VALUE NVARCHAR(10) NULL,
				  QTY_VOL_REMARKS NVARCHAR(500) NULL,
				  SAMPLE_VALUE NVARCHAR(10) NULL,
				  CRM_VALUE NVARCHAR(10) NULL,
				  MONEY_VALUE NVARCHAR(10) NULL,
				  AMOUNT DECIMAL(20,2) NULL,
				  KIND_REMARKS NVARCHAR(500) NULL,
				  CONTRACT_FROM NVARCHAR(10) NULL,
				  CONTRACT_TO NVARCHAR(10),
				  CRM_VOLUMN DECIMAL(20,2) NULL,
				  GIFT_VALUE NVARCHAR(10) NULL,
				  WHICH_KINDREMARKS NVARCHAR(500) NULL,
				  NEXT_VISIT_DATE NVARCHAR(10),
				  MR_REMARKS NVARCHAR(500),
				  PRODUCT NVARCHAR(MAX),
				  QTY_PRODUCT NVARCHAR(MAX),
				  SAMPLE_PRODUCT NVARCHAR(MAX)
				)
				CREATE NONCLUSTERED INDEX IX1 ON FTSDOCTORACTIVITY_REPORT (SEQ)
			END
		DELETE FROM FTSDOCTORACTIVITY_REPORT WHERE USERID=@USERID

	SET @SQL=''
	SET @SQL+=' INSERT INTO FTSDOCTORACTIVITY_REPORT  '
	SET @SQL+=' select '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY CREATE_ON) AS SEQ,CONVERT(NVARCHAR(10),HEAD.CREATE_ON,105) AS ACTIVITY_DATE,EMPTEMP.cnt_internalId AS EMPCODE,  '
	SET @SQL+=' ISNULL(EMPTEMP.cnt_firstName,'''')+'' ''+ISNULL(EMPTEMP.cnt_middleName,'''')+'' ''+ISNULL(EMPTEMP.cnt_lastName,'''') AS EMPLOYEE_NAME,   '
	SET @SQL+=' ST.state,ST.id as state_id,N.deg_designation,RPTTO.REPORTTO,SHOP.Shop_Name,TYP.Name SHOP_TYPE,  '
	SET @SQL+=' HEAD.SHOP_CODE,HEAD.DOC_ACTIVITYID,HEAD.DOC_REMARKS,   '
	SET @SQL+=' CASE WHEN HEAD.PRESCRIBER_VALUE=0 THEN ''NO'' WHEN HEAD.PRESCRIBER_VALUE=1 THEN ''YES'' ELSE '''' END PRESCRIBER,  '
	SET @SQL+=' CASE WHEN HEAD.QTY_VALUE=0 THEN ''Volume'' WHEN HEAD.QTY_VALUE=1 THEN ''Quantity'' ELSE '''' END QTY_VALUE,    '
	SET @SQL+=' HEAD.QTY_VOL_REMARKS,CASE WHEN HEAD.SAMPLE_VALUE=0 THEN ''NO'' WHEN HEAD.SAMPLE_VALUE=1 THEN ''YES'' ELSE '''' END SAMPLE_VALUE,   '
	SET @SQL+=' CASE WHEN HEAD.CRM_VALUE=0 THEN ''CME'' WHEN HEAD.CRM_VALUE=1 THEN ''CRM'' ELSE '''' END CRM_VALUE,   '
	SET @SQL+=' CASE WHEN HEAD.MONEY_VALUE=0 THEN ''Kind'' WHEN HEAD.MONEY_VALUE=1 THEN ''Money'' ELSE '''' END MONEY_VALUE,HEAD.AMOUNT,HEAD.KIND_REMARKS,   '
	SET @SQL+=' CONVERT(NVARCHAR(10),HEAD.FROM_DATE,105) AS CONTRACT_FROM,CONVERT(NVARCHAR(10),HEAD.TO_DATE,105) AS CONTRACT_TO,HEAD.CRM_VOLUME,   '
	SET @SQL+=' CASE WHEN HEAD.GIFT_VALUE=0 THEN ''NO'' WHEN HEAD.GIFT_VALUE=1 THEN ''YES'' ELSE '''' END GIFT_VALUE,HEAD.WHICH_KINDREMARKS,    '
	SET @SQL+=' CONVERT(NVARCHAR(10),HEAD.NEXT_VISIT_DATE,105) NEXT_VISIT,HEAD.MR_REMARKS,   '
	SET @SQL+='  stuff((    '
	SET @SQL+='         select '','' + u.PRODUCT_NAME   '
	SET @SQL+='         from FTS_DoctorActivityDetails u   '
	SET @SQL+='         where u.DOCACTIVITY_HEADID = HEAD.ID and u.PRODUCT_TYPE=''PRODUCT''    '
	SET @SQL+='         order by u.PRODUCT_NAME   '
	SET @SQL+='         for xml path('''')   '
	SET @SQL+='     ),1,1,'''') as PRODUCT,	 '
	SET @SQL+='     stuff((   '
	SET @SQL+='         select '','' + u.PRODUCT_NAME   '
	SET @SQL+='         from FTS_DoctorActivityDetails u  '
	SET @SQL+='         where u.DOCACTIVITY_HEADID = HEAD.ID and u.PRODUCT_TYPE=''QTY''   '
	SET @SQL+='         order by u.PRODUCT_NAME   '
	SET @SQL+='         for xml path('''')   '
	SET @SQL+='     ),1,1,'''') as QTY_PRODUCT,  '
	SET @SQL+=' 	  stuff((   '
	SET @SQL+='         select '','' + u.PRODUCT_NAME   '
	SET @SQL+='         from FTS_DoctorActivityDetails u    '
	SET @SQL+='         where u.DOCACTIVITY_HEADID = HEAD.ID and u.PRODUCT_TYPE=''SAMPLE''   '
	SET @SQL+='         order by u.PRODUCT_NAME   '
	SET @SQL+='         for xml path('''')  '
	SET @SQL+='     ),1,1,'''') as SAMPLE_PRODUCT   '
 
	SET @SQL+=' from FTS_DoctorActivity HEAD   '
	SET @SQL+=' INNER JOIN #TEMPCONTACT EMPTEMP ON EMPTEMP.USER_ID=HEAD.CREATE_BY   '
	SET @SQL+=' INNER JOIN ( select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from    '
	SET @SQL+=' tbl_trans_employeeCTC as cnt    '
	SET @SQL+=' left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation    '
	SET @SQL+=' group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null )N   ' 
	SET @SQL+=' on  N.emp_cntId=EMPTEMP.cnt_internalId    '
	SET @SQL+=' LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=EMPTEMP.cnt_internalid AND ADDR.add_addressType=''Office''   '
	SET @SQL+=' LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state    '
	SET @SQL+=' LEFT OUTER JOIN (    '
	SET @SQL+=' SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO   '
	SET @SQL+=' FROM tbl_master_employee EMP    '
	SET @SQL+=' INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo    '
	SET @SQL+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId    '
	SET @SQL+=' WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=EMPTEMP.cnt_internalId    '
	SET @SQL+=' LEFT OUTER JOIN tbl_Master_shop SHOP ON SHOP.Shop_Code=HEAD.SHOP_CODE   '
	SET @SQL+=' LEFT OUTER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type  '
	--SET @SQL+='WHERE  CONVERT(NVARCHAR(10),HEAD.CREATE_ON,105) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',105) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',105)   ' 
	SET @SQL+='WHERE  CAST(HEAD.CREATE_ON AS DATE) BETWEEN CAST('''+@FROMDATE+''' AS DATE) AND CAST('''+@TODATE+''' AS DATE)   ' 
	IF @STATEID<>''
		SET @SQL+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STS WHERE STS.State_Id=ST.id) '
	IF @EMPID<>''
		SET @SQL+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=EMPTEMP.cnt_internalId) '




	EXEC SP_EXECUTESQL @SQL

	--SELECT @SQL
	--SELECT * FROM #EMPLOYEE_LIST

	DROP TABLE #STATEID_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT
	-- Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 2.0

END