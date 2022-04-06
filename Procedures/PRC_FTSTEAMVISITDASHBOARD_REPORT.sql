--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','15','','','ALL','Summary',53028
--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','','','','EMP','Detail',53028
--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','','','','ALL','Summary',53028
--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','','','','AT_WORK','Detail',53028
--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','','','','AT_WORK','Summary',53028
--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','15','','EMP0000002','AT_WORKTRAVEL','Summary',53028
--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','','','','ON_LEAVE','Detail',53028
--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','15','','','NOT_LOGIN','Detail',53028
--EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT '2022-02-09','','','','GRAPH','Detail',53028

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTEAMVISITDASHBOARD_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTEAMVISITDASHBOARD_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTEAMVISITDASHBOARD_REPORT]
(
@TODAYDATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@ACTION NVARCHAR(20),
@RPTTYPE NVARCHAR(20),
--Rev 1.0
@BRANCHID NVARCHAR(MAX)=NULL,
--End of Rev 1.0
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 09/02/2022
Module	   : Team Visit Dashboard Summary & Detail.Refer: 0024666
1.0		v2.0.28		Debashis	23-03-2022		FSM - Portal: Branch selection required in 'Team Visit' against the selected 'State'.Refer: 0024742
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX),@EmpDefaultType NVARCHAR(50)=NULL

	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
		DROP TABLE #STATEID_LIST
	CREATE TABLE #STATEID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
	IF @STATEID <> ''
		BEGIN
			SET @STATEID=REPLACE(@STATEID,'''','')
			SET @SqlStrTable=''
			SET @SqlStrTable=' INSERT INTO #STATEID_LIST SELECT id from tbl_master_state where id in('+@STATEID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END
	
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DESIGNID <> ''
		BEGIN
			SET @DESIGNID=REPLACE(@DESIGNID,'''','')
			SET @SqlStrTable=''
			SET @SqlStrTable=' INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation where deg_id in('+@DESIGNID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	--Rev 1.0
	IF OBJECT_ID('tempdb..#BRANCHID_LIST') IS NOT NULL
		DROP TABLE #BRANCHID_LIST
	CREATE TABLE #BRANCHID_LIST (Branch_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #BRANCHID_LIST (Branch_Id ASC)
	IF @BRANCHID <> ''
		BEGIN
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #BRANCHID_LIST SELECT branch_id from tbl_master_branch where branch_id in('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	--End of Rev 1.0

	IF OBJECT_ID('tempdb..#TEMPNOTLOGIN') IS NOT NULL
		DROP TABLE #TEMPNOTLOGIN
	CREATE TABLE #TEMPNOTLOGIN
		(
			USERID INT,ACTION NVARCHAR(20),RPTTYPE NVARCHAR(20),EMPCODE NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPNOTLOGIN(EMPCODE)

	IF OBJECT_ID('tempdb..#TEMPSHOPUSER') IS NOT NULL
		DROP TABLE #TEMPSHOPUSER
	CREATE TABLE #TEMPSHOPUSER
	(
	User_Id BIGINT,distance_covered NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS,SDate DATETIME
	)
	CREATE NONCLUSTERED INDEX IX_shopuser ON #TEMPSHOPUSER(User_Id ASC)
	CREATE NONCLUSTERED INDEX IX1_shopuser ON #TEMPSHOPUSER(distance_covered ASC,SDate ASC)
	INSERT INTO #TEMPSHOPUSER 
	SELECT User_Id,distance_covered,SDate FROM tbl_trans_shopuser WHERE CONVERT(NVARCHAR(10),SDate,120)=CONVERT(NVARCHAR(10),@TODAYDATE,120) AND distance_covered IS NOT NULL

	SET @EmpDefaultType=(SELECT EMP.DefaultType FROM tbl_master_employee EMP WHERE EXISTS(SELECT USR.USER_ID FROM TBL_MASTER_USER USR WHERE EMP.emp_contactId=USR.user_contactId AND USR.USER_ID=@USERID))

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
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
	IF @EmpDefaultType<>'' OR @EmpDefaultType IS NOT NULL
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT CNT.cnt_internalId,CNT.cnt_firstName,CNT.cnt_middleName,CNT.cnt_lastName,CNT.cnt_contactType FROM TBL_MASTER_CONTACT CNT
			INNER JOIN tbl_master_employee EMP ON CNT.cnt_internalId=EMP.emp_contactId 
			WHERE CNT.cnt_contactType IN('EM') AND EMP.DefaultType=@EmpDefaultType
		END
	ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
		END

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSTEAMVISITDASHBOARD_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSTEAMVISITDASHBOARD_REPORT
			(
			  USERID INT,
			  ACTION NVARCHAR(20),
			  RPTTYPE NVARCHAR(20),
			  SEQ INT,
			  EMPCNT INT,
			  AT_WORK INT,
			  ON_LEAVE INT,
			  NOT_LOGIN INT,
			  EMPCODE NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  CONTACTNO NVARCHAR(50) NULL,
			  REPORTTO NVARCHAR(300) NULL,
			  LEAVEDATE NVARCHAR(100) NULL,
			  LOGGEDIN NVARCHAR(100) NULL,
			  LOGEDOUT NVARCHAR(100) NULL,
			  CURRENT_STATUS NVARCHAR(20),
			  TOTAL_HRS_WORKED NVARCHAR(50) NULL,
			  GPS_INACTIVE_DURATION NVARCHAR(50) NULL,
			  DISTANCE_COVERED NVARCHAR(50) NULL,
			  SHOPS_VISITED INT,
			  TOTAL_ORDER_BOOKED_VALUE DECIMAL(38,2),
			  TOTAL_COLLECTION DECIMAL(38,2),
			  DEPARTMENT NVARCHAR(100),
			  CHANNEL NVARCHAR(MAX),
			  CIRCLE NVARCHAR(MAX),
			  SECTION NVARCHAR(MAX)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSTEAMVISITDASHBOARD_REPORT (SEQ)
		END
	DELETE FROM FTSTEAMVISITDASHBOARD_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	IF @ACTION='ALL' AND @RPTTYPE='Summary'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,EMPCNT) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''EMP'' AS ACTION,''Summary'' AS RPTTYPE,COUNT(CNT.cnt_internalId) AS EMPCNT FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--Rev 1.0
			--IF @STATEID<>''
			--	SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			IF @STATEID<>'' AND @BRANCHID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id FROM #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			IF @STATEID='' AND @BRANCHID<>''
				SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			IF @STATEID<>'' AND @BRANCHID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id FROM #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
				END
			--End of Rev 1.0
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,AT_WORK) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''AT_WORK'' AS ACTION,''Summary'' AS RPTTYPE,CASE WHEN COUNT(ATTENLILO.AT_WORK) IS NULL THEN 0 ELSE COUNT(ATTENLILO.AT_WORK) END AS AT_WORK '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(Isonleave) ELSE 0 END AS AT_WORK '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,ON_LEAVE) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''ON_LEAVE'' AS ACTION,''Summary'' AS RPTTYPE,CASE WHEN COUNT(ATTEN.ON_LEAVE) IS NULL THEN 0 ELSE COUNT(ATTEN.ON_LEAVE) END AS ON_LEAVE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' ' 
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT ATTEN.User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(Isonleave) ELSE 0 END AS ON_LEAVE,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL AND ATTEN.Isonleave=''true'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave) ATTEN '
			SET @Strsql+='ON ATTEN.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,NOT_LOGIN) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''NOT_LOGIN'' AS ACTION,''Summary'' AS RPTTYPE,SUM(ISNULL(EMPCNT,0))-(SUM(ISNULL(AT_WORK,0))+SUM(ISNULL(ON_LEAVE,0))) AS NOT_LOGIN FROM('
			SET @Strsql+='SELECT COUNT(CNT.cnt_internalId) AS EMPCNT,0 AS AT_WORK,0 AS ON_LEAVE FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--Rev 1.0
			--IF @STATEID<>''
			--	SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			IF @STATEID<>'' AND @BRANCHID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id FROM #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			IF @STATEID='' AND @BRANCHID<>''
				SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			IF @STATEID<>'' AND @BRANCHID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id FROM #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
				END
			--End of Rev 1.0
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT 0 AS EMPCNT,CASE WHEN COUNT(ATTENLILO.AT_WORK) IS NULL THEN 0 ELSE COUNT(ATTENLILO.AT_WORK) END AS AT_WORK,0 AS ON_LEAVE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(Isonleave) ELSE 0 END AS AT_WORK '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT 0 AS EMPCNT,0 AS AT_WORK,CASE WHEN COUNT(ATTENLILO.ON_LEAVE) IS NULL THEN 0 ELSE COUNT(ATTENLILO.ON_LEAVE) END AS ON_LEAVE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(DISTINCT Isonleave) ELSE 0 END AS ON_LEAVE '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+=') AS NOTLOGIN '
			--SELECT @Strsql
			EXEC (@Strsql)
		END
	ELSE IF @ACTION='AT_WORK' AND @RPTTYPE='Summary'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,STATEID,STATE,DESIGNATION,EMPCNT) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''AT_WORK'' AS ACTION,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,STATEID,STATE,DESIGNATION,COUNT(DESIGNATION) AS EMPCNT '
			SET @Strsql+='FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 1.0
			SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BRAN WHERE BRAN.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+=') AS DB '
			IF @STATEID<>''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='GROUP BY STATEID,STATE,DESIGNATION '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='EMP' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO,DEPARTMENT,CHANNEL,CIRCLE,SECTION) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''EMP'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,'
			SET @Strsql+='CONTACTNO,REPORTTO,DEPARTMENT,CHANNEL,CIRCLE,SECTION FROM( '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,'
			SET @Strsql+='DEPT.cost_description AS DEPARTMENT,'
			SET @Strsql+='ISNULL((SELECT LTRIM(STUFF(((SELECT DISTINCT '', '' + ch_Channel FROM '
			SET @Strsql+='(SELECT EC.ch_Channel FROM Employee_Channel EC '
			SET @Strsql+='INNER JOIN Employee_ChannelMap ECM ON EC.ch_id=ECM.EP_CH_ID WHERE ECM.EP_EMP_CONTACTID=CNT.cnt_internalId '
			SET @Strsql+=') AS REFINV FOR XML PATH(''''))),1,2,'' ''))),'''') AS CHANNEL,'
			SET @Strsql+='ISNULL((SELECT LTRIM(STUFF(((SELECT DISTINCT '', '' + crl_Circle FROM '
			SET @Strsql+='(SELECT EC.crl_Circle FROM Employee_Circle EC '
			SET @Strsql+='INNER JOIN Employee_CircleMap ECM ON EC.crl_id=ECM.EP_CRL_ID WHERE ECM.EP_EMP_CONTACTID=CNT.cnt_internalId '
			SET @Strsql+=') AS REFINV FOR XML PATH(''''))),1,2,'' ''))),'''') AS CIRCLE,'
			SET @Strsql+='ISNULL((SELECT LTRIM(STUFF(((SELECT DISTINCT '', '' + sec_Section FROM '
			SET @Strsql+='(SELECT ES.sec_Section FROM Employee_Section ES '
			SET @Strsql+='INNER JOIN Employee_SectionMap ESM ON ES.sec_id=ESM.EP_SEC_ID WHERE ESM.EP_EMP_CONTACTID=CNT.cnt_internalId '
			SET @Strsql+=') AS REFINV FOR XML PATH(''''))),1,2,'' ''))),'''') AS SECTION '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 1.0
			SET @Strsql+='LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BRAN WHERE BRAN.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+=') AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='AT_WORK' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO,LOGGEDIN,LOGEDOUT,CURRENT_STATUS,'
			SET @Strsql+='TOTAL_HRS_WORKED,GPS_INACTIVE_DURATION,DISTANCE_COVERED,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION,DEPARTMENT) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''AT_WORK'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,'
			SET @Strsql+='DESIGNATION,CONTACTNO,REPORTTO,LOGGEDIN,LOGEDOUT,CURRENT_STATUS,'
			SET @Strsql+='CASE WHEN Total_Hrs_Worked>0 THEN RIGHT(''0'' + CAST(CAST(Total_Hrs_Worked AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(Total_Hrs_Worked AS VARCHAR) % 60 AS VARCHAR),2) ELSE ''--'' END AS Total_Hrs_Worked,'
			SET @Strsql+='RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR) % 60 AS VARCHAR),2) AS GPS_Inactive_duration,'
			SET @Strsql+='DISTANCE_COVERED,Shops_Visited,Total_Order_Booked_Value,Total_Collection,DEPARTMENT FROM( '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,CONVERT(VARCHAR(10),ATTEN.LOGGEDIN,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LOGGEDIN as TIME),100) AS LOGGEDIN,'
			SET @Strsql+='CASE WHEN LOGEDOUT IS NOT NULL THEN CONVERT(VARCHAR(10),ATTEN.LOGEDOUT,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LOGEDOUT AS TIME),100) ELSE ''--'' END AS LOGEDOUT,'
			SET @Strsql+='CASE WHEN USR.user_status=1 THEN ''Logged In'' ELSE ''Logged Out'' END AS CURRENT_STATUS,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS Total_Hrs_Worked,'
			SET @Strsql+='ISNULL(GPSSM.GPS_Inactive_duration,0) AS GPS_Inactive_duration,''--'' AS DISTANCE_COVERED,ISNULL(SHOPACT.shop_visited,0) AS Shops_Visited,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection,'
			SET @Strsql+='DEPT.cost_description AS DEPARTMENT '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId    '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department''   '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 1.0
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId FROM('
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId '
			SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT GPS.User_Id,CNT.cnt_internalId,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(GPS.Duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(GPS.Duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS GPS_Inactive_duration '
			SET @Strsql+='FROM tbl_FTS_GPSSubmission GPS '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=GPS.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),GPS.GPsDate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY GPS.User_Id,CNT.cnt_internalId) GPSSM ON GPSSM.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.total_visit_count) AS shop_visited FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '			
			SET @Strsql+='LEFT OUTER JOIN (SELECT SH.USER_ID,CNT.cnt_internalId,SUM(ISNULL(SH.SALE_VALUE,0)) AS Ordervalue FROM FSMUSERWISEDAYSTARTEND SH '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SH.USER_ID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SH.STARTENDDATE,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SH.USER_ID,CNT.cnt_internalId) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT COLLEC.user_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue FROM tbl_FTS_collection COLLEC '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY COLLEC.user_id,CNT.cnt_internalId) COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BRAN WHERE BRAN.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+=') AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='AT_WORKTRAVEL' AND @RPTTYPE='Summary'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO,DISTANCE_COVERED) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''AT_WORKTRAVEL'' AS ACTION,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY EMPCODE) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,'
			SET @Strsql+='DESIGNATION,CONTACTNO,REPORTTO,DISTANCE_COVERED FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,'
			SET @Strsql+='ISNULL(DISTANCE_COVERED,0) AS DISTANCE_COVERED '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 1.0
			SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id,SUM(CAST(DISTANCE_COVERED AS DECIMAL(18,2))) AS DISTANCE_COVERED FROM #TEMPSHOPUSER '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY User_Id) SHOPUSR ON SHOPUSR.user_id=USR.user_id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BRAN WHERE BRAN.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+=') AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='ON_LEAVE' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,LEAVEDATE,DEPARTMENT) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''ON_LEAVE'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,'
			SET @Strsql+='DESIGNATION,REPORTTO,LEAVEDATE,DEPARTMENT '
			SET @Strsql+='FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO,'
			SET @Strsql+='CONVERT(VARCHAR(10),ATTEN.LEAVEDATE,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LEAVEDATE AS TIME),100) AS LEAVEDATE,DEPT.cost_description AS DEPARTMENT '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department'' '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 1.0
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT ATTEN.User_Id AS USERID,Work_datetime AS LEAVEDATE,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL AND ATTEN.Isonleave=''true'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Work_datetime) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BRAN WHERE BRAN.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+=') AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='NOT_LOGIN' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO #TEMPNOTLOGIN '
			SET @Strsql+='SELECT DISTINCT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''NOT_LOGIN'' AS ACTION,''Summary'' AS RPTTYPE,EMPCODE FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			--Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(Isonleave) ELSE 0 END AS AT_WORK FROM tbl_fts_UserAttendanceLoginlogout '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BRAN WHERE BRAN.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			--Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(Isonleave) ELSE 0 END AS ON_LEAVE FROM tbl_fts_UserAttendanceLoginlogout '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' GROUP BY User_Id,'
			SET @Strsql+='CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BRAN WHERE BRAN.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+=') AS NOTLOGIN '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO,DEPARTMENT) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''NOT_LOGIN'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,'
			SET @Strsql+='DESIGNATION,CONTACTNO,REPORTTO,DEPARTMENT FROM(  '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,'
			SET @Strsql+='DEPT.cost_description AS DEPARTMENT '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId    '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department''   '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE NOT EXISTS(SELECT EMPCODE FROM #TEMPNOTLOGIN WHERE EMPCODE=CNT.cnt_internalId) AND USR.user_inactive=''N'' '
			SET @Strsql+=') AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='GRAPH' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''EMP'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO FROM( '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--Rev 1.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 1.0
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			--Rev 1.0
			IF @BRANCHID<>''
				SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCHID_LIST AS BRAN WHERE BRAN.Branch_Id=USR.user_branchId) '
			--End of Rev 1.0
			SET @Strsql+=') AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,LOGGEDIN,LOGEDOUT,GPS_INACTIVE_DURATION,DISTANCE_COVERED,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''AT_WORK'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,LOGGEDIN,LOGEDOUT,'
			SET @Strsql+='RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR) % 60 AS VARCHAR),2) AS GPS_Inactive_duration,'
			SET @Strsql+='DISTANCE_COVERED,Shops_Visited,Total_Order_Booked_Value,Total_Collection FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO,CONVERT(VARCHAR(10),ATTEN.LOGGEDIN,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LOGGEDIN as TIME),100) AS LOGGEDIN,CONVERT(VARCHAR(10),ATTEN.LOGEDOUT,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LOGEDOUT AS TIME),100) AS LOGEDOUT,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS Total_Hrs_Worked,'
			SET @Strsql+='ISNULL(GPSSM.GPS_Inactive_duration,0) AS GPS_Inactive_duration,ISNULL(DISTANCE_COVERED,0) AS DISTANCE_COVERED,ISNULL(SHOPACT.shop_visited,0) AS Shops_Visited,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT User_Id,SUM(CAST(DISTANCE_COVERED AS DECIMAL(18,2))) AS DISTANCE_COVERED FROM tbl_trans_shopuser '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY User_Id) SHOPUSR ON SHOPUSR.user_id=USR.user_id '
			SET @Strsql+='INNER JOIN (SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId FROM('
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId '
			SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT GPS.User_Id,CNT.cnt_internalId,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(GPS.Duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(GPS.Duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS GPS_Inactive_duration '
			SET @Strsql+='FROM tbl_FTS_GPSSubmission GPS '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=GPS.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),GPS.GPsDate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY GPS.User_Id,CNT.cnt_internalId) GPSSM ON GPSSM.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.total_visit_count) AS shop_visited FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT SH.USER_ID,CNT.cnt_internalId,SUM(ISNULL(SH.SALE_VALUE,0)) AS Ordervalue FROM FSMUSERWISEDAYSTARTEND SH '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SH.USER_ID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SH.STARTENDDATE,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SH.USER_ID,CNT.cnt_internalId) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT COLLEC.user_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue FROM tbl_FTS_collection COLLEC '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY COLLEC.user_id,CNT.cnt_internalId) COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId) AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,LEAVEDATE) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''ON_LEAVE'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTO,LEAVEDATE '
			SET @Strsql+='FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO,CONVERT(VARCHAR(10),ATTEN.LEAVEDATE,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LEAVEDATE AS TIME),100) AS LEAVEDATE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT ATTEN.User_Id AS USERID,Work_datetime AS LEAVEDATE,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL AND ATTEN.Isonleave=''true'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Work_datetime) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+=') AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql

			SET @Strsql=''
			SET @Strsql='INSERT INTO #TEMPNOTLOGIN '
			SET @Strsql+='SELECT DISTINCT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''NOT_LOGIN'' AS ACTION,''Summary'' AS RPTTYPE,EMPCODE FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(Isonleave) ELSE 0 END AS AT_WORK FROM tbl_fts_UserAttendanceLoginlogout '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id WHERE USR.user_inactive=''N'' '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(Isonleave) ELSE 0 END AS ON_LEAVE FROM tbl_fts_UserAttendanceLoginlogout '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' GROUP BY User_Id,'
			SET @Strsql+='CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id WHERE USR.user_inactive=''N'' '
			SET @Strsql+=') AS NOTLOGIN '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSTEAMVISITDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,''NOT_LOGIN'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTO FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE NOT EXISTS(SELECT EMPCODE FROM #TEMPNOTLOGIN WHERE EMPCODE=EMP.emp_contactId) AND USR.user_inactive=''N'' '
			SET @Strsql+=') AS DB '
			IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
				SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
				END
			ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
				BEGIN
					SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
					SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
					SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
				END
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	DROP TABLE #TEMPNOTLOGIN
	DROP TABLE #TEMPSHOPUSER
	--Rev 1.0
	DROP TABLE #BRANCHID_LIST
	--End of Rev 1.0

	SET NOCOUNT OFF
END