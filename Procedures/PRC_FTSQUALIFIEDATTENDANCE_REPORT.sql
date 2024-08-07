--EXEC PRC_FTSQUALIFIEDATTENDANCE_REPORT '2022-10-11','2022-11-08','1,118,119,120,121,122,123,124,125','','',378
--EXEC PRC_FTSQUALIFIEDATTENDANCE_REPORT '2022-03-09','2022-03-09','1','EMA0000008,EMA0000016,EMA0000012,EMM0000002,EMA0000020','1,2,3,4,5,6,7,8',378
--EXEC PRC_FTSQUALIFIEDATTENDANCE_REPORT '2023-07-01','2023-08-28','','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSQUALIFIEDATTENDANCE_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSQUALIFIEDATTENDANCE_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSQUALIFIEDATTENDANCE_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@BRANCHID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@CHANNELID NVARCHAR(MAX)=NULL,
--Rev 4.0
@CONSIDERDAYEND NVARCHAR(1)=NULL,
--End of Rev 4.0
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 05/11/2022
Module	   : Qualified Attendance Report.Refer: 0025416
1.0		v2.0.35		Debashis	15/11/2022		Need to optimized Employee Attendance, Team Visit and Qualified Attendance reports in ITC Portal.Refer: 0025453
2.0		v2.0.41		Debashis	09/08/2023		A coloumn named as Gender needs to be added in all the ITC reports.Refer: 0026680
3.0		v2.0.45		Debashis	28/03/2024		In Application, please consider Saturday and Sunday for qualified attendance.Refer: 0027330
4.0		v2.0.47		Debashis	05/06/2024		Qualified attendance for the day to be considered only if the DS marks day end for ITC.Refer: 0027498
5.0		v2.0.47		Debashis	10/06/2024		A new coloumn "Total CDM Days" is required under the Summary section. It shall be placed at the end.Refer: 0027511
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	--Rev 1.0
	SET LOCK_TIMEOUT -1
	--End of Rev 1.0
	DECLARE @DAYCOUNT INT,@LOOPCOUNT INT,@FIRSTTIME BIT=1
	DECLARE @SqlStrTable NVARCHAR(MAX)
	DECLARE @COLUMN_DATE NVARCHAR(10)=@FROMDATE
	DECLARE @SLHEADID BIGINT,@PARENTID BIGINT

	--Rev 3.0
	--DECLARE @TOTALDAYS AS INT,@FIRSTDATEOFMONTH DATETIME,@CURRENTDATEOFMONTH DATETIME,@EMP_IDs NVARCHAR(MAX)
	--SELECT @FIRSTDATEOFMONTH = @FROMDATE
	--SELECT @CURRENTDATEOFMONTH = @TODATE

	--;WITH CTE AS (SELECT 1 AS DAYID,@FIRSTDATEOFMONTH AS FROMDATE,DATENAME(DW, @FIRSTDATEOFMONTH) AS DAYNAME
	--UNION ALL
	--SELECT CTE.DAYID + 1 AS DAYID,DATEADD(D, 1 ,CTE.FROMDATE),DATENAME(DW, DATEADD(D, 1 ,CTE.FROMDATE)) AS DAYNAME
	--FROM CTE
	--WHERE DATEADD(D,1,CTE.FROMDATE) <= @CURRENTDATEOFMONTH
	--)
	--SELECT FROMDATE AS SUNDAYDATE,DAYNAME INTO #TMPSHOWSUNDAY
	--FROM CTE
	--WHERE DAYNAME IN ('Sunday')
	--OPTION (MAXRECURSION 1000)

	--SELECT @DAYCOUNT=DATEDIFF(D, @FROMDATE, @TODATE) +1

	--SET @TOTALDAYS=(SELECT @DAYCOUNT-COUNT(DAYNAME) FROM #TMPSHOWSUNDAY)
	SELECT @DAYCOUNT=DATEDIFF(D, @FROMDATE, @TODATE) +1
	--End of Rev 3.0

	IF OBJECT_ID('tempdb..#TMPEHEADINGQA') IS NOT NULL
		DROP TABLE #TMPEHEADINGQA
	CREATE TABLE #TMPEHEADINGQA
		(
			HEADID BIGINT,HEADNAME NVARCHAR(800),HEADSHRTNAME NVARCHAR(800),PARRENTID BIGINT
		)
	
	IF OBJECT_ID('tempdb..#EMPLOYEEATTENDANCEQA') IS NOT NULL
	 DROP TABLE #EMPLOYEEATTENDANCEQA
	
	--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	CREATE TABLE #EMPLOYEEATTENDANCEQA (BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(200),EMPID NVARCHAR(200),EMPNAME NVARCHAR(300),OUTLETEMPSEX TINYINT,
	GENDERDESC NVARCHAR(100),DSTYPE NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(300),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),CONTACTNO NVARCHAR(100),CH_ID BIGINT,
	CHANNEL NVARCHAR(100),REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100))
	CREATE NONCLUSTERED INDEX IX1 ON #EMPLOYEEATTENDANCEQA (BRANCH_ID,EMPCODE)

	--FOR REPORT HEADER
	INSERT INTO #TMPEHEADINGQA(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT 1,'Employee Details [All Unit(s)]','Employee Details [All Unit(s)]',0
	UNION ALL
	SELECT 2,'Branch','BRANCH_DESCRIPTION',1	
	UNION ALL
	SELECT 3,'WD ID','REPORTTOUID',1
	UNION ALL
	SELECT 4,'DS','EMPID',1
	UNION ALL
	SELECT 5,'DS Name','EMPNAME',1
	--Rev 2.0
	--UNION ALL
	--SELECT 6,'DS Type','DSTYPE',1
	--UNION ALL
	--SELECT 7,'Channel','CHANNEL',1
	--SET @SLHEADID=7
	--SET @PARENTID=7
	UNION ALL
	SELECT 6,'Gender','GENDERDESC',1
	UNION ALL
	SELECT 7,'DS Type','DSTYPE',1
	UNION ALL
	SELECT 8,'Channel','CHANNEL',1
	SET @SLHEADID=8
	SET @PARENTID=8
	--End of Rev 2.0

	DECLARE @emp_contactId NVARCHAR(100)
	SET @COLUMN_DATE =@FROMDATE

	IF OBJECT_ID('tempdb..#TMPATTENDACEQA') IS NOT NULL
		DROP TABLE #TMPATTENDACEQA
	--Rev 1.0 && Two new columns have been added as STARTENDDATE NVARCHAR(10) & STARTENDDATEORDBY NVARCHAR(10)
	--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	--Rev 5.0 && A new column has been added as TOTALCDMDAYS
	CREATE TABLE #TMPATTENDACEQA(STARTENDDATE NVARCHAR(10),STARTENDDATEORDBY NVARCHAR(10),BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),
	EMPNAME NVARCHAR(300),OUTLETEMPSEX TINYINT,GENDERDESC NVARCHAR(100),CONTACTNO NVARCHAR(100),STATEID BIGINT,STATE NVARCHAR(100),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),
	REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100),DSTYPE NVARCHAR(300),CH_ID BIGINT,CHANNEL NVARCHAR(100),PRESENTABSENT INT,TOTALCDMDAYS INT)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENDACEQA (BRANCH_ID,EMPCODE)

	--Rev 1.0
	IF OBJECT_ID('tempdb..#TMPATTENDACEQADET') IS NOT NULL
		DROP TABLE #TMPATTENDACEQADET
	--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	--Rev 5.0 && A new column has been added as TOTALCDMDAYS
	CREATE TABLE #TMPATTENDACEQADET(STARTENDDATE NVARCHAR(10),STARTENDDATEORDBY NVARCHAR(10),BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),
	EMPNAME NVARCHAR(300),OUTLETEMPSEX TINYINT,GENDERDESC NVARCHAR(100),CONTACTNO NVARCHAR(100),STATEID BIGINT,STATE NVARCHAR(100),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),
	REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100),DSTYPE NVARCHAR(300),CH_ID BIGINT,CHANNEL NVARCHAR(100),PRESENTABSENT INT,TOTALCDMDAYS INT)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENDACEQADET (BRANCH_ID,EMPCODE)
	--End of Rev 1.0

	IF OBJECT_ID('tempdb..#TMPEMPATTENDACESUMMARYQA') IS NOT NULL
		DROP TABLE #TMPEMPATTENDACESUMMARYQA
	--Rev 5.0 && A new column has been added as TOTALCDMDAYS
	CREATE TABLE #TMPEMPATTENDACESUMMARYQA(BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),TOTWORKINGDAYS INT,
	PRESENTABSENT INT,TOTALCDMDAYS INT)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPEMPATTENDACESUMMARYQA (BRANCH_ID,EMPCODE)

	--Rev 1.0
	--Rev 4.0
	--INSERT INTO #TMPATTENDACEQADET EXEC [PRC_FTSQUALIFIEDATTENDANCE_FETCH] @FROMDATE,@TODATE,@BRANCHID,@EMPID,@CHANNELID,@USERID
	INSERT INTO #TMPATTENDACEQADET EXEC [PRC_FTSQUALIFIEDATTENDANCE_FETCH] @FROMDATE,@TODATE,@BRANCHID,@EMPID,@CHANNELID,@CONSIDERDAYEND,@USERID
	--End of Rev 4.0

	--Rev 3.0
	--INSERT INTO #TMPEMPATTENDACESUMMARYQA(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,TOTWORKINGDAYS,PRESENTABSENT)
	--SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,@TOTALDAYS AS TOTWORKINGDAYS,SUM(PRESENTABSENT) AS PRESENTABSENT FROM #TMPATTENDACEQADET 
	--GROUP BY BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME
	--ORDER BY EMPCODE
	--Rev 5.0 && A new column has been added as TOTALCDMDAYS
	INSERT INTO #TMPEMPATTENDACESUMMARYQA(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,TOTWORKINGDAYS,PRESENTABSENT,TOTALCDMDAYS)
	SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,@DAYCOUNT AS TOTWORKINGDAYS,SUM(PRESENTABSENT) AS PRESENTABSENT,SUM(TOTALCDMDAYS) AS TOTALCDMDAYS FROM #TMPATTENDACEQADET 
	GROUP BY BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME
	ORDER BY EMPCODE
	--End of Rev 3.0
	--End of Rev 1.0

	SET @LOOPCOUNT=1
	IF @DAYCOUNT>0
		BEGIN
			WHILE @LOOPCOUNT<=@DAYCOUNT
				BEGIN
					SET @SqlStrTable=''
					SET @SqlStrTable='ALTER TABLE #EMPLOYEEATTENDANCEQA ADD '
					SET @SqlStrTable+='['+RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']' + ' NVARCHAR(50) NULL,'
					SET @SqlStrTable+='[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' INT NULL ' 

					EXEC SP_EXECUTESQL @SqlStrTable					

					SET @TODATE=@COLUMN_DATE

					--Rev 1.0
					--INSERT INTO #TMPATTENDACEQA EXEC [PRC_FTSQUALIFIEDATTENDANCE_FETCH] @COLUMN_DATE,@TODATE,@BRANCHID,@EMPID,@CHANNELID,@USERID
					--IF (SELECT COUNT(0) FROM #EMPLOYEEATTENDANCEQA A
					--	INNER JOIN #TMPATTENDACEQA B ON A.BRANCH_ID=B.BRANCH_ID AND A.EMPCODE=B.EMPCODE)>0
					--	SET @FIRSTTIME=0
					--ELSE
					--	SET @FIRSTTIME=1

					--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
					INSERT INTO #TMPATTENDACEQA(STARTENDDATE,STARTENDDATEORDBY,BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,CONTACTNO,STATEID,STATE,DEG_ID,
					DESIGNATION,DATEOFJOINING,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,DSTYPE,CH_ID,CHANNEL,PRESENTABSENT)
					SELECT STARTENDDATE,STARTENDDATEORDBY,BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,CONTACTNO,STATEID,STATE,DEG_ID,DESIGNATION,
					DATEOFJOINING,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,DSTYPE,CH_ID,CHANNEL,PRESENTABSENT FROM #TMPATTENDACEQADET WHERE STARTENDDATEORDBY BETWEEN @COLUMN_DATE AND @TODATE

					IF (SELECT COUNT(0) FROM #EMPLOYEEATTENDANCEQA A
						INNER JOIN #TMPATTENDACEQA B ON A.BRANCH_ID=B.BRANCH_ID AND A.EMPCODE=B.EMPCODE AND B.STARTENDDATEORDBY BETWEEN @COLUMN_DATE AND @TODATE)>0
						SET @FIRSTTIME=0
					ELSE
						SET @FIRSTTIME=1
					--End of Rev 1.0

					IF @FIRSTTIME=1
						BEGIN
							--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
							SET @SqlStrTable=''
							SET @SqlStrTable='INSERT INTO #EMPLOYEEATTENDANCEQA(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,CONTACTNO,STATEID,STATE,DEG_ID,'
							SET @SqlStrTable+='DESIGNATION,DATEOFJOINING,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,DSTYPE,CH_ID,CHANNEL,'
							SET @SqlStrTable+='[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
							SET @SqlStrTable+=') '
							SET @SqlStrTable+='SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,CONTACTNO,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,'
							SET @SqlStrTable+='REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,DSTYPE,CH_ID,CHANNEL,PRESENTABSENT '
							SET @SqlStrTable+='FROM #TMPATTENDACEQA '

							EXEC SP_EXECUTESQL @SqlStrTable

							SET @FIRSTTIME=0
						END
					ELSE IF @FIRSTTIME=0
						BEGIN
							--Rev 1.0
							--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
							SET @SqlStrTable=''
							SET @SqlStrTable='INSERT INTO #EMPLOYEEATTENDANCEQA(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,CONTACTNO,STATEID,STATE,DEG_ID,'
							SET @SqlStrTable+='DESIGNATION,DATEOFJOINING,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,DSTYPE,CH_ID,CHANNEL,'
							SET @SqlStrTable+='[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
							SET @SqlStrTable+=') '
							SET @SqlStrTable+='SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,CONTACTNO,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,'
							SET @SqlStrTable+='REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,DSTYPE,CH_ID,CHANNEL,PRESENTABSENT '
							SET @SqlStrTable+='FROM #TMPATTENDACEQA WHERE NOT EXISTS(SELECT EMPCODE FROM #EMPLOYEEATTENDANCEQA A WHERE A.BRANCH_ID=#TMPATTENDACEQA.BRANCH_ID AND A.EMPCODE=#TMPATTENDACEQA.EMPCODE) '
							
							EXEC SP_EXECUTESQL @sqlStrTable
							--End of Rev 1.0

							SET @SqlStrTable=''
							SET @SqlStrTable='UPDATE TEMP SET '
							SET @SqlStrTable+='TEMP.[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.PRESENTABSENT '
							SET @sqlStrTable+='FROM #EMPLOYEEATTENDANCEQA TEMP '
							SET @sqlStrTable+='INNER JOIN #TMPATTENDACEQA T ON TEMP.BRANCH_ID=T.BRANCH_ID AND TEMP.EMPCODE=T.EMPCODE '
						
							EXEC SP_EXECUTESQL @sqlStrTable
						END
						TRUNCATE TABLE #TMPATTENDACEQA
						--Rev 1.0
						DELETE FROM #TMPATTENDACEQADET WHERE STARTENDDATEORDBY BETWEEN @COLUMN_DATE AND @TODATE
						--End of Rev 1.0

						--FOR REPORT HEADER
						SET @PARENTID=@SLHEADID+1
					
						INSERT INTO #TMPEHEADINGQA(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+1 AS HEADID,CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105) AS HEADNAME,RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,0 AS PARRENTID 

						INSERT INTO #TMPEHEADINGQA(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+2 AS HEADID,'Present/Absent' AS HEADNAME,'PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 

						SET @SLHEADID=@SLHEADID+2

						--FOR REPORT HEADER

						SET @COLUMN_DATE=CONVERT(NVARCHAR(10),(SELECT DATEADD(D, 1, @COLUMN_DATE)),120)
						SET @LOOPCOUNT=@LOOPCOUNT+1
				END
		END		

	INSERT INTO #TMPEHEADINGQA(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT @SLHEADID+1,'Summary','Summary',0
	UNION ALL
	SELECT @SLHEADID+2,'Total Working Days','TOTWORKINGDAYS',@SLHEADID+1
	UNION ALL
	SELECT @SLHEADID+3,'Total Days Qualified Attendance','TOTDAYSPRESENT',@SLHEADID+1
	--Rev 5.0
	UNION ALL
	SELECT @SLHEADID+4,'Total CDM Days','TOTALCDMDAYS',@SLHEADID+1
	--End of Rev 5.0

	ALTER TABLE #EMPLOYEEATTENDANCEQA ADD Summary NVARCHAR(100)
	ALTER TABLE #EMPLOYEEATTENDANCEQA ADD TOTWORKINGDAYS INT DEFAULT(0) WITH VALUES
	ALTER TABLE #EMPLOYEEATTENDANCEQA ADD TOTDAYSPRESENT INT DEFAULT(0) WITH VALUES
	--Rev 5.0
	ALTER TABLE #EMPLOYEEATTENDANCEQA ADD TOTALCDMDAYS INT DEFAULT(0) WITH VALUES
	--End of Rev 5.0

	--Rev 1.0
	--INSERT INTO #TMPEMPATTENDACESUMMARYQA EXEC [PRC_FTSQUALIFIEDATTENDANCESUMMARY_FETCH] @FROMDATE,@TODATE,@BRANCHID,@EMPID,@CHANNELID,@USERID	

	--UPDATE EMPATT SET EMPATT.TOTWORKINGDAYS=T.TOTWORKINGDAYS FROM #EMPLOYEEATTENDANCEQA AS EMPATT 
	--INNER JOIN #TMPEMPATTENDACESUMMARYQA T ON EMPATT.BRANCH_ID=T.BRANCH_ID AND EMPATT.EMPCODE=T.EMPCODE

	--UPDATE EMPATT SET EMPATT.TOTDAYSPRESENT=T.TOTDAYSPRESENT FROM #EMPLOYEEATTENDANCEQA AS EMPATT 
	--INNER JOIN (SELECT BRANCH_ID,EMPCODE,SUM(PRESENTABSENT) AS TOTDAYSPRESENT FROM #TMPEMPATTENDACESUMMARYQA GROUP BY BRANCH_ID,EMPCODE) T ON EMPATT.BRANCH_ID=T.BRANCH_ID 
	--AND EMPATT.EMPCODE=T.EMPCODE
	
	--Rev 5.0 && A new column has been added as TOTALCDMDAYS
	UPDATE EMPATT SET EMPATT.TOTWORKINGDAYS=T.TOTWORKINGDAYS,EMPATT.TOTDAYSPRESENT=T.PRESENTABSENT,EMPATT.TOTALCDMDAYS=T.TOTALCDMDAYS FROM #EMPLOYEEATTENDANCEQA AS EMPATT 
	INNER JOIN #TMPEMPATTENDACESUMMARYQA T ON EMPATT.BRANCH_ID=T.BRANCH_ID AND EMPATT.EMPCODE=T.EMPCODE
	--End of Rev 1.0

	SELECT * FROM #TMPEHEADINGQA ORDER BY HEADID
	--Rev 1.0
	--SELECT * FROM #EMPLOYEEATTENDANCEQA
	SELECT * FROM #EMPLOYEEATTENDANCEQA ORDER BY EMPNAME
	--End of Rev 1.0

	DROP TABLE #EMPLOYEEATTENDANCEQA
	DROP TABLE #TMPEHEADINGQA
	--Rev 3.0
	--DROP TABLE #TMPSHOWSUNDAY
	--End of Rev 3.0
	DROP TABLE #TMPEMPATTENDACESUMMARYQA
	DROP TABLE #TMPATTENDACEQA
	DROP TABLE #TMPATTENDACEQADET

	SET NOCOUNT OFF
END
GO