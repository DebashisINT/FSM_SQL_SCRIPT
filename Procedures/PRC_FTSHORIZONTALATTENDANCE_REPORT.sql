IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSHORIZONTALATTENDANCE_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSHORIZONTALATTENDANCE_REPORT] AS' 
END
GO


--EXEC PRC_FTSHORIZONTALATTENDANCE_REPORT @FROM_DATE='2021-06-01',@TO_DATE='2021-06-11',@EMPID='',@SelfieURL='http://3.7.30.86:82//Commonfolder/AttendanceImageDemo/',@ShowAttendanceSelfie=1
ALTER PROCEDURE [dbo].[PRC_FTSHORIZONTALATTENDANCE_REPORT]
(
@FROM_DATE NVARCHAR(10)=NULL,
@TO_DATE NVARCHAR(10)=NULL,
@EMPID NVARCHAR(MAX) =NULL,
@Emp_code NVARCHAR(100)=NULL,

@TotalKMTravelled INT=NULL,
@SecondarySalesValue INT =NULL,
@IdleTimeCount INT=NULL,
@ShowAttendanceSelfie INT=NULL,
@SelfieURL NVARCHAR(MAX)=NULL,
@Userid bigint=null
--Rev work 2.0
,@ShowFullday INT=NULL
,@ISONLYLOGINDATA INT=NULL,
@ISONLYLOGOUTDATA INT=NULL
--End of rev work 2.0
-- Rev 4.0
,@BRANCHID NVARCHAR(MAX)=NULL
-- End of Rev 4.0
-- Rev 5.0
,@ShowFirstVisitTime INT=NULL
,@ShowLastVisitTime INT=NULL
-- End of Rev 5.0
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0					Tanmoy		26-11-2020		CREATE PROCEDURE
2.0  v2.0.32		Swatilekha  16.08.2022		Attendance register report enhancement required refer:0025111
3.0		v2.0.37		Sanchita	16-11-2022		Attendance Register Report- Multiple rows generating against a singular User ID if the user logs out multiple times.
												Also the distance travelled is showing zero though the total distance travelled showing data.
												Refer: 25444
4.0		V2.0.41		Sanchita	19/07/2023		Add Branch parameter in MIS -> Performance Summary report. Refer: 26135
5.0		V2.0.42		Sanchita	10/08/2023		Two check box is required to show the first call time & last call time in Attendance Register Report
												Refer: 26707
****************************************************************************************************************************************************************************/
BEGIN

	DECLARE @DAYCOUNT INT,@LOOPCOUNT INT,@FIRSTTIME BIT=1
	DECLARE @sqlStrTable NVARCHAR(MAX)
	DECLARE @COLUMN_DATE NVARCHAR(10)=@FROM_DATE
	DECLARE @SLHEADID BIGINT,@PARENTID BIGINT

	DECLARE @days AS INT,@FIRSTDATEOFMONTH DATETIME,@CURRENTDATEOFMONTH DATETIME,@EMP_IDs NVARCHAR(MAX)
	SELECT @FIRSTDATEOFMONTH = @FROM_DATE
	SELECT @CURRENTDATEOFMONTH = @TO_DATE

	--Rev 4.0
	DECLARE @SqlTable NVARCHAR(MAX)
	--End of Rev 4.0

	;WITH CTE AS (SELECT 1 AS DAYID,@FIRSTDATEOFMONTH AS FROMDATE,DATENAME(DW, @FIRSTDATEOFMONTH) AS DAYNAME
	UNION ALL
	SELECT CTE.DAYID + 1 AS DAYID,DATEADD(D, 1 ,CTE.FROMDATE),DATENAME(DW, DATEADD(D, 1 ,CTE.FROMDATE)) AS DAYNAME
	FROM CTE
	WHERE DATEADD(D,1,CTE.FROMDATE) <= @CURRENTDATEOFMONTH
	)
	SELECT FROMDATE AS SUNDAYDATE,DAYNAME INTO #TMPSHOWSUNDAY
	FROM CTE
	WHERE DAYNAME IN ('Sunday')
	OPTION (MAXRECURSION 1000)


	SELECT @DAYCOUNT=DATEDIFF(D, @FROM_DATE, @TO_DATE) +1

	set @days=(select @DAYCOUNT-count(DAYNAME) from #TMPSHOWSUNDAY)

	SET @EMP_IDs=@EMPID
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMP_IDs <> ''
		BEGIN
			SET @EMP_IDs = REPLACE(''''+@EMP_IDs+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMP_IDs+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	ELSE
		BEGIN
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee '
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TMPMASTEMPLOYEE') AND TYPE IN (N'U'))
		DROP TABLE #TMPMASTEMPLOYEE
	CREATE TABLE #TMPMASTEMPLOYEE(EMP_ID NUMERIC(18, 0) NOT NULL,EMP_UNIQUECODE VARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,EMP_CONTACTID NVARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPMASTEMPLOYEE (EMP_CONTACTID ASC)

	INSERT INTO #TMPMASTEMPLOYEE SELECT EMP_ID,EMP_UNIQUECODE,EMP_CONTACTID FROM tbl_master_employee

	IF OBJECT_ID('tempdb..#TMPEHEADING') IS NOT NULL
		DROP TABLE #TMPEHEADING
	CREATE TABLE #TMPEHEADING
		(
			HEADID BIGINT,HEADNAME NVARCHAR(800),HEADSHRTNAME NVARCHAR(800),PARRENTID BIGINT
		)
	
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#HorizontalAttendance') AND TYPE IN (N'U'))
			DROP TABLE #HorizontalAttendance
	
	-- Rev 4.0
	--CREATE TABLE #HorizontalAttendance (Empid NVARCHAR(200),EmpCode NVARCHAR(200),EMP_Name NVARCHAR(300),LoginID NVARCHAR(100),Department NVARCHAR(200))
	CREATE TABLE #HorizontalAttendance (Empid NVARCHAR(200),EmpCode NVARCHAR(200),EMP_Name NVARCHAR(300),
					LoginID NVARCHAR(100),Department NVARCHAR(200), Branch NVARCHAR(200) )
	-- End of Rev 4.0

	--FOR REPORT HEADER
	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT 1,'Employee Details [All Unit(s)]','Employee Details [All Unit(s)]',0
	UNION ALL
	SELECT 2,'Emp Code','EmpCode',1
	UNION ALL
	SELECT 3,'Name','EMP_Name',1
	UNION ALL
	SELECT 4,'Login ID','LoginID',1
	UNION ALL
	SELECT 5,'Department','Department',1
	-- Rev 4.0
	UNION ALL
	SELECT 6,'Branch','Branch',1
	-- End of Rev 4.0

	--FOR REPORT HEADER
	-- Rev 4.0
	--SET @SLHEADID=5
	--SET @PARENTID=5
	SET @SLHEADID=6
	SET @PARENTID=6
	-- End of Rev 4.0

	DECLARE @emp_contactId NVARCHAR(100)
	SET @COLUMN_DATE =@FROM_DATE

	IF OBJECT_ID('tempdb..#TMPATTENDACE') IS NOT NULL
			DROP TABLE #TMPATTENDACE
	CREATE TABLE #TMPATTENDACE(EmpCode NVARCHAR(100),EMP_NAME NVARCHAR(300),LoginID NVARCHAR(30),Department NVARCHAR(200),user_id BIGINT,
		LOGGEDIN NVARCHAR(30),LOGEDOUT NVARCHAR(30),ATTEN_STATUS NVARCHAR(300),duration_HR NVARCHAR(30),duration_MIN NVARCHAR(30),cnt_internalId NVARCHAR(100)
		,DISTANCE_COVERED NVARCHAR(30),IDEAL_TIME NVARCHAR(30),ORDERVALUE NVARCHAR(30),IMAGE_NAME NVARCHAR(max)	
		-- Rev 4.0
		, Branch NVARCHAR(200)
		-- End of Rev 4.0
		)
		--Rev work 2.0
		IF @ISONLYLOGINDATA=1
		  Begin
			-- Rev 3.0
			--ALTER TABLE #TMPATTENDACE ADD loginloation NVARCHAR(200)
			ALTER TABLE #TMPATTENDACE ADD loginloation NVARCHAR(max)
			-- End of Rev 3.0
		  End
		IF @ISONLYLOGOUTDATA=1
		  Begin
			-- Rev 3.0
			--ALTER TABLE #TMPATTENDACE ADD logoutloation NVARCHAR(200)
			ALTER TABLE #TMPATTENDACE ADD logoutloation NVARCHAR(max)
			-- End of Rev 3.0
		  End
		IF @ShowFullday =1
		  Begin
			ALTER TABLE #TMPATTENDACE ADD FullDay INT
		  End
		--End of rev work 2.0
		-- Rev 5.0
		IF @ShowFirstVisitTime=1
		  Begin
			ALTER TABLE #TMPATTENDACE ADD  FirstVisitTime NVARCHAR(30)
		  End
		IF @ShowLastVisitTime=1
		  Begin
			ALTER TABLE #TMPATTENDACE ADD LastVisitTime NVARCHAR(30)
		  End
		-- End of Rev 5.0
		
		IF OBJECT_ID('tempdb..#TMPATTENDACESUMMARY') IS NOT NULL
			DROP TABLE #TMPATTENDACESUMMARY
	CREATE TABLE #TMPATTENDACESUMMARY(EmpCode NVARCHAR(100),EMP_NAME NVARCHAR(300),LoginID NVARCHAR(50),Department NVARCHAR(200),user_id BIGINT,
		LOGGEDIN NVARCHAR(30),LOGEDOUT NVARCHAR(30),ATTEN_STATUS NVARCHAR(300),duration_HR NVARCHAR(30),duration_MIN INT,cnt_internalId NVARCHAR(100)
		-- Rev 4.0
		, Branch NVARCHAR(200)
		-- End of Rev 4.0
		)

		IF OBJECT_ID('tempdb..#TMPATTENDACESTATUS') IS NOT NULL
			DROP TABLE #TMPATTENDACESTATUS
	CREATE TABLE #TMPATTENDACESTATUS(EmpCode NVARCHAR(100),ATTEN_STATUS NVARCHAR(300),cnt_internalId NVARCHAR(100))

	IF OBJECT_ID('tempdb..#TMPATTENDACEESTIMATESUMMARY') IS NOT NULL
			DROP TABLE #TMPATTENDACEESTIMATESUMMARY
	CREATE TABLE #TMPATTENDACEESTIMATESUMMARY(Estimate int,cnt_internalId NVARCHAR(100))

	-- Rev 4.0
	IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
		DROP TABLE #BRANCH_LIST
	CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

	IF @BRANCHID<>''
		BEGIN
			SET @SqlTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @SqlTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @SqlTable
		END
	-- End of Rev 4.0

	SET @LOOPCOUNT=1
	IF @DAYCOUNT>0
	BEGIN
		WHILE @LOOPCOUNT<=@DAYCOUNT
			BEGIN
				
				SET @sqlStrTable=''
				SET @sqlStrTable = 'ALTER TABLE #HorizontalAttendance ADD '
				SET @sqlStrTable += '['+RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']' + ' NVARCHAR(50) NULL, '
				SET @sqlStrTable += '[In_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL, '

				--Rev work 2.0
				IF @ISONLYLOGINDATA=1
				Begin
				SET @sqlStrTable += '[Login_Location_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(max) NULL, '
				End
				--End of rev work 2.0

				SET @sqlStrTable += '[Out_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL, '	
				-- Rev 5.0
				IF @ShowFirstVisitTime=1
				BEGIN
					SET @sqlStrTable += '[FirstVisitTime_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL, '
				END
				IF @ShowLastVisitTime=1
				BEGIN
					SET @sqlStrTable += '[LastVisitTime_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL, '
				END
				-- End of Rev 5.0
				--Rev work 2.0
				IF @ISONLYLOGOUTDATA=1
				Begin
				SET @sqlStrTable += '[Logout_Location_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(max) NULL, '
				End
				--End of rev work 2.0			
				SET @sqlStrTable += '[Duration_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL, '
				SET @sqlStrTable += '[Status_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(100) NULL '

				IF @TotalKMTravelled=1
				BEGIN
				SET @sqlStrTable += ',[TotalKMTravelled_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL '
				END
				IF @SecondarySalesValue=1
				BEGIN
				SET @sqlStrTable += ',[SecondarySalesValue_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL '
				END
				IF @IdleTimeCount=1
				BEGIN
				SET @sqlStrTable += ',[IdleTimeCount_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL '
				END
				--Rev work 2.0
				IF @ShowFullday =1
				BEGIN
				SET @sqlStrTable += ',[FullDay_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL '
				END
				--End of Rev work 2.0
				IF @ShowAttendanceSelfie=1
				BEGIN
				SET @sqlStrTable += ',[ShowAttendanceSelfie_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(max) NULL '
				END
				--select @sqlStrTable
				EXEC SP_EXECUTESQL @sqlStrTable
					
					--Rev work 2.0	
					INSERT INTO #TMPATTENDACE 
					-- Rev 4.0
					--EXEC [PRC_FTSHORIZONTALATTENDANCE_FETCH] @FROM_DATE=@COLUMN_DATE,@EMPID=@EMPID,@SelfieURL=@SelfieURL,@Userid=@Userid
					--,@ShowFullday=@ShowFullday,@ISONLYLOGINDATA=@ISONLYLOGINDATA,@ISONLYLOGOUTDATA=@ISONLYLOGOUTDATA
					-- Rev 5.0
					--EXEC [PRC_FTSHORIZONTALATTENDANCE_FETCH] @FROM_DATE=@COLUMN_DATE,@EMPID=@EMPID,@SelfieURL=@SelfieURL,@Userid=@Userid
					--,@ShowFullday=@ShowFullday,@ISONLYLOGINDATA=@ISONLYLOGINDATA,@ISONLYLOGOUTDATA=@ISONLYLOGOUTDATA, @BRANCHID=@BRANCHID
					EXEC [PRC_FTSHORIZONTALATTENDANCE_FETCH] @FROM_DATE=@COLUMN_DATE,@EMPID=@EMPID,@SelfieURL=@SelfieURL,@Userid=@Userid
					,@ShowFullday=@ShowFullday,@ISONLYLOGINDATA=@ISONLYLOGINDATA,@ISONLYLOGOUTDATA=@ISONLYLOGOUTDATA, @BRANCHID=@BRANCHID,
					@ShowFirstVisitTime=@ShowFirstVisitTime, @ShowLastVisitTime=@ShowLastVisitTime
					-- End of Rev 5.0
					-- End of Rev 4.0
					--End of Rev work 2.0

					INSERT INTO #TMPATTENDACESTATUS
					SELECT EmpCode,ATTEN_STATUS,cnt_internalId FROM #TMPATTENDACE
					IF @FIRSTTIME=1
					BEGIN
						SET @sqlStrTable=''
						-- Rev 4.0
						--SET @sqlStrTable = 'INSERT INTO #HorizontalAttendance ( Empid,EmpCode,EMP_Name,LoginID,Department,'
						SET @sqlStrTable = 'INSERT INTO #HorizontalAttendance ( Empid,EmpCode,EMP_Name,LoginID,Department,Branch,'
						-- End of Rev 4.0
						SET @sqlStrTable += '[In_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '],'
						--Rev work 2.0
						IF @ISONLYLOGINDATA=1
						 Begin							
							SET @sqlStrTable += '[Login_Location_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '],'
						 End
						--End of rev work 2.0
						SET @sqlStrTable += '[Out_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '],'
						-- Rev 5.0
						IF @ShowFirstVisitTime=1
						BEGIN
							SET @sqlStrTable += ' [FirstVisitTime_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '], '
						END
						IF @ShowLastVisitTime=1
						BEGIN
							SET @sqlStrTable += ' [LastVisitTime_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '], '
						END
						-- End of Rev 5.0
						--Rev work 2.0
						IF @ISONLYLOGOUTDATA=1
						 Begin
							SET @sqlStrTable += '[Logout_Location_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '],'
						 End
						--End of rev work 2.0
						SET @sqlStrTable += '[Duration_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '],'
						SET @sqlStrTable += '[Status_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '

						IF @TotalKMTravelled=1
						BEGIN
						SET @sqlStrTable += ' ,[TotalKMTravelled_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'
						END
						IF @SecondarySalesValue=1
						BEGIN
						SET @sqlStrTable += ' ,[SecondarySalesValue_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'
						END
						IF @IdleTimeCount=1
						BEGIN
						SET @sqlStrTable += ' ,[IdleTimeCount_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'
						END
						--Rev work 2.0
						IF @ShowFullday =1
						BEGIN
						SET @sqlStrTable += ' ,[FullDay_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'
						END
						--End of Rev work 2.0
						IF @ShowAttendanceSelfie=1
						BEGIN
						SET @sqlStrTable += ' ,[ShowAttendanceSelfie_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
						END
						
						SET @sqlStrTable += ' ) '
						-- Rev 4.0
						--SET @sqlStrTable += ' SELECT cnt_internalId,EmpCode,EMP_NAME,LoginID,Department,LOGGEDIN, '
						SET @sqlStrTable += ' SELECT cnt_internalId,EmpCode,EMP_NAME,LoginID,Department,Branch,LOGGEDIN, '
						-- End of Rev 4.0
						--Rev work 2.0
						IF @ISONLYLOGINDATA=1
							Begin
								SET @sqlStrTable += ' loginloation, '
							End
						--End of rev work 2.0
						SET @sqlStrTable += ' LOGEDOUT, '
						-- Rev 5.0
						IF @ShowFirstVisitTime=1
						BEGIN
							SET @sqlStrTable += ' FirstVisitTime, '
						END
						IF @ShowLastVisitTime=1
						BEGIN
							SET @sqlStrTable += ' LastVisitTime, '
						END
						-- End of Rev 5.0
						--Rev work 2.0
						IF @ISONLYLOGOUTDATA=1
							Begin
								SET @sqlStrTable += ' logoutloation, '
							End
						--End of rev work 2.0

						SET @sqlStrTable += ' duration_HR,ATTEN_STATUS '
						IF @TotalKMTravelled=1
						BEGIN
							SET @sqlStrTable += ' ,DISTANCE_COVERED '
						END
						IF @SecondarySalesValue=1
						BEGIN
							SET @sqlStrTable += ' ,ORDERVALUE '
						END
						IF @IdleTimeCount=1
						BEGIN
							SET @sqlStrTable += ' ,IDEAL_TIME '
						END
						--Rev work 2.0
						IF @ShowFullday=1
						BEGIN
							SET @sqlStrTable += ' ,FullDay '
						END
						--End of Rev work 2.0
						IF @ShowAttendanceSelfie=1
						BEGIN
							SET @sqlStrTable += ' ,IMAGE_NAME '
						END
						SET @sqlStrTable += '  FROM #TMPATTENDACE '

						--select @sqlStrTable
						EXEC SP_EXECUTESQL @sqlStrTable						

						SET @FIRSTTIME=0
					
					END
					ELSE IF @FIRSTTIME=0
					BEGIN
						SET @sqlStrTable=''
						SET @sqlStrTable = ' UPDATE TEMP  SET '
						SET @sqlStrTable += 'TEMP.[In_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.LOGGEDIN, '
						--Rev work 2.0
						If @ISONLYLOGINDATA=1
						  Begin
							SET @sqlStrTable += 'TEMP.[Login_Location_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.loginloation, '
						  End
						--end of rev work 2.0
						SET @sqlStrTable += 'TEMP.[Out_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.LOGEDOUT, '
						--Rev work 2.0
						If @ISONLYLOGOUTDATA=1
						  Begin
							SET @sqlStrTable += 'TEMP.[Logout_Location_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.logoutloation, '
						  End
						--end of rev work 2.0
						SET @sqlStrTable += 'TEMP.[Duration_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.duration_HR, '
						SET @sqlStrTable += 'TEMP.[Status_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] =T.ATTEN_STATUS '

						IF @TotalKMTravelled=1
						BEGIN
						SET @sqlStrTable += ' ,TEMP.[TotalKMTravelled_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.DISTANCE_COVERED '
						END
						IF @SecondarySalesValue=1
						BEGIN
						SET @sqlStrTable += ' ,TEMP.[SecondarySalesValue_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.ORDERVALUE '
						END
						IF @IdleTimeCount=1
						BEGIN
						SET @sqlStrTable += ' ,TEMP.[IdleTimeCount_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.IDEAL_TIME '
						END
						--Rev work 2.0
						IF @ShowFullday=1
						BEGIN
						SET @sqlStrTable += ' ,TEMP.[FullDay_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.FullDay '
						END
						--End of Rev work 2.0
						IF @ShowAttendanceSelfie=1
						BEGIN
						SET @sqlStrTable += ' ,TEMP.[ShowAttendanceSelfie_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.IMAGE_NAME '
						END
						-- Rev 5.0
						IF @ShowFirstVisitTime=1
						BEGIN
							SET @sqlStrTable += ' ,TEMP.[FirstVisitTime_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.FirstVisitTime '
						END
						IF @ShowLastVisitTime=1
						BEGIN
							SET @sqlStrTable += ' ,TEMP.[LastVisitTime_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.LastVisitTime '
						END
						-- End of Rev 5.0

						SET @sqlStrTable += ' FROM #HorizontalAttendance TEMP INNER JOIN  '
						SET @sqlStrTable += '(SELECT * FROM #TMPATTENDACE )T ON T.cnt_internalId=TEMP.Empid '
						
						--SET @sqlStrTable += ' WHERE Empid='''+@emp_contactId+''' '
						EXEC SP_EXECUTESQL @sqlStrTable

					END
					TRUNCATE TABLE #TMPATTENDACE

					--FOR REPORT HEADER
					SET @PARENTID=@SLHEADID+1
					
					INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
					SELECT @SLHEADID+1 AS HEADID,CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105) AS HEADNAME,RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,0 AS PARRENTID 

					INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
					SELECT @SLHEADID+2 AS HEADID,'In-Time' AS HEADNAME,'In_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					
					--Rev work 2.0
					IF @ISONLYLOGINDATA=1
					  Begin
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+3 AS HEADID,'Login Location' AS HEADNAME,'Login_Location_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					 End
					--End of rev work 2.0
					INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
					--Rev work 2.0
					--SELECT @SLHEADID+3 AS HEADID,'Out Time' AS HEADNAME,'Out_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					SELECT @SLHEADID+4 AS HEADID,'Out Time' AS HEADNAME,'Out_Time_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					
					-- Rev 5.0
					IF @ShowFirstVisitTime=1
					BEGIN
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+5 AS HEADID,'First Call Time' AS HEADNAME,'FirstVisitTime_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					END

					IF @ShowLastVisitTime=1
					BEGIN
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+6 AS HEADID,'Last Call Time' AS HEADNAME,'LastVisitTime_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					END
					-- End of Rev 5.0

					IF @ISONLYLOGOUTDATA=1
					  Begin
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+7 AS HEADID,'Logout Location' AS HEADNAME,'Logout_Location_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					 End
					--End of rev work 2.0

					INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
					--Rev work 2.0
					--SELECT @SLHEADID+4 AS HEADID,'Duration' AS HEADNAME,'Duration_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					SELECT @SLHEADID+8 AS HEADID,'Duration' AS HEADNAME,'Duration_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					--End of rev work 2.0

					INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
					--Rev work 2.0
					--SELECT @SLHEADID+5 AS HEADID,'Status' AS HEADNAME,'Status_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					SELECT @SLHEADID+9 AS HEADID,'Status' AS HEADNAME,'Status_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
					--End of Rev work 2.0

					IF @TotalKMTravelled=1
					BEGIN
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						--Rev work 2.0
						--SELECT @SLHEADID+6 AS HEADID,'Total KM Travelled' AS HEADNAME,'TotalKMTravelled_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
						SELECT @SLHEADID+10 AS HEADID,'Total KM Travelled' AS HEADNAME,'TotalKMTravelled_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
						--End of Rev work 2.0
					END
					IF @SecondarySalesValue=1
					BEGIN
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						--Rev work 2.0
						--SELECT @SLHEADID+7 AS HEADID,'Secondary Sales Value' AS HEADNAME,'SecondarySalesValue_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
						SELECT @SLHEADID+11 AS HEADID,'Secondary Sales Value' AS HEADNAME,'SecondarySalesValue_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
						--End of Rev work 2.0
					END
					IF @IdleTimeCount=1
					BEGIN
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
						--Rev work 2.0 
						--SELECT @SLHEADID+8 AS HEADID,'Idle Time Count' AS HEADNAME,'IdleTimeCount_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
						SELECT @SLHEADID+12 AS HEADID,'Idle Time Count' AS HEADNAME,'IdleTimeCount_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
						--End of Rev work 2.0
					END
					--Rev work 2.0
					IF @ShowFullday=1
					BEGIN
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+13 AS HEADID,'Full Day' AS HEADNAME,'FullDay_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 						
					END
					--End of Rev work 2.0
					IF @ShowAttendanceSelfie=1
					BEGIN
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						--Rev work 2.0
						--SELECT @SLHEADID+9 AS HEADID,'Show Attendance Selfie' AS HEADNAME,'ShowAttendanceSelfie_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
						SELECT @SLHEADID+14 AS HEADID,'Show Attendance Selfie' AS HEADNAME,'ShowAttendanceSelfie_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 
						--End of Rev work 2.0
					END
					--Rev work 2.0
					--SET @SLHEADID=@SLHEADID+9
					SET @SLHEADID=@SLHEADID+12
					--End of Rev work 2.0

					--FOR REPORT HEADER


				SET @COLUMN_DATE=CONVERT(NVARCHAR(10),(SELECT DATEADD(D, 1, @COLUMN_DATE)),120)
				SET @LOOPCOUNT=@LOOPCOUNT+1
			END
	END

	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT @SLHEADID+1,'Summary','Summary',0
	UNION ALL
	SELECT @SLHEADID+2,'Late(s)','Late',@SLHEADID+1
	UNION ALL
	SELECT @SLHEADID+3,'Present','Present',@SLHEADID+1
	UNION ALL
	SELECT @SLHEADID+4,'Weekly Off','WeeklyOff',@SLHEADID+1
	UNION ALL
	SELECT @SLHEADID+5,'Absent','Absent',@SLHEADID+1

	IF @TotalKMTravelled=1
	BEGIN
	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT @SLHEADID+6,'Total KM Travelled','TotalKMTravelled',@SLHEADID+1
	END
	IF @SecondarySalesValue=1
	BEGIN
	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT @SLHEADID+7,'Secondary Sales Value','SecondarySalesValue',@SLHEADID+1
	END
	IF @IdleTimeCount=1
	BEGIN
	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT @SLHEADID+8,'Idle Time Count','IdleTimeCount',@SLHEADID+1
	END

	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT @SLHEADID+9,'Working Hour','WorkingHour',0
	UNION ALL
	SELECT @SLHEADID+10,'Estimated','Estimated',@SLHEADID+9
	UNION ALL
	SELECT @SLHEADID+11,'Actual','Actual',@SLHEADID+9
	UNION ALL
	SELECT @SLHEADID+12,'Remaining','Remaining',@SLHEADID+9

	ALTER TABLE #HorizontalAttendance ADD Summary NVARCHAR(100)
	ALTER TABLE #HorizontalAttendance ADD Late NVARCHAR(100)
	ALTER TABLE #HorizontalAttendance ADD Present NVARCHAR(100)
	ALTER TABLE #HorizontalAttendance ADD WeeklyOff NVARCHAR(100)
	ALTER TABLE #HorizontalAttendance ADD Absent NVARCHAR(100)

	IF @TotalKMTravelled=1
	BEGIN
	ALTER TABLE #HorizontalAttendance ADD TotalKMTravelled NVARCHAR(100)
	END
	IF @SecondarySalesValue=1
	BEGIN
	ALTER TABLE #HorizontalAttendance ADD SecondarySalesValue NVARCHAR(100)
	END
	IF @IdleTimeCount=1
	BEGIN
	ALTER TABLE #HorizontalAttendance ADD IdleTimeCount NVARCHAR(100)
	END

	ALTER TABLE #HorizontalAttendance ADD WorkingHour NVARCHAR(100)
	ALTER TABLE #HorizontalAttendance ADD Estimated NVARCHAR(100)
	ALTER TABLE #HorizontalAttendance ADD Actual NVARCHAR(100)
	ALTER TABLE #HorizontalAttendance ADD Remaining NVARCHAR(100)

	-- Rev 4.0 
	--INSERT INTO #TMPATTENDACESUMMARY EXEC [PRC_FTSHORIZONTALATTENDANCESUMMARY_FETCH] @FROM_DATE=@FROM_DATE,@TO_DATE=@TO_DATE,@EMPID=@EMPID,@Userid=@Userid
	INSERT INTO #TMPATTENDACESUMMARY EXEC [PRC_FTSHORIZONTALATTENDANCESUMMARY_FETCH] @FROM_DATE=@FROM_DATE,@TO_DATE=@TO_DATE,
				@EMPID=@EMPID,@Userid=@Userid,@BRANCHID=@BRANCHID
	-- End of Rev 4.0

	--SELECT SUM(duration_MIN),COUNT(ATTEN_STATUS) AS ATTEN_STATUS,cnt_internalId FROM #TMPATTENDACESUMMARY GROUP BY ATTEN_STATUS,cnt_internalId

	--UPDATE #HorizontalAttendance SET Late='0',Present='0',WeeklyOff='0',Absent='0',Estimated='0',Actual='0',Remaining='0'

	update ordr set ordr.Actual= T.ACTUAL from #HorizontalAttendance as ordr inner join (
	SELECT RIGHT('0' + CAST(CAST(SUM(duration_MIN) AS VARCHAR)/ 60 AS VARCHAR),3)  + ':' +RIGHT('0' + CAST(CAST(SUM(duration_MIN) AS VARCHAR) % 60 AS VARCHAR),2)	
	 ACTUAL,COUNT(ATTEN_STATUS)PRSNT,cnt_internalId  
	from #TMPATTENDACESUMMARY WHERE ATTEN_STATUS='Present' group by ATTEN_STATUS,cnt_internalId 
	)T on ordr.Empid=T.cnt_internalId

	update ordr set Present=T.PRSNT from #HorizontalAttendance as ordr inner join (
	SELECT COUNT(ATTEN_STATUS)PRSNT,cnt_internalId  
	from #TMPATTENDACESTATUS WHERE ATTEN_STATUS='Present' group by ATTEN_STATUS,cnt_internalId 
	)T on ordr.Empid=T.cnt_internalId

	update ordr set WeeklyOff=T.PRSNT from #HorizontalAttendance as ordr inner join (
	SELECT COUNT(ATTEN_STATUS)PRSNT,cnt_internalId  
	from #TMPATTENDACESTATUS WHERE ATTEN_STATUS='Weekly Off' group by ATTEN_STATUS,cnt_internalId 
	)T on ordr.Empid=T.cnt_internalId

	update ordr set Absent=T.PRSNT from #HorizontalAttendance as ordr inner join (
	SELECT COUNT(ATTEN_STATUS)PRSNT,cnt_internalId  
	from #TMPATTENDACESTATUS WHERE ATTEN_STATUS='Not Logged In' group by ATTEN_STATUS,cnt_internalId 
	)T on ordr.Empid=T.cnt_internalId

	IF @SecondarySalesValue=1
	BEGIN
	update ordr set ordr.SecondarySalesValue=T.Ordervalue from #HorizontalAttendance as ordr 
	inner join (
	 select SUM(Ordervalue)AS Ordervalue,userID,user_contactId
	  from tbl_trans_fts_Orderupdate ORDR 
	 INNER JOIN TBL_MASTER_SHOP SP ON ORDR.Shop_Code=SP.SHOP_CODE AND SP.type NOT IN (2,4) 
	 INNER JOIN tbl_master_user USR ON ORDR.userID=USR.user_id
	 WHERE CAST(Orderdate AS DATE) BETWEEN @FROM_DATE AND @TO_DATE
	 GROUP BY userID,user_contactId
	)T on ordr.Empid=T.user_contactId
	END

	IF @TotalKMTravelled=1
	BEGIN
	 update ordr set TotalKMTravelled=T.distance_covered from #HorizontalAttendance as ordr 
	 inner join (
	 SELECT SUM(distance_covered) AS distance_covered,User_Id,user_contactId FROM  ( 
	 SELECT ISNULL(distance_covered,0) AS distance_covered,T.User_Id,cast(SDate as date) as SDate,user_contactId FROM tbl_trans_shopuser T
	 INNER JOIN tbl_master_user USR ON T.User_Id=USR.user_id
	 WHERE CAST(T.SDate AS DATE) BETWEEN @FROM_DATE AND @TO_DATE
	 UNION ALL 
	 SELECT ISNULL(distance_covered,0) AS distance_covered,T.User_Id,cast(SDate as date) as SDate,user_contactId FROM TBL_TRANS_SHOPUSER_ARCH T
	 INNER JOIN tbl_master_user USR ON T.User_Id=USR.user_id
	 WHERE CAST(T.SDate AS DATE) BETWEEN @FROM_DATE AND @TO_DATE
	 ) T GROUP BY T.User_Id,user_contactId
	)T on ordr.Empid=T.user_contactId
	END

	IF @IdleTimeCount=1
	BEGIN
	--update ordr set IdleTimeCount=RIGHT('0' + CAST(CAST(T.IDEAL_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + ':' +RIGHT('0' + CAST(CAST(T.IDEAL_TIME AS VARCHAR) % 60 AS VARCHAR),2)
	update ordr set IdleTimeCount=ISNULL(CONVERT(NVARCHAR(50),cONVERT(DECIMAL(10,0),IDEAL_TIME/(select Value from FTS_APP_CONFIG_SETTINGS WHERE [Key]='idle_time'))),'0')
	from #HorizontalAttendance as ordr 
	inner join (
	SELECT user_id,SUM(IDEAL_TIME) AS IDEAL_TIME,user_contactId FROM(  
	SELECT user_contactId,USR.user_id,start_ideal_date_time,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(end_ideal_date_time,'00:00:00')) * 60) AS FLOAT) 
	+ CAST(DATEPART(MINUTE,ISNULL(end_ideal_date_time,'00:00:00')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) 
	- CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(start_ideal_date_time,'00:00:00')) * 60) AS FLOAT) 
	+ CAST(DATEPART(MINUTE,ISNULL(start_ideal_date_time,'00:00:00')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME FROM FTS_Ideal_Loaction 
		INNER JOIN tbl_master_user USR ON FTS_Ideal_Loaction.User_Id=USR.user_id
	WHERE CAST(start_ideal_date_time AS DATE) BETWEEN @FROM_DATE AND @TO_DATE
	) IDLE GROUP BY user_id,user_contactId
	)T on ordr.Empid=T.user_contactId
	END

	--truncate table #HorizontalAttendance
	update ordr set Late=T.LATE_CNT from #HorizontalAttendance as ordr inner join (
	SELECT USERID,COUNT(LATE_CNT) AS LATE_CNT,user_contactId FROM(
	SELECT A.User_Id AS USERID,
	CASE WHEN CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL((Login_datetime),'00:00:00')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL((Login_datetime),'00:00:00')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT)> 
	CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(MIN(EMPWHD.BeginTime),'00:00:00')) * 60) AS FLOAT) + 
	CAST(DATEPART(MINUTE,ISNULL(MIN(EMPWHD.BeginTime),'00:00:00')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) + MIN(EMPWHD.Grace) THEN COUNT(0) ELSE 0 END LATE_CNT,user_contactId
	FROM tbl_fts_UserAttendanceLoginlogout AS A 
	INNER JOIN tbl_master_user USR ON USR.user_id=A.User_Id 
	INNER JOIN #TMPMASTEMPLOYEE EMP ON EMP.emp_contactId=USR.user_contactId 
	INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId 
	INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours 
	INNER JOIN(
	SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails
	) EMPWHD ON EMPWHD.hourId=EMPWH.Id 

	WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),@FROM_DATE,120) AND CONVERT(NVARCHAR(10),@TO_DATE,120) 
	AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL AND A.Isonleave='false'
	AND EXISTS (SELECT TMP.emp_contactId FROM #EMPLOYEE_LIST TMP WHERE TMP.emp_contactId= USR.user_contactId)
	GROUP BY A.User_Id,A.Login_datetime,user_contactId) A WHERE LATE_CNT>0 GROUP BY USERID ,user_contactId
	)T on ordr.Empid=T.user_contactId


	INSERT INTO #TMPATTENDACEESTIMATESUMMARY
	select Estimate,EMPCTC.emp_cntId from tbl_trans_employeeCTC EMPCTC 
	INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours 
	INNER JOIN(
	SELECT @days*DATEDIFF(minute, BeginTime, EndTime) Estimate ,hourId
	FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id
	AND EXISTS (SELECT TMP.emp_contactId FROM #EMPLOYEE_LIST TMP WHERE TMP.emp_contactId= EMPCTC.emp_cntId)


	update ordr set ordr.Estimated= T.Estimate from #HorizontalAttendance as ordr 
	inner join (
	select RIGHT('0' + CAST(CAST(SUM(Estimate)/ 60 AS VARCHAR) AS VARCHAR),3)  + ':' +RIGHT('0' + CAST(CAST(SUM(Estimate) AS VARCHAR) % 60 AS VARCHAR),2) as Estimate
	,cnt_internalId from #TMPATTENDACEESTIMATESUMMARY
	group by cnt_internalId
	)T on ordr.Empid=T.cnt_internalId


	update ordr set ordr.Remaining= T.REMN from #HorizontalAttendance as ordr 
	inner join (
	select RIGHT('0' + CAST(CAST(SUM(REMN) AS VARCHAR)/ 60 AS VARCHAR),3)  + ':' +RIGHT('0' + CAST(CAST(SUM(REMN) AS VARCHAR) % 60 AS VARCHAR),2) as REMN,cnt_internalId
	 FROM (
	SELECT case when  SUM(Estimate)>ISNULL(SUM(duration_MIN),0) then SUM(Estimate)-ISNULL(SUM(duration_MIN),0) else 0 end AS REMN,
	EST.cnt_internalId from #TMPATTENDACEESTIMATESUMMARY EST
	LEFT OUTER JOIN	(
	SELECT ISNULL(SUM(duration_MIN),0) AS duration_MIN,cnt_internalId FROM #TMPATTENDACESUMMARY ACT WHERE ATTEN_STATUS='Present' 
	group by ATTEN_STATUS,cnt_internalId) E ON EST.cnt_internalId=E.cnt_internalId
	group by EST.cnt_internalId) R GROUP BY R.cnt_internalId
	)T on ordr.Empid=T.cnt_internalId


	SELECT * FROM #TMPEHEADING ORDER BY HEADID
	SELECT * FROM #HorizontalAttendance


	--SELECT * FROM #TMPATTENDACESTATUS

	--SELECT * FROM   tempdb.sys.columns WHERE  object_id = Object_id('tempdb..#HorizontalAttendance'); 

	DROP TABLE #HorizontalAttendance
	DROP TABLE #TMPEHEADING
	drop table #TMPSHOWSUNDAY
	drop table #TMPATTENDACESUMMARY
	DROP TABLE #TMPATTENDACEESTIMATESUMMARY
END
GO