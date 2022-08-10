IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_UserListBind]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_UserListBind] AS' 
END
GO


--EXEC prc_UserListBind @ACTION='BINDUSERS',@userid=11706,@BRANCHID=1,@PARTY_TYPE=4
 
ALTER PROCEDURE [dbo].[prc_UserListBind]
 @userid int=null,
 @BRANCHID NVARCHAR(MAX)=null,
 @ACTION NVARCHAR(500)=NULL,
 @PARTY_TYPE INT=NULL,
 @SHOP_CODE NVARCHAR(100)=NULL,
 @Header_id BIGINT=NULL
 AS
 /***************************************************************************************************************************************
1.0		26-08-2021		Tanmoy		Column Name change
2.0		07/09/2021		Sanchita	v2.0.26		Assign Party with User facility required from user master.
												Refer: 0024309
3.0		20/09/2021		Sanchita	v2.0.25		System should allow to select a User for Multiple parties. Previous changes reverted.
4.0		05/10/2021		Sanchita	v2.0.26		Mantis issue 24362 and 24363
5.0		10-03-2022		Sanchita	V2.0.28		FSM Portal : A column required 'Associate ID' in User master Listing. Refer: 24740
6.0		11-04-2022		Swati	          	    In user master in Assign Party entry section in edit mode selected party not coming as checked Mantise Refer: 0024819
7.0		01-08-2022		Swati	    V2.0.32     branch details not fetch in assign party details edit mode in user master Refer:0025119
***************************************************************************************************************************************/
Begin
	--Rev 1.0
	--IF ((select IsDMSFeatureOn from tbl_master_user where user_id=@userid)=1)
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
	--End of Rev 1.0
	BEGIN
		DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@userid)		
		CREATE TABLE #EMPHR
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)

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

	IF @ACTION='BINDUSERLIST'
	BEGIN
		--Rev 1.0
		--IF ((select IsDMSFeatureOn from tbl_master_user where user_id=@userid)=1)
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		--End of Rev 1.0
		BEGIN

			SELECT  distinct user_id,user_name,user_loginId,case when  (user_inactive ='Y') then 'Inactive' else 'Active' end as Status,case when  (user_maclock ='Y') then 'Mac Restriction' else 'Mac Open' end as StatusMac,user_status as Onlinestatus,
			(select top 1  deg_designation from tbl_master_designation where deg_id in (select top 1 emp_Designation from tbl_trans_employeeCTC where emp_CntId= user_contactId order by emp_id desc )) as designation,
			isnull(cnt_firstName,'')+' '+isnull(cnt_middleName,'')+' '+isnull(cnt_lastName,'') as 'AssignedUser', (select branch_description from tbl_master_branch where branch_id=tbl_master_contact.cnt_branchid) as BranchName,grp_name
			-- Rev 5.0
			,cnt_UCC 'AssignedUserID'
			-- End of Rev 5.0
			FROM [tbl_master_user],tbl_master_employee,tbl_master_contact,tbl_master_usergroup,#EMPHR_EDIT
			where emp_ContactId=user_contactId  and cnt_InternalId=user_contactId and EMPCODE=cnt_internalId
			and user_group=grp_id  and user_branchId in (SELECT s FROM dbo.GetSplit(',',@BRANCHID))

			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END
		ELSE
		BEGIN
			SELECT  distinct user_id,user_name,user_loginId,case when  (user_inactive ='Y') then 'Inactive' else 'Active' end as Status,case when  (user_maclock ='Y') then 'Mac Restriction' else 'Mac Open' end as StatusMac,user_status as Onlinestatus,
			(select top 1  deg_designation from tbl_master_designation where deg_id in (select top 1 emp_Designation from tbl_trans_employeeCTC where emp_CntId= user_contactId order by emp_id desc )) as designation,
			isnull(cnt_firstName,'')+' '+isnull(cnt_middleName,'')+' '+isnull(cnt_lastName,'') as 'AssignedUser', (select branch_description from tbl_master_branch where branch_id=tbl_master_contact.cnt_branchid) as BranchName,grp_name
			-- Rev 5.0
			,cnt_UCC 'AssignedUserID'
			-- End of Rev 5.0
			FROM [tbl_master_user],tbl_master_employee,tbl_master_contact,tbl_master_usergroup
			where emp_ContactId=user_contactId  and cnt_InternalId=user_contactId
			and user_group=grp_id  and user_branchId in (SELECT s FROM dbo.GetSplit(',',@BRANCHID))
		END
	END

	ELSE IF @ACTION='BINDPARTY'
	BEGIN
		--Rev 1.0
		--IF ((select IsDMSFeatureOn from tbl_master_user where user_id=@userid)=1)
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		--End of Rev 1.0
		BEGIN
			SELECT SHP.Shop_Code,Shop_Name,Shop_Owner_Contact FROM tbl_Master_shop SHP
			INNER JOIN tbl_master_user USR ON SHP.Shop_CreateUser=USR.USER_ID
			INNER JOIN #EMPHR_EDIT ON user_contactId=EMPCODE
			WHERE type=@PARTY_TYPE 

			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END
		ELSE
		BEGIN
			SELECT SHP.Shop_Code,Shop_Name,Shop_Owner_Contact FROM tbl_Master_shop SHP
			INNER JOIN tbl_master_user USR ON SHP.Shop_CreateUser=USR.USER_ID
			WHERE type=@PARTY_TYPE
		END
	END
	ELSE IF @ACTION='BINDUSERS'
	BEGIN
		--Rev 1.0
		--IF ((select IsDMSFeatureOn from tbl_master_user where user_id=@userid)=1)
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		--End of Rev 1.0
		BEGIN
			SELECT user_id,user_name,user_loginId from tbl_master_user USR 
			INNER JOIN #EMPHR_EDIT ON user_contactId=EMPCODE 
			where USR.user_inactive='N'
			
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END
		ELSE
		BEGIN
			SELECT user_id,user_name,user_loginId from tbl_master_user where user_inactive='N'
		END
	END
	ELSE IF @ACTION='BindAllSelectedPartyList'
	BEGIN
		--Rev 1.0
		--IF ((select IsDMSFeatureOn from tbl_master_user where user_id=@userid)=1)
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		--End of Rev 1.0
		BEGIN
			SELECT map.ID,SHP.Shop_Code,Shop_Name,Shop_Owner_Contact AS Party_Contact,
			User_Name,user_loginId AS Login_ID,map.ASSIGN_ON AS CreationDate FROM FTS_EmployeeShopMap map
			INNER JOIN tbl_Master_shop SHP ON MAP.SHOP_CODE=SHP.Shop_Code
			INNER JOIN tbl_master_user USR ON map.USER_ID=USR.USER_ID
			INNER JOIN #EMPHR_EDIT TMP ON user_contactId=TMP.EMPCODE
			WHERE ASSIGN_BY=@userid
			
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END
		ELSE
		BEGIN
			SELECT map.ID,SHP.Shop_Code,Shop_Name,Shop_Owner_Contact AS Party_Contact,
			User_Name,user_loginId AS Login_ID,map.ASSIGN_ON AS CreationDate FROM FTS_EmployeeShopMap map
			INNER JOIN tbl_Master_shop SHP ON MAP.SHOP_CODE=SHP.Shop_Code
			INNER JOIN tbl_master_user USR ON map.USER_ID=USR.USER_ID
			WHERE ASSIGN_BY=@userid
		END
	END

	ELSE IF @ACTION='BindAssignParty'
	BEGIN		
		SELECT *,
		STUFF((SELECT ',' + SHP.Shop_Name FROM FTS_EmployeeShopMap map
		INNER JOIN tbl_Master_shop SHP ON MAP.SHOP_CODE=SHP.Shop_Code
		where map.Header_id=hd.ID
		group by SHP.Shop_Code,SHP.Shop_Name
			FOR XML PATH ('')), 1, 1, ''
            ) as Party
			FROM FTS_EmployeeShopMapHeader hd 
			WHERE CREATED_BY=@userid			
	END
	ELSE IF @ACTION='BindUserListNew'
	BEGIN	
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		BEGIN
			select convert(nvarchar(10),USR.user_id) as UserID,USR.user_name as username,
			convert(bit,0) AS selected
			from tbl_master_user USR 
			INNER JOIN #EMPHR_EDIT ON USR.user_contactId=EMPCODE
			where USR.user_inactive='N' 
			-- Rev 2.0
			--and not exists(select USER_ID from FTS_EMPLOYEESHOPMAP where USR.user_id=MAP.USER_ID)
			-- Rev 3.0
			--and not exists(select USER_ID from FTS_EMPLOYEESHOPMAP MAP where USR.user_id=MAP.USER_ID)
			-- End of Rev 3.0
			-- End of Rev 2.0
			-- Rev 4.0
			and user_branchId=@BRANCHID
			-- End of Rev 4.0
		end
		ELSE
		BEGIN
			select convert(nvarchar(10),USR.user_id) as UserID,USR.user_name as username,
			convert(bit,0) AS selected
			from tbl_master_user USR 
			where USR.user_inactive='N' 
			-- Rev 3.0
			--and not exists(select USER_ID from FTS_EMPLOYEESHOPMAP MAP where USR.user_id=MAP.USER_ID)
			-- End of Rev 3.0
			-- Rev 4.0
			and user_branchId=@BRANCHID
			-- End of Rev 4.0
		END
	END

	ELSE IF @ACTION='EditBindUserListNew'
	BEGIN	
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		BEGIN
			SELECT DISTINCT head.NAME,shp.Shop_Name,map.SHOP_CODE,map.SHOP_TYPE 
			--Rev work 7.0 start 01.08.2022
			,map.BranchCode
			--Rev work 7.0 close 01.08.2022
			FROM FTS_EmployeeShopMapHeader head
			inner join FTS_EMPLOYEESHOPMAP map on map.Header_id=head.ID
			inner join tbl_Master_shop shp on shp.Shop_Code=map.SHOP_CODE
			 WHERE head.ID=@Header_id

			select convert(nvarchar(10),USR.user_id) as UserID,USR.user_name as username,
			convert(bit,0) AS selected
			from tbl_master_user USR 
			INNER JOIN #EMPHR_EDIT ON USR.user_contactId=EMPCODE
			where USR.user_inactive='N' 
			and not exists(select USER_ID from FTS_EMPLOYEESHOPMAP MAP where USR.user_id=MAP.USER_ID)

			union all

			select DISTINCT convert(nvarchar(10),USR.user_id) as UserID,USR.user_name as username,
			convert(bit,1) AS selected
			from tbl_master_user USR 
			INNER JOIN #EMPHR_EDIT ON USR.user_contactId=EMPCODE
			INNER JOIN FTS_EMPLOYEESHOPMAP MAP ON USR.user_id=MAP.USER_ID
			where USR.user_inactive='N' AND MAP.Header_id=@Header_id

			-- Rev 4.0
			SELECT DISTINCT map.Shop_Code,shp.Shop_Name, convert(bit,1) AS selected FROM FTS_EmployeeShopMapHeader head
			inner join FTS_EMPLOYEESHOPMAP map on map.Header_id=head.ID
			inner join tbl_Master_shop shp on shp.Shop_Code=map.SHOP_CODE
			 WHERE head.ID=@Header_id
			-- End of Rev 4.0

			--Rev 6.0
			Select distinct  
			'input#chProductSource'+cast(ROW_NUMBER() OVER (PARTITION BY x.id ORDER BY x.id)as varchar(20))rowid,
			--ROW_NUMBER() OVER (PARTITION BY x.id ORDER BY x.id) id,
			x.NAME,x.Shop_Name,x.SHOP_CODE id,x.SHOP_TYPE
			from
			(
				SELECT DISTINCT 
				ROW_NUMBER() OVER (PARTITION BY shp.Shop_ID ORDER BY shp.Shop_ID)id,
				head.NAME,shp.Shop_Name,map.SHOP_CODE,map.SHOP_TYPE 
				FROM FTS_EmployeeShopMapHeader head
				inner join FTS_EMPLOYEESHOPMAP map on map.Header_id=head.ID
				inner join tbl_Master_shop shp on shp.Shop_Code=map.SHOP_CODE
				WHERE head.ID=@Header_id
			)x
			--End Rev 6.0

		end
		ELSE
		BEGIN
			SELECT DISTINCT head.NAME,shp.Shop_Name,map.SHOP_CODE,map.SHOP_TYPE 
			--Rev work 7.0 start 01.08.2022
			,map.BranchCode
			--Rev work 7.0 close 01.08.2022
			FROM FTS_EmployeeShopMapHeader head
			inner join FTS_EMPLOYEESHOPMAP map on map.Header_id=head.ID
			inner join tbl_Master_shop shp on shp.Shop_Code=map.SHOP_CODE
			 WHERE head.ID=@Header_id

			select convert(nvarchar(10),USR.user_id) as UserID,USR.user_name as username,
			convert(bit,0) AS selected
			from tbl_master_user USR 
			where USR.user_inactive='N' 
			and not exists(select USER_ID from FTS_EMPLOYEESHOPMAP MAP where USR.user_id=MAP.USER_ID)
			
			union all

			select DISTINCT convert(nvarchar(10),USR.user_id) as UserID,USR.user_name as username,
			convert(bit,1) AS selected
			from tbl_master_user USR 
			INNER JOIN FTS_EMPLOYEESHOPMAP MAP ON USR.user_id=MAP.USER_ID
			where USR.user_inactive='N' AND MAP.Header_id=@Header_id

			-- Rev 4.0
			SELECT DISTINCT map.Shop_Code,shp.Shop_Name, convert(bit,1) AS selected FROM FTS_EmployeeShopMapHeader head
			inner join FTS_EMPLOYEESHOPMAP map on map.Header_id=head.ID
			inner join tbl_Master_shop shp on shp.Shop_Code=map.SHOP_CODE
			 WHERE head.ID=@Header_id
			-- End of Rev 4.0

			--Rev 6.0
			Select distinct  
			'input#chProductSource'+cast(ROW_NUMBER() OVER (PARTITION BY x.id ORDER BY x.id)as varchar(20))rowid,
			--ROW_NUMBER() OVER (PARTITION BY x.id ORDER BY x.id) id,
			x.NAME,x.Shop_Name,x.SHOP_CODE id,x.SHOP_TYPE
			from
			(
				SELECT DISTINCT 
				ROW_NUMBER() OVER (PARTITION BY shp.Shop_ID ORDER BY shp.Shop_ID)id,
				head.NAME,shp.Shop_Name,map.SHOP_CODE,map.SHOP_TYPE 
				FROM FTS_EmployeeShopMapHeader head
				inner join FTS_EMPLOYEESHOPMAP map on map.Header_id=head.ID
				inner join tbl_Master_shop shp on shp.Shop_Code=map.SHOP_CODE
				WHERE head.ID=@Header_id
			)x
			--End Rev 6.0
		END
	END
END
GO