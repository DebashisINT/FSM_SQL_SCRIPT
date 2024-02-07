IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_DeleteContactTypeEmplyeeMapping]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_DeleteContactTypeEmplyeeMapping] AS' 
END
GO

ALTER PROCEDURE [dbo].[prc_DeleteContactTypeEmplyeeMapping]
 @cnt_internalId nvarchar(20)=null
 
 AS
BEGIN
	BEGIN TRY
		DELETE tbl_trans_EmployeeTypeMapping WHERE Emp_EmpInternalId = @cnt_internalId
		return 1
	END TRY

	BEGIN CATCH
		return -1
	END CATCH
End






