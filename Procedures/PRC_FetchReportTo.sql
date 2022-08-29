IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FetchReportTo]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FetchReportTo] AS' 
END
GO
--EXEC PRC_FetchReportTo @action='ADDNEW',@userid=11706,@firstname='',@shortname=''
ALTER PROCEDURE [dbo].[PRC_FetchReportTo]
(
@action NVARCHAR(MAX)=NULL,
@userid int=null,
@firstname nvarchar(100)=null,
@shortname nvarchar(100)=null
)
AS
/***************************************************************************************************************************************
	1.0		26-08-2021		Tanmoy		Column Name change
	2.0		30-08-2022		Sanchita	New module - FSM - Master - Organization - User Account. 
										Employee with only WD designation will come as Report To from User Account module.
***************************************************************************************************************************************/
BEGIN
	
	IF @action='ADDNEW'
	BEGIN
		--Rev 1.0
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		--End of Rev 1.0
		BEGIN
			select DISTINCT ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
			from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC,FTS_EmployeeShopMap
			 where 
			tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
			and tbl_master_contact.cnt_internalId=FTS_EmployeeShopMap.EMP_INTERNALID 
			and cnt_contactType='EM'  
			and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')
			AND FTS_EmployeeShopMap.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID=@userid)
		END
		ELSE
		BEGIN
			select ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
			from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC	where 
			tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
			and cnt_contactType='EM'  
			and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')
		END
	END
	-- Rev 2.0
	ELSE IF @action='ADDNEW_WD'
	BEGIN
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		BEGIN
			select DISTINCT ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
			from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC,FTS_EmployeeShopMap, tbl_master_designation
			 where 
			tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
			and tbl_master_contact.cnt_internalId=FTS_EmployeeShopMap.EMP_INTERNALID 
			AND tbl_trans_employeeCTC.emp_Designation=tbl_master_designation.deg_ID AND tbl_master_designation.deg_designation='WD'
			and cnt_contactType='EM'  
			and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')
			AND FTS_EmployeeShopMap.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID=@userid)
		END
		ELSE
		BEGIN
			select ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
			from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC, tbl_master_designation	where 
			tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
			AND tbl_trans_employeeCTC.emp_Designation=tbl_master_designation.deg_ID AND tbl_master_designation.deg_designation='WD'
			and cnt_contactType='EM'  
			and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')
		END
	END
	-- End of Rev 2.0
END