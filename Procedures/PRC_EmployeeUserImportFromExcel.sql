IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_EmployeeUserImportFromExcel]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_EmployeeUserImportFromExcel] AS'  
 END 
 GO


ALTER PROCEDURE [dbo].[PRC_EmployeeUserImportFromExcel]
(
@CreateUser_Id BIGINT=0,
@FileName VARCHAR(200)=NULL
)
AS
/*****************************************************************************************************************
Written by : Priti Roy ON 20/02/2023
Module	   : Employee  Master Refer: 0025676
Rev 1.0		Priti	V2.0.49		01-10-2024	 0027734: Employee Master Import
*******************************************************************************************************************/
BEGIN
	declare @emplcode varchar(50)=null,
	@empname varchar(500)=null,
	@salutation varchar(500)='Mr',
	@firstname varchar(500)=null,
	@lastname varchar(500)=null,
	@middle varchar(500)=null,
	@dob datetime=null,
	@doj datetime=null,
	@gender varchar(500)='M',
	@grade varchar(500)=null,
	@blood_group varchar(500)=null,
	@marital_status varchar(500)=null,
	@organisation varchar(500)=null,
	@jobres varchar(500)=null,
	@deg varchar(500)=null,
	@emp_type varchar(500)=null,
	@branch varchar(500)=null,
	@department varchar(500)=null,
	@mobile float=null,
	@personalmobile varchar(500)=null,
	@Group NVARCHAR(500)=null,
	@Supervisor varchar(500)=null,
	@emptpy_id int=0	
	DECLARE @USERID BIGINT
	DECLARE @shop_typeId INT = ( select TOP 1 shop_typeId from tbl_shoptype where Name='shop' ) -- shop_typeId=1
	DECLARE @StateId int=0,@OrganisationId int=0
	DECLARE @USER_NAME VARCHAR(200),@USER_LOGINID float,@USER_GROUP VARCHAR(10)
	set @lastname =''
	set @middle =''
	

	declare db_cursor cursor for

	SELECT EmpCode ,EmpName ,Salutation ,FirstName ,MiddleName ,LastName ,Gender ,DateOfJoining ,Organization ,JobResponsibility ,Branch ,Designation ,EmployeeType ,Department ,
	PersonalMobile ,Supervisor,UserGroup FROM TEMPEmployeeData
	open db_cursor
	fetch next from db_cursor into @emplcode,@empname,@salutation,@firstname,@middle,@lastname,@gender,@doj,@organisation,@jobres,@branch,@deg,@emp_type,@department	
	,@personalmobile,@Supervisor,@Group
	while @@FETCH_STATUS=0
	begin
		 Declare @loopNumber int=0
		 set @loopNumber=1
		if(Isnull(@emplcode,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Code can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@salutation,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Salutation can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@firstname,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee first name can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@gender,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed','','Employee Gender can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@doj,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Date Of Joining can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		else if(Isnull(@organisation,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Organization can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@jobres,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Job Responsibility can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@branch,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Branch can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@deg,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Designation can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@emp_type,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Type can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@department,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Department can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@personalmobile,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee mobile number can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@Supervisor,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee Report To can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else if(Isnull(@Group,''))=''
		Begin
				insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
				values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee group can not be blank',@CreateUser_Id,GETDATE(),0)
		END
		Else
		Begin
			declare @sal_id int =(case @salutation when 'Mr' then 1 when 'Mr.' then 1 when 'Mrs' then 2 when 'Mrs.' then 2 when 'Ms' then 3 when 'Ms.' then 3 end)		
		declare @gen_id int =(case @gender when 'F' then 2 else 1 end)		
		declare @mar_id int =0		
		declare @internalId varchar(50)='', @BranchId int=0,@empid  bigint

		set @empid=(select emp_id from tbl_master_employee where emp_uniqueCode=LTRIM(RTRIM(@Supervisor)))
		if @empid is  null
		Begin
			set @empid=0
		end

		set @BranchId=(select top(1) branch_id from tbl_master_branch where ltrim (rtrim (branch_description))=LTRIM(RTRIM(@Branch)))
		if(@BranchId<>0)
		Begin
			select @emptpy_id=emptpy_id from tbl_master_employeeType  where emptpy_type=@emp_type


			IF NOT EXISTS(SELECT 1 FROM  tbl_master_employee where emp_uniqueCode=@emplcode)
				BEGIN


			exec 
			 [dbo].[EmployeeInsert]
				
				@cnt_ucc 		=@emplcode,
				@cnt_salutation = @sal_id,
				@cnt_firstName=@firstname,
				@cnt_middleName=@middle,
				@cnt_lastName=@lastname,
				@cnt_shortName=@emplcode,
				@cnt_branchId=@BranchId,
				@cnt_sex=@gen_id,
				@cnt_maritalStatus=@mar_id,
				@cnt_DOB=@dob,
				@cnt_anniversaryDate=null,
				@cnt_legalStatus=0,
				@cnt_education=0,		
				@cnt_contactSource =0,
				@cnt_referedBy=0,			
				@cnt_contactType='EM',			
				@lastModifyUser=378,
				@UserContactID=null,
				@bloodgroup	='',
				@WebLogIn='',
				@PassWord='',				
				@emp_dateofJoining=@doj,
				@result=@internalId	output

		
			if(ltrim(rtrim(@internalId))<>'')
			begin
			
				Update tbl_master_employee SET emp_din=' ',
				 emp_dateofJoining =@doj, 
				 emp_dateofLeaving ='',
				 emp_ReasonLeaving  ='',
				  emp_NextEmployer ='', 
				  emp_AddNextEmployer  ='',
				  LastModifyDate=GETDATE(),
				  LastModifyUser='378' Where  emp_contactid =@internalId

				DECLARE @JOB_ID BIGINT=0 

				IF EXISTS(SELECT 1 FROM tbl_master_jobResponsibility WHERE job_responsibility=@jobres)
				BEGIN
					SET @JOB_ID=(SELECT job_id FROM tbl_master_jobResponsibility WHERE job_responsibility=@jobres)
				END
				ELSE
				BEGIN
					
					INSERT INTO tbl_master_jobResponsibility (job_responsibility) VALUES(@jobres)
					SET @JOB_ID=SCOPE_IDENTITY()
				END

				DECLARE @DEG_ID BIGINT=0 

				IF EXISTS(SELECT 1 FROM tbl_master_designation WHERE deg_designation=@deg)
				BEGIN
					SET @DEG_ID=(SELECT deg_id FROM tbl_master_designation WHERE deg_designation=@deg)
				END
				ELSE
				BEGIN
					
		
					INSERT INTO tbl_master_designation (deg_designation,CreateDate,CreateUser,DisplayInTarget,ShowInSupervisorTracking)
					 VALUES(@deg,GETDATE(),378,0,0)
					SET @DEG_ID=SCOPE_IDENTITY()
				END


				DECLARE @DEPT_ID BIGINT=0 

				IF EXISTS(SELECT 1 FROM tbl_master_costCenter WHERE cost_costCenterType='Department' AND cost_description=@department)
				BEGIN
					SET @DEPT_ID=(SELECT cost_id FROM tbl_master_costCenter WHERE cost_costCenterType='Department' AND cost_description=@department)
				END
				ELSE
				BEGIN
		
		
					INSERT INTO tbl_master_costCenter (cost_costCenterType,cost_description,cost_costCenterHead)
					 VALUES('Department',@department,'N/A')
					SET @DEPT_ID=SCOPE_IDENTITY()
				END


				IF EXISTS(SELECT 1 FROM tbl_master_company WHERE cmp_Name=LTRIM(RTRIM(@organisation)))
				BEGIN
					SET @OrganisationId=(SELECT cmp_id FROM tbl_master_company WHERE cmp_Name=LTRIM(RTRIM(@organisation)))
				END
				ELSE
				BEGIN
		
					SET @OrganisationId=(SELECT top 1 cmp_id FROM tbl_master_company )
					
				END
				

				EXEC [dbo].[EmployeeCTCInsert]
				@emp_cntId 	=@internalId,
				@emp_dateofJoining=@DOJ,
				@emp_Organization=@OrganisationId,
				@emp_JobResponsibility=@JOB_ID,
				@emp_Designation=@DEG_ID,
				@emp_Grade=null, 
				@emp_type=@emptpy_id,
				@emp_Department=@DEPT_ID,
				@emp_reportTo=@empid,
				@emp_deputy=0,
				@emp_colleague=0,				
				@emp_workinghours=1,				
				@emp_currentCTC=0, 
				@emp_basic=0,
				@emp_HRA=0,
				@emp_CCA=0,
				@emp_spAllowance=0,
				@emp_childrenAllowance=0,
				@emp_totalLeavePA=2,
				@emp_PF=0,
				@emp_medicalAllowance=0,
				@emp_LTA=0,
				@emp_convence=0,
				@emp_mobilePhoneExp=0,
				@emp_totalMedicalLeavePA=0,	
				@userid=378,	
				@emp_LeaveSchemeAppliedFrom=@doj,
				@emp_branch=@BranchId,
				@emp_Remarks='0',
				@EMP_CarAllowance=0,
				@EMP_UniformAllowance=0,
				@EMP_BooksPeriodicals=0,
				@EMP_SeminarAllowance=0,
				@EMP_OtherAllowance=0



				Update tbl_master_contact SET Cnt_UCC =@emplcode Where  cnt_internalid =@internalId
				Update tbl_master_employee SET emp_uniquecode=@emplcode Where emp_contactID=@internalId







		--declare @prifixId 	varchar(10),
		--@prifixIdN 	varchar(20),
		--@maxID 	varchar(20),
		--@maxIDNO 	int,
		--@VendorInternalId 	varchar(20),
		--@id2	 	varchar(30)
		--select @prifixId= prefix_Name from tbl_master_prefix where prefix_type='Employee'
		--Select @prifixIdN= @prifixId + upper(LEFT(@empname,1))
		--select @maxID= max(cnt_internalid) from tbl_master_contact where cnt_internalid like @prifixIdN+'%'
		--if(@maxID is null)
		--begin
		--	set @VendorInternalId=@prifixIdN+'0000001'
		--end
		--else
		--begin
		--	select @maxIDNO = RIGHT(@maxID,7)+1
		--	if(@maxIDNO<=9)
		--		begin
		--		set @id2=@prifixIdN+'000000'
		--		end
		--	if(@maxIDNO>9 and @maxIDNO<=99)
		--		begin
		--		set @id2=@prifixIdN+'00000'
		--		end
		--	if(@maxIDNO>99 and @maxIDNO<=999)
		--		begin
		--		set @id2=@prifixIdN+'0000'
		--		end
		--	if(@maxIDNO>999 and @maxIDNO<=9999)
		--		begin
		--		set @id2=@prifixIdN+'000'
		--		end
		--	if(@maxIDNO>9999 and @maxIDNO<=99999)
		--		begin
		--		set @id2=@prifixIdN+'00'
		--		end
		--	if(@maxIDNO>99999 and @maxIDNO<=999999)
		--		begin
		--		set @id2=@prifixIdN+'0'
		--		end
		
		--	set @VendorInternalId = @id2 + cast(@maxIDNO as varchar(10))
		--end


				--IF(@branch='Assam Office')
				--BEGIN
				--	INSERT INTO tbl_master_address(add_cntId,add_entity,add_addressType,add_address1,add_address2,add_address3,add_landMark,add_country,add_state,add_city,
				--	add_area,add_pin,add_activityId,CreateDate,CreateUser)
				--	VALUES(@internalId,'employee','Office','Assam',NULL,NULL,NULL,1,28,636,NULL,20397,NULL,gEtdate(),378)

				--END
				--ELSE IF(@branch='Bokaro TEP')
				--BEGIN
				--	INSERT INTO tbl_master_address(add_cntId,add_entity,add_addressType,add_address1,add_address2,add_address3,add_landMark,add_country,add_state,add_city,
				--	add_area,add_pin,add_activityId,CreateDate,CreateUser)
				--	VALUES(@internalId,'employee','Office','Jharkhand',NULL,NULL,NULL,1,23,141,NULL,10672,NULL,gEtdate(),378)
				--END
				---- Rev 1.0
				--ELSE IF(@branch='WBHO')
				--BEGIN
				--	SET @StateId = (select top 1 id from tbl_master_state where state='MADHYA PRADESH')
				--	declare @cityId int = (select top 1 city_id from tbl_master_city where city_name='Bhopal')

				--	INSERT INTO tbl_master_address(add_cntId,add_entity,add_addressType,add_address1,add_address2,add_address3,add_landMark,add_country,add_state,add_city,
				--	add_area,add_pin,add_activityId,CreateDate,CreateUser,Isdefault)
				--	VALUES(@internalId,'employee','Office','C 21 MALL,MISROD,HOSHANGABAD ROAD,BHOPAL',NULL,NULL,NULL,1,@StateId,@cityId,NULL,'15973',NULL,gEtdate(),378,0)
				--END
				---- End of Rev 1.0
				--ELSE
				--BEGIN
				--	INSERT INTO tbl_master_address(add_cntId,add_entity,add_addressType,add_address1,add_address2,add_address3,add_landMark,add_country,add_state,add_city,
				--	add_area,add_pin,add_activityId,CreateDate,CreateUser)
				--	VALUES(@internalId,'employee','Office','West Bengal',NULL,NULL,NULL,1,15,557,NULL,9708,NULL,gEtdate(),378)
				--END

				if(isnull(@mobile,0)<>0)
				begin
				insert into tbl_master_phonefax(phf_cntId,phf_entity,phf_type,phf_phoneNumber,CreateDate,CreateUser)
				values(@internalId,'employee','Office',convert(nvarchar(18),convert(bigint,@mobile)),GETDATE(),378)
				end

				if(isnull(@personalmobile,'')<>'')
				begin
					insert into tbl_master_phonefax(phf_cntId,phf_entity,phf_type,phf_phoneNumber,CreateDate,CreateUser)					
					values(@internalId,'employee','Mobile',@personalmobile,GETDATE(),378)
				end

				

				

					

					SET @USER_GROUP=(SELECT TOP 1 grp_id FROM tbl_master_userGroup where grp_name=@Group)

				
					INSERT INTO tbl_master_user(user_name,user_loginId,user_password,user_contactId,user_branchId,user_group,user_lastsegement,user_LastFinYear,
					user_LastStno,user_LastStType,user_LastBatch,user_status,user_leavedate,user_TimeForTickerRefrsh,user_type,CreateDate,CreateUser,last_login_date,
					user_superUser,user_lastIP,user_EntryProfile,user_activity,user_AllowAccessIP,user_inactive,Mac_Address,DEviceType,SessionToken,user_imei_no,
					user_maclock,Gps_Accuracy,Custom_Configuration,HierarchywiseTargetSettings,IsShowPlanDetails,IsMoreDetailsMandatory,IsShowMoreDetailsMandatory,
					isMeetingAvailable,isRateNotEditable,autoRevisitDistanceInMeter,autoRevisitTimeInMinutes,IsAutoRevisitEnable,willLeaveApprovalEnable,IsShowTeamDetails,
					IsAllowPJPUpdateForTeam,willReportShow,isFingerPrintMandatoryForAttendance,isFingerPrintMandatoryForVisit,isSelfieMandatoryForAttendance,isAttendanceReportShow,
					isPerformanceReportShow,isVisitReportShow,willTimesheetShow,isAttendanceFeatureOnly,isOrderShow,isVisitShow,iscollectioninMenuShow,isShopAddEditAvailable,
					isEntityCodeVisible,isAreaMandatoryInPartyCreation,isShowPartyInAreaWiseTeam)					
					VALUES(@empname,@personalmobile,'mpcBb4q+5Dj/igo5ESszqw==',@INTERNALID,@BranchId,@USER_GROUP,1,NULL,NULL,NULL,NULL,0,NULL,86400,NULL,GETDATE(),378,NULL,'N',				
					NULL,'F',NULL,'','N',NULL,NULL,NULL,NULL,'N',200,NULL,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

					
					SELECT @USERID=SCOPE_IDENTITY()

					insert into FTS_UserPartyCreateAccess (User_Id,Shop_TypeId) VALUES(@USERID,@shop_typeId)

					set @StateId=(select top 1 branch_state  from tbl_master_branch where branch_id=@BranchId)

					insert into FTS_EMPSTATEMAPPING (USER_ID,STATE_ID,SYS_DATE_TIME ,AUTHOR ) values(@USERID,@StateId,SYSDATETIME(),'378')



					insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
					values(@emplcode,@loopNumber,@empname,'Success',@FileName,'Employee Code Save Successfully',@CreateUser_Id,GETDATE(),0)
					
			end
			
		END

		        ELSE
				BEGIN
					insert into EmployeeImportLog(EmployeeCode,LoopNumber,EmpName,Status,FileName,Description,CreatedBy,CreatedDatetime,ISShow)
					values(@emplcode,@loopNumber,@empname,'Failed',@FileName,'Employee CODE can not be Same.',@CreateUser_Id,GETDATE(),0)
				END
		END

			
		End
		

	fetch next from db_cursor into @emplcode,@empname,@salutation,@firstname,@middle,@lastname,@gender,@doj,@organisation,@jobres,@branch,@deg,@emp_type,@department	
	,@personalmobile,@Supervisor,@Group
	end
	close db_cursor
	deallocate db_cursor

	--Rev 1.0
	insert into tbl_trans_LastSegment(ls_cntId,ls_lastSegment,ls_lastCompany,ls_lastFinYear,ls_lastSettlementNo,ls_lastSettlementType,ls_lastdpcoid,ls_userid)
	select user_contactId,1,'COR0000002','2024-2025','2016001','F','1',user_id from tbl_master_user where user_id not in (select ls_userid from tbl_trans_LastSegment)
	--Rev 1.0 End

	DELETE FROM TEMPEmployeeData
	
	
END