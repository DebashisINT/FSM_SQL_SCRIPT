IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSATTNDASHBOARD]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSATTNDASHBOARD] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSATTNDASHBOARD]
(
@ACTION VARCHAR(50)=NULL,
@USER_ID VARCHAR(12)=NULL,
@DATE VARCHAR(12)=NULL,
@MONTH VARCHAR(10)=NULL,
@YEAR VARCHAR(30)=NULL,
@YYYYMM VARCHAR(30)=null,
@CREATE_USERID BIGINT=NULL
) --WITH ENCRYPTION
/****************************************************************************************************************************************************************************
1.0		v2.0.28		Debashis	28/03/2022		Error occured in @ACTION='GETABSENTTODAY'.Refer: 0024774
****************************************************************************************************************************************************************************/
AS 
BEGIN
	--Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@CREATE_USERID)		
			IF OBJECT_ID('tempdb..#EMPHR') IS NOT NULL
				DROP TABLE #EMPHR
			CREATE TABLE #EMPHR
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			IF OBJECT_ID('tempdb..#EMPHR_EDIT') IS NOT NULL
				DROP TABLE #EMPHR_EDIT
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
	--End of Rev 2.0

	IF(@ACTION='GETBOXDATA')
	BEGIN

	DECLARE @TOTAL_EMPLOYEE BIGINT=0
	DECLARE @TOTAL_ONTIME_PERCENTAGE DECIMAL(18,2)=0
	DECLARE @TOTAL_ONTIME BIGINT=0
	DECLARE @TOTAL_LATETODAY BIGINT=0
	DECLARE @TOTAL_ABSENT BIGINT=0

	DECLARE @IN_TIME TIME=(
	SELECT CONVERT(TIME,[VALUE]) FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='Intime'
	)


	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SET @TOTAL_EMPLOYEE=(SELECT COUNT(0) CNT FROM tbl_master_employee EMP
									INNER JOIN TBL_MASTER_USER USR ON EMP.emp_contactId=USR.user_contactId and user_inactive='N'
									INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
									WHERE EXISTS(
									SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId))


			SET @TOTAL_ONTIME=(SELECT COUNT(0) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
								INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
									WHERE EXISTS(
									SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
			 AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) AND Attendence_time IS NOT NULL 
															  AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)<=@IN_TIME  AND Isonleave='FALSE')

	
			SET @TOTAL_ONTIME_PERCENTAGE=(CONVERT(DECIMAL(18,2),@TOTAL_ONTIME)/CONVERT(DECIMAL(18,2),(CASE WHEN @TOTAL_EMPLOYEE=0 THEN 1 ELSE @TOTAL_EMPLOYEE END)))*100

			SET @TOTAL_LATETODAY=(SELECT COUNT(0) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
									INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID
									INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
									INNER JOIN tbl_master_employee EMP on EMP.emp_contactId=USR.user_contactId
									WHERE CAST(LOGOUT.Work_datetime AS DATE)=CAST(GETDATE() AS DATE) 
									AND LOGOUT.Attendence_time IS NOT NULL AND CONVERT(TIME,LOGOUT.Work_datetime)>@IN_TIME and  LOGOUT.Isonleave='FALSE'
									and EXISTS(
									SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
									)
		END
		ELSE
		BEGIN
			SET @TOTAL_EMPLOYEE=(SELECT COUNT(0) CNT FROM tbl_master_employee EMP
									INNER JOIN TBL_MASTER_USER USR ON EMP.emp_contactId=USR.user_contactId and user_inactive='N'

									WHERE EXISTS(
									SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId))


			SET @TOTAL_ONTIME=(SELECT COUNT(0) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
			INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
									WHERE EXISTS(
									SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
			 AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) AND Attendence_time IS NOT NULL 
															  AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)<=@IN_TIME  AND Isonleave='FALSE')

	
			SET @TOTAL_ONTIME_PERCENTAGE=(CONVERT(DECIMAL(18,2),@TOTAL_ONTIME)/CONVERT(DECIMAL(18,2),(CASE WHEN @TOTAL_EMPLOYEE=0 THEN 1 ELSE @TOTAL_EMPLOYEE END)))*100

			SET @TOTAL_LATETODAY=(SELECT COUNT(0) FROM tbl_fts_UserAttendanceLoginlogout WHERE CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) 
															  AND Attendence_time IS NOT NULL AND CONVERT(TIME,Work_datetime)>@IN_TIME and  Isonleave='FALSE')

		END
		SET @TOTAL_ABSENT=@TOTAL_EMPLOYEE-@TOTAL_ONTIME-@TOTAL_LATETODAY

		SELECT  @TOTAL_EMPLOYEE TOTAL_EMPLOYEE,@TOTAL_ONTIME_PERCENTAGE TOTAL_ONTIME_PERCENTAGE,@TOTAL_ONTIME TOTAL_ONTIME,@TOTAL_LATETODAY TOTAL_LATETODAY,@TOTAL_ABSENT TOTAL_ABSENT

	END
	ELSE IF(@ACTION='GETCALENDERDATA')
	BEGIN

	IF(LEN(@MONTH)=1) SET @MONTH='0'+@MONTH


	DECLARE @FROMDATE DATE=@YEAR+'-'+@MONTH+'-01' 

	DECLARE @TODATE DATE=DATEADD(DAY,-1, DATEADD(MONTH,1,@FROMDATE))

	CREATE TABLE #TEMP_FULLMONTH
	(
	name VARCHAR(100),
	[date] VARCHAR(10)
	)

	CREATE TABLE #TEMP_LEAVESTATUS
	(
	leavetype VARCHAR(100),
	fromdate VARCHAR(10),
	todatedate VARCHAR(10),
	[status] varchar(50)
	)

	if(cast(@toDATE as date)>cast(getdate() as date))
	set @TODATE=cast(getdate() as date)

    
		WHILE (@TODATE>=@FROMDATE)
		BEGIN

		DECLARE @STATUS VARCHAR(40)=''


		IF EXISTS(	SELECT 1
		FROM tbl_fts_UserAttendanceLoginlogout WHERE CAST(Work_datetime AS DATE)=CAST(@FROMDATE AS DATE) AND Isonleave='true'
		AND USER_ID=@USER_ID)
		BEGIN

			SET @STATUS='OnLeave'

		END
		ELSE IF EXISTS(	SELECT 1
		FROM tbl_fts_UserAttendanceLoginlogout WHERE CAST(Work_datetime AS DATE)=CAST(@FROMDATE AS DATE) AND Isonleave='FALSE' AND Attendence_time IS NOT NULL
		AND USER_ID=@USER_ID)
		BEGIN

			SET @STATUS='Present'

		END
		ELSE
		BEGIN

			SET @STATUS='Absent'


		END





	   INSERT INTO #TEMP_FULLMONTH
	   SELECT @STATUS,CONVERT(VARCHAR(10),CAST(@FROMDATE AS DATE),120)



		SET @FROMDATE=DATEADD(DAY,1,@FROMDATE)
		END
	

		SELECT * FROM #TEMP_FULLMONTH

		DROP TABLE #TEMP_FULLMONTH


	END
	ELSE IF(@ACTION='GETATTNSUMMARY')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SELECT month_name, count(0) cnt,ord from(
		   SELECT LEFT(DATENAME(MONTH,CAST(Work_datetime AS date)),3)+','+CAST(YEAR(Work_datetime) AS VARCHAR(10)) month_name,( cast(YEAR(Work_datetime) as varchar(10))+caSE WHEN MONTH(CAST(Work_datetime AS date))<10 THEN '0'+CAST(MONTH(CAST(Work_datetime AS date)) AS VARCHAR(10)) ELSE cast(MONTH(CAST(Work_datetime AS date))  as varchar(10)) END) ord 
		   FROM tbl_fts_UserAttendanceLoginlogout
			INNER JOIN TBL_MASTER_USER USR ON tbl_fts_UserAttendanceLoginlogout.USER_ID=USR.USER_ID
			INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
			WHERE CAST(Work_datetime AS date)
		   >= CAST(CAST(YEAR(DATEADD(MONTH,-5,GETDATE())) AS VARCHAR(10)) +'-'+ CAST(MONTH(DATEADD(MONTH,-5,GETDATE())) AS VARCHAR(10))+'-'+'01' AS DATE) AND Isonleave='FALSE' 
		   AND Attendence_time IS NOT NULL) TBL GROUP BY month_name ,ord order by cast(ord as bigint ) DESC
		END
		ELSE
		BEGIN
				SELECT month_name, count(0) cnt,ord from(
			   SELECT LEFT(DATENAME(MONTH,CAST(Work_datetime AS date)),3)+','+CAST(YEAR(Work_datetime) AS VARCHAR(10)) month_name,( cast(YEAR(Work_datetime) as varchar(10))+caSE WHEN MONTH(CAST(Work_datetime AS date))<10 THEN '0'+CAST(MONTH(CAST(Work_datetime AS date)) AS VARCHAR(10)) ELSE cast(MONTH(CAST(Work_datetime AS date))  as varchar(10)) END) ord 
			   FROM tbl_fts_UserAttendanceLoginlogout
				WHERE CAST(Work_datetime AS date)
			   >= CAST(CAST(YEAR(DATEADD(MONTH,-5,GETDATE())) AS VARCHAR(10)) +'-'+ CAST(MONTH(DATEADD(MONTH,-5,GETDATE())) AS VARCHAR(10))+'-'+'01' AS DATE) AND Isonleave='FALSE' 
			   AND Attendence_time IS NOT NULL) TBL GROUP BY month_name ,ord order by cast(ord as bigint ) DESC
		END
	--SELECT      MONTHNAME(CAST(Work_datetime AS date)) AS MonthName, YEAR(CAST(Work_datetime AS date)) AS Year, count(0) AS Profits
	--FROM tbl_fts_UserAttendanceLoginlogout WHERE CAST(Work_datetime AS date)
	--   <= CAST(CAST(YEAR(GETDATE()) AS VARCHAR(10)) +'-'+ CAST(MONTH(DATEADD(MONTH,-6,GETDATE())) AS VARCHAR(10))+'-'+'01' AS DATE) AND Isonleave='FALSE' 
	--GROUP BY { fn MONTHNAME(CAST(Work_datetime AS date)) }, MONTH(CAST(Work_datetime AS date)), YEAR(CAST(Work_datetime AS date))
	--order by Year(CAST(Work_datetime AS date)),month(CAST(Work_datetime AS date))


	END
	ELSE IF (@ACTION='GETUSER')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SELECT USER_ID,CNT.CNT_FIRSTNAME+' ' + ISNULL(CNT.CNT_MIDDLENAME,'')+' ' + ISNULL(CNT.CNT_LASTNAME,'') NAME FROM tbl_master_employee EMP
			INNER JOIN TBL_MASTER_USER USR ON EMP.emp_contactId=USR.user_contactId and user_inactive='N'
			INNER JOIN TBL_MASTER_CONTACT CNT ON CNT.CNT_INTERNALID=USR.user_contactId
			INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
		END
		ELSE
		BEGIN
			SELECT USER_ID,CNT.CNT_FIRSTNAME+' ' + ISNULL(CNT.CNT_MIDDLENAME,'')+' ' + ISNULL(CNT.CNT_LASTNAME,'') NAME FROM tbl_master_employee EMP
			INNER JOIN TBL_MASTER_USER USR ON EMP.emp_contactId=USR.user_contactId and user_inactive='N'
			INNER JOIN TBL_MASTER_CONTACT CNT ON CNT.CNT_INTERNALID=USR.user_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
		END
	END
	ELSE IF (@ACTION='GETRECENTLEAVE')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
		SELECT TOP 10 CNT.CNT_FIRSTNAME+' ' + ISNULL(CNT.CNT_MIDDLENAME,'')+' ' + ISNULL(CNT.CNT_LASTNAME,'') NAME,CONVERT(VARCHAR(10),Leave_FromDate,105) LEAVE_START_DATE,
		CONVERT(VARCHAR(10),Leave_ToDate,105) 
		LEAVE_END_DATE,LT.LEAVETYPE,LeaveReason LEAVE_REASON ,'Approved' CURRENT_STATUS
		FROM tbl_fts_UserAttendanceLoginlogout APP 
		INNER JOIN TBL_MASTER_USER USR ON APP.USER_ID=USR.user_id and user_inactive='N' and isonleave='true' and Logout_datetime is NULL
		INNER JOIN TBL_MASTER_CONTACT CNT ON CNT.CNT_INTERNALID=USR.user_contactId
		LEFT JOIN tbl_FTS_Leavetype LT ON LT.Leave_Id=APP.LEAVE_TYPE
		INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
		WHERE EXISTS(
		SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=cnt_internalId)
		ORDER BY APP.Work_datetime DESC
	END
	ELSE
	BEGIN
		SELECT TOP 10 CNT.CNT_FIRSTNAME+' ' + ISNULL(CNT.CNT_MIDDLENAME,'')+' ' + ISNULL(CNT.CNT_LASTNAME,'') NAME,CONVERT(VARCHAR(10),Leave_FromDate,105) LEAVE_START_DATE,
		CONVERT(VARCHAR(10),Leave_ToDate,105) 
		LEAVE_END_DATE,LT.LEAVETYPE,LeaveReason LEAVE_REASON ,'Approved' CURRENT_STATUS
		FROM tbl_fts_UserAttendanceLoginlogout APP INNER JOIN TBL_MASTER_USER USR ON APP.USER_ID=USR.user_id and user_inactive='N' and isonleave='true' and Logout_datetime is NULL
		INNER JOIN TBL_MASTER_CONTACT CNT ON CNT.CNT_INTERNALID=USR.user_contactId
		LEFT JOIN tbl_FTS_Leavetype LT ON LT.Leave_Id=APP.LEAVE_TYPE
		WHERE EXISTS(
		SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=cnt_internalId)
		ORDER BY APP.Work_datetime DESC
	END
	END
	ELSE IF(@ACTION='GETTOTALEMP')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SELECT 
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			 FROM tbl_master_employee 
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			INNER JOIN tbl_master_user on emp_contactId=user_contactId and user_inactive='N'
			INNER JOIN #EMPHR_EDIT TMP ON user_contactId=TMP.EMPCODE
			LEFT JOIN (
			SELECT emp_cntId,cost_description,deg_designation,
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
			 FROM tbl_trans_employeeCTC
			LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
			left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
			 where emp_effectiveuntil IS NULL
 
			 ) TBL
			ON TBL.emp_cntId=emp_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
		END
		ELSE
		BEGIN
			SELECT 
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			 FROM tbl_master_employee 
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			INNER JOIN tbl_master_user on emp_contactId=user_contactId and user_inactive='N'
			LEFT JOIN (
			SELECT emp_cntId,cost_description,deg_designation,
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
			 FROM tbl_trans_employeeCTC
			LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
			left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
			 where emp_effectiveuntil IS NULL
 
			 ) TBL
			ON TBL.emp_cntId=emp_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)

		END
	END
	ELSE IF(@ACTION='GETONTIMETODAY')
	BEGIN

	SET @IN_TIME =(
	SELECT CONVERT(TIME,[VALUE]) FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='Intime'
	)

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SELECT 
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			,CONVERT(varchar(15),CAST(@IN_TIME AS TIME),100) Att_Time, 
			CONVERT(varchar(15),CONVERT(TIME,Work_datetime),100) att_Given


			 FROM tbl_master_employee 
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			INNER JOIN tbl_master_user usr on emp_contactId=user_contactId and user_inactive='N'
			INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
			INNER JOIN tbl_fts_UserAttendanceLoginlogout  LOGOUT ON LOGOUT.User_Id=usr.user_id
			LEFT JOIN (
			SELECT emp_cntId,cost_description,deg_designation,
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
			 FROM tbl_trans_employeeCTC
			LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
			left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
			 where emp_effectiveuntil IS NULL
 
			 ) TBL
			ON TBL.emp_cntId=emp_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE)
			AND Attendence_time is not null
			AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)<=@IN_TIME  AND Isonleave='FALSE'
		END
		ELSE
		BEGIN
			SELECT 
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			,CONVERT(varchar(15),CAST(@IN_TIME AS TIME),100) Att_Time, 
			CONVERT(varchar(15),CONVERT(TIME,Work_datetime),100) att_Given


			 FROM tbl_master_employee 
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			INNER JOIN tbl_master_user usr on emp_contactId=user_contactId and user_inactive='N'
			INNER JOIN tbl_fts_UserAttendanceLoginlogout  LOGOUT ON LOGOUT.User_Id=usr.user_id
			LEFT JOIN (
			SELECT emp_cntId,cost_description,deg_designation,
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
			 FROM tbl_trans_employeeCTC
			LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
			left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
			 where emp_effectiveuntil IS NULL
 
			 ) TBL
			ON TBL.emp_cntId=emp_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE)
			AND Attendence_time is not null
			AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)<=@IN_TIME  AND Isonleave='FALSE'
		END
	END
	ELSE IF(@ACTION='GETLATETODAY')
	BEGIN

	SET @IN_TIME  =(
	SELECT CONVERT(TIME,[VALUE]) FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='Intime'
	)

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SELECT 
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			,CONVERT(varchar(15),CAST(@IN_TIME AS TIME),100) Att_Time, 
			CONVERT(varchar(15),CONVERT(TIME,Work_datetime),100) att_Given
			,convert(varchar(5),DateDiff(s, CAST(@IN_TIME AS TIME), CONVERT(TIME,Work_datetime))/3600)+':'+convert(varchar(5),DateDiff(s, CAST(@IN_TIME AS TIME), CONVERT(TIME,Work_datetime))%3600/60)+':'+convert(varchar(5),(DateDiff(s, CAST(@IN_TIME AS TIME), CONVERT(TIME,Work_datetime))%60)) Diff

			 FROM tbl_master_employee 
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			INNER JOIN tbl_master_user usr on emp_contactId=user_contactId and user_inactive='N'
			INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
			INNER JOIN tbl_fts_UserAttendanceLoginlogout  LOGOUT ON LOGOUT.User_Id=usr.user_id
			LEFT JOIN (
			SELECT emp_cntId,cost_description,deg_designation,
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
			 FROM tbl_trans_employeeCTC
			LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
			left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
			 where emp_effectiveuntil IS NULL
 
			 ) TBL
			ON TBL.emp_cntId=emp_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE)
			AND Attendence_time is not null
			AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)>@IN_TIME  AND Isonleave='FALSE'
		END
		ELSE
		BEGIN
			SELECT 
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			,CONVERT(varchar(15),CAST(@IN_TIME AS TIME),100) Att_Time, 
			CONVERT(varchar(15),CONVERT(TIME,Work_datetime),100) att_Given
			,convert(varchar(5),DateDiff(s, CAST(@IN_TIME AS TIME), CONVERT(TIME,Work_datetime))/3600)+':'+convert(varchar(5),DateDiff(s, CAST(@IN_TIME AS TIME), CONVERT(TIME,Work_datetime))%3600/60)+':'+convert(varchar(5),(DateDiff(s, CAST(@IN_TIME AS TIME), CONVERT(TIME,Work_datetime))%60)) Diff

			 FROM tbl_master_employee 
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			INNER JOIN tbl_master_user usr on emp_contactId=user_contactId and user_inactive='N'
			INNER JOIN tbl_fts_UserAttendanceLoginlogout  LOGOUT ON LOGOUT.User_Id=usr.user_id
			LEFT JOIN (
			SELECT emp_cntId,cost_description,deg_designation,
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
			 FROM tbl_trans_employeeCTC
			LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
			left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
			 where emp_effectiveuntil IS NULL
 
			 ) TBL
			ON TBL.emp_cntId=emp_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
			AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE)
			AND Attendence_time is not null
			AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)>@IN_TIME  AND Isonleave='FALSE'
		END


	END
	ELSE IF(@ACTION='GETABSENTTODAY')
	BEGIN

	SET @IN_TIME  =(
	SELECT CONVERT(TIME,[VALUE]) FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='Intime'
	)

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SELECT 
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			FROM tbl_master_employee 
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			INNER JOIN tbl_master_user usr on emp_contactId=user_contactId and user_inactive='N'
			INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
			LEFT JOIN (
			SELECT emp_cntId,cost_description,deg_designation,
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
			 FROM tbl_trans_employeeCTC
			LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
			left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
			 where emp_effectiveuntil IS NULL
 
			 ) TBL
			ON TBL.emp_cntId=emp_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
			AND NOT EXISTS(SELECT 1 FROM tbl_fts_UserAttendanceLoginlogout  LOGOUT WHERE LOGOUT.User_Id=usr.user_id and CAST(Work_datetime as time) IS NOT NULL AND Isonleave='FALSE' AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) AND Attendence_time is not null
			AND CAST(Work_datetime as time) IS NOT NULL)
		END
		ELSE
		BEGIN
			SELECT 
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			FROM tbl_master_employee 
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			INNER JOIN tbl_master_user usr on emp_contactId=user_contactId and user_inactive='N'
			--Rev 1.0
			--INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE
			--End of Rev 1.0
			LEFT JOIN (
			SELECT emp_cntId,cost_description,deg_designation,
			cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
			 FROM tbl_trans_employeeCTC
			LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
			INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
			LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
			left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
			 where emp_effectiveuntil IS NULL
 
			 ) TBL
			ON TBL.emp_cntId=emp_contactId
			WHERE EXISTS(
			SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=emp_contactId)
			AND NOT EXISTS(SELECT 1 FROM tbl_fts_UserAttendanceLoginlogout  LOGOUT WHERE LOGOUT.User_Id=usr.user_id and CAST(Work_datetime as time) IS NOT NULL AND Isonleave='FALSE' AND CAST(Work_datetime AS DATE)=CAST(GETDATE() AS DATE) AND Attendence_time is not null
			AND CAST(Work_datetime as time) IS NOT NULL)
		END
	END
	ELSE IF(@ACTION='GETATTNZOOMING')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SELECT * FROM (
			   SELECT convert(varchar(10),Work_datetime,105) Att_Date ,  LEFT(DATENAME(MONTH,CAST(Work_datetime AS date)),3)+','+CAST(YEAR(Work_datetime) 
			   AS VARCHAR(10)) month_name,( cast(YEAR(Work_datetime) as varchar(10))+caSE WHEN MONTH(CAST(Work_datetime AS date))<10 THEN '0'+CAST(MONTH(CAST(Work_datetime AS date)) AS VARCHAR(10)) ELSE cast(MONTH(CAST(Work_datetime AS date))  as varchar(10)) END) ord 
			   ,cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			, CONVERT(varchar(15),CONVERT(TIME,Work_datetime),100) att_Given,Work_datetime
			   FROM tbl_fts_UserAttendanceLoginlogout  LOGOUT
			   INNER JOIN tbl_master_user usr on LOGOUT.User_Id=usr.user_id and user_inactive='N'
				INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=usr.user_contactId
				INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
	
				LEFT JOIN (
				SELECT emp_cntId,cost_description,deg_designation,
				cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
				 FROM tbl_trans_employeeCTC
				LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
				INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
				LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
				left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
				 where emp_effectiveuntil IS NULL 
				 ) TBL
				ON TBL.emp_cntId=emp_contactId
			   WHERE CAST(Work_datetime AS date)
			   >= CAST(CAST(YEAR(DATEADD(MONTH,-5,GETDATE())) AS VARCHAR(10)) +'-'+ CAST(MONTH(DATEADD(MONTH,-5,GETDATE())) AS VARCHAR(10))+'-'+'01' AS DATE) AND Isonleave='FALSE' 
			   AND Attendence_time IS NOT NULL
			   ) TBL WHERE ord=@YYYYMM order by Work_datetime 
		END
		ELSE
		BEGIN
			SELECT * FROM (
			   SELECT convert(varchar(10),Work_datetime,105) Att_Date ,  LEFT(DATENAME(MONTH,CAST(Work_datetime AS date)),3)+','+CAST(YEAR(Work_datetime) 
			   AS VARCHAR(10)) month_name,( cast(YEAR(Work_datetime) as varchar(10))+caSE WHEN MONTH(CAST(Work_datetime AS date))<10 THEN '0'+CAST(MONTH(CAST(Work_datetime AS date)) AS VARCHAR(10)) ELSE cast(MONTH(CAST(Work_datetime AS date))  as varchar(10)) END) ord 
			   ,cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Employee,
			deg_designation Desg,cost_description Dept,Supervisor ,CASE WHEN ISNUMERIC(user_loginId)=1 THEN user_loginId ELSE '' END Contact
			, CONVERT(varchar(15),CONVERT(TIME,Work_datetime),100) att_Given,Work_datetime
			   FROM tbl_fts_UserAttendanceLoginlogout  LOGOUT
			   INNER JOIN tbl_master_user usr on LOGOUT.User_Id=usr.user_id and user_inactive='N'
				INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=usr.user_contactId
				INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
	
				LEFT JOIN (
				SELECT emp_cntId,cost_description,deg_designation,
				cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
				 FROM tbl_trans_employeeCTC
				LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
				INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
				LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
				left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
				 where emp_effectiveuntil IS NULL 
				 ) TBL
				ON TBL.emp_cntId=emp_contactId
			   WHERE CAST(Work_datetime AS date)
			   >= CAST(CAST(YEAR(DATEADD(MONTH,-5,GETDATE())) AS VARCHAR(10)) +'-'+ CAST(MONTH(DATEADD(MONTH,-5,GETDATE())) AS VARCHAR(10))+'-'+'01' AS DATE) AND Isonleave='FALSE' 
			   AND Attendence_time IS NOT NULL
			   ) TBL WHERE ord=@YYYYMM order by Work_datetime 
		END
	END

	ELSE IF(@ACTION='GETEMPDATEACTIVITY')
	BEGIN
	DECLARE @OUTPUT_TEXT VARCHAR(500)
	DECLARE @LOGIN_TEXT VARCHAR(500)
	DECLARE @LOGOUT_TEXT VARCHAR(500)

	DECLARE @SUPERVISOR VARCHAR(200)=
	(SELECT Supervisor FROM TBL_MASTER_USER usr   
		INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=usr.user_contactId
		INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
	
		LEFT JOIN (
		SELECT emp_cntId,cost_description,deg_designation,
		cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Supervisor
		 FROM tbl_trans_employeeCTC
		LEFT JOIN tbl_master_employee EM1 ON EM1.emp_id=emp_reportTo
		INNER JOIN tbl_master_contact ON cnt_internalId=emp_contactId
		LEFT JOIN tbl_master_designation ON deg_id=emp_Designation
		left join tbl_master_costCenter on cost_id=emp_Department and cost_costCenterType = 'department'
		 where emp_effectiveuntil IS NULL 
		 ) TBL ON TBL.emp_cntId=usr.user_contactId
		 WHERE USER_ID=@USER_ID
		 )

	DECLARE @STATE VARCHAR(200)=
	(SELECT state FROM TBL_MASTER_USER usr   	
		INNER JOIN  tbl_master_address ON add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId
		 INNER JOIN tbl_master_state on id=add_state
		 WHERE USER_ID=@USER_ID
		 )
	DECLARE @LOGIN_ID VARCHAR(200)=
	(SELECT user_loginId FROM TBL_MASTER_USER usr   	
		 WHERE USER_ID=@USER_ID
		 )
	DECLARE @EMP_NAME VARCHAR(200)=
	(SELECT cnt_firstName +' '+ ISNULL(cnt_middleName,'')+' '+ ISNULL(cnt_lastName,'') Name FROM TBL_MASTER_USER usr
	INNER JOIN tbl_master_contact on cnt_internalId=usr.user_contactId   	
		 WHERE USER_ID=@USER_ID
		 )

	DECLARE @IN_TIME_CALC  TIME=(
	SELECT CONVERT(TIME,[VALUE]) FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='Intime'
	)
	IF(
	SELECT COUNT(0) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
		INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								WHERE EXISTS(
								SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
		  AND Attendence_time IS NOT NULL 
														  AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)<=@IN_TIME_CALC  AND Isonleave='FALSE'
	and LOGOUT.User_Id=@USER_ID
	and cast (Work_datetime as date)=CAST(@DATE AS DATE))>0
	BEGIN

		SET @LOGIN_TEXT = (SELECT CONVERT(varchar(15),CONVERT(TIME,MIN(Work_datetime)),100) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
		INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								WHERE EXISTS(
								SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
		  AND Attendence_time IS NOT NULL 
														  AND CAST(Work_datetime as time) IS NOT NULL  AND Isonleave='FALSE'
														  and LOGOUT.User_Id=@USER_ID
	and cast (Work_datetime as date)=CAST(@DATE AS DATE))
	
	
		SET @LOGOUT_TEXT = (SELECT CONVERT(varchar(15),CONVERT(TIME,MAX(Work_datetime)),100) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
		INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								WHERE EXISTS(
								SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
		  AND Attendence_time IS  NULL 
														  AND CAST(Work_datetime as time) IS NOT NULL  AND Isonleave='FALSE'
														  and LOGOUT.User_Id=@USER_ID
	and cast (Work_datetime as date)=CAST(@DATE AS DATE))
	
		SELECT @EMP_NAME NAME,@LOGIN_ID LOGIN_ID,@STATE STATE,@SUPERVISOR SUPERVISOR,
		'In Time' STATUS,@LOGIN_TEXT LOGIN_TIME,@LOGOUT_TEXT LOGOUT_TIME
		--SET @OUTPUT_TEXT ='In Time Login: '+@LOGIN_TEXT +' Logout: '+ @LOGOUT_TEXT

	END
	ELSE IF(
	SELECT COUNT(0) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
		INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								WHERE EXISTS(
								SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
		  AND Attendence_time IS NOT NULL 
														  AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)>@IN_TIME_CALC  AND Isonleave='FALSE'
	and LOGOUT.User_Id=@USER_ID
	and cast (Work_datetime as date)=CAST(@DATE AS DATE))>0
	BEGIN

		SET @LOGIN_TEXT = (SELECT CONVERT(varchar(15),CONVERT(TIME,MIN(Work_datetime)),100) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
		INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								WHERE EXISTS(
								SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
		  AND Attendence_time IS NOT NULL 
														  AND CAST(Work_datetime as time) IS NOT NULL  AND Isonleave='FALSE'
														  and LOGOUT.User_Id=@USER_ID
	and cast (Work_datetime as date)=CAST(@DATE AS DATE))
	
	
		SET @LOGOUT_TEXT = (SELECT CONVERT(varchar(15),CONVERT(TIME,MAX(Work_datetime)),100) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
		INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								WHERE EXISTS(
								SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
		  AND Attendence_time IS NULL 
														  AND CAST(Work_datetime as time) IS NOT NULL  AND Isonleave='FALSE'
														  and LOGOUT.User_Id=@USER_ID
	and cast (Work_datetime as date)=CAST(@DATE AS DATE))
	
	

		--SET @OUTPUT_TEXT ='late Login: '+@LOGIN_TEXT +' Logout: '+ @LOGOUT_TEXT
			SELECT @EMP_NAME NAME,@LOGIN_ID LOGIN_ID,@STATE STATE,@SUPERVISOR SUPERVISOR,
		'Late' STATUS,@LOGIN_TEXT LOGIN_TIME,@LOGOUT_TEXT LOGOUT_TIME
	END
	ELSE IF(
	SELECT COUNT(0) FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
		INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								WHERE EXISTS(
								SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
		  AND Attendence_time IS NOT NULL 
														  AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)>=@IN_TIME_CALC  AND Isonleave='true'
	and LOGOUT.User_Id=@USER_ID
	and cast (Work_datetime as date)=CAST(@DATE AS DATE))>0
	BEGIN

	DECLARE @REASON VARCHAR(100)=( SELECT LeaveReason FROM tbl_fts_UserAttendanceLoginlogout LOGOUT
		INNER JOIN TBL_MASTER_USER USR ON LOGOUT.USER_ID=USR.USER_ID and user_inactive='N'
								WHERE EXISTS(
								SELECT 1  FROM tbl_master_address WHERE add_entity='employee' AND	add_addressType='Office' AND ADD_CNTID=user_contactId)
		  AND Attendence_time IS NOT NULL 
														  AND CAST(Work_datetime as time) IS NOT NULL AND CONVERT(TIME,Work_datetime)>=@IN_TIME_CALC  AND Isonleave='true'
	and LOGOUT.User_Id=@USER_ID
	and cast (Work_datetime as date)=CAST(@DATE AS DATE) AND ISNULL(LeaveReason,'')<>'')

		--SET @OUTPUT_TEXT ='On Leave Reason: '+@REASON

		SELECT @EMP_NAME NAME,@LOGIN_ID LOGIN_ID,@STATE STATE,@SUPERVISOR SUPERVISOR,
		'On Leave' STATUS,'' LOGIN_TIME,'' LOGOUT_TIME

	END
	ELSE 
	BEGIN

		SELECT @EMP_NAME NAME,@LOGIN_ID LOGIN_ID,@STATE STATE,@SUPERVISOR SUPERVISOR,
		'Absent' STATUS,'' LOGIN_TIME,'' LOGOUT_TIME


	END

	--select @OUTPUT_TEXT

	END

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
		END
END