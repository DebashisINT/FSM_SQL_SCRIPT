IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EmployeeInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [EmployeeInsert] AS' 
END
GO

ALTER PROCEDURE [dbo].[EmployeeInsert]
(
	--@cnt_id		int,
	@cnt_ucc 		varchar(10),
	@cnt_salutation		int,
	-- Rev 5.0
	--@cnt_firstName		varchar(50),
	@cnt_firstName		varchar(150),
	-- End of Rev 5.0
	@cnt_middleName	varchar(50),
	@cnt_lastName		varchar(50),
	@cnt_shortName	varchar(30),
	@cnt_branchId		int,
	@cnt_sex		int,
	@cnt_maritalStatus	int,
	@cnt_DOB		datetime,
	@cnt_anniversaryDate	datetime,
	@cnt_legalStatus 	int,
	@cnt_education		int,
/*	@cnt_profession	int,
	@cnt_organization 	varchar(50),
	@cnt_jobResponsibility	int,
	@cnt_designation	int,
	@cnt_industry		int,	*/
	@cnt_contactSource 	int,
	@cnt_referedBy		varchar(50),
	--@cnt_relation		int,
	@cnt_contactType 	varchar(50),
	--@cnt_contactStatus	int,
	--@cnt_LeadId		varchar(20),
	@lastModifyUser	varchar(20),
	@UserContactID	varchar(20),
	@bloodgroup		varchar(20),
	@WebLogIn		varchar(20),
	@PassWord		varchar(50),
	-- Rev 4.0
	@ChannelType varchar(max)= NULL,
	@Circle varchar(max)= NULL,
	@Section varchar(max)= NULL,
	@DefaultType varchar(50)=NULL,
	-- End of Rev 4.0
	--@IsShowPlanDetails varchar(10)=0,
	@emp_dateofJoining datetime=null,
	@result 	     varchar(50)	output
)
-- with encryption
AS
/***********************************************************************************************************************************
1.0		03-02-2020		Tanmoy						insert date of joining in tbl_master_employee 
2.0		19-02-2020		Tanmoy						move settings master_contact to master_user 
3.0		17/12/2021		Sanchita		v2.0.27		Resolve issue in Employee Import. Refer: 24554
4.0						Sanchita		v2.0.26		Three new multi select window in General Tab - Channel, Section, Circle . Refer: 24646
5.0		22-05-2023		Sanchita		V2.0.40		The first name field of the employee master should consider 150 character from the application end.  
													Refer: 26187
***********************************************************************************************************************************/
begin
declare @uniqueCode varchar(50)
-- Rev 4.0
DECLARE @sqlStrTable NVARCHAR(MAX) =''
-- End of Rev 4.0
declare @prifixId 	varchar(10),
	@prifixIdN 	varchar(20),
	@maxID 	varchar(20),
	@maxIDNO 	int,
	@InternalId 	varchar(20),
	@id2	 	varchar(30)
	select @prifixId= prefix_Name from tbl_master_prefix where prefix_type='Employee'
	Select @prifixIdN= @prifixId + upper(LEFT(@cnt_firstName,1))
	select @maxID= max(cnt_internalid) from tbl_master_contact where cnt_internalid like @prifixIdN+'%'
	if(@maxID is null)
	begin
		set @InternalId=@prifixIdN+'0000001'
	end
	else
	begin
		select @maxIDNO = RIGHT(@maxID,7)+1
		if(@maxIDNO<=9)
			begin
			set @id2=@prifixIdN+'000000'
			end
		if(@maxIDNO>9 and @maxIDNO<=99)
			begin
			set @id2=@prifixIdN+'00000'
			end
		if(@maxIDNO>99 and @maxIDNO<=999)
			begin
			set @id2=@prifixIdN+'0000'
			end
		if(@maxIDNO>999 and @maxIDNO<=9999)
			begin
			set @id2=@prifixIdN+'000'
			end
		if(@maxIDNO>9999 and @maxIDNO<=99999)
			begin
			set @id2=@prifixIdN+'00'
			end
		if(@maxIDNO>99999 and @maxIDNO<=999999)
			begin
			set @id2=@prifixIdN+'0'
			end
		
		set @InternalId = @id2 + cast(@maxIDNO as varchar(10))
	end
		select @uniqueCode=emp_uniqueCode from tbl_master_employee where emp_uniqueCode=@cnt_shortName
		if(@uniqueCode=@cnt_shortName)
		begin		
			if(@cnt_shortName='')
			begin
			
				INSERT INTO  tbl_master_contact 
				( cnt_ucc ,cnt_internalId, cnt_salutation, cnt_firstName, cnt_middleName, cnt_lastName, cnt_shortName, cnt_branchId, cnt_sex, cnt_maritalStatus, cnt_DOB, cnt_anniversaryDate, 
				cnt_legalStatus, cnt_education, /*cnt_profession, cnt_organization, cnt_jobResponsibility, cnt_designation, cnt_industry,*/ cnt_contactSource, cnt_referedBy,/* cnt_relation,*/ cnt_contactType,
				/* cnt_contactStatus,*/ cnt_bloodgroup,CreateDate, CreateUser,WebLogIn,PassWord)
				-- Rev 3.0
				--VALUES(@cnt_ucc,@InternalId,@cnt_salutation,UPPER(@cnt_firstName),UPPER(@cnt_middleName),UPPER(@cnt_lastName),@cnt_shortName,@cnt_branchId,@cnt_sex,@cnt_maritalStatus,@cnt_DOB,
				VALUES(@cnt_ucc,@InternalId,@cnt_salutation,UPPER(isnull(@cnt_firstName,'')),UPPER(isnull(@cnt_middleName,'')),UPPER(isnull(@cnt_lastName,'')),@cnt_shortName,@cnt_branchId,@cnt_sex,@cnt_maritalStatus,@cnt_DOB,
				-- End of Rev 3.0
				@cnt_anniversaryDate,@cnt_legalStatus,@cnt_education,/*@cnt_profession,@cnt_organization,@cnt_jobResponsibility,@cnt_designation,@cnt_industry,*/@cnt_contactSource,
				@cnt_referedBy/*,@cnt_relation*/,@cnt_contactType,/*@cnt_contactStatus,*/@bloodgroup,getdate(),@lastModifyUser,@WebLogIn,@PassWord)
					


				--Entering data to Employee table
				-- Rev 4.0
				--Insert into tbl_master_employee (emp_contactId,emp_uniqueCode,CreateUser,emp_dateofJoining,CreateDate) values(@InternalId,@cnt_shortName,@lastModifyUser,@emp_dateofJoining,getdate())
				
				Insert into tbl_master_employee (emp_contactId,emp_uniqueCode,CreateUser,emp_dateofJoining,CreateDate, DefaultType) 
					values(@InternalId,@cnt_shortName,@lastModifyUser,@emp_dateofJoining,getdate(),@DefaultType)
				-- End of Rev 4.0
				
				-- Rev 4.0
				if(@ChannelType is not null and @ChannelType<>'')
				begin
					set @ChannelType = REPLACE(''''+@ChannelType+'''',',',''',''')

					SET @sqlStrTable =''
					SET @sqlStrTable=' insert into Employee_ChannelMap select ch_id,'''+@InternalId+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Channel where ch_id in ('+@ChannelType+') '
					EXEC SP_EXECUTESQL @sqlStrTable
				end

				if(@Circle is not null and @Circle<>'')
				begin
					set @Circle = REPLACE(''''+@Circle+'''',',',''',''')

					SET @sqlStrTable =''
					SET @sqlStrTable=' insert into Employee_CircleMap select crl_id,'''+@InternalId+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Circle where crl_id in ('+@Circle+') '
					EXEC SP_EXECUTESQL @sqlStrTable
				end

				if(@Section is not null and @Section<>'')
				begin
					set @Section = REPLACE(''''+@Section+'''',',',''',''')

					SET @sqlStrTable =''
					SET @sqlStrTable=' insert into Employee_SectionMap select sec_id,'''+@InternalId+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Section where sec_id in ('+@Section+') '
					EXEC SP_EXECUTESQL @sqlStrTable
				end
				-- End of Rev 4.0

				--Entering data to Address table
			--	insert into tbl_master_address (add_entity,add_cntId,add_addressType,add_address1,add_address2,add_address3,add_landMark,add_country,add_state,add_city,add_pin) values('employee',@InternalId,'','','','','',0,0,'','')

				--Entering data to Phone table
			--	insert into tbl_master_phoneFax (phf_entity,phf_cntId,phf_type,phf_countryCode,phf_areaCode,phf_phoneNumber) values('employee',@InternalId,'','','','')

				--Entering data to Email  table
			---	insert into tbl_master_email (eml_entity,eml_cntId,eml_type,eml_email,eml_ccEmail,eml_website) values('employee',@InternalId,'','','','')
				--Entering data to EducationProfessional table
			--	insert into tbl_master_educationProfessional (edu_internalId,edu_degree,edu_country,edu_state) values(@InternalId,0,0,0)
			--	insert into tbl_master_contactExchange(crg_cntID,crg_company) values(@InternalId,'0')
				set
				@result= @InternalId	
			end
			else
			begin
				raiserror('Short Name Not Duplicate',16,1)
			end
		end
		else
		begin
			INSERT INTO  tbl_master_contact 
				( cnt_ucc ,cnt_internalId, cnt_salutation, cnt_firstName, cnt_middleName, cnt_lastName, cnt_shortName, cnt_branchId, cnt_sex, cnt_maritalStatus, cnt_DOB, cnt_anniversaryDate, 
				cnt_legalStatus, cnt_education, /*cnt_profession, cnt_organization, cnt_jobResponsibility, cnt_designation, cnt_industry,*/ cnt_contactSource, cnt_referedBy,/* cnt_relation,*/ cnt_contactType,
				/* cnt_contactStatus,*/ cnt_bloodgroup,CreateDate, CreateUser) 
				-- Rev 3.0
				--VALUES(@cnt_ucc,@InternalId,@cnt_salutation,UPPER(@cnt_firstName),UPPER(@cnt_middleName),UPPER(@cnt_lastName),@cnt_shortName,@cnt_branchId,@cnt_sex,@cnt_maritalStatus,@cnt_DOB,
				VALUES(@cnt_ucc,@InternalId,@cnt_salutation,UPPER(isnull(@cnt_firstName,'')),UPPER(isnull(@cnt_middleName,'')),UPPER(isnull(@cnt_lastName,'')),@cnt_shortName,@cnt_branchId,@cnt_sex,@cnt_maritalStatus,@cnt_DOB,
				-- End of Rev 3.0
				@cnt_anniversaryDate,@cnt_legalStatus,@cnt_education,/*@cnt_profession,@cnt_organization,@cnt_jobResponsibility,@cnt_designation,@cnt_industry,*/@cnt_contactSource,
				@cnt_referedBy/*,@cnt_relation*/,@cnt_contactType,/*@cnt_contactStatus,*/@bloodgroup,getdate(),@lastModifyUser)
					


				--Entering data to Employee table
				-- Rev 4.0
				--Insert into tbl_master_employee (emp_contactId,emp_uniqueCode,CreateUser,emp_dateofJoining,CreateDate) values(@InternalId,@cnt_shortName,@lastModifyUser,@emp_dateofJoining,getdate())
				
				Insert into tbl_master_employee (emp_contactId,emp_uniqueCode,CreateUser,emp_dateofJoining,CreateDate, DefaultType) 
					values(@InternalId,@cnt_shortName,@lastModifyUser,@emp_dateofJoining,getdate(),@DefaultType)
				-- End of Rev 4.0

				-- Rev 4.0
				if(@ChannelType is not null and @ChannelType<>'')
				begin
					set @ChannelType = REPLACE(''''+@ChannelType+'''',',',''',''')

					SET @sqlStrTable =''
					SET @sqlStrTable=' insert into Employee_ChannelMap select ch_id,'''+@InternalId+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Channel where ch_id in ('+@ChannelType+') '
					EXEC SP_EXECUTESQL @sqlStrTable
				end

				if(@Circle is not null and @Circle<>'')
				begin
					set @Circle = REPLACE(''''+@Circle+'''',',',''',''')

					SET @sqlStrTable =''
					SET @sqlStrTable=' insert into Employee_CircleMap select crl_id,'''+@InternalId+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Circle where crl_id in ('+@Circle+') '
					EXEC SP_EXECUTESQL @sqlStrTable
				end

				if(@Section is not null and @Section<>'')
				begin
					set @Section = REPLACE(''''+@Section+'''',',',''',''')

					SET @sqlStrTable =''
					SET @sqlStrTable=' insert into Employee_SectionMap select sec_id,'''+@InternalId+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Section where sec_id in ('+@Section+') '
					EXEC SP_EXECUTESQL @sqlStrTable
				end
				-- End of Rev 4.0

				--Entering data to Address table
				--insert into tbl_master_address (add_entity,add_cntId,add_addressType,add_address1,add_address2,add_address3,add_landMark,add_country,add_state,add_city,add_pin) values('employee',@InternalId,'','','','','',0,0,'','')

				--Entering data to Phone table
				--insert into tbl_master_phoneFax (phf_entity,phf_cntId,phf_type,phf_countryCode,phf_areaCode,phf_phoneNumber) values('employee',@InternalId,'','','','')

				--Entering data to Email  table
				--insert into tbl_master_email (eml_entity,eml_cntId,eml_type,eml_email,eml_ccEmail,eml_website) values('employee',@InternalId,'','','','')
				--Entering data to EducationProfessional table
				---insert into tbl_master_educationProfessional (edu_internalId,edu_degree,edu_country,edu_state) values(@InternalId,0,0,0)
				--insert into tbl_master_contactExchange(crg_cntID,crg_company) values(@InternalId,'0')
				set
				@result= @InternalId	
		end
end