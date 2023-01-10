IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_EmployeesListByStateDesignation_Hier]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_EmployeesListByStateDesignation_Hier] AS' 
END
GO

-- EXEC prc_EmployeesListByStateDesignation_Hier @STATE='WEST BENGAL', @DESIGNATION='Accountant', @USERID=378
-- EXEC prc_EmployeesListByStateDesignation_Hier @STATE='WEST BENGAL', @DESIGNATION='WD', @USERID=11706

ALTER PROC [dbo].[prc_EmployeesListByStateDesignation_Hier]
(
	@STATE VARCHAR(200),
	@DESIGNATION VARCHAR(200),
	@USERID BIGINT = 0
)

AS  
/*******************************************************************************************************************************************************************************************
1.0		v2.0.36		Sanchita	10-01-2023		Appconfig and User wise setting "IsAllDataInPortalwithHeirarchy = True" then data in portal shall be populated based on Hierarchy Only.
												Refer: 25504
********************************************************************************************************************************************************************************************/
SET NOCOUNT ON ;
BEGIN TRY  

	-- Rev 1.0
	DECLARE @Strsql NVARCHAR(MAX)


	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
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
		-- End of Rev 1.0
	
	--  Rev 1.0
	--SELECT (CNT.cnt_firstName + ' ' + CNT.cnt_lastName) AS EmpName, CNT.cnt_internalId AS EmpCode,USR.user_loginId AS LoginID,USR.user_id AS UserID
 
	--FROM  tbl_master_contact CNT 
	--LEFT OUTER  JOIN (
	--SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType='Office' 
	--)S on S.add_cntId=CNT.cnt_internalId

	--LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state

	--inner join
	--(
	--select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from 
	-- tbl_trans_employeeCTC as cnt 
	--left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation
	--group by emp_cntId,desg.deg_designation,desg.deg_id
	--)N

	--on  N.emp_cntId=CNT.cnt_internalId
	--INNER JOIN tbl_master_user USR ON USR.user_contactId = CNT.cnt_internalId

	--WHERE N.deg_designation = @DESIGNATION AND STAT.state = @STATE AND USR.user_inactive = 'N'
	----WHERE N.deg_designation = 'AVP (Consumer Finance)' AND STAT.state = 'WEST BENGAL'

	SET @Strsql=''

	SET @Strsql+=' SELECT (CNT.cnt_firstName + '' '' + CNT.cnt_lastName) AS EmpName, CNT.cnt_internalId AS EmpCode,USR.user_loginId AS LoginID,USR.user_id AS UserID '
	SET @Strsql+='  FROM  tbl_master_contact CNT '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
	BEGIN
		SET @Strsql+=' INNER JOIN #EMPHR_EDIT HRY ON CNT.cnt_internalId=HRY.EMPCODE    '
	END
	SET @Strsql+=' LEFT OUTER  JOIN ( '
	SET @Strsql+=' SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType=''Office'' '
	SET @Strsql+=' )S on S.add_cntId=CNT.cnt_internalId '
	SET @Strsql+=' LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state '
	SET @Strsql+=' 	inner join '
	SET @Strsql+=' ( '
	SET @Strsql+=' select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from '
	SET @Strsql+=' tbl_trans_employeeCTC as cnt '
	SET @Strsql+=' left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation '
	SET @Strsql+=' group by emp_cntId,desg.deg_designation,desg.deg_id '
	SET @Strsql+=' )N '
	SET @Strsql+=' on  N.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+=' INNER JOIN tbl_master_user USR ON USR.user_contactId = CNT.cnt_internalId '
	SET @Strsql+=' WHERE N.deg_designation = '''+@DESIGNATION+''' AND STAT.state = '''+@STATE+''' AND USR.user_inactive = ''N'' '

	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql
	-- end of Rev 1.0
 END TRY 
BEGIN CATCH 
        DECLARE @ErrorMessage NVARCHAR(4000) ; 
        DECLARE @ErrorSeverity INT ; 
        DECLARE @ErrorState INT ; 
        SELECT  @ErrorMessage = ERROR_MESSAGE() , 
                @ErrorSeverity = ERROR_SEVERITY() , 
                @ErrorState = ERROR_STATE() ; 
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState) ; 
END CATCH ; 
RETURN ; 
