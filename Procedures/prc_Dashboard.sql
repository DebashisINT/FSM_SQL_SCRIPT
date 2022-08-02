

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_Dashboard]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_Dashboard] AS' 
END
GO


ALTER PROC [dbo].[prc_Dashboard]
(
	@DASHBOARDACTION NVARCHAR(MAX),  
	@DASHBOARDGRIDVIEWFILTERNAME VARCHAR(250) = NULL,
	@USERID INT = 0
	-- Rev 1.0
	, @STATEIDLIST nvarchar(max) = ''
	-- End of Rev 1.0
)
AS
/********************************************************************************************
1.0		V2.0.29		Sanchita	08-03-2022		FSM - Portal: Branch selection required against the selected 'State'. Refer: 24729
2.0		V2.0.32		Sanchita	02-08-2022		Dashboard Data shall be showing based on Assign [Single/Multiple] Branch in Employee [Master Mapping]
												Refer: 25102
*********************************************************************************************/ 
    SET NOCOUNT ON ;
    BEGIN TRY 
	DECLARE @i_intTempID INT	= 0;

	IF @DASHBOARDACTION = 'DashboardGridView'
	BEGIN

		IF @DASHBOARDGRIDVIEWFILTERNAME = 'AT_WORK'
		BEGIN
			SELECT EMPNAME [Employee],DESIGNATION [Designation],ISNULL(CONTACTNO,'') [Mobile No.],LOGGEDIN [In Time],CURRENT_STATUS [Current Status],ISNULL(GPS_INACTIVE_DURATION,'00:00') +' (HH:MM)' [GPS Inactivity],ISNULL(SHOPS_VISITED,0) [Shops Visited],ISNULL(TOTAL_ORDER_BOOKED_VALUE,'0.00') [Order Value],ISNULL(TOTAL_COLLECTION,'0.00') [Collection Amt.],EMPCODE EMPID
			from FTSDASHBOARD_REPORT where USERID=@USERID and ACTION= @DASHBOARDGRIDVIEWFILTERNAME order by SHOPS_VISITED DESC
		END
		
	END
	IF @DASHBOARDACTION = 'DashboardStateList'
	BEGIN
	DECLARE @TEMPSTATE_ID INT = NULL
	(SELECT TOP 1 @TEMPSTATE_ID = STATE_ID FROM FTS_EMPSTATEMAPPING WHERE [USER_ID] = @USERID)
		--PRINT @TEMPSTATE_ID;
		IF @USERID > 0 
		BEGIN 
			--IF ((SELECT COUNT(*) FROM FTS_EMPSTATEMAPPING WHERE [USER_ID] = @USERID) > 0 AND ((SELECT TOP 1 STATE_ID FROM FTS_EMPSTATEMAPPING WHERE [USER_ID] = @USERID) <> 0))
			IF (@TEMPSTATE_ID = 0)
			BEGIN
				--SELECT ID, [Name] FROM (SELECT '' ID , 'All' [Name] Union all (SELECT '999999' ID , 'Undefined' [Name] Union all SELECT CAST(id as varchar(20)),state [name] FROM TBL_MASTER_STATE WHERE ID IN (SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM'))) TM INNER JOIN FTS_EMPSTATEMAPPING TSID ON TM.ID = CAST(TSID.STATE_ID as varchar(200))
				--SELECT ID, [Name] FROM (SELECT '' ID , 'All' [Name] Union all SELECT CAST(id as varchar(20)),state [name] FROM TBL_MASTER_STATE WHERE ID IN (SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM')) TM INNER JOIN FTS_EMPSTATEMAPPING TSID ON TM.ID = CAST(TSID.STATE_ID as varchar(200))
				--WHERE TSID.[USER_ID] = @USERID
				

				SELECT CAST(id as varchar(20)) ID,state [name] FROM TBL_MASTER_STATE WHERE ID IN (SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM' AND add_addressType = 'Office');	
			END
			ELSE
			BEGIN
				SELECT ID, [Name] FROM 
				(SELECT CAST(id as varchar(20)) ID,state [name] FROM TBL_MASTER_STATE WHERE ID IN 
				(SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM' AND add_addressType = 'Office')
				) TM INNER JOIN FTS_EMPSTATEMAPPING TSID ON TM.ID = CAST(TSID.STATE_ID as varchar(200))
				WHERE TSID.[USER_ID] = @USERID
			END
		END
		ELSE 
		BEGIN
			--SELECT '' ID , 'All' [Name] Union all (SELECT '999999' ID , 'Undefined' [Name] Union all SELECT CAST(id as varchar(20)),state [name] FROM TBL_MASTER_STATE WHERE ID IN (SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM'));
			SELECT CAST(id as varchar(20)) ID,state [name] FROM TBL_MASTER_STATE WHERE ID IN (SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM' AND add_addressType = 'Office');
		END
	END
	-- Rev 1.0
	IF @DASHBOARDACTION = 'DashboardBranchList'
	BEGIN
		-- Rev 2.0
		DECLARE @Contact_CNT_ID int
		set @Contact_CNT_ID = (select top 1 C.cnt_id from tbl_master_contact C inner join tbl_master_user U on C.cnt_internalid=U.user_contactId where U.user_id=@USERID)
		-- End of Rev 2.0

		if(@STATEIDLIST is null or @STATEIDLIST='')
		begin
			DECLARE @TEMPSTATE_ID1 INT = NULL
			(SELECT TOP 1 @TEMPSTATE_ID1 = STATE_ID FROM FTS_EMPSTATEMAPPING WHERE [USER_ID] = @USERID)
			
			IF @USERID > 0 
			BEGIN 
				IF (@TEMPSTATE_ID1 = 0)
				BEGIN
					SELECT CAST(branch_id as varchar(20)) ID,branch_code [name] FROM tbl_master_branch B where branch_state in 
					(SELECT id FROM TBL_MASTER_STATE WHERE ID IN (SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM' AND add_addressType = 'Office'))
					-- Rev 2.0
					and exists (select Branchid from FTS_EmployeeBranchMap where EmployeeId=@Contact_CNT_ID and Branchid=B.branch_id)
					-- End of Rev 2.0	
				END
				ELSE
				BEGIN
					SELECT CAST(branch_id as varchar(20)) ID,branch_code [name] FROM tbl_master_branch B where branch_state in 
					(SELECT id FROM 
					(SELECT id FROM TBL_MASTER_STATE WHERE ID IN 
					(SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM' AND add_addressType = 'Office')
					) TM INNER JOIN FTS_EMPSTATEMAPPING TSID ON TM.ID = CAST(TSID.STATE_ID as varchar(200))
					WHERE TSID.[USER_ID] = @USERID)
					-- Rev 2.0
					and exists (select Branchid from FTS_EmployeeBranchMap where EmployeeId=@Contact_CNT_ID and Branchid=B.branch_id)
					-- End of Rev 2.0
				END
			END
			ELSE 
			BEGIN
				SELECT CAST(branch_id as varchar(20)) ID,branch_code [name] FROM tbl_master_branch B where branch_state in 
				(SELECT id FROM TBL_MASTER_STATE WHERE ID IN (SELECT DISTINCT ADD_STATE FROM TBL_MASTER_ADDRESS TMA INNER JOIN tbl_master_contact TMC ON TMC.cnt_internalId = TMA.add_cntId AND cnt_contactType='EM' AND add_addressType = 'Office'))
				-- Rev 2.0
				and exists (select Branchid from FTS_EmployeeBranchMap where EmployeeId=@Contact_CNT_ID and Branchid=B.branch_id)
				-- End of Rev 2.0
			END
		END
		ELSE
		BEGIN
			SET @STATEIDLIST = ''''+ REPLACE(@STATEIDLIST,',',' '','' ') + ''''
			DECLARE @sqlQuery NVARCHAR(MAX)
			SET @sqlQuery = 'SELECT CAST(branch_id as varchar(20)) ID,branch_code [name] FROM tbl_master_branch B where branch_state IN ('+@STATEIDLIST+')'
			-- Rev 2.0
			SET @sqlQuery = @sqlQuery + ' and exists (select Branchid from FTS_EmployeeBranchMap where EmployeeId='+convert(varchar(10),@Contact_CNT_ID)+' and Branchid=B.branch_id) '
			-- End of Rev 2.0
			Exec sp_executesql @sqlQuery
		END

	END
	-- End of Rev 1.0		

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
GO