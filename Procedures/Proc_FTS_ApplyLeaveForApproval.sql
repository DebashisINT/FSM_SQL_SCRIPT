--EXEC Proc_FTS_ApplyLeaveForApproval @ACTION='GetMsgText',@subACTION='LeaveApply',@Emp_Name='ABC',@tinyurl='www.google.com'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_ApplyLeaveForApproval]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_ApplyLeaveForApproval] AS' 
END
GO

ALTER PROC [dbo].[Proc_FTS_ApplyLeaveForApproval]
(
@ACTION NVARCHAR(250)='',
@subACTION NVARCHAR(250)='',
@user_id NVARCHAR(MAX)=NULL,
@tinyURL NVARCHAR(MAX)=NULL,
@SessionToken NVARCHAR(MAX)=NULL,
@leave_from_date NVARCHAR(MAX)=NULL,
@leave_to_date NVARCHAR(MAX)=NULL,
@leave_type NVARCHAR(MAX)=NULL,
@leave_reason NVARCHAR(MAX)=NULL,
@Approve_User NVARCHAR(MAX)=NULL,
@isApprove bit=0,
@leave_lat NVARCHAR(MAX)=NULL,
@leave_long NVARCHAR(MAX)=NULL,
@leave_add NVARCHAR(MAX)=NULL,
@Emp_Name NVARCHAR(MAX)=NULL,
@output NVARCHAR(50) =null output 
) --WITH ENCRYPTION
AS
/*******************************************************************************************************************************
1.0		V2.0.8		Tanmoy		05-03-2020	@ACTION='GetLeaveDetails' report to fetch logic change	
*******************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
	BEGIN TRAN

	IF(@ACTION='APPLYLEAVE')
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM FTS_USER_LEAVEAPPLICATION WITH(NOLOCK) WHERE USER_ID=@user_id AND CAST(@leave_from_date AS date) BETWEEN 
			CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date) AND CURRENT_STATUS IN ('APPROVE','PENDING'))
				BEGIN
					IF NOT EXISTS(SELECT 1 FROM FTS_USER_LEAVEAPPLICATION WITH(NOLOCK) WHERE USER_ID=@user_id AND CAST(@leave_to_date AS date) BETWEEN 
					CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date)AND CURRENT_STATUS IN ('APPROVE','PENDING'))
						BEGIN
							INSERT INTO FTS_USER_LEAVEAPPLICATION(USER_ID,LEAVE_START_DATE,LEAVE_END_DATE,LEAVE_TYPE,LEAVE_REASON,CREATED_DATE,CURRENT_STATUS,LEAVE_LAT,LEAVE_LONG,LEAVE_ADDRESS)
							VALUES(@user_id,@leave_from_date,@leave_to_date,@leave_type,@leave_reason,GETDATE(),'PENDING',@leave_lat,@leave_long,@leave_add)

							--DECLARE @MobileNo VARCHAR(500)='9749838354',@sResponse VARCHAR(500)=''
							--DECLARE @smstext VARCHAR(500)='http://10.0.1.154:8088/oms/management/activities/leaveapproval.aspx?key='+cast(@user_id as varchar(50)) +'&AU=378'

							--EXEC pr_SendSmsSQL @MobileNo=@MobileNo,@smstext=@smstext,@sResponse=@sResponse OUTPUT
							set @output=SCOPE_IDENTITY()
							SELECT 'Leave Applied Successfully.'
						END
					ELSE
						BEGIN
						  SELECT 'Already Applied.'
						END
				END
			ELSE
				BEGIN
					SELECT 'Already Applied.'
				END
		END
	ELSE IF(@ACTION='GetLeaveDetails')
		BEGIN
			  SELECT top 1 CONVERT(VARCHAR(10),LEAVE_START_DATE,105) LEAVE_START_DATE,CONVERT(VARCHAR(10),
			  LEAVE_END_DATE,105) LEAVE_END_DATE,LEAVE_REASON,CURRENT_STATUS,CON.cnt_firstName NAME,
			  USR.user_loginId PHONE,TYPE.LeaveType LEAVE_TYPE,CON_RT.cnt_firstName REPORT_TO FROM FTS_USER_LEAVEAPPLICATION APP WITH(NOLOCK) 
			  INNER JOIN TBL_MASTER_USER USR WITH(NOLOCK) ON APP.USER_ID=USR.user_id
			  INNER JOIN TBL_MASTER_CONTACT CON WITH(NOLOCK) ON CON.cnt_internalId=USR.user_contactId
			  LEFT OUTER JOIN tbl_FTS_Leavetype TYPE WITH(NOLOCK) ON TYPE.Leave_Id=APP.LEAVE_TYPE
			  LEFT OUTER JOIN (SELECT cnt.emp_cntId,emp_reportTo FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
								LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL
								GROUP BY emp_cntId,emp_reportTo) DESG ON DESG.emp_cntId=CON.cnt_internalId
			  --Rev 1.0 Start
			  --left JOIN TBL_MASTER_USER USR_RT ON DESG.emp_reportTo=USR_RT.user_id
			  --left JOIN TBL_MASTER_CONTACT CON_RT ON CON_RT.cnt_internalId=USR_RT.user_contactId	
			   left JOIN tbl_master_employee USR_RT WITH(NOLOCK) ON DESG.emp_reportTo=USR_RT.emp_id
			   left JOIN TBL_MASTER_CONTACT CON_RT WITH(NOLOCK) ON CON_RT.cnt_internalId=USR_RT.emp_contactId
			  --Rev 1.0 End			 
			  WHERE APP.ID=@user_id 
			  --AND CAST(GETDATE() AS date) BETWEEN 
			  --CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date) ORDER BY CREATED_DATE DESC
		END
	ELSE IF(@ACTION='GetLeaveDetailsInSuccessPage')
		BEGIN
			  SELECT  
			  CASE WHEN CURRENT_STATUS='APPROVE' THEN 'Applied Leave for '+ISNULL ( CON.cnt_firstName,'') + ' ' + ISNULL ( CON.cnt_lastName,'')+' has been Approved by ' + ISNULL ( CON_RT.cnt_firstName,'') + ' ' + ISNULL ( CON_RT.cnt_lastName,'')
				   WHEN CURRENT_STATUS='REJECT' THEN 'Applied Leave for '+ISNULL ( CON.cnt_firstName,'') + ' ' + ISNULL ( CON.cnt_lastName,'')+' has been Rejected by '  + ISNULL ( CON_RT.cnt_firstName,'') + ' ' + ISNULL ( CON_RT.cnt_lastName,'')
				   ELSE 'LEAVE IS PENING' END 
			  FROM FTS_USER_LEAVEAPPLICATION APP WITH(NOLOCK) 
			  INNER JOIN TBL_MASTER_USER USR WITH(NOLOCK) ON APP.USER_ID=USR.user_id
			  INNER JOIN TBL_MASTER_CONTACT CON WITH(NOLOCK) ON CON.cnt_internalId=USR.user_contactId
			  --LEFT JOIN tbl_FTS_Leavetype TYPE ON TYPE.Leave_Id=APP.LEAVE_TYPE
			  --LEFT JOIN 	  (SELECT cnt.emp_cntId,emp_reportTo FROM tbl_trans_employeeCTC AS cnt 
					--			LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL
					--			GROUP BY emp_cntId,emp_reportTo) DESG ON DESG.emp_cntId=CON.cnt_internalId
			  LEFT OUTER JOIN TBL_MASTER_USER USR_RT WITH(NOLOCK) ON APP.APPROVAL_USER=USR_RT.user_id
			  LEFT OUTER JOIN TBL_MASTER_CONTACT CON_RT WITH(NOLOCK) ON CON_RT.cnt_internalId=USR_RT.user_contactId				 
			  WHERE APP.ID=@user_id 
			  --AND CAST(GETDATE() AS date) BETWEEN 
			  --CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date)
		END
	ELSE IF(@ACTION='ApproveRejectLeave')
		BEGIN
			UPDATE FTS_USER_LEAVEAPPLICATION SET APPROVAL_USER=@Approve_User,CURRENT_STATUS=CASE WHEN @isApprove=1 THEN 'APPROVE' ELSE 'REJECT' END
				  WHERE ID=@user_id 
				  --AND CAST(GETDATE() AS date) BETWEEN 
				  --CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date) 
				  and CURRENT_STATUS='PENDING'

				  SET @output =(select CONVERT(varchar(10),LEAVE_START_DATE,120) from FTS_USER_LEAVEAPPLICATION WHERE ID=@user_id )

			IF(@isApprove=1)
				BEGIN
				declare @Attendence_time VARCHAR(50)
				declare @New_User_time VARCHAR(50)

				SELECT @leave_type=LEAVE_TYPE,@leave_from_date=LEAVE_START_DATE,@leave_to_date=LEAVE_END_DATE
				,@Attendence_time=CREATED_DATE,@leave_lat=LEAVE_LAT,@leave_long=LEAVE_LONG,@leave_add=LEAVE_ADDRESS,@New_User_time=USER_ID FROM FTS_USER_LEAVEAPPLICATION
				WHERE ID=@user_id 
				--AND CAST(GETDATE() AS date) BETWEEN 
				--CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date)
				DECLARE @StartDate AS DATETIME
				DECLARE @EndDate AS DATETIME
				DECLARE @CurrentDate AS DATETIME
				DECLARE @count_i bigint=0
				SET @StartDate = cast(@leave_from_date as DATE)
				SET @EndDate =	cast(@leave_to_date as DATE)
					--GETDATE()
				SET @CurrentDate = @StartDate

				WHILE (cast(@CurrentDate as date) <= cast(@EndDate as date))
					BEGIN
					SET @Attendence_time=@CurrentDate
					insert into tbl_fts_UserAttendanceLoginlogout (User_Id,Login_datetime,Logout_datetime,Latitude,Longitude,Work_Type,Work_Desc,
									Work_Address,Work_datetime,Isonleave,Attendence_time,Leave_Type,Leave_FromDate,Leave_ToDate,Distributor_Name,Market_Worked) 
									values(@New_User_time,@Attendence_time,null,@leave_lat,@leave_long,NULL,NULL,@leave_add,@Attendence_time,'true',CONVERT(varchar(15),CAST(@Attendence_time AS TIME),100),@leave_type,@leave_from_date,@leave_to_date,
									NULL,NULL)
					DECLARE @datefetch DATETIME=GETDATE()
					DECLARE @sqlyyMM VARCHAR(50)=SUBSTRING(CONVERT(nvarchar(6),@datefetch, 112),3,2) +  SUBSTRING(CONVERT(nvarchar(6),@datefetch, 112),5,2)
					DECLARE @InternalID VARCHAR(50)=(select  user_contactId  from tbl_master_user where user_id=@New_User_time)
					DECLARE @val NVARCHAR(50)
					DECLARE @SQL NVARCHAR(MAX)
	
					INSERT INTO tbl_EmpAttendanceDetails (Emp_InternalId,LogTime)values(@InternalID,@CurrentDate)

					IF NOT exists(select * from tbl_Employee_Attendance WITH(NOLOCK) where convert(date,Att_Date)=convert(date,@datefetch) and Emp_InternalId=@InternalID)
						BEGIN
						   declare @new_id varchar(49)=NEWID()
							INSERT INTO tbl_Employee_Attendance(UniqueKey,Emp_InternalId,Att_Date,In_Time,Out_Time,UpdatedBy,UpdatedOn,YYMM,Emp_status,Remarks)
							values (@new_id+ cast(@count_i as varchar(10)),@InternalID,NULL 
							,NULL ,NULL,@New_User_time,@datefetch
							,cast(right(datepart(yy,@datefetch),2) as varchar(50))+ cast(DATEPART(MM,@datefetch) as varchar(50))
							,'AB','')
						END
					ELSE
						BEGIN
							update tbl_Employee_Attendance set Out_Time=NULL where convert(date,Att_Date)=convert(date,@datefetch)  and Emp_InternalId=@InternalID
						END			

					IF NOT exists(select * from tbl_EmpWiseAttendanceStatus WITH(NOLOCK) where Emp_InternalId=@InternalID and YYMM=@sqlyyMM)
						BEGIN
							insert into tbl_EmpWiseAttendanceStatus(Emp_InternalId,YYMM)
							VALUES(@InternalID,@sqlyyMM)
							set @val='AB'
							set @SQL ='update tbl_EmpWiseAttendanceStatus set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''' AND YYMM='''+@sqlyyMM+''''
							EXEC sp_ExecuteSql @SQL
						END
					ELSE
						BEGIN
							set @val='AB'
							set @SQL ='update tbl_EmpWiseAttendanceStatus set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''' AND YYMM='''+@sqlyyMM+''''
							EXEC sp_ExecuteSql @SQL
						END
						SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate); /*increment current date*/
					END
				END
		END
	ELSE IF(@ACTION='GetMsgText')
		BEGIN
		   IF(@subACTION='LeaveApply')
			   BEGIN
				   SELECT 'Leave Applied by ' + @Emp_Name + '. Please Approve/Reject by Clicking the link : ' + @tinyURL
				   SELECT 'Leave has been applied successfully. Please wait for the Approval/Rejection Notification.'
			   END
		   ELSE IF(@subACTION='LeaveReject')
			   BEGIN
				 SELECT 'Leave has been Rejected by: ' + @Emp_Name + '. You may again mark your Attendance ''At Work'' or may again Re-apply Leave. For any further query contact to HR.'
			   END
		   ELSE IF(@subACTION='LeaveApprove')
			   BEGIN
				 SELECT 'Your leave is approved by ' + @Emp_Name +'.'
			   END
		END

	COMMIT TRAN
	END TRY

	BEGIN CATCH

		IF(@@ROWCOUNT>0)
		   SELECT ERROR_MESSAGE()

	END CATCH

	SET NOCOUNT OFF
END