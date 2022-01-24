--EXEC PRC_FTSTRACKSALESMANCURRENTLOCATION_REPORT '2019-01-09','A','15','Summary',378
--EXEC PRC_FTSTRACKSALESMANCURRENTLOCATION_REPORT '2018-12-18','A','','Summary',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTRACKSALESMANCURRENTLOCATION_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTRACKSALESMANCURRENTLOCATION_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTRACKSALESMANCURRENTLOCATION_REPORT]
(
@TODAYDATE NVARCHAR(10)=NULL,
@HIERARCHY NVARCHAR(1)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@RPTTYPE NVARCHAR(10)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 18/12/2018
Module	   : Track Salesman Curent Location
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX)

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

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSHOP') AND TYPE IN (N'U'))
		DROP TABLE #TEMPSHOP
	CREATE TABLE #TEMPSHOP
	(
	USER_ID INT,EMPCODE NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,STATEID INT,STATE NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS,LOCATIONDATE DATETIME
	)

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

	SET @Strsql=''
	SET @Strsql='INSERT INTO #TEMPSHOP '
	SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,MAX(SHOP.SDate) AS LOCATIONDATE FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_trans_shopuser SHOP ON SHOP.user_id=USR.user_id '
	SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=EMP.emp_contactId AND add_addressType=''Office'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),SHOP.SDATE,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
	IF @HIERARCHY<>'A'
		SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
	IF @STATEID<>''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
	SET @Strsql+='GROUP BY USR.user_id,CNT.cnt_internalId,ST.ID,ST.state '
	--SELECT @Strsql
	EXEC(@Strsql)

	SET @Strsql=''
	SET @Strsql='SELECT EMPNAME AS Name,LOCATIONDATE AS [Date and Time],location_name AS [Current Location],STATE AS State,CONTACTNO AS Mobile FROM('
	SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME, '
	SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
	SET @Strsql+='SHOP.location_name,MAX(REPLACE(REPLACE(CONVERT(VARCHAR(10),SHOP.SDATE,105) +'' ''+ CONVERT(VARCHAR(15),CAST(SHOP.SDATE AS TIME),100),''AM'','' AM''),''PM'','' PM'')) LOCATIONDATE, '
	SET @Strsql+='USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_fts_UserAttendanceLoginlogout ATTEN ON ATTEN.User_Id=USR.user_id AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=EMP.emp_contactId AND add_addressType=''Office'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN #TEMPSHOP TMP ON TMP.EMPCODE=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN tbl_trans_shopuser SHOP ON SHOP.user_id=USR.user_id AND TMP.LOCATIONDATE=SHOP.SDate '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),SHOP.SDATE,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
	IF @HIERARCHY<>'A'
		SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
	IF @STATEID<>''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
	SET @Strsql+='GROUP BY USR.user_id,CNT.cnt_internalId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ST.ID,ST.state,SHOP.location_name,TMP.LOCATIONDATE,USR.user_loginId,RPTTO.user_id,RPTTO.emp_reportTo,'
	SET @Strsql+='RPTTO.cnt_internalId,RPTTO.REPORTTO '
	SET @Strsql+=') AS SALESMANTRACK ORDER BY LOCATIONDATE DESC'
	--SELECT @Strsql
	EXEC(@Strsql)

	DROP TABLE #TEMPCONTACT
	DROP TABLE #TEMPSHOP
END