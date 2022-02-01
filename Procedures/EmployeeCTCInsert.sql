IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EmployeeCTCInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [EmployeeCTCInsert] AS' 
END
GO




ALTER PROCEDURE [dbo].[EmployeeCTCInsert]
	@emp_cntId 				nvarchar(50),
	@emp_dateofJoining  	datetime,
	@emp_Organization		int,
	@emp_JobResponsibility	int,
	@emp_Designation		int,
	@emp_Grade		        int=null, 
	@emp_type				int,
	@emp_Department			int,
	@emp_reportTo			int,
	@emp_deputy				int,
	@emp_colleague			int,
	@emp_workinghours		int,
	@emp_currentCTC			nvarchar(50), 
	@emp_basic 				nvarchar(50),
	@emp_HRA 				nvarchar(50),
	@emp_CCA 				nvarchar(50),
	@emp_spAllowance 		nvarchar(50),
	@emp_childrenAllowance	nvarchar(50),
	@emp_totalLeavePA 		nvarchar(50),
	@emp_PF 				nvarchar(50),
	@emp_medicalAllowance	nvarchar(50),
	@emp_LTA				nvarchar(50),
	@emp_convence 			nvarchar(50),
	@emp_mobilePhoneExp		nvarchar(50),
	@emp_totalMedicalLeavePA nvarchar(50),	
	@userid 				int,	
	@emp_LeaveSchemeAppliedFrom	datetime,
	@emp_branch				int,
	@emp_Remarks			varchar(max),
	@EMP_CarAllowance  numeric(10, 0),
	@EMP_UniformAllowance  numeric(10, 0),
	@EMP_BooksPeriodicals  numeric(10, 0),
	@EMP_SeminarAllowance   numeric(10, 0),
	@EMP_OtherAllowance   numeric(10, 0),
	-- Rev 1.0
	@emp_colleague1			int=0,
	@emp_colleague2			int=0
	-- End of Rev 1.0
	
AS
/****************************************************************************************************************************************************
1.0		Sanchita		V2.0.26		29-01-2022		CTC Tab - "Colleague1" and "Colleague2", refer: 24655
****************************************************************************************************************************************************/
begin
	declare @rowEffected int,@oldLeaveScheme int, @oldEffectiveDate datetime

	select @oldLeaveScheme=isnull(emp_totalLeavePA,'0'),@oldEffectiveDate=emp_LeaveSchemeAppliedFrom from tbl_trans_employeeCTC where ( emp_effectiveuntil is null or emp_effectiveuntil = '1/1/1900 12:00:00 AM' or emp_effectiveuntil = '1/1/1900')  and emp_cntId = @emp_cntId

	---Rejoin Section----------
--	IF Not Exists(select * from tbl_trans_employeectc where emp_cntId=@emp_cntId  and (emp_effectiveuntil is null or emp_effectiveuntil = '1/1/1900 12:00:00 AM' or emp_effectiveuntil = '1/1/1900'))
--	BEGIN
		update tbl_master_employee set emp_dateofLeaving=NULL,emp_ReasonLeaving=NULL where emp_contactId=@emp_cntId
--	END



	--Updating Old data
	update tbl_trans_employeeCTC set emp_effectiveuntil = dateadd(dd,-1,@emp_dateofJoining) where ( emp_effectiveuntil is null or emp_effectiveuntil = '1/1/1900 12:00:00 AM' or emp_effectiveuntil = '1/1/1900')  and emp_cntId = @emp_cntId
	select @rowEffected=@@rowcount
	
	-- Rev 1.0 [ ,emp_colleague1 and ,emp_colleague1 added]
	--Inserting New row of data
	INSERT INTO tbl_trans_employeeCTC 
                            (emp_cntId,emp_effectiveDate,emp_organization, emp_JobResponsibility,
                            emp_Designation,Emp_Grade,emp_type,emp_Department,emp_reportTo,emp_deputy,emp_colleague,emp_workinghours,
                            emp_currentCTC,emp_basic,emp_HRA,emp_CCA,emp_spAllowance,emp_totalLeavePA,emp_PF,emp_medicalAllowance,
                            emp_LTA,emp_convence,emp_mobilePhoneExp,emp_totalMedicalLeavePA,CreateUser,CreateDate,
							emp_branch,emp_LeaveSchemeAppliedFrom,emp_Remarks,EMP_CarAllowance,EMP_UniformAllowance,EMP_BooksPeriodicals,EMP_SeminarAllowance,
							EMP_OtherAllowance,emp_colleague1,emp_colleague2)
                            Values(@emp_cntId,@emp_dateofJoining,@emp_organization,@emp_JobResponsibility,
                            @emp_Designation,@emp_Grade,@emp_type,@emp_Department,@emp_reportTo,@emp_deputy,@emp_colleague,@emp_workinghours,
                            @emp_currentCTC,@emp_basic,@emp_HRA,@emp_CCA,@emp_spAllowance,@emp_totalLeavePA,@emp_PF,@emp_medicalAllowance,
                            @emp_LTA,@emp_convence,@emp_mobilePhoneExp,@emp_totalMedicalLeavePA,@userid,getdate(),
							@emp_branch,@emp_LeaveSchemeAppliedFrom,@emp_Remarks,@EMP_CarAllowance,@EMP_UniformAllowance,@EMP_BooksPeriodicals,@EMP_SeminarAllowance,
							@EMP_OtherAllowance,@emp_colleague1,@emp_colleague2)
							--Updating tbl_master_contact
							update [tbl_master_contact] set
							[cnt_branchid]=@emp_branch 
						where [cnt_internalId]=@emp_cntId
						
  -- Code Added by  Sandip on 20032017 to update Branchid in tbl_master_user if User of this employee exists.	
  
  
	--Sudip Pal 05-02-2019 Grade


	if not exists(select Emp_Grade from  tbl_FTS_MapEmployeeGrade where Emp_Code=@emp_cntId)
	BEGIN
	if(@emp_Grade<>0)
	
	INSERT  INTO tbl_FTS_MapEmployeeGrade values(@emp_Grade,@emp_cntId,GETDATE())
	

	END
	ELSE
	BEGIN
	if(@emp_Grade<>0)
	update tbl_FTS_MapEmployeeGrade set Emp_Grade=@emp_Grade where Emp_Code=@emp_cntId
	else
	delete  from tbl_FTS_MapEmployeeGrade where Emp_Code=@emp_cntId
	END


	--Sudip Pal 05-02-2019 Grade
	
  
  			
	 if exists(select 'Y' from tbl_master_user where user_contactId=@emp_cntId)
      begin
          update tbl_master_user set user_branchId=@emp_branch where user_contactId=@emp_cntId
          --set @ReturnValue='1'
      end
       -- Code Above Added by  Sandip on 20032017 to update Branchid in tbl_master_user if User of this employee exists.									
						
						
						
						
						
						
						
						
						
	--Selecting Leave Scheme values from tbl_master_LeaveScheme
	Declare @PLtotal float,@PLentitlement int, @PLencashedEligibility int, @CLtotal int, @CLentitlement int
	Declare @CLencashedEligibility int, @SLtotal int, @SLentitlement int, @SLencashedEligibility int, @MLeligibility int, @MLtotalPre int, @MLtotalPos int,
	@PLapplicablefor char(1),@CLapplicablefor char(1),@SLapplicablefor char(1)
	select @PLtotal=ls_TotalPrevilegeLeave, @PLentitlement=ls_PLentitlement,@PLencashedEligibility=ls_PLencashedEligibility,@PLapplicablefor=ls_PLapplicablefor,
		@CLtotal=ls_CLtotal, @CLentitlement=ls_CLentitlement,@CLencashedEligibility=ls_CLencashedEligibility,@CLapplicablefor=ls_CLapplicablefor,
		@SLtotal=ls_SLtotal, @SLentitlement=ls_SLentitlement,@SLencashedEligibility=ls_SLencashedEligibility,@SLapplicablefor=ls_SLapplicablefor,
		@MLtotalPre=ls_MLtotalpre, @MLtotalPos=ls_MLtotalPos,@MLeligibility=ls_MLeligibility
	from tbl_master_LeaveScheme where ls_id=@emp_totalLeavePA

	--Inserting into tbl_trans_LeaveAccountBalance
	
--if(@oldLeaveScheme != @emp_totalLeavePA)
--begin
	declare @year varchar(5), @month float,@finYear varchar(10), @MLtotal int
	set @MLtotal=(@MLtotalPre+@MLtotalPos)
	
	select @year=Year(DATEADD(month,@PLentitlement,@emp_dateofJoining)), @month=month(DATEADD(month,@PLentitlement,@emp_dateofJoining))
   
	declare @FinY1 varchar(5),@finY2 varchar(5),@PLtotalThisYear float,@CLtotalThisYear float,@SLtotalThisYear float
	
	select @finYear=case when month(getdate())<4 then cast(year(getdate())-1 as varchar(4))+'-'+cast(year(getdate()) as varchar(4)) else cast(year(getdate()) as varchar(4))+'-'+cast(year(getdate())+1 as varchar(4)) end
	if(@year<=year(@emp_LeaveSchemeAppliedFrom))
		begin
			if(@year<year(@emp_LeaveSchemeAppliedFrom))
				set @month=1
			if(@PLapplicablefor='F')
			begin
					--Addition of 3 due to financial year "march end"
				if(@month<4)
					set @PLtotalThisYear = (@PLtotal*(4-@month)/12)
				else
					set @PLtotalThisYear = (@PLtotal*(12-@month+1+3)/12)	
			end
			else
			begin
				set @PLtotalThisYear = (@PLtotal*(12-@month+1)/12)	
			end
		end
		else
			set @PLtotalThisYear=0
--	if(@PLapplicablefor='F')
--	begin
--			--Addition of 3 due to financial year "march end"
--		if(@month<4)
--			set @PLtotalThisYear = (@PLtotal*(4-@month)/12)
--		else
--			set @PLtotalThisYear = (@PLtotal*(12-@month+1+3)/12)	
--	end
--	else
--	begin
--		set @PLtotalThisYear = (@PLtotal*(12-@month+1)/12)	
--	end
	select @year=Year(DATEADD(month,@CLentitlement,@emp_dateofJoining)), @month=month(DATEADD(month,@CLentitlement,@emp_dateofJoining))
	if(@year<=year(@emp_LeaveSchemeAppliedFrom))
		begin
			if(@year<year(@emp_LeaveSchemeAppliedFrom))
				set @month=1
			--print(@month)
			if(@CLapplicablefor='F')
			begin
					--Addition of 3 due to financial year "march end"
				--print('Fin')
				if(@month<4)
					set @CLtotalThisYear = (@CLtotal*(4-@month)/12)
				else
					set @CLtotalThisYear = (@CLtotal*(12-@month+1+3)/12)	
			end
			else
			begin
				--print('Calcu')
				--print((12-@month+1))
				set @CLtotalThisYear = (@CLtotal*(12-@month+1)/12)
				--print(@CLtotalThisYear)	;
			end
		end
		else
			set @CLtotalThisYear=0

	select @year=Year(DATEADD(month,@SLentitlement,@emp_dateofJoining)), @month=month(DATEADD(month,@SLentitlement,@emp_dateofJoining))
		if(@year<=year(@emp_LeaveSchemeAppliedFrom))
		begin	
			if(@year<year(@emp_LeaveSchemeAppliedFrom))
				set @month=1
			if(@SLapplicablefor='F')
			begin
					--Addition of 3 due to financial year "march end"
				if(@month<4)
					set @SLtotalThisYear = (@SLtotal*(4-@month)/12)
				else
					set @SLtotalThisYear = (@SLtotal*(12-@month+1+3)/12)	
			end
			else
			begin
				set @SLtotalThisYear = (@SLtotal*(12-@month+1)/12)	
			end
		end
		else
			set @SLtotalThisYear=0

    if(@rowEffected=0)
	begin
	insert into tbl_trans_LeaveAccountBalance 
			(lab_contactId,lab_effectiveDate,lab_financialYear,lab_PLBFLastYear,lab_PLCurrentYear
                    ,lab_PLEligibilityDate,lab_PLEncashmentEligibilityDate,lab_PLtotalAvailedThisYear
                    ,lab_PLtotalEncashedThisYear,lab_PLCFNextYear,lab_CLBFLastYear,lab_CLCurrentYear,
                    lab_CLEligibilityDate,lab_CLEncashmentEligibilityDate,lab_CLtotalAvailedThisYear,
                    lab_CLtotalEncashedThisYear,lab_CLCFNextYear,lab_SLBFLastYear,lab_SLCurrentYear,
                    lab_SLEligibilityDate,lab_SLEncashmentEligibilityDate,lab_SLtotalAvailedThisYear,
                    lab_SLtotalEncashedThisYear,lab_SLCFNextYear,lab_MLCurrentYear,lab_MLEligibilityDate)
		Values(@emp_cntId,@emp_LeaveSchemeAppliedFrom,@finYear,'0',@PLtotalThisYear,DATEADD(month,@PLentitlement,@emp_dateofJoining),
		DATEADD(month,@PLencashedEligibility,@emp_dateofJoining),'0','0','0','0',@CLtotalThisYear,
		DATEADD(month,@CLentitlement,@emp_dateofJoining),DATEADD(month,@CLencashedEligibility,@emp_dateofJoining),'0','0','0','0',
		@sLtotalThisYear,DATEADD(month,@SLentitlement,@emp_dateofJoining),DATEADD(month,@SLencashedEligibility,@emp_dateofJoining),
		'0','0','0',@MLtotal,DATEADD(month,@MLeligibility,@emp_dateofJoining))
	end
	else
		begin
		if(@oldLeaveScheme != @emp_totalLeavePA)
		begin
			declare @monthDiff int, @checkForData int, @TotalPLnew float,@PLold int, @CLold int,@finYearold varchar(15), @StrtMonth int, @endMonth int
			declare @Strtyear int,@endyear int
			--Month diff hold month in between lasteffective date to this new effctive date
			select @Strtyear=year(@emp_LeaveSchemeAppliedFrom), @endyear= year(@oldEffectiveDate)
			select @StrtMonth=month(@emp_LeaveSchemeAppliedFrom), @endMonth = month(@oldEffectiveDate)
			if(@Strtyear=@endyear)
				begin
				set @monthDiff=@StrtMonth-@endMonth
				end
			if(@Strtyear>@endyear)
				begin
				set @monthDiff=(@StrtMonth+12)-@endMonth
				end
			select @checkForData=isnull(lab_id,'0'),@finYearold=lab_financialYear from tbl_trans_LeaveAccountBalance where convert(varchar(10),lab_effectiveDate,103)=convert(varchar(10),cast(@oldEffectiveDate as datetime),103) and lab_contactId=@emp_cntId
			--Checking for Old data IN leave Account Balance
			--print('With OldCTC')
			--print(@checkForData)
			if (@checkForData !='0')
				begin
					--old leav scheme
					select @PLtotal=ls_TotalPrevilegeLeave, @PLentitlement=ls_PLentitlement,@PLencashedEligibility=ls_PLencashedEligibility,
						@CLtotal=ls_CLtotal, @CLentitlement=ls_CLentitlement,@CLencashedEligibility=ls_CLencashedEligibility,
						@SLtotal=ls_SLtotal, @SLentitlement=ls_SLentitlement,@SLencashedEligibility=ls_SLencashedEligibility,
						@MLtotalPre=ls_MLtotalpre, @MLtotalPos=ls_MLtotalPos,@MLeligibility=ls_MLeligibility
					from tbl_master_LeaveScheme where ls_id=@oldLeaveScheme
					declare @PLBFLastYear float,@PLCurrentYear float,@PLtotalAvailedThisYear float
                    declare @PLCFNextYear float,@CLBFLastYear float,@CLCurrentYear float,@CLtotalAvailedThisYear float
                    declare @CLCFNextYear float,@SLBFLastYear float,@SLCurrentYear float,@SLtotalAvailedThisYear float
                    declare @SLCFNextYear float,@MLCurrentYear float
					--Old leave account balance
					select @PLBFLastYear=isnull(lab_PLBFLastYear,'0'),@PLCurrentYear=isnull(lab_PLCurrentYear,'0'),@PLtotalAvailedThisYear=isnull(lab_PLtotalAvailedThisYear,'0')
						,@PLCFNextYear=isnull(lab_PLCFNextYear,'0'),@CLBFLastYear=isnull(lab_CLBFLastYear,'0'),@CLCurrentYear=isnull(lab_CLCurrentYear,'0'),@CLtotalAvailedThisYear=isnull(lab_CLtotalAvailedThisYear,'0'),
						@CLCFNextYear=isnull(lab_CLCFNextYear,'0'),@SLBFLastYear=isnull(lab_SLBFLastYear,'0'),@SLCurrentYear=isnull(lab_SLCurrentYear,'0'),@SLtotalAvailedThisYear=isnull(lab_SLtotalAvailedThisYear,'0'),
						@SLCFNextYear=isnull(lab_SLCFNextYear,'0'),@MLCurrentYear=isnull(lab_MLCurrentYear,'0')
					from tbl_trans_LeaveAccountBalance where lab_effectiveDate=@oldEffectiveDate and lab_contactId=@emp_cntId

					--Now update old record in the table on the basis of month difference @monthDiff
					declare @PLCF float,@CLCF float,@SLCF float, @finYearNew varchar(10),@PLtotaloldYear float,@CLtotaloldYear float,@SLtotaloldYear float
					set @PLtotaloldYear = (@PLtotal*(@monthDiff)/12)
					set @PLCF = @PLtotaloldYear-(@PLtotalAvailedThisYear)+@PLBFLastYear
					set @CLtotaloldYear = (@CLtotal*(@monthDiff)/12)
					set @CLCF = @CLtotaloldYear-(@CLtotalAvailedThisYear)+@CLBFLastYear
					set @SLtotaloldYear = (@SLtotal*(@monthDiff)/12)
					set @SLCF = @SLtotaloldYear-(@SLtotalAvailedThisYear)+@SLBFLastYear
					--Update table leave balance account
					update tbl_trans_LeaveAccountBalance set lab_PLCurrentYear=@PLtotaloldYear,lab_PLCFNextYear=@PLCF,
							lab_CLCurrentYear=@CLtotaloldYear,lab_CLCFNextYear=@CLCF,lab_SLCurrentYear=@SLtotaloldYear,lab_SLCFNextYear=@SLCF
						where 	convert(varchar(10),lab_effectiveDate,103)=convert(varchar(10),@oldEffectiveDate,103) and lab_contactId=@emp_cntId
					--New Entry On the basis of new leave scheme
--					if(@StrtMonth<4)
--						select @FinY1=year(dateadd(YY,-1,@emp_LeaveSchemeAppliedFrom)),@finY2=year(@emp_LeaveSchemeAppliedFrom)
--					else
--						select @FinY2=year(dateadd(YY,1,@emp_LeaveSchemeAppliedFrom)),@finY1=year(@emp_LeaveSchemeAppliedFrom)
--					set @finYearNew = @FinY1 + '-' + @FinY2
					set @finYearNew=@finYear
					
					insert into tbl_trans_LeaveAccountBalance 
							(lab_contactId,lab_effectiveDate,lab_financialYear,lab_PLBFLastYear,lab_PLCurrentYear
									,lab_PLEligibilityDate,lab_PLEncashmentEligibilityDate,lab_PLtotalAvailedThisYear
									,lab_PLtotalEncashedThisYear,lab_PLCFNextYear,lab_CLBFLastYear,lab_CLCurrentYear,
									lab_CLEligibilityDate,lab_CLEncashmentEligibilityDate,lab_CLtotalAvailedThisYear,
									lab_CLtotalEncashedThisYear,lab_CLCFNextYear,lab_SLBFLastYear,lab_SLCurrentYear,
									lab_SLEligibilityDate,lab_SLEncashmentEligibilityDate,lab_SLtotalAvailedThisYear,
									lab_SLtotalEncashedThisYear,lab_SLCFNextYear,lab_MLCurrentYear,lab_MLEligibilityDate)
						Values(@emp_cntId,@emp_LeaveSchemeAppliedFrom,@finYearNew,@PLCF,@PLtotalThisYear,DATEADD(month,@PLentitlement,@emp_dateofJoining),
						DATEADD(month,@PLencashedEligibility,@emp_dateofJoining),'0','0','0',@CLCF,@CLtotalThisYear,
						DATEADD(month,@CLentitlement,@emp_dateofJoining),DATEADD(month,@CLencashedEligibility,@emp_dateofJoining),'0','0','0',@SLCF,
						@sLtotalThisYear,DATEADD(month,@SLentitlement,@emp_dateofJoining),DATEADD(month,@SLencashedEligibility,@emp_dateofJoining),
						'0','0','0',@MLtotal,DATEADD(month,@MLeligibility,@emp_dateofJoining))
				end
			else
				begin
					--print('else')
					insert into tbl_trans_LeaveAccountBalance 
						(lab_contactId,lab_effectiveDate,lab_financialYear,lab_PLBFLastYear,lab_PLCurrentYear
								,lab_PLEligibilityDate,lab_PLEncashmentEligibilityDate,lab_PLtotalAvailedThisYear
								,lab_PLtotalEncashedThisYear,lab_PLCFNextYear,lab_CLBFLastYear,lab_CLCurrentYear,
								lab_CLEligibilityDate,lab_CLEncashmentEligibilityDate,lab_CLtotalAvailedThisYear,
								lab_CLtotalEncashedThisYear,lab_CLCFNextYear,lab_SLBFLastYear,lab_SLCurrentYear,
								lab_SLEligibilityDate,lab_SLEncashmentEligibilityDate,lab_SLtotalAvailedThisYear,
								lab_SLtotalEncashedThisYear,lab_SLCFNextYear,lab_MLCurrentYear,lab_MLEligibilityDate)
					Values(@emp_cntId,@emp_LeaveSchemeAppliedFrom,@finYear,'0',@PLtotalThisYear,DATEADD(month,@PLentitlement,@emp_dateofJoining),
					DATEADD(month,@PLencashedEligibility,@emp_dateofJoining),'0','0','0','0',@CLtotalThisYear,
					DATEADD(month,@CLentitlement,@emp_dateofJoining),DATEADD(month,@CLencashedEligibility,@emp_dateofJoining),'0','0','0','0',
					@sLtotalThisYear,DATEADD(month,@SLentitlement,@emp_dateofJoining),DATEADD(month,@SLencashedEligibility,@emp_dateofJoining),
					'0','0','0',@MLtotal,DATEADD(month,@MLeligibility,@emp_dateofJoining))
				end
		end	
		end
--end
end


