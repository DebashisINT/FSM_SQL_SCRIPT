IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'PRC_PROJECTREPORT_LISTING') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE PRC_PROJECTREPORT_LISTING AS' 
END
GO

-- exec PRC_PROJECTREPORT_LISTING @ACTION='GetListData', @USERID='378'
-- exec PRC_PROJECTREPORT_LISTING @ACTION='GETLISTINGDATA', @USERID='378', @FROMDATE='2022-07-19', @TODATE='2022-07-20'

ALTER PROCEDURE dbo.PRC_PROJECTREPORT_LISTING
(
@ACTION VARCHAR(500) = NULL,
@USERID	bigint = NULL,
@FROMDATE datetime = NULL,
@TODATE	datetime = NULL,
@Is_PageLoad varchar(100)=null,
@PR_ID bigint = 0,

@Month int = null,
@Year varchar(10) = null,
@PROJ_START_DT datetime = NULL,
@Project_Name varchar(max)=null,
@Area varchar(200)=null,
@Shop_Code varchar(100)=null,
@ShopTypeId bigint=null,
@Contact_Person varchar(200)=null,
@PhoneNo varchar(50)=null,
@ApproxQty decimal(12,2)=0,
@Grade varchar(200)=null,
@ProdName varchar(200)=null,
@ExptMonth int=null,
@ExptYear varchar(10)=null,
@Remarks varchar(500)=null,
@OrderLost varchar(200)=null,
@proj_complete_dt DATETIME =null,
-- Rev 1.0
@ArctName varchar(200)=null,
@ConslName varchar(200)=null,
@FabrName varchar(200)=null,
@Others varchar(200)=null,
@HODRemarks varchar(500) = null,
-- End of Rev 1.0
-- Rev 3.0
@SearchKey varchaR(500) ='',
-- End of Rev 3.0
@RETURNMESSAGE NVARCHAR(500) =NULL OUTPUT ,
@RETURNCODE NVARCHAR(20) =NULL OUTPUT

)  
AS 
/************************************************************************************************************************************ 
	Written by Sanchita	for V2.0.31	 - Project Report
	
	1.0		Sanchita	V2.0.33		Some more fields are required in Project & Projection report. Refer: 25203
	2.0		Sanchita	V2.0.42		FSM - CRM - Projection report - data not comming. data getting deleted somehow. unable to find from where.
									So table name changed from FTS_ProjectReport to FTS_CRMProjectinDetails. Mantis : 26135			
    3.0		Sanchita	V2.0.43		On demand search is required in Product Master & Projection Entry. Mantis : 26858		
	4.0		Sanchita	V2.0.43		Project & Projection entry report should show the data based on the settings. Mantis: 26987
	5.0		Sanchita	V2.0.45		PROJECT & PROJECTION ENTRY: Filter- Completed project drop-down data is not showing user-wise :-Eurobond. Mantis: 27210
	6.0		Sanchita	V2.0.45		Project name will be auto loaded after selecting the customer in Project & Projection report. Mantis: 27222
*************************************************************************************************************************************/
BEGIN

	DECLARE @empcode VARCHAR(50), @TotProject bigint, @InactProj bigint
	-- Rev 1.0
	DECLARE @ReportEmpID bigint, @IsHOD int
	-- End of Rev 1.0

	-- Rev 5.0
	IF(@ACTION = 'GETLISTINGDATA' OR @ACTION='GetProjectCompletedDT' OR @ACTION='GetOrderLostReason' )
	BEGIN
		-- Hierarchy
		set @empcode =(select user_contactId from Tbl_master_user where user_id=@USERID)		
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

		-- Rev 4.0
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Userid)=1)
		BEGIN
			-- If the above setting value is set as true for any user, he/she can only seen his/her data along with his hierarchical data.
		-- End of Rev 4.0
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
			-- Hierarchy
		-- Rev 4.0
		END
		ELSE
		BEGIN
			-- If the setting value is set as false, he/she can seen all the data irrespective of any hierarchy
			INSERT INTO #EMPHR_EDIT
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO 
			WHERE emp_effectiveuntil IS NULL
		END
	END
	-- End of Rev 5.0
	
	IF(@ACTION = 'GETLISTINGDATA')
	BEGIN
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'PROJECTREPORT_LISTING') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE PROJECTREPORT_LISTING
			(
				USERID INT,
				SEQ INT,
				PR_ID bigint,
				MONTH_YEAR varchar(100)  NOT NULL default '',
				PROJ_STARTDT datetime NULL,
				PROJ_STARTDT_ID varchar(50) NULL,
				PROJ_NAME varchar(5000) NOT NULL default '',
				Area varchar(200)  NOT NULL default '',
				CUST_NAME varchar(5000) NOT NULL default '',
				CATEGORY varchar(50) NOT NULL DEFAULT '',
				CONTACT_PERSON varchar(200)  NOT NULL default '',
				PHONE_NO VARCHAR(50)  NOT NULL default '',
				APPROX_QTY_SQFT DECIMAL(12,2) NOT null default 0,
				GRADE VARCHAR(200) NOT NULL default '',
				PROD_NAMECODE varchar(200) NOT NULL default '',
				EXPECTED_MONTH varchar(50) NOT NULL default '',
				EXPECTED_YEAR varchar(10) NOT NULL default '',
				CURRENT_REMARKS varchar(500) NOT NULL default '',
				EXECUTIVE_NAME varchar(200) not null default '',
				ORDER_LOST varchar(200) NOT NULL default '',
				PROJ_COMPLETE_DT datetime NULL,
				PROJ_COMPLETE_DT_ID varchar(50) NULL,
				-- Rev 1.0
				ARCTNAME varchar(200) NULL,
				CONSLNAME varchar(200) NULL,
				FABRNAME varchar(200) NULL,
				OTHERS varchar(200) NULL,
				HODREMARKS varchar(500) NULL,
				HODVISITEDBY varchar(500) null, 
				--HODVISITEDON datetime null
				HODVISITEDON varchar(50) null
				-- End of Rev 1.0
			)
			CREATE NONCLUSTERED INDEX IX1 ON PROJECTREPORT_LISTING (SEQ)
		END
		DELETE FROM PROJECTREPORT_LISTING WHERE USERID=@USERID

		if(@Is_PageLoad <> 'is_pageload')
		begin
			-- Rev 5.0
			---- Hierarchy
			--set @empcode =(select user_contactId from Tbl_master_user where user_id=@USERID)		
			--CREATE TABLE #EMPHR
			--(
			--EMPCODE VARCHAR(50),
			--RPTTOEMPCODE VARCHAR(50)
			--)

			--CREATE TABLE #EMPHR_EDIT
			--(
			--EMPCODE VARCHAR(50),
			--RPTTOEMPCODE VARCHAR(50)
			--)
		
			--INSERT INTO #EMPHR
			--SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			--FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL

			---- Rev 4.0
			--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@Userid)=1)
			--BEGIN
			--	-- If the above setting value is set as true for any user, he/she can only seen his/her data along with his hierarchical data.
			---- End of Rev 4.0
			--	;with cte as(select	
			--	EMPCODE,RPTTOEMPCODE
			--	from #EMPHR 
			--	where EMPCODE IS NULL OR EMPCODE=@empcode  
			--	union all
			--	select	
			--	a.EMPCODE,a.RPTTOEMPCODE
			--	from #EMPHR a
			--	join cte b
			--	on a.RPTTOEMPCODE = b.EMPCODE
			--	) 
			--	INSERT INTO #EMPHR_EDIT
			--	select EMPCODE,RPTTOEMPCODE  from cte 
			--	-- Hierarchy
			---- Rev 4.0
			--END
			--ELSE
			--BEGIN
			--	-- If the setting value is set as false, he/she can seen all the data irrespective of any hierarchy
			--	INSERT INTO #EMPHR_EDIT
			--	SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			--	FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO 
			--	WHERE emp_effectiveuntil IS NULL
			--END
			---- End of Rev 4.0
			-- End of Rev 5.0

			-- Rev 1.0
			set @IsHOD = 0
			if exists (select top 1 E.emp_id from tbl_master_employee E inner join tbl_master_user U on E.emp_contactid=U.user_contactid 
					inner join tbl_trans_employeectc CTC on CTC.emp_reportTo = E.emp_id
					where U.user_id=@USERID)
			begin
				set @IsHOD = 1
			end

			-- End of Rev 1.0

			insert into PROJECTREPORT_LISTING 
				(USERID,SEQ,PR_ID,MONTH_YEAR, PROJ_STARTDT,PROJ_STARTDT_ID,PROJ_NAME,Area,
				CUST_NAME,CATEGORY,CONTACT_PERSON ,PHONE_NO,APPROX_QTY_SQFT,GRADE,PROD_NAMECODE,EXPECTED_MONTH ,EXPECTED_YEAR,
				CURRENT_REMARKS,EXECUTIVE_NAME,ORDER_LOST,PROJ_COMPLETE_DT,PROJ_COMPLETE_DT_ID,ARCTNAME,CONSLNAME,FABRNAME,OTHERS,HODREMARKS,HODVISITEDBY, HODVISITEDON) 
			select @USERID,ROW_NUMBER() OVER(ORDER BY PR.PR_ID ASC) AS SEQ,PR.PR_ID, FORMAT(DATEFROMPARTS(1900, PR.MONTH, 1), 'MMM', 'en-US')+'-'+YEAR MONTH_YEAR, 
				convert(date, PROJ_STARTDT) PROJ_STARTDT, CONVERT(VARCHAR(10), convert(date,PROJ_STARTDT), 103) PROJ_STARTDT_ID, 
				PR.Project_Name, Area, 
				SH.Shop_Name, ST.Name, CONTACT_PERSON, PHONE_NO, APPROX_QTY_SQFT,GRADE, PROD_NAMECODE, FORMAT(DATEFROMPARTS(1900, PR.EXPECTED_MONTH, 1), 'MMM', 'en-US')+'-'+EXPECTED_YEAR as EXPECTED_MONTH, EXPECTED_YEAR, 
				CURRENT_REMARKS, U.user_name, 
				--(case when Order_LOST<>'' then replace(ORDER_LOST,' ','~') else ORDER_LOST end) as ORDER_LOST, 
				ORDER_LOST,
				(case when convert(date,PROJ_COMPLETE_DT)='1900-01-01' then null else PROJ_COMPLETE_DT end ) ,
				(case when convert(date,PROJ_COMPLETE_DT)='1900-01-01' then null else CONVERT(VARCHAR(10), convert(date,PROJ_COMPLETE_DT), 103) end ) 
				-- Rev 1.0
				,ARCTNAME,CONSLNAME,FABRNAME,OTHERS,HODRemarks, 
				--(case when @IsHOD=1 then isnull(UHOD.user_name,'') else '' end) HODVisitedBy, (case when @IsHOD=1 then HOD.VisitedOn else '' end) HODVisitedOn
				isnull(UHOD.user_name,'') HODVisitedBy,
				(case when convert(date,HOD.VisitedOn)='1900-01-01' then null else CONVERT(VARCHAR(10), convert(date,HOD.VisitedOn), 103) end )  HODVisitedOn
				-- End of Rev 1.0
				-- Rev 2.0
				--from FTS_ProjectReport PR 
				from FTS_CRMProjectinDetails PR
				-- End of Rev 2.0
				inner join tbl_master_user U on U.user_id = PR.CreatedBy 
				INNER JOIN #EMPHR_EDIT ON EMPCODE = U.user_contactId
				inner join tbl_master_shop SH on SH.Shop_Code=PR.Shop_Code
				inner join tbl_shoptype ST on ST.shop_typeId=PR.ShopTypeId
				-- Rev 1.0
				left outer join FTS_ProjectReport_HODVisit HOD on HOD.PR_ID=PR.PR_ID
				left outer join tbl_master_user UHOD on UHOD.user_id = HOD.VisitedBy
				-- End of Rev 1.0
				where convert(date,PR.CreatedOn) >= @FROMDATE and convert(date,PR.CreatedOn) <= @TODATE

			-- Rev 1.0
			set @ReportEmpID = (select top 1 emp_id from tbl_master_employee where emp_contactId=@empcode)

			delete from FTS_ProjectReport_HODVisit where PR_ID in 
					(select PL.PR_ID from PROJECTREPORT_LISTING PL 
					-- Rev 2.0
					--inner join FTS_ProjectReport PR on PR.PR_ID=PL.PR_ID 
					inner join FTS_CRMProjectinDetails PR on PR.PR_ID=PL.PR_ID 
					-- End of Rev 2.0
					inner join tbl_master_user U on U.user_id=PR.CreatedBy 
					inner join tbl_trans_employeeCTC CTC on CTC.emp_cntId = U.user_contactId
					where CTC.emp_reportTo=@ReportEmpID and PL.USERID=@USERID)


			insert into FTS_ProjectReport_HODVisit select PL.PR_ID,@USERID,GETDATE() from PROJECTREPORT_LISTING PL 
					-- Rev 2.0 
					--inner join FTS_ProjectReport PR on PR.PR_ID=PL.PR_ID 
					inner join FTS_CRMProjectinDetails PR on PR.PR_ID=PL.PR_ID 
					-- End of Rev 2.0
					inner join tbl_master_user U on U.user_id=PR.CreatedBy 
					inner join tbl_trans_employeeCTC CTC on CTC.emp_cntId = U.user_contactId
					where CTC.emp_reportTo=@ReportEmpID and PL.USERID=@USERID
			-- End of Rev 1.0

			-- Rev 5.0
			--drop table #EMPHR
			--drop table #EMPHR_EDIT
			IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPHR') AND TYPE IN (N'U'))
			BEGIN
				drop table #EMPHR
			END
			IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPHR_EDIT') AND TYPE IN (N'U'))
			BEGIN
				drop table #EMPHR_EDIT
			END
			-- End of Rev 5.0
		end
		
	END

	IF(@ACTION = 'GetListData')
	BEGIN

		select '0' Shop_Code, 'Select' Shop_Name
		union
		select Shop_Code, Shop_Name from tbl_Master_shop where type<>999 and Shop_CreateUser=@USERID
		order by Shop_Code


		select '0' Project_Id, 'Select' Project_Name
		union
		select distinct Project_Name Project_Id, Project_Name from tbl_master_shop where project_name is not null and project_name<>'' and Shop_CreateUser=@USERID
		order by Project_Id


		select '0' shop_typeId, 'Select' shop_typeName
		union
		select convert(nvarchar(10),shop_typeId), Name shop_typeName from tbl_shoptype where IsActive=1
		order by shop_typeId

		select user_name from tbl_master_user where user_id=@USERID

		-- Rev 1.0
		select top 1 E.emp_id from tbl_master_employee E inner join tbl_master_user U on E.emp_contactid=U.user_contactid 
			inner join tbl_trans_employeectc CTC on CTC.emp_reportTo = E.emp_id
			where U.user_id=@USERID 
		-- End of Rev 1.0


	end

	IF(@ACTION = 'ADD')
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION	
			
			-- Rev 2.0
			--insert into FTS_ProjectReport
			insert into FTS_CRMProjectinDetails
			-- End of Rev 2.0
			(
				MONTH, YEAR, PROJ_STARTDT, Project_Name, Area, Shop_Code, ShopTypeId, CONTACT_PERSON, PHONE_NO, APPROX_QTY_SQFT, 
				GRADE, PROD_NAMECODE, EXPECTED_MONTH, EXPECTED_YEAR, CURRENT_REMARKS, ORDER_LOST, PROJ_COMPLETE_DT, CreatedBy, CreatedOn,
				-- Rev 1.0
				ArctName, ConslName, FabrName, Others
				-- End of Rev 1.0
				) 
			values
			(
				isnull(@Month,0), isnull(@Year,''), @PROJ_START_DT, isnull(@Project_Name,''), isnull(@Area,''),isnull(@Shop_Code,''), isnull(@ShopTypeId,0), 
				isnull(@Contact_Person,''), isnull(@PhoneNo,''), isnull(@ApproxQty,0) ,
				isnull(@Grade,''),isnull(@ProdName,''), isnull(@ExptMonth,0), isnull(@ExptYear,'') , isnull(@Remarks,''), isnull(@OrderLost,''), isnull(@proj_complete_dt,''), 
				@USERID, GETDATE(),
				-- Rev 1.0
				@ArctName, @ConslName, @FabrName, @Others
				-- End of Rev 1.0
			)

			COMMIT TRANSACTION

			Set @RETURNMESSAGE= 'Success';
			Set @RETURNCODE='1'

		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			
			Set @RETURNMESSAGE= ERROR_MESSAGE();
			Set @RETURNCODE='-10'
	
		END CATCH

	end
	
	IF(@ACTION = 'EDIT')
	BEGIN
		select CRMPROJ.PR_ID, CRMPROJ.MONTH, CRMPROJ.YEAR, CRMPROJ.PROJ_STARTDT, CRMPROJ.Project_Name, CRMPROJ.Area, CRMPROJ.Shop_Code, CRMPROJ.ShopTypeId, CRMPROJ.CONTACT_PERSON, CRMPROJ.PHONE_NO, CRMPROJ.APPROX_QTY_SQFT, CRMPROJ.GRADE, CRMPROJ.PROD_NAMECODE, CRMPROJ.
			EXPECTED_MONTH, CRMPROJ.EXPECTED_YEAR, CRMPROJ.CURRENT_REMARKS, CRMPROJ.ORDER_LOST, CRMPROJ.PROJ_COMPLETE_DT, CRMPROJ.CreatedBy, CRMPROJ.CreatedOn
			-- Rev 1.0
			, CRMPROJ.ArctName, CRMPROJ.ConslName, CRMPROJ.FabrName, CRMPROJ.Others 
			-- End of Rev 1.0
			-- Rev 3.0
			, SH.Shop_Name
			-- End of Rev 3.0
			-- Rev 2.0
			--from FTS_ProjectReport
			-- Rev 3.0
			--from FTS_CRMProjectinDetails
			from FTS_CRMProjectinDetails CRMPROJ LEFT OUTER JOIN tbl_Master_shop SH ON CRMPROJ.Shop_Code=SH.Shop_Code
			-- End of Rev 3.0
			-- End of Rev 2.0
			where PR_ID = @PR_ID
	end

	IF(@ACTION = 'DELETE')
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION	
			
			-- Rev 2.0
			--delete from FTS_ProjectReport where PR_ID=@PR_ID
			delete from FTS_CRMProjectinDetails where PR_ID=@PR_ID
			-- End of Rev 2.0

			COMMIT TRANSACTION

			Set @RETURNMESSAGE= 'Deleted';
			Set @RETURNCODE='1'

		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			
			Set @RETURNMESSAGE= ERROR_MESSAGE();
			Set @RETURNCODE='-10'
	
		END CATCH

	end

	IF(@ACTION = 'MOD')
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION	
			-- Rev 2.0 
			--update FTS_ProjectReport set MONTH=isnull(@Month,0), YEAR=isnull(@Year,''), PROJ_STARTDT=@PROJ_START_DT, Project_Name=isnull(@Project_Name,''), 
			update FTS_CRMProjectinDetails set MONTH=isnull(@Month,0), YEAR=isnull(@Year,''), PROJ_STARTDT=@PROJ_START_DT, Project_Name=isnull(@Project_Name,''), 
			-- End of Rev 2.0
				Area=isnull(@Area,''), Shop_Code=isnull(@Shop_Code,''), 
				ShopTypeId=isnull(@ShopTypeId,0), CONTACT_PERSON=isnull(@Contact_Person,''), PHONE_NO=isnull(@PhoneNo,''), APPROX_QTY_SQFT=isnull(@ApproxQty,0), 
				GRADE=isnull(@Grade,''), PROD_NAMECODE=isnull(@ProdName,''), EXPECTED_MONTH=isnull(@ExptMonth,0), EXPECTED_YEAR=isnull(@ExptYear,''), 
				CURRENT_REMARKS=isnull(@Remarks,''), ORDER_LOST=isnull(@OrderLost,''), 
				PROJ_COMPLETE_DT=isnull(@proj_complete_dt,''), ModifiedBy=@USERID, ModifiedOn=GETDATE()
				-- Rev 1.0
				, ArctName=@ArctName, ConslName=@ConslName, FabrName=@FabrName, Others=@Others 
				-- End of Rev 1.0
				where PR_ID=@PR_ID


			COMMIT TRANSACTION

			Set @RETURNMESSAGE= 'Success';
			Set @RETURNCODE='1'

		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			
			Set @RETURNMESSAGE= ERROR_MESSAGE();
			Set @RETURNCODE='-10'
	
		END CATCH

	end

	IF(@ACTION = 'AUTOFILL')
	BEGIN
		select top 1 PR_ID, MONTH, YEAR, PROJ_STARTDT, Project_Name, Area, Shop_Code, ShopTypeId, CONTACT_PERSON, PHONE_NO, APPROX_QTY_SQFT, GRADE, PROD_NAMECODE, 
			-- Rev 2.0
			--EXPECTED_MONTH, EXPECTED_YEAR, CURRENT_REMARKS, ORDER_LOST, PROJ_COMPLETE_DT, CreatedBy, CreatedOn from FTS_ProjectReport
			EXPECTED_MONTH, EXPECTED_YEAR, CURRENT_REMARKS, ORDER_LOST, PROJ_COMPLETE_DT, CreatedBy, CreatedOn from FTS_CRMProjectinDetails
			-- End of Rev 2.0
			where Shop_Code=@Shop_Code and Project_Name=@Project_Name order by CreatedOn desc
	end

	IF(@ACTION = 'GetProjectNameList')
	BEGIN

		select '0' Project_Id, 'Select' Project_Name
		union
		select distinct Project_Name Project_Id, Project_Name from tbl_master_shop S where project_name is not null and project_name<>'' and Shop_CreateUser=@USERID 
		-- Rev 2.0
		--and not exists (select Project_Name from FTS_ProjectReport where Shop_Code=@Shop_Code and Project_Name=S.Project_Name 
		and not exists (select Project_Name from FTS_CRMProjectinDetails where Shop_Code=@Shop_Code and Project_Name=S.Project_Name 
		-- End of Rev 2.0
				and (ORDER_LOST<>'' or convert(date,PROJ_COMPLETE_DT)<>'1900-01-01') ) 
		order by Project_Id


	end

	IF(@ACTION = 'GetOrderLostReason')
	BEGIN
		
		select replace(ORDER_LOST,' ','~') ID, ORDER_LOST as Close_Reason , convert(nvarchar(10),count(ORDER_LOST)) as Close_Reason_Count
		-- Rev 2.0
		--from FTS_ProjectReport where ORDER_LOST<>'' group by ORDER_LOST order by ORDER_LOST
		-- Rev 5.0
		--from FTS_CRMProjectinDetails where ORDER_LOST<>'' group by ORDER_LOST order by ORDER_LOST
		---- End of Rev 2.0

		from FTS_CRMProjectinDetails PR
				inner join tbl_master_user U on U.user_id = PR.CreatedBy 
				INNER JOIN #EMPHR_EDIT ON EMPCODE = U.user_contactId
		where ORDER_LOST<>'' group by ORDER_LOST order by ORDER_LOST
		

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPHR') AND TYPE IN (N'U'))
		BEGIN
			drop table #EMPHR
		END
		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPHR_EDIT') AND TYPE IN (N'U'))
		BEGIN
			drop table #EMPHR_EDIT
		END
		-- End of Rev 5.0
	end

	IF(@ACTION = 'GetProjectCompletedDT')
	BEGIN
		
		select CONVERT(VARCHAR(10), convert(date,PROJ_COMPLETE_DT), 103) ID, CONVERT(VARCHAR(10), convert(date,PROJ_COMPLETE_DT), 103) as Completed_Date , 
			convert(nvarchar(10),count( convert(date,PROJ_COMPLETE_DT))) as Completed_Date_Count
			-- Rev 2.0
			--from FTS_ProjectReport where  convert(date,PROJ_COMPLETE_DT)<>'1900-01-01' group by  convert(date,PROJ_COMPLETE_DT) order by  convert(date,PROJ_COMPLETE_DT)
			-- Rev 5.0
			--from FTS_CRMProjectinDetails where  convert(date,PROJ_COMPLETE_DT)<>'1900-01-01' group by  convert(date,PROJ_COMPLETE_DT) order by  convert(date,PROJ_COMPLETE_DT)
			---- End of Rev 2.0
		
			from FTS_CRMProjectinDetails PR
				inner join tbl_master_user U on U.user_id = PR.CreatedBy 
				INNER JOIN #EMPHR_EDIT ON EMPCODE = U.user_contactId
			where  convert(date,PROJ_COMPLETE_DT)<>'1900-01-01' group by  convert(date,PROJ_COMPLETE_DT) order by  convert(date,PROJ_COMPLETE_DT)


		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPHR') AND TYPE IN (N'U'))
		BEGIN
			drop table #EMPHR
		END
		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPHR_EDIT') AND TYPE IN (N'U'))
		BEGIN
			drop table #EMPHR_EDIT
		END
		-- End of Rev 5.0
	end

	IF(@ACTION = 'TotProject_VS_InactivProject')
	BEGIN
		
		-- exec PRC_PROJECTREPORT_LISTING @ACTION='TotProject_VS_InactivProject', @USERID='378'
		-- exec PRC_PROJECTREPORT_LISTING @ACTION='TotProject_VS_InactivProject', @USERID='11722'

		set @TotProject  = 
		-- Rev 2.0
		--( select count(*) from FTS_ProjectReport PR where PR.CreatedBy = @USERID )
		( select count(*) from FTS_CRMProjectinDetails PR where PR.CreatedBy = @USERID )
		-- End of Rev 2.0

		--set @InactProj = (select  count(*) from FTS_ProjectReport PR
		--	where PR.CreatedBy =@USERID and convert(date,PR.PROJ_COMPLETE_DT)='1900-01-01' and 
		--	(	(ModifiedOn is null and datediff(day,convert(date,PR.CreatedOn),getdate())>31) or
		--		(datediff(day,convert(date,PR.ModifiedOn),getdate())>31) ))
		-- Rev 2.0
		--set @InactProj = (select  count(*) from FTS_ProjectReport PR
		set @InactProj = (select  count(*) from FTS_CRMProjectinDetails PR
		-- End of Rev 2.0
			where PR.CreatedBy =@USERID and convert(date,PR.PROJ_COMPLETE_DT)<>'1900-01-01' )


		select @TotProject TotProjectCnt , @InactProj InactivProjectCnt

	end

	IF(@ACTION = 'TotProject_VS_OrderLost')
	BEGIN
		
		-- exec PRC_PROJECTREPORT_LISTING @ACTION='TotProject_VS_OrderLost', @USERID='378'
		-- exec PRC_PROJECTREPORT_LISTING @ACTION='TotProject_VS_OrderLost', @USERID='11722'

		set @TotProject = 
		-- Rev 2.0
		--( select count(*) from FTS_ProjectReport PR where PR.CreatedBy = @USERID )

		--set @OrderLost = (select  count(*) from FTS_ProjectReport PR
		( select count(*) from FTS_CRMProjectinDetails PR where PR.CreatedBy = @USERID )

		set @OrderLost = (select  count(*) from FTS_CRMProjectinDetails PR
		-- End of Rev 2.0
			where PR.CreatedBy = @USERID and PR.ORDER_LOST<>'')

		select @TotProject TotProjectCnt , @OrderLost OrderLostCnt

	end

	IF(@ACTION = 'UserList')
	BEGIN
		
		-- exec PRC_PROJECTREPORT_LISTING @ACTION='UserList', @USERID='378'
		-- exec PRC_PROJECTREPORT_LISTING @ACTION='UserList', @USERID='11722'

		-- Hierarchy
		set @empcode =(select user_contactId from Tbl_master_user where user_id=@USERID)		
		CREATE TABLE #EMPHR2
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)

		CREATE TABLE #EMPHR2_EDIT
		(
		EMPCODE VARCHAR(50),
		RPTTOEMPCODE VARCHAR(50)
		)
		
		INSERT INTO #EMPHR2
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
		FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL

		-- Rev 4.0
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
		-- End of Rev 4.0
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHR2 
			where EMPCODE IS NULL OR EMPCODE=@empcode  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHR2 a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR2_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 
			-- Hierarchy
		-- Rev 4.0
		END
		ELSE
		BEGIN
			-- If the setting value is set as false, he/she can seen all the data irrespective of any hierarchy
			INSERT INTO #EMPHR2_EDIT
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO 
			WHERE emp_effectiveuntil IS NULL
		END
		-- End of Rev 4.0

		SELECT '0' AS UserId,'Select' AS UserName
		UNION ALL
		select distinct convert(nvarchar(10),U.user_id) as UserId, 
			trim(CON.cnt_firstName)+ (case when trim(CON.cnt_middleName)<>'' then ' '+CON.cnt_middleName else '' end)+ 
			(case when trim(CON.cnt_lastName)<>'' then ' '+CON.cnt_lastName else '' end)  + ' ('+ CON.cnt_UCC +')' as Salesman_Name 
			from tbl_master_user U 
			inner join tbl_master_employee E ON U.user_contactid = E.emp_contactid
			inner join tbl_master_contact CON on CON.cnt_internalId=E.emp_contactId
			INNER JOIN #EMPHR2_EDIT ON EMPCODE = U.user_contactId
			WHERE user_inactive='N' order by UserName

	end

	-- Rev 1.0
	IF(@ACTION = 'SaveHODRemarks')
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION	

		--insert into test values(@PR_ID)
		--insert into test values(@HODRemarks)
		--insert into test values(@USERID)

		
			-- Rev 2.0
			--update FTS_ProjectReport set HODRemarks=@HODRemarks, HODRemarksBy=@USERID, HODRemarksDt=GETDATE() where PR_ID=@PR_ID
			update FTS_CRMProjectinDetails set HODRemarks=@HODRemarks, HODRemarksBy=@USERID, HODRemarksDt=GETDATE() where PR_ID=@PR_ID
			-- End of Rev 2.0


			COMMIT TRANSACTION

			Set @RETURNMESSAGE= 'Success';
			Set @RETURNCODE='1'

		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			
			Set @RETURNMESSAGE= ERROR_MESSAGE();
			Set @RETURNCODE='-10'
	
		END CATCH

	end

	IF(@ACTION = 'GetHODRemarks')
	BEGIN
		-- Rev 2.0
		--declare @UID bigint = (select top 1 CreatedBy from FTS_ProjectReport where PR_ID = @PR_ID )
		declare @UID bigint = (select top 1 CreatedBy from FTS_CRMProjectinDetails where PR_ID = @PR_ID )
		-- End of Rev 2.0
		
		declare @empidRepoTo numeric(18,0) = (select emp_reportTo from tbl_trans_employeeCTC CTC inner join tbl_master_user U on CTC.emp_cntId=U.user_contactId 
			where U.user_id=@UID )

		declare @empidUser numeric(18,0) = ( select top 1 E.emp_id from tbl_master_employee E inner join tbl_master_user U on E.emp_contactid=U.user_contactid 
			--inner join tbl_trans_employeectc CTC on CTC.emp_reportTo = E.emp_id
			where U.user_id=@USERID )

		if(@empidUser = @empidRepoTo)
			-- Rev 2.0
			--select HODRemarks from FTS_ProjectReport where PR_ID = @PR_ID
			select HODRemarks from FTS_CRMProjectinDetails where PR_ID = @PR_ID
			-- End of Rev 2.0
		else
			select 'NOT HOD' HODRemarks
	end
	-- End of Rev 1.0
	-- Rev 3.0
	IF(@ACTION = 'CustomerNameSearch')
	BEGIN
		select top 10 Shop_Code, Shop_Name from tbl_Master_shop where type<>999 and Shop_CreateUser=@USERID
		-- Rev 6.0
		and trim(Project_Name)<>''
		-- End of Rev 6.0
		AND Shop_Name LIKE '%'+@SearchKey+'%'
		order by Shop_Code
	END
	IF(@ACTION = 'ProjectNameSearch')
	BEGIN
		select distinct top 10 Project_Name Project_Id, Project_Name from tbl_master_shop S where project_name is not null 
			and project_name<>'' and Shop_CreateUser=@USERID 
			and not exists (select Project_Name from FTS_CRMProjectinDetails where Shop_Code=@Shop_Code and Project_Name=S.Project_Name 
			and (ORDER_LOST<>'' or convert(date,PROJ_COMPLETE_DT)<>'1900-01-01') ) 
			AND project_name LIKE '%'+@SearchKey+'%'
		order by Project_Id

	END
	-- End of Rev 3.0
	-- Rev 6.0
	IF(@ACTION = 'GetProjectName')
	BEGIN

		select top 1 Project_Name from tbl_master_shop S where project_name is not null and project_name<>'' and Shop_Code=@Shop_Code 

	end
	-- End of Rev 6.0
END
GO