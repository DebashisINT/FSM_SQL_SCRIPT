--EXEC PRC_FTSEMPLOYEEOUTLETMASTER_REPORT '2020-04-01','2021-11-30','1','EMB0000017,EMP0000020',378
--EXEC PRC_FTSEMPLOYEEOUTLETMASTER_REPORT '2023-02-27','2023-02-28','','','1','0',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSEMPLOYEEOUTLETMASTER_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSEMPLOYEEOUTLETMASTER_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSEMPLOYEEOUTLETMASTER_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@BRANCHID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
--Rev 5.0
@ISPAGELOAD NVARCHAR(1)=NULL,
--End of Rev 5.0
-- Rev 9.0
@ISINACTIVEOUTLETS NVARCHAR(1)=NULL,
-- End of Rev 9.0
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 03/11/2021
Module	   : Employee Outlet Master.Refer: 0024448
1.0		v2.0.27		Debashis	01/03/2022		Enhancement done.Refer: 0024715
2.0		v2.0.30		Debashis	25/05/2022		Employee Outlet Master : There Date parameter shall be ignored. It will be treated like As on.Refer: 0024905
3.0		v2.0.39		PRITI		13/02/2023		0025663:Last Visit fields shall be available in Outlet Reports
4.0		v2.0.39		Debashis	02/05/2023		Employee Outlet Master -- logic need to be change.Refer: 0025994
5.0		v2.0.39		Debashis	12/05/2023		Optimization required for Employee Outlet Master.Refer: 0026020
6.0		v2.0.41		Sanchita	26/05/2023		New Coloumn "Status" add in Employee Outlet Master. Refer: 26240
7.0		v2.0.41		Sanchita	02/06/2023		Employee Outlet Master : Report, Outlet ID shall be showing Internal ID. Refer: 26239
8.0		v2.0.41		Debashis	09/08/2023		A coloumn named as Gender needs to be added in all the ITC reports.Refer: 0026680
9.0		v2.0.46		Sanchita	02/04/2024		0027343: Employee Outlet Master : Report parameter one check box required 'Consider Inactive Outlets'
10.0	v2.0.47		Debashis	04/06/2024		In Employee Outlet Master report, add a “DS Type” column at the end.Refer: 0027506
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX)

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

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId FROM tbl_master_employee WHERE emp_contactId IN('+@EMPID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	--Rev 1.0
	--IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
	--	DROP TABLE #TEMPCONTACT
	--CREATE TABLE #TEMPCONTACT
	--	(
	--		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_branchid INT,
	--		cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	--	)
	--CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
	--End of Rev 1.0

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes NVARCHAR(50)=(SELECT user_contactId FROM Tbl_master_user WHERE user_id=@USERID)		
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
		
			;with cte AS(SELECT	EMPCODE,RPTTOEMPCODE FROM #EMPHRS 
			WHERE EMPCODE IS NULL OR EMPCODE=@empcodes  
			UNION ALL
			SELECT a.EMPCODE,a.RPTTOEMPCODE FROM #EMPHRS a
			INNER JOIN cte b ON a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			SELECT EMPCODE,RPTTOEMPCODE FROM cte 
		END

	--Rev 1.0
	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--Rev 8.0
			cnt_sex TINYINT NULL,
			GENDERDESC NVARCHAR(100) NULL
			--End of Rev 8.0
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	
	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,
			--Rev 8.0
			cnt_sex,CASE WHEN cnt_sex=1 THEN 'Male' WHEN cnt_sex=0 THEN 'Female' END GENDERDESC
			--End of Rev 8.0
			FROM TBL_MASTER_CONTACT
			INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC,
			--Rev 8.0
			cnt_sex,CASE WHEN cnt_sex=1 THEN 'Male' WHEN cnt_sex=0 THEN 'Female' END GENDERDESC
			--End of Rev 8.0
			FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
		END
	--End of Rev 1.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSEMPLOYEEOUTLETMASTER_REPORT') AND TYPE IN (N'U'))
		BEGIN
			--Rev 1.0 && Two new fields added as REPORTTOUID & HREPORTTOUID
			--Rev 10.0 && Two new columns have been added as DSTYPEID & DSTYPE
			CREATE TABLE FTSEMPLOYEEOUTLETMASTER_REPORT
			(
			  USERID INT,
			  SEQ INT,
			  BRANCH_ID BIGINT,
			  BRANCHDESC NVARCHAR(300),
			  EMPCODE NVARCHAR(100) NULL,
			  EMPID NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  DATEOFJOINING NVARCHAR(10),
			  CONTACTNO NVARCHAR(50) NULL,
			  REPORTTOID NVARCHAR(300) NULL,
			  REPORTTOUID NVARCHAR(100),
			  REPORTTO NVARCHAR(300) NULL,
			  RPTTODESG NVARCHAR(50) NULL,
			  HREPORTTOID NVARCHAR(300) NULL,
			  HREPORTTOUID NVARCHAR(100),
			  HREPORTTO NVARCHAR(300) NULL,
			  HRPTTODESG NVARCHAR(50) NULL,
			  OUTLETID NVARCHAR(100),
			  OUTLETNAME VARCHAR(5000),
			  OUTLETADDRESS NVARCHAR(MAX),
			  OUTLETCONTACT NVARCHAR(100),
			  OUTLETLAT NVARCHAR(MAX),
			  OUTLETLANG NVARCHAR(MAX),
			  LASTVISITDATE NVARCHAR(100),--REV 3.0	
			  LASTVISITTIME NVARCHAR(100),--REV 3.0	
			  LASTVISITEDBY NVARCHAR(200),--REV 3.0	
			  OUTLETSTATUS	NVARCHAR(10), -- Rev 6.0
			  --Rev 8.0
			  OUTLETEMPSEX TINYINT,
			  GENDERDESC NVARCHAR(100),
			  --End of Rev 8.0
			  DSTYPEID BIGINT,
			  DSTYPE NVARCHAR(600)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSEMPLOYEEOUTLETMASTER_REPORT (SEQ)
		END
	DELETE FROM FTSEMPLOYEEOUTLETMASTER_REPORT WHERE USERID=@USERID

	--Rev 5.0
	IF @ISPAGELOAD='1'
		BEGIN
	--End of Rev 5.0
			--Rev 1.0 && Two new fields added as REPORTTOUID & HREPORTTOUID
			--Rev 10.0 && Two new columns have been added as DSTYPEID & DSTYPE
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSEMPLOYEEOUTLETMASTER_REPORT(USERID,SEQ,BRANCH_ID,BRANCHDESC,EMPCODE,EMPID,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,CONTACTNO,REPORTTOID,REPORTTOUID,REPORTTO,'
			SET @Strsql+='RPTTODESG,HREPORTTOID,HREPORTTOUID,HREPORTTO,HRPTTODESG,OUTLETID,OUTLETNAME,OUTLETADDRESS,OUTLETCONTACT,OUTLETLAT,OUTLETLANG,LASTVISITDATE,LASTVISITTIME,LASTVISITEDBY,'
			-- Rev 6.0
			--Rev 8.0
			--SET @Strsql+='OUTLETSTATUS) '
			SET @Strsql+='OUTLETSTATUS,OUTLETEMPSEX,GENDERDESC,DSTYPEID,DSTYPE) '
			--End of Rev 8.0
			-- End of Rev 6.0
			SET @Strsql+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,ROW_NUMBER() OVER(ORDER BY CNT.cnt_internalId) AS SEQ,BR.BRANCH_ID,BR.BRANCH_DESCRIPTION,CNT.cnt_internalId AS EMPCODE,EMP.emp_uniqueCode AS EMPID,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
			-- Rev 7.0
			--SET @Strsql+='USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOID,RPTTO.REPORTTOUID,RPTTO.REPORTTO,RPTTO.RPTTODESG,HRPTTO.HREPORTTOID,HRPTTO.HREPORTTOUID,HRPTTO.HREPORTTO,HRPTTO.HRPTTODESG,MS.EntityCode AS OUTLETID,'
			SET @Strsql+='USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOID,RPTTO.REPORTTOUID,RPTTO.REPORTTO,RPTTO.RPTTODESG,HRPTTO.HREPORTTOID,HRPTTO.HREPORTTOUID,HRPTTO.HREPORTTO,HRPTTO.HRPTTODESG,MS.Shop_ID AS OUTLETID,'
			-- End of Rev 7.0
			SET @Strsql+='MS.Shop_Name AS OUTLETNAME,MS.Address AS OUTLETADDRESS,MS.Shop_Owner_Contact AS OUTLETCONTACT,MS.Shop_Lat AS OUTLETLAT,MS.Shop_Long AS OUTLETLANG '
			--Rev 3.0
			SET @Strsql+=',CONVERT(NVARCHAR(10),MS.Lastvisit_date,105) AS LASTVISITDATE,CONVERT(NVARCHAR(10),MS.Lastvisit_date,108) AS LASTVISITTIME,UserTBl.user_name AS LASTVISITEDBY '
			--REV 3.0	end
			-- Rev 6.0
			SET @Strsql+=' , CASE WHEN ISNULL(MS.Entity_Status,0)=0 THEN ''Inactive'' ELSE ''Active'' END AS OUTLETSTATUS,'
			-- End of Rev 6.0
			--Rev 8.0
			SET @Strsql+='CNT.cnt_sex AS OUTLETEMPSEX,CNT.GENDERDESC,USR.FaceRegTypeID AS DSTYPEID,STG.Stage AS DSTYPE '
			--End of Rev 8.0
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
			SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN ( '
			SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
			SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS REPORTTOID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
			--Rev 1.0
			--SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
			SET @Strsql+='DESG.deg_designation AS RPTTODESG,CNT.cnt_UCC AS REPORTTOUID FROM tbl_master_employee EMP '
			--End of Rev 1.0
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
			SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS HREPORTTOID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS HREPORTTO,'
			--Rev 1.0
			--SET @Strsql+='DESG.deg_designation AS HRPTTODESG FROM tbl_master_employee EMP '
			SET @Strsql+='DESG.deg_designation AS HRPTTODESG,CNT.cnt_UCC AS HREPORTTOUID FROM tbl_master_employee EMP '
			--End of Rev 1.0
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN ('
			SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id'
			SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) HRPTTO ON HRPTTO.emp_cntId=RPTTO.REPORTTOID '
			--Rev 4.0
			--SET @Strsql+='LEFT OUTER JOIN tbl_Master_shop MS ON USR.USER_ID=MS.SHOP_CREATEUSER '
			SET @Strsql+='INNER JOIN tbl_Master_shop MS ON USR.USER_ID=MS.SHOP_CREATEUSER '
			--End of Rev 4.0
			--Rev 10.0
			SET @Strsql+='LEFT OUTER JOIN FTS_Stage STG WITH (NOLOCK) ON USR.FaceRegTypeID=STG.StageID '
			--End of Rev 10.0
			SET @Strsql+='LEFT OUTER JOIN tbl_master_user UserTBl ON CAST(UserTBl.user_id AS INT)=MS.Shop_CreateUser '
			--Rev 1.0
			--SET @Strsql+='WHERE DESG.deg_designation=''DS'' '
			SET @Strsql+='WHERE DESG.deg_designation IN(''DS'',''TL'') '
			--End of Rev 1.0
			--Rev 2.0
			--SET @Strsql+='AND CONVERT(NVARCHAR(10),MS.Shop_CreateTime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			--End of Rev 2.0
			IF @BRANCHID<>''
				SET @StrSql+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.branch_id) '
			IF @EMPID<>''
				SET @Strsql+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
			-- Rev 9.0
			IF @ISINACTIVEOUTLETS='0'
				SET @Strsql+='AND MS.Entity_Status=1 '
			-- End of Rev 9.0
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
	--Rev 5.0
		END
	--End of Rev 5.0

	DROP TABLE #BRANCH_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #TEMPCONTACT
	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END

	SET NOCOUNT OFF
END
GO