IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTS_ReAssignShopToGroupBeat]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTS_ReAssignShopToGroupBeat] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTS_ReAssignShopToGroupBeat]
(
@ACTION NVARCHAR(MAX),
@USER_ID BIGINT=NULL,
@GroupBeat_ID BIGINT=NULL,
@OLD_GroupBeat BIGINT=NULL,
@NEW_GroupBeat BIGINT=NULL,
@FromDate NVARCHAR(10)=NULL,
@ToDate NVARCHAR(10)=NULL,
@ShopCodes NVARCHAR(MAX)=NULL
)  
AS
/******************************************************************************************************************************
1.0			Pratik		19-08-2022			create sp for ReAssign Group Beat
******************************************************************************************************************************/
BEGIN
	IF @ACTION='ShopReAssignUser'
	BEGIN
		DECLARE @sqlStrTable NVARCHAR(MAX),@OLDGroupBeat_NAME NVARCHAR(500),@NEWGroupBeat_NAME NVARCHAR(500)

		IF OBJECT_ID('tempdb..#TEMP_SHOPCODE') IS NOT NULL
		DROP TABLE #TEMP_SHOPCODE
		CREATE TABLE #TEMP_SHOPCODE	(SHOP_CODE NVARCHAR(100) collate SQL_Latin1_General_CP1_CI_AS )
		IF @ShopCodes<>''
		BEGIN
			set @ShopCodes = REPLACE(''''+@ShopCodes+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #TEMP_SHOPCODE select Shop_Code from tbl_Master_shop where Shop_Code in('+@ShopCodes+')  '  --AND Shop_CreateUser='''+@OLD_GroupBeat+''' AND Entity_Status=1
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		SET @OLDGroupBeat_NAME =(SELECT [NAME] FROM FSM_GROUPBEAT WHERE ID=@OLD_GroupBeat)
		SET @NEWGroupBeat_NAME =(SELECT [NAME] FROM FSM_GROUPBEAT WHERE ID=@NEW_GroupBeat)
		--INSERT INTO #TEMP_SHOPCODE
		--SELECT Shop_Code FROM tbl_Master_shop WHERE Shop_CreateUser=@OLD_GroupBeat AND Entity_Status=1
		

		--UPDATE TBL_MASTER_SHOP SET OLD_CreateUser=Shop_CreateUser,Shop_CreateUser=@NEW_GroupBeat,Shop_ModifyTime=GETDATE()
		--,LastUpdated_By=@GroupBeat_ID,LastUpdated_On=GETDATE()
		--WHERE SHOP_CODE IN (SELECT SHOP_CODE FROM #TEMP_SHOPCODE)
		UPDATE TBL_MASTER_SHOP 
		SET 
		beat_id=@NEW_GroupBeat
		WHERE SHOP_CODE IN (SELECT SHOP_CODE FROM #TEMP_SHOPCODE)

		INSERT INTO FTS_ShopReassignGroupBeatLog
		SELECT SHOP_CODE,@OLD_GroupBeat,@NEW_GroupBeat,@USER_ID,GETDATE() FROM #TEMP_SHOPCODE


		SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,TYP.Name AS Type,
		GETDATE() AS UPDATED_ON,FGB.[NAME] as GroupBeatName,FGB.CODE as GroupBeatCode,FGB.ID as GroupBeatId
		--,@OLDGroupBeat_NAME AS OLD_UserName,@NEWGroupBeat_NAME AS New_UserName
		FROM #TEMP_SHOPCODE tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type	
		INNER JOIN FSM_GROUPBEAT as FGB on SHOP.beat_id=FGB.ID

		DROP TABLE #TEMP_SHOPCODE
	END

	IF @ACTION='ShopReAssignUserLog'
	BEGIN
		
		SELECT SHOP.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,tmp.UPDATED_ON,TYP.Name AS Type,FGB.NAME as NEW_GROUPBEAT,OFGB.NAME as OLD_GROUPBEAT
		FROM FTS_ShopReassignGroupBeatLog tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN FSM_GROUPBEAT as FGB ON tmp.NEW_GroupBeat=FGB.ID
		INNER JOIN FSM_GROUPBEAT as OFGB ON tmp.OLD_GroupBeat=OFGB.ID
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type
		WHERE CAST(tmp.UPDATED_ON AS DATE) BETWEEN @FromDate AND @ToDate
		ORDER BY tmp.UPDATED_ON DESC
	END

	IF @ACTION='ReAssignShopList'
	BEGIN
		IF OBJECT_ID('tempdb..#TEMP_SHOPCODEList') IS NOT NULL
		DROP TABLE #TEMP_SHOPCODEList
		CREATE TABLE #TEMP_SHOPCODEList	(SHOP_CODE NVARCHAR(100) collate SQL_Latin1_General_CP1_CI_AS )

		--INSERT INTO #TEMP_SHOPCODEList
		--SELECT Shop_Code FROM tbl_Master_shop WHERE Shop_CreateUser=@GroupBeat_ID AND Entity_Status=1

		INSERT INTO #TEMP_SHOPCODEList
		SELECT Shop_Code FROM tbl_Master_shop as tms
		inner join FSM_GROUPBEAT as fgu on tms.beat_id=fgu.ID
		WHERE tms.BEAT_ID=@GroupBeat_ID
		--Shop_CreateUser=@GroupBeat_ID AND Entity_Status=1


		SELECT tmp.SHOP_CODE,SHOP.Shop_Name,SHOP.Shop_Owner,SHOP.Shop_Owner_Contact,SHOP.Address,
		DD.Shop_Name AS DD_NAME,PP.Shop_Name AS PP_NAME,TYP.Name AS Type,USR.user_name,USR.user_loginId
		--,FEM.[Name]
		FROM #TEMP_SHOPCODEList tmp
		INNER JOIN tbl_Master_shop SHOP ON tmp.SHOP_CODE=SHOP.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop DD ON SHOP.assigned_to_dd_id=DD.SHOP_CODE
		LEFT OUTER JOIN tbl_Master_shop PP ON SHOP.assigned_to_pp_id=PP.SHOP_CODE
		INNER JOIN tbl_shoptype TYP ON TYP.TypeId=SHOP.type
		INNER JOIN tbl_master_user USR ON USR.user_id=SHOP.Shop_CreateUser
		--INNER JOIN FSMEmployee_Master AS FEM ON USR.user_contactId=FEM.ContactID
		DROP TABLE #TEMP_SHOPCODEList
	END
END
