IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_ReimbursementAllowance_Report_Get]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_ReimbursementAllowance_Report_Get] AS' 
END
GO

--prc_ReimbursementAllowance_Report_Get '15',NULL,NULL,NULL,NULL,NULL,'GetReport'
ALTER PROC [dbo].[prc_ReimbursementAllowance_Report_Get]
(
	@STATEID NVARCHAR(MAX)= NULL,
	@EXPENSETYPE NVARCHAR(MAX)= NULL,
	@VISITLOCATION NVARCHAR(MAX)= NULL,
	@EMPLOYEEGRADE NVARCHAR(MAX)= NULL,
	@MODEOFTRAVEL NVARCHAR(MAX)= NULL,
	@FUELTYPE NVARCHAR(MAX)= NULL,
	@ACTION VARCHAR(200) = ''
	-- Rev 3.0
	,@USERID INT=null
	-- End of Rev 3.0
)  --WITH ENCRYPTION
AS 

/****************************************************************************************************************************************************************************
Written by : Surojit Chatterjee on 06/02/2019
Module	  : Travel Allowance - Report
1.0	v1.0.0	Surojit	 07/02/2019 Show EligibleAmount = EligibleDistance * EligibleRate if EligibleDistance is not null EligibleRate is not null.
1.0 v2.0.0  Surojit  07/02/2019 Don't get report without state id
2.0		V2.0.35		Sanchita	In the Expense report, Conveyance details are not populating under Travelling Allowance report. refer: 25547.
3.0		v2.0.38		Sanchita	02-02-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/

SET NOCOUNT ON ;
	BEGIN TRY  

	IF @ACTION = 'GetReport' AND @STATEID IS NOT NULL
	BEGIN

	DECLARE @Strsql NVARCHAR(MAX) = '';
	DECLARE @sqlStrTable NVARCHAR(MAX) = '';

		CREATE TABLE #TempSate 
			( 
			  [SateID] INT
			)

		CREATE TABLE #TempExpenseType 
			( 
				[ExpenseTypeID] INT
			)

		CREATE TABLE #TempVisit 
		( 
			[VisitLocationID] INT
		)

		CREATE TABLE #TempGrade 
		( 
			[GradeID] INT
		)

		CREATE TABLE #TempModeTravel 
		( 
			[TravelID] INT
		)

		CREATE TABLE #TempFuelType 
		( 
			[FuelTypeID] INT
		)

		IF @STATEID IS NOT NULL
		BEGIN
			SET @STATEID=REPLACE(@STATEID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TempSate SELECT id from tbl_master_state where id in('+@STATEID+')'
			--SELECT @sqlStrTable
			EXEC SP_EXECUTESQL @sqlStrTable
			
		END

		IF @EXPENSETYPE IS NOT NULL
		BEGIN
			SET @EXPENSETYPE=REPLACE(@EXPENSETYPE,'''','')
			--INSERT INTO #TempExpenseType SELECT Id from FTS_Expense_Type where Id in(@EXPENSETYPE)
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TempExpenseType SELECT id from FTS_Expense_Type where id in('+@EXPENSETYPE+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		IF @VISITLOCATION IS NOT NULL
		BEGIN
			SET @VISITLOCATION=REPLACE(@VISITLOCATION,'''','')
			--INSERT INTO #TempVisit SELECT Id from FTS_Visit_Location where Id in(@VISITLOCATION)
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TempVisit SELECT id from FTS_Visit_Location where id in('+@VISITLOCATION+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		IF @EMPLOYEEGRADE IS NOT NULL
		BEGIN
			SET @EMPLOYEEGRADE=REPLACE(@EMPLOYEEGRADE,'''','')
			--INSERT INTO #TempGrade SELECT Emp_Grade from tbl_FTS_MapEmployeeGrade where Emp_Grade in(@EMPLOYEEGRADE)
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TempGrade SELECT Emp_Grade from tbl_FTS_MapEmployeeGrade where Emp_Grade in('+@EMPLOYEEGRADE+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		IF @MODEOFTRAVEL IS NOT NULL
		BEGIN
			SET @MODEOFTRAVEL=REPLACE(@MODEOFTRAVEL,'''','')
			--INSERT INTO #TempModeTravel SELECT Id from FTS_Travel_Mode where Id in(@MODEOFTRAVEL)
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TempModeTravel SELECT Id from FTS_Travel_Mode where Id in('+@MODEOFTRAVEL+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		IF @FUELTYPE IS NOT NULL
		BEGIN
			SET @FUELTYPE=REPLACE(@FUELTYPE,'''','')
			--INSERT INTO #TempFuelType SELECT Id from tbl_FTS_FuelTypes where Id in(@FUELTYPE)
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TempFuelType SELECT Id from tbl_FTS_FuelTypes where Id in('+@FUELTYPE+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		-- Rev 3.0
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
		-- End of Rev 3.0

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
		-- Rev 3.0
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
		-- End of Rev 3.0

	SET @Strsql=''
		
		SET @Strsql='SELECT REAPP.Createddate AS AppliedOn, REAPP.Date AS ForDate,USR.user_loginId AS LoginID, MASCON.cnt_firstName + '' '' + MASCON.cnt_lastName AS EmpName,'
		SET @Strsql+='EGRD.Employee_Grade AS Grade, REPORTTO AS Supervisor,MST.state AS StateName, '
		SET @Strsql+='VL.Visit_Location AS VisitLocation, ETYPE.Expense_Type AS ExpenseType,TMODE.TravelMode AS ModeOfTravel,'
		SET @Strsql+='FTYPE.FuelType AS FuelType,ISNULL(conv.EligibleDistance,CAST(0.00 AS DECIMAL(18,2))) AS EligibleDistance,ISNULL(REAPP.Total_distance,CAST(0.00 AS DECIMAL(18,2))) AS AppliedDistance,'

		SET @Strsql+='CASE WHEN REAPP.Expence_type_id <> 2 THEN ISNULL((SELECT SUM(ISNULL(distance_covered,0)) FROM tbl_trans_shopuser WHERE User_Id = REAPP.UserID '
		SET @Strsql+='AND CONVERT(date, REAPP.Date) = CONVERT(date, SDate)),CAST(0.00 AS DECIMAL(18,2))) ELSE CAST(0.00 AS DECIMAL(18,2)) END AS TotalTravelled, '

		SET @Strsql+='ISNULL(RAVER.Total_distance,CAST(0.00 AS DECIMAL(18,2))) AS ApprovedDistance,ISNULL(conv.EligibleRate,CAST(0.00 AS DECIMAL(18,2))) AS EligibleRate,'
		SET @Strsql+='(CASE WHEN REAPP.Total_distance IS NULL '
		SET @Strsql+='THEN CAST(0.00 AS DECIMAL(18,2)) '
		-- Rev 2.0
		--SET @Strsql+='WHEN REAPP.Amount IS NULL '
		SET @Strsql+='WHEN (REAPP.Amount IS NULL or REAPP.Amount=0) '
		-- End of Rev 2.0
		SET @Strsql+='THEN CAST(0.00 AS DECIMAL(18,2)) '
		SET @Strsql+='ELSE '
		SET @Strsql+='CAST((REAPP.Total_distance / REAPP.Amount) AS DECIMAL(18,2)) '
		SET @Strsql+='END ) AS AppliedRate, '

		--SET @Strsql+='ISNULL(conv.EligibleAmtday,CAST(0.00 AS DECIMAL(18,2))) AS EligibleAmount, '
		SET @Strsql+='(CASE WHEN conv.EligibleDistance IS NULL THEN ISNULL(conv.EligibleAmtday,CAST(0.00 AS DECIMAL(18,2))) '
		SET @Strsql+='WHEN conv.EligibleRate IS NULL THEN ISNULL(conv.EligibleAmtday,CAST(0.00 AS DECIMAL(18,2))) '
		SET @Strsql+='ELSE CAST((conv.EligibleDistance * conv.EligibleRate) AS DECIMAL(18,2)) '
		SET @Strsql+='END ) AS EligibleAmount, '

		SET @Strsql+='ISNULL(REAPP.Amount,CAST(0.00 AS DECIMAL(18,2))) AS AppliedAmount, '
		SET @Strsql+='ISNULL(RAVER.Amount,CAST(0.00 AS DECIMAL(18,2))) AS ApprovedAmount, '
		SET @Strsql+='(CASE WHEN RAVER.Status = ''1'' '
		SET @Strsql+='THEN ''Approved'' '
		SET @Strsql+='WHEN RAVER.Status = ''2'' '
		SET @Strsql+='THEN ''Rejected'' '
		SET @Strsql+='ELSE '
		SET @Strsql+='''Pending'' '
		SET @Strsql+='END) AS Status '
		SET @Strsql+='FROM FTS_REIMBURSEMENT_APPLICATION REAPP '

		--SET @Strsql+='LEFT OUTER JOIN tbl_trans_shopuser TRASHOP ON TRASHOP.User_Id = REAPP.UserID AND CONVERT(date, REAPP.Date) = CONVERT(date, TRASHOP.SDate) '

		SET @Strsql+='LEFT OUTER JOIN FTS_Reimbursement_Application_Verified RAVER ON RAVER.ApplicationID = REAPP.ApplicationID '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON REAPP.UserID = USR.user_id '
		SET @Strsql+='INNER JOIN tbl_master_contact MASCON ON MASCON.cnt_internalId = USR.user_contactId '
		SET @Strsql+='LEFT OUTER JOIN tbl_FTS_MapEmployeeGrade MEG ON MEG.Emp_Code = MASCON.cnt_internalId '
		SET @Strsql+='LEFT OUTER JOIN FTS_Employee_Grade EGRD ON  EGRD.Id = MEG.Emp_Grade '
		SET @Strsql+='INNER JOIN FTS_Visit_Location VL ON VL.Id = REAPP.Visit_type_id '
		SET @Strsql+='INNER JOIN FTS_Expense_Type ETYPE ON ETYPE.Id = REAPP.Expence_type_id '
		SET @Strsql+='LEFT OUTER JOIN FTS_Travel_Mode TMODE ON ISNULL(TMODE.Id,0) =ISNULL(REAPP.Mode_of_travel,0) '
		SET @Strsql+='LEFT OUTER JOIN tbl_FTS_FuelTypes FTYPE ON ISNULL(FTYPE.Id,0) =ISNULL(REAPP.Fuel_typeId,0) '
		SET @Strsql+='INNER JOIN tbl_master_state MST ON MST.id = REAPP.StateID '

		SET @Strsql+='LEFT OUTER JOIN (select g.Employee_Grade,cv.VisitlocId,cv.EmpgradeId,cv.ExpenseId,cv.StateId,cv.DesignationId,cv.TravelId,cv.EligibleDistance,cv.EligibleAmtday,cv.IsActive,cv.FuelID,cv.EligibleRate '
		SET @Strsql+='from FTS_Travel_Conveyance cv  INNER JOIN FTS_Employee_Grade g on cv.EmpgradeId=g.Id) as conv on conv.VisitlocId=REAPP.Visit_type_id and conv.ExpenseId=REAPP.Expence_type_id and conv.StateId=REAPP.StateID  '
		SET @Strsql+='AND ISNULL(conv.TravelId,0)=ISNULL(REAPP.Mode_of_travel,0) '
		SET @Strsql+='AND isnull(conv.FuelID,0)=isnull(REAPP.Fuel_typeId,0) '
		SET @Strsql+='AND IsActive=1 and conv.EmpgradeId= EGRD.Id '


		--SET @Strsql+='INNER JOIN ( '
		--SET @Strsql+='SELECT  cnt.emp_cntId,MAx(cnt.emp_id) AS emp_id FROM '
		--SET @Strsql+=' tbl_trans_employeeCTC AS cnt '
		--SET @Strsql+='GROUP BY emp_cntId '
		--SET @Strsql+=')N '
		--SET @Strsql+='ON  N.emp_cntId=USR.user_contactId '
		--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC  as reptto  on N.emp_id=reptto.emp_id '
		--SET @Strsql+='INNER JOIN tbl_master_employee AS MAS ON reptto.emp_reportTo = MAS.emp_id '
		--SET @Strsql+='INNER JOIN tbl_master_contact MASC ON MASC.cnt_internalId = MAS.emp_contactId '

		SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS RPTTOEMPCODE,CNT.cnt_internalId, '
		SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
		SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN ( '
		SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
		SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
		SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=MASCON.cnt_internalId '

		SET @Strsql+='WHERE USR.user_inactive = ''N'' '
		
		IF @STATEID IS NOT NULL
		BEGIN
			SET @Strsql+='AND REAPP.StateID IN  '
			SET @Strsql+='(SELECT [SateID] from #TempSate) '
		END

		IF @EXPENSETYPE IS NOT NULL
		BEGIN
			SET @Strsql+='AND REAPP.Expence_type_id IN '
			SET @Strsql+='(SELECT ExpenseTypeID from #TempExpenseType) '
		END

		IF @VISITLOCATION IS NOT NULL
		BEGIN
			SET @Strsql+='AND REAPP.Visit_type_id IN  '
			SET @Strsql+='(SELECT VisitLocationID from #TempVisit) '
		END

		IF @EMPLOYEEGRADE IS NOT NULL
		BEGIN
			SET @Strsql+='AND MEG.Emp_Grade IN   (SELECT GradeID from #TempGrade) '
		END
		
		IF @MODEOFTRAVEL IS NOT NULL
		BEGIN
			SET @Strsql+='AND (REAPP.Mode_of_travel IN (SELECT TravelID from #TempModeTravel where TravelID<>''2'')) '
			 SET @Strsql+='OR (REAPP.Mode_of_travel IN (SELECT TravelID from #TempModeTravel where TravelID=''2'') '
			IF @FUELTYPE IS NOT NULL
		    BEGIN
			SET @Strsql+='AND REAPP.Fuel_typeId IN (SELECT FuelTypeID from #TempFuelType)) '
			END
			ELSE
			BEGIN
			SET @Strsql+=') '
			END
		END

		--IF @MODEOFTRAVEL IS NOT NULL
		--BEGIN
		   
		--END


		
		--SELECT @Strsql
		EXEC SP_EXECUTESQL @Strsql

		

		DROP TABLE #TempSate
		DROP TABLE #TempExpenseType
		DROP TABLE #TempVisit
		DROP TABLE #TempGrade
		DROP TABLE #TempModeTravel
		DROP TABLE #TempFuelType
		DROP TABLE #TEMPCONTACT
		-- Rev 3.0
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END
		-- End of Rev 3.0

	END
	IF @ACTION = 'GetSateList'
	BEGIN

		SELECT id,state FROM tbl_master_state
		
	END
	IF @ACTION = 'GetExpenseTypeList'
	BEGIN

		SELECT id,Expense_Type FROM FTS_Expense_Type
		
	END

	IF @ACTION = 'GetVisitLocationList'
	BEGIN

		SELECT id,Visit_Location FROM FTS_Visit_Location
		
	END

	IF @ACTION = 'GetEmployeeGradeList'
	BEGIN

		SELECT Id,Employee_Grade FROM FTS_Employee_Grade
		
	END

	IF @ACTION = 'GetModeOfTravelList'
	BEGIN

		SELECT Id,TravelMode FROM FTS_Travel_Mode
		
	END

	IF @ACTION = 'GetFuelTypeList'
	BEGIN

		SELECT Id,FuelType FROM tbl_FTS_FuelTypes
		
	END

	END TRY
BEGIN CATCH 

    DECLARE @ErrorMessage NVARCHAR(4000) ; 
    DECLARE @ErrorSeverity INT ; 
    DECLARE @ErrorState INT ; 
    SELECT  @ErrorMessage = ERROR_MESSAGE() , 
            @ErrorSeverity = ERROR_SEVERITY() , 
			@ErrorState = ERROR_STATE() ; 
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState) ; 
END CATCH ; 
RETURN ; 
