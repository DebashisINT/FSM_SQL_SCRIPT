--EXEC PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_FETCH '2022-02-20','2022-02-28','','EMS0000812','',378
--EXEC PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_FETCH '2022-11-01','2022-11-16','','','',54685
--EXEC PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_FETCH '2022-11-01','2022-11-16','','','',54689

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_FETCH]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_FETCH] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_FETCH]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@BRANCHID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@CHANNELID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 16/11/2022
Module	   : Team Visit Attendance Hierarchy & Channel Wise.Refer: 0025220
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	SET LOCK_TIMEOUT -1

	DECLARE @SqlStr NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX),@LOGINCNTID NVARCHAR(100)

	IF OBJECT_ID('tempdb..#BRANCHHC_LIST') IS NOT NULL
		DROP TABLE #BRANCHHC_LIST
	CREATE TABLE #BRANCHHC_LIST (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCHHC_LIST (Branch_Id ASC)

	IF @BRANCHID<>''
		BEGIN
			SET @SqlStrTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @sqlStrTable='INSERT INTO #BRANCHHC_LIST SELECT branch_id FROM tbl_master_branch WITH(NOLOCK) WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF OBJECT_ID('tempdb..#EMPLOYEEHC_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEEHC_LIST
	CREATE TABLE #EMPLOYEEHC_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)

	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #EMPLOYEEHC_LIST SELECT emp_contactId FROM tbl_master_employee WITH(NOLOCK) WHERE emp_contactId IN('+@EMPID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF OBJECT_ID('tempdb..#CHANNELHC_LIST') IS NOT NULL
		DROP TABLE #CHANNELHC_LIST
	CREATE TABLE #CHANNELHC_LIST (CH_ID BIGINT)

	IF @CHANNELID <> ''
		BEGIN
			SET @CHANNELID=REPLACE(@CHANNELID,'''','')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #CHANNELHC_LIST SELECT CH_ID FROM Employee_Channel WITH(NOLOCK) WHERE CH_ID IN('+@CHANNELID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF OBJECT_ID('tempdb..#LOGINUSERCHANNELLIST') IS NOT NULL
		DROP TABLE #LOGINUSERCHANNELLIST
	CREATE TABLE #LOGINUSERCHANNELLIST (CH_ID BIGINT)
	SELECT @LOGINCNTID=user_contactId FROM tbl_master_user WHERE user_id=@USERID
	INSERT INTO #LOGINUSERCHANNELLIST SELECT EP_CH_ID FROM Employee_ChannelMap WITH(NOLOCK) WHERE EP_EMP_CONTACTID=@LOGINCNTID

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes NVARCHAR(50)=(SELECT user_contactId FROM Tbl_master_user WITH(NOLOCK) WHERE user_id=@Userid)
			CREATE TABLE #EMPHRS
			(
			EMPCODE NVARCHAR(50),
			RPTTOEMPCODE NVARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE NVARCHAR(50),
			RPTTOEMPCODE NVARCHAR(50)
			)
			
			INSERT INTO #EMPHRS
			SELECT DISTINCT EMPCODE,RPTTOEMPCODE FROM(
			SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') AS RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_employee TME WITH(NOLOCK) ON TME.emp_id=CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
			UNION ALL
			SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') AS RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_employee TME WITH(NOLOCK) ON TME.emp_id= CTC.emp_deputy WHERE emp_effectiveuntil IS NULL
			) EMPHRS
		
			;with cte as(SELECT	EMPCODE,RPTTOEMPCODE FROM #EMPHRS WHERE EMPCODE IS NULL OR EMPCODE=@empcodes  
			UNION ALL
			SELECT a.EMPCODE,a.RPTTOEMPCODE FROM #EMPHRS a
			JOIN cte b ON a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			SELECT EMPCODE,RPTTOEMPCODE FROM cte 
		END

	--DS & TL
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
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			deg_designation NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			INSERT INTO #TEMPCONTACT(cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,deg_designation)
			SELECT DISTINCT CNT.cnt_internalId,CNT.cnt_branchid,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_contactType,CNT.cnt_UCC,DESG.deg_designation 
			FROM TBL_MASTER_CONTACT CNT WITH(NOLOCK)
			INNER JOIN #EMPHR_EDIT EMPEDIT ON CNT.cnt_internalId=EMPEDIT.EMPCODE 
			INNER JOIN tbl_master_employee EMP WITH(NOLOCK) ON CNT.cnt_internalId=EMP.emp_contactId
			INNER JOIN (
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation 
			WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation IN('DS','TL') 
			GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
			) DESG ON EMP.emp_contactId=DESG.emp_cntId
			WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT(cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,deg_designation)
			SELECT DISTINCT CNT.cnt_internalId,CNT.cnt_branchid,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_contactType,CNT.cnt_UCC,DESG.deg_designation 
			FROM TBL_MASTER_CONTACT CNT WITH(NOLOCK)
			INNER JOIN tbl_master_employee EMP WITH(NOLOCK) ON CNT.cnt_internalId=EMP.emp_contactId
			INNER JOIN (
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation 
			WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation IN('DS','TL') 
			GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
			) DESG ON EMP.emp_contactId=DESG.emp_cntId
			WHERE cnt_contactType IN('EM')
		END

	--AE
	IF OBJECT_ID('tempdb..#TEMPCONTACTAE') IS NOT NULL
		DROP TABLE #TEMPCONTACTAE
	CREATE TABLE #TEMPCONTACTAE
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			deg_designation NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACTAE(cnt_internalId,cnt_contactType ASC)
	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			INSERT INTO #TEMPCONTACTAE(cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,deg_designation)
			SELECT DISTINCT CNT.cnt_internalId,CNT.cnt_branchid,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_contactType,CNT.cnt_UCC,DESG.deg_designation 
			FROM TBL_MASTER_CONTACT CNT WITH(NOLOCK)
			INNER JOIN #EMPHR_EDIT EMPEDIT ON CNT.cnt_internalId=EMPEDIT.EMPCODE 
			INNER JOIN tbl_master_employee EMP WITH(NOLOCK) ON CNT.cnt_internalId=EMP.emp_contactId
			INNER JOIN (
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation 
			WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation='AE'
			GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
			) DESG ON DESG.emp_cntId=EMP.emp_contactId
			WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			INSERT INTO #TEMPCONTACTAE(cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,deg_designation)
			SELECT DISTINCT CNT.cnt_internalId,CNT.cnt_branchid,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_contactType,CNT.cnt_UCC,DESG.deg_designation 
			FROM TBL_MASTER_CONTACT CNT WITH(NOLOCK)
			INNER JOIN tbl_master_employee EMP ON CNT.cnt_internalId=EMP.emp_contactId
			INNER JOIN (
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation 
			WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation='AE'
			GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
			) DESG ON DESG.emp_cntId=EMP.emp_contactId
			WHERE cnt_contactType IN('EM')
		END

	--WD
	IF OBJECT_ID('tempdb..#TEMPCONTACTWD') IS NOT NULL
		DROP TABLE #TEMPCONTACTWD
	CREATE TABLE #TEMPCONTACTWD
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			deg_designation NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACTWD(cnt_internalId,cnt_contactType ASC)
	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			INSERT INTO #TEMPCONTACTWD(cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,deg_designation)
			SELECT DISTINCT CNT.cnt_internalId,CNT.cnt_branchid,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_contactType,CNT.cnt_UCC,DESG.deg_designation 
			FROM TBL_MASTER_CONTACT CNT WITH(NOLOCK)
			INNER JOIN #EMPHR_EDIT EMPEDIT ON CNT.cnt_internalId=EMPEDIT.EMPCODE 
			INNER JOIN tbl_master_employee EMP WITH(NOLOCK) ON CNT.cnt_internalId=EMP.emp_contactId
			INNER JOIN (
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation 
			WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation='WD'
			GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
			) DESG ON DESG.emp_cntId=EMP.emp_contactId
			WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			INSERT INTO #TEMPCONTACTWD(cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,deg_designation)
			SELECT DISTINCT CNT.cnt_internalId,CNT.cnt_branchid,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_contactType,CNT.cnt_UCC,DESG.deg_designation 
			FROM TBL_MASTER_CONTACT CNT WITH(NOLOCK)
			INNER JOIN tbl_master_employee EMP WITH(NOLOCK) ON CNT.cnt_internalId=EMP.emp_contactId
			INNER JOIN (
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation 
			WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation='WD'
			GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
			) DESG ON DESG.emp_cntId=EMP.emp_contactId
			WHERE cnt_contactType IN('EM')
		END
	
	IF OBJECT_ID('tempdb..#TMPATTENLOGINOUTTVHC') IS NOT NULL
		DROP TABLE #TMPATTENLOGINOUTTVHC
	CREATE TABLE #TMPATTENLOGINOUTTVHC
	(USERID BIGINT,LOGGEDIN NVARCHAR(10),LOGIN_DATE NVARCHAR(10))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENLOGINOUTTVHC(USERID,LOGGEDIN,LOGIN_DATE)

	SET @SqlStr=''
	SET @SqlStr='INSERT INTO #TMPATTENLOGINOUTTVHC(USERID,LOGGEDIN,LOGIN_DATE) '
	SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,CAST(ATTEN.Work_datetime AS DATE) AS LOGIN_DATE '
	SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL '
	SET @SqlStr+='AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @SqlStr+='GROUP BY ATTEN.User_Id,CAST(ATTEN.Work_datetime AS DATE) '

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	SET @SqlStr=''
	SET @SqlStr+='SELECT ATTENINOUT.LOGIN_DATE,BR.BRANCH_ID,BR.BRANCH_DESCRIPTION,USR.USER_ID AS USERID,CNT.cnt_internalId AS EMPCODE,EMP.emp_uniqueCode AS EMPID,'
	SET @SqlStr+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @SqlStr+='STG.Stage AS DSTLTYPE,'
	SET @SqlStr+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	SET @SqlStr+='USR.user_loginId AS CONTACTNO,CH.CH_ID,CH.CHANNEL,CASE WHEN ATTENINOUT.LOGGEDIN<>'''' OR ATTENINOUT.LOGGEDIN IS NOT NULL THEN 1 ELSE 0 END AS PRESENTABSENT,RPTTOWD.REPORTTOIDWD,'
	SET @SqlStr+='RPTTOWD.REPORTTOUIDWD,RPTTOWD.REPORTTOWD,RPTTOWD.RPTTODESGWD,RPTTOAE.REPORTTOIDAE,RPTTOAE.REPORTTOUIDAE,RPTTOAE.REPORTTOAE,RPTTOAE.RPTTODESGAE,'
	SET @SqlStr+='ISNULL((SELECT LTRIM(STUFF(((SELECT DISTINCT '', '' + sec_Section FROM '
	SET @SqlStr+='(SELECT ES.sec_Section FROM Employee_Section ES WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN Employee_SectionMap ESM WITH (NOLOCK) ON ES.sec_id=ESM.EP_SEC_ID WHERE ESM.EP_EMP_CONTACTID=CNT.cnt_internalId '
	SET @SqlStr+=') AS SEC FOR XML PATH(''''))),1,2,'' ''))),'''') AS SECTION,'
	SET @SqlStr+='ISNULL((SELECT LTRIM(STUFF(((SELECT DISTINCT '', '' + crl_Circle FROM '
	SET @SqlStr+='(SELECT EC.crl_Circle FROM Employee_Circle EC WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN Employee_CircleMap ECM WITH (NOLOCK) ON EC.crl_id=ECM.EP_CRL_ID WHERE ECM.EP_EMP_CONTACTID=CNT.cnt_internalId '
	SET @SqlStr+=') AS CIR FOR XML PATH(''''))),1,2,'' ''))),'''') AS CIRCLE '
	SET @SqlStr+='FROM tbl_master_employee EMP WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN tbl_master_branch BR WITH (NOLOCK) ON CNT.cnt_branchid=BR.branch_id '
	SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN tbl_master_address ADDR WITH (NOLOCK) ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @SqlStr+='INNER JOIN tbl_master_state ST WITH (NOLOCK) ON ST.id=ADDR.add_state '
	SET @SqlStr+='INNER JOIN ( '
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH (NOLOCK) '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
	--WD
	SET @SqlStr+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId AS INTERNALIDWD,EMPCTC.emp_reportTo,CNT.cnt_internalId AS REPORTTOIDWD,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTOWD,'
	SET @SqlStr+='DESG.deg_designation AS RPTTODESGWD,CNT.cnt_UCC AS REPORTTOUIDWD '
	SET @SqlStr+='FROM tbl_master_employee EMP WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH (NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @SqlStr+='INNER JOIN #TEMPCONTACTWD CNT ON EMP.emp_contactId=CNT.cnt_internalId '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH (NOLOCK) '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON EMP.emp_contactId=DESG.emp_cntId '
	SET @SqlStr+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
	SET @SqlStr+='UNION ALL '
	SET @SqlStr+='SELECT EMPCTC.emp_cntId AS INTERNALIDWD,EMPCTC.emp_deputy AS emp_reportTo,CNT.cnt_internalId AS REPORTTOIDWD,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTOWD,'
	SET @SqlStr+='DESG.deg_designation AS RPTTODESGWD,CNT.cnt_UCC AS REPORTTOUIDWD '
	SET @SqlStr+='FROM tbl_master_employee EMP WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH (NOLOCK) ON EMP.emp_id=EMPCTC.emp_deputy '
	SET @SqlStr+='INNER JOIN #TEMPCONTACTWD CNT ON EMP.emp_contactId=CNT.cnt_internalId '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH (NOLOCK) '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON EMP.emp_contactId=DESG.emp_cntId '
	SET @SqlStr+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
	SET @SqlStr+=') RPTTOWD ON CNT.cnt_internalId=RPTTOWD.INTERNALIDWD '
	--AE
	SET @SqlStr+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId AS INTERNALIDAE,EMPCTC.emp_reportTo,CNT.cnt_internalId AS REPORTTOIDAE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTOAE,'
	SET @SqlStr+='DESG.deg_designation AS RPTTODESGAE,CNT.cnt_UCC AS REPORTTOUIDAE '
	SET @SqlStr+='FROM tbl_master_employee EMP WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH (NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @SqlStr+='INNER JOIN #TEMPCONTACTAE CNT ON EMP.emp_contactId=CNT.cnt_internalId '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH (NOLOCK) '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON EMP.emp_contactId=DESG.emp_cntId '
	SET @SqlStr+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
	SET @SqlStr+='UNION ALL '
	SET @SqlStr+='SELECT EMPCTC.emp_cntId AS INTERNALIDAE,EMPCTC.emp_deputy AS emp_reportTo,CNT.cnt_internalId AS REPORTTOIDAE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTOAE,'
	SET @SqlStr+='DESG.deg_designation AS RPTTODESGAE,CNT.cnt_UCC AS REPORTTOUIDAE '
	SET @SqlStr+='FROM tbl_master_employee EMP WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH (NOLOCK) ON EMP.emp_id=EMPCTC.emp_deputy '
	SET @SqlStr+='INNER JOIN #TEMPCONTACTAE CNT ON EMP.emp_contactId=CNT.cnt_internalId '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH (NOLOCK) '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON EMP.emp_contactId=DESG.emp_cntId '
	SET @SqlStr+='WHERE EMPCTC.emp_effectiveuntil IS NULL '	
	SET @SqlStr+=') RPTTOAE ON RPTTOWD.REPORTTOIDWD=RPTTOAE.INTERNALIDAE '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT EC.ch_id,EC.ch_Channel AS CHANNEL,ECM.EP_EMP_CONTACTID FROM Employee_Channel EC WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN Employee_ChannelMap ECM WITH (NOLOCK) ON EC.ch_id=ECM.EP_CH_ID '
	SET @SqlStr+=') CH ON CNT.cnt_internalId=CH.EP_EMP_CONTACTID '
	SET @SqlStr+='INNER JOIN #TMPATTENLOGINOUTTVHC ATTENINOUT ON USR.user_id=ATTENINOUT.USERID '
	SET @SqlStr+='LEFT OUTER JOIN FTS_Stage STG WITH (NOLOCK) ON USR.FaceRegTypeID=STG.StageID '
	SET @SqlStr+='WHERE DESG.deg_designation IN(''DS'',''TL'') '
	SET @SqlStr+='AND EXISTS (SELECT LC.CH_ID FROM #LOGINUSERCHANNELLIST LC WHERE CH.ch_id=LC.CH_ID) '
	IF @BRANCHID<>''
		SET @SqlStr+='AND EXISTS (SELECT Branch_Id FROM #BRANCHHC_LIST AS F WHERE F.Branch_Id=BR.branch_id) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEEHC_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	IF @CHANNELID<>''
		SET @SqlStr+='AND EXISTS (SELECT ch_id FROM #CHANNELHC_LIST AS CHN WHERE CHN.ch_id=CH.CH_ID) '
	SET @SqlStr+='ORDER BY ATTENINOUT.LOGIN_DATE '
	
	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	DROP TABLE #BRANCHHC_LIST
	DROP TABLE #TEMPCONTACT
	DROP TABLE #TEMPCONTACTAE
	DROP TABLE #TEMPCONTACTWD
	DROP TABLE #EMPLOYEEHC_LIST
	DROP TABLE #CHANNELHC_LIST

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	DROP TABLE #TMPATTENLOGINOUTTVHC
	DROP TABLE #LOGINUSERCHANNELLIST
	
	SET NOCOUNT OFF
END