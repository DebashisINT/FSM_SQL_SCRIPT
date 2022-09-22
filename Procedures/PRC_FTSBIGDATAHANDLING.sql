--EXEC PRC_FTSBIGDATAHANDLING

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSBIGDATAHANDLING]') AND TYPE in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSBIGDATAHANDLING] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSBIGDATAHANDLING]
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 26/12/2018
Module	   : Big data handle
1.0					Tanmoy		22-01-2020		add new column for tbl_trans_shopActivitysubmit_Archive
2.0		v2.0.32		Debashis	22-09-2022		Added a new table.Row: 743
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @FROMDATE NVARCHAR(10),@TODATE DATETIME
	SET @TODATE=GETDATE()
	SET @FROMDATE=DATEADD(DAY, -46, CONVERT(DATE, @TODATE))

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'TBL_TRANS_SHOPUSER_ARCH') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE TBL_TRANS_SHOPUSER_ARCH(
			[VisitId] [bigint] NOT NULL,
			[User_Id] [bigint] NULL,
			[Shop_Id] [bigint] NULL,
			[Lat_visit] [varchar](max) NULL,
			[Long_visit] [varchar](max) NULL,
			[location_name] [varchar](max) NULL,
			[distance_covered] [varchar](max) NULL,
			[SDate] [datetime] NULL,
			[Stime] [varchar](100) NULL,
			[shops_covered] [varchar](max) NULL,
			[Createddate] [datetime] NULL,
			[LoginLogout] [int] NULL,
			CONSTRAINT PK_VisitId PRIMARY KEY (VisitId))
		 CREATE NONCLUSTERED INDEX [IX_shopuserARCH] ON TBL_TRANS_SHOPUSER_ARCH([User_Id] ASC,[LoginLogout] ASC)INCLUDE ([SDate])
		END

	INSERT INTO TBL_TRANS_SHOPUSER_ARCH
	--SELECT * FROM tbl_trans_shopuser WHERE CONVERT(NVARCHAR(10),SDate,120) NOT BETWEEN CONVERT(NVARCHAR(10),@FROMDATE,120) AND GETDATE()

	--DELETE FROM tbl_trans_shopuser WHERE CONVERT(NVARCHAR(10),SDate,120) NOT BETWEEN CONVERT(NVARCHAR(10),@FROMDATE,120) AND GETDATE()
	SELECT * FROM tbl_trans_shopuser WHERE CONVERT(NVARCHAR(10),SDate,120) < CONVERT(NVARCHAR(10),GETDATE(),120)

	DELETE FROM tbl_trans_shopuser WHERE CONVERT(NVARCHAR(10),SDate,120) < CONVERT(NVARCHAR(10),GETDATE(),120)


	DECLARE @DateTime DateTime=DateAdd(month,-3,GETDATE())

	--SELECT @DateTime


	INSERT INTO tbl_trans_shopActivitysubmit_Archive
	(User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,
	total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,LATITUDE,LONGITUDE,REMARKS,
	MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,
	CheckIn_Time,CheckIn_Address,CheckOut_Time,CheckOut_Address,start_timestamp,device_model,battery,net_status,net_type,android_version)

	SELECT User_Id,Shop_Id,visited_date,visited_time,spent_duration,Createddate,
	total_visit_count,shopvisit_image,Is_Newshopadd,distance_travelled,ISUSED,
	LATITUDE,LONGITUDE,REMARKS,MEETING_ADDRESS,MEETING_PINCODE,MEETING_TYPEID,ISMEETING,IsOutStation,IsFirstVisit,Outstation_Distance,early_revisit_reason,
	CheckIn_Time,CheckIn_Address,CheckOut_Time,CheckOut_Address,start_timestamp,device_model,battery,net_status,net_type,android_version
	FROM tbl_trans_shopActivitysubmit where CAST(visited_time as DATE)<CAST(@DateTime as DATE)

	DELETE FROm  tbl_trans_shopActivitysubmit where CAST(visited_time as DATE)<CAST(@DateTime as DATE)

	--Rev 2.0
	SET IDENTITY_INSERT FSMUSERWISEGPSNETSTATUS_ARCH ON
	INSERT INTO FSMUSERWISEGPSNETSTATUS_ARCH(ID,USER_ID,DATE_TIME,GPS_SERVICE_STATUS,NETWORK_STATUS,CREATE_DATE,SCHEDULEDATE)
	SELECT ID,USER_ID,DATE_TIME,GPS_SERVICE_STATUS,NETWORK_STATUS,CREATE_DATE,GETDATE() FROM FSMUSERWISEGPSNETSTATUS 
	WHERE CONVERT(NVARCHAR(10),DATE_TIME,120)<=CONVERT(NVARCHAR(10),GETDATE()-7,120)
	SET IDENTITY_INSERT FSMUSERWISEGPSNETSTATUS_ARCH OFF

	DELETE FROM FSMUSERWISEGPSNETSTATUS WHERE CONVERT(NVARCHAR(10),DATE_TIME,120)<=CONVERT(NVARCHAR(10),GETDATE()-7,120)
	--End of Rev 2.0

END