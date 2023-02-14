--EXEC PRC_FTSMeetingDetails_List @FROMDATE='2020-05-22',@TODATE='2020-08-21',@USERID=378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSMeetingDetails_List]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSMeetingDetails_List] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_FTSMeetingDetails_List]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT,
@DesigId NVARCHAR(MAX)=NULL
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0			Tanmoy		20-08-2020			Create sp
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
		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_ucc NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		USER_ID BIGINT,
		-- Rev 2.0 [ existing issue solved]
		--Contact_no nvarchar(15)
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


	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_MeetingDetailsReport') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTS_MeetingDetailsReport
		(
		SEQ BIGINT,
		USERID BIGINT,
		USER_LOGINID NVARCHAR(100),
		EMPLOYEE NVARCHAR(300),
		EMPLOYEE_CODE NVARCHAR(100),
		EMPLOYEE_DESIGNATION NVARCHAR(200),
		REPORTTO NVARCHAR(300),
		REPORTTO_CODE NVARCHAR(100),
		REPORTTO_DESIGNATION NVARCHAR(300),
		SHOP_NAME NVARCHAR(300),
		MEETING_NAME NVARCHAR(300),
		LATITUDE NVARCHAR(MAX),
		LONGITUDE NVARCHAR(MAX),
		MEETING_ADDRESS NVARCHAR(MAX),
		MEETING_PINCODE NVARCHAR(15),
		REMARKS NVARCHAR(MAX),
		VISITED_TIME DATETIME,
		SPENT_DURATION NVARCHAR(15),
		TOTAL_VISIT_COUNT NVARCHAR(10),
		DISTANCE_TRAVELLED NVARCHAR(100),
		CREATEDDATE DATETIME
		)
	END

	delete from FTS_MeetingDetailsReport where USERID=@USERID

	SET @Strsql=' '

	SET @Strsql+=' INSERT INTO FTS_MeetingDetailsReport   '
	SET @Strsql+=' select ROW_NUMBER() OVER(ORDER BY ACTVT.visited_time DESC) AS SEQ,'''+STR(@USERID)+''',user_loginId, '
	SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''') +'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS Employee, '
	SET @Strsql+=' CNT.cnt_ucc AS EMPLOYEE_CODE,DESG.deg_designation,RPTTO.REPORTTO,REPORTTO_ID,RPTTODESG, '
	SET @Strsql+=' SHOP.Shop_Name, MEETING_NAME, '
	SET @Strsql+=' ACTVT.LATITUDE,ACTVT.LONGITUDE,ACTVT.MEETING_ADDRESS,ACTVT.MEETING_PINCODE,ACTVT.REMARKS,ACTVT.visited_time,ACTVT.spent_duration,ACTVT.total_visit_count, '
	SET @Strsql+=' ACTVT.distance_travelled,ACTVT.Createddate from tbl_trans_shopactivitysubmit ACTVT '
	SET @Strsql+=' INNER JOIN tbl_master_shop SHOP ON SHOP.Shop_Code=ACTVT.Shop_Id '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=ACTVT.User_Id '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+=' LEFT OUTER JOIN FTS_MEETING_TYPE TYP ON TYP.MEETING_ID=ACTVT.MEETING_TYPEID '

	SET @Strsql+=' LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo, '
	SET @Strsql+=' CNT.cnt_internalId,  '
	SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''')+'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS REPORTTO,  '
	SET @Strsql+=' DESG.deg_designation AS RPTTODESG,CNT.cnt_ucc AS REPORTTO_ID FROM tbl_master_employee EMP '
	SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo  '
	SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId  '
	SET @Strsql+=' LEFT OUTER JOIN (    '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt  	'
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL  '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId   '
	SET @Strsql+=' WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
  	
	SET @Strsql+=' LEFT OUTER JOIN (   '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL	 '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=CNT.cnt_internalId  '	
	SET @Strsql+=' WHERE ISMEETING=1 AND CONVERT(NVARCHAR(10),ACTVT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '	
	IF @STATEID<>''
		SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SAT.id) '
	IF @EMPID<>''
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	IF @DesigId<>''
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '

	SET @Strsql+=' ORDER BY ACTVT.visited_time   '

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

END