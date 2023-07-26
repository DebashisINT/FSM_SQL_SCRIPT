
-- exec PRC_FTSExpenseReport @ACTION='LIST', @fromdate='2023-04-25', @todate='2023-04-25', @employee_list='',@HQid_list='',@expid_list='',@USER_ID=378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSExpenseReport]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSExpenseReport] AS' 
END
GO
ALTER Proc [PRC_FTSExpenseReport]
(
	@ACTION NVARCHAR(500)='',
	@fromdate DATETIME=NULL,
	@todate DATETIME=NULL,
	@employee_list NVARCHAR(MAX)='',
	@HQid_list NVARCHAR(MAX)='',
	@expid_list NVARCHAR(MAX)='',
	@REIMBURSEMENT_DATE DATETIME=NULL,
	@EMPID NVARCHAR(100)='',
	@USER_ID BIGINT=0
)
As
/*******************************************************************************************************************************************************************************
* Created by Sanchita for V2.0.40 on 04-05-2023. Work done in Controller, View and Model
 * A New Expense Report is Required for BP Poddar. Refer: 25833
 * Rev 1.0		Sanchita	V2.0.40		Need to implement Branch and Area in the Expense Register Report. Refer: 26185
 * Rev 2.0		Sanchita	V2.0.42		In Station and Out Station expense data is not showing in the Expense Register Report. Refer: 26618
*******************************************************************************************************************************************************************************/
Begin
	if (@ACTION='LIST')
	BEGIN
		DECLARE @STR NVARCHAR(MAX)=''
		DECLARE @IsShowReimbursementTypeInAttendance NVARCHAR(10) = (SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsShowReimbursementTypeInAttendance')

		CREATE TABLE #TEMP_HQ(city_id VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
		CREATE TABLE #TEMP_EXPENSETYPE(expid VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
		CREATE TABLE #TEMP_EMPLOYEE(EMPID VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
		CREATE TABLE #TEMP_CONTACT(CONTACTID VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS,CON_NAME VARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS)
		
		CREATE TABLE #TEMP_shopActivitysubmit (REIMBURSEMENT_DATE DATETIME,
				HQ_NAME NVARCHAR(100),
				EMPID NVARCHAR(100),
				EMP_NAME NVARCHAR(500),
				EMP_DESIGNATION NVARCHAR(500),
				REPORTTO_NAME NVARCHAR(500),
				VISIT_LOCATION NVARCHAR(500),
				STATEID BIGINT,
				EMPGRADEID BIGINT,
				AREA_LOCATION_ID INT,
				USERID BIGINT)


		IF(ISNULL(@HQid_list,'')<>'')
		BEGIN    
			INSERT INTO #TEMP_HQ
			SELECT s FROM DBO.GetSplit(',',@HQid_list)
		END
		ELSE
		BEGIN
			INSERT INTO #TEMP_HQ 
			SELECT distinct C.city_id FROM tbl_master_city C INNER JOIN tbl_master_address E on C.city_id = E.add_city 
				where E.add_entity='employee' and E.add_addressType='Office'
		END

		IF(ISNULL(@expid_list,'')<>'')
			BEGIN    
				INSERT INTO #TEMP_EXPENSETYPE
				SELECT s FROM DBO.GetSplit(',',@expid_list)
			END
			ELSE
				BEGIN
					INSERT INTO #TEMP_EXPENSETYPE 
					SELECT VST_ID FROM Master_VisitLocation
				END

		IF(ISNULL(@employee_list,'')<>'')
			BEGIN
				INSERT INTO #TEMP_EMPLOYEE
				SELECT s FROM DBO.GetSplit(',',@employee_list) WHERE S IN (SELECT user_contactId FROM tbl_master_user WHERE user_inactive='N')
			END
		ELSE
			BEGIN
				INSERT INTO #TEMP_EMPLOYEE 
				SELECT emp_contactId FROM tbl_master_employee WHERE emp_contactId IN (SELECT user_contactId FROM tbl_master_user WHERE user_inactive='N')
			END

		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'EXPENSE_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE EXPENSE_REPORT
			(
				SL BIGINT,
				REIMBURSEMENT_DATE DATETIME,
				HQ_NAME NVARCHAR(100),
				EMPID NVARCHAR(100),
				EMP_NAME NVARCHAR(500),
				EMP_DESIGNATION NVARCHAR(500),
				REPORTTO_NAME NVARCHAR(500),
				EXPENSE_TYPE NVARCHAR(500),
				OTHER_ALLOWANCE NUMERIC(18,2),
				DAILY_ALLOWANCE NUMERIC(18,2),
				TOTAL_ALLOWANCE NUMERIC(18,2),
				IS_IMAGE BIT,
				BRANCHNAME NVARCHAR(200), 
				AREANAME NVARCHAR(1000),
				USER_ID BIGINT	
			)
			CREATE NONCLUSTERED INDEX IX1 ON EXPENSE_REPORT (SL)
		END
		DELETE FROM EXPENSE_REPORT WHERE [USER_ID]=@USER_ID

		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USER_ID)		
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

		--  CREATE TEMP TABLE FOR shopActivitysubmit ---
		SET @STR = ''
		SET @STR=@STR+ 'INSERT INTO #TEMP_shopActivitysubmit (REIMBURSEMENT_DATE, HQ_NAME, EMPID, EMP_NAME, EMP_DESIGNATION, '
		SET @STR=@STR+ 'REPORTTO_NAME, VISIT_LOCATION, USERID, STATEID, EMPGRADEID, AREA_LOCATION_ID) '

		SET @STR=@STR+ 'SELECT VISITED_DATE, city_name, EMPID,EMP_NAME,DESIGNATION,SUPERVISOR_NAME,'
		SET @STR=@STR+ '(CASE WHEN MAX(StationCode)=0 THEN ''In Station'' WHEN  MAX(StationCode)=1 THEN ''Ex Station'' ELSE ''Out Station'' END ) VISIT_LOCATION, '
		SET @STR=@STR+ 'USERID,STATEID,EMPGRADEID,AREA_LOCATION_ID  FROM ( '
		SET @STR=@STR+ 'SELECT  VISITED_DATE, CT.city_name,EMP.emp_uniqueCode AS EMPID,  '
		SET @STR=@STR+ '(ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''')) AS EMP_NAME, '
		SET @STR=@STR+ 'DESG.deg_designation DESIGNATION,  ISNULL(CNT_REP.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT_REP.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT_REP.CNT_LASTNAME,'''') SUPERVISOR_NAME, ' 
		SET @STR=@STR+ 'SA.StationCode , U.user_id AS USERID, AD.add_state AS STATEID, CTC.Emp_Grade AS EMPGRADEID, ATTN.AREA_LOCATION_ID '
		SET @STR=@STR+ 'FROM tbl_trans_shopActivitysubmit SA '
		SET @STR=@STR+ 'INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTN ON SA.User_Id=ATTN.user_id AND CONVERT(DATE,visited_date)=CONVERT(DATE,WORK_DATETIME) AND Isonleave=''false'' AND Login_datetime IS NOT NULL '
		SET @STR=@STR+ 'INNER JOIN TBL_MASTER_USER U ON SA.User_Id=U.user_id '
		SET @STR=@STR+ 'INNER JOIN TBL_MASTER_EMPLOYEE EMP ON U.user_contactId=emp_contactId '
		SET @STR=@STR+ 'INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=EMP.emp_contactId '
		SET @STR=@STR+ 'AND EXISTS (SELECT 1 FROM #TEMP_EMPLOYEE EMP WHERE EMP.EMPID=CNT.cnt_internalId)  '
		SET @STR=@STR+ 'INNER JOIN tbl_trans_employeeCTC CTC ON U.user_contactId = CTC.emp_cntId '
		SET @STR=@STR+ 'LEFT OUTER JOIN TBL_MASTER_ADDRESS AD ON U.user_contactId = AD.add_cntId '
		SET @STR=@STR+ 'INNER JOIN TBL_MASTER_CITY CT ON AD.add_city=CT.city_id '
		SET @STR=@STR+ 'AND EXISTS (SELECT 1 FROM #TEMP_HQ HQ WHERE HQ.city_id=CT.city_id) '
		SET @STR=@STR+ 'LEFT OUTER JOIN tbl_master_designation DESG ON DESG.deg_id=CTC.emp_Designation AND CTC.emp_effectiveuntil IS NULL '
		SET @STR=@STR+ 'LEFT JOIN tbl_master_employee EMP_REP ON CTC.emp_reportTo = EMP_REP.emp_id '
		SET @STR=@STR+ 'LEFT JOIN tbl_master_contact CNT_REP ON EMP_REP.emp_contactId=CNT_REP.cnt_internalId '
		SET @STR=@STR+ 'INNER JOIN Master_VisitLocation EXPT ON SA.StationCode=EXPT.VST_ID '
		SET @STR=@STR+ 'AND EXISTS (SELECT 1 FROM #TEMP_EXPENSETYPE ET WHERE ET.expid=EXPT.VST_ID) '
		SET @STR=@STR+ 'WHERE CONVERT(nvarchar(10),SA.visited_date ,120) BETWEEN '''+CONVERT(nvarchar(10),@fromdate,120)+'''  AND '''+CONVERT(nvarchar(10),@todate,120)+ ''' '
		SET @STR=@STR+ ' ) SHOP_ACT '
		SET @STR=@STR+ 'GROUP BY SHOP_ACT.VISITED_DATE, city_name, EMPID,EMP_NAME,DESIGNATION,SUPERVISOR_NAME,USERID,STATEID,EMPGRADEID,AREA_LOCATION_ID '
		
		EXEC (@STR)
		--  END CREATE TEMP TABLE FOR shopActivitysubmit ---

		-- INSERT RECORD IN LINQ TABLE ----
		SET @STR = ''
		SET @STR=@STR+ 'INSERT INTO EXPENSE_REPORT (SL, REIMBURSEMENT_DATE, HQ_NAME, EMPID, EMP_NAME, EMP_DESIGNATION, '
		SET @STR=@STR+ 'REPORTTO_NAME, EXPENSE_TYPE, OTHER_ALLOWANCE, DAILY_ALLOWANCE, TOTAL_ALLOWANCE, USER_ID, IS_IMAGE, BRANCHNAME, AREANAME) '
		SET @STR=@STR+ 'SELECT ROW_NUMBER() OVER (ORDER BY EMPID) SL, SHOP_ACT.REIMBURSEMENT_DATE, SHOP_ACT.HQ_NAME, SHOP_ACT.EMPID,SHOP_ACT.EMP_NAME,SHOP_ACT.EMP_DESIGNATION,SHOP_ACT.REPORTTO_NAME,SHOP_ACT.VISIT_LOCATION,'
		SET @STR=@STR+ 'ISNULL(RA_OTH.OTH_AMOUNT,0) AS OTHER_ALLOWANCE, ISNULL(CONFIG.DAILY_AMOUNT,0) AS DAILY_ALLOWANCE,  '
		SET @STR=@STR+ '(ISNULL(RA_OTH.OTH_AMOUNT,0)+ISNULL(CONFIG.DAILY_AMOUNT,0)) TOTAL_ALLOWANCE, '+LTRIM(RTRIM(STR(@USER_ID)))+' AS USER_ID, '
		SET @STR=@STR+ '(case when IMG.IMG_CNT >0 then 1 else 0 end) AS IS_IMAGE, ISNULL(BRANCHNAME,'''') BRANCHNAME, ISNULL(AREANAME,'''') AREANAME  '
		SET @STR=@STR+ 'FROM #TEMP_shopActivitysubmit SHOP_ACT '

		-- Other Allowance
		SET @STR+='LEFT OUTER JOIN ('
			SET @STR+='SELECT UserID,SUM(ISNULL(AMOUNT,0)) AS OTH_AMOUNT,CAST(DATE AS DATE) AS DATE FROM FTS_Reimbursement_Application '
			SET @STR+='WHERE Expence_type=''Other'' '
			SET @STR+='GROUP BY UserID,CAST(DATE AS DATE)) RA_OTH '
		SET @STR+='ON SHOP_ACT.USERID=RA_OTH.UserID AND CONVERT(DATE,SHOP_ACT.REIMBURSEMENT_DATE)=CONVERT(DATE,RA_OTH.DATE) '
		
		-- Daily Allowance
		-- Rev 1.0
		--SET @STR+='LEFT OUTER JOIN ('
		--	SET @STR+='SELECT SUM(ISNULL(TCON.EligibleAmtday,0)) AS DAILY_AMOUNT,VLOC.Visit_Location Visit_Location, TCON.EmpgradeId,TCON.ExpenseId ,TCON.StateId '
		--	SET @STR+='FROM FTS_Travel_Conveyance TCON '
		--		SET @STR+='INNER JOIN FTS_Expense_Type ET ON TCON.ExpenseId=ET.ID AND ET.Expense_Type=''Allowance'' '
		--		SET @STR+='INNER JOIN FTS_Visit_Location VLOC ON TCON.VisitlocId=VLOC.ID '
		--	SET @STR+='GROUP BY VLOC.Visit_Location, TCON.EmpgradeId,TCON.ExpenseId ,TCON.StateId) CONFIG '
		--SET @STR+='ON LTRIM(RTRIM(UPPER(REPLACE(CONFIG.Visit_Location,'' '',''''))))=LTRIM(RTRIM(UPPER(REPLACE(SHOP_ACT.VISIT_LOCATION,'' '','''')))) AND '
		--SET @STR+=' CONFIG.EmpgradeId=SHOP_ACT.EMPGRADEID AND CONFIG.StateId=SHOP_ACT.STATEID  '
		SET @STR+='LEFT OUTER JOIN ('
			SET @STR+='SELECT SUM(ISNULL(TCON.EligibleAmtday,0)) AS DAILY_AMOUNT,VLOC.Visit_Location Visit_Location, TCON.EmpgradeId,TCON.ExpenseId ,TCON.StateId, '
			
			IF (@IsShowReimbursementTypeInAttendance='1')
				SET @STR+=' ISNULL(BR.branch_description,'''') BRANCHNAME,ISNULL(AR.area_name,'''') AREANAME, AR.area_id '
			ELSE
				SET @STR+=' '''' BRANCHNAME,'''' AREANAME '

			SET @STR+='FROM FTS_Travel_Conveyance TCON '
				SET @STR+='INNER JOIN FTS_Expense_Type ET ON TCON.ExpenseId=ET.ID AND ET.Expense_Type=''Allowance'' '
				SET @STR+='INNER JOIN FTS_Visit_Location VLOC ON TCON.VisitlocId=VLOC.ID '
				
				IF (@IsShowReimbursementTypeInAttendance='1')
				BEGIN
					SET @STR+='left outer join FTS_TravelConveyanceBranchMap  BranchMap on TCON.TCId=BranchMap.TravelConveyanceID '
					SET @STR+='left outer join  FTS_TravelConveyanceAreaMap AreaMap on AreaMap.BranchMapid=BranchMap.BranchMapid '
					SET @STR+='left outer join TBL_MASTER_BRANCH BR on BranchMap.MapBranchId=BR.branch_id '
					SET @STR+='left outer join  tbl_master_area AR on AreaMap.MapAreaId=AR.area_id '
					SET @STR+='GROUP BY VLOC.Visit_Location, TCON.EmpgradeId,TCON.ExpenseId ,TCON.StateId, BR.branch_description, AR.area_name, AR.area_id ) CONFIG '
				END
				ELSE
				BEGIN
					SET @STR+='GROUP BY VLOC.Visit_Location, TCON.EmpgradeId,TCON.ExpenseId ,TCON.StateId ) CONFIG '
				END

		SET @STR+='ON LTRIM(RTRIM(UPPER(REPLACE(CONFIG.Visit_Location,'' '',''''))))=LTRIM(RTRIM(UPPER(REPLACE(SHOP_ACT.VISIT_LOCATION,'' '','''')))) AND '
		SET @STR+=' CONFIG.EmpgradeId=SHOP_ACT.EMPGRADEID AND CONFIG.StateId=SHOP_ACT.STATEID  '
		IF (@IsShowReimbursementTypeInAttendance='1')
			-- Rev 2.0
			--SET @STR+=' AND CONFIG.area_id=SHOP_ACT.AREA_LOCATION_ID '
			SET @STR+=' AND ( (SHOP_ACT.VISIT_LOCATION =''In Station'' OR SHOP_ACT.VISIT_LOCATION =''Ex Station'') OR (CONFIG.area_id=SHOP_ACT.AREA_LOCATION_ID ) ) '
			-- End of Rev 2.0
		-- End of Rev 1.0
		
		-- ATTACHMENT IMAGE EXIST CHECK
		SET @STR+='LEFT OUTER JOIN(SELECT COUNT(0) IMG_CNT, UserID,CAST(DATE AS DATE) AS DATE FROM FTS_Reimbursement_Applicationbills  '
		SET @STR+='GROUP BY UserID,CAST(DATE AS DATE)) IMG ON SHOP_ACT.USERID=IMG.UserID AND CONVERT(DATE,SHOP_ACT.REIMBURSEMENT_DATE)=CONVERT(DATE,IMG.DATE) '
		EXEC (@STR)
		-- END INSERT RECORD IN LINQ TABLE ----


		DROP TABLE #TEMP_HQ
		DROP TABLE #TEMP_EXPENSETYPE
		DROP TABLE #TEMP_EMPLOYEE
		DROP TABLE #TEMP_CONTACT
		DROP TABLE #TEMP_shopActivitysubmit

		IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USER_ID)=1)
		BEGIN
			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END

	END
	if (@ACTION='GetHQName')
	BEGIN
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'EXPENSE_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE EXPENSE_REPORT
			(
				SL BIGINT,
				REIMBURSEMENT_DATE DATETIME,
				HQ_NAME NVARCHAR(100),
				EMPID NVARCHAR(100),
				EMP_NAME NVARCHAR(500),
				EMP_DESIGNATION NVARCHAR(500),
				REPORTTO_NAME NVARCHAR(500),
				EXPENSE_TYPE NVARCHAR(500),
				OTHER_ALLOWANCE NUMERIC(18,2),
				DAILY_ALLOWANCE NUMERIC(18,2),
				TOTAL_ALLOWANCE NUMERIC(18,2),
				IS_IMAGE BIT,
				BRANCHNAME NVARCHAR(200), 
				AREANAME NVARCHAR(1000),
				USER_ID BIGINT	
			)
			CREATE NONCLUSTERED INDEX IX1 ON EXPENSE_REPORT (SL)
		END

		SELECT distinct cast(C.city_id as varchar(50)) as HQid, C.city_name as HQname FROM tbl_master_city C 
			INNER JOIN tbl_master_address E on C.city_id = E.add_city 
			where E.add_entity='employee' and E.add_addressType='Office'
			order by C.city_name
	END
	if (@ACTION='GetExpenseType')
	BEGIN
		SELECT cast(VST_ID as varchar(50)) as expid, VISIT_LOCATION as expense_type FROM Master_VisitLocation
			order by expid
	END
	if (@ACTION='LOADIMAGE')
	BEGIN
		DECLARE @UID BIGINT
		SET @UID = (SELECT TOP 1 USER_ID FROM TBL_MASTER_USER U INNER JOIN tbl_master_employee E ON E.emp_contactId=U.user_contactId WHERE E.emp_uniqueCode=@EMPID )

		select MapExpenseID, Bills from FTS_Reimbursement_Applicationbills where UserID=@UID and convert(date,[Date])=CONVERT(nvarchar(10),@REIMBURSEMENT_DATE,120)
	END
END