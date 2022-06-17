IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_EmployeesTargetSetting_InsertUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_EmployeesTargetSetting_InsertUpdate] AS' 
END
GO

ALTER PROC [dbo].[prc_EmployeesTargetSetting_InsertUpdate]
(
@EMPLOYEETARGETSETTINGID BIGINT ,
@FKEMPLOYEESTARGETSETTINGEMPTYPEID INT,
@FKEMPLOYEESCOUNTERTYPE INT = 4,
@EMPLOYEECODE VARCHAR(50),
@SETTINGMONTH INT,
@SETTINGYEAR INT,
@ORDERVALUE DECIMAL(18,2),
@NEWCOUNTER INT,
@COLLECTION DECIMAL(18,2),
@REVISIT INT
)
AS 
/*****************************************************************************************************
1.0			Sanchita	V2.0.30		08/06/2022		New column STAGE_ID added in table tbl_FTS_EmployeesTargetSetting but not taken care of here
													Refer: 
*****************************************************************************************************/
SET NOCOUNT ON ;
BEGIN TRY 
	DECLARE @SUCCESS BIT = 0;
	DECLARE @TEMP VARCHAR(200) ='';
	DECLARE @FROMDATE DATETIME = GETDATE();
	DECLARE @TODATE DATETIME = GETDATE();

	IF @EMPLOYEECODE IS NOT NULL AND @EMPLOYEECODE <> ''
	BEGIN
		SELECT @EMPLOYEETARGETSETTINGID = EmployeeTargetSettingID FROM tbl_FTS_EmployeesTargetSetting WHERE EmployeeCode = @EMPLOYEECODE AND SettingMonth = @SETTINGMONTH AND SettingYear = @SETTINGYEAR; --AND FKEmployeesTargetSettingEmpTypeID = @FKEMPLOYEESTARGETSETTINGEMPTYPEID AND FKEmployeesCounterType = @FKEMPLOYEESCOUNTERTYPE;
	 
		IF @EMPLOYEETARGETSETTINGID = 0
		BEGIN
			SET @TEMP = CONVERT(varchar(200),(CAST(@SETTINGYEAR as varchar(10)) + '-' + CAST(@SETTINGMONTH as varchar(10)) + '-1' ));
			SET @FROMDATE = DATEADD(month, DATEDIFF(month, 0, @TEMP), 0);
			SET @TODATE =DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, @TEMP) + 1, 0)) ;

			-- Rev 1.0
			--INSERT INTO tbl_FTS_EmployeesTargetSetting VALUES(@FKEMPLOYEESTARGETSETTINGEMPTYPEID, @EMPLOYEECODE,@SETTINGMONTH,@SETTINGYEAR,@ORDERVALUE,@NEWCOUNTER,@REVISIT,@COLLECTION,GETDATE(),GETDATE(),@FROMDATE,@TODATE,@FKEMPLOYEESCOUNTERTYPE);
			INSERT INTO tbl_FTS_EmployeesTargetSetting VALUES(@FKEMPLOYEESTARGETSETTINGEMPTYPEID, @EMPLOYEECODE,@SETTINGMONTH,@SETTINGYEAR,@ORDERVALUE,@NEWCOUNTER,@REVISIT,@COLLECTION,GETDATE(),GETDATE(),@FROMDATE,@TODATE,@FKEMPLOYEESCOUNTERTYPE,0);
			-- End of Rev Sanchita

			SET @EMPLOYEETARGETSETTINGID = SCOPE_IDENTITY();
			SET @SUCCESS = 1;
			--select * from tbl_FTS_EmployeesTargetSetting
		END	
		ELSE
		BEGIN
			UPDATE tbl_FTS_EmployeesTargetSetting SET OrderValue = @ORDERVALUE,
			FKEmployeesTargetSettingEmpTypeID = @FKEMPLOYEESTARGETSETTINGEMPTYPEID,
			FKEmployeesCounterType  = @FKEMPLOYEESCOUNTERTYPE,
			NewCounter = @NEWCOUNTER,
			[Collection] = @COLLECTION,
			Revisit = @REVISIT,
			ModifiedDate = GETDATE()
			WHERE EmployeeTargetSettingID = @EMPLOYEETARGETSETTINGID

			SET @SUCCESS = 1;
		END

	END

	SELECT @SUCCESS AS Success, @EMPLOYEETARGETSETTINGID AS EmployeeTargetSettingID

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
