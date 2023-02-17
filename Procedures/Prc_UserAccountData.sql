IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Prc_UserAccountData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Prc_UserAccountData] AS' 
END
GO
ALTER PROCEDURE [dbo].[Prc_UserAccountData]
	@FromJoinDate Varchar(25)=null,
	@ToJoinDate Varchar(25)=null,
	@User_id int=null
AS
/*==================================================================================================================================================
1.0		v2.0.31		Swatilekha	27-07-2022		New Sp Creation for New Module User Account Listing page.Refer: 25046
2.0		V2.0.39		Sanchita	16/02/2023		A setting required for 'User Account' Master module in FSM Portal. Refer: 25669
==================================================================================================================================================*/
Begin
	-- Rev 2.0
	DECLARE @sqlStrTable NVARCHAR(MAX)
	-- End of Rev 2.0

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)	
	BEGIN
		DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@User_id)		
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

	CREATE TABLE #CHANNEL
	(
		EMPCODE VARCHAR(50),
		CHANNELNAME VARCHAR(100)
	) 

	INSERT INTO #CHANNEL
	SELECT X.*
	FROM
	(
		SELECT CM.EP_EMP_CONTACTID,CH.CH_CHANNEL AS CHANNELNAME  
		FROM EMPLOYEE_CHANNELMAP CM,EMPLOYEE_CHANNEL CH
		WHERE CM.EP_CH_ID=CH.CH_ID
	)X

	CREATE TABLE #CIRCLE
	(
		EMPCODE VARCHAR(50),
		CIRCLENAME VARCHAR(100)
	) 
	INSERT INTO #CIRCLE
	SELECT CRM.EP_EMP_CONTACTID,CRL_CIRCLE AS CIRCLENAME
	FROM EMPLOYEE_CIRCLEMAP CRM,EMPLOYEE_CIRCLE ECR
	WHERE CRM.EP_CRL_ID=ECR.CRL_ID

	CREATE TABLE #SECTION
	(
		EMPCODE VARCHAR(50),
		SECTIONNAME VARCHAR(100)
	)
	INSERT INTO #SECTION
	SELECT ESM.EP_EMP_CONTACTID,ES.SEC_SECTION AS SECTIONNAME
	FROM EMPLOYEE_SECTIONMAP ESM,EMPLOYEE_SECTION ES
	WHERE ESM.EP_SEC_ID=ES.SEC_ID

	-- Rev 2.0
	DECLARE @IsShowUserAccountForITC VARCHAR(1) = '0'
	SET @IsShowUserAccountForITC = (SELECT TOP 1 VALUE FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsShowUserAccountForITC')
	-- End of Rev 2.0

	-- Rev 2.0
	--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	--  BEGIN
	--		SELECT DISTINCT U.user_loginId as USER_ID,U.USER_NAME,F.STAGE,
	--		(SELECT BRANCH_DESCRIPTION FROM TBL_MASTER_BRANCH WHERE BRANCH_ID=C.CNT_BRANCHID) AS BRANCHNAME,CTC.REPORTTO
	--		,CH.CHANNELNAME,CR.CIRCLENAME,SE.SECTIONNAME,u.CreateDate
	--		,CTC.deg_designation
	--		FROM TBL_MASTER_USER U
	--		LEFT OUTER JOIN FTS_STAGE F 
	--		ON U.FACEREGTYPEID=F.STAGEID
	--		INNER JOIN TBL_MASTER_EMPLOYEE E 
	--		ON E.EMP_CONTACTID=U.USER_CONTACTID
	--		INNER JOIN TBL_MASTER_CONTACT C ON C.CNT_INTERNALID=U.USER_CONTACTID
	--		INNER JOIN #EMPHR_EDIT EH ON EH.EMPCODE=C.CNT_INTERNALID
	--		LEFT OUTER JOIN
	--		(
	--			SELECT EMPCTC.emp_cntId,
	--			ISNULL(CNT.CNT_FIRSTNAME,'')+' '+ISNULL(CNT.CNT_MIDDLENAME,'')+' '+ISNULL(CNT.CNT_LASTNAME,'')+'['+EMP.emp_uniqueCode +']' AS REPORTTO
	--			,EMPCTC.emp_Designation AS DESGID ,DG.deg_designation           
	--			FROM tbl_master_employee EMP     
	--			INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo       
	--			INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=EMP.emp_contactId and CNT.cnt_contactType='EM' 
	--			LEFT OUTER JOIN  TBL_MASTER_DESIGNATION DG ON EMPCTC.emp_Designation=DG.deg_id   
	--			WHERE EMPCTC.emp_effectiveuntil IS NULL
	--		)CTC ON CTC.emp_cntId=C.cnt_internalId
	--		LEFT OUTER JOIN
	--		(
	--			SELECT T.EMPCODE
	--			, STUFF(( 
	--					SELECT ', ' + CHANNELNAME
	--					FROM #CHANNEL 
	--					WHERE EMPCODE = T.EMPCODE			
	--					FOR XML PATH(''),TYPE
	--				).value('.','NVARCHAR(MAX)'),1,2,'') AS CHANNELNAME
	--			FROM #CHANNEL T	
	--			GROUP BY T.EMPCODE
	--		)CH
	--		ON CH.EMPCODE=C.CNT_INTERNALID
	--		LEFT OUTER JOIN
	--		(
	--			SELECT T.EMPCODE
	--			, STUFF(( 
	--					SELECT ', ' + CIRCLENAME
	--					FROM #CIRCLE 
	--					WHERE EMPCODE = T.EMPCODE			
	--					FOR XML PATH(''),TYPE
	--				).value('.','NVARCHAR(MAX)'),1,2,'') AS CIRCLENAME
	--			FROM #CIRCLE T	
	--			GROUP BY T.EMPCODE
	--		)CR ON CR.EMPCODE=C.CNT_INTERNALID	
	--		LEFT OUTER JOIN
	--		(
	--			SELECT T.EMPCODE
	--			, STUFF
	--			(( 
	--					SELECT ', ' + SECTIONNAME
	--					FROM #SECTION 
	--					WHERE EMPCODE = T.EMPCODE			
	--					FOR XML PATH(''),TYPE
	--				).value('.','NVARCHAR(MAX)'),1,2,'') AS SECTIONNAME
	--			FROM #SECTION T
	--			GROUP BY T.EMPCODE
	--		)SE ON SE.EMPCODE=C.CNT_INTERNALID					
	--		WHERE C.cnt_contactType='EM'
	--		and isnull(e.emp_dateofLeaving,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and (e.emp_dateofJoining Between '1900-01-01' and '9999-12-31')
	--		--AND CTC.DESGID IN(291,310)  
	--		AND CTC.deg_designation IN('DS','TL')  and U.user_inactive='N'
	--		ORDER BY U.CREATEDATE DESC

	--		DROP TABLE #EMPHR
	--		DROP TABLE #EMPHR_EDIT	
	--		DROP TABLE #CHANNEL
	--		DROP TABLE #CIRCLE
	--		DROP TABLE #SECTION		
	--  END
	--ELSE
	--  BEGIN
	--		SELECT DISTINCT U.user_loginId as USER_ID,U.USER_NAME,F.STAGE,
	--		(SELECT BRANCH_DESCRIPTION FROM TBL_MASTER_BRANCH WHERE BRANCH_ID=C.CNT_BRANCHID) AS BRANCHNAME,CTC.REPORTTO
	--		,CH.CHANNELNAME,CR.CIRCLENAME,SE.SECTIONNAME,U.CREATEDATE
	--		,CTC.deg_designation
	--		FROM TBL_MASTER_USER U
	--		LEFT OUTER JOIN FTS_STAGE F 
	--		ON U.FACEREGTYPEID=F.STAGEID
	--		INNER JOIN TBL_MASTER_EMPLOYEE E 
	--		ON E.EMP_CONTACTID=U.USER_CONTACTID
	--		INNER JOIN TBL_MASTER_CONTACT C ON C.CNT_INTERNALID=U.USER_CONTACTID			
	--		LEFT OUTER JOIN
	--		(
	--			SELECT EMPCTC.emp_cntId,
	--			ISNULL(CNT.CNT_FIRSTNAME,'')+' '+ISNULL(CNT.CNT_MIDDLENAME,'')+' '+ISNULL(CNT.CNT_LASTNAME,'')+'['+EMP.emp_uniqueCode +']' AS REPORTTO  
	--			,EMPCTC.emp_Designation AS DESGID ,DG.deg_designation         
	--			FROM tbl_master_employee EMP     
	--			INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo       
	--			INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=EMP.emp_contactId and CNT.cnt_contactType='EM' 
	--			LEFT OUTER JOIN  TBL_MASTER_DESIGNATION DG ON EMPCTC.emp_Designation=DG.deg_id   
	--			WHERE EMPCTC.emp_effectiveuntil IS NULL
	--		)CTC ON CTC.emp_cntId=C.cnt_internalId
	--		LEFT OUTER JOIN
	--		(
	--			SELECT T.EMPCODE
	--			, STUFF(( 
	--					SELECT ', ' + CHANNELNAME
	--					FROM #CHANNEL 
	--					WHERE EMPCODE = T.EMPCODE			
	--					FOR XML PATH(''),TYPE
	--				).value('.','NVARCHAR(MAX)'),1,2,'') AS CHANNELNAME
	--			FROM #CHANNEL T	
	--			GROUP BY T.EMPCODE
	--		)CH
	--		ON CH.EMPCODE=C.CNT_INTERNALID
	--		LEFT OUTER JOIN
	--		(
	--			SELECT T.EMPCODE
	--			, STUFF(( 
	--					SELECT ', ' + CIRCLENAME
	--					FROM #CIRCLE 
	--					WHERE EMPCODE = T.EMPCODE			
	--					FOR XML PATH(''),TYPE
	--				).value('.','NVARCHAR(MAX)'),1,2,'') AS CIRCLENAME
	--			FROM #CIRCLE T	
	--			GROUP BY T.EMPCODE
	--		)CR ON CR.EMPCODE=C.CNT_INTERNALID	
	--		LEFT OUTER JOIN
	--		(
	--			SELECT T.EMPCODE
	--			, STUFF
	--			(( 
	--					SELECT ', ' + SECTIONNAME
	--					FROM #SECTION 
	--					WHERE EMPCODE = T.EMPCODE			
	--					FOR XML PATH(''),TYPE
	--				).value('.','NVARCHAR(MAX)'),1,2,'') AS SECTIONNAME
	--			FROM #SECTION T
	--			GROUP BY T.EMPCODE
	--		)SE ON SE.EMPCODE=C.CNT_INTERNALID	
	--		WHERE C.cnt_contactType='EM'
	--		and isnull(e.emp_dateofLeaving,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and (e.emp_dateofJoining Between '1900-01-01' and '9999-12-31')
	--		--AND CTC.DESGID IN(291,310)  
	--		AND CTC.deg_designation IN('DS','TL')  and U.user_inactive='N'
	--		ORDER BY U.CREATEDATE DESC

	--		DROP TABLE #CHANNEL
	--		DROP TABLE #CIRCLE
	--		DROP TABLE #SECTION
	--  END

	SET @sqlStrTable = ''
	SET @sqlStrTable += 'SELECT DISTINCT U.USER_ID AS UID, U.user_loginId as USER_ID,U.USER_NAME,F.STAGE, '
	SET @sqlStrTable += '(SELECT BRANCH_DESCRIPTION FROM TBL_MASTER_BRANCH WHERE BRANCH_ID=C.CNT_BRANCHID) AS BRANCHNAME,CTC.REPORTTO '
	SET @sqlStrTable += ',CH.CHANNELNAME,CR.CIRCLENAME,SE.SECTIONNAME,u.CreateDate '
	SET @sqlStrTable += ',CTC.deg_designation '
	SET @sqlStrTable += 'FROM TBL_MASTER_USER U '
	SET @sqlStrTable += 'LEFT OUTER JOIN FTS_STAGE F '
	SET @sqlStrTable += 'ON U.FACEREGTYPEID=F.STAGEID '
	SET @sqlStrTable += 'INNER JOIN TBL_MASTER_EMPLOYEE E '
	SET @sqlStrTable += 'ON E.EMP_CONTACTID=U.USER_CONTACTID '
	SET @sqlStrTable += 'INNER JOIN TBL_MASTER_CONTACT C ON C.CNT_INTERNALID=U.USER_CONTACTID '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	BEGIN
		SET @sqlStrTable += 'INNER JOIN #EMPHR_EDIT EH ON EH.EMPCODE=C.CNT_INTERNALID '
	END
	SET @sqlStrTable += 'LEFT OUTER JOIN '
	SET @sqlStrTable += '( '
	SET @sqlStrTable += '	SELECT EMPCTC.emp_cntId, '
	SET @sqlStrTable += '	ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''')+''[''+EMP.emp_uniqueCode +'']'' AS REPORTTO '
	SET @sqlStrTable += '	,EMPCTC.emp_Designation AS DESGID ,DG.deg_designation '
	SET @sqlStrTable += '	FROM tbl_master_employee EMP '
	SET @sqlStrTable += '	INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @sqlStrTable += '	INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=EMP.emp_contactId and CNT.cnt_contactType=''EM'' '
	SET @sqlStrTable += '	LEFT OUTER JOIN  TBL_MASTER_DESIGNATION DG ON EMPCTC.emp_Designation=DG.deg_id  '
	SET @sqlStrTable += '	WHERE EMPCTC.emp_effectiveuntil IS NULL '
	SET @sqlStrTable += ')CTC ON CTC.emp_cntId=C.cnt_internalId '
	SET @sqlStrTable += 'LEFT OUTER JOIN '
	SET @sqlStrTable += '( '
	SET @sqlStrTable += '	SELECT T.EMPCODE '
	SET @sqlStrTable += '	, STUFF((  '
	SET @sqlStrTable += '			SELECT '', '' + CHANNELNAME '
	SET @sqlStrTable += '			FROM #CHANNEL '
	SET @sqlStrTable += '			WHERE EMPCODE = T.EMPCODE '
	SET @sqlStrTable += '			FOR XML PATH(''''),TYPE '
	SET @sqlStrTable += '		).value(''.'',''NVARCHAR(MAX)''),1,2,'''') AS CHANNELNAME '
	SET @sqlStrTable += '	FROM #CHANNEL T	'
	SET @sqlStrTable += '	GROUP BY T.EMPCODE '
	SET @sqlStrTable += ')CH '
	SET @sqlStrTable += 'ON CH.EMPCODE=C.CNT_INTERNALID '
	SET @sqlStrTable += 'LEFT OUTER JOIN '
	SET @sqlStrTable += '( '
	SET @sqlStrTable += '	SELECT T.EMPCODE '
	SET @sqlStrTable += '	, STUFF(( '
	SET @sqlStrTable += '			SELECT '', '' + CIRCLENAME '
	SET @sqlStrTable += '			FROM #CIRCLE '
	SET @sqlStrTable += '			WHERE EMPCODE = T.EMPCODE '
	SET @sqlStrTable += '			FOR XML PATH(''''),TYPE '
	SET @sqlStrTable += '		).value(''.'',''NVARCHAR(MAX)''),1,2,'''') AS CIRCLENAME '
	SET @sqlStrTable += '	FROM #CIRCLE T	'
	SET @sqlStrTable += '	GROUP BY T.EMPCODE '
	SET @sqlStrTable += ')CR ON CR.EMPCODE=C.CNT_INTERNALID	'
	SET @sqlStrTable += 'LEFT OUTER JOIN '
	SET @sqlStrTable += '( '
	SET @sqlStrTable += '	SELECT T.EMPCODE '
	SET @sqlStrTable += '	, STUFF '
	SET @sqlStrTable += '	(( '
	SET @sqlStrTable += '			SELECT '', '' + SECTIONNAME '
	SET @sqlStrTable += '			FROM #SECTION '
	SET @sqlStrTable += '			WHERE EMPCODE = T.EMPCODE '
	SET @sqlStrTable += '			FOR XML PATH(''''),TYPE '
	SET @sqlStrTable += '		).value(''.'',''NVARCHAR(MAX)''),1,2,'''') AS SECTIONNAME '
	SET @sqlStrTable += '	FROM #SECTION T '
	SET @sqlStrTable += '	GROUP BY T.EMPCODE '
	SET @sqlStrTable += ')SE ON SE.EMPCODE=C.CNT_INTERNALID	'
	SET @sqlStrTable += 'WHERE C.cnt_contactType=''EM'' '
	SET @sqlStrTable += 'and isnull(e.emp_dateofLeaving,''1900-01-01 00:00:00.000'')=''1900-01-01 00:00:00.000'' and (e.emp_dateofJoining Between ''1900-01-01'' and ''9999-12-31'') '
	IF (@IsShowUserAccountForITC='1')
	BEGIN
		SET @sqlStrTable += 'AND CTC.deg_designation IN(''DS'',''TL'') '
	END
	SET @sqlStrTable += 'AND U.user_inactive=''N'' '
	SET @sqlStrTable += 'ORDER BY UID DESC '

	--SELECT @sqlStrTable
	EXEC SP_EXECUTESQL @sqlStrTable

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT	
	END
	DROP TABLE #CHANNEL
	DROP TABLE #CIRCLE
	DROP TABLE #SECTION
	-- End of Rev 2.0
End
GO