--EXEC PRC_FTSIDELTIMESMSTORPTTO_REPORT 1654

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSIDELTIMESMSTORPTTO_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSIDELTIMESMSTORPTTO_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSIDELTIMESMSTORPTTO_REPORT]
(
@USER_ID INT 
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 01/03/2019
Module	   : Idel Time SMS to Report to.
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@LOGINEMPCODE NVARCHAR(50),@IDLECNT INT=0

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

	SET @LOGINEMPCODE=(SELECT USER_CONTACTID FROM TBL_MASTER_USER WHERE USER_ID=@USER_ID)

	SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE INTO #EMPHR FROM tbl_trans_employeeCTC CTC LEFT OUTER JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO

	;WITH CTE AS(SELECT	EMPCODE FROM #EMPHR WHERE EMPCODE IS NULL OR EMPCODE=@LOGINEMPCODE
	UNION ALL
	SELECT A.EMPCODE FROM #EMPHR A
	JOIN CTE B
	ON A.RPTTOEMPCODE = B.EMPCODE
	) 
	SELECT DISTINCT TMU.user_id,TMU.USER_CONTACTID AS EMPCODE INTO #EMPLOYEEHRLIST FROM CTE 
	INNER JOIN TBL_MASTER_USER TMU ON CTE.EMPCODE=TMU.USER_CONTACTID
	INNER JOIN FTS_Ideal_Loaction IDL ON IDL.user_id=TMU.user_id AND TMU.user_id<>@USER_ID	

	SELECT @IDLECNT=COUNT(0) FROM FTS_Ideal_Loaction B WHERE EXISTS(SELECT A.user_id FROM #EMPLOYEEHRLIST A WHERE B.user_id=A.user_id) 
	AND CONVERT(NVARCHAR(10),start_ideal_date_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) AND Issupervisorsmssent=0

	SET @Strsql=''
	SET @Strsql='SELECT CASE WHEN '+LTRIM(RTRIM(STR(@IDLECNT)))+'=''0'' THEN '''' ELSE ''Idle time details: '' END+'
	SET @Strsql+='ISNULL(STUFF((SELECT '' | '' +EMPNAME+'': ''+CASE WHEN IDEAL_TIME IS NULL THEN ''00:00'' ELSE IDEAL_TIME END FROM( '
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='RIGHT(''0'' + CAST(CAST(IDEALLOACTION.IDEAL_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(IDEALLOACTION.IDEAL_TIME AS VARCHAR) % 60 AS VARCHAR),2) AS IDEAL_TIME '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG '
	SET @Strsql+='ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT USR.user_id AS RPTTOUSR,EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT user_id,SUM(IDEAL_TIME) AS IDEAL_TIME FROM('
	SET @Strsql+='SELECT user_id,'	
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(end_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(end_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - '
	SET @Strsql+='CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(start_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) + CAST(DATEPART(MINUTE,ISNULL(start_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME '
	SET @Strsql+='FROM FTS_Ideal_Loaction WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) AND Issupervisorsmssent=0 '
	SET @Strsql+=') IDLE GROUP BY user_id) IDEALLOACTION ON IDEALLOACTION.user_id=USR.user_id '
	SET @Strsql+='WHERE RPTTO.RPTTOUSR='+LTRIM(RTRIM(STR(@USER_ID)))+' '
	SET @Strsql+=') AS DB GROUP BY EMPNAME,IDEAL_TIME FOR XML PATH('''')), 2, 2, ''''),'''') SMS '
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	UPDATE FTS_Ideal_Loaction SET Issupervisorsmssent=1 WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) AND Issupervisorsmssent=0 AND user_id IN(SELECT USER_ID FROM #EMPLOYEEHRLIST)

	DROP TABLE #TEMPCONTACT
	DROP TABLE #EMPHR
	DROP TABLE #EMPLOYEEHRLIST
END