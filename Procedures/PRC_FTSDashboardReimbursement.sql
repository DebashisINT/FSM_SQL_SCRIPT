IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSDashboardReimbursement]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSDashboardReimbursement] AS' 
END
GO

ALTER PROC [dbo].[PRC_FTSDashboardReimbursement] 
(
@ACTION  VARCHAR(500)=NULL,
@FROMDATE  VARCHAR(15)=NULL,
@TODATE  VARCHAR(152)=NULL,
@CREATE_USERID BIGINT=NULL
)
AS
/***********************************************************************************************************************************************************
Rev 1.0		Sanchita	V2.0.41			08-06-2023		FSM Dashboard - Reimbursement tab - Applied Amount per Month - The months names getting overlapped.
														Refer: 26314
************************************************************************************************************************************************************/
BEGIN

DECLARE @TOTAL_APP NUMERIC(18,2)=0
DECLARE @TOTAL_APP_APPR NUMERIC(18,2)=0
DECLARE @TOTAL_APP_REJECT NUMERIC(18,2)=0
DECLARE @TOTAL_APP_PENDING NUMERIC(18,2)=0

	--Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@CREATE_USERID)		
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
	--End of Rev 2.0

IF(@ACTION='BOXDATA')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			SET @TOTAL_APP=(select SUM(Amount) from FTS_Reimbursement_Application 
							INNER JOIN TBL_MASTER_USER USR ON UserID=USR.USER_ID 
							INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE 
			where cast([Date] as date)>=cast(@FROMDATE as date) and cast([Date] as date)<=cast(@TODATE as date))

			SET @TOTAL_APP_APPR=(select SUM(Amount) from FTS_Reimbursement_Application_Verified 									
			where ApplicationID in (select ApplicationID from FTS_Reimbursement_Application 
									INNER JOIN TBL_MASTER_USER USR ON UserID=USR.USER_ID 
									INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE 
									where cast([Date] as date)>=cast(@FROMDATE as date) and cast([Date] as date)<=cast(@TODATE as date)) and status=1)

			SET @TOTAL_APP_REJECT=(select SUM(Amount) from FTS_Reimbursement_Application_Verified 
			where ApplicationID in (select ApplicationID from FTS_Reimbursement_Application
									INNER JOIN TBL_MASTER_USER USR ON UserID=USR.USER_ID 
									INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE 
									 where cast([Date] as date)>=cast(@FROMDATE as date) and cast([Date] as date)<=cast(@TODATE as date)) and status=2)
						
		END
		ELSE
		BEGIN
			SET @TOTAL_APP=(select SUM(Amount) from FTS_Reimbursement_Application where cast([Date] as date)>=cast(@FROMDATE as date) and cast([Date] as date)<=cast(@TODATE as date))
			SET @TOTAL_APP_APPR=(select SUM(Amount) from FTS_Reimbursement_Application_Verified where ApplicationID in (select ApplicationID from FTS_Reimbursement_Application where cast([Date] as date)>=cast(@FROMDATE as date) and cast([Date] as date)<=cast(@TODATE as date)) and status=1)
			SET @TOTAL_APP_REJECT=(select SUM(Amount) from FTS_Reimbursement_Application_Verified where ApplicationID in (select ApplicationID from FTS_Reimbursement_Application where cast([Date] as date)>=cast(@FROMDATE as date) and cast([Date] as date)<=cast(@TODATE as date)) and status=2)
					
		END
	SET @TOTAL_APP_PENDING=@TOTAL_APP-@TOTAL_APP_APPR-@TOTAL_APP_REJECT
	select ISNULL(@TOTAL_APP,0) total,ISNULL(@TOTAL_APP_APPR,0) approved,ISNULL(@TOTAL_APP_REJECT,0) rejected ,ISNULL(@TOTAL_APP_PENDING,0) pending

	END
ELSE IF(@ACTION='APPLIEDAMOUNTMONTH')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			select top 12 sum(Amount) Amount,months from (
			-- Rev 1.0
			--select Amount,DATENAME(MONTH,[Date])+','+DATENAME(YEAR,[Date]) months
			--,CONVERT(BIGINT,CONVERT(VARCHAR(50),YEAR([Date])) +CONVERT(VARCHAR(50),MONTH([Date]))) ord
			select Amount,FORMAT([Date],'MMM')+' '+DATENAME(YEAR,[Date]) months
			,format([Date],'yyyy-MM'+'-01') ord
			-- End of Rev 1.0
			from FTS_Reimbursement_Application --=where cast([Date] as date)>=cast([Date] as date)
			INNER JOIN TBL_MASTER_USER USR ON UserID=USR.USER_ID 
			INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE
			-- Rev 1.0
			where cast([Date] as date)>=@FROMDATE and cast([Date] as date)<=@TODATE
			-- End of Rev 1.0
			) tbl group by months,ord  order by ord desc
		END
		ELSE
		BEGIN
				select top 12 sum(Amount) Amount,months from (
			-- Rev 1.0
			--select Amount,DATENAME(MONTH,[Date])+','+DATENAME(YEAR,[Date]) months
			--,CONVERT(BIGINT,CONVERT(VARCHAR(50),YEAR([Date])) +CONVERT(VARCHAR(50),MONTH([Date]))) ord
			select Amount,FORMAT([Date],'MMM')+' '+DATENAME(YEAR,[Date]) months
			,format([Date],'yyyy-MM'+'-01') ord
			-- End of Rev 1.0
			from FTS_Reimbursement_Application --=where cast([Date] as date)>=cast([Date] as date)
			-- Rev 1.0
			where cast([Date] as date)>=@FROMDATE and cast([Date] as date)<=@TODATE
			-- End of Rev 1.0
			) tbl group by months,ord  order by ord desc
		END
	END
ELSE IF(@ACTION='BYTYPE')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
		select sum(Amount) Amount,Expence_type from (
		select Amount,Expence_type
		from FTS_Reimbursement_Application
		INNER JOIN TBL_MASTER_USER USR ON UserID=USR.USER_ID 
			INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE
		 where cast([Date] as date)<=cast(GETDATe() as date)
		) tbl group by Expence_type
		END
		ELSE
		BEGIN
			select sum(Amount) Amount,Expence_type from (
			select Amount,Expence_type
			from FTS_Reimbursement_Application where cast([Date] as date)<=cast(GETDATe() as date)
			) tbl group by Expence_type
		END
	END
ELSE IF(@ACTION='BYTYPECURRENTMONTH')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			select sum(Amount) Amount,Expence_type from (
			select Amount,Expence_type
			from FTS_Reimbursement_Application
			INNER JOIN TBL_MASTER_USER USR ON UserID=USR.USER_ID 
			INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE
			 where MONTH([Date])<=MONTH(GETDATe())
			) tbl group by Expence_type
		END
		ELSE
		BEGIN
			select sum(Amount) Amount,Expence_type from (
			select Amount,Expence_type
			from FTS_Reimbursement_Application where MONTH([Date])<=MONTH(GETDATe())
			) tbl group by Expence_type
		END
	END
ELSE IF(@ACTION='BYTYPELASTMONTH')
	BEGIN
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			select sum(Amount) Amount,Expence_type from (
			select Amount,Expence_type
			from FTS_Reimbursement_Application
			INNER JOIN TBL_MASTER_USER USR ON UserID=USR.USER_ID 
			INNER JOIN #EMPHR_EDIT TMPR ON USR.user_contactId=TMPR.EMPCODE
			 where MONTH([Date])<=MONTH(DATEADD(month,-1,GETDATe()))
			) tbl group by Expence_type
		END
		ELSE
		BEGIN
			select sum(Amount) Amount,Expence_type from (
			select Amount,Expence_type
			from FTS_Reimbursement_Application where MONTH([Date])<=MONTH(DATEADD(month,-1,GETDATe()))
			) tbl group by Expence_type
		END
	END


	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@CREATE_USERID)=1)
		BEGIN
			DROP TABLE #EMPHR
			DROP TABLE #EMPHR_EDIT
		END
END
