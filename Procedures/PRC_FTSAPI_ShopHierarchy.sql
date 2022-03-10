--EXEC PRC_FTSAPI_ShopHierarchy @user_id=11722,@area_id='',@SHOP_CODE=''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPI_ShopHierarchy]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPI_ShopHierarchy] AS' 
END
GO

ALTER PROC [dbo].[PRC_FTSAPI_ShopHierarchy] 
(
@SHOP_CODE NVARCHAR(100) =NULL,
@area_id NVARCHAR(100) =NULL,
@user_id BIGINT
) --WITH ENCRYPTION
AS  
/************************************************************************************************************************************************************************************************
1.0		V2.0.7		TANMOY		02-03-2020		CREATE SP 
2.0		V2.0.8		TANMOY		03-03-2020		shope details show empty
3.0				    TANMOY		11-05-2020		add column Entity_Code
4.0					TANMOY		15-05-2020		Add Extra search parameters @area_id
5.0					TANMOY		20-05-2020		ONLY ACTIVE SHOP show in  LIST
6.0					TANMOY		12-06-2020		Extar column show
7.0					TANMOY		23-06-2020		Extar column show
8.0		v2.0.27		Debashis	10-03-2022		New types are not coming in the All team view party section.Architect, fabricator,Consultant,Dealer,Builder,Corporate,Govt. Bodies,End User.
												Refer: 0024743
************************************************************************************************************************************************************************************************/ 
BEGIN
	 DECLARE @SHOP_TYPE NVARCHAR(10)
	 SET @SHOP_TYPE=(SELECT TYPE FROM tbl_Master_shop WHERE Shop_Code=@SHOP_CODE)
	 DECLARE @SQL NVARCHAR(MAX)

	 DECLARE @First_Id varchar(30) =''

	  IF OBJECT_ID('tempdb..#tMPFirst_Id') IS NOT NULL
		DROP TABLE #tMPFirst_Id
	CREATE TABLE #tMPFirst_Id(First_Id iNT)

		IF(ISNULL(@SHOP_CODE,'')='' and ISNULL(@area_id,'')<>'')
		BEGIN   	
		
			IF EXISTS(SELECT TOP(1)1 FROM tbl_Master_shop  WHERE type=2 AND Shop_CreateUser=@user_id  AND Area_id=ISNULL(@area_id,''))
			BEGIN
				--REV DEBASHIS
				--SET @First_Id='2'
				INSERT INTO #tMPFirst_Id VaLUeS(2)
				--END OF REV DEBASHIS
			END
			ELSE IF EXISTS(SELECT TOP(1)1 FROM tbl_Master_shop  WHERE type IN(4,6) AND Shop_CreateUser=@user_id  AND Area_id=ISNULL(@area_id,''))
			BEGIN
				--REV DEBASHIS
				--SET @First_Id='4,6'
				INSERT INTO #tMPFirst_Id VaLUeS(4)
				INSERT INTO #tMPFirst_Id VaLUeS(6)
				--END OF REV DEBASHIS
			END
			ELSE IF EXISTS (SELECT TOP(1)1 FROM tbl_Master_shop  WHERE type IN(1,3,5,7,8) AND Shop_CreateUser=@user_id AND Area_id=ISNULL(@area_id,''))
			BEGIN
				--REV DEBASHIS
				--SET @First_Id='1,3,5,7,8'
				INSERT INTO #tMPFirst_Id VaLUeS(1)
				INSERT INTO #tMPFirst_Id VaLUeS(3)
				INSERT INTO #tMPFirst_Id VaLUeS(5)
				INSERT INTO #tMPFirst_Id VaLUeS(7)
				INSERT INTO #tMPFirst_Id VaLUeS(8)
				--END OF REV DEBASHIS
			END
			--Rev 8.0
			ELSE IF EXISTS (SELECT TOP(1)1 FROM tbl_Master_shop  WHERE type IN(17,18,19,20,21,22,23,24) AND Shop_CreateUser=@user_id)
			BEGIN
				INSERT INTO #tMPFirst_Id VaLUeS(17)
				INSERT INTO #tMPFirst_Id VaLUeS(18)
				INSERT INTO #tMPFirst_Id VaLUeS(19)
				INSERT INTO #tMPFirst_Id VaLUeS(20)
				INSERT INTO #tMPFirst_Id VaLUeS(21)
				INSERT INTO #tMPFirst_Id VaLUeS(22)
				INSERT INTO #tMPFirst_Id VaLUeS(23)
				INSERT INTO #tMPFirst_Id VaLUeS(24)
			END
			--End of Rev 8.0
			ELSE
			BEGIN
				--REV DEBASHIS
				--SET @First_Id='0'
				INSERT INTO #tMPFirst_Id VaLUeS(0)
				--END OF REV DEBASHIS
			END
		
		END
		ELSE IF(ISNULL(@SHOP_CODE,'')='' and ISNULL(@area_id,'')='')
		BEGIN

			IF EXISTS(SELECT TOP(1)1 FROM tbl_Master_shop  WHERE type=2 AND Shop_CreateUser=@user_id)
			BEGIN
				--REV DEBASHIS
				--SET @First_Id='2'
				INSERT INTO #tMPFirst_Id VaLUeS(2)
				--END OF REV DEBASHIS
			END
			ELSE IF EXISTS(SELECT TOP(1)1 FROM tbl_Master_shop  WHERE type IN(4,6) AND Shop_CreateUser=@user_id)
			BEGIN
				--REV DEBASHIS
				--SET @First_Id='4,6'
				INSERT INTO #tMPFirst_Id VaLUeS(4)
				INSERT INTO #tMPFirst_Id VaLUeS(6)
				--END OF REV DEBASHIS
			END
			ELSE IF EXISTS (SELECT TOP(1)1 FROM tbl_Master_shop  WHERE type IN(1,3,5,7,8) AND Shop_CreateUser=@user_id)
			BEGIN
				--REV DEBASHIS
				--SET @First_Id='1,3,5,7,8'
				INSERT INTO #tMPFirst_Id VaLUeS(1)
				INSERT INTO #tMPFirst_Id VaLUeS(3)
				INSERT INTO #tMPFirst_Id VaLUeS(5)
				INSERT INTO #tMPFirst_Id VaLUeS(7)
				INSERT INTO #tMPFirst_Id VaLUeS(8)
				--END OF REV DEBASHIS
			END
			--Rev 8.0
			ELSE IF EXISTS (SELECT TOP(1)1 FROM tbl_Master_shop  WHERE type IN(17,18,19,20,21,22,23,24) AND Shop_CreateUser=@user_id)
			BEGIN
				INSERT INTO #tMPFirst_Id VaLUeS(17)
				INSERT INTO #tMPFirst_Id VaLUeS(18)
				INSERT INTO #tMPFirst_Id VaLUeS(19)
				INSERT INTO #tMPFirst_Id VaLUeS(20)
				INSERT INTO #tMPFirst_Id VaLUeS(21)
				INSERT INTO #tMPFirst_Id VaLUeS(22)
				INSERT INTO #tMPFirst_Id VaLUeS(23)
				INSERT INTO #tMPFirst_Id VaLUeS(24)
			END
			--End of Rev 8.0
			ELSE
			BEGIN
				--SET @First_Id='0'
				--REV DEBASHIS
				--SET @First_Id='0'
				INSERT INTO #tMPFirst_Id VaLUeS(0)
				--END OF REV DEBASHIS
			END
		END

		SET @SQL=''
		SET @SQL+=' SELECT SHOP.Shop_Code AS shop_id,SHOP.Shop_Name AS shop_name,SHOP.Shop_Lat AS shop_lat,SHOP.Shop_Long AS shop_long,SHOP.Address AS shop_address,  '
		SET @SQL+=' SHOP.Pincode AS shop_pincode,SHOP.Shop_Owner_Contact AS shop_contact,CONVERT(NVARCHAR(10),SHOP.total_visitcount) AS total_visited,CONVERT(NVARCHAR(10),SHOP.Lastvisit_date,121) AS last_visit_date,  '
		SET @SQL+=' CONVERT(NVARCHAR(10),SHOP.type) AS shop_type,ISNULL(dd.Shop_Name,'''') AS dd_name,SHOP.EntityCode as entity_code  '
		--Rev 6.0 Start
		set @SQL+=' ,convert(nvarchar(10),SHOP.Model_id) as model_id,convert(nvarchar(10),SHOP.Primary_id) as primary_app_id,convert(nvarchar(10),SHOP.Secondary_id) as secondary_app_id   '
		set @SQL+=' ,convert(nvarchar(10),SHOP.Lead_id) as lead_id,convert(nvarchar(10),SHOP.FunnelStage_id) as funnel_stage_id,convert(nvarchar(10),SHOP.Stage_id) as stage_id,SHOP.Booking_amount  '
		--Rev 6.0 End 
		--Rev 7.0 Start
		set @SQL+=' ,convert(nvarchar(10),SHOP.PartyType_id) as type_id,convert(nvarchar(10),SHOP.Area_id) as area_id   '
		--Rev 7.0 End 
		SET @SQL+='  FROM tbl_Master_shop SHOP  '
		SET @SQL+=' LEFT OUTER JOIN tbl_Master_shop DD ON DD.Shop_Code=SHOP.assigned_to_dd_id  '
		SET @SQL+=' WHERE SHOP.Entity_Status=1  '
		
		IF ISNULL(@SHOP_TYPE,'')='' AND ISNULL(@SHOP_CODE,'')='' --AND ISNULL(@area_id,'')=''
		BEGIN
			--REV DEBASHIS
			--SET @SQL+=' AND (SHOP.type IN ('+@First_Id+') AND SHOP.Shop_CreateUser='+STR(@user_id)+') '
			SET @SQL+=' AND (SHOP.type IN (SELECT First_Id FROM #tMPFirst_Id) AND SHOP.Shop_CreateUser='+STR(@user_id)+') '
			--END OF REV DEBASHIS
			--Hard code added for rollick only

			--REV DEBASHIS
			--IF(@First_Id=2)
			IF EXISTS (SELECT First_Id FROM #tMPFirst_Id WHERE First_Id=2)
			--END OF REV DEBASHIS
			BEGIN
				SET @SQL+=' OR SHOP.Shop_Code=''378_1578494646142'' '
			END
			--End Hard code added for rollick only
		END
		ELSE IF ISNULL(@SHOP_TYPE,'')='2' AND ISNULL(@SHOP_CODE,'')<>'' --AND ISNULL(@area_id,'')=''
			SET @SQL+=' AND SHOP.type=4 AND  SHOP.assigned_to_pp_id='''+@SHOP_CODE+''' AND SHOP.Shop_CreateUser='+STR(@user_id)+' '
		ELSE IF ISNULL(@SHOP_TYPE,'')='4' AND ISNULL(@SHOP_CODE,'')<>'' --AND ISNULL(@area_id,'')=''
			SET @SQL+=' AND SHOP.type=1 AND  SHOP.assigned_to_dd_id='''+@SHOP_CODE+''' AND SHOP.Shop_CreateUser='+STR(@user_id)+' '
		--Rev 2.0 Start
		ELSE IF ISNULL(@SHOP_TYPE,'')='1' AND ISNULL(@SHOP_CODE,'')<>'' --AND ISNULL(@area_id,'')=''
			SET @SQL+=' AND SHOP.type=0 AND  SHOP.Shop_Code='''+@SHOP_CODE+''' AND SHOP.Shop_CreateUser='+STR(@user_id)+' '
		--Rev 2.0 Start
		--IF ISNULL(@SHOP_TYPE,'')='' AND ISNULL(@SHOP_CODE,'')='' --AND ISNULL(@area_id,'')<>''
		--	SET @SQL+=' AND SHOP.type=2 AND SHOP.Shop_CreateUser='+STR(@user_id)+'  AND SHOP.Area_id='+STR(@area_id)+' '
		--ELSE IF ISNULL(@SHOP_TYPE,'')='2' AND ISNULL(@SHOP_CODE,'')<>'' AND ISNULL(@area_id,'')<>''
		--	SET @SQL+=' AND SHOP.type=4 AND  SHOP.assigned_to_pp_id='''+@SHOP_CODE+''' AND SHOP.Shop_CreateUser='+STR(@user_id)+' AND SHOP.Area_id='+STR(@area_id)+' '
		--ELSE IF ISNULL(@SHOP_TYPE,'')='4' AND ISNULL(@SHOP_CODE,'')<>'' AND ISNULL(@area_id,'')<>''
		--	SET @SQL+=' AND SHOP.type=1 AND  SHOP.assigned_to_dd_id='''+@SHOP_CODE+''' AND SHOP.Shop_CreateUser='+STR(@user_id)+' AND SHOP.Area_id='+STR(@area_id)+' '
		----Rev 2.0 Start
		--ELSE IF ISNULL(@SHOP_TYPE,'')='1' AND ISNULL(@SHOP_CODE,'')<>'' AND ISNULL(@area_id,'')<>''
		--	SET @SQL+=' AND SHOP.type=0 AND  SHOP.Shop_Code='''+@SHOP_CODE+''' AND SHOP.Shop_CreateUser='+STR(@user_id)+' AND SHOP.Area_id='+STR(@area_id)+' '
		if ISNULL(@area_id,'')<>''
		SET @SQL+=' AND SHOP.Area_id='+STR(@area_id)+''
		--Rev 2.0 Start

		EXEC SP_EXECUTESQL @SQL

	--SELECT @SQL

	DROP TABLE #tMPFirst_Id
END