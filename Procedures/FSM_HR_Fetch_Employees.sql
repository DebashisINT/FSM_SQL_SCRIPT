IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FSM_HR_Fetch_Employees]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FSM_HR_Fetch_Employees] AS' 
END
GO


--exec [FSM_HR_Fetch_Employees] '1900-01-01','9999-12-31',10,1,'','','','S','N','','11706'
--exec [FSM_HR_Fetch_Employees] '1900-01-01','9999-12-31',10,1,'','','','S','N','','378'
--exec HR_Fetch_Employees '6/1/2012 12:00:00 AM','10/26/2012 12:00:00 AM','10','1','','','','S','N','',11706
ALTER PROCEDURE [dbo].[FSM_HR_Fetch_Employees]
@FromJoinDate Varchar(25),
@ToJoinDate Varchar(25),
@PageSize int,
@PageNumber int,
@SearchString Varchar(100),
@SearchBy Char(2),
@FindOption int,
@ExportType Char(1),--'S','E'
@DevXFilterOn Char(1),--'Y','N'
@DevXFilterString Varchar(4000)
,@User_id int=null
-- exec HR_Fetch_Employees '6/1/2012 12:00:00 AM','10/26/2012 12:00:00 AM','10','1','','','','S','N','',11706
AS
/***************************************************************************************************************************************
	1.0_OLD		26-08-2021		Tanmoy		Column Name change
	2.0_OLD		08-03-2022		Sanchita	V2.2.29		One field required "Other ID" in employee master. [Character Type 200]. Refer: 24736

	1.0		17-03-2022		Swati		Mantise ID:0024752: Optimize FSM Employee Master 
	2.0		04-04-2022		Swati		Query optimise of employee master MantieID:-24792
	3.0		22-04-2022		Sanchita	Employee Master optimization correction done.
***************************************************************************************************************************************/
BEGIN
  Declare @DSql nVarchar(Max),@DSql1 nVarchar(Max), @DSql_SearchBy nVarchar(2000)

    
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
	
	BEGIN
		DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@User_id)		
		CREATE TABLE #EMPHR
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)

		CREATE TABLE #EMPHR_EDIT
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)
		
		INSERT INTO #EMPHR
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
		FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
		;with cte as(select	
		EMPCODE,RPTTOEMPCODE
		from #EMPHR 
		where EMPCODE IS NULL OR EMPCODE=@empcode  
		union all
		select	
		a.EMPCODE,a.RPTTOEMPCODE
		from #EMPHR a
		join cte b
		on a.RPTTOEMPCODE = b.EMPCODE
		) 
		INSERT INTO #EMPHR_EDIT
		select EMPCODE,RPTTOEMPCODE  from cte 
	END

  --This Query Will Be Inserted in Main Queries Where There is Any Filtering Option Like EN--Employee Name or EC--Employee Code
  Set @DSql_SearchBy=''
  if(@SearchBy='EN')
  Begin
    Set @DSql_SearchBy=' And Emp_ContactID in 
    (Select cnt_internalId from tbl_master_contact where 
    Ltrim(Rtrim(isnull(cnt_firstName,'''')))+'' ''+Ltrim(Rtrim(isnull(cnt_middleName,'''')))+'' ''
    + Ltrim(Rtrim(isnull(cnt_lastName,''''))) '
    
    if(@FindOption=0) Set @DSql_SearchBy=@DSql_SearchBy+'like '''+@SearchString+'%'')'
    else Set @DSql_SearchBy=@DSql_SearchBy+'='''+@SearchString+''')'
  End
    
  if(@SearchBy='EC')
  Begin
    Set @DSql_SearchBy=' And emp_uniqueCode '
    
    if(@FindOption=0) Set @DSql_SearchBy=@DSql_SearchBy+'like '''+@SearchString+'%'''
    else Set @DSql_SearchBy=@DSql_SearchBy+'='''+@SearchString+''''
  End

  /*REV 2.0 start*/
  --Find All Email Ids And Insert into #Email Table WithOut Repeating ContactID
  --Create Table #Email(Email_ContactID Varchar(20),Email_Ids Varchar(100))

  --Set @DSql='Select * into #Emp_Eml_Join From
  --(Select ContactID,Email from 
  --(Select emp_contactId ContactID From tbl_master_employee Where 
  --isnull(emp_dateofLeaving,''1900-01-01 00:00:00.000'')=''1900-01-01 00:00:00.000''
  --and (emp_dateofJoining Between '''+@FromJoinDate+''' and '''+@ToJoinDate+''')'
  
  --Set @DSql=@DSql+@DSql_SearchBy
  
  --Set @DSql=@DSql+') Emp
  --Left Outer Join
  --(Select eml_cntId,Ltrim(Rtrim(eml_email)) Email from tbl_master_email
  --Where Len(eml_email)>0 and LTRIM(Rtrim(isnull(eml_email,'''')))!='''') Eml
  --on eml_cntId=ContactID) Emp_Eml

  --Insert into #Email 
  --SELECT DISTINCT ContactID,C.Email
  --FROM #Emp_Eml_Join
  --CROSS APPLY
  --( 
  --SELECT Email + '' ''
  --FROM #Emp_Eml_Join E
  --WHERE E.ContactID=#Emp_Eml_Join.ContactID
  --FOR XML PATH('''')
  --) C(Email)
  
  --Drop Table #Emp_Eml_Join'

  --Exec sp_executesql @Dsql
 
  --print @Dsql
  -----------------------------------------------------------------------------------------


  ---Find All Phone mobile Number And Insert into #PhoneMobile Table WithOut Repeating ContactID
  --Create Table #PhoneMobile(PhoneMobile_ContactID Varchar(20),PhoneMobile_Numbers Varchar(100))

  --Set @DSql='Select * into #Emp_Phf_Join From
  --(Select ContactID,PhoneNumber from 
  --(Select emp_contactId ContactID From tbl_master_employee Where 
  --isnull(emp_dateofLeaving,''1900-01-01 00:00:00.000'')=''1900-01-01 00:00:00.000''
  --and (emp_dateofJoining Between '''+@FromJoinDate+''' and '''+@ToJoinDate+''')'
  
  --Set @DSql=@DSql+@DSql_SearchBy
  
  --Set @DSql=@DSql+') Emp
  --Left Outer Join
  --(Select phf_cntId,Ltrim(Rtrim(phf_phoneNumber)) PhoneNumber from tbl_master_phonefax
  --Where Len(phf_phoneNumber)>0 and LTRIM(Rtrim(isnull(phf_phoneNumber,'''')))!='''') phf
  --on phf_cntId=ContactID) Emp_Eml

  --Insert into #PhoneMobile 
  --SELECT DISTINCT ContactID,C.PhoneNumber
  --FROM #Emp_Phf_Join
  --CROSS APPLY
  --( 
  --SELECT PhoneNumber + '' ''
  --FROM #Emp_Phf_Join E
  --WHERE E.ContactID=#Emp_Phf_Join.ContactID
  --FOR XML PATH('''')
  --) C(PhoneNumber)
  
  --Drop Table #Emp_Phf_Join'

  --Exec sp_executesql @Dsql
    --Rev 2.0 close/
  --Debugging Start
    --print @Dsql
    --Select * into Email From #Email
    --Select * into PhoneMobile From #PhoneMobile
  --End Debugging Start
  
  -----------------------------------------------------------------------------------------
  
 IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FSMEmployee_Master') AND TYPE IN (N'U'))
		BEGIN
			-- Rev 3.0
			--CREATE TABLE FTS_Final_Display
			CREATE TABLE FSMEmployee_Master
			-- End of Rev 3.0
			(
			  Employee_Grade varchar(100),SRLNO int,ContactID Varchar(100),Code Varchar(100),Name Varchar(500),FirstName Varchar(200),MiddleName Varchar(200),
			  LastName Varchar(200),cnt_id int,BranchName Varchar(500),Department Varchar(200),DepartmentID int,CTC Varchar(500),
			  ReportTo Varchar(500),ReportToID Varchar(500) ,DOJ Varchar(200),CreatedBy Varchar(200),Designation Varchar(500),
			  DesignationID Varchar(200),Company Varchar(200),OrganizationID Varchar(200),Email_Ids Varchar(250),
			  PhoneMobile_Numbers Varchar(100),FatherName Varchar(500),PanCardNumber Varchar(100), cnt_OtherID varchar(200)
			  ,USERID int,CreateDate datetime,LastModifyDate datetime
			)
			-- Rev 3.0
			--CREATE NONCLUSTERED INDEX IX1 ON FTS_Final_Display (Code)
			CREATE NONCLUSTERED INDEX IX1 ON FSMEmployee_Master (Code)
			-- End of Rev 3.0
		END
	-- Rev 3.0
	--DELETE FROM FTS_Final_Display WHERE USERID=@User_id
	DELETE FROM FSMEmployee_Master WHERE USERID=@User_id
	-- End of Rev 3.0
	/*Rev 2.0 start*/
	Set @DSql='Insert into FSMEmployee_Master
  (
	USERID,Employee_Grade,SRLNO,ContactID,Code,Name,FirstName,MiddleName,LastName,cnt_id,BranchName,Department,DepartmentID,CTC,ReportTo,ReportToID,
	DOJ,CreatedBy,Designation,DesignationID,Company,OrganizationID,Email_Ids,PhoneMobile_Numbers,FatherName,PanCardNumber,cnt_OtherID
	
  )
	Select '+convert(varchar(50),@User_id) +',empgrade.Employee_Grade,
	ROW_NUMBER()  OVER (ORDER BY Ltrim(Rtrim(isnull(b.cnt_firstName,'''')))+'' ''+Ltrim(Rtrim(isnull(b.cnt_middleName,'''')))+'' ''+ Ltrim(Rtrim(isnull(b.cnt_lastName,''''))),a.emp_contactId desc) as SRLNO,
	a.emp_contactId ContactID,a.emp_uniqueCode Code,Ltrim(Rtrim(isnull(b.cnt_firstName,'''')))+'' ''+Ltrim(Rtrim(isnull(b.cnt_middleName,'''')))+'' ''+ Ltrim(Rtrim(isnull(b.cnt_lastName,''''))) Name ,
	Ltrim(Rtrim(isnull(b.cnt_firstName,''''))) FirstName,Ltrim(Rtrim(isnull(b.cnt_middleName,''''))) MiddleName,Ltrim(Rtrim(isnull(b.cnt_lastName,''''))) LastName,b.cnt_id
	,LTRIM(Rtrim(Branch_Description))+''[''+LTRIM(Rtrim(Branch_Code))+''] '' AS BranchName,
	-- CTC.Department Department
	EmpDesg.Department Department,CTC.DepartmentID DepartmentID
	,CTC.emp_currentCTC CTC,CTC.REPORTTO ReportTo
	,CTC.emp_reportTo ReportToID,Convert(Varchar(11),a.emp_dateofJoining,106) DOJ,Ltrim(Rtrim(isnull(User_Name,'''')))+'' [''+isnull(user_loginId,'''') +'']'' AS CreatedBy
	--,CTC.deg_designation Designation,CTC.emp_designation DesignationID
	,EmpDesg.EmpDesgignation Designation,EmpDesg.deg_id DesignationID
	, CTC.cmp_Name Company,CTC.emp_organization OrganizationID,Ltrim(Rtrim(eml.eml_email)) Email_Ids
	,Ltrim(Rtrim(phf.phf_phoneNumber)) PhoneMobile_Numbers,femrel_memberName FatherName,crg_Number PanCardNumber,a.cnt_OtherID
	From tbl_master_employee a
	INNER JOIN tbl_master_contact b ON a.emp_contactId=b.Cnt_InternalID and b.cnt_contactType=''EM''
	--INNER JOIN tbl_master_User USR ON a.emp_contactId=USR.USER_contactid
	LEFT OUTER JOIN tbl_master_User USR ON a.emp_contactId=USR.USER_contactid
	INNER JOIN tbl_master_branch BR ON  B.cnt_branchid=BR.branch_id
	--LEFT OUTER JOIN tbl_trans_employeeCTC CTC ON a.emp_contactId=CTC.emp_cntId
	--LEFT OUTER JOIN tbl_master_costCenter cost ON CTC.emp_Department=cost.cost_id
	--LEFT OUTER JOIN tbl_master_designation deg ON CTC.emp_designation=deg.deg_id
	--LEFT OUTER JOIN tbl_master_company cmp ON emp_organization=cmp.cmp_id
	LEFT OUTER JOIN 
	(
		SELECT Ltrim(Rtrim(DESG.Department))Department,EMPCTC.emp_Department DepartmentID,EMPCTC.emp_currentCTC,
		ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''')+''[''+EMP.emp_uniqueCode +'']'' AS REPORTTO
		,EMPCTC.emp_reportTo,DESG.deg_designation ,EMPCTC.emp_designation ,EMPCTC.emp_organization,
		EMPCTC.emp_cntId,CNT.cnt_internalId,DESG.deg_designation AS RPTTODESG ,desg.cmp_Name
		FROM tbl_master_employee EMP 
		INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo 
		INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=EMP.emp_contactId and CNT.cnt_contactType=''EM''
		INNER JOIN 
		(
			SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id,Ltrim(Rtrim(cost.cost_description))Department 
			,Ltrim(Rtrim(cmp.cmp_Name)) cmp_Name
			FROM tbl_trans_employeeCTC as cnt 
			LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation 
			LEFT OUTER JOIN tbl_master_costCenter cost ON cost.cost_id=cnt.emp_Department
			LEFT OUTER JOIN tbl_master_company cmp ON cmp.cmp_id=cnt.emp_organization
			WHERE cnt.emp_effectiveuntil IS NULL 
			GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,cost.cost_description,cmp.cmp_Name
		) DESG ON DESG.emp_cntId=EMP.emp_contactId 
		WHERE EMPCTC.emp_effectiveuntil IS NULL
	) CTC ON CTC.emp_cntId=b.cnt_internalId
	LEFT OUTER JOIN 
	(
		SELECT cnt.emp_cntId,desg.deg_designation EmpDesgignation,MAX(emp_id) as emp_id,desg.deg_id,Ltrim(Rtrim(cost.cost_description))Department    
		,Ltrim(Rtrim(cmp.cmp_Name)) cmp_Name    FROM tbl_trans_employeeCTC as cnt     
		LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation     
		LEFT OUTER JOIN tbl_master_costCenter cost ON cost.cost_id=cnt.emp_Department   
		LEFT OUTER JOIN tbl_master_company cmp ON cmp.cmp_id=cnt.emp_organization    
		WHERE cnt.emp_effectiveuntil IS NULL     
		GROUP BY emp_cntId,desg.deg_designation,desg.deg_id,cost.cost_description,cmp.cmp_Name  
	) EmpDesg ON EmpDesg.emp_cntId=a.emp_contactId
	LEFT OUTER JOIN tbl_master_email eml ON a.emp_contactId=eml.eml_cntId And Len(eml.eml_email)>0 and LTRIM(Rtrim(isnull(eml.eml_email,'''')))!=''''
	LEFT OUTER JOIN tbl_master_phonefax phf ON a.emp_contactId=phf.phf_cntId And Len(phf.phf_phoneNumber)>0 and LTRIM(Rtrim(isnull(phf.phf_phoneNumber,'''')))!=''''
	LEFT OUTER JOIN tbl_master_contactFamilyRelationship femrel ON a.emp_contactId=femrel.femrel_cntId 
	AND femrel_relationId=(Select fam_id from tbl_master_familyRelationship	where Ltrim(Rtrim(fam_familyRelationship))=''FATHER'')
	LEFT OUTER JOIN tbl_master_contactRegistration crg ON  a.emp_contactId=crg.crg_cntId AND crg.crg_type=''Pancard''
	LEFT OUTER JOIN  tbl_FTS_MapEmployeeGrade grad ON a.emp_contactId= grad.Emp_Code
	LEFT OUTER JOIN FTS_Employee_Grade as empgrade ON grad.Emp_Grade=empgrade.Id '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
			BEGIN
				Set @DSql=@DSql+'INNER JOIN #EMPHR_EDIT ON emp_contactId=EMPCODE '
			END
	
	Set @DSql=@DSql+'WHERE isnull(a.emp_dateofLeaving,''1900-01-01 00:00:00.000'')=''1900-01-01 00:00:00.000'' and (a.emp_dateofJoining Between '''+'1900-01-01'+''' and '''+'9999-12-31'+''') '
	--  IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	--		BEGIN
	--			Set @DSql=@DSql+'INNER JOIN #EMPHR_EDIT ON ContactID=EMPCODE '
	--		END
	----Set @DSql=@DSql+'  '
	--select @DSql
   Exec sp_executesql @DSql
 
--  Set @DSql='Insert into FTS_Final_Display
--  (
--	USERID,Employee_Grade,SRLNO,ContactID,Code,Name,FirstName,MiddleName,LastName,cnt_id,BranchName,Department,DepartmentID,CTC,ReportTo,ReportToID,
--	DOJ,CreatedBy,Designation,DesignationID,Company,OrganizationID,Email_Ids,PhoneMobile_Numbers,FatherName,PanCardNumber,cnt_OtherID
	
--  )

--  SELECT  '+convert(varchar(50),@User_id) +',empgrade.Employee_Grade,TBL.* FROM (
--    Select  ROW_NUMBER()  OVER (ORDER BY Name,ContactID desc) as SRLNO,ContactID,Code,Name,FirstName,MiddleName,LastName,cnt_id,
--  BranchName,Department,DepartmentID,CTC,ReportTo,ReportToID,DOJ,CreatedBy,Designation,
--  DesignationID,Company,OrganizationID,Email_Ids,PhoneMobile_Numbers,FatherName,PanCardNumber,cnt_OtherID
 
--   from
   
--  (Select ContactID,Code,Name,FirstName,MiddleName,LastName,cnt_id,BranchName,Department,DepartmentID,CTC,ReportTo,ReportToID,DOJ,CreatedBy,cnt_OtherID,Designation,
--  DesignationID,Company,OrganizationID,Email_Ids,PhoneMobile_Numbers,FatherName from 
  
--  (Select ContactID,Code,Name,FirstName,MiddleName,LastName,cnt_id,BranchName,Department,DepartmentID,CTC,ReportTo,ReportToID,DOJ,CreatedBy,cnt_OtherID,Designation,
--  DesignationID,Company,OrganizationID,Email_Ids,PhoneMobile_Numbers from 
  
--  (Select ContactID,Code,Name,FirstName,MiddleName,LastName,cnt_id,BranchName,Department,DepartmentID,CTC,ReportTo,ReportToID,DOJ,CreatedBy,cnt_OtherID,Designation,
--  DesignationID,Company,OrganizationID,Email_Ids  from 
  
--  (Select ContactID,Code,Name,FirstName,MiddleName,LastName,cnt_id,BranchName,Department,DepartmentID,CTC,ReportTo,ReportToID,DOJ,CreatedBy,cnt_OtherID,Designation,
--  DesignationID,Company,OrganizationID
--   From
--  (Select ContactID,LTRIM(Rtrim(emp_uniqueCode)) Code,Ltrim(Rtrim(Name)) Name,BranchName,DOJ,CreatedBy,cnt_OtherID,FirstName,MiddleName,LastName,cnt_id from 
--  (Select emp_contactId ContactID,emp_uniqueCode,Convert(Varchar(11),emp_dateofJoining,106) DOJ,
--  (Select Ltrim(Rtrim(isnull(User_Name,'''')))+'' [''+isnull(user_loginId,'''') +'']'' from tbl_master_User 
--  Where USER_ID=tbl_master_employee.CreateUser) CreatedBy,cnt_OtherID
--  from tbl_master_employee Where 
--  isnull(emp_dateofLeaving,''1900-01-01 00:00:00.000'')=''1900-01-01 00:00:00.000''
--  and (emp_dateofJoining Between '''+'1900-01-01'+''' and '''+'9999-12-31'+''')'
  
--  Set @DSql=@DSql+@DSql_SearchBy
  
--  Set @DSql=@DSql+') Emp
--  Left Outer Join
--  (Select cnt_id,Cnt_InternalID,Ltrim(Rtrim(isnull(cnt_firstName,''''))) FirstName,Ltrim(Rtrim(isnull(cnt_middleName,''''))) MiddleName,
--  Ltrim(Rtrim(isnull(cnt_lastName,''''))) LastName,
--  Ltrim(Rtrim(isnull(cnt_firstName,'''')))+'' ''+Ltrim(Rtrim(isnull(cnt_middleName,'''')))+'' ''+ Ltrim(Rtrim(isnull(cnt_lastName,''''))) Name ,
--  (Select LTRIM(Rtrim(Branch_Description))+''[''+LTRIM(Rtrim(Branch_Code))+''] '' from tbl_master_branch Where branch_id=cnt_branchid) BranchName
--  from tbl_master_contact) Cnt
--  On cnt_internalId=ContactID) Emp_Cnt
--  Left Outer Join
--  (Select emp_CntID,emp_Department DepartmentID,
--  (Select Ltrim(Rtrim(cost_description)) from tbl_master_costCenter Where cost_id=emp_Department) Department,
--  emp_reportTo ReportToID,
--  (Select 
--  (Select Ltrim(Rtrim(isnull(cnt_firstName,'''')))+'' ''+Ltrim(Rtrim(isnull(cnt_middleName,'''')))+
--  '' ''+ Ltrim(Rtrim(isnull(cnt_lastName,'''')))+'' [''+emp_uniqueCode +'']''
--  from tbl_Master_Contact Where Cnt_InternaliD=emp_contactId) 
--  From tbl_master_employee Where emp_id=emp_reportTo) ReportTo,
--  emp_designation DesignationID,
--  (Select deg_designation from  tbl_master_designation Where deg_id=emp_designation) Designation,
--  emp_organization OrganizationID,
--  (Select Ltrim(Rtrim(cmp_Name)) From tbl_master_company Where cmp_id=emp_organization) Company,
--  emp_currentCTC CTC
--  from tbl_trans_employeeCTC Where 
--  isnull(emp_effectiveuntil,''1900-01-01 00:00:00.000'')=''1900-01-01 00:00:00.000'') EmpCTC
--  On emp_cntId=ContactID) Emp_Cnt_EmpCTC
--  Left Outer Join
--  (Select Email_ContactID,Email_Ids from #Email) eml
--  On Email_ContactID=ContactID collate SQL_Latin1_General_CP1_CI_AS) Emp_Cnt_EmpCTC_eml


--  Left Outer Join
--  (Select PhoneMobile_ContactID,PhoneMobile_Numbers from #PhoneMobile) phf
--  ON PhoneMobile_ContactID=ContactID collate SQL_Latin1_General_CP1_CI_AS)Emp_Cnt_EmpCTC_eml_phf
--  Left Outer Join
--  (Select femrel_cntid,femrel_memberName FatherName from tbl_master_contactFamilyRelationship
--  Where femrel_relationId=(Select fam_id from tbl_master_familyRelationship 
--  where Ltrim(Rtrim(fam_familyRelationship))=''FATHER'')) femrel
--  On femrel_cntId=ContactID) Emp_Cnt_EmpCTC_eml_phf_femrel
--  Left Outer Join
--  (Select crg_cntId,crg_Number PanCardNumber from tbl_master_contactRegistration Where crg_type=''Pancard'') crg
--  On ContactID=crg_cntId
--  )
-- TBL 

--LEFT OUTER JOIN  tbl_FTS_MapEmployeeGrade as grad on grad.Emp_Code=TBL.ContactID

--LEFT OUTER JOIN FTS_Employee_Grade as empgrade on empgrade.Id=grad.Emp_Grade
--'
--  IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
--		BEGIN
--			Set @DSql=@DSql+'INNER JOIN #EMPHR_EDIT ON ContactID=EMPCODE '
--		END

-- Set @DSql=@DSql+'
  
--  '
  
--  Exec sp_executesql @DSql
/*Rev 2.0 close*/   
 -- print @DSql 
   
  --select * from tbl_master_contact
  ----------------- Update For CreationDate ------
  --Alter table FTS_Final_Display  
  --Add   [CreateDate] datetime null,
  --[LastModifyDate] datetime null
  
  --update FTS_Final_Display set CreateDate='01/01/2012',LastModifyDate='01/02/2016'
  
  --select CreateDate,LastModifyDate from FTS_Final_Display
  -- Rev 3.0 
  --update FTS_Final_Display set 
  update FSMEmployee_Master set 
  -- End of Rev 3.0
  CreateDate=c.CreateDate,
  LastModifyDate=(
  case when c.LastModifyDate is null then c.CreateDate else c.LastModifyDate end )
 --select * 
   from FSMEmployee_Master as t , tbl_master_contact as c
  where t.ContactID=c.cnt_internalId  collate SQL_Latin1_General_CP1_CI_AS

  Delete from FSMEmployee_Master where cnt_id is null
  ------------------------------------
  
  --select * from FTS_Final_Display
  
  ----Debugging Section
      --print SubString(@DSql,0,4000)
      --print SubString(@DSql,4001,4000)
  ----End Debugging Section
  
  if(@ExportType='S')
  Begin
    ---Dev Express Filter Section Embedded in Query
    if(@DevXFilterOn='Y')
    Begin
      Set @DSql='
        Select * from 
        (Select (Select COUNT(ContactID) From FSMEmployee_Master Where '+ @DevXFilterString +') TotalRecord,
        Row_Number() Over(Order By SRLNO) SRLNO ,ContactID ,Name ,FirstName ,MiddleName ,LastName ,cnt_id ,BranchName ,Department ,DepartmentID ,CTC ,
        ReportTo ,ReportToID  ,DOJ ,CreatedBy ,Designation ,DesignationID ,Company ,OrganizationID ,Email_Ids ,
        PhoneMobile_Numbers ,FatherName ,PanCardNumber  from FSMEmployee_Master
        Where '+ @DevXFilterString+' ) FDisplay order by LastModifyDate desc'
        --Where SRLNO BETWEEN (('+Cast(@PageNumber as Varchar(10)) +'- 1) * '+Cast(@PageSize as Varchar(10))+' )+ 1 AND '+
        --Cast(@PageNumber as Varchar(10))+' * '+Cast(@PageSize as Varchar(10))
        
        
    End
    Else
      Set @DSql='Select (Select COUNT(ContactID) From FSMEmployee_Master) TotalRecord,* from FSMEmployee_Master '
      --WHERE SRLNO BETWEEN (('+Cast(@PageNumber as Varchar(10)) +'- 1) * '+Cast(@PageSize as Varchar(10))+' )+ 1 AND '+
      --Cast(@PageNumber as Varchar(10))+' * '+Cast(@PageSize as Varchar(10)) +' '
    
    ----Debugging Section
      ----print @DSql
      ----Drop Table Final_Display
      ----Select * into Final_Display From FTS_Final_Display
    ----End Debugging Section

	 
	--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	
		BEGIN
			Set @DSql+='INNER JOIN #EMPHR_EDIT ON ContactID=EMPCODE '
		END

	Set @DSql+=' order by LastModifyDate desc'

    Exec sp_executesql @DSql
     
   
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
	
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT
	END

  End
  if(@ExportType='E')
  Begin
    if(@DevXFilterOn='Y')
    Begin
      Set @DSql='
      Select SRLNO,Name,FatherName, DOJ,Department,BranchName,CTC,ReportTo,Designation,Company,
      Email_Ids,PhoneMobile_Numbers,PanCardNumber,CreatedBy from FSMEmployee_Master Where '+ @DevXFilterString +'  order by LastModifyDate desc'
      Exec sp_executesql @DSql
    End
    Else
    Begin
      Select SRLNO,Name,FatherName, DOJ,Department,BranchName,CTC,ReportTo,Designation,Company,
      Email_Ids,PhoneMobile_Numbers,PanCardNumber,CreatedBy from FSMEmployee_Master order by  LastModifyDate desc
    End
  End

  -------Testing
  --print Substring(@Dsql,1,4000)
  --print Substring(@Dsql,4000,4000)
  --Select * from  #Email
  --Select * from #PhoneMobile
  ------------------------------

  --select @DSql
  /*Rev 2.0 start*/
  --Drop Table #Email
  --Drop Table #PhoneMobile
   /*Rev 2.0 close*/
  
  
End
