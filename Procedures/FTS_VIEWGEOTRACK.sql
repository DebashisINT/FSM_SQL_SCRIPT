
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FTS_VIEWGEOTRACK]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FTS_VIEWGEOTRACK] AS' 
END
GO

--exec FTS_VIEWGEOTRACK @ACTION ='GETUSERROUTE',
--@USER_ID =378, @State ='2,8,28,16,1,35,3,19,24,15', @Branch ='127,118,1,128,122,149,141,120,150,125,119,144,145,148,143,146,140,124,147,121,142',
--@dtFrom ='2024-03-01', @dtTo ='2024-03-21', @empId='EMG0000001'

ALTER PROCEDURE [dbo].[FTS_VIEWGEOTRACK]
(
@ACTION VARCHAR(50)=NULL,
@USER_ID int=NULL,
@State NVARCHAR(MAX)=NULL,
@Branch NVARCHAR(MAX)=NULL,
@dtFrom varchar(10)=null,
@dtTo varchar(10)=null,
@empId varchar(10)=null
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by Sanchita	21-03-2024		A new dashboard floating icon is required as "View Geotrack".. Refer: 27323
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @sqlStrTable NVARCHAR(MAX)

	IF @ACTION='GETUSERROUTE'
	BEGIN
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
			BEGIN
				DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USER_ID)		
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
	
		IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
			DROP TABLE #BRANCH_LIST
		CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
		CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

		IF @Branch<>''
			BEGIN
				SET @sqlStrTable=''
				SET @Branch=REPLACE(@Branch,'''','')
				SET @sqlStrTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@Branch+')'
				EXEC SP_EXECUTESQL @sqlStrTable
			END
	

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
			DROP TABLE #STATEID_LIST
		CREATE TABLE #STATEID_LIST (State_Id INT)
		CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
		IF @State <> ''
			BEGIN
				SET @State=REPLACE(@State,'''','')
				SET @sqlStrTable=''
				SET @sqlStrTable=' INSERT INTO #STATEID_LIST SELECT id from tbl_master_state where id in('+@State+')'
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
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
			BEGIN
				INSERT INTO #TEMPCONTACT
				SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_branchid FROM TBL_MASTER_CONTACT
				INNER JOIN #EMPHR_EDIT TMPR ON cnt_internalId=TMPR.EMPCODE
				WHERE cnt_contactType IN('EM') and cnt_internalId=@empId
			END
			ELSE
			BEGIN
				INSERT INTO #TEMPCONTACT
				SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_branchid FROM TBL_MASTER_CONTACT 
				WHERE cnt_contactType IN('EM') and cnt_internalId=@empId
			END

		declare  @sql nvarchar(MAX)
		set @sql=' select  Lat_visit as Visit_Lat,Long_visit as Visit_Long,CAST(shopusr.User_Id as VARCHAR(50)) User_Id'
		--,CONT.cnt_firstName+'' ''+CONT.cnt_lastName +'' :Location ''+ shopusr.location_name  as  description
		set @sql+=',CONT.cnt_firstName+'' ''+CONT.cnt_lastName as SalesMan, isnull(shopusr.distance_covered,0) Distance_Covered
		from TBL_TRANS_SHOPUSER_ARCH  as shopusr'

		--set @sql+=' INNER JOIN (SELECT User_Id,max(VisitId) as maxvisit FROM TBL_TRANS_SHOPUSER_ARCH where 
		--cast(SDate as date)>=cast('''+@dtFrom+''' as date) and cast(SDate as date)<=cast('''+@dtTo+''' as date)
		--group by User_Id)T ON T.maxvisit=shopusr.VisitId '
	
		set @sql+=' INNER JOIN tbl_master_user as USR on USR.user_id=shopusr.User_Id
		INNER JOIN #TEMPCONTACT as CONT on USR.user_contactId=CONT.cnt_internalId '
		SET @sql+='INNER JOIN tbl_master_branch BR ON CONT.cnt_branchid=BR.branch_id '
		SET @sql+=' INNER JOIN (
		SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' 
		)S on S.add_cntId=CONT.cnt_internalId '
		--inner join (
		--select   usrattendance.User_Id,usrattendance.Isonleave from 
		--tbl_fts_UserAttendanceLoginlogout as usrattendance group by usrattendance.User_Id,usrattendance.Isonleave,cast(Work_datetime as date)
		--having cast(Work_datetime as date)=cast('''+@Date+''' as date)
		--)Tpresent  on Tpresent.User_Id=USR.user_id and Tpresent.Isonleave=''false''
		SET @sql+='where cast(SDate as date)>=cast('''+@dtFrom+''' as date) and cast(SDate as date)<=cast('''+@dtTo+''' as date)
					and   isnull(shopusr.Lat_visit,'''')<>'''''
		IF @State<>''
			SET @sql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=S.add_state) '
		IF @Branch<>''	
			SET @sql+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.BRANCH_ID) '
	
		set @sql+='union    
		 select  Lat_visit as Visit_Lat,Long_visit as Visit_Long,CAST(shopusr.User_Id as VARCHAR(50)) User_Id'
		set @sql+=',CONT.cnt_firstName+'' ''+CONT.cnt_lastName as SalesMan, isnull(shopusr.distance_covered,0) Distance_Covered
		from tbl_trans_shopuser  as shopusr'

		--set @sql+=' INNER JOIN (SELECT User_Id,max(VisitId) as maxvisit FROM tbl_trans_shopuser 
		--	where cast(SDate as date)>=cast('''+@dtFrom+''' as date) and cast(SDate as date)<=cast('''+@dtTo+''' as date) 
		--	group by User_Id)T ON T.maxvisit=shopusr.VisitId '
	
		set @sql+=' INNER JOIN tbl_master_user as USR on USR.user_id=shopusr.User_Id
		INNER JOIN #TEMPCONTACT as CONT on USR.user_contactId=CONT.cnt_internalId '
		SET @sql+='INNER JOIN tbl_master_branch BR ON CONT.cnt_branchid=BR.branch_id '
		SET @sql+=' INNER JOIN (
		SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' 
		)S on S.add_cntId=CONT.cnt_internalId '
		--inner join (
		--select   usrattendance.User_Id,usrattendance.Isonleave from 
		--tbl_fts_UserAttendanceLoginlogout as usrattendance group by usrattendance.User_Id,usrattendance.Isonleave,cast(Work_datetime as date)
		--having cast(Work_datetime as date)=cast('''+@Date+''' as date)
		--)Tpresent  on Tpresent.User_Id=USR.user_id and Tpresent.Isonleave=''false''
		SET @sql+=' where cast(SDate as date)>=cast('''+@dtFrom+''' as date) and cast(SDate as date)<=cast('''+@dtTo+''' as date)  
				and   isnull(shopusr.Lat_visit,'''')<>'''' AND isnull(shopusr.Lat_visit,'''')<>''0'' AND isnull(shopusr.Long_visit,'''')<>''0''
				AND isnull(shopusr.Lat_visit,'''')<>''0.0'' AND isnull(shopusr.Long_visit,'''')<>''0.0''
				AND isnull(shopusr.Lat_visit,'''')<>''0.00'' AND isnull(shopusr.Long_visit,'''')<>''0.00''
				and isnull(shopusr.Lat_visit,'''') not like ''%-%'' and isnull(shopusr.Long_visit,'''') not like ''%-%'' '

		IF @State<>''
			SET @sql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=S.add_state) '
			SET @sql+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.BRANCH_ID) '
		
		--select (@sql)
		EXEC Sp_ExecuteSQl @sql

		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
			BEGIN
				DROP TABLE #EMPHR
				DROP TABLE #EMPHR_EDIT
			END
		DROP TABLE #BRANCH_LIST
		DROP TABLE #STATEID_LIST
		DROP TABLE #TEMPCONTACT
	END

	SET NOCOUNT OFF
END
GO