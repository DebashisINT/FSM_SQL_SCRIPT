IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_CheckMasterData]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_CheckMasterData] AS' 
END
GO


ALTER  Procedure[dbo].[prc_CheckMasterData]    
 @action nvarchar(150)=null,    
 @educationid int=null,    
 @cnt_internalId nvarchar(50)=null,    
 @documentid  int=null,    
 @id int = null,    
 @finyear varchar(30) = null,    
 @ReturnValue nvarchar (50)=null output    
 AS    
/*****************************************************************************************************    
1.0		Sanchita	V2.0.26		27-01-2022	FTS Portal # Three Master Modules required under Master > Other Masters : (As like Designation master module)
											Refer: 24646:
2.0		Sanchita	v2.0.39		22-03-2023	While creating a new Branch, that branch should be mapped automatically for System Admin Employee/User
											Refer: 25744
*****************************************************************************************************/
Begin    
    if(@action='Education')    
    begin    
        if exists(select cnt_education from tbl_master_contact where cnt_education=@educationid)    
     begin    
   set @ReturnValue='-10'    
     end    
  else if exists(select edu_degree from tbl_master_educationProfessional where edu_degree=@educationid)    
   begin    
      set @ReturnValue='-10'    
   end       
       else    
   begin    
     delete from tbl_master_education where edu_id=@educationid    
     set @ReturnValue='1'    
   end     
    end    
        
    else if(@action='DocumentTypeMaster')    
    begin    
        if exists(select doc_documentTypeId from tbl_master_document where doc_documentTypeId=@documentid)    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
     delete from tbl_master_documentType where dty_id=@documentid    
     set @ReturnValue='1'    
   end     
    end    
        
    else if(@action='RemarkCategory')    
    begin    
        if exists(select id from tbl_master_remarksCategory where id in (select cat_id from tbl_master_contactRemarks where cat_id=@id))    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
     Delete from tbl_master_remarksCategory Where id =@id    
     set @ReturnValue='1'    
   end     
    end    
        
    else if(@action='RegionDel')    
    begin    
        if exists(select branch_regionid from tbl_master_branch where branch_regionid in (select reg_id from tbl_master_regions where reg_id=@id))    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
     Delete from tbl_master_regions Where reg_id =@id    
     set @ReturnValue='1'    
   end     
    end    
    else if(@action='AreaDEl')    
    begin    
        if exists(select branch_area from tbl_master_branch where branch_area in (select area_id from tbl_master_area where area_id=@id))    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
     Delete from tbl_master_area Where area_id =@id    
     set @ReturnValue='1'    
   end     
    end    
     else if(@action='colorDEl')    
    begin    
        if exists(select sProducts_Color from Master_sProducts where sProducts_Color in (select Color_ID from Master_Color where Color_ID=@id))    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
     Delete from Master_Color Where Color_ID =@id    
     set @ReturnValue='1'    
   end     
    end    
    else if(@action='SizeDEl')    
    begin    
        if exists(select sProducts_Size from Master_sProducts where sProducts_Size in (select Size_ID from Master_Size where Size_ID=@id))    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
     Delete from Master_Size Where Size_ID =@id    
     set @ReturnValue='1'    
   end     
    end    
    else if(@action='PinCode')    
    begin    
      if exists(select 1 from tbl_master_branch where branch_pin =@id)    
     begin    
         set @ReturnValue='-10'    
     end     
     else if exists(select 1 from tbl_master_address where add_pin =CAST( @id as varchar(10)))    
     begin    
        set @ReturnValue='-10'    
     end 
     -------------------Sam Section Start---------------------
	  else if exists(select 'Y' from tbl_trans_PurchaseInvoiceAddress where InvoiceAdd_pin=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end 
	  
	  else if exists(select 'Y' from tbl_trans_TransitPurchaseInvoiceAddress where InvoiceAdd_pin=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end
	  else if exists(select 'Y' from tbl_trans_TransitSalesInvoiceAddress where InvoiceAdd_pin=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end   
	  -------------------Sam Section End---------------------      
     else    
     begin      
     Delete from tbl_master_pinzip Where pin_id =@id    
     set @ReturnValue='1'    
     End    
    end    
        
     ---Code added by Debjyoti    
     else if(@action='FinancialYear')    
    begin    
      if exists(select 1 from tbl_trans_LeaveAccountBalance where lab_financialYear =@finyear)    
     begin    
         set @ReturnValue='-10'    
     end     
    else if exists(select 1 from Trans_AccountsLedger where AccountsLedger_FinYear =@finyear)    
     begin    
   set @ReturnValue='-10'    
     end        
    else if exists(select 1 from Trans_AccountsLedger_Log where AccountsLedger_FinYear =@finyear)    
     begin    
   set @ReturnValue='-10'    
     end     
  else if exists(select 1 from Trans_MainAccountSummary where MainAccountSummary_FinYear =@finyear)    
     begin    
   set @ReturnValue='-10'    
     end        
  else if exists(select 1 from Trans_SubAccountSummary where SubAccountSummary_FinYear =@finyear)    
     begin    
   set @ReturnValue='-10'    
     end  
     else if exists(select 1 from trans_CustDebitCreditNote where DCNote_FinYear =@finyear)    
     begin    
   set @ReturnValue='-10'    
     end 
     else if exists(select 1 from Trans_VendorDebitCreditNote where DCNote_FinYear =@finyear)    
     begin    
        set @ReturnValue='-10'    
     end  
     -------------------------Sam Section Start--------------
     else if exists(select 'S' from tbl_trans_PurchaseInvoice where Invoice_FinYear =@finyear)    
     begin    
        set @ReturnValue='-10'    
     end 
     else if exists(select 'S' from tbl_trans_TransitPurchaseInvoice where Invoice_FinYear =@finyear)    
     begin    
        set @ReturnValue='-10'
     end      
     else if exists(select 'S' from tbl_trans_TransitSalesInvoice where Invoice_FinYear =@finyear)      
     begin    
        set @ReturnValue='-10'    
     end 
    
     
     -----------------------
     
              
    else    
     begin      
     set @ReturnValue='1'    
     End    
    end    
    ----End here    
     ---Code added by Debjyoti    
    else if(@action='UdfGroup')    
    begin    
       if exists(select 1 from tbl_master_remarksCategory where cat_group_id=@id)    
     begin    
   set @ReturnValue='-10'    
     end     
     else    
     begin    
     Delete from tbl_master_udfGroup Where id =@id    
     set @ReturnValue='1'    
     End    
    end    
    --- End here    
    else if(@action='JobResponsibilities')    
    begin    
        if exists(select 'Y' from tbl_master_contact where cnt_jobResponsibility in (select job_id from tbl_master_jobResponsibility where job_id=@id))    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
     Delete from tbl_master_jobResponsibility Where job_id =@id    
     set @ReturnValue='1'    
   end     
    end        
     else if(@action='Designation')    
    begin    
        if exists(select 'Y' from tbl_master_contact where cnt_designation in (select deg_id from tbl_master_designation where deg_id=@id))    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
     Delete from tbl_master_designation Where deg_id =@id    
     set @ReturnValue='1'    
   end     
    end    
     
	 -- Rev 1.0
	else if(@action='Channel')    
    begin    
        if exists(select 'Y' from Employee_ChannelMap where EP_CH_ID in (select ch_id from Employee_Channel where ch_id=@id))    
		begin    
			set @ReturnValue='-10'    
		end     
		else    
		begin    
			Delete from Employee_Channel Where ch_id =@id    
			set @ReturnValue='1'    
		end     
    end    

	else if(@action='Circle')    
    begin    
        if exists(select 'Y' from Employee_CircleMap where EP_CRL_ID in (select crl_id from Employee_Circle where crl_id=@id))    
		begin    
			set @ReturnValue='-10'    
		end     
		else    
		begin    
			Delete from Employee_Circle Where crl_id =@id    
			set @ReturnValue='1'    
		end     
    end 

	else if(@action='Section')    
    begin    
        if exists(select 'Y' from Employee_SectionMap where EP_SEC_ID in (select sec_id from Employee_Section where sec_id=@id))    
		begin    
			set @ReturnValue='-10'    
		end     
		else    
		begin    
			Delete from Employee_Section Where sec_id =@id    
			set @ReturnValue='1'    
		end     
    end 
	 -- End of Rev 1.0
        
    else if(@action='State')    
     begin    
  if exists(select 'Y' from tbl_master_address where add_state in (select id from tbl_master_state where id=@id))    
     begin    
      set @ReturnValue='-10'    
     end 
     -------------------Sam Section Start---------------------
	  else if exists(select 'Y' from tbl_trans_PurchaseInvoiceAddress where InvoiceAdd_stateId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end 
	  
	  else if exists(select 'Y' from tbl_trans_TransitPurchaseInvoiceAddress where InvoiceAdd_stateId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end
	  else if exists(select 'Y' from tbl_trans_TransitSalesInvoiceAddress where InvoiceAdd_stateId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end   
	  -------------------Sam Section End---------------------     
       else    
   begin    
     Delete from tbl_master_state Where id =@id    
     set @ReturnValue='1'    
   end     
     end    
     else if(@action='country')    
   begin    
   if exists(select 'Y' from tbl_master_address where add_country in (select cou_id from tbl_master_country where cou_id=@id))    
	  begin    
		set @ReturnValue='-10'    
	  end   
	  -------------------Sam Section Start---------------------
	  else if exists(select 'Y' from tbl_trans_PurchaseInvoiceAddress where InvoiceAdd_countryId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end 
	  
	  else if exists(select 'Y' from tbl_trans_TransitPurchaseInvoiceAddress where InvoiceAdd_countryId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end
	  else if exists(select 'Y' from tbl_trans_TransitSalesInvoiceAddress where InvoiceAdd_countryId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end   
	  -------------------Sam Section End---------------------    
     else    
    begin    
      Delete from tbl_master_country Where cou_id =@id    
      set @ReturnValue='1'    
    end     
   end    
     else if(@action='City')    
     begin    
     if exists(select 'Y' from tbl_master_address where add_city in (select city_id from tbl_master_city where city_id=@id))    
		 begin    
		   set @ReturnValue='-10'    
		 end
     -------------------Sam Section Start---------------------
	  else if exists(select 'Y' from tbl_trans_PurchaseInvoiceAddress where InvoiceAdd_cityId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end 
	  
	  else if exists(select 'Y' from tbl_trans_TransitPurchaseInvoiceAddress where InvoiceAdd_cityId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end
	  else if exists(select 'Y' from tbl_trans_TransitSalesInvoiceAddress where InvoiceAdd_cityId=@id)    
	  begin    
		   set @ReturnValue='-10'    
	  end   
	  -------------------Sam Section End---------------------    
     else    
	   begin    
		 Delete from tbl_master_city Where city_id =@id    
		 set @ReturnValue='1'    
	   end     
     end    
         
          
     ---.......... Code Added by Sam on 26122016..............    
     else if(@action='TDSTCS')    
        begin    
   declare @TDSTCSCode varchar(80)    
   select @TDSTCSCode=TDSTCS_Code from Master_TDSTCS where TDSTCS_ID=@id    
    
      if exists(select top 1 * from Master_MainAccount where Ltrim(rtrim(MainAccount_TDSRate)) =@TDSTCSCode)    
     begin    
   set @ReturnValue='-10'    
     end     
    else if exists(select top 1 * from Master_SubAccount  where SubAccount_TDSRate =@TDSTCSCode)    
     begin    
          
   set @ReturnValue='-10'    
     end     
     else if exists(select 1 from tbl_master_productTdsMap  where TDSTCS_ID =@id)    
     begin    
          
          set @ReturnValue='-10'    
     end 
     else if exists(select 'S' from tbl_trans_TDSDetails  where TDSMainId =@id)    
     begin    
          
          set @ReturnValue='-10'    
     end      
             
    else    
           begin      
              delete from Master_TDSTCS where TDSTCS_ID=@id    
     set @ReturnValue='1'    
     End    
    end    
        
     ---.......... Code End..............    
         
     ---Code added by Debjyoti    
      else if(@action='DELETEREMARKSDATA')    
        begin    
        delete from [tbl_master_contactRemarks] where cat_id=@id and rea_internalId=@cnt_internalId    
        End    
         
     --Code End Here    
         
     ---Code added by Debjyoti    
      else if(@action='DeleteFinancer')    
        begin    
         delete from tbl_master_FinancerExecutive where Fin_InternalId=@cnt_internalId    
         delete from tbl_master_contact where cnt_internalId=@cnt_internalId    
         set @ReturnValue='1'    
        End    
         
     --Code End Here    
         
     ---Code added by Sam on 11012017 for Lead or Customer    
         
        else if(@action='DeleteLeadOrContact')    
     begin    
               
          if exists(select top 1 * from dbo.Master_IndustryMap where IndustryMap_EntityID =@cnt_internalId)    
     begin    
   set @ReturnValue='-10'    
     end 
         
     else if exists(select top 1 * from tbl_trans_contactBankDetails where cbd_cntId =@cnt_internalId)    
     begin    
   set @ReturnValue='-10'    
     end      
     -- For Sale Activities Added By Sam on 17022017        
      else if exists(select top 1 * from tbl_trans_sales where sls_contactlead_id =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end     
     --   For Proforma Quotation Added By Sam on 17022017         
     else if exists(select top 1 * from tbl_trans_Quotation where Customer_Id =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end   
      else if exists(select top 1 * from trans_CustDebitCreditNote where DCNote_CustomerID =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end  
      else if exists(select top 1 * from Trans_VendorDebitCreditNote where DCNote_VendorID =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end           
     --   For Sale Order Added By Sam on 10032017     
     else if exists(select top 1 * from tbl_trans_SalesOrder where Customer_Id =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end     
     --   For Sale Challan Added By Sam on 10032017     
     else if exists(select top 1 * from tbl_trans_SalesChallan  where Customer_Id =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end     
     --   For Sale Invoice Added By Sam on 10032017     
     else if exists(select top 1 * from tbl_trans_SalesInvoice  where Customer_Id =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end   
	 
	    --   For Sale return Added By kaushik on 09052017   
     else if exists(select top 1 * from tbl_trans_SalesReturn  where Customer_Id =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end   
	 	    --   For Sale return Added By kaushik on 09052017   
     else if exists(select top 1 * from tbl_trans_PurchaseReturn  where Customer_Id =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end  
      --   For Customer Receipt Payment Added By Priti on 12042017     
     else if exists(select top 1 * from Trans_CustomerReceiptPayment  where ReceiptPayment_CustomerID =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end    
      --   For Vendor Receipt Payment Added By Priti on 12042017     
     else if exists(select top 1 * from Trans_VendorReceiptPayment  where ReceiptPayment_VendorID =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end    
      --   For PurchaseOrder  Added By Priti on 12042017     
     else if exists(select top 1 * from tbl_trans_PurchaseOrder  where PurchaseOrder_VendorId =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end    
      --   For TransporterEntries used in Custom Transporter Control  Added By Samrat Roy on 27042017     
     else if exists(select top 1 * from tbl_trans_EntriesTransporterInformation where trp_InternalId =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end 
     
         else if exists(select top 1 * from tbl_trans_CustomerOpeningAccount where Cus_InternalId =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end 
     
     -----------Sam Section to Prevent Master Data If it is being used in My Section Start---------------
     else if exists(select top 1 * from tbl_trans_PurchaseInvoice where Vendor_Id =@cnt_internalId)      
     begin    
         set @ReturnValue='-10'    
     end 
     
     else if exists(select top 1 * from tbl_trans_TransitPurchaseInvoice where Vendor_Id =@cnt_internalId)      
     begin    
        set @ReturnValue='-10'    
     end 
     
     else if exists(select top 1 * from tbl_trans_TransitSalesInvoice where Customer_Id =@cnt_internalId)      
     begin    
         set @ReturnValue='-10'    
     end 
     
    -----------Sam Section to Prevent Master Data If it is being used in My Section Start--------------- 
         else if exists(select top 1 * from tbl_trans_VendorOpeningAccount where Ven_InternalId =@cnt_internalId)      
     begin    
   set @ReturnValue='-10'    
     end 
     
        
      else    
           begin      
              delete from  tbl_master_contact where cnt_internalId=@cnt_internalId    
              delete from tbl_master_document where doc_contactId=@cnt_internalId    
              delete from tbl_master_address where add_cntId=@cnt_internalId    
              delete from tbl_master_phonefax where phf_cntId=@cnt_internalId    
              delete from tbl_master_email where eml_cntId=@cnt_internalId    
              delete from tbl_master_contactRegistration where crg_cntId=@cnt_internalId    
              delete from tbl_master_contactFamilyRelationship where femrel_cntId=@cnt_internalId    
                  
                  
     set @ReturnValue='1'    
     End    
        End    
         
     --Code End Here    
         
     ---Code added by Debjyoti For Industry Check    
       else if(@action='Industry')    
    begin    
        if exists(select 1 from tbl_master_industry where ind_principalIndustry=@id)    
     begin    
   set @ReturnValue='-10'    
     end     
  else if exists(select * from Master_IndustryMap where IndustryMap_IndustryID=@id)    
     begin    
   set @ReturnValue='-10'    
     end     
  else if exists(select * from tbl_trans_Activies where act_industryid=@id)    
     begin    
   set @ReturnValue='-10'    
     end     
       else    
   begin    
      set @ReturnValue='1'    
   end     
    end    
     --End Here    
         
     --Code added by Debjyoti for Product check    
       else if(@action='ProductMaster')    
    begin    
       if exists(select 1 from Master_sProducts where sProducts_ID=@id and (isnull(sProduct_TaxSchemesale,0)<>0 or isnull(sProduct_TaxSchemepur,0)<>0  ) )    
     begin    
   set @ReturnValue='-2'    
     end     
    -----------Sam Section to Prevent Master Data If it is being used in My Section Start---------------    
     else if exists(select 'S' from tbl_trans_PurchaseInvoiceProducts where InvoiceDetails_ProductId= @id)   
     begin    
         set @ReturnValue='-10'    
     end  
     
      
      
     
     else if exists(select top 1 * from tbl_trans_TransitPurchaseInvoiceProducts where InvoiceDetails_ProductId= @id)      
     begin    
        set @ReturnValue='-10'    
     end 
     
     else if exists(select top 1 * from tbl_trans_TransitSalesInvoiceProducts   where InvoiceDetails_ProductId= @id)      
     begin    
         set @ReturnValue='-10'    
     end 
     
    -----------Sam Section to Prevent Master Data If it is being used in My Section Start--------------- 
        
     
      else if exists(select 1 from tbl_trans_Oldunit_details where Product_id= @id)   
     begin    
         set @ReturnValue='-10'    
     end    
     
     -- for Purchase Invoice By Sam on 25052017 End 
   -- for Sale Activities        
      else if exists(select * from tbl_trans_Activies where ','+act_productIds+',' like '%,'+CAST(@id as varchar(5))+',%' )    
     begin    
   set @ReturnValue='-10'    
     end     
   -- for Sale Activities Again    
       else if exists(select * from tbl_trans_sales where sls_product_id=@id )    
   begin    
    set @ReturnValue='-10'    
   end     
   else if exists(select * from tbl_master_ProdComponent where Product_id=@id or Component_prodId=@id )    
   begin    
    set @ReturnValue='-3'    
   end     
  -- Code Added By Sam On 10032017 start    
  -- for Quotation    
  else if exists(select * from tbl_trans_QuotationProducts where QuoteDetails_ProductId=@id)    
   begin    
    set @ReturnValue='-10'    
   end     
  -- for Sales Order     
  else if exists(select * from tbl_trans_SalesOrderProducts where OrderDetails_ProductId=@id)    
   begin    
    set @ReturnValue='-10'    
   end     
  -- for Sales Challan      
  else if exists(select * from tbl_trans_SalesChallanProducts where ChallanDetails_ProductId=@id)    
  begin    
   set @ReturnValue='-10'    
  end     
  -- for Purchase Challan     
  else if exists(select * from tbl_trans_IndentDetails where IndentDetails_ProductId=@id)    
  begin    
   set @ReturnValue='-10'    
  end     
  -- for Purchase Order     
  else if exists(select * from tbl_trans_PurchaseOrderDetails where OrderDetails_ProductId=@id)    
  begin    
   set @ReturnValue='-10'    
  end     
      
  -- for Purchase Challan      
  else if exists(select * from tbl_trans_PurchaseChallanDetails where ChallanDetails_ProductId=@id)    
  begin    
   set @ReturnValue='-10'    
  end      
  -- for Indent Details      
  else if exists(select * from tbl_trans_IndentDetails where IndentDetails_ProductId=@id)    
  begin    
   set @ReturnValue='-10'    
  end       
      -- for sales return or customer return      
  else if exists(select * from tbl_trans_SalesReturnProducts where ReturnDetails_ProductId=@id)    
  begin    
   set @ReturnValue='-10'    
  end 

   -- for purchase return or return agaimsr grn
  else if exists(select * from tbl_trans_PurchaseReturnProducts where ReturnDetails_ProductId=@id)    
  begin    
   set @ReturnValue='-10'    
  end 


  else    
   begin    
    delete from tbl_master_productTdsMap where sProducts_ID=@id    
    delete from tbl_master_contactRemarks where rea_internalId='ProductMaster'+cast(@id as varchar(10))    
    set @ReturnValue='1'    
   end    
    end    
        
    --End Here    
    
 
        --Code added by Debjyoti for Tax Scheme     
       else if(@action='TaxScheme')    
    begin    
    declare @taxRateCode int = null    
 declare @taxRateScheme varchar(100) = null     
 select @taxRateCode=TaxRates_TaxCode,@taxRateScheme=TaxRatesSchemeName from Config_TaxRates where TaxRates_ID=@id     
        if (exists( select 1 from tbl_trans_ProductTaxRate where TaxRatesSchemeName=@taxRateScheme and TaxRates_TaxCode=@taxRateCode and prodId<>0 )) OR 
		   (exists( select MainAccount_ReferenceID from tbl_trans_LedgerTaxRate where TaxRates_ID=@id))
     begin    
   set @ReturnValue='-10'    
     end      
  else if exists( select 1 from Master_sProducts where sProduct_TaxSchemePur=@id or sProduct_TaxSchemeSale=@id )    
     begin    
   set @ReturnValue='-10'    
     end   
    /*Code Added By Sam on 25052017 For Purchase Invoice Start*/
    
    else if exists( select 'S' from tbl_trans_TransitPurchaseInvoiceProductTax where ProductTax_TaxTypeId=@id or ProductTax_VatGstCstId=@id )    
     begin    
   set @ReturnValue='-10'    
     end      
  else if exists( select 1 from tbl_trans_TransitPurchaseInvoiceTax where InvoiceTax_TaxTypeId =@id or InvoiceTax_VatGstCstId =@id )    
     begin    
   set @ReturnValue='-10'    
     end 
     
     else if exists( select 'S' from tbl_trans_TransitSalesInvoiceProductTax where ProductTax_TaxTypeId=@id or ProductTax_VatGstCstId=@id )    
     begin    
   set @ReturnValue='-10'    
     end      
  else if exists( select 1 from tbl_trans_TransitSalesInvoiceTax where InvoiceTax_TaxTypeId =@id or ProductTax_VatGstCstId =@id )    
     begin    
   set @ReturnValue='-10'    
     end 
    
    /*Code Added By Sam on 25052017 For Purchase Invoice*/
         
  else if exists( select 1 from tbl_trans_QuotationProductTax where ProductTax_TaxTypeId=@id or ProductTax_VatGstCstId=@id )    
     begin    
   set @ReturnValue='-10'    
     end      
  else if exists( select 1 from tbl_trans_QuotationTax where ProductTax_VatGstCstId =@id or QuoteTax_TaxTypeId =@id )    
     begin    
   set @ReturnValue='-10'    
     end     
  else if exists( select 1 from tbl_trans_PurchaseOrderProductTax where ProductTax_VatGstCstId =@id or ProductTax_TaxTypeId =@id )    
     begin    
   set @ReturnValue='-10'    
     end    
  else if exists( select 1 from tbl_trans_PurchaseOrderTax where ProductTax_VatGstCstId =@id or OrderTax_TaxTypeId =@id )    
     begin    
   set @ReturnValue='-10'    
     end 
	 
	  else if exists( select 1 from tbl_trans_SalesReturnProductTax where ProductTax_VatGstCstId =@id or ProductTax_TaxTypeId =@id )    
     begin    
   set @ReturnValue='-10'    
     end    
  else if exists( select 1 from tbl_trans_salesReturnTax where ReturnTax_VatGstCstId =@id or ReturnTax_TaxTypeId =@id )    
     begin    
   set @ReturnValue='-10'    
     end     
	 
	  else if exists( select 1 from tbl_trans_PurchasereturnProductTax where ProductTax_VatGstCstId =@id or ProductTax_TaxTypeId =@id )    
     begin    
   set @ReturnValue='-10'    
     end    
  else if exists( select 1 from tbl_trans_PurchaseReturnTax where ReturnTax_VatGstCstId =@id or ReturnTax_TaxTypeId =@id )    
     begin    
   set @ReturnValue='-10'    
     end                   
  else    
   begin    
    delete from tbl_trans_ProductTaxRate where TaxRatesSchemeName=@taxRateScheme and TaxRates_TaxCode=@taxRateCode and prodId<>0    
    set @ReturnValue='1'    
   end    
    end    
        
    --End Here     
        
 ----- Code added by subhra fot Product class    
    
 else if(@action='ProductClass')    
    begin    
      if exists(select * from tbl_trans_Activies where ','+act_productClassGroup+',' like '%,'+CAST(@id as varchar(5))+',%' )    
     begin    
   set @ReturnValue='-10'    
     end     
  else if exists( select 1 from master_sproducts where ProductClass_Code=@id )    
     begin    
   set @ReturnValue='-10'    
     end     
    end    
 --End Here    
 ----- Code added by subhra fot Tax    
    
 else if(@action='Task')    
    begin    
      if exists(select * from tbl_trans_Activies where act_assign_task= @id)    
	  begin    
			set @ReturnValue='-10'    
	  end     
      else    
      begin    
            set @ReturnValue='1'    
     end    
    end    
 --End Here    
  ----- Code added by Sam on 25052017 for Currency Start  
  
    else if(@action='BuildingWareHouse')    
     begin    
		 if exists(select 'S' from tbl_trans_PurchaseInvoiceWarehouse where InvoiceWarehouse_WarehouseId= @id)    
		 begin    
			 set @ReturnValue='-10'    
		 end  
		 else
		 begin
			 delete from tbl_master_building  where bui_id=@id
			 set @ReturnValue='1'   
		 end 
     end
     
     else if(@action='Currency')    
     begin    
		 if exists(select 'S' from tbl_trans_PurchaseInvoice where Currency_Id= @id)    
		 begin    
			 set @ReturnValue='-10'    
		 end 
		 if exists(select 'S' from tbl_trans_TransitPurchaseInvoice where Currency_Id= @id)    
		 begin    
			 set @ReturnValue='-10'    
		 end 
		 if exists(select 'S' from tbl_trans_TransitSalesInvoice where Currency_Id= @id)    
		 begin    
			 set @ReturnValue='-10'    
		 end 
		 else
		 begin
			 delete from tbl_Master_CurrencyRateDateWise where CRID=@id
			 set @ReturnValue='1'   
		 end 
     end
 ----- Code added by Sam on 17022017 forBranch Start  
   
    
 else if(@action='Branch')    
    begin    
      if exists(select * from tbl_master_contact where cnt_branchid= @id)    
     begin    
         set @ReturnValue='-10'    
     end  
     
     /*Code Added By Sam on 25052017 for Purchase Invoice Start*/ 
    else if exists(select 'S' from tbl_trans_PurchaseInvoice where Invoice_BranchId=@id)
	 begin
		set @ReturnValue='-10' 
	 end
	 else if exists(select 'S' from tbl_trans_TransitPurchaseInvoice where Invoice_BranchId=@id)
	 begin
		set @ReturnValue='-10' 
	 end
	 else if exists(select 'S' from tbl_trans_TransitSalesInvoice where Invoice_BranchId=@id)
	 begin
		set @ReturnValue='-10' 
	 end
     /*Code Above Added By Sam on 25052017 for Purchase Invoice End*/ 
       
   else if exists(select * from tbl_trans_Quotation where Quote_BranchId= @id)    
     begin    
   set @ReturnValue='-10'    
     end     
  else if exists(select * from tbl_trans_PurchaseOrder where PurchaseOrder_BranchId=@id)    
     begin    
   set @ReturnValue='-10'    
   end     
  else if exists(select * from Trans_CustomerReceiptPayment where ReceiptPayment_BranchID=@id)    
     begin    
   set @ReturnValue='-10'    
   end     
    else if exists(select * from tbl_trans_Indent where Indent_BranchIdTo=@id or Indent_BranchIdFor=@id)    
     begin    
   set @ReturnValue='-10'    
   end     
  else if exists(select * from Trans_CashBankVouchers where CashBank_BranchID=@id)    
     begin    
   set @ReturnValue='-10'    
   end     
   else if exists(select * from Trans_VendorReceiptPayment where ReceiptPayment_BranchID=@id)    
     begin    
   set @ReturnValue='-10'    
   end      
  else if exists(select * from Trans_CustomerReceiptPayment where ReceiptPayment_BranchID=@id)    
     begin    
   set @ReturnValue='-10'    
   end      
  else if exists(select * from tbl_trans_SalesChallan where Challan_BranchId=@id)    
     begin    
    set @ReturnValue='-10'    
   end     
  else if exists(select * from tbl_trans_SalesChallan where Challan_BranchId=@id)    
     begin    
    set @ReturnValue='-10'    
   end     
  else if exists(select * from tbl_trans_SalesOrder where Order_BranchId=@id)    
     begin    
    set @ReturnValue='-10'    
   end   
    else if exists(select * from tbl_trans_SalesReturn where Return_BranchId=@id)    
     begin    
    set @ReturnValue='-10'    
   end     
    else if exists(select * from tbl_trans_PurchaseReturn where Return_BranchId=@id)    
     begin    
    set @ReturnValue='-10'    
   end     
       else if exists(select * from trans_CustDebitCreditNote where DCNote_BranchID=@id)    
     begin    
    set @ReturnValue='-10'    
   end    
       else if exists(select * from Trans_VendorDebitCreditNote where DCNote_BranchID=@id)    
     begin    
    set @ReturnValue='-10'    
   end         
      else    
   begin    
      Delete from tbl_master_contactRemarks  Where rea_internalId=(select branch_internalId from tbl_master_branch where branch_id=@id)
	  -- Rev 2.0
	  delete from FTS_EmployeeBranchMap where BranchId=@id
	  -- End of Rev 2.0
      Delete from tbl_master_branch  Where branch_ID =@id and branch_id not in (select distinct cnt_branchid from tbl_master_contact) 
    set @ReturnValue='1'    
   end    
      end    
          
 --End Here    
 else if(@action='NumberingScheme')    
    begin    
      if exists(select * from tbl_master_company where onrole_schema_id=@id OR offrole_schema_id=@id)   
       
		 begin    
			   set @ReturnValue='-10'    
		 end     
       
      else    
   begin    
       
    set @ReturnValue='1'    
   end    
      end    
     
     
  ----- Code added by Kallol on 08052017 forVehicle   
  ----- START    
    
  else if(@action='VehicleMaster')    
    begin    
			if exists(select 1 from tbl_trans_VehiclesDriver where VehiclesRegNo in (Select vehicle_regNo from tbl_master_vehicle where vehicle_id = @id))
			
			 begin    
				set @ReturnValue='-10'    
			end         
			  else    
			  BEGIN
			  delete from tbl_master_vehicle where [vehicle_Id]=@id    
			  set @ReturnValue='1'    
			 END
    end    
          
  ---- END   
     
    
     
     
     
 ------- Code added by Sam on 17022017 forCurrency Start    
    
 --else if(@action='Currency')    
 --   begin    
 --       if exists(select * from tbl_trans_Quotation where Currency_Id= @id)    
 --    begin    
 --  set @ReturnValue='-10'    
 --    end         
 --     else    
 --  begin    
 --   delete from tbl_master_branch where branch_id=@id    
 --   set @ReturnValue='1'    
 --  end    
 --     end    
 ----End Here    
     
      
     
End
