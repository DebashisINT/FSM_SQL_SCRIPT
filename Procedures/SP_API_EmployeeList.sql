--EXEC SP_API_EmployeeList '','',''
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SP_API_EmployeeList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [SP_API_EmployeeList] AS' 
END
GO

--EXEC SP_API_EmployeeList '',''
ALTER Proc [SP_API_EmployeeList]
(
@StateId nvarchar(max)=null,
@DesigId nvarchar(max)=null,
--Rev 2.0
--@ShopID nvarchar(max)=null
@DeptId nvarchar(max)=null
--End of Rev 2.0
-- Rev 3.0
, @USERID INT =NULL
-- End of Rev 3.0
) WITH ENCRYPTION
AS
/*******************************************************************************************************************************************************************************************
1.0		v2.0.25		Debashis	22-11-2021		Inactive employee name is appearing in the search parameter of Attendance Register report.Refer: 0024494
2.0		v2.0.25		Debashis	25-11-2021		@ShopID parameter was wrong.Now it has been rectified.
3.0		v2.0.36		Sanchita	10-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" then data in portal shall be populated based on Hierarchy Only.
												Refer: 25504
********************************************************************************************************************************************************************************************/
BEGIN
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	-- Rev 3.0
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
		-- End of Rev 3.0

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
	IF @DesigId <> ''
		BEGIN
			SET @DesigId=REPLACE(@DesigId,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation where deg_id in('+@DesigId+')'
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

	-- Rev 3.0
	--INSERT INTO #TEMPCONTACT
	--SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT '
	SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT CNT '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE    '
	END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '

	EXEC SP_EXECUTESQL @Strsql
	-- End of Rev 3.0
	
	SET @Strsql=''
	SET @Strsql='SELECT * FROM( '
	SET @Strsql+='SELECT DISTINCT EMP.emp_contactId as empcode, '
	SET @Strsql+=' LTRIM(RTRIM((IsNull(cnt_firstName,'''')+'' ''+CASE WHEN IsNull(cnt_middleName,'''')<>'''' THEN cnt_middleName+'' '' ELSE '''' END +IsNull(cnt_lastName,'''')))) as empname, '
	SET @Strsql+=' ST.id,DESG.deg_id FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	--Rev 1.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON EMP.emp_contactId=USR.user_contactId AND USR.user_inactive=''N'' '
	--End of Rev 1.0
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=EMP.emp_contactId AND EMPCTC.emp_effectiveuntil IS NULL '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
	SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+=') AS EMP '
	IF @STATEID<>'' AND @DesigId=''
		SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=EMP.id) '
	IF @STATEID='' AND @DesigId<>''
		SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=EMP.deg_id) '
	IF @STATEID<>'' AND @DesigId<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=EMP.id) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=EMP.deg_id) '
		END
	SET @Strsql+='ORDER BY empname '
	--select @Strsql
	EXEC (@Strsql)		
	
	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT

	-- Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHR
	END
	-- End of Rev 3.0

END