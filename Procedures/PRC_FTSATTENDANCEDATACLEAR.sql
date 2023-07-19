--EXEC PRC_FTSATTENDANCEDATACLEAR

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSATTENDANCEDATACLEAR]') AND TYPE in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSATTENDANCEDATACLEAR] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSATTENDANCEDATACLEAR]

AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 31/08/2022
Module	   : Attendance data Archive from main tables
1.0		v2.0.38		Debashis	25-01-2023		Increase month by 3 from 2.
2.0		v2.0.41		Debashis	19-07-2023		Following table records shall be kept for 2 months.
												Shopsubmit
												Daystart Dayend
												Attendance Login Logout.Refer: 0026597
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'tbl_fts_UserAttendanceLoginlogout_ARCH') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE [dbo].[tbl_fts_UserAttendanceLoginlogout_ARCH](
			[Id] [bigint] IDENTITY(1,1) NOT NULL,
			[User_Id] [bigint] NULL,
			[Login_datetime] [datetime] NULL,
			[Logout_datetime] [datetime] NULL,
			[Latitude] [varchar](100) NULL,
			[Longitude] [varchar](100) NULL,
			[Work_Type] [varchar](100) NULL,
			[Work_Desc] [varchar](max) NULL,
			[Work_Address] [varchar](max) NULL,
			[Work_datetime] [datetime] NULL,
			[Isonleave] [varchar](50) NULL,
			[Attendence_time] [varchar](50) NULL,
			[Leave_Type] [int] NULL,
			[Leave_FromDate] [datetime] NULL,
			[Leave_ToDate] [datetime] NULL,
			[Distributor_Name] [nvarchar](500) NULL,
			[Market_Worked] [nvarchar](500) NULL,
			[LeaveReason] [nvarchar](500) NULL,
			[From_AreaId] [bigint] NULL,
			[To_AreaId] [bigint] NULL,
			[Distance] [numeric](18, 2) NULL,
			[StaticDistance] [numeric](18, 2) NULL
			) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

			CREATE NONCLUSTERED INDEX [IX_PERFORM] ON [dbo].[tbl_fts_UserAttendanceLoginlogout_ARCH]
			(
				[User_Id] ASC,
				[Logout_datetime] ASC,
				[Isonleave] ASC,
				[Login_datetime] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 92) ON [PRIMARY]

			CREATE NONCLUSTERED INDEX [IXIDDTLEAVE] ON [dbo].[tbl_fts_UserAttendanceLoginlogout_ARCH]
			(
				[User_Id] ASC,
				[Logout_datetime] ASC,
				[Isonleave] ASC,
				[Login_datetime] ASC
			)
			INCLUDE ( 	[Market_Worked]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 92) ON [PRIMARY]

			CREATE NONCLUSTERED INDEX [LOGINOUTONLEAVE] ON [dbo].[tbl_fts_UserAttendanceLoginlogout_ARCH]
			(
				[Logout_datetime] ASC,
				[Isonleave] ASC,
				[Login_datetime] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 92) ON [PRIMARY]
		END

		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FSMUSERWISEDAYSTARTEND_ARCH') AND TYPE IN (N'U'))
			BEGIN
				CREATE TABLE [dbo].[FSMUSERWISEDAYSTARTEND_ARCH](
				[ID] [int] IDENTITY(1,1) NOT NULL,
				[USER_ID] [bigint] NULL,
				[STARTENDDATE] [datetime] NULL,
				[LOCATION_NAME] [nvarchar](1000) NULL,
				[LATITUDE] [nvarchar](max) NULL,
				[LONGITUDE] [nvarchar](max) NULL,
				[SHOP_TYPE] [int] NULL,
				[SHOP_ID] [nvarchar](100) NULL,
				[ISSTART] [bit] NULL,
				[ISEND] [bit] NULL,
				[SALE_VALUE] [numeric](18, 2) NULL,
				[REMARKS] [nvarchar](1000) NULL,
				[DAYSTARTENDIMAGE] [nvarchar](1000) NULL,
				[VISITDDID] [nvarchar](100) NULL,
				[VISITDDNAME] [nvarchar](500) NULL,
				[VISITDDDATE] [datetime] NULL,
				[ISDDVISTEDONCEBYDAY] [bit] NULL
				) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

				CREATE NONCLUSTERED INDEX [IDXISEND] ON [dbo].[FSMUSERWISEDAYSTARTEND_ARCH]
				(
					[ISEND] ASC
				)
				INCLUDE ( 	[USER_ID],
					[STARTENDDATE]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 92) ON [PRIMARY]

				CREATE NONCLUSTERED INDEX [IDXISSTART] ON [dbo].[FSMUSERWISEDAYSTARTEND_ARCH]
				(
					[ISSTART] ASC
				)
				INCLUDE ( 	[USER_ID],
					[STARTENDDATE],
					[LOCATION_NAME]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 92) ON [PRIMARY]
			END

		SET IDENTITY_INSERT tbl_fts_UserAttendanceLoginlogout_ARCH ON
		INSERT INTO tbl_fts_UserAttendanceLoginlogout_ARCH(Id,User_Id,Login_datetime,Logout_datetime,Latitude,Longitude,Work_Type,Work_Desc,Work_Address,Work_datetime,Isonleave,Attendence_time,Leave_Type,
		Leave_FromDate,Leave_ToDate,Distributor_Name,Market_Worked,LeaveReason,From_AreaId,To_AreaId,Distance,StaticDistance)
		SELECT Id,User_Id,Login_datetime,Logout_datetime,Latitude,Longitude,Work_Type,Work_Desc,Work_Address,Work_datetime,Isonleave,Attendence_time,Leave_Type,Leave_FromDate,Leave_ToDate,Distributor_Name,
		Market_Worked,LeaveReason,From_AreaId,To_AreaId,Distance,StaticDistance FROM tbl_fts_UserAttendanceLoginlogout
		--Rev 1.0
		--WHERE CONVERT(NVARCHAR(10),Work_datetime,120) < CONVERT(NVARCHAR(10),DATEADD(month, -2, GETDATE()),120)
		--Rev 2.0
		--WHERE CONVERT(NVARCHAR(10),Work_datetime,120) < CONVERT(NVARCHAR(10),DATEADD(month, -3, GETDATE()),120)
		WHERE CONVERT(NVARCHAR(10),Work_datetime,120) < CONVERT(NVARCHAR(10),DATEADD(month, -2, GETDATE()),120)
		--End of Rev 2.0
		--End of Rev 1.0
		SET IDENTITY_INSERT tbl_fts_UserAttendanceLoginlogout_ARCH OFF

		--Rev 1.0
		--DELETE FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120) < CONVERT(NVARCHAR(10),DATEADD(month, -2, GETDATE()),120)
		--Rev 2.0
		--DELETE FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120) < CONVERT(NVARCHAR(10),DATEADD(month, -3, GETDATE()),120)
		DELETE FROM tbl_fts_UserAttendanceLoginlogout WHERE CONVERT(NVARCHAR(10),Work_datetime,120) < CONVERT(NVARCHAR(10),DATEADD(month, -2, GETDATE()),120)
		--End of Rev 2.0
		--End of Rev 1.0

		SET IDENTITY_INSERT FSMUSERWISEDAYSTARTEND_ARCH ON
		INSERT INTO FSMUSERWISEDAYSTARTEND_ARCH(ID,USER_ID,STARTENDDATE,LOCATION_NAME,LATITUDE,LONGITUDE,SHOP_TYPE,SHOP_ID,ISSTART,ISEND,SALE_VALUE,REMARKS,DAYSTARTENDIMAGE,VISITDDID,VISITDDNAME,
		VISITDDDATE,ISDDVISTEDONCEBYDAY)
		SELECT ID,USER_ID,STARTENDDATE,LOCATION_NAME,LATITUDE,LONGITUDE,SHOP_TYPE,SHOP_ID,ISSTART,ISEND,SALE_VALUE,REMARKS,DAYSTARTENDIMAGE,VISITDDID,VISITDDNAME,VISITDDDATE,ISDDVISTEDONCEBYDAY
		FROM FSMUSERWISEDAYSTARTEND
		--Rev 1.0
		--WHERE CONVERT(NVARCHAR(10),STARTENDDATE,120) < CONVERT(NVARCHAR(10),DATEADD(month, -2, GETDATE()),120) 
		--Rev 2.0
		--WHERE CONVERT(NVARCHAR(10),STARTENDDATE,120) < CONVERT(NVARCHAR(10),DATEADD(month, -3, GETDATE()),120) 
		WHERE CONVERT(NVARCHAR(10),STARTENDDATE,120) < CONVERT(NVARCHAR(10),DATEADD(month, -2, GETDATE()),120) 
		--End of Rev 2.0
		--End of Rev 1.0
		SET IDENTITY_INSERT FSMUSERWISEDAYSTARTEND_ARCH OFF

		--Rev 1.0
		--DELETE FROM FSMUSERWISEDAYSTARTEND WHERE CONVERT(NVARCHAR(10),STARTENDDATE,120) < CONVERT(NVARCHAR(10),DATEADD(month, -2, GETDATE()),120) 
		--Rev 2.0
		--DELETE FROM FSMUSERWISEDAYSTARTEND WHERE CONVERT(NVARCHAR(10),STARTENDDATE,120) < CONVERT(NVARCHAR(10),DATEADD(month, -3, GETDATE()),120)
		DELETE FROM FSMUSERWISEDAYSTARTEND WHERE CONVERT(NVARCHAR(10),STARTENDDATE,120) < CONVERT(NVARCHAR(10),DATEADD(month, -2, GETDATE()),120)
		--End of Rev 2.0
		--End of Rev 1.0

	SET NOCOUNT OFF
END