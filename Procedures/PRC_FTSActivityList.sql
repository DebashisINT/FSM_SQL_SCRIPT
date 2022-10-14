--exec PRC_FTSActivityList @Action='ActivityList',@user_id=11774,@URL=''

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSActivityList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSActivityList] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSActivityList]
(
@Action nvarchar(max),
@user_id  BIGINT=0,
@URL NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/*********************************************************************************************
1.0			2.0.18		Tanmoy		08-09-2020		create sp
*********************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @Action='ActivityDropdownList'
		BEGIN
			SELECT * FROM FTS_Activity WITH(NOLOCK) 
		END

	IF @Action='ActivityTypeList'
		BEGIN
			SELECT * FROM FTS_ActivityType WITH(NOLOCK) 
		END

	IF @Action='ActivityProductList'
		BEGIN
			SELECT sProducts_ID,sProducts_Name FROM Master_sProducts WITH(NOLOCK) 
		END

	IF @Action='ActivityPriorityList'
		BEGIN
			SELECT * FROM FTS_Priority WITH(NOLOCK) 
		END

	IF @Action='ActivityList'
		BEGIN
			SELECT head.Id,head.ActivityCode,head.Party_Code,CONVERT(NVARCHAR(10),head.Activity_DateTime,120) AS Activity_Date,
			RIGHT(CONVERT(VARCHAR,head.Activity_DateTime, 100), 7) AS Activity_Time,
			head.ContactName,head.Activityid,
			head.Typeid,head.ActivitySubject,head.ActivityDetails,head.Assignto,head.Duration,head.Priorityid,
			CONVERT(NVARCHAR(10),head.Duedate,120) AS Duedate,
			RIGHT(CONVERT(VARCHAR,head.Duedate, 100), 7) AS due_time,
			ProdId,PROD.ProdId,
			@URL+ISNULL(tbl.IMAGE_NAME,'') AS IMAGE,@URL+ISNULL(attch.IMAGE_NAME,'') AS Attachment
			FROM FTS_SalesActivity head WITH(NOLOCK) 
			LEFT OUTER JOIN FTS_ActivityProducts PROD WITH(NOLOCK) ON head.Id=PROD.ActivityId
			left outer join(select IMAGE_NAME,Id from FTS_SalesActivity WITH(NOLOCK) inner join FTS_ActivityImagesMapping WITH(NOLOCK) on Id=FTS_ActivityImagesMapping.ActivityId where IMAGE_TYPE='Image' ) tbl
			on head.Id=tbl.Id
			left outer join(select IMAGE_NAME,Id from FTS_SalesActivity WITH(NOLOCK) inner join FTS_ActivityImagesMapping WITH(NOLOCK) on Id=FTS_ActivityImagesMapping.ActivityId where IMAGE_TYPE='Attachment' ) attch
			on head.Id=attch.Id
			WHERE head.Created_by=@user_id
		END

	SET NOCOUNT OFF
END