
--PRC_FTSREIMBURSEMENTLIST_VIEW_REPORT 'JAN','1700'
--PRC_FTSREIMBURSEMENTLIST_VIEW_REPORT 'JAN','1654'
--PRC_FTSREIMBURSEMENTLIST_VIEW_REPORT 'FEB',1677


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSREIMBURSEMENTLIST_VIEW_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSREIMBURSEMENTLIST_VIEW_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSREIMBURSEMENTLIST_VIEW_REPORT]
(
@MONTH NVARCHAR(3)=NULL,
@USERID INT=NULL,
--Rev 2.0
@YEAR NVARCHAR(10)=NULL
--End of Rev 2.0
)  
AS
/****************************************************************************************************************************************************************************
Written by : Subhra Mukherjee on 29/01/2019
Module	   : Reimbursement View List
RAV.status=1 means Approved  RAV.status=2 then 'Rejected'

2.0		Tanmoy			v2.0.4		02/01/2020		Year field required in the Monthly report.Refer: 0021574
3.0		Pratik						29/11/2021		Changed the logic for UserId Filter
4.0		Sanchita		V2.0.40		20-04-2023		In TRAVELLING ALLOWANCE -- Approve/Reject Page: One Coloumn('Confirm/Reject') required 
													before 'Approve/Reject' coloumn. refer: 25809
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	DECLARE @MONTHNAME NVARCHAR(3),@MONTHNO INT=0,@FROMDATE NVARCHAR(10),@TODATE NVARCHAR(10)
	SET @MONTHNAME=@MONTH
	SET @MONTHNO=DATEPART(MM,@MONTHNAME+'01 1900')
	--Rev 2.0
	--SET @FROMDATE=CONVERT(VARCHAR(10),DATEADD(MONTH, CONVERT(INT,@MONTHNO) - 1, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)),120)
	--SET @TODATE=CONVERT(VARCHAR(10),DATEADD(DAY, -1, DATEADD(MONTH, CONVERT(INT,@MONTHNO), DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0))),120)
	SET @FROMDATE=CONVERT(VARCHAR(10),DATEADD(MONTH, CONVERT(INT,@MONTHNO) - 1, @YEAR),120)
	SET @TODATE=CONVERT(VARCHAR(10),DATEADD(DAY, -1, DATEADD(MONTH, CONVERT(INT,@MONTHNO), @YEAR)),120)
	--End of Rev 2.0

	--SET @Strsql='select  ROW_NUMBER() OVER(ORDER BY h.Date) AS SEQ,h.ApplicationID,h.MapExpenseID,CONVERT(NVARCHAR(10),h.Date,105) as Date,U.user_contactId,
	--isnull(cnt_firstName,'''')+'' ''+isnull(cnt_middleName,'''')+'' ''+isnull(cnt_lastName,'''') as ''Name'',deg.deg_designation,conv.Employee_Grade, '
	--SET @Strsql+='h.Visit_type_id,loc.Visit_Location,h.Expence_type_id,ty.Expense_Type,h.Mode_of_travel,mde.TravelMode,h.Fuel_typeId,f.FuelType  '
	--SET @Strsql+=',h.From_location,h.To_location,h.Hotel_name,h.Remark '
	--SET @Strsql+=',isnull(conv.EligibleDistance,0) as ''Eligible_Dist'',isnull(conv.EligibleAmtday,0) as ''Eligible_Amt'',isnull(h.Total_distance,0) as ''Applied_Dist'' '
	--SET @Strsql+=',isnull(h.Amount,0) as ''Applied_Amt'',isnull(h.Total_distance,0) as ''Apprvd_Dist'',isnull(h.Amount,0) as ''Apprvd_Amt'' '

	--SET @Strsql+=' from  FTS_Reimbursement_Application h '
	--SET @Strsql+=' left outer join FTS_Visit_Location loc on loc.Id=h.Visit_type_id '
	--SET @Strsql+=' left outer join FTS_Expense_Type ty on ty.Id=h.Expence_type_id '
	--SET @Strsql+=' left outer join FTS_Travel_Mode mde on mde.Id=h.Mode_of_travel '
	--SET @Strsql+=' left outer join tbl_FTS_FuelTypes f on f.Id=h.Fuel_typeId '
	--SET @Strsql+=' left outer join tbl_master_designation deg on h.Designation_ID=deg.deg_id '
	--SET @Strsql+=' INNER JOIN TBL_MASTER_USER U ON U.user_id=H.UserID '
	--SET @Strsql+=' INNER JOIN tbl_master_contact cn on cn.cnt_internalId=U.user_contactId '
	--SET @Strsql+='Inner join (select g.Employee_Grade,cv.VisitlocId,cv.EmpgradeId,cv.ExpenseId,cv.StateId,cv.DesignationId,cv.TravelId,cv.EligibleDistance,cv.EligibleAmtday,cv.IsActive,cv.FuelID '
	--SET @Strsql+=' from FTS_Travel_Conveyance cv '
	--SET @Strsql+=' inner join FTS_Employee_Grade g on cv.EmpgradeId=g.Id) as conv on conv.VisitlocId=h.Visit_type_id and conv.ExpenseId=h.Expence_type_id and conv.StateId=h.StateID'
	--SET @Strsql+=' and conv.DesignationId=h.Designation_ID and isnull(conv.TravelId,0)=isnull(h.Mode_of_travel,0) and isnull(conv.FuelID,0)=isnull(h.Fuel_typeId,0) and IsActive=1'
	--SET @Strsql+=' where h.UserID='+STR(@USERID)+' '
	--SET @Strsql+=' and CONVERT(NVARCHAR(10),h.Date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	----SELECT @Strsql
	--EXEC SP_EXECUTESQL @Strsql

	select ROW_NUMBER() OVER(ORDER BY h.Date) AS SEQ,CONVERT(VARCHAR(250),h.ApplicationID) AS ApplicationID,h.MapExpenseID,CONVERT(NVARCHAR(10),h.Date,105) as Date,U.user_contactId,
		isnull(cnt_firstName,'')+' '+isnull(cnt_middleName,'')+' '+isnull(cnt_lastName,'') as 'Name',deg.deg_designation,conv.Employee_Grade,		
		h.Visit_type_id,loc.Visit_Location,h.Expence_type_id,ty.Expense_Type,h.Mode_of_travel,mde.TravelMode,h.Fuel_typeId,f.FuelType  ,h.From_location,h.To_location,h.Hotel_name,
		h.Remark,RAV.Remark as 'App_Rej_Remarks'
		,isnull(conv.EligibleDistance,0) as 'Eligible_Dist',isnull(conv.EligibleAmtday,0) as 'Eligible_Amt'
		,isnull(h.Total_distance,0) as 'Applied_Dist' , isnull(h.Amount,0) 
		as 'Applied_Amt',CASE WHEN RAV.Amount IS NULL THEN isnull(h.Total_distance,0) ELSE RAV.Total_distance END as 'Apprvd_Dist',CASE WHEN RAV.Amount IS NULL 
		THEN isnull(h.Amount,0) ELSE RAV.Amount	END as 'Apprvd_Amt',CONVERT(NVARCHAR(10),getdate(),105) as 'ToDate'
		,CASE WHEN DATEADD(d, (select CAST(isnull(Value,0) AS INT) from FTS_APP_CONFIG_SETTINGS where [Key]='Allow_Approved_Lock_Days'), h.Createddate) <getdate() THEN 1 ELSE 0 END 'is_ApprovedPermision'
		,CASE WHEN ISNULL(AB.MapExpenseID,'')<>'' THEN 1 ELSE 0 END as 'is_Image'
		,(select cast(isnull(Value,0) as int) from FTS_APP_CONFIG_SETTINGS where [Key]='Allow_Approved_Lock_Days') as 'Settings_Allow_Approved_days'
		,'Entered on: '+CONVERT(NVARCHAR(10),h.Createddate,105)+', Today is: '+CONVERT(NVARCHAR(10),getdate(),105)+'. You can approve/reject only on/after '
						+CONVERT(NVARCHAR(10),DATEADD(d, (select CAST(isnull(Value+1,0) AS INT) from FTS_APP_CONFIG_SETTINGS 
									where [Key]='Allow_Approved_Lock_Days'), h.Createddate),105) as 'Checked_Message'
		,case when RAV.status=1 then 'Approved' when RAV.status=2 then 'Rejected' else 'Pending' end status
		-- Rev 4.0
		, h.Conf_Rej_Remarks 
		-- End of Rev 4.0
		from  FTS_Reimbursement_Application h 
		LEFT OUTER JOIN FTS_Visit_Location loc on loc.Id=h.Visit_type_id
		LEFT OUTER JOIN FTS_Expense_Type ty on ty.Id=h.Expence_type_id 
		LEFT OUTER JOIN FTS_Travel_Mode mde on mde.Id=h.Mode_of_travel  
		LEFT OUTER JOIN tbl_FTS_FuelTypes f on f.Id=h.Fuel_typeId  
		LEFT OUTER JOIN tbl_master_designation deg on h.Designation_ID=deg.deg_id 
		INNER JOIN TBL_MASTER_USER U ON U.user_id=H.UserID  
		INNER JOIN tbl_master_contact cn on cn.cnt_internalId=U.user_contactId 
		LEFT OUTER JOIN 
		(select g.Employee_Grade,cv.VisitlocId,cv.EmpgradeId,cv.ExpenseId,cv.StateId,cv.DesignationId,cv.TravelId,cv.EligibleDistance,
		case when (isnull(cv.EligibleDistance,0)*isnull(cv.EligibleRate,0))=0 then  cv.EligibleAmtday else (isnull(cv.EligibleDistance,0)*isnull(cv.EligibleRate,0)) end as EligibleAmtday,
		cv.IsActive,cv.FuelID  
		from FTS_Travel_Conveyance cv  inner join FTS_Employee_Grade g on cv.EmpgradeId=g.Id) as conv on conv.VisitlocId=h.Visit_type_id and conv.ExpenseId=h.Expence_type_id and conv.StateId=h.StateID  
		and ISNULL(conv.TravelId,0)=ISNULL(h.Mode_of_travel,0)
		and isnull(conv.FuelID,0)=isnull(h.Fuel_typeId,0) 
		and IsActive=1 
		LEFT OUTER JOIN FTS_Reimbursement_Application_Verified RAV ON RAV.ApplicationID = h.ApplicationID
		INNER JOIN 
		(
		SELECT add_cntId,add_state  FROM  tbl_master_address  where add_addressType='Office'
		)S on S.add_cntId=cn.cnt_internalId
		LEFT OUTER JOIN tbl_master_state as STAT on STAT.id=S.add_state and STAT.id=conv.StateId
		--rev 3.0
		--INNER JOIN  tbl_FTS_MapEmployeeGrade as grade on grade.Emp_Code=cn.cnt_internalId  and grade.Emp_Grade=conv.EmpgradeId
		Left JOIN  tbl_FTS_MapEmployeeGrade as grade on grade.Emp_Code=cn.cnt_internalId  and grade.Emp_Grade=conv.EmpgradeId
		--End of rev 3.0
		LEFT OUTER JOIN 
		(select distinct MapExpenseID from FTS_Reimbursement_Applicationbills) AB on AB.MapExpenseID=h.MapExpenseID

		where  CONVERT(NVARCHAR(10),h.Date,120) BETWEEN CONVERT(NVARCHAR(10),@FROMDATE,120) AND CONVERT(NVARCHAR(10),@TODATE,120) 
		--REV 3.0
		--and U.user_id=@USERID
		and h.UserID=@USERID
		--End of rev 3.0
END
