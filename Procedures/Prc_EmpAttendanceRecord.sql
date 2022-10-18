IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Prc_EmpAttendanceRecord]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Prc_EmpAttendanceRecord] AS' 
END
GO

ALTER PROCEDURE [dbo].[Prc_EmpAttendanceRecord]
(
@UserId BIGINT,
@startDate datetime,
@EndDate datetime,
@EmpId  NVARCHAR(15)
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
 --declare @EndDate datetime=convert(datetime,dbo.eOfMonth(@startDate)) 
	
	DECLARE @intime datetime,@outTime datetime,@status varchar(30),@holidayStatus varchar(30),@Remarks nvarchar(500),@query nvarchar(max), @WeekNo bigint=1,@lateHour varchar(10),
	@workingHourMin numeric(18,0),@outTimeSql varchar(1000)
	DECLARE @emp_workinghours bigint 
	SELECT @emp_workinghours = emp_workinghours from tbl_trans_employeeCTC WITH(NOLOCK) where emp_id=(
	SELECT MAX(emp_id) FROM tbl_trans_employeeCTC where emp_cntId=@EmpId )

	WHILE(@startDate <=@EndDate)
		BEGIN		
		SELECT @intime=null,@outTime= null,@status=null

		SELECT @intime=In_Time ,@outTime=Out_Time ,@status=lvtype.Name  from tbl_Employee_Attendance att WITH(NOLOCK) 
		LEFT OUTER JOIN Config_LeaveType lvtype WITH(NOLOCK) ON att.Emp_status=lvtype.Code
		WHERE Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120) = convert(varchar(10),@startDate,120)
 
		IF NOT EXISTS(SELECT 1 FROM tbl_EmpAttendanceRecord_report WITH(NOLOCK) where EmpId=@EmpId and UserId=@UserId)
			BEGIN
				SET @query =N'insert tbl_EmpAttendanceRecord_report (EmpId,UserId) values('''+cast(@EmpId as varchar(10))+''','''+cast(@UserId as varchar(10))+''')'  
				EXEC sp_executesql @query 
			END
		
		--Calculate total Working Hour
		 
		UPDATE tbl_EmpAttendanceRecord_report SET 
		WorkingHourExpected=isnull(WorkingHourExpected,0) + isnull((select datediff(minute,BeginTime,EndTime) 
		FROM tbl_EmpWorkingHoursDetails WITH(NOLOCK) 
		WHERE hourId=@emp_workinghours and DayWeek =datepart(weekday,@startDate)),0)
		WHERE EmpId=@EmpId and UserId=@UserId

		SET @holidayStatus=null;
		SET @Remarks='';

		SELECT @holidayStatus=hol_Description from tbl_master_holiday WITH(NOLOCK) where  Convert(varchar(10),hol_DateOfHoliday,105) =  Convert(varchar(10),@startDate,105)

		select @Remarks=Remarks from tbl_Employee_Attendance WITH(NOLOCK) where  Convert(varchar(10),Att_Date,120) = Convert(varchar(10),@startDate,120) and Emp_InternalId=@EmpId

		set @Remarks= isnull(@Remarks,'')

		--select Remarks from tbl_Employee_Attendance where  Convert(varchar(10),Att_Date,120) =  Convert(varchar(10),'2018-11-07',120)
		set @query = N'update tbl_EmpAttendanceRecord_report set day'+cast(DATEPART(day,@startDate) as varchar(2))+'='''+isnull(@holidayStatus,'')+''',
		Remarks'+cast(DATEPART(day,@startDate) as varchar(2))+'='''+@Remarks+'''
		where EmpId='''+cast(@EmpId as varchar(10))+'''  and UserId='+ cast(@UserId as varchar(10))
		exec sp_executesql @query  

		IF EXISTS(select 1 from tbl_Employee_Attendance WITH(NOLOCK) where Emp_InternalId=@EmpId and convert(varchar(10),Att_Date,120) = convert(varchar(10),@startDate,120))
			BEGIN
				IF(@outTime is null)
					BEGIN
						SET	@outTimeSql='Null'
					END
				ELSE
					BEGIN
						SET	@outTimeSql=''''+cast(@outTime as varchar(20))+''''
					END
					 
				SET @query = N'update tbl_EmpAttendanceRecord_report set day'+cast(DATEPART(day,@startDate) as varchar(2))+'='''+case when @intime is null and @holidayStatus is not null then @holidayStatus else @status end+''',
				day'+cast(DATEPART(day,@startDate) as varchar(2))+'In='''+cast(@intime as varchar(20))+''',
				day'+cast(DATEPART(day,@startDate) as varchar(2))+ 'Out=' + @outTimeSql+' 
				where EmpId='''+cast(@EmpId as varchar(10))+'''  and UserId='+ cast(@UserId as varchar(10))
					
				EXEC sp_executesql @query  
						 
				update tbl_EmpAttendanceRecord_report 
				set WorkingHourActual=isnull(WorkingHourActual,0) + isnull(datediff(minute,@intime,@outTime),0) 
				where EmpId=@EmpId and UserId=@UserId
		
				IF(DATEDIFF(minute,(select dateAdd(Minute,Grace, BeginTime) from tbl_EmpWorkingHoursDetails WITH(NOLOCK) where hourId=@emp_workinghours and DayWeek =datepart(weekday,@startDate)),cast(@intime as time))>0)
					BEGIN
						SET @lateHour=null
						SELECT @lateHour=Convert(varchar(10), DATEDIFF(minute,(select dateAdd(Minute,Grace, BeginTime)  from tbl_EmpWorkingHoursDetails where hourId=@emp_workinghours and DayWeek =datepart(weekday,@startDate)),cast(@intime as time))/60)+':'+
						SUBSTRING('00'+	 Convert(varchar(10),DATEDIFF(minute,(select dateAdd(Minute,Grace, BeginTime)  from tbl_EmpWorkingHoursDetails where hourId=@emp_workinghours and DayWeek =datepart(weekday,@startDate)),cast(@intime as time))%60)
						,len('00'+	 Convert(varchar(10),DATEDIFF(minute,(select dateAdd(Minute,Grace, BeginTime)  from tbl_EmpWorkingHoursDetails where hourId=@emp_workinghours and DayWeek =datepart(weekday,@startDate)),cast(@intime as time))%60))-1,2)

						SET @query = N'update tbl_EmpAttendanceRecord_report set 
						day'+cast(DATEPART(day,@startDate) as varchar(2))+'Late='''+@lateHour+'''
						where EmpId='''+cast(@EmpId as varchar(10))+'''  and UserId='+ cast(@UserId as varchar(10))
							 
						EXEC sp_executesql @query
					END

				IF(DATEDIFF(minute,(select dateadd(minute,Grace,BeginTime)  from tbl_EmpWorkingHoursDetails where hourId=@emp_workinghours and DayWeek =datepart(weekday,@startDate)),cast(@intime as time))>0 and @status <>'Absent')
					BEGIN
						UPDATE tbl_EmpAttendanceRecord_report set LateCount=LateCount+1 where EmpId=@EmpId and UserId=@UserId
					END
			END
			   
			IF(@status in ('Compensatory off','Official Visit','Official Visit - Outstation','Present','Personal Delay','Paid holiday','Privilege Leave','Sick Leave'))
				UPDATE tbl_EmpAttendanceRecord_report set PresentFull =PresentFull+1 where EmpId=@EmpId and UserId=@UserId
			ELSE IF (@status in ('Half day(Casual)','Half day(Sick)'))
					update tbl_EmpAttendanceRecord_report set PresentHalf =PresentHalf+1 where EmpId=@EmpId and UserId=@UserId
			ELSE IF (@status ='Absent')
				UPDATE tbl_EmpAttendanceRecord_report set TotAbsent =TotAbsent+1 where EmpId=@EmpId and UserId=@UserId
			ELSE
				BEGIN
					IF EXISTS (SELECT 1 FROM tbl_EmpWorkingHoursDetails WITH(NOLOCK) where hourId=@emp_workinghours and DayWeek =datepart(weekday,@startDate))
						UPDATE tbl_EmpAttendanceRecord_report set TotAbsent =TotAbsent+1 where EmpId=@EmpId and UserId=@UserId
					ELSE
						BEGIN
							update tbl_EmpAttendanceRecord_report set WeeklyOff =WeeklyOff+1 where EmpId=@EmpId and UserId=@UserId
						END
				END
			  IF(datepart(WEEKDAY,@startDate)=7)
				SET @WeekNo=@WeekNo+1
			SET @startDate = dateadd(day,1,@startDate)
		END

	SET NOCOUNT OFF
END