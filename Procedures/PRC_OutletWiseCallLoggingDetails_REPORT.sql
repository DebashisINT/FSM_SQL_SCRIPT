
--exec PRC_OUTLETWISECALLLOGGING_REPORT @FROMDATE='22-12-2023',@TODATE='22-12-2023',@USERID=378
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_OUTLETWISECALLLOGGING_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_OUTLETWISECALLLOGGING_REPORT] AS' 
END
GO
ALTER PROCEDURE [dbo].[PRC_OUTLETWISECALLLOGGING_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) 
WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
* Created by Priti for V2.0.44 on 19/12/2023. Work done in Controller, View and Model
* A new report is required as Outlet wise Call Logging Details Report (Customisation). Refer: 0027064  
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
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

	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DESIGNID <> ''
		BEGIN
			SET @DESIGNID=REPLACE(@DESIGNID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation where deg_id in('+@DESIGNID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
	DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')

	--drop TABLE OUTLETWISECALLLOGGING_REPORT

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'OUTLETWISECALLLOGGING_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE OUTLETWISECALLLOGGING_REPORT
			(
				 USERID INT,
				 SEQ INT,
				 CALLDATE NVARCHAR(10),
				EMPID NVARCHAR(500),
				EMPName NVARCHAR(500),
				Category NVARCHAR(200),
				ASMReporting NVARCHAR(500),
				VisitType NVARCHAR(200),
				VisitRevisitTime NVARCHAR(20),
				MDDName NVARCHAR(500),
				MDDCode NVARCHAR(500),
				OutletName NVARCHAR(500),
				OutletCode NVARCHAR(500),
				MobileNo NVARCHAR(100),
				OwnerName NVARCHAR(500),
				CALL_DATE NVARCHAR(10),
				CALL_TIME NVARCHAR(20),
				CALL_DURATION NVARCHAR(40),
				CalLCount BIGINT	
			)
			CREATE NONCLUSTERED INDEX IX1 ON OUTLETWISECALLLOGGING_REPORT (SEQ)
		END
		DELETE FROM OUTLETWISECALLLOGGING_REPORT WHERE [USERID]=@USERID


		
			IF OBJECT_ID('tempdb..#OUTLETWISECALLLOGGING_REPORT_LIST') IS NOT NULL
			DROP TABLE #OUTLETWISECALLLOGGING_REPORT_LIST
			CREATE TABLE #OUTLETWISECALLLOGGING_REPORT_LIST
			(
				 USERID INT,
				 SEQ INT,
				 CALLDATE NVARCHAR(10),
				EMPID NVARCHAR(500),
				EMPName NVARCHAR(500),
				Category NVARCHAR(200),
				ASMReporting NVARCHAR(500),
				VisitType NVARCHAR(200),
				VisitRevisitTime NVARCHAR(20),
				MDDName NVARCHAR(500),
				MDDCode NVARCHAR(500),
				OutletName NVARCHAR(500),
				OutletCode NVARCHAR(500),
				MobileNo NVARCHAR(100),
				OwnerName NVARCHAR(500),
				CALL_DATE NVARCHAR(10),
				CALL_TIME NVARCHAR(20),
				CALL_DURATION NVARCHAR(40),
				CalLCount BIGINT,
				emp_contactId NVARCHAR(200),
				STATEID BIGINT,
				deg_id INT
			)
			CREATE NONCLUSTERED INDEX IX1 ON #OUTLETWISECALLLOGGING_REPORT_LIST (SEQ)
		


SET @Strsql=''
SET @Strsql='INSERT INTO #OUTLETWISECALLLOGGING_REPORT_LIST (USERID,SEQ,CALLDATE,EMPID,EMPName,Category,ASMReporting,VisitType,VisitRevisitTime,MDDName,MDDCode,OutletName,OutletCode,MobileNo,OwnerName,CALL_DATE,CALL_TIME,CALL_DURATION,CalLCount,emp_contactId,STATEID,deg_id) '

SET @Strsql+=' select USERID,SEQ,CREATED_DATE,EMPID,EMPName,Category,ASMReporting,VisitType,visited_time,MDDName,MDDCode,OutletName,OutletCode,MobileNo,OwnerName,CALL_DATE,CALL_TIME,CALL_DURATION,CallCount,emp_contactId,STATEID,deg_id from ( '
SET @Strsql+=' select  '+STR(@USERID)+' AS USERID,ROW_NUMBER() OVER(ORDER BY CALL_DATE_TIME DESC) AS SEQ,CONVERT(NVARCHAR(10),CALL_DATE_TIME,105)AS CREATED_DATE,emp_uniqueCode as EMPID '
SET @Strsql+=',ISNULL(CNTEMP.CNT_FIRSTNAME,'''')+''''+ISNULL(CNTEMP.CNT_MIDDLENAME,'''')+ ''''+ISNULL(CNTEMP.CNT_LASTNAME,'''') as EMPName '
SET @Strsql+=',EmpDesgignation AS Category,REPORTTO AS ASMReporting,shoptype.Name	as VisitType'
SET @Strsql+=',case when CONVERT(NVARCHAR(10),shopActivity.visited_time,120)=CONVERT(NVARCHAR(10),CALL_DATE_TIME,120) then CONVERT(NVARCHAR(10),shopActivity.visited_time,108) else NULL end visited_time '
SET @Strsql+=',MDD.Shop_Name as MDDName,MDD.EntityCode as MDDCode ,shop.Shop_Name as OutletName,shop.EntityCode as OutletCode,Shop_Owner_Contact as MobileNo,Shop_Owner as OwnerName'
SET @Strsql+=',CONVERT(NVARCHAR(10),CALL_DATE_TIME,105)CALL_DATE,CALL_TIME,CALL_DURATION,1 as CallCount '
SET @Strsql+=',emp_contactId ,ISNULL(ST.ID,0) AS STATEID,EmpDesg.deg_id'
SET @Strsql+=' from tbl_master_employee EMP '
SET @Strsql+='INNER JOIN #TEMPCONTACT CNTEMP ON CNTEMP.cnt_internalId=EMP.emp_contactId '
SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNTEMP.cnt_internalid AND ADDR.add_addressType=''Office'' '
SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId '
SET @Strsql+='INNER JOIN FSMCALLHISTORYLIST CALLHISTORY on USR.user_id=CALLHISTORY.USERID '
SET @Strsql+='INNER JOIN tbl_Master_shop  shop  on shop.Shop_Code=CALLHISTORY.SHOP_ID '
SET @Strsql+='inner join tbl_shoptype shoptype  on shoptype.TypeId=shop.type '
SET @Strsql+='inner join tbl_trans_shopActivitysubmit shopActivity ON shopActivity.Shop_Id=shop.Shop_Code and CONVERT(NVARCHAR(10),visited_time,120)=CONVERT(NVARCHAR(10),CALL_DATE_TIME,120) '
SET @Strsql+='LEFT OUTER JOIN '
SET @Strsql+='( '
SET @Strsql+='select Shop_ID,Shop_Code,Shop_Name,assigned_to_dd_id,EntityCode from tbl_Master_shop where type=4 '
SET @Strsql+=')MDD on MDD.Shop_Code=shop.assigned_to_dd_id '
SET @Strsql+='LEFT OUTER JOIN '
SET @Strsql+='('
SET @Strsql+='	SELECT 	'	
SET @Strsql+='	ISNULL(CNT.CNT_FIRSTNAME,'''')+''''+ISNULL(CNT.CNT_MIDDLENAME,'''')+ ''''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO	'	
SET @Strsql+='	,EMPCTC.emp_cntId '
SET @Strsql+='	FROM tbl_master_employee EMP WITH (NOLOCK) '
SET @Strsql+='	INNER JOIN tbl_trans_employeeCTC EMPCTC WITH (NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo '
SET @Strsql+='	INNER JOIN #TEMPCONTACT CNT WITH(NOLOCK) ON CNT.cnt_internalId=EMP.emp_contactId and CNT.cnt_contactType=''EM''	'		
SET @Strsql+=') CTC ON CTC.emp_cntId=CNTEMP.cnt_internalId '
SET @Strsql+='LEFT OUTER JOIN '
SET @Strsql+='( '
SET @Strsql+='	SELECT cnt.emp_cntId,desg.deg_designation EmpDesgignation,MAX(emp_id) as emp_id,desg.deg_id '
SET @Strsql+='	FROM tbl_trans_employeeCTC as cnt WITH (NOLOCK)      '
SET @Strsql+='	LEFT OUTER JOIN tbl_master_designation desg WITH (NOLOCK) ON desg.deg_id=cnt.emp_Designation  '	 
SET @Strsql+='	WHERE cnt.emp_effectiveuntil IS NULL     '
SET @Strsql+='	GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
SET @Strsql+=') EmpDesg ON EmpDesg.emp_cntId=EMP.emp_contactId '
SET @Strsql+='WHERE CONVERT(NVARCHAR(10),CALL_DATE_TIME,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '

SET @Strsql+=') AS DB '


IF @STATEID<>'' AND @DESIGNID='' AND @EMPID=''
		SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID=''
		SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
	ELSE IF @STATEID='' AND @DESIGNID='' AND @EMPID<>''
		SET @Strsql+='WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.emp_contactId) '
	ELSE IF @STATEID<>'' AND @DESIGNID='' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.emp_contactId) '
		END
	ELSE IF @STATEID='' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.emp_contactId) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID=''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
		END
	ELSE IF @STATEID<>'' AND @DESIGNID<>'' AND @EMPID<>''
		BEGIN
			SET @Strsql+='WHERE EXISTS (SELECT State_Id from #STATEID_LIST AS ST WHERE ST.State_Id=DB.STATEID) '
			SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DB.deg_id) '
			SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=DB.emp_contactId) '
		END



	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql


	SET @Strsql=''
	SET @Strsql='INSERT INTO OUTLETWISECALLLOGGING_REPORT (USERID,SEQ,CALLDATE,EMPID,EMPName,Category,ASMReporting,VisitType,VisitRevisitTime,MDDName,MDDCode,OutletName,OutletCode,MobileNo,OwnerName,CALL_DATE,CALL_TIME,CALL_DURATION,CalLCount) '
	SET @Strsql+=' select USERID,SEQ,CALLDATE,EMPID,EMPName,Category,ASMReporting,VisitType,VisitRevisitTime,MDDName,MDDCode,OutletName,OutletCode,MobileNo,OwnerName,CALL_DATE,CALL_TIME,CALL_DURATION,CalLCount from #OUTLETWISECALLLOGGING_REPORT_LIST '

	
--SELECT @Strsql
EXEC SP_EXECUTESQL @Strsql


	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	DROP TABLE #OUTLETWISECALLLOGGING_REPORT_LIST

SET NOCOUNT OFF
END