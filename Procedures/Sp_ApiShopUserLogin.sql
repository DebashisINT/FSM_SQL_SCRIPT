IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_ApiShopUserLogin]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_ApiShopUserLogin] AS' 
END
GO

ALTER PROCEDURE [dbo].[Sp_ApiShopUserLogin]
(
@userName varchar(MAX),
@password varchar(MAX),
@SessionToken varchar(MAX)=NULL,
@latitude varchar(MAX)=NULL,
@longitude varchar(MAX)=NULL,
@login_time varchar(MAX)=NULL,
@ImeiNo varchar(MAX)=NULL,
@location_name varchar(MAX)=NULL,
@version_name varchar(MAX)=NULL,
@Weburl varchar(MAX)=NULL,
@device_token varchar(300)=NULL
)--WITH ENCRYPTION
AS
/*******************************************************************************************************************************************

REV NO.		DATE			VERSION			DEVELOPER			CHANGES										           	INSTRUCTED BY
-------		----			-------			---------			-------											        -------------					
1.0			08-03-2019		V 1.0.21		SUDIP			    DGM should not Set Target								SUMAN,Pijush Da		
2.0			13-03-2019		V 1.0.21		SUDIP			    Home location/cworking time								NIKHIl,Pijush Da		
3.0			21-05-2019		V 3.4.0			TANMOY				MINIMUM VERSION CHECKING								SUMAN DA,PIJUSH DA,SAIKAT DA
4.0			21-05-2019		V 3.5.0			TANMOY				send new fild sales visit true/false					SUMAN DA,PIJUSH DA,SAIKAT DA
5.0			11-10-2019						TANMOY				spent_duration junk data handel							Pijush Da and Indra da
6.0			26-12-2019						TANMOY				willAlarmTrigger true for plan active employee			Indra da
7.0			25-02-2020						TANMOY				willAlarmTrigger IsShowPlanDetails get from master_user
8.0			02-08-2021						TANMOY				willAlarmTrigger set value user_inactive='N' checking Refer:24220
9.0			14-02-2022		V 2.0.27		Debashis			Added two new fields as IsOnLeaveForToday & OnLeaveForTodayStatus.Row: 646		
*******************************************************************************************************************************************/
BEGIN
	--BEGIN  TRAN

	declare @SQL nvarchar(MAX)
	declare @val nvarchar(MAX)
	declare  @UserId  int
	declare  @Cnt_Id  nvarchar(100)
	declare  @User_Type nvarchar(MAX)
	declare @branchid int
	declare @InternalID varchar(50)
	declare @Imeiuser nvarchar(100)=NULL
	declare @Imeiexists nvarchar(100)=NULL
	declare @attendancecount int=0
	declare @Isattendance varchar(50)='false'
	declare @isOnLeave varchar(50)=''
	declare @add_attendence_time varchar(50)=''
	declare @willAlarmTrigger varchar(50)='false'
	declare @DesignationID varchar(50)=NULL
	declare @Idealtime varchar(50)=NULL
	declare @datefetch datetime =GETDATE()
	DECLARE @isFieldWorkVisible NVARCHAR(10)
	DECLARE @Spent_Duration int=0
	DECLARE @distributor_name NVARCHAR(200),@market_worked NVARCHAR(200)

	declare @Intime varchar(50)=NULL
	declare @Outtime varchar(50)=NULL


	declare @versions int

	IF EXISTS (SELECT * FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='SalesVisitShow' AND [Value]='1')
		BEGIN
			SET  @isFieldWorkVisible='True'
		END
	ELSE
		BEGIN
			SET  @isFieldWorkVisible='False'
		END

	set @versions=REPLACE(REPLACE(REPLACE(REPLACE(@version_name,'Version ',''),'D',''),'L',''),'.','')
	IF(@versions>=(SELECT REPLACE(Value,'.','') FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='min_req_version'))
		BEGIN

		set @datefetch=@login_time
		set @UserId=(select user_id  from  tbl_master_user as usr where  user_loginId=@userName   and user_password=@password and user_inactive='N')
		set @InternalID=(select  user_contactId  from tbl_master_user where user_id=@UserId)
		set @Imeiuser=(select Imei_No  from tbl_User_IMEI usimei where userid=@UserId)


		SET @Intime=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='Intime')
		SET @Outtime=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='Outtime')

		SET @DesignationID=(
		select  N.deg_id  from tbl_master_user as musr
		INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId = musr.user_contactId
		INNER JOIN
		(
		select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from 
		tbl_trans_employeeCTC as cnt 
		left outer  join  tbl_master_designation as desg on desg.deg_id=cnt.emp_Designation
		group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null
		)N
		on  N.emp_cntId=musr.user_contactId 
		where musr.user_id=@UserId)


		set @Idealtime=(select  Ideal_time  from [tbl_FTS_Idealtime_designation] where DesignationID=@DesignationID)
		if(isnull(@Idealtime,'')='')
			BEGIN

				set @Idealtime=(select value from FTS_APP_CONFIG_SETTINGS where [Key]='idle_time')
			END


		IF EXISTS(select  top 1 u.user_id  from tbl_trans_employeeCTC  as c inner join tbl_master_employee e on c.emp_reportTo=e.emp_id inner join tbl_master_user as u on u.user_contactId=e.emp_contactId where u.user_id=@UserId)
			BEGIN
				SET @willAlarmTrigger='true'
			END

		--Rev 8.0 Start
		----REV 6.0  Start
		--IF ((select ISNULL(IsShowPlanDetails,0) from tbl_master_user where user_contactId=(select top 1 user_contactId from tbl_master_user where user_id=@userid))=1 and @willAlarmTrigger='false')
		IF ((select ISNULL(IsShowPlanDetails,0) from tbl_master_user where user_contactId=(select top 1 user_contactId from tbl_master_user where user_id=@userid) AND user_inactive='N')=1 and @willAlarmTrigger='false')
		--Rev 8.0 End
			BEGIN
				SET @willAlarmTrigger='true'
			END
		--REV 6.0  End

		IF EXISTS(select  User_Id from tbl_fts_UserAttendanceLoginlogout where User_Id=@UserId and Login_datetime is not null
		and cast(Login_datetime as date)=cast(GETDATE() as date))
			BEGIN

				set @Isattendance='true'

				--set @isOnLeave=(select  Isonleave from tbl_fts_UserAttendanceLoginlogout where User_Id=@UserId and Login_datetime is not null and cast(Login_datetime as date)=cast(GETDATE() as date))
				--set @add_attendence_time=(select top 1 Attendence_time from tbl_fts_UserAttendanceLoginlogout where User_Id=@UserId and Login_datetime is not null and cast(Login_datetime as date)=cast(GETDATE() as date) order by Id desc)

				select top 1 @isOnLeave=Isonleave,@add_attendence_time=Attendence_time from tbl_fts_UserAttendanceLoginlogout where User_Id=@UserId and Login_datetime is not null and cast(Login_datetime as date)=cast(GETDATE() as date) order by Id desc


			END

			

		IF( datediff(SECOND, 0,  CONVERT(VARCHAR(8),GETDATE(),108)) <= datediff(SECOND, 0, @Outtime) )
			BEGIN
			---------------------------////// IMEI CHECKING /////////////////-----------------------------------------------


			set @Imeiexists=(select top 1 UserId  from tbl_User_IMEI usimei where Imei_No=@ImeiNo order by Id desc)

			if(isnull(@UserId,'') !='')
				BEGIN

				IF  (isnull(@Imeiuser,'')='' and  isnull(@ImeiNo,'')<>'' and isnull(@UserId,'')<>'' and isnull(@Imeiexists,'')='')
					BEGIN

						insert  into tbl_User_IMEI (UserId,Imei_No,CreateDate,CreatedBy) values(@UserId,@ImeiNo,GETDATE(),@UserId)

					END

				IF (@Imeiuser=@ImeiNo or (isnull(@Imeiuser,'')=''  and  isnull(@Imeiexists,'')=''))

					BEGIN

						update tbl_master_user  set  SessionToken=@SessionToken,user_status=1 where user_loginId=@userName   and user_password=@password and user_inactive='N'

						insert  into  tbl_trans_shopuser ([User_Id],sdate,Createddate,location_name,Lat_visit,Long_visit,LoginLogout)
						SELECT  top 1 user_id  ,@datefetch,getdate(),@location_name,@latitude,@longitude,1
						FROM tbl_master_user as usr 
						where user_loginId=@userName  and user_password=@password and user_inactive='N'


						-------------------------Device Token----------------------------------------

						If exists(select  Id  from tbl_FTS_devicetoken where UserID=@UserId)
							BEGIN
								UPDATE tbl_FTS_devicetoken set device_token=@device_token  where UserID=@UserId
							END
						ELSE
							BEGIN
								INSERT INTO tbl_FTS_devicetoken(device_token,UserID)VALUES(@device_token,@UserId)
							END

						--------------------------Attendane Main table Synchronization------------------------------------------

						declare @sqlyyMM varchar(50)


						set @sqlyyMM =SUBSTRING(CONVERT(nvarchar(6),@datefetch, 112),3,2) +  SUBSTRING(CONVERT(nvarchar(6),@datefetch, 112),5,2)

						INSERT INTO  tbl_EmpAttendanceDetails (Emp_InternalId,LogTime)values(@InternalID,@datefetch)

						IF NOT exists(select  *  from tbl_Employee_Attendance where convert(date,Att_Date)=convert(date,@datefetch) and Emp_InternalId=@InternalID)
							BEGIN

								INSERT INTO tbl_Employee_Attendance(UniqueKey,
								Emp_InternalId,
								Att_Date,
								In_Time,
								Out_Time,
								UpdatedBy,
								UpdatedOn,
								YYMM,
								Emp_status,
								Remarks)

								values

								(
								@SessionToken,
								@InternalID
								,@datefetch
								,@datefetch
								,NULL
								,@UserId
								,@datefetch
								,@sqlyyMM
								,'P'
								,''
								)
							END

						ELSE

							BEGIN
								update tbl_Employee_Attendance set Out_Time=@datefetch   where convert(date,Att_Date)=convert(date,@datefetch)  and Emp_InternalId=@InternalID
							END

						IF NOT exists(select  *  from tbl_EmpWiseAttendanceStatus where Emp_InternalId=@InternalID and YYMM=@sqlyyMM)
							BEGIN

								insert into tbl_EmpWiseAttendanceStatus(UniqueKey,Emp_InternalId,YYMM)
								VALUES(@SessionToken,@InternalID,@sqlyyMM)


								set @val='P'
								set @SQL ='update tbl_EmpWiseAttendanceStatus set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''' AND YYMM='''+@sqlyyMM+''''

								EXEC sp_ExecuteSql @SQL
							END
						ELSE
							BEGIN

								set @val='P'

								set @SQL ='update tbl_EmpWiseAttendanceStatus set Day'+cast(DATEPART(dd,@datefetch) as varchar(50))+'='''+@val +''' where Emp_InternalId='''+@InternalID+''' AND YYMM='''+@sqlyyMM+''''
								EXEC sp_ExecuteSql @SQL
							END

						--------------------------End  Attendane Main table Synchronization------------------------------------------





						----------------------------Version  Insertion----------------------------


						if(isnull(@version_name,'') !='' )
							BEGIN

							If exists(select AppVersionHistory_ID from Master_AppVersionUsages where UserId=@UserId)
								BEGIN

									update [Master_AppVersionUsages] set [AppVersionHistory_Number]=@version_name where UserId=@UserId

								END

							ELSE
								BEGIN

									Insert into [Master_AppVersionUsages] ([UserId],[AppVersionHistory_Number],[AppVersionHistory_UpdateDate])
									values(@UserId,@version_name,GETDATE())

								END

							END
						----------------------------Version  Insertion----------------------------


						-----------------------Total Counting Return---------------------

						select  @attendancecount=isnull(count(DISTINCT  cast(SDate as date)),0) from tbl_trans_shopuser where User_Id=@UserId
						
						
						--Start Rev 5.0
						--select  isnull((sum(datepart(hour,isnull(spent_duration,'00:00:00')) * 60)) +sum(datepart(minute,isnull(spent_duration,'00:00:00')) * 1) ,0) as total_time_spent_at_shop
						--,isnull(count(shop_id),0) as total_shop_visited
						--,@attendancecount AS total_attendance
						--from tbl_trans_shopActivitysubmit  where User_Id=@UserId

						BEGIN TRY
						BEGIN TRANSACTION 
     					select  @Spent_Duration=isnull((sum(datepart(hour,isnull(spent_duration,'00:00:00')) * 60)) +sum(datepart(minute,isnull(spent_duration,'00:00:00')) * 1) ,0)											
						from tbl_trans_shopActivitysubmit  where User_Id=@UserId

						 COMMIT
						 END TRY
						 BEGIN CATCH
							IF @@TRANCOUNT > 0
							begin
								ROLLBACK 
								SET @Spent_Duration=0
							end
						 END CATCH
						 
						 select @distributor_name=ISNULL(Distributor_Name,''),@market_worked=ISNULL(Market_Worked,'') from tbl_fts_UserAttendanceLoginlogout 
						where User_Id=@UserId and Login_datetime is not null and cast(Login_datetime as date)=cast(GETDATE() as date) order by Id desc  
						

						 select  @Spent_Duration as total_time_spent_at_shop
						,isnull(count(shop_id),0) as total_shop_visited
						,@attendancecount AS total_attendance
						from tbl_trans_shopActivitysubmit  where User_Id=@UserId
						
						--End Rev 5.0
						
						-----------------------Total Counting Return---------------------


						SELECT  top 1 cast(USR.user_id as varchar(50)) as [user_id],cnt_firstName+' '+cnt_lastName  as name,phf.phf_phoneNumber as phone_number,addr.add_address1,eml_email as email 
						,@ImeiNo as imeino
						,ver.AppVersionHistory_Number as version_name
						,case when isnull(STAT.id,'') <>'' then (@Weburl  +case when isnull(saladdr.ProfileImage,'')='' then'profile.png' else  saladdr.ProfileImage end) else null end as profile_image
						,S.add_address1 as [address]
						,saladdr.Latitude as latitude
						,saladdr.longitude as longitude
						,S.add_country   as country 
						,cast(S.add_city as varchar(50)) as city
						--,saladdr.stateid as [state]
						,STAT.id as [state]
						,pinzip.pin_code as pincode
						,@willAlarmTrigger as willAlarmTrigger
						,@Idealtime as idle_time
						,'200' as success
						,@Isattendance as isAddAttendence
						,@isOnLeave as  isOnLeave
						,@add_attendence_time as add_attendence_time
						,cast(Gps_Accuracy as varchar(50)) as Gps_Accuracy
						,home.Latitude as home_lat
						,home.Longitude as home_long
						,@Intime as user_login_time
						,@Outtime as user_logout_time,
						@isFieldWorkVisible AS isFieldWorkVisible
						,@distributor_name as distributor_name
						,@market_worked as market_worked,
						--Rev 9.0
						ULA.IsOnLeaveForToday,ULA.OnLeaveForTodayStatus
						--End of Rev 9.0
						FROM tbl_master_user as usr
						LEFT OUTER JOIN [Master_AppVersionUsages] ver on  usr.user_id=ver.UserId
						LEFT OUTER JOIN tbl_master_contact  as cont on usr.user_contactId=cont.cnt_internalId
						LEFT OUTER JOIN tbl_master_address as addr on addr.add_cntId= usr.user_contactId 
						LEFT OUTER JOIN tbl_master_phonefax as phf on phf.phf_cntId= usr.user_contactId 
						LEFT OUTER JOIN tbl_master_email as eml on eml.eml_internalId= usr.user_contactId 
						LEFT OUTER JOIN tbl_salesman_address as saladdr on usr.user_id= saladdr.UserId 
						LEFT OUTER  JOIN (
						SELECT   add_cntId,add_state,add_city,add_country,add_pin,add_address1  FROM  tbl_master_address  where add_addressType='Office'
						)S on S.add_cntId=cont.cnt_internalId
						--LEFT OUTER JOIN tbl_master_pinzip as pinzip on pinzip.pin_id=S.add_pin
						LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state
						LEFT outer join tbl_master_pinzip as pinzip on pinzip.pin_id=S.add_pin
						LEFT OUTER JOIN tbl_FTS_userhomeaddress as home on home.UserID=usr.user_id
						--Rev 9.0
						LEFT OUTER JOIN (
						SELECT TOP 1 USER_ID,CASE WHEN CURRENT_STATUS='APPROVE' THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsOnLeaveForToday,ISNULL(CURRENT_STATUS,'') AS OnLeaveForTodayStatus 
						FROM FTS_USER_LEAVEAPPLICATION
						WHERE USER_ID=@UserId AND CAST(GETDATE() AS DATE) BETWEEN CAST(LEAVE_START_DATE AS DATE) AND CAST(LEAVE_END_DATE AS DATE)
						) ULA ON usr.user_id=ULA.USER_ID 
						--End of Rev 9.0
						--v2.0

						--Inner Join    tbl_trans_employeeCTC as ct2   on ct2.emp_cntId=cont.cnt_internalId
						--inner join
						--(select  max(emp_id) as maxemp ,emp_cntId  from tbl_trans_employeeCTC ct1 group by emp_cntId)T on T.maxemp=ct2.emp_id
						--inner join 
						--(
						--select distinct BeginTime,EndTime,hourId from tbl_EmpWorkingHoursDetails)worknghrs on worknghrs.hourId=ct2.emp_workinghours
						--v2.0

						where
						--user_loginId=@userName  and user_password=@password 
						USR.user_id=@UserId  and user_inactive='N'
						order by  phf.Isdefault desc

						---1.0

						


						if NOT EXISTS (SELECT * FROM TBL_FTS__NOTALLOW_STATE_TARGET WHERE DESIGNATION_ID=@DesignationID)--<>119
							BEGIN

							---1.0
							IF EXISTS(select *  from FTS_EMPSTATEMAPPING where STATE_ID=0 and  USER_ID=@UserId)
								BEGIN
									select  stat.id as id,stat.state as state_name  from tbl_master_state as stat
									INNER JOIN 
									(
									select distinct  add_state  from tbl_master_address
									)T on stat.id=T.add_state


								END
							ELSE
								BEGIN
									select  STATE_ID as id,stat.state as state_name  from FTS_EMPSTATEMAPPING as empstate  inner  join  tbl_master_state as stat on empstate.STATE_ID=stat.id where  USER_ID=@UserId 
								END
							END

							

					END

				ELSE

					BEGIN
						select 0
						select '207' as success
					END


				END

			ELSE
				BEGIN
					select 0
					select '202' as success
				END
			END

		ELSE

			BEGIN
				select 0
				select '220' as success
			END

		END
	ELSE
		BEGIN
			select 0
			select '206' as success,'New version is available now. Please update it from the Play Store.' as 'Dynamic_message' -- Unless you can''t login into the app.
		END

	--COMMIT TRAN
End