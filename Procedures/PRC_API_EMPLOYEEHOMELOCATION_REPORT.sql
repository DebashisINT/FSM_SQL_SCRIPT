IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_API_EMPLOYEEHOMELOCATION_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_API_EMPLOYEEHOMELOCATION_REPORT] AS' 
END
GO

--exec PRC_API_EMPLOYEEHOMELOCATION_REPORT null,null,'LIST','1653'
ALTER PROCEDURE [dbo].[PRC_API_EMPLOYEEHOMELOCATION_REPORT]
(
@Employee varchar(max)=null,
@EmployeeAll varchar(max)=null,
@ACTION	varchar(max)=null,
@EMP_ID bigint=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : TANMOY GHOSH  on 28/03/2019
Module	   : Employee Home Location for API
1.0			v2.0.11		Debashis	26/05/2020		Home location data is showing multiple for a user.Now solved.Refer: 0022370
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @Employee <> ''
		BEGIN
			SET @Employee = REPLACE(''''+@Employee+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@Employee+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF @ACTION='LIST'
		BEGIN
			SET @Strsql='select T.employe_name as Emp_Name,T.Address as address,T.City as cityname,T.State as statename,T.cnt_internalId,
			T.Pincode as pin_code,T.Latitude as Latitude,T.Longitude as longatude,T.CreatedDate as UpdateDate,T.UserID from (
			SELECT empAdd.Address,empAdd.City,empAdd.State,empAdd.Pincode,empAdd.Latitude,empAdd.Longitude,empAdd.UserID,'
			--Rev 1.0
			--convert(varchar,	empAdd.CreatedDate, 103) as CreatedDate,mcont.cnt_firstName+'' ''+mcont.cnt_middleName+'' ''+mcont.cnt_lastName as employe_name,mcont.cnt_internalId
			SET @Strsql+='CONVERT(VARCHAR,empAdd.CreatedDate, 103) AS CreatedDate,'
			SET @Strsql+='ISNULL(mcont.cnt_firstName,'''')+'' ''+ISNULL(mcont.cnt_middleName,'''')+(CASE WHEN ISNULL(mcont.cnt_middleName,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(mcont.cnt_lastName,'''') AS employe_name,'
			SET @Strsql+='mcont.cnt_internalId '
			--End of Rev 1.0
			SET @Strsql+='FROM tbl_FTS_userhomeaddress as empAdd inner join tbl_master_user empMast on empMast.user_id=empAdd.UserID
			inner join tbl_master_contact as mcont on mcont.cnt_internalId=empMast.user_contactId) as T'
			if(ISNULL(@EmployeeAll,'')<>'All')
		           BEGIN
				if(isnull(@Employee,'')<>'' )
			          BEGIN
					SET @Strsql+=' WHERE EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=T.cnt_internalId) '
				   END
			    END
		END

	IF @ACTION='DETAILS'
		BEGIN
			SET @Strsql='select T.employe_name as Emp_Name,T.Address as address,T.City as cityname,T.State as statename,T.cnt_internalId,
			T.Pincode as pin_code,T.Latitude as Latitude,T.Longitude as longatude,T.CreatedDate as UpdateDate,T.UserID,T.StateCode,T.city_id from (
			SELECT empAdd.Address,empAdd.City,empAdd.State,empAdd.Pincode,empAdd.Latitude,empAdd.Longitude,empAdd.UserID,
			convert(varchar(50),empAdd.CreatedDate, 103) as CreatedDate,mcont.cnt_firstName+'' ''+mcont.cnt_middleName+'' ''+mcont.cnt_lastName as employe_name,mcont.cnt_internalId,
			SM.id as StateCode,CM.city_id
			FROM tbl_FTS_userhomeaddress as empAdd inner join tbl_master_user empMast on empMast.user_id=empAdd.UserID
			inner join tbl_master_contact as mcont on mcont.cnt_internalId=empMast.user_contactId
			LEFT OUTER JOIN tbl_master_state SM ON UPPER(SM.state)=UPPER(empAdd.State)
			LEFT OUTER JOIN tbl_master_CITY CM ON UPPER(CM.city_name)=UPPER(empAdd.City)
			) as T WHERE T.UserID='+str(@EMP_ID)+''
			
		END
	
	--select @Strsql
	exec sp_executesql @Strsql
	DROP TABLE #EMPLOYEE_LIST

	SET NOCOUNT OFF
END