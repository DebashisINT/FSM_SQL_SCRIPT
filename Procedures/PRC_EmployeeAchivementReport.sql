--exec PRC_EmployeeAchivementReport @user_id='378',@FromDate='2020-06-10',@TODATE='2020-07-27'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_EmployeeAchivementReport]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_EmployeeAchivementReport] AS'  
END 
GO 

ALTER PROCEDURE  [dbo].[PRC_EmployeeAchivementReport]
(
@user_id BIGINT,
@FromDate NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@deptid NVARCHAR(MAX)=NULL,
@DesigId NVARCHAR(MAX)=NULL,
@Supercode NVARCHAR(MAX)=NULL
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************
1.0			Tanmoy		23-07-2020	Create Procedure
2.0			Sanchita	02-02-2023		v2.0.38		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
													then data in portal shall be populated based on Hierarchy Only. Refer: 25504
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

		-- Rev 2.0
		DECLARE @user_contactId NVARCHAR(15)
		SELECT @user_contactId=user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@user_id

		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_id)=1)
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
		-- End of Rev 2.0

		IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
		CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			USER_ID BIGINT
		)
		CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
		
		-- Rev 2.0
		--INSERT INTO #TEMPCONTACT
		--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,user_id FROM TBL_MASTER_CONTACT CNT
		--INNER JOIN tbl_master_user USR ON CNT.cnt_internalId=USR.user_contactId WHERE cnt_contactType IN('EM')

		SET @Strsql=''
		SET @Strsql+=' INSERT INTO #TEMPCONTACT '
		SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,user_id FROM TBL_MASTER_CONTACT CNT '
		SET @Strsql+=' INNER JOIN tbl_master_user USR ON CNT.cnt_internalId=USR.user_contactId '
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_id)=1)
		BEGIN
			SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
		END
		SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
		exec sp_executesql @Strsql
		-- End of Rev 2.0

		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_EmployeeAchievementDetailsReport') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTS_EmployeeAchievementDetailsReport
			(
			SEQ BIGINT,
			USERID BIGINT,
			Date NVARCHAR(10),
			Time NVARCHAR(10),
			Employee NVARCHAR(300),
			Supervisor NVARCHAR(300),
			Designation NVARCHAR(200),
			Department NVARCHAR(100),
			CustomerName NVARCHAR(300),
			CustomerAddress NVARCHAR(500),
			ContactNo NVARCHAR(15),
			Mail NVARCHAR(100),
			Model NVARCHAR(100),
			PrimaryApplication NVARCHAR(100),
			SecondaryApplication NVARCHAR(100),
			BookingAmount DECIMAL(20,2),
			LeadType NVARCHAR(100),
			Stage NVARCHAR(100),
			FunnelStage NVARCHAR(10)
			)
		END

		DELETE FROM FTS_EmployeeAchievementDetailsReport WHERE USERID=@user_id

	SET @Strsql=' '

	SET @Strsql+=' INSERT INTO FTS_EmployeeAchievementDetailsReport  '
	SET @Strsql+=' SELECT ROW_NUMBER() OVER(ORDER BY MAP.UPDATE_DATE DESC) AS SEQ,'''+STR(@user_id)+''',CONVERT(NVARCHAR(10),MAP.UPDATE_DATE,105) AS visit_date,FORMAT(MAP.UPDATE_DATE,''hh:mm tt'') AS visit_time, '
	SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''')+'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS EMPLOYEE,RPTTO.REPORTTO, '
	SET @Strsql+=' desg.deg_designation,DEPT.cost_description DEPARTMENT,SHOP.SHOP_NAME AS cust_name,SHOP.ADDRESS,SHOP.Shop_Owner_Contact,SHOP.SHOP_OWNER_EMAIL,PROD.SPRODUCTS_NAME AS MODEL, '
	SET @Strsql+=' PIMARY.PrimaryApplication,SECON.SecondaryApplication,SHOP.Booking_amount,LD.LeadType,STG.Stage,funnel.FunnelStage '
	SET @Strsql+=' FROM FTS_STAGEMAP MAP '
	SET @Strsql+=' INNER JOIN FTS_STAGE STG ON STG.StageID=MAP.STAGE_ID  AND STG.IsActive=1 '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.USER_ID=MAP.USER_ID '
	SET @Strsql+=' LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo, '
	SET @Strsql+=' CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO, '
	SET @Strsql+=' DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP  '
	SET @Strsql+=' INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+=' INNER JOIN ( '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+=' WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON CNT.cnt_internalId=RPTTO.emp_cntId '
	SET @Strsql+=' INNER JOIN tbl_trans_employeeCTC CTC ON CTC.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON CTC.emp_Designation=desg.deg_id '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_costCenter DEPT ON CTC.emp_Department=DEPT.cost_id AND DEPT.cost_costCenterType = ''department'' ' 
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHOP ON MAP.SHOP_ID=SHOP.SHOP_CODE '
	SET @Strsql+=' LEFT OUTER JOIN Master_sProducts PROD ON SHOP.Model_id=PROD.sProducts_ID '
	SET @Strsql+=' LEFT OUTER JOIN FTS_PrimaryApplication PIMARY ON SHOP.Primary_id=PIMARY.ID '
	SET @Strsql+=' LEFT OUTER JOIN FTS_SecondaryApplication SECON ON SHOP.Secondary_id=SECON.ID '
	SET @Strsql+=' LEFT OUTER JOIN FTS_LeadType LD ON SHOP.Lead_id=LD.LeadTypeID '
	SET @Strsql+=' LEFT OUTER JOIN FTS_FunnelStage funnel ON SHOP.FunnelStage_id=funnel.FunnelStageID '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),MAP.UPDATE_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FromDate+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @EMPID <> ''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=CNT.cnt_internalId) '
	END
	IF @DesigId <> ''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=desg.deg_id) '
	END
	IF @Supercode <> ''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #SUPER_LIST AS SUPR WHERE SUPR.emp_contactId=RPTTO.cnt_internalId) '
	END
	IF @deptid <> ''
	BEGIN
		SET @Strsql+=' AND EXISTS (SELECT dept_id from #DEPARTMENT_LIST AS DPT WHERE DPT.dept_id=DEPT.cost_id) '
	END

	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #DEPARTMENT_LIST
	DROP TABLE #SUPER_LIST
	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT
	-- Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_id)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 2.0

	SET NOCOUNT OFF
END