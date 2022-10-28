--EXEC PRC_FTSAPIEMPLOYEEPERFORMANCE_REPORT '2022-04-01','2022-09-29',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPIEMPLOYEEPERFORMANCE_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPIEMPLOYEEPERFORMANCE_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSAPIEMPLOYEEPERFORMANCE_REPORT]
(
--Rev 1.0
@FROMDATE NVARCHAR(10),
@TODATE NVARCHAR(10),
--End of Rev 1.0
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 19/02/2019
Module	   : Employee Performance Details for API
1.0		v17.0.0		20/02/2019		Debashis		Two extra optional input: "from_date" & "to_date". Refer mail: FTS | Changes in api
2.0		v17.0.0		22/02/2019		Debashis		Implemented Heirarchy in any reports. Refer: Heirarchy in any reports.
3.0		v19.0.0		28/02/2019		Debashis		Total Travel (KM) : Should the the Total distance traveled by user on the current date.Refer mail: Performance Report
4.0		v2.0.33		29/09/2022		Debashis		New Sales Order type data is not showing in the Performance Summary report in FSM mobile App.Refer: 0025250
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX),@LOGINEMPCODE NVARCHAR(50)
	--Rev 3.0
	--Rev 4.0
	--DECLARE @TABLENAME NVARCHAR(30)
	DECLARE @TABLENAME NVARCHAR(50)
	--End of Rev 4.0
	--End of Rev 3.0
	--Rev 4.0
	DECLARE @IsActivateNewOrderScreenwithSize BIT
	SELECT @IsActivateNewOrderScreenwithSize=IsActivateNewOrderScreenwithSize FROM tbl_master_user WITH(NOLOCK) WHERE USER_ID=@USERID
	--End of Rev 4.0

	SET @LOGINEMPCODE=(SELECT USER_CONTACTID FROM TBL_MASTER_USER WITH(NOLOCK) WHERE USER_ID=@USERID)

	SELECT emp_cntId AS EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE INTO #EMPHR FROM tbl_trans_employeeCTC CTC WITH(NOLOCK) 
	LEFT OUTER JOIN tbl_master_employee TME WITH(NOLOCK) ON TME.emp_id= CTC.emp_reportTO

	;WITH CTE AS(SELECT	EMPCODE FROM #EMPHR WHERE EMPCODE IS NULL OR EMPCODE=@LOGINEMPCODE
	UNION ALL
	SELECT A.EMPCODE FROM #EMPHR A
	JOIN CTE B
	ON A.RPTTOEMPCODE = B.EMPCODE
	) 
	SELECT DISTINCT TMU.USER_CONTACTID AS EMPCODE INTO #EMPLOYEEHRLIST FROM CTE 
	INNER JOIN TBL_MASTER_USER TMU WITH(NOLOCK) ON CTE.EMPCODE=TMU.USER_CONTACTID

	--Rev 3.0
	IF @FROMDATE=CONVERT(NVARCHAR(10),GETDATE(),120) AND @TODATE=CONVERT(NVARCHAR(10),GETDATE(),120)
		SET @TABLENAME='TBL_TRANS_SHOPUSER WITH(NOLOCK) '
	ELSE
		SET @TABLENAME='TBL_TRANS_SHOPUSER_ARCH WITH(NOLOCK) '
	--End of Rev 3.0
	--Rev 4.0
	IF @IsActivateNewOrderScreenwithSize=1
		BEGIN
			IF OBJECT_ID('tempdb..#TMPORDATTRIBUTE') IS NOT NULL
				DROP TABLE #TMPORDATTRIBUTE
			CREATE TABLE #TMPORDATTRIBUTE(ID BIGINT,USER_ID BIGINT,ORDER_ID NVARCHAR(200),ORDER_DATE DATETIME,Ordervalue DECIMAL(18,2))
			CREATE NONCLUSTERED INDEX IX1 ON #TMPORDATTRIBUTE (USER_ID ASC)
			INSERT INTO #TMPORDATTRIBUTE(ID,USER_ID,ORDER_ID,ORDER_DATE,Ordervalue)
			SELECT ORDH.ID,ORDH.USER_ID,ORDH.ORDER_ID,ORDER_DATE,SUM(ISNULL(ORDD.Ordervalue,0)) AS Ordervalue FROM ORDERPRODUCTATTRIBUTE ORDH WITH(NOLOCK) 
			INNER JOIN(SELECT ORDD.ID,ORDD.USER_ID,ORDD.ORDER_ID,(ORDD.QTY*ORDD.RATE) AS Ordervalue FROM ORDERPRODUCTATTRIBUTEDET ORDD WITH(NOLOCK) 
			) ORDD ON ORDH.ID=ORDD.ID AND ORDH.USER_ID=ORDD.USER_ID AND ORDH.ORDER_ID=ORDD.ORDER_ID 
			GROUP BY ORDH.ID,ORDH.USER_ID,ORDH.ORDER_ID,ORDH.ORDER_DATE
		END
	--End of Rev 4.0

	--Rev 2.0
	--INSERT INTO #EMPLOYEEHRLIST SELECT emp_contactId FROM tbl_master_employee EMP INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo 
	--WHERE EMPCTC.emp_cntId=@LOGINEMPCODE
	--End of Rev 2.0

	--Rev 4.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TMPMASTEMPLOYEE') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TMPMASTEMPLOYEE') IS NOT NULL
	--End of Rev 4.0
		DROP TABLE #TMPMASTEMPLOYEE
	CREATE TABLE #TMPMASTEMPLOYEE(EMP_ID NUMERIC(18, 0) NOT NULL,EMP_UNIQUECODE VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,EMP_CONTACTID NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPMASTEMPLOYEE (EMP_CONTACTID ASC)

	INSERT INTO #TMPMASTEMPLOYEE SELECT EMP_ID,EMP_UNIQUECODE,EMP_CONTACTID FROM tbl_master_employee WITH(NOLOCK) WHERE EXISTS(SELECT emp_contactId FROM #EMPLOYEEHRLIST WHERE EMPCODE=emp_contactId)

	--Rev 4.0
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
	--End of Rev 4.0
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
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WITH(NOLOCK) WHERE cnt_contactType IN('EM')

	--Rev 3.0 && KM_TRAVELLED has been introduced.
	SET @Strsql=''
	SET @Strsql='SELECT EMPUSRID,ROW_NUMBER() OVER(ORDER BY EMPNAME) AS SEQ,CONTACTNO,STATEID,STATE,EMPCODE,EMPNAME,EMPID,'
	--Rev 3.0
	--SET @Strsql+='DEG_ID,DESIGNATION,RPTTOUSRID,RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,ISNULL(DISTANCE_TRAVELLED,0) AS DISTANCE_TRAVELLED,ISNULL(KM_TRAVELLED,0) AS KM_TRAVELLED,Total_Order_Booked_Value,Total_Collection FROM( '
	SET @Strsql+='DEG_ID,DESIGNATION,RPTTOUSRID,RPTTOEMPCODE,REPORTTO,RPTTODESGID,RPTTODESG,TOTAL_VISIT,NEWSHOP_VISITED,RE_VISITED,ISNULL(KM_TRAVELLED,0) AS DISTANCE_TRAVELLED,Total_Order_Booked_Value,Total_Collection FROM( '
	--End of Rev 3.0
	SET @Strsql+='SELECT USR.USER_ID AS EMPUSRID,CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,ST.ID AS STATEID,'
	SET @Strsql+='ST.state AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.RPTTOUSRID,RPTTO.RPTTOEMPCODE,RPTTO.REPORTTO,RPTTO.RPTTODESGID,RPTTO.RPTTODESG,EMP.emp_uniqueCode AS EMPID,'
	SET @Strsql+='ISNULL(SHOPACT.NEWSHOP_VISITED,0)+ISNULL(SHOPACT.RE_VISITED,0) AS TOTAL_VISIT,ISNULL(SHOPACT.NEWSHOP_VISITED,0) AS NEWSHOP_VISITED,ISNULL(SHOPACT.RE_VISITED,0) AS RE_VISITED,DISTANCE_TRAVELLED,SHOPUSR.KM_TRAVELLED,'
	SET @Strsql+='ISNULL(ORDHEAD.Ordervalue,0) AS Total_Order_Booked_Value,ISNULL(COLLEC.collectionvalue,0) AS Total_Collection '
	SET @Strsql+='FROM #TMPMASTEMPLOYEE EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR WITH(NOLOCK) ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST WITH(NOLOCK) ON ST.id=ADDR.add_state '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,CNT.cnt_internalId FROM tbl_fts_UserAttendanceLoginlogout ATTEN WITH(NOLOCK) '
	SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
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
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT WITH(NOLOCK) '
	SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--Rev 1.0
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--End of Rev 1.0
	SET @Strsql+='AND SHOPACT.Is_Newshopadd=1 '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT SHOPACT.User_Id,CNT.cnt_internalId,0 AS NEWSHOP_VISITED,COUNT(SHOPACT.Shop_Id) AS RE_VISITED,SUM(ISNULL(distance_travelled,0)) AS DISTANCE_TRAVELLED '
	SET @Strsql+='FROM tbl_trans_shopActivitysubmit SHOPACT WITH(NOLOCK) '
	SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=SHOPACT.User_Id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--Rev 1.0
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SHOPACT.visited_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--End of Rev 1.0
	SET @Strsql+='AND SHOPACT.Is_Newshopadd=0 '
	SET @Strsql+='GROUP BY SHOPACT.User_Id,CNT.cnt_internalId '
	SET @Strsql+=') AA GROUP BY User_Id,cnt_internalId) SHOPACT ON SHOPACT.cnt_internalId=CNT.cnt_internalId '
	--Rev 3.0
	SET @Strsql+='LEFT OUTER JOIN (SELECT User_Id,SUM(CAST(DISTANCE_COVERED AS DECIMAL(18,2))) AS KM_TRAVELLED FROM '+@TABLENAME+' '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='GROUP BY User_Id) SHOPUSR ON SHOPUSR.user_id=USR.user_id '
	--End of Rev 3.0
	--Rev 4.0
	IF @IsActivateNewOrderScreenwithSize=0
		BEGIN
	--End of Rev 4.0
			SET @Strsql+='LEFT OUTER JOIN (SELECT ORDH.userID,CNT.cnt_internalId,SUM(ISNULL(Ordervalue,0)) AS Ordervalue FROM tbl_trans_fts_Orderupdate ORDH WITH(NOLOCK) '
			SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=ORDH.userID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			--Rev 1.0
			--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			--End of Rev 1.0
			SET @Strsql+='GROUP BY ORDH.userID,CNT.cnt_internalId) ORDHEAD ON ORDHEAD.cnt_internalId=CNT.cnt_internalId '
	--Rev 4.0
		END
	ELSE IF @IsActivateNewOrderScreenwithSize=1
		BEGIN
			SET @Strsql+='LEFT OUTER JOIN ('
			SET @Strsql+='SELECT ORDH.USER_ID,CNT.cnt_internalId,SUM(ISNULL(ORDH.Ordervalue,0)) AS Ordervalue FROM #TMPORDATTRIBUTE ORDH '
			SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=ORDH.USER_ID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			SET @Strsql+='GROUP BY ORDH.USER_ID,CNT.cnt_internalId) ORDHEAD ON CNT.cnt_internalId=ORDHEAD.cnt_internalId '
		END
	--End of Rev 4.0
	SET @Strsql+='LEFT OUTER JOIN (SELECT COLLEC.user_id,CNT.cnt_internalId,SUM(ISNULL(COLLEC.collection,0)) AS collectionvalue FROM tbl_FTS_collection COLLEC WITH(NOLOCK) '
	SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=COLLEC.user_id '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	--Rev 1.0
	--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) = CONVERT(NVARCHAR(10),GETDATE(),120) '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),COLLEC.collection_date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	--End of Rev 1.0
	SET @Strsql+='GROUP BY COLLEC.user_id,CNT.cnt_internalId) COLLEC ON COLLEC.cnt_internalId=CNT.cnt_internalId '
	SET @Strsql+='LEFT OUTER JOIN (SELECT USR.USER_ID AS RPTTOUSRID,EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS RPTTOEMPCODE,'
	--Rev 2.0
	--SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG FROM #TMPMASTEMPLOYEE EMP '
	SET @Strsql+='ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,DESG.DEG_ID AS RPTTODESGID,DESG.deg_designation AS RPTTODESG '
	SET @Strsql+='FROM tbl_master_employee EMP WITH(NOLOCK) '
	--End of Rev 2.0
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_contactId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE CNT.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+=') AS DB '
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #TEMPCONTACT
	DROP TABLE #EMPHR
	DROP TABLE #EMPLOYEEHRLIST
	DROP TABLE #TMPMASTEMPLOYEE
	--Rev 4.0
	IF @IsActivateNewOrderScreenwithSize=1
		DROP TABLE #TMPORDATTRIBUTE
	--End of Rev 4.0

	SET NOCOUNT OFF
END