--EXEC PRC_FTSPJPvsActualDetails_List @FROMDATE='2020-06-01',@TODATE='2020-06-19',@USERID=1

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSPJPvsActualDetails_List]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSPJPvsActualDetails_List] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_FTSPJPvsActualDetails_List]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT,
@DesigId NVARCHAR(MAX)=NULL
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0			Tanmoy		19-06-2020			Create sp
2.0			Sanchita	02-02-2023		v2.0.38		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
													then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
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

	-- Rev 2.0
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
		-- Rev 2.0 [ existing issue solved]
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
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
		END
	SET @Strsql+=' WHERE cnt_contactType IN(''EM'') '
	exec sp_executesql @Strsql
	-- End of Rev 2.0
 
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTS_PJPvsActualDetailsReport') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTS_PJPvsActualDetailsReport
		(
		SEQ BIGINT,
		USERID BIGINT,
		Date NVARCHAR(10),
		EMPLOYEE NVARCHAR(300),
		Designation NVARCHAR(200),
		Phone NVARCHAR(15),
		Supervisor NVARCHAR(300),
		State NVARCHAR(200),
		PJPCustomer NVARCHAR(300),
		CustomerPhone NVARCHAR(15),
		CustomerType NVARCHAR(100),
		Location NVARCHAR(100),
		From_Time NVARCHAR(15),
		To_Time NVARCHAR(15),
		PJPRemarks NVARCHAR(500),
		AchvCustomer NVARCHAR(300),
		AchvCustomerPhone NVARCHAR(15),
		AchvCustomerType NVARCHAR(100),
		AchvLocation NVARCHAR(100),
		AchvCustomerAddress NVARCHAR(MAX),
		GPSAddress NVARCHAR(MAX),
		AchvVisit_Time NVARCHAR(15),
		Status NVARCHAR(20),
		Ordervalue DECIMAL(20,2),
		AchvRemarks NVARCHAR(500),
		)
	END
	delete from FTS_PJPvsActualDetailsReport where USERID=@USERID
 
	SET @Strsql=' '
 
	SET @Strsql+=' INSERT INTO FTS_PJPvsActualDetailsReport   '
	SET @Strsql+=' SELECT ROW_NUMBER() OVER(ORDER BY ATTEN.Login_datetime DESC) AS SEQ,'''+STR(@USERID)+''',ATTEN.Login_datetime,  '
	SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''')+'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS EMPLOYEE,  '
	SET @Strsql+=' DESG.deg_designation,CNT.Contact_no,RPTTO.REPORTTO,SAT.state,PJPCustomer,CustomerPhone,CustomerType,Location,From_Time,To_Time,PJPRemarks  '
	SET @Strsql+=' PJPRemarks,AchvCustomer,AchvCustomerPhone,AchvCustomerType,AchvLocation,AchvCustomerAddress,GPSAddress,AchvVisit_Time,   '
	SET @Strsql+=' CASE WHEN PJPCustomer=AchvCustomer THEN ''PJP Matched'' WHEN ISNULL(AchvCustomer,'''')='''' THEN ''PJP Not Matched'' WHEN ISNULL(PJPCustomer,'''')='''' THEN VISIT_STATUS END AS Status,   '
	SET @Strsql+=' ISNULL(Ordervalue,0) AS Ordervalue, AchvRemarks   '
	SET @Strsql+=' FROM tbl_master_employee emp   '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=emp.emp_contactId    '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SOP ON SOP.Shop_CreateUser=CNT.USER_ID   '
	
	SET @Strsql+=' INNER JOIN (   '
	SET @Strsql+=' SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime    '
	SET @Strsql+=' FROM tbl_fts_UserAttendanceLoginlogout ATTEN    '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N''    '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId    '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)   '
	SET @Strsql+=' AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false''    '
	SET @Strsql+=' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105)     '
	SET @Strsql+=' ) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId    '
	 
	SET @Strsql+=' LEFT OUTER JOIN (   '
	SET @Strsql+=' SELECT User_Id,cnt_internalId,CONVERT(NVARCHAR(10),PJP_Date,105) AS PJP_Date,PJPCustomer,CustomerPhone,CustomerType,  '
	SET @Strsql+=' Location,From_Time,To_Time,PJPRemarks,SHOP_CODE FROM(     '
	SET @Strsql+=' SELECT PJP.User_Id,CNT.cnt_internalId,CAST(PJP.PJP_Date AS DATE) AS PJP_Date,PJP.From_Time,PJP.To_Time,     '
	SET @Strsql+=' PJP.REMARKS AS PJPRemarks,SHOP.Shop_Name AS PJPCustomer,SHOP.Shop_Owner_Contact AS CustomerPhone,    '
	SET @Strsql+=' TYP.Name AS CustomerType,AREA.area_name AS Location,PJP.SHOP_CODE    '
	SET @Strsql+=' FROM FTS_PJPPlanDetails PJP     '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=PJP.User_Id    '-- AND USR.user_loginId='9563218466'
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId    '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_Code=PJP.SHOP_CODE   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type    '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_area AREA ON AREA.area_id=SHOP.Area_id    '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),PJP.PJP_Date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)     '
	SET @Strsql+=' ) AA    '
	SET @Strsql+=' ) PJP ON PJP.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=PJP.PJP_Date AND SOP.Shop_Code=PJP.SHOP_CODE     '
	
	SET @Strsql+=' LEFT OUTER JOIN (     '
	SET @Strsql+=' SELECT User_Id,cnt_internalId,CONVERT(NVARCHAR(10),VISITED_TIME,105) AS VISITED_DATE,VISITED_TIME,AchvCustomer,AchvCustomerPhone,    '
	SET @Strsql+=' AchvCustomerType,AchvLocation,AchvCustomerAddress,GPSAddress,Shop_Id,AchvVisit_Time,AchvRemarks,VISIT_STATUS FROM(   '
	SET @Strsql+=' SELECT SHOPACT.User_Id,CNT.cnt_internalId,CAST(SHOPACT.visited_time AS DATE) AS visited_time,SHOP.Shop_Name AS AchvCustomer,    '
	SET @Strsql+=' SHOP.Shop_Owner_Contact AchvCustomerPhone,TYP.Name AS AchvCustomerType,AREA.area_name AS AchvLocation,SHOP.Address AS AchvCustomerAddress,   '
	SET @Strsql+=' '''' AS GPSAddress,SHOPACT.Shop_Id,CONVERT(VARCHAR(15),CAST(SHOPACT.visited_time AS TIME),100) AS AchvVisit_Time,    '
	SET @Strsql+=' SHOPACT.REMARKS AS AchvRemarks,CASE WHEN Is_Newshopadd=1 THEN ''New Visit'' ELSE ''Re-Visit'' END AS VISIT_STATUS    '
	SET @Strsql+=' FROM tbl_trans_shopActivitysubmit SHOPACT      '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id   '-- AND USR.user_loginId='9563218466'  
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId     '
	SET @Strsql+=' INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_Code=SHOPACT.Shop_Id    '
	SET @Strsql+=' LEFT OUTER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type    '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_area AREA ON AREA.area_id=SHOP.Area_id     '
	SET @Strsql+=' WHERE Is_Newshopadd IN(0,1)    '
	SET @Strsql+=' AND CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)     '
	SET @Strsql+=' ) AA   '
	SET @Strsql+=' ) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=SHOPACT.VISITED_DATE AND SOP.Shop_Code=SHOPACT.Shop_Id    '
	
	SET @Strsql+=' LEFT OUTER JOIN (SELECT ORDH.userID,CNT.cnt_internalId,ISNULL(Ordervalue,0) AS Ordervalue,    '
	SET @Strsql+=' CONVERT(NVARCHAR(10),ORDH.Orderdate,105) AS ORDDATE,ORDH.Shop_Code    '
	SET @Strsql+=' FROM tbl_trans_fts_Orderupdate ORDH      '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID     '
	SET @Strsql+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId     '
	SET @Strsql+=' WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120)   '
	SET @Strsql+=' ) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=ORDHEAD.ORDDATE AND ORDHEAD.Shop_Code=SHOPACT.Shop_Id    '
	
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_address ADRS ON ADRS.add_cntId=emp.emp_contactId AND ADRS.add_addressType=''OFFICE''   '
	SET @Strsql+=' LEFT OUTER JOIN TBL_MASTER_STATE SAT ON SAT.id=ADRS.add_state    '
	SET @Strsql+=' LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,   '
	SET @Strsql+=' CNT.cnt_internalId,  '
	SET @Strsql+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')<>'''' THEN ISNULL(CNT.cnt_middleName,'''')+'' '' ELSE '''' END +ISNULL(CNT.cnt_lastName,'''') AS REPORTTO,  '
	SET @Strsql+=' DESG.deg_designation AS RPTTODESG,CNT.cnt_ucc AS REPORTTO_ID FROM tbl_master_employee EMP    '
	SET @Strsql+=' LEFT OUTER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo    '
	SET @Strsql+=' LEFT OUTER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId  '
	SET @Strsql+=' LEFT OUTER JOIN (    '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt  	'
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL  '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId   '
	SET @Strsql+=' WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId   '
	SET @Strsql+=' LEFT OUTER JOIN (   '
	SET @Strsql+=' SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt   '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL	 '
	SET @Strsql+=' GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=CNT.cnt_internalId  '
	
	SET @Strsql+=' WHERE (PJPCustomer IS NOT NULL OR AchvCustomer IS NOT NULL)  '--CNT.Contact_no IN ('9563218466') AND 
	IF @STATEID<>''
		SET @Strsql+=' AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=SAT.id) '
	IF @EMPID<>''
		SET @Strsql+=' AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	IF @DesigId<>''
		SET @Strsql+=' AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DEG WHERE DEG.deg_id=DESG.deg_id) '

	SET @Strsql+=' ORDER BY EMPLOYEE,Login_datetime   '

	EXEC SP_EXECUTESQL @Strsql
	--SELECT @Strsql


	DROP TABLE #TEMPCONTACT
	DROP TABLE #STATEID_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #DESIGNATION_LIST
	-- Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 2.0

END