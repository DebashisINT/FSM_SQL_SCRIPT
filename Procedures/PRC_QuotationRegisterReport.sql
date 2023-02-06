--exec PRC_QuotationRegisterReport @user_id='378',@FromDate='2020-05-10',@TODATE='2020-07-01'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_QuotationRegisterReport]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_QuotationRegisterReport] AS'  
END 
GO 

ALTER PROCEDURE  [dbo].[PRC_QuotationRegisterReport]
(
@user_id BIGINT,
@FromDate NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@deptid NVARCHAR(MAX)=NULL,
@DesigId NVARCHAR(MAX)=NULL
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
			cnt_ucc NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			USER_ID BIGINT,
			-- Rev 2.0 [ existing error solved ]
			--Contact_no nvarchar(15)
			Contact_no nvarchar(50)
			-- End of Rev 2.0
		)
		CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
		-- Rev 2.0
		--INSERT INTO #TEMPCONTACT
		--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id,USR.user_loginId FROM TBL_MASTER_CONTACT CNT
		--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE cnt_contactType IN('EM')

		SET @Strsql=''
		SET @Strsql+=' INSERT INTO #TEMPCONTACT '
		SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id,USR.user_loginId FROM TBL_MASTER_CONTACT CNT '
		SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_id)=1)
		BEGIN
			SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
		END
		SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
		exec sp_executesql @Strsql
		-- End of Rev 2.0

		IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID=OBJECT_ID(N'FTS_QUOTATIONREGISTERREPORT') AND TYPE IN (N'U'))
		BEGIN
		CREATE TABLE FTS_QUOTATIONREGISTERREPORT
		(
		SEQ BIGINT,
		USERID BIGINT,
		QUOTATION_NO NVARCHAR(100),
		QUOTATION_DATE NVARCHAR(10),
		HYPOTHECATION NVARCHAR(100),
		ACCOUNT_NO NVARCHAR(100),
		MODEL NVARCHAR(300),
		BS NVARCHAR(100),
		DESC1 NVARCHAR(100),
		DESC2 NVARCHAR(100),
		DESC3 NVARCHAR(100),
		DESC4 NVARCHAR(100),
		DESC5 NVARCHAR(100),
		DESC6 NVARCHAR(100),
		DESC7 NVARCHAR(100),
		AMOUNT DECIMAL(18,2),
		DISCOUNT DECIMAL(18,2),
		CGST DECIMAL(18,2),
		SGST DECIMAL(18,2),
		TCS DECIMAL(18,2),
		INSURANCE DECIMAL(18,2),
		NET_AMOUNT DECIMAL(18,2),
		CREATE_DATE DATETIME,
		UPDATE_DATE DATETIME,
		USERS NVARCHAR(300)
		)
		END
		DELETE FROM FTS_QUOTATIONREGISTERREPORT WHERE USERID=@user_id

		SET @Strsql=' '
		SET @Strsql+=' INSERT INTO FTS_QUOTATIONREGISTERREPORT '
		SET @Strsql+=' SELECT ROW_NUMBER() OVER(ORDER BY QUOTATION_DATE) AS SEQ,'''+STR(@user_id)+''',QUOTATION_NO,CONVERT(NVARCHAR(10),QUOTATION_DATE,105),HYPOTHECATION,ACCOUNT_NO,PROD.sProducts_Name AS MODEL,BS.VALUE AS BS,CONVERT(NVARCHAR(20),GEARBOX) +''  speed'', '
		SET @Strsql+=' CONVERT(NVARCHAR(10),NUMBER1) +'' nos'',CONVERT(NVARCHAR(20),VALUE1)+'' x ''+CONVERT(NVARCHAR(10),VALUE2), '
		SET @Strsql+=' CONVERT(NVARCHAR(10),TYRES1)+'' tyres'',CONVERT(NVARCHAR(10),NUMBER2)+'' nos'',CONVERT(NVARCHAR(10),VALUE3)+'' x ''+CONVERT(NVARCHAR(10),VALUE4),CONVERT(NVARCHAR(10),TYRES2)+'' tyres'', '
		SET @Strsql+=' AMOUNT,DISCOUNT,CGST,SGST,TCS,INSURANCE,NET_AMOUNT,CREATE_DATE,UPDATE_DATE, '
		SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''')+'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS USERS '
		SET @Strsql+=' FROM FTS_Quotation qut '
		SET @Strsql+=' LEFT OUTER JOIN fts_master_bs BS ON qut.BS_ID=BS.ID '
		SET @Strsql+=' INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=qut.MODEL_ID '
		SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.USER_ID=qut.USER_ID '
		SET @Strsql+=' LEFT OUTER JOIN (    '
		SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt   '
		SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL '
		SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON CNT.cnt_internalId =DESG.emp_cntId '
		SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON CNT.cnt_internalId=CTC.emp_cntId '
		SET @Strsql+=' INNER JOIN tbl_master_costCenter DEPT ON dept.cost_id=emp_Department AND cost_costCenterType=''Department'' '
		SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),qut.QUOTATION_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FromDate+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		IF @EMPID <> ''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=CNT.cnt_internalId) '
		END
		IF @DesigId <> ''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '
		END
		IF @deptid <> ''
		BEGIN
			SET @Strsql+=' AND EXISTS (SELECT dept_id from #DEPARTMENT_LIST AS DPT WHERE DPT.dept_id=CTC.emp_Department) '
		END

		EXEC SP_EXECUTESQL @Strsql
		--SELECT @Strsql
		
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #DEPARTMENT_LIST
	DROP TABLE #TEMPCONTACT
	-- Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_id)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 2.0

END