IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_DASHBOARDPARTYDETAIL]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_DASHBOARDPARTYDETAIL] AS' 
END
GO
--exec PRC_DASHBOARDPARTYDETAIL  'GETLIST' ,11734
--exec PRC_DASHBOARDPARTYDETAIL  @ACTION='GETLISTSTATEWISE' ,@stateid='15'
--exec PRC_DASHBOARDPARTYDETAIL  @ACTION='GETLISTSTATEWISE' ,@stateid='15',@IS_Electician=0,@TYPE_Id=0,@CREATE_USERID=378,@PARTY_ID=0
--exec PRC_DASHBOARDPARTYDETAIL  @ACTION='GETLISTSTATEWISE' ,@stateid='15',@IS_Electician=0,@TYPE_Id=1
ALTER PROC [dbo].[PRC_DASHBOARDPARTYDETAIL]
(
@ACTION VARCHAR(500)=NULL,
@stateid VARCHAR(500)=NULL,
@USER_ID VARCHAR(500)=NULL,
@TYPE_ID VARCHAR(500)=NULL,
@PARTY_ID VARCHAR(500)=NULl,
@IS_Electician BIT=NULl,
@CREATE_USERID BIGINT=NULL
)
AS
/***********************************************************************************************************************
1.0			Tanmoy			19-08-2021			add hierarchy 
2.0		Sanchita	v2.0.39		10/02/2023		View Party' option shall be available in FSM Dashboard along with Dashboard Setting rights. 
												Refer: 25661
***********************************************************************************************************************/
BEGIN

	--Rev 1.0
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
	--End of Rev 1.0

	IF(@ACTION='GETLIST')
	BEGIN
		SELECT shop_code,Shop_Name, Address, Shop_Owner, isnull(Shop_Lat,'0') Shop_Lat,isnull(Shop_Long,'0') Shop_Long
		,Shop_Owner_Contact,PARTYSTATUS,isnuLL(MAP_COLOR,'D') MAP_COLOR,Shop_CreateUser FROM tbl_Master_shop
		left join FSM_PARTYSTATUS ON Party_Status_id=ID
		WHERE Shop_CreateUser=@USER_ID  
	END
	ELSE IF(@ACTION='GETLISTSTATEWISE')
	BEGIN

		DECLARE @str varchar(max)=''
		-- Rev 2.0
		if (@stateid <> '')
		begin
		-- End of Rev 2.0
			SET @str='SELECT shop_code,Shop_Name, ISNULL(Address,'''') Address, Shop_Owner, isnull(Shop_Lat,''0'') Shop_Lat,isnull(Shop_Long,''0'') Shop_Long
			,Shop_Owner_Contact,PARTYSTATUS,isnuLL(MAP_COLOR,''D'') MAP_COLOR,Shop_CreateUser,ISNULL(state,'''') state
			FROM tbl_Master_shop '
			--Rev 1.0
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
			BEGIN
				SET @str=@str+' INNER JOIN TBL_MASTER_USER USR ON tbl_Master_shop.Shop_CreateUser=USR.USER_ID '
				SET @str=@str+' INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE '
			END
			--End of Rev 1.0
			SET @str=@str+' left join FSM_PARTYSTATUS ON Party_Status_id=ID
			left join tbl_master_state s on s.id=stateid
			WHERE stateId=' + @stateid 		+' and Shop_Name<>''GPTPL'' and type <>2 and type<>10 and Shop_Name<>''Meeting'''
			IF ISNULL(@IS_Electician,0)=0
			BEGIN
				SET @str=@str+' AND type <>11  '
				IF (ISNULL(@TYPE_ID,0)<>0)
				BEGIN
					SET @str=@str+' AND (retailer_id =' +  @TYPE_ID + ' OR dealer_id='+ @TYPE_ID +')'
				END
				IF (ISNULL(@PARTY_ID,0)<>0)
				BEGIN
					SET @str=@str+' AND Party_Status_id =' +  @PARTY_ID 
				END
			END
			ELSE
			BEGIN
				SET @str=@str+' AND type =11'
			END
		-- Rev 2.0
		end
		-- End of Rev 2.0
--SELECT @str
EXEC (@str)
--SELECT @str
	END

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END

END
