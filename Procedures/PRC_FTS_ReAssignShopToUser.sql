IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTS_ReAssignShopToUser]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTS_ReAssignShopToUser] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTS_ReAssignShopToUser]
(
@ACTION NVARCHAR(MAX),
@USER_ID BIGINT=NULL,
@OLD_USER BIGINT=NULL,
@NEW_USER BIGINT=NULL,
@FromDate NVARCHAR(10)=NULL,
@ToDate NVARCHAR(10)=NULL,
@ShopCodes NVARCHAR(MAX)=NULL
)  
AS
/******************************************************************************************************************************
1.0			Tanmoy		11-08-2020			create sp for ReAssign Shop
2.0			Tanmoy		20-08-2020			Add action 'ReAssignShopList'
3.0			Tanmoy		26-08-2020			Re-assign shop update modifytime
4.0			Sanchita	08-11-2022			Beat Column is required while Reassign the Party List. Refer: 25431
5.0			Sanchita	04-01-2022			A new feature required as "Re-assigned Area/Route/Beat. refer: 25545
6.0			Sanchita	13-01-2023			A new feature required as "Re-assigned Area/Route/Beat - Resolve reported issue. Refer: 25545
******************************************************************************************************************************/
BEGIN
	IF @ACTION='ShopReAssignUser'
	BEGIN
		DECLARE @sqlStrTable NVARCHAR(MAX),@OLDUSER_NAME NVARCHAR(500),@NEWUSER_NAME NVARCHAR(500)

		IF OBJECT_ID('tempdb..#TEMP_SHOPCODE') IS NOT NULL
		DROP TABLE #TEMP_SHOPCODE
		CREATE TABLE #TEMP_SHOPCODE	(SHOP_CODE NVARCHAR(100) collate SQL_Latin1_General_CP1_CI_AS )
		IF @ShopCodes<>''
		BEGIN
			set @ShopCodes = REPLACE(''''+@ShopCodes+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TEMP_SHOPCODE select Shop_Code from tbl_Master_shop where Shop_Code in('+@ShopCodes+')  '  --AND Shop_CreateUser='''+@OLD_USER+''' AND Entity_Status=1
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		SET @OLDUSER_NAME =(SELECT user_name FROM tbl_master_user WHERE user_id=@OLD_USER)
		SET @NEWUSER_NAME =(SELECT user_name FROM tbl_master_user WHERE user_id=@NEW_USER)
		--INSERT INTO #TEMP_SHOPCODE
		--SELECT Shop_Code FROM tbl_Master_shop WHERE Shop_CreateUser=@OLD_USER AND Entity_Status=1
		

		UPDATE TBL_MASTER_SHOP SET OLD_CreateUser=Shop_CreateUser,Shop_CreateUser=@NEW_USER,Shop_ModifyTime=GETDATE()
		,LastUpdated_By=@USER_ID,LastUpdated_On=GETDATE()
		WHERE SHOP_CODE IN (SELECT SHOP_CODE FROM #TEMP_SHOPCODE)

		INSERT INTO FTS_ShopReassignUserLog
		SELECT SHOP_CODE,@OLD_USER,@NEW_USER,@USER_ID,GETDATE() FROM #TEMP_SHOPCODE


		SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,TYP.Name AS Type,
		GETDATE() AS UPDATED_ON,@OLDUSER_NAME AS OLD_UserName,@NEWUSER_NAME AS New_UserName
		FROM #TEMP_SHOPCODE tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type	
		
		DROP TABLE #TEMP_SHOPCODE
	END

	IF @ACTION='ShopReAssignUserLog'
	BEGIN
		
		SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,tmp.UPDATED_ON,OLDUSR.user_name AS OLD_UserName,
		NEWUSR.user_name AS New_UserName,TYP.Name AS Type
		FROM FTS_ShopReassignUserLog tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN TBL_MASTER_USER OLDUSR ON OLDUSR.USER_ID=tmp.OLD_USER
		INNER JOIN TBL_MASTER_USER NEWUSR ON NEWUSR.USER_ID=tmp.NEW_USER
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type
		WHERE CAST(tmp.UPDATED_ON AS DATE) BETWEEN @FromDate AND @ToDate
		ORDER BY tmp.UPDATED_ON DESC
	END

	IF @ACTION='ReAssignShopList'
	BEGIN
		IF OBJECT_ID('tempdb..#TEMP_SHOPCODEList') IS NOT NULL
		DROP TABLE #TEMP_SHOPCODEList
		CREATE TABLE #TEMP_SHOPCODEList	(SHOP_CODE NVARCHAR(100) collate SQL_Latin1_General_CP1_CI_AS )

		INSERT INTO #TEMP_SHOPCODEList
		SELECT Shop_Code FROM tbl_Master_shop WHERE Shop_CreateUser=@USER_ID AND Entity_Status=1

		SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,TYP.Name AS Type,USR.user_name,USR.user_loginId
		-- Rev 4.0
		,isnull(BEAT.Name,'') as Beat
		-- End of Rev 4.0
		FROM #TEMP_SHOPCODEList tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type
		INNER JOIN tbl_master_user USR ON USR.user_id=SHOP.Shop_CreateUser
		-- Rev 4.0
		left outer join FSM_GROUPBEAT BEAT on SHOP.beat_id=BEAT.ID
		-- End of Rev 4.0	
		DROP TABLE #TEMP_SHOPCODEList
	END

	-- Rev 5.0
	IF @ACTION='ReAssignShopListForAreaRouteBeat'
	BEGIN
		IF OBJECT_ID('tempdb..#TEMP_SHOPCODEList_AreaRouteBeat') IS NOT NULL
		DROP TABLE #TEMP_SHOPCODEList_AreaRouteBeat
		CREATE TABLE #TEMP_SHOPCODEList_AreaRouteBeat	(SHOP_CODE NVARCHAR(100) collate SQL_Latin1_General_CP1_CI_AS )

		INSERT INTO #TEMP_SHOPCODEList_AreaRouteBeat
		SELECT Shop_Code FROM tbl_Master_shop WHERE Shop_CreateUser=@USER_ID AND Entity_Status=1

		SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,TYP.Name AS Type,USR.user_name,USR.user_loginId
		,isnull(BEAT.Name,'') as Beat, isnull(BEAT_AREA.NAME,'') as Area, isnull(BEAT_ROUTE.NAME,'') as Route  
		FROM #TEMP_SHOPCODEList_AreaRouteBeat tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type
		INNER JOIN tbl_master_user USR ON USR.user_id=SHOP.Shop_CreateUser
		left outer join FSM_GROUPBEAT BEAT on SHOP.beat_id=BEAT.ID
		left outer join FSM_GROUPBEAT BEAT_AREA on BEAT.AREA_CODE=BEAT_AREA.ID AND BEAT_AREA.CODE_TYPE='AREA'
		left outer join FSM_GROUPBEAT BEAT_ROUTE on beat.ROUTE_CODE=BEAT_ROUTE.ID AND BEAT_ROUTE.CODE_TYPE='ROUTE'
		DROP TABLE #TEMP_SHOPCODEList_AreaRouteBeat
	END

	IF @ACTION='ShopReAssignUser_ForAreaRouteBeat'
	BEGIN
		DECLARE @BEAD_ID bigint, @SHOP_CODE VARCHAR(100)

		SET @sqlStrTable =''
		SET @OLDUSER_NAME=''
		SET @NEWUSER_NAME =''

		IF OBJECT_ID('tempdb..#TEMP_SHOPCODE_AreaRouteBeat') IS NOT NULL
		DROP TABLE #TEMP_SHOPCODE_AreaRouteBeat
		CREATE TABLE #TEMP_SHOPCODE_AreaRouteBeat	(SHOP_CODE NVARCHAR(100) collate SQL_Latin1_General_CP1_CI_AS )
		IF @ShopCodes<>''
		BEGIN
			set @ShopCodes = REPLACE(''''+@ShopCodes+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TEMP_SHOPCODE_AreaRouteBeat select Shop_Code from tbl_Master_shop where Shop_Code in('+@ShopCodes+')  '  --AND Shop_CreateUser='''+@OLD_USER+''' AND Entity_Status=1
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		SET @OLDUSER_NAME = (SELECT user_name FROM tbl_master_user WHERE user_id=@OLD_USER)
		SET @NEWUSER_NAME = (SELECT user_name FROM tbl_master_user WHERE user_id=@NEW_USER)
		--INSERT INTO #TEMP_SHOPCODE_AreaRouteBeat
		--SELECT Shop_Code FROM tbl_Master_shop WHERE Shop_CreateUser=@OLD_USER AND Entity_Status=1
		
		UPDATE TBL_MASTER_SHOP SET OLD_CreateUser=Shop_CreateUser,Shop_CreateUser=@NEW_USER,Shop_ModifyTime=GETDATE()
		,LastUpdated_By=@USER_ID,LastUpdated_On=GETDATE()
		WHERE SHOP_CODE IN (SELECT SHOP_CODE FROM #TEMP_SHOPCODE_AreaRouteBeat)

		INSERT INTO FTS_ShopReassignUserLog
		SELECT SHOP_CODE,@OLD_USER,@NEW_USER,@USER_ID,GETDATE() FROM #TEMP_SHOPCODE_AreaRouteBeat

		DECLARE db_cursorSHOP_PARTY_MAP CURSOR FOR  
		Select SHOP_CODE FROM #TEMP_SHOPCODE_AreaRouteBeat --where name='HY4467'
		OPEN db_cursorSHOP_PARTY_MAP   
		FETCH NEXT FROM db_cursorSHOP_PARTY_MAP INTO @SHOP_CODE
		WHILE @@FETCH_STATUS = 0   
		BEGIN
			set @BEAD_ID = (SELECT TOP 1 BEAT_ID FROM TBL_MASTER_SHOP WHERE SHOP_CODE=@SHOP_CODE )

			-- Rev 6.0
			-- BEAT MAPPING WITH OLD PARTY WILL REMAIN 
			--IF EXISTS (SELECT * FROM FSM_GROUPBEAT_USERMAP WHERE BEAT_ID=@BEAD_ID AND USER_ID=@OLD_USER)
			--BEGIN
			--	DELETE FROM FSM_GROUPBEAT_USERMAP WHERE BEAT_ID=@BEAD_ID AND USER_ID=@OLD_USER
			--END
			-- End of Rev 6.0

			IF NOT EXISTS (SELECT * FROM FSM_GROUPBEAT_USERMAP WHERE BEAT_ID=@BEAD_ID AND USER_ID=@NEW_USER )
			BEGIN
				INSERT INTO FSM_GROUPBEAT_USERMAP (BEAT_ID,USER_ID) values(@BEAD_ID,@NEW_USER)
			END

		FETCH NEXT FROM db_cursorSHOP_PARTY_MAP INTO @SHOP_CODE
		end
		CLOSE db_cursorSHOP_PARTY_MAP   
		DEALLOCATE db_cursorSHOP_PARTY_MAP

		--SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		--DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,TYP.Name AS Type,
		--GETDATE() AS UPDATED_ON,@OLDUSER_NAME AS OLD_UserName,@NEWUSER_NAME AS New_UserName
		--FROM #TEMP_SHOPCODE_AreaRouteBeat tmp
		--INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		--LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		--LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		--INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type	

		SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,tmp.UPDATED_ON,OLDUSR.user_name AS OLD_UserName,
		NEWUSR.user_name AS New_UserName,TYP.Name AS Type
		,isnull(BEAT.Name,'') as Beat, isnull(BEAT_AREA.NAME,'') as Area, isnull(BEAT_ROUTE.NAME,'') as Route 
		FROM FTS_ShopReassignUserLog tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN TBL_MASTER_USER OLDUSR ON OLDUSR.USER_ID=tmp.OLD_USER
		INNER JOIN TBL_MASTER_USER NEWUSR ON NEWUSR.USER_ID=tmp.NEW_USER
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type
		left outer join FSM_GROUPBEAT BEAT on SHOP.beat_id=BEAT.ID
		left outer join FSM_GROUPBEAT BEAT_AREA on BEAT.AREA_CODE=BEAT_AREA.ID AND BEAT_AREA.CODE_TYPE='AREA'
		left outer join FSM_GROUPBEAT BEAT_ROUTE on beat.ROUTE_CODE=BEAT_ROUTE.ID AND BEAT_ROUTE.CODE_TYPE='ROUTE'
		WHERE CAST(tmp.UPDATED_ON AS DATE) = convert(date,getdate())
		ORDER BY tmp.UPDATED_ON DESC

		
		DROP TABLE #TEMP_SHOPCODE_AreaRouteBeat
	END

	IF @ACTION='ShopReAssignUserLog_AreaRouteBeat'
	BEGIN
		
		SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,tmp.UPDATED_ON,OLDUSR.user_name AS OLD_UserName,
		NEWUSR.user_name AS New_UserName,TYP.Name AS Type
		,isnull(BEAT.Name,'') as Beat, isnull(BEAT_AREA.NAME,'') as Area, isnull(BEAT_ROUTE.NAME,'') as Route 
		FROM FTS_ShopReassignUserLog tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN TBL_MASTER_USER OLDUSR ON OLDUSR.USER_ID=tmp.OLD_USER
		INNER JOIN TBL_MASTER_USER NEWUSR ON NEWUSR.USER_ID=tmp.NEW_USER
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type
		left outer join FSM_GROUPBEAT BEAT on SHOP.beat_id=BEAT.ID
		left outer join FSM_GROUPBEAT BEAT_AREA on BEAT.AREA_CODE=BEAT_AREA.ID AND BEAT_AREA.CODE_TYPE='AREA'
		left outer join FSM_GROUPBEAT BEAT_ROUTE on beat.ROUTE_CODE=BEAT_ROUTE.ID AND BEAT_ROUTE.CODE_TYPE='ROUTE'
		WHERE CAST(tmp.UPDATED_ON AS DATE) BETWEEN @FromDate AND @ToDate
		ORDER BY tmp.UPDATED_ON DESC
	END
	-- End of Rev 5.0
END
