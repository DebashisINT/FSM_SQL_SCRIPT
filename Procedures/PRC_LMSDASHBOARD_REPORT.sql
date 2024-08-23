
-- exec PRC_FTSDASHBOARD_REPORT @TODAYDATE='2022-03-30', @STATEID='15,3,19,28', @DESIGNID='',@USERID=378,@EMPID='',@BRANCHID='1,118,119,122',@ACTION='AT_WORK',@RPTTYPE='Detail'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMSDASHBOARD_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMSDASHBOARD_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_LMSDASHBOARD_REPORT]
(

@ACTION NVARCHAR(20) ='',
@RPTTYPE NVARCHAR(20) ='',
@USERID INT =0,
@STATEID NVARCHAR(max)='',
@BRANCHID NVARCHAR(max)=''

) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Priti Roy on 20/08/2024
0027667:LMS Dashboard
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	
			IF OBJECT_ID('tempdb..#USERTABLE') IS NOT NULL
			DROP TABLE #USERTABLE
			CREATE TABLE #USERTABLE
			(
			user_contactId nvarchar(100),
			user_id  int,
			user_name NVARCHAR(500),
			USER_LOGINID NVARCHAR(500),
			TOPICID int
			)

			INSERT INTO #USERTABLE
			SELECT user_contactId,user_id,user_name,USER_LOGINID,TOPICID  FROM TBL_MASTER_USER U      
			INNER JOIN FTS_EmployeeBranchMap EBM ON U.user_contactId=EBM.Emp_Contactid        
			inner join LMS_TOPIC_BRANCHMAP BRANCHMAP on BRANCHMAP.TOPIC_BRANCHID=EBM.BranchId    
			where U.user_inactive='N'     
			UNION ALL     
 
			SELECT user_contactId,user_id,user_name,USER_LOGINID,TOPICID  FROM TBL_MASTER_USER U  
			INNER JOIN tbl_trans_employeeCTC CTC ON U.user_contactId=CTC.emp_cntId                        
			INNER JOIN LMS_TOPIC_DESIGMAP DESIGMAP on DESIGMAP.TOPIC_DESIGID=CTC.emp_Designation     where U.user_inactive='N'     
 
			UNION ALL     
 
			SELECT user_contactId,user_id,user_name,USER_LOGINID,TOPICID FROM TBL_MASTER_USER U      
			INNER JOIN tbl_trans_employeeCTC CTC ON U.user_contactId=CTC.emp_cntId                            
			INNER JOIN LMS_TOPIC_DEPTMAP DEPTMAP on DEPTMAP.TOPIC_DEPTID=CTC.emp_Department     where U.user_inactive='N'   
 
			UNION ALL    
 
			SELECT user_contactId,user_id,user_name,USER_LOGINID,TOPICID FROM TBL_MASTER_USER U     
			INNER JOIN  LMS_TOPIC_EMPMAP EMPMAP on EMPMAP.TOPIC_USERID=U.user_id     where U.user_inactive='N'

			IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
			DROP TABLE #BRANCH_LIST
			CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
			CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

			IF @BRANCHID<>''
			BEGIN
				SET @SqlStrTable=''
				SET @BRANCHID=REPLACE(@BRANCHID,'''','')
				SET @sqlStrTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
				EXEC SP_EXECUTESQL @SqlStrTable
			END



		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'LMSDASHBOARD_LIST') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE LMSDASHBOARD_LIST
			(
			    USERID INT,
				SEQ BIGINT,
				USER_ID bigint,
				USER_NAME varchar(50),
				USER_LOGINID varchar(50),
				TOPICID bigint,
				TOPICNAME nvarchar(300),
				CONTENT_ID bigint,
				CONTENTTITLE nvarchar(100),
				CONTENTDESC nvarchar(300),				
				COMPLETIONSTATUS nvarchar(20)				
			)
			CREATE NONCLUSTERED INDEX IX1 ON LMSDASHBOARD_LIST (SEQ)
		END
	DELETE FROM LMSDASHBOARD_LIST WHERE USERID=@USERID

	SET @Strsql=''
	

	IF @ACTION='ALL' AND @RPTTYPE='Summary'
	Begin
		SET @Strsql=@Strsql+ ' SELECT '
			SET @Strsql=@Strsql+ ''+cast(@USERID as varchar(250)) +','	
			SET @Strsql=@Strsql+ ' ROW_NUMBER() OVER(ORDER BY tbl.ID desc) AS SEQ,tbl.USERID,tbl.USER_NAME,tbl.USER_LOGINID,TOPICID,TOPICNAME,CONTENT_ID,CONTENTTITLE,CONTENTDESC,COMPLETIONSTATUS

			from (

			 SELECT ID,USERID,MUSER.USER_NAME,MUSER.USER_LOGINID,INFO.TOPICID,TOPIC.TOPICNAME,CONTENT_ID,CONTENTTITLE,CONTENTDESC,CONTENT.CREATEDON ASSIGNEDON  
			 ,CASE WHEN ISCONTENTCOMPLETED=0 THEN ''Pending'' WHEN ISCONTENTCOMPLETED=1 THEN ''Completed'' END COMPLETIONSTATUS 
			  FROM FSMUSERLMSTOPICCONTENTINFO INFO 
			 inner join  TBL_MASTER_USER MUSER on INFO.USERID=MUSER.USER_ID inner join  LMS_TOPICS TOPIC ON TOPIC.TOPICID=INFO.TOPICID 
			 inner join  LMS_CONTENT CONTENT ON CONTENT.CONTENTID=INFO.CONTENT_ID

			 union all


			SELECT  CONTENTID as ID,
			user_id USERID,user_name,USERLIST.USER_LOGINID
			,TOPICMAP.TOPICID,TOPICMAP.TOPICNAME
			,CONTENT.CONTENTID CONTENT_ID,CONTENTTITLE,CONTENTDESC,CONTENT.CREATEDON ASSIGNEDON  
			,''Untouched''  COMPLETIONSTATUS 
			FROM  LMS_CONTENT  CONTENT
			inner join   LMS_TOPICS TOPICMAP on CONTENT.CONTENT_TOPICID=TOPICMAP.TOPICID
			inner join #USERTABLE USERLIST on USERLIST.TOPICID=TOPICMAP.TOPICID

			where NOT EXISTS  (select ''Y'' from FSMUSERLMSTOPICCONTENTINFO where USERID=user_id    and CONTENT_ID=CONTENT.CONTENTID) 
			)tbl 
			left outer join tbl_master_user MUser on MUser.user_id=tbl.USERID
			left outer join FTS_EmployeeBranchMap EMP on EMP.Emp_Contactid=MUser.user_contactId
			left outer join tbl_master_branch branch on branch.branch_id=EMP.BranchId
			left outer join tbl_trans_employeeCTC CTC on CTC.emp_cntId=MUser.user_contactId
			left outer join tbl_master_designation DESIGNATION on DESIGNATION.deg_id=CTC.emp_Designation
			
			'


			IF @BRANCHID<>''
			SET @Strsql+=' where  EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=branch.branch_id) '



			INSERT INTO LMSDASHBOARD_LIST (USERID, SEQ,USER_ID,USER_NAME,USER_LOGINID,TOPICID,TOPICNAME,CONTENT_ID,CONTENTTITLE,CONTENTDESC,COMPLETIONSTATUS )
			
			
			EXEC (@Strsql)

	End
	
	DROP TABLE #USERTABLE
	DROP TABLE #BRANCH_LIST

	SET NOCOUNT OFF
END
GO