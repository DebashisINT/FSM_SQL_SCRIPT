--EXEC Proc_FTS_ConveyanceConfigurationListing '11713','8','2023','0'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_FTS_ConveyanceConfigurationListing]') AND TYPE in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_FTS_ConveyanceConfigurationListing] AS' 
END
GO

ALTER PROCEDURE  [dbo].[Proc_FTS_ConveyanceConfigurationListing]
(
@user_id NVARCHAR(50)=NULL,
@month NVARCHAR(50)=NULL,
@year NVARCHAR(50)=NULL,
@visit_type NVARCHAR(50)=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
1.0		v2.0.35		Debashis	20-10-2022		Reimbursement is showing wrong in Summary (Total Claim Amount).Refer: 0025396
2.0		v2.0.39		Debashis	12-05-2023		Api should return the image_list sequentially.Refer: 0026106
3.0		v2.0.40		Debashis	08-08-2023		total_claim_amount mismatch from api due to wrong checking.Now it has been taken care of.
												Refer: 0026698
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @totalclaim varchar(50)
	DECLARE @totalapproved varchar(50)
	DECLARE @Valueeditablelock int
	
	SET @Valueeditablelock=(select isnull(Value,0) from  FTS_APP_CONFIG_SETTINGS WHERE [Key]='Allow_Approved_Lock_Days')

	DECLARE @GradeID INT
	SET @GradeID=(
	SELECT TOP 1 grd.Emp_Grade FROM tbl_master_user AS usr 
	INNER JOIN tbl_FTS_MapEmployeeGrade AS grd ON usr.user_contactId=grd.Emp_Code
	WHERE usr.user_id=@user_id)

	--Rev 3.0
	--IF(@visit_type<>0)
	IF(@visit_type<>'0')
	--End of Rev 3.0
		BEGIN
			--Rev 1.0
			--SET @totalclaim=(SELECT SUM(ISNULL(Amount,0)) AS total_claim_amount  from [FTS_Reimbursement_Application] where userId=@user_id   and DATEPART(mm,date)=@month  and Visit_type_id=@visit_type )
			--SET @totalapproved=(select  sum(isnull(Amount,0)) as total_approved_amount  from [FTS_Reimbursement_Application_Verified] where userId=@user_id   and DATEPART(mm,date)=@month  and Visit_type_id=@visit_type  and status=1)
			SET @totalclaim=(SELECT SUM(ISNULL(Amount,0)) AS total_claim_amount FROM [FTS_Reimbursement_Application] WHERE userId=@user_id AND DATEPART(mm,date)=@month AND DATEPART(YYYY,date)=@year AND Visit_type_id=@visit_type)
			SET @totalapproved=(SELECT SUM(ISNULL(Amount,0)) AS total_approved_amount FROM [FTS_Reimbursement_Application_Verified] WHERE userId=@user_id AND DATEPART(mm,date)=@month AND DATEPART(YYYY,date)=@year AND Visit_type_id=@visit_type AND status=1)
			--End of Rev 1.0

			SELECT DISTINCT Visit_type_id AS visit_type_id,CASE WHEN Visit_type_id=1 THEN 'Local' ELSE 'Outstation' END AS visit_type,
			@totalclaim AS total_claim_amount,ISNULL(@totalapproved,0) AS total_approved_amount 
			FROM [FTS_Reimbursement_Application] WHERE userId=@user_id AND Visit_type_id=@visit_type AND DATEPART(mm,date)=@month AND DATEPART(YYYY,date)=@year
 
			SELECT extype.Id AS expense_type_id,extype.Expense_Type AS expense_type,ISNULL(T.total_amount,0) AS total_amount,T.Visit_type_id as visit_type_id
			FROM FTS_Expense_Type AS extype
			LEFT OUTER JOIN (
			SELECT Expence_type_id AS expense_type_id,Visit_type_id,SUM(ISNULL(Amount,0)) AS total_amount FROM [FTS_Reimbursement_Application]  
			GROUP BY Expence_type_id,userId,Visit_type_id,DATEPART(mm,date),DATEPART(mm,date),DATEPART(YYYY,date) HAVING DATEPART(mm,date)=@month AND DATEPART(YYYY,date)=@year AND userId=@user_id
			)T ON T.expense_type_id=extype.Id AND ISNULL(T.Visit_type_id,@visit_type)=@visit_type

			SELECT DISTINCT remapp.MapExpenseID,remapp.SubExpenseID,remapp.Visit_type_id as visit_type_id ,vst.Visit_Location as visit_type,  
			remapp.Expence_type_id as expense_type_id,isnull(conv.EligibleRate,0) as maximum_rate,remapp.Mode_of_travel,
			isnull(conv.EligibleDistance,0) as maximum_distance,isnull(conv.EligibleAmtday,0) as maximum_allowance,CONVERT(char(10), remapp.Date,126)  as Date,
			remapp.From_location,remapp.To_location,
			remapp.Amount,remapp.Total_distance,remapp.Remark,CONVERT(CHAR(19),CONVERT(DATETIME,remapp.Start_date_time,101),120) as Start_date_time,
			CONVERT(CHAR(19), CONVERT(DATETIME,remapp.End_date_time,101),120) as End_date_time,
			remapp.Location,remapp.Hotel_name,
			remapp.Food_type,remapp.Fuel_typeId,
			case when isnull(remappverify.status,0)=0 then 'Pending' when isnull(remappverify.status,0)=2 then 'Rejected' else 'Approved'  end as status,
			case when (isnull(remapp.Amount,0) - isnull(remappverify.Amount,0))=0.00 then '0' else isnull(remappverify.Amount,'0') end as approved_amount,
			case when datediff(dd,remapp.Createddate,getdate())<=@Valueeditablelock then 'true' else 'false' end as isEditable,
			fual.FuelType,
			mode.TravelMode as travel_mode
			FROM [FTS_Reimbursement_Application] AS remapp
			LEFT OUTER JOIN [FTS_Reimbursement_Application_Verified] AS remappverify ON remapp.ApplicationID=remappverify.ApplicationID
			INNER JOIN tbl_master_user AS usr ON usr.user_id=remapp.UserID
			LEFT OUTER JOIN tbl_FTS_MapEmployeeGrade AS gradeb ON gradeb.Emp_Code=usr.user_contactId 
			LEFT OUTER JOIN FTS_Travel_Conveyance as conv on remapp.Visit_type_id=conv.VisitlocId and remapp.Expence_type_id=conv.ExpenseId  and conv.EmpgradeId=gradeb.Emp_Grade and 
			isnull(remapp.Mode_of_travel,'0')=isnull(conv.TravelId,'0') and 
			isnull(remapp.Fuel_typeId,'0')=isnull(conv.FuelID,'0')   and remapp.StateID=conv.StateId
			and IsActive=1
			LEFT OUTER JOIN FTS_Travel_Mode as mode on mode.Id=remapp.Mode_of_travel
			LEFT OUTER JOIN FTS_Visit_Location as vst on vst.Id=remapp.Visit_type_id
			LEFT OUTER JOIN tbl_FTS_FuelTypes as fual on fual.Id=remapp.Fuel_typeId
			where DATEPART(mm,remapp.date)=@month and remapp.userId=@user_id and remapp.Visit_type_id=@visit_type  and  DATEPART(YYYY,remapp.date)=@year

			SELECT MapExpenseID,VisitlocId,ExpenseID,Bills,ApplictnimageID FROM [FTS_Reimbursement_Applicationbills]
			WHERE DATEPART(mm,date)=@month AND userId=@user_id AND DATEPART(YYYY,Date)=@year
		END
	ELSE
		BEGIN
			--Rev 1.0
			--SET  @totalclaim=(select  sum(isnull(Amount,0)) as total_claim_amount  from [FTS_Reimbursement_Application] where userId=@user_id   and DATEPART(mm,date)=@month )
			--SET  @totalapproved=(select  sum(isnull(Amount,0)) as total_approved_amount  from [FTS_Reimbursement_Application_Verified] where userId=@user_id   and DATEPART(mm,date)=@month and status=1)
			SET @totalclaim=(SELECT SUM(ISNULL(Amount,0)) AS total_claim_amount FROM [FTS_Reimbursement_Application] WHERE userId=@user_id AND DATEPART(mm,date)=@month AND DATEPART(YYYY,date)=@year)
			SET @totalapproved=(SELECT SUM(ISNULL(Amount,0)) AS total_approved_amount FROM [FTS_Reimbursement_Application_Verified] WHERE userId=@user_id AND DATEPART(YYYY,date)=@year AND DATEPART(mm,date)=@month AND status=1)
			--End of Rev 1.0

			SELECT DISTINCT Visit_type_id AS visit_type_id,CASE WHEN Visit_type_id=1 THEN 'Local' ELSE 'Outstation' END AS visit_type,
			@totalclaim AS total_claim_amount,ISNULL(@totalapproved,0) AS total_approved_amount FROM [FTS_Reimbursement_Application]
			WHERE userId=@user_id AND DATEPART(mm,date)=@month AND DATEPART(YYYY,date)=@year

			SELECT extype.Id AS expense_type_id,extype.Expense_Type AS expense_type,ISNULL(T.total_amount,0) AS total_amount
			FROM FTS_Expense_Type AS extype
			LEFT OUTER JOIN (
			SELECT Expence_type_id AS expense_type_id,SUM(ISNULL(Amount,0)) AS total_amount FROM [FTS_Reimbursement_Application]  
			GROUP BY Expence_type_id,userId,DATEPART(mm,date),StateID,DATEPART(mm,date),DATEPART(YYYY,date) HAVING DATEPART(mm,date)=@month AND DATEPART(YYYY,date)=@year AND userId=@user_id
			)T ON T.expense_type_id=extype.Id 

			SELECT DISTINCT remapp.MapExpenseID,remapp.SubExpenseID,remapp.Visit_type_id AS visit_type_id,vst.Visit_Location AS visit_type,remapp.Expence_type_id AS expense_type_id,
			ISNULL(conv.EligibleRate,0) AS maximum_rate,remapp.Mode_of_travel,ISNULL(conv.EligibleDistance,0) AS maximum_distance,ISNULL(conv.EligibleAmtday,0) as maximum_allowance,
			CONVERT(char(10), remapp.Date,126) AS Date,remapp.From_location,remapp.To_location,remapp.Amount,remapp.Total_distance,remapp.Remark,
			CONVERT(CHAR(19),CONVERT(DATETIME,remapp.Start_date_time,101),120) as Start_date_time,CONVERT(CHAR(19), CONVERT(DATETIME,remapp.End_date_time,101),120) as End_date_time,
			remapp.Location,remapp.Hotel_name,remapp.Food_type,remapp.Fuel_typeId,
			case when isnull(remappverify.status,0)=0 then 'Pending' when isnull(remappverify.status,0)=2 then 'Rejected' else 'Approved'  end as status,
			case when (isnull(remapp.Amount,0) - isnull(remappverify.Amount,0))=0.00 then '0' else isnull(remappverify.Amount,'0') end as approved_amount,
			case when datediff(dd,remapp.Createddate,getdate())<=@Valueeditablelock then 'true' else 'false' end as isEditable,
			fual.FuelType,mode.TravelMode as travel_mode
			FROM [FTS_Reimbursement_Application] AS remapp
			LEFT OUTER JOIN [FTS_Reimbursement_Application_Verified] AS remappverify ON remapp.ApplicationID=remappverify.ApplicationID
			INNER JOIN tbl_master_user AS usr ON usr.user_id=remapp.UserID
			LEFT OUTER JOIN tbl_FTS_MapEmployeeGrade as gradeb on gradeb.Emp_Code=usr.user_contactId 
			LEFT OUTER JOIN FTS_Travel_Conveyance as conv on remapp.Visit_type_id=conv.VisitlocId and remapp.Expence_type_id=conv.ExpenseId and 
			ISNULL(remapp.Mode_of_travel,'0')=isnull(conv.TravelId,'0') and 
			ISNULL(remapp.Fuel_typeId,'0')=isnull(conv.FuelID,'0')  and remapp.StateID=conv.StateId   and conv.EmpgradeId=gradeb.Emp_Grade 
			AND IsActive=1
			LEFT OUTER JOIN FTS_Travel_Mode as mode on mode.Id=remapp.Mode_of_travel
			LEFT OUTER JOIN FTS_Visit_Location as vst on vst.Id=remapp.Visit_type_id
			LEFT OUTER JOIN tbl_FTS_FuelTypes as fual on fual.Id=remapp.Fuel_typeId
			where DATEPART(mm,remapp.date)=@month and remapp.userId=@user_id  and  DATEPART(YYYY,remapp.date)=@year

			SELECT MapExpenseID,VisitlocId,ExpenseID,Bills,ApplictnimageID FROM [FTS_Reimbursement_Applicationbills]
			WHERE DATEPART(mm,date)=@month and userId=@user_id  and  DATEPART(YYYY,Date)=@year
			--Rev 2.0
			ORDER BY Bills
			--End of Rev 2.0
		END
	
	SET NOCOUNT OFF
END