
--drop PROC [dbo].[PRC_BRANDVOLUMEVALUETARGETASSIGN ]

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_BRANDVOLUMEVALUETARGETASSIGN]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_BRANDVOLUMEVALUETARGETASSIGN] AS'  
 END 
 GO
ALTER PROC [dbo].[PRC_BRANDVOLUMEVALUETARGETASSIGN] 
(
@ACTION NVARCHAR(150) = NULL,
@TargetType NVARCHAR(100) = '',
@TARGET_ID BIGINT = 0 ,
@TargetDate DATETIME = NULL,
@TargetNo NVARCHAR(100) = '',
@USER_ID BIGINT=NULL,
@UNIQUETARGETLEVELID bigint=0,
@UNIQUETARGETLEVEL nvarchar(200)='',
@UNIQUEINTERNALID nvarchar(10)='' ,
@UNIQUETIMEFRAME nvarchar(200)='' ,
@UNIQUESTARTEDATE datetime= NULL,
@UNIQUEENDDATE datetime= NULL,
@UNIQUEBRANDID BIGINT= NULL,
@FSM_UDT_BRANDTARGETASSIGN FSM_UDT_BRANDTARGETASSIGN ReadOnly,
@ReturnValue BIGINT=0 OUTPUT

) --WITH ENCRYPTION
AS  
/************************************************************************************************
Written by : Priti Roy on 06/11/2024
0027770:A new module is required as  Target Assign

************************************************************************************************/ 
    SET NOCOUNT ON ;
    BEGIN TRY 
	BEGIN TRANSACTION	

	DECLARE @SALESTARGETID BIGINT = 0;
	Declare @LastCount bigint=0,@LastCountDetails bigint=0
	DECLARE @Success BIT = 0;
	DECLARE @TARGETLEVELID bigint=0,@TARGETLEVEL nvarchar(200)='',@INTERNALID nvarchar(100)='' ,@TIMEFRAME nvarchar(200)='' ,@STARTEDATE datetime,@ENDDATE datetime
	,@BRANDID bigint=0,@BRANDNAME nvarchar(200)='',@ORDERAMOUNT Numeric(18,4)=0,@COLLECTION Numeric(18,4)=0, @ORDERQTY Numeric(18,4)=0

	
		IF @ACTION = 'INSERTBRANDTARGET'
		BEGIN

		IF @TargetNo IS NOT NULL AND @TargetNo <> ''
		BEGIN

					select  @LastCount=iSNULL(MAX(BRANDTARGET_ID),0) from FSM_BRANDTARGETASSIGN  
					INSERT INTO FSM_BRANDTARGETASSIGN(BRANDTARGET_ID,BRANDTARGETLEVELID,BRANDTARGETDOCNUMBER,BRANDTARGETDATE,CREATEDBY,CREATEDON) 
					VALUES(@LastCount+1,@TargetType,@TargetNo,@TargetDate,@USER_ID,GETDATE());			

					
					DECLARE db_cursor CURSOR FOR  
					Select 	TARGETLEVELASSIGNID,TARGETLEVELASSIGNNAME,INTERNALID,TIMEFRAME ,STARTDATE,ENDDATE,BRANDID,BRANDNAME,ORDERAMOUNT,ORDERQTY
					From @FSM_UDT_BRANDTARGETASSIGN order by SlNo ASC				

					OPEN db_cursor   
					FETCH NEXT FROM db_cursor INTO @TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@BRANDID,@BRANDNAME,@ORDERAMOUNT,@ORDERQTY

					WHILE @@FETCH_STATUS = 0   
					BEGIN 

							select  @LastCountDetails=iSNULL(MAX(BRANDTARGETDETAILS_ID),0) from FSM_BRANDTARGETASSIGN_DETAILS  

							if NOT EXISTS (select 'Y' from FSM_BRANDTARGETASSIGN_DETAILS   where TARGETLEVELASSIGNID=@TARGETLEVELID and TARGETLEVELASSIGNNAME=@TARGETLEVEL and 	INTERNALID=@INTERNALID and TIMEFRAME=@TIMEFRAME
							and STARTDATE=@STARTEDATE and ENDDATE=@ENDDATE and BRANDID=@BRANDID and BRANDNAME=@BRANDNAME )
							Begin
								INSERT INTO FSM_BRANDTARGETASSIGN_DETAILS(BRANDTARGETDETAILS_ID,BRANDTARGET_ID,BRANDTARGETDOCNUMBER
								,TARGETLEVELASSIGNID,TARGETLEVELASSIGNNAME,
								INTERNALID,TIMEFRAME,STARTDATE,ENDDATE,BRANDID,BRANDNAME,ORDERAMOUNT,ORDERQTY,BRANDTARGETLEVELID,CREATEDBY,CREATEDON	
								)
								Select @LastCountDetails+1,@LastCount+1,@TargetNo
								,@TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@BRANDID,@BRANDNAME,@ORDERAMOUNT,@ORDERQTY,@TargetType,@USER_ID,GETDATE()
							END
					
							SET @Success = 1;

					 FETCH NEXT FROM db_cursor INTO @TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@BRANDID,@BRANDNAME,@ORDERAMOUNT,@ORDERQTY
					END   

					CLOSE db_cursor   
					DEALLOCATE db_cursor
					END
			

		SELECT @LastCount+1 AS DetailsID, @Success AS 'Success';

		END

		Else IF @ACTION = 'UPDATEBRANDTARGET'
		BEGIN

		IF @TargetNo IS NOT NULL AND @TargetNo <> ''
		BEGIN


					--update FSM_BRANDTARGETASSIGN set BRANDTARGETTYPE=@TargetType,BRANDTARGETDOCNUMBER=@TargetNo,BRANDTARGETDATE=@TargetDate,UPDATEDBY=@USER_ID,UPDATEDON=GETDATE()
					--where BRANDTARGET_ID=@TARGET_ID

					update FSM_BRANDTARGETASSIGN set UPDATEDBY=@USER_ID,UPDATEDON=GETDATE() where BRANDTARGET_ID=@TARGET_ID


					delete from FSM_BRANDTARGETASSIGN_DETAILS where BRANDTARGET_ID=@TARGET_ID

					
					DECLARE db_cursor CURSOR FOR  
					Select 	TARGETLEVELASSIGNID,TARGETLEVELASSIGNNAME,INTERNALID,TIMEFRAME ,STARTDATE,ENDDATE,BRANDID,BRANDNAME,ORDERAMOUNT,ORDERQTY
					From @FSM_UDT_BRANDTARGETASSIGN order by SlNo ASC	

					OPEN db_cursor   
					FETCH NEXT FROM db_cursor INTO @TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@BRANDID,@BRANDNAME,@ORDERAMOUNT,@ORDERQTY

					WHILE @@FETCH_STATUS = 0   
					BEGIN 

							select  @LastCountDetails=iSNULL(MAX(BRANDTARGETDETAILS_ID),0) from FSM_BRANDTARGETASSIGN_DETAILS
							
							if NOT EXISTS (select 'Y' from FSM_BRANDTARGETASSIGN_DETAILS   where TARGETLEVELASSIGNID=@TARGETLEVELID and TARGETLEVELASSIGNNAME=@TARGETLEVEL and 	INTERNALID=@INTERNALID and TIMEFRAME=@TIMEFRAME
							and STARTDATE=@STARTEDATE and ENDDATE=@ENDDATE and BRANDID=@BRANDID and BRANDNAME=@BRANDNAME )
							Begin
								INSERT INTO FSM_BRANDTARGETASSIGN_DETAILS(BRANDTARGETDETAILS_ID,BRANDTARGET_ID,BRANDTARGETDOCNUMBER
								,TARGETLEVELASSIGNID,TARGETLEVELASSIGNNAME,
								INTERNALID,TIMEFRAME,STARTDATE,ENDDATE,BRANDID,BRANDNAME,ORDERAMOUNT,ORDERQTY,BRANDTARGETLEVELID,CREATEDBY,CREATEDON	
								)
								Select @LastCountDetails+1,@TARGET_ID,@TargetNo
								,@TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@BRANDID,@BRANDNAME,@ORDERAMOUNT,@ORDERQTY,@TargetType,@USER_ID,GETDATE()
							END
					
							SET @Success = 1;

					 FETCH NEXT FROM db_cursor INTO @TARGETLEVELID,@TARGETLEVEL,@INTERNALID,@TIMEFRAME ,@STARTEDATE,@ENDDATE,@BRANDID,@BRANDNAME,@ORDERAMOUNT,@ORDERQTY
					END   

					CLOSE db_cursor   
					DEALLOCATE db_cursor
					END

		SELECT @TARGET_ID AS DetailsID, @Success AS 'Success';

		END

		else IF @ACTION = 'GETDETAILSBRANDTARGET'
		Begin
		
		select BRANDTARGETDETAILS_ID,ROW_NUMBER() OVER(ORDER BY BRANDTARGETDETAILS_ID ASC) AS SlNO,BRANDTARGETDOCNUMBER TARGETDOCNUMBER,TARGETLEVELASSIGNID TARGETLEVELID,TARGETLEVELASSIGNNAME TARGETLEVEL,INTERNALID,TIMEFRAME,
			CONVERT(nvarchar(10),STARTDATE,105) STARTEDATE, CONVERT(nvarchar(10),ENDDATE,105) ENDDATE,
			BRANDID,BRANDNAME,ORDERAMOUNT,ORDERQTY
		from FSM_BRANDTARGETASSIGN_DETAILS DETAILS where DETAILS.BRANDTARGET_ID=@TARGET_ID
		end
		else IF @ACTION = 'GETHEADERBRANDTARGET'
		Begin
				select BRANDTARGET_ID,BRANDTARGETLEVELID TARGETLEVEL,BRANDTARGETDOCNUMBER TARGETDOCNUMBER,BRANDTARGETDATE TARGETDATE,CREATEDBY,CREATEDON,UPDATEDBY,UPDATEDON 
				from FSM_BRANDTARGETASSIGN STARGET  where STARGET.BRANDTARGET_ID=@TARGET_ID
		End
		else IF @ACTION = 'CHECKUNIQUETARGETDOCNUMBER'
		Begin
				if EXISTS (select 'Y' from FSM_BRANDTARGETASSIGN   where BRANDTARGETDOCNUMBER=@TargetNo and BRANDTARGET_ID<>@TARGET_ID)
				Begin
					set @ReturnValue=1;
				end
				Else
				Begin
					set @ReturnValue=0;
				End
		End
		ELSE IF (@ACTION='DELETE')
		BEGIN	    
		  delete from FSM_BRANDTARGETASSIGN_DETAILS  Where BRANDTARGET_ID =@TARGET_ID   
		  Delete from FSM_BRANDTARGETASSIGN Where BRANDTARGET_ID =@TARGET_ID     
		  set @ReturnValue='1'    
		END  
		else IF @ACTION = 'CHECKUNIQUETARGETDETAILS'
		Begin
				if EXISTS (select 'Y' from FSM_BRANDTARGETASSIGN_DETAILS where TARGETLEVELASSIGNNAME=@UNIQUETARGETLEVEL and TARGETLEVELASSIGNID=@UNIQUETARGETLEVELID and INTERNALID=@UNIQUEINTERNALID 
					 and TIMEFRAME=@UNIQUETIMEFRAME and STARTDATE=@UNIQUESTARTEDATE and ENDDATE=@UNIQUEENDDATE and BRANDTARGETLEVELID=@TargetType
					 AND BRANDID=@UNIQUEBRANDID AND BRANDTARGETDOCNUMBER<>@TargetNo )
				Begin
					set @ReturnValue=1;
				end
				Else
				Begin
					set @ReturnValue=0;
				End
				
		End



		
		
		COMMIT TRANSACTION
		

    END TRY

	
    BEGIN CATCH
		
		ROLLBACK TRANSACTION
	
        DECLARE @ErrorMessage NVARCHAR(4000) ;
        DECLARE @ErrorSeverity INT ;
        DECLARE @ErrorState INT ;
        SELECT  @ErrorMessage = ERROR_MESSAGE() ,
                @ErrorSeverity = ERROR_SEVERITY() ,
                @ErrorState = ERROR_STATE() ;
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState) ;
    END CATCH ;
    RETURN ;
GO
