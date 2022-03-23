--EXEC prc_FSMDashboardData 'TrackRoute','2018-12-28','2018-12-28',1677,15

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_FSMDashboardData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_FSMDashboardData] AS' 
END
GO

ALTER PROCEDURE [dbo].[prc_FSMDashboardData]
(
@Action varchar(200)='',
@Fromdate nvarchar(10)=null,
@ToDate   nvarchar(10)=null,
@userid Varchar(10)='',
-- Rev 1.0
--@stateid varchar(500)=''
@stateid nvarchar(max)='',
@branchid nvarchar(max)=''
-- End of Rev 1.0
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************************
1.0		V2.0.29		Sanchita	08-03-2022		FSM - Portal: Branch selection required against the selected 'State'. Refer: 24729
2.0		v2.0.28		Debashis	23-03-2022		FSM - Portal: Branch selection required in 'Team Visit' against the selected 'State'.Refer: 0024742
*****************************************************************************************************************************************************************************************/
BEGIN    
	--IF NOT EXISTS(SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FSMDASHBOARD_TEMPSHOPVISIT') AND TYPE IN (N'U'))
	--	BEGIN
	--		CREATE TABLE FSMDASHBOARD_TEMPSHOPVISIT
	--		(
	--		USERID BIGINT,EMPCODE VARCHAR(50),EMPNAME VARCHAR(500),TOTALSHOP BIGINT,REVISIT BIGINT,NEWSHOPVISIT  BIGINT,CONTACTNO VARCHAR(50),RPTTOUSERID BIGINT,RPTTOID BIGINT,RPTTOCODE VARCHAR(50)
	--		,REPORTTO  VARCHAR(500)
	--		)
	--	END
	IF NOT EXISTS(SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FSMDASHBOARD_TEMPAVGSHOPVISIT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FSMDASHBOARD_TEMPAVGSHOPVISIT
			(
			   AVG_DATA VARCHAR(20)
			)
		END

	SET @stateid=CASE WHEN @stateid='0' then '' else @stateid end
	-- Rev 1.0
	SET @branchid=CASE WHEN @branchid='0' then '' else @branchid end
	-- End of Rev 1.0

	IF(@Action ='TODAYDATA' )
	BEGIN
		--EXEC PRC_FTSDASHBOARD_REPORT @TODAYDATE=@ToDate,@STATEID=@stateid,@DESIGNID='',@EMPID='',@Action='GRAPH',@RPTTYPE='Detail',@USERID=@userid

		--select ACTION,COUNT(*) Count from FTSDASHBOARD_REPORT   WHERE USERID=@userid group by ACTION
		-- Rev 1.0
		--EXEC PRC_FTSDASHBOARD_REPORT @TODAYDATE=@ToDate,@STATEID=@stateid,@DESIGNID='',@EMPID='',@Action='ALL',@RPTTYPE='Summary',@USERID=@userid
		EXEC PRC_FTSDASHBOARD_REPORT @TODAYDATE=@ToDate,@STATEID=@stateid,@DESIGNID='',@EMPID='',@Action='ALL',@RPTTYPE='Summary',@USERID=@userid,@BRANCHID=@branchid
		-- End of Rev 1.0

		SELECT ACTION,EMPCNT AS Count FROM FTSDASHBOARD_REPORT WHERE USERID=@userid AND ACTION='EMP'
		UNION ALL
		SELECT ACTION,AT_WORK AS Count FROM FTSDASHBOARD_REPORT WHERE USERID=@userid AND ACTION='AT_WORK'
		UNION ALL
		SELECT ACTION,ON_LEAVE AS Count FROM FTSDASHBOARD_REPORT WHERE USERID=@userid AND ACTION='ON_LEAVE'
		UNION ALL
		SELECT ACTION,NOT_LOGIN AS Count FROM FTSDASHBOARD_REPORT WHERE USERID=@userid AND ACTION='NOT_LOGIN'
		
		--EXEC PRC_FTSDASHBOARDWIDGET_REPORT @todate,'A',@stateid,'Summary',@userid		

		--select * from FTSDASHBOARDWIDGET_REPORT WHERE USERID=@userid
  
	END

	--Rev 2.0
	ELSE IF(@Action ='TODAYTEAMVISITDATA')
		BEGIN
			EXEC PRC_FTSTEAMVISITDASHBOARD_REPORT @TODAYDATE=@ToDate,@STATEID=@stateid,@DESIGNID='',@EMPID='',@Action='ALL',@RPTTYPE='Summary',@BRANCHID=@branchid,@USERID=@userid

			SELECT ACTION,EMPCNT AS Count FROM FTSTEAMVISITDASHBOARD_REPORT WHERE USERID=@userid AND ACTION='EMP'
			UNION ALL
			SELECT ACTION,AT_WORK AS Count FROM FTSTEAMVISITDASHBOARD_REPORT WHERE USERID=@userid AND ACTION='AT_WORK'
			UNION ALL
			SELECT ACTION,ON_LEAVE AS Count FROM FTSTEAMVISITDASHBOARD_REPORT WHERE USERID=@userid AND ACTION='ON_LEAVE'
			UNION ALL
			SELECT ACTION,NOT_LOGIN AS Count FROM FTSTEAMVISITDASHBOARD_REPORT WHERE USERID=@userid AND ACTION='NOT_LOGIN'
		END
	--End of Rev 2.0

	ELSE IF(@Action='TrackRoute')
	BEGIn

	    DECLARE @COUNT BIGINT=( SELECT COUNT(*) FROM (
	    select  Row_Number() over(order by SDate)   as rw,Lat_visit as lat,Long_visit  as lng
		,location_name as title
		,location_name as description
		,Lat_visit +', '+Long_visit  as [location]
		,convert(varchar(50),SDate,103) + ' ' + FORMAT(Sdate,'hh:mm tt') as SDate
		,case when isnull(shp.LoginLogout,'')='' then 'In field' when isnull(shp.LoginLogout,'')=1 then 'Login' else 'Logout' end as loginstatus
		from tbl_trans_shopuser as shp
		inner join tbl_master_user  as usr on  shp.User_Id=usr.user_id
		where shp.User_Id=@userid
		and cast(SDate as Date)=@ToDate
		) T)

		--SELECT @COUNT
		DECLARE @DIVIDER BIGINT=1
		--SELECT @COUNT
		IF((@COUNT)>23)
		   SET @DIVIDER= CAST(@COUNT/23 AS INT)+1

        SELECT * FROM (
		select  Row_Number() over(order by SDate)   as rw,Lat_visit as lat,Long_visit  as lng
		,location_name as title
		,location_name as description
		,Lat_visit +', '+Long_visit  as [location]
		,convert(varchar(50),SDate,103) + ' ' + FORMAT(Sdate,'hh:mm tt') as SDate
		,case when isnull(shp.LoginLogout,'')='' then 'In field' when isnull(shp.LoginLogout,'')=1 then 'Login' else 'Logout' end as loginstatus
		from tbl_trans_shopuser as shp
		inner join tbl_master_user  as usr on  shp.User_Id=usr.user_id
		where shp.User_Id=@userid
		and cast(SDate as Date)=@ToDate
		) T WHERE (rw=1 or rw=@COUNT)
		union 

		SELECT top 21 * FROM (
	    select  Row_Number() over(order by SDate)   as rw,Lat_visit as lat,Long_visit  as lng
		,location_name as title
		,location_name as description
		,Lat_visit +', '+Long_visit  as [location]
		,convert(varchar(50),SDate,103) + ' ' + FORMAT(Sdate,'hh:mm tt') as SDate
		,case when isnull(shp.LoginLogout,'')='' then 'In field' when isnull(shp.LoginLogout,'')=1 then 'Login' else 'Logout' end as loginstatus
		from tbl_trans_shopuser as shp
		inner join tbl_master_user  as usr on  shp.User_Id=usr.user_id
		where shp.User_Id=@userid
		and cast(SDate as Date)=@ToDate
		) T WHERE (rw%@DIVIDER=0)
		 
	   

	END

END