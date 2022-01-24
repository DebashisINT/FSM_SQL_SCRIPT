--EXEC PRC_FTSTOPNSHOPORDER_REPORT '2018-04-01','2018-12-12',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTOPNSHOPORDER_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTOPNSHOPORDER_REPORT] AS'
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTOPNSHOPORDER_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@USERID INT 
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 12/12/2018
Module	   : Top N shops order wise
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
	SET @Strsql='SELECT TOP 10 SEQ,Shop_Code,ORDERCNT,Shop_Name,owner_name,shop_address,contact_no,CONVERT(DECIMAL(18,2),ORDVALUE) AS ORDVALUE FROM ('
	SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY SUM(ORDDET.ORDVALUE) DESC) AS SEQ,'
	SET @Strsql+='SHOP.Shop_Code,COUNT(ORDHEAD.OrderCode) AS ORDERCNT,SHOP.Shop_Name,SHOP.Shop_Owner AS owner_name,SHOP.Address AS shop_address,SHOP.Shop_Owner_Contact AS contact_no,SUM(ORDDET.ORDVALUE) AS ORDVALUE '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
	SET @Strsql+='INNER JOIN tbl_trans_fts_Orderupdate ORDHEAD ON ORDHEAD.Shop_Code=SHOP.Shop_Code AND ORDHEAD.userID=USR.user_id '
	SET @Strsql+='INNER JOIN (SELECT Order_ID,SUM(Product_Qty*Product_Rate) AS ORDVALUE FROM tbl_FTs_OrderdetailsProduct GROUP BY Order_ID) ORDDET ON ORDHEAD.OrderId=ORDDET.Order_ID '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,'
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='WHERE RPTTO.REPORTTO IS NOT NULL AND USR.user_inactive=''N'' AND RPTTO.user_id='+STR(@USERID)+' '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),ORDHEAD.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY SHOP.Shop_Code,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Address,SHOP.Shop_Owner_Contact '
	SET @Strsql+=') AS ORDVALRATIO ORDER BY SEQ '
	--SELECT @Strsql
	EXEC (@Strsql)

	DROP TABLE #TEMPCONTACT
END