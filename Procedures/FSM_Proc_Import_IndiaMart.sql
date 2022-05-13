IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FSM_Proc_Import_IndiaMart]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FSM_Proc_Import_IndiaMart] AS'  
 END 
 GO 

ALTER  Proc [dbo].[FSM_Proc_Import_IndiaMart]
(
@session_token varchar(MAX)=NULL,
@user_id varchar(50)=NULL,
@JsonXML XML=NULL,
@Action varchar(20)=NULL,
@Errortext varchar(max)=NULL,
@MobileNo varchar(400)=NULL,
@TotalCount int = 0,
@ReturnValue varchar(50)=null   output
) 
/**************************************************************************************************************************************************************
Written by Sanchita on 13-05-2022. Refer: 24890
***************************************************************************************************************************************************************/
As

BEGIN
	BEGIN TRY
	BEGIN TRANSACTION	
				
				INSERT  INTO  FSM_tbl_Import_IndiaMart   ([Indiamart_Id],[UNIQUE_QUERY_ID],[QUERY_TYPE],[QUERY_TIME],[SENDER_NAME],
					[SENDER_MOBILE],[SENDER_EMAIL],[SENDER_COMPANY],[SENDER_ADDRESS],[SENDER_CITY],[SENDER_STATE],[SENDER_COUNTRY_ISO],
					[SENDER_MOBILE_ALT],[SENDER_EMAIL_ALT],[QUERY_PRODUCT_NAME],[QUERY_MESSAGE],[CALL_DURATION],[RECEIVER_MOBILE],
					[TOTAL_COUNT],[Created_Date],[Creaded_By],[ApiMobile])
				select 
					XMLproduct.value('(Indiamart_Id/text())[1]','nvarchar(MAX)')	,
					XMLproduct.value('(UNIQUE_QUERY_ID/text())[1]','nvarchar(MAX)')		,
					XMLproduct.value('(QUERY_TYPE/text())[1]','nvarchar(MAX)')		,
					XMLproduct.value('(QUERY_TIME/text())[1]','nvarchar(MAX)')	,
					XMLproduct.value('(SENDER_NAME/text())[1]','nvarchar(MAX)')	,
					XMLproduct.value('(SENDER_MOBILE/text())[1]','nvarchar(MAX)')	,
					XMLproduct.value('(SENDER_EMAIL/text())[1]','nvarchar(MAX)')	,
					XMLproduct.value('(SENDER_COMPANY/text())[1]','nvarchar(MAX)')	    ,
					XMLproduct.value('(SENDER_ADDRESS/text())[1]','nvarchar(120)')	    ,
					XMLproduct.value('(SENDER_CITY/text())[1]','nvarchar(MAX)')  ,
					XMLproduct.value('(SENDER_STATE/text())[1]','nvarchar(MAX)')  ,
					XMLproduct.value('(SENDER_COUNTRY_ISO/text())[1]','nvarchar(MAX)')  ,
					XMLproduct.value('(SENDER_MOBILE_ALT/text())[1]','nvarchar(MAX)')  ,
					XMLproduct.value('(SENDER_EMAIL_ALT/text())[1]','nvarchar(MAX)')  ,
					XMLproduct.value('(QUERY_PRODUCT_NAME/text())[1]','nvarchar(MAX)')  ,
					XMLproduct.value('(QUERY_MESSAGE/text())[1]','nvarchar(MAX)')  ,
					XMLproduct.value('(CALL_DURATION/text())[1]','nvarchar(MAX)')  ,
					XMLproduct.value('(RECEIVER_MOBILE/text())[1]','nvarchar(MAX)'),
					@TotalCount ,GETDATE(),@user_id,@MobileNo
				
				FROM  @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  
				WHERE NOT EXISTS(select Indiamart_Id from  FSM_tbl_Import_IndiaMart where  CAST(QUERY_TIME as datetime)=CAST(XMLproduct.value('(QUERY_TIME/text())[1]','nvarchar(MAX)')  as datetime) and ApiMobile=@MobileNo	)

			
				Insert into tbl_CRM_Import (Date,Customer_Name,Contact_Person,PhoneNo,Alt_PhoneNo,MobileNo,Alt_MobileNo,Email,Email_Alt,Location,City,Pincode,
				Area,State,Product_Required,Qty,Order_Value,Enq_Details,Created_Date,Taged_vendor,vend_type,ApiMobile)
				SELECT 
				--CONVERT(VARCHAR(24), CONVERT(DATETIME, LTRIM(XMLproduct.value('(QUERY_TIME/text())[1]','varchar(max)')) , 103), 121),
				XMLproduct.value('(QUERY_TIME/text())[1]','nvarchar(MAX)'),
				XMLproduct.value('(SENDER_COMPANY/text())[1]','nvarchar(MAX)')  ,
				XMLproduct.value('(SENDER_NAME/text())[1]','nvarchar(MAX)')	,
				--case  when isnull( XMLproduct.value('(SENDER_MOBILE/text())[1]','nvarchar(MAX)'),'')='' then  XMLproduct.value('(SENDER_MOBILE_ALT/text())[1]','nvarchar(MAX)')  else XMLproduct.value('(SENDER_MOBILE/text())[1]','nvarchar(MAX)')  end,
				XMLproduct.value('(SENDER_MOBILE/text())[1]','nvarchar(MAX)')  ,
				XMLproduct.value('(SENDER_MOBILE_ALT/text())[1]','nvarchar(MAX)')  ,
				XMLproduct.value('(SENDER_MOBILE/text())[1]','nvarchar(MAX)')  ,
				XMLproduct.value('(SENDER_MOBILE_ALT/text())[1]','nvarchar(MAX)')  ,
				XMLproduct.value('(SENDER_EMAIL/text())[1]','nvarchar(MAX)')	,
				XMLproduct.value('(SENDER_EMAIL_ALT/text())[1]','nvarchar(MAX)')	,

				XMLproduct.value('(SENDER_STATE/text())[1]','nvarchar(MAX)') +','+XMLproduct.value('(SENDER_CITY/text())[1]','nvarchar(MAX)'),
				XMLproduct.value('(SENDER_CITY/text())[1]','nvarchar(MAX)'),
				''
				,''
				,stat.id
				,XMLproduct.value('(QUERY_PRODUCT_NAME/text())[1]','nvarchar(MAX)')  
				,NULL
				,NULL
				,XMLproduct.value('(QUERY_MESSAGE/text())[1]','nvarchar(MAX)')  ,
				GETDATE()
				,XMLproduct.value('(Indiamart_Id/text())[1]','nvarchar(MAX)')
				,'Indiamart'
				,@MobileNo
				FROM  @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)  
				Left outer Join tbl_master_state as stat on Rtrim(LTrim(Lower(XMLproduct.value('(SENDER_STATE/text())[1]','nvarchar(MAX)'))))  =Rtrim(LTrim(Lower(stat.state)))
				WHERE NOT EXISTS(select Crm_Id from  tbl_CRM_Import where  CAST(Date as datetime)=CAST(XMLproduct.value('(QUERY_TIME/text())[1]','nvarchar(MAX)')  as datetime)	and vend_type='Indiamart' and ApiMobile=@MobileNo)
				
				INSERT INTO ERROR_FORCRMVENDORDATA(Created_date,MobileNo,ErrorMessage)
				VALUES(GETDATE(),@MobileNo,@Errortext)
		  
			Set @ReturnValue=1
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH

	ROLLBACK TRANSACTION
		Declare @ErrorMSG varchar(max)	
		
		set @ErrorMSG=ERROR_MESSAGE() 
		Set @ReturnValue=ERROR_MESSAGE() 
		INSERT INTO ERROR_FORCRMVENDORDATA(Created_date,MobileNo,ErrorMessage)
		VALUES(GETDATE(),@MobileNo,@ErrorMSG)
				
	END CATCH
END

GO
