--EXEC PRC_FTSATTENDANCEWISEPERFORMANCE_REPORT 'FEB','','','EMP0000002','Summary',378
--EXEC PRC_FTSATTENDANCEWISEPERFORMANCE_REPORT 'JAN','','','EMP0000002','Details',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSATTENDANCEWISEPERFORMANCE_REPORT]') AND TYPE in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSATTENDANCEWISEPERFORMANCE_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSATTENDANCEWISEPERFORMANCE_REPORT]
(
@MONTH NVARCHAR(3)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@RPTTYPE NVARCHAR(10),
--Rev 5.0
@YEARS NVARCHAR(10)=NULL,
--End of Rev 5.0
@USERID INT
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 05/02/2019
Module	   : Attendance wise Performance Summary
1.0		v8.0.0		Debashis	11/02/2019		Late Count showing wrong.Now it has been solved.
2.0		v13.0.0		Debashis	12/02/2019		Not Login Count has been implemented.
3.0		v13.0.0		Debashis	14/02/2019		Not Login Count showing wrong.Now it has been solved.
4.0		v15.0.0		Debashis	19/02/2019		Not Login count showing in (-ve) figure.There are some employees whose attendance was marked on Sunday.But as per report
												functionality Not Login count=(No. of total day upto current date of selected month-total Sundays upto current date of 
												selected month)-Total Present days.But now functionality has been changed as discussed with Pijush Da that if any Employee
												marked attendance on Sunday then that day should be excluded from above Sunday count formula.
												Refer mail: Performance report Monthwise
5.0		V2.0.4		Tanmoy		02/01/2020		Year field required in the Monthly report.Refer: 0021574
6.0		v2.0.38		Sanchita	02-02-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX),@MONTHNAME NVARCHAR(3),@MONTHNO INT=0,@FROMDATE NVARCHAR(10),@TODATE NVARCHAR(10),@NOOFDAYS INT
	--Rev 2.0
	DECLARE @NOOFDAYSINMONTH INT,@NOOFSUNDAYS INT,@CURRENTMONTHNAME NVARCHAR(3)
	--End of Rev 2.0
	--Rev 4.0
	DECLARE @YEAR AS INT,@FIRSTDATEOFMONTH DATETIME,@CURRENTDATEOFMONTH DATETIME
	--End of Rev 4.0

	SET @MONTHNAME=@MONTH
	SET @MONTHNO=DATEPART(MM,@MONTHNAME+'01 1900')
	--Rev 5.0
	--SET @FROMDATE=CONVERT(VARCHAR(10),DATEADD(MONTH, CONVERT(INT,@MONTHNO) - 1, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)),120)
	--SET @TODATE=CONVERT(VARCHAR(10),DATEADD(DAY, -1, DATEADD(MONTH, CONVERT(INT,@MONTHNO), DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0))),120)
	SET @FROMDATE=CONVERT(VARCHAR(10),DATEADD(MONTH, CONVERT(INT,@MONTHNO) - 1, @YEARS),120)
	SET @TODATE=CONVERT(VARCHAR(10),DATEADD(DAY, -1, DATEADD(MONTH, CONVERT(INT,@MONTHNO), @YEARS)),120)
	--End of Rev 5.0
	SET @NOOFDAYS=(SELECT DATEDIFF(DD,@FROMDATE,@TODATE)+1)

	--Rev 2.0
	--Select DateDiff(ww, @FROMDATE, GETDATE()) as NumOfSundays --Calculate No of Sundays From date to As on date.
	SET @CURRENTMONTHNAME=(SELECT UPPER(CONVERT(CHAR(3),GETDATE(),0)))
	IF @MONTH=@CURRENTMONTHNAME
		BEGIN
			SET @NOOFDAYSINMONTH=(SELECT DATEDIFF(DD,@FROMDATE,GETDATE())+1)
			SET @NOOFSUNDAYS=(SELECT DATEDIFF(WW,@FROMDATE, GETDATE()))
		END
	ELSE IF @MONTH<>@CURRENTMONTHNAME
		BEGIN
			SET @NOOFDAYSINMONTH=(SELECT DATEDIFF(DD,@FROMDATE,@TODATE)+1)
			SET @NOOFSUNDAYS=(SELECT DATEDIFF(WW,@FROMDATE,@TODATE))
		END
	--End of Rev 2.0

	--Rev 4.0
	SELECT @YEAR=YEAR(@FROMDATE)
	SELECT @FIRSTDATEOFMONTH = @FROMDATE
	SELECT @CURRENTDATEOFMONTH = (SELECT CONVERT(VARCHAR(10),GETDATE(),120))
	;WITH CTE AS (SELECT 1 AS DAYID,@FIRSTDATEOFMONTH AS FROMDATE,DATENAME(DW, @FIRSTDATEOFMONTH) AS DAYNAME
	UNION ALL
	SELECT CTE.DAYID + 1 AS DAYID,DATEADD(D, 1 ,CTE.FROMDATE),DATENAME(DW, DATEADD(D, 1 ,CTE.FROMDATE)) AS DAYNAME
	FROM CTE
	WHERE DATEADD(D,1,CTE.FROMDATE) < @CURRENTDATEOFMONTH
	)
	SELECT FROMDATE AS SUNDAYDATE,DAYNAME INTO #TMPSHOWSUNDAY
	FROM CTE
	WHERE DAYNAME IN ('Sunday')
	OPTION (MAXRECURSION 1000)
	--End of Rev 4.0

	-- Rev 6.0
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
	-- End of Rev 6.0

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
	
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
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

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
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
	-- Rev 6.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT CNT '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
	END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
	exec sp_executesql @Strsql
	-- End of Rev 6.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSATTENDANCEWISEPERFORMANCE_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSATTENDANCEWISEPERFORMANCE_REPORT
			(
			  USERID INT,
			  SEQ INT,
			  RPTTYPE NVARCHAR(10),
			  EMPCODE NVARCHAR(100) NULL,
			  EMPID NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  CONTACTNO NVARCHAR(50) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  RPTTOEMPCODE NVARCHAR(100) NULL,
			  REPORTTO NVARCHAR(300) NULL,
			  RPTTODESGID INT,
			  RPTTODESG NVARCHAR(50) NULL,
			  WORK_DATE NVARCHAR(10),
			  IN_TIME NVARCHAR(10),
			  GRACE_TIME NVARCHAR(10),
			  LOGGEDIN NVARCHAR(10),
			  LATE_HRS NVARCHAR(10),
			  LATE_CNT INT,
			  ABSENT_CNT INT,
			  --Rev 2.0
			  NOTLOGIN_CNT INT,
			  --End of Rev 2.0
			  TGT_NC INT,
			  ACHV_NC INT,
			  TGT_RV INT,
			  ACHV_RV INT,
			  TGT_ORDERVALUE DECIMAL(38,2),
			  ACHV_ORDERVALUE DECIMAL(38,2),
			  TGT_COLLECTION DECIMAL(38,2),
			  ACHV_COLLECTION DECIMAL(38,2)
			)
			CREATE NONCLUSTERED INDEX IX ON FTSATTENDANCEWISEPERFORMANCE_REPORT (SEQ)
		END
	DELETE FROM FTSATTENDANCEWISEPERFORMANCE_REPORT WHERE USERID=@USERID AND RPTTYPE=@RPTTYPE 

	SET @Strsql=''
	IF @RPTTYPE='Summary'
		BEGIN
			SET @Strsql='INSERT INTO FTSATTENDANCEWISEPERFORMANCE_REPORT(USERID,SEQ,RPTTYPE,EMPCODE,EMPID,EMPNAME,CONTACTNO,STATEID,STATE,DEG_ID,DESIGNATION,RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG,LATE_CNT,'
			--Rev 2.0
			--SET @Strsql+='ABSENT_CNT,TGT_NC,ACHV_NC,TGT_RV,ACHV_RV,TGT_ORDERVALUE,ACHV_ORDERVALUE,TGT_COLLECTION,ACHV_COLLECTION) '
			SET @Strsql+='ABSENT_CNT,NOTLOGIN_CNT,TGT_NC,ACHV_NC,TGT_RV,ACHV_RV,TGT_ORDERVALUE,ACHV_ORDERVALUE,TGT_COLLECTION,ACHV_COLLECTION) '
			--End of Rev 2.0
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,ROW_NUMBER() OVER(ORDER BY DESIGNATION) AS SEQ,''Summary'' AS RPTTYPE,EMPCODE,EMPID,EMPNAME,CONTACTNO,STATEID,STATE,DEG_ID,DESIGNATION,'
			--Rev 2.0
			--SET @Strsql+='RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG,LATE_CNT,(LATE_CNT/3) AS ABSENT_CNT,TGT_NC,ACHV_NC,TGT_RV,ACHV_RV,TGT_ORDERVALUE,ACHV_ORDERVALUE,TGT_COLLECTION,ACHV_COLLECTION FROM( '
			SET @Strsql+='RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG,LATE_CNT,(LATE_CNT/3) AS ABSENT_CNT,ISNULL(NOTLOGIN_CNT,0) AS NOTLOGIN_CNT,TGT_NC,ACHV_NC,TGT_RV,ACHV_RV,TGT_ORDERVALUE,ACHV_ORDERVALUE,TGT_COLLECTION,ACHV_COLLECTION FROM( '
			--End of Rev 2.0
			SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ST.ID AS STATEID,ST.state AS STATE,'
			SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTOEMPCODE,RPTTO.REPORTTO,RPTTO.RPTTODESGID,RPTTO.RPTTODESG,EMP.emp_uniqueCode AS EMPID,SUM(ISNULL(ATTEN.LATE_CNT,0)) AS LATE_CNT,'
			--Rev 2.0
			--Rev 4.0
			--SET @Strsql+='('+LTRIM(RTRIM(STR(@NOOFDAYSINMONTH)))+'-'+LTRIM(RTRIM(STR(@NOOFSUNDAYS)))+')-SUM(ATTEN.PRESENT_CNT) AS NOTLOGIN_CNT,'
			SET @Strsql+='('+LTRIM(RTRIM(STR(@NOOFDAYSINMONTH)))+'-('+LTRIM(RTRIM(STR(@NOOFSUNDAYS)))+'-SUM(ATTEN.SUNDAY_CNT)))-SUM(ATTEN.PRESENT_CNT) AS NOTLOGIN_CNT,'
			--End of Rev 4.0
			--End of Rev 2.0
			SET @Strsql+='SUM(ISNULL(EMPTGTSET.NewCounter,0)) AS TGT_NC,SUM(ISNULL(EMPTGTSET.Revisit,0)) AS TGT_RV,SUM(ISNULL(EMPTGTSET.OrderValue,0)) AS TGT_ORDERVALUE,SUM(ISNULL(EMPTGTSET.Collection,0)) AS TGT_COLLECTION,'
			SET @Strsql+='SUM(ISNULL(NEWSHOPVISITED,0)) AS ACHV_NC,SUM(ISNULL(REVISITSHOP,0)) AS ACHV_RV,SUM(ISNULL(ORDHEAD.Ordervalue,0)) AS ACHV_ORDERVALUE,SUM(ISNULL(COLLEC.collectionvalue,0)) AS ACHV_COLLECTION '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId) ATTENLOG ON ATTENLOG.cnt_internalId=CNT.cnt_internalId AND ATTENLOG.USERID=USR.user_id '
			--Rev 1.0
			--SET @Strsql+='LEFT OUTER JOIN (SELECT A.User_Id AS USERID,'
			--SET @Strsql+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
			--SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			--SET @Strsql+='+ MIN(EMPWHD.Grace) THEN COUNT(0) ELSE 0 END AS LATE_CNT FROM tbl_fts_UserAttendanceLoginlogout A '
			--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id '
			--SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
			--SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
			--SET @Strsql+='INNER JOIN(SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			--SET @Strsql+='AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL AND A.Isonleave=''false'' '
			--SET @Strsql+='GROUP BY A.User_Id) ATTEN ON ATTEN.USERID=USR.user_id '
			--Rev 2.0
			--SET @Strsql+='LEFT OUTER JOIN (SELECT USERID,COUNT(LATE_CNT) AS LATE_CNT FROM('
			--SET @Strsql+='SELECT A.User_Id AS USERID,CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL((Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL((Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
			--Rev 3.0
			--SET @Strsql+='LEFT OUTER JOIN (SELECT USERID,COUNT(LATE_CNT) AS LATE_CNT,COUNT(PRESENT_CNT) AS PRESENT_CNT FROM('
			--SET @Strsql+='SELECT A.User_Id AS USERID,A.LOGIN_DATETIME AS PRESENT_CNT,'
			--SET @Strsql+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL((Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL((Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
			----End of Rev 2.0
			--SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + '
			--SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) + MIN(EMPWHD.Grace) THEN COUNT(0) ELSE 0 END LATE_CNT '
			--SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout AS A '
			--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id '
			--SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
			--SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
			--SET @Strsql+='INNER JOIN('
			--SET @Strsql+='SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			--SET @Strsql+='AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL AND A.Isonleave=''false'' '
			--SET @Strsql+='GROUP BY A.User_Id,A.Login_datetime) A WHERE LATE_CNT>0 GROUP BY USERID) ATTEN ON ATTEN.USERID=USR.user_id '
			--Rev 4.0
			--SET @Strsql+='LEFT OUTER JOIN (SELECT USERID,SUM(LATE_CNT) AS LATE_CNT,SUM(PRESENT_CNT) AS PRESENT_CNT FROM('
			--SET @Strsql+='SELECT USERID,0 AS PRESENT_CNT,COUNT(LATE_CNT) AS LATE_CNT FROM('
			SET @Strsql+='LEFT OUTER JOIN (SELECT USERID,SUM(LATE_CNT) AS LATE_CNT,SUM(PRESENT_CNT) AS PRESENT_CNT,SUM(SUNDAY_CNT) AS SUNDAY_CNT FROM('
			SET @Strsql+='SELECT USERID,0 AS PRESENT_CNT,COUNT(LATE_CNT) AS LATE_CNT,0 AS SUNDAY_CNT FROM('
			--End of Rev 4.0
			SET @Strsql+='SELECT A.User_Id AS USERID,0 AS PRESENT_CNT,'
			SET @Strsql+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL((Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL((Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + '
			SET @Strsql+='CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) + MIN(EMPWHD.Grace) THEN COUNT(0) ELSE 0 END LATE_CNT '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout AS A '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
			SET @Strsql+='INNER JOIN('
			SET @Strsql+='SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL AND A.Isonleave=''false'' '
			SET @Strsql+='GROUP BY A.User_Id,A.Login_datetime) A WHERE LATE_CNT>0 GROUP BY USERID '
			SET @Strsql+='UNION ALL '
			--Rev 4.0
			--SET @Strsql+='SELECT A.User_Id AS USERID,COUNT(A.Login_datetime) AS PRESENT_CNT,0 AS LATE_CNT FROM tbl_fts_UserAttendanceLoginlogout AS A '
			SET @Strsql+='SELECT A.User_Id AS USERID,COUNT(A.Login_datetime) AS PRESENT_CNT,0 AS LATE_CNT,0 AS SUNDAY_CNT FROM tbl_fts_UserAttendanceLoginlogout AS A '
			--End of Rev 4.0
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
			SET @Strsql+='INNER JOIN('
			SET @Strsql+='SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL AND A.Isonleave=''false'' '
			SET @Strsql+='GROUP BY A.User_Id,A.Login_datetime '
			--Rev 4.0
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT A.User_Id AS USERID,0 AS PRESENT_CNT,0 AS LATE_CNT,COUNT(DISTINCT CONVERT(NVARCHAR(10),A.Login_datetime,120)) AS SUNDAY_CNT FROM tbl_fts_UserAttendanceLoginlogout AS A '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
			SET @Strsql+='INNER JOIN(SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),GETDATE(),120) '
			SET @Strsql+='AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL AND A.Isonleave=''false'' '
			SET @Strsql+='AND EXISTS(SELECT CONVERT(NVARCHAR(10),SUNDAYDATE,120) AS SUNDAY FROM #TMPSHOWSUNDAY WHERE CONVERT(NVARCHAR(10),SUNDAYDATE,120)=CONVERT(NVARCHAR(10),A.Work_datetime,120))'
			SET @Strsql+='GROUP BY A.User_Id'
			--End of Rev 4.0
			SET @Strsql+=') A GROUP BY USERID) ATTEN ON ATTEN.USERID=USR.user_id '
			--End of Rev 3.0
			--End of Rev 1.0
			--Rev 4.0
			--SET @Strsql+='LEFT OUTER JOIN(SELECT EmployeeCode,NewCounter,Revisit,OrderValue,Collection FROM tbl_FTS_EmployeesTargetSetting '
			SET @Strsql+='LEFT OUTER JOIN(SELECT EmployeeCode,SUM(NewCounter) AS NewCounter,SUM(Revisit) AS Revisit,SUM(OrderValue) AS OrderValue,SUM(Collection) AS Collection '
			SET @Strsql+='FROM tbl_FTS_EmployeesTargetSetting '
			--End of Rev 4.0
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODATE+''',120) BETWEEN CONVERT(NVARCHAR(10),FromDate,120) AND CONVERT(NVARCHAR(10),ToDate,120) '
			--Rev 4.0
			SET @Strsql+='GROUP BY EmployeeCode '
			--End of Rev 4.0
			SET @Strsql+=') EMPTGTSET ON EMPTGTSET.EmployeeCode=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN ('
			SET @Strsql+='SELECT User_Id,cnt_internalId,SUM(NEWSHOPVISITED) AS NEWSHOPVISITED,SUM(REVISITSHOP) AS REVISITSHOP FROM('
			SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.Shop_Id) AS NEWSHOPVISITED,0 AS REVISITSHOP FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.Is_Newshopadd=1 ' 
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,0 AS NEWSHOPVISITED,COUNT(SHOPACT.Shop_Id) AS REVISITSHOP FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.Is_Newshopadd=0 '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId ) SHOPACT GROUP BY SHOPACT.User_Id,SHOPACT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN ('
			SET @Strsql+='SELECT ORDH.userID,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue FROM tbl_trans_fts_Orderupdate ORDH '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY ORDH.userID,CNT.cnt_internalId) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN ('
			SET @Strsql+='SELECT COLLEC.user_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue FROM tbl_FTS_collection COLLEC '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY COLLEC.user_id,CNT.cnt_internalId) COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS RPTTOEMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.RPTTOEMPCODE IS NOT NULL '
			SET @Strsql+='GROUP BY CNT.cnt_internalId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ST.ID,ST.state,DESG.DEG_ID,DESG.deg_designation,USR.user_loginId,RPTTOEMPCODE,RPTTO.REPORTTO,RPTTO.RPTTODESGID,'
			SET @Strsql+='RPTTO.RPTTODESG,EMP.emp_uniqueCode '
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
		END
	ELSE IF @RPTTYPE='Details'
		BEGIN
			SET @Strsql='INSERT INTO FTSATTENDANCEWISEPERFORMANCE_REPORT(USERID,SEQ,RPTTYPE,EMPCODE,EMPID,EMPNAME,CONTACTNO,WORK_DATE,IN_TIME,GRACE_TIME,LOGGEDIN,LATE_HRS,TGT_NC,ACHV_NC,TGT_RV,ACHV_RV,'
			SET @Strsql+='TGT_ORDERVALUE,ACHV_ORDERVALUE,TGT_COLLECTION,ACHV_COLLECTION) '
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,ROW_NUMBER() OVER(ORDER BY WORK_DATE) AS SEQ,''Details'' AS RPTTYPE,EMPCODE,EMPID,EMPNAME,CONTACTNO,WORK_DATE,IN_TIME,GRACE_TIME,'
			SET @Strsql+='LOGGEDIN,LATE_HRS,TGT_NC,ACHV_NC,TGT_RV,ACHV_RV,TGT_ORDERVALUE,ACHV_ORDERVALUE,TGT_COLLECTION,ACHV_COLLECTION '
			SET @Strsql+='FROM('
			SET @Strsql+='SELECT EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ATTENLOG.WORK_DATE,USR.user_loginId AS CONTACTNO,REPLACE(REPLACE(ATTEN.IN_TIME,''AM'','' AM''),''PM'','' PM'') AS IN_TIME,REPLACE(REPLACE(ATTEN.GRACE_TIME,''AM'','' AM''),''PM'','' PM'') AS GRACE_TIME,'
			SET @Strsql+='RIGHT(''0'' + CAST(CAST(ATTEN.LATE_HRS AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(ATTEN.LATE_HRS AS VARCHAR) % 60 AS VARCHAR),2) AS LATE_HRS,'
			SET @Strsql+='REPLACE(REPLACE(ATTENLOG.LOGGEDIN,''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,'
			SET @Strsql+='ISNULL(EMPTGTSET.NewCounter,0)/'+LTRIM(RTRIM(STR(@NOOFDAYS)))+' AS TGT_NC,ISNULL(EMPTGTSET.Revisit,0)/'+LTRIM(RTRIM(STR(@NOOFDAYS)))+' AS TGT_RV,ISNULL(EMPTGTSET.OrderValue,0)/'+LTRIM(RTRIM(STR(@NOOFDAYS)))+' AS TGT_ORDERVALUE,'
			SET @Strsql+='ISNULL(EMPTGTSET.Collection,0)/'+LTRIM(RTRIM(STR(@NOOFDAYS)))+' AS TGT_COLLECTION,ISNULL(NEWSHOPVISITED,0) AS ACHV_NC,ISNULL(REVISITSHOP,0) AS ACHV_RV,ISNULL(ORDHEAD.Ordervalue,0) AS ACHV_ORDERVALUE,'
			SET @Strsql+='ISNULL(COLLEC.collectionvalue,0) AS ACHV_COLLECTION FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN ( '
			SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(15),CAST(ATTEN.Login_datetime AS TIME),100)) AS LOGGEDIN,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS WORK_DATE '
			SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) '
			SET @Strsql+=') ATTENLOG ON ATTENLOG.cnt_internalId=CNT.cnt_internalId AND ATTENLOG.USERID=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN (SELECT A.User_Id AS USERID,CONVERT(VARCHAR(15),CAST(EMPWHD.BeginTime AS TIME),100) AS IN_TIME,''00:''+CONVERT(VARCHAR(15),EMPWHD.Grace) AS GRACE_TIME,'
			SET @Strsql+='CONVERT(NVARCHAR(10),A.Work_datetime,105) AS WORK_DATE,'
			SET @Strsql+='CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(A.Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(A.Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> '
			SET @Strsql+='(CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			SET @Strsql+='+ MIN(EMPWHD.Grace)) THEN '
			SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(A.Login_datetime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(A.Login_datetime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - '
			SET @Strsql+='(CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
			SET @Strsql+='+ MIN(EMPWHD.Grace)) ELSE 0 END AS LATE_HRS FROM tbl_fts_UserAttendanceLoginlogout A '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id '
			SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours '
			SET @Strsql+='INNER JOIN(SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL AND A.Isonleave=''false'' '
			SET @Strsql+='GROUP BY A.User_Id,EMPWHD.BeginTime,EMPWHD.Grace,A.Work_datetime) ATTEN ON ATTEN.USERID=USR.user_id AND ATTENLOG.WORK_DATE=ATTEN.WORK_DATE '
			SET @Strsql+='LEFT OUTER JOIN(SELECT EmployeeCode,NewCounter,Revisit,OrderValue,Collection FROM tbl_FTS_EmployeesTargetSetting '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),'''+@TODATE+''',120) BETWEEN CONVERT(NVARCHAR(10),FromDate,120) AND CONVERT(NVARCHAR(10),ToDate,120) '
			SET @Strsql+=') EMPTGTSET ON EMPTGTSET.EmployeeCode=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN ('
			SET @Strsql+='SELECT User_Id,cnt_internalId,SUM(NEWSHOPVISITED) AS NEWSHOPVISITED,SUM(REVISITSHOP) AS REVISITSHOP,VISIT_DATE FROM('
			SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.Shop_Id) AS NEWSHOPVISITED,0 AS REVISITSHOP,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISIT_DATE FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.Is_Newshopadd=1 '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,0 AS NEWSHOPVISITED,COUNT(SHOPACT.Shop_Id) AS REVISITSHOP,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISIT_DATE FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.Is_Newshopadd=0 '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) ) SHOPACT GROUP BY SHOPACT.User_Id,SHOPACT.cnt_internalId,VISIT_DATE '
			SET @Strsql+=') SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND SHOPACT.VISIT_DATE=ATTENLOG.WORK_DATE '
			SET @Strsql+='LEFT OUTER JOIN ('
			SET @Strsql+='SELECT ORDH.userID,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue,CONVERT(NVARCHAR(10),ORDH.Orderdate,105) AS ORDDATE FROM tbl_trans_fts_Orderupdate ORDH '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY ORDH.userID,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ORDH.Orderdate,105) '
			SET @Strsql+=') ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId AND ATTENLOG.WORK_DATE=ORDHEAD.ORDDATE '
			SET @Strsql+='LEFT OUTER JOIN ('
			SET @Strsql+='SELECT COLLEC.user_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue,CONVERT(NVARCHAR(10),COLLEC.collection_date,105) AS collection_date FROM tbl_FTS_collection COLLEC '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY COLLEC.user_id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),COLLEC.collection_date,105)) COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId AND ATTENLOG.WORK_DATE=COLLEC.collection_date '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS RPTTOEMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.RPTTOEMPCODE IS NOT NULL '
			SET @Strsql+=') AS DB '
			IF @EMPID<>''
				SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
			SET @Strsql+='ORDER BY WORK_DATE '
		END
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	--Rev 4.0
	DROP TABLE #TMPSHOWSUNDAY
	--End of Rev 4.0
	-- Rev 6.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 6.0
END