IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_TASKMANAGEMENT]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_TASKMANAGEMENT] AS'  
 END 
 GO 

ALTER PROCEDURE [dbo].[PRC_TASKMANAGEMENT]
(
	@USERID INT =NULL,
	@ACTION_TYPE VARCHAR(20)= NULL,
	@STARTDATE datetime =NULL,
	@DUETDATE datetime =NULL,
	@Task_Name NVARCHAR(300) =NULL,
	@Priority BIGINT=0,
	@Task_Details NVARCHAR(20) =NULL,	
	@SALESMANID nvarchar(10)=NULL,
	@TASK_ID BIGINT=0,
	@RETURNMESSAGE NVARCHAR(500) =NULL OUTPUT ,
	@RETURNCODE NVARCHAR(20) =NULL OUTPUT,
	@Task_IDS NVARCHAR(Max) =NULL
)
 
AS
/****************************************************************************************************************************************************************************
Written by : PRITI on 08-05-2023. Refer: 
0026031:Copy the current Enquiry page, and create a duplicate and name it as 'Task Management'
0026032: Customization in Task Management Page
0026034: Customization in Add Task Page 
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	IF(@ACTION_TYPE='ADD')
	BEGIN
			BEGIN TRY
			BEGIN TRANSACTION	
				
				insert into MASTER_TASKMANAGEMENT(TASK_STARTDATE,TASK_DUEDATE,TASK_NAME,TASK_PRIORITY,TASK_DETAILS,CREATEDBY,CREATEDON)
				values( CONVERT(DATETIME,CONVERT(VARCHAR(15),CAST(@STARTDATE as date),120)+' '+CONVERT(VARCHAR(15),CAST(GETDATE() AS TIME),108)) ,
				CONVERT(DATETIME,CONVERT(VARCHAR(15),CAST(@DUETDATE as date),120)+' '+CONVERT(VARCHAR(15),CAST(GETDATE() AS TIME),108)) ,
				@Task_Name,@Priority,@Task_Details,@USERID,getdate()
				)

				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Success';
				Set @RETURNCODE='1'

			END TRY

			BEGIN CATCH

			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	END	
	ELSE IF(@ACTION_TYPE='EDIT') 
	BEGIN
			select TASK_ID,CONVERT(VARCHAR(10),TASK_STARTDATE,120)TASK_STARTDATE,CONVERT(VARCHAR(10),TASK_DUEDATE,120)TASK_DUEDATE,TASK_NAME,TASK_PRIORITY,TASK_DETAILS,TASK_SALESMANASSIGNID,TASK_SMANASSIGNDATE,TASK_SALESMANASSIGNBY,TASK_SALESMANREASSIGNID
			,TASK_SMANREASSIGNDATE,TASK_SALESMANREASSIGNBY,TASK_STATUS,TASK_ISDELETED,CREATEDBY,CREATEDON,UPDATEDBY
			,UPDATEDON from MASTER_TASKMANAGEMENT where TASK_ID=@TASK_ID
	END
	ELSE IF(@ACTION_TYPE='MOD') 
	BEGIN
			BEGIN TRY
			BEGIN TRANSACTION		
				
				update MASTER_TASKMANAGEMENT set TASK_STARTDATE=CONVERT(DATETIME,CONVERT(VARCHAR(15),CAST(@STARTDATE as date),120)+' '+CONVERT(VARCHAR(15),CAST(GETDATE() AS TIME),108)),
				TASK_DUEDATE=CONVERT(DATETIME,CONVERT(VARCHAR(15),CAST(@DUETDATE as date),120)+' '+CONVERT(VARCHAR(15),CAST(GETDATE() AS TIME),108)),				
				TASK_NAME=@Task_Name,TASK_PRIORITY=@Priority,TASK_DETAILS=@Task_Details
				,UPDATEDBY=@USERID,
				UPDATEDON=getdate()
				where TASK_ID=@TASK_ID

				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Success';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	END
	ELSE IF(@ACTION_TYPE='DELETE') 
	BEGIN
			BEGIN TRY
			BEGIN TRANSACTION		
				update MASTER_TASKMANAGEMENT set TASK_ISDELETED=1 where TASK_ID=@TASK_ID
				delete FTSTASKMANAGEMENTDETAIL where TASK_ID=@TASK_ID
				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Deleted';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	END
	--ELSE IF(@ACTION_TYPE='RESTORE') 
	--		BEGIN TRY
	--		BEGIN TRANSACTION		
	--			update tbl_CRM_Import set Is_deleted=0 where Crm_Id=@CRM_ID
	--			COMMIT TRANSACTION

	--			Set @RETURNMESSAGE= 'Restored';
	--			Set @RETURNCODE='1'

	--		END TRY
	--		BEGIN CATCH
	--		ROLLBACK TRANSACTION
			
	--			Set @RETURNMESSAGE= ERROR_MESSAGE();
	--			Set @RETURNCODE='-10'
	
	--		END CATCH
	--ELSE IF(@ACTION_TYPE='PERMANENTDELETE') 
	--		BEGIN TRY
	--		BEGIN TRANSACTION		
	--			DELETE FROM tbl_CRM_Import where Crm_Id=@CRM_ID  and  Is_deleted=1
	--			COMMIT TRANSACTION

	--			Set @RETURNMESSAGE= 'PDeleted';
	--			Set @RETURNCODE='1'

	--		END TRY
	--		BEGIN CATCH
	--		ROLLBACK TRANSACTION
			
	--			Set @RETURNMESSAGE= ERROR_MESSAGE();
	--			Set @RETURNCODE='-10'
	
	--		END CATCH
	--ELSE IF(@ACTION_TYPE='MASSDELETE') 
	--		BEGIN TRY
	--		BEGIN TRANSACTION	
					
			
	--			select * into #tempmassdel FROM DBO.GETSPLIT('|',@CRM_IDS)
	--			--select s from #tempmassdel
	--			update tbl_CRM_Import set Is_deleted=1 where Crm_Id in(select s from #tempmassdel where s<>'')

	--			COMMIT TRANSACTION

	--			Set @RETURNMESSAGE= 'Deleted';
	--			Set @RETURNCODE='1'

	--		END TRY
	--		BEGIN CATCH
	--		ROLLBACK TRANSACTION
			
	--			Set @RETURNMESSAGE= ERROR_MESSAGE();
	--			Set @RETURNCODE='-10'
	
	--		END CATCH
	ELSE IF(@ACTION_TYPE='BULKASSIGN' and @SALESMANID is not null and @SALESMANID<>'0')
	Begin
			BEGIN TRY
			BEGIN TRANSACTION	
					
				select * into #tempBulkAssign FROM DBO.GETSPLIT('|',@Task_IDS)
				
				update MASTER_TASKMANAGEMENT set TASK_SALESMANASSIGNID=@SALESMANID, TASK_SMANASSIGNDATE=getdate() where TASK_ID in(select s from #tempBulkAssign where s<>'')

				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Success';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	End
	ELSE IF(@ACTION_TYPE='CHECKASSIGNSALESMAN') 
		begin
			DECLARE @CNT INT = (SELECT COUNT(0) FROM MASTER_TASKMANAGEMENT WHERE TASK_ID=@TASK_ID and TASK_SALESMANASSIGNID is not NULL and TASK_SALESMANASSIGNID<>0)
			IF @CNT>0
			BEGIN
				Set @RETURNMESSAGE= 'Exist';
				Set @RETURNCODE='-1'
			END
			ELSE
			BEGIN
				Set @RETURNMESSAGE= 'NotExist';
				Set @RETURNCODE='1'
			END
		end
	--	--rev 1.0
		ELSE IF(@ACTION_TYPE='OldAssignedSalesMan') 
		begin
			SELECT user_name,user_id FROM MASTER_TASKMANAGEMENT as TCM(nolock)
			inner join tbl_master_user as TMU(nolock) on TCM.TASK_SALESMANASSIGNID=TMU.user_id
			WHERE TASK_ID=@TASK_ID
		end
		
	--	--End of rev 1.0
	--	--rev 2.0
		ELSE IF(@ACTION_TYPE='ReBULKASSIGN' and @SALESMANID is not null and @SALESMANID<>'0') 
		Begin
			BEGIN TRY
			BEGIN TRANSACTION	
					
				select * into #tempBulkReAssign FROM DBO.GETSPLIT('|',@Task_IDS)
				
				update MASTER_TASKMANAGEMENT set TASK_SALESMANREASSIGNID=@SALESMANID, TASK_SMANREASSIGNDATE=getdate() where TASK_ID in(select s from #tempBulkReAssign where s<>'')

				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Success';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
		End
	--	--End of rev 2.0

	ELSE if(@ACTION_TYPE='GetTaskPriority')
	begin
		SELECT cast(TASKPRIORITY_ID as varchar)TASKPRIORITY_ID, TASKPRIORITY_FROM TaskPriorityDesc from MASTER_TASKPRIORITY order by TASKPRIORITY_ID
	end

	ELSE if(@ACTION_TYPE='GetSalesmanlist')
	begin
		SELECT '0' AS UserID,'Select' AS username
		UNION ALL
		select convert(nvarchar(10),U.user_id) as UserID ,user_name+ ' ('+ E.emp_uniqueCode +')' as username 
		from tbl_master_user U inner join tbl_master_employee E ON U.user_contactid = E.emp_contactid
		WHERE user_inactive='N' order by UserID
	end
	SET NOCOUNT OFF
END
go