IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_DailyAttRegister]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_DailyAttRegister] AS' 
END
GO

ALTER PROCEDURE [dbo].[prc_DailyAttRegister]
(
@action NVARCHAR(50) = null,
@BranchList NVARCHAR(max) = null,
@rptDate datetime = null,
@searchKey NVARCHAR(50)=null,
@ShowInActive bit=null,
@considerPayBranch bit=null
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF(@action ='GenerateReport')
		BEGIN
			SELECT s INTO #branch FROM dbo.GetSplit(',',@BranchList)  
			 declare @emp_workinghours bigint,@EmpId NVARCHAR(10),@EmpCode NVARCHAR(30),@EmpName NVARCHAR(100)
			 declare @AttTable table(
					EmpCode NVARCHAR(30),
					EmpName NVARCHAR(100),
					AttDate datetime,
					Intime datetime,
					Outtime datetime, 
					AttStatusName NVARCHAR(50),
					LateHour NVARCHAR(20) 
					)

			declare dbcur cursor for
			select cnt_internalId,cnt_UCC,cnt_firstName + Rtrim(space(1)+ isnull(cnt_lastName,''))+ space(1)+isnull(cnt_middleName,'')  
			from tbl_master_contact cnt WITH(NOLOCK) 
			INNER JOIN tbl_master_employee emp WITH(NOLOCK) ON cnt.cnt_internalId = emp.emp_contactId 
			INNER JOIN #branch br WITH(NOLOCK) ON br.s=case when @considerPayBranch=1 THEN ISNULL(Payroll_branch,cnt.cnt_branchid) ELSE cnt.cnt_branchid END 
			WHERE cnt_contactType='EM' and Inactive in (0,@ShowInActive)

			OPEN dbcur 
			FETCH NEXT FROM dbcur INTO @EmpId,@EmpCode,@EmpName

			 WHILE @@FETCH_STATUS=0
				BEGIN
					SELECT @emp_workinghours = emp_workinghours FROM tbl_trans_employeeCTC WITH(NOLOCK) WHERE emp_id=(
					SELECT MAX(emp_id) FROM tbl_trans_employeeCTC WITH(NOLOCK) WHERE emp_cntId=@EmpId )
				  
					IF EXISTS(SELECT 1 FROM tbl_Employee_Attendance WITH(NOLOCK) WHERE Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120) = convert(varchar(10),@rptDate,120))
						BEGIN
							INSERT INTO @AttTable select @EmpCode,@EmpName,Att_Date ,In_Time ,Out_Time,Name,												
							case when (select DATEDIFF(minute,(select dateAdd(Minute,Grace, BeginTime)  from tbl_EmpWorkingHoursDetails where hourId=@emp_workinghours and DayWeek =datepart(weekday,@rptDate)),cast(In_Time as time)))>0 then 
							Convert(varchar(10), DATEDIFF(minute,(select dateAdd(Minute,Grace, BeginTime)  from tbl_EmpWorkingHoursDetails where hourId=@emp_workinghours and DayWeek =datepart(weekday,@rptDate)),cast(In_Time as time))/60)+':'+
							SUBSTRING('00'+	 Convert(varchar(10),DATEDIFF(minute,(select dateAdd(Minute,Grace, BeginTime)  from tbl_EmpWorkingHoursDetails where hourId=@emp_workinghours and DayWeek =datepart(weekday,@rptDate)),cast(In_Time as time))%60)
							,len('00'+	 Convert(varchar(10),DATEDIFF(minute,(select dateAdd(Minute,Grace, BeginTime)  from tbl_EmpWorkingHoursDetails where hourId=@emp_workinghours and DayWeek =datepart(weekday,@rptDate)),cast(In_Time as time))%60))-1,2)
							else null end
							from tbl_Employee_Attendance atd WITH(NOLOCK) 
							INNER JOIN Config_LeaveType ltype WITH(NOLOCK) ON atd.Emp_status = ltype.Code
							WHERE Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120) = convert(varchar(10),@rptDate,120)
						END
					ELSE
						BEGIN
							IF EXISTS (SELECT 1 FROM tbl_EmpWorkingHoursDetails WITH(NOLOCK) where hourId=@emp_workinghours and DayWeek =datepart(weekday,@rptDate))
								INSERT INTO @AttTable values(@EmpCode,@EmpName,@rptDate,null,null,
								isnull((select hol_Description  from tbl_master_holiday where  Convert(varchar(10),hol_DateOfHoliday,105) =  Convert(varchar(10),@rptDate,105)),'Absent')
								,null)
								else 
								insert into @AttTable values(@EmpCode,@EmpName,@rptDate,null,null,
								isnull((select hol_Description  from tbl_master_holiday where  Convert(varchar(10),hol_DateOfHoliday,105) =  Convert(varchar(10),@rptDate,105)),'Weekly Off'),
								null
								)
						END

					 FETCH NEXT FROM dbcur INTO @EmpId,@EmpCode,@EmpName
				END
			CLOSE dbcur
			DEALLOCATE dbcur

			select row_number() over(order by AttDate asc ) slno,*,
			convert(varchar(5),DateDiff(s, Intime, Outtime)/3600)+':'+RIGHT('00'++convert(varchar(5),DateDiff(s, Intime, Outtime)%3600/60),2)+':'
			+RIGHT('00'+convert(varchar(5),(DateDiff(s, Intime, Outtime)%60)),2) WorkingHour   from @AttTable
		END
	ELSE IF(@action ='GetEmail')
		BEGIN
			 SELECT TOP 10 eml_email  from tbl_master_email email WITH(NOLOCK) 
			 INNER JOIN tbl_master_contact cnt WITH(NOLOCK) ON email.eml_cntId = cnt.cnt_internalId where cnt_contactType='EM' and eml_email<>''
			 and eml_email like '%'+ @searchKey+'%'
		END

	SET NOCOUNT OFF
END