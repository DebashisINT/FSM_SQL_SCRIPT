IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APISHOPREVISITAUDIOINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APISHOPREVISITAUDIOINFO] AS' 
END
GO

ALTER  PROCEDURE [dbo].[PRC_APISHOPREVISITAUDIOINFO]
(
@ACTION NVARCHAR(20),
@USER_ID NVARCHAR(50)=NULL,
@SHOP_ID NVARCHAR(100)=NULL,
@VISIT_DATETIME DATETIME=NULL,
@REVISITORVISIT CHAR(1)=NULL,
@SHOPVISIT_AUDIO NVARCHAR(500)=NULL,
@AUDIOPATH NVARCHAR(500)=NULL
) --WITH ENCRYPTION
AS
/************************************************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 31/07/2024
Module	   : Shop Revisit Audio Info Details.Refer: Row: 957
************************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

		IF @ACTION='SHOPAUDIOSAVE'
			BEGIN
				INSERT INTO FSMUSERREVISITAUDIO(USERID,SHOPID,VISIT_DATETIME,REVISITORVISIT,AUDIONAME,AUDIOPATH,CREATED_BY,CREATED_ON)
				SELECT @USER_ID,@SHOP_ID,@VISIT_DATETIME,@REVISITORVISIT,@SHOPVISIT_AUDIO,@AUDIOPATH,@USER_ID,GETDATE()
				SELECT 1
			END
	SET NOCOUNT OFF
END
GO