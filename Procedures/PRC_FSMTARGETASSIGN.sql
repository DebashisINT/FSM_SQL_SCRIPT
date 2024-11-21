IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMTARGETASSIGN]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMTARGETASSIGN] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FSMTARGETASSIGN]
(
@Action varchar(200)='',
@SearchKey VARCHAR(250) = NULL,
@USERID Varchar(10)=''

) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************************
Written by : Priti Roy on 06/11/2024
0027770:A new module is required as  Target Assign

*****************************************************************************************************************************************************************************************/
BEGIN    

	IF(@Action ='1' ) 
	BEGIN

		if(isnull(@SearchKey,'')!='')
		Begin		
			select convert(varchar(500),branch_id)+'|'+branch_internalId as ID ,branch_description as NAME ,branch_internalId as INTERNALID,branch_code as CODE 
			from tbl_master_branch
			where
			(branch_description like '%'+@SearchKey+'%' OR branch_code like '%'+@SearchKey+'%') ORDER BY branch_description ASC
		End
		else
		Begin
			select convert(varchar(500),branch_id)+'|'+branch_internalId as ID ,branch_description as NAME ,branch_internalId as INTERNALID,branch_code as CODE 
			from tbl_master_branch
		End
		
	END
	
	IF(@Action ='2' OR @Action ='3' OR @Action ='4' )
	BEGIN
		--DECLARE @LEVEL_SHORTNAME VARCHAR(10)

		--IF(@Action ='ASM')
		--	SET @LEVEL_SHORTNAME = 'ASM'
		--ELSE IF (@Action ='SalesOfficer')
		--	SET @LEVEL_SHORTNAME = 'SLO'
		--ELSE IF(@Action ='Salesman')
		--	SET @LEVEL_SHORTNAME = 'SLM'

		if(isnull(@SearchKey,'')!='')
		Begin		
			select convert(varchar(500),cnt_id)+'|'+CON.cnt_internalId as ID , 
				(isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') ) as [NAME] 
				,EMAP.TARGET_LEVEL_SHORTNAME as INTERNALID, EMP.emp_uniqueCode as CODE
				from FSM_TARGET_EMPMAP EMAP 
				INNER JOIN	tbl_master_contact CON ON EMAP.TARGET_EMPCNTID=CON.cnt_internalId
				INNER JOIN tbl_master_employee EMP ON CON.cnt_internalId=EMP.emp_contactId
			where EMAP.TARGET_LEVEL_ID=@Action and
			((isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') ) like '%'+@SearchKey+'%' 
					OR EMP.emp_uniqueCode like '%'+@SearchKey+'%') ORDER BY [NAME] ASC
		End
		else
		Begin
			select convert(varchar(500),cnt_id)+'|'+CON.cnt_internalId as ID , 
				(isnull(CON.cnt_firstName,'')+' '+isnull(CON.cnt_middleName,'')+' '+isnull(CON.cnt_lastName,'') ) as [NAME] 
				,EMAP.TARGET_LEVEL_SHORTNAME as INTERNALID, EMP.emp_uniqueCode as CODE
				from FSM_TARGET_EMPMAP EMAP 
				INNER JOIN	tbl_master_contact CON ON EMAP.TARGET_EMPCNTID=CON.cnt_internalId
				INNER JOIN tbl_master_employee EMP ON CON.cnt_internalId=EMP.emp_contactId
			where EMAP.TARGET_LEVEL_ID=@Action
		End
		
	END
	
	IF(@Action ='5' ) 
	BEGIN

		if(isnull(@SearchKey,'')!='')
		Begin		
			select convert(varchar(500),ID)+'|'+CODE as ID , NAME ,CODE as INTERNALID,CODE from FSM_GROUPBEAT 
			where CODE_TYPE='BEAT' AND
			(CODE like '%'+@SearchKey+'%' OR NAME like '%'+@SearchKey+'%') ORDER BY NAME ASC
		End
		else
		Begin
			select convert(varchar(500),ID)+'|'+CODE as ID , NAME ,CODE as INTERNALID,CODE from FSM_GROUPBEAT
			where CODE_TYPE='BEAT' 
		End
		
	END
	IF(@Action ='6' ) 
	BEGIN

		if(isnull(@SearchKey,'')!='')
		Begin		
			select convert(varchar(500),Shop_ID)+'|'+Shop_Code as ID , Shop_Name AS NAME ,Shop_Code as INTERNALID,Shop_Code AS CODE from tbl_Master_shop 
			where Entity_Status=1 AND
			(Shop_Code like '%'+@SearchKey+'%' OR Shop_Name like '%'+@SearchKey+'%') ORDER BY NAME ASC
		End
		else
		Begin
			select convert(varchar(500),Shop_ID)+'|'+Shop_Code as ID, Shop_Name AS NAME ,Shop_Code as INTERNALID,Shop_Code AS CODE from tbl_Master_shop 
			where Entity_Status=1 
		End
		
	END

	IF(@Action ='GETPRODUCTLIST' ) 
	BEGIN

		if(isnull(@SearchKey,'')!='')
		Begin		
			select convert(varchar(5000),sProducts_ID)+'|'+sProducts_Code+'|'+sProducts_Name as ID ,sProducts_Code as INTERNALID,sProducts_Code as CODE, sProducts_Name as NAME 
			from Master_sProducts
			where sProduct_Status='A' and
			(sProducts_Code like '%'+@SearchKey+'%' OR sProducts_Name like '%'+@SearchKey+'%') ORDER BY sProducts_Name ASC
		End
		else
		Begin
			select convert(varchar(5000),sProducts_ID)+'|'+sProducts_Code+'|'+sProducts_Name as ID ,sProducts_Code as INTERNALID,sProducts_Code as CODE, sProducts_Name as NAME 
			from Master_sProducts 
			where sProduct_Status='A'
		End
		
	END



	IF(@Action ='GETBRANDLIST' ) 
	BEGIN

		if(isnull(@SearchKey,'')!='')
		Begin		
			select Brand_Id as ID , Brand_Name as NAME 
			from tbl_master_brand
			where Brand_IsActive=1
			and (Brand_Name like '%'+@SearchKey+'%' OR Brand_Name like '%'+@SearchKey+'%') ORDER BY Brand_Name ASC
		End
		else
		Begin
			select Brand_Id as ID , Brand_Name as NAME 
			from tbl_master_brand
			where Brand_IsActive=1
		End
		
	END
END
GO


