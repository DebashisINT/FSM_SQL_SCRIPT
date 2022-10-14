IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTS_SALESACTIVITY]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTS_SALESACTIVITY] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_FTS_SALESACTIVITY]
(
@ACTION_TYPE NVARCHAR(MAX)= NULL,
@ActivityCode NVARCHAR(100)=NULL,
@party_id NVARCHAR(100)=NULL,
@date NVARCHAR(15)=NULL,
@time NVARCHAR(15)=NULL,
@name NVARCHAR(300)=NULL,
@activity_id BIGINT=NULL,
@type_id BIGINT=NULL,
@subject NVARCHAR(MAX)=NULL,
@details NVARCHAR(MAX)=NULL,
@user_id BIGINT=NULL,
@duration NVARCHAR(15)=NULL,
@priority_id BIGINT=NULL,
@due_date NVARCHAR(15)=NULL,
@due_time NVARCHAR(15)=NULL,
@product_id BIGINT=NULL,
@JsonXML XML=NULL
) --WITH ENCRYPTION 
AS
/****************************************************************************************************************************************************************************
1.0			2.0.18		Tanmoy		08-09-2020		create sp
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	--IF(@ACTION_TYPE='SAVE')
	--BEGIN
		BEGIN TRY
		BEGIN TRANSACTION	
			Declare @Sales_ActivityID int
			IF NOT EXISTS (SELECT 1 FROM FTS_SalesActivity WITH(NOLOCK) WHERE ActivityCode=@ActivityCode)
				BEGIN
					insert into FTS_SalesActivity WITH(TABLOCK) (ActivityCode,Party_Code,Activity_Date,Activity_Time,Activity_DateTime,ContactName,Activityid,Typeid,ActivitySubject,ActivityDetails,Assignto,
					Duration,Priorityid,Duedate,Created_date,Created_by)
					values(@ActivityCode,@party_id,@date,@time,@date+' '+Convert(nvarchar(10),convert(time,@time,108)),@name,@activity_id,@type_id,
					@subject,@details,@user_id,@duration,@priority_id,@due_date+' '+Convert(nvarchar(10),convert(time,@due_time,108)),GETDATE(),@user_id)
						
					------For Activity Product
					SELECT @Sales_ActivityID=SCOPE_IDENTITY()

					INSERT INTO FTS_ActivityProducts_LOG
					SELECT * FROM FTS_ActivityProducts WITH(NOLOCK) WHERE ActivityId=@Sales_ActivityID

					delete from FTS_ActivityProducts where ActivityId=@Sales_ActivityID
											
					insert into FTS_ActivityProducts WITH(TABLOCK) (ActivityId,Party_Code,ProdId,Act_Prod_Qty,Act_Prod_Rate,Act_Prod_Remarks)
					select @Sales_ActivityID,@party_id,@product_id,0,0,''

					INSERT FTS_ActivityImagesMapping
					select @Sales_ActivityID,@party_id,
					XMLproduct.value('(attachment/text())[1]','nvarchar(MAX)'),
					XMLproduct.value('(attachmenttype/text())[1]','nvarchar(100)')
					FROM  @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)

					----update SMS and Email
					--update ACTIVITY_SMS set SalesActivityId=@Lead_Sales_ActivityID where SMSid=@SMSID
					--update ACTIVITY_EMAIL set LeadSalesActivityId=@Lead_Sales_ActivityID where Emailid=@EMAILID

					SELECT 'Success' AS STATUS,'Successfully add activity' AS RETURNMESSAGE,1 AS RETURNCODE
				END
			ELSE
				BEGIN
					SET @Sales_ActivityID=(SELECT Id FROM FTS_SalesActivity WITH(NOLOCK) WHERE ActivityCode=@ActivityCode)

					UPDATE FTS_SalesActivity WITH(TABLOCK) SET Party_Code=@party_id,Activity_Date=@date,Activity_Time=@time,
					Activity_DateTime=@date+' '+Convert(nvarchar(10),convert(time,@time,108)),ContactName=@name,Activityid=@activity_id,
					Typeid=@type_id,ActivitySubject=@subject,ActivityDetails=@details,Assignto=@user_id,Duration=@duration,Priorityid=@priority_id,
					Duedate=@due_date+' '+Convert(nvarchar(10),convert(time,@due_time,108)),Modified_date=GETDATE(),Modified_by=@user_id
					WHERE ActivityCode=@ActivityCode
				
					INSERT INTO FTS_ActivityProducts_LOG
					SELECT * FROM FTS_ActivityProducts WHERE ActivityId=@Sales_ActivityID

					delete from FTS_ActivityProducts where ActivityId=@Sales_ActivityID
											
					insert into FTS_ActivityProducts(ActivityId,Party_Code,ProdId,Act_Prod_Qty,Act_Prod_Rate,Act_Prod_Remarks)
					select @Sales_ActivityID,@party_id,@product_id,0,0,''

					DELETE FROM FTS_ActivityImagesMapping WHERE ActivityId=@Sales_ActivityID

					INSERT FTS_ActivityImagesMapping
					select @Sales_ActivityID,@party_id,
					XMLproduct.value('(attachment/text())[1]','nvarchar(MAX)'),
					XMLproduct.value('(attachmenttype/text())[1]','nvarchar(100)')
					FROM  @JsonXML.nodes('/root/data')AS TEMPTABLE(XMLproduct)

					SELECT 'Success' AS STATUS,'Successfully edit activity' AS RETURNMESSAGE,1 AS RETURNCODE
				END
			COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION
			
			--Set @RETURNMESSAGE= ERROR_MESSAGE();
			--Set @RETURNCODE='-10'
			SELECT  'Failed' AS STATUS,ERROR_MESSAGE() AS RETURNMESSAGE,'-10' AS RETURNCODE
	
		END CATCH
	--END
	SET NOCOUNT OFF
END