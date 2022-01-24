--EXEC PRC_FTSSHOPVISITANALYSIS_REPORT '2017-11-24','2018-11-29',378
--EXEC PRC_FTSSHOPVISITANALYSIS_REPORT '2018-12-01','2018-12-07',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSSHOPVISITANALYSIS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSSHOPVISITANALYSIS_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSSHOPVISITANALYSIS_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 05/12/2018
Module	   : Visit Shop Analysis
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

	SET @Strsql=''
	SET @Strsql='SELECT * FROM ('
	SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='SHOPVISIT.TOTALSPVISIT AS TOTALSHOP,(SHOPVISIT.TOTALSPVISIT-SHOPVISIT.NEWSHOPVISIT) AS REVISIT,SHOPVISIT.NEWSHOPVISIT,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,'
	SET @Strsql+='RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT User_Id,SUM(TOTALSPVISIT) AS TOTALSPVISIT,SUM(NEWSHOPVISIT) AS NEWSHOPVISIT FROM( '
	SET @Strsql+='SELECT User_Id,COUNT(total_visit_count) AS TOTALSPVISIT,0 AS NEWSHOPVISIT FROM tbl_trans_shopActivitysubmit '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),visited_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120)  AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY User_Id '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT Shop_CreateUser AS User_Id,0 AS TOTALSPVISIT,ISNULL(COUNT(DISTINCT Shop_ID),0) AS NEWSHOPVISIT FROM tbl_Master_shop '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Shop_CreateTime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120)  AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY Shop_CreateUser) AS AA GROUP BY User_Id '
	SET @Strsql+=') SHOPVISIT ON SHOPVISIT.User_Id=SHOP.Shop_CreateUser AND SHOPVISIT.User_Id=USR.user_id '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' AND RPTTO.user_id='+STR(@USERID)+' '
	SET @Strsql+=') AS TOPVISITSHOP ORDER BY TOTALSHOP DESC '
	--SELECT @Strsql
	EXEC (@Strsql)

	DROP TABLE #TEMPCONTACT
END