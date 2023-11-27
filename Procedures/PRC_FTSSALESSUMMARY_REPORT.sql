--EXEC PRC_FTSSALESSUMMARY_REPORT '2021-09-20','2021-09-20','','','',11706

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSSALESSUMMARY_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSSALESSUMMARY_REPORT] AS' 
END
GO


ALTER PROCEDURE [dbo].[PRC_FTSSALESSUMMARY_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT,
--Rev 14.0
@BRANCHID NVARCHAR(MAX)=NULL
--Rev 14.0 End
)  
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 30/11/2018
Module	   : Sales Report - Summary
1.0		v2.0.0		Debashis	17/01/2019		Employee Summary was not matching for date wise.Now solved.Refer: Fwd: Shop visited count showing wrong.
2.0		v2.0.0		Debashis	25/01/2019		Post Login we have to check in with At work or On Leave for attendance & “Work Type” need work type column in Employee 
												Summary report.(Field Work, Meeting & Others).Refer: FSM - Features & Issues # Karuna Group
3.0		v8.0.0		Debashis	06/02/2019		Employee Summary - New column [Idle Time] -total idle time. Refer: HIGH PRIORITY
4.0		v13.0.0		Debashis	12/02/2019		Idle Time showing wrong.Now solved.
5.0		v13.0.0		Debashis	12/02/2019		Required Total Idle time with count. Refer: Employee Summary
6.0		v19.0.0		Debashis	27/02/2019		From Last Login to Last Logout, if calculated hrs is less then 9 (hrs), to he shown in Employee Summary Report, in a new 
												column  after "Working Duration" as "Undertime(hrs)" = Value of (9 hrs(-) Less Total Working duration column value). 
												Do not show value calculated in Negative(-).Refer mail: (no subject)
7.0		v20.0.0		Debashis	29/03/2019		"On Leave" showing wrong value.Now it has been rectified.
8.0					Tanmoy		08/05/2019		Employee Id add
9.0		v27.0.0		Debashis	21/05/2019		Should also check data based on From and Todate to consider Leave Data from Fields of the related Tables and 
												the fields Attendance Type : Should consider leave and show as : On Leave,Work/Leave Type : Should show the type like 
												'Casual' or 'Sick' etc. as the data found. Refer: Fwd: Multi day Leave In App
10.0	v2.0.13		Debashis	24/06/2020		Branch column required in the various FSM reports.Refer: 0022610
11.0	v2.0.14		Debashis	02/07/2020		Employee Summary & Performance Summary - full month data showing all type 'At Work' in output.Now solved.Refer: 0022640
12.0	v2.0.24		TANMOY		29/07/2021		Employee hierarchy  WISE FILTER
13.0	v2.0.25		Sanchita	20/09/2021		Hierarchy not working when Select All taken
14.0	V2.0.42		Priti	    20/07/2023      Branch Parameter is required for various FSM reports.Refer:0026135
15.0	V2.0.43		Sanchita	27/11/2023		An error is showing while trying to generate Employee Summary Report when both Branch and State 
												are selected. Mantis: 27042
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

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
			--Rev 10.0
			cnt_branchid INT,
			--End of Rev 10.0
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	--Rev 10.0
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	--End of Rev 10.0

	--Rev 14.0
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
	  --Rev 14.0 End

	--Rev 12.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
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
	--End of Rev 12.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSSALESSUMMARY_REPORT') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTSSALESSUMMARY_REPORT
		(
		  USERID INT,
		  SEQ INT,
		  USER_LOGINID NVARCHAR(50),
		  EMPCODE NVARCHAR(100) NULL,
		  EMPNAME NVARCHAR(300) NULL,
		  STATEID INT,
		  STATE NVARCHAR(50) NULL,
		  --Rev 10.0
		  BRANCHDESC NVARCHAR(300),
		  --End of Rev 10.0
		  DEG_ID INT,
		  DESIGNATION NVARCHAR(50) NULL,
		  ATTEN_STATUS NVARCHAR(10),
		  --Rev 2.0
		  WORK_LEAVE_TYPE NVARCHAR(2000) NULL,
		  --End of Rev 2.0
		  REPORTTO NVARCHAR(300) NULL,
		  LOGGEDIN NVARCHAR(100) NULL,
		  LOGEDOUT NVARCHAR(100) NULL,
		  TOTAL_HRS_WORKED NVARCHAR(50) NULL,
		  --Rev 6.0
		  UNDERTIME NVARCHAR(50) NULL,
		  --End of Rev 6.0
		  GPS_INACTIVE_DURATION NVARCHAR(50) NULL,
		  --Rev 3.0
		  IDEAL_TIME NVARCHAR(50) NULL,
		  --End of Rev 3.0
		  --Rev 5.0
		  IDEALTIME_CNT INT,
		  --End of Rev 5.0
		  SHOPS_VISITED INT,
		  TOTAL_ORDER_BOOKED_VALUE DECIMAL(38,2),
		  TOTAL_COLLECTION DECIMAL(38,2),
		  Employee_ID NVARCHAR(100) NULL
		)
		CREATE NONCLUSTERED INDEX IX1 ON FTSSALESSUMMARY_REPORT (SEQ)
	END
	DELETE FROM FTSSALESSUMMARY_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	--Rev 2.0
	--SET @Strsql='INSERT INTO FTSSALESSUMMARY_REPORT(USERID,SEQ,USER_LOGINID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,ATTEN_STATUS,REPORTTO,LOGGEDIN,LOGEDOUT,TOTAL_HRS_WORKED,GPS_INACTIVE_DURATION,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	--SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY EMPCODE) AS SEQ,USER_LOGINID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,ATTEN_STATUS,REPORTTO,LOGGEDIN,LOGEDOUT,'
	--Rev 10.0
	--SET @Strsql='INSERT INTO FTSSALESSUMMARY_REPORT(USERID,SEQ,USER_LOGINID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,ATTEN_STATUS,WORK_LEAVE_TYPE,REPORTTO,LOGGEDIN,LOGEDOUT,TOTAL_HRS_WORKED,'
	SET @Strsql='INSERT INTO FTSSALESSUMMARY_REPORT(USERID,SEQ,USER_LOGINID,EMPCODE,EMPNAME,STATEID,STATE,BRANCHDESC,DEG_ID,DESIGNATION,ATTEN_STATUS,WORK_LEAVE_TYPE,REPORTTO,LOGGEDIN,LOGEDOUT,TOTAL_HRS_WORKED,'
	--End of Rev 10.0
	--Rev 3.0
	--SET @Strsql+='GPS_INACTIVE_DURATION,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	--Rev 5.0
	--SET @Strsql+='GPS_INACTIVE_DURATION,IDEAL_TIME,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	--Rev 6.0
	--SET @Strsql+='GPS_INACTIVE_DURATION,IDEAL_TIME,IDEALTIME_CNT,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	SET @Strsql+='UNDERTIME,GPS_INACTIVE_DURATION,IDEAL_TIME,IDEALTIME_CNT,SHOPS_VISITED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION,Employee_ID) '
	--End of Rev 6.0
	--End of Rev 5.0
	--End of Rev 3.0
	--Rev 10.0
	--SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY EMPCODE) AS SEQ,USER_LOGINID,EMPCODE,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,ATTEN_STATUS,WORK_LEAVE_TYPE,REPORTTO,LOGGEDIN,LOGEDOUT,'
	SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY EMPCODE) AS SEQ,USER_LOGINID,EMPCODE,EMPNAME,STATEID,STATE,BRANCHDESC,DEG_ID,DESIGNATION,ATTEN_STATUS,WORK_LEAVE_TYPE,REPORTTO,'
	SET @Strsql+='LOGGEDIN,LOGEDOUT,'
	--End of Rev 10.0
	--End of Rev 2.0
	SET @Strsql+='CASE WHEN Total_Hrs_Worked>0 THEN RIGHT(''0'' + CAST(CAST(Total_Hrs_Worked AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(Total_Hrs_Worked AS VARCHAR) % 60 AS VARCHAR),2) ELSE ''Not Logged out'' END AS Total_Hrs_Worked,'
	--Rev 6.0
	SET @Strsql+='CASE WHEN WORK_TIME>0 THEN RIGHT(''0'' + CAST(CAST(WORK_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(WORK_TIME AS VARCHAR) % 60 AS VARCHAR),2) ELSE ''0'' END AS WORK_TIME,'
	--End of Rev 6.0
	SET @Strsql+='RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(GPS_Inactive_duration AS VARCHAR) % 60 AS VARCHAR),2) AS GPS_Inactive_duration,'
	--Rev 3.0
	SET @Strsql+='RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR) % 60 AS VARCHAR),2) AS IDEAL_TIME,'
	--End of Rev 3.0
	--Rev 5.0
	SET @Strsql+='IDEAL_TIME/30 AS IDEALTIME_CNT,'
	--End of Rev 5.0
	--Rev 7.0
	--SET @Strsql+='Shops_Visited,Total_Order_Booked_Value,Total_Collection FROM( '
	SET @Strsql+='CASE WHEN ATTEN_STATUS=''At Work'' THEN Shops_Visited ELSE 0 END AS Shops_Visited,CASE WHEN ATTEN_STATUS=''At Work'' THEN Total_Order_Booked_Value ELSE 0.00 END AS Total_Order_Booked_Value,'
	SET @Strsql+='CASE WHEN ATTEN_STATUS=''At Work'' THEN Total_Collection ELSE 0.00 END AS Total_Collection,Employee_ID FROM( '
	--End of Rev 7.0
	--Rev 10.0
	--SET @Strsql+='SELECT USR.USER_LOGINID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,CNT.cnt_UCC as Employee_ID,ST.ID AS STATEID,ST.state AS STATE,'
	SET @Strsql+='SELECT USR.USER_LOGINID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='CNT.cnt_UCC as Employee_ID,ST.ID AS STATEID,ST.state AS STATE,BR.branch_description AS BRANCHDESC,'
	--End of Rev 10.0
	--Rev 2.0
	--SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,ATTEN.ATTEN_STATUS,RPTTO.REPORTTO,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT,'
	SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,ATTEN.ATTEN_STATUS,BR.branch_id,'
	--Rev 11.0
	--SET @Strsql+='CASE WHEN ATTEN.ATTEN_STATUS=''At Work'' THEN (SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(WRKACT.WrkActvtyDescription)) From tbl_fts_UserAttendanceLoginlogout AS ATTEN '
	--SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=ATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	--SET @Strsql+='INNER JOIN tbl_attendance_worktype ATTENWRKTYP ON ATTENWRKTYP.UserID=ATTEN.User_Id AND ATTEN.Id=ATTENWRKTYP.attendanceid '
	--SET @Strsql+='INNER JOIN tbl_FTS_WorkActivityList WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID '   
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	--SET @Strsql+='GROUP BY WRKACT.WrkActvtyDescription FOR XML PATH('''')), 1, 1, ''''),'''')) '
	--SET @Strsql+='WHEN ATTEN.ATTEN_STATUS=''On Leave'' THEN (SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(LTYP.LeaveType)) From tbl_fts_UserAttendanceLoginlogout AS ATTEN '
	--SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=ATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	--SET @Strsql+='INNER JOIN tbl_FTS_Leavetype LTYP ON LTYP.Leave_Id=ATTEN.Leave_Type '
	----Rev 9.0
	----SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODATE+''',120) BETWEEN CONVERT(NVARCHAR(10),ATTEN.Leave_FromDate,120) AND CONVERT(NVARCHAR(10),ATTEN.Leave_ToDate,120) '
	----End of Rev 9.0
	--SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' '
	--SET @Strsql+='GROUP BY LTYP.LeaveType FOR XML PATH('''')), 1, 1, ''''),'''')) END AS WORK_LEAVE_TYPE,'
	SET @Strsql+='CASE WHEN ATTEN.ATTEN_STATUS=''At Work'' THEN (SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(WRKACT.WrkActvtyDescription)) From tbl_fts_UserAttendanceLoginlogout AS UATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=UATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON MUSR.user_contactId=TMP.EMPCODE '
		END
	SET @Strsql+='INNER JOIN tbl_attendance_worktype ATTENWRKTYP ON ATTENWRKTYP.UserID=UATTEN.User_Id AND UATTEN.Id=ATTENWRKTYP.attendanceid '
	SET @Strsql+='INNER JOIN tbl_FTS_WorkActivityList WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID '   
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),UATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' AND CONVERT(NVARCHAR(10),ATTEN.LOGGEDIN,105)=CONVERT(NVARCHAR(10),UATTEN.Work_datetime,105) '
	SET @Strsql+='GROUP BY WRKACT.WrkActvtyDescription FOR XML PATH('''')), 1, 1, ''''),'''')) '
	SET @Strsql+='WHEN ATTEN.ATTEN_STATUS=''On Leave'' THEN (SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(LTYP.LeaveType)) From tbl_fts_UserAttendanceLoginlogout AS UATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=UATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON MUSR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='INNER JOIN tbl_FTS_Leavetype LTYP ON LTYP.Leave_Id=UATTEN.Leave_Type '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODATE+''',120) BETWEEN CONVERT(NVARCHAR(10),UATTEN.Leave_FromDate,120) AND CONVERT(NVARCHAR(10),UATTEN.Leave_ToDate,120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' AND CONVERT(NVARCHAR(10),ATTEN.LOGEDOUT,105)=CONVERT(NVARCHAR(10),UATTEN.Work_datetime,105) '
	SET @Strsql+='GROUP BY LTYP.LeaveType FOR XML PATH('''')), 1, 1, ''''),'''')) END AS WORK_LEAVE_TYPE,'
	--End of Rev 11.0
	SET @Strsql+='RPTTO.REPORTTO,ATTEN.LOGGEDIN,ATTEN.LOGEDOUT,'
	--End of Rev 2.0
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS Total_Hrs_Worked,'
	--Rev 6.0
	SET @Strsql+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)>0 THEN '
	SET @Strsql+='ATTEN.WORK_TIME-(CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)) ELSE '
	SET @Strsql+='ATTEN.WORK_TIME-(CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(''23:59:00'',''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(''23:59:00'',''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @Strsql+='- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)) END AS WORK_TIME,'
	--End of Rev 6.0
	--Rev 1.0
	--SET @Strsql+='ISNULL(GPSSM.GPS_Inactive_duration,0) AS GPS_Inactive_duration,ISNULL(SHOPACT.shop_visited,0) AS Shops_Visited,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
	--Rev 3.0
	--SET @Strsql+='ISNULL(GPSSM.GPS_Inactive_duration,0) AS GPS_Inactive_duration,CASE WHEN ATTEN.ATTEN_STATUS=''At Work'' THEN ISNULL(SHOPACT.shop_visited,0) ELSE 0 END AS Shops_Visited,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
	SET @Strsql+='ISNULL(GPSSM.GPS_Inactive_duration,0) AS GPS_Inactive_duration,IDEALLOACTION.IDEAL_TIME,'
	SET @Strsql+='CASE WHEN ATTEN.ATTEN_STATUS=''At Work'' THEN ISNULL(SHOPACT.shop_visited,0) ELSE 0 END AS Shops_Visited,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
	--End of Rev 3.0
	--End of Rev 1.0
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	--Rev 10.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	--End of Rev 10.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
	SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	--Rev 6.0
	--SET @Strsql+='LEFT OUTER JOIN (SELECT ATTEN.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT,CNT.cnt_internalId, '
	--Rev 9.0
	--SET @Strsql+='LEFT OUTER JOIN (SELECT ATTEN.User_Id AS USERID,MIN(ATTEN.Login_datetime) AS LOGGEDIN,MAX(ATTEN.Logout_datetime) AS LOGEDOUT,CNT.cnt_internalId,MAX(EMPWHD.WORK_TIME) AS WORK_TIME, '
	----End of Rev 6.0
	--SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' ELSE ''On Leave'' END ATTEN_STATUS '
	--SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	----Rev 6.0
	--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=CNT.cnt_internalId '
	--SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
	--SET @Strsql+='INNER JOIN('
	--SET @Strsql+='SELECT DISTINCT hourId,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EndTime),''00:00:00'')) * 60) AS FLOAT) + '
	--SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(EndTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - '
	--SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(BeginTime),''00:00:00'')) * 60) AS FLOAT) + '
	--SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS WORK_TIME FROM tbl_EmpWorkingHoursDetails GROUP BY hourId) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
	----End of Rev 6.0
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT USERID,LOGGEDIN,LOGEDOUT,cnt_internalId,WORK_TIME,ATTEN_STATUS FROM('
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(ATTEN.Login_datetime) AS LOGGEDIN,MAX(ATTEN.Logout_datetime) AS LOGEDOUT,CNT.cnt_internalId,MAX(EMPWHD.WORK_TIME) AS WORK_TIME,''At Work'' AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
	SET @Strsql+='INNER JOIN('
	SET @Strsql+='SELECT DISTINCT hourId,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EndTime),''00:00:00'')) * 60) AS FLOAT) + '
	SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(EndTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - '
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(BeginTime),''00:00:00'')) * 60) AS FLOAT) + '
	SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS WORK_TIME FROM tbl_EmpWorkingHoursDetails GROUP BY hourId) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND ATTEN.Isonleave=''false'' '
	SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(ATTEN.Login_datetime) AS LOGGEDIN,MAX(ATTEN.Logout_datetime) AS LOGEDOUT,CNT.cnt_internalId,MAX(EMPWHD.WORK_TIME) AS WORK_TIME,''On Leave'' AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
	SET @Strsql+='INNER JOIN('
	SET @Strsql+='SELECT DISTINCT hourId,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EndTime),''00:00:00'')) * 60) AS FLOAT) + '
	SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(EndTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - '
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(BeginTime),''00:00:00'')) * 60) AS FLOAT) + '
	SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS WORK_TIME FROM tbl_EmpWorkingHoursDetails GROUP BY hourId) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODATE+''',120) BETWEEN CONVERT(NVARCHAR(10),ATTEN.Leave_FromDate,120) AND CONVERT(NVARCHAR(10),ATTEN.Leave_ToDate,120) '
	SET @Strsql+='AND ATTEN.Isonleave=''true'' '
	SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,ATTEN.Isonleave) LEAVEWORK '	
	SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
	--End of Rev 9.0
	SET @Strsql+='LEFT OUTER JOIN (SELECT GPS.User_Id,CNT.cnt_internalId,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(GPS.Duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(GPS.Duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS GPS_Inactive_duration '
	SET @Strsql+='FROM tbl_FTS_GPSSubmission GPS '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=GPS.User_Id '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),GPS.GPsDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY GPS.User_Id,CNT.cnt_internalId) GPSSM ON GPSSM.cnt_internalId=CNT.cnt_internalId '
	--Rev 3.0
	--Rev 4.0
	--SET @Strsql+='LEFT OUTER JOIN ('
	--SET @Strsql+='SELECT user_id,'	
	--SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(end_ideal_date_time),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(end_ideal_date_time),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - '
	--SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(start_ideal_date_time),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(start_ideal_date_time),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME '
	--SET @Strsql+='FROM FTS_Ideal_Loaction GROUP BY user_id) IDEALLOACTION ON IDEALLOACTION.user_id=USR.user_id '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT user_id,SUM(IDEAL_TIME) AS IDEAL_TIME FROM('
	SET @Strsql+='SELECT user_id,'	
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(end_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(end_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - '
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(start_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(start_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME '
	SET @Strsql+='FROM FTS_Ideal_Loaction WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+=') IDLE GROUP BY user_id) IDEALLOACTION ON IDEALLOACTION.user_id=USR.user_id '
	--End of Rev 4.0
	--End of Rev 3.0
	--Rev 1.0
	--SET @Strsql+='LEFT OUTER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(DISTINCT SHOPACT.Shop_Id) AS shop_visited FROM tbl_trans_shopActivitysubmit SHOPACT '
	--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT User_Id,cnt_internalId,SUM(shop_visited) AS shop_visited FROM('
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.Shop_Id) AS shop_visited FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND SHOPACT.Is_Newshopadd=1 GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.Shop_Id) AS shop_visited FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND SHOPACT.Is_Newshopadd=0 GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
	SET @Strsql+=') SHOPACT GROUP BY SHOPACT.User_Id,SHOPACT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
	--End of Rev 1.0
	SET @Strsql+='LEFT OUTER JOIN (SELECT ORDH.userID,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue FROM tbl_trans_fts_Orderupdate ORDH '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY ORDH.userID,CNT.cnt_internalId) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT COLLEC.user_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue FROM tbl_FTS_collection COLLEC '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id '
	-- Rev 13.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
	END
	-- End of Rev 13.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY COLLEC.user_id,CNT.cnt_internalId) COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId) AS SALESSUM '

	--Rev 14.0
	-- Rev 15.0
	--IF @BRANCHID<>''
	--	SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCH_LIST AS F WHERE F.Branch_Id=SALESSUM.branch_id) '
	-- End of Rev 15.0
    --Rev 14.0 End
	IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
		SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SALESSUM.STATEID) '
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
		SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=SALESSUM.deg_id) '
	ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
		SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=SALESSUM.EMPCODE) '
	ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SALESSUM.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=SALESSUM.EMPCODE) '
		END
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=SALESSUM.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=SALESSUM.EMPCODE) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SALESSUM.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=SALESSUM.deg_id) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SALESSUM.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=SALESSUM.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=SALESSUM.EMPCODE) '
		END
	-- Rev 15.0
	IF @STATEID='' AND @DESIGNID='' AND @EMPID='' AND  @BRANCHID<>''
	BEGIN
		SET @Strsql+='WHERE EXISTS (SELECT Branch_Id FROM #BRANCH_LIST AS F WHERE F.Branch_Id=SALESSUM.branch_id) '
	END
	BEGIN
		SET @Strsql+='AND EXISTS (SELECT Branch_Id FROM #BRANCH_LIST AS F WHERE F.Branch_Id=SALESSUM.branch_id) '
	END
	-- End of Rev 15.0

	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	--Rev 14.0
    DROP TABLE #BRANCH_LIST
    --Rev 14.0 End

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		drop table #EMPHR
		drop TABLE #EMPHR_EDIT
	END

	SET NOCOUNT OFF
END
GO