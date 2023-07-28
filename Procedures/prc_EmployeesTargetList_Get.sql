
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_EmployeesTargetList_Get]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_EmployeesTargetList_Get] AS' 
END
GO
--prc_EmployeesTargetList_Get 'ANDAMAN & NICOBAR ISLANDS','',378
-- exec prc_EmployeesTargetList_Get @EMPTYPEID=3, @STATE='WEST BENGAL', @DESIGNATION='WD', @USERID=11706, @SETTINGMONTH='1', @SETTINGYEAR='2023',@COUNTERTYPE=4,@TYPE='GetList'
-- exec prc_EmployeesTargetList_Get @EMPTYPEID=0, @STATE='', @DESIGNATION='', @USERID=11706, @SETTINGMONTH='1', @SETTINGYEAR='2023',@COUNTERTYPE=0,@TYPE='GetByID'

--SELECT user_contactId FROM tbl_master_user

ALTER PROC [dbo].[prc_EmployeesTargetList_Get]
(
@EMPTYPEID INT,
@STATE VARCHAR(MAX) ,
@DESIGNATION VARCHAR(MAX) = null,
@USERID INT = 0,
@SETTINGMONTH INT,
@SETTINGYEAR INT,
@COUNTERTYPE INT,
@TYPE VARCHAR(100) = NULL
) WITH ENCRYPTION 

AS 
/*******************************************************************************************************************************************************************************************
1.0		v2.0.36		Sanchita	10-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" then data in portal shall be populated based on Hierarchy Only.
												Refer: 25504
2.0		V2.0.39		Sanchita	18-04-2023		"Unable to upload Employee Target from Portal.
												After importing the Target template from the portal, no data is showing in the listing page.	"
												After analysis it was found that in the Download Format excel, the column "Stage" was missing.
												This resulted in error. This has been resolved. Refer: 25837
3.0		V2.0.42		Sanchita	28-07-2023		Masters - Organization - Employees Target - when clicked on the Search button no data comming.
												Error showing from SP - column Stage not found. Mantis : 26637
********************************************************************************************************************************************************************************************/
 SET NOCOUNT ON ;
 BEGIN TRY 
 Declare @CONTACTUSERID nvarchar(MAX);

 IF @TYPE IS NULL OR @TYPE = 'GetList'
 BEGIN

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

	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	--SELECT * FROM #TEMPCONTACT
	
	DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@userid)


	SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE INTO #EMPHR   FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO

	;with cte as(select	
	EMPCODE
	from #EMPHR 
	where EMPCODE IS NULL OR EMPCODE=@empcode  
	union all
	select	
	a.EMPCODE
	from #EMPHR a
	join cte b
	on a.RPTTOEMPCODE = b.EMPCODE
	) 

	select 
	user_id INTO #EMPLOYEELIST
	from cte 
	inner join tbl_master_user TMU on cte.EMPCODE=TMU.user_contactId



	--SELECT * FROM #EMPLOYEELIST


		select	 USR.user_id , 
		 USR.user_loginId as ContactNo
		,USR.user_contactId as EmployeeCode
		,CNT.cnt_firstName+' '+CNT.cnt_lastName as Employeename
		,ETST.TypeName AS EmpTypeName
		 
		,ETST2.TypeName AS CounterTypeName
		--,STAT.state
		 
		,N.deg_designation as Designation
		 
		--,RPTTO.REPORTTO AS Supervisor
		 
		--,ISNULL(EMPST.SettingMonthYear , '') as SettingMonthYear

		,ISNULL(EMPST.NewCounter,0 ) AS NewCounter

		,ISNULL(EMPST.Revisit,0 ) AS Revisit

		,ISNULL(EMPST.OrderValue ,0.0 ) AS OrderValue

		,ISNULL(EMPST.EmployeeTargetSettingID,0) AS EmployeeTargetSettingID

		,ISNULL(EMPST.[Collection],0.0 ) AS [Collection]

		,ISNULL(EMPST.CreatedDate,GETDATE()) AS CreatedDate

		,ISNULL(EMPST.ModifiedDate,GETDATE()) AS ModifiedDate

		-- Rev 3.0
		, 0 as Stage 
		-- End of Rev 3.0

		from tbl_master_user as USR
		INNER JOIN  #EMPLOYEELIST EMLIST ON EMLIST.user_id=usr.user_id and usr.user_id<>@USERID
		--(SELECT user_id reportto,UserID userid FROM (SELECT TMU.user_id AS UserID,TMU.user_name username,desg.deg_id,DESG.emp_reportTo FROM tbl_master_employee  MEMP
		--INNER JOIN  tbl_master_user  TMU on TMU.user_contactId=MEMP.emp_contactId  
		--INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id,cnt.emp_reportTo  FROM tbl_trans_employeeCTC as cnt  
		--LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,cnt.emp_reportTo ) 
		--DESG ON DESG.emp_cntId=MEMP.emp_contactId 
		--)EMP
  --      INNER JOIN tbl_master_employee EM ON EM.emp_id=EMP.emp_reportTo  
	 --   INNER JOIN  TBL_MASTER_USER  TMU on TMU.user_contactId=EM.emp_contactId 
	 --   ) REPORTTO ON REPORTTO.userid=USR.user_id and REPORTTO.reportto= @USERID

		LEFT OUTER JOIN tbl_FTS_EmployeesTargetSetting EMPST ON LTRIM(RTRIM(EMPST.EmployeeCode)) = LTRIM(RTRIM(USR.user_contactId)) AND (EMPST.SettingMonth = @SETTINGMONTH AND EMPST.SettingYear = @SETTINGYEAR) AND EMPST.FKEmployeesTargetSettingEmpTypeID = @EMPTYPEID AND EMPST.FKEmployeesCounterType = @COUNTERTYPE

		LEFT OUTER JOIN tbl_FTS_EmployeesTargetSettingEmpType ETST ON LTRIM(RTRIM(EMPST.FKEmployeesTargetSettingEmpTypeID)) = LTRIM(RTRIM(ETST.EmployeesTargetSettingEmpTypeID)) 

		LEFT OUTER JOIN tbl_FTS_EmployeesTargetSettingEmpType ETST2 ON LTRIM(RTRIM(EMPST.FKEmployeesCounterType)) = LTRIM(RTRIM(ETST2.EmployeesTargetSettingEmpTypeID)) 

		INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId 

		LEFT JOIN (select add_cntId,add_state, mstate.state from tbl_master_address madd INNER JOIN tbl_master_state as mstate on mstate.id=madd.add_state where add_addresstype='office' ) STAT on STAT.add_cntId=USR.user_contactId 

		and STAT.state = @STATE

		LEFT JOIN (select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id  from 

		tbl_trans_employeeCTC as cnt 

		INNER JOIN    tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation   AND desg.DisplayInTarget = 1

		group by  emp_cntId,desg.deg_designation)N

		on USR.user_contactId= N.emp_cntId  --AND deg_designation = @DESIGNATION

		--where EMP.emp_reportTo = @USERID

		DROP TABLE #TEMPCONTACT
		drop table #EMPHR
	    drop table #EMPLOYEELIST
END

ELSE IF @TYPE = 'GetByID'
BEGIN
	-- Rev 1.0
	declare @Strsql nvarchar(max)

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DECLARE @empcode1 VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
		CREATE TABLE #EMPHR1
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)

		CREATE TABLE #EMPHR_EDIT1
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)
		
		INSERT INTO #EMPHR1
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
		FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
		;with cte as(select	
		EMPCODE,RPTTOEMPCODE
		from #EMPHR1 
		where EMPCODE IS NULL OR EMPCODE=@empcode1  
		union all
		select	
		a.EMPCODE,a.RPTTOEMPCODE
		from #EMPHR1 a
		join cte b
		on a.RPTTOEMPCODE = b.EMPCODE
		) 
		INSERT INTO #EMPHR_EDIT1
		select EMPCODE,RPTTOEMPCODE  from cte 

	END

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT1') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT1
		CREATE TABLE #TEMPCONTACT1
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_ucc NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			USER_ID BIGINT
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT1(cnt_internalId,cnt_contactType ASC)
	
	SET @Strsql=''
	SET @Strsql+=' INSERT INTO #TEMPCONTACT1 '
	SET @Strsql+=' SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,CNT.cnt_UCC,USR.user_id FROM TBL_MASTER_CONTACT CNT '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT1 HRY ON CNT.cnt_internalId=HRY.EMPCODE    '
	END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '

	--select @Strsql
	EXEC SP_EXECUTESQL @Strsql
	-- End of Rev 1.0

	-- Rev 1.0
	--SELECT ETS.EmployeeTargetSettingID,ETS.FKEmployeesTargetSettingEmpTypeID,ETS.EmployeeCode,ETS.SettingMonth,ETS.SettingYear,ETS.OrderValue,ETS.NewCounter,ETS.Revisit,ETS.Collection FROM  tbl_FTS_EmployeesTargetSetting ETS
	--INNER JOIN tbl_master_user USR ON ETS.EmployeeCode = USR.user_contactId
	--WHERE USR.user_id = @USERID AND ETS.SettingMonth = @SETTINGMONTH AND ETS.SettingYear = @SETTINGYEAR

	SET @Strsql=''
	SET @Strsql+=' SELECT ETS.EmployeeTargetSettingID,ETS.FKEmployeesTargetSettingEmpTypeID,ETS.EmployeeCode,ETS.SettingMonth,ETS.SettingYear,ETS.OrderValue,ETS.NewCounter,ETS.Revisit,ETS.Collection FROM  tbl_FTS_EmployeesTargetSetting ETS '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON ETS.EmployeeCode = USR.user_contactId '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #TEMPCONTACT1 CNT ON CNT.USER_ID=USR.User_Id '
	end
	SET @Strsql+=' WHERE USR.user_id = '''+ convert(varchar, @USERID)+''' AND ETS.SettingMonth = '''+ convert(varchar, @SETTINGMONTH)+''' AND ETS.SettingYear = '''+ convert(varchar, @SETTINGYEAR) +''' '
	select @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #TEMPCONTACT1
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT1
		DROP TABLE #EMPHR1
	END
	-- End of Rev 1.0
	
END
--ELSE IF @TYPE= 'GetReportToList'
--BEGIN
	
--		SELECT USR.user_id,USR.user_name,USR.user_contactId,REPORTTO.reportto,MC.cnt_firstName + ' ' + MC.cnt_lastName from tbl_master_user as USR
--		INNER JOIN 
--		(SELECT user_id reportto,UserID userid FROM (SELECT TMU.user_id AS UserID,TMU.user_name username,desg.deg_id,DESG.emp_reportTo FROM tbl_master_employee  MEMP
--		INNER JOIN  tbl_master_user  TMU on TMU.user_contactId=MEMP.emp_contactId  
--		INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id,cnt.emp_reportTo  FROM tbl_trans_employeeCTC as cnt  
--		LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,cnt.emp_reportTo ) 
--		DESG ON DESG.emp_cntId=MEMP.emp_contactId 
--		)EMP
--        INNER JOIN tbl_master_employee EM ON EM.emp_id=EMP.emp_reportTo  
--	    INNER JOIN  TBL_MASTER_USER  TMU on TMU.user_contactId=EM.emp_contactId 
--	    ) REPORTTO ON REPORTTO.userid=USR.user_id and REPORTTO.reportto= @USERID
--		INNER JOIN tbl_master_contact MC ON MC.cnt_internalId = USR.user_contactId




--END

ELSE IF @TYPE = 'GetTemplateByStateDesignation'
BEGIN

	DECLARE @TempSate table
		( 
		  [Sate] VARCHAR(100)
		)

	DECLARE @TempDesignation table
	( 
		[Designation] VARCHAR(100)
	)

	WHILE LEN(@STATE) > 0
	BEGIN
		DECLARE @TDay VARCHAR(200)
		IF CHARINDEX(',',@STATE) > 0
			SET  @TDay = SUBSTRING(@STATE,0,CHARINDEX(',',@STATE))
		ELSE
			BEGIN
			SET  @TDay = @STATE
			SET @STATE = ''
			END
	  INSERT INTO  @TempSate VALUES (replace(@TDay,'|','&'))
	 SET @STATE = REPLACE(@STATE,@TDay + ',' , '')
	 END

		 WHILE LEN(@DESIGNATION) > 0
	BEGIN

		DECLARE @TDesg VARCHAR(200)
		IF CHARINDEX(',',@DESIGNATION) > 0
			SET  @TDesg = SUBSTRING(@DESIGNATION,0,CHARINDEX(',',@DESIGNATION));
		ELSE
			BEGIN
			SET  @TDesg = @DESIGNATION
			SET @DESIGNATION = ''
			END
	  INSERT INTO  @TempDesignation VALUES (@TDesg)
	 SET @DESIGNATION = REPLACE(@DESIGNATION,@TDesg + ',' , '')
	 END

	 

	  --SELECT *  FROM @Temp

	(
		SELECT musr.user_loginId AS LoginID,CNT.cnt_firstName + ' '+ CNT.cnt_lastName AS EmpName,n.deg_designation AS Designation,
		S.add_state AS StateID,STAT.state AS StateName,CNT.cnt_internalId AS EMPCODE,
	
		MASC.cnt_firstName + ' '+ MASC.cnt_lastName AS ReportTo,repttodesg.deg_designation AS ReportToDesignation,

		'EMP' AS [Type],convert(char(3), GETDATE(), 0) AS [MonthName],DATEPART(yyyy, GETDATE()) AS [Year], 0 as NewCounter, 0 as ReVisit, 0 as TargetValue, Convert(INT,'0') as TargetCollection
		-- Rev 2.0
		, 0 as Stage 
		-- End of Rev 2.0
		 FROM tbl_master_user AS musr
		inner join tbl_master_contact CNT ON CNT.cnt_internalId = musr.user_contactId
		inner join
		(
		select  cnt.emp_cntId,desg.deg_designation,MAx(cnt.emp_id) as emp_id,desg.deg_id from 
		 tbl_trans_employeeCTC as cnt 
		left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation
	
		group by emp_cntId,desg.deg_designation,desg.deg_id
		)N
		on  N.emp_cntId=musr.user_contactId
		inner  JOIN (
		SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType='Office' 
		)S on S.add_cntId=CNT.cnt_internalId
		LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state
		INNER  JOIN tbl_trans_employeeCTC  as reptto  on N.emp_id=reptto.emp_id
		INNER  join  tbl_master_designation as repttodesg on repttodesg.deg_id=reptto.emp_Designation
		INNER JOIN tbl_master_employee AS MAS ON reptto.emp_reportTo = MAS.emp_id
		INNER JOIN tbl_master_contact MASC ON MASC.cnt_internalId = MAS.emp_contactId
		INNER JOIN @TempSate tmp  ON STAT.state = tmp.Sate
		INNER JOIN @TempDesignation tmpdsg ON n.deg_designation = tmpdsg.Designation
		WHERE musr.user_inactive = 'N'
		--WHERE 
		--STAT.state = @STATE AND 
		--n.deg_designation= @DESIGNATION)
	)

	UNION ALL

	(
		SELECT MS.Shop_Owner_Contact AS LoginID, MS.Shop_Name AS ShopName,'' AS Designation,MS.stateId AS StateID,MST.state AS ShopState, '' AS EmpCode,
		MCON.cnt_firstName + ' '+ MCON.cnt_lastName AS ReportTo,N.deg_designation AS ReportToDesignation,
		(CASE WHEN ST.typeID = 2
		THEN 'PP'
		END) AS ShopType,convert(char(3), GETDATE(), 0) AS [MonthName],DATEPART(yyyy, GETDATE()) AS [Year],
		0 AS ShopCounter,
		0 AS ShopRevisit,
		0 AS TargetValue,
		Convert(INT,'0') AS TargetCollection
		-- Rev 2.0
		, 0 as Stage 
		-- End of Rev 2.0
		FROM tbl_master_shop MS INNER JOIN tbl_shoptype ST ON  MS.type = ST.typeID 
		INNER JOIN tbl_master_state MST ON MST.id= MS.stateId
		INNER JOIN tbl_master_user MUSR ON 
			MUSR.user_id = 
			CASE WHEN MS.AssignTo IS NULL
			THEN MS.Shop_CreateUser
			ELSE 
			MS.AssignTo
			END
		INNER JOIN tbl_master_contact MCON ON MCON.cnt_internalId = MUSR.user_contactId
		inner join
		(
			select  cnt.emp_cntId,desg.deg_designation,MAx(cnt.emp_id) as emp_id,desg.deg_id from 
			 tbl_trans_employeeCTC as cnt 
			left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation
			group by emp_cntId,desg.deg_designation,desg.deg_id
		)N
		on  N.emp_cntId=MUSR.user_contactId
		INNER JOIN @TempSate tmp  ON MST.state = tmp.Sate
		WHERE (ST.typeID = 2) --AND MUSR.user_inactive = 'N'
		--AND MST.state = @STATE
	)
	UNION ALL

	(
		SELECT MS.Shop_Owner_Contact AS LoginID, MS.Shop_Name AS ShopName,'' AS Designation,MS.stateId AS StateID,MST.state AS ShopState, '' AS EmpCode,
		MCON.cnt_firstName + ' '+ MCON.cnt_lastName AS ReportTo,N.deg_designation AS ReportToDesignation,
		(CASE 
		WHEN ST.typeID = 4
		THEN 'DD'
		END) AS ShopType,convert(char(3), GETDATE(), 0) AS [MonthName],DATEPART(yyyy, GETDATE()) AS [Year],
		0 AS ShopCounter,
		0 AS ShopRevisit,
		0 AS TargetValue,
		Convert(INT,'0') AS TargetCollection
		-- Rev 2.0
		, 0 as Stage 
		-- End of Rev 2.0
		FROM tbl_master_shop MS INNER JOIN tbl_shoptype ST ON  MS.type = ST.typeID 
		INNER JOIN tbl_master_state MST ON MST.id= MS.stateId
		INNER JOIN tbl_master_user MUSR ON 
			MUSR.user_id = 
			CASE WHEN MS.AssignTo IS NULL
			THEN MS.Shop_CreateUser
			ELSE 
			MS.AssignTo
			END
		INNER JOIN tbl_master_contact MCON ON MCON.cnt_internalId = MUSR.user_contactId
		inner join
		(
			select  cnt.emp_cntId,desg.deg_designation,MAx(cnt.emp_id) as emp_id,desg.deg_id from 
			 tbl_trans_employeeCTC as cnt 
			left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation
			group by emp_cntId,desg.deg_designation,desg.deg_id
		)N
		on  N.emp_cntId=MUSR.user_contactId
		INNER JOIN @TempSate tmp  ON MST.state = tmp.Sate
		WHERE (ST.typeID = 4) --AND MUSR.user_inactive = 'N'
		--AND MST.state = @STATE
	)
	
	--select * from tbl_FTS_EmployeesTargetSetting
	--select * from tbl_FTS_EmployeesTargetSettingCounterTarget
	--select * from tbl_FTS_EmployeesTargetSettingEmpType


END

ELSE IF @TYPE = 'GetUserHierarchywiseTarget'
BEGIN
	SELECT HierarchywiseTargetSettings FROM tbl_master_user WHERE USER_ID = @USERID
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