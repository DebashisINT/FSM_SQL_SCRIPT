


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_QUESTIONS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_QUESTIONS] AS' 
END
GO


ALTER PROC [dbo].[PRC_LMS_QUESTIONS]
(
@ACTION VARCHAR(500)=NULL,
@ID BIGINT=NULL,
@selected VARCHAR(max)=NULL,
@USER_ID BIGINT=NULL,
@ISPAGELOAD CHAR(1)='0',

@QUESTIONNAME NVARCHAR(250)=NULL,
@QUESTIONDESCRIPTION NVARCHAR(500)=NULL,
@OPTION1 NVARCHAR(250)=NULL,
@OPTION2 NVARCHAR(250)=NULL,
@OPTION3 NVARCHAR(250)=NULL,
@OPTION4 NVARCHAR(250)=NULL,
@POINT1 int=0,
@POINT2 int=0,
@POINT3 int=0,
@POINT4 int=0,
@CORRECT1 int=0,
@CORRECT2 int=0,
@CORRECT3 int=0,
@CORRECT4 int=0,
@TOPIC_IDS NVARCHAR(MAX)=NULL,
@CATEGORY_IDS NVARCHAR(MAX)=NULL,
-- Rev Sanchita
@MODE VARCHAR(50)=NULL,
@CONTENTID BIGINT = 0 ,
-- End of Rev Sanchita
@ReturnValue BIGINT=0 OUTPUT
)
AS
/*************************************************************************************************************************
Written by : Priti Roy ON 02/07/2024
Module	   : LMS - Question Master implementation.Refer: 0027545
******************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	Declare @LastCount bigint=0,@QUESTIONS_ID bigint=0,@LASTCOUNTOPTIONS bigint=0,@LASTCOUNTTOPICMAP  bigint=0,@LASTCOUNTCATEGORYMAP  bigint=0,@TOPICID bigint=0,@CATEGORYID bigint=0
	DECLARE @sqlStrTable NVARCHAR(MAX)
	-- Rev Sanchita
	DECLARE @QUESTIONMAPID_AUTO BIGINT
	-- End of Rev Sanchita

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

	IF OBJECT_ID('tempdb..#CATEGORY_LIST') IS NOT NULL
	DROP TABLE #CATEGORY_LIST
	CREATE TABLE #CATEGORY_LIST (CATEGORYID BIGINT)	
	IF @CATEGORY_IDS<>''
	BEGIN
		set @CATEGORY_IDS = REPLACE(''''+@CATEGORY_IDS+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #CATEGORY_LIST select CATEGORYID from LMS_CATEGORY where CATEGORYID in('+@CATEGORY_IDS+')'
		EXEC SP_EXECUTESQL @sqlStrTable
	END		

	IF(@ACTION='ADD')
	BEGIN
		
			--IF OBJECT_ID('tempdb..#TOPIC_LIST') IS NOT NULL
			--DROP TABLE #TOPIC_LIST
			--CREATE TABLE #TOPIC_LIST (TOPICID BIGINT)	
			--IF @TOPIC_IDS<>''
			--BEGIN
			--	set @TOPIC_IDS = REPLACE(''''+@TOPIC_IDS+'''',',',''',''')
			--	SET @sqlStrTable=''
			--	SET @sqlStrTable=' INSERT INTO #TOPIC_LIST select TOPICID from LMS_TOPICS where TOPICID in('+@TOPIC_IDS+')'
			--	EXEC SP_EXECUTESQL @sqlStrTable
			--END

			--IF OBJECT_ID('tempdb..#CATEGORY_LIST') IS NOT NULL
			--DROP TABLE #CATEGORY_LIST
			--CREATE TABLE #CATEGORY_LIST (CATEGORYID BIGINT)	
			--IF @CATEGORY_IDS<>''
			--BEGIN
			--	set @CATEGORY_IDS = REPLACE(''''+@CATEGORY_IDS+'''',',',''',''')
			--	SET @sqlStrTable=''
			--	SET @sqlStrTable=' INSERT INTO #CATEGORY_LIST select CATEGORYID from LMS_CATEGORY where CATEGORYID in('+@CATEGORY_IDS+')'
			--	EXEC SP_EXECUTESQL @sqlStrTable
			--END

		IF NOT EXISTS (SELECT 1 FROM LMS_QUESTIONS WHERE QUESTIONS_NAME=@QUESTIONNAME )
		BEGIN			

			

			select  @LastCount=iSNULL(MAX(QUESTIONS_ID),0) from LMS_QUESTIONS  
			INSERT INTO LMS_QUESTIONS(QUESTIONS_ID,QUESTIONS_NAME,QUESTIONS_DESCRIPTN,CREATEDBY,CREATEDON)
			VALUES (@LastCount+1,Ltrim(Rtrim(Replace(@QUESTIONNAME,'?','')))+' '+'?',@QUESTIONDESCRIPTION,@USER_ID,GETDATE())		

			set @QUESTIONS_ID=@LastCount+1;

			select  @LASTCOUNTOPTIONS=iSNULL(MAX(QUESTIONS_OPTIONSID),0) from LMS_QUESTIONSOPTIONS 
			INSERT INTO LMS_QUESTIONSOPTIONS(QUESTIONS_OPTIONSID,QUESTIONS_ID,OPTIONS_NUMBER1,OPTIONS_POINT1,OPTIONS_CORRECT1,OPTIONS_NUMBER2,OPTIONS_POINT2,OPTIONS_CORRECT2,OPTIONS_NUMBER3,OPTIONS_POINT3,OPTIONS_CORRECT3,
			OPTIONS_NUMBER4,OPTIONS_POINT4,OPTIONS_CORRECT4,CREATEDBY,CREATEDON
			)
			VALUES (@LASTCOUNTOPTIONS+1,@QUESTIONS_ID,@OPTION1,@POINT1,@CORRECT1,@OPTION2,@POINT2,@CORRECT2,@OPTION3,@POINT3,@CORRECT3,@OPTION4,@POINT4,@CORRECT4			
			,@USER_ID,GETDATE())		


			declare DB_CURSOR_TOPIC_LIST cursor for
			SELECT TOPICID FROM #TOPIC_LIST 	
			open DB_CURSOR_TOPIC_LIST
			fetch next from DB_CURSOR_TOPIC_LIST into @TOPICID
			while @@FETCH_STATUS=0
			begin
				select  @LASTCOUNTTOPICMAP=iSNULL(MAX(QUESTIONS_TOPICMAP_ID),0) from LMS_QUESTIONS_TOPICMAP 
				INSERT INTO LMS_QUESTIONS_TOPICMAP(QUESTIONS_TOPICMAP_ID,QUESTIONS_TOPICID,QUESTIONS_ID,CREATEDBY,CREATEDON)
				select @LASTCOUNTTOPICMAP+1,@TOPICID, @QUESTIONS_ID,@USER_ID,GETDATE() 

			fetch next from DB_CURSOR_TOPIC_LIST into @TOPICID
			END
			close DB_CURSOR_TOPIC_LIST
			deallocate DB_CURSOR_TOPIC_LIST


			declare DB_CURSOR_CATEGORY_LIST cursor for
			SELECT CATEGORYID FROM #CATEGORY_LIST	
			open DB_CURSOR_CATEGORY_LIST
			fetch next from DB_CURSOR_CATEGORY_LIST into @CATEGORYID
			while @@FETCH_STATUS=0
			begin
				select  @LASTCOUNTCATEGORYMAP=iSNULL(MAX(QUESTIONS_CATEGORYMAP_ID),0) from LMS_QUESTIONS_CATEGORYMAP 
				INSERT INTO LMS_QUESTIONS_CATEGORYMAP(QUESTIONS_CATEGORYMAP_ID,QUESTIONS_CATEGORYID,QUESTIONS_ID,CREATEDBY,CREATEDON)
				select @LASTCOUNTCATEGORYMAP+1,@CATEGORYID, @QUESTIONS_ID,@USER_ID,GETDATE()

			fetch next from DB_CURSOR_CATEGORY_LIST into @CATEGORYID
			END
			close DB_CURSOR_CATEGORY_LIST
			deallocate DB_CURSOR_CATEGORY_LIST

			DROP TABLE #TOPIC_LIST
			DROP TABLE #CATEGORY_LIST

			-- Rev Sanchita
			IF(@MODE = 'AddOnFly')
			BEGIN
				SET @QUESTIONMAPID_AUTO = isnull((SELECT MAX(CONTENT_QUESTIONMAPID) FROM LMS_CONTENT_QUESTIONMAP ),0)+1

				INSERT INTO LMS_CONTENT_QUESTIONMAP (CONTENT_QUESTIONMAPID, CONTENTID, CONTENT_QUESTIONID, CREATEDBY, CREATEDON)
				VALUES (@QUESTIONMAPID_AUTO, @CONTENTID, @QUESTIONS_ID, @USER_ID, GETDATE() )
			END
			-- End of Rev Sanchita

			SET @ReturnValue=1
		END
		ELSE
		BEGIN
			SET @ReturnValue=-1
		END
	END
	ELSE IF (@ACTION='EDIT')
	BEGIN		
		SELECT * 
		,(SELECT STUFF((SELECT ', ' + CAST([QUESTIONS_CATEGORYID] AS nvarchar(10)) [text()]
		FROM LMS_QUESTIONS_CATEGORYMAP WHERE QUESTIONS_ID = t.QUESTIONS_ID 
		FOR XML PATH(''), TYPE)
		.value('.','NVARCHAR(MAX)'),1,2,'') QUESTIONS_CATEGORY
		FROM LMS_QUESTIONS_CATEGORYMAP t WHERE t.QUESTIONS_ID=QUS.QUESTIONS_ID GROUP BY QUESTIONS_ID ) AS CATEGORYIDS 

		,(SELECT STUFF((SELECT ', ' + CAST([QUESTIONS_TOPICID] AS nvarchar(10)) [text()]
		FROM LMS_QUESTIONS_TOPICMAP WHERE QUESTIONS_ID = t.QUESTIONS_ID 
		FOR XML PATH(''), TYPE)
		.value('.','NVARCHAR(MAX)'),1,2,'') QUESTIONS_TOPIC
		FROM LMS_QUESTIONS_TOPICMAP t WHERE t.QUESTIONS_ID=QUS.QUESTIONS_ID GROUP BY QUESTIONS_ID ) AS TOPICIDS        
		FROM LMS_QUESTIONS QUS
		INNER JOIN LMS_QUESTIONSOPTIONS  ON QUS.QUESTIONS_ID=LMS_QUESTIONSOPTIONS.QUESTIONS_ID where QUS.QUESTIONS_ID=@ID


		SELECT * FROM LMS_QUESTIONS_TOPICMAP WHERE QUESTIONS_ID=@ID
		SELECT * FROM LMS_QUESTIONS_CATEGORYMAP WHERE QUESTIONS_ID=@ID

		--SELECT QUS.QUESTIONS_ID,
		--(SELECT STUFF((SELECT ', ' + CAST([QUESTIONS_CATEGORYID] AS nvarchar(10)) [text()]
		--FROM LMS_QUESTIONS_CATEGORYMAP WHERE QUESTIONS_ID = t.QUESTIONS_ID 
		--FOR XML PATH(''), TYPE)
		--.value('.','NVARCHAR(MAX)'),1,2,'') QUESTIONS_CATEGORY
		--FROM LMS_QUESTIONS_CATEGORYMAP t WHERE t.QUESTIONS_ID=QUS.QUESTIONS_ID GROUP BY QUESTIONS_ID ) AS CATEGORYIDS 
            
		--FROM LMS_QUESTIONS QUS
		--WHERE QUS.QUESTIONS_ID=@ID

		--SELECT QUS.QUESTIONS_ID,
		--(SELECT STUFF((SELECT ', ' + CAST([QUESTIONS_TOPICID] AS nvarchar(10)) [text()]
		--FROM LMS_QUESTIONS_TOPICMAP WHERE QUESTIONS_ID = t.QUESTIONS_ID 
		--FOR XML PATH(''), TYPE)
		--.value('.','NVARCHAR(MAX)'),1,2,'') QUESTIONS_CATEGORY
		--FROM LMS_QUESTIONS_TOPICMAP t WHERE t.QUESTIONS_ID=QUS.QUESTIONS_ID GROUP BY QUESTIONS_ID ) AS TOPICIDS             
		--FROM LMS_QUESTIONS QUS
		--WHERE QUS.QUESTIONS_ID=@ID

	END
	ELSE IF(@ACTION='UPDATE')
	BEGIN

		IF EXISTS (SELECT 1 FROM LMS_QUESTIONS WHERE QUESTIONS_NAME=@QUESTIONNAME  AND QUESTIONS_ID<>@ID)
		BEGIN
			SET @ReturnValue=-1
		END
		ELSE
		BEGIN
			
			DELETE FROM LMS_QUESTIONSOPTIONS  where QUESTIONS_ID=@ID
			DELETE FROM LMS_QUESTIONS_TOPICMAP WHERE QUESTIONS_ID=@ID
			DELETE FROM LMS_QUESTIONS_CATEGORYMAP WHERE QUESTIONS_ID=@ID

			UPDATE LMS_QUESTIONS SET QUESTIONS_NAME=Ltrim(Rtrim(Replace(@QUESTIONNAME,'?','')))+' '+'?',QUESTIONS_DESCRIPTN=@QUESTIONDESCRIPTION ,UPDATEDBY=@USER_ID,UPDATEDON=GETDATE() WHERE  QUESTIONS_ID=@ID 

						
			

			select  @LASTCOUNTOPTIONS=iSNULL(MAX(QUESTIONS_OPTIONSID),0) from LMS_QUESTIONSOPTIONS 
			INSERT INTO LMS_QUESTIONSOPTIONS(QUESTIONS_OPTIONSID,QUESTIONS_ID,OPTIONS_NUMBER1,OPTIONS_POINT1,OPTIONS_CORRECT1,OPTIONS_NUMBER2,OPTIONS_POINT2,OPTIONS_CORRECT2,OPTIONS_NUMBER3,OPTIONS_POINT3,OPTIONS_CORRECT3,
			OPTIONS_NUMBER4,OPTIONS_POINT4,OPTIONS_CORRECT4,CREATEDBY,CREATEDON
			)
			VALUES (@LASTCOUNTOPTIONS+1,@ID,@OPTION1,@POINT1,@CORRECT1,@OPTION2,@POINT2,@CORRECT2,@OPTION3,@POINT3,@CORRECT3,@OPTION4,@POINT4,@CORRECT4			
			,@USER_ID,GETDATE())		


			declare DB_CURSOR_TOPIC_LIST cursor for
			SELECT TOPICID FROM #TOPIC_LIST 	
			open DB_CURSOR_TOPIC_LIST
			fetch next from DB_CURSOR_TOPIC_LIST into @TOPICID
			while @@FETCH_STATUS=0
			begin
				select  @LASTCOUNTTOPICMAP=iSNULL(MAX(QUESTIONS_TOPICMAP_ID),0) from LMS_QUESTIONS_TOPICMAP 
				INSERT INTO LMS_QUESTIONS_TOPICMAP(QUESTIONS_TOPICMAP_ID,QUESTIONS_TOPICID,QUESTIONS_ID,CREATEDBY,CREATEDON)
				select @LASTCOUNTTOPICMAP+1,@TOPICID, @ID,@USER_ID,GETDATE() 

			fetch next from DB_CURSOR_TOPIC_LIST into @TOPICID
			END
			close DB_CURSOR_TOPIC_LIST
			deallocate DB_CURSOR_TOPIC_LIST


			declare DB_CURSOR_CATEGORY_LIST cursor for
			SELECT CATEGORYID FROM #CATEGORY_LIST	
			open DB_CURSOR_CATEGORY_LIST
			fetch next from DB_CURSOR_CATEGORY_LIST into @CATEGORYID
			while @@FETCH_STATUS=0
			begin
				select  @LASTCOUNTCATEGORYMAP=iSNULL(MAX(QUESTIONS_CATEGORYMAP_ID),0) from LMS_QUESTIONS_CATEGORYMAP 
				INSERT INTO LMS_QUESTIONS_CATEGORYMAP(QUESTIONS_CATEGORYMAP_ID,QUESTIONS_CATEGORYID,QUESTIONS_ID,CREATEDBY,CREATEDON)
				select @LASTCOUNTCATEGORYMAP+1,@CATEGORYID, @ID,@USER_ID,GETDATE()

			fetch next from DB_CURSOR_CATEGORY_LIST into @CATEGORYID
			END
			close DB_CURSOR_CATEGORY_LIST
			deallocate DB_CURSOR_CATEGORY_LIST

			DROP TABLE #TOPIC_LIST
			DROP TABLE #CATEGORY_LIST

			SET @ReturnValue=1		
		END		
	END
	


	ELSE IF (@ACTION='DELETE')
	BEGIN	    

	  if EXISTS (select 'Y' from LMS_CONTENT_QUESTIONMAP  where CONTENT_QUESTIONID=@ID)
	  Begin
		set @ReturnValue='-1'    
	  End
	  Else
	  BEGIN
			DELETE FROM LMS_QUESTIONS WHERE QUESTIONS_ID=@ID
			DELETE FROM LMS_QUESTIONSOPTIONS  where QUESTIONS_ID=@ID
			DELETE FROM LMS_QUESTIONS_TOPICMAP WHERE QUESTIONS_ID=@ID
			DELETE FROM LMS_QUESTIONS_CATEGORYMAP WHERE QUESTIONS_ID=@ID
			set @ReturnValue='1'  
	  END
    END  
	ELSE IF @ACTION='GETLISTINGDETAILS'
	BEGIN
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'LMS_QUESTIONSMASTERLIST') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE LMS_QUESTIONSMASTERLIST
			(
				USERID INT,
				SEQ BIGINT,
				QUESTIONS_ID int,	
				QUESTIONS_NAME NVARCHAR(500),
				QUESTIONS_DESCRIPTN NVARCHAR(1000),
				CNTTOPIC bigint,
				CNTCATEGORY bigint,
				CREATEDATE datetime,
				CREATEUSER NVARCHAR(100),
				MODIFYDATE datetime,
				MODIFYUSER NVARCHAR(100)
			)
			CREATE NONCLUSTERED INDEX IX1PF_PURREGPROD_RPT ON LMS_QUESTIONSMASTERLIST (SEQ)
		END
		DELETE FROM LMS_QUESTIONSMASTERLIST where USERID=@USER_ID

		IF(@ISPAGELOAD='1')
		BEGIN
			INSERT INTO LMS_QUESTIONSMASTERLIST (USERID, SEQ, QUESTIONS_ID, QUESTIONS_NAME,QUESTIONS_DESCRIPTN,CNTTOPIC,CNTCATEGORY,CREATEDATE,CREATEUSER,MODIFYDATE,MODIFYUSER )

			SELECT @USER_ID,ROW_NUMBER() OVER(ORDER BY QUESTIONS.QUESTIONS_ID desc) AS SEQ,QUESTIONS.QUESTIONS_ID,QUESTIONS_NAME,QUESTIONS_DESCRIPTN	
			,CNTTOPIC,CNTCATEGORY
			,CONVERT(VARCHAR(10),CREATEDON,120)CREATEDON			
			,UC.user_name as CREATEUSER			
			,CONVERT(VARCHAR(10),UPDATEDON,120)UPDATEDON	
			,UM.user_name as MODIFYUSER					
			FROM LMS_QUESTIONS  AS QUESTIONS
			left outer join (select count(QUESTIONS_TOPICID)CNTTOPIC,QUESTIONS_ID from LMS_QUESTIONS_TOPICMAP  group by QUESTIONS_ID  )TOPICMAP on TOPICMAP.QUESTIONS_ID=QUESTIONS.QUESTIONS_ID
			left outer join (select count(QUESTIONS_CATEGORYID)CNTCATEGORY,QUESTIONS_ID from LMS_QUESTIONS_CATEGORYMAP  group by QUESTIONS_ID  )CATEGORYMAP on CATEGORYMAP.QUESTIONS_ID=QUESTIONS.QUESTIONS_ID			
			left outer join tbl_master_user UC ON UC.user_id=QUESTIONS.CREATEDBY
			left outer join tbl_master_user  UM ON UM.user_id=QUESTIONS.UPDATEDBY
		END

	END
	ELSE IF (@ACTION='GETTOPIC')
	BEGIN	    
	  if(@ID<>0)
	  Begin
		Select TOPICID,TOPICNAME from LMS_TOPICS WHERE TOPICSTATUS=1
		union All
		Select TOPICID,TOPICNAME from LMS_TOPICS  TOPICS
		INNER JOIN LMS_QUESTIONS_TOPICMAP MAP ON MAP.QUESTIONS_TOPICID=TOPICS.TOPICID
		where MAP.QUESTIONS_ID=@ID
	  End
      else
	  Begin
		Select TOPICID,TOPICNAME from LMS_TOPICS  WHERE TOPICSTATUS=1
	  End
    END
	ELSE IF (@ACTION='GETCATEGORY')
	BEGIN  
	  if(@ID<>0)
	  Begin
		Select CATEGORYID,CATEGORYNAME from LMS_CATEGORY  WHERE CATEGORYSTATUS=1
		union All
		Select CATEGORYID,CATEGORYNAME from LMS_CATEGORY CAT
		inner join LMS_QUESTIONS_CATEGORYMAP MAP on CAT.CATEGORYID=MAP.QUESTIONS_CATEGORYID
		where MAP.QUESTIONS_ID=@ID
	  End
      else
	  Begin
		Select CATEGORYID,CATEGORYNAME from LMS_CATEGORY  WHERE CATEGORYSTATUS=1
	  End
      
    END
	ELSE IF @ACTION='GETCATEGORYLISTINGDETAILS'
	BEGIN		
			Select CATEGORYID,CATEGORYNAME,CATEGORYDESCRIPTION from LMS_CATEGORY  CAT	
			INNER JOIN LMS_QUESTIONS_CATEGORYMAP MAP ON MAP.QUESTIONS_CATEGORYID=CAT.CATEGORYID
			INNER JOIN  LMS_QUESTIONS  AS QUESTIONS ON QUESTIONS.QUESTIONS_ID=MAP.QUESTIONS_ID
			WHERE QUESTIONS.QUESTIONS_ID=@ID
	END
	ELSE IF @ACTION='GETTOPICLISTINGDETAILS'
	BEGIN		
			Select TOPICID,TOPICNAME,TOPICBASEDON_NAME as TOPICBASEDON from LMS_TOPICS  CAT	
			LEFT OUTER JOIN LMS_TOPICBASEDON B ON CAT.TOPICBASEDON_ID=B.TOPICBASEDON_ID
			INNER JOIN LMS_QUESTIONS_TOPICMAP MAP ON MAP.QUESTIONS_TOPICID=CAT.TOPICID
			INNER JOIN  LMS_QUESTIONS  AS QUESTIONS ON QUESTIONS.QUESTIONS_ID=MAP.QUESTIONS_ID
			WHERE QUESTIONS.QUESTIONS_ID=@ID
	END
	

	SET NOCOUNT OFF
END
GO