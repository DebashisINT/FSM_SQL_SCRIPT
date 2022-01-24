--EXEC PRC_FTSSHOPCOLLECTION_REPORT '2017-11-24','2018-11-29',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSSHOPCOLLECTION_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSSHOPCOLLECTION_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSSHOPCOLLECTION_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 05/12/2018
Module	   : Shop Collection
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
	SET @Strsql+='SELECT DISTINCT SHOP.Shop_Code,SHOP.Shop_Name AS SHOPNAME,SHOP.Shop_Name+'',''+ST.state+'',''+SHOP.PINCODE AS SHOPNAMEADDR,SUM(ISNULL(COLLEC.COLLECAMT,0)) AS COLLECAMT FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
	--SET @Strsql+='INNER JOIN tbl_trans_shopActivitysubmit SHOPVISIT ON SHOPVISIT.User_Id=SHOP.Shop_CreateUser AND SHOPVISIT.User_Id=USR.user_id '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.ID=SHOP.stateId '
	--SET @Strsql+='INNER JOIN tbl_FTS_collection COLLEC ON COLLEC.shop_id=SHOP.Shop_Code AND COLLEC.USER_ID=USR.USER_ID '
	SET @Strsql+='INNER JOIN '
	SET @Strsql+='(SELECT shop_id,USER_ID,SUM(ISNULL(collection,0)) AS COLLECAMT FROM tbl_FTS_collection '
	SET @Strsql+='WHERE CONVERT(VARCHAR(10),collection_date,120) BETWEEN CONVERT(VARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(VARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY shop_id,USER_ID) COLLEC ON COLLEC.shop_id=SHOP.Shop_Code AND COLLEC.USER_ID=USR.USER_ID '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' AND RPTTO.user_id='+STR(@USERID)+' '
	--SET @Strsql+='AND CONVERT(VARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(VARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(VARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY SHOP.Shop_Code,SHOP.Shop_Name,ST.state,SHOP.PINCODE HAVING SUM(COLLEC.COLLECAMT)<>0 '
	SET @Strsql+=') AS SHOPCOLLECTION ORDER BY COLLECAMT DESC '
	--SELECT @Strsql
	EXEC (@Strsql)

	DROP TABLE #TEMPCONTACT
END