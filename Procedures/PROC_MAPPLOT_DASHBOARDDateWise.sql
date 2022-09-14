--EXEC PROC_MAPPLOT_DASHBOARDDateWise '15','2022-09-14',378,'1,122'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_MAPPLOT_DASHBOARDDateWise]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_MAPPLOT_DASHBOARDDateWise] AS' 
END
GO

ALTER PROCEDURE [dbo].[PROC_MAPPLOT_DASHBOARDDateWise]
(
@STATEID NVARCHAR(MAX)=NULL,
@Date NVARCHAR(10)=NULL,
@CREATE_USERID BIGINT=NULL,
--Rev 2.0
@BRANCHID NVARCHAR(MAX)=NULL
--End of Rev 2.0
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0					Tanmoy		30-01-2020		create sp
2.0		v2.0.32		Debashis	14/09/2022		Branch selection option is required on various reports.Refer: 0025198
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	--SET @STATEID=''
	DECLARE @sqlStrTable NVARCHAR(MAX)

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

	--Rev 2.0
	IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
		DROP TABLE #BRANCH_LIST
	CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

	IF @BRANCHID<>''
		BEGIN
			SET @sqlStrTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @sqlStrTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	--End of Rev 2.0

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
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
	
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_branchid FROM TBL_MASTER_CONTACT
			INNER JOIN #EMPHR_EDIT TMPR ON cnt_internalId=TMPR.EMPCODE
			WHERE cnt_contactType IN('EM')
		END
		ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_branchid FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
		END

	declare  @sql nvarchar(MAX)
	set @sql=' select  VisitId,Lat_visit as lat,Long_visit as lng,CAST(shopusr.User_Id as VARCHAR(50)) User_Id'
	--,CONT.cnt_firstName+'' ''+CONT.cnt_lastName +'' :Location ''+ shopusr.location_name  as  description
	set @sql+=',CONT.cnt_firstName+'' ''+CONT.cnt_lastName as SalesMan
	,case when rtrim(shopusr.location_name)=''Login from'' then ''Logged in''  when rtrim(shopusr.location_name)=''Logout at'' then ''Logged out''
		when rtrim(shopusr.location_name) is null then ''Address not Available''  else shopusr.location_name end as Loaction,USR.user_loginId Mobile,
		CAST((select count(0) from tbl_trans_shopActivitysubmit where User_Id=USR.user_id and visited_date=cast('''+@Date+''' as date)) as VARCHAR(20)) Total_Visit
	from TBL_TRANS_SHOPUSER_ARCH  as shopusr'

	--INNER JOIN
	--( 
	--SELECT  User_Id,max(VisitId) as maxvisit FROM TBL_TRANS_SHOPUSER_ARCH  group by User_Id)T
	--on T.maxvisit=shopusr.VisitId
	set @sql+=' INNER JOIN (SELECT User_Id,max(VisitId) as maxvisit FROM TBL_TRANS_SHOPUSER_ARCH where cast(SDate as date)=cast('''+@Date+''' as date) group by User_Id)T ON T.maxvisit=shopusr.VisitId '
	
	set @sql+=' INNER JOIN tbl_master_user as USR on USR.user_id=shopusr.User_Id
	INNER JOIN #TEMPCONTACT as CONT on USR.user_contactId=CONT.cnt_internalId '
	--Rev 2.0
	SET @sql+='INNER JOIN tbl_master_branch BR ON CONT.cnt_branchid=BR.branch_id '
	--End of Rev 2.0
	SET @sql+=' INNER JOIN (
	SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' 
	)S on S.add_cntId=CONT.cnt_internalId
	inner join (
	select   usrattendance.User_Id,usrattendance.Isonleave from 
	tbl_fts_UserAttendanceLoginlogout as usrattendance group by usrattendance.User_Id,usrattendance.Isonleave,cast(Work_datetime as date)
	having cast(Work_datetime as date)=cast('''+@Date+''' as date)
	)Tpresent  on Tpresent.User_Id=USR.user_id and Tpresent.Isonleave=''false''
	where cast(SDate as date)=cast('''+@Date+''' as date) and   isnull(shopusr.Lat_visit,'''')<>'''''
	IF @STATEID<>''
		SET @sql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=S.add_state) '
	--Rev 2.0
	IF @BRANCHID<>''
		SET @sql+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.BRANCH_ID) '
	--End of Rev 2.0

	set @sql+='union    
	 select  VisitId,Lat_visit as lat,Long_visit as lng,CAST(shopusr.User_Id as VARCHAR(50)) User_Id'
	set @sql+=',CONT.cnt_firstName+'' ''+CONT.cnt_lastName as SalesMan
	,case when rtrim(shopusr.location_name)=''Login from'' then ''Logged in''  when rtrim(shopusr.location_name)=''Logout at'' then ''Logged out''
		when rtrim(shopusr.location_name) is null then ''Address not Available''  else shopusr.location_name end as Loaction,USR.user_loginId Mobile,
		CAST((select count(0) from tbl_trans_shopActivitysubmit where User_Id=USR.user_id and visited_date=cast('''+@Date+''' as date)) as VARCHAR(20)) Total_Visit
	from tbl_trans_shopuser  as shopusr'

	set @sql+=' INNER JOIN (SELECT User_Id,max(VisitId) as maxvisit FROM tbl_trans_shopuser where cast(SDate as date)=cast('''+@Date+''' as date) group by User_Id)T ON T.maxvisit=shopusr.VisitId '
	
	set @sql+=' INNER JOIN tbl_master_user as USR on USR.user_id=shopusr.User_Id
	INNER JOIN #TEMPCONTACT as CONT on USR.user_contactId=CONT.cnt_internalId '
	--Rev 2.0
	SET @sql+='INNER JOIN tbl_master_branch BR ON CONT.cnt_branchid=BR.branch_id '
	--End of Rev 2.0
	SET @sql+=' INNER JOIN (
	SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' 
	)S on S.add_cntId=CONT.cnt_internalId
	inner join (
	select   usrattendance.User_Id,usrattendance.Isonleave from 
	tbl_fts_UserAttendanceLoginlogout as usrattendance group by usrattendance.User_Id,usrattendance.Isonleave,cast(Work_datetime as date)
	having cast(Work_datetime as date)=cast('''+@Date+''' as date)
	)Tpresent  on Tpresent.User_Id=USR.user_id and Tpresent.Isonleave=''false''
	where cast(SDate as date)=cast('''+@Date+''' as date) and   isnull(shopusr.Lat_visit,'''')<>'''''

	--if(isnull(@StateID,0)<>0)
	--set @sql+='  and S.add_state='''+@StateID+'''  '
	IF @STATEID<>''
		SET @sql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=S.add_state) '
	--Rev 2.0
	IF @BRANCHID<>''
		SET @sql+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.BRANCH_ID) '
	--End of Rev 2.0

	--select (@sql)
	EXEC Sp_ExecuteSQl @sql

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END
	--Rev 2.0
	DROP TABLE #BRANCH_LIST
	--End of Rev 2.0

	SET NOCOUNT OFF
END