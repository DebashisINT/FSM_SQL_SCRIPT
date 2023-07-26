
--EXEC PRC_FTSORDERDBWITHANOTHERTAB_REPORT '2023-07-01','2023-07-24','TOP10STVAL',378,'15,3,35,1,24,19,16,2,28,8','1,118,119,120,121,122,123,124,125,127,128'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSORDERDBWITHANOTHERTAB_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSORDERDBWITHANOTHERTAB_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSORDERDBWITHANOTHERTAB_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@REPORTTYPE NVARCHAR(20)=NULL,
@USERID BIGINT=NULL
-- Rev 3.0
,@STATEID NVARCHAR(MAX)=NULL,
@BRANCHID NVARCHAR(MAX)=NULL
-- End of Rev 3.0
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder On 30/04/2020
Module	   : FSM ORDER DASHBOARD WITH ANOTHER TAB.Refer: 22266
1.0		Sanchita	v2.0.33		FSM Dashboard - Order Panel - Incorrect value showing user head "Statewise Top Orders on Order Value" . Refer: 25214
2.0		Debashis	v2.0.33		Dashboard Order analytics tab would consider the new Sales Order table (Lavos type order).Refer: 0025229
3.0		Sanchita	V2.0.41		State & Branch selection facility is required in the Order Analytics in Dashboard. Refer: 26309
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX)
	--Rev 2.0
	DECLARE @IsActivateNewOrderScreenwithSize BIT
	SELECT @IsActivateNewOrderScreenwithSize=IsActivateNewOrderScreenwithSize FROM tbl_master_user WHERE user_id=@USERID
	--End of Rev 2.0

	-- Rev 3.0
	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
		DROP TABLE #STATEID_LIST
	CREATE TABLE #STATEID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
	IF @STATEID <> ''
		BEGIN
			SET @STATEID=REPLACE(@STATEID,'''','')
			SET @Strsql=''
			SET @Strsql=' INSERT INTO #STATEID_LIST SELECT id from tbl_master_state where id in('+@STATEID+')'
			EXEC SP_EXECUTESQL @Strsql
		END
	
	IF OBJECT_ID('tempdb..#BRANCHID_LIST') IS NOT NULL
		DROP TABLE #BRANCHID_LIST
	CREATE TABLE #BRANCHID_LIST (Branch_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #BRANCHID_LIST (Branch_Id ASC)
	IF @BRANCHID <> ''
		BEGIN
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @Strsql=''
			SET @Strsql=' INSERT INTO #BRANCHID_LIST SELECT branch_id from tbl_master_branch where branch_id in('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @Strsql
		END
	-- End of Rev 3.0

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
			IF OBJECT_ID('tempdb..#EMPHR') IS NOT NULL
				DROP TABLE #EMPHR
			CREATE TABLE #EMPHR
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			IF OBJECT_ID('tempdb..#EMPHR_EDIT') IS NOT NULL
				DROP TABLE #EMPHR_EDIT
			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
		
			INSERT INTO #EMPHR
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHR 
			where EMPCODE IS NULL OR EMPCODE=@empcode  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHR a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 

		END

	SET @Strsql=''
	IF @REPORTTYPE='ORDCNT'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT COUNT(0) AS ORDCNT FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '

					SET @Strsql='SELECT COUNT(0) AS ORDCNT FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT COUNT(0) AS ORDCNT FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '

					SET @Strsql='SELECT COUNT(0) AS ORDCNT FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='ORDVALUE'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT CASE WHEN CAST(SUM(ISNULL(Ordervalue,0)) AS DECIMAL(18,2)) IS NULL THEN 0.00 ELSE CAST(SUM(ISNULL(Ordervalue,0.00)) AS DECIMAL(18,2)) END AS ORDVALUE '
					--SET @Strsql+='FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '

					SET @Strsql='SELECT CASE WHEN CAST(SUM(ISNULL(Ordervalue,0)) AS DECIMAL(18,2)) IS NULL THEN 0.00 ELSE CAST(SUM(ISNULL(Ordervalue,0.00)) AS DECIMAL(18,2)) END AS ORDVALUE '
					SET @Strsql+='FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT CASE WHEN CAST(SUM(ISNULL(ORDVALUE,0)) AS DECIMAL(18,2)) IS NULL THEN 0.00 ELSE CAST(SUM(ISNULL(ORDVALUE,0.00)) AS DECIMAL(18,2)) END AS ORDVALUE '
					--SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--SET @Strsql+='INNER JOIN(SELECT ID,USER_ID,ORDER_ID,(QTY*RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET '
					--SET @Strsql+=') ORDD ON ORDHEAD.ID=ORDD.ID AND ORDHEAD.USER_ID=ORDD.USER_ID AND ORDHEAD.ORDER_ID=ORDD.ORDER_ID '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '

					SET @Strsql='SELECT CASE WHEN CAST(SUM(ISNULL(ORDVALUE,0)) AS DECIMAL(18,2)) IS NULL THEN 0.00 ELSE CAST(SUM(ISNULL(ORDVALUE,0.00)) AS DECIMAL(18,2)) END AS ORDVALUE '
					SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN(SELECT ID,USER_ID,ORDER_ID,(QTY*RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET '
					SET @Strsql+=') ORDD ON ORDHEAD.ID=ORDD.ID AND ORDHEAD.USER_ID=ORDD.USER_ID AND ORDHEAD.ORDER_ID=ORDD.ORDER_ID '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='AVGORDVALUE'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT CASE WHEN CAST(SUM(ISNULL(Ordervalue,0)) AS DECIMAL(18,2)) IS NULL THEN 0.00 ELSE CAST(SUM(ISNULL(Ordervalue,0.00))/COUNT(0) AS DECIMAL(18,2)) END AS AVGORDVALUE '
					--SET @Strsql+='FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '

					SET @Strsql='SELECT CASE WHEN CAST(SUM(ISNULL(Ordervalue,0)) AS DECIMAL(18,2)) IS NULL THEN 0.00 ELSE CAST(SUM(ISNULL(Ordervalue,0.00))/COUNT(0) AS DECIMAL(18,2)) END AS AVGORDVALUE '
					SET @Strsql+='FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT CASE WHEN CAST(SUM(ISNULL(ORDVALUE,0)) AS DECIMAL(18,2)) IS NULL THEN 0.00 ELSE CAST(SUM(ISNULL(ORDVALUE,0.00))/COUNT(ORDHEAD.ORDER_ID) AS DECIMAL(18,2)) END AS AVGORDVALUE '
					--SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--SET @Strsql+='INNER JOIN(SELECT ID,USER_ID,ORDER_ID,(QTY*RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET '
					--SET @Strsql+=') ORDD ON ORDHEAD.ID=ORDD.ID AND ORDHEAD.USER_ID=ORDD.USER_ID AND ORDHEAD.ORDER_ID=ORDD.ORDER_ID '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					
					SET @Strsql='SELECT CASE WHEN CAST(SUM(ISNULL(ORDVALUE,0)) AS DECIMAL(18,2)) IS NULL THEN 0.00 ELSE CAST(SUM(ISNULL(ORDVALUE,0.00))/COUNT(ORDHEAD.ORDER_ID) AS DECIMAL(18,2)) END AS AVGORDVALUE '
					SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN(SELECT ID,USER_ID,ORDER_ID,(QTY*RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET '
					SET @Strsql+=') ORDD ON ORDHEAD.ID=ORDD.ID AND ORDHEAD.USER_ID=ORDD.USER_ID AND ORDHEAD.ORDER_ID=ORDD.ORDER_ID '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='ORDDELV'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT COUNT(0) AS ORDDELV FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='AND EXISTS(SELECT BILLD.OrderCode FROM tbl_FTS_BillingDetails BILLD WHERE BILLD.OrderCode=ORDHEAD.OrderCode) '
					SET @Strsql='SELECT COUNT(0) AS ORDDELV FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND EXISTS(SELECT BILLD.OrderCode FROM tbl_FTS_BillingDetails BILLD WHERE BILLD.OrderCode=ORDHEAD.OrderCode) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT COUNT(0) AS ORDDELV FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='AND EXISTS(SELECT BILLD.OrderCode FROM tbl_FTS_BillingDetails BILLD WHERE BILLD.OrderCode=ORDHEAD.ORDER_ID) '
					SET @Strsql='SELECT COUNT(0) AS ORDDELV FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					SET @Strsql+='AND EXISTS(SELECT BILLD.OrderCode FROM tbl_FTS_BillingDetails BILLD WHERE BILLD.OrderCode=ORDHEAD.ORDER_ID) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					-- End of 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='ORDCNTDATE'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,ORDCNT FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDERDATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDERDATE AS DATE) AS ORDERDATE,COUNT(0) AS ORDCNT FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDERDATE AS DATE)) ORDDT '
					SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,ORDCNT FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDERDATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDERDATE AS DATE) AS ORDERDATE,COUNT(0) AS ORDCNT FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDERDATE AS DATE)) ORDDT '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,ORDCNT FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDER_DATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDER_DATE AS DATE) AS ORDERDATE,COUNT(0) AS ORDCNT FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDER_DATE AS DATE)) ORDDT '
					SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,ORDCNT FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDER_DATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDER_DATE AS DATE) AS ORDERDATE,COUNT(0) AS ORDCNT FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDER_DATE AS DATE)) ORDDT '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='ORDVALDT'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,ORDVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDERDATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDERDATE AS DATE) AS ORDERDATE,CAST(SUM(ISNULL(ORDHEAD.Ordervalue,0.00)) AS DECIMAL(18,2)) AS ORDVALUE '
					--SET @Strsql+='FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDERDATE AS DATE)) ORDVDT '
					SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,ORDVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDERDATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDERDATE AS DATE) AS ORDERDATE,CAST(SUM(ISNULL(ORDHEAD.Ordervalue,0.00)) AS DECIMAL(18,2)) AS ORDVALUE '
					SET @Strsql+='FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDERDATE AS DATE)) ORDVDT '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,ORDVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDER_DATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDER_DATE AS DATE) AS ORDERDATE,CAST(SUM(ISNULL(ORDD.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE '
					--SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--SET @Strsql+='INNER JOIN(SELECT ID,USER_ID,ORDER_ID,(QTY*RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET '
					--SET @Strsql+=') ORDD ON ORDHEAD.ID=ORDD.ID AND ORDHEAD.USER_ID=ORDD.USER_ID AND ORDHEAD.ORDER_ID=ORDD.ORDER_ID '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDER_DATE AS DATE)) ORDVDT '
					SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,ORDVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDER_DATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDER_DATE AS DATE) AS ORDERDATE,CAST(SUM(ISNULL(ORDD.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE '
					SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN(SELECT ID,USER_ID,ORDER_ID,(QTY*RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET '
					SET @Strsql+=') ORDD ON ORDHEAD.ID=ORDD.ID AND ORDHEAD.USER_ID=ORDD.USER_ID AND ORDHEAD.ORDER_ID=ORDD.ORDER_ID '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDER_DATE AS DATE)) ORDVDT '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='ORDVALDELV'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,BILLVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDERDATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDERDATE AS DATE) AS ORDERDATE,CAST(SUM(ISNULL(BILLHEAD.invoice_amount,0.00)) AS DECIMAL(18,2)) AS BILLVALUE '
					--SET @Strsql+='FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN tbl_FTS_BillingDetails BILLHEAD ON ORDHEAD.OrderCode=BILLHEAD.OrderCode '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDERDATE AS DATE)) ORDBV '
					SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,BILLVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDERDATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDERDATE AS DATE) AS ORDERDATE,CAST(SUM(ISNULL(BILLHEAD.invoice_amount,0.00)) AS DECIMAL(18,2)) AS BILLVALUE '
					SET @Strsql+='FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN tbl_FTS_BillingDetails BILLHEAD ON ORDHEAD.OrderCode=BILLHEAD.OrderCode '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--IF @STATEID<>''
					--	SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					--IF  @STATEID<>'' and @BRANCHID<>''
					--	SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '					
					--SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDER_DATE AS DATE)) ORDVDT '
					SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDERDATE AS DATE)) ORDBV '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,BILLVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDER_DATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDER_DATE AS DATE) AS ORDERDATE,CAST(SUM(ISNULL(BILLHEAD.invoice_amount,0.00)) AS DECIMAL(18,2)) AS BILLVALUE '
					--SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN tbl_FTS_BillingDetails BILLHEAD ON ORDHEAD.ORDER_ID=BILLHEAD.OrderCode '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDER_DATE AS DATE)) ORDBV '
					SET @Strsql='SELECT CONVERT(NVARCHAR(5),ORDERDATE,105) AS ORDERDATE,BILLVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY CAST(ORDHEAD.ORDER_DATE AS DATE)) AS SEQ,CAST(ORDHEAD.ORDER_DATE AS DATE) AS ORDERDATE,CAST(SUM(ISNULL(BILLHEAD.invoice_amount,0.00)) AS DECIMAL(18,2)) AS BILLVALUE '
					SET @Strsql+='FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN tbl_FTS_BillingDetails BILLHEAD ON ORDHEAD.ORDER_ID=BILLHEAD.OrderCode '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY CAST(ORDHEAD.ORDER_DATE AS DATE)) ORDBV '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='TOP10ITEMSVAL'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT TOP 10 OVD.SEQ,OVD.PRODUCT,OVD.ORDVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,PRODUCT,ORDVALUE FROM('
					--SET @Strsql+='SELECT DET.PRODUCT,CAST(SUM(ISNULL(DET.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN (SELECT ORDDET.Order_ID,PROD.sProducts_Name AS PRODUCT,(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE FROM tbl_FTs_OrderdetailsProduct ORDDET '
					--SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.Product_Id '
					--SET @Strsql+=') DET ON ORDHEAD.OrderId=DET.Order_ID '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY DET.PRODUCT '
					--SET @Strsql+=')OV '
					--SET @Strsql+=')OVD '

					SET @Strsql='SELECT TOP 10 OVD.SEQ,OVD.PRODUCT,OVD.ORDVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,PRODUCT,ORDVALUE FROM('
					SET @Strsql+='SELECT DET.PRODUCT,CAST(SUM(ISNULL(DET.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN (SELECT ORDDET.Order_ID,PROD.sProducts_Name AS PRODUCT,(ORDDET.Product_Qty*ORDDET.Product_Rate) AS ORDVALUE FROM tbl_FTs_OrderdetailsProduct ORDDET '
					SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.Product_Id '
					SET @Strsql+=') DET ON ORDHEAD.OrderId=DET.Order_ID '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY DET.PRODUCT '
					SET @Strsql+=')OV '
					SET @Strsql+=')OVD '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT TOP 10 OVD.SEQ,OVD.PRODUCT,OVD.ORDVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,PRODUCT,ORDVALUE FROM('
					--SET @Strsql+='SELECT DET.PRODUCT,CAST(SUM(ISNULL(DET.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,PROD.sProducts_Name AS PRODUCT,(ORDDET.QTY*ORDDET.RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET ORDDET '
					--SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.PRODUCT_ID '
					--SET @Strsql+=') DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY DET.PRODUCT '
					--SET @Strsql+=')OV '
					--SET @Strsql+=')OVD '
					SET @Strsql='SELECT TOP 10 OVD.SEQ,OVD.PRODUCT,OVD.ORDVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,PRODUCT,ORDVALUE FROM('
					SET @Strsql+='SELECT DET.PRODUCT,CAST(SUM(ISNULL(DET.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,PROD.sProducts_Name AS PRODUCT,(ORDDET.QTY*ORDDET.RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET ORDDET '
					SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.PRODUCT_ID '
					SET @Strsql+=') DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY DET.PRODUCT '
					SET @Strsql+=')OV '
					SET @Strsql+=')OVD '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='TOP10ITEMSQTY'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT TOP 10 OVD.SEQ,OVD.PRODUCT,OVD.ORDQTY FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDQTY DESC) AS SEQ,PRODUCT,ORDQTY FROM('
					--SET @Strsql+='SELECT DET.PRODUCT,SUM(DET.ORDQTY) AS ORDQTY FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN (SELECT ORDDET.Order_ID,PROD.sProducts_Name AS PRODUCT,ORDDET.Product_Qty AS ORDQTY FROM tbl_FTs_OrderdetailsProduct ORDDET '
					--SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.Product_Id '
					--SET @Strsql+=') DET ON ORDHEAD.OrderId=DET.Order_ID '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY DET.PRODUCT '
					--SET @Strsql+=')OV '
					--SET @Strsql+=')OVD '

					SET @Strsql='SELECT TOP 10 OVD.SEQ,OVD.PRODUCT,OVD.ORDQTY FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDQTY DESC) AS SEQ,PRODUCT,ORDQTY FROM('
					SET @Strsql+='SELECT DET.PRODUCT,SUM(DET.ORDQTY) AS ORDQTY FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN (SELECT ORDDET.Order_ID,PROD.sProducts_Name AS PRODUCT,ORDDET.Product_Qty AS ORDQTY FROM tbl_FTs_OrderdetailsProduct ORDDET '
					SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.Product_Id '
					SET @Strsql+=') DET ON ORDHEAD.OrderId=DET.Order_ID '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY DET.PRODUCT '
					SET @Strsql+=')OV '
					SET @Strsql+=')OVD '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT TOP 10 OVD.SEQ,OVD.PRODUCT,OVD.ORDQTY FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDQTY DESC) AS SEQ,PRODUCT,ORDQTY FROM('
					--SET @Strsql+='SELECT DET.PRODUCT,SUM(DET.ORDQTY) AS ORDQTY FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,PROD.sProducts_Name AS PRODUCT,ORDDET.QTY AS ORDQTY FROM ORDERPRODUCTATTRIBUTEDET ORDDET '
					--SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.PRODUCT_ID '
					--SET @Strsql+=') DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY DET.PRODUCT '
					--SET @Strsql+=')OV '
					--SET @Strsql+=')OVD '

					SET @Strsql='SELECT TOP 10 OVD.SEQ,OVD.PRODUCT,OVD.ORDQTY FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDQTY DESC) AS SEQ,PRODUCT,ORDQTY FROM('
					SET @Strsql+='SELECT DET.PRODUCT,SUM(DET.ORDQTY) AS ORDQTY FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,PROD.sProducts_Name AS PRODUCT,ORDDET.QTY AS ORDQTY FROM ORDERPRODUCTATTRIBUTEDET ORDDET '
					SET @Strsql+='INNER JOIN Master_sProducts PROD ON PROD.sProducts_ID=ORDDET.PRODUCT_ID '
					SET @Strsql+=') DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY DET.PRODUCT '
					SET @Strsql+=')OV '
					SET @Strsql+=')OVD '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='TOP10CUSTVAL'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT TOP 10 CUD.SEQ,CUD.SHOPNAME,CUD.ORDVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,SHOPNAME,ORDVALUE FROM('
					--SET @Strsql+='SELECT SHOP.Shop_Name AS SHOPNAME,CAST(SUM(ISNULL(ORDHEAD.Ordervalue,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON ORDHEAD.Shop_Code=SHOP.Shop_Code '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY SHOP.Shop_Name '
					--SET @Strsql+=')CU '
					--SET @Strsql+=')CUD '

					SET @Strsql='SELECT TOP 10 CUD.SEQ,CUD.SHOPNAME,CUD.ORDVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,SHOPNAME,ORDVALUE FROM('
					SET @Strsql+='SELECT SHOP.Shop_Name AS SHOPNAME,CAST(SUM(ISNULL(ORDHEAD.Ordervalue,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON ORDHEAD.Shop_Code=SHOP.Shop_Code '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY SHOP.Shop_Name '
					SET @Strsql+=')CU '
					SET @Strsql+=')CUD '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT TOP 10 CUD.SEQ,CUD.SHOPNAME,CUD.ORDVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,SHOPNAME,ORDVALUE FROM('
					--SET @Strsql+='SELECT SHOP.Shop_Name AS SHOPNAME,CAST(SUM(ISNULL(DET.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,(ORDDET.QTY*ORDDET.RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET ORDDET '
					--SET @Strsql+=') DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID '
					--SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON ORDHEAD.SHOP_ID=SHOP.Shop_Code '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY SHOP.Shop_Name '
					--SET @Strsql+=')CU '
					--SET @Strsql+=')CUD '

					SET @Strsql='SELECT TOP 10 CUD.SEQ,CUD.SHOPNAME,CUD.ORDVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,SHOPNAME,ORDVALUE FROM('
					SET @Strsql+='SELECT SHOP.Shop_Name AS SHOPNAME,CAST(SUM(ISNULL(DET.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,(ORDDET.QTY*ORDDET.RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET ORDDET '
					SET @Strsql+=') DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID '
					SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON ORDHEAD.SHOP_ID=SHOP.Shop_Code '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_address ADDR ON ADDR.add_cntId=USR.user_contactId AND ADDR.add_addressType=''Office'' '
					SET @Strsql+='LEFT OUTER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=USR.user_branchId) '
					SET @Strsql+='GROUP BY SHOP.Shop_Name '
					SET @Strsql+=')CU '
					SET @Strsql+=')CUD '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	ELSE IF @REPORTTYPE='TOP10STVAL'
		BEGIN
			--Rev 2.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 2.0
					-- Rev 3.0
					--SET @Strsql='SELECT TOP 10 STD.SEQ,STD.STCODE,STD.STATENAME,STD.ORDVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,STCODE,STATENAME,ORDVALUE FROM('
					--SET @Strsql+='SELECT ST.StateUniqueCode AS STCODE,ST.state AS STATENAME,CAST(SUM(ISNULL(ORDHEAD.Ordervalue,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					---- Rev 1.0
					----SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
					----SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.ID=SHOP.STATEID '
					--SET @Strsql+='INNER JOIN tbl_master_branch BR on BR.branch_id=USR.user_branchId '
					--SET @Strsql += 'INNER JOIN tbl_master_state ST ON ST.ID=BR.branch_state '
					---- End of Rev 1.0
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY ST.StateUniqueCode,ST.state '
					--SET @Strsql+=')ST '
					--SET @Strsql+=')STD '

					SET @Strsql='SELECT TOP 10 STD.SEQ,STD.STCODE,STD.STATENAME,STD.ORDVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,STCODE,STATENAME,ORDVALUE FROM('
					SET @Strsql+='SELECT ST.StateUniqueCode AS STCODE,ST.state AS STATENAME,CAST(SUM(ISNULL(ORDHEAD.Ordervalue,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM tbl_trans_fts_Orderupdate AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.userID '
					-- Rev 1.0
					--SET @Strsql+='INNER JOIN tbl_Master_shop SHOP ON SHOP.Shop_CreateUser=USR.user_id '
					--SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.ID=SHOP.STATEID '
					SET @Strsql+='INNER JOIN tbl_master_branch BR on BR.branch_id=USR.user_branchId '
					SET @Strsql += 'INNER JOIN tbl_master_state ST ON ST.ID=BR.branch_state '
					-- End of Rev 1.0
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDERDATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=BR.branch_id) '
					SET @Strsql+='GROUP BY ST.StateUniqueCode,ST.state '
					SET @Strsql+=')ST '
					SET @Strsql+=')STD '
					-- End of Rev 3.0
			--Rev 2.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					-- Rev 3.0
					--SET @Strsql='SELECT TOP 10 STD.SEQ,STD.STCODE,STD.STATENAME,STD.ORDVALUE FROM('
					--SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,STCODE,STATENAME,ORDVALUE FROM('
					--SET @Strsql+='SELECT ST.StateUniqueCode AS STCODE,ST.state AS STATENAME,CAST(SUM(ISNULL(DET.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					--SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					--IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					--BEGIN
					--	SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					--END
					--SET @Strsql+='INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,(ORDDET.QTY*ORDDET.RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET ORDDET '
					--SET @Strsql+=') DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID '
					--SET @Strsql+='INNER JOIN tbl_master_branch BR on BR.branch_id=USR.user_branchId '
					--SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.ID=BR.branch_state '
					--SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					--SET @Strsql+='GROUP BY ST.StateUniqueCode,ST.state '
					--SET @Strsql+=')ST '
					--SET @Strsql+=')STD '

					SET @Strsql='SELECT TOP 10 STD.SEQ,STD.STCODE,STD.STATENAME,STD.ORDVALUE FROM('
					SET @Strsql+='SELECT ROW_NUMBER() OVER(ORDER BY ORDVALUE DESC) AS SEQ,STCODE,STATENAME,ORDVALUE FROM('
					SET @Strsql+='SELECT ST.StateUniqueCode AS STCODE,ST.state AS STATENAME,CAST(SUM(ISNULL(DET.ORDVALUE,0.00)) AS DECIMAL(18,2)) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTE AS ORDHEAD '
					SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ORDHEAD.USER_ID '
					IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
					BEGIN
						SET @Strsql+='INNER JOIN #EMPHR_EDIT TMP ON USR.user_contactId=TMP.EMPCODE '
					END
					SET @Strsql+='INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,(ORDDET.QTY*ORDDET.RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET ORDDET '
					SET @Strsql+=') DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID '
					SET @Strsql+='INNER JOIN tbl_master_branch BR on BR.branch_id=USR.user_branchId '
					SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.ID=BR.branch_state '
					SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDHEAD.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
					IF @STATEID<>''
						SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
					IF  @STATEID<>'' and @BRANCHID<>''
						SET @Strsql+=' and EXISTS (SELECT Branch_Id from #BRANCHID_LIST AS BR WHERE BR.Branch_Id=BR.branch_id) '
					SET @Strsql+='GROUP BY ST.StateUniqueCode,ST.state '
					SET @Strsql+=')ST '
					SET @Strsql+=')STD '
					-- End of Rev 3.0
				END
			--End of Rev 2.0
		END
	
	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END

	SET NOCOUNT OFF
END