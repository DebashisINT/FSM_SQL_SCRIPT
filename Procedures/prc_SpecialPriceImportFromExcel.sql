IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_SpecialPriceImportFromExcel]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_SpecialPriceImportFromExcel] AS'  
 END 
 GO 

ALTER PROC [dbo].[prc_SpecialPriceImportFromExcel]
(

    @Action varchar(55)=null,
	@UserId int=null,
	@BRANCH varchar(200)=null,
	@PRODUCTCODE Varchar(200)=null,
	@PRODUCTNAME varchar(200)=null,
	@SPECIALPRICE numeric(18,2)=0,
	@decription  nvarchar(500)=null,
	@status varchar(20)=null,
	@SPECIALPRICEID bigint=0,
	@ProductID  bigint=0,
	@BranchId  bigint=0,
	@FileName Nvarchar(500)=null,
	@LOOPCOUNTER BIGINT=0,
	@SearchKey varchaR(50) ='',
	--Rev 1.0 
	@DesignationId BIGINT=0,
	@EMPINTERNALID nvarchar(100) ='',
	@USERLOGINID  nvarchar(200) =null
	--Rev 1.0  End
)  
As 
/*****************************************************************************************************************************************
Written by : Priti Roy ON 02/04/2024
Module	   : New Price Upload module shall be implemented named as Special Price Upload.Refer: 0027292
1.0        03-06-2024         2.0.47            Priti               	0027493: Modification in ITC special price upload module.

**************************************************************************************************************************/
Begin
begin tran t1        
Begin try 
DECLARE @SUCCESS BIT = 0;
DECLARE @HASLOG BIT = 0;
declare @IsExist bigint=0,@IsExistSPECIAL_PRICE bigint=0;
 Declare @LastCount bigint=0,@ProductsID bigint=0,@LASTID bigint=0,@branch_id bigint=0,@LastBRANCH_MAP bigint=0
	
	

	if(@Action)='InsertSpecialPriceDataFromExcel'
	Begin


	   /*-----------------------Validation start-------------------------*/
	           if(@PRODUCTCODE)=''
			   Begin
			       rollback tran t1 
					SET @HASLOG = 0;
					SET @SUCCESS =0;         
					select 'Product Code can not be blank' as MSG,@HASLOG AS HasLog ,@SUCCESS AS Success  ,'' as internal_id       
					return
			   End

			    if(@BRANCH)=''
			   Begin
			       rollback tran t1 
					SET @HASLOG = 0;
					SET @SUCCESS =0;         
					select 'Branch can not be blank' as MSG,@HASLOG AS HasLog ,@SUCCESS AS Success   ,'' as internal_id  
					return
			   End			    
			    if(@SPECIALPRICE)=0
			   Begin
			       rollback tran t1 
					SET @HASLOG = 0;
					SET @SUCCESS =0;         
					select 'SPECIAL PRICE can not be blank' as MSG,@HASLOG AS HasLog ,@SUCCESS AS Success,'' as internal_id   
					return
			   End

			  --Rev 1.0 
			  if(Isnull(@USERLOGINID,'')!='')
			  Begin
					select @EMPINTERNALID=user_contactId from tbl_master_user  where user_loginId=@USERLOGINID
					select @DesignationId=cast(emp_Designation as int) from tbl_trans_employeeCTC  where emp_cntId=@EMPINTERNALID

			  End
			  --Rev 1.0  End

			   --select @LastCount=count(0) from PRODUCT_SPECIAL_PRICE_BRANCHWISE
			   select top 1 @LastCount=ID from PRODUCT_SPECIAL_PRICE_BRANCHWISE  order by ID desc

			   select @ProductsID=sProducts_ID from Master_sProducts where sProducts_Code=LTRIM(RTRIM(@PRODUCTCODE))
			   select @branch_id=branch_id from tbl_master_branch  where branch_description=LTRIM(RTRIM(@BRANCH))

			   if(@branch_id<>0 and @ProductsID<>0)
			   Begin
					select @IsExist=count(0) from PRODUCT_BRANCH_MAP  where BRANCH_ID=@branch_id  and PRODUCT_ID=@ProductsID

				   if(@IsExist=0)
				   Begin
						 --select @LastBRANCH_MAP=count(0) from PRODUCT_BRANCH_MAP
						 select top 1 @LastBRANCH_MAP=PRODUCTBRANCHMAP_ID from PRODUCT_BRANCH_MAP order by PRODUCTBRANCHMAP_ID desc
						insert into PRODUCT_BRANCH_MAP(PRODUCTBRANCHMAP_ID,BRANCH_ID,PRODUCT_CODE,PRODUCT_ID,CREATED_BY,CREATED_ON)
						select @LastBRANCH_MAP+1,@branch_id,LTRIM(RTRIM(@PRODUCTCODE)),@ProductsID,@UserId,GETDATE()
				   End
			   END

			 
			  select @IsExistSPECIAL_PRICE=count(0) from PRODUCT_SPECIAL_PRICE_BRANCHWISE  where BRANCH_ID=@branch_id  and PRODUCT_ID=@ProductsID  and isnull(EMPINTERNALID,'')=LTRIM(RTRIM(@EMPINTERNALID))
			  if(@IsExistSPECIAL_PRICE=0)
				   Begin
				/*-----Insert Into tbl_master_contact and Employee Table----*/
				INSERT INTO  PRODUCT_SPECIAL_PRICE_BRANCHWISE 
				( ID,PRODUCT_CODE,PRODUCT_ID,SPECIAL_PRICE,BRANCH_ID,CREATED_BY,CREATED_ON
				--Rev 1.0 
				,EMPINTERNALID,DesignationID
				--Rev 1.0  End
				) 
				VALUES(@LastCount+1,LTRIM(RTRIM(@PRODUCTCODE)),@ProductsID,@SPECIALPRICE,@branch_id,@UserId,GETDATE()
				--Rev 1.0 
				,LTRIM(RTRIM(@EMPINTERNALID)),@DesignationId
				--Rev 1.0  End
				)

				set @LASTID=SCOPE_IDENTITY();
					SET @HASLOG = 1;
				SET @SUCCESS = 1;

				End
				Else
				Begin
					update PRODUCT_SPECIAL_PRICE_BRANCHWISE set SPECIAL_PRICE=@SPECIALPRICE,MODIFIED_BY=@UserId,MODIFIED_ON=GETDATE()   where BRANCH_ID=@branch_id  and PRODUCT_ID=@ProductsID and isnull(EMPINTERNALID,'')=LTRIM(RTRIM(@EMPINTERNALID))
						SET @HASLOG = 1;
						SET @SUCCESS = 1;
				End

		


			
	End
	else if(@Action)='InsertSpecialPriceImportLOg'
	Begin
				--Rev 1.0 
				if(Isnull(@USERLOGINID,'')!='')
				  Begin
						select @EMPINTERNALID=user_contactId from tbl_master_user  where user_loginId=@USERLOGINID
						select @DesignationId=cast(emp_Designation as int) from tbl_trans_employeeCTC  where emp_cntId=@EMPINTERNALID

				  End
				  --Rev 1.0  End
			   --select @LastCount=count(0) from PRODUCT_SPECIAL_PRICE_BRANCHWISE_LOG
			   select top 1 @LastCount=LOGID from PRODUCT_SPECIAL_PRICE_BRANCHWISE_LOG  order by LOGID desc
			   select @ProductsID=sProducts_ID from Master_sProducts where sProducts_Code=LTRIM(RTRIM(@PRODUCTCODE))
			   select @branch_id=branch_id from tbl_master_branch  where branch_description=LTRIM(RTRIM(@BRANCH))

				insert into PRODUCT_SPECIAL_PRICE_BRANCHWISE_LOG(LOGID,PRODUCT_ID,SPECIAL_PRICE,BRANCH_ID,CREATED_BY,CREATED_ON,DESCRIPTION,STATUS,FILENAME,LOOPCOUNTER
				--Rev 1.0 
				,EMPINTERNALID,DesignationID
				--Rev 1.0  End
				)
				select @LastCount+1,@ProductsID,@SPECIALPRICE,@branch_id,@UserId,GETDATE(),@decription,@status,@FileName,@LOOPCOUNTER
				--Rev 1.0 
				,@EMPINTERNALID,@DesignationId
				--Rev 1.0  End

				set @LASTID=SCOPE_IDENTITY();
	End
	else if(@Action)='GetSpecialPrice'
	Begin
		select ID,PRODUCT_ID,PRODUCT_CODE,sProducts_Name,branch_description,SPECIAL_PRICE 
		--Rev 1.0 
		,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name
		,deg_designation,DesignationID
		--Rev 1.0 End
		from PRODUCT_SPECIAL_PRICE_BRANCHWISE SP
		inner join Master_sProducts MP on SP.PRODUCT_ID=MP.sProducts_ID
		inner join tbl_master_branch MB on  SP.BRANCH_ID=MB.branch_id
		LEFT OUTER JOIN tbl_master_contact CONTACT ON  CONTACT.cnt_internalId=SP.EMPINTERNALID
		LEFT OUTER JOIN tbl_master_Designation Designation on Designation.deg_id=SP.DesignationID
		where  ID=@SPECIALPRICEID
	End
	else if(@Action)='DeleteSpecialPrice'
	Begin
		delete from PRODUCT_SPECIAL_PRICE_BRANCHWISE where ID=@SPECIALPRICEID
		delete from PRODUCTSPECIALPRICELIST where SPECIALPRICEID=@SPECIALPRICEID  and USERID=@UserId
		SELECT '1' AS INSERTMSG
	End
	else if(@Action)='UpdateSpecialPrice'
	Begin
		update PRODUCT_SPECIAL_PRICE_BRANCHWISE set SPECIAL_PRICE=@SPECIALPRICE where ID=@SPECIALPRICEID

		update PRODUCTSPECIALPRICELIST set SPECIALPRICE=@SPECIALPRICE where  USERID=@UserId and  SPECIALPRICEID=@SPECIALPRICEID
		SELECT '1' AS INSERTMSG
	End	
	else if(@Action)='InsertSpecialPrice'
	Begin
				--select @LastCount=count(0) from PRODUCT_SPECIAL_PRICE_BRANCHWISE
				select top 1 @LastCount=ID from PRODUCT_SPECIAL_PRICE_BRANCHWISE  order by id desc
				select @PRODUCTCODE=sProducts_Code from Master_sProducts where sProducts_ID=@ProductID

				select @IsExistSPECIAL_PRICE=count(0) from PRODUCT_SPECIAL_PRICE_BRANCHWISE  where BRANCH_ID=@BranchId  and PRODUCT_ID=@ProductID
				if(@IsExistSPECIAL_PRICE=0)
				Begin
					INSERT INTO  PRODUCT_SPECIAL_PRICE_BRANCHWISE 
					( ID,PRODUCT_CODE,PRODUCT_ID,SPECIAL_PRICE,BRANCH_ID,CREATED_BY,CREATED_ON,
					--Rev 1.0 
					EMPINTERNALID,DesignationID
					--Rev 1.0 End
					) 
					VALUES(@LastCount+1,@PRODUCTCODE,@ProductID,@SPECIALPRICE,@BranchId,@UserId,GETDATE()
					--Rev 1.0 
					,@EMPINTERNALID,@DesignationId
					--Rev 1.0 End
					)

					set @LASTID=SCOPE_IDENTITY();
					SELECT @LASTID AS INSERTMSG
				End
				Else
				Begin
					update PRODUCT_SPECIAL_PRICE_BRANCHWISE set SPECIAL_PRICE=@SPECIALPRICE,MODIFIED_BY=@UserId,MODIFIED_ON=GETDATE()   where BRANCH_ID=@BranchId  and PRODUCT_ID=@ProductID
					SELECT '1' AS INSERTMSG
				End
	End	
	else if(@Action)='GetSpecialPriceLOG'
	Begin
			select LOGID,PRODUCT_ID,sProducts_Code,sProducts_Name,branch_description,SPECIAL_PRICE,DESCRIPTION,STATUS,FILENAME,CREATED_ON,LOOPCOUNTER from PRODUCT_SPECIAL_PRICE_BRANCHWISE_LOG  SPlog
			inner join Master_sProducts MP on SPlog.PRODUCT_ID=MP.sProducts_ID
		inner join tbl_master_branch MB on  SPlog.BRANCH_ID=MB.branch_id
			WHERE FILENAME=@FileName
	End
	--Rev 1.0 
	else if(@Action)='GetEmployee'
	Begin
		select cnt_internalId,Replace(ISNULL(cnt_firstName,'')+' '+ISNULL(cnt_middleName,'')+ ' '+ISNULL(cnt_lastName,''),'''','&#39;') AS Employee_Name,cnt_UCC 
		from tbl_master_contact 		
		INNER JOIN tbl_master_user USR ON tbl_master_contact.cnt_internalId=USR.user_contactId AND USR.user_inactive='N'	
		inner join tbl_trans_employeeCTC on tbl_trans_employeeCTC.emp_cntId=tbl_master_contact.cnt_internalId
		where emp_Designation=@DesignationId 
		
		and ((cnt_firstName like '%' + @SearchKey + '%') or  (cnt_middleName like '%' + @SearchKey + '%') or  (cnt_lastName like '%' + @SearchKey + '%')		
		or (cnt_UCC like '%' + @SearchKey + '%'))
		
	End
	--Rev 1.0  End
	else if(@Action)='ALLPAGELOADDATA'
	Begin
		
		select branch_id,branch_description from  tbl_master_branch

		select 0 as deg_id, 'Select' as deg_designation 
		Union all
		select deg_id, deg_designation from tbl_master_Designation
	End
 commit tran t1          
SELECT @SUCCESS AS Success,'SUCCESSFULL' as MSG ,@HASLOG AS HasLog  ,@LASTID as internal_id 
 return         
End Try      
      
Begin Catch      
rollback tran t1
 
select @SUCCESS AS Success ,ERROR_MESSAGE() as MSG,@HASLOG AS HasLog  ,'' as internal_id            
		
return    

End Catch
	
end	
    