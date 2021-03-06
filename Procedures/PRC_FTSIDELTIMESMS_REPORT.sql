--EXEC PRC_FTSIDELTIMESMS_REPORT 1655

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSIDELTIMESMS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSIDELTIMESMS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSIDELTIMESMS_REPORT]
(
@USER_ID INT 
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 13/02/2019
Module	   : Idel Time SMS.
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

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
	SET @Strsql='SELECT ''You have been found in a same location for more than 30 mins. Please proceed for further visit to achieve target. Thanks.'' '
	SET @Strsql+='FROM( '
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,IDEALLOACTION.IDEAL_TIME '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
	SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT user_id,SUM(IDEAL_TIME) AS IDEAL_TIME FROM('
	SET @Strsql+='SELECT user_id,'	
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(end_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(end_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - '
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(start_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(start_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME '
	SET @Strsql+='FROM FTS_Ideal_Loaction WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) AND IsSmssent=0 '
	SET @Strsql+=') IDLE GROUP BY user_id) IDEALLOACTION ON IDEALLOACTION.user_id=USR.user_id '
	SET @Strsql+='WHERE USR.USER_ID='+LTRIM(RTRIM(STR(@USER_ID)))+' '
	SET @Strsql+=') AS IT '
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	UPDATE FTS_Ideal_Loaction SET IsSmssent=1 WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) AND IsSmssent=0 AND user_id=@USER_ID

	DROP TABLE #TEMPCONTACT
END