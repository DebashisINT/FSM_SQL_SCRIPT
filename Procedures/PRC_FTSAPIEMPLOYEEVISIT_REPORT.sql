--EXEC PRC_FTSAPIEMPLOYEEVISIT_REPORT '2020-02-24','2020-02-24',2106

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPIEMPLOYEEVISIT_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPIEMPLOYEEVISIT_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSAPIEMPLOYEEVISIT_REPORT]
(
--Rev 1.0
@FROMDATE NVARCHAR(10),
@TODATE NVARCHAR(10),
--End of Rev 1.0
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 20/02/2019
Module	   : Employee Visit Summary & Details for API
1.0		v17.0.0		20/02/2019		Debashis		Two extra optional input: "from_date" & "to_date"
													One extra field in response: "total_distance_travelled". Refer mail: FTS | Changes in api
2.0		v17.0.0		22/02/2019		Debashis		Implemented Heirarchy in any reports. Refer: Heirarchy in any reports.
3.0		v18.0.0		26/02/2019		Debashis		Details sort on EMONAME and VISITED_TIME.Instructed by Pijush da.
4.0		v2.0.7		25/02/2020		Debashis		View visit report enhancement in FSM App.Refer: 0021839
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX),@LOGINEMPCODE NVARCHAR(50)

	SET @LOGINEMPCODE=(SELECT USER_CONTACTID FROM TBL_MASTER_USER WHERE USER_ID=@USERID)

	SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE INTO #EMPHR FROM tbl_trans_employeeCTC CTC LEFT OUTER JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO

	;WITH CTE AS(SELECT	EMPCODE FROM #EMPHR WHERE EMPCODE IS NULL OR EMPCODE=@LOGINEMPCODE
	UNION ALL
	SELECT A.EMPCODE FROM #EMPHR A
	JOIN CTE B
	ON A.RPTTOEMPCODE = B.EMPCODE
	) 
	SELECT DISTINCT TMU.USER_CONTACTID AS EMPCODE INTO #EMPLOYEEHRLIST FROM CTE 
	INNER JOIN TBL_MASTER_USER TMU ON CTE.EMPCODE=TMU.USER_CONTACTID

	--Rev 2.0
	--INSERT INTO #EMPLOYEEHRLIST SELECT emp_contactId FROM tbl_master_employee EMP INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo 
	--WHERE EMPCTC.emp_cntId=@LOGINEMPCODE
	--End of Rev 2.0

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TMPMASTEMPLOYEE') AND TYPE IN (N'U'))
		DROP TABLE #TMPMASTEMPLOYEE
	CREATE TABLE #TMPMASTEMPLOYEE(EMP_ID NUMERIC(18, 0) NOT NULL,EMP_UNIQUECODE VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,EMP_CONTACTID NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPMASTEMPLOYEE (EMP_CONTACTID ASC)

	INSERT INTO #TMPMASTEMPLOYEE SELECT EMP_ID,EMP_UNIQUECODE,EMP_CONTACTID FROM tbl_master_employee WHERE EXISTS(SELECT emp_contactId FROM #EMPLOYEEHRLIST WHERE EMPCODE=emp_contactId)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	SET @Strsql=''
	BEGIN
		SET @Strsql='SELECT EMPUSRID,ROW_NUMBER() OVER(ORDER BY EMPNAME) AS SEQ,CONTACTNO,STATEID,STATE,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,RPTTOUSRID,RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG,TOTAL_VISIT,'
		--Rev 1.0
		--SET @Strsql+='FROM( '
		SET @Strsql+='DISTANCE_TRAVELLED,KM_TRAVELLED FROM( '
		--End of Rev 1.0
		SET @Strsql+='SELECT USR.USER_ID AS EMPUSRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ST.ID AS STATEID,'
		SET @Strsql+='ST.state AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.RPTTOUSRID,RPTTO.RPTTOEMPCODE,RPTTO.REPORTTO,RPTTO.RPTTODESGID,RPTTO.RPTTODESG,EMP.emp_uniqueCode AS EMPID,'
		--Rev 1.0
		--SET @Strsql+='ISNULL(SHOPACT.NEWSHOP_VISITED,0)+ISNULL(SHOPACT.RE_VISITED,0) AS TOTAL_VISIT '
		SET @Strsql+='ISNULL(SHOPACT.NEWSHOP_VISITED,0)+ISNULL(SHOPACT.RE_VISITED,0) AS TOTAL_VISIT,ISNULL(DISTANCE_TRAVELLED,0) AS DISTANCE_TRAVELLED,ISNULL(KM_TRAVELLED,0) AS KM_TRAVELLED '
		--End of Rev 1.0
		SET @Strsql+='FROM #TMPMASTEMPLOYEE EMP '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
		SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
		SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
		SET @Strsql+='INNER JOIN ( '
		SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
		SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN ( '
		SET @Strsql+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
		--Rev 1.0
		--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		--End of Rev 1.0
		SET @Strsql+='AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL AND ATTEN.Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId '
		SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
		SET @Strsql+='LEFT OUTER JOIN ( '
		SET @Strsql+='SELECT User_Id,cnt_internalId,SUM(NEWSHOP_VISITED) AS NEWSHOP_VISITED,SUM(RE_VISITED) AS RE_VISITED,SUM(DISTANCE_TRAVELLED) AS DISTANCE_TRAVELLED FROM( '
		SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.Shop_Id) AS NEWSHOP_VISITED,0 AS RE_VISITED,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED '
		SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
		--Rev 1.0
		--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		--End of Rev 1.0
		SET @Strsql+='AND SHOPACT.Is_Newshopadd=1 '
		SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
		SET @Strsql+='UNION ALL '
		SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.Shop_Id) AS RE_VISITED,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED '
		SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
		--Rev 1.0
		--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		--End of Rev 1.0
		SET @Strsql+='AND SHOPACT.Is_Newshopadd=0 '
		SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
		SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
		--Rev 1.0
		SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id,SUM(CAST(DISTANCE_COVERED AS DECIMAL(18,2))) AS KM_TRAVELLED FROM tbl_trans_shopuser '
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		SET @Strsql+='GROUP BY User_Id) SHOPUSR ON SHOPUSR.user_id=USR.user_id '
		--End of Rev 1.0
		SET @Strsql+='LEFT OUTER JOIN (SELECT USR.USER_ID AS RPTTOUSRID,EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS RPTTOEMPCODE,'
		--Rev 2.0
		--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG FROM #TMPMASTEMPLOYEE EMP '
		SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG '
		SET @Strsql+='FROM tbl_master_employee EMP '
		--End of Rev 2.0
		SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN ('
		SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
		SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
		SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
		SET @Strsql+=') AS DB '
		--SELECT @Strsql
		EXEC SP_EXECUTESQL @Strsql
	END
	BEGIN
		SET @Strsql=''
		--Rev 3.0
		--SET @Strsql='SELECT EMPUSRID,ROW_NUMBER() OVER(ORDER BY EMPNAME) AS SEQ,CONTACTNO,STATEID,STATE,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,RPTTOUSRID,RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG, '
		SET @Strsql='SELECT EMPUSRID,ROW_NUMBER() OVER(ORDER BY EMPNAME,VISITED_TIME) AS SEQ,CONTACTNO,STATEID,STATE,EMPCODE,EMPNAME,EMPID,DEG_ID,DESIGNATION,RPTTOUSRID,RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG, '
		--End of Rev 3.0
		SET @Strsql+='SHOP_NAME,VISITED_DATE,VISITED_TIME,DISTANCE_TRAVELLED,KM_TRAVELLED,SPENT_DURATION FROM( '
		SET @Strsql+='SELECT USR.USER_ID AS EMPUSRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ST.ID AS STATEID,'
		SET @Strsql+='ST.state AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.RPTTOUSRID,RPTTO.RPTTOEMPCODE,RPTTO.REPORTTO,RPTTO.RPTTODESGID,RPTTO.RPTTODESG,EMP.emp_uniqueCode AS EMPID,'
		SET @Strsql+='SHOP.SHOP_NAME,SHOPACT.VISITED_DATE,REPLACE(REPLACE(SHOPACT.VISITED_TIME,''AM'','' AM''),''PM'','' PM'') AS VISITED_TIME,SHOPACT.DISTANCE_TRAVELLED,SHOPUSR.KM_TRAVELLED,SHOPACT.SPENT_DURATION '
		SET @Strsql+='FROM #TMPMASTEMPLOYEE EMP '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
		SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
		SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
		SET @Strsql+='INNER JOIN ( '
		SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
		SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN ( '
		SET @Strsql+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
		--Rev 1.0
		--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		--End of Rev 1.0
		SET @Strsql+='AND ATTEN.Login_datetime IS NOT NULL AND ATTEN.Logout_datetime IS NULL AND ATTEN.Isonleave=''false'' '
		SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) '
		SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId '
		SET @Strsql+='LEFT OUTER JOIN ( '
		SET @Strsql+='SELECT User_Id,cnt_internalId,Shop_Id,SUM(NEWSHOP_VISITED) AS NEWSHOP_VISITED,SUM(RE_VISITED) AS RE_VISITED,SUM(DISTANCE_TRAVELLED) AS DISTANCE_TRAVELLED,VISITED_DATE,VISITED_TIME,SPENT_DURATION FROM( '
		SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,COUNT(SHOPACT.Shop_Id) AS NEWSHOP_VISITED,0 AS RE_VISITED,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,'
		SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITED_DATE,CONVERT(VARCHAR(15),CAST(SHOPACT.visited_time AS TIME),100) AS VISITED_TIME,SHOPACT.SPENT_DURATION '
		SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
		--Rev 1.0
		--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		--End of Rev 1.0
		SET @Strsql+='AND SHOPACT.Is_Newshopadd=1 '
		SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.visited_time,SHOPACT.SPENT_DURATION '
		SET @Strsql+='UNION ALL '
		SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,Shop_Id,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.Shop_Id) AS RE_VISITED,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED,'
		SET @Strsql+='CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) AS VISITED_DATE,CONVERT(VARCHAR(15),CAST(SHOPACT.visited_time AS TIME),100) AS VISITED_TIME,SPENT_DURATION '
		SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
		--Rev 1.0
		--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		--End of Rev 1.0
		SET @Strsql+='AND SHOPACT.Is_Newshopadd=0 '
		SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId,SHOPACT.Shop_Id,SHOPACT.visited_time,SHOPACT.SPENT_DURATION '
		SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId,Shop_Id,VISITED_DATE,VISITED_TIME,SPENT_DURATION) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId AND ATTEN.Login_datetime=SHOPACT.VISITED_DATE '
		SET @Strsql+='INNER JOIN ('
		SET @Strsql+='SELECT DISTINCT Shop_Code,Shop_CreateUser,Shop_Name,Address,Shop_Owner_Contact, '
		SET @Strsql+='CASE WHEN TYPE=1 THEN ''Shop'' WHEN TYPE=2 THEN ''PP'' WHEN TYPE=3 THEN ''New Party'' WHEN TYPE=4 THEN ''DD'' END AS SHOP_TYPE '
		SET @Strsql+='FROM tbl_Master_shop '
		--Rev 4.0
		--SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id AND SHOP.Shop_Code=SHOPACT.Shop_Id '
		SET @Strsql+=') SHOP ON SHOP.Shop_Code=SHOPACT.Shop_Id '
		--End of Rev 4.0
		SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id,SUM(CAST(DISTANCE_COVERED AS DECIMAL(18,2))) AS KM_TRAVELLED FROM tbl_trans_shopuser '
		--Rev 1.0
		--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120)=CONVERT(NVARCHAR(10),GETDATE(),120) '
		SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
		--End of Rev 1.0
		SET @Strsql+='GROUP BY User_Id) SHOPUSR ON SHOPUSR.user_id=USR.user_id '
		SET @Strsql+='LEFT OUTER JOIN (SELECT USR.USER_ID AS RPTTOUSRID,EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS RPTTOEMPCODE,'
		--Rev 2.0
		--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG FROM #TMPMASTEMPLOYEE EMP '
		SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG '
		SET @Strsql+='FROM tbl_master_employee EMP '
		--End of Rev 2.0
		SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
		SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
		SET @Strsql+='INNER JOIN ('
		SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
		SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
		SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
		SET @Strsql+=') AS DB '
		--SELECT @Strsql
		EXEC SP_EXECUTESQL @Strsql
	END

	DROP TABLE #TEMPCONTACT
	DROP TABLE #EMPHR
	DROP TABLE #EMPLOYEEHRLIST
	DROP TABLE #TMPMASTEMPLOYEE
END