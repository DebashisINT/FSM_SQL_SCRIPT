IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSHORIZONTALATTENDANCE_FETCH]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSHORIZONTALATTENDANCE_FETCH] AS' 
END
GO

--EXEC PRC_FTSHORIZONTALATTENDANCE_FETCH @FROM_DATE='2021-06-10',@EMPID='EMA0000009',@SelfieURL='http://3.7.30.86:82//Commonfolder/AttendanceImageDemo/'
ALTER PROCEDURE [dbo].[PRC_FTSHORIZONTALATTENDANCE_FETCH]
(
@FROM_DATE NVARCHAR(10)=NULL,
@TO_DATE NVARCHAR(10)=NULL,
@EMPID NVARCHAR(MAX) =NULL,
@Emp_code NVARCHAR(100)=NULL,
@SelfieURL NVARCHAR(MAX)=NULL,
@Userid bigint=null
--Rev work 2.0
,@ShowFullday INT=NULL,
@ISONLYLOGINDATA INT=NULL,
@ISONLYLOGOUTDATA INT=NULL
--End of rev work 2.0
-- Rev 4.0
,@BRANCHID NVARCHAR(MAX)=NULL
-- End of Rev 4.0
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0					Tanmoy		26-11-2020		CREATE PROCEDURE
2.0		v2.0.32			Swatilekha  16.08.2022	Attendance register report enhancement required refer:0025111
3.0		v2.0.37		Sanchita	16-11-2022		Attendance Register Report- Multiple rows generating against a singular User ID if the user logs out multiple times.
												Also the distance travelled is showing zero though the total distance travelled showing data.
												Refer: 25444
4.0		V2.0.41		Sanchita	19/07/2023		Add Branch parameter in MIS -> Performance Summary report. Refer: 26135
****************************************************************************************************************************************************************************/
BEGIN
	DECLARE @sqlStrTable NVARCHAR(MAX)
	DECLARE @sqlStr NVARCHAR(MAX)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END


		--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Userid)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@Userid)		
			CREATE TABLE #EMPHRS
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
		
			INSERT INTO #EMPHRS
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHRS 
			where EMPCODE IS NULL OR EMPCODE=@empcodes  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHRS a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 

		END
	--End of Rev 3.0



	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Userid)=1)
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT
			INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
			WHERE cnt_contactType IN('EM')
		END
		ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
		END
	DECLARE @IMAGE NVARCHAR(MAX)=''

	--SET @IMAGE=(SELECT * FROM  FTS_AttendanceImage IMG
	--			INNER JOIN TBL_MASTER_USER WHERE ATTEN.User_Id=IMG.USER_ID AND CAST(ATTEN.Work_datetime AS DATE)=cast(IMG.Attendance_DATE as date))

	--Rev work 2.0
	IF @ShowFullday=1
	  BEGIN
		IF OBJECT_ID('tempdb..#TEMPCTCCONTACT') IS NOT NULL		
			DROP TABLE #TEMPCTCCONTACT
			CREATE TABLE #TEMPCTCCONTACT
			(
				cnt_internalId NVARCHAR(10) NULL,
				emp_workinghours int NULL,
				FullDayWorkingHour NVARCHAR(50) NULL,
				HalfDayWorkingHour NVARCHAR(50) NULL			
			)
		INSERT INTO #TEMPCTCCONTACT(cnt_internalId,emp_workinghours,FullDayWorkingHour,HalfDayWorkingHour)
		Select ctc.emp_cntId,ctc.emp_workinghours,Convert(varchar(8), ewod.FullDayWorkingHour, 108) as FullDayWorkingHour,Convert(varchar(8), ewod.HalfDayWorkingHour, 108) as HalfDayWorkingHour
		From TBL_EMPWORKINGHOURS wo
		INNER JOIN TBL_EMPWORKINGHOURSDETAILS ewod ON  wo.Id=ewod.hourId
		INNER JOIN TBL_TRANS_EMPLOYEECTC ctc ON wo.Id=ctc.emp_workinghours
	 END
	--End of Rev work 2.0
	-- Rev 4.0
	IF OBJECT_ID('tempdb..#BRANCH_LIST') IS NOT NULL
		DROP TABLE #BRANCH_LIST
	CREATE TABLE #BRANCH_LIST (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #BRANCH_LIST (Branch_Id ASC)

	IF @BRANCHID<>''
		BEGIN
			SET @sqlStrTable=''
			SET @BRANCHID=REPLACE(@BRANCHID,'''','')
			SET @sqlStrTable='INSERT INTO #BRANCH_LIST SELECT branch_id FROM tbl_master_branch WHERE branch_id IN ('+@BRANCHID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	-- End of Rev 4.0
	-- Rev 3.0
	If @ISONLYLOGINDATA=1 or @ISONLYLOGOUTDATA=1
	begin
			IF OBJECT_ID('tempdb..#TMPLOGINOUTLOC') IS NOT NULL		
				DROP TABLE #TMPLOGINOUTLOC

			CREATE TABLE #TMPLOGINOUTLOC(USERID BIGINT,SDATE NVARCHAR(10),LOGINLOATION NVARCHAR(MAX),LOGOUTLOATION NVARCHAR(MAX))
			
			SET @sqlStr=''
			SET @sqlStr+=' INSERT INTO #TMPLOGINOUTLOC(USERID,SDATE,LOGINLOATION,LOGOUTLOATION) '
			SET @sqlStr+=' SELECT User_Id,SDate,'''' AS LOGINLOATION,'''' AS LOGOUTLOATION FROM( '
			SET @sqlStr+=' SELECT User_Id,cast(SDate as date) as SDate,LoginLogout '
			SET @sqlStr+=' FROM tbl_trans_shopuser  '
			SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),tbl_trans_shopuser.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120)  '
			SET @sqlStr+=' AND LoginLogout IN(0,1) '
			SET @sqlStr+=' UNION ALL '
			SET @sqlStr+=' SELECT User_Id,cast(SDate as date) as SDate,LoginLogout   '
			SET @sqlStr+=' FROM TBL_TRANS_SHOPUSER_ARCH '
			SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),TBL_TRANS_SHOPUSER_ARCH.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
			SET @sqlStr+=' AND LoginLogout IN(0,1) '
			SET @sqlStr+=' ) AA GROUP BY User_Id,SDate '
			EXEC SP_EXECUTESQL @sqlStr

			If @ISONLYLOGINDATA=1
			BEGIN
				IF OBJECT_ID('tempdb..#TMPLOGINLOC') IS NOT NULL	
					DROP TABLE #TMPLOGINLOC

				CREATE TABLE #TMPLOGINLOC(USERID BIGINT,SDATE NVARCHAR(10),LOGINLOATION NVARCHAR(MAX))

				SET @sqlStr=''
				SET @sqlStr+=' INSERT INTO #TMPLOGINLOC(USERID,SDATE,LOGINLOATION) '
				SET @sqlStr+=' SELECT User_Id,SDate,LOGINLOATION  FROM  (  '
				SET @sqlStr+=' SELECT User_Id,cast(SDate as date) as SDate,location_name AS LOGINLOATION '
				SET @sqlStr+=' FROM tbl_trans_shopuser  '
				SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),tbl_trans_shopuser.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120)  '
				SET @sqlStr+=' AND LoginLogout =1 '
				SET @sqlStr+=' UNION ALL  '
				SET @sqlStr+=' SELECT User_Id,cast(SDate as date) as SDate,location_name AS LOGINLOATION '
				SET @sqlStr+=' FROM TBL_TRANS_SHOPUSER_ARCH  '
				SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),TBL_TRANS_SHOPUSER_ARCH.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
				SET @sqlStr+=' AND LoginLogout =1 '
				SET @sqlStr+=' ) BB ORDER BY User_Id '
				EXEC SP_EXECUTESQL @sqlStr

				UPDATE A SET A.LOGINLOATION=B.LOGINLOATION
				FROM #TMPLOGINOUTLOC A
				INNER JOIN #TMPLOGINLOC B ON A.USERID=B.USERID AND A.SDate=B.SDate

			END

			IF @ISONLYLOGOUTDATA=1
			BEGIN
				IF OBJECT_ID('tempdb..#TMPLOGOUTLOC') IS NOT NULL
					DROP TABLE #TMPLOGOUTLOC

				CREATE TABLE #TMPLOGOUTLOC(USERID BIGINT,SDATE NVARCHAR(10),LOGOUTLOATION NVARCHAR(MAX)) 

				SET @sqlStr=''
				SET @sqlStr+=' INSERT INTO #TMPLOGOUTLOC(USERID,SDATE,LOGOUTLOATION) '
				SET @sqlStr+=' SELECT User_Id,SDate,LOGOUTLOATION  FROM  (  '
				SET @sqlStr+=' SELECT User_Id,cast(SDate as date) as SDate,location_name AS LOGOUTLOATION '
				SET @sqlStr+=' FROM tbl_trans_shopuser  '
				SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),tbl_trans_shopuser.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
				SET @sqlStr+=' AND LoginLogout =0 '
				SET @sqlStr+=' UNION ALL '
				SET @sqlStr+=' SELECT User_Id,cast(SDate as date) as SDate,location_name AS LOGOUTLOATION '
				SET @sqlStr+=' FROM TBL_TRANS_SHOPUSER_ARCH  '
				SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),TBL_TRANS_SHOPUSER_ARCH.SDate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
				SET @sqlStr+=' AND LoginLogout =0 '
				SET @sqlStr+=' ) BB ORDER BY User_Id '
				EXEC SP_EXECUTESQL @sqlStr

				UPDATE A SET A.LOGOUTLOATION=B.LOGOUTLOATION
				FROM #TMPLOGINOUTLOC A
				INNER JOIN #TMPLOGOUTLOC B ON A.USERID=B.USERID AND A.SDate=B.SDate
			END

	end
	-- End of Rev 3.0

	SET @sqlStr=''
	SET @sqlStr+=' SELECT EmpCode,EMP_NAME,LoginID,Department,user_id,LOGGEDIN,LOGEDOUT,ATTEN_STATUS , '
	SET @sqlStr+=' RIGHT(''0'' + CAST(CAST(duration AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(duration AS VARCHAR) % 60 AS VARCHAR),2) AS duration_HR,duration AS duration_MIN '
	SET @sqlStr+=' ,cnt_internalId '
	SET @sqlStr+=' ,distance_covered,IDEAL_TIME,Ordervalue, '


	--SET @Strsql+=' +''&nbsp;&nbsp;&nbsp;&nbsp;<span  class="actionInput" onclick="AddAttachmentMoneyReceipt( ''+CONVERT(NVARCHAR(10),rcpt.MoneyReceipt_ID)+'',''''''+rcpt.DocumentNumber+'''''')"><i class="fa fa-paperclip" data-toggle="tooltip" data-placement="left" title="Attachment"></i></span>'' '

	SET @sqlStr+=' CASE WHEN ISNULL(IMAGE_NAME,'''')<>'''' THEN ''<a class="example-image-link" href=''''''+IMAGE_NAME+'''''' data-lightbox="example-1"><img src=''''''+IMAGE_NAME+'''''' data-lightbox=''''''+IMAGE_NAME+'''''' alt="No Image Found" height="42" width="42"></a>'' ELSE '''' END AS IMAGE_NAME '
	--Rev work 2.0
	If @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,loginloation '
	 End
	If @ISONLYLOGOUTDATA=1
	 Begin
	   SET @sqlStr+=' ,logoutloation '
	 End
	IF @ShowFullday=1
	 Begin	
		SET @sqlStr+=' ,(case when duration>=T.FullDayWorkingHour then 1 else 0 end) AS FullDay '	
	 End
	--End of Rev work 2.0
	-- Rev 4.0
	 SET @sqlStr+=' ,Branch '
	-- End of Rev 4.0

	SET @sqlStr+=' FROM ( '
	SET @sqlStr+=' SELECT CNT.cnt_UCC AS EmpCode, '
	SET @sqlStr+=' ISNULL(CNT.cnt_firstName,'''')+'' ''+CASE WHEN ISNULL(CNT.cnt_middleName,'''')='''' THEN '''' ELSE ISNULL(CNT.cnt_middleName,'''')+'' '' END +ISNULL(CNT.cnt_lastName,'''') AS EMP_NAME '
	SET @sqlStr+=' ,usr.user_loginId AS LoginID,cost_description AS Department,USR.user_id '
	SET @sqlStr+=' ,RIGHT(CONVERT(VARCHAR, CAST(LOGGEDIN AS DATETIME), 100),7) AS LOGGEDIN,RIGHT(CONVERT(VARCHAR, CAST(LOGEDOUT AS DATETIME), 100),7) AS LOGEDOUT, '
				   
	SET @sqlStr+=' CASE WHEN ISNULL(LOGGEDIN,'''')<>'''' THEN  ATTEN_STATUS ELSE '
	SET @sqlStr+=' CASE WHEN (SELECT FORMAT(CAST('''+@FROM_DATE+''' AS DATE), ''dddd''))=''Sunday'' THEN ''Weekly Off'' ELSE ''Not Logged In'' END END AS ATTEN_STATUS, '
	SET @sqlStr+=' CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGEDOUT,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) '
	SET @sqlStr+=' - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(ATTEN.LOGGEDIN,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS duration '
	SET @sqlStr+=' ,CNT.cnt_internalId '

	SET @sqlStr+=' ,distance_covered,IDEAL_TIME,Ordervalue,CASE WHEN ISNULL(IMAGE_NAME,'''')<>'''' THEN '''+@SelfieURL+'''+ISNULL(IMAGE_NAME,'''') ELSE '''' END as IMAGE_NAME '
	--Rev work 2.0
	If @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,ATTEN.loginloation '
	 End
	If @ISONLYLOGOUTDATA=1
	 Begin
	 	SET @sqlStr+=' ,ATTEN.logoutloation '
	 End
	IF @ShowFullday=1
	 Begin
		SET @sqlStr+=' ,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(CTCEMP.FullDayWorkingHour,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(CTCEMP.FullDayWorkingHour,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) As FullDayWorkingHour  '
		SET @sqlStr+=' ,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(CTCEMP.HalfDayWorkingHour,''00:00:00'')) * 60) AS FLOAT) +CAST(DATEPART(MINUTE,ISNULL(CTCEMP.HalfDayWorkingHour,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS HalfDayWorkingHour '
	 End
	--End of Rev work 2.0
	-- Rev 4.0
	SET @sqlStr+=' , BR.branch_description as Branch '
	-- End of Rev 4.0

	SET @sqlStr+='  FROM tbl_master_user USR '
	SET @sqlStr+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @sqlStr+=' INNER JOIN TBL_TRANS_EMPLOYEECTC CTC ON CTC.emp_cntId=CNT.cnt_internalId '
	SET @sqlStr+=' LEFT OUTER JOIN tbl_master_costCenter DEPT ON CTC.emp_Department=DEPT.cost_id AND DEPT.cost_costCenterType=''Department'' '
	-- Rev 4.0
	SET @sqlStr+='INNER JOIN tbl_master_branch BR ON CTC.emp_branch=BR.branch_id '
	IF @BRANCHID<>''
		SET @sqlStr+='AND EXISTS (SELECT Branch_Id FROM #Branch_List AS F WHERE F.Branch_Id=BR.BRANCH_ID) '
	-- End of Rev 4.0
	--Rev work 2.0
	IF @ShowFullday=1
	 Begin
	   SET @sqlStr+=' LEFT OUTER JOIN #TEMPCTCCONTACT CTCEMP ON USR.user_contactid=CTCEMP.cnt_internalId '
	 End
	--End of Rev work 2.0
	SET @sqlStr+=' LEFT OUTER JOIN ( '
	SET @sqlStr+=' SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,Login_datetime,ATTEN_STATUS '
	SET @sqlStr+=' ,distance_covered,IDEAL_TIME,Ordervalue,IMAGE_NAME '
	--Rev work 2.0
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,loginloation '
	 End
	 IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,logoutloation '
	 End
	--End of Rev work 2.0
	SET @sqlStr+=' FROM( '
	SET @sqlStr+=' SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT, '
	SET @sqlStr+=' CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime, '
	SET @sqlStr+=' CASE WHEN Isonleave=''false'' THEN ''Present'' ELSE ''Absent'' END AS ATTEN_STATUS '

	SET @sqlStr+=' ,distance_covered, '
	--SET @sqlStr+=' RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR) % 60 AS VARCHAR),2) AS IDEAL_TIME,  '
	SET @sqlStr+=' ISNULL(CONVERT(NVARCHAR(50),cONVERT(DECIMAL(10,0),IDEAL_TIME/(select Value from FTS_APP_CONFIG_SETTINGS WHERE [Key]=''idle_time''))),''0'') AS IDEAL_TIME,  '
	SET @sqlStr+=' Ordervalue,IMAGE_NAME  '
	--Rev work 2.0
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,DISTNC.loginloation '		
	 End
	 IF @ISONLYLOGOUTDATA=1
	 Begin
	 	SET @sqlStr+=' ,DISTNC.logoutloation '
	 End
	--End of Rev work 2.0

	SET @sqlStr+=' FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @sqlStr+=' INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @sqlStr+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '

	SET @sqlStr+=' LEFT OUTER JOIN ( '
	SET @sqlStr+=' SELECT SUM(distance_covered) AS distance_covered,User_Id,SDate '
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,loginloation '
	 End
	 -- Rev 3.0
	 IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,logoutloation '
	 End
	 -- End of Rev 3.0
	SET @sqlStr+=' FROM  ( '
	SET @sqlStr+=' SELECT ISNULL(distance_covered,0) AS distance_covered,User_Id,cast(tbl_trans_shopuser.SDate as date) as SDate '	
	--Rev work 2.0
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+='  ,LINOUT.LOGINLOATION as loginloation '
	 End
	--End of Rev work 2.0
	 -- Rev 3.0
	 IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,LINOUT.LOGOUTLOATION as logoutloation '
	 End
	 -- End of Rev 3.0
	SET @sqlStr+=' FROM tbl_trans_shopuser '
	-- Rev 3.0
	If @ISONLYLOGINDATA=1 or @ISONLYLOGOUTDATA=1
		SET @sqlStr+=' LEFT OUTER JOIN #TMPLOGINOUTLOC LINOUT ON tbl_trans_shopuser.User_Id=LINOUT.USERID AND cast(tbl_trans_shopuser.SDate as date)=LINOUT.SDATE '
	-- End of Rev 3.0
	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),tbl_trans_shopuser.SDate,120) =CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
	--Rev work 2.0
	-- Rev 3.0
	--If @ISONLYLOGINDATA=1
	-- Begin
	--	SET @sqlStr+=' and LoginLogout=1 '
	-- End
	-- end of Rev 3.0	
	--End of Rev work 2.0
	SET @sqlStr+=' UNION ALL '
	SET @sqlStr+=' SELECT ISNULL(distance_covered,0) AS distance_covered,User_Id,cast(TBL_TRANS_SHOPUSER_ARCH.SDate as date) as SDate '
	--Rev work 2.0
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+='  ,LINOUT.LOGINLOATION as loginloation '
	 End
	--End of Rev work 2.0
	-- Rev 3.0
	 IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,LINOUT.LOGOUTLOATION as logoutloation '
	 End
	 -- End of Rev 3.0
	SET @sqlStr+=' FROM TBL_TRANS_SHOPUSER_ARCH '
	-- Rev 3.0
	If @ISONLYLOGINDATA=1 or @ISONLYLOGOUTDATA=1
		SET @sqlStr+=' LEFT OUTER JOIN #TMPLOGINOUTLOC LINOUT ON TBL_TRANS_SHOPUSER_ARCH.User_Id=LINOUT.USERID AND cast(TBL_TRANS_SHOPUSER_ARCH.SDate as date)=LINOUT.SDATE '
	-- End of Rev 3.0
	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),TBL_TRANS_SHOPUSER_ARCH.SDate,120) =CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
	--Rev work 2.0
	-- Rev 3.0
	--If @ISONLYLOGINDATA=1
	-- Begin
	--	SET @sqlStr+=' and LoginLogout=1 '
	-- End
	-- End of Rev 3.0
	--End of Rev work 2.0
	SET @sqlStr+=' ) T GROUP BY User_Id,T.SDate '
	--Rev work 2.0
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,T.loginloation'
	 End
	--End of Rev work 2.0
	-- Rev 3.0
	IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,T.logoutloation'
	 End
	 -- End of Rev 3.0
	SET @sqlStr+=' ) DISTNC ON ATTEN.User_Id=DISTNC.User_Id AND CAST(ATTEN.Work_datetime AS DATE)=cast(DISTNC.SDate as date) '
	SET @sqlStr+=' LEFT OUTER JOIN FTS_AttendanceImage IMG ON ATTEN.User_Id=IMG.USER_ID AND CAST(ATTEN.Work_datetime AS DATE)=cast(IMG.Attendance_DATE as date) '
	SET @sqlStr+=' LEFT OUTER JOIN (SELECT user_id,SUM(IDEAL_TIME) AS IDEAL_TIME,CAST(start_ideal_date_time AS DATE) AS start_ideal_date_time FROM(  '
	SET @sqlStr+=' SELECT user_id,start_ideal_date_time,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(end_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) '
	SET @sqlStr+=' + CAST(DATEPART(MINUTE,ISNULL(end_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(start_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) '
	SET @sqlStr+=' + CAST(DATEPART(MINUTE,ISNULL(start_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME FROM FTS_Ideal_Loaction  '
	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) ) IDLE GROUP BY user_id,CAST(start_ideal_date_time AS DATE)) '
	SET @sqlStr+=' IDEALLOACTION ON IDEALLOACTION.user_id=ATTEN.User_Id AND CAST(ATTEN.Work_datetime AS DATE)=CAST(IDEALLOACTION.start_ideal_date_time AS DATE) '
	SET @sqlStr+=' LEFT OUTER JOIN ( '
	SET @sqlStr+=' select SUM(Ordervalue)AS Ordervalue,CAST(Orderdate AS DATE) AS Orderdate,userID from tbl_trans_fts_Orderupdate ORDR '
	SET @sqlStr+=' INNER JOIN TBL_MASTER_SHOP SP ON ORDR.Shop_Code=SP.SHOP_CODE AND SP.type NOT IN (2,4) '
	SET @sqlStr+=' GROUP BY CAST(Orderdate AS DATE),userID) ORDRV ON  ATTEN.User_Id=ORDRV.userID AND CAST(ATTEN.Work_datetime AS DATE)=ORDRV.Orderdate '

	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
	SET @sqlStr+=' AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave '
	SET @sqlStr+=' ,Ordervalue,IMAGE_NAME,IDEAL_TIME,DISTNC.distance_covered '
	--Rev work 2.0
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,loginloation '
	 End
	--End of Rev work 2.0
	-- Rev 3.0
	IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,logoutloation '
	 End
	 -- End of Rev 3.0
	SET @sqlStr+=' UNION ALL '
				   
	SET @sqlStr+=' SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime, '
	SET @sqlStr+=' CASE WHEN Isonleave=''false'' THEN ''Present'' ELSE ''Absent'' END AS ATTEN_STATUS '

	SET @sqlStr+=' ,distance_covered, '
	--SET @sqlStr+=' RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR)/ 60 AS VARCHAR),2)  + '':'' +RIGHT(''0'' + CAST(CAST(IDEAL_TIME AS VARCHAR) % 60 AS VARCHAR),2) AS IDEAL_TIME,  '
	SET @sqlStr+=' ISNULL(CONVERT(NVARCHAR(50),cONVERT(DECIMAL(10,0),IDEAL_TIME/(select Value from FTS_APP_CONFIG_SETTINGS WHERE [Key]=''idle_time''))),''0'') AS IDEAL_TIME,  '
	SET @sqlStr+=' Ordervalue,IMAGE_NAME  '

	--Rev work 2.0
	If @ISONLYLOGINDATA=1
	 Begin
		-- Rev 3.0
		--SET @sqlStr+=',Null as loginloation '
		SET @sqlStr+=',DISTNC.loginloation '
		-- End of Rev 3.0
	 End
	IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,DISTNC.logoutloation '
	 End
	--End of Rev work 2.0

	SET @sqlStr+=' FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @sqlStr+=' INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @sqlStr+=' INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '

	SET @sqlStr+=' LEFT OUTER JOIN ( '
	SET @sqlStr+=' SELECT SUM(distance_covered) AS distance_covered,User_Id,SDate '
	--Rev work 2.0
	-- Rev 3.0
	If @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=',loginloation '
	 End
	 -- End of Rev 3.0
	IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,logoutloation  '
	 End
	--End of Rev 2.0
	SET @sqlStr+=' FROM  ( '
	SET @sqlStr+=' SELECT ISNULL(distance_covered,0) AS distance_covered,User_Id,cast(tbl_trans_shopuser.SDate as date) as SDate '
	-- Rev 3.0
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,LINOUT.LOGINLOATION as loginloation '
	 End
	 -- End of Rev 3.0
	--Rev work 2.0
	IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,LINOUT.LOGOUTLOATION as logoutloation '
	 End
	--End of Rev 2.0
	SET @sqlStr+=' FROM tbl_trans_shopuser '
	-- Rev 3.0
	If @ISONLYLOGINDATA=1 or @ISONLYLOGOUTDATA=1
		SET @sqlStr+=' LEFT OUTER JOIN #TMPLOGINOUTLOC LINOUT ON tbl_trans_shopuser.User_Id=LINOUT.USERID AND cast(tbl_trans_shopuser.SDate as date)=LINOUT.SDATE '
	-- End of Rev 3.0
	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),tbl_trans_shopuser.SDate,120) =CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
	
	 --Rev work 2.0
	-- Rev 3.0
	--IF @ISONLYLOGOUTDATA=1
	--  Begin
	--	SET @sqlStr+=' AND LoginLogout=0 '
	--  End
	-- End of Rev 3.0
	--End of Rev work 2.0
	SET @sqlStr+=' UNION ALL '
	SET @sqlStr+=' SELECT ISNULL(distance_covered,0) AS distance_covered,User_Id,cast(TBL_TRANS_SHOPUSER_ARCH.SDate as date) as SDate '
	-- Rev 3.0
	IF @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,LINOUT.LOGINLOATION as loginloation '
	 End
	 -- End of Rev 3.0
	--Rev work 2.0
	IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,LINOUT.LOGOUTLOATION as logoutloation '
	 End
	--End of Rev 2.0
	SET @sqlStr+=' FROM TBL_TRANS_SHOPUSER_ARCH '
	-- Rev 3.0
	If @ISONLYLOGINDATA=1 or @ISONLYLOGOUTDATA=1
		SET @sqlStr+=' LEFT OUTER JOIN #TMPLOGINOUTLOC LINOUT ON TBL_TRANS_SHOPUSER_ARCH.User_Id=LINOUT.USERID AND cast(TBL_TRANS_SHOPUSER_ARCH.SDate as date)=LINOUT.SDATE '
	-- End of Rev 3.0
	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),TBL_TRANS_SHOPUSER_ARCH.SDate,120) =CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
	-- Rev 3.0
	----Rev work 2.0
	--IF @ISONLYLOGOUTDATA=1
	--  Begin
	--	SET @sqlStr+=' AND LoginLogout=0 '
	--  End
	----End of Rev work 2.0
	-- End of Rev 3.0

	SET @sqlStr+=' ) T GROUP BY T.User_Id,T.SDate '
	-- Rev 3.0
	IF @ISONLYLOGINDATA=1
	  Begin
		SET @sqlStr+=' ,T.loginloation '
	  End
	-- End of Rev 3.0
	--Rev work 2.0
	IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,T.logoutloation'
	 End
	--End of Rev work 2.0
	SET @sqlStr+=' ) DISTNC ON ATTEN.User_Id=DISTNC.User_Id AND CAST(ATTEN.Work_datetime AS DATE)=cast(DISTNC.SDate as date) '
	SET @sqlStr+=' LEFT OUTER JOIN FTS_AttendanceImage IMG ON ATTEN.User_Id=IMG.USER_ID AND CAST(ATTEN.Work_datetime AS DATE)=cast(IMG.Attendance_DATE as date) '
	SET @SqlSTR+=' LEFT OUTER JOIN (SELECT user_id,SUM(IDEAL_TIME) AS IDEAL_TIME,CAST(start_ideal_date_time AS DATE) AS start_ideal_date_time FROM(  '
	SET @SqlSTR+=' SELECT user_id,start_ideal_date_time,CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(end_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) '
	SET @SqlSTR+=' + CAST(DATEPART(MINUTE,ISNULL(end_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) - CAST(CAST(ISNULL(CAST((DATEPART(HOUR,ISNULL(start_ideal_date_time,''00:00:00'')) * 60) AS FLOAT) '
	SET @SqlSTR+=' + CAST(DATEPART(MINUTE,ISNULL(start_ideal_date_time,''00:00:00'')) * 1 AS FLOAT),0) AS VARCHAR(100)) AS FLOAT) AS IDEAL_TIME FROM FTS_Ideal_Loaction  '
	SET @SqlSTR+=' WHERE CONVERT(NVARCHAR(10),start_ideal_date_time,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) ) IDLE GROUP BY user_id,CAST(start_ideal_date_time AS DATE)) '
	SET @SqlSTR+=' IDEALLOACTION ON IDEALLOACTION.user_id=ATTEN.User_Id AND CAST(ATTEN.Work_datetime AS DATE)=CAST(IDEALLOACTION.start_ideal_date_time AS DATE) '
	SET @sqlStr+=' LEFT OUTER JOIN ( '
	SET @sqlStr+=' select SUM(Ordervalue)AS Ordervalue,CAST(Orderdate AS DATE) AS Orderdate,userID from tbl_trans_fts_Orderupdate ORDR '
	SET @sqlStr+=' INNER JOIN TBL_MASTER_SHOP SP ON ORDR.Shop_Code=SP.SHOP_CODE AND SP.type NOT IN (2,4) '
	SET @sqlStr+=' GROUP BY CAST(Orderdate AS DATE),userID) ORDRV ON  ATTEN.User_Id=ORDRV.userID AND CAST(ATTEN.Work_datetime AS DATE)=ORDRV.Orderdate '

	SET @sqlStr+=' WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) AND CONVERT(NVARCHAR(10),'''+@FROM_DATE+''',120) '
	SET @sqlStr+=' AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
	SET @sqlStr+=' GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),ATTEN.Isonleave,Ordervalue,IMAGE_NAME,IDEAL_TIME,DISTNC.distance_covered '
	-- Rev 3.0
	IF @ISONLYLOGINDATA=1
	  Begin
		SET @sqlStr+=' ,loginloation '
	  End
	-- End of Rev 3.0
	--Rev work 2.0
	IF @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,logoutloation '	
	 End
	--End of rev 2.0
	SET @sqlStr+=' ) LOGINLOGOUT GROUP BY USERID,cnt_internalId,Login_datetime,ATTEN_STATUS,distance_covered,IDEAL_TIME,Ordervalue,IMAGE_NAME '
	--Rev work 2.0
	If @ISONLYLOGINDATA=1
	 Begin
		SET @sqlStr+=' ,loginloation '
	 End
	If @ISONLYLOGOUTDATA=1
	 Begin
		SET @sqlStr+=' ,logoutloation '
	 End
	--End of rev 2.0
	SET @sqlStr+=' ) ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	IF @EMPID <> ''
	BEGIN
		SET @sqlStr+=' WHERE EXISTS (SELECT TMP.emp_contactId FROM #EMPLOYEE_LIST TMP WHERE TMP.emp_contactId= CNT.cnt_internalId) '
	END
	SET @sqlStr+=' ) T '

	EXEC SP_EXECUTESQL @sqlStr
	--select @sqlStr


	--Rev 3.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Userid)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	--End of Rev 3.0
	--Rev work 2.0
	If @ShowFullday=1
		DROP TABLE #TEMPCTCCONTACT
	--End of rev 2.0
	-- Rev 3.0
	IF OBJECT_ID('tempdb..#TMPLOGINOUTLOC') IS NOT NULL		
		DROP TABLE #TMPLOGINOUTLOC

	IF OBJECT_ID('tempdb..#TMPLOGOUTLOC') IS NOT NULL
		DROP TABLE #TMPLOGOUTLOC

	IF OBJECT_ID('tempdb..#TMPLOGINLOC') IS NOT NULL	
		DROP TABLE #TMPLOGINLOC
	-- End of Rev 3.0
END
GO