--EXEC PRC_EmployeeNameSearch_Desg 378,'a','AE'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_EmployeeNameSearch_Desg]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_EmployeeNameSearch_Desg] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_EmployeeNameSearch_Desg]  
(
@USER_ID BIGINT=0,
@SearchKey varchar(50) ='',
@DesigId nvarchar(max)=null,
@Action nvarchar(max)=null,
@AeId nvarchar(max)=null,
@WdId nvarchar(max)=null,
@BranchId nvarchar(max)=null
) --WITH ENCRYPTION
AS
/*******************************************************************************************************************************************************************************************
			Pratik		08-11-2021		Employee name search with desig.
1.0			Pratik		24-11-2021		Employee name search with branch filter.
2.0		v2.0.27		Debashis	01/03/2022		Enhancement done.Refer: 0024715
********************************************************************************************************************************************************************************************/
BEGIN
SET NOCOUNT ON
	declare @Desig_Id as int, @empcodes VARCHAR(50),@DesigAE_Id int,@DesigWD_Id int
	--Rev 2.0
	--set @Desig_Id=(select deg_id from tbl_master_designation where deg_designation=@DesigId)
	IF (@Action='DS' OR @DesigId='DS')
		BEGIN
			SELECT @DesigID = coalesce(@DesigID + ',', '') + CONVERT(VARCHAR,deg_id) FROM tbl_master_designation 
			WHERE deg_designation IN('DS','TL')
		END
	ELSE
		SET @Desig_Id=(select deg_id from tbl_master_designation where deg_designation=@DesigId)
	--End of Rev 2.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
			--set @empcodes =(select user_contactId from Tbl_master_user where user_id=@USER_ID)		
			--CREATE TABLE #EMPHRS
			--(
			--EMPCODE VARCHAR(50),
			--RPTTOEMPCODE VARCHAR(50)
			--)

			--CREATE TABLE #EMPHR_EDIT
			--(
			--EMPCODE VARCHAR(50),
			--RPTTOEMPCODE VARCHAR(50)
			--)
		
			--INSERT INTO #EMPHRS
			--SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			--FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
			--and CTC.emp_Designation=@Desig_Id
			--;with cte as(select	
			--EMPCODE,RPTTOEMPCODE
			--from #EMPHRS 
			--where EMPCODE IS NULL OR EMPCODE=@empcodes  
			--union all
			--select	
			--a.EMPCODE,a.RPTTOEMPCODE
			--from #EMPHRS a
			--join cte b
			--on a.RPTTOEMPCODE = b.EMPCODE
			--) 
			--INSERT INTO #EMPHR_EDIT
			--select EMPCODE,RPTTOEMPCODE  from cte 
			set @empcodes =(SELECT user_contactId FROM Tbl_master_user WHERE user_id=@USER_ID)		
			CREATE TABLE #EMPHRS
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
		
			INSERT INTO #EMPHRS
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte AS(SELECT	EMPCODE,RPTTOEMPCODE FROM #EMPHRS 
			WHERE EMPCODE IS NULL OR EMPCODE=@empcodes  
			UNION ALL
			SELECT a.EMPCODE,a.RPTTOEMPCODE FROM #EMPHRS a
			INNER JOIN cte b ON a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			SELECT EMPCODE,RPTTOEMPCODE FROM cte 

		END
	If(@Action='AE')
	Begin
		

	--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
	--	BEGIN
	--		select top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
	--		from tbl_master_contact 
	--		INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
	--		--rev 1.0
	--		--where (cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%')
	--		where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
	--		and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
	--		--End of rev 1.0

	--		DROP TABLE #EMPHR_EDIT
	--		DROP TABLE #EMPHRS
	--	END
	--ELSE
	--	BEGIN
	--		select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
	--		from tbl_master_contact 
	--		inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
	--		--rev 1.0
	--		--where (cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%')
	--		where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
	--		and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
	--		--End of rev 1.0
			
	--	END
		select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
			from tbl_master_contact 
			inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
			--rev 1.0
			--where (cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%')
			where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
			and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
			--End of rev 1.0
	END
	If(@Action='WD')
	Begin
		set @empcodes =(select user_contactId from Tbl_master_user where user_id=@USER_ID)	
		set @DesigAE_Id=(select deg_id from tbl_master_designation where deg_designation='AE')
		if(@AeId='')
		begin
			Select @AeId = COALESCE(@AeId + ', ' + tbl_trans_employeeCTC.emp_cntid, emp_cntid) 
			From tbl_trans_employeeCTC
			where emp_Designation=@DesigAE_Id
			--Select @AeId;
		end
		--if(@SearchKey<>'')
		--	begin
		--		select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
		--		from tbl_master_contact 
		--		inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
		--		where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
		--		and (CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId))
		--		--rev 1.0
		--		and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
		--		--End of rev 1.0
		--		--(select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigAE_Id)
			
		--	end
		--	else
		--	begin
		--		select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
		--		from tbl_master_contact 
		--		inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
		--		where CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId)
		--		--rev 1.0
		--		and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
		--		--End of rev 1.0
		--		--(select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigAE_Id)
			
		--	end
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
			--select top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
			--from tbl_master_contact 
			--INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE
			----rev 1.0
			----where (cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%')
			--where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
			--and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
			----End of rev 1.0

			if(@SearchKey<>'')
			begin
				select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
				from tbl_master_contact 
				inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
				INNER JOIN #EMPHR_EDIT ON tbl_master_contact.cnt_internalId=EMPCODE
				where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
				and (CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId))
				--rev 1.0
				and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
				--End of rev 1.0
				--(select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigAE_Id)
			
			end
			else
			begin
				select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
				from tbl_master_contact 
				inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
				INNER JOIN #EMPHR_EDIT ON tbl_master_contact.cnt_internalId=EMPCODE
				where CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId)
				--rev 1.0
				and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
				--End of rev 1.0
				--(select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigAE_Id)
			
			end

			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END
	ELSE
		BEGIN
			if(@SearchKey<>'')
			begin
				select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
				from tbl_master_contact 
				inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
				where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
				and (CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId))
				--rev 1.0
				and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
				--End of rev 1.0
				--(select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigAE_Id)
			
			end
			else
			begin
				select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
				from tbl_master_contact 
				inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
				where CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId)
				--rev 1.0
				and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
				--End of rev 1.0
				--(select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigAE_Id)
			
			end
			
		END



		
		
	END	
	If(@Action='DS')
	Begin
		set @empcodes =(select user_contactId from Tbl_master_user where user_id=@USER_ID)	
		set @DesigAE_Id=(select deg_id from tbl_master_designation where deg_designation='AE')
		set @DesigWD_Id=(select deg_id from tbl_master_designation where deg_designation='WD')
		if(@AeId='')
		begin
			Select @AeId = COALESCE(@AeId + ',' + tbl_trans_employeeCTC.emp_cntid, emp_cntid) 
			From tbl_trans_employeeCTC
			where emp_Designation=@DesigAE_Id
			--Select @AeId;
		end
		if(@WdId='')
		begin
			Select @WdId = COALESCE(@WdId + ',' + tbl_trans_employeeCTC.emp_cntid, emp_cntid) 
			From tbl_trans_employeeCTC
			where emp_Designation=@DesigWD_Id 
			--rev Pratik
			--and emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@AeId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigAE_Id)
			--End of rev Pratik
			--Select @AeId;
		end
		--if(@SearchKey<>'')
		--begin
		--	select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
		--	from tbl_master_contact 
		--	inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
		--	where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
		--	and (CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId))
		--	--rev 1.0
		--	and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
		--	--End of rev 1.0
		--	--(select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigWD_Id)
			
		--end
		--else
		--begin
		--	select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
		--	from tbl_master_contact 
		--	inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
		--	where CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId)
		--	--rev 1.0
		--	and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
		--	--End of rev 1.0
			
		--end



		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USER_ID)=1)
		BEGIN
			if(@SearchKey<>'')
			begin
				select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
				from tbl_master_contact 
				--Rev 2.0
				--inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
				INNER JOIN tbl_trans_employeeCTC CTC ON tbl_master_contact.cnt_internalId=CTC.emp_cntId AND CTC.emp_Designation IN(@Desig_Id)
				--End of Rev 2.0
				INNER JOIN #EMPHR_EDIT ON tbl_master_contact.cnt_internalId=EMPCODE
				--Rev 2.0
				--where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
				WHERE ((cnt_firstName LIKE '%' + @SearchKey + '%') OR (cnt_middleName LIKE '%' + @SearchKey + '%') OR (cnt_lastName LIKE '%' + @SearchKey + '%') OR(cnt_UCC LIKE '%' + @SearchKey + '%'))
				--End of Rev 2.0
				and (CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId))
				--rev 1.0
				and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
				--End of rev 1.0
				--(select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigWD_Id)
			
			end
			else
			begin
				select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
				from tbl_master_contact 
				--Rev 2.0
				--inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
				INNER JOIN tbl_trans_employeeCTC CTC ON tbl_master_contact.cnt_internalId=CTC.emp_cntId AND CTC.emp_Designation IN(@Desig_Id)
				--End of Rev 2.0
				INNER JOIN #EMPHR_EDIT ON tbl_master_contact.cnt_internalId=EMPCODE
				where CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId)
				--where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
				--rev 1.0
				and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
				--End of rev 1.0
			
			end

			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END
	ELSE
		if(@SearchKey<>'')
		begin
			select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
			from tbl_master_contact 
			--Rev 2.0
			--inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
			--where ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%'))
			INNER JOIN tbl_trans_employeeCTC CTC ON tbl_master_contact.cnt_internalId=CTC.emp_cntId AND CTC.emp_Designation IN(@Desig_Id)
			WHERE ((cnt_firstName LIKE '%' + @SearchKey + '%') OR (cnt_middleName LIKE '%' + @SearchKey + '%') OR (cnt_lastName LIKE '%' + @SearchKey + '%') OR (cnt_UCC LIKE '%' + @SearchKey + '%'))
			--End of Rev 2.0
			and (CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId))
			--rev 1.0
			and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
			--End of rev 1.0
			--(select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_trans_employeeCTC as ttec(nolock) on s=ttec.emp_cntId and ttec.emp_Designation=@DesigWD_Id)
			
		end
		else
		begin
			select distinct top(10)cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
			from tbl_master_contact 
			--Rev 2.0
			--inner join tbl_trans_employeeCTC CTC on tbl_master_contact.cnt_internalId=CTC.emp_cntId and CTC.emp_Designation=@Desig_Id
			INNER JOIN tbl_trans_employeeCTC CTC ON tbl_master_contact.cnt_internalId=CTC.emp_cntId AND CTC.emp_Designation IN(@Desig_Id)
			--End of Rev 2.0
			--where CTC.emp_reportTo in (select ttec.emp_id from dbo.getsplit(',',@WdId) inner join tbl_master_employee as ttec(nolock) on s=ttec.emp_contactId)
			where cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
			--rev 1.0
			--and cnt_branchid in (select s from dbo.getsplit(',',@BranchId))
			--End of rev 1.0
			
		end
	END	
END