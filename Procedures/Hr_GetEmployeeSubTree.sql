--Exec Hr_GetEmployeeSubTree 594

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hr_GetEmployeeSubTree]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Hr_GetEmployeeSubTree] AS' 
END
GO

ALTER PROCEDURE [dbo].[Hr_GetEmployeeSubTree]
(
@empid AS INT
) WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.26		Debashis	28/02/2022		Optimized Login by User "Admin".Refer: 0024716
2.0		V2.0.39		Sanchita	21/03/2023		Dashboard optimization. Refer: 25741
****************************************************************************************************************************************************************************/
BEGIN
	Declare @EmployeeHierarchy Varchar(Max)
	
	-- Rev 2.0
	--if (isnull((Select 1 from Sys.objects Where type='U' and Name='Employees'),0)=1)
	--	Drop Table Employees
	--CREATE TABLE Employees
	--(
	--	empid Varchar(100),
	--	empcntid Varchar(100),
	--	mgrid Varchar(100)
	--);
	----Rev 1.0
	--CREATE NONCLUSTERED INDEX [IDXMGRID] ON [Employees] ([mgrid])
	----End of Rev 1.0
	
	--Insert into Employees
	--Select E.emp_id,e.emp_contactId,c.emp_reportTo from tbl_master_employee E 
	--Inner Join
	--tbl_trans_employeeCTC C
	--On E.emp_contactId=C.emp_cntId  
	--And isnull(emp_dateofLeaving,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'

	
	--;WITH Employees_Subtree(empid,empcntid,mgrid, lvl)
	--  AS
	--  ( 
	--	-- Anchor Member (AM)
	--	SELECT empid,empcntid, mgrid, 0
	--	FROM Employees
	--	WHERE empid = @empid 

	--	UNION all
	    
	--	-- Recursive Member (RM)
	--	SELECT e.empid,e.empcntid,e.mgrid, es.lvl+1
	--	FROM Employees AS e
	--	  JOIN Employees_Subtree AS es
	--		ON e.mgrid = es.empid    
	--  ) 
	
	--Select @EmployeeHierarchy = coalesce(@EmployeeHierarchy + ', ', '') + Convert(varchar,user_id) from tbl_Master_User 
	--Where user_contactId in (Select distinct empcntid FROM Employees_Subtree )
  
	--Select isnull(@EmployeeHierarchy,'')

  
	--Drop Table Employees


	IF OBJECT_ID('tempdb..#Employees') IS NOT NULL
		Drop Table #Employees
	CREATE TABLE #Employees
	(
		empid Varchar(100),
		empcntid Varchar(100),
		mgrid Varchar(100)
	);
	CREATE NONCLUSTERED INDEX [IDXMGRID] ON [#Employees] ([mgrid])
	
	Insert into #Employees
	Select E.emp_id,e.emp_contactId,c.emp_reportTo from tbl_master_employee E 
	Inner Join
	tbl_trans_employeeCTC C
	On E.emp_contactId=C.emp_cntId  
	And isnull(emp_dateofLeaving,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'

	
	;WITH Employees_Subtree(empid,empcntid,mgrid, lvl)
	  AS
	  ( 
		-- Anchor Member (AM)
		SELECT empid,empcntid, mgrid, 0
		FROM #Employees
		WHERE empid = @empid 

		UNION all
	    
		-- Recursive Member (RM)
		SELECT e.empid,e.empcntid,e.mgrid, es.lvl+1
		FROM #Employees AS e
		  JOIN Employees_Subtree AS es
			ON e.mgrid = es.empid    
	  ) 
	Select @EmployeeHierarchy = coalesce(@EmployeeHierarchy + ', ', '') + Convert(varchar,user_id) from tbl_Master_User 
	Where user_contactId in (Select distinct empcntid FROM Employees_Subtree )

	Select isnull(@EmployeeHierarchy,'')

	Drop Table #Employees
	-- End of Rev 1.0

END