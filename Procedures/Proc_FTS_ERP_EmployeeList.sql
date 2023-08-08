IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_ERP_EmployeeList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_ERP_EmployeeList] AS' 
END
GO

ALTER proc [dbo].[Proc_FTS_ERP_EmployeeList]
@Action varchar(50)=NULL,
@userid int=null,
-- Rev 2.0
@SearchKey varchaR(50) =''
-- End of Rev 2.0
As
/***************************************************************************************************************************************
	1.0		26-08-2021		Tanmoy		Column Name change
	2.0		08-08-2023		Sanchita	FSM - Masters - Organization - Employees - Change Supervisor should be On Demand Search. Mantis: 26700
***************************************************************************************************************************************/
Begin
	-- Rev 2.0
	DECLARE @strCmd NVARCHAR(MAX)
	-- End of Rev 2.0

	--Rev 1.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
	--End of Rev 1.0
	BEGIN
		if(@Action='Past')
		BEGIN
			-- Rev 2.0
			--select DISTINCT emp.emp_id as Id,cont.cnt_firstName +' '+ cont.cnt_lastName as Name from tbl_master_contact  as cont
			--INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId 
			--INNER JOIN FTS_EmployeeShopMap MAP ON cont.cnt_internalId=MAP.EMP_INTERNALID
			--where cont.cnt_internalId not in('EMK0000010','EMB0000002')
			--AND MAP.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID=@userid)
			
			SET @strCmd = ''
			SET @strCmd = 'select DISTINCT top(10) emp.emp_id as Id,cont.cnt_firstName +'' ''+ cont.cnt_lastName as Name, cnt_UCC from tbl_master_contact  as cont '
			SET @strCmd += 'INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId '
			SET @strCmd += 'INNER JOIN FTS_EmployeeShopMap MAP ON cont.cnt_internalId=MAP.EMP_INTERNALID '
			SET @strCmd += 'where cont.cnt_internalId not in(''EMK0000010'',''EMB0000002'') '
			SET @strCmd += 'AND MAP.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID='+cast(@userid as varchar(50))+') '
			IF @SearchKey <>''
			BEGIN
				SET @strCmd += 'AND ( (cont.cnt_firstName like ''%'+ @SearchKey +'%'') or  (cont.cnt_middleName like ''%'+ @SearchKey +'%'') or  (cont.cnt_lastName like ''%'+ @SearchKey +'%'') '
				SET @strCmd += '	or (cont.cnt_UCC like ''%'+ @SearchKey +'%'') )'
			END
			EXEC (@strCmd)
			-- End of Rev 2.0
		END
		ELSE if(@Action='New')
		BEGIN
			-- Rev 2.0
			--select emp.emp_id as Id,cont.cnt_firstName +' '+ cont.cnt_lastName as Name from tbl_master_contact  as cont
			--INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId
			--INNER JOIN FTS_EmployeeShopMap MAP ON cont.cnt_internalId=MAP.EMP_INTERNALID
			--where MAP.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID=@userid)

			SET @strCmd = ''
			SET @strCmd = 'select top(10) emp.emp_id as Id,cont.cnt_firstName +'' ''+ cont.cnt_lastName as Name, cnt_UCC from tbl_master_contact  as cont '
			SET @strCmd += 'INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId '
			SET @strCmd += 'INNER JOIN FTS_EmployeeShopMap MAP ON cont.cnt_internalId=MAP.EMP_INTERNALID '
			SET @strCmd += 'where MAP.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID='+cast(@userid as varchar(50))+') '
			IF @SearchKey <>''
			BEGIN
				SET @strCmd += 'AND ( (cont.cnt_firstName like ''%'+ @SearchKey +'%'') or  (cont.cnt_middleName like ''%'+ @SearchKey +'%'') or  (cont.cnt_lastName like ''%'+ @SearchKey +'%'') '
				SET @strCmd += '	or (cont.cnt_UCC like ''%'+ @SearchKey +'%'') ) '
			END
			EXEC (@strCmd)
			-- End of Rev 2.0
		END
		else
		BEGIN
			-- Rev 2.0
			--select emp.emp_id as Id,cont.cnt_firstName +' '+ cont.cnt_lastName as Name from tbl_master_contact  as cont
			--INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId
			--INNER JOIN FTS_EmployeeShopMap MAP ON cont.cnt_internalId=MAP.EMP_INTERNALID
			--where MAP.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID=@userid)

			SET @strCmd = ''
			SET @strCmd = 'select emp.emp_id as Id,cont.cnt_firstName +'' ''+ cont.cnt_lastName as Name, cnt_UCC from tbl_master_contact  as cont '
			SET @strCmd += 'INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId '
			SET @strCmd += 'INNER JOIN FTS_EmployeeShopMap MAP ON cont.cnt_internalId=MAP.EMP_INTERNALID '
			SET @strCmd += 'where MAP.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID='+cast(@userid as varchar(50))+') '
			IF @SearchKey <>''
			BEGIN
				SET @strCmd += 'AND ( (cont.cnt_firstName like ''%'+ @SearchKey +'%'') or  (cont.cnt_middleName like ''%'+ @SearchKey +'%'') or  (cont.cnt_lastName like ''%'+ @SearchKey +'%'') '
				SET @strCmd += '	or (cont.cnt_UCC like ''%'+ @SearchKey +'%'') ) '
			END
			EXEC (@strCmd)
			-- End of Rev 2.0
		END
	END
	ELSE
	BEGIN
		if(@Action='Past')
			-- Rev 2.0
			--select emp.emp_id as Id,cont.cnt_firstName +' '+ cont.cnt_lastName as Name from tbl_master_contact  as cont
			--INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId 
			--where cont.cnt_internalId not in('EMK0000010','EMB0000002')
			BEGIN	
				SET @strCmd = ''
				SET @strCmd = 'select top(10) emp.emp_id as Id,cont.cnt_firstName +'' ''+ cont.cnt_lastName as Name, cnt_UCC from tbl_master_contact  as cont '
				SET @strCmd += 'INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId '
				SET @strCmd += 'where cont.cnt_internalId not in(''EMK0000010'',''EMB0000002'') '
				IF @SearchKey <>''
				BEGIN
					SET @strCmd += 'AND ( (cont.cnt_firstName like ''%'+ @SearchKey +'%'') or  (cont.cnt_middleName like ''%' + @SearchKey + '%'') or  (cont.cnt_lastName like ''%' + @SearchKey + '%'') '
					SET @strCmd += '	or (cont.cnt_UCC like ''%' + @SearchKey + '%'') ) '
				END
				--select @strCmd
				EXEC (@strCmd)
			END
			-- End of Rev 2.0
		ELSE if(@Action='New')
			-- Rev 2.0
			--select emp.emp_id as Id,cont.cnt_firstName +' '+ cont.cnt_lastName as Name from tbl_master_contact  as cont
			--INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId
			BEGIN
				SET @strCmd = ''
				SET @strCmd = 'select top(10) emp.emp_id as Id,cont.cnt_firstName +'' ''+ cont.cnt_lastName as Name, cnt_UCC from tbl_master_contact  as cont '
				SET @strCmd += 'INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId '
				IF @SearchKey <>''
				BEGIN
					SET @strCmd += 'WHERE ( (cont.cnt_firstName like ''%'+ @SearchKey +'%'') or  (cont.cnt_middleName like ''%'+ @SearchKey +'%'') or  (cont.cnt_lastName like ''%'+ @SearchKey +'%'') '
					SET @strCmd += '	or (cont.cnt_UCC like ''%'+ @SearchKey +'%'') ) '
				END
				EXEC (@strCmd)
			END
			-- End of Rev 2.0
		else
		BEGIN
			-- Rev 2.0
			--select emp.emp_id as Id,cont.cnt_firstName +' '+ cont.cnt_lastName as Name from tbl_master_contact  as cont
			--INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId

			SET @strCmd = ''
			SET @strCmd = 'select emp.emp_id as Id,cont.cnt_firstName +'' ''+ cont.cnt_lastName as Name, cnt_UCC from tbl_master_contact  as cont '
			SET @strCmd += 'INNER JOIN tbl_master_employee as emp on cont.cnt_internalId=emp.emp_contactId '
			IF @SearchKey <>''
			BEGIN
				SET @strCmd += 'AND ( (cont.cnt_firstName like ''%'+ @SearchKey +'%'') or  (cont.cnt_middleName like ''%'+ @SearchKey +'%'') or  (cont.cnt_lastName like ''%'+ @SearchKey +'%'') '
				SET @strCmd += '	or (cont.cnt_UCC like ''%'+ @SearchKey +'%''))  '
			END
			EXEC (@strCmd)
			-- End of Rev 2.0
		END
	END
END