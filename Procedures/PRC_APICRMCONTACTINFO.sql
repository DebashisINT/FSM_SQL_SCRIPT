IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APICRMCONTACTINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APICRMCONTACTINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APICRMCONTACTINFO]
(
@ACTION NVARCHAR(20),
@USERID INT=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 05/12/2023
Purpose : For CRM Contact API.Row: 880 to 884 & 898
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='CRMCOMPANYLIST'
		BEGIN
			SELECT COMPANY_ID AS company_id,COMPANY_NAME AS company_name FROM CRM_CONTACT_COMPANY
		END
	ELSE IF @ACTION='CRMTYPELIST'
		BEGIN
			SELECT [TYPE_ID] AS [type_id],[TYPE_NAME] AS [type_name] FROM CRM_CONTACT_TYPE
		END
	ELSE IF @ACTION='CRMSTATUSLIST'
		BEGIN
			SELECT STATUS_ID AS status_id,STATUS_NAME AS status_name FROM CRM_CONTACT_STATUS
		END
	ELSE IF @ACTION='CRMSOURCELIST'
		BEGIN
			SELECT SOURCE_ID AS source_id,SOURCE_NAME AS source_name FROM CRM_CONTACT_SOURCE
		END
	ELSE IF @ACTION='CRMSTAGELIST'
		BEGIN
			SELECT STAGE_ID AS stage_id,STAGE_NAME AS stage_name FROM CRM_CONTACT_STAGE
		END
	ELSE IF @ACTION='CRMCOMPANYSAVE'
		BEGIN
			INSERT INTO CRM_CONTACT_COMPANY(COMPANY_NAME,IsActive,CREATED_BY,CREATED_DATE)
			SELECT XMLproduct.value('(company_name/text())[1]','VARCHAR(200)'),1,@USERID,GETDATE()
			FROM @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)

			SELECT COMPANY_ID,COMPANY_NAME FROM CRM_CONTACT_COMPANY WHERE CREATED_BY=@USERID AND IsActive=1
		END

	SET NOCOUNT OFF
END
GO