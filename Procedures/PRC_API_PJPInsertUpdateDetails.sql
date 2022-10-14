-- exec PRC_API_PJPInsertUpdateDetails @Action='PJP_ADD',@UserID='11740',@PJP_Date='2020-04-03',@From_Time='11.24 am',@To_Time='11.50 am',@SHOP_CODE='11740_1823249882737',@LOCATIONS='Jadavpur',@REMARKS='fgd',@CREATED_USER='378'
-- exec PRC_API_PJPInsertUpdateDetails @Action='TeamLocationList',@UserID='11708',@PJP_Date='2020-04-03'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_API_PJPInsertUpdateDetails]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_API_PJPInsertUpdateDetails] AS' 
END
GO

ALTER PROCEDURE  [dbo].[PRC_API_PJPInsertUpdateDetails]
(
@Action NVARCHAR(50)=NULL,
@UserID NVARCHAR(100)=NULL,
@PJP_Date NVARCHAR(20)=null,
@From_Time NVARCHAR(10)=null,
@To_Time NVARCHAR(10)=null,
@SHOP_CODE NVARCHAR(100)=null,
@LOCATIONS NVARCHAR(300)=null,
@REMARKS NVARCHAR(500)=null,
@CREATED_USER NVARCHAR(100)=NULL,
@PJP_ID NVARCHAR(100)=NULL,
@YEARS NVARCHAR(10)=NULL,
@MONTH NVARCHAR(3)=NULL,
@pjp_lat NVARCHAR(MAX)=NULL,
@pjp_long NVARCHAR(MAX)=NULL,
@pjp_radius NVARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************
1.0			Tanmoy		02-04-2020	Create Procedure
2.0			Tanmoy		15-04-2020	@Action='TeamLocationList' remove Login from and logout at
3.0			Tanmoy		22-04-2020	ADD THREE COLUMN
4.0			Tanmoy		02-06-2020	@Action='PJP_List' after shop name add Area and City
5.0			Tanmoy		16-07-2020	@Action='TeamLocationList' remove Login from and Logout at from List and calculate total distance
*******************************************************************************************************************************************/ 
BEGIN
	SET NOCOUNT ON

	declare @scope bigint,@FROMDATE NVARCHAR(10),@TODATE NVARCHAR(10)

	IF @Action='PJP_ADD'
		BEGIN		
			INSERT INTO FTS_PJPPlanDetails WITH(TABLOCK) (User_Id,PJP_Date,From_Time,To_Time,SHOP_CODE,LOCATIONS,REMARKS,pjp_lat,pjp_long,pjp_radius,CREATED_BY,CREATED_ON)
			VALUES(@UserID,@PJP_Date,@From_Time,@To_Time,@SHOP_CODE,@LOCATIONS,@REMARKS,@pjp_lat,@pjp_long,@pjp_radius,@CREATED_USER,GETDATE())
		
			set @scope=SCOPE_IDENTITY();

			select @scope as msg
		END

	IF @Action='PJP_EDIT'
		BEGIN
			INSERT INTO FTS_PJPPlanDetails_LOG WITH(TABLOCK) 
			SELECT PJP_ID,User_Id,PJP_Date,From_Time,To_Time,SHOP_CODE,LOCATIONS,REMARKS,CREATED_BY,CREATED_ON,UPDATED_BY,UPDATED_ON,pjp_lat,pjp_long,pjp_radius 
			FROM FTS_PJPPlanDetails WITH(NOLOCK) WHERE PJP_ID=@PJP_ID

			UPDATE FTS_PJPPlanDetails WITH(TABLOCK) SET User_Id=@UserID,PJP_Date=@PJP_Date,From_Time=@From_Time,To_Time=@To_Time,
			SHOP_CODE=@SHOP_CODE,LOCATIONS=@LOCATIONS,REMARKS=@REMARKS,UPDATED_BY=@CREATED_USER,UPDATED_ON=GETDATE(),
			pjp_lat=@pjp_lat,pjp_long=@pjp_long,pjp_radius=@pjp_radius
			WHERE PJP_ID=@PJP_ID

			set @scope=SCOPE_IDENTITY();

			select @scope as msg
		END

	IF @Action='PJP_DetailsList'
		BEGIN
			IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
				DROP TABLE #TEMPCONTACT
			CREATE TABLE #TEMPCONTACT
				(
					cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				)
			CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WITH(NOLOCK) WHERE cnt_contactType IN('EM')

			SET @FROMDATE=CONVERT(VARCHAR(10),DATEADD(MONTH, CONVERT(INT,@MONTH) - 1, @YEARS),120)
			SET @TODATE=CONVERT(VARCHAR(10),DATEADD(DAY, -1, DATEADD(MONTH, CONVERT(INT,@MONTH), @YEARS)),120)

			SELECT PJP.PJP_ID,PJP.User_Id,CONVERT(NVARCHAR(10),PJP.PJP_Date,120) AS PJP_Date,PJP.From_Time,PJP.To_Time,PJP.SHOP_CODE,PJP.LOCATIONS,
			PJP.REMARKS,SHOP.Shop_Name,
			CASE WHEN PJP.UPDATED_BY IS NULL THEN PJP.CREATED_BY ELSE PJP.UPDATED_BY END CREATED_USER ,
			REPORTTO, 1 AS isUpdateable,PJP.pjp_lat,PJP.pjp_long,PJP.pjp_radius
			FROM FTS_PJPPlanDetails PJP WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_Master_shop SHOP WITH(NOLOCK) ON SHOP.Shop_Code=PJP.SHOP_CODE
			LEFT OUTER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=PJP.User_Id		
			LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'')+' '+ISNULL(CNT.CNT_MIDDLENAME,'')+' '+ISNULL(CNT.CNT_LASTNAME,'') AS REPORTTO,
			DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP WITH(NOLOCK) 
			INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo 
			INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId 
			INNER JOIN ( 
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId 
			WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=USR.user_contactId
			WHERE CONVERT(NVARCHAR(10),PJP.PJP_Date,120) BETWEEN CONVERT(NVARCHAR(10),@FROMDATE,120) AND CONVERT(NVARCHAR(10),@TODATE,120)
			AND PJP.User_Id=@UserID

			SELECT REPORTTO FROM tbl_master_user USR WITH(NOLOCK) 
			LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'')+' '+ISNULL(CNT.CNT_MIDDLENAME,'')+' '+ISNULL(CNT.CNT_LASTNAME,'') AS REPORTTO,
			DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP WITH(NOLOCK) 
			INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo 
			INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId 
			INNER JOIN ( 
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId 
			WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=USR.user_contactId
			WHERE user_id=@UserID

			DROP TABLE #TEMPCONTACT
		END

	IF @Action='PJP_DELETE'
		BEGIN
			INSERT INTO FTS_PJPPlanDetails_LOG WITH(TABLOCK) 
			SELECT PJP_ID,User_Id,PJP_Date,From_Time,To_Time,SHOP_CODE,LOCATIONS,REMARKS,CREATED_BY,CREATED_ON,UPDATED_BY,UPDATED_ON,pjp_lat,pjp_long,pjp_radius 
			FROM FTS_PJPPlanDetails WITH(NOLOCK) WHERE PJP_ID=@PJP_ID

			DELETE FROM FTS_PJPPlanDetails WHERE PJP_ID=@PJP_ID

			set @scope=SCOPE_IDENTITY();

			select @scope as msg
		END

	IF @Action='CUSTOMER_LIST'
		BEGIN
			SELECT Shop_Code AS cust_id,Shop_Name AS cust_name FROM tbl_Master_shop WITH(NOLOCK) WHERE Shop_CreateUser=@UserID
		END

	IF @Action='PJP_ConfigList'
		BEGIN
			IF OBJECT_ID('tempdb..#TEMPCONTACT1') IS NOT NULL
				DROP TABLE #TEMPCONTACT1
			CREATE TABLE #TEMPCONTACT1
				(
					cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				)
			CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT1(cnt_internalId,cnt_contactType ASC)
			INSERT INTO #TEMPCONTACT1
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WITH(NOLOCK) WHERE cnt_contactType IN('EM')

			select (select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='pjp_past_days' AND IsActive=1) as pjp_past_days,
			REPORTTO from tbl_master_user USR WITH(NOLOCK) 
			LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'')+' '+ISNULL(CNT.CNT_MIDDLENAME,'')+' '+ISNULL(CNT.CNT_LASTNAME,'') AS REPORTTO,
			DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP WITH(NOLOCK) 
			INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo 
			INNER JOIN #TEMPCONTACT1 CNT ON CNT.cnt_internalId=EMP.emp_contactId 
			INNER JOIN ( 
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId 
			WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=USR.user_contactId
			WHERE User_Id=@UserID

			DROP TABLE #TEMPCONTACT1
		END
	IF @Action='TeamLocationList'
		BEGIN		
			DECLARE @total_visit_distance NVARCHAR(10)

			SET @total_visit_distance=(SELECT TOP(1)StaticDistance FROM tbl_fts_UserAttendanceLoginlogout WITH(NOLOCK) WHERE CAST(Work_datetime AS DATE) =@PJP_Date AND User_Id=@UserID)

			SELECT VisitId AS id,ISNULL(Lat_visit,'0.00') AS latitude,ISNULL(Long_visit,'0.00') AS longitude,
			CASE WHEN ISNULL(location_name,'')='' THEN 'Unknown' 
			WHEN location_name LIKE '%Login from%' THEN REPLACE(location_name,'Login from ','') ELSE REPLACE(location_name,'Logout at ','') END AS location_name,
			ISNULL(distance_covered,0.00) AS distance_covered,ISNULL(Stime,'0:00') AS last_update_time,ISNULL(shops_covered,0) AS shops_covered,
			ISNULL(meeting_attended,0) AS meetings_attended,network_status,battery_percentage FROM tbl_trans_shopuser WITH(NOLOCK) 
			WHERE User_Id=@UserID AND CONVERT(NVARCHAR(10),SDate,120) = CONVERT(NVARCHAR(10),@PJP_Date,120)
			AND location_name NOT LIKE '%Login from%' AND location_name NOT LIKE '%Logout at%'
			UNION ALL
			SELECT VisitId AS id,ISNULL(Lat_visit,'0.00') AS latitude,ISNULL(Long_visit,'0.00') AS longitude,
			CASE WHEN ISNULL(location_name,'')='' THEN 'Unknown' 
			WHEN location_name LIKE '%Login from%' THEN REPLACE(location_name,'Login from ','') ELSE REPLACE(location_name,'Logout at ','') END AS location_name,
			--ISNULL(location_name,'UNKNOWN') AS location_name,
			ISNULL(distance_covered,0.00) AS distance_covered,ISNULL(Stime,'0:00') AS last_update_time,ISNULL(shops_covered,0) AS shops_covered,
			ISNULL(meeting_attended,0) AS meetings_attended,network_status,battery_percentage FROM TBL_TRANS_SHOPUSER_ARCH WITH(NOLOCK) 
			WHERE User_Id=@UserID AND CONVERT(NVARCHAR(10),SDate,120) = CONVERT(NVARCHAR(10),@PJP_Date,120)
			AND location_name NOT LIKE '%Login from%' AND location_name NOT LIKE '%Logout at%' 

			SELECT SUM(distance_covered) total_distance,CASE WHEN ISNULL(@total_visit_distance,'')='' THEN '0.00'  ELSE @total_visit_distance end AS total_visit_distance FROM
			(
			SELECT SUM(distance_covered) as distance_covered FROM tbl_trans_shopuser WITH(NOLOCK) 
			WHERE User_Id=@UserID AND CONVERT(NVARCHAR(10),SDate,120) = CONVERT(NVARCHAR(10),@PJP_Date,120)
			AND location_name NOT LIKE '%Login from%' AND location_name NOT LIKE '%Logout at%'
			UNION ALL
			SELECT SUM(distance_covered) as distance_covered FROM TBL_TRANS_SHOPUSER_ARCH WITH(NOLOCK) 
			WHERE User_Id=@UserID AND CONVERT(NVARCHAR(10),SDate,120) = CONVERT(NVARCHAR(10),@PJP_Date,120)
			AND location_name NOT LIKE '%Login from%' AND location_name NOT LIKE '%Logout at%'
			)  as A
		END

	IF @Action='PJP_List'
		BEGIN
			IF OBJECT_ID('tempdb..#TEMPCONTACTL') IS NOT NULL
				DROP TABLE #TEMPCONTACTL
			CREATE TABLE #TEMPCONTACTL
				(
					cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				)
			CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACTL(cnt_internalId,cnt_contactType ASC)
			INSERT INTO #TEMPCONTACTL
			SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType FROM TBL_MASTER_CONTACT WITH(NOLOCK) WHERE cnt_contactType IN('EM')

			SELECT PJP.PJP_ID,PJP.User_Id,CONVERT(NVARCHAR(10),PJP.PJP_Date,120) AS PJP_Date,PJP.From_Time,PJP.To_Time,PJP.SHOP_CODE,PJP.LOCATIONS,
			PJP.REMARKS,
			SHOP.Shop_Name +' (Area : ' + CASE WHEN ISNULL(SHOP.Area_id,'')='' THEN 'N.A.)' ELSE ARA.area_name+','+CIT.city_name+')' END AS Shop_Name,
			CASE WHEN PJP.UPDATED_BY IS NULL THEN PJP.CREATED_BY ELSE PJP.UPDATED_BY END CREATED_USER ,
			REPORTTO, 1 AS isUpdateable
			FROM FTS_PJPPlanDetails PJP WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_Master_shop SHOP WITH(NOLOCK) ON SHOP.Shop_Code=PJP.SHOP_CODE
			LEFT OUTER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=PJP.User_Id
			LEFT OUTER JOIN tbl_master_area ARA WITH(NOLOCK) ON ARA.area_id=SHOP.Area_id
			LEFT OUTER JOIN tbl_master_city CIT WITH(NOLOCK) ON CIT.city_id=ARA.city_id		
			LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId,ISNULL(CNT.CNT_FIRSTNAME,'')+' '+ISNULL(CNT.CNT_MIDDLENAME,'')+' '+ISNULL(CNT.CNT_LASTNAME,'') AS REPORTTO,
			DESG.deg_designation AS RPTTODESG FROM tbl_master_employee EMP WITH(NOLOCK) 
			INNER JOIN tbl_trans_employeeCTC EMPCTC WITH(NOLOCK) ON EMP.emp_id=EMPCTC.emp_reportTo 
			INNER JOIN #TEMPCONTACTL CNT ON CNT.cnt_internalId=EMP.emp_contactId 
			INNER JOIN ( 
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt WITH(NOLOCK) 
			LEFT OUTER JOIN tbl_master_designation desg WITH(NOLOCK) ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId 
			WHERE EMPCTC.emp_effectiveuntil IS NULL ) RPTTO ON RPTTO.emp_cntId=USR.user_contactId
			WHERE CONVERT(NVARCHAR(10),PJP.PJP_Date,120) = CONVERT(NVARCHAR(10),@PJP_Date,120)
			AND PJP.User_Id=@UserID		

			DROP TABLE #TEMPCONTACTL
		END

	SET NOCOUNT OFF
END