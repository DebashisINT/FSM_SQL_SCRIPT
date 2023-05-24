

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ Proc_TravelConveyanceManage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [ Proc_TravelConveyanceManage] AS' 
END
GO

ALTER Proc  [dbo].[Proc_TravelConveyanceManage]

@Action varchar(100)=NULL,
@TcID  varchar(500)=NULL,
@VisitlocId varchar(100)=NULL,
@ExpenseId varchar(100)=NULL,
@DesignationId varchar(100)=NULL,
@TravelId  varchar(100)=NULL,
@StateId varchar(100)=NULL,
@EmpgradeId  varchar(100)=NULL,
@EligibleDistanc varchar(100)=NULL,
@EligibleRate varchar(100)=NULL,
@EligibleAmtday varchar(100)=NULL,
@FuelID varchar(50)=NULL,
@USERID  int=NULL,
@IsActive bit=NULL

 As
  /***********************************************************************************************************************
 1.0		Priti	V2.0.40		20-05-2023		0026145: Modification in the ‘Configure Travelling Allowance’ page.
***************************************************************************************************************************/
 BEGIN

 if(@Action='Insert')


 Begin
 IF NOT EXISTS(select TcID from FTS_Travel_Conveyance where VisitlocId=@VisitlocId and EmpgradeId=@EmpgradeId and DesignationId=@DesignationId and StateId=@StateId and ExpenseId=@ExpenseId and TravelId=@TravelId and FuelID=@FuelID and IsActive=1)
 BEGIN

 INSERT  INTO FTS_Travel_Conveyance (VisitlocId,
EmpgradeId,
ExpenseId,
DesignationId,
StateId,
TravelId,
EligibleDistance,
EligibleRate,
EligibleAmtday,
FuelID,
IsActive,
Sysdate,
CreatedBy)
VALUES
(
@VisitlocId,
@EmpgradeId,
@ExpenseId,
@DesignationId,
@StateId,
@TravelId,
@EligibleDistanc,
@EligibleRate,
@EligibleAmtday
,@FuelID
,@IsActive
,GETDATE()
,@USERID
)


END

 End
 else  if(@Action='Update')

 Begin
  IF NOT EXISTS(select TcID from FTS_Travel_Conveyance where VisitlocId=@VisitlocId and EmpgradeId=@EmpgradeId and DesignationId=@DesignationId and StateId=@StateId and ExpenseId=@ExpenseId and TravelId=@TravelId and FuelID=@FuelID and IsActive=1 and TCId<>@TcID)
BEGIN
UPDATE FTS_Travel_Conveyance set VisitlocId=@VisitlocId,
--EmpgradeId=@EmpgradeId,
ExpenseId=@ExpenseId,
DesignationId=@DesignationId,
--StateId=@StateId,
TravelId=@TravelId,
EligibleDistance=@EligibleDistanc,
EligibleRate=@EligibleRate,
EligibleAmtday=@EligibleAmtday,
FuelID=@FuelID,
IsActive=@IsActive
where TCId=@TcID
END
 End

 else if(@Action='Delete')
 BEGIN

 --Rev 1.0
 delete from FTS_TravelConveyanceAreaMap where BranchMapid in (select BranchMapid from FTS_TravelConveyanceBranchMap where TravelConveyanceID=@TcID)
 delete from FTS_TravelConveyanceBranchMap where TravelConveyanceID=@TcID
  --Rev 1.0 End
 delete  from FTS_Travel_Conveyance where TCId=@TcID

 END
 End

