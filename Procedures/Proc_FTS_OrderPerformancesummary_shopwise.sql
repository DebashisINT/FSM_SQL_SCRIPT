
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_OrderPerformancesummary_shopwise]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_OrderPerformancesummary_shopwise] AS' 
END
GO
--exec [Proc_FTS_OrderPerformancesummary_shopwise] '','','','',''
ALTER  Proc [dbo].[Proc_FTS_OrderPerformancesummary_shopwise]
(
@Employee_id varchar(MAX)=NULL,
@start_date  varchar(MAX)=NULL,
@end_date  varchar(MAX)=NULL,
@stateID varchar(MAX)=NULL,
@DesignationID varchar(MAX)=NULL
-- Rev 1.0
, @USERID INT = null
-- End of Rev 1.0
)WITH ENCRYPTION
As
/****************************************************************************************************************************************************************************
1.0		v2.0.38		Sanchita	02-02-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN

	declare @SQL  nvarchar(MAX)=NULL,@sqlEmpStrTable nvarchar(MAX),@sqlShopStrTable nvarchar(MAX),@sqlStateStrTable nvarchar(MAX)

	-- Rev 1.0
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
	-- End of Rev 1.0

	----------------------------------EMPLOYEE---------------------------
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
					DROP TABLE #EMPLOYEE_LIST
				CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
				IF @Employee_id <> ''
					BEGIN
						SET @Employee_id = REPLACE(''''+@Employee_id+'''',',',''',''')
						SET @sqlEmpStrTable=''
						SET @sqlEmpStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT cnt_internalId from tbl_master_contact where cnt_internalId in('+@Employee_id+')'
						EXEC SP_EXECUTESQL @sqlEmpStrTable
					END

	-------------------------------STATE----------------------------------------------------
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATE_LIST') AND TYPE IN (N'U'))
					DROP TABLE #STATE_LIST
				CREATE TABLE #STATE_LIST (STATE_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
				IF @stateID <> ''
					BEGIN
						SET @stateID = REPLACE(''''+@stateID+'''',',',''',''')
						SET @sqlStateStrTable=''
						SET @sqlStateStrTable=' INSERT INTO #STATE_LIST SELECT id from tbl_master_state where id in('+@stateID+')'
						EXEC SP_EXECUTESQL @sqlStateStrTable
					END

	----------------------------------DESIGNATION-------------------------------------------------------

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#DESIGNATION_LIST') AND TYPE IN (N'U'))
					DROP TABLE #DESIGNATION_LIST
				CREATE TABLE #DESIGNATION_LIST (DEG_ID NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS,cnt_DegInternalID  NVARCHAR(100) ,DegnationName  NVARCHAR(100))
				IF @DesignationID<> ''
					BEGIN
						SET @DesignationID = REPLACE(''''+@DesignationID+'''',',',''',''')
						SET @sqlStateStrTable=''
						SET @sqlStateStrTable='INSERT INTO  #DESIGNATION_LIST select  desg.deg_id ,cnt.emp_cntId,desg.deg_designation  from 
											 tbl_trans_employeeCTC as cnt left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation where desg.deg_id in('+@DesignationID+')
											 group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null'
						EXEC SP_EXECUTESQL @sqlStateStrTable
					END

	SET @SQL='
	select  ordupdate.Shop_code,ordupdate.OrderCode,shp.Shop_Name ,R.Total_invoiceamt,ordupdate.Ordervalue,ordupdate.Collectionvalue,
	CNT.cnt_firstName+'' ''+CNT.cnt_middleName+'' ''+CNT.cnt_lastName as EmployeeName,ordupdate.Orderdate,
	TYP.Name as Typename,DEG.deg_designation,STAT.state as StateName
	from  tbl_trans_fts_Orderupdate as ordupdate 
	LEFT OUTER JOIN
	(
	select  isnull(sum(invoice_amount),0) as Total_invoiceamt,OrderCode  from tbl_FTS_BillingDetails group by OrderCode
	)R on R.OrderCode=ordupdate.OrderCode
	inner join tbl_Master_shop as shp on shp.Shop_Code=ordupdate.Shop_code
	inner join tbl_shoptype as TYP on shp.type=TYP.TypeId
	inner join tbl_master_user as USR on USR.user_id=ordupdate.userID
	inner join tbl_master_contact as CNT on CNT.cnt_internalId=USR.user_contactId '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			SET @SQL+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
		END
	SET @SQL+=' LEFT OUTER  JOIN (
	SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' 
	)S on S.add_cntId=CNT.cnt_internalId
	INNER JOIN tbl_master_state as STAT on STAT.id=S.add_state
	LEFT OUTER JOIN
	(
	select  desg.deg_id ,cnt.emp_cntId,desg.deg_designation  from 
	tbl_trans_employeeCTC as cnt left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation
	group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null
	)DEG on DEG.emp_cntId= CNT.cnt_internalId where USR.user_id<>0  '



	if(isnull(@Employee_id,'')<>'')
	SET @SQL+=' AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST WHERE emp_contactId=cnt_internalId) '
	if(isnull(@stateID,'')<>'')
	SET @SQL+=' AND EXISTS (SELECT STATE_ID FROM #STATE_LIST WHERE STATE_ID=STAT.id) '
	if(isnull(@DesignationID,'')<>'')
	SET @SQL+=' AND EXISTS (SELECT DEG_ID FROM #DESIGNATION_LIST WHERE DEG_ID=DEG.deg_id) '
	if(isnull(@start_date,'')<>'')
	SET  @SQL+='  and  cast(ordupdate.Orderdate  as date)>='''+@start_date+'''' 
	if(isnull(@end_date,'')<>'')
	SET  @SQL+='  and  cast(ordupdate.Orderdate  as date)<='''+@end_date+'''' 
	EXEC Sp_ExecuteSQL @SQL
	DROP  TABLE #EMPLOYEE_LIST
	DROP  TABLE #STATE_LIST
	DROP  TABLE #DESIGNATION_LIST
	-- Rev 1.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 1.0
END

