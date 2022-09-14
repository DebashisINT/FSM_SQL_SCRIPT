--exec SP_API_Getshoplists_Report @Shoptype='2,4',@Weburl='',@StateId='',@Action='Counter',@Create_UserId=378,@Shnm='Prime Partner,Distributor'
--exec SP_API_Getshoplists_Report @Shoptype='5',@Weburl='',@StateId='',@Action='Counter',@Create_UserId=378,@Shnm='Show All'
--EXEC SP_API_Getshoplists_Report @Action='Counter',@Shoptype='1',@user_id=378,@Weburl=''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SP_API_Getshoplists_Report]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [SP_API_Getshoplists_Report] AS' 
END
GO

ALTER PROCEDURE [dbo].[SP_API_Getshoplists_Report]
(
@user_id varchar(50)=NULL,
@session_token varchar(MAX)=NULL,
@Uniquecont int=NULL,
@Weburl varchar(MAX)=NULL,
@FromDate varchar(MAX)=NULL,
@Todate varchar(MAX)=NULL,
@Action varchar(100)=NULL,
@shopid  varchar(50)=NULL,
@address varchar(MAX)=NULL,
@pincode varchar(MAX)=NULL,
@shopname varchar(MAX)=NULL,
@ownername varchar(MAX)=NULL,
@ownercontact varchar(MAX)=NULL,
@owneremail varchar(MAX)=NULL,
@dob varchar(MAX)=NULL,
@doanniversary varchar(MAX)=NULL,
@StateId varchar(MAX)=NULL,
@Shoptype varchar(MAX)=NULL,
@AssignTo varchar(100)=NULL,
@Create_UserId int=NULL,
--Rev 10.0
@BRANCHID NVARCHAR(MAX)=NULL
--End of Rev 10.0
) --WITH ENCRYPTION
AS
/*================================================================================================================================================================
1.0					Tanmoy		30-07-2019     change left outer join to inner join
2.0		v2.0.11		Debashis	12/05/2020		FTS reports with more fields.Refer: 0022323
3.0					TANMOY		28/07/2021		employee hierarchy on Settings
4.0		v2.0.26		Debashis	12/01/2022		District/Cluster/Pincode fields are required in some of the reports.Refer: 0024575
5.0		v2.0.26		Debashis	13/01/2022		Sub Type field required in some of the reports.Refer: 0024576
6.0		v2.0.26		Debashis	13/01/2022		Alternate phone no. 1 & alternate email fields are required in some of the reports.Refer: 0024577
7.0					Swatilekha	16/06/2022		Show All checkbox required for Shops report in fsm Refer: 24948
8.0					Swatilekha	30/06/2022		GSTIN & Trade License number field required in Listing of Master - Shops Report in fsm Refer: 0024573
9.0		v2.0.31		Debashis	08/07/2022		While trying to generate the "Shops" report by selecting the type as "Dealer" in the National Plastic, 
												the system is getting logged out.Now it has been taken care of.Refer: 0025031
10.0	v2.0.32		Debashis	14/09/2022		Branch selection option is required on various reports.Refer: 0025198
==================================================================================================================================================================*/
BEGIN
	SET NOCOUNT ON

	DECLARE @sql nvarchar(MAX)=''
	DECLARE @topcount nvarchar(100)=@Uniquecont
	DECLARE @ReportTABLE Table(userid int,userreport int)
	--Rev 10.0
	DECLARE @SqlTable NVARCHAR(MAX)
	--End of Rev 10.0

	--if(isnull(@user_id,'')<>'')
	--BEGIN
	--insert into  @ReportTABLE


	--select @user_id as user_id,@user_id as reprtuserid 

	--union
	--select  user_id,reprtuserid  from dbo.[Get_UserReporthierarchy](@user_id)


	--order by user_id

	--END
	--Rev 10.0
	IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
		DROP TABLE #BRANCH_LIST
	CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

	IF @BRANCHID<>''
		BEGIN
			SET @SqlTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @SqlTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @SqlTable
		END
	--End of Rev 10.0
	--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Create_UserId)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@Create_UserId)		
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
		--End of Rev 3.0
	IF(@Action='ShopDetails')
		BEGIN
			IF(isnull(@Uniquecont,0)<>0)
				BEGIN
					SET @sql='SELECT TOP  '+@topcount+' cast(Shop_ID as varchar(50)) as shop_Auto,Shop_Code as shop_id,Shop_Name as shop_name,'
					--Rev 2.0
					SET @sql+='SHOP.EntityCode,SHOP.Entity_Location,CASE WHEN SHOP.Entity_Status=1 THEN ''Active'' ELSE ''Inactive'' END AS Entity_Status,MO.TypeName AS Specification,SHOP.ShopOwner_PAN,'
					SET @sql+='SHOP.ShopOwner_Aadhar,'
					--End of Rev 2.0
					SET @sql+='Address as [address],Pincode as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name,
					Shop_WebSite,Shop_Owner_Email as owner_email,Shop_Owner_Contact as owner_contact_no,Shop_CreateUser,Shop_CreateTime,
					FORMAT(Shop_CreateTime,''hh:mm tt'') as time_shop,Shop_ModifyUser,Shop_ModifyTime,'''+@Weburl+'''+ Shop_Image as Shop_Image,dob,date_aniversary,typs.Name as Shoptype,shop.type,
					b.Shop_Name as PP,c.Shop_Name as DD,'
					--Rev 4.0
					SET @sql+='CITY.CITY_NAME AS District,shop.CLUSTER AS Cluster,'
					--End of Rev 4.0
					--Rev 6.0
					SET @sql+='shop.Alt_MobileNo1,shop.Shop_Owner_Email2 '
					--End of Rev 6.0
					SET @sql+='from tbl_Master_shop as shop
					INNER JOIN  tbl_master_user usr on shop.Shop_CreateUser=usr.user_id '
					IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Create_UserId)=1)
					BEGIN
						SET @sql+='INNER JOIN #EMPHR_EDIT HY ON usr.user_contactId=HY.EMPCODE '
					END
					--INNER JOIN @ReportTABLE as rt on rt.userid=usr.user_id
					--Rev 2.0
					SET @sql+='LEFT OUTER JOIN Master_OutLetType MO ON SHOP.Entity_Type=MO.TypeID '
					--End of Rev 2.0
					SET @sql+='LEFT OUTER JOIN tbl_salesman_address as saladdr on shop.Shop_CreateUser=saladdr.UserId 
					LEFT OUTER JOIN tbl_Master_shop as b on shop.Shop_Code=b.assigned_to_pp_id 
					LEFT OUTER JOIN tbl_Master_shop as c on shop.Shop_Code=c.assigned_to_dd_id '
					--Rev 4.0
					SET @sql+='LEFT OUTER JOIN TBL_MASTER_CITY CITY ON shop.Shop_City=CITY.city_id '
					--End of Rev 4.0
					--and user_id='''+@user_id+''' '
					if(isnull(@StateId,'')<>'')
						BEGIN
							SET @sql +='where saladdr.stateid='+@StateId+''
						END
					--and  SessionToken='''+@session_token+''' 
					SET @sql +='order  by Shop_ID  desc '

					EXEC SP_EXECUTESQL @sql
					--select  @sql
				END
			ELSE IF(isnull(@FromDate,'')='' and  isnull(@Todate,'')='')
				BEGIN
					SET @sql='select distinct cast(shop.Shop_ID as varchar(50))	as shop_Auto ,Shop_Code as shop_id,	Shop_Name as shop_name,'
					--Rev 2.0
					SET @sql+='SHOP.EntityCode,SHOP.Entity_Location,CASE WHEN SHOP.Entity_Status=1 THEN ''Active'' ELSE ''Inactive'' END AS Entity_Status,MO.TypeName AS Specification,SHOP.ShopOwner_PAN,'
					SET @sql+='SHOP.ShopOwner_Aadhar,'
					--End of Rev 2.0
					SET @sql+='shop.Address as [address],shop.Pincode as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name,
					Shop_WebSite,Shop_Owner_Email as owner_email,Shop_Owner_Contact as owner_contact_no,
					Shop_CreateUser,Shop_CreateTime,FORMAT(Shop_CreateTime,''hh:mm tt'') as time_shop,Shop_ModifyUser,Shop_ModifyTime,'''+@Weburl+''' + Shop_Image as Shop_Image,dob,
					date_aniversary,typs.Name as Shoptype,shop.type,CNT.cnt_firstName + '' ''+ CNT.cnt_middleName +'' ''+CNT.cnt_lastName as UserName,
					isnull(count(Act.ActivityId),0) as countactivity,
					Lastactivitydate=(select top 1 convert(varchar(50),visited_time,103) + '' '' + FORMAT(visited_time,''hh:mm tt'') as SDate1 
					from tbl_trans_shopActivitysubmit as shpusr  where  shpusr.user_id=usr.user_id and shpusr.Shop_Id=shop.Shop_Code order by visited_time desc),'
					--Rev 4.0
					SET @sql+='CITY.CITY_NAME AS District,shop.CLUSTER AS Cluster,'
					--End of Rev 4.0
					--Rev 6.0
					SET @sql+='shop.Alt_MobileNo1,shop.Shop_Owner_Email2 '
					--End of Rev 6.0
					SET @sql+='from tbl_Master_shop as shop
					INNER JOIN  tbl_master_user usr on shop.Shop_CreateUser=usr.user_id 
					INNER JOIN  tbl_shoptype  as typs on typs.shop_typeId=shop.type '
					IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Create_UserId)=1)
					BEGIN
						SET @sql+='INNER JOIN #EMPHR_EDIT HY ON usr.user_contactId=HY.EMPCODE '
					END
					--INNER JOIN @ReportTABLE as rt on rt.userid=usr.user_id
					SET @sql+='and user_id='''+@user_id+''' '
					--Rev 2.0
					SET @sql+='LEFT OUTER JOIN Master_OutLetType MO ON SHOP.Entity_Type=MO.TypeID '
					--End of Rev 2.0
					SET @sql+='INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId = usr.user_contactId
					INNER JOIN tbl_trans_shopActivitysubmit as Act on Act.Shop_Id=shop.Shop_Code
					LEFT OUTER JOIN tbl_salesman_address as saladdr on shop.Shop_CreateUser=saladdr.UserId '
					--Rev 4.0
					SET @sql+='LEFT OUTER JOIN TBL_MASTER_CITY CITY ON shop.Shop_City=CITY.city_id '
					--End of Rev 4.0
					if(isnull(@StateId,'')<>'')
						BEGIN
							SET @sql +='where saladdr.stateid='+@StateId+''
						END
					SET @sql +='GROUP BY shop.Shop_ID,Shop_Code,Shop_Name,shop.Address,shop.Pincode,Shop_Lat,Shop_Long,Shop_City,Shop_Owner,Shop_CreateUser,Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,
					Shop_Image,usr.user_id,dob,date_aniversary,typs.Name,shop.type,CNT.cnt_firstName ,CNT.cnt_middleName ,CNT.cnt_lastName,Shop_WebSite,Shop_Owner_Email,Shop_Owner_Contact,'
					--Rev 2.0
					SET @sql+='SHOP.EntityCode,SHOP.Entity_Location,SHOP.Entity_Status,MO.TypeName,SHOP.ShopOwner_PAN,SHOP.ShopOwner_Aadhar,'
					--End of Rev 2.0
					--Rev 4.0
					SET @sql+='CITY.CITY_NAME,shop.CLUSTER,'
					--End of Rev 4.0
					--Rev 6.0
					SET @sql+='shop.Alt_MobileNo1,shop.Shop_Owner_Email2 '
					--End of Rev 6.0
					SET @sql+='ORDER BY Shop_ID desc'
					--and  SessionToken=@session_token'

					EXEC SP_EXECUTESQL @sql
				END
			ELSE
				BEGIN
					--Rev 2.0
					--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT2') AND TYPE IN (N'U'))
					IF OBJECT_ID('tempdb..#TEMPCONTACT2') IS NOT NULL
					--End of Rev 2.0
						DROP TABLE #TEMPCONTACT2
					CREATE TABLE #TEMPCONTACT2
						(
							cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
						)
					CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT2(cnt_internalId,cnt_contactType ASC)
					INSERT INTO #TEMPCONTACT2
					SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

					--Rev 2.0
					--SET @sql='SELECT distinct cast(shop.Shop_ID as varchar(50))	as shop_Auto ,shop.Shop_Code as shop_id,shop.Shop_Name as shop_name,
					SET @sql='SELECT distinct cast(shop.Shop_ID as varchar(50))	as shop_Auto ,shop.Shop_Code as shop_id,shop.Shop_Name as shop_name,SHOP.EntityCode,SHOP.Entity_Location,'
					SET @sql+='CASE WHEN SHOP.Entity_Status=1 THEN ''Active'' ELSE ''Inactive'' END AS Entity_Status,MO.TypeName AS Specification,SHOP.ShopOwner_PAN,SHOP.ShopOwner_Aadhar,'
					--End of Rev 2.0
					SET @sql+='shop.Address as [address],shop.Pincode as pin_code,shop.Shop_Lat as shop_lat,shop.Shop_Long as shop_long,shop.Shop_City,shop.Shop_Owner as owner_name
					,shop.Shop_WebSite,shop.Shop_Owner_Email as owner_email,shop.Shop_Owner_Contact as owner_contact_no,shop.Shop_CreateUser,shop.Shop_CreateTime,
					FORMAT(shop.Shop_CreateTime,''hh:mm tt'') as time_shop,shop.Shop_ModifyUser,shop.Shop_ModifyTime,'''+@Weburl+''' +shop.Shop_Image as Shop_Image
					,shop.dob,shop.date_aniversary,typs.Name as Shoptype,EMP.emp_uniqueCode as EMPCODE,CNT.cnt_firstName+'' '' +CNT.cnt_middleName+'' ''+CNT.cnt_lastName as EMPNAME
					,usr.user_loginId,shop.type,STAT.state as STATE,RPTTO.REPORTTO
					,PP=(select Shop_Name  from tbl_Master_shop as b where  b.Shop_Code=shop.assigned_to_pp_id )
					,DD=(select Shop_Name  from tbl_Master_shop as c where  c.Shop_Code=shop.assigned_to_dd_id )
					,CNT.cnt_firstName + '' ''+ CNT.cnt_middleName +'' ''+CNT.cnt_lastName as UserName,'
					--Rev 4.0
					SET @sql+='CITY.CITY_NAME AS District,shop.CLUSTER AS Cluster,'
					--End of Rev 4.0
					--Rev 6.0
					SET @sql+='shop.Alt_MobileNo1,shop.Shop_Owner_Email2,'
					--End of Rev 6.0
					--Rev 10.0
					SET @sql+='BR.BRANCH_ID,BR.BRANCH_DESCRIPTION AS BRANCHDESC '
					--End of Rev 10.0
					--, countactivity=(select isnull(count(Act.ActivityId),0)  from tbl_trans_shopActivitysubmit as Act where Act.Shop_Id=shop.Shop_Code )
					--,Lastactivitydate=(select top 1 convert(varchar(50),visited_time,103) + '' '' + FORMAT(visited_time,''hh:mm tt'') as SDate1 from tbl_trans_shopActivitysubmit as shpusr  where  shpusr.user_id=usr.user_id and shpusr.Shop_Id=shop.Shop_Code order by visited_time desc)
					set @sql +='from tbl_Master_shop as shop
					INNER JOIN tbl_master_user  usr on shop.Shop_CreateUser=usr.user_id 
					INNER JOIN tbl_shoptype  as typs on typs.shop_typeId=shop.type '
					IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Create_UserId)=1)
					BEGIN
						SET @sql+='INNER JOIN #EMPHR_EDIT HY ON usr.user_contactId=HY.EMPCODE '
					END
					--INNER JOIN @ReportTABLE as rt on rt.userid=usr.user_id'
					--Rev 2.0
					SET @sql+='LEFT OUTER JOIN Master_OutLetType MO ON SHOP.Entity_Type=MO.TypeID '
					--End of Rev 2.0
					set @sql+='INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId = usr.user_contactId
					INNER JOIN tbl_master_employee as EMP on CNT.cnt_internalId=EMP.emp_contactId 
					LEFT OUTER JOIN tbl_salesman_address as saladdr on shop.Shop_CreateUser=saladdr.UserId  '
					--Rev 10.0
					SET @sql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
					--End of Rev 10.0
					--Rev 4.0
					SET @sql+='LEFT OUTER JOIN TBL_MASTER_CITY CITY ON shop.Shop_City=CITY.city_id '
					--End of Rev 4.0
					--Rev 1 
					set @sql +='INNER  JOIN (
							SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' 
							)S on S.add_cntId=CNT.cnt_internalId

					INNER JOIN tbl_master_state as STAT on STAT.id=S.add_state  '
					--end of Rev 1
					set @sql +='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,USR.user_id,CNT.cnt_internalId,
					ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO FROM tbl_master_employee EMP 
					INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo 
					INNER JOIN #TEMPCONTACT2 CNT ON CNT.cnt_internalId=EMP.emp_contactId 
					INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId 
					) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
					--left outer join  tbl_Master_shop as b on shop.Shop_Code=b.assigned_to_pp_id 
					--left outer join  tbl_Master_shop as c on shop.Shop_Code=c.assigned_to_dd_id 
					set @sql +='where cast(shop.Shop_CreateTime as date) between  '''+@FromDate+''' and '''+@Todate+''' '
					if(isnull(@user_id,'0')<>'0')
						BEGIN
							set @sql +=' and usr.user_id='''+@user_id+''''
						END
					if(isnull(@StateId,'')<>'')
						BEGIN
							set @sql +=' and saladdr.stateid='+@StateId+''
						END
					--Rev 10.0
					IF @BRANCHID<>''
						SET @sql+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.BRANCH_ID) '
					--End of Rev 10.0
					SET @sql+='GROUP BY shop.Shop_ID,shop.Shop_Code,shop.Shop_Name,shop.Address,shop.Pincode,shop.Shop_Lat,shop.Shop_Long,shop.Shop_City,shop.Shop_Owner,shop.Shop_CreateUser,
					shop.Shop_CreateTime,shop.Shop_ModifyUser,shop.Shop_ModifyTime,shop.Shop_Image,usr.user_id,shop.dob,shop.date_aniversary,typs.Name,shop.type,CNT.cnt_firstName ,CNT.cnt_middleName,'
					--Rev 2.0
					--CNT.cnt_lastName,shop.Shop_WebSite,shop.Shop_Owner_Email,shop.Shop_Owner_Contact,assigned_to_pp_id ,assigned_to_dd_id,EMP.emp_uniqueCode,CNT.cnt_firstName,CNT.cnt_middleName,
					SET @sql+='CNT.cnt_lastName,shop.Shop_WebSite,shop.Shop_Owner_Email,shop.Shop_Owner_Contact,assigned_to_pp_id,assigned_to_dd_id,EMP.emp_uniqueCode,SHOP.EntityCode,SHOP.Entity_Location,'
					SET @sql+='SHOP.Entity_Status,MO.TypeName,SHOP.ShopOwner_PAN,SHOP.ShopOwner_Aadhar,'
					--End of Rev 2.0
					SET @sql+='CNT.cnt_lastName,STAT.state,usr.user_loginId,RPTTO.REPORTTO,'
					--Rev 4.0
					SET @sql+='CITY.CITY_NAME,shop.CLUSTER,'
					--End of Rev 4.0
					--Rev 6.0
					SET @sql+='shop.Alt_MobileNo1,shop.Shop_Owner_Email2,'
					--End of Rev 6.0
					--Rev 10.0
					SET @sql+='BR.BRANCH_ID,BR.BRANCH_DESCRIPTION '
					--End of Rev 10.0
					SET @sql+='ORDER BY Shop_ID DESC '
					--select @sql
					EXEC SP_EXECUTESQL @sql

					--Rev 2.0
					DROP TABLE #TEMPCONTACT2
					--End of Rev 2.0
				END

			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Create_UserId)=1)
			BEGIN
				DROP TABLE #EMPHR
				DROP TABLE #EMPHR_EDIT
			END
		END

	ELSE IF(@Action='ShopDetailsById')
		BEGIN
			SELECT cast(Shop_ID as varchar(50))	as shop_Auto ,Shop_Code as shop_id,	Shop_Name as shop_name,
			Address as [address],Pincode as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name
			,Shop_WebSite,Shop_Owner_Email as owner_email	,Shop_Owner_Contact as owner_contact_no
			,Shop_CreateUser,Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,Shop_Image as Shop_Image
			,Convert(varchar(50),dob,103)  as dobstr
			,Convert(varchar(50),date_aniversary,103)  as date_aniversarystr 
			,typs.Name as Shoptype
			,shop.type
			,cast(shop.AssignTo  as varchar(50)) as Assign_To
			from tbl_Master_shop as shop
			INNER JOIN  tbl_master_user  usr on shop.Shop_CreateUser=usr.user_id 
			INNER JOIN  tbl_shoptype  as typs on typs.shop_typeId=shop.type
			and Shop_ID=@shopid
		END
	ELSE IF(@Action='Modify')
		BEGIN
			declare @StateModify varchar(50)
			set @StateModify=(select  top 1 stat.id  from tbl_master_pinzip as pin  inner join tbl_master_city as cty  on cty.city_id=pin.city_id  
			inner join tbl_master_state as stat on stat.id=cty.state_id where pin.pin_code=@pincode)
			if(isnull(@StateModify,'')='')
				BEGIN
					update tbl_Master_shop set Shop_Name=@shopname,Address=@address,Pincode=@pincode,Shop_Owner_Contact=@ownercontact,
					Shop_Owner=@ownername,Shop_Owner_Email=@owneremail,dob=@dob,date_aniversary=@doanniversary,type=@Shoptype,AssignTo=@AssignTo
					where Shop_ID=@shopid
				END
			ELSE
				BEGIN
					update tbl_Master_shop set Shop_Name=@shopname,Address=@address,Pincode=@pincode,Shop_Owner_Contact=@ownercontact,
					Shop_Owner=@ownername,Shop_Owner_Email=@owneremail,dob=@dob,date_aniversary=@doanniversary,type=@Shoptype,stateId=@StateModify,AssignTo=@AssignTo
					where Shop_ID=@shopid
				END
		END

	ELSE IF(@Action='Delete')
		BEGIN
			DELETE FROM tbl_Master_shop WHERE Shop_ID=@shopid
		END
	ELSE IF(@Action='Gettypes')
		BEGIN
			SELECT TypeId AS ID,Name FROM tbl_shoptype
		END
------------------------------------------------

	IF(@Action='Counter')
		BEGIN
			DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX)
			--Rev 7.0
			CREATE TABLE #TMPSHOPTYPENAME(SHOPTYPENAME NVARCHAR(MAX))
			--End of Rev 7.0

			--Rev 2.0
			--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
			IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
			--End of Rev 2.0
				DROP TABLE #STATEID_LIST
			CREATE TABLE #STATEID_LIST (State_Id INT)
			CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
			IF @STATEID <> ''
				BEGIN
					SET @STATEID=REPLACE(@STATEID,'''','')
					SET @sqlStrTable=''
					SET @sqlStrTable=' INSERT INTO #STATEID_LIST SELECT id from tbl_master_state where id in('+@STATEID+')'
					EXEC SP_EXECUTESQL @sqlStrTable
				END

			--Rev 2.0
			--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
			IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
			--End of Rev 2.0
				DROP TABLE #TEMPCONTACT
			CREATE TABLE #TEMPCONTACT
				(
					cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				)
			CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

			SET @Shoptype = REPLACE(''''+@Shoptype+'''',',',''',''')

			SET @Shoptype=REPLACE(@Shoptype,'''','')
			
			--Rev 7.0
			SET @sql='INSERT INTO #TMPSHOPTYPENAME(SHOPTYPENAME) SELECT (
			ISNULL((SELECT LTRIM(STUFF(((SELECT DISTINCT '','' + [Name] FROM ShopTypeData WHERE [shop_typeId] IN('+@Shoptype+')	
				FOR XML PATH(''''))),1,1,''''))),'''')) '
			EXEC(@sql)
			SET @sql=''
			--End of Rev 7.0
			

			--SET @sqlStrTable=''
			--SET @sqlStrTable=' INSERT INTO #Shop_List select branch_id from tbl_master_branch where branch_id in('+@Shoptype+')'

			SET @sql='select distinct cast(shop.Shop_ID as varchar(50))	as shop_Auto ,stat.state as statename ,shop.Shop_Code as shop_id,CAST(shop.Shop_Name as nvarchar(2500)) as shop_name,'
			--Rev 2.0
			SET @sql+='SHOP.EntityCode,SHOP.Entity_Location,CASE WHEN SHOP.Entity_Status=1 THEN ''Active'' ELSE ''Inactive'' END AS Entity_Status,MO.TypeName AS Specification,SHOP.ShopOwner_PAN,'
			SET @sql+='SHOP.ShopOwner_Aadhar,'
			--End of Rev 2.0
			SET @sql+='shop.Address as [address],shop.Pincode as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name,
			Shop_WebSite,Shop_Owner_Email as owner_email,Shop_Owner_Contact as owner_contact_no,
			LTRIM(RTRIM((IsNull(CNT.cnt_firstName,'''')+'' ''+IsNull(CNT.cnt_middleName,'''')+'' ''+IsNull(CNT.cnt_lastName,'''')))) as user_name,Shop_CreateUser,Shop_CreateTime,
			FORMAT(Shop_CreateTime,''hh:mm tt'') as time_shop,Shop_ModifyUser,Shop_ModifyTime,'''+@Weburl+''' + Shop_Image as Shop_Image,dob,date_aniversary,typs.Name as Shoptype,
			shop.type,CNT.cnt_firstName + '' ''+ CNT.cnt_middleName +'' ''+CNT.cnt_lastName as UserName '
			--set @sql +=' 
			--,isnull(count(Act.ActivityId),0) as countactivity
			SET @sql +=',0 as countactivity '

			--,Lastactivitydate=(select top 1 convert(varchar(50),visited_time,103) + '' '' + FORMAT(visited_time,''hh:mm tt'') as SDate1 from tbl_trans_shopActivitysubmit as shpusr  where  shpusr.user_id=usr.user_id and shpusr.Shop_Id=shop.Shop_Code order by visited_time desc)
			--Rev 9.0
			--SET @sql +=', PP=(select Shop_Name  from tbl_Master_shop as b where  b.Shop_Code=shop.assigned_to_pp_id )
			--,DD=(select Shop_Name from tbl_Master_shop as c where  c.Shop_Code=shop.assigned_to_dd_id ) '
			SET @sql +=',SHOPPP.Shop_Name AS PP,SHOPDD.Shop_Name AS DD '
			--End of Rev 9.0
			--,convert(varchar(50),T.visited_time,103) + '' '' + FORMAT(T.visited_time,''hh:mm tt'') as Lastactivitydate 
			SET @sql +=', null as Lastactivitydate,'
			--Rev 4.0
			SET @sql+='CITY.CITY_NAME AS District,shop.CLUSTER AS Cluster,'
			--End of Rev 4.0
			--Rev 5.0
			SET @sql+='(SELECT ISNULL(STUFF((SELECT '','' + typsd.Name FROM tbl_shoptypeDetails AS typsd '
			SET @sql+='WHERE typs.shop_typeId=typsd.TYPE_ID '
			SET @sql+='ORDER BY typsd.Name FOR XML PATH('''')), 1, 1, ''''),'''')) AS SubType,'
			--End of Rev 5.0
			--Rev 6.0
			SET @sql+='shop.Alt_MobileNo1,shop.Shop_Owner_Email2 '
			--End of Rev 6.0
			--Rev work 8.0 start 30.06.2022
			SET @sql+=',shop.gstn_number,shop.trade_licence_number '
			--Rev work 8.0 start 30.06.2022
			SET @sql+='FROM tbl_Master_shop as shop '
			--Rev 2.0
			SET @sql+='LEFT OUTER JOIN Master_OutLetType MO ON SHOP.Entity_Type=MO.TypeID '
			--End of Rev 2.0
			SET @sql +='INNER JOIN tbl_master_user usr on shop.Shop_CreateUser=usr.user_id 
			INNER JOIN tbl_shoptype as typs on typs.shop_typeId=shop.type '
			SET @sql +='LEFT OUTER JOIN tbl_master_state as stat on shop.stateId=stat.id '
			--Rev 4.0
			SET @sql+='LEFT OUTER JOIN TBL_MASTER_CITY CITY ON shop.Shop_City=CITY.city_id '
			--End of Rev 4.0
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Create_UserId)=1)
				BEGIN
					SET @sql+='INNER JOIN #EMPHR_EDIT HY ON usr.user_contactId=HY.EMPCODE '
				END
			--INNER JOIN @ReportTABLE as rt on rt.userid=usr.user_id
			SET @sql +='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId = usr.user_contactId
			INNER JOIN tbl_master_employee EMP ON CNT.cnt_internalId = EMP.emp_contactId '
			--INNER JOIN   tbl_trans_shopActivitysubmit as Act on Act.Shop_Id=shop.Shop_Code 
			--LEFT OUTER  JOIN   tbl_salesman_address as saladdr on shop.Shop_CreateUser=saladdr.UserId  '
			--set @sql +=' LEFT OUTER JOIN
			--(

			--select  shpusr.user_id,shpusr.Shop_Id,

			--MAX (visited_time) as visited_time

			-----convert(varchar(50),visited_time,103) + '' '' + FORMAT(visited_time,''hh:mm tt'') as SDate1 

			--from tbl_trans_shopActivitysubmit as shpusr  
			--group by user_id,Shop_Id

			--)T ON  T.user_id=usr.user_id and T.Shop_Id=shop.Shop_Code   where shop.Shop_ID is not null'
			if(isnull(@StateId,'')<>'')
				BEGIN
					---set @sql +='and shop.stateId='+@StateId+''
					SET @sql +='  AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=shop.stateId) '
				END
			--Rev work start 7.0
				--if(isnull(@Shoptype,'')<>'')
				--BEGIN
				--	SET @sql +=' and shop.type in ('+@Shoptype+')'
				--END				 				 
				 IF (SELECT SHOPTYPENAME FROM #TMPSHOPTYPENAME)<>'Show All'
				  begin
					if(isnull(@Shoptype,'')<>'')
						BEGIN
							SET @sql +=' and shop.type in ('+@Shoptype+')'
						END
				   end				
			--Rev work close  7.0
			--Rev 9.0
			SET @sql +=' LEFT OUTER JOIN('
			SET @sql +=' SELECT DISTINCT A.Shop_Code,A.assigned_to_pp_id,A.Shop_Name FROM tbl_Master_shop A '
			SET @sql +=' ) SHOPPP ON SHOP.assigned_to_pp_id=SHOPPP.Shop_Code '
			SET @sql +=' LEFT OUTER JOIN('
			SET @sql +=' SELECT DISTINCT A.Shop_Code,A.assigned_to_dd_id,A.Shop_Name FROM tbl_Master_shop A '
			SET @sql +=' ) SHOPDD ON SHOP.assigned_to_dd_id=SHOPDD.Shop_Code '
			--End of Rev 9.0
			--set @sql +=' 
			--group by shop.Shop_ID,Shop_Code,Shop_Name,shop.Address,shop.Pincode,Shop_Lat,Shop_Long,Shop_City,Shop_Owner,Shop_CreateUser,Shop_CreateTime,
			--usr.user_name,
			--Shop_ModifyUser,Shop_ModifyTime,Shop_Image 
			--,usr.user_id
			--,dob
			--,date_aniversary
			--,typs.Name 
			--,shop.type
			--,CNT.cnt_firstName ,CNT.cnt_middleName ,CNT.cnt_lastName
			--,Shop_WebSite
			--,Shop_Owner_Email
			--,Shop_Owner_Contact,shop.assigned_to_pp_id,assigned_to_dd_id,T.visited_time
			--order  by Shop_ID  desc'
			SET @sql +='order by shop.Shop_code desc '
			 --and  SessionToken=@session_token'
			 --select @sql
			EXEC (@sql)

			--Rev 2.0
			DROP TABLE #STATEID_LIST
			DROP TABLE #TEMPCONTACT
			--End of Rev 2.0
			--Rev 7.0
			DROP TABLE #TMPSHOPTYPENAME
			--End of Rev 7.0
		END

	if(@Action='PPDDLIST')
		BEGIN
			--Rev 2.0
			--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT1') AND TYPE IN (N'U'))
			IF OBJECT_ID('tempdb..#TEMPCONTACT1') IS NOT NULL
			--End of Rev 2.0
				DROP TABLE #TEMPCONTACT1
			CREATE TABLE #TEMPCONTACT1
				(
					cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				)
			CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT1(cnt_internalId,cnt_contactType ASC)
			INSERT INTO #TEMPCONTACT1
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')	

			set @sql='select distinct cast(shop.Shop_ID as varchar(50))	as shop_Auto ,stat.state as statename ,Shop_Code as shop_id,CAST(Shop_Name as nvarchar(2500)) as shop_name,
			shop.Address as [address],shop.Pincode as pin_code,Shop_Lat as shop_lat,Shop_Long as shop_long,Shop_City,Shop_Owner as owner_name
			,Shop_WebSite,Shop_Owner_Email as owner_email	,Shop_Owner_Contact as owner_contact_no
			,LTRIM(RTRIM((IsNull(CNT.cnt_firstName,'''')+'' ''+IsNull(CNT.cnt_middleName,'''')+'' ''+IsNull(CNT.cnt_lastName,'''')))) as user_name,Shop_CreateUser,Shop_CreateTime,
			FORMAT(Shop_CreateTime,''hh:mm tt'') as time_shop,Shop_ModifyUser,Shop_ModifyTime,dob,date_aniversary,typs.Name as Shoptype,shop.type,
			CNT.cnt_firstName + '' ''+ CNT.cnt_middleName +'' ''+CNT.cnt_lastName as UserName '
			set @sql +=',0 as countactivity '
			set @sql +=', null as Lastactivitydate 
			from tbl_Master_shop as shop '
			set @sql +='INNER JOIN  tbl_master_user  usr on shop.Shop_CreateUser=usr.user_id '
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Create_UserId)=1)
				BEGIN
					SET @sql+='INNER JOIN #EMPHR_EDIT HY ON usr.user_contactId=HY.EMPCODE '
				END
			SET @sql+=' INNER JOIN tbl_shoptype  as typs on typs.shop_typeId=shop.type 
			LEFT OUTER JOIN tbl_master_state as stat on shop.stateId=stat.id 
			INNER JOIN #TEMPCONTACT1 CNT ON CNT.cnt_internalId = usr.user_contactId 
			INNER JOIN tbl_master_employee EMP ON CNT.cnt_internalId = EMP.emp_contactId '
			set @sql +=' and shop.type in (2,4) '
			set @sql +='order  by Shop_CreateTime desc '
			---select @sql
			EXEC (@sql)

			--Rev 2.0
			DROP TABLE #TEMPCONTACT1
			--End of Rev 2.0
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Create_UserId)=1)
			BEGIN
				DROP TABLE #EMPHR
				DROP TABLE #EMPHR_EDIT
			END
		END
	
	--Rev 10.0
	DROP TABLE #BRANCH_LIST
	--End of Rev 10.0
	--Rev 2.0
	SET NOCOUNT OFF
	--End of Rev 2.0
END
GO