IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIUSERSHOPACTIVITYSUBMITINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIUSERSHOPACTIVITYSUBMITINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIUSERSHOPACTIVITYSUBMITINFO]
(
@ACTION NVARCHAR(20),
@USER_ID BIGINT=NULL,
@FROMDATE NVARCHAR(20)=NULL,
@TODATE NVARCHAR(20)=NULL,
@DATESPAN INT=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 31/03/2022
Purpose : For APP Log Files Detection API.Row: 675
1.0		v2.0.37		Debashis	10/01/2023		Some new fields have been added.Row: 788
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @SqlStr NVARCHAR(MAX)

	IF @DATESPAN<>0
		BEGIN
			SET @FROMDATE=CONVERT(NVARCHAR(10),(GetDate() - @DATESPAN)+1,120)
			SET @TODATE=CONVERT(NVARCHAR(10),GetDate(),120)
		END

	IF @ACTION='FEEDBACKLIST'
		BEGIN
			SET @SqlStr='SELECT User_Id,Shop_Id FROM('
			SET @SqlStr+='SELECT User_Id,Shop_Id FROM tbl_trans_shopActivitysubmit WITH(NOLOCK) '
			SET @SqlStr+='WHERE User_Id='+LTRIM(RTRIM(STR(@USER_ID)))+' '
			IF @FROMDATE<>'' AND @TODATE<>''
				SET @SqlStr+='AND CONVERT(NVARCHAR(10),visited_time,120) BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+''' '
			SET @SqlStr+='UNION ALL '
			SET @SqlStr+='SELECT User_Id,Shop_Id FROM tbl_trans_shopActivitysubmit_ARCHIVE WITH(NOLOCK) '
			SET @SqlStr+='WHERE User_Id='+LTRIM(RTRIM(STR(@USER_ID)))+' '
			IF @FROMDATE<>'' AND @TODATE<>''
				SET @SqlStr+='AND CONVERT(NVARCHAR(10),visited_time,120) BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+''' '
			SET @SqlStr+=') SHOP '
			SET @SqlStr+='GROUP BY User_Id,Shop_Id ORDER BY Shop_Id '
			--SELECT @SqlStr
			EXEC(@SqlStr)

			--Rev 1.0
			--SET @SqlStr='SELECT User_Id,Shop_Id,feedback,date_time FROM('
			SET @SqlStr='SELECT User_Id,Shop_Id,feedback,date_time,multi_contact_name,multi_contact_number FROM('
			--End of Rev 1.0
			SET @SqlStr+='SELECT User_Id,Shop_Id,REMARKS AS feedback,CONVERT(NVARCHAR(10),visited_time,120)+'' ''+CONVERT(NVARCHAR(10),visited_time,108) AS date_time,'
			--Rev 1.0
			SET @SqlStr+='Multi_Contact_Name AS multi_contact_name,Multi_Contact_Number AS multi_contact_number '
			--End of Rev 1.0
			SET @SqlStr+='FROM tbl_trans_shopActivitysubmit WITH(NOLOCK) '
			SET @SqlStr+='WHERE User_Id='+LTRIM(RTRIM(STR(@USER_ID)))+' '
			IF @FROMDATE<>'' AND @TODATE<>''
				SET @SqlStr+='AND CONVERT(NVARCHAR(10),visited_time,120) BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+''' '
			SET @SqlStr+='UNION ALL '
			SET @SqlStr+='SELECT User_Id,Shop_Id,REMARKS AS feedback,CONVERT(NVARCHAR(10),visited_time,120)+'' ''+CONVERT(NVARCHAR(10),visited_time,108) AS date_time,'
			--Rev 1.0
			SET @SqlStr+='Multi_Contact_Name AS multi_contact_name,Multi_Contact_Number AS multi_contact_number '
			--End of Rev 1.0
			SET @SqlStr+='FROM tbl_trans_shopActivitysubmit_ARCHIVE WITH(NOLOCK) '
			SET @SqlStr+='WHERE User_Id='+LTRIM(RTRIM(STR(@USER_ID)))+' '
			IF @FROMDATE<>'' AND @TODATE<>''
				SET @SqlStr+='AND CONVERT(NVARCHAR(10),visited_time,120) BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+''' '
			SET @SqlStr+=') SHOPDET '
			SET @SqlStr+='ORDER BY Shop_Id '
			--SELECT @SqlStr
			EXEC(@SqlStr)
		END

	SET NOCOUNT OFF
END