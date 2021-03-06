--EXEC PRC_FTSDASHBOARDWIDGET_REPORT '2018-12-18','A','15','Summary',378
--EXEC PRC_FTSDASHBOARDWIDGET_REPORT '2018-12-21','A','','Summary',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSDASHBOARDWIDGET_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSDASHBOARDWIDGET_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSDASHBOARDWIDGET_REPORT]
(
@TODAYDATE NVARCHAR(10)=NULL,
@HIERARCHY NVARCHAR(1)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@RPTTYPE NVARCHAR(10)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 14/12/2018
Module	   : Dashboard Widget
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@FinYearStDate NVARCHAR(10)=NULL,@AVGSHOPVISITDAYCNT DECIMAL(18,2)=0,@AVGSALEDAYCNT DECIMAL(18,2)=0,@AVGUSERVISITCNT DECIMAL(18,2)=0,@sqlStrTable NVARCHAR(MAX)
	DECLARE @FROMDATE NVARCHAR(10)

	--SET @FinYearStDate='2018-04-01'

	--SET @DAYCNT=(SELECT DATEDIFF(DAY,CONVERT(DATE,@FinYearStDate),CONVERT(DATE,@TODAYDATE))+1)
	SET @AVGSHOPVISITDAYCNT=(SELECT COUNT(DISTINCT visited_date) FROM tbl_trans_shopActivitysubmit)
	SET @AVGSALEDAYCNT=(SELECT COUNT(Orderdate) FROM tbl_trans_fts_Orderupdate)
	SET @AVGUSERVISITCNT=(SELECT COUNT(DISTINCT Userid) FROM tbl_trans_fts_Orderupdate)
	SET @FROMDATE=DATEADD(DAY, -7, CONVERT(DATE, @TODAYDATE))

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

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSDASHBOARDWIDGET_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSDASHBOARDWIDGET_REPORT
			(
			  USERID INT,
			  MODULENAME NVARCHAR(20),
			  RPTTYPE NVARCHAR(20),
			  SEQ INT,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  TOTALSHOP INT DEFAULT(0),
			  REVISIT INT DEFAULT(0),
			  NEWSHOPVISIT INT DEFAULT(0),
			  SHOPVISITPERDAY INT DEFAULT(0),
			  DURATIONSPENTPERDAY NVARCHAR(20) DEFAULT(''),
			  ORDVALUE DECIMAL(18,2) DEFAULT(0.00),
			  AVGORDVALUE DECIMAL(18,2) DEFAULT(0.00),
			  TOTALORDVALUE DECIMAL(18,2) DEFAULT(0.00),
			  HIGHPERFORMSTATE DECIMAL(18,2) DEFAULT(0.00)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSDASHBOARDWIDGET_REPORT (SEQ)
		END
	DELETE FROM FTSDASHBOARDWIDGET_REPORT WHERE USERID=@USERID AND RPTTYPE=@RPTTYPE 

	IF @RPTTYPE='Summary'
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDWIDGET_REPORT(USERID,MODULENAME,RPTTYPE,SEQ,STATEID,STATE,TOTALSHOP,REVISIT,NEWSHOPVISIT) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''SHOPVISIT'' AS MODULENAME,''Summary'' AS RPTTYPE,'
			IF @STATEID<>''
				SET @Strsql+='ROW_NUMBER() OVER(ORDER BY STATE) AS SEQ,STATEID,STATE,'
			ELSE IF @STATEID=''
				SET @Strsql+='1 AS SEQ,0 AS STATEID,'''' AS STATE,'
			SET @Strsql+='SUM(TOTALSHOP) AS TOTALSHOP,SUM(REVISIT) AS REVISIT,SUM(NEWSHOPVISIT) AS NEWSHOPVISIT FROM ('
			SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SHOPVISIT.TOTALSPVISIT AS TOTALSHOP,(SHOPVISIT.TOTALSPVISIT-SHOPVISIT.NEWSHOPVISIT) AS REVISIT,SHOPVISIT.NEWSHOPVISIT,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,'
			SET @Strsql+='RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN ( '
			SET @Strsql+='SELECT User_Id,SUM(TOTALSPVISIT) AS TOTALSPVISIT,SUM(NEWSHOPVISIT) AS NEWSHOPVISIT FROM( '
			SET @Strsql+='SELECT User_Id,COUNT(total_visit_count) AS TOTALSPVISIT,0 AS NEWSHOPVISIT FROM tbl_trans_shopActivitysubmit '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),visited_date,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY User_Id '
			SET @Strsql+='UNION ALL '
			SET @Strsql+='SELECT Shop_CreateUser AS User_Id,0 AS TOTALSPVISIT,ISNULL(COUNT(DISTINCT Shop_ID),0) AS NEWSHOPVISIT FROM tbl_Master_shop '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),Shop_CreateTime,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY Shop_CreateUser) AS AA GROUP BY User_Id '
			SET @Strsql+=') SHOPVISIT ON SHOPVISIT.User_Id=SHOP.Shop_CreateUser AND SHOPVISIT.User_Id=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.ID) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+=') AS TOPVISITSHOP '
			IF @STATEID<>''
				SET @Strsql+='GROUP BY STATEID,STATE '
			SET @Strsql+='ORDER BY TOTALSHOP DESC '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDWIDGET_REPORT(USERID,MODULENAME,RPTTYPE,SEQ,STATEID,STATE,SHOPVISITPERDAY) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AVGSHOPVISIT'' AS MODULENAME,''Summary'' AS RPTTYPE,'
			IF @STATEID<>''
				SET @Strsql+='ROW_NUMBER() OVER(ORDER BY ISNULL(ST.state,''State Undefined'')) AS SEQ,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			ELSE IF @STATEID=''
				SET @Strsql+='1 AS SEQ,0 AS STATEID,'''' AS STATE,'
			SET @Strsql+='FLOOR(SUM(DISTINCT SHOPVISIT.TOTALSPVISIT)/'+STR(FLOOR(@AVGSHOPVISITDAYCNT),8,2)+') AS SHOPVISITPERDAY FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='INNER JOIN ( '
			SET @Strsql+='SELECT User_Id,SUM(TOTALSPVISIT) AS TOTALSPVISIT,SUM(NEWSHOPVISIT) AS NEWSHOPVISIT FROM( '
			SET @Strsql+='SELECT User_Id,COUNT(total_visit_count) AS TOTALSPVISIT,0 AS NEWSHOPVISIT FROM tbl_trans_shopActivitysubmit '
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),visited_date,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),visited_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY User_Id) AS AA GROUP BY User_Id '
			SET @Strsql+=') SHOPVISIT ON SHOPVISIT.User_Id=SHOP.Shop_CreateUser AND SHOPVISIT.User_Id=USR.user_id '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.ID) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			IF @STATEID<>''
				SET @Strsql+='GROUP BY ST.ID,ST.state '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDWIDGET_REPORT(USERID,MODULENAME,RPTTYPE,SEQ,STATEID,STATE,DURATIONSPENTPERDAY) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AVGDURATION'' AS MODULENAME,''Summary'' AS RPTTYPE,'
			IF @STATEID<>''
				SET @Strsql+='ROW_NUMBER() OVER(ORDER BY STATE) AS SEQ,STATEID,STATE,'
			ELSE IF @STATEID=''
				SET @Strsql+='1 AS SEQ,0 AS STATEID,'''' AS STATE,'
			SET @Strsql+='RIGHT(''0'' + CAST(FLOOR(SUM(spent_duration)) AS VARCHAR), 2) + '':'' + RIGHT(''0'' + CAST(FLOOR((((SUM(spent_duration) * 3600) % 3600) / 60)) AS VARCHAR), 2) AS DURATIONSPENTPERDAY '
			SET @Strsql+='FROM( '			
			SET @Strsql+='SELECT ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,CASE WHEN spent_duration<>0 THEN CAST(CAST(Shop_Id AS VARCHAR)/spent_duration AS DECIMAL(18,2)) ELSE 0 END AS spent_duration '
			--SET @Strsql+='SELECT ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,CASE WHEN spent_duration<>0 THEN CAST((CAST(Shop_Id AS VARCHAR)/spent_duration)/'+STR(FLOOR(@AVGUSERVISITCNT),8,2)+' AS DECIMAL(18,2)) ELSE 0 END AS spent_duration '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL '
			SET @Strsql+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='INNER JOIN (SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(Shop_Id) AS Shop_Id,CAST(CAST(ISNULL(CAST((SUM(DATEPART(HOUR,ISNULL(spent_duration,''00:00:00'')) * 60)) AS FLOAT) + '
			SET @Strsql+='CAST(SUM(DATEPART(MINUTE,ISNULL(spent_duration,''00:00:00'')) * 1) AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS spent_duration FROM tbl_trans_shopActivitysubmit SHOPACT '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.ID) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+=') AS DB '
			IF @STATEID<>''
				SET @Strsql+='GROUP BY STATEID,STATE '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDWIDGET_REPORT(USERID,MODULENAME,RPTTYPE,SEQ,STATEID,STATE,ORDVALUE) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''TODAYSALES'' AS MODULENAME,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY STATE) AS SEQ,STATEID,STATE,SUM(CONVERT(DECIMAL(18,2),ORDVALUE))/100000 AS ORDVALUE FROM ('
			SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			IF @STATEID<>''
				SET @Strsql+='ROW_NUMBER() OVER(ORDER BY ISNULL(ST.state,''State Undefined'')) AS SEQ,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			ELSE IF @STATEID=''
				SET @Strsql+='1 AS SEQ,0 AS STATEID,'''' AS STATE,'
			SET @Strsql+='SUM(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120)=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.ID) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_loginId,RPTTO.user_id,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
			IF @STATEID<>''
				SET @Strsql+=',ST.ID,ST.state '
			SET @Strsql+=') AS ORDVALUE '
			SET @Strsql+='GROUP BY STATEID,STATE '
			SET @Strsql+='ORDER BY ORDVALUE DESC '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDWIDGET_REPORT(USERID,MODULENAME,RPTTYPE,SEQ,STATEID,STATE,AVGORDVALUE) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''AVGSALES'' AS MODULENAME,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY STATE) AS SEQ,STATEID,STATE,'
			SET @Strsql+='(SUM(CONVERT(DECIMAL(18,2),ORDVALUE))/'+STR(FLOOR(@AVGSALEDAYCNT),8,2)+')/1000000 AS AVGORDVALUE FROM ('
			SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			IF @STATEID<>''
				SET @Strsql+='ROW_NUMBER() OVER(ORDER BY ISNULL(ST.state,''State Undefined'')) AS SEQ,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			ELSE IF @STATEID=''
				SET @Strsql+='1 AS SEQ,0 AS STATEID,'''' AS STATE,'
			SET @Strsql+='SUM(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.ID) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_loginId,RPTTO.user_id,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
			IF @STATEID<>''
				SET @Strsql+=',ST.ID,ST.state '
			SET @Strsql+=') AS ORDVALUE '
			SET @Strsql+='GROUP BY STATEID,STATE '
			SET @Strsql+='ORDER BY AVGORDVALUE DESC '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDWIDGET_REPORT(USERID,MODULENAME,RPTTYPE,SEQ,STATEID,STATE,TOTALORDVALUE) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''TOTALSALES'' AS MODULENAME,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY STATE) AS SEQ,STATEID,STATE,'
			SET @Strsql+='SUM(CONVERT(DECIMAL(18,2),ORDVALUE))/1000000 AS TOTALORDVALUE FROM ('
			SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			IF @STATEID<>''
				SET @Strsql+='ROW_NUMBER() OVER(ORDER BY ISNULL(ST.state,''State Undefined'')) AS SEQ,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			ELSE IF @STATEID=''
				SET @Strsql+='1 AS SEQ,0 AS STATEID,'''' AS STATE,'
			SET @Strsql+='SUM(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.ID) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_loginId,RPTTO.user_id,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
			IF @STATEID<>''
				SET @Strsql+=',ST.ID,ST.state '
			SET @Strsql+=') AS ORDVALUE '
			SET @Strsql+='GROUP BY STATEID,STATE '
			SET @Strsql+='ORDER BY TOTALORDVALUE DESC '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='INSERT INTO FTSDASHBOARDWIDGET_REPORT(USERID,MODULENAME,RPTTYPE,SEQ,STATEID,STATE,HIGHPERFORMSTATE) '
			SET @Strsql+='SELECT TOP 1 '+STR(@USERID)+' AS USERID,''BESTSTATE'' AS MODULENAME,''Summary'' AS RPTTYPE,ROW_NUMBER() OVER(ORDER BY SEQ) AS SEQ,STATEID,STATE,'
			SET @Strsql+='SUM(CONVERT(DECIMAL(18,2),ORDVALUE))/100000 AS TOTALORDVALUE FROM ('
			SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			IF @STATEID<>''
				SET @Strsql+='ROW_NUMBER() OVER(ORDER BY ISNULL(ST.state,''State Undefined'')) AS SEQ,ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			ELSE IF @STATEID=''
				SET @Strsql+='1 AS SEQ,ISNULL(ST.id,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,'
			SET @Strsql+='SUM(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND add_addressType=''Office'' '
			SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120)<=CONVERT(NVARCHAR(10),'''+@TODAYDATE+''',120) '
			IF @STATEID<>''
				SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.ID) '
			IF @HIERARCHY<>'A'
				SET @Strsql+='AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ST.id,ST.state,USR.user_loginId,RPTTO.user_id,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
			IF @STATEID<>''
				SET @Strsql+=',ST.ID,ST.state '
			SET @Strsql+=') AS ORDVALUE '
			SET @Strsql+='GROUP BY SEQ,STATEID,STATE '
			SET @Strsql+='ORDER BY TOTALORDVALUE DESC '
			--SELECT @Strsql
			EXEC (@Strsql)
	END
	
	DROP TABLE #TEMPCONTACT
	DROP TABLE #STATEID_LIST
END