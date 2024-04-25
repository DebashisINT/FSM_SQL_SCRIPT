IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMImportCRMEnquiries]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMImportCRMEnquiries] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FSMImportCRMEnquiries]
(
@Action NVARCHAR(500)=NULL,
@FromDate NVARCHAR(10)=NULL,
@ToDate NVARCHAR(10)=NULL,
@CreateUser_Id NVARCHAR(10)=NULL,
@IMPORT_TABLE UDT_ImportCRMEnquiries READONLY
) 
AS
/******************************************************************************************************************************
Written by Sanchita  on 21-11-2023 for V2.0.43		Bulk Import feature required for Enquiry Module. Mantis: 27020
1.0		Priti	    V2.0.46		25/04/2024	        0027383: New Enquires type Add and Hide # Eurobond Portal
******************************************************************************************************************************/
BEGIN

	DECLARE @Date datetime, @Customer_Name nvarchar(500), @Contact_Person nvarchar(500), @PhoneNo nvarchar(50),
            @Email nvarchar(500), @Location nvarchar(500), @vend_type nvarchar(500), @Product_Required nvarchar(500),
            @Quantity decimal(18,2), @UOM nvarchar(100), @Order_Value decimal(18,2), @Enq_Details nvarchar(max) 

	IF(@Action='BULKIMPORT')
	BEGIN

		DECLARE DB_CURSOR CURSOR FOR
		SELECT [Date], [Customer_Name], [Contact_Person], [PhoneNo], [Email], [Location],[vend_type],
			[Product_Required], [Quantity], [UOM], [Order_Value], [Enq_Details]
			FROM @IMPORT_TABLE where [PhoneNo] is not NULL
		OPEN DB_CURSOR
		FETCH NEXT FROM DB_CURSOR INTO @Date,@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@vend_type
										,@Product_Required,@Quantity,@UOM,@Order_Value,@Enq_Details
		WHILE @@FETCH_STATUS=0
		begin

			IF ISNULL(@Date,'')<>''
			BEGIN
				IF ISNULL(@Customer_Name,'')<>''
				BEGIN
					IF (ISNULL(@PhoneNo,'')<>'' AND ISNULL(@PhoneNo,'')<>'0' AND ISNUMERIC(@PhoneNo)=1 )
					BEGIN
						IF ISNULL(@vend_type,'')<>''
						BEGIN
							IF (ISNULL(@vend_type,'')='Website' or ISNULL(@vend_type,'')='Direct Call' or ISNULL(@vend_type,'')='Exhibition'
									or ISNULL(@vend_type,'')='Twak' or ISNULL(@vend_type,'')='MccoyMart' or ISNULL(@vend_type,'')='Other' 
									---Rev 1.0
									or ISNULL(@vend_type,'')='Exporters India'
									---Rev 1.0 End
									)
							BEGIN
								IF NOT EXISTS(SELECT Crm_Id FROM tbl_CRM_Import WHERE 
									[Date]=@Date AND [Customer_Name]=@Customer_Name AND [Contact_Person]=@Contact_Person AND [PhoneNo]=@PhoneNo
									AND [Email]=@Email AND [Location]=@Location AND [Product_Required]=@Product_Required AND [Qty]=@Quantity
									AND [UOM]=ISNULL(@UOM,'') AND [Order_Value]=@Order_Value --AND [Enq_Details]=@Enq_Details
									AND [vend_type]=@vend_type AND [MobileNo]=@PhoneNo)
								BEGIN
									insert into tbl_CRM_Import([Date],[Customer_Name],[Contact_Person],[PhoneNo],[Email],[Location],[Product_Required],[Qty],[UOM],
										[Order_Value],[Enq_Details],[vend_type],[Created_Date],	[Created_By],[Modified_By],[Modified_Date],[MobileNo])
									values( @Date, @Customer_Name, @Contact_Person,@PhoneNo,@Email,@Location,@Product_Required,@Quantity,ISNULL(@UOM,''),
										@Order_Value,@Enq_Details,@vend_type, getdate(),	@CreateUser_Id,null,null,@PhoneNo)

									INSERT INTO FSM_CRMEnquiriesImportLog
										([Date],[Customer_Name],[Contact_Person],[PhoneNo],[Email],[Location],[Product_Required],[Qty],[UOM],
										[Order_Value],[Enq_Details],[vend_type],[Created_Date],	[Created_By],[Modified_By],[Modified_Date],[MobileNo]
										,[ImportStatus],[ImportMsg],[ImportDate])
									values( @Date,
										@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@Product_Required,@Quantity,ISNULL(@UOM,''),
										@Order_Value,@Enq_Details,@vend_type, getdate(),	@CreateUser_Id,null,null,@PhoneNo
										,'Sucess','Sucess',GETDATE() )
								END
								ELSE
								BEGIN
									INSERT INTO FSM_CRMEnquiriesImportLog
										([Date],[Customer_Name],[Contact_Person],[PhoneNo],[Email],[Location],[Product_Required],[Qty],[UOM],
										[Order_Value],[Enq_Details],[vend_type],[Created_Date],	[Created_By],[Modified_By],[Modified_Date],[MobileNo]
										,[ImportStatus],[ImportMsg],[ImportDate])
									values( @Date,
										@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@Product_Required,@Quantity,ISNULL(@UOM,''),
										@Order_Value,@Enq_Details,@vend_type, getdate(),	@CreateUser_Id,null,null,@PhoneNo
										,'Faild','Record already exists',GETDATE() )
								END
							END
							ELSE
							BEGIN
								INSERT INTO FSM_CRMEnquiriesImportLog
									([Date],[Customer_Name],[Contact_Person],[PhoneNo],[Email],[Location],[Product_Required],[Qty],[UOM],
									[Order_Value],[Enq_Details],[vend_type],[Created_Date],	[Created_By],[Modified_By],[Modified_Date],[MobileNo]
									,[ImportStatus],[ImportMsg],[ImportDate])
								values( @Date,
									@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@Product_Required,@Quantity,ISNULL(@UOM,''),
									@Order_Value,@Enq_Details,@vend_type, getdate(),	@CreateUser_Id,null,null,@PhoneNo
									,'Faild','Provided By Invalid',GETDATE() )
							END

						END
						ELSE
						BEGIN
							INSERT INTO FSM_CRMEnquiriesImportLog
								([Date],[Customer_Name],[Contact_Person],[PhoneNo],[Email],[Location],[Product_Required],[Qty],[UOM],
								[Order_Value],[Enq_Details],[vend_type],[Created_Date],	[Created_By],[Modified_By],[Modified_Date],[MobileNo]
								,[ImportStatus],[ImportMsg],[ImportDate])
							values( @Date,
								@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@Product_Required,@Quantity,ISNULL(@UOM,''),
								@Order_Value,@Enq_Details,@vend_type, getdate(),	@CreateUser_Id,null,null,@PhoneNo
								,'Faild','Provided By Blank',GETDATE() )
						END
					END
					ELSE
					BEGIN
						INSERT INTO FSM_CRMEnquiriesImportLog
							([Date],[Customer_Name],[Contact_Person],[PhoneNo],[Email],[Location],[Product_Required],[Qty],[UOM],
							[Order_Value],[Enq_Details],[vend_type],[Created_Date],	[Created_By],[Modified_By],[Modified_Date],[MobileNo]
							,[ImportStatus],[ImportMsg],[ImportDate])
						values( @Date,
							@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@Product_Required,@Quantity,ISNULL(@UOM,''),
							@Order_Value,@Enq_Details,@vend_type, getdate(),	@CreateUser_Id,null,null,@PhoneNo
							,'Faild','Phone No Invalid',GETDATE() )
					END
				END
				ELSE
				BEGIN
					INSERT INTO FSM_CRMEnquiriesImportLog
						([Date],[Customer_Name],[Contact_Person],[PhoneNo],[Email],[Location],[Product_Required],[Qty],[UOM],
						[Order_Value],[Enq_Details],[vend_type],[Created_Date],	[Created_By],[Modified_By],[Modified_Date],[MobileNo]
						,[ImportStatus],[ImportMsg],[ImportDate])
					values( @Date,
						@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@Product_Required,@Quantity,ISNULL(@UOM,''),
						@Order_Value,@Enq_Details,@vend_type, getdate(),	@CreateUser_Id,null,null,@PhoneNo
						,'Faild','Customer Name Blank',GETDATE() )
				END
			END
			ELSE
			BEGIN
				INSERT INTO FSM_CRMEnquiriesImportLog
					([Date],[Customer_Name],[Contact_Person],[PhoneNo],[Email],[Location],[Product_Required],[Qty],[UOM],
					[Order_Value],[Enq_Details],[vend_type],[Created_Date],	[Created_By],[Modified_By],[Modified_Date],[MobileNo]
					,[ImportStatus],[ImportMsg],[ImportDate])
				values( @Date,
					@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@Product_Required,@Quantity,ISNULL(@UOM,''),
					@Order_Value,@Enq_Details,@vend_type, getdate(),	@CreateUser_Id,null,null,@PhoneNo
					,'Faild','Date Blank',GETDATE() )

			END

			
			FETCH NEXT FROM DB_CURSOR INTO @Date,@Customer_Name,@Contact_Person,@PhoneNo,@Email,@Location,@vend_type
										,@Product_Required,@Quantity,@UOM,@Order_Value,@Enq_Details

		END

		close db_cursor
		deallocate db_cursor

		SELECT logs.* FROM FSM_CRMEnquiriesImportLog AS logs
		INNER JOIN @IMPORT_TABLE temp ON 
		logs.[Date]=CONVERT(DATE,temp.[Date]) AND logs.[Customer_Name]=temp.Customer_Name AND logs.[Contact_Person]=temp.Contact_Person AND logs.[PhoneNo]=temp.PhoneNo
		AND logs.[Email]=temp.Email AND logs.[Location]=temp.[Location] AND logs.[Product_Required]=temp.Product_Required AND logs.[Qty]=temp.Quantity
		AND logs.[UOM]=ISNULL(temp.UOM,'') AND logs.[Order_Value]=temp.Order_Value --AND logs.[Enq_Details]=temp.Enq_Details
		AND logs.[vend_type]=temp.vend_type AND logs.[MobileNo]=temp.PhoneNo
		AND convert(date, logs.Created_Date)=convert(date,getdate())
	END
	ELSE IF (@Action='SHOWIMPORTLOG')
	BEGIN
		SELECT logs.[Date], logs.Customer_Name, logs.Contact_Person, logs.PhoneNo, logs.Email, logs.[Location] ,logs.vend_type , 
		logs.Product_Required,	logs.Qty, logs.UOM, logs.Order_Value, logs.Enq_Details, logs.ImportDate, logs.ImportMsg, logs.ImportStatus
		FROM FSM_CRMEnquiriesImportLog AS logs
		INNER JOIN @IMPORT_TABLE temp ON 
		logs.[Date]=CONVERT(DATE,temp.[Date]) AND logs.[Customer_Name]=temp.Customer_Name AND logs.[Contact_Person]=temp.Contact_Person AND logs.[PhoneNo]=temp.PhoneNo
		AND logs.[Email]=temp.Email AND logs.[Location]=temp.[Location] AND logs.[Product_Required]=temp.Product_Required AND logs.[Qty]=temp.Quantity
		AND logs.[UOM]=ISNULL(temp.UOM,'') AND logs.[Order_Value]=temp.Order_Value --AND logs.[Enq_Details]=temp.Enq_Details
		AND logs.[vend_type]=temp.vend_type AND logs.[MobileNo]=temp.PhoneNo

	END
	ELSE IF (@Action='GetBulkEnquiriesImportLog')
	BEGIN
		SELECT [Date], Customer_Name, Contact_Person, PhoneNo, Email, [Location] ,vend_type as vend_type, Product_Required,
		Qty,UOM,Order_Value,Enq_Details
			FROM FSM_CRMEnquiriesImportLog 
			WHERE convert(date, Created_Date) BETWEEN @FromDate AND @ToDate
			ORDER BY Created_Date DESC
	END
 END
 GO