--EXEC PRC_FTSEMPLOYEEPERFORMANCEDETAILS_REPORT '2020-06-19','2020-06-19','','','EMB0000002',378
--EXEC PRC_FTSEMPLOYEEPERFORMANCEDETAILS_REPORT '2021-02-01','2021-03-31','','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSEMPLOYEEPERFORMANCEDETAILS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSEMPLOYEEPERFORMANCEDETAILS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSEMPLOYEEPERFORMANCEDETAILS_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 06/03/2021
Module	   : Employee Performance Details.Refer: 0023845
1.0		v2.0.15		Debashis	18/03/2020		"Visit Time" - required in Employee Performance report.Refer: 0023876
2.0					TANMOY		22-04-2021		Electrician type and Electrician name  correction Ref:0023987
3.0		v2.0.24		Tanmoy		30/07/2021		Employee hierarchy wise filter
4.0		v2.0.25		Sancita		20/09/2021		Hierarchy not working when Select All taken
5.0		v2.0.31		Debashis	23/06/2022		FSM : Report : MIS : EMPLOYEE PERFORMANCE
												Required to connect from Archive table.
												Because 3 months previous data are not showing in this report.Refer: 0024984
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX),@isRevisitTeamDetail NVARCHAR(100)
	DECLARE @CURSOR_LOCATION CURSOR,@LOCUSERID BIGINT,@LOCATION_NAME NVARCHAR(1000),@SDATE NVARCHAR(10),@SDATEORDBY NVARCHAR(10),@M_LOCUSERID BIGINT,@M_SDATE NVARCHAR(10),@M_SDATEORDBY NVARCHAR(10),
	@CONCATELOCATION NVARCHAR(1000)

	SELECT @isRevisitTeamDetail=[Value] FROM fts_app_config_settings WHERE [Key]='isRevisitTeamDetail' AND [Description]='Revisit from Team Details in Portal'

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
	
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DESIGNID <> ''
		BEGIN
			SET @DESIGNID=REPLACE(@DESIGNID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation where deg_id in('+@DESIGNID+')'
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

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	--Rev 5.0
	IF OBJECT_ID('tempdb..#tbl_trans_shopActivitysubmit') IS NOT NULL
		DROP TABLE #tbl_trans_shopActivitysubmit
	CREATE TABLE #tbl_trans_shopActivitysubmit(
	[ActivityId] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
	[User_Id] [bigint] NULL,
	[Shop_Id] [varchar](100) NULL,
	[visited_date] [date] NULL,
	[visited_time] [datetime] NULL,
	[spent_duration] [varchar](100) NULL,
	[Createddate] [datetime] NULL,
	[total_visit_count] [int] NULL,
	[shopvisit_image] [nvarchar](max) NULL,
	[Is_Newshopadd] [bit] NULL,
	[distance_travelled] [decimal](18, 2) NULL,
	[ISUSED] [int] NULL,
	[LATITUDE] [nvarchar](100) NULL,
	[LONGITUDE] [nvarchar](100) NULL,
	[REMARKS] [nvarchar](500) NULL,
	[MEETING_ADDRESS] [nvarchar](500) NULL,
	[MEETING_PINCODE] [nvarchar](10) NULL,
	[MEETING_TYPEID] [int] NULL,
	[ISMEETING] [bit] NULL,
	[IsOutStation] [bit] NULL,
	[IsFirstVisit] [bit] NULL,
	[Outstation_Distance] [numeric](18, 2) NULL,
	[early_revisit_reason] [varchar](max) NULL,
	[device_model] [varchar](200) NULL,
	[android_version] [varchar](200) NULL,
	[battery] [varchar](200) NULL,
	[net_status] [varchar](200) NULL,
	[net_type] [varchar](200) NULL,
	[CheckIn_Time] [varchar](50) NULL,
	[CheckIn_Address] [varchar](500) NULL,
	[CheckOut_Time] [varchar](50) NULL,
	[CheckOut_Address] [varchar](500) NULL,
	[start_timestamp] [varchar](200) NULL,
	[competitor_img] [nvarchar](500) NULL,
	[Revisit_Code] [nvarchar](100) NULL,
	[Ordernottaken_Status] [nvarchar](100) NULL,
	[Ordernottaken_Remarks] [nvarchar](500) NULL
	)
	CREATE NONCLUSTERED INDEX IX_Code_userID ON #tbl_trans_shopActivitysubmit(Shop_Id ASC,User_Id ASC) INCLUDE (visited_time)
	CREATE NONCLUSTERED INDEX IXSHIDSPNTVD ON #tbl_trans_shopActivitysubmit(Shop_Id ASC,visited_date ASC,spent_duration ASC) INCLUDE (distance_travelled,REMARKS)
	CREATE NONCLUSTERED INDEX IXSPNTREM ON #tbl_trans_shopActivitysubmit(spent_duration ASC,distance_travelled ASC,REMARKS ASC)
	CREATE NONCLUSTERED INDEX NCLIDX_20210218_182341 ON #tbl_trans_shopActivitysubmit(User_Id ASC,visited_date ASC)
	CREATE NONCLUSTERED INDEX NCLIDX_20210218_234437 ON #tbl_trans_shopActivitysubmit(User_Id ASC,Createddate ASC,ISMEETING ASC)
	CREATE NONCLUSTERED INDEX NCLIDX_tbl_trans_shopActivitysubmit_Is_Newshopadd ON #tbl_trans_shopActivitysubmit(Is_Newshopadd ASC) INCLUDE (User_Id,Shop_Id,visited_time,spent_duration,distance_travelled)
	CREATE NONCLUSTERED INDEX NCLIDX_tbl_trans_shopActivitysubmit_User_Id_ISMEETING_Createddate ON #tbl_trans_shopActivitysubmit(User_Id ASC,ISMEETING ASC,Createddate ASC)
	INCLUDE (visited_date,visited_time,spent_duration,distance_travelled,LATITUDE,LONGITUDE,REMARKS,MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID)
	CREATE NONCLUSTERED INDEX NCLIDX_tbl_trans_shopActivitysubmit_User_Id_visited_date ON #tbl_trans_shopActivitysubmit(User_Id ASC,visited_date ASC)
	INCLUDE (Shop_Id,spent_duration,total_visit_count,ISMEETING)
	CREATE NONCLUSTERED INDEX Shop_ID_VISIT ON #tbl_trans_shopActivitysubmit(Shop_Id ASC,visited_date ASC)
	CREATE NONCLUSTERED INDEX SHOPCREATE ON #tbl_trans_shopActivitysubmit(Is_Newshopadd ASC) INCLUDE (User_Id,Shop_Id,visited_time)
	CREATE NONCLUSTERED INDEX USERIDSHOPCREATE ON #tbl_trans_shopActivitysubmit(User_Id ASC,Is_Newshopadd ASC) INCLUDE (Shop_Id,visited_time)

	SET IDENTITY_INSERT #tbl_trans_shopActivitysubmit ON
	INSERT INTO #tbl_trans_shopActivitysubmit(ActivityId,User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,LATITUDE,
	LONGITUDE,REMARKS,MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,device_model,android_version,battery,net_status,net_type,
	CheckIn_Time,CheckIn_Address,CheckOut_Time,CheckOut_Address,start_timestamp,competitor_img,Revisit_Code,Ordernottaken_Status,Ordernottaken_Remarks)

	SELECT ActivityId,User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,LATITUDE,LONGITUDE,REMARKS,
	MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,device_model,android_version,battery,net_status,net_type,
	CheckIn_Time,CheckIn_Address,CheckOut_Time,CheckOut_Address,start_timestamp,competitor_img,Revisit_Code,Ordernottaken_Status,Ordernottaken_Remarks FROM(
	SELECT ActivityId,User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,LATITUDE,LONGITUDE,REMARKS,
	MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,device_model,android_version,battery,net_status,net_type,
	CheckIn_Time,CheckIn_Address,CheckOut_Time,CheckOut_Address,start_timestamp,competitor_img,Revisit_Code,Ordernottaken_Status,Ordernottaken_Remarks
	FROM tbl_trans_shopActivitysubmit
	UNION ALL
	SELECT ActivityId,User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,LATITUDE,LONGITUDE,REMARKS,
	MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,device_model,android_version,battery,net_status,net_type,
	CheckIn_Time,CheckIn_Address,CheckOut_Time,CheckOut_Address,start_timestamp,competitor_img,Revisit_Code,Ordernottaken_Status,Ordernottaken_Remarks
	FROM tbl_trans_shopActivitysubmit_Archive
	) SHOPACTIVITYSUBMIT ORDER BY ActivityId
	SET IDENTITY_INSERT #tbl_trans_shopActivitysubmit OFF
	--End of Rev 5.0

	IF OBJECT_ID('tempdb..#TMPLOCATIONNAME') IS NOT NULL
		DROP TABLE #TMPLOCATIONNAME
	CREATE TABLE #TMPLOCATIONNAME(USER_ID BIGINT,LOCATION_NAME NVARCHAR(2000),SDATE NVARCHAR(10),SDATEORDBY NVARCHAR(10))

	SET @CURSOR_LOCATION=CURSOR FAST_FORWARD FOR 
	SELECT DISTINCT User_Id,LOCATION_NAME,CONVERT(NVARCHAR(10),SDATE,105) AS SDATE,CONVERT(NVARCHAR(10),SDATE,120) SDATEORDBY FROM TBL_TRANS_SHOPUSER_ARCH 
	WHERE (LOCATION_NAME LIKE '%Login from%' OR LOCATION_NAME LIKE '%Logout at%')
	AND CONVERT(NVARCHAR(10),SDATE,120) BETWEEN CONVERT(NVARCHAR(10),@FROMDATE,120) AND CONVERT(NVARCHAR(10),@TODATE,120)
	ORDER BY User_Id,CONVERT(NVARCHAR(10),SDATE,120)

	OPEN @CURSOR_LOCATION

	FETCH NEXT FROM @CURSOR_LOCATION INTO @LOCUSERID,@LOCATION_NAME,@SDATE,@SDATEORDBY

	WHILE @@FETCH_STATUS=0
		BEGIN
			SET @M_LOCUSERID=@LOCUSERID
			SET @M_SDATEORDBY=@SDATEORDBY
			SET @M_SDATE=@SDATE
			SET @CONCATELOCATION=''
			WHILE @M_LOCUSERID=@LOCUSERID AND @M_SDATEORDBY=@SDATEORDBY AND @@FETCH_STATUS=0
				BEGIN
					IF @CONCATELOCATION=''
						SET @CONCATELOCATION=@location_name
					ELSE IF @CONCATELOCATION<>''
						SET @CONCATELOCATION=@CONCATELOCATION+' || '+@LOCATION_NAME
					FETCH NEXT FROM @CURSOR_LOCATION INTO @LOCUSERID,@LOCATION_NAME,@SDATE,@SDATEORDBY
					IF (@M_LOCUSERID=@LOCUSERID AND @M_SDATEORDBY<>@SDATEORDBY) OR (@M_LOCUSERID<>@LOCUSERID AND @M_SDATEORDBY=@SDATEORDBY) OR @@FETCH_STATUS=-1
						BEGIN
							INSERT INTO #TMPLOCATIONNAME(USER_ID,LOCATION_NAME,SDATE,SDATEORDBY)
							SELECT @M_LOCUSERID,@CONCATELOCATION,@M_SDATE,@M_SDATEORDBY
						END

				END		
		END
	CLOSE @CURSOR_LOCATION
	DEALLOCATE @CURSOR_LOCATION

	--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
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
	--End of Rev 3.0

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSEMPLOYEEPERFORMANCEDETAILS_REPORT') AND TYPE IN (N'U'))
		BEGIN
			--Rev 1.0 && A new column added as SHPVISITTIME NVARCHAR(10)
			CREATE TABLE FTSEMPLOYEEPERFORMANCEDETAILS_REPORT
			(
			  USERID INT,
			  SEQ INT,
			  LOGIN_DATETIMEORDBY NVARCHAR(10),
			  WORK_DATE NVARCHAR(10),
			  LOGGEDIN NVARCHAR(100) NULL,
			  LOGEDOUT NVARCHAR(100) NULL,
			  LOGINOUTLOCATION NVARCHAR(2000) NULL,
			  CONTACTNO NVARCHAR(50) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  BRANCHDESC NVARCHAR(300),
			  OFFICE_ADDRESS NVARCHAR(300),
			  ATTEN_STATUS NVARCHAR(20),
			  WORK_LEAVE_TYPE NVARCHAR(2000) NULL,
			  REMARKS NVARCHAR(2000) NULL,
			  EMPCODE NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  EMPID NVARCHAR(100) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  DATEOFJOINING NVARCHAR(10),
			  REPORTTO NVARCHAR(300) NULL,
			  RPTTODESG NVARCHAR(50) NULL,
			  CUSTTYPE NVARCHAR(100),
			  CUSTCODE NVARCHAR(100),
			  CUSTNAME NVARCHAR(300) NULL,
			  ENTITYCODE NVARCHAR(600) NULL,
			  CUSTADD NVARCHAR(300) NULL,
			  CUSTMOB NVARCHAR(100) NULL,
			  COMPNAME NVARCHAR(300) NULL,
			  ELECTRICIANADD NVARCHAR(300) NULL,
			  ELECTRICIANMOB NVARCHAR(100) NULL,
			  GPTPLNAME NVARCHAR(300) NULL,
			  GPTPLADD NVARCHAR(300) NULL,
			  GPTPLMOB NVARCHAR(100) NULL,
			  ELECTRICIAN NVARCHAR(300) NULL,
			  ENTITYTYPE NVARCHAR(300) NULL,
			  VISITTYPE NVARCHAR(100) NULL,
			  VISITREMARKS NVARCHAR(1000),
			  MEETINGREMARKS NVARCHAR(1000),
			  MEETING_ADDRESS NVARCHAR(1000),
			  TOTAL_VISIT INT,
			  NEWSHOP_VISITED INT,
			  RE_VISITED INT,
			  TOTMETTING INT,
			  SHPVISITTIME NVARCHAR(10) NULL,
			  SPENT_DURATION NVARCHAR(50),
			  DISTANCE_TRAVELLED DECIMAL(38,2),
			  TOTAL_ORDER_BOOKED_VALUE DECIMAL(38,2),
			  TOTAL_COLLECTION DECIMAL(38,2)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSEMPLOYEEPERFORMANCEDETAILS_REPORT (SEQ)
		END
	DELETE FROM FTSEMPLOYEEPERFORMANCEDETAILS_REPORT WHERE USERID=@USERID

	SET @Strsql=''
	--Rev 1.0 && A new column added as SHPVISITTIME
	SET @Strsql='INSERT INTO FTSEMPLOYEEPERFORMANCEDETAILS_REPORT(USERID,SEQ,LOGIN_DATETIMEORDBY,WORK_DATE,LOGGEDIN,LOGEDOUT,LOGINOUTLOCATION,CONTACTNO,STATEID,STATE,BRANCHDESC,OFFICE_ADDRESS,ATTEN_STATUS,'
	SET @Strsql+='WORK_LEAVE_TYPE,REMARKS,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,DATEOFJOINING,REPORTTO,RPTTODESG,CUSTTYPE,CUSTCODE,CUSTNAME,ENTITYCODE,CUSTADD,CUSTMOB,COMPNAME,ELECTRICIANADD,ELECTRICIANMOB,'
	SET @Strsql+='GPTPLNAME,GPTPLADD,GPTPLMOB,ELECTRICIAN,ENTITYTYPE,VISITTYPE,VISITREMARKS,MEETINGREMARKS,MEETING_ADDRESS,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,TOTMETTING,SPENT_DURATION,SHPVISITTIME,'
	SET @Strsql+='DISTANCE_TRAVELLED,TOTAL_ORDER_BOOKED_VALUE,TOTAL_COLLECTION) '
	SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY LOGIN_DATETIMEORDBY) AS SEQ,LOGIN_DATETIMEORDBY,LOGIN_DATETIME,LOGGEDIN,LOGEDOUT,LOGINOUTLOCATION,CONTACTNO,STATEID,STATE,'
	SET @Strsql+='BRANCHDESC,OFFICE_ADDRESS,ATTEN_STATUS,WORK_LEAVE_TYPE,REMARKS,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,DATEOFJOINING,REPORTTO,RPTTODESG,CUSTTYPE,CUSTCODE,CUSTNAME,ENTITYCODE,CUSTADD,CUSTMOB,'
	SET @Strsql+='COMPNAME,ELECTRICIANADD,ELECTRICIANMOB,GPTPLNAME,GPTPLADD,GPTPLMOB,ELECTRICIAN,ENTITYTYPE,VISITTYPE,VISITREMARKS,MEETINGREMARKS,MEETING_ADDRESS,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,TOTMETTING,'
	SET @Strsql+='SPENT_DURATION,SHPVISITTIME,DISTANCE_TRAVELLED,Total_Order_Booked_Value,Total_Collection FROM('
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ST.ID AS STATEID,ST.state AS STATE,BR.branch_description AS BRANCHDESC,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	SET @Strsql+='USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,RPTTO.RPTTODESG,Login_datetimeORDBY,LOGIN_DATETIME,ATTEN.LOGGEDIN AS LOGGEDIN,ATTEN.LOGEDOUT AS LOGEDOUT,SU.LOCATION_NAME AS LOGINOUTLOCATION,'
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,ATTEN_STATUS,'
	SET @Strsql+='(SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(WRKACT.WrkActvtyDescription)) From tbl_fts_UserAttendanceLoginlogout AS UATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=UATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=MUSR.user_contactId '
		END
	--End of Rev 3.0
	SET @Strsql+='INNER JOIN tbl_attendance_worktype ATTENWRKTYP ON ATTENWRKTYP.UserID=UATTEN.User_Id AND UATTEN.Id=ATTENWRKTYP.attendanceid '
	SET @Strsql+='INNER JOIN tbl_FTS_WorkActivityList WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),UATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL '
	SET @Strsql+='AND Isonleave=''false'' AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),UATTEN.Work_datetime,105) GROUP BY WRKACT.WrkActvtyDescription FOR XML PATH('''')), 1, 1, ''''),'''')) AS WORK_LEAVE_TYPE,'
	SET @Strsql+='REPLACE((SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(ISNULL(A.Work_Desc,''''))) From tbl_fts_UserAttendanceLoginlogout AS A '
	SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=A.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=MUSR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),A.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND A.Login_datetime IS NOT NULL AND A.Logout_datetime IS NULL '
	SET @Strsql+='AND A.Isonleave=''false'' AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),A.Work_datetime,105) FOR XML PATH('''')),1,1,''''),'''')),'','','''') AS REMARKS,'
	SET @Strsql+='SHOP.CUSTTYPE,SHOP.Shop_Code AS CUSTCODE,SHOP.Shop_Name AS CUSTNAME,SHOP.ENTITYCODE,SHOP.Address AS CUSTADD,SHOP.Shop_Owner_Contact AS CUSTMOB,SHOPPP.Shop_Name AS COMPNAME,'
	--Rev 2.0 Star
	--SET @Strsql+='SHOP.ELECTRICIANADD,SHOP.ELECTRICIANMOB,SHOPDD.Shop_Name AS GPTPLNAME,SHOPDD.Address AS GPTPLADD,SHOPDD.Shop_Owner_Contact AS GPTPLMOB,SHOP.ELECTRICIAN,'
	SET @Strsql+='SHOP.ELECTRICIANADD,SHOP.ELECTRICIANMOB,SHOPDD.Shop_Name AS GPTPLNAME,SHOPDD.Address AS GPTPLADD,SHOPDD.Shop_Owner_Contact AS GPTPLMOB,SHOPCUS.Shop_Name AS ELECTRICIAN,'
	--Rev 2.0 eND
	SET @Strsql+='CASE WHEN SHOP.CUSTTYPE=''Entity'' THEN SHOP.ENTITY ELSE '''' END AS ENTITYTYPE,SHOPACT.VISITTYPE,SHOPACT.SHPVISITTIME,SHOPACT.VISITREMARKS,SHOPACT.MEETINGREMARKS,SHOPACT.MEETING_ADDRESS,'
	SET @Strsql+='ISNULL(SHOPACT.NEWSHOP_VISITED,0)+ISNULL(SHOPACT.RE_VISITED,0)+ISNULL(SHOPACT.TOTMETTING,0) AS TOTAL_VISIT,ISNULL(SHOPACT.NEWSHOP_VISITED,0) AS NEWSHOP_VISITED,'
	SET @Strsql+='ISNULL(SHOPACT.RE_VISITED,0) AS RE_VISITED,ISNULL(SHOPACT.TOTMETTING,0) AS TOTMETTING,SPENT_DURATION,DISTANCE_TRAVELLED,ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,'
	SET @Strsql+='ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,Login_datetimeORDBY,ATTEN_STATUS FROM('
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetimeORDBY,CASE WHEN Isonleave=''false'' THEN ''At Work'' ELSE ''On Leave'' END AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL '
	SET @Strsql+='AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120),ATTEN.Work_Address,ATTEN.Isonleave '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetimeORDBY,CASE WHEN Isonleave=''false'' THEN ''At Work'' ELSE ''On Leave'' END AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL '
	SET @Strsql+='AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120),ATTEN.Work_Address,ATTEN.Isonleave '
	SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,Login_datetimeORDBY,ATTEN_STATUS '
	SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	SET @Strsql+='LEFT OUTER JOIN #TMPLOCATIONNAME SU ON USR.USER_ID=SU.User_Id AND ATTEN.Login_datetime=SU.SDATE '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,SUM(NEWSHOP_VISITED) AS NEWSHOP_VISITED,SUM(RE_VISITED) AS RE_VISITED,SUM(TOTMETTING) AS TOTMETTING,SPENT_DURATION,SUM(DISTANCE_TRAVELLED) AS DISTANCE_TRAVELLED,'
	SET @Strsql+='VISITED_TIME,SHPVISITTIME,VISITTYPE,VISITREMARKS,MEETINGREMARKS,MEETING_ADDRESS FROM('
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,COUNT(SHOPACT.Shop_Id) AS NEWSHOP_VISITED,0 AS RE_VISITED,0 AS TOTMETTING,SPENT_DURATION,'
	SET @Strsql+='SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITED_TIME,CONVERT(VARCHAR(8),CAST(SHOPACT.visited_time AS TIME),108) AS SHPVISITTIME,'
	SET @Strsql+='''New Visit'' AS VISITTYPE,SHOPACT.REMARKS AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS MEETING_ADDRESS '
	--Rev 5.0
	--SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='FROM #tbl_trans_shopActivitysubmit SHOPACT '
	--End of Rev 5.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.Is_Newshopadd=1 '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.VISITED_TIME,SPENT_DURATION,SHOPACT.REMARKS '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.Shop_Id) AS RE_VISITED,0 AS TOTMETTING,SPENT_DURATION,'
	SET @Strsql+='SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITED_TIME,CONVERT(VARCHAR(8),CAST(SHOPACT.visited_time AS TIME),108) AS SHPVISITTIME,'
	SET @Strsql+='''ReVisit'' AS VISITTYPE,SHOPACT.REMARKS AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS MEETING_ADDRESS '
	--Rev 5.0
	--SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='FROM #tbl_trans_shopActivitysubmit SHOPACT '
	--End of Rev 5.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.Is_Newshopadd=0 AND SHOPACT.ISMEETING=0 '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.VISITED_TIME,SPENT_DURATION,SHOPACT.REMARKS '
	--MEETING
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,0 AS RE_VISITED,COUNT(SHOPACT.Shop_Id) AS TOTMETTING,SPENT_DURATION,0 AS DISTANCE_TRAVELLED,'
	SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITED_TIME,CONVERT(VARCHAR(8),CAST(SHOPACT.visited_time AS TIME),108) AS SHPVISITTIME,''Meeting'' AS VISITTYPE,'''' AS VISITREMARKS,'
	SET @Strsql+='SHOPACT.REMARKS AS MEETINGREMARKS,SHOPACT.MEETING_ADDRESS '
	--Rev 5.0
	--SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='FROM #tbl_trans_shopActivitysubmit SHOPACT '
	--End of Rev 5.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND SHOPACT.ISMEETING=1 AND SHOPACT.MEETING_TYPEID IS NOT NULL '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,SHOPACT.VISITED_TIME,SPENT_DURATION,SHOPACT.REMARKS,SHOPACT.MEETING_ADDRESS '
	SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId,Shop_Id,VISITED_TIME,SHPVISITTIME,VISITTYPE,VISITREMARKS,SPENT_DURATION,MEETINGREMARKS,MEETING_ADDRESS '
	SET @Strsql+=') SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=SHOPACT.VISITED_TIME '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT DISTINCT MS.Shop_Code,MS.Shop_CreateUser,MS.Shop_Name,MS.Address,MS.Shop_Owner_Contact,MS.assigned_to_pp_id,MS.assigned_to_dd_id,MS.assigned_to_shop_id,MS.type,MS.EntityCode,'
	SET @Strsql+='CASE WHEN TYPE=1 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.retailer_id) '
	SET @Strsql+='WHEN TYPE=2 THEN ''Company Name'' '
	--Rev 2.0 Star
	--SET @Strsql+='WHEN TYPE=4 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.dealer_id) END AS CUSTTYPE,'
	SET @Strsql+='WHEN TYPE=4 THEN (SELECT STYPD.NAME FROM TBL_SHOPTYPEDETAILS STYPD WHERE STYPD.ID=MS.dealer_id) ELSE (SELECT STYPD.Name FROM TBL_SHOPTYPE STYPD WHERE STYPD.TypeId=MS.TYPE) END AS CUSTTYPE,'
	--Rev 2.0 End
	SET @Strsql+='ENT.ENTITY,CASE WHEN MS.type=11 THEN MS.Shop_Name ELSE '''' END AS ELECTRICIAN,'
	SET @Strsql+='CASE WHEN MS.type=11 THEN MS.Address ELSE '''' END AS ELECTRICIANADD,'
	SET @Strsql+='CASE WHEN MS.type=11 THEN MS.Shop_Owner_Contact ELSE '''' END AS ELECTRICIANMOB '
	SET @Strsql+='FROM tbl_Master_shop MS '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EN.ENTITY,MSTSHP.Shop_Code FROM FSM_ENTITY EN '
	SET @Strsql+='INNER JOIN tbl_Master_shop MSTSHP ON EN.ID=MSTSHP.Entity_Id '
	SET @Strsql+=') ENT ON MS.Shop_Code=ENT.Shop_Code '
	SET @Strsql+=') SHOP ON SHOP.Shop_Code=SHOPACT.Shop_Id '
	SET @Strsql+='LEFT OUTER JOIN('
	SET @Strsql+='SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_pp_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A ) SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code ' 
	SET @Strsql+='LEFT OUTER JOIN(SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_dd_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A ) SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
	--Rev 2.0 Star
	SET @Strsql+='LEFT OUTER JOIN(SELECT DISTINCT A.Shop_CreateUser,A.assigned_to_shop_id,A.Shop_Code,A.Shop_Name,A.Address,A.Shop_Owner_Contact,Type FROM tbl_Master_shop A) SHOPCUS ON SHOP.assigned_to_shop_id=SHOPCUS.Shop_Code '
	--Rev 2.0 End
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT ORDH.userID,ORDH.SHOP_CODE,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue,CONVERT(NVARCHAR(10),ORDH.Orderdate,105) AS ORDDATE FROM tbl_trans_fts_Orderupdate ORDH '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDH.userID '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY ORDH.userID,ORDH.SHOP_CODE,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ORDH.Orderdate,105) '
	SET @Strsql+=') ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=ORDHEAD.ORDDATE AND ORDHEAD.SHOP_CODE=SHOP.SHOP_CODE '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT COLLEC.user_id,COLLEC.shop_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue,CONVERT(NVARCHAR(10),COLLEC.collection_date,105) AS collection_date '
	SET @Strsql+='FROM tbl_FTS_collection COLLEC '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=COLLEC.user_id '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY COLLEC.user_id,COLLEC.shop_id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),COLLEC.collection_date,105) '
	SET @Strsql+=') COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=COLLEC.collection_date AND COLLEC.shop_id=SHOP.SHOP_CODE '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ST.ID AS STATEID,ST.state AS STATE,BR.branch_description AS BRANCHDESC,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	SET @Strsql+='USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO,RPTTO.RPTTODESG,Login_datetimeORDBY,LOGIN_DATETIME,ATTEN.LOGGEDIN AS LOGGEDIN,ATTEN.LOGEDOUT AS LOGEDOUT,SU.LOCATION_NAME AS LOGINOUTLOCATION,'
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,ATTEN_STATUS,'
	SET @Strsql+='(SELECT DISTINCT ISNULL(STUFF((SELECT '','' + LTRIM(RTRIM(LTYP.LeaveType)) From tbl_fts_UserAttendanceLoginlogout AS UATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user MUSR ON MUSR.USER_ID=UATTEN.USER_ID AND MUSR.user_inactive=''N'' AND MUSR.USER_ID=USR.USER_ID '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=MUSR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN tbl_FTS_Leavetype LTYP ON LTYP.Leave_Id=UATTEN.Leave_Type '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),UATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL '
	SET @Strsql+='AND Isonleave=''true'' AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),UATTEN.Work_datetime,105) GROUP BY LTYP.LeaveType FOR XML PATH('''')), 1, 1, ''''),'''')) AS WORK_LEAVE_TYPE,'
	SET @Strsql+=''''' AS REMARKS,'''' AS CUSTTYPE,'''' AS CUSTCODE,'''' AS CUSTNAME,'''' AS EntityCode,'''' AS CUSTADD,'''' AS CUSTMOB,'''' AS COMPNAME,'''' AS ELECTRICIANADD,'''' AS ELECTRICIANMOB,'''' AS GPTPLNAME,'
	SET @Strsql+=''''' AS GPTPLADD,'''' AS GPTPLMOB,'''' AS ELECTRICIAN,'''' AS ENTITYTYPE,'''' AS VISITTYPE,NULL AS SHPVISITTIME,'''' AS VISITREMARKS,'''' AS MEETINGREMARKS,'''' AS MEETING_ADDRESS,0 AS TOTAL_VISIT,'
	SET @Strsql+='0 AS NEWSHOP_VISITED,0 AS RE_VISITED,0 AS TOTMETTING,NULL AS SPENT_DURATION,0.00 AS DISTANCE_TRAVELLED,0.00 AS Total_Order_Booked_Value,0.00 AS Total_Collection FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=CNT.cnt_internalId '
		END
	--End of Rev 3.0
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL '
	SET @Strsql+='GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @Strsql+=') DESG ON DESG.emp_cntId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,Login_datetimeORDBY,ATTEN_STATUS FROM('
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetimeORDBY,''On Leave'' AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL '
	SET @Strsql+='AND Isonleave=''true'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS Login_datetimeORDBY,''On Leave'' AS ATTEN_STATUS '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	--Rev 4.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		SET @Strsql+='INNER JOIN #EMPHR_EDIT TMPEDT ON TMPEDT.EMPCODE=USR.user_contactId '
		END
	--End of Rev 4.0
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL '
	SET @Strsql+='AND Isonleave=''true'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) '
	SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,Login_datetimeORDBY,ATTEN_STATUS '
	SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	SET @Strsql+='LEFT OUTER JOIN #TMPLOCATIONNAME SU ON USR.USER_ID=SU.User_Id AND ATTEN.Login_datetime=SU.SDATE '
	SET @Strsql+=') AS DB '
	IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
		SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
		SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
	ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
		SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
	ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
		END
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.EMPCODE) '
		END
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT

	--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	--End of Rev 3.0
	--End of Rev 5.0
	DROP TABLE #tbl_trans_shopActivitysubmit
	--End of Rev 5.0

	SET NOCOUNT OFF
END