--EXEC PRC_FTSATTENDANCEREMINDSMS_REPORT 1650

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSATTENDANCEREMINDSMS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSATTENDANCEREMINDSMS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSATTENDANCEREMINDSMS_REPORT]
(
@USER_ID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 04/02/2019
Module	   : Attendance Reminder SMS
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPNOTLOGIN') AND TYPE IN (N'U'))
		DROP TABLE #TEMPNOTLOGIN
	CREATE TABLE #TEMPNOTLOGIN
		(
			EMPCODE NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPNOTLOGIN(EMPCODE)

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

	SET @Strsql=''
	SET @Strsql='INSERT INTO #TEMPNOTLOGIN '
	SET @Strsql+='SELECT DISTINCT EMPCODE FROM('
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''false'' THEN COUNT(Isonleave) ELSE 0 END AS AT_WORK FROM tbl_fts_UserAttendanceLoginlogout '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),GETDATE(),120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+='GROUP BY User_Id,CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id WHERE USR.user_inactive=''N'' '
	SET @Strsql+='AND USR.USER_ID='+STR(@USER_ID)+' '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
	SET @Strsql+='FROM tbl_master_employee EMP INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN (SELECT User_Id AS USERID,CASE WHEN Isonleave=''true'' THEN COUNT(Isonleave) ELSE 0 END AS ON_LEAVE FROM tbl_fts_UserAttendanceLoginlogout '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),GETDATE(),120) AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''true'' GROUP BY User_Id,'
	SET @Strsql+='CAST(Work_datetime AS DATE),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id WHERE USR.user_inactive=''N'' '
	SET @Strsql+='AND USR.USER_ID='+STR(@USER_ID)+' '
	SET @Strsql+=') AS NOTLOGIN '
	--SELECT @Strsql
	EXEC (@Strsql)

	SET @Strsql=''
	SET @Strsql='SELECT ''Attendance Reminder from FSM(Karuna): Login through mobile app and mark your attendance as At Work/On Leave. Please ignore if attendance is already marked.'' FROM( '
	SET @Strsql+='SELECT EMP.emp_uniqueCode AS EMPID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
	SET @Strsql+='DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTO '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='LEFT OUTER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
	SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId WHERE emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='WHERE NOT EXISTS(SELECT EMPCODE FROM #TEMPNOTLOGIN WHERE EMPCODE=CNT.cnt_internalId) AND USR.user_inactive=''N'' '
	SET @Strsql+='AND USR.USER_ID='+STR(@USER_ID)+' '
	SET @Strsql+=') AS DB '
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #TEMPCONTACT
	DROP TABLE #TEMPNOTLOGIN
END