--EXEC prc_OutletListMapReport @Month='07',@Year='2022',@State='3',@PartyType='0',@PartyStatus=2

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_OutletListMapReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_OutletListMapReport] AS' 
END
GO

ALTER PROCEDURE [dbo].[prc_OutletListMapReport]
(
@State NVARCHAR(10)=NULL,
@PartyType NVARCHAR(10)=NULL,--SHOP TYPE
@PartyStatus NVARCHAR(10)=NULL,--ALL,NEW,RE-VISIT
@Month NVARCHAR(10),--MONTH ID
@Year NVARCHAR(10),
@CREATE_USERID BIGINT=NULL
) WITH ENCRYPTION
/****************************************************************************************************************************************************************************
1.0		v2.0.31		Debashis	07-07-2022		Optimization done.Refer: 0025028
****************************************************************************************************************************************************************************/
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @sqlStr NVARCHAR(MAX)
	--select TOP(1)Shop_Code,Shop_Name,Shop_Owner_Contact from tbl_trans_shopActivitysubmit ACTVTY
	--INNER JOIN tbl_Master_shop SHP ON ACTVTY.Shop_Id=SHP.Shop_Code
	-- where ACTVTY.Shop_Id='11708_1605365925571' ORDER BY ACTVTY.visited_time DESC

	-- SELECT * FROM tbl_trans_shopActivitysubmit

	--select * from tbl_trans_shopActivitysubmit_Archive

	--IF @PartyStatus='2'
	--BEGIN
	--	SET @PartyStatus=1,0
	--END
	DECLARE @from_Date NVARCHAR(10)
	DECLARE @to_Date NVARCHAR(10)

	--Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@CREATE_USERID)		
			IF OBJECT_ID('tempdb..#EMPHR') IS NOT NULL
				DROP TABLE #EMPHR
			CREATE TABLE #EMPHR
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			IF OBJECT_ID('tempdb..#EMPHR_EDIT') IS NOT NULL
				DROP TABLE #EMPHR_EDIT
			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
		
			INSERT INTO #EMPHR
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHR 
			where EMPCODE IS NULL OR EMPCODE=@empcode  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHR a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 

		END
	--End of Rev 2.0

	DECLARE @start_Date NVARCHAR(10)=@Year+'-'+@Month+'-01'
	DECLARE @end_Date date

	select @end_Date = cast(dateadd(dd,-(DAY(@start_Date )),DATEADD(mm,1,@start_Date ))as varchar(50))

	set @from_Date=@start_Date
	set @to_Date=convert(nvarchar(10),@end_Date,120)

	IF OBJECT_ID('tempdb..#SHOPVISITREVIST_COLUR') IS NOT NULL
		DROP TABLE #SHOPVISITREVIST_COLUR
	CREATE TABLE #SHOPVISITREVIST_COLUR
	(
	--Rev 1.0
	SEQ BIGINT,
	--End of Rev 1.0
	shop_code NVARCHAR(100),
	Shop_Name NVARCHAR(300),
	Shop_Owner NVARCHAR(300),
	Shop_Owner_Contact NVARCHAR(20),
	Address NVARCHAR(500),
	PARTYSTATUS nvarchar(100),
	Shop_CreateUser nvarchar(200),
	Shop_Lat NVARCHAR(MAX),
	Shop_Long NVARCHAR(MAX),
	State NVARCHAR(200),
	MAP_COLOR NVARCHAR(100),
	visitdate date,
	Is_Newshopadd int
	)
	--Rev 1.0
	CREATE NONCLUSTERED INDEX IX1 ON #SHOPVISITREVIST_COLUR (SEQ ASC)
	--End of Rev 1.0

	IF OBJECT_ID('tempdb..#SHOPTYPE') IS NOT NULL
		DROP TABLE #SHOPTYPE
	CREATE TABLE #SHOPTYPE
	(
	SP_TYPE NVARCHAR(10)
	)
	--Rev 1.0
	CREATE NONCLUSTERED INDEX IX1 ON #SHOPTYPE (SP_TYPE ASC)
	--End of Rev 1.0

	IF @PartyType='0'
	BEGIN
		INSERT INTO #SHOPTYPE
		SELECT shop_typeId FROM tbl_shoptype
		--Rev 1.0
		WHERE IsActive=1
		--End of Rev 1.0
	END
	ELSE
	BEGIN
		INSERT INTO #SHOPTYPE
		SELECT @PartyType
	END
	--Rev 1.0
	--declare @shop_code NVARCHAR(100)
	--DECLARE TMP_Cursor CURSOR FAST_FORWARD
	-- FOR select distinct Shop_Id from tbl_trans_shopActivitysubmit where convert(date,visited_date) between @start_Date and @end_Date
	--OPEN TMP_Cursor

	--FETCH NEXT FROM TMP_Cursor INTO @shop_code
	--WHILE @@FETCH_STATUS = 0  
	--BEGIN  

	IF OBJECT_ID('tempdb..#TMPSHOPLIST') IS NOT NULL
		DROP TABLE #TMPSHOPLIST
	CREATE TABLE #TMPSHOPLIST
	(Shop_Id NVARCHAR(100))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPSHOPLIST (Shop_Id ASC)

	INSERT INTO #TMPSHOPLIST(Shop_Id)
	SELECT DISTINCT Shop_Id FROM tbl_trans_shopActivitysubmit WHERE CONVERT(DATE,visited_date) BETWEEN @start_Date AND @end_Date
	--End of Rev 1.0
	SET @sqlStr=''
	--Rev 1.0
	--SET @sqlStr+=' INSERT INTO #SHOPVISITREVIST_COLUR '
	--SET @sqlStr+=' select TOP(1)Shop_Code,Shop_Name,Shop_Owner,Shop_Owner_Contact,Address,case when Is_Newshopadd=0 then ''New Visit'' when Is_Newshopadd=1 then ''Re-Visit'' end  AS PARTYSTATUS, '
	SET @sqlStr=' INSERT INTO #SHOPVISITREVIST_COLUR(seq,shop_code,Shop_Name,Shop_Owner,Shop_Owner_Contact,Address,PARTYSTATUS,Shop_CreateUser,Shop_Lat,Shop_Long,State,MAP_COLOR,visitdate,Is_Newshopadd) '
	SET @sqlStr+='SELECT ROW_NUMBER() OVER(ORDER BY ACTVTY.visited_time DESC) AS SEQ,Shop_Code,Shop_Name,Shop_Owner,Shop_Owner_Contact,Address,'
	SET @sqlStr+='CASE WHEN Is_Newshopadd=0 then ''New Visit'' when Is_Newshopadd=1 then ''Re-Visit'' end  AS PARTYSTATUS, '
	--End of Rev 1.0
	SET @sqlStr+=' USR.USER_NAME AS Shop_CreateUser,SHP.Shop_Lat,SHP.Shop_Long,ST.state, '
	SET @sqlStr+=' CASE WHEN Is_Newshopadd=1 AND Ordernottaken_Status=''Failure'' THEN ''Red''  '
	SET @sqlStr+=' WHEN Is_Newshopadd=1 AND Ordernottaken_Status=''Success'' THEN ''Orange'' ' 
	SET @sqlStr+=' WHEN Is_Newshopadd=0 AND Ordernottaken_Status=''Failure'' THEN ''Black'' '
	SET @sqlStr+=' WHEN Is_Newshopadd=0 AND Ordernottaken_Status=''Success'' THEN ''Green'' END AS COLORS,cast(visited_date as date),Is_Newshopadd '
	SET @sqlStr+='  from tbl_trans_shopActivitysubmit ACTVTY '
	SET @sqlStr+=' INNER JOIN tbl_Master_shop SHP ON ACTVTY.Shop_Id=SHP.Shop_Code '
	SET @sqlStr+=' INNER JOIN tbl_master_user USR ON USR.user_id=SHP.Shop_CreateUser '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
	BEGIN
		SET @sqlStr+=' INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE '
	END
	SET @sqlStr+=' INNER JOIN tbl_master_state ST ON ST.id=SHP.stateId '
	SET @sqlStr+='WHERE CONVERT(NVARCHAR(10),ACTVTY.visited_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@from_Date+''',120) AND CONVERT(NVARCHAR(10),'''+@to_Date+''',120) '
	--Rev 1.0
	--SET @sqlStr+='  and ACTVTY.Shop_Id='''+@shop_code+''' and SHOP_CODE!=''378_SHOP_1579677088132'' '
	SET @sqlStr+='  AND EXISTS(select Shop_Id from #TMPSHOPLIST where ACTVTY.Shop_Id=Shop_Id) '
	SET @sqlStr+='  and SHOP_CODE!=''378_SHOP_1579677088132'' '
	--End of Rev 1.0
	SET @sqlStr+='  AND EXISTS (SELECT TEMP.SP_TYPE FROM #SHOPTYPE TEMP WHERE SHP.type=TEMP.SP_TYPE) '
	SET @sqlStr+='  and SHP.stateId='''+@State+''' '--AND Is_Newshopadd IN (@PartyStatus)
		
	--IF @PartyStatus!=2
	--BEGIN
	--	SET @sqlStr+='  AND Is_Newshopadd ='+@PartyStatus+' '
	--END
	--Rev 1.0
	--SET @sqlStr+='  ORDER BY ACTVTY.visited_time DESC '
	--End of Rev 1.0
	--SELECT @sqlStr
	EXEC SP_EXECUTESQL @sqlStr
	-- UNION ALL

	-- select TOP(1)Shop_Code,Shop_Name,Shop_Owner,Shop_Owner_Contact,Address,NULL AS PARTYSTATUS,
	--USR.USER_NAME AS Shop_CreateUser,SHP.Shop_Lat,SHP.Shop_Long,ST.state,
	--CASE WHEN Is_Newshopadd=1 AND Ordernotkaten_Status='Failure' THEN 'Red' 
	--WHEN Is_Newshopadd=1 AND Ordernotkaten_Status='Success' THEN 'Orange' 
	--WHEN Is_Newshopadd=0 AND Ordernotkaten_Status='Failure' THEN 'Black' 
	--WHEN Is_Newshopadd=0 AND Ordernotkaten_Status='Success' THEN 'Green' END AS COLORS
	-- from tbl_trans_shopActivitysubmit_Archive ACTVTY
	--INNER JOIN tbl_Master_shop SHP ON ACTVTY.Shop_Id=SHP.Shop_Code
	--INNER JOIN tbl_master_user USR ON USR.user_id=SHP.Shop_CreateUser
	--INNER JOIN tbl_master_state ST ON ST.id=SHP.stateId
	-- where ACTVTY.Shop_Id=@shop_code and SHOP_CODE!='378_SHOP_1579677088132' ORDER BY ACTVTY.visited_time DESC

	--FETCH NEXT FROM TMP_Cursor INTO @shop_code
	--END
	--CLOSE TMP_Cursor  
	--DEALLOCATE TMP_Cursor 

	SET @sqlStr=''
	--Rev 1.0
	--SET @sqlStr+=' SELECT * FROM #SHOPVISITREVIST_COLUR '
	SET @sqlStr='SELECT shop_code,Shop_Name,Shop_Owner,Shop_Owner_Contact,Address,PARTYSTATUS,Shop_CreateUser,Shop_Lat,Shop_Long,State,MAP_COLOR,visitdate,Is_Newshopadd '
	SET @sqlStr+='FROM #SHOPVISITREVIST_COLUR '
	--SET @sqlStr+='ORDER BY SEQ '
	--End of Rev 1.0
	IF @PartyStatus!=2
	BEGIN
		SET @sqlStr+='  where Is_Newshopadd ='+@PartyStatus+' '
	END
	-- Rev 1.0
	SET @sqlStr+='ORDER BY SEQ '
	-- end of Rev 1.0

	EXEC SP_EXECUTESQL @sqlStr

	DROP TABLE #SHOPVISITREVIST_COLUR
	DROP TABLE #SHOPTYPE
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END
	--Rev 1.0
	DROP TABLE #TMPSHOPLIST
	
	SET NOCOUNT OFF
	--End of Rev 1.0
END