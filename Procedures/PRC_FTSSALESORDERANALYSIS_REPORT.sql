--EXEC PRC_FTSSALESORDERANALYSIS_REPORT '2018-04-01','2018-12-11','API','Summary',378
--EXEC PRC_FTSSALESORDERANALYSIS_REPORT '2018-04-01','2018-12-11','PORTAL','Summary',378
--EXEC PRC_FTSSALESORDERANALYSIS_REPORT '2018-04-01','2018-12-11','PORTAL','Detail',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSSALESORDERANALYSIS_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSSALESORDERANALYSIS_REPORT] AS'
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSSALESORDERANALYSIS_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@MODULE NVARCHAR(20)=NULL,
@ACTION NVARCHAR(20)=NULL,
@USERID INT 
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 11/12/2018
Module	   : Sales Order Analysis
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

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSSALESORDERANALYSIS_REPORT') AND TYPE IN (N'U'))
	BEGIN
		CREATE TABLE FTSSALESORDERANALYSIS_REPORT
		(
		  USERID INT,
		  SEQ INT,
		  ACTION NVARCHAR(20),
		  MODULE NVARCHAR(20),
		  USRID INT,
		  EMPCODE NVARCHAR(100) NULL,
		  EMPNAME NVARCHAR(300) NULL,
		  ORDDATE NVARCHAR(10) NULL,
		  SHOP_CODE NVARCHAR(300) NULL,
		  SHOP_NAME NVARCHAR(300) NULL,
		  ORDVALUE DECIMAL(18,2),
		  CONTACTNO NVARCHAR(100) NULL,
		  RPTTOUSERID NVARCHAR(100),
		  RPTTOID NVARCHAR(100),
		  RPTTOCODE NVARCHAR(100) NULL,
		  REPORTTO NVARCHAR(300) NULL		  
		)
		CREATE NONCLUSTERED INDEX IX1 ON FTSSALESORDERANALYSIS_REPORT (SEQ)
	END
	DELETE FROM FTSSALESORDERANALYSIS_REPORT WHERE USERID=@USERID AND ACTION=@ACTION

	SET @Strsql=''
	IF @MODULE='API' AND @ACTION='Summary'
		BEGIN
			SET @Strsql='SELECT USRID,EMPCODE,EMPNAME,CONVERT(DECIMAL(18,2),ORDVALUE) AS ORDVALUE,CONTACTNO,RPTTOUSERID,RPTTOID,RPTTOCODE,REPORTTO FROM ('
			SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='SUM(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_loginId,RPTTO.user_id,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
			SET @Strsql+=') AS ORDVALUE ORDER BY ORDVALUE DESC '
			--SELECT @Strsql
			EXEC (@Strsql)

			SET @Strsql=''
			SET @Strsql='SELECT SEQ,USRID,EMPCODE,EMPNAME,Orderdate,Shop_Code,Shop_Name,CONVERT(DECIMAL(18,2),ORDVALUE) AS ORDVALUE,RPTTOUSERID,RPTTOID,RPTTOCODE,REPORTTO FROM ('
			SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY EMP.emp_contactId,CAST(ORDHEAD.Orderdate AS DATE)) AS SEQ,USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
			SET @Strsql+='CAST(ORDHEAD.Orderdate AS DATE) AS Orderdate,SHOP.Shop_Code,SHOP.Shop_Name,SUM(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,'
			SET @Strsql+='RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
			SET @Strsql+='FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
			SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
			SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
			SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
			SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
			SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
			SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' AND RPTTO.user_id='+STR(@USERID)+' '
			SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ORDHEAD.Orderdate,SHOP.Shop_Code,SHOP.Shop_Name,RPTTO.user_id,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
			SET @Strsql+=') AS ORDVALUE ORDER BY SEQ '
			--SELECT @Strsql
			EXEC (@Strsql)
		END
	ELSE IF @MODULE='PORTAL'
		BEGIN
			IF @ACTION='Summary'
				BEGIN
					SET @Strsql='INSERT INTO FTSSALESORDERANALYSIS_REPORT(USERID,ACTION,MODULE,SEQ,USRID,EMPCODE,EMPNAME,ORDVALUE,CONTACTNO,RPTTOUSERID,RPTTOID,RPTTOCODE,REPORTTO) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''Summary'' AS ACTION,''PORTAL'' AS MODULE,ROW_NUMBER() OVER(ORDER BY CONVERT(DECIMAL(18,2),ORDVALUE) DESC) AS SEQ,'
					SET @Strsql+='USRID,EMPCODE,EMPNAME,CONVERT(DECIMAL(18,2),ORDVALUE) AS ORDVALUE,CONTACTNO,RPTTOUSERID,RPTTOID,RPTTOCODE,REPORTTO FROM ('
					SET @Strsql+='SELECT DISTINCT USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					SET @Strsql+='SUM(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
					SET @Strsql+='FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
					SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
					SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' AND RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,USR.user_loginId,RPTTO.user_id,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
					SET @Strsql+=') AS ORDVALUE ORDER BY ORDVALUE DESC '
					--SELECT @Strsql
					EXEC (@Strsql)
				END
			ELSE IF @ACTION='Detail'
				BEGIN
					SET @Strsql=''
					SET @Strsql='INSERT INTO FTSSALESORDERANALYSIS_REPORT(USERID,ACTION,MODULE,SEQ,USRID,EMPCODE,EMPNAME,ORDDATE,SHOP_CODE,SHOP_NAME,ORDVALUE,RPTTOUSERID,RPTTOID,RPTTOCODE,REPORTTO) '
					SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,''Detail'' AS ACTION,''PORTAL'' AS MODULE,SEQ,USRID,EMPCODE,EMPNAME,Orderdate,Shop_Code,Shop_Name,CONVERT(DECIMAL(18,2),ORDVALUE) AS ORDVALUE,RPTTOUSERID,RPTTOID,RPTTOCODE,REPORTTO FROM ('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY EMP.emp_contactId,CAST(ORDHEAD.Orderdate AS DATE)) AS SEQ,USR.user_id AS USRID,EMP.emp_contactId AS EMPCODE,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
					SET @Strsql+='CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,105) AS Orderdate,SHOP.Shop_Code,SHOP.Shop_Name,SUM(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE,RPTTO.user_id AS RPTTOUSERID,RPTTO.emp_reportTo AS RPTTOID,'
					SET @Strsql+='RPTTO.cnt_internalId AS RPTTOCODE,RPTTO.REPORTTO '
					SET @Strsql+='FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
					SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
					SET @Strsql+='INNER JOIN tbl_FTs_OrderdetailsProduct ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
					SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
					SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
					SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
					SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' AND RPTTO.user_id='+STR(@USERID)+' '
					SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='GROUP BY USR.user_id,EMP.emp_contactId,CNT.CNT_FIRSTNAME,CNT.CNT_MIDDLENAME,CNT.CNT_LASTNAME,ORDHEAD.Orderdate,SHOP.Shop_Code,SHOP.Shop_Name,RPTTO.user_id,RPTTO.emp_reportTo,RPTTO.cnt_internalId,RPTTO.REPORTTO '
					SET @Strsql+=') AS ORDVALUE ORDER BY SEQ '
					--SELECT @Strsql
					EXEC (@Strsql)
				END
		END

	DROP TABLE #TEMPCONTACT
END