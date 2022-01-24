IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[View_Userhiarchy]') AND type in (N'V')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE VIEW [View_Userhiarchy] AS SELECT 1 A' 
END 
GO 

ALTER VIEW [dbo].[View_Userhiarchy]
 --WITH ENCRYPTION
AS
select usr.user_id ,usr.user_name ,empctc.emp_cntId,empctc.emp_reportTo,usr1.user_id as reprtuserid,usr1.user_name as reportmanager,usr.user_loginId contact_no   
from tbl_master_user as usr 
inner join tbl_master_employee as emp on usr.user_contactId=emp.emp_contactId
inner join  (SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id,emp_reportTo FROM tbl_trans_employeeCTC AS cnt  
LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL  
GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,emp_reportTo) as empctc on emp.emp_contactId=empctc.emp_cntId
inner join tbl_master_employee as emp1 on emp1.emp_id=empctc.emp_reportTo
inner join tbl_master_user as usr1 on  usr1.user_contactId=emp1.emp_contactId 
where usr.user_inactive='N'
and empctc.emp_id in (select max(emp_id) from tbl_trans_employeeCTC group by emp_cntId )

GO