--EXEC PRC_FTSAPILEADERBOARDPOINTSDETAILS 'OVERALL',54958,'1','1','M','http://localhost:16126/CommonFolder/ProfileImages/'
--EXEC PRC_FTSAPILEADERBOARDPOINTSDETAILS 'BRANCHLISTS','','','','','','118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 138, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150,1'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPILEADERBOARDPOINTSDETAILS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPILEADERBOARDPOINTSDETAILS] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSAPILEADERBOARDPOINTSDETAILS]
(
@ACTION NVARCHAR(20),
@USERID BIGINT=NULL,
@ACTIVITYBASED NVARCHAR(5)=NULL,
@BRANCHWISE BIGINT=NULL,
@ACTIVITYMODE NCHAR(1)=NULL,
@PROFILEIMAGEPATH NVARCHAR(500)=NULL,
@CHILDBRANCH NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 11/04/2024
Module	   : Leaderboard Points Details.Row: 905 to 908 & Refer: 0027300
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @StrSql NVARCHAR(MAX)

	IF @ACTION='OVERALL'
		BEGIN
			SET @StrSql='SELECT USERID AS [user_id],EMPNAME AS [user_name],CONTACTNO AS user_phone,ATTENDANCEPOINTS AS attendance,NEWSHOP_VISITEDPOINTS AS new_visit,RE_VISITEDPOINTS AS revisit,'
			SET @StrSql+='ORDERPOINTS AS [order],ACTIVITIESPOINTS AS activities,POSITION AS position,TOTALSCORES AS totalscore,'
			SET @StrSql+='CASE WHEN PROFILE_PICTURES_URL<>'''' THEN '''+@PROFILEIMAGEPATH+'''+PROFILE_PICTURES_URL ELSE '''' END AS profile_pictures_url '
			SET @StrSql+='FROM FTSLEADERBOARDPOINTSDETAILS_REPORT WHERE ACTIVITYMODE='''+@ACTIVITYMODE+''' '
			IF @BRANCHWISE<>0
				SET @StrSql+='AND BRANCH_ID='+TRIM(STR(@BRANCHWISE))+' '
			IF @ACTIVITYBASED<>'All'
				BEGIN
					IF @ACTIVITYBASED='1'
						SET @StrSql+='AND ATTENDANCEID='''+@ACTIVITYBASED+''' '
					ELSE IF @ACTIVITYBASED='2'
						SET @StrSql+='AND NEWSHOP_VISITEDID='''+@ACTIVITYBASED+''' '
					ELSE IF @ACTIVITYBASED='3'
						SET @StrSql+='AND RE_VISITEDID='''+@ACTIVITYBASED+''' '
					ELSE IF @ACTIVITYBASED='4'
						SET @StrSql+='AND ORDERID='''+@ACTIVITYBASED+''' '
					ELSE IF @ACTIVITYBASED='5'
						SET @StrSql+='AND ACTIVITIESID='''+@ACTIVITYBASED+''' '
				END
			SET @StrSql+='ORDER BY POSITION '

			--SELECT @StrSql
			EXEC SP_EXECUTESQL @StrSql
		END
	IF @ACTION='OWN'
		BEGIN
			SET @StrSql='SELECT USERID AS [user_id],EMPNAME AS [user_name],CONTACTNO AS user_phone,ATTENDANCEPOINTS AS attendance,NEWSHOP_VISITEDPOINTS AS new_visit,RE_VISITEDPOINTS AS revisit,'
			SET @StrSql+='ORDERPOINTS AS [order],ACTIVITIESPOINTS AS activities,POSITION AS position,TOTALSCORES AS totalscore,'
			SET @StrSql+='CASE WHEN PROFILE_PICTURES_URL<>'''' THEN '''+@PROFILEIMAGEPATH+'''+PROFILE_PICTURES_URL ELSE '''' END AS profile_pictures_url '
			SET @StrSql+='FROM FTSLEADERBOARDPOINTSDETAILS_REPORT WHERE USERID='+TRIM(STR(@USERID))+' AND ACTIVITYMODE='''+@ACTIVITYMODE+''' '
			IF @BRANCHWISE<>0
				SET @StrSql+='AND BRANCH_ID='+TRIM(STR(@BRANCHWISE))+' '
			IF @ACTIVITYBASED<>'All'
				BEGIN
					IF @ACTIVITYBASED='1'
						SET @StrSql+='AND ATTENDANCEID='''+@ACTIVITYBASED+''' '
					ELSE IF @ACTIVITYBASED='2'
						SET @StrSql+='AND NEWSHOP_VISITEDID='''+@ACTIVITYBASED+''' '
					ELSE IF @ACTIVITYBASED='3'
						SET @StrSql+='AND RE_VISITEDID='''+@ACTIVITYBASED+''' '
					ELSE IF @ACTIVITYBASED='4'
						SET @StrSql+='AND ORDERID='''+@ACTIVITYBASED+''' '
					ELSE IF @ACTIVITYBASED='5'
						SET @StrSql+='AND ACTIVITIESID='''+@ACTIVITYBASED+''' '
				END
			SET @StrSql+='ORDER BY POSITION '

			--SELECT @StrSql
			EXEC SP_EXECUTESQL @StrSql
		END
	IF @ACTION='ACTIVITYLISTS'
		BEGIN
			SELECT ID AS id,POINT_SECTION AS [value] FROM MASTER_LEADERBOARDPOINTS WHERE IS_ACTIVE=1 ORDER BY ID
		END
	IF @ACTION='BRANCHLISTS'
		BEGIN
			DECLARE @BRANCHCNT INT=0
			SET @BRANCHCNT=(SELECT COUNT(0) FROM tbl_master_branch)

			IF OBJECT_ID('tempdb..#PBRANCH_LIST') IS NOT NULL
				DROP TABLE #PBRANCH_LIST
			CREATE TABLE #PBRANCH_LIST (BRANCH_PARENTID BIGINT NULL)
			CREATE NONCLUSTERED INDEX IX1 ON #PBRANCH_LIST (BRANCH_PARENTID ASC)

			IF OBJECT_ID('tempdb..#Branch_List') IS NOT NULL
				DROP TABLE #Branch_List
			CREATE TABLE #Branch_List (Branch_Id BIGINT NULL)
			CREATE NONCLUSTERED INDEX IX1 ON #Branch_List (Branch_Id ASC)

			IF @CHILDBRANCH<>''  
				BEGIN
					SET @CHILDBRANCH = REPLACE(@CHILDBRANCH,'''','')
					SET @StrSql=''
					SET @StrSql='INSERT INTO #PBRANCH_LIST(BRANCH_PARENTID) '
					SET @StrSql+='SELECT BRANCH_PARENTID FROM (SELECT DISTINCT BRANCH_PARENTID FROM TBL_MASTER_BRANCH WHERE branch_id IN('+@CHILDBRANCH+') AND branch_parentId<>0 '
					SET @StrSql+='UNION '
					SET @StrSql+='SELECT DISTINCT BRANCH_PARENTID FROM TBL_MASTER_BRANCH WHERE BRANCH_PARENTID IN('+@CHILDBRANCH+') AND branch_parentId<>0 '
					SET @StrSql+=') BR '

					--SELECT @StrSql
					EXEC SP_EXECUTESQL @StrSql

					SET @StrSql=''
					SET @StrSql='INSERT INTO #Branch_List(Branch_Id) '
					SET @StrSql+='SELECT branch_id FROM tbl_master_branch WHERE (BRANCH_ID IN('+@CHILDBRANCH+')) '

					--SELECT @StrSql
					EXEC SP_EXECUTESQL @StrSql
				END

			IF @BRANCHCNT=1
				BEGIN
					INSERT INTO #PBRANCH_LIST(BRANCH_PARENTID)
					SELECT branch_parentId FROM (
					SELECT A.branch_parentId,A.branch_id,A.branch_description as Code FROM tbl_master_branch A WHERE A.branch_parentId=0
					UNION 
					SELECT A.branch_parentId,A.branch_id,A.branch_description as Code FROM tbl_master_branch A, tbl_master_branch B 
					WHERE A.branch_id=B.branch_parentId AND B.branch_parentId <>0
					) BR

					SELECT branch_parentId AS branch_head_id,branch_description AS branch_head FROM (
					SELECT A.branch_parentId,A.branch_id,A.branch_description FROM tbl_master_branch A WHERE A.branch_parentId=0
					UNION 
					SELECT A.branch_parentId,A.branch_id,A.branch_description FROM tbl_master_branch A, tbl_master_branch B 
					WHERE A.branch_id=B.branch_parentId AND B.branch_parentId <>0
					) BR

					SELECT branch_parentId AS branch_head_id,branch_id AS id,branch_description AS [value] FROM tbl_master_branch
					WHERE branch_parentId IN(SELECT BRANCH_PARENTID FROM #PBRANCH_LIST) 
					ORDER BY branch_parentId ASC
				END
			ELSE IF @BRANCHCNT>1
				BEGIN
					INSERT INTO #PBRANCH_LIST(BRANCH_PARENTID)
					SELECT 0 BRANCH_PARENTID
					UNION ALL
					SELECT BRANCH_PARENTID FROM (SELECT DISTINCT BRANCH_PARENTID FROM TBL_MASTER_BRANCH 
					WHERE --branch_id IN(118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 138, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150,1) AND 
					branch_parentId<>0
					) BR

					--SELECT branch_id AS branch_head_id,branch_description AS branch_head FROM (
					--SELECT A.branch_id,A.branch_description FROM tbl_master_branch A WHERE A.branch_parentId=0
					--UNION 
					--SELECT A.branch_id,A.branch_description FROM tbl_master_branch A, tbl_master_branch B WHERE A.branch_id=B.branch_parentId AND B.branch_parentId <>0
					--) BR WHERE EXISTS (SELECT BRANCH_PARENTID FROM #PBRANCH_LIST AS BM WHERE BM.BRANCH_PARENTID = BR.branch_id)
					SELECT 0 AS branch_head_id,'All' AS branch_head
					UNION ALL
					SELECT branch_id AS branch_head_id,branch_description AS branch_head FROM (
					SELECT A.branch_id,A.branch_description FROM tbl_master_branch A WHERE A.branch_parentId=0
					UNION 
					SELECT A.branch_id,A.branch_description FROM tbl_master_branch A, tbl_master_branch B WHERE A.branch_id=B.branch_parentId AND B.branch_parentId <>0
					) BR

					SELECT * FROM(
					SELECT DISTINCT 0 AS branch_head_id,branch_id AS id,branch_description AS [value] FROM tbl_master_branch
					UNION ALL
					SELECT branch_parentId AS branch_head_id,branch_id AS id,branch_description AS [value] FROM tbl_master_branch
					WHERE branch_parentId IN(SELECT BRANCH_PARENTID FROM #PBRANCH_LIST WHERE BRANCH_PARENTID<>0) 
					--AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE tbl_master_branch.branch_id=F.Branch_Id)
					) BR
					ORDER BY branch_head_id ASC
				END
		END

	IF @ACTION='BRANCHLISTS'
		BEGIN
			DROP TABLE #Branch_List
			DROP TABLE #PBRANCH_LIST
		END

	SET NOCOUNT OFF
END
GO