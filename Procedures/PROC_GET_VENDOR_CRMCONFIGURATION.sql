IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_GET_VENDOR_CRMCONFIGURATION]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_GET_VENDOR_CRMCONFIGURATION] AS'  
 END 
 GO 

ALTER PROC  [PROC_GET_VENDOR_CRMCONFIGURATION]
(
@EnquiryFrom varchar(100)= NULL,
@VENDORID VARCHAR(100) = NULL,
@FromDate DATE = NULL,
@ToDate DATE = NULL
) 
AS
/**************************************************************************************************************************************************************
Written by Sanchita. refer: 24631
1.0		Sanchita	V2.0.30		12-05-2022	 FSM CRM Enquiry API upgradation for IndiaMart. Refer: 24890
***************************************************************************************************************************************************************/
BEGIN

	-- Rev 1.0
	--UPDATE TBL_CONFIG_VENDORLIST SET APIURL='https://mapi.indiamart.com/wservce/enquiry/listing/GLUSR_MOBILE/'+APIMOBILE+'/GLUSR_MOBILE_KEY/'+APIKEY+'/'+'START_TIME/'+LEFT(REPLACE(CONVERT(CHAR(15),@FromDate,106),' ','-'),11)+'/END_TIME/'+LEFT(REPLACE(CONVERT(CHAR(15),@ToDate,106),' ','-'),11)+'/' WHERE VENDORID=1
	UPDATE TBL_CONFIG_VENDORLIST SET APIURL='https://mapi.indiamart.com/wservce/crm/crmListing/v2/?glusr_crm_key='+APIKEY+'&start_time='+LEFT(REPLACE(CONVERT(CHAR(15),@FromDate,106),' ','-'),11)+'&end_time='+LEFT(REPLACE(CONVERT(CHAR(15),@ToDate,106),' ','-'),11) WHERE VENDORID=1
	-- End of Rev 1.0

	SELECT  APIURL,APIMOBILE  FROM TBL_CONFIG_VENDORLIST WHERE VENDORID IN (SELECT ITEMS FROM DBO.SPLITSTRING(@VENDORID,','))

	-------NEW CHANGES----------

END


GO
