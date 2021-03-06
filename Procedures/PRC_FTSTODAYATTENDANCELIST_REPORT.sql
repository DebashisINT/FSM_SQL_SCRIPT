--EXEC PRC_FTSTODAYATTENDANCELIST_REPORT '2018-11-26','API','Summary','1','',378
--EXEC PRC_FTSTODAYATTENDANCELIST_REPORT '2018-11-26','API','Summary','2','EMR0000001',378
--EXEC PRC_FTSTODAYATTENDANCELIST_REPORT '2018-11-26','PORTAL','Summary','0','',378
--EXEC PRC_FTSTODAYATTENDANCELIST_REPORT '2018-11-26','PORTAL','Detail','0','EMR0000001',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTODAYATTENDANCELIST_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTODAYATTENDANCELIST_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTODAYATTENDANCELIST_REPORT]
(
@TODATE NVARCHAR(10)=NULL,
@MODULETYPE NVARCHAR(50)=NULL,
@ACTION NVARCHAR(50)=NULL,
@APICOND NVARCHAR(50)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT 
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 03/12/2018
Module	   : Today's Attendance List
1.0		v1.0.68		Sudip	17/12/2018		Route List not showing as expected
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
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
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSTODAYATTENDANCELIST_REPORT') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTSTODAYATTENDANCELIST_REPORT
		(
		  USERID INT,		  
		  SEQ INT,
		  MODULETYPE NVARCHAR(50),
		  ACTION NVARCHAR(50),
		  USRID INT,
		  EMPCODE NVARCHAR(100) NULL,
		  EMPNAME NVARCHAR(300) NULL,
		  LOGGEDIN NVARCHAR(100) NULL,
		  WORKSTATUS NVARCHAR(100) NULL,
		  CONTACTNO NVARCHAR(100) NULL,
		  RPTTOID INT,
		  RPTTOCODE NVARCHAR(100) NULL,
		  REPORTTO NVARCHAR(300) NULL,
		  WORK_TYPE	NVARCHAR(MAX) NULL,
		  DESCRIPTION NVARCHAR(MAX) NULL,
		  PINCODE NVARCHAR(50) NULL,
		  ADDRESS NVARCHAR(MAX) NULL
		)
		CREATE NONCLUSTERED INDEX IX1 ON FTSTODAYATTENDANCELIST_REPORT (SEQ)
	END
	DELETE FROM FTSTODAYATTENDANCELIST_REPORT WHERE USERID=@USERID AND MODULETYPE=@MODULETYPE AND ACTION=@ACTION 

	SET @Strsql=''
	IF @MODULETYPE='API' AND @ACTION='Summary'
		BEGIN
			IF @APICOND='1'
				--CONVERT(VARCHAR(15),CAST(RIGHT('0' + CAST(CAST(LOGGEDIN AS VARCHAR)/ 60 AS VARCHAR),2)  + ':' +RIGHT('0' + CAST(CAST(LOGGEDIN AS VARCHAR) % 60 AS VARCHAR),2) AS TIME),100) AS LOGGEDIN,
				BEGIN
					SET @Strsql='SELECT USRID,EMPCODE,EMPNAME,'
					SET @Strsql+='REPLACE(REPLACE(CONVERT(VARCHAR(15),CAST(RIGHT(''0'' + CAST(CAST(LOGGEDIN AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(LOGGEDIN AS VARCHAR) % 60 AS VARCHAR),2) AS TIME),100),''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,'
					SET @Strsql+='STATUS,CONTACTNO,RPTTOID,RPTTOCODE,REPORTTO FROM('
					SET @Strsql+='SELECT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS LOGGEDIN,'
					SET @Strsql+='CASE WHEN ATTEN.STATUS IS NULL THEN ''Not Logged In'' ELSE ATTEN.STATUS END AS STATUS,USR.user_loginId AS CONTACTNO,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
					SET @Strsql+='FROM tbl_master_employee EMP '
					--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT ATTEN.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT,'
					SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' WHEN Isonleave=''true'' THEN ''On Leave'' END STATUS,CNT.cnt_internalId,CAST(ATTEN.Work_datetime AS DATE) AS TODAYDATE '
					SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
					SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,Isonleave,CAST(ATTEN.Work_datetime AS DATE)) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
					SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND CONVERT(NVARCHAR(10),ATTEN.TODAYDATE,120)=CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+='GROUP BY USR.user_id,CNT.cnt_internalId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ATTEN.LOGGEDIN,ATTEN.STATUS,USR.user_loginId,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
					SET @Strsql+=') AS ATTEN ORDER BY EMPCODE'
					--SELECT @Strsql
					EXEC (@Strsql)
				END			
			ELSE IF @APICOND='2'
				BEGIN
					SET @Strsql=''
					SET @Strsql='SELECT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					SET @Strsql+='WRKACT.WrkActvtyDescription AS WORK_TYPE,ATTEN.Work_Desc AS DESCRIPTION,WRKACT.WorkActivityID AS WORK_ID,ATTEN.Work_Address AS LOCATION '
					SET @Strsql+='FROM tbl_master_employee EMP '
					--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON USR.user_id=ATTEN.User_Id '
					SET @Strsql+='INNER JOIN tbl_attendance_worktype ATTENWRKTYP ON ATTENWRKTYP.UserID=ATTEN.User_Id AND ATTEN.Id=ATTENWRKTYP.attendanceid '
					SET @Strsql+='INNER JOIN tbl_FTS_WorkActivityList WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID '
					SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					IF @EMPID<>''
						SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=CNT.cnt_internalId) '
					SET @Strsql+='ORDER BY CNT.cnt_internalId '
					--SELECT @Strsql
					EXEC (@Strsql)

					SET @Strsql=''
					SET @Strsql='SELECT DISTINCT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					SET @Strsql+='ATTENR.RouteID AS PINCODE,''Route ''+(Pincode) as Routename '
					SET @Strsql+='FROM tbl_master_employee EMP '
					--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON USR.user_id=ATTEN.User_Id '
					SET @Strsql+='INNER JOIN (SELECT attendanceid,RouteID,UserID FROM tbl_attendance_RouteShop GROUP BY attendanceid,RouteID,UserID) ATTENR ON ATTENR.UserID=ATTEN.User_Id AND ATTENR.attendanceid=ATTEN.Id '
					SET @Strsql+='INNER JOIN (SELECT Shop_CreateUser,Address,Pincode FROM tbl_Master_shop GROUP BY Shop_CreateUser,Address,Pincode) MSHOP '
					SET @Strsql+='ON MSHOP.Shop_CreateUser=ATTENR.UserID AND ATTENR.RouteID=MSHOP.Pincode '
					SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					IF @EMPID<>''
						SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=CNT.cnt_internalId) '
					SET @Strsql+='ORDER BY CNT.cnt_internalId '
					--SELECT @Strsql
					EXEC (@Strsql)
					SET @Strsql=''
					--Ref  1.0
					--SET @Strsql='SELECT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					--SET @Strsql+='ATTENR.RouteID AS PINCODE,MSHOP.Shop_Name,MSHOP.Address '
					--SET @Strsql+='FROM tbl_master_employee EMP '
					----SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					----SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					--SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					--SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					--SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON USR.user_id=ATTEN.User_Id '
					--SET @Strsql+='INNER JOIN (SELECT attendanceid,RouteID,UserID FROM tbl_attendance_RouteShop GROUP BY attendanceid,RouteID,UserID) ATTENR ON ATTENR.UserID=ATTEN.User_Id AND ATTENR.attendanceid=ATTEN.Id '
					--SET @Strsql+='INNER JOIN (SELECT Shop_CreateUser,Shop_Name,Address,Pincode FROM tbl_Master_shop GROUP BY Shop_CreateUser,Shop_Name,Address,Pincode) MSHOP '
					--SET @Strsql+='ON MSHOP.Shop_CreateUser=ATTENR.UserID AND ATTENR.RouteID=MSHOP.Pincode '
					--SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '

		             SET @Strsql+=' select usr.user_id as USRID,Pincode as PINCODE,Shop_Code as shop_id,Address  as [Address],Shop_Name  as Shop_Name,Shop_Owner_Contact as shop_contact_no   ,cont.cnt_internalId as EMPCODE,ISNULL(cont.CNT_FIRSTNAME,'''')+'' ''+ISNULL(cont.CNT_MIDDLENAME,'''')+'' ''+ISNULL(cont.CNT_LASTNAME,'''') AS EMPNAME
					from tbl_Master_shop 
					INNER JOIN tbl_fts_UserAttendanceLoginlogout as loginlogout on tbl_Master_shop.Shop_CreateUser=loginlogout.User_Id
					INNER JOIN tbl_attendance_Route as attenroute on loginlogout.Id=attenroute.attendanceid and tbl_Master_shop.Pincode=attenroute.RouteID
					INNER JOIN tbl_attendance_RouteShop as routeshp   on loginlogout.Id=routeshp.attendanceid and routeshp.ShopID=tbl_Master_shop.Shop_Code
					INNER JOIN tbl_master_user as usr on usr.user_id=loginlogout.User_Id
					INNER JOIN tbl_master_contact as cont on cont.cnt_internalId=usr.user_contactId
					where cast(Work_datetime as date)=convert(date,GETDATE()) '
					IF @EMPID<>''
						SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=cont.cnt_internalId) '
					SET @Strsql+='UNION ALL '
					SET @Strsql+='select usr.user_id as USRID, routeshp.RouteID as PINCODE,''Other''  as shop_id,'''' as  shop_address,''Other''  Shop_Name,'''' as shop_contact_no  , cont.cnt_internalId as EMPCODE,ISNULL(cont.CNT_FIRSTNAME,'''')+'' ''+ISNULL(cont.CNT_MIDDLENAME,'''')+'' ''+ISNULL(cont.CNT_LASTNAME,'''') AS EMPNAME 
					from tbl_fts_UserAttendanceLoginlogout as loginlogout
					INNER JOIN tbl_attendance_Route as attenroute on loginlogout.Id=attenroute.attendanceid
					INNER JOIN tbl_attendance_RouteShop as routeshp   on loginlogout.Id=routeshp.attendanceid and  attenroute.RouteID=routeshp.RouteID 
					INNER JOIN tbl_master_user as usr on usr.user_id=loginlogout.User_Id
					INNER JOIN tbl_master_contact as cont on cont.cnt_internalId=usr.user_contactId '
					SET @Strsql+='where cast(Work_datetime as date)=convert(date,GETDATE()) and loginlogout.User_Id=1686 and routeshp.ShopID like ''%~New~%'' '
					IF @EMPID<>''
						SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=cont.cnt_internalId) '
					SET @Strsql+='ORDER BY cont.cnt_internalId '
					--Ref 1.0
					--SELECT @Strsql
					EXEC (@Strsql)
				END
		END
	ELSE IF @MODULETYPE='PORTAL'
		BEGIN
			IF @ACTION='Summary'
				BEGIN
					SET @Strsql=''
					SET @Strsql='INSERT INTO FTSTODAYATTENDANCELIST_REPORT(USERID,SEQ,MODULETYPE,ACTION,USRID,EMPCODE,EMPNAME,LOGGEDIN,WORKSTATUS,CONTACTNO,RPTTOID,RPTTOCODE,REPORTTO) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY EMPCODE) AS SEQ,''PORTAL'' AS MODULETYPE,''Summary'' AS ACTION,USRID,EMPCODE,EMPNAME,'
					SET @Strsql+='REPLACE(REPLACE(CONVERT(VARCHAR(15),CAST(RIGHT(''0'' + CAST(CAST(LOGGEDIN AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(LOGGEDIN AS VARCHAR) % 60 AS VARCHAR),2) AS TIME),100),''AM'','' AM''),''PM'','' PM'') AS LOGGEDIN,'
					SET @Strsql+='STATUS,CONTACTNO,RPTTOID,RPTTOCODE,REPORTTO FROM('
					SET @Strsql+='SELECT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS LOGGEDIN,'
					SET @Strsql+='CASE WHEN ATTEN.STATUS IS NULL THEN ''Not Logged In'' ELSE ATTEN.STATUS END AS STATUS,USR.user_loginId AS CONTACTNO,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
					SET @Strsql+='FROM tbl_master_employee EMP '
					--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT ATTEN.User_Id AS USERID,MIN(Login_datetime) AS LOGGEDIN,MAX(Logout_datetime) AS LOGEDOUT,'
					SET @Strsql+='CASE WHEN Isonleave=''false'' THEN ''At Work'' WHEN Isonleave=''true'' THEN ''On Leave'' END STATUS,CNT.cnt_internalId,CAST(ATTEN.Work_datetime AS DATE) AS TODAYDATE '
					SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
					SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,Isonleave,CAST(ATTEN.Work_datetime AS DATE)) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
					SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND CONVERT(NVARCHAR(10),ATTEN.TODAYDATE,120)=CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ATTEN.LOGGEDIN,ATTEN.STATUS,USR.user_loginId,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
					SET @Strsql+=') AS ATTEN '
					--SELECT @Strsql
					EXEC (@Strsql)
				END
			ELSE IF @ACTION='Detail'
				BEGIN
					SET @Strsql=''
					SET @Strsql='INSERT INTO FTSTODAYATTENDANCELIST_REPORT(USERID,SEQ,MODULETYPE,ACTION,USRID,EMPCODE,EMPNAME,WORK_TYPE,DESCRIPTION,PINCODE,ADDRESS) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY EMP.emp_contactId) AS SEQ,''PORTAL'' AS MODULETYPE,''Detail'' AS ACTION,USR.user_id AS USRID,'
					SET @Strsql+='CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					SET @Strsql+='WRKACT.WrkActvtyDescription AS WORK_TYPE,ATTEN.Work_Desc AS DESCRIPTION,ATTENR.RouteID AS PINCODE,MSHOP.Address FROM tbl_master_employee EMP '
					--SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON USR.user_id=ATTEN.User_Id '
					SET @Strsql+='LEFT OUTER JOIN (SELECT UserID,attendanceid,worktypeID FROM tbl_attendance_worktype GROUP BY UserID,attendanceid,worktypeID) ATTENWRKTYP ON ATTENWRKTYP.UserID=ATTEN.User_Id '
					SET @Strsql+='AND ATTEN.Id=ATTENWRKTYP.attendanceid '
					SET @Strsql+='LEFT OUTER JOIN (SELECT WorkActivityID,WrkActvtyDescription FROM tbl_FTS_WorkActivityList GROUP BY WorkActivityID,WrkActvtyDescription) WRKACT ON WRKACT.WorkActivityID=ATTENWRKTYP.worktypeID '
					SET @Strsql+='LEFT OUTER JOIN (SELECT attendanceid,RouteID,UserID FROM tbl_attendance_RouteShop GROUP BY attendanceid,RouteID,UserID) ATTENR ON ATTENR.UserID=ATTEN.User_Id '
					SET @Strsql+='AND ATTENR.attendanceid=ATTEN.Id '
					SET @Strsql+='LEFT OUTER JOIN (SELECT Shop_CreateUser,Address,Pincode FROM tbl_Master_shop GROUP BY Shop_CreateUser,Address,Pincode) MSHOP ON MSHOP.Shop_CreateUser=ATTENR.UserID '
					SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODATE+''',120) AND WRKACT.WrkActvtyDescription IS NOT NULL '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					IF @EMPID<>''
						SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EM WHERE EM.emp_contactId=CNT.cnt_internalId) '
					--SELECT @Strsql
					EXEC (@Strsql)
				END
		END
	DROP TABLE #TEMPCONTACT
END