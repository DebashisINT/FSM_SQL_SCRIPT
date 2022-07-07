--EXEC PRC_FTSDASHBOARD_REPORT '2019-05-20','5,8,9,14,15,19,26,28,29,38','','','ALL','Summary',378
--EXEC PRC_FTSDASHBOARD_REPORT '2018-12-10','','','','EMP','Detail',378
--EXEC PRC_FTSDASHBOARD_REPORT '2018-10-26','','','','ALL','Summary',378
--EXEC PRC_FTSDASHBOARD_REPORT '2018-12-28','','','','AT_WORK','Detail',378
--EXEC PRC_FTSDASHBOARD_REPORT '2018-12-28','','','','AT_WORK','Summary',378
--EXEC PRC_FTSDASHBOARD_REPORT '2018-12-28','15','','EMP0000002','AT_WORKTRAVEL','Summary',378
--EXEC PRC_FTSDASHBOARD_REPORT '2018-12-07','','','','ON_LEAVE','Detail',378
--EXEC PRC_FTSDASHBOARD_REPORT '2018-12-21','15','','','NOT_LOGIN','Detail',378
--EXEC PRC_FTSDASHBOARD_REPORT '2018-12-18','','','','GRAPH','Detail',378
-- exec PRC_FTSDASHBOARD_REPORT @TODAYDATE='2022-03-30', @STATEID='15,3,19,28', @DESIGNID='',@USERID=378,@EMPID='',@BRANCHID='1,118,119,122',@ACTION='AT_WORK',@RPTTYPE='Detail'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSDASHBOARD_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSDASHBOARD_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSDASHBOARD_REPORT]
(
@TODAYDATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@ACTION NVARCHAR(20),
@RPTTYPE NVARCHAR(20),
@USERID INT
-- Rev 6.0
,@BRANCHID nvarchar(max)=NULL
-- End of Rev 6.0
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 06/12/2018
Module	   : Dashboard Summary & Detail
1.0		v27.0.0		Debashis	21/05/2019		Not Logged In: If the Leave updated for the day user logged in, it should not consider the same as Not Logged In.
												(It may be on future date also)
												On Leave : Should consider the value from the fields if the Leave details found entered(It may be on future date also).
												Refer: Fwd: Multi day Leave In App
2.0		V2.0.12		Tanmoy		12-06-2020		Add Department @ACTION='EMP' AND @RPTTYPE='Detail',@ACTION='AT_WORK' AND @RPTTYPE='Detail'@ACTION='ON_LEAVE' AND @RPTTYPE='Detail'
												@ACTION='NOT_LOGIN' AND @RPTTYPE='Detail' Mantis :22402
3.0		v2.0.13		Debashis	17-06-2020		DASHBOARD - NOT LOGIN CALCULATION ENHANCEMENT.Refer: 0022505
4.0		v2.0.12		Debashis	19-06-2020		There is more then one space between Name & Surname in the Dashboard.Remove those space.Refer: 0022355
5.0		v2.0.12		Debashis	25-06-2020		Rana Roy has provided the attendance at 9.30 which is shown in the performance summary report but from the dashboard, 
												it is showing under "Not Logged In".This issue happens on Karuna Management.
												The problem was in the Dashboard query. Previously the Employee CTC table was considered for finding the Supervisor of 
												an employee which has been removed now and the problem has been taken care of.Refer mail: Fwd: Showing wrong report
6.0		V2.0.29		Sanchita	08-03-2022		FSM - Portal: Branch selection required against the selected 'State'. Refer: 24729
7.0		V2.0.30		Sanchita	30-03-2022		The branch selection taken care when clicked on Employee Strength, Employees At Work, Employees on Leave. Refer: 24765
8.0		v2.0.29		Debashis	13-05-2022		ITC : FSM : Dashboard added few columns.Refer: 0024887
9.0		v2.0.30		Debashis	20-06-2022		All Tab Data [Employee Strength, Employees at Work, Not Logged In] shall be showing the data of employees those having 
												Designation = DS or TL.Refer: 0024963
10.0	v2.0.31		Debashis	07-07-2022		ADDED TWO CTC RECORD, DATA SHOWING DUPLICATE IN
												1. EMPLOYEE STRENGTH
												2. EMPLOYEE AT WORK
												3. ON LEAVE
												4. NOT LOGGEDIN.Refer: 0025019
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	--Rev 9.0
	DECLARE @IsShowOnlyDSTLInDashboard NVARCHAR(100)=''
	SET @IsShowOnlyDSTLInDashboard=(SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsShowOnlyDSTLInDashboard')
	--End of Rev 9.0

	--Rev 5.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
	--End of Rev 5.0
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
	
	-- Rev 6.0
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
	-- End of Rev 6.0	

	--Rev 5.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
	--End of Rev 5.0
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

	--Rev 5.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	--End of Rev 5.0
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	--Rev 5.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPNOTLOGIN') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPNOTLOGIN') IS NOT NULL
	--End of Rev 5.0
		DROP TABLE #TEMPNOTLOGIN
	CREATE TABLE #TEMPNOTLOGIN
		(
			USERID INT,ACTION NVARCHAR(20),RPTTYPE NVARCHAR(20),EMPCODE NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPNOTLOGIN(EMPCODE)

	--Rev 5.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSHOPUSER') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPSHOPUSER') IS NOT NULL
	--End of Rev 5.0
		DROP TABLE #TEMPSHOPUSER
	CREATE TABLE #TEMPSHOPUSER
	(
	User_Id BIGINT,distance_covered NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS,SDate DATETIME
	)
	CREATE NONCLUSTERED INDEX IX_shopuser ON #TEMPSHOPUSER(User_Id ASC)
	CREATE NONCLUSTERED INDEX IX1_shopuser ON #TEMPSHOPUSER(distance_covered ASC,SDate ASC)
	INSERT INTO #TEMPSHOPUSER 
	SELECT User_Id,distance_covered,SDate FROM tbl_trans_shopuser WHERE CONVERT(NVARCHAR(10),SDate,120)=CONVERT(NVARCHAR(10),@TODAYDATE,120) AND distance_covered IS NOT NULL

	--Rev 6.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
			IF OBJECT_ID('tempdb..#EMPHR') IS NOT NULL
				DROP TABLE #EMPHR
			CREATE TABLE #EMPHR
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			IF OBJECT_ID('tempdb..#EMPHR_EDIT') IS NOT NULL
				DROP TABLE #EMPHR_EDIT
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
			where EMPCODE IS NULL OR EMPCODE=@empcode  
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
	--End of Rev 6.0

	--Rev 5.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
	--End of Rev 5.0
		DROP TABLE #TEMPCONTACT
	--Rev 8.0 && cnt_UCC has been added
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	--Rev 6.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			--Rev 9.0
			--INSERT INTO #TEMPCONTACT
			--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT
			--INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
			--WHERE cnt_contactType IN('EM')
			IF @IsShowOnlyDSTLInDashboard='0'
				BEGIN
					INSERT INTO #TEMPCONTACT
					SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT
					INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
					WHERE cnt_contactType IN('EM')
				END
			ELSE
				BEGIN
					INSERT INTO #TEMPCONTACT
					SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT CNT
					INNER JOIN #EMPHR_EDIT ON CNT.cnt_internalId=EMPCODE
					INNER JOIN tbl_master_employee EMP ON CNT.cnt_internalId=EMP.emp_contactId
					INNER JOIN (
					SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt 
					LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation 
					WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation IN('DS','TL') 
					GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
					) DESG ON DESG.emp_cntId=EMP.emp_contactId
					WHERE CNT.cnt_contactType IN('EM')
				END
			--End of Rev 9.0
		END
	ELSE
		BEGIN
			--Rev 9.0
			--INSERT INTO #TEMPCONTACT
			--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
			IF @IsShowOnlyDSTLInDashboard='0'
				BEGIN
					INSERT INTO #TEMPCONTACT
					SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
				END
			ELSE
				BEGIN
					INSERT INTO #TEMPCONTACT
					SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT CNT
					INNER JOIN tbl_master_employee EMP ON CNT.cnt_internalId=EMP.emp_contactId
					INNER JOIN (
					SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt 
					LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation 
					WHERE cnt.emp_effectiveuntil IS NULL AND desg.deg_designation IN('DS','TL') 
					GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
					) DESG ON DESG.emp_cntId=EMP.emp_contactId
					WHERE CNT.cnt_contactType IN('EM')
				END
			--End of Rev 9.0
		END
	--End of Rev 6.0
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSDASHBOARD_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSDASHBOARD_REPORT
			(
			  USERID INT,
			  ACTION NVARCHAR(20),
			  RPTTYPE NVARCHAR(20),
			  SEQ INT,
			  EMPCNT INT,
			  AT_WORK INT,
			  ON_LEAVE INT,
			  NOT_LOGIN INT,
			  --Rev 8.0
			  EMPID NVARCHAR(100) NULL,
			  --End of Rev 8.0
			  EMPCODE NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  CONTACTNO NVARCHAR(50) NULL,
			  --Rev 8.0
			  REPORTTOUID NVARCHAR(100),
			  --End of Rev 8.0
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
			  --Rev 2.0 Start
			  DEPARTMENT NVARCHAR(100),
			  --Rev 2.0 End
			  -- Rev 6.0
			  BRANCHID int,
			  BRANCH NVARCHAR(300)
			  -- End of Rev 6.0
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSDASHBOARD_REPORT (SEQ)
		END
	DELETE FROM FTSDASHBOARD_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	IF @ACTION='ALL' AND @RPTTYPE='Summary'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,EMPCNT) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''EMP'' AS ACTION,''Summary'' AS RPTTYPE,COUNT(CNT.cnt_internalId) AS EMPCNT FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			IF @STATEID<>''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			-- Rev 6.0
			--IF @BRANCHID<>''
			--BEGIN
			--	IF @STATEID<>''
			--		SET @Strsql+='and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			--	else
			--		SET @Strsql+='WHERE EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			--END
			IF  @STATEID<>'' and @BRANCHID<>''
			BEGIN
				SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			END
			-- End of Rev 6.0
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,AT_WORK) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AT_WORK'' AS ACTION,''Summary'' AS RPTTYPE,CASE WHEN COUNT(ATTENLILO.AT_WORK) IS NULL THEN 0 ELSE COUNT(ATTENLILO.AT_WORK) END AS AT_WORK FROM tbl_master_employee EMP '
			--Rev 5.0
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			--Rev 5.0
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			--SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			--SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(Isonleave) ELSE 0 END AS AT_WORK '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			-- Rev 6.0
			IF @STATEID<>'' and @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			-- End of Rev 6.0
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,ON_LEAVE) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''ON_LEAVE'' AS ACTION,''Summary'' AS RPTTYPE,CASE WHEN COUNT(ATTEN.ON_LEAVE) IS NULL THEN 0 ELSE COUNT(ATTEN.ON_LEAVE) END AS ON_LEAVE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' ' 
			--Rev 5.0
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id '
			--SET @Strsql+='FROM tbl_trans_employeeCTC as cnt '
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
			--SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
			--SET @Strsql+='FROM tbl_master_employee EMP '
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN (SELECT ATTEN.User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(Isonleave) ELSE 0 END AS ON_LEAVE,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			--Rev 1.0
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			--Rev 3.0
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) BETWEEN CONVERT(NVARCHAR(10),ATTEN.Leave_FromDate,120) AND CONVERT(NVARCHAR(10),ATTEN.Leave_ToDate,120) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--End of Rev 3.0
			--End of Rev 1.0
			SET @Strsql+='AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL AND ATTEN.Isonleave=''true'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave) ATTEN '
			SET @Strsql+='ON ATTEN.cnt_internalId=CNT.cnt_internalId WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			-- Rev 6.0
			IF @STATEID<>'' and @BRANCHID<>''
				SET @Strsql+='AND EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			-- End of Rev 6.0
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,NOT_LOGIN) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''NOT_LOGIN'' AS ACTION,''Summary'' AS RPTTYPE,SUM(ISNULL(EMPCNT,0))-(SUM(ISNULL(AT_WORK,0))+SUM(ISNULL(ON_LEAVE,0))) AS NOT_LOGIN FROM('
			SET @Strsql+='SELECT COUNT(CNT.cnt_internalId) AS EMPCNT,0 AS AT_WORK,0 AS ON_LEAVE FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			IF @STATEID<>''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			-- Rev 6.0
			--IF @BRANCHID<>''
			--BEGIN
			--	IF @STATEID<>''
			--		SET @Strsql+='AND EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			--	ELSE
			--		SET @Strsql+='WHERE EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			--END

			IF @STATEID<>'' and @BRANCHID<>''
			BEGIN
				SET @Strsql+='AND EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			END

			-- End of Rev 6.0
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT 0 AS EMPCNT,CASE WHEN COUNT(ATTENLILO.AT_WORK) IS NULL THEN 0 ELSE COUNT(ATTENLILO.AT_WORK) END AS AT_WORK,0 AS ON_LEAVE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			--Rev 5.0
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			--Rev 5.0
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			--SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			--SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(Isonleave) ELSE 0 END AS AT_WORK '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			-- Rev 6.0
			IF @STATEID<>'' and @BRANCHID<>''
				SET @Strsql+='and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			-- End of Rev 6.0
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT 0 AS EMPCNT,0 AS AT_WORK,CASE WHEN COUNT(ATTENLILO.ON_LEAVE) IS NULL THEN 0 ELSE COUNT(ATTENLILO.ON_LEAVE) END AS ON_LEAVE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			--Rev 5.0
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--eND OF Rev 5.0
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			--Rev 5.0
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			--SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			--SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--End of Rev 5.0
			--Rev 1.0
			--SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(Isonleave) ELSE 0 END AS ON_LEAVE '
			--SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(DISTINCT Isonleave) ELSE 0 END AS ON_LEAVE '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout '
			--Rev 3.0
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) BETWEEN CONVERT(NVARCHAR(10),Leave_FromDate,120) AND CONVERT(NVARCHAR(10),Leave_ToDate,120) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--End of Rev 3.0
			--End of Rev 1.0
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			-- Rev 6.0
			IF @STATEID<>'' and @BRANCHID<>''
				SET @Strsql+='and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
			-- End of Rev 6.0
			SET @Strsql+=') AS NOTLOGIN '

			--SET @Strsql=''
			--SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,NOT_LOGIN) '
			--SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''NOT_LOGIN'' AS ACTION,''Summary'' AS RPTTYPE,SUM(ISNULL(EMPCNT,0))-(SUM(ISNULL(AT_WORK,0))+SUM(ISNULL(ON_LEAVE,0))) AS NOT_LOGIN FROM FTSDASHBOARD_REPORT '
			--SET @Strsql+='WHERE ACTION IN(''EMP'',''AT_WORK'',''ON_LEAVE'') AND RPTTYPE=''Summary'' '			
			--SELECT @Strsql
			EXEC (@Strsql)
		END
	ELSE IF @ACTION='AT_WORK' AND @RPTTYPE='Summary'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,STATEID,STATE,DESIGNATION,EMPCNT) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AT_WORK'' AS ACTION,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,STATEID,STATE,DESIGNATION,COUNT(DESIGNATION) AS EMPCNT '
			SET @Strsql+='FROM('
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
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
			SET @Strsql+=') AS DB '
			IF @STATEID<>''
				SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='GROUP BY STATEID,STATE,DESIGNATION '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='EMP' AND @RPTTYPE='Detail'
		BEGIN
			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO,DEPARTMENT) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''EMP'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,'
			SET @Strsql+='DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO '
			--Rev 2.0 Start		
			SET @Strsql+=' , Department FROM( '
			--Rev 2.0 End
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOUID,RPTTO.REPORTTO '
			--Rev 2.0 Start		
			SET @Strsql+=' ,DEPT.cost_description as Department '
			--Rev 2.0 End
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--Rev 2.0
			--Rev Debashis
			--SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId    '
			SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId AND CTC.emp_effectiveuntil IS NULL '
			--End of Rev Debashis
			SET @Strsql+=' LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department''   '
			--Rev 2.0 End
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
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
			-- Rev 7.0
			IF @STATEID<>'' and @BRANCHID<>''
			BEGIN
				SET @Strsql+='and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=(select top 1 user_branchId from tbl_master_user where user_contactid=DB.EMPCODE)) '
			END
			-- End of Rev 7.0
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='AT_WORK' AND @RPTTYPE='Detail'
		BEGIN
			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO,LOGGEDIN,LOGEDOUT,'
			SET @Strsql+='CURRENT_STATUS,TOTAL_HRS_WORKED,GPS_INACTIVE_DURATION,DISTANCE_COVERED,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION '
			--Rev 2.0 Start		
			SET @Strsql+=' ,DEPARTMENT) '
			--Rev 2.0 End		
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AT_WORK'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,'
			SET @Strsql+='DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO,LOGGEDIN,LOGEDOUT,CURRENT_STATUS,'
			SET @Strsql+='CASE WHEN Total_Hrs_Worked>0 THEN RIGHT(''0'' + CAST(CAST(Total_Hrs_Worked AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(Total_Hrs_Worked AS VARCHAR) % 60 AS VARCHAR),2) ELSE ''--'' END AS Total_Hrs_Worked,'
			SET @Strsql+='RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR) % 60 AS VARCHAR),2) AS GPS_Inactive_duration,'
			SET @Strsql+='DISTANCE_COVERED,Shops_Visited,Total_Order_Booked_Value,Total_Collection  '
				--Rev 2.0 Start		
			SET @Strsql+=' ,Department FROM( '
			--Rev 2.0 End
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOUID,RPTTO.REPORTTO,CONVERT(VARCHAR(10),ATTEN.LOGGEDIN,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LOGGEDIN as TIME),100) AS LOGGEDIN,'
			SET @Strsql+='CASE WHEN LOGEDOUT IS NOT NULL THEN CONVERT(VARCHAR(10),ATTEN.LOGEDOUT,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LOGEDOUT AS TIME),100) ELSE ''--'' END AS LOGEDOUT,'
			SET @Strsql+='CASE WHEN USR.user_status=1 THEN ''Logged In'' ELSE ''Logged Out'' END AS CURRENT_STATUS,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS Total_Hrs_Worked,'
			--SET @Strsql+='ISNULL(GPSSM.GPS_Inactive_duration,0) AS GPS_Inactive_duration,ISNULL(DISTANCE_COVERED,0) AS DISTANCE_COVERED,ISNULL(SHOPACT.shop_visited,0) AS Shops_Visited,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
			SET @Strsql+='ISNULL(GPSSM.GPS_Inactive_duration,0) AS GPS_Inactive_duration,''--'' AS DISTANCE_COVERED,ISNULL(SHOPACT.shop_visited,0) AS Shops_Visited,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
			--Rev 2.0 Start		
			SET @Strsql+=' ,DEPT.cost_description as Department '
			--Rev 2.0 End
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--Rev 2.0
			--Rev Debashis
			--SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId AND CTC.emp_effectiveuntil IS NULL '
			--End of Rev Debashis
			SET @Strsql+=' LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department''   '
			--Rev 2.0 End
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			--SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id,SUM(CAST(DISTANCE_COVERED AS DECIMAL(18,2))) AS DISTANCE_COVERED FROM #TEMPSHOPUSER '
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--SET @Strsql+='GROUP BY User_Id) SHOPUSR ON SHOPUSR.user_id=USR.user_id '
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
			SET @Strsql+='LEFT OUTER JOIN (SELECT ORDH.userID,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue FROM tbl_trans_fts_Orderupdate ORDH '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY ORDH.userID,CNT.cnt_internalId) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId '
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
			-- Rev 7.0
			IF @STATEID<>'' and @BRANCHID<>''
			BEGIN
				SET @Strsql+='and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=(select top 1 user_branchId from tbl_master_user where user_contactid=DB.EMPCODE)) '
			END
			-- End of Rev 7.0

			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='AT_WORKTRAVEL' AND @RPTTYPE='Summary'
		BEGIN
			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO,DISTANCE_COVERED) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AT_WORKTRAVEL'' AS ACTION,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY EMPCODE) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,'
			SET @Strsql+='STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO,DISTANCE_COVERED FROM('
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOUID,RPTTO.REPORTTO,ISNULL(DISTANCE_COVERED,0) AS DISTANCE_COVERED '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id,SUM(CAST(DISTANCE_COVERED AS DECIMAL(18,2))) AS DISTANCE_COVERED FROM #TEMPSHOPUSER '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY User_Id) SHOPUSR ON SHOPUSR.user_id=USR.user_id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
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
			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTOUID,REPORTTO,LEAVEDATE,DEPARTMENT) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''ON_LEAVE'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,'
			SET @Strsql+='DEG_ID,DESIGNATION,REPORTTOUID,REPORTTO,LEAVEDATE '
			--Rev 2.0 Start		
			SET @Strsql+=' , Department '
			--Rev 2.0 End
			SET @Strsql+='FROM('
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTOUID,RPTTO.REPORTTO,CONVERT(VARCHAR(10),ATTEN.LEAVEDATE,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LEAVEDATE AS TIME),100) AS LEAVEDATE '
			--Rev 2.0 Start		
			SET @Strsql+=' ,DEPT.cost_description as Department '
			--Rev 2.0 End
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--Rev 2.0 Start
			--Rev Debashis
			--SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId    '
			SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId AND CTC.emp_effectiveuntil IS NULL '
			--End of Rev Debashis
			SET @Strsql+=' LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department''   '
			--Rev 2.0 End
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			--Rev 1.0
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--End of Rev 1.0
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT ATTEN.User_Id AS USERID,Work_datetime AS LEAVEDATE,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			--Rev 1.0
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--Rev 3.0
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) BETWEEN CONVERT(NVARCHAR(10),ATTEN.Leave_FromDate,120) AND CONVERT(NVARCHAR(10),ATTEN.Leave_ToDate,120) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--End of Rev 3.0
			--End of Rev 1.0
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
			-- Rev 7.0
			IF @STATEID<>'' and @BRANCHID<>''
			BEGIN
				SET @Strsql+='and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=(select top 1 user_branchId from tbl_master_user where user_contactid=DB.EMPCODE)) '
			END
			-- End of Rev 7.0
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='NOT_LOGIN' AND @RPTTYPE='Detail'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO #TEMPNOTLOGIN '
			SET @Strsql+='SELECT DISTINCT '+STR(@USERID)+' AS USERID,''NOT_LOGIN'' AS ACTION,''Summary'' AS RPTTYPE,EMPCODE FROM('
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE FROM tbl_master_employee EMP '
			--Rev 5.0
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			--Rev 5.0
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
			--SET @Strsql+='FROM tbl_master_employee EMP '
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(Isonleave) ELSE 0 END AS AT_WORK FROM tbl_fts_UserAttendanceLoginlogout '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE FROM tbl_master_employee EMP '
			--Rev 5.0
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			--Rev 5.0
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			--SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
			--SET @Strsql+='FROM tbl_master_employee EMP INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			--End of Rev 5.0
			SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(Isonleave) ELSE 0 END AS ON_LEAVE FROM tbl_fts_UserAttendanceLoginlogout '
			--Rev 1.0
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' GROUP BY User_Id,'
			--Rev 3.0
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) BETWEEN CONVERT(NVARCHAR(10),Leave_FromDate,120) AND CONVERT(NVARCHAR(10),Leave_ToDate,120) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			--End of Rev 3.0
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' GROUP BY User_Id,'
			--End of Rev 1.0
			SET @Strsql+='CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id WHERE USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
			SET @Strsql+=') AS NOTLOGIN '
			--SELECT @Strsql
			EXEC (@Strsql)

			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO,DEPARTMENT) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''NOT_LOGIN'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,'
			SET @Strsql+='DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO   '
			--Rev 2.0 Start		
			SET @Strsql+=' ,Department FROM(  '
			--Rev 2.0 End
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOUID,RPTTO.REPORTTO '
			--Rev 2.0 Start		
			SET @Strsql+=' ,DEPT.cost_description as Department '
			--Rev 2.0 End
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			--Rev 2.0 Start
			--Rev Debashis
			--SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId    '
			SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId AND CTC.emp_effectiveuntil IS NULL '
			--End of Rev Debashis
			SET @Strsql+=' LEFT OUTER JOIN tbl_master_costCenter DEPT ON DEPT.cost_id=CTC.emp_Department AND DEPT.cost_costCenterType = ''department''   '
			--Rev 2.0 End
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
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
			-- Rev 7.0
			IF @STATEID<>'' and @BRANCHID<>''
			BEGIN
				SET @Strsql+='and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=(select top 1 user_branchId from tbl_master_user where user_contactid=DB.EMPCODE)) '
			END
			-- End of Rev 7.0
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @ACTION='GRAPH' AND @RPTTYPE='Detail'
		BEGIN
			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''EMP'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,'
			SET @Strsql+='DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO FROM( '
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOUID,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
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

			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTOUID,REPORTTO,LOGGEDIN,LOGEDOUT,'
			SET @Strsql+='GPS_INACTIVE_DURATION,DISTANCE_COVERED,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AT_WORK'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,'
			SET @Strsql+='DEG_ID,DESIGNATION,REPORTTOUID,REPORTTO,LOGGEDIN,LOGEDOUT,'
			SET @Strsql+='RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR) % 60 AS VARCHAR),2) AS GPS_Inactive_duration,'
			SET @Strsql+='DISTANCE_COVERED,Shops_Visited,Total_Order_Booked_Value,Total_Collection FROM('
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTOUID,RPTTO.REPORTTO,CONVERT(VARCHAR(10),ATTEN.LOGGEDIN,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LOGGEDIN as TIME),100) AS LOGGEDIN,CONVERT(VARCHAR(10),ATTEN.LOGEDOUT,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LOGEDOUT AS TIME),100) AS LOGEDOUT,'
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS Total_Hrs_Worked,'
			SET @Strsql+='ISNULL(GPSSM.GPS_Inactive_duration,0) AS GPS_Inactive_duration,ISNULL(DISTANCE_COVERED,0) AS DISTANCE_COVERED,ISNULL(SHOPACT.shop_visited,0) AS Shops_Visited,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
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
			SET @Strsql+='LEFT OUTER JOIN (SELECT ORDH.userID,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue FROM tbl_trans_fts_Orderupdate ORDH '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY ORDH.userID,CNT.cnt_internalId) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId '
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

			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,REPORTTOUID,REPORTTO,LEAVEDATE) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''ON_LEAVE'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,'
			SET @Strsql+='DEG_ID,DESIGNATION,REPORTTOUID,REPORTTO,LEAVEDATE FROM('
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,RPTTO.REPORTTOUID,RPTTO.REPORTTO,CONVERT(VARCHAR(10),ATTEN.LEAVEDATE,105) +'' ''+ CONVERT(VARCHAR(15),CAST(ATTEN.LEAVEDATE AS TIME),100) AS LEAVEDATE '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
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
			SET @Strsql+='SELECT DISTINCT '+STR(@USERID)+' AS USERID,''NOT_LOGIN'' AS ACTION,''Summary'' AS RPTTYPE,EMPCODE FROM('
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

			--Rev 8.0 && Some new fields have been added as BRANCHID,BRANCH,EMPID & REPORTTOUID
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARD_REPORT(USERID,ACTION,RPTTYPE,SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''NOT_LOGIN'' AS ACTION,''Detail'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,BRANCHID,BRANCH,EMPID,EMPCODE,EMPNAME,STATEID,STATE,'
			SET @Strsql+='DEG_ID,DESIGNATION,CONTACTNO,REPORTTOUID,REPORTTO FROM('
			--Rev 4.0
			--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SELECT BR.BRANCH_ID AS BRANCHID,BR.BRANCH_DESCRIPTION AS BRANCH,EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			--End of Rev 4.0
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOUID,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			--Rev 8.0
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON USR.user_branchId=BR.branch_id '
			--End of Rev 8.0
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
			SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,CNT.cnt_UCC AS REPORTTOUID,'
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

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END

	SET NOCOUNT OFF
END
GO