--EXEC PRC_FTSPJPvsActualSummary_List '2020-06-10','2020-06-11','','',1

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSPJPvsActualSummary_List]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSPJPvsActualSummary_List] AS'  
END 
GO

ALTER PROCEDURE [dbo].[PRC_FTSPJPvsActualSummary_List]
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
1.0			Tanmoy		17-06-2020					Create sp
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
			-- Rev 2.0 [ existing error solved]
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


	IF OBJECT_ID('test_TEMPCONTACT') IS NOT NULL
		DROP TABLE test_TEMPCONTACT
	


	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_PJPvsActualSummaryReport') AND TYPE IN (N'U'))
	BEGIN
	CREATE TABLE FTS_PJPvsActualSummaryReport
	(
	SEQ BIGINT,
	USERID BIGINT,
	Date NVARCHAR(10),
	Employee NVARCHAR(300),
	Designation NVARCHAR(200),
	Phone NVARCHAR(15),
	Supervisor NVARCHAR(300),
	State NVARCHAR(200),
	PJPCount INT,
	ActualVisit INT,
	OrderValue DECIMAL(20,2),
	Productivity DECIMAL(18,2)
	)
	END

	delete from FTS_PJPvsActualSummaryReport where USERID=@USERID


	SET @Strsql=' '
	SET @Strsql+=' INSERT INTO FTS_PJPvsActualSummaryReport   '
	SET @Strsql+=' SELECT ROW_NUMBER() OVER(ORDER BY ATTEN.Login_datetime DESC) AS SEQ,'''+STR(@USERID)+''',ATTEN.Login_datetime,  '
	SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''')+'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS EMPLOYEE,  '
	SET @Strsql+=' DESG.deg_designation,CNT.Contact_no,RPTTO.REPORTTO,SAT.state,ISNULL(PJP.PJPCount,0) AS PJPCount,ISNULL(SHOPACT.ActualVisit,0) AS ActualVisit,ISNULL(Ordervalue,0) AS Ordervalue,   '
	SET @Strsql+=' CAST((CAST(ISNULL(SHOPACT.ActualVisit,0) AS DECIMAL(18,2))/CASE WHEN ISNULL(PJP.PJPCount,0)<>0 THEN CAST(ISNULL(PJP.PJPCount,0) AS DECIMAL(18,2)) ELSE 1 END)*100 AS DECIMAL(18,2)) AS Productivity   '
	SET @Strsql+='  FROM tbl_master_employee emp   '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=emp.emp_contactId    '

	SET @Strsql+=' INNER JOIN (   '
	SET @Strsql+=' SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime   '
	SET @Strsql+=' FROM tbl_fts_UserAttendanceLoginlogout ATTEN    '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N''   '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId    '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)   '
	SET @Strsql+=' AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false''    '
	SET @Strsql+=' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105)   '
	SET @Strsql+=' ) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId  '

	SET @Strsql+=' LEFT OUTER JOIN (   '
	SET @Strsql+=' SELECT User_Id,cnt_internalId,CONVERT(NVARCHAR(10),PJP_Date,105) AS PJP_Date,SUM(PJPCount) AS PJPCount FROM(   '
	SET @Strsql+=' SELECT PJP.User_Id,CNT.cnt_internalId,COUNT(PJP.SHOP_CODE) AS PJPCount,CAST(PJP.PJP_Date AS DATE) AS PJP_Date   '
	SET @Strsql+=' FROM FTS_PJPPlanDetails PJP   '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=PJP.User_Id     '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId    '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),PJP.PJP_Date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)    '
	SET @Strsql+=' GROUP BY PJP.User_Id,CNT.cnt_internalId,CAST(PJP.PJP_Date AS DATE)    '
	SET @Strsql+=' ) AA GROUP BY User_Id,cnt_internalId,CAST(PJP_Date AS DATE)   '
	SET @Strsql+=' ) PJP ON PJP.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=PJP.PJP_Date   '

	SET @Strsql+=' LEFT OUTER JOIN (   '
	SET @Strsql+=' SELECT User_Id,cnt_internalId,CONVERT(NVARCHAR(10),VISITED_TIME,105) AS VISITED_TIME,SUM(ActualVisit) AS ActualVisit FROM(   '
	SET @Strsql+=' SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.Shop_Id) AS ActualVisit,CAST(SHOPACT.visited_time AS DATE) AS visited_time   '
	SET @Strsql+=' FROM tbl_trans_shopActivitysubmit SHOPACT    '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id    '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId    '
	SET @Strsql+=' WHERE Is_Newshopadd IN(0,1)   '
	SET @Strsql+=' AND CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)    '
	SET @Strsql+=' GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,CAST(SHOPACT.visited_time AS DATE)   '
	SET @Strsql+=' ) AA GROUP BY User_Id,cnt_internalId,CAST(VISITED_TIME AS DATE)    '
	SET @Strsql+=' ) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=SHOPACT.VISITED_TIME    '

	SET @Strsql+=' LEFT OUTER JOIN (SELECT ORDH.userID,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue,COUNT(ORDH.SHOP_CODE) AS ORDCNT,  '
	SET @Strsql+=' CONVERT(NVARCHAR(10),ORDH.Orderdate,105) AS ORDDATE    '
	SET @Strsql+=' FROM tbl_trans_fts_Orderupdate ORDH     '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID     '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId     '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)     '
	SET @Strsql+=' GROUP BY ORDH.userID,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ORDH.Orderdate,105)    '
	SET @Strsql+=' ) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=ORDHEAD.ORDDATE     '

	SET @Strsql+=' LEFT OUTER JOIN tbl_master_address ADRS ON ADRS.add_cntId=emp.emp_contactId AND ADRS.add_addressType=''OFFICE''    '
	SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_STATE SAT ON SAT.id=ADRS.add_state    '
	SET @Strsql+=' LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,   '
	SET @Strsql+=' CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,  '
	SET @Strsql+=' DESG.deg_designation AS RPTTODESG,CNT.cnt_ucc AS REPORTTO_ID FROM tbl_master_employee EMP   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo    '		
	SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId  '
	SET @Strsql+=' LEFT OUTER JOIN (    '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt  '		
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL  '	  
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId   '
	SET @Strsql+=' WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId   '
	SET @Strsql+=' LEFT OUTER JOIN (   '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL	 '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=CNT.cnt_internalId  '

	IF @STATEID<>'' AND @EMPID='' AND @DesigId=''
		SET @Strsql+=' WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SAT.id) '
	IF @EMPID<>'' AND @STATEID='' AND @DesigId=''
		SET @Strsql+=' WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	IF @DesigId<>'' AND @STATEID='' AND @EMPID=''
		SET @Strsql+=' WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '
	IF @DesigId<>'' AND @STATEID<>'' AND @EMPID=''
	BEGIN
		SET @Strsql+=' WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SAT.id) '
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '
	END
	IF @DesigId<>'' AND @STATEID='' AND @EMPID<>''
	BEGIN
		SET @Strsql+=' WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '
	END
	IF @DesigId='' AND @STATEID<>'' AND @EMPID<>''
	BEGIN
		SET @Strsql+=' WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SAT.id) '
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	END
	IF @DesigId<>'' AND @STATEID<>'' AND @EMPID<>''
	BEGIN
		SET @Strsql+=' WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SAT.id) '
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	END

	EXEC SP_EXECUTESQL @Strsql
	--WHERE CNT.Contact_no='8336901708' 
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