IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_Locationupdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_Locationupdate] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_FTS_Locationupdate]
(
@session_token varchar(MAX)=NULL,
@user_id varchar(50)=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************
1.0			TANMOY		20-01-2020		INSERT EXTRA DATA metting_attended
****************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	INSERT INTO [tbl_trans_shopuser] WITH(TABLOCK)([User_Id],[Shop_Id],[Lat_visit],[Long_visit],[location_name],[distance_covered],[SDate],[Stime],[shops_covered],Createddate,[meeting_attended],[home_distance],network_status,battery_percentage,home_duration)
    SELECT @user_id,NULL,
	XMLproduct.value('(latitude/text())[1]','nvarchar(MAX)'),
	XMLproduct.value('(longitude/text())[1]','nvarchar(MAX)'),
	XMLproduct.value('(location_name/text())[1]','nvarchar(MAX)'),
	XMLproduct.value('(distance_covered/text())[1]','nvarchar(MAX)'),
	XMLproduct.value('(date/text())[1]','datetime'),
	XMLproduct.value('(last_update_time/text())[1]','nvarchar(120)'),
	XMLproduct.value('(shops_covered/text())[1]','nvarchar(MAX)'),	
	GETDATE() ,
	--REV 1.0 START
	XMLproduct.value('(meeting_attended/text())[1]','INT'),
	--REV 1.0 END
	XMLproduct.value('(home_distance/text())[1]','nvarchar(MAX)'),
	XMLproduct.value('(network_status/text())[1]','nvarchar(MAX)'),
	XMLproduct.value('(battery_percentage/text())[1]','nvarchar(MAX)'),
	XMLproduct.value('(home_duration/text())[1]','nvarchar(MAX)')
	FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)		
	WHERE NOT EXISTS(SELECT VisitId FROM [tbl_trans_shopuser] WITH(NOLOCK) WHERE SDate=XMLproduct.value('(date/text())[1]','datetime') and User_Id=@user_id)

	SELECT 1

	SET NOCOUNT OFF
END