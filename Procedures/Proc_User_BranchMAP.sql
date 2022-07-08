
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_User_BranchMAP]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_User_BranchMAP] AS'  
 END 
 GO 
ALTER Proc [dbo].[Proc_User_BranchMAP]
(
@EMPID varchar(100)
)  
As
/******************************************************************************************************************************
1.0			Pratik		01-07-2022			create sp 
******************************************************************************************************************************/
BEGIN
	
		select *  from
		(
		
		select branch_description,branch_id,case when isnull(empmap.EmployeeId,'')='' then cast(0 as bit) else cast(1 as bit) end as IsChecked,
		'Success' as status from tbl_master_branch as BRNCH  
		LEFT OUTER JOIN FTS_EmployeeBranchMap as empmap on BRNCH.branch_id=empmap.BranchId
		and empmap.EmployeeId=@EMPID
		)T	order by T.branch_description
	
END


