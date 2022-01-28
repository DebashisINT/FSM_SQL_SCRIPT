--EXEC PRC_FTSSMSSENDTGTVSACHV_REPORT '','1681',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSSMSSENDTGTVSACHV_REPORT]') AND TYPE in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSSMSSENDTGTVSACHV_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSSMSSENDTGTVSACHV_REPORT]
(
@STATEID NVARCHAR(MAX)=NULL,
@USER_ID NVARCHAR(MAX)=NULL,
@USERID INT 
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 17/01/2019
Module	   : SMS for Target Vs Achievement
1.0		v2.0.0		Debashis	22/01/2019		For the time being, SMS generation will be started where targets are not defined for the employees.Refer: SMS Updation
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#STATEID_LIST') AND TYPE IN (N'U'))
		DROP TABLE #STATEID_LIST
	CREATE TABLE #STATEID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
	IF @STATEID <> ''
		BEGIN
			SET @STATEID=REPLACE(@STATEID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #STATEID_LIST SELECT id from tbl_master_state where id in('+@STATEID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#USER_LIST') AND TYPE IN (N'U'))
		DROP TABLE #USER_LIST
	CREATE TABLE #USER_LIST (user_id INT)
	IF @USER_ID <> ''
		BEGIN
			SET @USER_ID=REPLACE(@USER_ID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #USER_LIST SELECT user_id FROM tbl_master_user WHERE user_id in('+@USER_ID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

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
	--Rev 1.0
	--SET @Strsql='SELECT ''Target Vs Achievement: ''+TGTNEWCOUNTER+'', ''+CASE WHEN ACHVNEWSHOPVISITED<>'''' THEN ACHVNEWSHOPVISITED ELSE ''NC ACHV - 0'' END +'' | ''+'
	--SET @Strsql+='TGTREVISIT+'', ''+CASE WHEN ACHVREVISITSHOP<>'''' THEN ACHVREVISITSHOP ELSE ''RV ACHV - 0'' END SMS FROM( '
	--SET @Strsql+='SELECT ''NC TGT - ''+LTRIM(RTRIM(STR(TGT.NEWCOUNTER/TGT.DAYS))) AS TGTNEWCOUNTER,''RV TGT - ''+LTRIM(RTRIM(STR(TGT.REVISIT/DAYS))) AS TGTREVISIT,'''' AS ACHVNEWSHOPVISITED,'''' AS ACHVREVISITSHOP FROM('
	SET @Strsql='SELECT ''Target Vs Achievement: ''+CASE WHEN SUM(TGTNEWCOUNTER)<>0 THEN ''NC TGT - ''+LTRIM(RTRIM(STR(SUM(TGTNEWCOUNTER)))) ELSE ''NC TGT - 0'' END +'', ''+'
	SET @Strsql+='CASE WHEN SUM(ACHVNEWSHOPVISITED)<>0 THEN ''NC ACHV - ''+LTRIM(RTRIM(STR(SUM(ACHVNEWSHOPVISITED)))) ELSE ''NC ACHV - 0'' END '
	SET @Strsql+='+'' | ''+CASE WHEN SUM(TGTREVISIT)<>0 THEN ''RV TGT - ''+LTRIM(RTRIM(STR(SUM(TGTREVISIT)))) ELSE ''RV TGT - 0'' END +'', ''+'
	SET @Strsql+='CASE WHEN SUM(ACHVREVISITSHOP)<>0 THEN ''RV ACHV - ''+LTRIM(RTRIM(STR(SUM(ACHVREVISITSHOP)))) ELSE ''RV ACHV - 0'' END AS SMS FROM( '
	SET @Strsql+='SELECT (TGT.NEWCOUNTER/TGT.DAYS) AS TGTNEWCOUNTER,(TGT.REVISIT/TGT.DAYS) AS TGTREVISIT,0 AS ACHVNEWSHOPVISITED,0 AS ACHVREVISITSHOP FROM('
	--End of Rev 1.0
	SET @Strsql+='SELECT USR.user_id,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ST.ID AS STATEID,'
	SET @Strsql+='ST.state AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS REPORTTOUSER,RPTTO.REPORTTO,'
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,EMPTGTSET.NewCounter,EMPTGTSET.Revisit,'
	SET @Strsql+='DATEDIFF(DAY,CONVERT(DATE,EMPTGTSET.FromDate),CONVERT(DATE,EMPTGTSET.ToDate))+1 AS DAYS '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	--Rev 1.0
	--SET @Strsql+='INNER JOIN tbl_FTS_EmployeesTargetSetting EMPTGTSET ON EMPTGTSET.EmployeeCode=CNT.cnt_internalId '
	SET @Strsql+='LEFT OUTER JOIN tbl_FTS_EmployeesTargetSetting EMPTGTSET ON EMPTGTSET.EmployeeCode=CNT.cnt_internalId '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),GETDATE(),120) BETWEEN CONVERT(NVARCHAR(10),EMPTGTSET.FromDate,120) AND CONVERT(NVARCHAR(10),EMPTGTSET.ToDate,120) '
	--End of Rev 1.0
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT USR.user_id,EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	--Rev 1.0
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),GETDATE(),120) BETWEEN CONVERT(NVARCHAR(10),EMPTGTSET.FromDate,120) AND CONVERT(NVARCHAR(10),EMPTGTSET.ToDate,120) '
	--End of Rev 1.0
	SET @Strsql+=') AS TGT WHERE EXISTS (SELECT USER_ID from #USER_LIST AS USL WHERE USL.user_id=TGT.user_id) '
	IF @STATEID<>''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=TGT.STATEID) '
	SET @Strsql+='UNION ALL '
	--Rev 1.0
	--SET @Strsql+='SELECT '''' AS TGTNEWCOUNTER,'''' AS TGTREVISIT,''NC ACHV - ''+LTRIM(RTRIM(STR(ISNULL(ACHV.NEWSHOPVISITED,0)))) AS ACHVNEWSHOPVISITED,''RV ACHV - ''+LTRIM(RTRIM(STR(ACHV.REVISITSHOP))) AS ACHVREVISITSHOP FROM('
	SET @Strsql+='SELECT 0 AS TGTNEWCOUNTER,0 AS TGTREVISIT,ISNULL(ACHV.NEWSHOPVISITED,0) AS ACHVNEWSHOPVISITED,ISNULL(ACHV.REVISITSHOP,0) AS ACHVREVISITSHOP FROM('
	--End of Rev 1.0
	SET @Strsql+='SELECT USR.user_id,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ST.ID AS STATEID,'
	SET @Strsql+='ST.state AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.user_id AS REPORTTOUSER,RPTTO.REPORTTO,'
	SET @Strsql+='ADDR.add_address1+'' ''+ISNULL(ADDR.add_address2,'''')+'' ''+ISNULL(ADDR.add_address3,'''') AS OFFICE_ADDRESS,EMP.emp_uniqueCode AS EMPID,SHOPACT.NEWSHOPVISITED,SHOPACT.REVISITSHOP '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT USR.user_id,EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT User_Id,cnt_internalId,SUM(NEWSHOPVISITED) AS NEWSHOPVISITED,SUM(REVISITSHOP) AS REVISITSHOP FROM('
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,COUNT(SHOPACT.Shop_Id) AS NEWSHOPVISITED,0 AS REVISITSHOP FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),GETDATE(),120) '
	SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120)=CONVERT(NVARCHAR(10),GETDATE(),120) '
	SET @Strsql+='AND SHOPACT.Is_Newshopadd=1 GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,0 AS NEWSHOPVISITED,COUNT(SHOPACT.Shop_Id) AS REVISITSHOP FROM tbl_trans_shopActivitysubmit SHOPACT '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT User_Id,CONVERT(NVARCHAR(10),Login_datetime,105) AS Login_datetime FROM tbl_fts_UserAttendanceLoginlogout WHERE Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+='AND CONVERT(NVARCHAR(10),Work_datetime,120)=CONVERT(NVARCHAR(10),GETDATE(),120) '
	SET @Strsql+='GROUP BY User_Id,CONVERT(NVARCHAR(10),Login_datetime,105))ATTEN ON ATTEN.User_Id=SHOPACT.User_Id AND ATTEN.Login_datetime=CONVERT(NVARCHAR(10),SHOPACT.visited_time,105) '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120)=CONVERT(NVARCHAR(10),GETDATE(),120) '
	SET @Strsql+='AND SHOPACT.Is_Newshopadd=0 GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
	SET @Strsql+=') SHOPACT GROUP BY SHOPACT.User_Id,SHOPACT.cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
	SET @Strsql+=') AS ACHV WHERE EXISTS (SELECT USER_ID from #USER_LIST AS USL WHERE USL.user_id=ACHV.user_id) '
	IF @STATEID<>''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=ACHV.STATEID) '
	SET @Strsql+=') AS DB '
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	DROP TABLE #USER_LIST
END