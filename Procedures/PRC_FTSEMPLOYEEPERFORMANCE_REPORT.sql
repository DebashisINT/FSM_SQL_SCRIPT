--EXEC PRC_FTSEMPLOYEEPERFORMANCE_REPORT '2020-06-19','2020-06-19','','','EMB0000002',378
--EXEC PRC_FTSEMPLOYEEPERFORMANCE_REPORT '2021-01-01','2022-01-12','','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSEMPLOYEEPERFORMANCE_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSEMPLOYEEPERFORMANCE_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSEMPLOYEEPERFORMANCE_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 31/12/2018
Module	   : Employee Performance Details
1.0		v2.0.0		Debashis	05/01/2019		Total Visit count is reflecting wrong in report compare to Employee Summary vs Performance Summary.Now solved.Refer:Employee 
												Summary Vs Performance Report
2.0		v2.0.0		Debashis	23/01/2019		Total Count is not matching while generating Performance Summary report.Now solved.Refer:Total Count is not matching while 
												generating Performance Summary report.
3.0		v2.0.0		Debashis	25/01/2019		On Leave and Leave type is not added in Performance report.Refer: FSM - Features & Issues # Karuna Group
4.0		v8.0.0		Debashis	06/02/2019		Performance Report - New column [Travelled(KM)]. Refer: HIGH PRIORITY
5.0		v19.0.0		Debashis	27/02/2019		"Remarks" from Attendance table, to be shown in "Performance Summary" after "Work/Leave Type" column wrapping in multiple lines.
												Refer mail: (no subject)
6.0		v20.0.0		Debashis	04/03/2019		Duplicate visit capturing while checking Performance summary report.Refer mail: FSM issues
7.0		v21.0.0		Debashis	11/08/2019		The "Shop_CreateTime" column has been blocked as it is no more required.
8.0		v21.0.0		Debashis	26/09/2019		Diamond Outlet type created from the mobile app and when check the performance summary report, the particular shop type is 
												showing as blank.It should show 'Diamond Outlet' in the type column of Performance summary report.Refer: 0020734
9.0		v2.0.4		Debashis	27/02/2020		There 'Type' is showing blank for saaggifo FSM.additional three types should be consider 'Chemist', 'Stockist', 'Doctor'.
												Refer: 0021849
10.0	v2.0.11		Debashis	12/05/2020		FTS reports with more fields.Refer: 0022323
11.0	v2.0.12		Debashis	09/06/2020		Revisit from Team details is showing meeting in Performance summary report.Refer: 0022447
12.0	v2.0.13		Debashis	16/06/2020		Logout Time showing wrong as it was considered 12hrs format.Now it has been made 24hrs format and issue has been taken 
												care of.Refer: 0022499
13.0	v2.0.12		Debashis	17/06/2020		Small rectification/enhancement required in FSM Portal.Refer: 0022355
14.0	v2.0.13		Debashis	24/06/2020		Branch column required in the various FSM reports.Refer: 0022610
15.0	v2.0.14		Debashis	02/07/2020		Employee Summary & Performance Summary - full month data showing all type 'At Work' in output.Now solved.Refer: 0022640
16.0	v2.0.15		Debashis	16/03/2021		Performance Summary Report
												Duration Spend in Shop - A NEW COLUMN REQUIRED.
												It will show 'Duration Spend' for each shop.Refer: 0023872
17.0	v2.0.24		Tanmoy		30/07/2021		Employee hierarchy wise filter
18.0	v2.0.26		Debashis	12/01/2022		District/Cluster/Pincode fields are required in some of the reports.Refer: 0024575
19.0	v2.0.26		Debashis	13/01/2022		Alternate phone no. 1 & alternate email fields are required in some of the reports.Refer: 0024577
20.0	v2.0.27		Debashis	16/02/2022		New Type=Lead (16) to be considered in the report.Refer: 0024676
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	--Rev 11.0
	DECLARE @isRevisitTeamDetail NVARCHAR(100)
	SELECT @isRevisitTeamDetail=[Value] FROM fts_app_config_settings WHERE [Key]='isRevisitTeamDetail' AND [Description]='Revisit from Team Details in Portal'
	--End of Rev 11.0

	--Rev 10.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
	--End of Rev 10.0
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
	
	--Rev 10.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
	--End of Rev 10.0
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

	--Rev 10.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
	--End of Rev 10.0
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	--Rev 10.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
	--End of Rev 10.0
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--Rev 14.0
			cnt_branchid INT,
			--End of Rev 14.0
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	--Rev 14.0
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	--End of Rev 14.0

	--Rev 17.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
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
		
			INSERT INTO #EMPHRS
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHRS 
			where EMPCODE IS NULL OR EMPCODE=@empcodes  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHRS a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 

		END
	--End of Rev 17.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSEMPLOYEEPERFORMANCE_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSEMPLOYEEPERFORMANCE_REPORT
			(
			  USERID INT,
			  SEQ INT,
			  WORK_DATE NVARCHAR(10),
			  LOGGEDIN NVARCHAR(100) NULL,
			  LOGEDOUT NVARCHAR(100) NULL,
			  CONTACTNO NVARCHAR(50) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  --Rev 14.0
			  BRANCHDESC NVARCHAR(300),
			  --End of Rev 14.0
			  OFFICE_ADDRESS NVARCHAR(300),
			  ATTEN_STATUS NVARCHAR(20),
			  --Rev 3.0
			  WORK_LEAVE_TYPE NVARCHAR(2000) NULL,
			  --End of Rev 3.0
			  --Rev 5.0
			  REMARKS NVARCHAR(2000) NULL,
			  --End of Rev 5.0
			  EMPCODE NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  EMPID NVARCHAR(100) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  DATEOFJOINING NVARCHAR(10),
			  REPORTTO NVARCHAR(300) NULL,
			  RPTTODESG NVARCHAR(50) NULL,
			  SHOP_TYPE NVARCHAR(10),
			  SHOP_CODE NVARCHAR(100),
			  SHOP_NAME NVARCHAR(300) NULL,
			  --Rev 10.0
			  ENTITYCODE NVARCHAR(600) NULL,
			  --End of Rev 10.0
			  SHOPADDR_CONTACT NVARCHAR(300) NULL,
			  --Rev 18.0
			  SHOP_DISTRICT NVARCHAR(50) NULL,
			  SHOP_PINCODE NVARCHAR(120) NULL,
			  SHOP_CLUSTER NVARCHAR(500) NULL,
			  --End of Rev 18.0
			  PP_NAME NVARCHAR(300) NULL,
			  PPADDR_CONTACT NVARCHAR(300) NULL,
			  DD_NAME NVARCHAR(300) NULL,
			  DDADDR_CONTACT NVARCHAR(300) NULL,
			  --Rev 19.0
			  ALT_MOBILENO1 NVARCHAR(40) NULL,
			  SHOP_OWNER_EMAIL2 NVARCHAR(300) NULL,
			  --End of Rev 19.0
			   --Rev 13.0
			  VISITREMARKS NVARCHAR(1000),
			  MEETINGREMARKS NVARCHAR(1000),
			  MEETING_ADDRESS NVARCHAR(1000),
			  --End of Rev 13.0
			  TOTAL_VISIT INT,
			  NEWSHOP_VISITED INT,
			  RE_VISITED INT,
			  --Rev 13.0
			  TOTMETTING INT,
			  --End of Rev 13.0
			  --Rev 16.0
			  SPENT_DURATION NVARCHAR(50),
			  --End of Rev 16.0
			  --Rev 4.0
			  DISTANCE_TRAVELLED DECIMAL(38,2),
			  --End of Rev 4.0
			  TOTAL_ORDER_BOOKED_VALUE DECIMAL(38,2),
			  TOTAL_COLLECTION DECIMAL(38,2)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSEMPLOYEEPERFORMANCE_REPORT (SEQ)
		END
	DELETE FROM FTSEMPLOYEEPERFORMANCE_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	--Rev 3.0
	--SET @Strsql='INSERT INTO FTSEMPLOYEEPERFORMANCE_REPORT(USERID,SEQ,WORK_DATE,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,OFFICE_ADDRESS,ATTEN_STATUS,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,DATEOFJOINING,'
	--SET @Strsql+='REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,SHOPADDR_CONTACT,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	--SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY LOGIN_DATETIME) AS SEQ,LOGIN_DATETIME,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,OFFICE_ADDRESS,ATTEN_STATUS,EMPCODE,EMPNAME,EMPID,'
	--Rev 5.0
	--SET @Strsql='INSERT INTO FTSEMPLOYEEPERFORMANCE_REPORT(USERID,SEQ,WORK_DATE,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,OFFICE_ADDRESS,ATTEN_STATUS,WORK_LEAVE_TYPE,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,DATEOFJOINING,'
	--Rev 14.0
	--SET @Strsql='INSERT INTO FTSEMPLOYEEPERFORMANCE_REPORT(USERID,SEQ,WORK_DATE,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,OFFICE_ADDRESS,ATTEN_STATUS,WORK_LEAVE_TYPE,REMARKS,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,DATEOFJOINING,'
	SET @Strsql='INSERT INTO FTSEMPLOYEEPERFORMANCE_REPORT(USERID,SEQ,WORK_DATE,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,BRANCHDESC,OFFICE_ADDRESS,ATTEN_STATUS,WORK_LEAVE_TYPE,REMARKS,EMPCODE,EMPNAME,EMPID,'
	SET @Strsql+='DEG_ID,DESIGNATION,DATEOFJOINING,'
	--End of Rev 14.0
	----End of Rev 5.0
	----Rev 4.0
	----SET @Strsql+='REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,SHOPADDR_CONTACT,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	--Rev 10.0
	--SET @Strsql+='REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,SHOPADDR_CONTACT,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,DISTANCE_TRAVELLED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	--Rev 13.0
	--SET @Strsql+='REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,ENTITYCODE,SHOPADDR_CONTACT,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,DISTANCE_TRAVELLED,'
	--Rev 16.0 && Added a new field as SPENT_DURATION
	--Rev 18.0 && Added three new fields as SHOP_DISTRICT,SHOP_PINCODE & SHOP_CLUSTER
	--Rev 19.0 && Added two new fields as ALT_MOBILENO1 & SHOP_OWNER_EMAIL2
	SET @Strsql+='REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,ENTITYCODE,SHOPADDR_CONTACT,SHOP_DISTRICT,SHOP_PINCODE,SHOP_CLUSTER,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,ALT_MOBILENO1,'
	SET @Strsql+='SHOP_OWNER_EMAIL2,VISITREMARKS,MEETINGREMARKS,MEETING_ADDRESS,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,TOTMETTING,SPENT_DURATION,DISTANCE_TRAVELLED,'
	--End of Rev 13.0
	SET @Strsql+='TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	--End of Rev 10.0
	--End of Rev 4.0
	--Rev 5.0
	--SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY LOGIN_DATETIME) AS SEQ,LOGIN_DATETIME,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,OFFICE_ADDRESS,ATTEN_STATUS,WORK_LEAVE_TYPE,EMPCODE,EMPNAME,EMPID,'
	--Rev 14.0
	--SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY LOGIN_DATETIME) AS SEQ,LOGIN_DATETIME,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,OFFICE_ADDRESS,ATTEN_STATUS,WORK_LEAVE_TYPE,REMARKS,EMPCODE,EMPNAME,EMPID,'
	SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY LOGIN_DATETIME) AS SEQ,LOGIN_DATETIME,LOGGEDIN,LOGEDOUT,CONTACTNO,STATEID,STATE,BRANCHDESC,OFFICE_ADDRESS,ATTEN_STATUS,'
	SET @Strsql+='WORK_LEAVE_TYPE,REMARKS,EMPCODE,EMPNAME,EMPID,'
	--End of Rev 14.0
	--End of Rev 5.0
	--End of Rev 3.0
	--Rev 10.0
	--SET @Strsql+='DEG_ID,DESIGNATION,DATEOFJOINING,REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,SHOPADDR_CONTACT,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,'
	--Rev 13.0
	--SET @Strsql+='DEG_ID,DESIGNATION,DATEOFJOINING,REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,ENTITYCODE,SHOPADDR_CONTACT,PP_NAME,PPADDR_CONTACT,DD_NAME,DDADDR_CONTACT,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,'
	SET @Strsql+='DEG_ID,DESIGNATION,DATEOFJOINING,REPORTTO,RPTTODESG,SHOP_TYPE,SHOP_CODE,SHOP_NAME,ENTITYCODE,SHOPADDR_CONTACT,SHOP_DISTRICT,SHOP_PINCODE,SHOP_CLUSTER,PP_NAME,PPADDR_CONTACT,DD_NAME,'
	--Rev 19.0
	--SET @Strsql+='DDADDR_CONTACT,VISITREMARKS,MEETINGREMARKS,MEETING_ADDRESS,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,TOTMETTING,'
	SET @Strsql+='DDADDR_CONTACT,ALT_MOBILENO1,SHOP_OWNER_EMAIL2,VISITREMARKS,MEETINGREMARKS,MEETING_ADDRESS,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,TOTMETTING,'
	--End of Rev 19.0
	--End of Rev 13.0
	--End of Rev 10.0
	--Rev 4.0
	--SET @Strsql+='Total_Order_Booked_Value,Total_Collection FROM( '
	--Rev 16.0
	--SET @Strsql+='DISTANCE_TRAVELLED,Total_Order_Booked_Value,Total_Collection FROM( '
	SET @Strsql+='SPENT_DURATION,DISTANCE_TRAVELLED,Total_Order_Booked_Value,Total_Collection FROM( '
	--End of Rev 16.0
	--End of Rev 4.0
	--Rev 13.0
	--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,'
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,'
	--End of Rev 13.0
	--Rev 14.0
	--SET @Strsql+='ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,USR.user_loginId AS CONTACTNO,'
	SET @Strsql+='ISNULL(ST.state,''State Undefined'') AS STATE,BR.branch_description AS BRANCHDESC,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,USR.user_loginId AS CONTACTNO,'
	--End of Rev 14.0
	--Rev 12.0
	--SET @Strsql+='RPTTO.REPORTTO,RPTTO.RPTTODESG,LOGIN_DATETIME,REPLACE(REPLACE(ATTEN.LOGGEDIN,''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,REPLACE(REPLACE(LOGEDOUT,''AM'','' AM''),''PM'','' PM'') AS LOGEDOUT,'
	SET @Strsql+='RPTTO.REPORTTO,RPTTO.RPTTODESG,LOGIN_DATETIME,ATTEN.LOGGEDIN AS LOGGEDIN,ATTEN.LOGEDOUT AS LOGEDOUT,'
	--End of Rev 12.0
	--Rev 3.0
	--SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,ATTEN_STATUS,SHOP.SHOP_TYPE,SHOP.Shop_Code,SHOP.Shop_Name,'
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,ATTEN_STATUS,'
	--Rev 15.0
	--SET @Strsql+='(SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(WRKACT.WrkActvtyDescription)) From tbl_fts_UserAttendanceLoginlogout AS ATTEN '
	--SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=ATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	--SET @Strsql+='INNER JOIN tbl_attendance_worktype ATTENWRKTYP ON ATTENWRKTYP.UserID=ATTEN.User_Id AND ATTEN.Id=ATTENWRKTYP.attendanceid '
	--SET @Strsql+='INNER JOIN tbl_FTS_WorkActivityList WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID '   
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	--SET @Strsql+='GROUP BY WRKACT.WrkActvtyDescription FOR XML PATH('''')), 1, 1, ''''),'''')) AS WORK_LEAVE_TYPE,'
	SET @Strsql+='(SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(WRKACT.WrkActvtyDescription)) From tbl_fts_UserAttendanceLoginlogout AS UATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=UATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	SET @Strsql+='INNER JOIN tbl_attendance_worktype ATTENWRKTYP ON ATTENWRKTYP.UserID=UATTEN.User_Id AND UATTEN.Id=ATTENWRKTYP.attendanceid '
	SET @Strsql+='INNER JOIN tbl_FTS_WorkActivityList WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID '   
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),UATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),UATTEN.Work_datetime,105) '
	SET @Strsql+='GROUP BY WRKACT.WrkActvtyDescription FOR XML PATH('''')), 1, 1, ''''),'''')) AS WORK_LEAVE_TYPE,'
	--End of Rev 15.0
	--Rev 5.0
	SET @Strsql+='REPLACE((SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(ISNULL(A.Work_Desc,''''))) From tbl_fts_UserAttendanceLoginlogout AS A '
	SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=A.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL AND A.Isonleave=''false'' AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),A.Work_datetime,105) '
	SET @Strsql+='FOR XML PATH('''')),1,1,''''),'''')),'','','''') AS REMARKS,'
	--End of Rev 5.0
	--Rev 9.0
	--SET @Strsql+='SHOP.SHOP_TYPE,SHOP.Shop_Code,SHOP.Shop_Name,'
	--Rev 10.0
	--SET @Strsql+='ISNULL(SHOP.SHOP_TYPE,''Meeting'') AS SHOP_TYPE,SHOP.Shop_Code,SHOP.Shop_Name,'
	SET @Strsql+='ISNULL(SHOP.SHOP_TYPE,''Meeting'') AS SHOP_TYPE,SHOP.Shop_Code,SHOP.Shop_Name,SHOP.ENTITYCODE,'
	--End of Rev 10.0
	--End of Rev 9.0
	--End of Rev 3.0
	--Rev 1.0
	--Rev 18.0
	--SET @Strsql+='SHOP.Address+'' ''+SHOP.Shop_Owner_Contact AS SHOPADDR_CONTACT,SHOPPP.Shop_Name AS PP_NAME,SHOPPP.Address+'' ''+SHOPPP.Shop_Owner_Contact AS PPADDR_CONTACT,'
	--Rev 19.0
	--SET @Strsql+='SHOP.Address+'' ''+SHOP.Shop_Owner_Contact AS SHOPADDR_CONTACT,SHOP.CITY_NAME AS SHOP_DISTRICT,SHOP.Pincode AS SHOP_PINCODE,SHOP.CLUSTER AS SHOP_CLUSTER,'
	--SET @Strsql+='SHOPPP.Shop_Name AS PP_NAME,SHOPPP.Address+'' ''+SHOPPP.Shop_Owner_Contact AS PPADDR_CONTACT,'
	SET @Strsql+='SHOP.Address+'' ''+SHOP.Shop_Owner_Contact AS SHOPADDR_CONTACT,SHOP.CITY_NAME AS SHOP_DISTRICT,SHOP.Pincode AS SHOP_PINCODE,SHOP.CLUSTER AS SHOP_CLUSTER,SHOP.ALT_MOBILENO1,'
	SET @Strsql+='SHOP.SHOP_OWNER_EMAIL2,SHOPPP.Shop_Name AS PP_NAME,SHOPPP.Address+'' ''+SHOPPP.Shop_Owner_Contact AS PPADDR_CONTACT,'
	--End of Rev 19.0
	--End of Rev 18.0
	--Rev 13.0
	--SET @Strsql+='SHOPDD.Shop_Name AS DD_NAME,SHOPDD.Address+'' ''+SHOPDD.Shop_Owner_Contact AS DDADDR_CONTACT,'
	SET @Strsql+='SHOPDD.Shop_Name AS DD_NAME,SHOPDD.Address+'' ''+SHOPDD.Shop_Owner_Contact AS DDADDR_CONTACT,SHOPACT.VISITREMARKS,SHOPACT.MEETINGREMARKS,SHOPACT.MEETING_ADDRESS,'
	--End of Rev 13.0
	--End of Rev 1.0
	--Rev 4.0
	--SET @Strsql+='ISNULL(SHOPACT.NEWSHOP_VISITED,0)+ISNULL(SHOPACT.RE_VISITED,0) AS TOTAL_VISIT,ISNULL(SHOPACT.NEWSHOP_VISITED,0) AS NEWSHOP_VISITED,ISNULL(SHOPACT.RE_VISITED,0) AS RE_VISITED,'
	--Rev 13.0
	--SET @Strsql+='ISNULL(SHOPACT.NEWSHOP_VISITED,0)+ISNULL(SHOPACT.RE_VISITED,0) AS TOTAL_VISIT,ISNULL(SHOPACT.NEWSHOP_VISITED,0) AS NEWSHOP_VISITED,ISNULL(SHOPACT.RE_VISITED,0) AS RE_VISITED,DISTANCE_TRAVELLED,'
	SET @Strsql+='ISNULL(SHOPACT.NEWSHOP_VISITED,0)+ISNULL(SHOPACT.RE_VISITED,0)+ISNULL(SHOPACT.TOTMETTING,0) AS TOTAL_VISIT,ISNULL(SHOPACT.NEWSHOP_VISITED,0) AS NEWSHOP_VISITED,'
	--Rev 16.0
	--SET @Strsql+='ISNULL(SHOPACT.RE_VISITED,0) AS RE_VISITED,ISNULL(SHOPACT.TOTMETTING,0) AS TOTMETTING,DISTANCE_TRAVELLED,'
	SET @Strsql+='ISNULL(SHOPACT.RE_VISITED,0) AS RE_VISITED,ISNULL(SHOPACT.TOTMETTING,0) AS TOTMETTING,SPENT_DURATION,DISTANCE_TRAVELLED,'
	--End of Rev 16.0
	--End of Rev 13.0
	--End of Rev 4.0
	SET @Strsql+='ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	--Rev 14.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	--End of Rev 14.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	--Rev 17.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT EMPHR ON EMPHR.EMPCODE=CNT.cnt_internalId '
		END
	--End of Rev 17.0
	--Rev 1.0
	--SET @Strsql+='INNER JOIN ('
	--SET @Strsql+='SELECT DISTINCT Shop_Code,Shop_CreateUser,Shop_Name,Address,Shop_Owner_Contact,assigned_to_pp_id,assigned_to_dd_id,CONVERT(NVARCHAR(10),Shop_CreateTime,105) AS Shop_CreateTime FROM tbl_Master_shop '
	--SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id '
	--SET @Strsql+='LEFT OUTER JOIN('
	--SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact FROM tbl_Master_shop A '
	--SET @Strsql+=') SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '
	--SET @Strsql+='LEFT OUTER JOIN( '
	--SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact FROM tbl_Master_shop A '
	--SET @Strsql+=') SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	--End of Rev 1.0
	SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	--Rev 6.0
	--SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	--End of Rev 6.0
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	--Rev 6.0
	--SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	--End of Rev 6.0
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	--Rev 1.0
	--SET @Strsql+='LEFT OUTER JOIN ( '
	--SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,SUM(NEWSHOP_VISITED) AS NEWSHOP_VISITED,SUM(RE_VISITED) AS RE_VISITED,VISITED_TIME FROM( '
	--SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,COUNT(SHOPACT.total_visit_count) AS NEWSHOP_VISITED,0 AS RE_VISITED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time FROM tbl_trans_shopActivitysubmit SHOPACT '
	--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @Strsql+='AND SHOPACT.Is_Newshopadd=1 '
	--SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.visited_time '
	--SET @Strsql+='UNION ALL '
	--SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.total_visit_count) AS RE_VISITED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time FROM tbl_trans_shopActivitysubmit SHOPACT '
	--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @Strsql+='AND SHOPACT.Is_Newshopadd=0 '
	--SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.visited_time '
	--SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId,Shop_Id,VISITED_TIME) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND SHOP.Shop_Code=SHOPACT.Shop_Id '
	--End of Rev 1.0
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,ATTEN_STATUS FROM( '
	--Rev 12.0
	--SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(15),CAST(ATTEN.Login_datetime as TIME),100)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	--End of Rev 12.0
	SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' ELSE ''On Leave'' END AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '
	SET @Strsql+='UNION ALL '
	--Rev 12.0
	--SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(15),CAST(ATTEN.Logout_datetime as TIME),100)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	--End of Rev 12.0
	SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' ELSE ''On Leave'' END AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
	SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '
	SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,ATTEN_STATUS) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '	
	--Rev 1.0
	--SET @Strsql+='AND ATTEN.USERID=SHOPACT.User_Id AND ATTEN.Login_datetime=SHOPACT.visited_time AND ATTEN.Login_datetime IS NOT NULL '
	SET @Strsql+='AND ATTEN.USERID=USR.user_id '
	--SET @Strsql+='LEFT OUTER JOIN ('
	--SET @Strsql+='SELECT DISTINCT Shop_Code,Shop_CreateUser,Shop_Name,Address,Shop_Owner_Contact,assigned_to_pp_id,assigned_to_dd_id,CONVERT(NVARCHAR(10),Shop_CreateTime,105) AS Shop_CreateTime FROM tbl_Master_shop '
	--SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id AND ATTEN.Login_datetime=SHOP.Shop_CreateTime '
	--SET @Strsql+='LEFT OUTER JOIN('
	--SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact FROM tbl_Master_shop A '
	--SET @Strsql+=') SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '
	--SET @Strsql+='LEFT OUTER JOIN( '
	--SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact FROM tbl_Master_shop A '
	--SET @Strsql+=') SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	--End of Rev 1.0
	SET @Strsql+='LEFT OUTER JOIN ( '
	--Rev 4.0
	--SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,SUM(NEWSHOP_VISITED) AS NEWSHOP_VISITED,SUM(RE_VISITED) AS RE_VISITED,VISITED_TIME FROM( '
	--Rev 13.0
	--SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,SUM(NEWSHOP_VISITED) AS NEWSHOP_VISITED,SUM(RE_VISITED) AS RE_VISITED,SUM(DISTANCE_TRAVELLED) AS DISTANCE_TRAVELLED,VISITED_TIME FROM( '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,SUM(NEWSHOP_VISITED) AS NEWSHOP_VISITED,SUM(RE_VISITED) AS RE_VISITED,SUM(TOTMETTING) AS TOTMETTING,SPENT_DURATION,'
	SET @Strsql+='SUM(DISTANCE_TRAVELLED) AS DISTANCE_TRAVELLED,VISITED_TIME,VISITREMARKS,MEETINGREMARKS,MEETING_ADDRESS FROM('
	--End of Rev 13.0
	--End of Rev 4.0
	--Rev 2.0
	--SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,COUNT(SHOPACT.total_visit_count) AS NEWSHOP_VISITED,0 AS RE_VISITED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time FROM tbl_trans_shopActivitysubmit SHOPACT '
	--Rev 4.0
	--SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,COUNT(SHOPACT.Shop_Id) AS NEWSHOP_VISITED,0 AS RE_VISITED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time '
	--Rev 13.0
	--SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,COUNT(SHOPACT.Shop_Id) AS NEWSHOP_VISITED,0 AS RE_VISITED,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,'
	--SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,COUNT(SHOPACT.Shop_Id) AS NEWSHOP_VISITED,0 AS RE_VISITED,0 AS TOTMETTING,SPENT_DURATION,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,'
	SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time,SHOPACT.REMARKS AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS MEETING_ADDRESS '
	--End of Rev 13.0
	--End of Rev 4.0
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	--End of Rev 2.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND SHOPACT.Is_Newshopadd=1 '
	--Rev 13.0
	--SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.visited_time '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.visited_time,SHOPACT.SPENT_DURATION,SHOPACT.REMARKS '
	--End of Rev 13.0
	SET @Strsql+='UNION ALL '
	--Rev 2.0
	--SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.total_visit_count) AS RE_VISITED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time FROM tbl_trans_shopActivitysubmit SHOPACT '
	--Rev 4.0
	--SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.Shop_Id) AS RE_VISITED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time '
	--Rev 13.0
	--SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.Shop_Id) AS RE_VISITED,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,'
	--SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.Shop_Id) AS RE_VISITED,0 AS TOTMETTING,SPENT_DURATION,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,'
	SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time,SHOPACT.REMARKS AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS MEETING_ADDRESS '
	--End of Rev 13.0
	--End of Rev 4.0
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	--End of Rev 2.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--Rev 13.0
	--SET @Strsql+='AND SHOPACT.Is_Newshopadd=0 '	
	--SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.visited_time '
	SET @Strsql+='AND SHOPACT.Is_Newshopadd=0 AND SHOPACT.ISMEETING=0 '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.visited_time,SHOPACT.SPENT_DURATION,SHOPACT.REMARKS '
	--MEETING
	SET @Strsql+='UNION ALL '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,0 AS RE_VISITED,COUNT(SHOPACT.Shop_Id) AS TOTMETTING,SPENT_DURATION,0 AS DISTANCE_TRAVELLED,'
	SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS visited_time,'''' AS VISITREMARKS,SHOPACT.REMARKS AS MEETINGREMARKS,SHOPACT.MEETING_ADDRESS '
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND SHOPACT.ISMEETING=1 AND SHOPACT.MEETING_TYPEID IS NOT NULL '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,SHOPACT.visited_time,SHOPACT.SPENT_DURATION,SHOPACT.REMARKS,SHOPACT.MEETING_ADDRESS '
	--End of Rev 13.0
	--Rev 2.0
	--SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId,Shop_Id,VISITED_TIME) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '--AND SHOP.Shop_Code=SHOPACT.Shop_Id '
	--Rev 13.0
	--SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId,Shop_Id,VISITED_TIME) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=SHOPACT.VISITED_TIME '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId,Shop_Id,VISITED_TIME,VISITREMARKS,SPENT_DURATION,MEETINGREMARKS,MEETING_ADDRESS) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
	SET @Strsql+='AND ATTEN.Login_datetime=SHOPACT.VISITED_TIME '
	--End of Rev 13.0
	--End of Rev 2.0
	--Rev 1.0
	SET @Strsql+='LEFT OUTER JOIN ('
	--Rev 7.0
	--SET @Strsql+='SELECT DISTINCT Shop_Code,Shop_CreateUser,Shop_Name,Address,Shop_Owner_Contact,assigned_to_pp_id,assigned_to_dd_id,CONVERT(NVARCHAR(10),Shop_CreateTime,105) AS Shop_CreateTime,Type, '
	SET @Strsql+='SELECT DISTINCT shop.Shop_Code,shop.Shop_CreateUser,shop.Shop_Name,shop.Address,shop.Shop_Owner_Contact,shop.assigned_to_pp_id,shop.assigned_to_dd_id,shop.Type, '
	--Rev 10.0
	SET @Strsql+='shop.EntityCode,'
	--End of Rev 10.0
	--End of Rev 7.0
	--Rev 8.0
	--SET @Strsql+='CASE WHEN TYPE=1 THEN ''Shop'' WHEN TYPE=2 THEN ''PP'' WHEN TYPE=3 THEN ''New Party'' WHEN TYPE=4 THEN ''DD'' END AS SHOP_TYPE '
	--Rev 9.0
	--SET @Strsql+='CASE WHEN TYPE=1 THEN ''Shop'' WHEN TYPE=2 THEN ''PP'' WHEN TYPE=3 THEN ''New Party'' WHEN TYPE=4 THEN ''DD'' WHEN TYPE=5 THEN ''Diamond'' END AS SHOP_TYPE '
	--Rev 20.0 && A new TYPE has been added as "Lead".
	SET @Strsql+='CASE WHEN shop.TYPE=1 THEN ''Shop'' WHEN shop.TYPE=2 THEN ''PP'' WHEN shop.TYPE=3 THEN ''New Party'' WHEN shop.TYPE=4 THEN ''DD'' WHEN shop.TYPE=5 THEN ''Diamond'' '
	SET @Strsql+='WHEN shop.TYPE=6 THEN ''Stockist'' WHEN shop.TYPE=7 THEN ''Chemist'' WHEN shop.TYPE=8 THEN ''Doctor'' WHEN shop.TYPE=16 THEN ''Lead'' WHEN shop.TYPE=999 THEN ''Meeting'' END AS SHOP_TYPE,'
	--Rev 18.0
	SET @Strsql+='shop.Pincode,CITY.CITY_NAME,shop.CLUSTER,'
	--End of Rev 18.0
	--Rev 19.0
	SET @Strsql+='shop.Alt_MobileNo1,shop.Shop_Owner_Email2 '
	--End of Rev 19.0
	--End of Rev 9.0
	--End of Rev 8.0
	SET @Strsql+='FROM tbl_Master_shop shop '
	--Rev 18.0
	SET @Strsql+='LEFT OUTER JOIN TBL_MASTER_CITY CITY ON shop.Shop_City=CITY.city_id '
	--End of Rev 18.0
	--Rev 11.0
	--SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id AND SHOP.Shop_Code=SHOPACT.Shop_Id '
	IF @isRevisitTeamDetail='1'
		SET @Strsql+=') SHOP ON SHOP.Shop_Code=SHOPACT.Shop_Id '
	ELSE IF @isRevisitTeamDetail='0'
		SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id AND SHOP.Shop_Code=SHOPACT.Shop_Id '
	--End of Rev 11.0
	SET @Strsql+='LEFT OUTER JOIN('
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '
	SET @Strsql+='LEFT OUTER JOIN( '
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A '
	SET @Strsql+=') SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	--End of Rev 1.0
	SET @Strsql+='LEFT OUTER JOIN (SELECT ORDH.userID,ORDH.SHOP_CODE,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue,CONVERT(NVARCHAR(10),ORDH.Orderdate,105) AS ORDDATE FROM tbl_trans_fts_Orderupdate ORDH '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY ORDH.userID,ORDH.SHOP_CODE,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ORDH.Orderdate,105)) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=ORDHEAD.ORDDATE AND ORDHEAD.SHOP_CODE=SHOP.SHOP_CODE '
	SET @Strsql+='LEFT OUTER JOIN (SELECT COLLEC.user_id,COLLEC.shop_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue,CONVERT(NVARCHAR(10),COLLEC.collection_date,105) AS collection_date FROM tbl_FTS_collection COLLEC '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY COLLEC.user_id,COLLEC.shop_id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),COLLEC.collection_date,105)) COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=COLLEC.collection_date AND COLLEC.shop_id=SHOP.SHOP_CODE '
	--Rev 3.0
	SET @Strsql+='UNION ALL '
	--Rev 13.0
	--SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ISNULL(ST.ID,0) AS STATEID,'
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,'
	--End of Rev 13.0
	--Rev 14.0
	--SET @Strsql+='ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,USR.user_loginId AS CONTACTNO,'
	SET @Strsql+='ISNULL(ST.state,''State Undefined'') AS STATE,'''' AS BRANCHDESC,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	SET @Strsql+='USR.user_loginId AS CONTACTNO,'
	--End of Rev 14.0
	--Rev 12.0
	--SET @Strsql+='RPTTO.REPORTTO,RPTTO.RPTTODESG,LOGIN_DATETIME,REPLACE(REPLACE(LOGGEDIN,''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,REPLACE(REPLACE(LOGEDOUT,''AM'','' AM''),''PM'','' PM'') AS LOGEDOUT,'
	SET @Strsql+='RPTTO.REPORTTO,RPTTO.RPTTODESG,LOGIN_DATETIME,ATTEN.LOGGEDIN AS LOGGEDIN,ATTEN.LOGEDOUT AS LOGEDOUT,'
	--End of Rev 12.0
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,ATTEN_STATUS,'
	--Rev 15.0
	--SET @Strsql+='(SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(LTYP.LeaveType)) From tbl_fts_UserAttendanceLoginlogout AS ATTEN '
	--SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=ATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	--SET @Strsql+='INNER JOIN tbl_FTS_Leavetype LTYP ON LTYP.Leave_Id=ATTEN.Leave_Type '
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' '
	--SET @Strsql+='GROUP BY LTYP.LeaveType FOR XML PATH('''')), 1, 1, ''''),'''')) AS WORK_LEAVE_TYPE,'
	SET @Strsql+='(SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(LTYP.LeaveType)) From tbl_fts_UserAttendanceLoginlogout AS UATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=UATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	SET @Strsql+='INNER JOIN tbl_FTS_Leavetype LTYP ON LTYP.Leave_Id=UATTEN.Leave_Type '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),UATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),UATTEN.Work_datetime,105) '
	SET @Strsql+='GROUP BY LTYP.LeaveType FOR XML PATH('''')), 1, 1, ''''),'''')) AS WORK_LEAVE_TYPE,'
	--End of Rev 15.0
	--Rev 5.0
	SET @Strsql+=''''' AS REMARKS,'
	--End of Rev 5.0
	--Rev 10.0
	--SET @Strsql+=''''' AS SHOP_TYPE,'''' AS Shop_Code,'''' AS Shop_Name,'''' AS SHOPADDR_CONTACT,'''' AS PP_NAME,'''' AS PPADDR_CONTACT,'''' AS DD_NAME,'''' AS DDADDR_CONTACT,0 AS TOTAL_VISIT,0 AS NEWSHOP_VISITED,0 AS RE_VISITED,'
	--Rev 13.0
	--SET @Strsql+=''''' AS SHOP_TYPE,'''' AS Shop_Code,'''' AS Shop_Name,'''' AS EntityCode,'''' AS SHOPADDR_CONTACT,'''' AS PP_NAME,'''' AS PPADDR_CONTACT,'''' AS DD_NAME,'''' AS DDADDR_CONTACT,'
	--SET @Strsql+='0 AS TOTAL_VISIT,0 AS NEWSHOP_VISITED,0 AS RE_VISITED,'
	--Rev 18.0
	--SET @Strsql+=''''' AS SHOP_TYPE,'''' AS Shop_Code,'''' AS Shop_Name,'''' AS EntityCode,'''' AS SHOPADDR_CONTACT,'''' AS PP_NAME,'''' AS PPADDR_CONTACT,'''' AS DD_NAME,'''' AS DDADDR_CONTACT,'
	--Rev 19.0
	--SET @Strsql+=''''' AS SHOP_TYPE,'''' AS Shop_Code,'''' AS Shop_Name,'''' AS EntityCode,'''' AS SHOPADDR_CONTACT,'''' AS SHOP_DISTRICT,'''' AS SHOP_PINCODE,'''' AS SHOP_CLUSTER,'''' AS PP_NAME,'
	--SET @Strsql+=''''' AS PPADDR_CONTACT,'''' AS DD_NAME,'''' AS DDADDR_CONTACT,'
	SET @Strsql+=''''' AS SHOP_TYPE,'''' AS Shop_Code,'''' AS Shop_Name,'''' AS EntityCode,'''' AS SHOPADDR_CONTACT,'''' AS SHOP_DISTRICT,'''' AS SHOP_PINCODE,'''' AS SHOP_CLUSTER,'''' AS ALT_MOBILENO1,'
	SET @Strsql+=''''' AS Shop_Owner_Email2,'''' AS PP_NAME,'''' AS PPADDR_CONTACT,'''' AS DD_NAME,'''' AS DDADDR_CONTACT,'
	--End of Rev 19.0
	--End of Rev 18.0
	SET @Strsql+=''''' AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS MEETING_ADDRESS,0 AS TOTAL_VISIT,0 AS NEWSHOP_VISITED,0 AS RE_VISITED,0 AS TOTMETTING,'
	--End of Rev 13.0
	--End of Rev 10.0
	--Rev 4.0
	--SET @Strsql+='0.00 AS Total_Order_Booked_Value,0.00 AS Total_Collection '
	--Rev 16.0 && A new field added as SPENT_DURATION
	SET @Strsql+='NULL AS SPENT_DURATION,0.00 AS DISTANCE_TRAVELLED,0.00 AS Total_Order_Booked_Value,0.00 AS Total_Collection '
	--End of Rev 4.0
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	--Rev 14.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	--End of Rev 14.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	--Rev 6.0
	--SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	--End of Rev 6.0
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	--Rev 6.0
	--SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	--End of Rev 6.0
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,ATTEN_STATUS FROM( '
	--Rev 12.0
	--SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(15),CAST(ATTEN.Login_datetime as TIME),100)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	--End of Rev 12.0
	SET @Strsql+='''On Leave'' AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) '
	SET @Strsql+='UNION ALL '
	--Rev 12.0
	--SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(15),CAST(ATTEN.Logout_datetime as TIME),100)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	--End of Rev 12.0
	SET @Strsql+='''On Leave'' AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''true'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) '
	SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,ATTEN_STATUS) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	--End of Rev 3.0
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

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	--End of Rev 4.0
	SET NOCOUNT OFF
END