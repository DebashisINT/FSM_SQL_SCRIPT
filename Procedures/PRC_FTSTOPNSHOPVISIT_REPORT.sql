--EXEC PRC_FTSTOPNSHOPVISIT_REPORT 'API','2017-11-24','2018-11-29',0,'','Summary',378
--EXEC PRC_FTSTOPNSHOPVISIT_REPORT 'PORTAL','2017-11-24','2018-11-29',0,'','Summary',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTOPNSHOPVISIT_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTOPNSHOPVISIT_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTOPNSHOPVISIT_REPORT]
(
@MODULETYPE NVARCHAR(50)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@NOOFSHOP INT=0,
@SHOPCODE NVARCHAR(MAX)=NULL,
@ACTION NVARCHAR(50)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 30/11/2018
Module	   : TOP N Visit Shop
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#SHOP_LIST') AND TYPE IN (N'U'))
		DROP TABLE #SHOP_LIST
	CREATE TABLE #SHOP_LIST (Shop_Code NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @SHOPCODE <> ''
		BEGIN
			SET @SHOPCODE=REPLACE(@SHOPCODE,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #SHOP_LIST SELECT Shop_Code from tbl_Master_shop where Shop_Code in('+@SHOPCODE+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF @MODULETYPE='PORTAL' AND @ACTION IN('Summary','Detail')
		BEGIN
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSTOPNSHOPVISIT_REPORT') AND TYPE IN (N'U'))
			BEGIN
				CREATE TABLE FTSTOPNSHOPVISIT_REPORT
				(
				  USERID INT,
				  ACTION NVARCHAR(50),
				  MODULETYPE NVARCHAR(50),
				  SHOP_CODE NVARCHAR(MAX),
				  SHOP_NAME NVARCHAR(100) NULL,
				  OWNER_NAME NVARCHAR(300) NULL,
				  SHOP_VISITED INT,
				  ADDRESS NVARCHAR(MAX),
				  CONTACT_NO NVARCHAR(100),
				  VISITCNT INT
				)
				CREATE NONCLUSTERED INDEX IX1 ON FTSTOPNSHOPVISIT_REPORT (USERID)
			END
			DELETE FROM FTSTOPNSHOPVISIT_REPORT WHERE USERID=@USERID AND ACTION=@ACTION AND MODULETYPE=@MODULETYPE
		END

	SET @Strsql=''
	IF @MODULETYPE='API' AND @ACTION='Summary'
		BEGIN
			SET @Strsql='SELECT TOP 10 Shop_Code,shop_name,owner_name,shop_visited,address,contact_no,VISITCNT FROM( '
			SET @Strsql+='SELECT SHOP.Shop_Code,SHOP.Shop_Name AS shop_name,SHOP.Shop_Owner AS owner_name,COUNT(SHOPACT.total_visit_count) AS shop_visited,SHOP.Address AS address,'
			SET @Strsql+='SHOP.Shop_Owner_Contact AS contact_no,ROW_NUMBER() OVER(ORDER BY SUM(SHOPACT.total_visit_count) DESC) AS VISITCNT FROM tbl_Master_shop AS SHOP '
			SET @Strsql+='INNER JOIN tbl_trans_shopActivitysubmit SHOPACT ON SHOP.Shop_Code=SHOPACT.Shop_Id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			IF @SHOPCODE<>''
				SET @Strsql+='AND EXISTS (SELECT Shop_Code FROM #SHOP_LIST AS S WHERE S.Shop_Code=SHOP.Shop_Code) '
			SET @Strsql+='GROUP BY SHOP.Shop_Code,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Address,SHOP.Shop_Owner_Contact) TOPVISIT '
			SET @Strsql+='GROUP BY Shop_Code,shop_name,owner_name,shop_visited,address,contact_no,VISITCNT '
			SET @Strsql+='ORDER BY MAX(shop_visited) DESC '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @MODULETYPE='PORTAL'
		BEGIN
			SET @Strsql='INSERT INTO FTSTOPNSHOPVISIT_REPORT(USERID,ACTION,MODULETYPE,SHOP_CODE,SHOP_NAME,OWNER_NAME,SHOP_VISITED,ADDRESS,CONTACT_NO,VISITCNT) '
			SET @Strsql+='SELECT '+STR(@USERID)+' AS USERID,CASE WHEN '''+@ACTION+'''=''Summary'' THEN ''Summary'' ELSE ''Detail'' END AS ACTION,''PORTAL'' AS MODULETYPE,Shop_Code,shop_name,'
			SET @Strsql+='owner_name,shop_visited,address,contact_no,VISITCNT FROM( '
			SET @Strsql+='SELECT SHOP.Shop_Code,SHOP.Shop_Name AS shop_name,SHOP.Shop_Owner AS owner_name,COUNT(SHOPACT.total_visit_count) AS shop_visited,SHOP.Address AS address,'
			SET @Strsql+='SHOP.Shop_Owner_Contact AS contact_no,ROW_NUMBER() OVER(ORDER BY SUM(SHOPACT.total_visit_count) DESC) AS VISITCNT FROM tbl_Master_shop AS SHOP '
			SET @Strsql+='INNER JOIN tbl_trans_shopActivitysubmit SHOPACT ON SHOP.Shop_Code=SHOPACT.Shop_Id '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			IF @SHOPCODE<>''
				SET @Strsql+='AND EXISTS (SELECT Shop_Code FROM #SHOP_LIST AS S WHERE S.Shop_Code=SHOP.Shop_Code) '
			SET @Strsql+='GROUP BY SHOP.Shop_Code,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Address,SHOP.Shop_Owner_Contact) TOPVISIT '
			IF @NOOFSHOP<>0
				SET @Strsql+='WHERE TOPVISIT.VISITCNT<='+STR(@NOOFSHOP)+' '
			SET @Strsql+='GROUP BY Shop_Code,shop_name,owner_name,shop_visited,address,contact_no,VISITCNT '					
			SET @Strsql+='ORDER BY MAX(shop_visited) DESC '
			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	DROP TABLE #SHOP_LIST
END

