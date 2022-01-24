--EXEC PRC_FTSSUBORDINATES_REPORT 'API','2018-11-26',378
--EXEC PRC_FTSSUBORDINATES_REPORT 'PORTAL','2018-11-26',1656

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSSUBORDINATES_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSSUBORDINATES_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSSUBORDINATES_REPORT]
(
@MODULETYPE NVARCHAR(50)=NULL,
@TODATE NVARCHAR(10)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 29/11/2018
Module	   : Subordinates List
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX)

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

	IF @MODULETYPE='PORTAL'
		BEGIN
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSSUBORDINATES_REPORT') AND TYPE IN (N'U'))
			BEGIN
				CREATE TABLE FTSSUBORDINATES_REPORT
				(
				  USERID INT,
				  MODULETYPE NVARCHAR(50),
				  MEMBERID NVARCHAR(10),
				  MEMBERNAME NVARCHAR(80) NULL,
				  STATUS NVARCHAR(50) NULL,
				  CONTACTNO NVARCHAR(50) NULL
				)
				CREATE NONCLUSTERED INDEX IX1 ON FTSSUBORDINATES_REPORT (MEMBERID)
			END
			DELETE FROM FTSSUBORDINATES_REPORT WHERE USERID=@USERID
		END

	SET @Strsql=''
	IF @MODULETYPE='API'
		BEGIN
			SET @Strsql='SELECT DISTINCT USR.user_id AS USRID,CNT.cnt_internalId AS MEMBERID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS MEMBERNAME,'
			SET @Strsql+='CASE WHEN ATTENLILO.STATUS IS NULL THEN ''Not Logged In'' ELSE ATTENLILO.STATUS END AS STATUS,USR.user_loginId AS CONTACTNO,RPTTO.cnt_internalId,RPTTO.emp_reportTo,RPTTO.user_id,'
			SET @Strsql+='RPTTO.REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id AS USERID,CONVERT(NVARCHAR(10),Work_datetime,105) AS WORKTIME,CASE WHEN Isonleave=''false'' THEN ''At Work'' WHEN Isonleave=''true'' THEN ''On Leave'' END STATUS FROM tbl_fts_UserAttendanceLoginlogout '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Work_datetime,105),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='WHERE RPTTO.user_id='+STR(@USERID)+' '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @MODULETYPE='PORTAL'
		BEGIN
			SET @Strsql='INSERT INTO FTSSUBORDINATES_REPORT(USERID,MODULETYPE,MEMBERID,MEMBERNAME,STATUS,CONTACTNO) '
			SET @Strsql+='SELECT DISTINCT '+STR(@USERID)+' AS USERID,''PORTAL'' AS MODULETYPE,CNT.cnt_internalId AS MEMBERID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS MEMBERNAME,'
			SET @Strsql+='CASE WHEN ATTENLILO.STATUS IS NULL THEN ''Not Logged In'' ELSE ATTENLILO.STATUS END AS STATUS,USR.user_loginId AS CONTACTNO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMPCTC.emp_cntId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id AS USERID,CONVERT(NVARCHAR(10),Work_datetime,105) AS WORKTIME,CASE WHEN Isonleave=''false'' THEN ''At Work'' WHEN Isonleave=''true'' THEN ''On Leave'' END STATUS FROM tbl_fts_UserAttendanceLoginlogout '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Work_datetime,105),Isonleave) ATTENLILO ON ATTENLILO.USERID=USR.user_id '
			SET @Strsql+='WHERE RPTTO.user_id='+STR(@USERID)+' '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	DROP TABLE #TEMPCONTACT
END