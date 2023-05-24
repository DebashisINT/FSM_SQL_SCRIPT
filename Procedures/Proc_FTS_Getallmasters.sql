IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_Getallmasters]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_Getallmasters] AS' 
END
GO

--exec Proc_FTS_Getallmasters 'TravelAllowance',null
ALTER Proc [dbo].[Proc_FTS_Getallmasters]
@Action varchar(50)=NULL,
@ExpenseID varchar(50)=1,
@Tcid varchar(200)=NULL
As
/***********************************************************************************************************************
1.0		Priti		V2.0.36		23-01-2022		0025583: Portal Changes Required in Module : CONFIGURE TRAVELLING ALLOWANCE
2.0		Sanchita	V2.0.40		09-05-2023		26063: BP Poddar Expense Feature Modification
3.0		Priti	    V2.0.40		20-05-2023		0026145: Modification in the ‘Configure Travelling Allowance’ page.
***************************************************************************************************************************/
Begin
Declare @Variable_Value varchar(50)=null
SELECT @Variable_Value=Value FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='isExpenseFeatureAvailable'

if(@Action ='VisitLocation')
Begin
	--- REV 1.0
	if(@Variable_Value='1')
	Begin
		SELECT  Id as ID ,Visit_Location as Name FROM FTS_Visit_Location  
		where Visit_Location<>'Local'
		order by Visit_Location
	END
	ELSE
	BEGIN
		SELECT  Id as ID ,Visit_Location as Name FROM FTS_Visit_Location  
		where Visit_Location not in ('In Station','Ex Station')
		order by Visit_Location
	END
	 ---END REV 1.0
End

else if(@Action ='Expense')
Begin
	-- Rev 2.0
	DECLARE @IsExpenseFeatureAvailable VARCHAR(10)
	SET @IsExpenseFeatureAvailable = (select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsExpenseFeatureAvailable')
	
	IF(@IsExpenseFeatureAvailable='1')
	BEGIN
		SELECT  Id as ID ,Expense_Type as Name FROM FTS_Expense_Type where Expense_Type='Allowance'
	END
	ELSE
	BEGIN
	-- End of Rev 2.0
		--- REV 1.0
		if(@Variable_Value='1')
		Begin
			SELECT  Id as ID ,Expense_Type as Name FROM FTS_Expense_Type 
			where Id NOT IN(2,3,4,5,6,7)
			order by Expense_Type
		End
		Else
		Begin
			SELECT  Id as ID ,Expense_Type as Name FROM FTS_Expense_Type 
			where Expense_Type<>'Other'
			order by Expense_Type
	
		END
		 ---END REV 1.0
	-- Rev 2.0
	END
	-- End of Rev 2.0
End

else if(@Action ='TravelMode')
BEGIn
    ---REV 1.0
	if(@Variable_Value='1')
	Begin
		SELECT  Id as ID ,TravelMode as Name,Expense_Id,fueladjust FROM FTS_Travel_Mode  where TravelMode='Conveyance'
		order by TravelMode
	END
	ELSE
	Begin
		SELECT  Id as ID ,TravelMode as Name,Expense_Id,fueladjust FROM FTS_Travel_Mode  
		where TravelMode<>'Conveyance'
		order by TravelMode
	End
	 ---END REV 1.0
END


else if(@Action ='Designation')
Begin
SELECT  cast(deg_id  as int ) as ID ,deg_designation as Name FROM tbl_master_designation order by deg_designation
End

else if(@Action ='EmpGrade')
Begin
SELECT  Id as ID ,Employee_Grade as Name FROM FTS_Employee_Grade order by Employee_Grade
End
else if(@Action ='State')
Begin
SELECT  id as ID ,state as Name FROM tbl_master_state
End
else if(@Action ='Fuel')
Begin
SELECT  Id as ID ,FuelType as Name,TravelMode as Mode FROM tbl_FTS_FuelTypes
End

else if(@Action='TravelAllowance')
begin
select *  from
(
select Row_number() over (order by Sysdate ) as Slno,cast (TCId as varchar(500)) as TCId,VisitlocId as  VisitlocId,EmpgradeId as EmpgradeId ,
ExpenseId as ExpenseId ,DesignationId as DesignationId,StateId as StateId,TravelId as TravelId,
EligibleDistance,	EligibleRate	,EligibleAmtday 
,case when IsActive=1 then 'Active' else 'Inactive' end as IsActivename
,vst_loc.Visit_Location as VisitlocName
,expnsetype.Expense_Type as ExpenseName
,travelmod.TravelMode as TravelName
,desg.deg_designation as DesignationName
,grad.Employee_Grade as EmpgradeName
,stat.state as StateName
,fueltype.FuelType as FuelTypes
,conv.FuelID as fuelID
,CONVERT(CHAR(10),Sysdate,103) + ' ' +  CONVERT(CHAR(26),Sysdate,108) as DateConveyance
--Rev 1.0
,branch_description BranchName,area_name AreaName
--Rev 1.0 End
 from FTS_Travel_Conveyance as conv
INNER JOIN FTS_Visit_Location as vst_loc on conv.VisitlocId=vst_loc.Id
INNER JOIN FTS_Expense_Type as expnsetype on conv.ExpenseId=expnsetype.Id
LEFT OUTER  JOIN FTS_Travel_Mode as travelmod on conv.TravelId=travelmod.Id
LEFT OUTER JOIN tbl_master_designation as desg on conv.DesignationId=desg.deg_id
INNER JOIN FTS_Employee_Grade as grad on conv.EmpgradeId=grad.Id
INNER JOIN tbl_master_state as stat on conv.StateId=stat.id
LEFT OUTER JOIN  tbl_FTS_FuelTypes as fueltype on conv.FuelID=fueltype.id

--Rev 1.0
left outer join FTS_TravelConveyanceBranchMap  BranchMap on BranchMap.TravelConveyanceID=TCId
left outer join  FTS_TravelConveyanceAreaMap AreaMap on AreaMap.BranchMapid=BranchMap.BranchMapid

left outer join TBL_MASTER_BRANCH on BranchMap.MapBranchId=TBL_MASTER_BRANCH.branch_id
left outer join  tbl_master_area on AreaMap.MapAreaId=tbl_master_area.area_id
--Rev 1.0 End

)T order by T.Slno desc
end





else if(@Action='TravelAllowancebyID')
begin
select cast (TCId as varchar(500)) as TCId,VisitlocId as  VisitlocId,EmpgradeId as EmpgradeIdfetch ,
ExpenseId as ExpenseId ,DesignationId as DesignationId,StateId as StateIdfetch,TravelId as TravelId,
cast(EligibleDistance as decimal(18,2)) as EligibleDistance,	EligibleRate	,EligibleAmtday ,FuelID as fuelID,cast(trvmod.fueladjust as bit) as fueladjust
,case when IsActive=1 then 'Active' else 'Inactive' end as IsActivename,
IsActive
,StateId,BranchMap.MapBranchId BranchId,MapAreaId AreaId
--Rev 1.0
,branch_description BranchName,area_name AreaName
--Rev 1.0 End
 from FTS_Travel_Conveyance as conv
 LEFT OUTER JOIN FTS_Travel_Mode as trvmod on conv.TravelId=trvmod.Id
  --Rev 1.0
 LEFT OUTER JOIN FTS_TravelConveyanceBranchMap BranchMap on TravelConveyanceID=TCId
 LEFT OUTER JOIN FTS_TravelConveyanceAreaMap AreaMap on BranchMap.BranchMapid=AreaMap.BranchMapid
left outer join TBL_MASTER_BRANCH on BranchMap.MapBranchId=TBL_MASTER_BRANCH.branch_id
left outer join  tbl_master_area on AreaMap.MapAreaId=tbl_master_area.area_id
--Rev 1.0 End
 where TCId=@Tcid




end


END