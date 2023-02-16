IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_UserNameSearchForListing]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_UserNameSearchForListing] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_UserNameSearchForListing]  
(
@USER_ID BIGINT=0,
@SearchKey varchaR(50) =''
)  
AS
/*******************************************************************************************************************************************************************************************
Written by Sanchita for		V2.0.39		on	16/02/2023
A setting required for Employee and User Master module in FSM Portal. Refer: 25668
********************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
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
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
		
			select top(10) U.user_id,Replace(U.user_name,'''','&#39;') as user_name,U.user_loginId,E.emp_uniqueCode AS EmployeeID from tbl_Master_user U
			INNER JOIN #EMPHR_EDIT ON user_contactId=EMPCODE
			INNER JOIN tbl_master_employee E ON E.emp_contactId = U.user_contactId
			where user_group is not null and ((U.user_name like '%'+@SearchKey+'%') or  (U.user_loginId like '%'+@SearchKey+'%')
					or  (E.emp_uniqueCode like '%'+@SearchKey+'%'))
			
			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END
	ELSE
		BEGIN
			select top(10)U.user_id,Replace(U.user_name,'''','&#39;') as user_name,U.user_loginId,E.emp_uniqueCode AS EmployeeID from tbl_Master_user U
			INNER JOIN tbl_master_employee E ON E.emp_contactId = U.user_contactId
			where user_group is not null and ((U.user_name like '%'+@SearchKey+'%') or  (U.user_loginId like '%'+@SearchKey+'%')
				or  (E.emp_uniqueCode like '%'+@SearchKey+'%'))
			
		END
END