--- exec PRC_APIHierarchyWiseUser @user_id='11706', @ACTION='MEMBER',@area_id='',@isFirstScreen='true',@isAllTeam='true'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIHierarchyWiseUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIHierarchyWiseUser] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIHierarchyWiseUser]
(
@user_id BIGINT=NULL,
@ACTION NVARCHAR(MAX)=NULL,
@isFirstScreen NVARCHAR(MAX)=NULL,
@isAllTeam NVARCHAR(MAX)=NULL,
@area_id NVARCHAR(100)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		30-01-2020		Tanmoy		create sp
2.0		14-02-2020		Tanmoy		@ACTION='SHOPLIST' ADD NEW COLUMN SHOP TYPE
3.0		21-02-2020		Tanmoy		@ACTION='MEMBER' user_name get from tbl_master_contact
4.0		25-02-2020		Tanmoy		@ACTION='SHOPLIST' add column assigned_to_dd_id NAME
5.0		03-02-2020		Tanmoy		@ACTION='MEMBER' add column contact no
6.0		09-04-2020		Tanmoy		@ACTION='MEMBER' add (ME) AFTER PARENT NAME
7.0		11-05-2020		Tanmoy		@ACTION='SHOPLIST' add column Entity_Code
8.0		11-05-2020		Tanmoy		@ACTION='SHOPLIST' add EXTRA input Area_id
9.0		20-05-2020		Tanmoy		@ACTION='SHOPLIST' Active shop only List
10.0	11-06-2020		Tanmoy		@ACTION='SHOPLIST' add extra column
11.0	23-06-2020		Tanmoy		@ACTION='SHOPLIST' add extra column
****************************************************************************************************************************************************************************/
BEGIN
	 DECLARE @SQL NVARCHAR(MAX)
	 DECLARE @IsAdminExcludefromAllTeam VARCHAR(10)=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAdminExcludefromAllTeam')
	IF @ACTION='MEMBER'
	BEGIN
		--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		--		DROP TABLE #TEMPCONTACT
		--	CREATE TABLE #TEMPCONTACT
		--		(
		--			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		--			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		--			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		--			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		--			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		--			USER_ID	BIGINT NULL,
		--		)
		--	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
		--	INSERT INTO #TEMPCONTACT
		--	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,USR.user_id FROM TBL_MASTER_CONTACT CNT
		--	INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.CNT_INTERNALID  WHERE cnt_contactType IN('EM')

		--SELECT ISNULL(TEMP.cnt_firstName ,'')+' '+ISNULL(TEMP.cnt_middleName,'')+' '+ISNULL(TEMP.cnt_lastName,'') AS EMP_NAME,TEMP.USER_ID
		-- FROM #TEMPCONTACT TEMP
		--INNER JOIN (
		--SELECT user_id FROM dbo.Get_UserReporthierarchy (@user_id)) T ON T.user_id=TEMP.USER_ID

		--DROP TABLE #TEMPCONTACT

		IF(ISNULL(@isAllTeam,'false')='false')
		begin
		if(@isFirstScreen='true')
			begin


			select CAST(user_id AS NVARCHAR(10)) AS user_id,
			--Rev 3.0 Start
			ISNULL(CNT.cnt_firstName,'')+' '+ISNULL(CNT.cnt_middleName,'')+' '+ISNULL(CNT.cnt_lastName,'')+' ( Me )' AS user_name,cnt_internalId emp_cntId
			--5.0 start
			,user_loginId contact_no 
			--5.0 End
			from tbl_master_user usr
			LEFT OUTER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=usr.user_contactId
			--Rev 3.0 end
			where user_id =@user_id

			UNION ALL
			select CAST(user_id AS NVARCHAR(10)) AS user_id,
			--Rev 3.0 Start
			ISNULL(CNT.cnt_firstName,'')+' '+ISNULL(CNT.cnt_middleName,'')+' '+ISNULL(CNT.cnt_lastName,'') AS user_name,emp_cntId
			--5.0 start
			,contact_no 
			--5.0 End
			from View_Userhiarchy
			LEFT OUTER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=emp_cntId
			--Rev 3.0 end
			where reprtuserid =@user_id
			end
		else
			begin
			select CAST(user_id AS NVARCHAR(10)) AS user_id,
			--Rev 3.0 Start
			ISNULL(CNT.cnt_firstName,'')+' '+ISNULL(CNT.cnt_middleName,'')+' '+ISNULL(CNT.cnt_lastName,'') AS user_name,emp_cntId
			--5.0 start
			,contact_no 
			--5.0 End
			from View_Userhiarchy
			LEFT OUTER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=emp_cntId
			--Rev 3.0 end
			where reprtuserid =@user_id
			end
		end
		else
		begin
		if(@isFirstScreen='true')
			begin
			IF(isnull(@IsAdminExcludefromAllTeam,'0')='0')
			BEGIN
			
			select user_id,emp_cntId,user_name,contact_no from (
			select CAST(user_id AS NVARCHAR(10)) AS user_id,
			--Rev 3.0 Start
			--ISNULL(CNT.cnt_firstName,'')+' '+ISNULL(CNT.cnt_middleName,'')+' '+ISNULL(CNT.cnt_lastName,'') AS user_name,
			emp_cntId
			--5.0 start
			,RTRIM(LTRIM(
					CONCAT(
						LTRIM(COALESCE(CNT.cnt_firstName + ' ', ''))
						, LTRIM(COALESCE(CNT.cnt_middleName + ' ', ''))
						, COALESCE(CNT.cnt_lastName, '')
					)
				)) user_name
			,contact_no ,0 AS SL
			--5.0 End
			from View_ALLUserhiarchy
			LEFT OUTER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=emp_cntId  where user_id=@user_id
			UNION ALL						
			select CAST(user_id AS NVARCHAR(10)) AS user_id,
			--Rev 3.0 Start
			--ISNULL(CNT.cnt_firstName,'')+' '+ISNULL(CNT.cnt_middleName,'')+' '+ISNULL(CNT.cnt_lastName,'') AS user_name,
			emp_cntId
			--5.0 start
			,RTRIM(LTRIM(
					CONCAT(
						LTRIM(COALESCE(CNT.cnt_firstName + ' ', ''))
						, LTRIM(COALESCE(CNT.cnt_middleName + ' ', ''))
						, COALESCE(CNT.cnt_lastName, '')
					)
				)) user_name
			,contact_no ,1 AS SL
			--5.0 End
			from View_ALLUserhiarchy
			LEFT OUTER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=emp_cntId where user_id<>@user_id
			--Rev 3.0 end
			--where isnull(reprtuserid,0)=0
			) tbl order by SL
			end
			ELSE
			BEGIN
			select user_id,emp_cntId,user_name,contact_no from (
			select CAST(user_id AS NVARCHAR(10)) AS user_id,
			--Rev 3.0 Start
			--ISNULL(CNT.cnt_firstName,'')+' '+ISNULL(CNT.cnt_middleName,'')+' '+ISNULL(CNT.cnt_lastName,'') AS user_name,
			emp_cntId
			--5.0 start
			,RTRIM(LTRIM(
					CONCAT(
						LTRIM(COALESCE(CNT.cnt_firstName + ' ', ''))
						, LTRIM(COALESCE(CNT.cnt_middleName + ' ', ''))
						, COALESCE(CNT.cnt_lastName, '')
					)
				)) user_name
			,contact_no ,0 AS SL
			--5.0 End
			from View_ALLUserhiarchy
			LEFT OUTER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=emp_cntId  where user_id=@user_id
			UNION ALL						
			select CAST(user_id AS NVARCHAR(10)) AS user_id,
			--Rev 3.0 Start
			--ISNULL(CNT.cnt_firstName,'')+' '+ISNULL(CNT.cnt_middleName,'')+' '+ISNULL(CNT.cnt_lastName,'') AS user_name,
			emp_cntId
			--5.0 start
			,RTRIM(LTRIM(
					CONCAT(
						LTRIM(COALESCE(CNT.cnt_firstName + ' ', ''))
						, LTRIM(COALESCE(CNT.cnt_middleName + ' ', ''))
						, COALESCE(CNT.cnt_lastName, '')
					)
				)) user_name
			,contact_no ,1 AS SL
			--5.0 End
			from View_ALLUserhiarchy
			LEFT OUTER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=emp_cntId where user_id<>@user_id
			--Rev 3.0 end
			--where isnull(reprtuserid,0)=0
			) tbl 
			where user_id<>'378' order by SL
			END

			END


		else
			begin
			select CAST(user_id AS NVARCHAR(10)) AS user_id,
			--Rev 3.0 Start
			ISNULL(CNT.cnt_firstName,'')+' '+ISNULL(CNT.cnt_middleName,'')+' '+ISNULL(CNT.cnt_lastName,'') AS user_name,emp_cntId
			--5.0 start
			,contact_no 
			--5.0 End
			from View_ALLUserhiarchy
			LEFT OUTER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=emp_cntId
			--Rev 3.0 end
			where reprtuserid =@user_id
			end

		end
	END

	IF @ACTION='SHOPLIST'
	BEGIN

		SET @SQL=''
		SET @SQL+=' SELECT SHOP.Shop_Code AS shop_id,SHOP.Shop_Name AS shop_name,SHOP.Shop_Lat AS shop_lat,SHOP.Shop_Long AS shop_long,   '
		SET @SQL+=' SHOP.Address AS shop_address,SHOP.Pincode AS shop_pincode,SHOP.Shop_Owner_Contact AS shop_contact,   '
		SET @SQL+=' CONVERT(NVARCHAR(10),SHOP.total_visitcount) AS total_visited,   '
		SET @SQL+=' CONVERT(NVARCHAR(10),SHOP.Lastvisit_date,121) AS last_visit_date,  '
		SET @SQL+=' CONVERT(NVARCHAR(5),SHOP.type) AS shop_type,   '
		--Rev 4.0 Start
		SET @SQL+=' ISNULL(DD.Shop_Name,'''') as dd_name  '
		--Rev 4.0 End
		--Rev 7.0 Start
		SET @SQL+=' ,ISNULL(SHOP.EntityCode,'''') as entity_code   '
		--Rev 7.0 End 
		--Rev 10.0 Start
		set @sql+=' ,convert(nvarchar(10),SHOP.Model_id) as model_id,convert(nvarchar(10),SHOP.Primary_id) as primary_app_id,convert(nvarchar(10),SHOP.Secondary_id) as secondary_app_id   '
		set @sql+=' ,convert(nvarchar(10),SHOP.Lead_id) as lead_id,convert(nvarchar(10),SHOP.FunnelStage_id) as funnel_stage_id,convert(nvarchar(10),SHOP.Stage_id) as stage_id,SHOP.Booking_amount  '
		--Rev 10.0 End 
		--Rev 11.0 Start
		set @sql+=' ,convert(nvarchar(10),SHOP.PartyType_id) as type_id,convert(nvarchar(10),SHOP.Area_id) as area_id   '
		--Rev 11.0 End 
		SET @SQL+='  FROM tbl_Master_shop SHOP   '
		SET @SQL+='  LEFT OUTER JOIN tbl_Master_shop DD ON DD.Shop_Code=SHOP.assigned_to_dd_id   '
		SET @SQL+='  WHERE SHOP.Shop_CreateUser='''+STR(@user_id)+'''  '
		--REV 9.0 START
		SET @SQL+=' AND SHOP.Entity_Status=1	  '
		--REV 9.0 END
		IF ISNULL(@area_id,'')<>''
		SET @SQL+='  AND SHOP.Area_id='''+STR(@area_id)+'''  '


		EXEC SP_EXECUTESQL @SQL

	END
END