IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_AttendanceList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_AttendanceList] AS' 
END
GO

ALTER PROCEDURE [Proc_FTS_AttendanceList]
(
@user_id NVARCHAR(50),
@session_token NVARCHAR(MAX)=NULL,
@start_date NVARCHAR(MAX)=NULL,
@end_date NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @logindate datetime=NULL
	DECLARE @logoutdate datetime=NULL
	DECLARE @logintime NVARCHAR(50)=NULL
	DECLARE @logouttime NVARCHAR(50)=NULL
	DECLARE @duration NVARCHAR(50)=NULL

	if(isnull(@start_date,'') ='' and isnull(@end_date,'')='')
		BEGIN
			select T.User_Id,T.login_date  as login_date,T.login_time as  login_time,Isonleave,
			T.logout_date  as  logout_date ,
			T.logout_time  as logout_time,
			convert(NVARCHAR(50),T.duration)  as duration
			from(
			select User_Id,CAST(CONVERT(NVARCHAR,Min(Work_datetime),102) AS DATETIME)  as login_date ,
			 Min(Work_datetime) as login_time ,
			Max(Work_datetime) as logout_date , MAX(Work_datetime)    as logout_time ,
			convert(NVARCHAR(100),DateDiff(s,  Min(Work_datetime),Max(Work_datetime))%86400/3600) + ':'+convert(varchar(100),DateDiff(s,  Min(Work_datetime),Max(Work_datetime))%3600/60) +  ':'+convert(varchar(100),DateDiff(s,  Min(Work_datetime),Max(Work_datetime))%60)  as duration
			,cast(Isonleave as varchar(50)) as Isonleave
			from tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK)
			where User_Id=@user_id and convert(date,Work_datetime) between  DateAdd(DAY,-15,convert(date,GETDATE())) and convert(date,GETDATE())
			group by cast(Work_datetime as date),User_Id,Isonleave
			)T
			inner join
			(
			select user_id ,user_status from tbl_master_user WITH(NOLOCK) where user_id=@user_id
			)T1 on T.User_Id=T1.user_id

			order by T.login_date desc
		END

	ELSE
		BEGIN
			select T.User_Id,T.login_date as login_date,T.login_time  as login_time  ,Isonleave,
			--case when ( cast(logout_date as date)=cast(GETDATE() as date) and T1.user_status=1) then ''  else convert(varchar(50),cast(T.logout_date as date)) end as logout_date ,
			--case when ( cast(logout_date as date)=cast(GETDATE() as date) and T1.user_status=1) then NULL  else T.logout_date end as logout_time,
			 convert(varchar(50),cast(T.logout_date as date) ) as logout_date ,
			T.logout_date  as logout_time,
			convert(varchar(50),T.duration) as duration
			 from(
			select User_Id,
			--Min(Work_datetime) as login_date 
			CAST(CONVERT(VARCHAR,Min(Work_datetime),102) AS DATETIME)   as login_date ,

			Min(Work_datetime)  as login_time ,
			Max(Work_datetime) as logout_date ,convert(varchar, Max(Work_datetime), 102) as logout_time ,
			convert(varchar(100),DateDiff(s,  Min(Work_datetime),Max(Work_datetime))%86400/3600) + ':'+convert(varchar(100),DateDiff(s,  Min(Work_datetime),Max(Work_datetime))%3600/60) +  ':'+convert(varchar(100),DateDiff(s,  Min(Work_datetime),Max(Work_datetime))%60)  as duration
			,cast(Isonleave as varchar(50)) as Isonleave
			from  tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK)
			where convert(date,Work_datetime) between @start_date  and @end_date and User_Id=@user_id
			group by cast(Work_datetime as date),User_Id,Isonleave
			)T
			INNER JOIN
			(
			select user_id ,user_status from tbl_master_user WITH(NOLOCK) where user_id=@user_id
			)T1 on T.User_Id=T1.user_id
			order by T.login_date DESC
		END

	SET NOCOUNT OFF
END