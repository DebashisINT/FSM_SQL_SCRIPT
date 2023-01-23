--exec  FTS_GetDriving_Distance 2,2018,1792

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FTS_GetDriving_Distance]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FTS_GetDriving_Distance] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[FTS_GetDriving_Distance]
(
@Month int=NULL,
@Year int=NULL,
@user_Id int=NULL
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.38		Sanchita	12-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" 
												then data in portal shall be populated based on Hierarchy Only. Refer: 25504
****************************************************************************************************************************************************************************/
BEGIN

	Create table  #ReportTABLE 
	(

	userid int

	)

	CREATE NONCLUSTERED INDEX cnt_internalId ON #ReportTABLE (userid ASC)

	insert into  #ReportTABLE
	select  user_id  from dbo.[Get_UserReporthierarchy](@user_Id)
	union
	select @user_Id as user_id






	declare  @Tabledates Table
	(
	datevisit varchar(50)
	)


	Create table  #TGroupbySum 
	(
	userid varchar(50),
	datevisit  varchar(50),
	Totaldistance decimal(18,4) default 0
	)



	declare @date_from datetime, @date_to datetime
	set @date_from=(select cast(DATEADD(month,@Month-1,DATEADD(year,@Year-1900,0))  as date))
	set @date_to=(select cast(DATEADD(day,-1,DATEADD(month,@Month,DATEADD(year,@Year-1900,0)))   as date))
	;with dates as(

		select @date_from as dt

		union all

		select DATEADD(d,1,dt) from dates where dt<@date_to


	)
	insert into @Tabledates select  *  from dates


	declare @datecount int=0
	declare @sql varchar(MAX)

	set @datecount=(select count(datevisit)   from @Tabledates )

	-- Rev 1.0
	DECLARE @user_contactId NVARCHAR(15)
	SELECT @user_contactId=user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@user_Id

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_Id)=1)
	BEGIN
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
		where EMPCODE IS NULL OR EMPCODE=@user_contactId  
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
	-- End of Rev 1.0


	CREATE TABLE #tempdatewiseuser
	(
	userid INT ,
	Totaldistancecal decimal(18,4)  
	)

	DECLARE  @i INT=1
	WHILE @i<=@datecount
	BEGIN
	EXEC ('ALTER TABLE #tempdatewiseuser ADD Date_'+@i+' decimal(18,4);')
		SET @i=@i+1
	END


	insert into #tempdatewiseuser (userid) select user_id  from tbl_master_user

	--SELECT * FROM #tempdatewiseuser


	insert into #TGroupbySum (userid,datevisit,Totaldistance)(
	select  UserId,cast(visitdate as Date) ,sum(Distanceinkm) as s  from tbl_locationdistancecalculation  group by UserId,visitdate
	having  Datepart(mm,visitdate )=@Month and  Datepart(YYYY,visitdate)=@Year )


	--select *  from #TGroupbySum

	DECLARE  @j INT=1
	WHILE @j<=@datecount

	BEGIN
	--print @j

	set @sql='UPDATE a set a.Date_'+cast(@j as varchar(50))+'=Totaldistance  from  #tempdatewiseuser as a inner join #TGroupbySum as b on a.userid=b.userid and cast(datepart(day,datevisit) as int) ='+str(@j)+''

	EXEC(@sql)
	SET @j=@j+1
	--select  @sql

	END

	if(@datecount=28)
	BEGIN
	set @sql='UPDATE #tempdatewiseuser  set Totaldistancecal=isnull(Date_1,0)+isnull(Date_2,0)+isnull(Date_3,0)+isnull(Date_4,0)+isnull(Date_5,0)+isnull(Date_6,0)+isnull(Date_7,0)+
	isnull(Date_8,0)+isnull(Date_9,0)+isnull(Date_10,0)+isnull(Date_11,0)+isnull(Date_12,0)+isnull(Date_13,0)+isnull(Date_14,0)+isnull(Date_15,0)+isnull(Date_16,0)+isnull(Date_17,0)+isnull(Date_18,0)+isnull(Date_19,0)+isnull(Date_20,0)+isnull(Date_21,0)+isnull(Date_22,0)
	+isnull(Date_23,0)+isnull(Date_24,0)+isnull(Date_25,0)+isnull(Date_26,0)+isnull(Date_27,0)+isnull(Date_28,0)
	'
	END
	else if(@datecount=29)
	BEGIN
	set @sql='UPDATE #tempdatewiseuser  set Totaldistancecal=isnull(Date_1,0)+isnull(Date_2,0)+isnull(Date_3,0)+isnull(Date_4,0)+isnull(Date_5,0)+isnull(Date_6,0)+isnull(Date_7,0)+
	isnull(Date_8,0)+isnull(Date_9,0)+isnull(Date_10,0)+isnull(Date_11,0)+isnull(Date_12,0)+isnull(Date_13,0)+isnull(Date_14,0)+isnull(Date_15,0)+isnull(Date_16,0)+isnull(Date_17,0)+isnull(Date_18,0)+isnull(Date_19,0)+isnull(Date_20,0)+isnull(Date_21,0)+isnull(Date_22,0)
	+isnull(Date_23,0)+isnull(Date_24,0)+isnull(Date_25,0)+isnull(Date_26,0)+isnull(Date_27,0)+isnull(Date_28,0)+isnull(Date_29,0)
	'
	END
	else if(@datecount=30)
	BEGIN
	set @sql='UPDATE #tempdatewiseuser  set Totaldistancecal=isnull(Date_1,0)+isnull(Date_2,0)+isnull(Date_3,0)+isnull(Date_4,0)+isnull(Date_5,0)+isnull(Date_6,0)+isnull(Date_7,0)+
	isnull(Date_8,0)+isnull(Date_9,0)+isnull(Date_10,0)+isnull(Date_11,0)+isnull(Date_12,0)+isnull(Date_13,0)+isnull(Date_14,0)+isnull(Date_15,0)+isnull(Date_16,0)+isnull(Date_17,0)+isnull(Date_18,0)+isnull(Date_19,0)+isnull(Date_20,0)+isnull(Date_21,0)+isnull(Date_22,0)
	+isnull(Date_23,0)+isnull(Date_24,0)+isnull(Date_25,0)+isnull(Date_26,0)+isnull(Date_27,0)+isnull(Date_28,0)+isnull(Date_29,0)+isnull(Date_30,0)
	'
	END
	if(@datecount=31)
	BEGIN
	set @sql='UPDATE #tempdatewiseuser  set Totaldistancecal=isnull(Date_1,0)+isnull(Date_2,0)+isnull(Date_3,0)+isnull(Date_4,0)+isnull(Date_5,0)+isnull(Date_6,0)+isnull(Date_7,0)+
	isnull(Date_8,0)+isnull(Date_9,0)+isnull(Date_10,0)+isnull(Date_11,0)+isnull(Date_12,0)+isnull(Date_13,0)+isnull(Date_14,0)+isnull(Date_15,0)+isnull(Date_16,0)+isnull(Date_17,0)+isnull(Date_18,0)+isnull(Date_19,0)+isnull(Date_20,0)+isnull(Date_21,0)+isnull(Date_22,0)
	+isnull(Date_23,0)+isnull(Date_24,0)+isnull(Date_25,0)+isnull(Date_26,0)+isnull(Date_27,0)+isnull(Date_28,0)+isnull(Date_29,0)+isnull(Date_30,0)+isnull(Date_31,0)
	'
	END

	EXEC(@sql)

	Select  Substring(DATENAME(MONTH,datevisit),1,3) + '-'+ cast(Datepart(dd,datevisit) as varchar(50))  as datevisit from @Tabledates

	-- Rev 1.0 [below SQl query converted to dynamic SQL . @sql added]
	set @sql = ''
	set @sql += ' SELECT datedistance.* '
	set @sql += ' ,cast(usr.user_id  as int) as User_Id '
	set @sql += ' ,CNT.cnt_firstName + '' ''+ CNT.cnt_middleName +'' ''+CNT.cnt_lastName as UserName '
	set @sql += ' ,CNT1.cnt_firstName + '' ''+ CNT1.cnt_middleName +'' ''+CNT1.cnt_lastName as ReportName '
	set @sql += ' ,N.deg_designation as Designation '
	set @sql += ' ,usr.user_loginId as UserLoginID '
	 set @sql += ' FROM #tempdatewiseuser  as datedistance '
	set @sql += ' INNER JOIN  tbl_master_user  usr on datedistance.userid=usr.user_id '
	set @sql += ' INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId = usr.user_contactId '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_Id)=1)
	BEGIN
		SET @sql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE '
	END
	set @sql += ' inner join #ReportTABLE as rt on rt.userid=usr.user_id  '
	set @sql += ' INNER JOIN '
	set @sql += ' ( '
	set @sql += ' select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from '
	set @sql += ' tbl_trans_employeeCTC as cnt '
	set @sql += ' left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation '
	set @sql += ' group by emp_cntId,desg.deg_designation,desg.deg_id '
	set @sql += ' )N '
	set @sql += ' on  N.emp_cntId=usr.user_contactId '
	set @sql += ' inner join tbl_master_employee as emp on usr.user_contactId=emp.emp_contactId '
	set @sql += ' inner join  tbl_trans_employeeCTC as empctc on emp.emp_contactId=empctc.emp_cntId '
	set @sql += ' inner join tbl_master_employee as emp1 on emp1.emp_id=empctc.emp_reportTo '
	set @sql += ' inner join tbl_master_user as usr1 on  usr1.user_contactId=emp1.emp_contactId '
	set @sql += ' INNER JOIN tbl_master_contact CNT1 ON CNT1.cnt_internalId = usr1.user_contactId '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_Id)=1)
	BEGIN
		SET @sql+=' INNER JOIN #EMPHR_EDIT HRY1 ON CNT1.cnt_internalId=HRY1.EMPCODE '
	END
	set @sql += ' where empctc.emp_id in (select max(emp_id) from tbl_trans_employeeCTC group by emp_cntId ) '
	set @sql += ' order by CNT.cnt_firstName '
	EXEC(@sql)
	
	drop  table  #tempdatewiseuser
	drop table  #TGroupbySum
	drop table  #ReportTABLE
	-- Rev 1.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@user_Id)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END
	-- End of Rev 1.0

End