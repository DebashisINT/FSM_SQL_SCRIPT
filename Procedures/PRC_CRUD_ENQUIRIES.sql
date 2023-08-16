IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_CRUD_ENQUIRIES]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_CRUD_ENQUIRIES] AS'  
 END 
 GO 

ALTER PROCEDURE [dbo].[PRC_CRUD_ENQUIRIES]
(
	@USERID INT =NULL,
	@ACTION_TYPE VARCHAR(20)= NULL,
	@DATE datetime =NULL,
	@CUSTNAME NVARCHAR(300) =NULL,
	@CONTACTPERSON NVARCHAR(200) =NULL,
	@PHONENO NVARCHAR(20) =NULL,
	@EMAIL NVARCHAR(100) =NULL,
	@LOCATION NVARCHAR(300) =NULL,
	@PRODUCTREQUIRED NVARCHAR(300) =NULL,
	@QTY DECIMAL(18,2) =NULL,
	@ORDER_VALUE DECIMAL(18,2) =NULL,
	@VEND_TYPE NVARCHAR(100) =NULL,
	@ENQ_DETAILS NVARCHAR(1000) =NULL,
	@CRM_ID uniqueidentifier =NULL,
	@CRM_IDS NVARCHAR(MAX) =NULL,
	@SALESMANID nvarchar(10)=NULL,
	@UOM nvarchar(100)='',
	@RETURNMESSAGE NVARCHAR(500) =NULL OUTPUT ,
	@RETURNCODE NVARCHAR(20) =NULL OUTPUT

)
 
AS
/****************************************************************************************************************************************************************************
Written by : Sanchita on 07-02-2022. Refer: 24631
1.0		Pratik		v2.0.28		30/03/2022		Added Action='OldAssignedSalesMan'. Refer: 24776
2.0		Pratik		v2.0.28		12/04/2022		Added Action='ReBULKASSIGN'. Refer: 24810
3.0		Sanchita	V2.0.30		19-05-2022		MobileNo to be updated along with PhoneNo . Refer: 
4.0		Sanchita	V2.0.42		16-08-2023		The enquiry doesn't showing in the listing after modification. Mantis: 26721
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	IF(@ACTION_TYPE='ADD')
			BEGIN TRY
			BEGIN TRANSACTION	
				-- Rev 3.0 [ MobileNo updated with @PHONENO ]	
				insert into tbl_CRM_Import(Date,Customer_Name,Contact_Person,PhoneNo,Email,Location,Product_Required,Qty,UOM,Order_Value,Enq_Details,vend_type,Created_Date,
				Created_By,Modified_By,Modified_Date,MobileNo)
				values( CONVERT(DATETIME,CONVERT(VARCHAR(15),CAST(@DATE as date),120)+' '+CONVERT(VARCHAR(15),CAST(GETDATE() AS TIME),108)) ,
				@CUSTNAME,@CONTACTPERSON,@PHONENO,@EMAIL,@LOCATION,@PRODUCTREQUIRED,@QTY,ISNULL(@UOM,''),@ORDER_VALUE,@ENQ_DETAILS,@VEND_TYPE,getdate(),
				@USERID,null,null,@PHONENO)
				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Success';
				Set @RETURNCODE='1'

			END TRY

			BEGIN CATCH

			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
			--END	
	ELSE IF(@ACTION_TYPE='EDIT') 
			-- Rev 4.0
			--select Date,Customer_Name,Contact_Person,PhoneNo,Email,Location,Product_Required,isnull(Qty,0)as Qty,UOM,isnull(Order_Value,0) as Order_Value,Enq_Details,vend_type,Created_Date,PhoneNo,
			--	Created_By,Modified_By,Modified_Date,isnull(Supervisor,0) as Supervisor,isnull(salesman,0) as salesman,isnull(verify,0) as verify 
			--	from tbl_CRM_Import where Crm_Id=@CRM_ID
			select Date,Customer_Name,Contact_Person,PhoneNo,Email,Location,Product_Required,isnull(Qty,0)as Qty,UOM,isnull(Order_Value,0) as Order_Value,Enq_Details,vend_type,Created_Date,PhoneNo,
				Created_By,Modified_By,Modified_Date,isnull(Supervisor,0) as Supervisor,isnull(salesman,0) as salesman,isnull(verify,0) as verify 
				, convert(varchar(10),Date,105) as txtDate
				from tbl_CRM_Import where Crm_Id=@CRM_ID
			-- End of Rev 4.0
	ELSE IF(@ACTION_TYPE='MOD') 
			BEGIN TRY
			BEGIN TRANSACTION		
				-- Rev 3.0 [ MobileNo updated with @PHONENO ]
				-- Rev 4.0
				--update tbl_CRM_Import set Date=CONVERT(DATETIME,CONVERT(VARCHAR(15),CAST(@DATE as date),120)+' '+CONVERT(VARCHAR(15),CAST(GETDATE() AS TIME),108)),
				
				--Customer_Name=@CUSTNAME,Contact_Person=@CONTACTPERSON,PhoneNo=@PHONENO,Email=@EMAIL,Location=@LOCATION,Product_Required=@PRODUCTREQUIRED
				--,Qty=@QTY,UOM=ISNULL(@UOM,''),Order_Value=@ORDER_VALUE,Vend_Type=@VEND_TYPE,Enq_Details=@ENQ_DETAILS,Modified_By=@USERID,
				--Modified_Date=getdate(), MobileNo=@PHONENO
				--where Crm_Id=@CRM_ID

				update tbl_CRM_Import set --Date=CONVERT(DATETIME,CONVERT(VARCHAR(15),CAST(@DATE as date),120)+' '+CONVERT(VARCHAR(15),CAST(GETDATE() AS TIME),108)),
				
				Customer_Name=@CUSTNAME,Contact_Person=@CONTACTPERSON,PhoneNo=@PHONENO,Email=@EMAIL,Location=@LOCATION,Product_Required=@PRODUCTREQUIRED
				,Qty=ISNULL(@QTY,0),UOM=ISNULL(@UOM,''),Order_Value=ISNULL(@ORDER_VALUE,0),
				--Vend_Type=@VEND_TYPE,
				Enq_Details=@ENQ_DETAILS,Modified_By=@USERID,
				Modified_Date=getdate(), MobileNo=@PHONENO
				where Crm_Id=@CRM_ID
				-- End of Rev 4.0

				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Success';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	ELSE IF(@ACTION_TYPE='DELETE') 
			BEGIN TRY
			BEGIN TRANSACTION		
				update tbl_CRM_Import set Is_deleted=1 where Crm_Id=@CRM_ID
				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Deleted';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	
	ELSE IF(@ACTION_TYPE='RESTORE') 
			BEGIN TRY
			BEGIN TRANSACTION		
				update tbl_CRM_Import set Is_deleted=0 where Crm_Id=@CRM_ID
				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Restored';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	ELSE IF(@ACTION_TYPE='PERMANENTDELETE') 
			BEGIN TRY
			BEGIN TRANSACTION		
				DELETE FROM tbl_CRM_Import where Crm_Id=@CRM_ID  and  Is_deleted=1
				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'PDeleted';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	ELSE IF(@ACTION_TYPE='MASSDELETE') 
			BEGIN TRY
			BEGIN TRANSACTION	
					
			
				select * into #tempmassdel FROM DBO.GETSPLIT('|',@CRM_IDS)
				--select s from #tempmassdel
				update tbl_CRM_Import set Is_deleted=1 where Crm_Id in(select s from #tempmassdel where s<>'')

				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Deleted';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	ELSE IF(@ACTION_TYPE='BULKASSIGN' and @SALESMANID is not null and @SALESMANID<>'0') 
			BEGIN TRY
			BEGIN TRANSACTION	
					
				select * into #tempBulkAssign FROM DBO.GETSPLIT('|',@CRM_IDS)
				
				update tbl_CRM_Import set SalesmanId=@SALESMANID, SalesmanAssign_dt=getdate() where Crm_Id in(select s from #tempBulkAssign where s<>'')

				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Success';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
	ELSE IF(@ACTION_TYPE='CHECKASSIGNSALESMAN') 
		begin
			DECLARE @CNT INT = (SELECT COUNT(0) FROM tbl_CRM_Import WHERE Crm_Id=@CRM_ID and SalesmanId is not NULL and SalesmanId<>0)
			IF @CNT>0
			BEGIN
				Set @RETURNMESSAGE= 'Exist';
				Set @RETURNCODE='-1'
			END
			ELSE
			BEGIN
				Set @RETURNMESSAGE= 'NotExist';
				Set @RETURNCODE='1'
			END
		end
		--rev 1.0
		ELSE IF(@ACTION_TYPE='OldAssignedSalesMan') 
		begin
			SELECT user_name,user_id FROM tbl_CRM_Import as TCM(nolock)
			inner join tbl_master_user as TMU(nolock) on TCM.SalesmanId=TMU.user_id
			WHERE Crm_Id=@CRM_ID
		end
		
		--End of rev 1.0
		--rev 2.0
		ELSE IF(@ACTION_TYPE='ReBULKASSIGN' and @SALESMANID is not null and @SALESMANID<>'0') 
			BEGIN TRY
			BEGIN TRANSACTION	
					
				select * into #tempBulkReAssign FROM DBO.GETSPLIT('|',@CRM_IDS)
				
				update tbl_CRM_Import set ReAssignedSalesman=@SALESMANID, ReSalesmanAssignDT=getdate() where Crm_Id in(select s from #tempBulkReAssign where s<>'')

				COMMIT TRANSACTION

				Set @RETURNMESSAGE= 'Success';
				Set @RETURNCODE='1'

			END TRY
			BEGIN CATCH
			ROLLBACK TRANSACTION
			
				Set @RETURNMESSAGE= ERROR_MESSAGE();
				Set @RETURNCODE='-10'
	
			END CATCH
		--End of rev 2.0

	if(@ACTION_TYPE='GetEnquiryFrom')
	begin
		SELECT EnqID, EnquiryFromDesc from tbl_master_EnquiryFrom order by EnqID
	end

	if(@ACTION_TYPE='GetSalesmanlist')
	begin
		SELECT '0' AS UserID,'Select' AS username
		UNION ALL
		select convert(nvarchar(10),U.user_id) as UserID ,user_name+ ' ('+ E.emp_uniqueCode +')' as username 
		from tbl_master_user U inner join tbl_master_employee E ON U.user_contactid = E.emp_contactid
		WHERE user_inactive='N' order by UserID
	end
END
go