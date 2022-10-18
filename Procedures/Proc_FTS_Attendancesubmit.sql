--exec [Proc_FTS_Attendancesubmit] '1655','','','','','','2019-01-09 12:52:55','true','','1:52 pm','','','2019-01-09','2019-01-10','2'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_Attendancesubmit]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_Attendancesubmit] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_FTS_Attendancesubmit]
(
@user_id NVARCHAR(MAX),
@wtype NVARCHAR(MAX)=NULL,
@wdesc NVARCHAR(MAX)=NULL,
@wlatitude NVARCHAR(MAX)=NULL,
@wlongitude NVARCHAR(MAX)=NULL,
@Waddress NVARCHAR(MAX)=NULL,
@Wdatetime datetime=NULL,
@Isonleave NVARCHAR(50)=NULL,
@SessionToken NVARCHAR(MAX)=NULL,
@add_attendence_time varchar(50)=NULL,
@RouteID NVARCHAR(MAX)=NULL,
@ShopList_List XML=NULL,
@Target_List XML=NULL,
@leave_from_date NVARCHAR(MAX)=NULL,
@leave_to_date NVARCHAR(MAX)=NULL,
@leave_type NVARCHAR(MAX)=NULL,
@order_taken NVARCHAR(MAX)=NULL,
@collection_taken NVARCHAR(MAX)=NULL,
@new_shop_visit NVARCHAR(MAX)=NULL ,
@revisit_shop NVARCHAR(MAX)=NULL,
@state_id NVARCHAR(MAX)=NULL,
@Distributor_Name NVARCHAR(500)=NULL,
@Market_Worked NVARCHAR(500)=NULL,
----REV 3.0 START
@IsNoPlanUpdate NVARCHAR(5)=NULL,
----REV 3.0 END
--REV 6.0 START
@leave_reason NVARCHAR(500)=null,
--REV 6.0 END
--REV 9.0 START
@from_Areaid NVARCHAR(100)=null,
@to_Areaid NVARCHAR(100)=null,
@distance NVARCHAR(100)=null,
--REV 9.0 END
--Rev 11.0
@beat_id BIGINT=NULL,
--End of Rev 11.0
@FUNDPLAN UDT_FUNDPLAN READONLY
)--WITH ENCRYPTION
AS
/************************************************************************************************
1.0					Tanmoy		30-10-2019		ADD TWO COLUMEN tbl_fts_UserAttendanceLoginlogout
2.0					Tanmoy		23-12-2019		INSERT AND UPDATE FUND PLAN
3.0					Tanmoy		06-01-2019		No Plan Insert
4.0					Tanmoy      22-01-2020      Achivemet date and plan date add server time
5.0					Indranil    28-01-2020      Approval for Leave type introduced.
6.0					Tanmoy      13-02-2020      add new column leave reason
7.0					Indranil    21-02-2020      Change Message text.
8.0					Tanmoy      25-02-2020      settings chsnges master_contact to master_user
9.0					Tanmoy      04-12-2020      add new column from_Areaid,to_Areaid,distance
10.0				Tanmoy      08-12-2020      add new column STATICDISTANCE
11.0	v2.0.32		Debashis	09-08-2022		New column has been added.Row: 725
************************************************************************************************/ 
BEGIN
	SET NOCOUNT ON

	DECLARE @InternalID varchar(50)
	DECLARE @identity varchar(50)
	DECLARE @SQL nvarchar(MAX)
	DECLARE @val nvarchar(MAX)
	DECLARE @datefetch datetime =GETDATE()
	
	set @InternalID=(select user_contactId from tbl_master_user WITH(NOLOCK) where user_id=@user_id)
	set @SessionToken=right(@SessionToken,10)+convert(Nvarchar(100),@datefetch,109)
	--if exists(select  User_Id from tbl_fleet_UserAttendance where User_Id=@user_id and Login_datetime is not null)
	--BEgin
	declare @sqlyyMM varchar(50)

	declare @PLAN_ID BIGINT,@PLAN_AMT DECIMAL(20,4)=NULL,@PLAN_DATE DATETIME=NULL,@PLAN_REMARKS NVARCHAR(500)=NULL
					DECLARE @ACHIV_AMT DECIMAL(20,4)=NULL,@ACHIV_DATE DATETIME=NULL,@ACHIV_REMARKS NVARCHAR(500)=NULL
					DECLARE @MAXID int

	DECLARE @STATICDISTANCE NUMERIC(18,2)

	SET @STATICDISTANCE=(SELECT ISNULL(Distance,0) FROM FTS_AreaDistance WITH(NOLOCK) WHERE From_AreaID=@from_Areaid AND To_AreaID=@to_Areaid)

	if(@leave_from_date ='')
	SET @leave_from_date=null

	if(@leave_to_date ='')
	SET @leave_to_date=null
	--REV 9.0 START
	if (@from_Areaid='')
	SET @from_Areaid =null

	IF (@to_Areaid='')
	SET @to_Areaid =null

	IF (@distance='')
	SET @distance=null
	--REV 9.0 END

	--REV 9.0 START
	IF(convert(nvarchar(10),@STATICDISTANCE)='')
	SET @STATICDISTANCE=null
	--REV 9.0 end

	--Rev Debashis
	DECLARE @IsDatatableUpdateForDashboardAttendanceTab NVARCHAR(100)
	SELECT @IsDatatableUpdateForDashboardAttendanceTab=[Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsDatatableUpdateForDashboardAttendanceTab'
	--End of Rev Debashis

	---REV 5.0
	DECLARE @VALIDATION_LEAVE BIT=1

	IF EXISTS(SELECT 1 FROM FTS_USER_LEAVEAPPLICATION WITH(NOLOCK) WHERE USER_ID=@user_id AND CAST(@leave_from_date AS date) BETWEEN 
	CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date) AND CURRENT_STATUS IN ('APPROVE','PENDING') AND @Isonleave='TRUE')
		BEGIN
			SET @VALIDATION_LEAVE=0
		END

	IF EXISTS(SELECT 1 FROM FTS_USER_LEAVEAPPLICATION WITH(NOLOCK) WHERE USER_ID=@user_id AND CAST(@leave_to_date AS date) BETWEEN 
	CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date)AND CURRENT_STATUS IN ('APPROVE','PENDING')AND @Isonleave='TRUE')
		BEGIN
		SET @VALIDATION_LEAVE=0
		END


	DECLARE @VALIDATION_ATWORK BIT=1

    IF  EXISTS(SELECT 1 FROM FTS_USER_LEAVEAPPLICATION WITH(NOLOCK) WHERE USER_ID=@user_id AND CAST(getdate() AS date) BETWEEN 
	CAST(LEAVE_START_DATE AS date) AND CAST(LEAVE_END_DATE  AS date) AND CURRENT_STATUS IN ('APPROVE','PENDING') AND @Isonleave='FALSE')
		BEGIN
			SET @VALIDATION_ATWORK=0
		END

	IF(@VALIDATION_LEAVE =1 AND @VALIDATION_ATWORK=1)
	BEGIN
	---END REV 5.0
		if(isnull(@Wdatetime,'')='')
			BEGIN
				set @datefetch=GETDATE()
				set @sqlyyMM =SUBSTRING(CONVERT(nvarchar(6),@datefetch, 112),3,2) +  SUBSTRING(CONVERT(nvarchar(6),@datefetch, 112),5,2)

				IF NOT EXISTS(select  User_Id from tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) where User_Id=@user_id and  cast(Login_datetime as date)=cast(@datefetch as date))
				BEGIN
					--Rev 11.0 &&Added a new column as Beat_ID
					insert into tbl_fts_UserAttendanceLoginlogout WITH(TABLOCK) (User_Id,Login_datetime,Logout_datetime,Latitude,Longitude,Work_Type,Work_Desc,
					Work_Address,Work_datetime,Isonleave,Attendence_time,Leave_Type,Leave_FromDate,Leave_ToDate,Distributor_Name,Market_Worked,LeaveReason
					--REV 9.0 START
					,From_AreaId,To_AreaId,Distance
					--REV 9.0 END
					--REV 10.0 START
					,StaticDistance
					--REV 10.0 END	
					,Beat_ID				
					) 
					values(@user_id,null,null,@wlatitude,@wlongitude,@wtype,@wdesc,@Waddress,@datefetch,@Isonleave,@add_attendence_time,@leave_type,@leave_from_date,@leave_to_date,
					@Distributor_Name,@Market_Worked,
					--REV 6.0 START
					@leave_reason
					--REV 6.0 END
					--REV 9.0 START
					,@from_Areaid,@to_Areaid,@distance 
					--REV 9.0 END
					--REV 10.0 START
					,@STATICDISTANCE
					--REV 10.0 END	
					,@beat_id
					)	
					SET @identity=SCOPE_IDENTITY()

					-----------------------Sub Ordinate tables---------------
					if(isnull(@add_attendence_time,'')<>'')
					BEGIN
						insert into tbl_attendance_worktype select @identity,items,@user_id  from dbo.SplitString(@wtype,',')

						insert into tbl_attendance_Route select @identity,items,@user_id  from dbo.SplitString(@RouteID,',')

						if(isnull(@order_taken,'')<>'' and isnull(@collection_taken,'')<>'' and isnull(@new_shop_visit,'')<>'' and isnull(@revisit_shop,'')<>'' and @Isonleave='false')
						BEGIN
							insert into FTS_Attendance_Target WITH(TABLOCK) (Attendanceid,UserID,Order_taken,Collection_taken,New_shop_visit,Revisit_shop,Createddate,CreatedBy)
							values(@identity,@user_id,@order_taken,@collection_taken,@new_shop_visit,@revisit_shop,GETDATE(),@user_id)
						END

						if(@ShopList_List is not null)
						BEGIN
							INSERT  INTO  tbl_attendance_RouteShop WITH(TABLOCK) (attendanceid,RouteID,ShopID,UserID)
							select @identity,XMLproduct.value('(route/text())[1]','bigint')	,XMLproduct.value('(shop_id/text())[1]','varchar(MAX)')	
							,@user_id FROM  @ShopList_List.nodes('/root/data')AS TEMPTABLE(XMLproduct)   
						END
					END
					-----------------------Sub Ordinate tables---------------

					--------------------------Attendane Main table Synchronization------------------------------------------
					--Rev Debashis
					IF @IsDatatableUpdateForDashboardAttendanceTab='1'
						BEGIN
					--End of Rev Debashis
							INSERT INTO tbl_EmpAttendanceDetails WITH(TABLOCK) (Emp_InternalId,LogTime)values(@InternalID,@datefetch)

							IF NOT EXISTS(select Emp_InternalId from tbl_Employee_Attendance WITH(NOLOCK) where convert(date,Att_Date)=convert(date,@datefetch) and Emp_InternalId=@InternalID)
								BEGIN
									INSERT INTO tbl_Employee_Attendance WITH(TABLOCK) (UniqueKey,Emp_InternalId,Att_Date,In_Time,Out_Time,UpdatedBy,UpdatedOn,YYMM,Emp_status,Remarks)
									values (@SessionToken,@InternalID,@datefetch,null,NULL,@user_id,@datefetch,@sqlyyMM,case when  @Isonleave='false' then  'P' else 'AB' end,'')
								END
							ELSE
								BEGIN
									update tbl_Employee_Attendance WITH(TABLOCK) SET Out_Time=@datefetch   where convert(date,Att_Date)=convert(date,@datefetch) and Emp_InternalId=@InternalID
								END

							IF NOT EXISTS(select Emp_InternalId from tbl_EmpWiseAttendanceStatus WITH(NOLOCK) where Emp_InternalId=@InternalID and YYMM=@sqlyyMM)
								BEGIN
									insert into tbl_EmpWiseAttendanceStatus WITH(TABLOCK) (Emp_InternalId,YYMM)
									VALUES(@InternalID,@sqlyyMM)
									if(@Isonleave='true')
									set @val='AB'
									else
									set @val='P'
									set @SQL ='update tbl_EmpWiseAttendanceStatus WITH(TABLOCK) set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''' AND YYMM='''+@sqlyyMM+''''
									EXEC sp_ExecuteSql @SQL
								END
							ELSE
								BEGIN
									if(@Isonleave='true')
									set @val='AB'
									else
									set @val='P'
									set @SQL ='update tbl_EmpWiseAttendanceStatus WITH(TABLOCK) set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''' AND YYMM='''+@sqlyyMM+''''
									EXEC sp_ExecuteSql @SQL
								END
					--Rev Debashis
						END
					--End of Rev Debashis
					--------------------------End  Attendane Main table Synchronization------------------------------------------


					----REV 2.0 START
					-------------------------------START FOR FUND PLAN-------------------------------------------------------------------
					--declare @PLAN_ID BIGINT,@PLAN_AMT DECIMAL(20,4)=NULL,@PLAN_DATE DATETIME=NULL,@PLAN_REMARKS NVARCHAR(500)=NULL
					--DECLARE @ACHIV_AMT DECIMAL(20,4)=NULL,@ACHIV_DATE DATETIME=NULL,@ACHIV_REMARKS NVARCHAR(500)=NULL
					--DECLARE @MAXID int
					----REV 3.0 START
					IF ISNULL(@IsNoPlanUpdate,'0')='1'
						BEGIN
						----REV 3.0 END
							DECLARE FUNDPLAN_CURSOR CURSOR  
							LOCAL  FORWARD_ONLY  FOR  

							select PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_REMARKS from @FUNDPLAN 
							OPEN FUNDPLAN_CURSOR  
							FETCH NEXT FROM FUNDPLAN_CURSOR INTO  @PLAN_ID,@PLAN_AMT,@PLAN_DATE,@PLAN_REMARKS,@ACHIV_DATE,@ACHIV_REMARKS
							WHILE @@FETCH_STATUS = 0  
								BEGIN  
									IF ISNULL(@ACHIV_AMT,0)>0
									BEGIN
										SET @ACHIV_DATE=@PLAN_DATE
									END

									--Rev 4.0 Start
									IF ISNULL(@ACHIV_DATE,'')<>''
										BEGIN
											SET @ACHIV_DATE=cast((SELECT CONVERT(VARCHAR(10),@ACHIV_DATE,121) +' '+ CONVERT(VARCHAR(15),CAST(GETDATE() as TIME),108)) as datetime)
										END
									IF ISNULL(@PLAN_DATE,'')<>''
									BEGIN
										-- SELECT CONVERT(VARCHAR(10),CAST(@PLAN_DATE AS datE),105) 
										SET @PLAN_DATE=CAST((SELECT CONVERT(VARCHAR(10),CAST(@PLAN_DATE AS datE),121) +' '+ CONVERT(VARCHAR(15),CAST(GETDATE() as TIME),108)) AS DATETIME)
									END
									--Rev 4.0 End

									IF NOT EXISTS (SELECT PLAN_ID FROM FTS_UserDalyFundPlan WITH(NOLOCK) WHERE USER_ID=@User_id AND PLAN_ID=@PLAN_ID AND CAST(PLAN_DATE AS DATE)=CAST(@PLAN_DATE AS DATE))
										BEGIN
											INSERT INTO FTS_UserDalyFundPlan WITH(TABLOCK) (USER_ID,PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_DATE,ACHIV_REMARKS,CREATE_DATE)
											VALUES (@User_id,@PLAN_ID,@PLAN_AMT,@PLAN_DATE,@PLAN_REMARKS,@ACHIV_AMT,@ACHIV_DATE,@ACHIV_REMARKS,GETDATE())
										END
									ELSE
										BEGIN
											UPDATE FTS_UserDalyFundPlan WITH(TABLOCK) SET PLAN_AMT=@PLAN_AMT,PLAN_REMARKS=@PLAN_REMARKS,ACHIV_AMT=@ACHIV_AMT,ACHIV_DATE=@ACHIV_DATE,
											ACHIV_REMARKS=@ACHIV_REMARKS,UPDATE_DATE=GETDATE()
											WHERE USER_ID=@User_id AND PLAN_ID=@PLAN_ID AND PLAN_DATE=@PLAN_DATE
										END

									INSERT INTO FTS_UserDalyFundPlan_LOG WITH(TABLOCK) (USER_ID,PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_DATE,ACHIV_REMARKS,CREATE_DATE)
											VALUES (@User_id,@PLAN_ID,@PLAN_AMT,@PLAN_DATE,@PLAN_REMARKS,@ACHIV_AMT,@ACHIV_DATE,@ACHIV_REMARKS,GETDATE())

									FETCH NEXT FROM FUNDPLAN_CURSOR INTO  @PLAN_ID,@PLAN_AMT,@PLAN_DATE,@PLAN_REMARKS,@ACHIV_AMT,@ACHIV_REMARKS
								END
							CLOSE FUNDPLAN_CURSOR  
							DEALLOCATE FUNDPLAN_CURSOR  
							----REV 3.0 START
						END
					ELSE
						BEGIN
						--Rev 8.0 Start
							IF (SELECT IsShowPlanDetails FROM tbl_master_user WITH(NOLOCK) WHERE user_contactId=@InternalID)=1
							--Rev 8.0 End
								BEGIN
									INSERT INTO FTS_UserDalyFundPlan WITH(TABLOCK) (USER_ID,PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_DATE,ACHIV_REMARKS,CREATE_DATE)
									VALUES (@User_id,(SELECT [VALUE] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='NoPlanID'),0,GETDATE(),'',0,GETDATE(),'',GETDATE())

									INSERT INTO FTS_UserDalyFundPlan_LOG WITH(TABLOCK) (USER_ID,PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_DATE,ACHIV_REMARKS,CREATE_DATE)
									VALUES (@User_id,(SELECT [VALUE] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='NoPlanID'),0,GETDATE(),'',0,GETDATE(),'',GETDATE())
								END
						END
						----REV 3.0 END
					-------------------------------END FOR FUND PLAN---------------------------------------------------------------------
					----REV 2.0 END
				END
			END

		ELSE
			BEGIN
				set @datefetch=@Wdatetime
				set @sqlyyMM =SUBSTRING(CONVERT(nvarchar(6),@datefetch, 112),3,2) +  SUBSTRING(CONVERT(nvarchar(6),@datefetch, 112),5,2)
				--select @sqlyyMM
				IF NOT EXISTS(select  User_Id from tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) where User_Id=@user_id and  cast(Login_datetime as date)=cast(@datefetch as date))
					BEGIN
						--Rev 11.0 &&Added a new column as Beat_ID
						insert into tbl_fts_UserAttendanceLoginlogout WITH(TABLOCK) (User_Id,Login_datetime,Logout_datetime,Latitude,Longitude,Work_Type,Work_Desc,
						Work_Address,Work_datetime,Isonleave,Attendence_time,Leave_Type,Leave_FromDate,Leave_ToDate,Distributor_Name,Market_Worked,LeaveReason
						--REV 9.0 START
						,From_AreaId,To_AreaId,Distance
						--REV 9.0 END
						--REV 10.0 START
						,StaticDistance
						--REV 10.0 END
						,Beat_ID
						) 
						values(@user_id,@Wdatetime,null,@wlatitude,@wlongitude,@wtype,@wdesc,@Waddress,@Wdatetime,@Isonleave,@add_attendence_time,@leave_type,@leave_from_date,@leave_to_date,
						@Distributor_Name,@Market_Worked,
						--REV 6.0 START
						@leave_reason
						--REV 6.0 END
						--REV 9.0 START
						,@from_Areaid,@to_Areaid,@distance 
						--REV 9.0 END
						--REV 10.0 START
						,@STATICDISTANCE
						--REV 10.0 END
						,@beat_id
						)
						SET @identity=SCOPE_IDENTITY()

						if(isnull(@add_attendence_time,'')<>'')
						BEGIN
							-----------------------Sub Ordinate tables---------------
							insert into tbl_attendance_worktype select @identity,items,@user_id  from dbo.SplitString(@wtype,',')

							insert into tbl_attendance_Route select @identity,items,@user_id  from dbo.SplitString(@RouteID,',')

							if(isnull(@order_taken,'')<>'' and isnull(@collection_taken,'')<>'' and isnull(@new_shop_visit,'')<>'' and isnull(@revisit_shop,'')<>'' and @Isonleave='false')
							BEGIN
								insert into FTS_Attendance_Target WITH(TABLOCK) (Attendanceid,UserID,Order_taken,Collection_taken,New_shop_visit,Revisit_shop,Createddate,CreatedBy)
								values(@identity,@user_id,@order_taken,@collection_taken,@new_shop_visit,@revisit_shop,GETDATE(),@user_id)
							END

							-------------Attendance Shop -----------------

							if(@ShopList_List is not null)
							BEGIN
								INSERT INTO tbl_attendance_RouteShop WITH(TABLOCK) (attendanceid,RouteID,ShopID,UserID)
								select @identity,XMLproduct.value('(route/text())[1]','bigint')	,
								XMLproduct.value('(shop_id/text())[1]','varchar(MAX)'),@user_id
								FROM  @ShopList_List.nodes('/root/data')AS TEMPTABLE(XMLproduct)   
							END

							-------------  Statewise Target -----------------

							if(@Target_List is not null)
							BEGIN
								INSERT INTO FTS_Attendance_Target_Statewise WITH(TABLOCK) (Attendanceid,UserID,State_Id,Target_Value,Createddate)
								select @identity,@user_id,XMLproduct.value('(id/text())[1]','bigint')	,
								XMLproduct.value('(primary_value/text())[1]','decimal(18,2)')	,GETDATE()
								FROM  @Target_List.nodes('/root/data')AS TEMPTABLE(XMLproduct)   
							END

							-----------------------Sub Ordinate tables---------------
						END

						--------------------------Attendane Main table Synchronization------------------------------------------
						--Rev Debashis
					IF @IsDatatableUpdateForDashboardAttendanceTab='1'
						BEGIN
					--End of Rev Debashis
							INSERT INTO tbl_EmpAttendanceDetails WITH(TABLOCK) (Emp_InternalId,LogTime)values(@InternalID,@Wdatetime)

							IF NOT EXISTS(select Emp_InternalId from tbl_Employee_Attendance WITH(NOLOCK) where convert(date,Att_Date)=convert(date,@datefetch) and Emp_InternalId=@InternalID)
								BEGIN
									INSERT INTO tbl_Employee_Attendance WITH(TABLOCK) (UniqueKey,Emp_InternalId,Att_Date,In_Time,Out_Time,UpdatedBy,UpdatedOn,YYMM,Emp_status,Remarks)
									values (@SessionToken,@InternalID,case when  @Isonleave='false' then @datefetch else NULL end
									,case when  @Isonleave='false' then @Wdatetime else NULL end,NULL,@user_id,@datefetch
									--,right(datepart(yy,@datefetch),2)+ +RIGHT('00' + CAST(DATEPART(mm, @datefetch) AS varchar(2)), 2)
									,cast(right(datepart(yy,@datefetch),2) as varchar(50))+ cast(DATEPART(MM,@datefetch) as varchar(50))
									,case when  @Isonleave='false' then  'P' else 'AB' end,'')
								END
							ELSE
								BEGIN
									update tbl_Employee_Attendance WITH(TABLOCK) SET Out_Time=case when  @Isonleave='true' then @datefetch else NULL end   where convert(date,Att_Date)=convert(date,@datefetch)  and Emp_InternalId=@InternalID
								END

							IF NOT EXISTS(select Emp_InternalId from tbl_EmpWiseAttendanceStatus WITH(NOLOCK) where Emp_InternalId=@InternalID and YYMM=@sqlyyMM)
								BEGIN
									insert into tbl_EmpWiseAttendanceStatus WITH(TABLOCK) (Emp_InternalId,YYMM)
									VALUES(@InternalID,@sqlyyMM)
									if(@Isonleave='true')
									set @val='AB'
									else
									set @val='P'
									set @SQL ='update tbl_EmpWiseAttendanceStatus WITH(TABLOCK) set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''' AND YYMM='''+@sqlyyMM+''''

									EXEC sp_ExecuteSql @SQL
								END
							ELSE
								BEGIN
									if(@Isonleave='true')
									set @val='AB'
									else
									set @val='P'
									set @SQL ='update tbl_EmpWiseAttendanceStatus WITH(TABLOCK) set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''' AND YYMM='''+@sqlyyMM+''''
									--SET  @SQL +=' cast(right(datepart(yy,'''+@datefetch+'''),2) as varchar(50)) + cast(DATEPART(MM,'''+@datefetch+''') as varchar(50))'

									--select @SQL
									EXEC sp_ExecuteSql @SQL
								END
					--Rev Debashis
						END
					--End of Rev Debashis
						--------------------------End  Attendane Main table Synchronization------------------------------------------

						----REV 2.0 START
						-------------------------------START FOR FUND PLAN-------------------------------------------------------------------
						----REV 3.0 START
						IF ISNULL(@IsNoPlanUpdate,'0')='1'
							BEGIN
							----REV 3.0 END
								DECLARE FUNDPLAN_CURSOR CURSOR  
								LOCAL  FORWARD_ONLY  FOR  

								select PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_REMARKS from @FUNDPLAN 
								OPEN FUNDPLAN_CURSOR  
								FETCH NEXT FROM FUNDPLAN_CURSOR INTO  @PLAN_ID,@PLAN_AMT,@PLAN_DATE,@PLAN_REMARKS,@ACHIV_AMT,@ACHIV_REMARKS
								WHILE @@FETCH_STATUS = 0  
									BEGIN  
										IF ISNULL(@ACHIV_AMT,0)>0
										BEGIN
											SET @ACHIV_DATE=@PLAN_DATE
										END

										--Rev 4.0 Start
										IF ISNULL(@ACHIV_DATE,'')<>''
											BEGIN
												SET @ACHIV_DATE=cast((SELECT CONVERT(VARCHAR(10),@ACHIV_DATE,121) +' '+ CONVERT(VARCHAR(15),CAST(GETDATE() as TIME),108)) as datetime)
											END
										IF ISNULL(@PLAN_DATE,'')<>''
										BEGIN
											-- SELECT CONVERT(VARCHAR(10),CAST(@PLAN_DATE AS datE),105) 
											SET @PLAN_DATE=CAST((SELECT CONVERT(VARCHAR(10),CAST(@PLAN_DATE AS datE),121) +' '+ CONVERT(VARCHAR(15),CAST(GETDATE() as TIME),108)) AS DATETIME)
										END
										--Rev 4.0 End

										IF NOT EXISTS (SELECT PLAN_ID FROM FTS_UserDalyFundPlan WITH(NOLOCK) WHERE USER_ID=@User_id AND PLAN_ID=@PLAN_ID AND CAST(PLAN_DATE AS DATE)=CAST(@PLAN_DATE AS DATE))
											BEGIN
												INSERT INTO FTS_UserDalyFundPlan WITH(TABLOCK) (USER_ID,PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_DATE,ACHIV_REMARKS,CREATE_DATE)
												VALUES (@User_id,@PLAN_ID,@PLAN_AMT,@PLAN_DATE,@PLAN_REMARKS,@ACHIV_AMT,@ACHIV_DATE,@ACHIV_REMARKS,GETDATE())
											END
										ELSE
											BEGIN
												UPDATE FTS_UserDalyFundPlan WITH(TABLOCK) SET PLAN_AMT=@PLAN_AMT,PLAN_REMARKS=@PLAN_REMARKS,ACHIV_AMT=@ACHIV_AMT,ACHIV_DATE=@ACHIV_DATE,
												ACHIV_REMARKS=@ACHIV_REMARKS,UPDATE_DATE=GETDATE()
												WHERE USER_ID=@User_id AND PLAN_ID=@PLAN_ID AND PLAN_DATE=@PLAN_DATE
											END

										INSERT INTO FTS_UserDalyFundPlan_LOG WITH(TABLOCK) (USER_ID,PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_DATE,ACHIV_REMARKS,CREATE_DATE)
												VALUES (@User_id,@PLAN_ID,@PLAN_AMT,@PLAN_DATE,@PLAN_REMARKS,@ACHIV_AMT,@ACHIV_DATE,@ACHIV_REMARKS,GETDATE())

										FETCH NEXT FROM FUNDPLAN_CURSOR INTO  @PLAN_ID,@PLAN_AMT,@PLAN_DATE,@PLAN_REMARKS,@ACHIV_AMT,@ACHIV_REMARKS
									END
								CLOSE FUNDPLAN_CURSOR  
								DEALLOCATE FUNDPLAN_CURSOR  
								----REV 3.0 START
							END
						ELSE
							BEGIN
							--Rev 8.0 Start
							IF (SELECT IsShowPlanDetails FROM tbl_master_user WITH(NOLOCK) WHERE user_contactId=@InternalID)=1
							--Rev 8.0 End
								BEGIN
									INSERT INTO FTS_UserDalyFundPlan WITH(TABLOCK) (USER_ID,PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_DATE,ACHIV_REMARKS,CREATE_DATE)
									VALUES (@User_id,(SELECT [VALUE] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='NoPlanID'),0,GETDATE(),'',0,GETDATE(),'',GETDATE())

									INSERT INTO FTS_UserDalyFundPlan_LOG WITH(TABLOCK) (USER_ID,PLAN_ID,PLAN_AMT,PLAN_DATE,PLAN_REMARKS,ACHIV_AMT,ACHIV_DATE,ACHIV_REMARKS,CREATE_DATE)
									VALUES (@User_id,(SELECT [VALUE] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='NoPlanID'),0,GETDATE(),'',0,GETDATE(),'',GETDATE())
								END
							END
							----REV 3.0 END
						-------------------------------END FOR FUND PLAN---------------------------------------------------------------------
						----REV 2.0 END
					END
			END
	---REV 5.0
		select  'Attendence successfully submitted.' as output

	END
	ELSE
	BEGIN
	  SELECT 'Leave Already Applied.'  -- REV 7.0
	END
	---END REV 5.0
	--End

	SET NOCOUNT OFF
END