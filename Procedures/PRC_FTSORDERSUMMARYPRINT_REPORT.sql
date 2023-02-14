--EXEC PRC_FTSORDERSUMMARYPRINT_REPORT '','','','Details',467,'P'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSORDERSUMMARYPRINT_REPORT]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSORDERSUMMARYPRINT_REPORT] AS'  
 END 
 GO 

ALTER PROCEDURE [dbo].[PRC_FTSORDERSUMMARYPRINT_REPORT]
(
@COMPANYID NVARCHAR(20),
@FINYEAR NVARCHAR(12),
@FULLPATH NVARCHAR(100),
@TABLENAME NVARCHAR(50),
@ORDID NVARCHAR(MAX),
@ISCREATEORPREVIEW NVARCHAR(1)
) WITH ENCRYPTION
AS
/*****************************************************************************************************************************************************************************************************
Written By : Pratik Ghosh On 15/06/2022
Purpose : For Sales Order Print.Refer: 24944
1.0		v2.0.30		Debashis	27/06/2022	Amount in Word showing wrong.Now solved.
2.0	    v2.0.39		PRITI 	    07/02/2023	0025604:Enhancement Required in the Order Summary Report
******************************************************************************************************************************************************************************************************/
BEGIN
    SET NOCOUNT ON
    DECLARE @StrSql AS NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_id INT,
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT (cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_id,cnt_internalId, cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType='TM'

	IF @ORDID<>''
        SET @ORDID=REPLACE(@ORDID,'''','')

	SET @StrSql=''
	
	IF @TABLENAME='Header'
		BEGIN
			IF @ISCREATEORPREVIEW='L'
				BEGIN
					SET @StrSql='SELECT 0 AS Id,'''' Shop_Code,'''' Shop_Name,'''' as Orderdate,'''' AS OrderCode,'''' AS Address,'''' AS Shop_Owner_Contact '
					SET @StrSql+=','''' AS EmployeeName '
					SET @StrSql+='FROM tbl_trans_fts_Orderupdate as ordhd '
				END
			ELSE IF @ISCREATEORPREVIEW='P'
				BEGIN
					SET @StrSql='select ordhd.OrderId AS Id,shp.Shop_Code,shp.Shop_Name '
					SET @StrSql+=',(CONVERT(NVARCHAR(10),ordhd.Orderdate,105)+'' ''+CONVERT(NVARCHAR(10),ordhd.Orderdate,108)) as Orderdate,ordhd.OrderCode,shp.Address,shp.Shop_Owner_Contact '
					SET @StrSql+=',ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EmployeeName '
					SET @StrSql+='from tbl_trans_fts_Orderupdate as ordhd '
					SET @StrSql+='INNER JOIN tbl_Master_shop as shp on shp.Shop_Code=ordhd.Shop_code '
					SET @StrSql+='INNER JOIN tbl_master_user usr on shp.Shop_CreateUser=usr.user_id '
					SET @StrSql+='INNER JOIN tbl_master_contact CNT on CNT.cnt_internalId=usr.user_contactId '
					SET @StrSql+='where ordhd.OrderId IN ('+@ORDID+') '
				END
		END
	ELSE IF @TABLENAME='Details'
		BEGIN
			IF @ISCREATEORPREVIEW='L'
				BEGIN
					SET @StrSql='SELECT 0 AS SEQ,Order_ProdId,0 AS sProducts_ID,'''' AS sProducts_Code,'''' AS sProducts_Description,'''' AS sProducts_Name,Product_Id,0.00 AS Product_Qty,0.00 AS Product_Rate,0.00 AS Product_Price,'''' AS Shop_code,'''' AS Shop_Name,'''' AS sProducts_Name,'
					SET @StrSql+='0 AS relation_Id,0.00 AS MRP,'''' AS Orderdate,'''' AS OrderCode,0 AS Address,'''' AS Shop_Owner_Contact,'''' AS EmployeeName,'''' AS AmountInWords '
					--Rev 2.0
					SET @StrSql+=',0.00 AS ORDER_MRP,0.00 AS ORDER_DISCOUNT '
					--Rev 2.0 End
					SET @StrSql+='FROM tbl_FTs_OrderdetailsProduct ordprod '
				END
			ELSE IF @ISCREATEORPREVIEW='P'
				BEGIN
					SET @StrSql='select ROW_NUMBER() OVER(ORDER BY Order_ProdId DESC) AS SEQ,Order_ProdId,mprod.sProducts_ID,mprod.sProducts_Code,sProducts_Description,sProducts_Name '
					SET @StrSql+=',Product_Id,Product_Qty,Product_Rate,Product_Price,ordprod.Shop_code,shp.Shop_Name,mprod.sProducts_Name,Order_ID AS relation_Id,MRP '
					SET @StrSql+=',(CONVERT(NVARCHAR(10),ordhd.Orderdate,105)+'' ''+CONVERT(NVARCHAR(10),ordhd.Orderdate,108)) as Orderdate,ordhd.OrderCode '
					SET @StrSql+=',shp.Address,shp.Shop_Owner_Contact '
					SET @StrSql+=',ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EmployeeName '
					--Rev 1.0
					--SET @StrSql+=',(select  dbo.[FN_AmountInWords]((SELECT SUM(ISNULL(Product_Price,0)) from tbl_FTs_OrderdetailsProduct where Order_ID='+@ORDID+'),0 ) ) AS AmountInWords '
					SET @StrSql+=',(select  dbo.[FN_AmountInWords]((SELECT SUM(ISNULL(Product_Price,0)) from tbl_FTs_OrderdetailsProduct where Order_ID='+@ORDID+'),@@NESTLEVEL)) AS AmountInWords '
					--End of Rev 1.0
					--Rev 2.0
					SET @StrSql+=',ISNULL(ordprod.ORDER_MRP,0)ORDER_MRP,ISNULL(ordprod.ORDER_DISCOUNT,0)ORDER_DISCOUNT '
					--Rev 2.0 End
					SET @StrSql+='from tbl_FTs_OrderdetailsProduct as ordprod '
					SET @StrSql+='inner join Master_sProducts as mprod on ordprod.Product_Id=mprod.sProducts_ID '
					SET @StrSql+='inner join tbl_Master_shop as shp on shp.Shop_Code=ordprod.Shop_code '
					SET @StrSql+='inner join tbl_trans_fts_Orderupdate as ordhd on ordhd.OrderId=ordprod.Order_ID '
					SET @StrSql+='INNER JOIN tbl_master_user usr on shp.Shop_CreateUser=usr.user_id '
					SET @StrSql+='INNER JOIN tbl_master_contact CNT on CNT.cnt_internalId=usr.user_contactId '
					SET @StrSql+='where ordhd.OrderId IN('+@ORDID+') '
				END
		END
	ELSE IF @TABLENAME='CompanyMaster'
        BEGIN
            SET @StrSql='select c.*,(cmp_bigLogo+'''+@FULLPATH+''') as Upload_Picture,Upper(c.cmp_Name) as upper_CompanyName,phone=(select top 1 phf_phoneNumber from tbl_master_phonefax where phf_cntId=c.cmp_internalid),email=(select top 1 eml_email from tbl_master_email where eml_cntId=c.cmp_internalid)  ,
            (case when ISNULL(a.add_address1,'''')<>'''' then ISNULL(a.add_address1,'''') +'', '' ELSE '''' END) +(case when ISNULL(a.add_address2,'''')<>'''' then ISNULL(a.add_address2,'''') +'', '' ELSE '''' END)+(case when ISNULL(a.add_address3,'''')<>'''' then ISNULL(a.add_address3,'''') +'', '' ELSE '''' END)+case when (select ISNULL(city_name,'''') from tbl_master_city  
            where city_id=a.add_city)<>'''' then (select ISNULL(city_name,'''') from tbl_master_city where city_id=a.add_city)+''-''+(select pin_code from tbl_master_pinzip where pin_id=a.add_pin)+''.'' 
            else '''' end as ''Address'',
            (select city_name from tbl_master_city where city_id=a.add_city)as add_city,(select pin_code from tbl_master_pinzip where pin_id=a.add_pin) as add_pin  
            from tbl_master_company c  left join tbl_master_address a on c.cmp_internalid=a.add_cntId where c.cmp_internalid='''+@COMPANYID+''' '
        END

	--SELECT @StrSql 
    EXEC (@StrSql)

	DROP TABLE #TEMPCONTACT

	SET NOCOUNT OFF
END