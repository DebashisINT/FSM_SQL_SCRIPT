IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Prc_AttendanceSystem]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Prc_AttendanceSystem] AS' 
END
GO  
 
ALTER PROCEDURE [dbo].[Prc_AttendanceSystem]
(
@Action NVARCHAR(100) = null,
@SearchKey NVARCHAR(100) = null,
@EmpId NVARCHAR(20) = null,
@startDate datetime = null,
@FinYear NVARCHAR(20)= null,
@Att_Date smalldatetime = null,
@In_Time datetime=null,
@Out_Time datetime= null,
@User bigint=null,
@Emp_status NVARCHAR(10) = null,
@UserHierchy NVARCHAR(MAX)=null,
@BranchHierchy NVARCHAR(MAX) = null,
@branchId bigint=null,
@Remarks NVARCHAR(1000)=null
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @insertquery NVARCHAR(MAX)
	DECLARE @user_contactId NVARCHAR(15),@emp_id BIGINT

	IF(@Action='Get10Emp')
		BEGIN
			SELECT @user_contactId=user_contactId FROM tbl_master_user WITH(NOLOCK) WHERE user_id=@User

			IF EXISTS(SELECT 1 FROM tbl_master_employee WITH(NOLOCK) WHERE emp_contactId=@user_contactId and Usehierchy=1)
				BEGIN
					SELECT TOP 10 cnt_internalId, cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) Name,
					cnt_shortName EmpCode from tbl_master_contact cnt WITH(NOLOCK) 
					INNER JOIN [dbo].[fn_getEmpHierarchy](@User) child on cnt.cnt_internalId = child.internalId
					where cnt_contactType='EM'
					and (cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) 
					like '%' + @SearchKey + '%' or cnt_shortName like '%' + @SearchKey + '%' ) 
					ORDER BY len(cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,''))), 
					cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) asc
				END
			ELSE
				BEGIN
					SELECT TOP 10 cnt_internalId, cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) Name,
					cnt_shortName EmpCode from tbl_master_contact cnt WITH(NOLOCK) 
					where cnt_contactType='EM'
					and (cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) 
					like '%' + @SearchKey + '%' or cnt_shortName like '%' + @SearchKey + '%' ) 
					ORDER BY len(cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,''))), 
					cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) asc
				END
		END
	ELSE IF(@Action='SaveAttendance')
		BEGIN   
			INSERT INTO tbl_EmpAttendanceDetails(Emp_InternalId) values(@EmpId)
			   
			IF NOT EXISTS(SELECT 1 FROM tbl_Employee_Attendance WITH(NOLOCK) where convert(varchar(10),Att_Date,120)=convert(varchar(10),getdate(),120) and Emp_InternalId=@EmpId)
				BEGIN			     
					INSERT INTO tbl_Employee_Attendance(Emp_InternalId,Att_Date,In_Time,YYMM,Emp_status)
					VALUES(@EmpId,getdate(),getdate(),substring(CONVERT(nvarchar(6), getdate(), 112),3,4),'P')
				  
					IF NOT EXISTS (SELECT * FROM tbl_EmpWiseAttendanceStatus WITH(NOLOCK) WHERE Emp_InternalId=@EmpId and YYMM=substring(CONVERT(nvarchar(6), getdate(), 112),3,4))
						BEGIN 
							set @insertquery = N'insert into tbl_EmpWiseAttendanceStatus(Emp_InternalId,YYMM,day'+CONVERT(varchar(5),datepart(day,getdate()))+')
							values ('''+@EmpId+''','+substring(CONVERT(nvarchar(6), getdate(), 112),3,4)+',''P'')'
							 
							exec sp_executesql @insertquery
						END
					ELSE
						BEGIN
							set @insertquery = N'update tbl_EmpWiseAttendanceStatus set day'+CONVERT(varchar(5),datepart(day,getdate()))+'=''P'' where 
							Emp_InternalId='''+ @EmpId + ''' and YYMM='''+substring(CONVERT(nvarchar(6), getdate(), 112),3,4)+''''
							exec sp_executesql @insertquery
						END
				END
			ELSE
				BEGIN
					UPDATE tbl_Employee_Attendance set Out_Time=getdate() where convert(varchar(10),Att_Date,120)=convert(varchar(10),getdate(),120) and Emp_InternalId=@EmpId 
				END
		END
	ELSE IF(@Action='GetEmpAttendanceByMonth')
		BEGIN
			declare @emp_workinghours bigint ,@UpdateDayPermission int
			select @emp_workinghours = emp_workinghours from tbl_trans_employeeCTC WITH(NOLOCK) where emp_id=(
			select max(emp_id) from tbl_trans_employeeCTC WITH(NOLOCK) where emp_cntId=@EmpId )

			select @UpdateDayPermission=UpdateDayPermission+1 from tbl_master_employee WITH(NOLOCK) where emp_contactId=
			(select user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@User)
			--emp_contactId=@EmpId				

			declare @EndDate datetime=convert(datetime,dbo.eOfMonth(@startDate))

			declare @AttTable table(
			AttDate datetime,
			Intime datetime,
			Outtime datetime,
			AttStatus varchar(5),
			AttStatusName varchar(50),
			Remarks varchar(2000),
			ShouldEditVissible varchar(50) 
			)				 

			IF(@EmpId != '')
				BEGIN
					WHILE(@startDate <=@EndDate)
						BEGIN
							IF EXISTS(SELECT 1 FROM tbl_Employee_Attendance WITH(NOLOCK) where Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120) = convert(varchar(10),@startDate,120))
								BEGIN
									INSERT INTO @AttTable select Att_Date ,In_Time ,Out_Time,Emp_status,Name
									,isnull(REPLACE(Remarks, CHAR(10), '\n'),'')Remarks,'display:none'
									from tbl_Employee_Attendance atd WITH(NOLOCK) 
									INNER JOIN Config_LeaveType ltype WITH(NOLOCK) ON atd.Emp_status = ltype.Code
									where Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120) = convert(varchar(10),@startDate,120)
								END
							ELSE
								BEGIN
									IF EXISTS (SELECT 1 FROM tbl_EmpWorkingHoursDetails WITH(NOLOCK) where hourId=@emp_workinghours and DayWeek =datepart(weekday,@startDate))
									insert into @AttTable values(@startDate,null,null,'AB',
									isnull((select hol_Description  from tbl_master_holiday where  Convert(varchar(10),hol_DateOfHoliday,105) =  Convert(varchar(10),@startDate,105)),'Absent')
									,'','display:none')
									else 
									insert into @AttTable values(@startDate,null,null,'WO',
									isnull((select hol_Description  from tbl_master_holiday where  Convert(varchar(10),hol_DateOfHoliday,105) =  Convert(varchar(10),@startDate,105)),'Weekly Off')
									,'','display:none')
								END

							SET @startDate = dateadd(day,1,@startDate)
						END
				END
				 
				update @AttTable set ShouldEditVissible= case when 
				CONVERT(varchar(10),DATEADD(day,@UpdateDayPermission,AttDate),120)>Convert(varchar(10),getdate(),120) then 'display:inline-block' else 'display:none' end
					
				update @AttTable set ShouldEditVissible='display:none' where convert(varchar(10),AttDate,120)>convert(varchar(10),getdate(),120)


			--select row_number() over(order by AttDate asc ) slno,*,
			--cast((DATEDIFF(second,Intime,Outtime)/60)/60 as varchar(2)) +':'+
			--SUBSTRING('00'+cast(DATEDIFF(MINUTE, Intime,Outtime)%60 as varchar(10)),len('00'+cast(DATEDIFF(MINUTE, Intime,Outtime)%60 as varchar(10)))-1,2)
			-- WorkingHour   from @AttTable


				select row_number() over(order by AttDate asc ) slno,*,
				convert(varchar(5),DateDiff(s, Intime, Outtime)/3600)+':'+RIGHT('00'++convert(varchar(5),DateDiff(s, Intime, Outtime)%3600/60),2)+':'
			+RIGHT('00'+convert(varchar(5),(DateDiff(s, Intime, Outtime)%60)),2)
				WorkingHour   from @AttTable
		END
	ELSE IF (@action='GetFinacialYearBasedQouteDate')  
		BEGIN  
			SELECT CONVERT(date,finyear_startdate) finYearStartDate ,CONVERT(date,FinYear_EndDate) finYearEndDate from  dbo.Master_FinYear where FinYear_Code=@FinYear
		END			
	ELSE IF (@action='updateAttendance')
		BEGIN				
			IF EXISTS(SELECT 1 FROM tbl_Employee_Attendance  WITH(NOLOCK) where Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120)=convert(varchar(10),@Att_Date,120) )
				BEGIN
					update tbl_Employee_Attendance 
						set In_Time=@In_Time,Out_Time=@Out_Time,UpdatedBy=@User,UpdatedOn=getdate(),Emp_status=@Emp_status,Remarks=@Remarks
						where Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120)=convert(varchar(10),@Att_Date,120) 

					set @insertquery = N'update tbl_EmpWiseAttendanceStatus set day'+CONVERT(varchar(5),datepart(day,@Att_Date))+'='''+@Emp_status+''' where 
					Emp_InternalId='''+ @EmpId + ''' and YYMM='''+substring(CONVERT(nvarchar(6), @Att_Date, 112),3,4)+''''
					exec sp_executesql @insertquery
				END
			ELSE
				BEGIN
					insert into tbl_Employee_Attendance (Emp_InternalId,Att_Date,In_Time,Out_Time,UpdatedBy,UpdatedOn,YYMM,Emp_status,Remarks)
					values(@EmpId,@Att_Date,@In_Time,@Out_Time,@User,getdate(),substring(CONVERT(nvarchar(6), @Att_Date, 112),3,4),@Emp_status,@Remarks)	

					set @insertquery = N'insert into tbl_EmpWiseAttendanceStatus(Emp_InternalId,YYMM,day'+CONVERT(varchar(5),datepart(day,@Att_Date))+')
					values ('''+@EmpId+''','+substring(CONVERT(nvarchar(6), @Att_Date, 112),3,4)+','''+@Emp_status+''')'
							 
					exec sp_executesql @insertquery
				END
			insert into tbl_EmpAttendance_UpdateLog(Emp_InternalId ,Att_Date,In_Time,Out_Time,UpdatedBy,UpdatedOn,Emp_status,Remarks)
			values(@EmpId,@Att_Date,@In_Time,@Out_Time,@User,getdate(),@Emp_status,@Remarks)
		END
	ELSE IF(@Action='GetEmploggedByMonth')
		BEGIN			 
			declare @EndDate1 datetime=convert(datetime,dbo.eOfMonth(@startDate))

			declare @AttTable1 table(
			AttDate datetime,
			Intime datetime,
			Outtime datetime
			)
			IF(@EmpId != '')
				BEGIN
					WHILE(@startDate <=@EndDate1)
						BEGIN
							IF EXISTS(SELECT 1 FROM tbl_Employee_Attendance WITH(NOLOCK) where Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120) = convert(varchar(10),@startDate,120))
								BEGIN
									insert into @AttTable1 select Att_Date ,In_Time ,Out_Time from tbl_Employee_Attendance 
									where Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120) = convert(varchar(10),@startDate,120)
								END
							ELSE
								BEGIN
									INSERT INTO @AttTable1 values(@startDate,null,null)
								END

						SET @startDate = dateadd(day,1,@startDate)
	
						END
				END
			select AttDate,isnull((DATEDIFF(second,Intime,Outtime)/60)/60,0)WorkingHour,isnull((DATEDIFF(second,Intime,Outtime)/60)%60,0)WorkingMin,
			convert(varchar(10),AttDate,112) keyString
			--isnull(
			--cast((DATEDIFF(second,Intime,Outtime)/60)/60 as varchar(2)) +':'+cast((DATEDIFF(second,Intime,Outtime)/60)%60 as varchar(2))+':'
			--+cast(DATEDIFF(second,Intime,Outtime)%60 as varchar(2)),0) WorkingHour 
			from @AttTable1
		END
	ELSE IF (@action='GetLeaveType')  
		BEGIN  
			SELECT Code,Name from Config_LeaveType  order by OrderBy
		END
	ELSE IF (@action='GetEmpNameByUserid') 
		BEGIN
			select cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) Name,cnt_internalId
			from tbl_master_contact WITH(NOLOCK) where cnt_internalId =(
			select user_contactId from tbl_master_user WITH(NOLOCK) where user_id=@User)
		END
	ELSE IF (@action='GetBranchList') 
		BEGIN
			select  s into #branchList  from dbo.GetSplit(',',@BranchHierchy) 

			SELECT 0 branch_id,'-All-'branch_description  
			UNION ALL
			SELECT branch_id,branch_description  from tbl_master_branch br WITH(NOLOCK) 
			INNER JOIN #branchList b on br.branch_id = b.s

			DROP TABLE #branchList
		END			
	ELSE IF(@Action='Get10EmpByBranch')
		BEGIN				
			create table #branchListTemp(id bigint)

		IF(@branchId=0) 
			INSERT INTO #branchListTemp select  s from dbo.GetSplit(',',@BranchHierchy)  
		ELSE
			INSERT INTO #branchListTemp values (@branchId)
					
		SELECT @user_contactId=user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@User

		IF EXISTS(SELECT 1 FROM tbl_master_employee  where emp_contactId=@user_contactId and Usehierchy=1)
			BEGIN
				select Top 10 cnt_internalId, cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) Name,
				cnt_shortName EmpCode from tbl_master_contact cnt WITH(NOLOCK) 
				INNER JOIN [dbo].[fn_getEmpHierarchy](@User) child on cnt.cnt_internalId = child.internalId
				INNER JOIN #branchListTemp br on br.id = cnt.cnt_branchid
				where cnt_contactType='EM'
				and (cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) 
				like '%' + @SearchKey + '%' or cnt_shortName like '%' + @SearchKey + '%' ) 
				order by len(cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,''))), 
				cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) asc
			END
		ELSE
			BEGIN
				SELECT TOP 10 cnt_internalId, cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) Name,
				cnt_shortName EmpCode from tbl_master_contact cnt WITH(NOLOCK) 
				INNER JOIN #branchListTemp br on br.id = cnt.cnt_branchid
				where cnt_contactType='EM'
				and (cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) 
				like '%' + @SearchKey + '%' or cnt_shortName like '%' + @SearchKey + '%' ) 
				order by len(cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,''))), 
				cnt_firstName+space(1)+ltrim(ltrim(space(1)+isnull(cnt_middleName,''))+space(1)+isnull(cnt_lastName,'')) asc
			END
		END
	
	SET NOCOUNT OFF
END