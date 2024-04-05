IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FTS_VIEWGEOGRAPHY]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FTS_VIEWGEOGRAPHY] AS'  
END 
GO 

--exec FTS_VIEWGEOGRAPHY @ACTION='GETOUTLETLOCATION', @State='27,28,29,22,26,16,1,25,7,35,3,18,5,6,19,40,24,15',
--	@Branch='131',
--	@PartyType='1,2,3,4,5,6,7,8,11,99', @USER_ID=378


ALTER PROCEDURE [dbo].[FTS_VIEWGEOGRAPHY]
(
@ACTION VARCHAR(50)=NULL,
@USER_ID int=NULL,
@State NVARCHAR(MAX)=NULL,
@Branch NVARCHAR(MAX)=NULL,
@PartyType NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by Sanchita	20-03-2024		A new dashboard floating menu is required as "View Geography".. Refer: 27322
****************************************************************************************************************************************************************************/
BEGIN
	IF @ACTION='GETPARTYTYPE'
	BEGIN
		SELECT SHOP_TYPEID,NAME  FROM TBL_SHOPTYPE  WHERE ISACTIVE=1

	END
	IF @ACTION='GETOUTLETLOCATION'
	BEGIN
		DECLARE @sqlStr NVARCHAR(MAX)
		
		IF OBJECT_ID('tempdb..#STATE_LIST') IS NOT NULL
			DROP TABLE #STATE_LIST
		CREATE TABLE #STATE_LIST (State_Id BIGINT NULL)
		CREATE NONCLUSTERED INDEX State_Id ON #STATE_LIST (State_Id ASC)

		IF @State<>''
		BEGIN
			SET @sqlStr=''
			SET @State=REPLACE(@State,'''','')
			SET @sqlStr='INSERT INTO #STATE_LIST SELECT id FROM tbl_master_state WHERE id IN ('+@State+')'
			EXEC SP_EXECUTESQL @sqlStr
		END


		IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
			DROP TABLE #BRANCH_LIST
		CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
		CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

		IF @Branch<>''
		BEGIN
			SET @sqlStr=''
			SET @Branch=REPLACE(@Branch,'''','')
			SET @sqlStr='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@Branch+')'
			EXEC SP_EXECUTESQL @sqlStr
		END

		IF OBJECT_ID('tempdb..#PARTYTYPE_LIST') IS NOT NULL
			DROP TABLE #PARTYTYPE_LIST
		CREATE TABLE #PARTYTYPE_LIST (Shoptype_Id BIGINT NULL)
		CREATE NONCLUSTERED INDEX Shoptype_Id ON #PARTYTYPE_LIST (Shoptype_Id ASC)

		IF @PartyType<>''
		BEGIN
			SET @sqlStr=''
			SET @PartyType=REPLACE(@PartyType,'''','')
			SET @sqlStr='INSERT INTO #PARTYTYPE_LIST SELECT shop_typeId FROM tbl_shoptype WHERE shop_typeId IN ('+@PartyType+')'
			EXEC SP_EXECUTESQL @sqlStr
		END

		SET @sqlStr=''
		SET @sqlStr+='SELECT Shop_Name,Address, SHP.Shop_Lat,SHP.Shop_Long, SHP.type Shop_PartyId '
		SET @sqlStr+='  from tbl_master_shop SHP '
		SET @sqlStr+=' INNER JOIN tbl_master_user USR ON USR.user_id=SHP.Shop_CreateUser '
		IF @State<>''
			SET @sqlStr+='  INNER JOIN #STATE_LIST TMPST ON SHP.stateId=TMPST.State_Id '
		
		IF @Branch<>''
			SET @sqlStr+=' INNER JOIN #BRANCH_LIST TMPBR ON USR.user_branchid=TMPBR.Branch_Id '

		IF @PartyType<>''
			SET @sqlStr+=' INNER JOIN #PARTYTYPE_LIST TMPPT ON SHP.type=TMPPT.Shoptype_Id '
		
		SET @sqlStr+=' where SHP.Shop_Lat<>''0'' and SHP.Shop_Long<>''0'' and SHP.Shop_Lat not like ''%-%'' and SHP.Shop_Long not like ''%-%''	ORDER BY shop_code'
		
		---SELECT @sqlStr
		EXEC SP_EXECUTESQL @sqlStr

		DROP TABLE #STATE_LIST
		DROP TABLE #BRANCH_LIST
		DROP TABLE #PARTYTYPE_LIST
	END
End
GO