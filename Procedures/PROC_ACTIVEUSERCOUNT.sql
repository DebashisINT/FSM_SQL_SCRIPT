IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_ACTIVEUSERCOUNT]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_ACTIVEUSERCOUNT] AS' 
END
GO
ALTER Proc [dbo].[PROC_ACTIVEUSERCOUNT]
As

Begin
CREATE TABLE #tempusercount
(
CLIENT_NAME nvarchar(500),
User_Counts int
)

declare @DB_NAME varchar(MAX),@sqlStrTable NVARCHAR(MAX),@CLIENT_NAME NVARCHAR(500),@html nvarchar(MAX)
DECLARE UOMMAIN_CURSOR CURSOR  
LOCAL  FORWARD_ONLY  FOR  

select DB1,CLIENT_NAME from BREEZE_CLIENT_DETAILS where TYPE_OF_PRODUCT in ('FSM','Attendance System - FSM') --'BreezeERP on Cloud, AMC',
OPEN UOMMAIN_CURSOR  
FETCH NEXT FROM UOMMAIN_CURSOR INTO  @DB_NAME,@CLIENT_NAME
WHILE @@FETCH_STATUS = 0  
BEGIN  

    DECLARE @tab char(1) = CHAR(9), @Emailid nvarchar(max), @sqlQry nvarchar(max)
	SET @sqlStrTable=''
	SET @sqlStrTable=' INSERT INTO #tempusercount SELECT '''+@CLIENT_NAME+''',COUNT(1) AS USERS FROM ['+@DB_NAME+'].[dbo].[TBL_MASTER_USER] USR WHERE USR.user_inactive=''N'' AND USR.user_loginId!=''admin'' and isComplementaryUser=0 '
	SET @sqlStrTable=' INSERT INTO #tempusercount SELECT '''+@CLIENT_NAME+''', COUNT(1) AS USERS FROM ['+@DB_NAME+'].[dbo].[tbl_master_employee] EMP '
	SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_user] USR ON USR.user_contactId=EMP.emp_contactId AND user_inactive=''N'' and ISNULL(USR.Custom_Configuration,0)=0 and USR.isComplementaryUser=0 '--USR.user_name!=''ADMIN''  '
	SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_address] ADDR ON ADDR.add_cntId=EMP.emp_contactId AND ADDR.add_addressType=''Office'' '
	SET @sqlStrTable+='INNER JOIN ['+@DB_NAME+'].[dbo].[tbl_master_state] ST ON ST.id=ADDR.add_state '
	EXEC SP_EXECUTESQL @sqlStrTable

FETCH NEXT FROM UOMMAIN_CURSOR INTO  @DB_NAME,@CLIENT_NAME
END  
CLOSE UOMMAIN_CURSOR  
DEALLOCATE UOMMAIN_CURSOR  

EXEC spQueryToHtmlTable @html = @html OUTPUT, @query = N'SELECT * FROM #tempusercount'

EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'BreezeERP',  
		@body = @html,
        @body_format = 'HTML',
		@subject = 'USER COUNT',
		@recipients = 'pijushk.bhattacharya@indusnet.co.in;santanu.roy@indusnet.co.in;goutamk.das@indusnet.co.in;avijit.bonu@indusnet.co.in;suman.roy@indusnet.co.in;debashis.talukder@indusnet.co.in;priyanka@indusnet.co.in;ranajit.jana@indusnet.co.in'
		--@recipients = 'pijushk.bhattacharya@indusnet.co.in'
		
DROP TABLE #tempusercount
END
GO