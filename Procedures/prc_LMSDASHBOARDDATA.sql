
--EXEC prc_FSMDashboardData 'TrackRoute','2018-12-28','2018-12-28',1677,15

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_LMSDASHBOARDDATA]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_LMSDASHBOARDDATA] AS' 
END
GO

ALTER PROCEDURE [dbo].[prc_LMSDASHBOARDDATA]
(
@Action varchar(200)='',
@USERID Varchar(10)='',
@RPTTYPE NVARCHAR(20)='',
@STATEID NVARCHAR(max)='',
@BRANCHID NVARCHAR(max)=''
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************************
Written by : Priti Roy on 20/08/2024
0027667:LMS Dashboard
*****************************************************************************************************************************************************************************************/
BEGIN    
	
	Declare @Pending bigint=0,@AssignedTopics bigint=0


	

	IF(@Action ='TOTALCOUNT' )
	BEGIN
		
		EXEC PRC_LMSDASHBOARD_REPORT @Action='ALL',@RPTTYPE='Summary',@USERID=@userid,@STATEID=@STATEID,@BRANCHID=@BRANCHID
		

		select count(distinct USER_ID)CNT from LMSDASHBOARD_LIST  where USERID=@userid

		--select count(distinct TOPICID)CNT from LMSDASHBOARD_LIST  where USERID=@userid

		--select count(*)CNT from LMSDASHBOARD_LIST where   COMPLETIONSTATUS='Untouched' and  USERID=@userid

		--select count(*)CNT from LMSDASHBOARD_LIST where   COMPLETIONSTATUS='Pending'  and  USERID=@userid

		--select count(*)CNT from LMSDASHBOARD_LIST where   COMPLETIONSTATUS='Completed' and  USERID=@userid

		select count(*)CNT from LMS_TOPICS  where TOPICSTATUS=1

		select count(distinct TOPICID)CNT from LMSDASHBOARD_LIST where   COMPLETIONSTATUS='Untouched' and  USERID=@userid  
		and TOPICID not in (select TOPICID from LMSDASHBOARD_LIST where   COMPLETIONSTATUS in ('Pending' ,'Completed' ))

		select count(distinct TOPICID)CNT from LMSDASHBOARD_LIST where   COMPLETIONSTATUS='Pending'  and  USERID=@userid
		and TOPICID  in (select TOPICID from LMSDASHBOARD_LIST where   COMPLETIONSTATUS in ('Untouched' ,'Completed' ))

		select count(distinct TOPICID)CNT from LMSDASHBOARD_LIST where   COMPLETIONSTATUS='Completed' and  USERID=@userid
		and TOPICID not in (select TOPICID from LMSDASHBOARD_LIST where   COMPLETIONSTATUS in ('Untouched' ,'Pending' ))


		select @Pending=count(distinct TOPICID) from LMSDASHBOARD_LIST where   COMPLETIONSTATUS='Pending'  and  USERID=@userid
		and TOPICID  in (select TOPICID from LMSDASHBOARD_LIST where   COMPLETIONSTATUS in ('Untouched' ,'Completed' ))

		--select @Pending=count(*) from LMSDASHBOARD_LIST where   COMPLETIONSTATUS='Pending'  and  USERID=@userid

		select @AssignedTopics=count(*) from LMS_TOPICS  where TOPICSTATUS=1

		if(@AssignedTopics=0)
		set @AssignedTopics=1

		--select (@Pending / @AssignedTopics) * 100  as AverageProgress
		select round((convert(decimal,@Pending) / convert(decimal,@AssignedTopics)) * 100,0)  as AverageProgress
		
	END
	ELSE IF(@Action ='TOTALUSERLIST' )
	BEGIN

				
			select 
			--tbl.USER_ID as [Learner ID], 
			MUser.user_name as [Learner Name]
			,MUser.USER_LOGINID as [Login ID]
			,branch_description Branch,deg_designation as Designation,TOPICID as[Assigned Topic],CONTENT_ID as [Assigned Content] from (
			select  list.USER_ID,
			COUNT(distinct TOPICID)TOPICID,count(distinct CONTENT_ID)CONTENT_ID
			from LMSDASHBOARD_LIST  list	
			where  USERID=@userid
			group by list.USER_ID
			)tbl 
			left outer join tbl_master_user MUser on MUser.user_id=tbl.USER_ID
			left outer join FTS_EmployeeBranchMap EMP on EMP.Emp_Contactid=MUser.user_contactId
			left outer join tbl_master_branch branch on branch.branch_id=EMP.BranchId
			left outer join tbl_trans_employeeCTC CTC on CTC.emp_cntId=MUser.user_contactId
			left outer join tbl_master_designation DESIGNATION on DESIGNATION.deg_id=CTC.emp_Designation

		   

	END
	ELSE IF(@Action ='TOTALUSERCOMPLETEDLIST' )
	BEGIN
			select 
			--tbl.USER_ID as [Learner ID]
			MUser.user_name as [Learner Name]
			,MUser.USER_LOGINID as [Login ID]
			,branch_description Branch,deg_designation as Designation,TOPICID as[Assigned Topic],CONTENT_ID as [Assigned Content] 
			,ISCONTENTCOMPLETED as Completed--,ISCONTENTPending
			from (
			select  list.USER_ID,
			COUNT(distinct TOPICID)TOPICID,count(distinct CONTENT_ID)CONTENT_ID
			from LMSDASHBOARD_LIST  list	
			where  USERID=@userid
			group by list.USER_ID
			)tbl 
			left outer join tbl_master_user MUser on MUser.user_id=tbl.USER_ID
			left outer join FTS_EmployeeBranchMap EMP on EMP.Emp_Contactid=MUser.user_contactId
			left outer join tbl_master_branch branch on branch.branch_id=EMP.BranchId
			left outer join tbl_trans_employeeCTC CTC on CTC.emp_cntId=MUser.user_contactId
			left outer join tbl_master_designation DESIGNATION on DESIGNATION.deg_id=CTC.emp_Designation
			left outer join (select count(ISCONTENTCOMPLETED)ISCONTENTCOMPLETED,USERID from  FSMUSERLMSTOPICCONTENTINFO  where ISCONTENTCOMPLETED=1 group by USERID)INFO on INFO.USERID=tbl.USER_ID
			--left outer join (select count(ISCONTENTCOMPLETED)ISCONTENTPending,USERID from  FSMUSERLMSTOPICCONTENTINFO  where ISCONTENTCOMPLETED=0 group by USERID)INFO1 on INFO1.USERID=tbl.USER_ID

		   

	END
	ELSE IF(@Action ='TOTALUSERPENDINGLIST' )
	BEGIN
			select 
			--tbl.USER_ID as [Learner ID]			
			 MUser.user_name as [Learner Name]
			,MUser.USER_LOGINID as [Login ID]
			,branch_description Branch,deg_designation as Designation,TOPICID as[Assigned Topic],CONTENT_ID as [Assigned Content] 
			,ISCONTENTCOMPLETED as Completed,ISCONTENTPending as Pending
			from (
			select  list.USER_ID,
			COUNT(distinct TOPICID)TOPICID,count(distinct CONTENT_ID)CONTENT_ID
			from LMSDASHBOARD_LIST  list	
			where  USERID=@userid
			group by list.USER_ID
			)tbl 
			left outer join tbl_master_user MUser on MUser.user_id=tbl.USER_ID
			left outer join FTS_EmployeeBranchMap EMP on EMP.Emp_Contactid=MUser.user_contactId
			left outer join tbl_master_branch branch on branch.branch_id=EMP.BranchId
			left outer join tbl_trans_employeeCTC CTC on CTC.emp_cntId=MUser.user_contactId
			left outer join tbl_master_designation DESIGNATION on DESIGNATION.deg_id=CTC.emp_Designation
			left outer join (select count(ISCONTENTCOMPLETED)ISCONTENTCOMPLETED,USERID from  FSMUSERLMSTOPICCONTENTINFO  where ISCONTENTCOMPLETED=1 group by USERID)INFO on INFO.USERID=tbl.USER_ID
			left outer join (select count(ISCONTENTCOMPLETED)ISCONTENTPending,USERID from  FSMUSERLMSTOPICCONTENTINFO  where ISCONTENTCOMPLETED=0 group by USERID)INFO1 on INFO1.USERID=tbl.USER_ID

		   

	END
	
END