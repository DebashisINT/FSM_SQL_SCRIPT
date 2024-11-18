IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_REPORTS_TOPICLIST]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_REPORTS_TOPICLIST] AS' 
END
GO
ALTER PROC [dbo].[PRC_LMS_REPORTS_TOPICLIST]
(
@ISPAGELOAD CHAR(1)='0',
@USER_ID BIGINT=0
)
AS
/*************************************************************************************************************************
Written by : Priti Roy ON 16/10/2024
0027764: A new LMS reports is required under the Reports tab of LMS0027764: A new LMS reports is required under the Reports tab of LMS
******************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @sqlStrTable NVARCHAR(MAX)
	
	

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'LMS_REPORTTOPICLIST') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE LMS_REPORTTOPICLIST
			(
				USERID INT,
				SEQ BIGINT,
				TOPICID bigint,
				TOPICNAME nvarchar(300),
				TOPICSTATUS nvarchar(20),
				CONTENTID bigint,
				CONTENTTITLE nvarchar(300), 
				CONTENTSTATUS nvarchar(20),
				QuestionMapped nvarchar(20),
				QUESTIONSCount bigint
			)
			CREATE NONCLUSTERED INDEX IX1PF_PURREGPROD_RPT ON LMS_REPORTTOPICLIST (SEQ)
		END
		DELETE FROM LMS_REPORTTOPICLIST where USERID=@USER_ID

	  
	IF (@ISPAGELOAD<>0)
	BEGIN

	        insert into LMS_REPORTTOPICLIST(USERID,SEQ,TOPICID,TOPICNAME,TOPICSTATUS,CONTENTID,CONTENTTITLE,CONTENTSTATUS,QuestionMapped,QUESTIONSCount)
	
			select @USER_ID,ROW_NUMBER() OVER(ORDER BY TOPICID ASC) AS SEQ,
			TOPICID,TOPICNAME,
			case when TOPICSTATUS=1 then 'Published'  when TOPICSTATUS=0 then 'Unpublished' end TOPICSTATUS,
			CONTENTID,CONTENTTITLE, 
			case when CONTENTSTATUS=1 then 'Published' when CONTENTSTATUS=0 then 'Unpublished' end CONTENTSTATUS
			,case when isnull(QUESTIONSCount,0)=0 then 'No'  when isnull(QUESTIONSCount,0)>=0 then 'Yes' end as QuestionMapped
			,isnull(QUESTIONSCount,0)QUESTIONSCount
			from LMS_TOPICS
			left outer join LMS_CONTENT on CONTENT_TOPICID=TOPICID
			left outer join 
			(select count(0) as QUESTIONSCount,QUESTIONS_TOPICID from LMS_QUESTIONS_TOPICMAP group by QUESTIONS_TOPICID)TOPICMAP
			on TOPICMAP.QUESTIONS_TOPICID=TOPICID
	END

	

	SET NOCOUNT OFF
END
GO

