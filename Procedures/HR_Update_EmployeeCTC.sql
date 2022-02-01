IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HR_Update_EmployeeCTC]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HR_Update_EmployeeCTC] AS' 
END
GO

--exec employeeCTCupdate '8/1/2009 12:00:00 AM',68,71,175,18,3,579,570,570,2,'','','','','','','2','','','','','','',275,1531,78,'1/1/2010 12:00:00 AM','EMS0000102','',0,0,0,0,0

ALTER PROCEDURE [dbo].[HR_Update_EmployeeCTC]  
	-- Add the parameters for the stored procedure here
@emp_dateofJoining		datetime,
@emp_organization		int,

@emp_JobResponsibility	int, 
@emp_Designation		int, 
@emp_Grade		        int, 
@emp_type				int, 
@emp_Department			int,
@emp_reportTo			int,  
@emp_deputy				int, 
@emp_colleague			int,
@emp_workinghours		int,
@emp_currentCTC			varchar(50), 
@emp_basic				varchar(50),
@emp_HRA				varchar(50), 
@emp_CCA				varchar(50), 
@emp_spAllowance		varchar(50),
@emp_childrenAllowance	varchar(50),
@emp_totalLeavePA		varchar(10),
@emp_PF					varchar(50), 
@emp_medicalAllowance	varchar(50),
@emp_LTA				varchar(50),
@emp_convence			varchar(50), 
@emp_mobilePhoneExp		varchar(50),
@emp_totalMedicalLeavePA varchar(50),
@userid					int,
@Id						int,
@emp_branch				int,
@emp_LeaveSchemeAppliedFrom	datetime,
@emp_cntId				varchar(10),
@emp_Remarks			varchar(max),
@EMP_CarAllowance  numeric(10, 0),
@EMP_UniformAllowance  numeric(10, 0),
@EMP_BooksPeriodicals  numeric(10, 0),
@EMP_SeminarAllowance   numeric(10, 0),
@EMP_OtherAllowance   numeric(10, 0)
-- Rev 1.0
,@emp_colleague1  int = 0,
@emp_colleague2 int = 0
-- End of Rev 1.0
AS
/****************************************************************************************************************************************************
1.0		Sanchita		V2.0.26		29-01-2022		CTC Tab - "Colleague1" and "Colleague2", refer: 24655
****************************************************************************************************************************************************/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Select old data to compare with new one!
	declare @LeaveSchemeOld int,@LeaveSchemeAppldfromOld datetime
		select @LeaveSchemeOld=emp_totalMedicalLeavePA, @LeaveSchemeAppldfromOld=emp_LeaveSchemeAppliedFrom
		From [tbl_trans_employeeCTC] Where [emp_id] = @Id

	-- Rev 1.0 [ emp_colleague1 and emp_colleague2 added]
	-- Insert data before update ctc in log table
	INSERT INTO tbl_trans_employeeCTC_Log(emp_id, emp_cntId, emp_effectiveDate, emp_effectiveuntil, emp_Organization, emp_JobResponsibility,
	 emp_Designation,emp_type, emp_Department, emp_reportTo, emp_deputy, emp_colleague, emp_workinghours, emp_currentCTC, 
	 emp_basic, emp_HRA, emp_CCA, emp_spAllowance, emp_childrenAllowance, emp_totalLeavePA, emp_PF, emp_medicalAllowance, emp_LTA, 
	 emp_convence, emp_mobilePhoneExp, emp_totalMedicalLeavePA, CreateDate, CreateUser, LastModifyDate, LastModifyUser, 
	 emp_LeaveSchemeAppliedFrom, emp_branch,emp_Remarks ,EMP_CarAllowance,EMP_UniformAllowance,EMP_BooksPeriodicals,EMP_SeminarAllowance
	, EMP_OtherAllowance,Emp_Grade, emp_colleague1, emp_colleague2, LogModifyDate, LogModifyUser, LogStatus)
	select *,getdate(),@userId,'M' from tbl_trans_employeeCTC Where [emp_id] = @Id
	
	-- Rev 1.0 [ emp_colleague1 and emp_colleague2 added]
	-- Update EmployeeCTC table
	UPDATE [tbl_trans_employeeCTC] SET
							[emp_effectiveDate] =@emp_dateofJoining,
                            [emp_organization] = @emp_organization, [emp_JobResponsibility] = @emp_JobResponsibility,
                            [emp_Designation] = @emp_Designation, Emp_Grade=@emp_Grade,   [emp_type] = @emp_type, [emp_Department] = @emp_Department,
                            [emp_reportTo] = @emp_reportTo, [emp_deputy] = @emp_deputy, [emp_colleague] = @emp_colleague,
                            [emp_workinghours] = @emp_workinghours, [emp_currentCTC] = @emp_currentCTC, [emp_basic] = @emp_basic,
                            [emp_HRA] = @emp_HRA, [emp_CCA] = @emp_CCA,[emp_spAllowance] = @emp_spAllowance,
                            [emp_childrenAllowance] = @emp_childrenAllowance, [emp_totalLeavePA] = @emp_totalLeavePA,
                            [emp_PF] = @emp_PF, [emp_medicalAllowance] = @emp_medicalAllowance, [emp_LTA] = @emp_LTA,
                            [emp_convence] = @emp_convence, [emp_mobilePhoneExp] = @emp_mobilePhoneExp,
                            [emp_totalMedicalLeavePA] = @emp_totalMedicalLeavePA, [LastModifyDate] = getdate(),
                            [LastModifyUser] = @userid,[emp_branch]=@emp_branch,[emp_LeaveSchemeAppliedFrom]=@emp_LeaveSchemeAppliedFrom,
							[emp_Remarks]=@emp_Remarks ,
							EMP_CarAllowance=@EMP_CarAllowance,
							EMP_UniformAllowance=@EMP_UniformAllowance,
							EMP_BooksPeriodicals=@EMP_BooksPeriodicals,
							EMP_SeminarAllowance=@EMP_SeminarAllowance,
							EMP_OtherAllowance=@EMP_OtherAllowance,
							[emp_colleague1] = @emp_colleague1,
							[emp_colleague2] = @emp_colleague2
						Where [emp_id] = @Id
	
	--insert into log table befor update contacts
		insert into tbl_master_contact_Log(cnt_id, cnt_internalId, cnt_branchid, cnt_accessLevel, cnt_addDate, cnt_modUserId, cnt_modDate, cnt_UCC, cnt_salutation, cnt_firstName, cnt_middleName, cnt_lastName, cnt_shortName, cnt_contactSource, cnt_contactType, cnt_legalStatus, cnt_referedBy, cnt_relation, cnt_contactStatus, cnt_speakLanguage, cnt_writeLanguage, cnt_dOB, cnt_maritalStatus, cnt_anniversaryDate, cnt_education, cnt_profession, cnt_jobResponsibility, cnt_organization, cnt_industry, cnt_designation, cnt_preferedContact, cnt_sex, cnt_UserAccess, cnt_RelationshipManager, cnt_salesRepresentative, CreateDate, CreateUser, LastModifyDate, LastModifyUser, cnt_LeadId, cnt_RegistrationDate, cnt_rating, cnt_reason, cnt_status, cnt_Lead_Stage, cnt_bloodgroup, WebLogIn, PassWord, LogModifyDate, LogModifyUser, LogStatus)
		select cnt_id, cnt_internalId, cnt_branchid, cnt_accessLevel, cnt_addDate, cnt_modUserId, cnt_modDate, cnt_UCC, cnt_salutation, cnt_firstName, cnt_middleName, cnt_lastName, cnt_shortName, cnt_contactSource, cnt_contactType, cnt_legalStatus, cnt_referedBy, cnt_relation, cnt_contactStatus, cnt_speakLanguage, cnt_writeLanguage, cnt_dOB, cnt_maritalStatus, cnt_anniversaryDate, cnt_education, cnt_profession, cnt_jobResponsibility, cnt_organization, cnt_industry, cnt_designation, cnt_preferedContact, cnt_sex, cnt_UserAccess, cnt_RelationshipManager, cnt_salesRepresentative, CreateDate, CreateUser, LastModifyDate, LastModifyUser, cnt_LeadId, cnt_RegistrationDate, cnt_rating, cnt_reason, cnt_status, cnt_Lead_Stage, cnt_bloodgroup, WebLogIn, PassWord,getdate(),@userId,'M' from tbl_master_contact where [cnt_internalId]=@emp_cntId
	
	--Updating tbl_master_contact
	update [tbl_master_contact] set [cnt_branchid]=@emp_branch where [cnt_internalId]=@emp_cntId
	--Comparing With The old Values of leave scheme


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
	


	--print(@LeaveSchemeOld)
	--print(@emp_totalLeavePA)
	if(@LeaveSchemeOld != @emp_totalLeavePA)
	Begin
		--print('inside')
		--Selecting Leave Scheme values from tbl_master_LeaveScheme
		Declare @PLtotal float,@PLentitlement int, @PLencashedEligibility int, @CLtotal int, @CLentitlement int, @CLencashedEligibility int, @SLtotal int, @SLentitlement int, @SLencashedEligibility int, @MLeligibility int, @MLtotalPre int, @MLtotalPos int
		select @PLtotal=ls_TotalPrevilegeLeave, @PLentitlement=ls_PLentitlement,@PLencashedEligibility=ls_PLencashedEligibility,
			@CLtotal=ls_CLtotal, @CLentitlement=ls_CLentitlement,@CLencashedEligibility=ls_CLencashedEligibility,
			@SLtotal=ls_SLtotal, @SLentitlement=ls_SLentitlement,@SLencashedEligibility=ls_SLencashedEligibility,
			@MLtotalPre=ls_MLtotalpre, @MLtotalPos=ls_MLtotalPos,@MLeligibility=ls_MLeligibility
		from tbl_master_LeaveScheme where ls_id=@emp_totalLeavePA
		
		--Inserting into tbl_trans_LeaveAccountBalance
		declare @year varchar(5), @month float,@finYear varchar(10), @MLtotal int
		set @MLtotal=(ISNULL(@MLtotalPre,0)+ISNULL(@MLtotalPos,0))
		select @year=Year(@emp_LeaveSchemeAppliedFrom), @month=month(@emp_LeaveSchemeAppliedFrom)
		declare @FinY1 varchar(5),@finY2 varchar(5),@PLtotalThisYear float,@CLtotalThisYear float,@SLtotalThisYear float
		if(@month<4)
			begin
				select @FinY1=year(dateadd(YY,-1,@emp_LeaveSchemeAppliedFrom)),@finY2=year(@emp_LeaveSchemeAppliedFrom)
				set @PLtotalThisYear = ISNULL((@PLtotal*(4-@month)/12),0)
				set @CLtotalThisYear = (@CLtotal*(4-@month)/12)
				set @sLtotalThisYear = (@SLtotal*(4-@month)/12)
			end
		else
			begin
				select @FinY2=year(dateadd(YY,1,@emp_LeaveSchemeAppliedFrom)),@finY1=year(@emp_LeaveSchemeAppliedFrom)
				--Addition of 3 due to financial year "march end"
				set @PLtotalThisYear = ISNULL((@PLtotal*(12-@month+1+3)/12),0)
				set @CLtotalThisYear = (@CLtotal*(12-@month+1+3)/12)
				set @sLtotalThisYear = (@SLtotal*(12-@month+1+3)/12)
				
			end
		set @finYear = @FinY1 + '-' + @FinY2

		declare @monthDiff int, @checkForData int, @TotalPLnew float,@PLold int, @CLold int,@finYearold varchar(15), @StrtMonth int, @endMonth int
			declare @Strtyear int,@endyear int
			--Month diff hold month in between lasteffective date to this new effctive date
			select @Strtyear=year(@emp_LeaveSchemeAppliedFrom), @endyear= year(@LeaveSchemeAppldfromOld)
			select @StrtMonth=month(@emp_LeaveSchemeAppliedFrom), @endMonth = month(@LeaveSchemeAppldfromOld)
			if(@Strtyear=@endyear)
				begin
				set @monthDiff=@StrtMonth-@endMonth
				end
			if(@Strtyear>@endyear)
				begin
				set @monthDiff=(@StrtMonth+12)-@endMonth
				end
		----old leav scheme
		select @PLtotal=ls_TotalPrevilegeLeave, @PLentitlement=ls_PLentitlement,@PLencashedEligibility=ls_PLencashedEligibility,
						@CLtotal=ls_CLtotal, @CLentitlement=ls_CLentitlement,@CLencashedEligibility=ls_CLencashedEligibility,
						@SLtotal=ls_SLtotal, @SLentitlement=ls_SLentitlement,@SLencashedEligibility=ls_SLencashedEligibility,
						@MLtotalPre=ls_MLtotalpre, @MLtotalPos=ls_MLtotalPos,@MLeligibility=ls_MLeligibility
			from tbl_master_LeaveScheme where ls_id=@LeaveSchemeOld
		declare @PLBFLastYear float,@PLCurrentYear float,@PLtotalAvailedThisYear float
        declare @PLCFNextYear float,@CLBFLastYear float,@CLCurrentYear float,@CLtotalAvailedThisYear float
        declare @CLCFNextYear float,@SLBFLastYear float,@SLCurrentYear float,@SLtotalAvailedThisYear float
        declare @SLCFNextYear float,@MLCurrentYear float
		--Old leave account balance
		select @PLBFLastYear=isnull(lab_PLBFLastYear,'0'),@PLCurrentYear=isnull(lab_PLCurrentYear,'0'),@PLtotalAvailedThisYear=lab_PLtotalAvailedThisYear
						,@PLCFNextYear=isnull(lab_PLCFNextYear,'0'),@CLBFLastYear=isnull(lab_CLBFLastYear,'0'),@CLCurrentYear=isnull(lab_CLCurrentYear,'0'),@CLtotalAvailedThisYear=isnull(lab_CLtotalAvailedThisYear,'0'),
						@CLCFNextYear=isnull(lab_CLCFNextYear,'0'),@SLBFLastYear=isnull(lab_SLBFLastYear,'0'),@SLCurrentYear=isnull(lab_SLCurrentYear,'0'),@SLtotalAvailedThisYear=isnull(lab_SLtotalAvailedThisYear,'0'),
						@SLCFNextYear=isnull(lab_SLCFNextYear,'0'),@MLCurrentYear=isnull(lab_MLCurrentYear,'0')
			from tbl_trans_LeaveAccountBalance where lab_effectiveDate=@LeaveSchemeAppldfromOld and lab_contactId=@emp_cntId

		--Now update old record in the table on the basis of month difference @monthDiff
		
		declare @PLCF float,@CLCF float,@SLCF float, @finYearNew varchar(10),@PLtotaloldYear float,@CLtotaloldYear float,@SLtotaloldYear float
		set @PLtotaloldYear = ISNULL((@PLtotal*(@monthDiff+1)/12),0)
		--print(@PLtotaloldYear)
		--print(@PLtotalAvailedThisYear)
		--print(@PLBFLastYear)
		set @PLCF = ISNULL(isnull(@PLtotaloldYear,0)-isnull(@PLtotalAvailedThisYear,0)+isnull(@PLBFLastYear,0),0)
		set @CLtotaloldYear = (isnull(@CLtotal,0)*(isnull(@monthDiff,0)+1)/12)
		set @CLCF = isnull(@CLtotaloldYear,0)-isnull(@CLtotalAvailedThisYear,0)+isnull(@CLBFLastYear,0)
		set @SLtotaloldYear = (isnull(@SLtotal,0)*(isnull(@monthDiff,0)+1)/12)
		set @SLCF = isnull(@SLtotaloldYear,0)-isnull(@SLtotalAvailedThisYear,0)+isnull(@SLBFLastYear,0)
		
		update tbl_trans_LeaveAccountBalance set lab_PLCurrentYear=@PLtotaloldYear,lab_PLCFNextYear=@PLCF,
							lab_CLCurrentYear=@CLtotaloldYear,lab_CLCFNextYear=@CLCF,lab_SLCurrentYear=@SLtotaloldYear,lab_SLCFNextYear=@SLCF
			where lab_effectiveDate=@LeaveSchemeAppldfromOld and lab_contactId=@emp_cntId

		--New Entry On the basis of new leave scheme
		if(@StrtMonth<4)
			select @FinY1=year(dateadd(YY,-1,@emp_LeaveSchemeAppliedFrom)),@finY2=year(@emp_LeaveSchemeAppliedFrom)
		else
			select @FinY2=year(dateadd(YY,1,@emp_LeaveSchemeAppliedFrom)),@finY1=year(@emp_LeaveSchemeAppliedFrom)
		set @finYearNew = @FinY1 + '-' + @FinY2
					
					
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
	End
END