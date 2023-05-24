

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_ReimbesementConfiguration]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_ReimbesementConfiguration] AS' 
END
GO
ALTER Proc  [dbo].[Proc_ReimbesementConfiguration]

@Action varchar(100)=NULL,
@Conveyance [udt_TravelConveyance] READONLY,
@USERID  int=NULL,
@IsActive bit=NULL,
@BranchList [udt_TravelConveyanceBranchMap] READONLY,
@AreaList [udt_TravelConveyanceAreaMap] READONLY


 As
 /***********************************************************************************************************************
 1.0		Priti	V2.0.40		20-05-2023		0026145: Modification in the ‘Configure Travelling Allowance’ page.
***************************************************************************************************************************/
 BEGIN

 if(@Action='Insert')

Begin

DECLARE  @VisitlocId varchar(50),@EmpgradeId  varchar(50), @ExpenseId  varchar(50) , @DesignationId   varchar(50),@StateId   varchar(50),
@TravelId  varchar(50) ,@EligibleDistance  varchar(50),@EligibleRate  varchar(50) ,@EligibleAmtday  varchar(50),@fuelID  varchar(50) 

--Rev 1.0
,@TCId uniqueidentifier,@TravelConveyance_Id nvarchar(Max)=null,@Branch_Id int=0,@State_id int=0,@area_id int=0,@Cityid int=0,@BranchMapid int=0,@City_id int=0
,@Value varchar(50)=null


SELECT @Value=Isnull(Value,'') FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsShowReimbursementTypeInAttendance'


CREATE TABLE #BRANCH_MAP
	(
	BRANCHID INT
	)
CREATE TABLE #AREA_MAP
(
AREAID INT
)
if(Exists(select * from @BranchList ))
Begin

	INSERT INTO #BRANCH_MAP
	SELECT BranchId FROM @BranchList
End

if(Exists(select * from @AreaList ))
Begin


INSERT INTO #AREA_MAP
SELECT AREAID FROM @AreaList
End
--Rev 1.0 End

DECLARE db_cursor CURSOR FOR 

SELECT [VisitlocId] ,[EmpgradeId],[ExpenseId] , [DesignationId]  ,[StateId]  ,[TravelId]  ,[EligibleDistance],
[EligibleRate]  ,[EligibleAmtday]  ,[fuelID]  FROM @Conveyance
 

OPEN db_cursor  

	FETCH NEXT FROM db_cursor INTO @VisitlocId ,@EmpgradeId ,@ExpenseId,@DesignationId,@StateId,@TravelId,@EligibleDistance,
	@EligibleRate,@EligibleAmtday,@fuelID

WHILE @@FETCH_STATUS = 0  
BEGIN  
--Rev 1.0 
if  EXISTS(select * from #BRANCH_MAP)
begin
	if(@Value='1')
	Begin
		if  EXISTS(select * from #AREA_MAP)
		Begin
			if NOT EXISTS(
			select TcID from FTS_Travel_Conveyance 
			left outer join FTS_TravelConveyanceBranchMap BranchMap on TravelConveyanceID=TCId
			left outer join FTS_TravelConveyanceAreaMap AreaMap on BranchMap.BranchMapid=AreaMap.BranchMapid
			where VisitlocId=@VisitlocId and EmpgradeId=@EmpgradeId and DesignationId=@DesignationId 
			and StateId=@StateId and ExpenseId=@ExpenseId and TravelId=@TravelId and FuelID=@fuelID and IsActive=1
			and BranchMap.MapBranchId in (select BRANCHID from #BRANCH_MAP)
			and AreaMap.MapAreaId in (select AREAID from #AREA_MAP)

			)
			Begin


				set @TCId=NEWID();
				INSERT  INTO FTS_Travel_Conveyance  (TCId,VisitlocId,EmpgradeId,ExpenseId,DesignationId,StateId,TravelId,EligibleDistance,EligibleRate,
				EligibleAmtday,FuelID,IsActive,Sysdate,CreatedBy)
				select   @TCId,@VisitlocId , @EmpgradeId, @ExpenseId ,  @DesignationId  ,  @StateId  , @TravelId  , @EligibleDistance, @EligibleRate  ,
				@EligibleAmtday  , @fuelID  , @IsActive, GETDATE(), @USERID 

				--Rev 1.0 
				if(Exists(select * from @BranchList ))
				Begin
					DECLARE db_cursorBranchMap CURSOR FOR 
					SELECT BRANCH_ID,branch_state,branch_city FROM TBL_MASTER_BRANCH A inner join  #BRANCH_MAP  MAP on MAP.BRANCHID=A.branch_id
					OPEN db_cursorBranchMap  
					FETCH NEXT FROM db_cursorBranchMap INTO @Branch_Id,@State_id,@City_id	

					WHILE @@FETCH_STATUS = 0  
					BEGIN 
						if(@State_id=@StateId)
						Begin
								insert into FTS_TravelConveyanceBranchMap(TravelConveyanceID,MapStateId,MapBranchId,CreateOn,CreateBy)
								values(@TCId,@State_id,@Branch_Id,Getdate(),@USERID)

								SELECT @BranchMapid=SCOPE_IDENTITY()

								if(Exists(select * from @AreaList ))
								Begin

									DECLARE db_cursorAreaMap CURSOR FOR 
									SELECT area_id,city_id FROM tbl_master_area A inner join  #AREA_MAP  MAP on MAP.AREAID=A.area_id
									OPEN db_cursorAreaMap  
									FETCH NEXT FROM db_cursorAreaMap INTO @area_id,@Cityid	

									WHILE @@FETCH_STATUS = 0  
									BEGIN 

							    
										if(@City_id=@Cityid)
										Begin
												insert into FTS_TravelConveyanceAreaMap(BranchMapid,MapBranchId,MapAreaId,CreateOn,CreateBy)
												values(@BranchMapid,@Branch_Id,@area_id,Getdate(),@USERID)

										End	
										FETCH NEXT FROM db_cursorAreaMap INTO @area_id,@Cityid		
									End
									CLOSE db_cursorAreaMap  
									DEALLOCATE db_cursorAreaMap 

								End
					 
						End	
						FETCH NEXT FROM db_cursorBranchMap INTO @Branch_Id,@State_id,@City_id	
					End
					CLOSE db_cursorBranchMap  
					DEALLOCATE db_cursorBranchMap 
				End
				--Rev 1.0 End
		End
		End
		else
		Begin
			if NOT EXISTS(
			select TcID from FTS_Travel_Conveyance 
			left outer join FTS_TravelConveyanceBranchMap BranchMap on TravelConveyanceID=TCId
			left outer join FTS_TravelConveyanceAreaMap AreaMap on BranchMap.BranchMapid=AreaMap.BranchMapid
			where VisitlocId=@VisitlocId and EmpgradeId=@EmpgradeId and DesignationId=@DesignationId 
			and StateId=@StateId and ExpenseId=@ExpenseId and TravelId=@TravelId and FuelID=@fuelID and IsActive=1
			and BranchMap.MapBranchId in (select BRANCHID from #BRANCH_MAP)	

			)
			Begin

				set @TCId=NEWID();
				INSERT  INTO FTS_Travel_Conveyance  (TCId,VisitlocId,EmpgradeId,ExpenseId,DesignationId,StateId,TravelId,EligibleDistance,EligibleRate,
				EligibleAmtday,FuelID,IsActive,Sysdate,CreatedBy)
				select   @TCId,@VisitlocId , @EmpgradeId, @ExpenseId ,  @DesignationId  ,  @StateId  , @TravelId  , @EligibleDistance, @EligibleRate  ,
				@EligibleAmtday  , @fuelID  , @IsActive, GETDATE(), @USERID 

				--Rev 1.0 
				if(Exists(select * from @BranchList ))
				Begin
					DECLARE db_cursorBranchMap CURSOR FOR 
					SELECT BRANCH_ID,branch_state,branch_city FROM TBL_MASTER_BRANCH A inner join  #BRANCH_MAP  MAP on MAP.BRANCHID=A.branch_id
					OPEN db_cursorBranchMap  
					FETCH NEXT FROM db_cursorBranchMap INTO @Branch_Id,@State_id,@City_id	

					WHILE @@FETCH_STATUS = 0  
					BEGIN 
						if(@State_id=@StateId)
						Begin
								insert into FTS_TravelConveyanceBranchMap(TravelConveyanceID,MapStateId,MapBranchId,CreateOn,CreateBy)
								values(@TCId,@State_id,@Branch_Id,Getdate(),@USERID)

								SELECT @BranchMapid=SCOPE_IDENTITY()

								if(Exists(select * from @AreaList ))
								Begin

									DECLARE db_cursorAreaMap CURSOR FOR 
									SELECT area_id,city_id FROM tbl_master_area A inner join  #AREA_MAP  MAP on MAP.AREAID=A.area_id
									OPEN db_cursorAreaMap  
									FETCH NEXT FROM db_cursorAreaMap INTO @area_id,@Cityid	

									WHILE @@FETCH_STATUS = 0  
									BEGIN 

							    
										if(@City_id=@Cityid)
										Begin
												insert into FTS_TravelConveyanceAreaMap(BranchMapid,MapBranchId,MapAreaId,CreateOn,CreateBy)
												values(@BranchMapid,@Branch_Id,@area_id,Getdate(),@USERID)

										End	
										FETCH NEXT FROM db_cursorAreaMap INTO @area_id,@Cityid		
									End
									CLOSE db_cursorAreaMap  
									DEALLOCATE db_cursorAreaMap 

								End
					 
						End	
						FETCH NEXT FROM db_cursorBranchMap INTO @Branch_Id,@State_id,@City_id	
					End
					CLOSE db_cursorBranchMap  
					DEALLOCATE db_cursorBranchMap 
				End
				--Rev 1.0 End
			End
		End
	End
end
Else
Begin
--Rev 1.0 End
if NOT EXISTS(
select TcID from FTS_Travel_Conveyance where VisitlocId=@VisitlocId and EmpgradeId=@EmpgradeId and DesignationId=@DesignationId 
and StateId=@StateId and ExpenseId=@ExpenseId and TravelId=@TravelId and FuelID=@fuelID and IsActive=1)

Begin

		set @TCId=NEWID();
		INSERT  INTO FTS_Travel_Conveyance  (TCId,VisitlocId,EmpgradeId,ExpenseId,DesignationId,StateId,TravelId,EligibleDistance,EligibleRate,
		EligibleAmtday,FuelID,IsActive,Sysdate,CreatedBy)
		select   @TCId,@VisitlocId , @EmpgradeId, @ExpenseId ,  @DesignationId  ,  @StateId  , @TravelId  , @EligibleDistance, @EligibleRate  ,
		@EligibleAmtday  , @fuelID  , @IsActive, GETDATE(), @USERID 

	
End

--Rev 1.0 
End
--Rev 1.0 End


      FETCH NEXT FROM db_cursor INTO @VisitlocId ,@EmpgradeId ,@ExpenseId,@DesignationId,@StateId,@TravelId,@EligibleDistance,@EligibleRate,@EligibleAmtday,@fuelID 


END 

CLOSE db_cursor  
DEALLOCATE db_cursor 

END


 END