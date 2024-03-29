IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_MONTHLYACTIVEUSERCOUNT]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_MONTHLYACTIVEUSERCOUNT] AS' 
END
GO

-- EXEC PROC_MONTHLYACTIVEUSERCOUNT

ALTER Proc [dbo].[PROC_MONTHLYACTIVEUSERCOUNT]
(
	@CLIENT_DBNAME NVARCHAR(500) = ''  -- select DB1,CLIENT_NAME from BREEZE_CLIENT_DETAILS where TYPE_OF_PRODUCT in ('FSM','Attendance System - FSM') 
)
As
/************************************************************************************************************************************************************
Written for Alter query for Active User Count Monthwise as per discussion
Mantis : 26243

CHURN PROBABLITY
	FORMULA - 
		IF(CURRENT MONTH ATTENDANCE COUNT < LAST 3 MONTH AVERAGE ATTENDANCE COUNT AND 
		CURRENT MONTH ATTENDANCE COUNT<PREVIOUS MONTH ATTENDANCE COUNT), 
			VALUE = "HIGH RISK") 
		OTHERWISE 
			"No churn probability detected."


"Business Growth" 
	 FORMULA - 
		IF((CURRENT MONTH Order Count< LAST 3 MONTH AVERAGE order COUNT), 
			show 'Growth is less <20%> from last 3 months Order Count"   (CALCULATION OF % = (Current month count/last 3 month average count *100)
		Otherwise
		IF((CURRENT MONTH Order Count>= LAST 3 MONTH AVERAGE order COUNT), 
			show 'Growth is > <20%> from last 3 months Order Count"   (CALCULATION OF % = (CALCULATION OF % = (Current month count/last 3 month average count *100)
************************************************************************************************************************************************************/
Begin
	CREATE TABLE #tempusercount_raw
	(
	SLNO int,
	Month_Name varchar(50),
	CLIENT_NAME nvarchar(500),
	Activ_User_Count bigint,
	Inactiv_User_Count bigint,
	Attendance_Count bigint,
	ORDER_COUNT BIGINT
	)

	CREATE TABLE #master_user
	(
		user_id numeric(10),
		user_contactId nvarchar(100),
		Custom_Configuration bit,
		isComplementaryUser bit,
		user_inactive VARCHAR(2),
		LastModifyDate NVARCHAR(50)
	)

	--CREATE TABLE #tempusercount
	--(
	--	SLNO int,
	--	Month_Name varchar(50),
	--	CLIENT_NAME nvarchar(500),
	--	Activ_User_Count bigint,
	--	Inactiv_User_Count bigint,
	--	Attendance_Count bigint,
	--	ORDER_COUNT BIGINT,
	--	CHURN_PROBABLITY nvarchar(100),
	--	BUSUNESS_GROWTH NVARCHAR(100)
	--)
	--create nonclustered index idx on #tempusercount (CLIENT_NAME,SLNO)
	CREATE TABLE #tempusercount
	(
		SLNO int,
		[Month] varchar(50),
		[FSM Customer Name] nvarchar(500),
		[Active User(s)] bigint,
		[Inactive User(s)] bigint,
		[Attendance Count] bigint,
		[Order Count] BIGINT,
		[Churn Probability (Based on Last 3 months Attendance data)] nvarchar(100),
		[Growth in Business on Order basis (Based on Last 3 months Order data)] NVARCHAR(100)
	)
	create nonclustered index idx on #tempusercount ([FSM Customer Name],SLNO)

	declare @DB_NAME varchar(MAX),@sqlStrTable NVARCHAR(MAX),@CLIENT_NAME NVARCHAR(500),@html nvarchar(MAX)
	DECLARE UOMMAIN_CURSOR CURSOR  
	LOCAL  FORWARD_ONLY  FOR  

	select DB1,CLIENT_NAME from BREEZE_CLIENT_DETAILS where TYPE_OF_PRODUCT in ('FSM','Attendance System - FSM') 
			AND DB1 IS NOT NULL AND DB1 NOT IN ('DB1','ROCHAKFOOD','HomatticLife', 'DRYFTDYNAMICS') --and DB1='Lavos' --AND DB1 ='DugarOverseas' -- DB1='EUROBOND'  --'BreezeERP on Cloud, AMC',
	OPEN UOMMAIN_CURSOR  
	FETCH NEXT FROM UOMMAIN_CURSOR INTO  @DB_NAME,@CLIENT_NAME
	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		DECLARE @tab char(1) = CHAR(9), @Emailid nvarchar(max), @sqlQry nvarchar(max), @StartMonthNo int, @EndMonthNo int, @ASONDATE DATETIME, 
		@MonthName varchar(50), @Month varchar(10), @Year varchar(10), @DATE VARCHAR(10), @NoofDaysInMonth bigint, @slno int,
		@myDayRequired varchar(10), @NoOfSundays int, @AuditExists INT=0


		SET @sqlStrTable=' USE ['+@DB_NAME+']; SELECT @AuditExists=count(*) FROM sys.objects WHERE object_id=OBJECT_ID(N''Tbl_Master_User_Audit'') AND TYPE IN (N''U'') ; USE MASTER; '
		exec sp_executesql @sqlStrTable, N'@AuditExists int OUTPUT ', @AuditExists=@AuditExists OUTPUT
		
	
		IF @AuditExists=0
		BEGIN
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #master_user SELECT USR.user_id, USR.user_contactId, USR.Custom_Configuration, USR.isComplementaryUser, USR.user_inactive, USR.LastModifyDate  FROM ['+@DB_NAME+'].[dbo].[tbl_master_employee] EMP '
			SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_user] USR ON USR.user_contactId=EMP.emp_contactId AND ISNULL(USR.Custom_Configuration,0)=0 and USR.isComplementaryUser=0 '--USR.user_name!=''ADMIN''  '
			SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_address] ADDR ON ADDR.add_cntId=EMP.emp_contactId AND ADDR.add_addressType=''Office'' '
			SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_state] ST ON ST.id=ADDR.add_state '
			EXEC SP_EXECUTESQL @sqlStrTable
		END
		ELSE
		BEGIN
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #master_user SELECT USR.user_id, USR.user_contactId, USR.Custom_Configuration, USR.isComplementaryUser, '
			SET @sqlStrTable+=' (CASE WHEN UA.user_inactive IS NULL THEN USR.user_inactive ELSE UA.user_inactive END ) AS USER_INACTIVE, UA.LastModifyDate  '
			SET @sqlStrTable+='FROM ['+@DB_NAME+'].[dbo].[tbl_master_employee] EMP '
			SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_user] USR ON USR.user_contactId=EMP.emp_contactId AND ISNULL(USR.Custom_Configuration,0)=0 and USR.isComplementaryUser=0 '--USR.user_name!=''ADMIN''  '
			SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_address] ADDR ON ADDR.add_cntId=EMP.emp_contactId AND ADDR.add_addressType=''Office'' '
			SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_state] ST ON ST.id=ADDR.add_state '
			SET @sqlStrTable+='LEFT OUTER JOIN (SELECT user_inactive, USER_ID, LastModifyDate FROM ['+@DB_NAME+'].[dbo].Tbl_Master_User_Audit ) UA ON UA.USER_ID=USR.USER_ID '
			--SELECT @sqlStrTable
			EXEC SP_EXECUTESQL @sqlStrTable

		END;

		WITH CTE([user_id], [user_contactid], [Custom_Configuration], [isComplementaryUser],[user_inactive],[LastModifyDate], duplicatecount)
		AS (SELECT [user_id], [user_contactid], [Custom_Configuration], [isComplementaryUser],[user_inactive],[LastModifyDate], 
			ROW_NUMBER() OVER(PARTITION BY [user_id], month([LastModifyDate]) ORDER BY [user_id],[LastModifyDate] ) AS DuplicateCount
			FROM #master_user --where user_id=11994
			)
		DELETE FROM CTE WHERE DuplicateCount>1 ;

	
	-----SELECT * from  #master_user;



		SET @StartMonthNo = 6
		SET @EndMonthNo = 0
		SET @slno = 7
		
		WHILE (@StartMonthNo >= @EndMonthNo)
		BEGIN
			SET @ASONDATE = DATEADD(MONTH, -@StartMonthNo, CURRENT_TIMESTAMP);
			SET @Month = FORMAT(MONTH(@ASONDATE),'00')
			SET @Year = YEAR(@ASONDATE)
			SET @DATE = @Year+'-'+@Month+'-01'
			SET @MonthName = DATENAME(MONTH,@DATE)
			
			--SET @NoofDaysInMonth = (select COUNT( DISTINCT(CONVERT(DATE,Login_datetime))) from EUROBOND..tbl_fts_UserAttendanceLoginlogout WHERE 
			--						MONTH(CONVERT(DATE,Login_datetime))=@Month AND YEAR(CONVERT(DATE,Login_datetime))=@Year)
			--						+
			--						(select COUNT( DISTINCT(CONVERT(DATE,Login_datetime))) from EUROBOND..tbl_fts_UserAttendanceLoginlogout_ARCH WHERE 
			--						MONTH(CONVERT(DATE,Login_datetime))=@Month AND YEAR(CONVERT(DATE,Login_datetime))=@Year
			--						)
			set @NoofDaysInMonth = 1  -- division by no of days in the month not needed.
			-- end

			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #tempusercount_raw '
			SET @sqlStrTable+=' SELECT SLNO, Month_Name, CLIENT_NAME, ISNULL(Activ_User_Count,0) Activ_User_Count, ISNULL(Inactiv_User_Count,0) Inactiv_User_Count, ISNULL(SUM(Attendance_Count),0), ISNULL(ORDER_COUNT,0) ORDER_COUNT FROM ( '
			SET @sqlStrTable+=' SELECT '+cast(@slno as varchar(10))+' SLNO ,'''+@MonthName+' '+@Year+''' Month_Name, '''+@CLIENT_NAME+''' CLIENT_NAME, '
			IF @AuditExists=1
			BEGIN
				SET @sqlStrTable+=' ( (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''N'' AND LastModifyDate IS NULL) + (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''N'' AND MONTH(LastModifyDate)='+@Month+') ) AS Activ_User_Count, '
				SET @sqlStrTable+=' ( (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''Y''  AND LastModifyDate IS NULL) + (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''Y''  AND MONTH(LastModifyDate)='+@Month+') ) AS Inactiv_User_count, '
			END
			ELSE
			BEGIN
				SET @sqlStrTable+=' (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''N'' ) AS Activ_User_Count, '
				SET @sqlStrTable+=' (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''Y'' ) AS Inactiv_User_count, '
			END
			SET @sqlStrTable+=' (SELECT COUNT(MONTH(CONVERT(DATE,ATTN.Login_datetime)))/'+CAST(@NoofDaysInMonth AS VARCHAR(10)) +'   FROM ['+@DB_NAME+'].[dbo].tbl_fts_UserAttendanceLoginlogout ATTN '
			SET @sqlStrTable+=' WHERE ATTN.Login_datetime IS NOT NULL AND MONTH(CONVERT(DATE,ATTN.Login_datetime))='+CAST(@Month AS VARCHAR(10))+' AND YEAR(CONVERT(DATE,ATTN.Login_datetime))='''+@Year+'''  '
			SET @sqlStrTable+=' GROUP BY MONTH(CONVERT(DATE,ATTN.Login_datetime)) ) Attendance_Count , '
			SET @sqlStrTable+='(SELECT SUM(ORD_CNT)  FROM ( '
			SET @sqlStrTable+='SELECT COUNT(0) ORD_CNT FROM ['+@DB_NAME+'].[dbo].tbl_trans_fts_Orderupdate where MONTH(CONVERT(DATE,ORDERDATE))='+CAST(@Month AS VARCHAR(10))+' AND YEAR(CONVERT(DATE,ORDERDATE))='''+@Year+'''  '
			SET @sqlStrTable+=' UNION '
			SET @sqlStrTable+='SELECT COUNT(0) ORD_CNT FROM ['+@DB_NAME+'].[dbo].ORDERPRODUCTATTRIBUTE where MONTH(CONVERT(DATE,ORDER_DATE))='+CAST(@Month AS VARCHAR(10))+' AND YEAR(CONVERT(DATE,ORDER_DATE))='''+@Year+'''  '
			SET @sqlStrTable+=' ) OC ) ORDER_COUNT'

			SET @sqlStrTable+=' UNION ALL '
			SET @sqlStrTable+=' SELECT '+cast(@slno as varchar(10))+' SLNO,'''+@MonthName+' '+@Year+''' Month_Name, '''+@CLIENT_NAME+''' CLIENT_NAME, '
			IF @AuditExists=1
			BEGIN
				SET @sqlStrTable+=' ( (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''N'' AND LastModifyDate IS NULL) + (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''N'' AND MONTH(LastModifyDate)='+@Month+') ) AS Activ_User_Count, '
				SET @sqlStrTable+=' ( (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''Y''  AND LastModifyDate IS NULL) + (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''Y''  AND MONTH(LastModifyDate)='+@Month+') ) AS Inactiv_User_count, '
			END
			ELSE
			BEGIN
				SET @sqlStrTable+=' (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''N'' ) AS Activ_User_Count, '
				SET @sqlStrTable+=' (SELECT COUNT(0) FROM #master_user WHERE user_inactive=''Y'' ) AS Inactiv_User_count, '
			END
			SET @sqlStrTable+=' (SELECT COUNT(MONTH(CONVERT(DATE,ATTN.Login_datetime)))/'+CAST(@NoofDaysInMonth AS VARCHAR(10)) +'   FROM ['+@DB_NAME+'].[dbo].tbl_fts_UserAttendanceLoginlogout_ARCH ATTN '
			SET @sqlStrTable+=' WHERE ATTN.Login_datetime IS NOT NULL AND MONTH(CONVERT(DATE,ATTN.Login_datetime))='+CAST(@Month AS VARCHAR(10))+' AND YEAR(CONVERT(DATE,ATTN.Login_datetime))='''+@Year+'''  '
			SET @sqlStrTable+=' GROUP BY MONTH(CONVERT(DATE,ATTN.Login_datetime)) ) Attendance_Count , '
			--SET @sqlStrTable+=' (SELECT COUNT(0) FROM ['+@DB_NAME+'].[dbo].tbl_trans_fts_Orderupdate where MONTH(CONVERT(DATE,ORDERDATE))='+CAST(@Month AS VARCHAR(10))+' AND YEAR(CONVERT(DATE,ORDERDATE))='''+@Year+''') ORDER_COUNT '
			SET @sqlStrTable+='(SELECT SUM(ORD_CNT)  FROM ( '
			SET @sqlStrTable+='SELECT COUNT(0) ORD_CNT FROM ['+@DB_NAME+'].[dbo].tbl_trans_fts_Orderupdate where MONTH(CONVERT(DATE,ORDERDATE))='+CAST(@Month AS VARCHAR(10))+' AND YEAR(CONVERT(DATE,ORDERDATE))='''+@Year+'''  '
			SET @sqlStrTable+=' UNION '
			SET @sqlStrTable+='SELECT COUNT(0) ORD_CNT FROM ['+@DB_NAME+'].[dbo].ORDERPRODUCTATTRIBUTE where MONTH(CONVERT(DATE,ORDER_DATE))='+CAST(@Month AS VARCHAR(10))+' AND YEAR(CONVERT(DATE,ORDER_DATE))='''+@Year+'''  '
			
			SET @sqlStrTable+=' ) OC ) ORDER_COUNT'
			
			SET @sqlStrTable+=' ) A GROUP BY SLNO, Month_Name, CLIENT_NAME, Activ_User_Count,	Inactiv_User_Count,	ORDER_COUNT '
			
			--SELECT @sqlStrTable
			
			EXEC SP_EXECUTESQL @sqlStrTable

			set @slno = @slno - 1
			set @StartMonthNo = @StartMonthNo - 1
		END

		DELETE FROM #master_user

	FETCH NEXT FROM UOMMAIN_CURSOR INTO  @DB_NAME,@CLIENT_NAME
	END  
	CLOSE UOMMAIN_CURSOR  
	DEALLOCATE UOMMAIN_CURSOR  


	--select * from #tempusercount_raw

	INSERT INTO #tempusercount
	SELECT SLNO, Month_Name, CLIENT_NAME, Activ_User_Count, Inactiv_User_Count, Attendance_Count, ORDER_COUNT, CHURN_PROBABLITY, BUSUNESS_GROWTH
	FROM (
		SELECT cnt1.SLNO,cnt1.Month_Name , cnt1.CLIENT_NAME , cnt1.Activ_User_Count , cnt1.Inactiv_User_Count , cnt1.Attendance_Count ,cnt1.ORDER_COUNT,
		(CASE WHEN CHURN.AVG_Attendance_Count>0 and Attendance_Count>0 THEN (CASE WHEN Attendance_Count<CHURN.AVG_Attendance_Count AND Attendance_Count<PRV_MONTH_Attendance_Count THEN 'Risk % is: '+cast(cast( ((cast((AVG_Attendance_Count-Attendance_Count) as float)/cast( Attendance_Count as float)) *100) as decimal(12,2)) as varchar(50)) ELSE 'No churn probability detected.' END ) ELSE 'No Attendance Data found.' END) AS CHURN_PROBABLITY ,
		(CASE WHEN BG.AVG_ORDER_COUNT>0 THEN (CASE WHEN cnt1.ORDER_COUNT<BG.AVG_ORDER_COUNT THEN 'Growth is < '+cast(cast( ((cast(cnt1.ORDER_COUNT as float)/cast( BG.AVG_ORDER_COUNT as float)) *100) as decimal(12,2)) as varchar(50))+'% from last 3 months Order Count' else 'Growth is > '+cast(cast( ((cast(cnt1.ORDER_COUNT as float)/cast( BG.AVG_ORDER_COUNT as float)) *100) as decimal(12,2)) as varchar(50))+'% from last 3 months Order Count' end ) ELSE 'No orders found' END ) AS BUSUNESS_GROWTH
		FROM #tempusercount_raw cnt1 
		left outer join (select CLIENT_NAME,sum(Attendance_Count)/3 AVG_Attendance_Count from #tempusercount_raw where SLNO IN (3,4,5) group by CLIENT_NAME ) CHURN ON CNT1.CLIENT_NAME=CHURN.CLIENT_NAME
		left outer join (select CLIENT_NAME,sum(Attendance_Count) PRV_MONTH_Attendance_Count from #tempusercount_raw where SLNO IN (3) group by CLIENT_NAME ) CHURN_PRV ON CNT1.CLIENT_NAME=CHURN_PRV.CLIENT_NAME
		left outer join (select CLIENT_NAME, SUM(ORDER_COUNT)/3 AVG_ORDER_COUNT from #tempusercount_raw where SLNO IN (3,4,5) group by CLIENT_NAME ) BG ON CNT1.CLIENT_NAME=BG.CLIENT_NAME
		where cnt1.SLNO=2
		UNION
		SELECT cnt1.SLNO,cnt1.Month_Name , cnt1.CLIENT_NAME , cnt1.Activ_User_Count , cnt1.Inactiv_User_Count , cnt1.Attendance_Count ,cnt1.ORDER_COUNT,
		(CASE WHEN CHURN.AVG_Attendance_Count>0 and Attendance_Count>0 THEN (CASE WHEN Attendance_Count<CHURN.AVG_Attendance_Count AND Attendance_Count<PRV_MONTH_Attendance_Count THEN 'Risk % is: '+cast(cast( ((cast((AVG_Attendance_Count-Attendance_Count) as float)/cast( Attendance_Count as float)) *100) as decimal(12,2)) as varchar(50)) ELSE 'No churn probability detected.' END ) ELSE 'No Attendance Data found.' END) AS CHURN_PROBABLITY ,
		(CASE WHEN BG.AVG_ORDER_COUNT>0 THEN (CASE WHEN cnt1.ORDER_COUNT<BG.AVG_ORDER_COUNT THEN 'Growth is < '+cast(cast( ((cast(cnt1.ORDER_COUNT as float)/cast( BG.AVG_ORDER_COUNT as float)) *100) as decimal(12,2)) as varchar(50))+'% from last 3 months Order Count' else 'Growth is > '+cast(cast( ((cast(cnt1.ORDER_COUNT as float)/cast( BG.AVG_ORDER_COUNT as float)) *100) as decimal(12,2)) as varchar(50))+'% from last 3 months Order Count' end ) ELSE 'No orders found' END ) AS BUSUNESS_GROWTH
		FROM #tempusercount_raw cnt1 
		left outer join (select CLIENT_NAME,sum(Attendance_Count)/3 AVG_Attendance_Count from #tempusercount_raw where SLNO IN (4,5,6) group by CLIENT_NAME ) CHURN ON CNT1.CLIENT_NAME=CHURN.CLIENT_NAME
		left outer join (select CLIENT_NAME,sum(Attendance_Count) PRV_MONTH_Attendance_Count from #tempusercount_raw where SLNO IN (4) group by CLIENT_NAME ) CHURN_PRV ON CNT1.CLIENT_NAME=CHURN_PRV.CLIENT_NAME
		left outer join (select CLIENT_NAME, SUM(ORDER_COUNT)/3 AVG_ORDER_COUNT from #tempusercount_raw where SLNO IN (4,5,6) group by CLIENT_NAME ) BG ON CNT1.CLIENT_NAME=BG.CLIENT_NAME
		where cnt1.SLNO=3
		UNION
		SELECT cnt1.SLNO,cnt1.Month_Name , cnt1.CLIENT_NAME , cnt1.Activ_User_Count , cnt1.Inactiv_User_Count , cnt1.Attendance_Count ,cnt1.ORDER_COUNT,
		(CASE WHEN CHURN.AVG_Attendance_Count>0 and Attendance_Count>0 THEN (CASE WHEN Attendance_Count<CHURN.AVG_Attendance_Count AND Attendance_Count<PRV_MONTH_Attendance_Count THEN 'Risk % is: '+cast(cast( ((cast((AVG_Attendance_Count-Attendance_Count) as float)/cast( Attendance_Count as float)) *100) as decimal(12,2)) as varchar(50)) ELSE 'No churn probability detected.' END ) ELSE 'No Attendance Data found.' END) AS CHURN_PROBABLITY ,
		(CASE WHEN BG.AVG_ORDER_COUNT>0 THEN (CASE WHEN cnt1.ORDER_COUNT<BG.AVG_ORDER_COUNT THEN 'Growth is < '+cast(cast( ((cast(cnt1.ORDER_COUNT as float)/cast( BG.AVG_ORDER_COUNT as float)) *100) as decimal(12,2)) as varchar(50))+'% from last 3 months Order Count' else 'Growth is > '+cast(cast( ((cast(cnt1.ORDER_COUNT as float)/cast( BG.AVG_ORDER_COUNT as float)) *100) as decimal(12,2)) as varchar(50))+'% from last 3 months Order Count' end ) ELSE 'No orders found' END ) AS BUSUNESS_GROWTH
		FROM #tempusercount_raw cnt1 
		left outer join (select CLIENT_NAME,sum(Attendance_Count)/3 AVG_Attendance_Count from #tempusercount_raw where SLNO IN (5,6,7) group by CLIENT_NAME ) CHURN ON CNT1.CLIENT_NAME=CHURN.CLIENT_NAME
		left outer join (select CLIENT_NAME,sum(Attendance_Count) PRV_MONTH_Attendance_Count from #tempusercount_raw where SLNO IN (5) group by CLIENT_NAME ) CHURN_PRV ON CNT1.CLIENT_NAME=CHURN_PRV.CLIENT_NAME
		left outer join (select CLIENT_NAME, SUM(ORDER_COUNT)/3 AVG_ORDER_COUNT from #tempusercount_raw where SLNO IN (5,6,7) group by CLIENT_NAME ) BG ON CNT1.CLIENT_NAME=BG.CLIENT_NAME
		where cnt1.SLNO=4
		UNION
		SELECT cnt1.SLNO,cnt1.Month_Name , cnt1.CLIENT_NAME , cnt1.Activ_User_Count , cnt1.Inactiv_User_Count , cnt1.Attendance_Count ,cnt1.ORDER_COUNT,
		(CASE WHEN CHURN.AVG_Attendance_Count>0 THEN (CASE WHEN Attendance_Count<CHURN.AVG_Attendance_Count AND Attendance_Count<PRV_MONTH_Attendance_Count THEN 'HIGH_RISK' ELSE 'No churn probability detected.' END ) ELSE '' END) AS CHURN_PROBABLITY ,
		(CASE WHEN BG.AVG_ORDER_COUNT>0 THEN (CASE WHEN cnt1.ORDER_COUNT<BG.AVG_ORDER_COUNT THEN 'Growth is < '+cast(cast( ((cast(cnt1.ORDER_COUNT as float)/cast( BG.AVG_ORDER_COUNT as float)) *100) as decimal(12,2)) as varchar(50))+'% from last 3 months Order Count' else 'Growth is > '+cast(cast( ((cast(cnt1.ORDER_COUNT as float)/cast( BG.AVG_ORDER_COUNT as float)) *100) as decimal(12,2)) as varchar(50))+'% from last 3 months Order Count' end ) ELSE '' END ) AS BUSUNESS_GROWTH
		FROM #tempusercount_raw cnt1 
		left outer join (select CLIENT_NAME,sum(Attendance_Count)/3 AVG_Attendance_Count from #tempusercount_raw where SLNO IN (5,6,7) group by CLIENT_NAME ) CHURN ON CNT1.CLIENT_NAME=CHURN.CLIENT_NAME
		left outer join (select CLIENT_NAME,sum(Attendance_Count) PRV_MONTH_Attendance_Count from #tempusercount_raw where SLNO IN (6) group by CLIENT_NAME ) CHURN_PRV ON CNT1.CLIENT_NAME=CHURN_PRV.CLIENT_NAME
		left outer join (select CLIENT_NAME, SUM(ORDER_COUNT)/3 AVG_ORDER_COUNT from #tempusercount_raw where  SLNO IN (5,6,7) group by CLIENT_NAME ) BG ON CNT1.CLIENT_NAME=BG.CLIENT_NAME
		where cnt1.SLNO=5 -- to show last 3 months data
	) A
	order by CLIENT_NAME, SLNO DESC

	--SELECT * FROM #tempusercount

	DELETE FROM #tempusercount WHERE SLNO=5


	DROP INDEX idx ON #tempusercount
	alter table #tempusercount drop column SLNO

	--SELECT * FROM #tempusercount 
	
	-- send email ---
	EXEC spQueryToHtmlTable @html = @html OUTPUT, @query = N'SELECT *  FROM #tempusercount  '

	EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'BreezeERP',  
			@body = @html,
			@body_format = 'HTML',
			@subject = 'FSM Client Churn Probability Forecasting',
			@recipients = 'pijushk.bhattacharya@indusnet.co.in; sneha.das@indusnet.co.in; priyanka@indusnet.co.in; goutamk.das@indusnet.co.in; sanchita.saha@indusnet.co.in'
			--@recipients = 'pijushk.bhattacharya@indusnet.co.in; sanchita.saha@indusnet.co.in'
			--@recipients = 'sanchita.saha@indusnet.co.in'
			--@recipients = 'pijushk.bhattacharya@indusnet.co.in ; suman.roy@indusnet.co.in ; sanchita.saha@indusnet.co.in'
	-- end send email ---
		
	DROP TABLE #tempusercount
	DROP TABLE #master_user	
	DROP TABLE #tempusercount_raw

END
GO