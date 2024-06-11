--EXEC PRC_FTSTEAMVISITATTENDANCE_FETCH '2022-02-20','2022-02-28','','EMS0000812','',378
--EXEC PRC_FTSTEAMVISITATTENDANCE_FETCH '2023-07-01','2023-08-10','','','1,4',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTEAMVISITATTENDANCE_FETCH]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTEAMVISITATTENDANCE_FETCH] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTEAMVISITATTENDANCE_FETCH]
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
Written by : Debashis Talukder ON 04/03/2022
Module	   : Team Visit Attendance.Refer: 0024720
1.0		v2.0.29		Debashis	10/05/2022		FSM > MIS Reports > Team Visit Report
												There, two columns required after DS ID column :
												a) DS/TL Name [Contact table]
												b) DS/TL Type [FaceRegTypeID from tbl_master_user].Refer: 0024870
2.0		v2.0.33		Debashis	09/10/2022		Code optimized.Refer: 0025331
3.0		v2.0.33		Debashis	10/10/2022		'Section' and 'Circle' columns required [After the 'Channel' column].Refer: 0025219
4.0		v2.0.33		Debashis	10/10/2022		Team Visit: report the following field value:
												"Present/Absent", "Total Working Day", "Total Days Present" , "Total Days Absent" shall be considered 'Attendance time'
												instead 'Day Start'.Refer: 0025240
5.0		v2.0.35		Debashis	15/11/2022		Need to optimized Employee Attendance, Team Visit and Qualified Attendance reports in ITC Portal.Refer: 0025453
6.0		v2.0.41		Debashis	09/08/2023		A coloumn named as Gender needs to be added in all the ITC reports.Refer: 0026680
7.0		v2.0.47		Debashis	10/06/2024		A new coloumn "Total CDM Days" is required under the Summary section. It shall be placed at the end.Refer: 0027509
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	--Rev 5.0
	SET LOCK_TIMEOUT -1
	--End of Rev 5.0

	DECLARE @SqlStr NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
		DROP TABLE #BRANCH_LIST
	CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

	IF @BRANCHID<>''
		BEGIN
			SET @SqlStrTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @sqlStrTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)

	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId FROM tbl_master_employee WHERE emp_contactId IN('+@EMPID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF OBJECT_ID('tempdb..#CHANNEL_LIST') IS NOT NULL
		DROP TABLE #CHANNEL_LIST
	CREATE TABLE #CHANNEL_LIST (CH_ID BIGINT)

	IF @CHANNELID <> ''
		BEGIN
			SET @CHANNELID=REPLACE(@CHANNELID,'''','')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #CHANNEL_LIST SELECT CH_ID FROM Employee_Channel WHERE CH_ID IN('+@CHANNELID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@Userid)		
			CREATE TABLE #EMPHRS
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
			
			--Rev 2.0 && WITH (NOLOCK) has been added in all tables
			INSERT INTO #EMPHRS
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC WITH (NOLOCK)
			LEFT JOIN tbl_master_employee TME WITH (NOLOCK) ON TME.emp_id= CTC.emp_reportTO 
			WHERE emp_effectiveuntil IS NULL
		
			;with cte as(SELECT	EMPCODE,RPTTOEMPCODE FROM #EMPHRS WHERE EMPCODE IS NULL OR EMPCODE=@empcodes  
			UNION ALL
			SELECT a.EMPCODE,a.RPTTOEMPCODE FROM #EMPHRS a
			JOIN cte b ON a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			SELECT EMPCODE,RPTTOEMPCODE FROM cte 
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
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--Rev 6.0
			cnt_sex TINYINT NULL,
			GENDERDESC NVARCHAR(100) NULL
			--End of Rev 6.0
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			--Rev 2.0 && WITH (NOLOCK) has been added in all tables
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,
			--Rev 6.0
			cnt_sex,CASE WHEN cnt_sex=1 THEN 'Male' WHEN cnt_sex=0 THEN 'Female' END GENDERDESC
			--End of Rev 6.0
			FROM TBL_MASTER_CONTACT WITH (NOLOCK)
			INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			--Rev 2.0 && WITH (NOLOCK) has been added in all tables
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,
			--Rev 6.0
			cnt_sex,CASE WHEN cnt_sex=1 THEN 'Male' WHEN cnt_sex=0 THEN 'Female' END GENDERDESC
			--End of Rev 6.0
			FROM TBL_MASTER_CONTACT WITH (NOLOCK)
			WHERE cnt_contactType IN('EM')
		END

	--Rev 2.0
	--Rev 4.0
	--IF OBJECT_ID('tempdb..#TMPDAYSTARTENDTV') IS NOT NULL
	--	DROP TABLE #TMPDAYSTARTENDTV
	--CREATE TABLE #TMPDAYSTARTENDTV
	--(USERID BIGINT,DAYSTTIME NVARCHAR(10),DAYENDTIME NVARCHAR(10))
	--CREATE NONCLUSTERED INDEX IX1 ON #TMPDAYSTARTENDTV(USERID)

	--SET @SqlStr=''
	--SET @SqlStr='INSERT INTO #TMPDAYSTARTENDTV(USERID,DAYSTTIME,DAYENDTIME) '
	--SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108)) AS DAYSTTIME,NULL AS DAYENDTIME '
	--SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND '
	--SET @SqlStr+='WHERE ISSTART=1 '
	--SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) '
	--SET @SqlStr+='GROUP BY DAYSTEND.User_Id '
	--SET @SqlStr+='UNION ALL '
	--SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,NULL AS DAYSTTIME,MAX(CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108)) AS DAYENDTIME '
	--SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND '
	--SET @SqlStr+='WHERE ISEND=1 '
	--SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) '
	--SET @SqlStr+='GROUP BY DAYSTEND.User_Id '

	--Rev 5.0
	--IF OBJECT_ID('tempdb..#TMPATTENLOGINOUTTV') IS NOT NULL
	--	DROP TABLE #TMPATTENLOGINOUTTV
	--CREATE TABLE #TMPATTENLOGINOUTTV
	--(USERID BIGINT,LOGGEDIN NVARCHAR(10),LOGEDOUT NVARCHAR(10))
	--CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENLOGINOUTTV(USERID,LOGGEDIN)

	--SET @SqlStr=''
	--SET @SqlStr='INSERT INTO #TMPATTENLOGINOUTTV(USERID,LOGGEDIN,LOGEDOUT) '
	--SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT '
	--SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH (NOLOCK) '
	--SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL '
	--SET @SqlStr+='AND Logout_datetime IS NULL AND Isonleave=''false'' '
	--SET @SqlStr+='GROUP BY ATTEN.User_Id '
	--SET @SqlStr+='UNION ALL '
	--SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT '
	--SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH (NOLOCK) '
	--SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NULL '
	--SET @SqlStr+='AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
	--SET @SqlStr+='GROUP BY ATTEN.User_Id '
	----End of Rev 4.0
	IF OBJECT_ID('tempdb..#TMPATTENLOGINOUTTV') IS NOT NULL
		DROP TABLE #TMPATTENLOGINOUTTV
	--Rev 7.0 && A new column has been added as WORKACTIVITYDESCRIPTION NVARCHAR(500)
	CREATE TABLE #TMPATTENLOGINOUTTV
	(USERID BIGINT,LOGGEDIN NVARCHAR(10),LOGIN_DATE NVARCHAR(10),WORKACTIVITYDESCRIPTION NVARCHAR(500))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENLOGINOUTTV(USERID,LOGGEDIN,LOGIN_DATE)

	SET @SqlStr=''
	--Rev 7.0 && A new column has been added as WORKACTIVITYDESCRIPTION
	SET @SqlStr='INSERT INTO #TMPATTENLOGINOUTTV(USERID,LOGGEDIN,LOGIN_DATE,WORKACTIVITYDESCRIPTION) '
	SET @SqlStr+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,CAST(ATTEN.Work_datetime AS DATE) AS LOGIN_DATE,WRKACT.WRKACTVTYDESCRIPTION '
	SET @SqlStr+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_master_user USR WITH (NOLOCK) ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--Rev 7.0
	SET @SqlStr+='INNER JOIN tbl_attendance_worktype ATTENWRKTYP ON ATTENWRKTYP.UserID=ATTEN.User_Id AND ATTEN.Id=ATTENWRKTYP.attendanceid '
	SET @SqlStr+='INNER JOIN tbl_FTS_WorkActivityList WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID '
	--End of Rev 7.0
	SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL '
	SET @SqlStr+='AND Logout_datetime IS NULL AND Isonleave=''false'' '
	--Rev 7.0
	--SET @SqlStr+='GROUP BY ATTEN.User_Id,CAST(ATTEN.Work_datetime AS DATE) '
	SET @SqlStr+='AND WRKACT.WrkActvtyDescription IN(''CDM Day'',''Non CDM Day'') '
	SET @SqlStr+='GROUP BY ATTEN.User_Id,CAST(ATTEN.Work_datetime AS DATE),WRKACT.WrkActvtyDescription '
	--End of Rev 7.0
	--End of Rev 5.0

	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr
	--End of Rev 2.0

	--Rev 2.0 && WITH (NOLOCK) has been added in all tables
	--Rev 5.0 && Added a new column as LOGIN_DATE
	--Rev 6.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	--Rev 7.0 && A new column has been added as TOTALCDMDAYS
	SET @SqlStr=''
	SET @SqlStr+='SELECT ATTENINOUT.LOGIN_DATE,BR.BRANCH_ID,BR.BRANCH_DESCRIPTION,USR.USER_ID AS USERID,CNT.cnt_internalId AS EMPCODE,EMP.emp_uniqueCode AS EMPID,'
	SET @SqlStr+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	--Rev 1.0
	SET @SqlStr+='CNT.cnt_sex AS OUTLETEMPSEX,CNT.GENDERDESC,STG.Stage AS DSTLTYPE,'
	--End of Rev 1.0
	SET @SqlStr+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	--Rev 4.0
	--SET @SqlStr+='USR.user_loginId AS CONTACTNO,CH.CH_ID,CH.CHANNEL,CASE WHEN DAYSTARTEND.DAYSTTIME<>'''' OR DAYSTARTEND.DAYSTTIME IS NOT NULL THEN 1 ELSE 0 END AS PRESENTABSENT,RPTTO.REPORTTOID,'
	SET @SqlStr+='USR.user_loginId AS CONTACTNO,CH.CH_ID,CH.CHANNEL,CASE WHEN ATTENINOUT.LOGGEDIN<>'''' OR ATTENINOUT.LOGGEDIN IS NOT NULL THEN 1 ELSE 0 END AS PRESENTABSENT,RPTTO.REPORTTOID,'
	--End of Rev 4.0
	SET @SqlStr+='RPTTO.REPORTTOUID,RPTTO.REPORTTO,RPTTO.RPTTODESG,'
	--Rev 3.0
	SET @SqlStr+='ISNULL((SELECT LTRIM(STUFF(((SELECT DISTINCT '', '' + sec_Section FROM '
	SET @SqlStr+='(SELECT ES.sec_Section FROM Employee_Section ES WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN Employee_SectionMap ESM WITH (NOLOCK) ON ES.sec_id=ESM.EP_SEC_ID WHERE ESM.EP_EMP_CONTACTID=CNT.cnt_internalId '
	SET @SqlStr+=') AS SEC FOR XML PATH(''''))),1,2,'' ''))),'''') AS SECTION,'
	SET @SqlStr+='ISNULL((SELECT LTRIM(STUFF(((SELECT DISTINCT '', '' + crl_Circle FROM '
	SET @SqlStr+='(SELECT EC.crl_Circle FROM Employee_Circle EC WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN Employee_CircleMap ECM WITH (NOLOCK) ON EC.crl_id=ECM.EP_CRL_ID WHERE ECM.EP_EMP_CONTACTID=CNT.cnt_internalId '
	SET @SqlStr+=') AS CIR FOR XML PATH(''''))),1,2,'' ''))),'''') AS CIRCLE,'
	--End of Rev 3.0
	--Rev 7.0
	SET @SqlStr+='CASE WHEN ATTENINOUT.WORKACTIVITYDESCRIPTION=''CDM Day'' THEN 1 ELSE 0 END AS TOTALCDMDAYS '
	--End of Rev 7.0
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
	SET @SqlStr+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS REPORTTOID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @SqlStr+='DESG.deg_designation AS RPTTODESG,CNT.cnt_UCC AS REPORTTOUID FROM tbl_master_employee EMP WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH (NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH (NOLOCK) '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON DESG.emp_cntId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL '
	SET @SqlStr+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '	
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT EC.ch_id,EC.ch_Channel AS CHANNEL,ECM.EP_EMP_CONTACTID FROM Employee_Channel EC WITH (NOLOCK) '
	SET @SqlStr+='INNER JOIN Employee_ChannelMap ECM WITH (NOLOCK) ON EC.ch_id=ECM.EP_CH_ID '
	SET @SqlStr+=') CH ON CNT.cnt_internalId=CH.EP_EMP_CONTACTID '
	--Rev 1.0
	--Rev 5.0
	--SET @SqlStr+='LEFT OUTER JOIN FTS_Stage STG WITH (NOLOCK) ON USR.FaceRegTypeID=STG.StageID '
	----End of Rev 1.0
	--SET @SqlStr+='LEFT OUTER JOIN ('
	----Rev 4.0
	----SET @SqlStr+='SELECT USERID,MIN(DAYSTTIME) AS DAYSTTIME,MAX(DAYENDTIME) AS DAYENDTIME FROM('
	------Rev 2.0
	------SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108)) AS DAYSTTIME,NULL AS DAYENDTIME '
	------SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND WHERE ISSTART=1 '
	------SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) '
	------SET @SqlStr+='GROUP BY DAYSTEND.User_Id '
	------SET @SqlStr+='UNION ALL '
	------SET @SqlStr+='SELECT DAYSTEND.User_Id AS USERID,NULL AS DAYSTTIME,MAX(CONVERT(VARCHAR(5),CAST(DAYSTEND.STARTENDDATE AS TIME),108)) AS DAYENDTIME '
	------SET @SqlStr+='FROM FSMUSERWISEDAYSTARTEND DAYSTEND WHERE ISEND=1 '
	------SET @SqlStr+='AND CONVERT(NVARCHAR(10),DAYSTEND.STARTENDDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) '
	------SET @SqlStr+='GROUP BY DAYSTEND.User_Id '
	----SET @SqlStr+='SELECT USERID,DAYSTTIME,DAYENDTIME FROM #TMPDAYSTARTENDTV '
	------End of Rev 2.0
	----SET @SqlStr+=') DAYSTEND GROUP BY USERID) DAYSTARTEND ON DAYSTARTEND.USERID=USR.user_id '
	--SET @SqlStr+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,LOGIN_DATE FROM('
	--SET @SqlStr+='SELECT USERID,LOGGEDIN,LOGEDOUT,LOGIN_DATE FROM #TMPATTENLOGINOUTTV '
	--SET @SqlStr+=') INOUT GROUP BY USERID,LOGIN_DATE) ATTENINOUT ON USR.user_id=ATTENINOUT.USERID '
	SET @SqlStr+='INNER JOIN #TMPATTENLOGINOUTTV ATTENINOUT ON USR.user_id=ATTENINOUT.USERID '
	SET @SqlStr+='LEFT OUTER JOIN FTS_Stage STG WITH (NOLOCK) ON USR.FaceRegTypeID=STG.StageID '
	--End of Rev 5.0
	--End of Rev 4.0
	SET @SqlStr+='WHERE DESG.deg_designation IN(''DS'',''TL'') '
	IF @BRANCHID<>''
		SET @SqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.branch_id) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	IF @CHANNELID<>''
		SET @SqlStr+='AND EXISTS (SELECT ch_id FROM #CHANNEL_LIST AS CHN WHERE CHN.ch_id=CH.CH_ID) '
	--Rev 5.0
	SET @SqlStr+='ORDER BY ATTENINOUT.LOGIN_DATE '
	--End of Rev 5.0
	
	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	DROP TABLE #BRANCH_LIST
	DROP TABLE #TEMPCONTACT
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #CHANNEL_LIST

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	--Rev 2.0
	--Rev 4.0
	--DROP TABLE #TMPDAYSTARTENDTV
	DROP TABLE #TMPATTENLOGINOUTTV
	--End of Rev 4.0
	--End of Rev 2.0
	
	SET NOCOUNT OFF
END