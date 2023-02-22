IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_EmployeeUserInsertFromExcel]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_EmployeeUserInsertFromExcel] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_EmployeeUserInsertFromExcel]
(
@ImportEmployee UDT_ImportEmployeeData READONLY,
-- Rev 1.0	
--@ImportEmployee UDT_ImportEmployee READONLY,
--@ImportUser UDT_ImportUser READONLY,
@FileName VARCHAR(200)=NULL,
-- Rev 1.0 End
@CreateUser_Id BIGINT
)
AS
/*****************************************************************************************************************
Rev 1.0		Priti	v2.0.39		20-02-2023	 	0025676: Employee Import Facility
*******************************************************************************************************************/
BEGIN

	-- Rev 1.0	
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'TEMPEmployeeData') AND TYPE IN (N'U'))
		BEGIN
			Create table TEMPEmployeeData
			(	EmpCode Nvarchar(500),
				EmpName Nvarchar(500),
				Salutation Nvarchar(50),
				FirstName Nvarchar(500),
				MiddleName Nvarchar(500),
				LastName Nvarchar(500),
				Gender Nvarchar(50),
				DateOfJoining Datetime,
				Organization Nvarchar(500),
				JobResponsibility Nvarchar(500),
				Branch Nvarchar(500),
				Designation Nvarchar(500),
				EmployeeType Nvarchar(500),
				Department Nvarchar(500),
				PersonalMobile Nvarchar(500),
				Supervisor Nvarchar(500),
				UserGroup Nvarchar(500)
			)
		
	END
	-- Rev 1.0 End

	INSERT INTO TEMPEmployeeData 
	SELECT * FROM @ImportEmployee where EmpCode is not NULL

	-- Rev 1.0 
	--INSERT INTO Employee_Data 
	--SELECT * FROM @ImportEmployee where EmpCode is not NULL

	--INSERT INTO User_Data 
	--SELECT * FROM @ImportUser where [EmpCode] is not NULL

	--EXEC PRC_EmployeeUserImport

	EXEC PRC_EmployeeUserImportFromExcel @CreateUser_Id ,@FileName
	-- Rev 1.0 End
END