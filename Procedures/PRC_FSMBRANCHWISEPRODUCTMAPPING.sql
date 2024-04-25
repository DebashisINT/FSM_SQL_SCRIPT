
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMBRANCHWISEPRODUCTMAPPING]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMBRANCHWISEPRODUCTMAPPING] AS' 
END
GO
ALTER PROC [dbo].[PRC_FSMBRANCHWISEPRODUCTMAPPING]
(
    @Action varchar(55)=null,
	@UserId int=null,	
	@PRODUCTID NVARCHAR(MAX)=null,
	@BRANCHID NVARCHAR(MAX)=NULL,
	@ParentEMPID NVARCHAR(MAX)=NULL,
	@ChildEMPID NVARCHAR(MAX)=NULL,
	@PRODUCTBRANCHMAP_ID  bigint=0
	
)  
As 
/*****************************************************************************************************************************************
Written by : Priti Roy ON 08/04/2024
Module	   : New Branch wise Product mapping module shall be implemented.Refer: 0027290
1.0    V2.0.46     Priti       22-04-2024      BRANCH WISE PRODUCT MAPPING Setting. Mantis: 0027387

**************************************************************************************************************************/
Begin
begin tran t1        
Begin try 
	DECLARE @sqlStrTable NVARCHAR(MAX)
	DECLARE @Branch_Id bigint=0,@PRODUCT_ID bigint=0,@sProducts_Code varchar(80)= NULL,@Emp_Contactid varchar(80)='',@Child_Contactid varchar(80)=''
	Declare @LastCount bigint=0,@IsExist bigint=0
	DECLARE @SUCCESS BIT = 0;
	DECLARE @HASLOG BIT = 0,@LASTID bigint=0

	IF OBJECT_ID('tempdb..#Branch_List') IS NOT NULL
	DROP TABLE #Branch_List
	CREATE TABLE #Branch_List (Branch_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Branch_Id ON #Branch_List (Branch_Id ASC)

	IF OBJECT_ID('tempdb..#Employee_List') IS NOT NULL
	DROP TABLE #Employee_List
	CREATE TABLE #Employee_List (EMP_ID BIGINT NULL)
	CREATE NONCLUSTERED INDEX EMP_ID ON #Employee_List (EMP_ID ASC)	

	IF OBJECT_ID('tempdb..#Product_List') IS NOT NULL
	DROP TABLE #Product_List
	CREATE TABLE #Product_List (PRODUCT_ID BIGINT NULL,sProducts_Code varchar(80) NULL)
	CREATE NONCLUSTERED INDEX PRODUCT_ID ON #Product_List (PRODUCT_ID ASC,sProducts_Code)
	--Rev 1.0		
	Declare @Value Nvarchar(20)=''
	--Rev 1.0 end
	if(@Action)='FETCHBRANCHS'
	Begin	
		--select * from (
		--select branch_id as ID,branch_description,branch_code from tbl_master_branch a where a.branch_id=1  
		--union all 
		--select branch_id as ID,branch_description,branch_code from tbl_master_branch b --where b.branch_parentId=1
		--) a order by branch_description


		select branch_id as ID,branch_description,branch_code from tbl_master_branch
	
	End
	else if(@Action)='FETCHPRODUCTS'
	Begin
		SELECT  SPRODUCTS_ID,SPRODUCTS_NAME,SPRODUCTS_CODE PRODUCT_CODE,SPRODUCTS_NAME PRODUCT_NAME,
		CASE WHEN SPRODUCT_ISINVENTORY=1 THEN 'YES' ELSE 'NO'END ISINVENTORY,
		ISNULL((CASE WHEN SPRODUCT_ISINVENTORY=1 THEN ISNULL(SPRODUCTS_HSNCODE,'') ELSE SERVICE_CATEGORY_CODE END),'') HSNSAC,
		ISNULL(PRODUCTCLASS_NAME,'') CLASSCODE,ISNULL(BRAND_NAME,'') BRANDNAME,
		(CASE WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='0' AND ISNULL(IS_ACTIVE_BATCH,'0')='0' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='0' THEN ''
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='1' AND ISNULL(IS_ACTIVE_BATCH,'0')='0' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='0' THEN 'W'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='0' AND ISNULL(IS_ACTIVE_BATCH,'0')='1' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='0' THEN 'B'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='0' AND ISNULL(IS_ACTIVE_BATCH,'0')='0' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='1' THEN 'S'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='1' AND ISNULL(IS_ACTIVE_BATCH,'0')='1' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='0' THEN 'WB'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='1' AND ISNULL(IS_ACTIVE_BATCH,'0')='0' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='1' THEN 'WS'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='1' AND ISNULL(IS_ACTIVE_BATCH,'0')='1' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='1' THEN 'WBS'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='0' AND ISNULL(IS_ACTIVE_BATCH,'0')='1' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='1' THEN 'BS'
		END) AS PRODUCTTYPE
		 FROM MASTER_SPRODUCTS
		 LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE
		 LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND
		 LEFT OUTER JOIN TBL_MASTER_SERVICE_TAX ON TAX_ID=SPRODUCTS_SERVICETAX
		 Left Outer Join dbo.tbl_master_product_packingDetails  On sProducts_ID=packing_sProductId
		 LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCT_STOCKUOM = STK_MASTER_UOM.UOM_ID 
		 LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID 
		 LEFT OUTER JOIN DBO.MASTER_UOM AS MASTER_UOM ON DBO.tbl_master_product_packingDetails.packing_saleUOM = MASTER_UOM.UOM_ID 

	End
	else if(@Action)='FETCHPARENTEMPLOYEE'
	Begin
		
		--Rev 1.0		
		select @Value=Value from FTS_APP_CONFIG_SETTINGS where [Key]='IsActivateEmployeeBranchHierarchy'	
		--Rev 1.0 end

		IF @BRANCHID <> ''
		BEGIN
		SET @BRANCHID=REPLACE(@BRANCHID,'''','')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #Branch_List select branch_id from tbl_master_branch where branch_id in('+@BRANCHID+')'
		EXEC SP_EXECUTESQL @sqlStrTable
		END

		
			
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #Employee_List select emp_reportTo from tbl_trans_employeeCTC '
		EXEC SP_EXECUTESQL @sqlStrTable
		
		--Rev 1.0
		if(@Value='1')
		Begin
			select DISTINCT cnt_id,emp_reportTo,cnt_internalId,cnt_UCC	
			,CASE WHEN( EMP.CNT_MIDDLENAME IS NULL  OR EMP.CNT_MIDDLENAME='') THEN ISNULL(EMP.CNT_FIRSTNAME,'')+' ' +ISNULL(EMP.CNT_LASTNAME,'')+' '+'('+EMP.cnt_UCC+')' ELSE ISNULL(EMP.CNT_FIRSTNAME,'')+' '+ ISNULL(EMP.CNT_MIDDLENAME,'')+' ' +ISNULL(EMP.CNT_LASTNAME,'')+' '+'('+EMP.cnt_UCC+')' END AS EMPLOYEENAME
			,deg_designation
			from tbl_master_contact EMP			
			inner join tbl_trans_employeeCTC CTC on EMP.cnt_internalId=CTC.emp_cntId
			inner join tbl_master_designation  desig on desig.deg_id=CTC.emp_Designation
			inner join tbl_master_employee  employee on employee.emp_contactId=EMP.cnt_internalId
			where EXISTS (select EMP_ID from #Employee_List as PL where PL.EMP_ID=employee.emp_id) 			
			and EXISTS (select Branch_Id from #Branch_List as BL where BL.Branch_Id=CTC.emp_branch)
		End
		Else		
		Begin
		--Rev 1.0 End
			select DISTINCT cnt_id,emp_reportTo,cnt_internalId,cnt_UCC	
			,CASE WHEN( EMP.CNT_MIDDLENAME IS NULL  OR EMP.CNT_MIDDLENAME='') THEN ISNULL(EMP.CNT_FIRSTNAME,'')+' ' +ISNULL(EMP.CNT_LASTNAME,'')+' '+'('+EMP.cnt_UCC+')' ELSE ISNULL(EMP.CNT_FIRSTNAME,'')+' '+ ISNULL(EMP.CNT_MIDDLENAME,'')+' ' +ISNULL(EMP.CNT_LASTNAME,'')+' '+'('+EMP.cnt_UCC+')' END AS EMPLOYEENAME
			,deg_designation
			from tbl_master_contact EMP
			inner join FTS_EmployeeBranchMap BranchMap on EMP.cnt_internalId=BranchMap.Emp_Contactid
			inner join tbl_trans_employeeCTC CTC on EMP.cnt_internalId=CTC.emp_cntId
			inner join tbl_master_designation  desig on desig.deg_id=CTC.emp_Designation
			inner join tbl_master_employee  employee on employee.emp_contactId=EMP.cnt_internalId
			where EXISTS (select EMP_ID from #Employee_List as PL where PL.EMP_ID=employee.emp_id) 
			and EXISTS (select Branch_Id from #Branch_List as BL where BL.Branch_Id=BranchMap.BranchId)
		--Rev 1.0
		End
		--Rev 1.0 End

	    drop table #Employee_List
		DROP TABLE #Branch_List

	End
	else if(@Action)='FETCHCHILDEMPLOYEE'
	Begin
			
		--Rev 1.0		
		select @Value=Value from FTS_APP_CONFIG_SETTINGS where [Key]='IsActivateEmployeeBranchHierarchy'	
		--Rev 1.0 end


		IF @BRANCHID <> ''
		BEGIN
		SET @BRANCHID=REPLACE(@BRANCHID,'''','')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #Branch_List select branch_id from tbl_master_branch where branch_id in('+@BRANCHID+')'
		EXEC SP_EXECUTESQL @sqlStrTable
		END
				
		
				
		if(isnull(@ParentEMPID,'')='')	
		Begin			
			
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #Employee_List select emp_reportTo from tbl_trans_employeeCTC '
			EXEC SP_EXECUTESQL @sqlStrTable


			SET @sqlStrTable=''
			SET @sqlStrTable=' select DISTINCT cnt_id,emp_reportTo,cnt_internalId,cnt_UCC		
			,CASE WHEN( EMP.CNT_MIDDLENAME IS NULL  OR EMP.CNT_MIDDLENAME='''') THEN ISNULL(EMP.CNT_FIRSTNAME,'''')+'''' +ISNULL(EMP.CNT_LASTNAME,'''')+''''+''(''+EMP.cnt_UCC+'')'' ELSE ISNULL(EMP.CNT_FIRSTNAME,'''')+''''+ ISNULL(EMP.CNT_MIDDLENAME,'''')+'''' +ISNULL(EMP.CNT_LASTNAME,'''')+''''+''(''+EMP.cnt_UCC+'')'' END AS EMPLOYEENAME
			,deg_designation
			from tbl_master_contact EMP '

			if(@Value='0')
			begin
				SET @sqlStrTable+=' inner join FTS_EmployeeBranchMap BranchMap on EMP.cnt_internalId=BranchMap.Emp_Contactid '
			End
			SET @sqlStrTable+=' inner join tbl_trans_employeeCTC CTC on EMP.cnt_internalId=CTC.emp_cntId
			inner join tbl_master_designation  desig on desig.deg_id=CTC.emp_Designation	
			inner join tbl_master_employee  employee on employee.emp_contactId=EMP.cnt_internalId
			where 
			not EXISTS (select EMP_ID from #Employee_List as PL where PL.EMP_ID=employee.emp_id) '
			if(@Value='1')
			begin
			SET @sqlStrTable+=' and EXISTS (select Branch_Id from #Branch_List as BL where BL.Branch_Id=CTC.emp_branch)'
			End
			else
			begin
			SET @sqlStrTable+=' and EXISTS (select Branch_Id from #Branch_List as BL where BL.Branch_Id=BranchMap.BranchId)'
			End

			EXEC SP_EXECUTESQL @sqlStrTable
			
		end
		else
		begin
			SET @ParentEMPID=''''+REPLACE(@ParentEMPID,',',''',''')+''''	
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #Employee_List select emp_id from tbl_master_employee where emp_contactId in ('+@ParentEMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable		

			SET @sqlStrTable=''
			SET @sqlStrTable='
			select DISTINCT cnt_id,emp_reportTo,cnt_internalId,cnt_UCC,		
			CASE WHEN( EMP.CNT_MIDDLENAME IS NULL  OR EMP.CNT_MIDDLENAME='' '') THEN ISNULL(EMP.CNT_FIRSTNAME,'' '')+'' '' +ISNULL(EMP.CNT_LASTNAME,'' '')+'' '' ELSE ISNULL(EMP.CNT_FIRSTNAME,'''')+'' ''+ ISNULL(EMP.CNT_MIDDLENAME,'' '')+'' '' +ISNULL(EMP.CNT_LASTNAME,'' '')+'''' END AS EMPLOYEENAME
			,deg_designation
			from tbl_master_contact EMP '
			if(@Value='0')
			begin
			SET @sqlStrTable+=' inner join FTS_EmployeeBranchMap BranchMap on EMP.cnt_internalId=BranchMap.Emp_Contactid'
			End
			SET @sqlStrTable+=' inner join tbl_trans_employeeCTC CTC on EMP.cnt_internalId=CTC.emp_cntId
			inner join tbl_master_designation  desig on desig.deg_id=CTC.emp_Designation
			inner join tbl_master_employee  employee on employee.emp_contactId=EMP.cnt_internalId
			where 
			EXISTS (select EMP_ID from #Employee_List as PL where PL.EMP_ID=CTC.emp_reportTo)  '

			if(@Value='1')
			begin
			SET @sqlStrTable+=' and EXISTS (select Branch_Id from #Branch_List as BL where BL.Branch_Id=CTC.emp_branch)'
			End
			else
			begin
			SET @sqlStrTable+=' and EXISTS (select Branch_Id from #Branch_List as BL where BL.Branch_Id=BranchMap.BranchId)'
			End
			
			EXEC SP_EXECUTESQL @sqlStrTable
		end
	    drop table #Employee_List
		DROP TABLE #Branch_List

	End
	ELSE IF @ACTION='Add'
	Begin
		
				
				IF @BRANCHID <> ''
				BEGIN
				SET @BRANCHID=REPLACE(@BRANCHID,'''','')
				SET @sqlStrTable=''
				SET @sqlStrTable=' INSERT INTO #Branch_List select branch_id from tbl_master_branch where branch_id in('+@BRANCHID+')'
				EXEC SP_EXECUTESQL @sqlStrTable
				END

			

				IF @PRODUCTID <> ''
				BEGIN
				SET @PRODUCTID=REPLACE(@PRODUCTID,'''','')
				SET @sqlStrTable=''
				SET @sqlStrTable=' INSERT INTO #Product_List select sProducts_ID,sProducts_Code from Master_sProducts where sProducts_ID in('+@PRODUCTID+')'
				EXEC SP_EXECUTESQL @sqlStrTable
				END

				IF OBJECT_ID('tempdb..#EMP1_List') IS NOT NULL
				DROP TABLE #EMP1_List
				CREATE TABLE #EMP1_List (emp_contactId nvarchar(100) null,BranchId bigint null)
				CREATE NONCLUSTERED INDEX emp_contactId ON #EMP1_List (emp_contactId ASC)

				IF @ParentEMPID <> ''
				BEGIN				
				SET @ParentEMPID=''''+REPLACE(@ParentEMPID,',',''',''')+''''				
				SET @sqlStrTable=''
				SET @sqlStrTable=' INSERT INTO #EMP1_List select Emp_Contactid,BranchId from FTS_EmployeeBranchMap where Emp_Contactid in('+@ParentEMPID+')'
				EXEC SP_EXECUTESQL @sqlStrTable				
				END

				IF OBJECT_ID('tempdb..#CHILDEMP_List') IS NOT NULL
				DROP TABLE #CHILDEMP_List
				CREATE TABLE #CHILDEMP_List (BranchId bigint null,Parent_contactId nvarchar(100) null,Child_contactId nvarchar(100) null)
				CREATE NONCLUSTERED INDEX Child_contactId ON #CHILDEMP_List (Child_contactId ASC)
				IF @ChildEMPID <> ''
				BEGIN				
					SET @ChildEMPID=''''+REPLACE(@ChildEMPID,',',''',''')+''''	
				END



				DECLARE db_cursorBranch CURSOR FOR  
				select Branch_Id from #Branch_List
				OPEN db_cursorBranch   
				FETCH NEXT FROM db_cursorBranch INTO @Branch_Id
				WHILE @@FETCH_STATUS = 0   
				BEGIN

							IF (select count(0) from #EMP1_List)<>0
							Begin

								IF @ChildEMPID <> ''
								BEGIN				
											
								SET @sqlStrTable=''
								SET @sqlStrTable='	INSERT INTO #CHILDEMP_List select BranchId,emp.emp_contactId,map.Emp_Contactid from FTS_EmployeeBranchMap map 
													inner join tbl_trans_employeeCTC ctc on ctc.emp_cntId=map.Emp_Contactid
													inner join tbl_master_employee emp on emp.emp_id=ctc.emp_reportTo 
													where map.Emp_Contactid in('+@ChildEMPID+')'									

								EXEC SP_EXECUTESQL @sqlStrTable				
								END


								DECLARE db_cursorParentEMP CURSOR FOR  
								select Emp_Contactid,BranchId from #EMP1_List  where BranchId=@Branch_Id
								OPEN db_cursorParentEMP   
								FETCH NEXT FROM db_cursorParentEMP INTO @Emp_Contactid,@Branch_Id
								WHILE @@FETCH_STATUS = 0   
								BEGIN
											
											IF (select count(0) from #CHILDEMP_List)<>0
											Begin

												DECLARE db_cursorCHILDEMP CURSOR FOR  
												select Child_contactId,Parent_contactId,BranchId from #CHILDEMP_List  where BranchId=@Branch_Id  and isnull(Parent_contactId,'')=@Emp_Contactid
												OPEN db_cursorCHILDEMP   
												FETCH NEXT FROM db_cursorCHILDEMP INTO @Child_Contactid,@Emp_Contactid,@Branch_Id
												WHILE @@FETCH_STATUS = 0   
												BEGIN

																DECLARE db_cursorProduct CURSOR FOR  
																select PRODUCT_ID,sProducts_Code from #Product_List
																OPEN db_cursorProduct   
																FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
																WHILE @@FETCH_STATUS = 0   
																BEGIN													
								
																	select top 1 @LastCount=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP  order by PRODUCTBRANCHMAP_ID desc
																	select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@Branch_Id  and PRODUCT_ID=@PRODUCT_ID  and isnull(PARENTEMP_INTERNALID,'')=@Emp_Contactid  and isnull(CHILDEMP_INTERNALID,'')=@Child_Contactid
																	if(@IsExist=0)
																	Begin
																		insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,PARENTEMP_INTERNALID,CHILDEMP_INTERNALID,CREATED_BY,CREATED_ON)
																		select @LastCount+1,@Branch_Id,@sProducts_Code,@PRODUCT_ID,@Emp_Contactid,@Child_Contactid,@UserId,Getdate()

																		set @LASTID=SCOPE_IDENTITY();													
																	END

																FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
																END   

																CLOSE db_cursorProduct   
																DEALLOCATE db_cursorProduct

												FETCH NEXT FROM db_cursorCHILDEMP INTO @Child_Contactid,@Emp_Contactid,@Branch_Id
												END   

												CLOSE db_cursorCHILDEMP   
												DEALLOCATE db_cursorCHILDEMP


											End
											Else
											Begin
												DECLARE db_cursorProduct CURSOR FOR  
												select PRODUCT_ID,sProducts_Code from #Product_List
												OPEN db_cursorProduct   
												FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
												WHILE @@FETCH_STATUS = 0   
												BEGIN

													
								
													select top 1 @LastCount=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP  order by PRODUCTBRANCHMAP_ID desc


													select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@Branch_Id  and PRODUCT_ID=@PRODUCT_ID  and isnull(PARENTEMP_INTERNALID,'')=@Emp_Contactid
													if(@IsExist=0)
													Begin
														insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,PARENTEMP_INTERNALID,CREATED_BY,CREATED_ON)
														select @LastCount+1,@Branch_Id,@sProducts_Code,@PRODUCT_ID,@Emp_Contactid,@UserId,Getdate()

														set @LASTID=SCOPE_IDENTITY();

													
													END

												FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
												END   

												CLOSE db_cursorProduct   
												DEALLOCATE db_cursorProduct
											End

								FETCH NEXT FROM db_cursorParentEMP INTO @Emp_Contactid,@Branch_Id
								END   

								CLOSE db_cursorParentEMP   
								DEALLOCATE db_cursorParentEMP

											
							END
							else
							begin
									IF @ChildEMPID <> ''
									BEGIN				
									--SET @ChildEMPID=''''+REPLACE(@ChildEMPID,',',''',''')+''''				
									SET @sqlStrTable=''
									--SET @sqlStrTable='	INSERT INTO #CHILDEMP_List(BranchId,Parent_contactId,Child_contactId) select BranchId,emp.emp_contactId,map.Emp_Contactid from FTS_EmployeeBranchMap map 
									--					inner join tbl_trans_employeeCTC ctc on ctc.emp_cntId=map.Emp_Contactid
									--					left outer join tbl_master_employee emp on emp.emp_id=ctc.emp_reportTo
									--					where map.Emp_Contactid in('+@ChildEMPID+')'

									--SET @sqlStrTable='	INSERT INTO #CHILDEMP_List(BranchId,Child_contactId) select BranchId,map.Emp_Contactid from FTS_EmployeeBranchMap map 
									--					inner join tbl_trans_employeeCTC ctc on ctc.emp_cntId=map.Emp_Contactid														
									--					where map.Emp_Contactid in('+@ChildEMPID+')'

														
									SET @sqlStrTable='INSERT INTO #CHILDEMP_List(BranchId,Parent_contactId,Child_contactId) '
									SET @sqlStrTable+='select distinct map.BranchId,emp.emp_contactId,map.Emp_Contactid from FTS_EmployeeBranchMap map 
									inner join tbl_trans_employeeCTC ctc on ctc.emp_cntId=map.Emp_Contactid
									left outer join 
									(select emp_id,emp1.emp_contactId,BranchId from tbl_master_employee emp1
									inner join FTS_EmployeeBranchMap map1 on map1.Emp_Contactid=emp1.emp_contactId
									) EMP
									  on EMP.emp_id=ctc.emp_reportTo  and EMP.BranchId= map.BranchId
									where map.Emp_Contactid in('+@ChildEMPID+')'

									EXEC SP_EXECUTESQL @sqlStrTable				
									END

								IF (select count(0) from #CHILDEMP_List)<>0
								Begin
									
									

									DECLARE db_cursorCHILDEMP CURSOR FOR  
									select Child_contactId,BranchId from #CHILDEMP_List  where BranchId=@Branch_Id  									
									OPEN db_cursorCHILDEMP   
									FETCH NEXT FROM db_cursorCHILDEMP INTO @Child_Contactid,@Branch_Id									
									WHILE @@FETCH_STATUS = 0   
									BEGIN

													DECLARE db_cursorProduct CURSOR FOR  
													select PRODUCT_ID,sProducts_Code from #Product_List
													OPEN db_cursorProduct   
													FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
													WHILE @@FETCH_STATUS = 0   
													BEGIN													
								
														select top 1 @LastCount=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP  order by PRODUCTBRANCHMAP_ID desc
														select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@Branch_Id  and PRODUCT_ID=@PRODUCT_ID    and isnull(CHILDEMP_INTERNALID,'')=@Child_Contactid
														
														if(@IsExist=0)
														Begin
															insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,CHILDEMP_INTERNALID,CREATED_BY,CREATED_ON)
															select @LastCount+1,@Branch_Id,@sProducts_Code,@PRODUCT_ID,@Child_Contactid,@UserId,Getdate()

															set @LASTID=SCOPE_IDENTITY();													
														END

													FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
													END   

													CLOSE db_cursorProduct   
													DEALLOCATE db_cursorProduct

									FETCH NEXT FROM db_cursorCHILDEMP INTO @Child_Contactid,@Branch_Id
									END   

									CLOSE db_cursorCHILDEMP   
									DEALLOCATE db_cursorCHILDEMP


								End
								Else
								Begin
									DECLARE db_cursorProduct CURSOR FOR  
									select PRODUCT_ID,sProducts_Code from #Product_List
									OPEN db_cursorProduct   
									FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
									WHILE @@FETCH_STATUS = 0   
									BEGIN
								
										select top 1 @LastCount=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP  order by PRODUCTBRANCHMAP_ID desc


										select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@Branch_Id  and PRODUCT_ID=@PRODUCT_ID
										if(@IsExist=0)
										Begin
											insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,CREATED_BY,CREATED_ON)
											select @LastCount+1,@Branch_Id,@sProducts_Code,@PRODUCT_ID,@UserId,Getdate()

											set @LASTID=SCOPE_IDENTITY();
										END

									FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
									END   

									CLOSE db_cursorProduct   
									DEALLOCATE db_cursorProduct
								End
							End
								

				FETCH NEXT FROM db_cursorBranch INTO @Branch_Id
				END   

				CLOSE db_cursorBranch   
				DEALLOCATE db_cursorBranch

			
				SET @HASLOG = 1;
				SET @SUCCESS = 1;

				drop table #Branch_List
				drop table #Product_List
				DROP TABLE #EMP1_List
				DROP TABLE #CHILDEMP_List
	End
	ELSE IF @ACTION='Delete'
	Begin
		delete from PRODUCT_BRANCH_MAP where PRODUCTBRANCHMAP_ID=@PRODUCTBRANCHMAP_ID
		delete from PRODUCTBRANCHMAPLIST where PRODUCTBRANCHMAP_ID=@PRODUCTBRANCHMAP_ID  and USERID=@UserId
		SELECT '1' AS INSERTMSG
	End
	ELSE IF @ACTION='FETCHBRANCHMAP'
	Begin

		select @BRANCH_ID=BRANCH_ID from PRODUCT_BRANCH_MAP where PRODUCTBRANCHMAP_ID=@PRODUCTBRANCHMAP_ID

		select branch_id as ID,branch_description,branch_code from tbl_master_branch


		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #Employee_List select emp_reportTo from tbl_trans_employeeCTC '
		EXEC SP_EXECUTESQL @sqlStrTable
		

		select DISTINCT cnt_id,emp_reportTo,cnt_internalId,cnt_UCC	
		,CASE WHEN( EMP.CNT_MIDDLENAME IS NULL  OR EMP.CNT_MIDDLENAME='') THEN ISNULL(EMP.CNT_FIRSTNAME,'')+' ' +ISNULL(EMP.CNT_LASTNAME,'')+' '+'('+EMP.cnt_UCC+')' ELSE ISNULL(EMP.CNT_FIRSTNAME,'')+' '+ ISNULL(EMP.CNT_MIDDLENAME,'')+' ' +ISNULL(EMP.CNT_LASTNAME,'')+' '+'('+EMP.cnt_UCC+')' END AS EMPLOYEENAME
		,deg_designation
		from tbl_master_contact EMP
		inner join FTS_EmployeeBranchMap BranchMap on EMP.cnt_internalId=BranchMap.Emp_Contactid
		inner join tbl_trans_employeeCTC CTC on EMP.cnt_internalId=CTC.emp_cntId
		inner join tbl_master_designation  desig on desig.deg_id=CTC.emp_Designation
		inner join tbl_master_employee  employee on employee.emp_contactId=EMP.cnt_internalId
		where EXISTS (select EMP_ID from #Employee_List as PL where PL.EMP_ID=employee.emp_id) 
		and BranchMap.BranchId=@BRANCH_ID

	    drop table #Employee_List
		

		select DISTINCT EMP.cnt_id,EMP.cnt_internalId,EMP.cnt_UCC,		
		CASE WHEN( EMP.CNT_MIDDLENAME IS NULL  OR EMP.CNT_MIDDLENAME='') THEN ISNULL(EMP.CNT_FIRSTNAME,'')+' ' +ISNULL(EMP.CNT_LASTNAME,'')+' ' ELSE ISNULL(EMP.CNT_FIRSTNAME,'')+' '+ ISNULL(EMP.CNT_MIDDLENAME,'')+' ' +ISNULL(EMP.CNT_LASTNAME,'')+' ' END AS EMPLOYEENAME
		,desig.deg_designation
		from tbl_master_contact EMP
		inner join FTS_EmployeeBranchMap BranchMap on EMP.cnt_internalId=BranchMap.Emp_Contactid
		inner join tbl_trans_employeeCTC CTC on EMP.cnt_internalId=CTC.emp_cntId
		inner join tbl_master_designation  desig on desig.deg_id=CTC.emp_Designation		
		where cnt_internalId in (SELECT CHILDEMP_INTERNALID FROM PRODUCT_BRANCH_MAP  WHERE BRANCH_ID=@BRANCH_ID)


		SELECT  SPRODUCTS_ID,SPRODUCTS_NAME,SPRODUCTS_CODE PRODUCT_CODE,SPRODUCTS_NAME PRODUCT_NAME,
		CASE WHEN SPRODUCT_ISINVENTORY=1 THEN 'YES' ELSE 'NO'END ISINVENTORY,
		ISNULL((CASE WHEN SPRODUCT_ISINVENTORY=1 THEN ISNULL(SPRODUCTS_HSNCODE,'') ELSE SERVICE_CATEGORY_CODE END),'') HSNSAC,
		ISNULL(PRODUCTCLASS_NAME,'') CLASSCODE,ISNULL(BRAND_NAME,'') BRANDNAME,
		(CASE WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='0' AND ISNULL(IS_ACTIVE_BATCH,'0')='0' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='0' THEN ''
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='1' AND ISNULL(IS_ACTIVE_BATCH,'0')='0' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='0' THEN 'W'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='0' AND ISNULL(IS_ACTIVE_BATCH,'0')='1' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='0' THEN 'B'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='0' AND ISNULL(IS_ACTIVE_BATCH,'0')='0' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='1' THEN 'S'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='1' AND ISNULL(IS_ACTIVE_BATCH,'0')='1' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='0' THEN 'WB'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='1' AND ISNULL(IS_ACTIVE_BATCH,'0')='0' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='1' THEN 'WS'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='1' AND ISNULL(IS_ACTIVE_BATCH,'0')='1' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='1' THEN 'WBS'
		WHEN ISNULL(IS_ACTIVE_WAREHOUSE,'0')='0' AND ISNULL(IS_ACTIVE_BATCH,'0')='1' AND ISNULL(IS_ACTIVE_SERIALNO,'0')='1' THEN 'BS'
		END) AS PRODUCTTYPE
		 FROM MASTER_SPRODUCTS
		 LEFT OUTER JOIN MASTER_PRODUCTCLASS ON PRODUCTCLASS_ID=MASTER_SPRODUCTS.PRODUCTCLASS_CODE
		 LEFT OUTER JOIN  TBL_MASTER_BRAND ON BRAND_ID=SPRODUCTS_BRAND
		 LEFT OUTER JOIN TBL_MASTER_SERVICE_TAX ON TAX_ID=SPRODUCTS_SERVICETAX
		 Left Outer Join dbo.tbl_master_product_packingDetails  On sProducts_ID=packing_sProductId
		 LEFT OUTER JOIN DBO.MASTER_UOM AS STK_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCT_STOCKUOM = STK_MASTER_UOM.UOM_ID 
		 LEFT OUTER JOIN DBO.MASTER_UOM AS SALES_MASTER_UOM ON DBO.MASTER_SPRODUCTS.SPRODUCTS_QUOTELOTUNIT = SALES_MASTER_UOM.UOM_ID 
		 LEFT OUTER JOIN DBO.MASTER_UOM AS MASTER_UOM ON DBO.tbl_master_product_packingDetails.packing_saleUOM = MASTER_UOM.UOM_ID 

		
		
		SELECT @BRANCH_ID as BRANCH_ID,IsNull((SELECT Stuff((	
		Select DISTINCT ', ' + cast(PARENTEMP_INTERNALID as nvarchar(max)) 	FROM PRODUCT_BRANCH_MAP  WHERE BRANCH_ID=@BRANCH_ID
		For XML Path ('')),1,2,'')),'') as PARENTEMP_INTERNALID, 

		IsNull((SELECT Stuff((	
		Select DISTINCT ', ' + cast(CHILDEMP_INTERNALID as nvarchar(max)) 	FROM PRODUCT_BRANCH_MAP  WHERE BRANCH_ID=@BRANCH_ID
		For XML Path ('')),1,2,'')),'') as CHILDEMP_INTERNALID,

		IsNull((SELECT Stuff((	
		Select DISTINCT ', ' + cast(PRODUCT_ID as varchar(100)) 	FROM PRODUCT_BRANCH_MAP  WHERE BRANCH_ID=@BRANCH_ID
		For XML Path ('')),1,2,'')),'') as PRODUCT_ID

		



	End
	ELSE IF @ACTION='EDIT'
	BEGIN
		DELETE from PRODUCT_BRANCH_MAP where PRODUCTBRANCHMAP_ID=@PRODUCTBRANCHMAP_ID

		IF @BRANCHID <> ''
				BEGIN
				SET @BRANCHID=REPLACE(@BRANCHID,'''','')
				SET @sqlStrTable=''
				SET @sqlStrTable=' INSERT INTO #Branch_List select branch_id from tbl_master_branch where branch_id in('+@BRANCHID+')'
				EXEC SP_EXECUTESQL @sqlStrTable
				END

				

				IF @PRODUCTID <> ''
				BEGIN
				SET @PRODUCTID=REPLACE(@PRODUCTID,'''','')
				SET @sqlStrTable=''
				SET @sqlStrTable=' INSERT INTO #Product_List select sProducts_ID,sProducts_Code from Master_sProducts where sProducts_ID in('+@PRODUCTID+')'
				EXEC SP_EXECUTESQL @sqlStrTable
				END

				IF OBJECT_ID('tempdb..#EMP1_ListEDIT') IS NOT NULL
				DROP TABLE #EMP1_ListEDIT
				CREATE TABLE #EMP1_ListEDIT (emp_contactId nvarchar(100) null,BranchId bigint null)
				CREATE NONCLUSTERED INDEX emp_contactId ON #EMP1_ListEDIT (emp_contactId ASC)

				IF @ParentEMPID <> ''
				BEGIN				
				SET @ParentEMPID=''''+REPLACE(@ParentEMPID,',',''',''')+''''				
				SET @sqlStrTable=''
				SET @sqlStrTable=' INSERT INTO #EMP1_ListEDIT select Emp_Contactid,BranchId from FTS_EmployeeBranchMap where Emp_Contactid in('+@ParentEMPID+')'
				EXEC SP_EXECUTESQL @sqlStrTable				
				END

				IF OBJECT_ID('tempdb..#CHILDEMP_ListEDIT') IS NOT NULL
				DROP TABLE #CHILDEMP_ListEDIT
				CREATE TABLE #CHILDEMP_ListEDIT (BranchId bigint null,Parent_contactId nvarchar(100) null,Child_contactId nvarchar(100) null)
				CREATE NONCLUSTERED INDEX Child_contactId ON #CHILDEMP_ListEDIT (Child_contactId ASC)

				



				DECLARE db_cursorBranch CURSOR FOR  
				select Branch_Id from #Branch_List
				OPEN db_cursorBranch   
				FETCH NEXT FROM db_cursorBranch INTO @Branch_Id
				WHILE @@FETCH_STATUS = 0   
				BEGIN

							IF (select count(0) from #EMP1_ListEDIT)<>0
							Begin

								IF @ChildEMPID <> ''
								BEGIN				
								SET @ChildEMPID=''''+REPLACE(@ChildEMPID,',',''',''')+''''				
								SET @sqlStrTable=''
								SET @sqlStrTable='	INSERT INTO #CHILDEMP_ListEDIT select BranchId,emp.emp_contactId,map.Emp_Contactid from FTS_EmployeeBranchMap map 
													inner join tbl_trans_employeeCTC ctc on ctc.emp_cntId=map.Emp_Contactid
													inner join tbl_master_employee emp on emp.emp_id=ctc.emp_reportTo 
													where map.Emp_Contactid in('+@ChildEMPID+')'									

								EXEC SP_EXECUTESQL @sqlStrTable				
								END


								DECLARE db_cursorParentEMP CURSOR FOR  
								select Emp_Contactid,BranchId from #EMP1_ListEDIT where BranchId=@Branch_Id
								OPEN db_cursorParentEMP   
								FETCH NEXT FROM db_cursorParentEMP INTO @Emp_Contactid,@Branch_Id
								WHILE @@FETCH_STATUS = 0   
								BEGIN
											
											IF (select count(0) from #CHILDEMP_ListEDIT)<>0
											Begin

												DECLARE db_cursorCHILDEMP CURSOR FOR  
												select Child_contactId,Parent_contactId,BranchId from #CHILDEMP_ListEDIT  where BranchId=@Branch_Id  and isnull(Parent_contactId,'')=@Emp_Contactid
												OPEN db_cursorCHILDEMP   
												FETCH NEXT FROM db_cursorCHILDEMP INTO @Child_Contactid,@Emp_Contactid,@Branch_Id
												WHILE @@FETCH_STATUS = 0   
												BEGIN

																DECLARE db_cursorProduct CURSOR FOR  
																select PRODUCT_ID,sProducts_Code from #Product_List
																OPEN db_cursorProduct   
																FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
																WHILE @@FETCH_STATUS = 0   
																BEGIN													
								
																	select top 1 @LastCount=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP  order by PRODUCTBRANCHMAP_ID desc
																	select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@Branch_Id  and PRODUCT_ID=@PRODUCT_ID  and isnull(PARENTEMP_INTERNALID,'')=@Emp_Contactid  and isnull(CHILDEMP_INTERNALID,'')=@Child_Contactid
																	if(@IsExist=0)
																	Begin
																		insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,PARENTEMP_INTERNALID,CHILDEMP_INTERNALID,CREATED_BY,CREATED_ON)
																		select @LastCount+1,@Branch_Id,@sProducts_Code,@PRODUCT_ID,@Emp_Contactid,@Child_Contactid,@UserId,Getdate()

																		set @LASTID=SCOPE_IDENTITY();													
																	END

																FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
																END   

																CLOSE db_cursorProduct   
																DEALLOCATE db_cursorProduct

												FETCH NEXT FROM db_cursorCHILDEMP INTO @Child_Contactid,@Emp_Contactid,@Branch_Id
												END   

												CLOSE db_cursorCHILDEMP   
												DEALLOCATE db_cursorCHILDEMP


											End
											Else
											Begin
												DECLARE db_cursorProduct CURSOR FOR  
												select PRODUCT_ID,sProducts_Code from #Product_List
												OPEN db_cursorProduct   
												FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
												WHILE @@FETCH_STATUS = 0   
												BEGIN

													
								
													select top 1 @LastCount=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP  order by PRODUCTBRANCHMAP_ID desc


													select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@Branch_Id  and PRODUCT_ID=@PRODUCT_ID  and isnull(PARENTEMP_INTERNALID,'')=@Emp_Contactid
													if(@IsExist=0)
													Begin
														insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,PARENTEMP_INTERNALID,CREATED_BY,CREATED_ON)
														select @LastCount+1,@Branch_Id,@sProducts_Code,@PRODUCT_ID,@Emp_Contactid,@UserId,Getdate()

														set @LASTID=SCOPE_IDENTITY();

													
													END

												FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
												END   

												CLOSE db_cursorProduct   
												DEALLOCATE db_cursorProduct
											End

								FETCH NEXT FROM db_cursorParentEMP INTO @Emp_Contactid,@Branch_Id
								END   

								CLOSE db_cursorParentEMP   
								DEALLOCATE db_cursorParentEMP

											
							END
							else
							begin
									IF @ChildEMPID <> ''
									BEGIN				
									SET @ChildEMPID=''''+REPLACE(@ChildEMPID,',',''',''')+''''				
									SET @sqlStrTable=''
						

														
									SET @sqlStrTable='INSERT INTO #CHILDEMP_ListEDIT(BranchId,Parent_contactId,Child_contactId) 
									select distinct map.BranchId,emp.emp_contactId,map.Emp_Contactid from FTS_EmployeeBranchMap map 
									inner join tbl_trans_employeeCTC ctc on ctc.emp_cntId=map.Emp_Contactid
									left outer join 
									(select emp_id,emp1.emp_contactId,BranchId from tbl_master_employee emp1
									inner join FTS_EmployeeBranchMap map1 on map1.Emp_Contactid=emp1.emp_contactId
									) EMP
									  on EMP.emp_id=ctc.emp_reportTo  and EMP.BranchId= map.BranchId
									where map.Emp_Contactid in('+@ChildEMPID+')'

									EXEC SP_EXECUTESQL @sqlStrTable				
									END

								IF (select count(0) from #CHILDEMP_ListEDIT)<>0
								Begin
									
									

									DECLARE db_cursorCHILDEMP CURSOR FOR  
									select Child_contactId,Parent_contactId,BranchId from #CHILDEMP_ListEDIT  where BranchId=@Branch_Id  									
									OPEN db_cursorCHILDEMP   
									FETCH NEXT FROM db_cursorCHILDEMP INTO @Child_Contactid,@Emp_Contactid,@Branch_Id									
									WHILE @@FETCH_STATUS = 0   
									BEGIN

													DECLARE db_cursorProduct CURSOR FOR  
													select PRODUCT_ID,sProducts_Code from #Product_List
													OPEN db_cursorProduct   
													FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
													WHILE @@FETCH_STATUS = 0   
													BEGIN													
								
														select top 1 @LastCount=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP  order by PRODUCTBRANCHMAP_ID desc
														select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@Branch_Id  and PRODUCT_ID=@PRODUCT_ID  and isnull(PARENTEMP_INTERNALID,'')=@Emp_Contactid  and isnull(CHILDEMP_INTERNALID,'')=@Child_Contactid
														
														if(@IsExist=0)
														Begin
															insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,PARENTEMP_INTERNALID,CHILDEMP_INTERNALID,CREATED_BY,CREATED_ON)
															select @LastCount+1,@Branch_Id,@sProducts_Code,@PRODUCT_ID,@Emp_Contactid,@Child_Contactid,@UserId,Getdate()

															set @LASTID=SCOPE_IDENTITY();													
														END

													FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
													END   

													CLOSE db_cursorProduct   
													DEALLOCATE db_cursorProduct

									FETCH NEXT FROM db_cursorCHILDEMP INTO @Child_Contactid,@Emp_Contactid,@Branch_Id
									END   

									CLOSE db_cursorCHILDEMP   
									DEALLOCATE db_cursorCHILDEMP


								End
								Else
								Begin
									DECLARE db_cursorProduct CURSOR FOR  
									select PRODUCT_ID,sProducts_Code from #Product_List
									OPEN db_cursorProduct   
									FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
									WHILE @@FETCH_STATUS = 0   
									BEGIN
								
										select top 1 @LastCount=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP  order by PRODUCTBRANCHMAP_ID desc


										select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@Branch_Id  and PRODUCT_ID=@PRODUCT_ID
										if(@IsExist=0)
										Begin
											insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,CREATED_BY,CREATED_ON)
											select @LastCount+1,@Branch_Id,@sProducts_Code,@PRODUCT_ID,@UserId,Getdate()

											set @LASTID=SCOPE_IDENTITY();
										END

									FETCH NEXT FROM db_cursorProduct INTO @PRODUCT_ID,@sProducts_Code
									END   

									CLOSE db_cursorProduct   
									DEALLOCATE db_cursorProduct
								End
							End
								

				FETCH NEXT FROM db_cursorBranch INTO @Branch_Id
				END   

				CLOSE db_cursorBranch   
				DEALLOCATE db_cursorBranch

			
				SET @HASLOG = 1;
				SET @SUCCESS = 1;

				drop table #Branch_List
				drop table #Product_List
				DROP TABLE #EMP1_ListEDIT
				DROP TABLE #CHILDEMP_ListEDIT

	END
 commit tran t1          
SELECT @SUCCESS AS Success,'SUCCESS' as MSG ,@HASLOG AS HasLog  ,@LASTID as internal_id 
 return         
End Try      
      
Begin Catch      
rollback tran t1
 
select ERROR_MESSAGE() AS Success ,ERROR_MESSAGE() as MSG,@HASLOG AS HasLog  ,@LASTID as internal_id            
		
return    

End Catch
	
end	
    