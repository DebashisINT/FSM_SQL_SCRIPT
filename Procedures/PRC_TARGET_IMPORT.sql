IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_TARGET_IMPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_TARGET_IMPORT] AS' 
END
GO
ALTER PROC PRC_TARGET_IMPORT
(
@ACTION VARCHAR(500)=NULL,
@USER_ID BIGINT=NULL,
@IMPORT_TABLE FSM_UDT_IMPORTSALESTARGET READONLY,
-- End of Rev 8.0
@RETURN_VALUE BIGINT=0 OUTPUT,
@FromDate NVARCHAR(10)=NULL,
@ToDate NVARCHAR(10)=NULL,
@IMPORT_PRODUCTTABLE FSM_UDT_IMPORTPRODUCTTARGET READONLY,
@IMPORT_BRANDTABLE FSM_UDT_IMPORTBRANDTARGET READONLY,
@IMPORT_WODTABLE FSM_UDT_IMPORTWODTARGET READONLY
)
AS
/*************************************************************************************************************************
Written by : Priti Roy on 22/11/2024
0027770:A new module is required as  Target Assign
******************************************************************************************************************************/
BEGIN
	DECLARE @SALESTARGETID BIGINT = 0;
	Declare @LastCount bigint=0,@LastCountDetails bigint=0,@LastCountIMPORTLOG bigint=0
	DECLARE @Success BIT = 0;
	DECLARE @TARGETLEVELID bigint=0,@TARGETLEVEL nvarchar(200)='',@TARGETLEVELNAME nvarchar(200)='',@TARGETLEVELCODE nvarchar(200)='' ,@TIMEFRAME nvarchar(200)='' ,@STARTEDATE datetime= NULL,@ENDDATE datetime= NULL
	,@ORDERAMOUNT Numeric(18,4)=0,@COLLECTION Numeric(18,4)=0, @ORDERQTY Numeric(18,4)=0,@INTERNALID nvarchar(200)=''
	,@NEWVISIT bigint=0,@REVISIT bigint=0,@TargetDate DATETIME = NULL,@TargetNo NVARCHAR(100) = '',@EmployeeGroup NVARCHAR(100) = '',@TargetFor NVARCHAR(100) = '',@WODCOUNT bigint=0
	,@BRANDNAME nvarchar(200)='',@BRANDID bigint=0,@PRODUCTCODE nvarchar(200)='',@PRODUCTNAME nvarchar(200)=''
	Declare @HeaderTARGETLEVELID  bigint=0,@PRODUCTID bigint=0
	DECLARE @FAIL VARCHAR(10) = 'FALSE'

	IF @ACTION = 'INSERTSALESTARGET'
	BEGIN
			

			DECLARE db_cursorHEADER CURSOR FOR  
			Select 	DISTINCT DocumentNo,DocumentDate,EmployeeGroup,TargetFor
			From @IMPORT_TABLE 		where DocumentNo<>''

			OPEN db_cursorHEADER   
			FETCH NEXT FROM db_cursorHEADER INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor

			WHILE @@FETCH_STATUS = 0   
			BEGIN 

				if(isnull(@TargetNo,'')='')
				Begin
						
						select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
						INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
						DocumentNo,DocumentDate,
						EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
						)
						Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
							,@EmployeeGroup,@TargetFor
						,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
						,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Document Number is empty.',@USER_ID,GETDATE()

						SET @FAIL = 'TRUE'
					
				End
				if(isnull(@TargetDate,'')='')
				Begin
						
						select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
						INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
						DocumentNo,DocumentDate,
						EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
						)
						Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
							,@EmployeeGroup,@TargetFor
						,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
						,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Document Date is empty.',@USER_ID,GETDATE()

						SET @FAIL = 'TRUE'
					
				End



				IF(@FAIL='FALSE')
				BEGIN
					if EXISTS (select 'Y' from FSM_SALESTARGETASSIGN   where TARGETDOCNUMBER=TRIM(@TargetNo))
					Begin
						

							select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
							INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
							DocumentNo,DocumentDate,
							EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
							)
							Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
								,@EmployeeGroup,@TargetFor
							,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
							,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Duplicate Document Number.',@USER_ID,GETDATE()
							


					end
					ELSE
					BEGIN
								DECLARE db_cursor CURSOR FOR  
								Select 	DocumentNo,DocumentDate,EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME ,STARTEDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY
								From @IMPORT_TABLE 		WHERE DocumentNo=@TargetNo

								OPEN db_cursor   
								FETCH NEXT FROM db_cursor INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY

								WHILE @@FETCH_STATUS = 0   
								BEGIN 	

										if(isnull(@EmployeeGroup,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Target Type is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TargetFor,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Target Level is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TARGETLEVELNAME,'')='' OR isnull(@TARGETLEVELCODE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Assignee Name is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TIMEFRAME,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Time Frame is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@STARTEDATE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Start Date is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@ENDDATE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','End Date is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@NEWVISIT,0)=0 and isnull(@REVISIT,0)=0 and isnull(@ORDERAMOUNT,0)=0 and isnull(@COLLECTION,0)=0 and isnull(@ORDERQTY,0)=0)
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  

												

												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','New Visit,ReVisit,Order Amount,Collection Amount,Order Quantity is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
										--if(isnull(@REVISIT,0)=0)
										--Begin
										--		select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
										--		INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
										--		DocumentNo,DocumentDate,
										--		EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
										--		)
										--		Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
										--			,@EmployeeGroup,@TargetFor
										--		,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
										--		,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','ReVisit is empty.',@USER_ID,GETDATE()

										--		SET @FAIL = 'TRUE'
										--End
										--if(isnull(@ORDERAMOUNT,0)=0)
										--Begin
										--		select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
										--		INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
										--		DocumentNo,DocumentDate,
										--		EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
										--		)
										--		Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
										--			,@EmployeeGroup,@TargetFor
										--		,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
										--		,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Order Amount is empty.',@USER_ID,GETDATE()

										--		SET @FAIL = 'TRUE'
										--End
										--if(isnull(@COLLECTION,0)=0)
										--Begin
										--		select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
										--		INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
										--		DocumentNo,DocumentDate,
										--		EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
										--		)
										--		Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
										--			,@EmployeeGroup,@TargetFor
										--		,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
										--		,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Collection Amount is empty.',@USER_ID,GETDATE()

										--		SET @FAIL = 'TRUE'
										--End
										--if(isnull(@ORDERQTY,0)=0)
										--Begin
										--		select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
										--		INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
										--		DocumentNo,DocumentDate,
										--		EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
										--		)
										--		Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
										--			,@EmployeeGroup,@TargetFor
										--		,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
										--		,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Order Quantity is empty.',@USER_ID,GETDATE()

										--		SET @FAIL = 'TRUE'
										--End


										IF(@FAIL='FALSE')
										Begin
												select @HeaderTARGETLEVELID=ID from FSM_TARGETLEVELSETUP_MASTER  where LEVEL_NAME=trim(@TargetFor)


												if  NOT EXISTS (select 'Y' from FSM_SALESTARGETASSIGN   where TARGETDOCNUMBER=@TargetNo)
												BEGIN
													select  @LastCount=iSNULL(MAX(SALESTARGET_ID),0) from FSM_SALESTARGETASSIGN  
													INSERT INTO FSM_SALESTARGETASSIGN(SALESTARGET_ID,TARGETLEVELID,TARGETDOCNUMBER,TARGETDATE,CREATEDBY,CREATEDON) 
													VALUES(@LastCount+1,@HeaderTARGETLEVELID,@TargetNo,@TargetDate,@USER_ID,GETDATE());		
												END

									

												IF(@TargetFor='Region')
												BEGIN
											
														select @TARGETLEVELID=branch_id,@TARGETLEVEL=branch_description,@INTERNALID=branch_internalId from tbl_master_branch  
														WHERE branch_description=TRIM(@TARGETLEVELNAME) AND  branch_code=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='ASM' OR @Action ='SalesOfficer' OR @Action ='Salesman' )
												BEGIN
											
													select @TARGETLEVELID=cnt_id, 
													@TARGETLEVEL=(isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') ),
													 @INTERNALID=CON.cnt_internalId
													from tbl_master_contact CON 									

													where (isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') )=TRIM(@TARGETLEVELNAME)
													and CON.cnt_shortName=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='Beat' )
												BEGIN
											
													select @TARGETLEVELID=ID,@TARGETLEVEL=NAME,@INTERNALID=CODE from FSM_GROUPBEAT  
														WHERE NAME=TRIM(@TARGETLEVELNAME) AND  CODE=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='Outlet' )
												BEGIN
											
													select @TARGETLEVELID=Shop_ID, @TARGETLEVEL=Shop_Name,@INTERNALID=Shop_Code
													from tbl_Master_shop WHERE Shop_Name=TRIM(@TARGETLEVELNAME) AND  Shop_Code=TRIM(@TARGETLEVELCODE)
											
												END



									

												if  EXISTS (select 'Y' from FSM_SALESTARGETASSIGN   where TARGETDOCNUMBER=@TargetNo)
												BEGIN
											
													select @SALESTARGETID=SALESTARGET_ID from FSM_SALESTARGETASSIGN   where TARGETDOCNUMBER=@TargetNo

													select  @LastCountDetails=iSNULL(MAX(SALESTARGETDETAILS_ID),0) from FSM_SALESTARGETASSIGN_DETAILS  
														INSERT INTO FSM_SALESTARGETASSIGN_DETAILS(SALESTARGETDETAILS_ID,SALESTARGET_ID,TARGETDOCNUMBER
														,TARGETLEVELASSIGNID,TARGETLEVELASSIGNNAME,	INTERNALID,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,
														COLLECTION,ORDERQTY, TARGETLEVELID,CREATEDBY,CREATEDON	
													)
														Select @LastCountDetails+1,@SALESTARGETID,@TargetNo
														,@TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,
														@COLLECTION,@ORDERQTY, @HeaderTARGETLEVELID,@USER_ID,GETDATE()
							
												END

										END

								
									SET @Success = 1;

									FETCH NEXT FROM db_cursor INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY

								END   

								CLOSE db_cursor   
								DEALLOCATE db_cursor

					END
				END
			
				SET @Success = 1;

				FETCH NEXT FROM db_cursorHEADER INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor

			END   

			CLOSE db_cursorHEADER   
			DEALLOCATE db_cursorHEADER

		SELECT @LastCount+1 AS DetailsID, @Success AS 'Success';

	END
	else IF @ACTION = 'INSERTPRODUCTTARGET'
	BEGIN
			

			DECLARE db_cursorHEADER CURSOR FOR  
			Select 	DISTINCT DocumentNo,DocumentDate,EmployeeGroup,TargetFor
			From @IMPORT_PRODUCTTABLE 	where DocumentNo<>''	

			OPEN db_cursorHEADER   
			FETCH NEXT FROM db_cursorHEADER INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor

			WHILE @@FETCH_STATUS = 0   
			BEGIN 
				

				if(isnull(@TargetNo,'')='')
				Begin
						
						select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
						INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
						DocumentNo,DocumentDate,
						EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
						)
						Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
							,@EmployeeGroup,@TargetFor
						,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
						,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Document Number is empty.',@USER_ID,GETDATE()

						SET @FAIL = 'TRUE'
					
				End
				if(isnull(@TargetDate,'')='')
				Begin
						
						select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
						INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
						DocumentNo,DocumentDate,
						EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
						)
						Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
							,@EmployeeGroup,@TargetFor
						,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
						,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Document Date is empty.',@USER_ID,GETDATE()

						SET @FAIL = 'TRUE'
					
				End



				IF(@FAIL='FALSE')
				BEGIN
					if EXISTS (select 'Y' from FSM_PRODUCTTARGETASSIGN   where TARGETDOCNUMBER=TRIM(@TargetNo))
					Begin
							SELECT @LastCount+1 AS DetailsID, @Success AS 'Success';

							select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
							INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
							DocumentNo,DocumentDate,
							EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,PRODUCTCODE,PRODUCTNAME,ORDERAMOUNT,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
							)
							Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
								,@EmployeeGroup,@TargetFor
							,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
							,@ENDDATE,@PRODUCTCODE,@PRODUCTNAME,@ORDERAMOUNT,@ORDERQTY,'Failed','Duplicate Document Number.',@USER_ID,GETDATE()
							


					end
					ELSE
					BEGIN
								DECLARE db_cursor CURSOR FOR  
								Select 	DocumentNo,DocumentDate,EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME ,STARTEDATE,ENDDATE,PRODUCTCODE,PRODUCTNAME,ORDERAMOUNT,ORDERQTY
								From @IMPORT_PRODUCTTABLE 		WHERE DocumentNo=@TargetNo

								OPEN db_cursor   
								FETCH NEXT FROM db_cursor INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@PRODUCTCODE,@PRODUCTNAME,@ORDERAMOUNT,@ORDERQTY

								WHILE @@FETCH_STATUS = 0   
								BEGIN 	

										SET @FAIL = 'FALSE'
										if(isnull(@EmployeeGroup,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Target Type is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TargetFor,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Target Level is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TARGETLEVELNAME,'')='' OR isnull(@TARGETLEVELCODE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Assignee Name is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TIMEFRAME,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Time Frame is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@STARTEDATE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Start Date is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@ENDDATE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','End Date is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
										if( isnull(@ORDERAMOUNT,0)=0  and isnull(@ORDERQTY,0)=0)
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  

												

												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Order Amount,Order Quantity is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
										if(@PRODUCTNAME='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  												

												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Product Name is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
										if(@PRODUCTCODE='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  												

												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Product Code is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(@PRODUCTNAME<>'')
										Begin
											select @PRODUCTID=Isnull(sProducts_ID,0) from Master_sProducts where sProducts_Name=@PRODUCTNAME  and sProducts_Code=@PRODUCTCODE
											if(@PRODUCTID=0)
											Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  												

												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,NEWVISIT,REVISIT,ORDERAMOUNT,COLLECTION,ORDERQTY,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@NEWVISIT,@REVISIT,@ORDERAMOUNT,@COLLECTION,@ORDERQTY,'Failed','Product not found.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
											end

										End

										IF(@FAIL='FALSE')
										BEGIN
												select @HeaderTARGETLEVELID=ID from FSM_TARGETLEVELSETUP_MASTER  where LEVEL_NAME=trim(@TargetFor)


												if  NOT EXISTS (select 'Y' from FSM_PRODUCTTARGETASSIGN   where TARGETDOCNUMBER=@TargetNo)
												BEGIN
													select  @LastCount=iSNULL(MAX(PRODUCTTARGET_ID),0) from FSM_PRODUCTTARGETASSIGN  
													INSERT INTO FSM_PRODUCTTARGETASSIGN(PRODUCTTARGET_ID,TARGETLEVELID,TARGETDOCNUMBER,TARGETDATE,CREATEDBY,CREATEDON) 
													VALUES(@LastCount+1,@HeaderTARGETLEVELID,@TargetNo,@TargetDate,@USER_ID,GETDATE());		
												END									

												IF(@TargetFor='Region')
												BEGIN
											
														select @TARGETLEVELID=branch_id,@TARGETLEVEL=branch_description,@INTERNALID=branch_internalId from tbl_master_branch  
														WHERE branch_description=TRIM(@TARGETLEVELNAME) AND  branch_code=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='ASM' OR @Action ='SalesOfficer' OR @Action ='Salesman' )
												BEGIN
											
													select @TARGETLEVELID=cnt_id, 
													@TARGETLEVEL=(isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') ),
													 @INTERNALID=CON.cnt_internalId
													from tbl_master_contact CON 									

													where (isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') )=TRIM(@TARGETLEVELNAME)
													and CON.cnt_shortName=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='Beat' )
												BEGIN
											
													select @TARGETLEVELID=ID,@TARGETLEVEL=NAME,@INTERNALID=CODE from FSM_GROUPBEAT  
														WHERE NAME=TRIM(@TARGETLEVELNAME) AND  CODE=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='Outlet' )
												BEGIN
											
													select @TARGETLEVELID=Shop_ID, @TARGETLEVEL=Shop_Name,@INTERNALID=Shop_Code
													from tbl_Master_shop WHERE Shop_Name=TRIM(@TARGETLEVELNAME) AND  Shop_Code=TRIM(@TARGETLEVELCODE)
											
												END

												if(@PRODUCTNAME<>'')
												Begin
													select @PRODUCTID=sProducts_ID from Master_sProducts where sProducts_Name=@PRODUCTNAME  and sProducts_Code=@PRODUCTCODE
												End

												if  EXISTS (select 'Y' from FSM_PRODUCTTARGETASSIGN   where TARGETDOCNUMBER=@TargetNo)
												BEGIN
											
													select @SALESTARGETID=PRODUCTTARGET_ID from FSM_PRODUCTTARGETASSIGN   where TARGETDOCNUMBER=@TargetNo

													select  @LastCountDetails=iSNULL(MAX(PRODUCTTARGETDETAILS_ID),0) from FSM_PRODUCTTARGETASSIGN_DETAILS  
														INSERT INTO FSM_PRODUCTTARGETASSIGN_DETAILS(PRODUCTTARGETDETAILS_ID,PRODUCTTARGET_ID,TARGETDOCNUMBER
														,TARGETLEVELASSIGNID,TARGETLEVELASSIGNNAME,	INTERNALID,TIMEFRAME,STARTDATE,ENDDATE,PRODUCTID,PRODUCTCODE,PRODUCTNAME,ORDERAMOUNT,
														ORDERQTY, TARGETLEVELID,CREATEDBY,CREATEDON	
													)
														Select @LastCountDetails+1,@SALESTARGETID,@TargetNo
														,@TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@PRODUCTID,@PRODUCTCODE,@PRODUCTNAME,@ORDERAMOUNT,
														@ORDERQTY, @HeaderTARGETLEVELID,@USER_ID,GETDATE()
							
												END
										END
								
									SET @Success = 1;

									FETCH NEXT FROM db_cursor INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@PRODUCTCODE,@PRODUCTNAME,@ORDERAMOUNT,@ORDERQTY

								END   

								CLOSE db_cursor   
								DEALLOCATE db_cursor

					END
				END
			
				SET @Success = 1;

				FETCH NEXT FROM db_cursorHEADER INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor

			END   

			CLOSE db_cursorHEADER   
			DEALLOCATE db_cursorHEADER

		SELECT @LastCount+1 AS DetailsID, @Success AS 'Success';

	END
	else IF @ACTION = 'INSERTBRANDTARGET'
	BEGIN
			

			DECLARE db_cursorHEADER CURSOR FOR  
			Select 	DISTINCT DocumentNo,DocumentDate,EmployeeGroup,TargetFor
			From @IMPORT_BRANDTABLE where DocumentNo<>''		

			OPEN db_cursorHEADER   
			FETCH NEXT FROM db_cursorHEADER INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor

			WHILE @@FETCH_STATUS = 0   
			BEGIN 
				if(isnull(@TargetNo,'')='')
				Begin
						
						select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
						INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
						DocumentNo,DocumentDate,
						EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
						)
						Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
							,@EmployeeGroup,@TargetFor
						,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
						,@ENDDATE,'Failed','Document Number is empty.',@USER_ID,GETDATE()

						SET @FAIL = 'TRUE'
					
				End
				if(isnull(@TargetDate,'')='')
				Begin
						
						select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
						INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
						DocumentNo,DocumentDate,
						EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
						)
						Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
							,@EmployeeGroup,@TargetFor
						,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
						,@ENDDATE,'Failed','Document Date is empty.',@USER_ID,GETDATE()

						SET @FAIL = 'TRUE'
					
				End

				IF(@FAIL='FALSE')
				BEGIN
					if EXISTS (select 'Y' from FSM_BRANDTARGETASSIGN   where BRANDTARGETDOCNUMBER=TRIM(@TargetNo))
					Begin
							SELECT @LastCount+1 AS DetailsID, @Success AS 'Success';

							select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
							INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
							DocumentNo,DocumentDate,
							EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
							)
							Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
								,@EmployeeGroup,@TargetFor
							,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
							,@ENDDATE,'Failed','Duplicate Document Number.',@USER_ID,GETDATE()
							


					end
					ELSE
					BEGIN
								DECLARE db_cursor CURSOR FOR  
								Select 	DocumentNo,DocumentDate,EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME ,STARTEDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME
								From @IMPORT_BRANDTABLE 		WHERE DocumentNo=@TargetNo

								OPEN db_cursor   
								FETCH NEXT FROM db_cursor INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME

								WHILE @@FETCH_STATUS = 0   
								BEGIN 	

										if(isnull(@EmployeeGroup,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Target Type is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TargetFor,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Target Level is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TARGETLEVELNAME,'')='' OR isnull(@TARGETLEVELCODE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Assignee Name is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TIMEFRAME,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Time Frame is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@STARTEDATE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Start Date is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@ENDDATE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','End Date is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
										if(isnull(@BRANDNAME,'')='') 
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Brand Name is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
										if( isnull(@ORDERAMOUNT,0)=0  and isnull(@ORDERQTY,0)=0)
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  

												

												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Order Amount,Order Quantity is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
										if( isnull(@BRANDNAME,'')=''  )
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  

												

												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Brand is empty..',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End


										if(@BRANDNAME<>'')
										Begin
											select @BRANDID=isnull(Brand_Id,0) from tbl_master_brand where Brand_Name=trim(@BRANDNAME)
											if( isnull(@BRANDID,0)=0  )
											Begin
													select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG												

													INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
													DocumentNo,DocumentDate,
													EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,BRANDNAME,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
													)
													Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
														,@EmployeeGroup,@TargetFor
													,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
													,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME,'Failed','Brand not found.',@USER_ID,GETDATE()

													SET @FAIL = 'TRUE'
											End

										End

										IF(@FAIL='FALSE')
										BEGIN

												select @HeaderTARGETLEVELID=ID from FSM_TARGETLEVELSETUP_MASTER  where LEVEL_NAME=trim(@TargetFor)


												if  NOT EXISTS (select 'Y' from FSM_BRANDTARGETASSIGN   where BRANDTARGETDOCNUMBER=@TargetNo)
												BEGIN
													select  @LastCount=iSNULL(MAX(BRANDTARGET_ID),0) from FSM_BRANDTARGETASSIGN  
													INSERT INTO FSM_BRANDTARGETASSIGN(BRANDTARGET_ID,BRANDTARGETLEVELID,BRANDTARGETDOCNUMBER,BRANDTARGETDATE,CREATEDBY,CREATEDON) 
													VALUES(@LastCount+1,@HeaderTARGETLEVELID,@TargetNo,@TargetDate,@USER_ID,GETDATE());		
												END

									

												IF(@TargetFor='Region')
												BEGIN
											
														select @TARGETLEVELID=branch_id,@TARGETLEVEL=branch_description,@INTERNALID=branch_internalId from tbl_master_branch  
														WHERE branch_description=TRIM(@TARGETLEVELNAME) AND  branch_code=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='ASM' OR @Action ='SalesOfficer' OR @Action ='Salesman' )
												BEGIN
											
													select @TARGETLEVELID=cnt_id, 
													@TARGETLEVEL=(isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') ),
													 @INTERNALID=CON.cnt_internalId
													from tbl_master_contact CON 									

													where (isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') )=TRIM(@TARGETLEVELNAME)
													and CON.cnt_shortName=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='Beat' )
												BEGIN
											
													select @TARGETLEVELID=ID,@TARGETLEVEL=NAME,@INTERNALID=CODE from FSM_GROUPBEAT  
														WHERE NAME=TRIM(@TARGETLEVELNAME) AND  CODE=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='Outlet' )
												BEGIN
											
													select @TARGETLEVELID=Shop_ID, @TARGETLEVEL=Shop_Name,@INTERNALID=Shop_Code
													from tbl_Master_shop WHERE Shop_Name=TRIM(@TARGETLEVELNAME) AND  Shop_Code=TRIM(@TARGETLEVELCODE)
											
												END

												if(@BRANDNAME<>'')
												Begin
													select @BRANDID=Brand_Id from tbl_master_brand where Brand_Name=trim(@BRANDNAME)
												End
									

												if  EXISTS (select 'Y' from FSM_BRANDTARGETASSIGN   where BRANDTARGETDOCNUMBER=@TargetNo)
												BEGIN
											
													select @SALESTARGETID=BRANDTARGET_ID from FSM_BRANDTARGETASSIGN   where BRANDTARGETDOCNUMBER=@TargetNo

													select  @LastCountDetails=iSNULL(MAX(BRANDTARGETDETAILS_ID),0) from FSM_BRANDTARGETASSIGN_DETAILS  
														INSERT INTO FSM_BRANDTARGETASSIGN_DETAILS(BRANDTARGETDETAILS_ID,BRANDTARGET_ID,BRANDTARGETDOCNUMBER
														,TARGETLEVELASSIGNID,TARGETLEVELASSIGNNAME,	INTERNALID,TIMEFRAME,STARTDATE,ENDDATE,BRANDID,BRANDNAME,ORDERAMOUNT,
														ORDERQTY, BRANDTARGETLEVELID,CREATEDBY,CREATEDON	
													)
														Select @LastCountDetails+1,@SALESTARGETID,@TargetNo
														,@TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@BRANDID,@BRANDNAME,@ORDERAMOUNT,
														@ORDERQTY, @HeaderTARGETLEVELID,@USER_ID,GETDATE()
							
												END
										END
								
									SET @Success = 1;

									FETCH NEXT FROM db_cursor INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@BRANDNAME

								END   

								CLOSE db_cursor   
								DEALLOCATE db_cursor

					END
				END
				SET @Success = 1;

				FETCH NEXT FROM db_cursorHEADER INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor

			END   

			CLOSE db_cursorHEADER   
			DEALLOCATE db_cursorHEADER

		SELECT @LastCount+1 AS DetailsID, @Success AS 'Success';

	END
	else IF @ACTION = 'INSERTWODTARGET'
	BEGIN
			

			DECLARE db_cursorHEADER CURSOR FOR  
			Select 	DISTINCT DocumentNo,DocumentDate,EmployeeGroup,TargetFor
			From @IMPORT_WODTABLE 	where DocumentNo<>''	

			OPEN db_cursorHEADER   
			FETCH NEXT FROM db_cursorHEADER INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor

			WHILE @@FETCH_STATUS = 0   
			BEGIN 
				
				if(isnull(@TargetNo,'')='')
				Begin
						
						select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
						INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
						DocumentNo,DocumentDate,
						EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
						)
						Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
							,@EmployeeGroup,@TargetFor
						,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
						,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@WODCOUNT,'Failed','Document Number is empty.',@USER_ID,GETDATE()

						SET @FAIL = 'TRUE'
					
				End
				if(isnull(@TargetDate,'')='')
				Begin
						
						select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
						INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
						DocumentNo,DocumentDate,
						EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ORDERAMOUNT,ORDERQTY,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
						)
						Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
							,@EmployeeGroup,@TargetFor
						,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
						,@ENDDATE,@ORDERAMOUNT,@ORDERQTY,@WODCOUNT,'Failed','Document Date is empty.',@USER_ID,GETDATE()

						SET @FAIL = 'TRUE'
					
				End

				IF(@FAIL='FALSE')
				BEGIN
					if EXISTS (select 'Y' from FSM_WODTARGETASSIGN   where WODTARGETDOCNUMBER=TRIM(@TargetNo))
					Begin
							SELECT @LastCount+1 AS DetailsID, @Success AS 'Success';

							select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
							INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
							DocumentNo,DocumentDate,
							EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
							)
							Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
								,@EmployeeGroup,@TargetFor
							,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
							,@ENDDATE,@WODCOUNT,'Failed','Duplicate Document Number.',@USER_ID,GETDATE()
							


					end
					ELSE
					BEGIN
								DECLARE db_cursor CURSOR FOR  
								Select 	DocumentNo,DocumentDate,EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTEDATE,ENDDATE,WODCOUNT
								From @IMPORT_WODTABLE 		WHERE DocumentNo=@TargetNo

								OPEN db_cursor   
								FETCH NEXT FROM db_cursor INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@WODCOUNT

								WHILE @@FETCH_STATUS = 0   
								BEGIN 	


											if(isnull(@EmployeeGroup,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,'Failed','Target Type is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TargetFor,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@WODCOUNT,'Failed','Target Level is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TARGETLEVELNAME,'')='' OR isnull(@TARGETLEVELCODE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@WODCOUNT,'Failed','Assignee Name is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@TIMEFRAME,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@WODCOUNT,'Failed','Time Frame is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@STARTEDATE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@WODCOUNT,'Failed','Start Date is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End

										if(isnull(@ENDDATE,'')='')
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@WODCOUNT,'Failed','End Date is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
										if(isnull(@WODCOUNT,'')='') 
										Begin
												select  @LastCountIMPORTLOG=iSNULL(MAX(IMPORT_TARGET_ID),0) from IMPORT_TARGET_LOG  
												INSERT INTO IMPORT_TARGET_LOG(IMPORT_TARGET_ID,
												DocumentNo,DocumentDate,
												EmployeeGroup,TargetFor,TARGETLEVELNAME,TARGETLEVELCODE,TIMEFRAME,STARTDATE,ENDDATE,WODCOUNT,ImportStatus,ImportMsg,CREATEDBY,CREATEDON
												)
												Select @LastCountIMPORTLOG+1,@TargetNo,@TargetDate
													,@EmployeeGroup,@TargetFor
												,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME,@STARTEDATE
												,@ENDDATE,@WODCOUNT,'Failed','WOD Count is empty.',@USER_ID,GETDATE()

												SET @FAIL = 'TRUE'
										End
									
										IF(@FAIL='FALSE')
										BEGIN

												select @HeaderTARGETLEVELID=ID from FSM_TARGETLEVELSETUP_MASTER  where LEVEL_NAME=trim(@TargetFor)


												if  NOT EXISTS (select 'Y' from FSM_WODTARGETASSIGN   where WODTARGETDOCNUMBER=@TargetNo)
												BEGIN
													select  @LastCount=iSNULL(MAX(WODTARGET_ID),0) from FSM_WODTARGETASSIGN  

													INSERT INTO FSM_WODTARGETASSIGN(WODTARGET_ID,TARGETLEVELID,WODTARGETDOCNUMBER,WODTARGETDATE,CREATEDBY,CREATEDON) 
													VALUES(@LastCount+1,@HeaderTARGETLEVELID,@TargetNo,@TargetDate,@USER_ID,GETDATE());	
													
												END

									

												IF(@TargetFor='Region')
												BEGIN
											
														select @TARGETLEVELID=branch_id,@TARGETLEVEL=branch_description,@INTERNALID=branch_internalId from tbl_master_branch  
														WHERE branch_description=TRIM(@TARGETLEVELNAME) AND  branch_code=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='ASM' OR @Action ='SalesOfficer' OR @Action ='Salesman' )
												BEGIN
											
													select @TARGETLEVELID=cnt_id, 
													@TARGETLEVEL=(isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') ),
													 @INTERNALID=CON.cnt_internalId
													from tbl_master_contact CON 									

													where (isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') )=TRIM(@TARGETLEVELNAME)
													and CON.cnt_shortName=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='Beat' )
												BEGIN
											
													select @TARGETLEVELID=ID,@TARGETLEVEL=NAME,@INTERNALID=CODE from FSM_GROUPBEAT  
														WHERE NAME=TRIM(@TARGETLEVELNAME) AND  CODE=TRIM(@TARGETLEVELCODE)
											
												END
												IF(@Action ='Outlet' )
												BEGIN
											
													select @TARGETLEVELID=Shop_ID, @TARGETLEVEL=Shop_Name,@INTERNALID=Shop_Code
													from tbl_Master_shop WHERE Shop_Name=TRIM(@TARGETLEVELNAME) AND  Shop_Code=TRIM(@TARGETLEVELCODE)
											
												END



									

												if  EXISTS (select 'Y' from FSM_WODTARGETASSIGN   where WODTARGETDOCNUMBER=@TargetNo)
												BEGIN
											
													select @SALESTARGETID=WODTARGET_ID from FSM_WODTARGETASSIGN   where WODTARGETDOCNUMBER=@TargetNo

													select  @LastCountDetails=iSNULL(MAX(WODTARGETDETAILS_ID),0) from FSM_WODTARGETASSIGN_DETAILS  
														INSERT INTO FSM_WODTARGETASSIGN_DETAILS(WODTARGETDETAILS_ID,WODTARGET_ID,WODTARGETDOCNUMBER
														,TARGETLEVELASSIGNID,TARGETLEVELASSIGNNAME,	INTERNALID,TIMEFRAME,STARTDATE,ENDDATE,WODCOUNT, TARGETLEVELID,CREATEDBY,CREATEDON	
													)
														Select @LastCountDetails+1,@SALESTARGETID,@TargetNo
														,@TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@WODCOUNT, @HeaderTARGETLEVELID,@USER_ID,GETDATE()
							
												END
										END
								
									SET @Success = 1;

									FETCH NEXT FROM db_cursor INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor,@TARGETLEVELNAME,@TARGETLEVELCODE,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@WODCOUNT

								END   

								CLOSE db_cursor   
								DEALLOCATE db_cursor

					END
				END
				SET @Success = 1;

				FETCH NEXT FROM db_cursorHEADER INTO @TargetNo,@TargetDate,@EmployeeGroup,@TargetFor

			END   

			CLOSE db_cursorHEADER   
			DEALLOCATE db_cursorHEADER

		SELECT @LastCount+1 AS DetailsID, @Success AS 'Success';

	END
	ELSE IF (@Action='GETIMPORTLOG')
	BEGIN
		SELECT 
		IMPORT_TARGET_ID,
		DocumentNo,
		DocumentDate,
		EmployeeGroup,
		TargetFor,
		TARGETLEVELNAME,
		TARGETLEVELCODE,
		TIMEFRAME,
		STARTDATE,
		ENDDATE,
		NEWVISIT,
		REVISIT,
		ORDERAMOUNT,
		COLLECTION,
		BRANDID,
		BRANDNAME,
		ORDERQTY,
		ImportStatus,
		ImportMsg,
		WODCOUNT,
		PRODUCTID,
		PRODUCTCODE,
		PRODUCTNAME,
		CREATEDBY,
		CREATEDON

		FROM IMPORT_TARGET_LOG LOGS 
		WHERE convert(date, LOGS.CREATEDON) BETWEEN @FromDate AND @ToDate
		ORDER BY LOGS.CREATEDON DESC

	END
	ELSE IF (@Action='SHOWIMPORTLOG')
	BEGIN
		SELECT 
		IMPORT_TARGET_ID,
		DocumentNo,
		DocumentDate,
		EmployeeGroup,
		TargetFor,
		TARGETLEVELNAME,
		TARGETLEVELCODE,
		TIMEFRAME,
		STARTDATE,
		ENDDATE,
		NEWVISIT,
		REVISIT,
		ORDERAMOUNT,
		COLLECTION,
		BRANDID,
		BRANDNAME,
		ORDERQTY,
		ImportStatus,
		ImportMsg,
		WODCOUNT,
		PRODUCTID,
		PRODUCTCODE,
		PRODUCTNAME,
		CREATEDBY,
		CREATEDON

		FROM IMPORT_TARGET_LOG LOGS 
		--WHERE convert(date, LOGS.CREATEDON) BETWEEN @FromDate AND @ToDate
		ORDER BY LOGS.CREATEDON DESC

	END
END
GO
