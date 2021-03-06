--EXEC PRC_FTSVISITLOGMONITOR_REPORT 'API','2018-12-17','2018-12-17','0','Summary',378
--EXEC PRC_FTSVISITLOGMONITOR_REPORT 'PORTAL','2018-12-06','2018-12-06','0','Summary',1672
--EXEC PRC_FTSVISITLOGMONITOR_REPORT 'PORTAL','2018-12-06','2018-12-06','0','Detail',1672

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSVISITLOGMONITOR_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSVISITLOGMONITOR_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSVISITLOGMONITOR_REPORT]
(
@MODULETYPE NVARCHAR(50)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@USERLIST NVARCHAR(MAX)=NULL,
@ACTION NVARCHAR(50)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 29/11/2018
Module	   : Visit Log Monitoring

REV NO.		DATE			VERSION			DEVELOPER			CHANGES										           	INSTRUCTED BY
-------		----			-------			---------			-------											        -------------					
1.0			01-12-2018		V 1.0.70		SUDIP PAL			 OUTPUT VISIT DATE yy-mm-dd										
2.0         17-12-2018		V 1.0.70		SUDIP PAL			Visit not showing although visited
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#USERID_LIST') AND TYPE IN (N'U'))
		DROP TABLE #USERID_LIST
	CREATE TABLE #USERID_LIST (user_id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #USERID_LIST (user_id ASC)
	IF @USERLIST <> ''
		BEGIN
			SET @USERLIST=REPLACE(@USERLIST,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #USERID_LIST SELECT user_id from tbl_master_user where user_id in('+@USERLIST+')'
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

	IF @MODULETYPE='PORTAL' AND @ACTION IN('Summary','Detail')
		BEGIN
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSVISITLOGMONITOR_REPORT') AND TYPE IN (N'U'))
			BEGIN
				CREATE TABLE FTSVISITLOGMONITOR_REPORT
				(
				  USERID INT,
				  ACTION NVARCHAR(50),
				  MODULETYPE NVARCHAR(50),
				  USERNAME NVARCHAR(80) NULL,
				  USRID INT,
				  SHOPVISIT INT,
				  SHOPNAME NVARCHAR(100) NULL,
				  SHOPID INT,
				  CONTACTNO NVARCHAR(50) NULL,
				  VISITDATE NVARCHAR(50) NULL,
				  TIMESPENT NVARCHAR(100) NULL
				)
				CREATE NONCLUSTERED INDEX IX1 ON FTSVISITLOGMONITOR_REPORT (USERID,SHOPID)
			END
			DELETE FROM FTSVISITLOGMONITOR_REPORT WHERE USERID=@USERID AND ACTION=@ACTION AND MODULETYPE=@MODULETYPE
		END

	SET @Strsql=''
	IF @MODULETYPE='API' AND @ACTION='Summary'
		BEGIN
			SET @Strsql='SELECT USRID,USERNAME,CONTACTNO,SHOPVISIT,RIGHT(''0'' + CAST(TIMESPENT/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(TIMESPENT % 60 AS VARCHAR),2) AS TIMESPENT FROM( '
			SET @Strsql+='SELECT USR.user_id AS USRID,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS USERNAME,'
			--SET @Strsql+='SUM(total_visit_count) AS SHOPVISIT,USR.user_loginId AS CONTACTNO,'
			--SET @Strsql+='CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(spent_duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(spent_duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS TIMESPENT, '
			SET @Strsql+='SHOPACT.total_visit_count AS SHOPVISIT,USR.user_loginId AS CONTACTNO,SHOPACT.spent_duration AS TIMESPENT,RPTTO.cnt_internalId AS RPTTOID,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_Master_shop AS SHOP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON SHOP.SHOP_CREATEUSER=USR.USER_ID '
			SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			--REf 2.0
			--SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+=' INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_contactId=EMPCTC.emp_cntId '
			--REf 2.0
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '			
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '		
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT User_Id,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(spent_duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(spent_duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS spent_duration,'
			SET @Strsql+='COUNT(total_visit_count) AS total_visit_count from tbl_trans_shopActivitysubmit '
			SET @Strsql+='WHERE CONVERT(VARCHAR(10),visited_time,120) BETWEEN CONVERT(VARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(VARCHAR(10),'''+@TODATE+''',120) GROUP BY User_Id '
			SET @Strsql+=') AS SHOPACT ON USR.user_id=SHOPACT.User_Id '
			--SET @Strsql+='INNER JOIN tbl_trans_shopActivitysubmit SHOPACT ON SHOP.Shop_Code=SHOPACT.Shop_Id AND USR.user_id=SHOPACT.User_Id '
			--SET @Strsql+='WHERE SHOPACT.visited_date BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+''' '
			--IF (@USERLIST<>'' AND @USERLIST<>'0')
			--	SET @Strsql+='AND EXISTS (SELECT user_id FROM #USERID_LIST AS US WHERE US.user_id=USR.USER_ID) '
			SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='GROUP BY CNT.cnt_internalId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_id,USR.user_loginId,SHOPACT.spent_duration,SHOPACT.total_visit_count,'
			SET @Strsql+='RPTTO.cnt_internalId,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO) AS VISIT '
			SET @Strsql+='ORDER BY USRID '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql

			SET @Strsql=''
			SET @Strsql='SELECT DISTINCT USERNAME,USRID,SHOPNAME,SHOPID,CONTACTNO,VISITDATE,RIGHT(''0'' + CAST(TIMESPENT/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(TIMESPENT % 60 AS VARCHAR),2) AS TIMESPENT FROM( '
			SET @Strsql+='SELECT ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS USERNAME,USR.user_id AS USRID,SHOP.Shop_Name AS SHOPNAME,SHOP.Shop_ID AS SHOPID,USR.user_loginId AS CONTACTNO,'
			--Ref 1.0
			--SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) +'' ''+ CONVERT(VARCHAR(15),CAST(SHOPACT.visited_time AS TIME),100) AS VISITDATE,'
			SET @Strsql+='SHOPACT.visited_time AS VISITDATE,'
			--Ref 1.0
			SET @Strsql+='CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(spent_duration,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(spent_duration,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS TIMESPENT '
			SET @Strsql+='FROM tbl_Master_shop AS SHOP '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON SHOP.SHOP_CREATEUSER=USR.USER_ID '
			SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
			---REf 2.0			
			---SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+=' INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_contactId=EMPCTC.emp_cntId '			
			--REf 2.0
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET	 @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN tbl_trans_shopActivitysubmit SHOPACT ON SHOP.Shop_Code=SHOPACT.Shop_Id AND USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='WHERE SHOPACT.visited_date BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+''' '
			--IF (@USERLIST<>'' AND @USERLIST<>'0')
			--	SET @Strsql+='AND EXISTS (SELECT user_id FROM #USERID_LIST AS US WHERE US.user_id=USR.USER_ID) '
			SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+=') AS VITSITDET ORDER BY SHOPID '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @MODULETYPE='PORTAL'
		BEGIN
			IF @ACTION='Summary'
				BEGIN
					SET @Strsql=''
					SET @Strsql='INSERT INTO FTSVISITLOGMONITOR_REPORT(USERID,MODULETYPE,ACTION,USERNAME,USRID,SHOPVISIT,TIMESPENT) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''PORTAL'' AS MODULETYPE,''Summary'' AS ACTION,USERNAME,USRID,SHOPVISIT,RIGHT(''0'' + CAST(TIMESPENT/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(TIMESPENT % 60 AS VARCHAR),2) AS TIMESPENT FROM( '
					SET @Strsql+='SELECT ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS USERNAME,USR.user_id AS USRID,'
					--SUM(total_visit_count) AS SHOPVISIT,'
					--SET @Strsql+='CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(spent_duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(spent_duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS TIMESPENT '
					SET @Strsql+='SHOPACT.total_visit_count AS SHOPVISIT,SHOPACT.spent_duration AS TIMESPENT '
					SET @Strsql+='FROM tbl_Master_shop AS SHOP '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON SHOP.SHOP_CREATEUSER=USR.USER_ID '
					SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='INNER JOIN (SELECT User_Id,CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(spent_duration,''00:00:00'')) * 60)) AS FLOAT) +CAST(SUM(DATEPART(MINUTE,ISNULL(spent_duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS spent_duration,'
					SET @Strsql+='COUNT(total_visit_count) AS total_visit_count from tbl_trans_shopActivitysubmit '
					SET @Strsql+='WHERE CONVERT(VARCHAR(10),visited_time,120) BETWEEN CONVERT(VARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(VARCHAR(10),'''+@TODATE+''',120) GROUP BY User_Id '
					SET @Strsql+=') AS SHOPACT ON USR.user_id=SHOPACT.User_Id '
					--SET @Strsql+='INNER JOIN tbl_trans_shopActivitysubmit SHOPACT ON SHOP.Shop_Code=SHOPACT.Shop_Id AND USR.user_id=SHOPACT.User_Id '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--IF (@USERLIST<>'' AND @USERLIST<>'0')
					--	SET @Strsql+='AND EXISTS (SELECT user_id FROM #USERID_LIST AS US WHERE US.user_id=USR.USER_ID) '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+='GROUP BY CNT.cnt_internalId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_id,USR.user_loginId,SHOPACT.spent_duration,SHOPACT.total_visit_count,'
					SET @Strsql+='RPTTO.cnt_internalId,RPTTO.emp_reportTo,RPTTO.user_id,RPTTO.REPORTTO) AS VISIT '
					SET @Strsql+='ORDER BY USRID '
					--SELECT @Strsql
					EXEC SP_EXECUTESQL @Strsql
				END
			ELSE IF @ACTION='Detail'
				BEGIN
					SET @Strsql=''
					SET @Strsql='INSERT INTO FTSVISITLOGMONITOR_REPORT(USERID,MODULETYPE,ACTION,USERNAME,USRID,SHOPNAME,SHOPID,CONTACTNO,VISITDATE,TIMESPENT) '
					SET @Strsql+='SELECT DISTINCT '+STR(@USERID)+' AS USERID,''PORTAL'' AS MODULETYPE,''Detail'' AS ACTION,USERNAME,USRID,SHOPNAME,SHOPID,CONTACTNO,VISITDATE,RIGHT(''0'' + CAST(TIMESPENT/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(TIMESPENT % 60 AS VARCHAR),2) AS TIMESPENT FROM( '
					SET @Strsql+='SELECT ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS USERNAME,USR.user_id AS USRID,SHOP.Shop_Name AS SHOPNAME,SHOP.Shop_ID AS SHOPID,USR.user_loginId AS CONTACTNO,'
					SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) +'' ''+ CONVERT(VARCHAR(15),CAST(SHOPACT.visited_time as TIME),100) AS VISITDATE,'
					SET @Strsql+='CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(spent_duration,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(spent_duration,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS TIMESPENT '
					SET @Strsql+='FROM tbl_Master_shop AS SHOP '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON SHOP.SHOP_CREATEUSER=USR.USER_ID '
					SET @Strsql+='INNER JOIN tbl_master_employee EMP ON EMP.emp_contactId=USR.user_contactId '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='INNER JOIN tbl_trans_shopActivitysubmit SHOPACT ON SHOP.Shop_Code=SHOPACT.Shop_Id AND USR.user_id=SHOPACT.User_Id '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--IF (@USERLIST<>'' AND @USERLIST<>'0')
					--	SET @Strsql+='AND EXISTS (SELECT user_id FROM #USERID_LIST AS US WHERE US.user_id=USR.USER_ID) '
					SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+=') AS VITSITDET ORDER BY SHOPID '
					--SELECT @Strsql
					EXEC SP_EXECUTESQL @Strsql
				END
		END
	DROP TABLE #USERID_LIST
END