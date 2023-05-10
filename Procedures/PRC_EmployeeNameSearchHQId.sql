IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_EmployeeNameSearchHQId]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_EmployeeNameSearchHQId] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_EmployeeNameSearchHQId]  
(
	@USER_ID BIGINT=0,
	@SearchKey nvarchar(50) ='',
	@HQid nvarchar(max)=''
) --WITH ENCRYPTION
AS
/*******************************************************************************************************************************************************************************************
Written by Sanchita for		V2.0.40		on	10-05-2023	
	If HQ is selected then the Employee field should show only those employees whose HQ is selected in the HQ field. 
	Refer : 26063
********************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @STRSQL NVARCHAR(MAX)

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
	BEGIN
		DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USER_ID)		
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

	IF(@HQid <>'')
	BEGIN
		CREATE TABLE #MASTER_ADDRESS
		(
			ADD_ID	NUMERIC(10),
			ADD_CNTID NVARCHAR(100),
			ADD_CITY INT
		)
		
		SET @HQid= ''''+ REPLACE(@HQid,',',''',''') + ''''

		SET @STRSQL =  'INSERT INTO #MASTER_ADDRESS '
		SET @STRSQL += 'SELECT add_id, add_cntId, add_city FROM tbl_master_address WHERE add_city IN ('+@HQid+') '
		EXEC (@STRSQL)
	END


	SET @STRSQL = ''
	SET @STRSQL =  'select top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'''')+'' ''+ISNULL(cnt_middleName,'''')+ '' ''+ISNULL(cnt_lastName,''''),'''',''&#39;'') AS Employee_Name,cnt_UCC  '
	SET @STRSQL += 'from tbl_master_contact '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
	BEGIN
		SET @STRSQL += 'INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE '
	END
	SET @STRSQL += 'INNER JOIN tbl_master_user USR ON tbl_master_contact.cnt_internalId=USR.user_contactId AND USR.user_inactive=''N'' '
	IF(@HQid<>'')
	BEGIN
		SET @STRSQL += 'INNER JOIN #MASTER_ADDRESS ADDR ON  USR.user_contactId=ADDR.add_cntId '
	END
	SET @STRSQL += 'where (cnt_firstName like ''%'+ @SearchKey +'%'') or  (cnt_middleName like ''%'+ @SearchKey +'%'') or  (cnt_lastName like ''%'+ @SearchKey +'%'') '
	SET @STRSQL += 'or (cnt_UCC like ''%'+ @SearchKey +'%'') '
	EXEC (@STRSQL)

	--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
	--	BEGIN
			
	--		select top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
	--		from tbl_master_contact 
	--		INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
	--		INNER JOIN tbl_master_user USR ON tbl_master_contact.cnt_internalId=USR.user_contactId AND USR.user_inactive='N'
	--		where (cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%')
	--				or (cnt_UCC like '%' + @SearchKey + '%')
			
	--		DROP TABLE #EMPHR_EDIT
	--		DROP TABLE #EMPHRS
	--	END
	--ELSE
	--	BEGIN
	--		select top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
	--		from tbl_master_contact 
	--		INNER JOIN tbl_master_user USR ON tbl_master_contact.cnt_internalId=USR.user_contactId AND USR.user_inactive='N'
	--		where (cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%')
	--				or (cnt_UCC like '%' + @SearchKey + '%')
					
	--	END

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
	BEGIN
		DROP TABLE #EMPHR_EDIT
		DROP TABLE #EMPHRS
	END
	IF(@HQid <>'')
	BEGIN
		DROP TABLE #MASTER_ADDRESS
	END
END
