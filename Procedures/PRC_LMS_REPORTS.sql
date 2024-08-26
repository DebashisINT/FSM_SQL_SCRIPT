IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_REPORTS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_REPORTS] AS' 
END
GO
ALTER PROC [dbo].[PRC_LMS_REPORTS]
(
@ACTION NVARCHAR(100)=NULL,
@selected NVARCHAR(max)=NULL,
@USER_IDS NVARCHAR(MAX)=NULL,
@ISPAGELOAD CHAR(1)='0',
@SearchKey NVARCHAR(50) ='',
@TOPIC_IDS NVARCHAR(MAX)=NULL,
@fromdate DATETIME=NULL,
@todate DATETIME=NULL,
@CONTENT_IDS NVARCHAR(MAX)=NULL,
@USER_ID BIGINT=0,
@ReturnValue BIGINT=0 OUTPUT,
@_Status  NVARCHAR(100)=NULL,
@STATEID NVARCHAR(max)='',
@BRANCHID NVARCHAR(max)=''
)
AS
/*************************************************************************************************************************
Written by : Priti Roy ON 08/08/2024
Module	   :LMS- Reports.Refer: 0027567
******************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	Declare @LastCount bigint=0,@QUESTIONS_ID bigint=0,@LASTCOUNTOPTIONS bigint=0,@LASTCOUNTTOPICMAP  bigint=0,@LASTCOUNTCATEGORYMAP  bigint=0,@TOPICID bigint=0,@CATEGORYID bigint=0
	DECLARE @sqlStrTable NVARCHAR(MAX)
	
	IF OBJECT_ID('tempdb..#USER_LIST') IS NOT NULL
	DROP TABLE #USER_LIST
	CREATE TABLE #USER_LIST (USERID BIGINT)	
	IF @USER_IDS<>''
	BEGIN
		set @USER_IDS = REPLACE(''''+@USER_IDS+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #USER_LIST select user_id from TBL_MASTER_USER where user_id in('+@USER_IDS+')'
		EXEC SP_EXECUTESQL @sqlStrTable
	END

	IF OBJECT_ID('tempdb..#TOPIC_LIST') IS NOT NULL
	DROP TABLE #TOPIC_LIST
	CREATE TABLE #TOPIC_LIST (TOPICID BIGINT)	
	IF @TOPIC_IDS<>''
	BEGIN
		set @TOPIC_IDS = REPLACE(''''+@TOPIC_IDS+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #TOPIC_LIST select TOPICID from LMS_TOPICS where TOPICID in('+@TOPIC_IDS+')'
		EXEC SP_EXECUTESQL @sqlStrTable
	END

	IF OBJECT_ID('tempdb..#CONTENT_LIST') IS NOT NULL
	DROP TABLE #CONTENT_LIST
	CREATE TABLE #CONTENT_LIST (CONTENTID BIGINT)	
	IF @CONTENT_IDS<>''
	BEGIN
		set @CONTENT_IDS = REPLACE(''''+@CONTENT_IDS+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #CONTENT_LIST select CONTENTID from LMS_CONTENT where CONTENTID in('+@CONTENT_IDS+')'
		EXEC SP_EXECUTESQL @sqlStrTable
	END		


	  
	IF @ACTION='GETLISTINGDETAILS'
	BEGIN
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'LMS_REPORTSLIST') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE LMS_REPORTSLIST
			(
				USERID INT,
				SEQ BIGINT,
				USER_ID bigint,
				USER_NAME varchar(50),
				TOPICID bigint,
				TOPICNAME nvarchar(300),
				CONTENT_ID bigint,
				CONTENTTITLE nvarchar(100),
				CONTENTDESC nvarchar(300),
				ASSIGNEDON datetime,
				COMPLETIONSTATUS nvarchar(20),
				TIMESPENT nvarchar(20),
				CompletionDate datetime,
				FirstAccessDateandTime datetime,
				LastAccessDateandTime datetime,
				CompletionDurationDays int,
				user_loginId varchar(50)
			)
			CREATE NONCLUSTERED INDEX IX1PF_PURREGPROD_RPT ON LMS_REPORTSLIST (SEQ)
		END
		DELETE FROM LMS_REPORTSLIST where USERID=@USER_ID

			DECLARE @STR NVARCHAR(MAX)='',@Status_Option int=0		
			if(@_Status='0')
			Begin
				set @_Status='Pending'
			End
			Else if(@_Status='1')
			Begin
				set @_Status='Completed'
			end
			Else if(@_Status='2')
			Begin
				set @_Status='Untouched'
			end

			--SET @STR=@STR+ ' SELECT '
			--SET @STR=@STR+ ''+cast(@USER_ID as varchar(250)) +','			
			--SET @STR=@STR+ 'ROW_NUMBER() OVER(ORDER BY ID desc) AS SEQ,USERID,MUSER.USER_NAME'
			----SET @STR=@STR+ ' ,INFO.TOPICID,TOPIC.TOPICNAME'
			--SET @STR=@STR+ '  ,CASE WHEN isnull(INFO.TOPICID,0)=0 then TOPICMAP.TOPICID else INFO.TOPICID end as TOPICID'
			--SET @STR=@STR+ ' ,CASE WHEN isnull(INFO.TOPICID,0)=0 then TOPICMAP.TOPICNAME else TOPIC.TOPICNAME end as TOPICNAME'
			--SET @STR=@STR+ ' ,CONTENT_ID,CONTENTTITLE,CONTENTDESC,CONTENT.CREATEDON ASSIGNEDON '

			----SET @STR=@STR+ ' ,CASE WHEN ISCONTENTCOMPLETED=0 THEN ''Pending'' WHEN ISCONTENTCOMPLETED=1 THEN ''Completed'' END COMPLETIONSTATUS'
			--SET @STR=@STR+ ' ,CASE WHEN ISCONTENTCOMPLETED=0 THEN ''Pending'' WHEN ISCONTENTCOMPLETED=1 THEN ''Completed'' Else ''Untouched'' END COMPLETIONSTATUS'
			--SET @STR=@STR+ ' ,CONTENT_WATCH_LENGTH AS TIMESPENT,'
			--SET @STR=@STR+ ' case when ISCONTENTCOMPLETED=1 THEN CONTENTLASTVIEW else null end CompletionDate,'
			--SET @STR=@STR+ ' CREATED_ON as FirstAccessDateandTime'
			--SET @STR=@STR+ ' ,CONTENTLASTVIEW as LastAccessDateandTime'
			--SET @STR=@STR+ ' ,DATEDIFF(day,CREATED_ON, CONTENTLASTVIEW) as CompletionDurationDays'
			----SET @STR=@STR+ ' FROM FSMUSERLMSTOPICCONTENTINFO INFO'
			----SET @STR=@STR+ ' inner join  TBL_MASTER_USER MUSER on INFO.USERID=MUSER.USER_ID'
			----SET @STR=@STR+ ' inner join  LMS_TOPICS TOPIC ON TOPIC.TOPICID=INFO.TOPICID'
			----SET @STR=@STR+ ' inner join  LMS_CONTENT CONTENT ON CONTENT.CONTENTID=INFO.CONTENT_ID'

			--SET @STR=@STR+ ' FROM  LMS_CONTENT  CONTENT  '
			-- SET @STR=@STR+ ' left outer join  FSMUSERLMSTOPICCONTENTINFO INFO  ON CONTENT.CONTENTID=INFO.CONTENT_ID'
			-- SET @STR=@STR+ ' left outer join  TBL_MASTER_USER MUSER on INFO.USERID=MUSER.USER_ID '
			-- SET @STR=@STR+ ' left outer join  LMS_TOPICS TOPIC ON TOPIC.TOPICID=INFO.TOPICID'
			-- SET @STR=@STR+ ' left outer join  LMS_TOPICS TOPICMAP ON TOPICMAP.TOPICID=CONTENT.CONTENT_TOPICID'

		 --   SET @STR=@STR+ '  WHERE CONVERT(nvarchar(10),CONTENT.CREATEDON ,120) BETWEEN '''+CONVERT(nvarchar(10),@fromdate,120)+'''  AND '''+CONVERT(nvarchar(10),@todate,120)+ ''' '

			--IF @USER_IDS<>''
			--SET @STR=@STR+ '  and EXISTS (SELECT USERID FROM #USER_LIST AS F WHERE F.USERID=INFO.USERID) ' 

			--IF @TOPIC_IDS<>''
			--SET @STR=@STR+ '  and EXISTS (SELECT TOPICID FROM #TOPIC_LIST AS F WHERE F.TOPICID=INFO.TOPICID) ' 

			--IF @CONTENT_IDS<>''
			--SET @STR=@STR+ '  and EXISTS (SELECT CONTENTID FROM #CONTENT_LIST AS F WHERE F.CONTENTID=INFO.CONTENT_ID) '
			
			--If @_Status<>''
			--SET @STR=@STR+ ' and ISCONTENTCOMPLETED='+cast(@Status_Option as varchar(100)) +''

			SET @STR=@STR+ ' SELECT '
			SET @STR=@STR+ ''+cast(@USER_ID as varchar(250)) +','	
			SET @STR=@STR+ ' ROW_NUMBER() OVER(ORDER BY ID desc) AS SEQ,USERID,USER_NAME,TOPICID,TOPICNAME,CONTENT_ID,CONTENTTITLE,CONTENTDESC,ASSIGNEDON,COMPLETIONSTATUS,TIMESPENT,CompletionDate,FirstAccessDateandTime,LastAccessDateandTime,CompletionDurationDays,USER_LOGINID

			from (

			 SELECT ID,USERID,MUSER.USER_NAME,INFO.TOPICID,TOPIC.TOPICNAME,CONTENT_ID,CONTENTTITLE,CONTENTDESC,CONTENT.CREATEDON ASSIGNEDON  
			 ,CASE WHEN ISCONTENTCOMPLETED=0 THEN ''Pending'' WHEN ISCONTENTCOMPLETED=1 THEN ''Completed'' END COMPLETIONSTATUS 
			 ,CONTENT_WATCH_LENGTH AS TIMESPENT, case when ISCONTENTCOMPLETED=1 THEN CONTENTLASTVIEW else null end CompletionDate
			 , CREATED_ON as FirstAccessDateandTime ,CONTENTLASTVIEW as LastAccessDateandTime ,DATEDIFF(day,CREATED_ON, CONTENTLASTVIEW) as CompletionDurationDays 
			 ,MUSER.user_loginId
			 FROM FSMUSERLMSTOPICCONTENTINFO INFO 
			 inner join  TBL_MASTER_USER MUSER on INFO.USERID=MUSER.USER_ID inner join  LMS_TOPICS TOPIC ON TOPIC.TOPICID=INFO.TOPICID 
			 inner join  LMS_CONTENT CONTENT ON CONTENT.CONTENTID=INFO.CONTENT_ID

			 union all


			SELECT  CONTENTID as ID,
			user_id USERID,user_name
			,TOPICMAP.TOPICID,TOPICMAP.TOPICNAME
			,CONTENT.CONTENTID CONTENT_ID,CONTENTTITLE,CONTENTDESC,CONTENT.CREATEDON ASSIGNEDON  
			,''Untouched''  COMPLETIONSTATUS ,'''' AS TIMESPENT
			, null as CompletionDate, null as FirstAccessDateandTime ,null as LastAccessDateandTime 
			,0 as CompletionDurationDays 
			,USER_LOGINID
			FROM  LMS_CONTENT  CONTENT
			inner join   LMS_TOPICS TOPICMAP on CONTENT.CONTENT_TOPICID=TOPICMAP.TOPICID
			inner join

			(SELECT user_id,user_name,USER_LOGINID,TOPICID FROM TBL_MASTER_USER U 
			INNER JOIN FTS_EmployeeBranchMap EBM ON U.user_contactId=EBM.Emp_Contactid 

			inner join LMS_TOPIC_BRANCHMAP BRANCHMAP on BRANCHMAP.TOPIC_BRANCHID=EBM.BranchId 
			where U.user_inactive=''N''
			UNION ALL
			SELECT user_id,user_name,USER_LOGINID,TOPICID FROM TBL_MASTER_USER U 
			INNER JOIN tbl_trans_employeeCTC CTC ON U.user_contactId=CTC.emp_cntId 
                
			INNER JOIN LMS_TOPIC_DESIGMAP DESIGMAP on DESIGMAP.TOPIC_DESIGID=CTC.emp_Designation
			where U.user_inactive=''N''
			UNION ALL
			SELECT user_id,user_name,USER_LOGINID,TOPICID FROM TBL_MASTER_USER U 
			INNER JOIN tbl_trans_employeeCTC CTC ON U.user_contactId=CTC.emp_cntId 
                    
			INNER JOIN LMS_TOPIC_DEPTMAP DEPTMAP on DEPTMAP.TOPIC_DEPTID=CTC.emp_Department
			where U.user_inactive=''N''
			UNION ALL
			SELECT user_id,user_name,USER_LOGINID,TOPICID FROM TBL_MASTER_USER U
			INNER JOIN  LMS_TOPIC_EMPMAP EMPMAP on EMPMAP.TOPIC_USERID=U.user_id
			where U.user_inactive=''N'')tbl on tbl.TOPICID=TOPICMAP.TOPICID

			where NOT EXISTS  (select ''Y'' from FSMUSERLMSTOPICCONTENTINFO where USERID=user_id    and CONTENT_ID=CONTENT.CONTENTID) 
			)tbl '

			SET @STR=@STR+ '  WHERE CONVERT(nvarchar(10),ASSIGNEDON ,120) BETWEEN '''+CONVERT(nvarchar(10),@fromdate,120)+'''  AND '''+CONVERT(nvarchar(10),@todate,120)+ ''' '

			IF @USER_IDS<>''
			SET @STR=@STR+ '  and EXISTS (SELECT USERID FROM #USER_LIST AS F WHERE F.USERID=tbl.USERID) ' 

			IF @TOPIC_IDS<>''
			SET @STR=@STR+ '  and EXISTS (SELECT TOPICID FROM #TOPIC_LIST AS F WHERE F.TOPICID=tbl.TOPICID) ' 

			IF @CONTENT_IDS<>''
			SET @STR=@STR+ '  and EXISTS (SELECT CONTENTID FROM #CONTENT_LIST AS F WHERE F.CONTENTID=tbl.CONTENT_ID) '
			
			If @_Status<>''
			SET @STR=@STR+ ' and COMPLETIONSTATUS='''+cast(@_Status as varchar(100)) +''''

			INSERT INTO LMS_REPORTSLIST (USERID, SEQ,USER_ID,USER_NAME,TOPICID,TOPICNAME,CONTENT_ID,CONTENTTITLE,CONTENTDESC,ASSIGNEDON,COMPLETIONSTATUS,TIMESPENT,CompletionDate,FirstAccessDateandTime,LastAccessDateandTime,CompletionDurationDays,user_loginId )
			
			
			EXEC (@STR)

			--select @STR

		--END

	END
	ELSE IF (@ACTION='GETTOPIC')
	BEGIN	    
	 
		Select TOPICID,TOPICNAME from LMS_TOPICS  WHERE TOPICSTATUS=1
	  
    END
	ELSE IF (@ACTION='GetContent')
	BEGIN  
	 -- if(@ID<>0)
	 -- Begin
		--Select CATEGORYID,CATEGORYNAME from LMS_CATEGORY  WHERE CATEGORYSTATUS=1
		--union All
		--Select CATEGORYID,CATEGORYNAME from LMS_CATEGORY CAT
		--inner join LMS_QUESTIONS_CATEGORYMAP MAP on CAT.CATEGORYID=MAP.QUESTIONS_CATEGORYID
		--where MAP.QUESTIONS_ID=@ID
	 -- End
  --    else
	 -- Begin
		select CONTENTID,CONTENTTITLE,CONTENTDESC from LMS_CONTENT  where CONTENTSTATUS=1
	  --End
      
    END
	
	ELSE IF @ACTION='GETUSER'
	BEGIN
		SELECT top(10) user_id,user_name,user_loginId FROM TBL_MASTER_USER  
		where  user_name like '%' + @SearchKey + '%'
	END
	ELSE IF @ACTION='GETStatus'
	BEGIN
		Select 'Pending' as ContentStatus
		Union 
		Select 'Completed' as ContentStatus
	End
	ELSE IF(@ACTION='GETREPORTSCOUNTDATA')
	BEGIN
		DECLARE @TotalPending INT = 0, @TotalCOMPLETED INT = 0, @TotalUntouched INT = 0

		IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'LMS_REPORTSLIST') AND TYPE IN (N'U'))
		BEGIN
			

			SET @TotalPending = ISNULL((SELECT COUNT(0) from LMS_REPORTSLIST  where COMPLETIONSTATUS='Pending'),0)
			SET @TotalCOMPLETED = ISNULL((SELECT COUNT(0) from LMS_REPORTSLIST  where COMPLETIONSTATUS='Completed'),0)
			SET @TotalUntouched = ISNULL((SELECT COUNT(0) from LMS_REPORTSLIST  where COMPLETIONSTATUS='Untouched'),0)
			
		END

		SELECT @TotalPending AS cnt_TotalPending, @TotalCOMPLETED AS cnt_TotalCOMPLETED, @TotalUntouched AS cnt_TotalUntouchedContent

	END

	SET NOCOUNT OFF
END
GO

