IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_TargetVsAchivementReport]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_TargetVsAchivementReport] AS'  
 END 
 GO 
--exec PRC_TargetVsAchivementReport @user_id='378',@FromDate='2020-06-10',@TODATE='2020-07-10'

ALTER PROCEDURE  [dbo].[PRC_TargetVsAchivementReport]
(
@user_id BIGINT,
@FromDate DATE=NULL,
@TODATE DATE=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@deptid NVARCHAR(MAX)=NULL,
@DesigId NVARCHAR(MAX)=NULL,
@Supercode NVARCHAR(MAX)=NULL
)  
AS
/****************************************************************************************************************************************
1.0			Tanmoy		23-07-2020	Create Procedure
2.0			Sanchiita	14-06-2022		Error on generating report , string or binary data truncated.
*******************************************************************************************************************************************/ 
BEGIN
		SET NOCOUNT ON
		DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX)
		
		
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
		
		
		IF OBJECT_ID('tempdb..#SUPER_LIST') IS NOT NULL
		DROP TABLE #SUPER_LIST
		CREATE TABLE #SUPER_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
		IF @Supercode <> ''
		BEGIN
			SET @Supercode = REPLACE(''''+@Supercode+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #SUPER_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@Supercode+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		IF OBJECT_ID('tempdb..#DEPARTMENT_LIST') IS NOT NULL
		DROP TABLE #DEPARTMENT_LIST
		CREATE TABLE #DEPARTMENT_LIST (dept_id BIGINT)
		CREATE NONCLUSTERED INDEX IX2 ON #DEPARTMENT_LIST (dept_id ASC)
		IF @deptid <> ''
		BEGIN
			SET @deptid=REPLACE(@deptid,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #DEPARTMENT_LIST SELECT cost_id from tbl_master_costCenter where cost_id in('+@deptid+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

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
			-- Rev 2.0
			--Contact_no nvarchar(15)
			Contact_no nvarchar(50)
			-- End of Rev 2.0
		)
		CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
		INSERT INTO #TEMPCONTACT
		SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id,USR.user_loginId FROM TBL_MASTER_CONTACT CNT
		INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE cnt_contactType IN('EM')

		--;with months (date)
		--	AS
		--	(
		--		SELECT @FromDate
		--		UNION ALL
		--		SELECT DATEADD(month, 1, date)
		--		from months
		--		where DATEADD(month, 1, date) = @TODATE
		--	)

		--	select     [MonthName]    = DATENAME(mm, date),
		--			   [MonthNumber]  = DATEPART(mm, date), 
		--			   [LastDayOfMonth]  = DATEPART(dd, EOMONTH(date)),
		--			   [MonthYear]    = DATEPART(yy, date) INTO #TEMMONTH
		--	from months

		SELECT   DateName( month , DateAdd( month , [MonthNumber] , -1 )) [MonthName],
		[MonthNumber],[LastDayOfMonth],[MonthYear] INTO #TEMMONTH
		from(  
		SELECT  Month(DATEADD(MONTH, x.number, @FromDate)) AS [MonthNumber],
		DATEPART(dd, EOMONTH(DATEADD(MONTH, x.number, @FromDate))) AS  [LastDayOfMonth],
		DATEPART(yy, DATEADD(MONTH, x.number, @FromDate)) AS [MonthYear] 
		FROM    master.dbo.spt_values x  
		WHERE   x.type = 'P'          
		AND     x.number <= DATEDIFF(MONTH, @FromDate, @TODATE)  
		) A 

			--select * from #TEMMONTH

		CREATE TABLE #EMPLOYEEWISESUMMARY
		(
		Month_Name VARCHAR(50),
		FromDate VARCHAR(10),
		ToDate VARCHAR(10),
		USER_ID BIGINT,
		EMP_CODE VARCHAR(500),
		EMP_NAME VARCHAR(500),
		DESIG VARCHAR(500) ,
		DEPT VARCHAR(500) ,
		DESIG_ID BIGINT ,
		DEPT_ID BIGINT ,
		ENQ_TGT VARCHAR(50) DEFAULT 0,
		ENQ_ACH VARCHAR(50) DEFAULT 0,
		LEAD_TGT VARCHAR(50) DEFAULT 0,
		LEAD_ACH VARCHAR(50) DEFAULT 0,
		TD_TGT VARCHAR(50) DEFAULT 0,
		TD_ACH VARCHAR(50) DEFAULT 0,
		BOOKING_TGT VARCHAR(50) DEFAULT 0,
		BOOKING_ACH VARCHAR(50) DEFAULT 0,
		RT_TGT VARCHAR(50) DEFAULT 0,
		RT_ACH VARCHAR(50) DEFAULT 0
		)


		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_TargetVsAcchivementReport') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTS_TargetVsAcchivementReport
			(
			SEQ BIGINT,
			USERID BIGINT,
			Month NVARCHAR(50),
			MonthFromDate nvarchar(10),
			MonthToDate nvarchar(10),
			Employee nvarchar(300),
			Supervisor nvarchar(300),
			Designation nvarchar(300),
			Department nvarchar(300),
			InquiryTarget INT,
			InquiryAchv INT,
			LeadTarget INT,
			LeadAchv INT,
			TestDriveTarget INT,
			TestDriveAchv INT,
			BookingTarget INT,
			BookingAchv INT,
			TerailTarget INT,
			RetailAchv INT
			)
		END
		delete from FTS_TargetVsAcchivementReport where USERID=@user_id

		DECLARE @MonthName NVARCHAR(20)
		DECLARE	@MonthNumber INT
		DECLARE	@LastDayOfMonth INT
		DECLARE @MonthYear INT
	
		DECLARE @STARTDATE DATETIME,@ENDDATE DATETIME

		DECLARE @EMP_NAME VARCHAR(500)=''
		DECLARE @EMP_DESG VARCHAR(500)=''
		DECLARE @EMP_DEPT VARCHAR(500)=''
		DECLARE @USER_IDS BIGINT

		DECLARE @DESIG_ID BIGINT
		DECLARE @DEPT_ID BIGINT

		DECLARE @Stage_id VARCHAR(50),@emp_code VARCHAR(50),@counter bigint

		---- TARGET

		DECLARE DB_CURSORMONTH CURSOR FOR
		SELECT MonthName,MonthNumber,LastDayOfMonth,MonthYear FROM #TEMMONTH
		OPEN DB_CURSORMONTH 
		FETCH NEXT FROM DB_CURSORMONTH INTO @MonthName,@MonthNumber,@LastDayOfMonth,@MonthYear
		WHILE @@FETCH_STATUS=0
		BEGIN
			SET @STARTDATE=CONVERT(NVARCHAR(10),@MonthYear)+'-'+CONVERT(NVARCHAR(3),@MonthNumber)+'-01'
			IF @STARTDATE<@FromDate
				SET @STARTDATE=@FromDate

			SET @ENDDATE=CONVERT(NVARCHAR(10),@MonthYear)+'-'+CONVERT(NVARCHAR(3),@MonthNumber)+'-'+CONVERT(NVARCHAR(3),@LastDayOfMonth)
			IF @ENDDATE >@TODATE
				SET @ENDDATE=@TODATE

			DECLARE DB_CURSOR CURSOR FOR
			SELECT Stage,SUM(NewCounter) cnt,EmployeeCode FROM tbl_FTS_EmployeesTargetSetting
			LEFT OUTER JOIN FTS_Stage ON STAGE_ID=StageID
			where SettingMonth=@MonthNumber 
			and isnull(STAGE_ID,0)<>0 and SettingYear=@MonthYear group by Stage,EmployeeCode
			OPEN DB_CURSOR 
			FETCH NEXT FROM DB_CURSOR INTO @Stage_id,@counter,@emp_code
			WHILE @@FETCH_STATUS=0
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM #EMPLOYEEWISESUMMARY WHERE EMP_CODE=@emp_code AND Month_Name=@MonthName)
				BEGIN
					SET @EMP_NAME=(SELECT cnt_firstName +ltrim(RTRIM(' '+isnull(cnt_middleName,'')))+ltrim(RTRIM(' '+isnull(cnt_lastName,''))) FROM TBL_MASTER_CONTACT WHERE cnt_internalId=@emp_code)
			
					SET @EMP_DESG =(SELECT deg_designation FROM tbl_trans_employeeCTC
					INNER JOIN tbl_master_designation DESG ON DESG.deg_id=emp_Designation
					 WHERE emp_effectiveuntil IS NULL AND emp_cntId=@emp_code)

					 SET @EMP_DEPT =(SELECT cost_description FROM tbl_trans_employeeCTC
					INNER JOIN tbl_master_costCenter DEPT ON dept.cost_id=emp_Department AND cost_costCenterType='Department'
					WHERE emp_effectiveuntil IS NULL AND emp_cntId=@emp_code)

					SET @DESIG_ID =(SELECT DESG.deg_id FROM tbl_trans_employeeCTC
					INNER JOIN tbl_master_designation DESG ON DESG.deg_id=emp_Designation
					 WHERE emp_effectiveuntil IS NULL AND emp_cntId=@emp_code)

					 SET @DEPT_ID =(SELECT cost_id FROM tbl_trans_employeeCTC
					INNER JOIN tbl_master_costCenter DEPT ON dept.cost_id=emp_Department AND cost_costCenterType='Department'
					WHERE emp_effectiveuntil IS NULL AND emp_cntId=@emp_code)

					SET @USER_IDS=(SELECT TOP(1)USER_ID FROM TBL_MASTER_USER WHERE user_contactId=@emp_code AND user_inactive='N ')

					INSERT INTO #EMPLOYEEWISESUMMARY(Month_Name,FromDate,ToDate,USER_ID,EMP_CODE,EMP_NAME,DEPT,DESIG,DESIG_ID,DEPT_ID) 
					VALUES(@MonthName,CONVERT(NVARCHAR(10),@STARTDATE,105),CONVERT(NVARCHAR(10),@ENDDATE,105),@USER_IDS,@emp_code,@EMP_NAME,@EMP_DEPT,@EMP_DESG,@DESIG_ID,@DEPT_ID)
			
				END

				IF(@Stage_id='Enquiry')
					BEGIN
				
						UPDATE #EMPLOYEEWISESUMMARY SET ENQ_TGT=@counter WHERE  EMP_CODE=@emp_code AND Month_Name=@MonthName
					END
				ELSE IF(@Stage_id='Lead')
					BEGIN
						UPDATE #EMPLOYEEWISESUMMARY SET LEAD_TGT=@counter WHERE  EMP_CODE=@emp_code	 AND Month_Name=@MonthName			
					END
				ELSE IF(@Stage_id='Test Drive')
					BEGIN
						UPDATE #EMPLOYEEWISESUMMARY SET TD_TGT=@counter WHERE  EMP_CODE=@emp_code AND Month_Name=@MonthName
					END
				ELSE IF(@Stage_id='Booking')
					BEGIN
						UPDATE #EMPLOYEEWISESUMMARY SET BOOKING_TGT=@counter WHERE  EMP_CODE=@emp_code AND Month_Name=@MonthName
					END
				ELSE IF(@Stage_id='Retail')
					BEGIN
						UPDATE #EMPLOYEEWISESUMMARY SET RT_TGT=@counter WHERE  EMP_CODE=@emp_code AND Month_Name=@MonthName
					END

				FETCH NEXT FROM DB_CURSOR INTO @Stage_id,@counter,@emp_code
			END
			CLOSE DB_CURSOR
			DEALLOCATE DB_CURSOR


			---ACHIEVEMRNT

			DECLARE DB_CURSOR CURSOR FOR
			select Stage,count(0) cnt,user_contactId  FROM FTS_STAGEMAP MAP
			INNER JOIN tbl_master_user USR ON USR.user_id=MAP.USER_ID
			LEFT OUTER JOIN FTS_Stage ON STAGE_ID=StageID
			where CAST(update_date AS DATE) BETWEEN @STARTDATE AND @ENDDATE
			group by Stage,user_contactId
			OPEN DB_CURSOR 
			FETCH NEXT FROM DB_CURSOR INTO @Stage_id,@counter,@emp_code
			WHILE @@FETCH_STATUS=0
			BEGIN

				IF NOT EXISTS(SELECT 1 FROM #EMPLOYEEWISESUMMARY WHERE EMP_CODE=@emp_code AND Month_Name=@MonthName)
				BEGIN
					SET @EMP_NAME=(SELECT cnt_firstName +ltrim(RTRIM(' '+isnull(cnt_middleName,'')))+ltrim(RTRIM(' '+isnull(cnt_lastName,''))) FROM TBL_MASTER_CONTACT WHERE cnt_internalId=@emp_code)

					SET @EMP_DESG =(SELECT deg_designation FROM tbl_trans_employeeCTC
					INNER JOIN tbl_master_designation DESG ON DESG.deg_id=emp_Designation
					 WHERE emp_effectiveuntil IS NULL AND emp_cntId=@emp_code)

					 SET @EMP_DEPT =(SELECT cost_description FROM tbl_trans_employeeCTC
					INNER JOIN tbl_master_costCenter DEPT ON dept.cost_id=emp_Department AND cost_costCenterType='Department'
					WHERE emp_effectiveuntil IS NULL AND emp_cntId=@emp_code)

					SET @DESIG_ID =(SELECT DESG.deg_id FROM tbl_trans_employeeCTC
					INNER JOIN tbl_master_designation DESG ON DESG.deg_id=emp_Designation
					 WHERE emp_effectiveuntil IS NULL AND emp_cntId=@emp_code)

					 SET @DEPT_ID =(SELECT cost_id FROM tbl_trans_employeeCTC
					INNER JOIN tbl_master_costCenter DEPT ON dept.cost_id=emp_Department AND cost_costCenterType='Department'
					WHERE emp_effectiveuntil IS NULL AND emp_cntId=@emp_code)

					SET @USER_IDS=(SELECT TOP(1)USER_ID FROM TBL_MASTER_USER WHERE user_contactId=@emp_code AND user_inactive='N ')

					INSERT INTO #EMPLOYEEWISESUMMARY(Month_Name,FromDate,ToDate,USER_ID,EMP_CODE,EMP_NAME,DEPT,DESIG,DESIG_ID,DEPT_ID) 
					VALUES(@MonthName,CONVERT(NVARCHAR(10),@STARTDATE,105),CONVERT(NVARCHAR(10),@ENDDATE,105),@USER_IDS,@emp_code,@EMP_NAME,@EMP_DEPT,@EMP_DESG,@DESIG_ID,@DEPT_ID)
			
				END

				IF(@Stage_id='Enquiry')
					BEGIN
				
						UPDATE #EMPLOYEEWISESUMMARY SET ENQ_ACH=@counter WHERE  EMP_CODE=@emp_code AND Month_Name=@MonthName
					END
				ELSE IF(@Stage_id='Lead')
					BEGIN
						UPDATE #EMPLOYEEWISESUMMARY SET LEAD_ACH=@counter WHERE  EMP_CODE=@emp_code	 AND Month_Name=@MonthName			
					END
				ELSE IF(@Stage_id='Test Drive')
					BEGIN
						UPDATE #EMPLOYEEWISESUMMARY SET TD_ACH=@counter WHERE  EMP_CODE=@emp_code AND Month_Name=@MonthName
					END
				ELSE IF(@Stage_id='Booking')
					BEGIN
						UPDATE #EMPLOYEEWISESUMMARY SET BOOKING_ACH=@counter WHERE  EMP_CODE=@emp_code AND Month_Name=@MonthName
					END
				ELSE IF(@Stage_id='Retail')
					BEGIN
						UPDATE #EMPLOYEEWISESUMMARY SET RT_ACH=@counter WHERE  EMP_CODE=@emp_code AND Month_Name=@MonthName
					END

				FETCH NEXT FROM DB_CURSOR INTO @Stage_id,@counter,@emp_code
			END
			CLOSE DB_CURSOR
			DEALLOCATE DB_CURSOR

			FETCH NEXT FROM DB_CURSORMONTH INTO @MonthName,@MonthNumber,@LastDayOfMonth,@MonthYear
		END
		CLOSE DB_CURSORMONTH
		DEALLOCATE DB_CURSORMONTH

		SET @Strsql=' '
		SET @Strsql+=' INSERT INTO FTS_TargetVsAcchivementReport '
		SET @Strsql+=' SELECT ROW_NUMBER() OVER(ORDER BY FromDate) AS SEQ,'''+STR(@user_id)+''',Month_Name,FromDate,ToDate, '
		SET @Strsql+=' EMP_NAME,REPORTTO,DESIG,DEPT,ENQ_TGT,ENQ_ACH,LEAD_TGT,LEAD_ACH,TD_TGT,TD_ACH,BOOKING_TGT,BOOKING_ACH,RT_TGT,RT_ACH FROM #EMPLOYEEWISESUMMARY TEMP'
		SET @Strsql+=' LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,   '
		SET @Strsql+=' CNT.cnt_internalId,  '
		SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''')+'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS REPORTTO,  '
		SET @Strsql+=' DESG.deg_designation AS RPTTODESG,CNT.cnt_ucc AS REPORTTO_ID FROM tbl_master_employee EMP    '
		SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo    '
		SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId  '
		SET @Strsql+=' LEFT OUTER JOIN (    '
		SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt  	'
		SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL  '
		SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId   '
		SET @Strsql+=' WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=TEMP.EMP_CODE   '
		SET @Strsql+=' WHERE Month_Name IN (SELECT MonthName FROM #TEMMONTH) '
		IF @EMPID <> ''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=TEMP.EMP_CODE) '
		END
		IF @DesigId <> ''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=TEMP.DESIG_ID) '
		END
		IF @Supercode <> ''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #SUPER_LIST AS SUPR WHERE SUPR.emp_contactId=RPTTO.cnt_internalId) '
		END
		IF @deptid <> ''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT dept_id from #DEPARTMENT_LIST AS DPT WHERE DPT.dept_id=TEMP.DEPT_ID) '
		END

		EXEC SP_EXECUTESQL @Strsql
		SELECT @Strsql

		--SELECT * FROM #EMPLOYEEWISESUMMARY

	DROP TABLE #EMPLOYEEWISESUMMARY

	DROP TABLE #TEMMONTH

	SET NOCOUNT OFF
END
GO