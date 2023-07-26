IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_TASKMANAGEMENT_LISTING]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_TASKMANAGEMENT_LISTING] AS'  
END 
 
GO

 --exec PRC_TASKMANAGEMENT_LISTING @USERID='378',@TaskPriority='1,23',@FROMDATE='2023-05-08',@TODATE='2023-05-09',@Is_PageLoad=0
ALTER PROCEDURE [dbo].[PRC_TASKMANAGEMENT_LISTING]
(
@USERID INT=NULL,
@TaskPriority NVARCHAR(500)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@Is_PageLoad Nvarchar(10)=NULL
)
 
AS
/****************************************************************************************************************************************************************************
Written by : PRITI on 08-05-2023. Refer: 
0026031:Copy the current Enquiry page, and create a duplicate and name it as 'Task Management'
0026032: Customization in Task Management Page
0026034: Customization in Add Task Page 
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX)

	set @TaskPriority = ''''+ replace(@TaskPriority,',',''',''') + ''''

	----Rev 3.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPMAXSALESMANFEEDBACK') AND TYPE IN (N'U'))
	--	DROP TABLE #TEMPMAXSALESMANFEEDBACK
	--CREATE TABLE #TEMPMAXSALESMANFEEDBACK
	--	(
	--		created_date DATETIME NULL
	--	)
	--CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPMAXSALESMANFEEDBACK(created_date ASC)
	--INSERT INTO #TEMPMAXSALESMANFEEDBACK
	--select max(s.created_date) as Created_Date from ENQURIES_SALESMANFEEDBACK s
	--inner join tbl_CRM_Import h on h.Crm_Id=s.enq_crm_id
	--group by s.enq_crm_id
	----End of Rev 3.0
	
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
 
 --IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSALESMAN') AND TYPE IN (N'U'))
	--	DROP TABLE #TEMPSALESMAN
	--CREATE TABLE #TEMPSALESMAN
	--	(
	--		cnt_id int,
	--		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_UCC NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	--		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
	--	)
	--CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPSALESMAN(cnt_internalId,cnt_contactType ASC)
	--INSERT INTO #TEMPSALESMAN
	-- Select cnt_id,cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType
 --                      from tbl_master_contact  where Substring(cnt_internalId,1,2)='AG' 
 --                      union all 
 --                      select cnt_id,cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType
 --                      from (select row_number() over (partition by emp_cntId order by emp_id desc ) as Row, emp_cntId,emp_id 
 --                      from tbl_trans_employeeCTC where emp_type=19) ctc inner join tbl_master_contact cnt on ctc.emp_cntId=cnt.cnt_internalId 
 --                      where ctc.Row=1  



    --drop TABLE TASKMANAGEMENT_LISTING


	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'TASKMANAGEMENT_LISTING') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE TASKMANAGEMENT_LISTING
			(
			  USERID INT,
			  SEQ INT,
			  TASK_ID INT,
			  STARTDATE datetime NULL,
			  DUETDATE datetime NULL,
			  Task_Name NVARCHAR(300) NULL,
			  Task_Priority NVARCHAR(200) NULL,
			  Task_Details NVARCHAR(500) NULL,			  
			  CREATED_DATE datetime NULL,
			  CREATED_BY NVARCHAR(50) NULL,
			  MODIFIED_BY NVARCHAR(50) NULL,
			  MODIFIED_DATE datetime NULL,			
			  Task_STATUS NVARCHAR(50) NULL,
			  ASSIGNED_TO NVARCHAR(200) NULL,			
			  ReASSIGNED_TO NVARCHAR(200) NULL,			 
			  SalesmanAssign_date datetime NULL,
			  ReSalesmanAssign_date datetime NULL,
			  ASSIGNED_TOID NVARCHAR(200) NULL
			)
			CREATE NONCLUSTERED INDEX IX1 ON TASKMANAGEMENT_LISTING (SEQ)
		END
	DELETE FROM TASKMANAGEMENT_LISTING WHERE USERID=@USERID

	if(@Is_PageLoad='0')
	Begin

	SET @Strsql=' INSERT INTO TASKMANAGEMENT_LISTING (USERID,SEQ,TASK_ID,STARTDATE,DUETDATE,Task_Name,Task_Priority,Task_Details,ASSIGNED_TO,SalesmanAssign_date,ReASSIGNED_TO,ReSalesmanAssign_date '
	SET @Strsql+=' ,CREATED_BY,CREATED_DATE,MODIFIED_BY,MODIFIED_DATE,Task_STATUS,ASSIGNED_TOID) '
	SET @Strsql+=' select '+STR(@USERID)+',ROW_NUMBER() OVER(ORDER BY task.TASK_STARTDATE desc) AS SEQ,task.TASK_ID,task.TASK_STARTDATE,task.TASK_DUEDATE,task.TASK_NAME,TASKPRIORITY_FROM PRIORITY,task.TASK_DETAILS,cnt1.Assignsalesman_name,task.TASK_SMANASSIGNDATE '
	SET @Strsql+=',ReAssignSalesman_Name,TASK_SMANREASSIGNDATE, '
	SET @Strsql+=' u.user_name as CREATEDBY,CREATEDON,u1.user_name as UPDATEDBY,UPDATEDON '	
	--SET @Strsql+=' ,case when isnull(TASK_SALESMANASSIGNID,0)=0 then ''Pending'' when isnull(TASK_SALESMANASSIGNID,0)<>0 then ''Re Assigned'' when isnull(TASK_SALESMANASSIGNID,0)<>0 then ''Assigned'' else '''' end as STATUS   '
	SET @Strsql+=' , taskstatus.TASK_STATUS as STATUS'
	SET @Strsql+=' ,user_loginId '
	SET @Strsql+='from MASTER_TASKMANAGEMENT task '
	SET @Strsql+=' inner join MASTER_TASKPRIORITY on TASKPRIORITY_ID=TASK_PRIORITY '
	SET @Strsql+='left outer join ( select usr.user_id, trim(CON.cnt_firstName)+ (case when trim(CON.cnt_middleName)<>'''' then '''' +CON.cnt_middleName else '''' end)+ (case when trim(CON.cnt_lastName)<>'''' then '''' +CON.cnt_lastName else '''' end)  +  ( CON.cnt_UCC ) Assignsalesman_name '
	SET @Strsql+=' from tbl_master_employee em '
	SET @Strsql+='inner join tbl_master_user usr on em.emp_contactid = usr.user_contactId '
	SET @Strsql+='inner join #TEMPCONTACT CON on CON.cnt_internalId=em.emp_contactId '
	SET @Strsql+=' ) cnt1 on cnt1.user_id = task.TASK_SALESMANASSIGNID '
	SET @Strsql+='left outer join ( select usrReAssign.user_id, trim(CONReAssign.cnt_firstName)+ (case when trim(CONReAssign.cnt_middleName)<>'''' then '''' +CONReAssign.cnt_middleName else '''' end)+ (case when trim(CONReAssign.cnt_lastName)<>'''' then '''' +CONReAssign.cnt_lastName else '''' end)  + ( CONReAssign.cnt_UCC ) ReAssignSalesman_Name '
	SET @Strsql+=',usrReAssign.user_loginId from tbl_master_employee emReAssign '
	SET @Strsql+='inner join tbl_master_user usrReAssign on emReAssign.emp_contactid = usrReAssign.user_contactId '
	SET @Strsql+='inner join #TEMPCONTACT CONReAssign on CONReAssign.cnt_internalId=emReAssign.emp_contactId '
	SET @Strsql+=') ReAssign on ReAssign.user_id = task.TASK_SALESMANREASSIGNID '
	SET @Strsql+='left outer join(select user_id,user_name from tbl_master_user ) u on cast(u.user_id as int)=task.CREATEDBY '
	SET @Strsql+='left outer join(select user_id,user_name from tbl_master_user ) u1 on cast(u1.user_id as int)=task.UPDATEDBY '
	SET @Strsql+='left outer join FTSTASKMANAGEMENTDETAIL taskstatus on taskstatus.TASK_ID=task.TASK_ID and taskstatus.ISACTIVE=1'
	SET @Strsql+=' where CONVERT(NVARCHAR(10),task.TASK_STARTDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+=' and isnull(task.TASK_ISDELETED,0)=0  '	
	SET @Strsql+=' and task.TASK_PRIORITY in ('+@TaskPriority+') '
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql
	end
	drop table #TEMPCONTACT
	
	SET NOCOUNT OFF
END

