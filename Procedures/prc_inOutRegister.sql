IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_inOutRegister]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_inOutRegister] AS' 
END
GO

ALTER PROCEDURE [prc_inOutRegister]
(
@userid bigint=NULL,
@date datetime = NULL,
@Empid varchar(100)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @timeTable TABLE(
	inout DATETIME
	)	  
	--Fetch emp details
	INSERT INTO tbl_report_inOutRegister (internalId,Empcode,EmpName,userId)
	SELECT cnt_internalId,cnt_UCC,cnt_firstName+space(1)+ltrim(isnull(cnt_middleName,'')+space(1))+isnull(cnt_lastName,''),@userid
	FROM tbl_master_contact WHERE cnt_internalId=@Empid

	INSERT INTO @timeTable (inout) 
	SELECT In_Time FROM tbl_Employee_Attendance WITH(NOLOCK) WHERE Emp_InternalId=@Empid
	and convert(varchar(10),Att_Date ,120) = convert(varchar(10),@date,120)

	INSERT INTO @timeTable (inout) 
	SELECT LogTime from tbl_EmpAttendanceDetails WITH(NOLOCK) WHERE Emp_InternalId=@Empid
	and convert(varchar(10),LogTime,120) = convert(varchar(10),@date,120)
	and LogTime not in ((select max(LogTime)  from tbl_EmpAttendanceDetails where Emp_InternalId=@Empid
	and convert(varchar(10),LogTime,120) = convert(varchar(10),@date,120)),(select min(LogTime)  from tbl_EmpAttendanceDetails where Emp_InternalId=@Empid
	and convert(varchar(10),LogTime,120) = convert(varchar(10),@date,120)))

	INSERT INTO @timeTable (inout) 
	SELECT Out_Time from tbl_Employee_Attendance WITH(NOLOCK) WHERE Emp_InternalId=@Empid
	and convert(varchar(10),Att_Date ,120) = convert(varchar(10),@date,120)
	 
	DECLARE @timeStamp datetime,@inorOut int=1,@sqlStr varchar(max),@slot int=1,@incount int =0,@outCount int=0
	DECLARE dbcur cursor for select inout from @timeTable where inout is not null ORDER BY inout
	OPEN dbcur
	FETCH NEXT FROM dbcur into @timeStamp
	WHILE @@FETCH_STATUS=0 and @inorOut<=20
		BEGIN		
			IF(@inorOut%2 !=0)
				BEGIN
				 SET @sqlStr='update tbl_report_inOutRegister set Intime'+cast(@slot as varchar(5))+'='''+cast(@timeStamp as varchar(20))+''' where 
				 internalId='''+@Empid+''' and userId='+cast(@userid as varchar(5))

				 EXEC(@sqlStr)
				 SET @incount =@incount+1
				END
			ELSE
				BEGIN
				 SET @sqlStr='update tbl_report_inOutRegister set Outime'+cast(@slot as varchar(5))+'='''+cast(@timeStamp as varchar(20))+''' where 
				 internalId='''+@Empid+''' and userId='+cast(@userid as varchar(5))

				 EXEC(@sqlStr)
				 SET @slot=@slot+1
				 SET @outCount =@outCount +1
				END

			SET @inorOut=@inorOut+1

		FETCH NEXT FROM dbcur into @timeStamp
		END
	CLOSE dbcur
	DEALLOCATE dbcur

	UPDATE tbl_report_inOutRegister SET incount=@incount,outCount=@outCount WHERE userId=@userid and internalId=@Empid

	SET NOCOUNT OFF
END