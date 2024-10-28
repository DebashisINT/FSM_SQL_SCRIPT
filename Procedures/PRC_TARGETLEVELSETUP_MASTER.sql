IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_TARGETLEVELSETUP_MASTER]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_TARGETLEVELSETUP_MASTER] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_TARGETLEVELSETUP_MASTER]
(
	@ACTION NVARCHAR(500)=NULL,
	--@IMPORT_TABLE udt_ImportCurrentStock READONLY,
	@USERID INT=NULL,
	--@FromDate NVARCHAR(10)=NULL,
	--@ToDate NVARCHAR(10)=NULL,
	--@IS_PAGELOAD NVARCHAR(100)=NULL,
	--@SearchKey nvarchar(max) = NULL,
	@DESIG_ID BIGINT=0,
	@BRANCHID NVARCHAR(MAX)='',
	@SALESMANLEVEL VARCHAR(100)=NULL,
	@BASEDON BIGINT=0,
	@SELECTEDEMPLOYEEBASEDONMAPLIST NVARCHAR(max)=NULL,
	--@QUANTITY DECIMAL(18,4)=0,
	
	@RETURN_VALUE nvarchar(500)=NULL OUTPUT

) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************
Written by Sanchita

Target Level Set up master creation : 27768
***************************************************************************************************************************************/
BEGIN

	DECLARE @empcode VARCHAR(50), @StrSql NVARCHAR(MAX)
	DECLARE @CNT_CONTACTID NVARCHAR(100), @CNT_USERID NUMERIC(10,0), @TARGET_ID_AUTO BIGINT, @ID BIGINT, @TARGET_LEVELID BIGINT

	IF(@ACTION='GETLEVELDATA')
	BEGIN
		SELECT ID, LEVEL_NAME, LEVEL_SEQ, LEVEL_PARENTID FROM FSM_TARGETLEVELSETUP_MASTER ORDER BY LEVEL_SEQ 
	END

	IF(@ACTION='GETDROPDOWNBINDDATA')
	BEGIN
		SELECT '0' deg_id, '-- Select --' deg_designation
		union
		select CONVERT(VARCHAR(10), deg_id) deg_id , deg_designation from tbl_master_designation
		ORDER BY deg_designation

	END

	IF(@ACTION='GETEMPLOYEELIST' OR @ACTION='SHOW')
	BEGIN
		SET @empcode =(select user_contactId from Tbl_master_user where user_id=@USERID)		
		CREATE TABLE #EMPHR
		(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
		)

		CREATE TABLE #EMPHR_EDIT
		(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
		)

		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
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

		SET @StrSql = ''
			
		IF @ACTION='GETEMPLOYEELIST'
		BEGIN
			SET @StrSql = 'SELECT convert(nvarchar(10),EMP.emp_id) as [ID], '
			SET @StrSql += 'isnull(CON.cnt_firstName,'''')+'' ''+isnull(CON.cnt_middleName,'''')+'' ''+isnull(CON.cnt_lastName,'''') AS [NAME] , convert(bit,1) as selected '
			SET @StrSql += 'FROM tbl_master_EMPLOYEE EMP '
			SET @StrSql += 'inner join tbl_master_contact CON on EMP.emp_contactId=con.cnt_internalId '
			SET @StrSql += 'inner join tbl_master_user U on EMP.emp_contactId=U.user_contactId and U.user_inactive=''N''  '
			SET @StrSql += 'INNER JOIN FSM_TARGET_EMPMAP MAP ON EMP.emp_contactId=MAP.TARGET_EMPCNTID AND MAP.TARGET_LEVEL_SHORTNAME= '''+@SALESMANLEVEL+''' '
			
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
			BEGIN
				SET @StrSql += 'INNER JOIN #EMPHR_EDIT EMPHR ON CON.cnt_internalId=EMPHR.EMPCODE '
			END

			SET @StrSql += ' UNION ALL '

			SET @StrSql += 'SELECT convert(nvarchar(10),EMP.emp_id) as [ID], '
			SET @StrSql += 'isnull(CON.cnt_firstName,'''')+'' ''+isnull(CON.cnt_middleName,'''')+'' ''+isnull(CON.cnt_lastName,'''') AS [NAME] , convert(bit,0) as selected '
			SET @StrSql += 'FROM tbl_master_EMPLOYEE EMP '
			SET @StrSql += 'inner join tbl_master_contact CON on EMP.emp_contactId=con.cnt_internalId '
			SET @StrSql += 'inner join tbl_master_user U on EMP.emp_contactId=U.user_contactId and U.user_inactive=''N''  '
			SET @StrSql += ' AND NOT EXISTS(SELECT TARGET_EMPCNTID FROM FSM_TARGET_EMPMAP WHERE TARGET_EMPCNTID=EMP.emp_contactId )'
			
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
			BEGIN
				SET @StrSql += 'INNER JOIN #EMPHR_EDIT EMPHR ON CON.cnt_internalId=EMPHR.EMPCODE '
			END

			IF(@DESIG_ID <> 0)
			BEGIN
				SET @StrSql += 'INNER JOIN TBL_TRANS_EMPLOYEECTC EMP_CTC ON EMP.emp_contactId=EMP_CTC.EMP_CNTID '
				SET @StrSql += 'INNER JOIN TBL_MASTER_DESIGNATION DEG ON EMP_CTC.emp_Designation=DEG.DEG_ID AND DEG.DEG_ID= '+ CONVERT(VARCHAR(10), @DESIG_ID)
			END

			--SET @StrSql += ' WHERE NOT EXISTS(SELECT TARGET_EMPCNTID FROM FSM_TARGET_EMPMAP WHERE TARGET_EMPCNTID=EMP.emp_contactId ) '

			--SELECT @StrSql

			EXEC (@StrSql)	
		END
		ELSE IF @ACTION='SHOW'
		BEGIN
			SET @StrSql = 'SELECT convert(nvarchar(10),EMP.emp_id) as [ID], '
			SET @StrSql += 'isnull(CON.cnt_firstName,'''')+'' ''+isnull(CON.cnt_middleName,'''')+'' ''+isnull(CON.cnt_lastName,'''') AS [NAME] , convert(bit,1) as selected '
			SET @StrSql += 'FROM tbl_master_EMPLOYEE EMP '
			SET @StrSql += 'inner join tbl_master_contact CON on EMP.emp_contactId=con.cnt_internalId '
			SET @StrSql += 'inner join tbl_master_user U on EMP.emp_contactId=U.user_contactId and U.user_inactive=''N''  '
			SET @StrSql += 'INNER JOIN FSM_TARGET_EMPMAP MAP ON EMP.emp_contactId=MAP.TARGET_EMPCNTID AND MAP.TARGET_LEVEL_SHORTNAME= '''+@SALESMANLEVEL+''' '
			
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
			BEGIN
				SET @StrSql += 'INNER JOIN #EMPHR_EDIT EMPHR ON CON.cnt_internalId=EMPHR.EMPCODE '
			END

			---SELECT @StrSql
			
			EXEC (@StrSql)	
		END

		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END

	IF(@ACTION='ADD')
	BEGIN
		select s into #EMPBASEDONMAP  from dbo.GetSplit(',',@SELECTEDEMPLOYEEBASEDONMAPLIST)

		BEGIN TRY
		BEGIN TRANSACTION
			
			set @StrSql='DELETE FROM FSM_TARGET_EMPMAP WHERE TARGET_EMPID NOT IN ('+@SELECTEDEMPLOYEEBASEDONMAPLIST+') AND TARGET_LEVEL_SHORTNAME = ''' +@SALESMANLEVEL+ ''' ' 
			EXEC (@StrSql)	

			declare db_cursor_BO cursor for
			SELECT s FROM #EMPBASEDONMAP 	
			open db_cursor_BO
			fetch next from db_cursor_BO into @ID
			while @@FETCH_STATUS=0
			begin

				SET @CNT_CONTACTID = ISNULL( (SELECT TOP 1 emp_contactId FROM tbl_master_employee WHERE emp_id=@ID) ,'')
				SET @CNT_USERID = ISNULL( (SELECT TOP 1 USER_ID FROM TBL_MASTER_USER WHERE user_contactId=@CNT_CONTACTID) ,'')

				--SET @TARGET_LEVELID = (SELECT * FROM FSM_TARGETLEVELSETUP_MASTER WHERE LEVEL_SHORTNAME=@SALESMANLEVEL )
	
				SET @TARGET_ID_AUTO = isnull((SELECT MAX(TARGET_ID) FROM FSM_TARGET_EMPMAP),0)+1

				--IF EXISTS(SELECT TARGET_ID FROM FSM_TARGET_EMPMAP WHERE TARGET_EMPCNTID=@CNT_CONTACTID)
				--BEGIN
				--	DELETE FROM FSM_TARGET_EMPMAP WHERE TARGET_EMPCNTID=@CNT_CONTACTID
				--END

				IF NOT EXISTS(SELECT TARGET_ID FROM FSM_TARGET_EMPMAP WHERE TARGET_EMPCNTID=@CNT_CONTACTID)
				BEGIN
					INSERT INTO FSM_TARGET_EMPMAP (TARGET_ID, TARGET_LEVEL_SHORTNAME, TARGET_BASEDON, TARGET_EMPID, TARGET_EMPCNTID, TARGET_USERID,
													CREATEDBY, CREATEDON, UPDATEDBY, UPDATEDON)
					VALUES (@TARGET_ID_AUTO, @SALESMANLEVEL, @BASEDON, @ID, @CNT_CONTACTID, @CNT_USERID, @USERID, SYSDATETIME(), NULL,NULL )
				END
				

				fetch next from db_cursor_BO into @ID
			END
			close db_cursor_BO
			deallocate db_cursor_BO

			SET @RETURN_VALUE = '1'

		COMMIT TRANSACTION
		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			set @RETURN_VALUE='-10'
		
		END CATCH
	END

	
END
GO

