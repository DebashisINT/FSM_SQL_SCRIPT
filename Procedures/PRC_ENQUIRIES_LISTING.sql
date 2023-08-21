IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_ENQUIRIES_LISTING]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_ENQUIRIES_LISTING] AS'  
END 
 
GO

-- exec PRC_ENQUIRIES_LISTING @USERID='378',@ENQUIRIESFROM='3,4,5',@FROMDATE='2020-01-01',@TODATE='2000-01-26'
ALTER PROCEDURE [dbo].[PRC_ENQUIRIES_LISTING]
(
@USERID INT=NULL,
@ENQUIRIESFROM NVARCHAR(500)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL
)
 
AS
/****************************************************************************************************************************************************************************
Written by Sanchita. Refer: 24631
1.0		Pratik		v2.0.28		13/04/2022		Modified the query to fetch status as re assigned and re assined salesman name. Refer: 24810
2.0		Pratik		v2.0.28		14/04/2022		Some new column insertion & column reassign in the listing page of CRM. Refer: 24816
3.0		Pratik		v2.0.28		18/04/2022		Assigned On & Reassigned On column required in Enquiry module. Refer: 24827
4.0		Sanchita	V2.0.42		21/08/2023		CRM Enquiries - Some of the Indiamart Enquiry are not coming while showing the enquiry list.
												Mantis: 26736
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX)

	set @ENQUIRIESFROM = ''''+ replace(@ENQUIRIESFROM,',',''',''') + ''''

	--Rev 3.0
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPMAXSALESMANFEEDBACK') AND TYPE IN (N'U'))
		DROP TABLE #TEMPMAXSALESMANFEEDBACK
	CREATE TABLE #TEMPMAXSALESMANFEEDBACK
		(
			created_date DATETIME NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPMAXSALESMANFEEDBACK(created_date ASC)
	INSERT INTO #TEMPMAXSALESMANFEEDBACK
	select max(s.created_date) as Created_Date from ENQURIES_SALESMANFEEDBACK s
	inner join tbl_CRM_Import h on h.Crm_Id=s.enq_crm_id
	group by s.enq_crm_id
	--End of Rev 3.0
	
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
 
 IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSALESMAN') AND TYPE IN (N'U'))
		DROP TABLE #TEMPSALESMAN
	CREATE TABLE #TEMPSALESMAN
		(
			cnt_id int,
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPSALESMAN(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPSALESMAN
	 Select cnt_id,cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType
                       from tbl_master_contact  where Substring(cnt_internalId,1,2)='AG' 
                       union all 
                       select cnt_id,cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType
                       from (select row_number() over (partition by emp_cntId order by emp_id desc ) as Row, emp_cntId,emp_id 
                       from tbl_trans_employeeCTC where emp_type=19) ctc inner join tbl_master_contact cnt on ctc.emp_cntId=cnt.cnt_internalId 
                       where ctc.Row=1  




	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'ENQUIRIES_LISTING') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE ENQUIRIES_LISTING
			(
			  USERID INT,
			  SEQ INT,
			  CRM_ID uniqueidentifier,
			  DATE datetime NULL,
			  CUSTOMER_NAME NVARCHAR(200) NULL,
			  CONTACT_PERSON NVARCHAR(200) NULL,
			  PHONENO NVARCHAR(200) NULL,
			  EMAIL NVARCHAR(100) NULL,
			  LOCATION NVARCHAR(100) NULL,
			  -- Rev 4.0
			  --PRODUCT_REQUIRED NVARCHAR(100) NULL,
			  PRODUCT_REQUIRED NVARCHAR(500) NULL,
			  -- End of Rev 4.0
			  QTY VARCHAR(100) NULL,
			  UOM VARCHAR(100) NULL,
			  ORDER_VALUE DECIMAL(18,2) NULL,
			  ENQ_DETAILS ntext NULL,
			  CREATED_DATE datetime NULL,
			  CREATED_BY NVARCHAR(50) NULL,
			  MODIFIED_BY NVARCHAR(50) NULL,
			  MODIFIED_DATE datetime NULL,
			  TAGED_VENDOR NVARCHAR(400) NULL,
			  VEND_TYPE NVARCHAR(100) NULL,
			  SUPERVISOR BIT NULL,
			  SALESMAN BIT NULL,
			  VERIFY BIT NULL,
			  ENQ_NUMBER INT,
			  SOURCE NVARCHAR(600) NULL,
			  INDUSTRY NVARCHAR(100) NULL,
			  MISC_COMMENTS NVARCHAR(600) NULL, 
			  PRIORITYS NVARCHAR(10) NULL, 
			  EXIST_CUST NVARCHAR(5) NULL,
			  LAST_CONTACT_DATE DATETIME NULL,
			  NEXT_CONTACT_DATE DATETIME NULL,
			  CONTACTEDBY NVARCHAR(200) NULL,
			  ENQ_PRODREQ NVARCHAR(1000) NULL,
			  FEEDBACK NVARCHAR(1000) NULL,
			  FINAL_INDUSTRY NVARCHAR(100) NULL,
			  ACTIVITY NVARCHAR(10) NULL,
			  VERIFY_BY NVARCHAR(200) NULL,
			  VERIFY_ON DATETIME NULL,
			  VERIFY_CLOSUREDATE DATETIME NULL,
			  ENQUIRY_WORKFLOW NVARCHAR(5) NULL,
			  STATUS NVARCHAR(50) NULL,
			  ASSIGNED_TO NVARCHAR(50) NULL,
			 --rev 2.0
			  ReASSIGNED_TO NVARCHAR(100) NULL,
			  Day NVARCHAR(10) NULL,
			  Month NVARCHAR(10) NULL,
			  Year NVARCHAR(10) NULL,
			  State NVARCHAR(100) NULL,
			  Area NVARCHAR(100) NULL,
			 --End of rev 2.0
			 --rev 3.0
			 SalesmanAssign_date nvarchar(50) NULL,
			 ReSalesmanAssign_date nvarchar(50) NULL
			 --End of rev 3.0
			)
			CREATE NONCLUSTERED INDEX IX1 ON ENQUIRIES_LISTING (SEQ)
		END
	DELETE FROM ENQUIRIES_LISTING WHERE USERID=@USERID

	SET @Strsql=' INSERT INTO ENQUIRIES_LISTING(USERID,SEQ,CRM_ID,DATE,CUSTOMER_NAME,CONTACT_PERSON,PHONENO,EMAIL,LOCATION,PRODUCT_REQUIRED,QTY,UOM,ORDER_VALUE,ENQ_DETAILS,CREATED_DATE,'
	SET @Strsql+='CREATED_BY,MODIFIED_BY,MODIFIED_DATE,TAGED_VENDOR,VEND_TYPE,SUPERVISOR,SALESMAN,VERIFY,ENQ_NUMBER,SOURCE,INDUSTRY,'
	SET @Strsql+='MISC_COMMENTS,PRIORITYS,EXIST_CUST,LAST_CONTACT_DATE,NEXT_CONTACT_DATE,CONTACTEDBY,ENQ_PRODREQ,FEEDBACK,FINAL_INDUSTRY,'
	SET @Strsql+='ACTIVITY,VERIFY_BY,VERIFY_ON,VERIFY_CLOSUREDATE'
	--Rev 1.0
	SET @Strsql+=',ENQUIRY_WORKFLOW,STATUS,ASSIGNED_TO'
	--End of Rev 1.0
	--rev 2.0
	SET @Strsql+=',ReASSIGNED_TO,Day,Month,Year,State,Area'
	--End of rev 2.0
	--rev 3.0
	SET @Strsql+=',SalesmanAssign_date,ReSalesmanAssign_date'
	--End of rev 3.0
	SET @Strsql+=') '

	SET @Strsql+=' select '+STR(@USERID)+',ROW_NUMBER() OVER(ORDER BY h.Date desc) AS SEQ,h.Crm_Id,h.Date,h.Customer_Name,h.Contact_Person'
	--Rev 2.0
	--SET @Strsql+=' ,h.PhoneNo'
	SET @Strsql+=' ,isnull(h.PhoneNo,'''') '
	SET @Strsql+=' +case when isnull(h.PhoneNo,'''')<>'''' then (case when isnull(h.Alt_PhoneNo,'''')<>'''' then '' / ''+isnull(h.Alt_PhoneNo,'''') else isnull(h.Alt_PhoneNo,'''') end) else '''' end '
	SET @Strsql+=' +case when isnull(h.Alt_PhoneNo,'''')<>'''' then (case when isnull(h.MobileNo,'''')<>'''' then '' / ''+isnull(h.MobileNo,'''') else isnull(h.MobileNo,'''') end) else '''' end '
	SET @Strsql+=' +case when isnull(h.MobileNo,'''')<>'''' then (case when isnull(h.Alt_MobileNo,'''')<>'''' then '' / ''+isnull(h.Alt_MobileNo,'''') else isnull(h.Alt_MobileNo,'''') end) else '''' end  as PhoneNo'
	--End of Rev 2.0
	-- Rev 4.0
	--SET @Strsql+=',Email,h.Location,h.Product_Required,h.Qty,h.UOM,h.Order_Value,h.Enq_Details'
	SET @Strsql+=',Email,h.Location,LEFT(h.Product_Required,500),h.Qty,h.UOM,h.Order_Value,h.Enq_Details'
	-- End of Rev 4.0
	SET @Strsql+=',h.Created_Date,u.user_name,u1.user_name,h.Modified_Date,h.Taged_vendor,h.vend_type,isnull(h.Supervisor,0) as Supervisor,isnull(h.salesman,0) as salesman,
	 isnull(h.verify,0) as verify'
	
	SET @Strsql+=',sprvsr.enq_id as supervsr_enq_no,sprvsr.source as supervsr_source'
	SET @Strsql+=',sprvsr.ind_industry as supervsr_Industry,sprvsr.Misc_comments as supervsr_Misc_comments'
	SET @Strsql+=',case when sprvsr.enq_priorityID=0 then ''Low'' when sprvsr.enq_priorityID=1 then ''Normal'' when sprvsr.enq_priorityID=2 then ''High'''
	SET @Strsql+=' when sprvsr.enq_priorityID=3 then ''Urgent'' when sprvsr.enq_priorityID=4 then ''Immediate'' end as supervsr_Prioritys'
	SET @Strsql+=',case when sprvsr.Is_Exist_Customer=''Y'' then ''Yes'' when sprvsr.Is_Exist_Customer=''N'' then ''No'' end as supervsr_Is_Exist_Customer'
	SET @Strsql+=',slsman.last_contactdate as salesman_last_contactdate,slsman.next_contactdate as salesman_next_contactdate'
	SET @Strsql+=',slsman.Contactedby as salesman_Contactedby'
	SET @Strsql+=',slsman.enq_prodreq as salesman_enq_prodreq,slsman.feedback as salesman_feedback,slsman.ind_industry as salesman_final_industry '
	SET @Strsql+=',case when slsman.Is_useful=''Y'' then ''Usefull'' when slsman.Is_useful=''N'' then ''No use'' end as salesman_Activity'
	SET @Strsql+=',vrfy.verify_by,vrfy.verified_on,vrfy.closure_date as veryfy_closure_date'
	SET @Strsql+=',(select Variable_Value from Config_SystemSettings where Variable_Name=''Enquiry_Workflow'') as Variable_Value '
	--rev 1.0
	--SET @Strsql+=',case when SalesmanId=0 then ''Pending'' else ''Assigned'' end as STATUS   '
	SET @Strsql+=',case when SalesmanId=0 then ''Pending'' when isnull(ReAssignedSalesman,0)<>0 then ''Re Assigned'' when SalesmanId<>0 then ''Assigned'' else '''' end as STATUS   '
	--SET @Strsql+=',case when SalesmanId=0 then '''' else us.user_name end as ASSIGNED_TO   '
	--rev 2.0
	--SET @Strsql+=',case when SalesmanId=0 then '''' when isnull(ReAssignedSalesman,0)<>0 then ura.user_name when SalesmanId<>0 then us.user_name end as ASSIGNED_TO   '
	--End of rev 1.0
	SET @Strsql+=',case when SalesmanId=0 then '''' else us.user_name end as ASSIGNED_TO'
	SET @Strsql+=',case when isnull(ReAssignedSalesman,0)=0 then '''' else ura.user_name end as ReASSIGNED_TO '
	SET @Strsql+=',FORMAT(h.Date,''dd'') as Day,FORMAT(h.Date,''MM'') as Month,FORMAT(h.Date,''yyyy'') as Year'
	SET @Strsql+=',ISNULL(pvt.[location1],'''') AS State,ISNULL(pvt.[location2],'''') AS Area'
	--End of rev 2.0
	--rev 3.0
	SET @Strsql+=',CONVERT(NVARCHAR(10),h.SalesmanAssign_dt,105)+'' ''+ CONVERT(NVARCHAR(10),h.SalesmanAssign_dt,108) as SalesmanAssign_date'
	SET @Strsql+=',CONVERT(NVARCHAR(10),h.ReSalesmanAssignDT,105)+'' ''+ CONVERT(NVARCHAR(10),h.ReSalesmanAssignDT,108) as ReSalesmanAssign_date'
	--End of rev 3.0
	SET @Strsql+=' from tbl_CRM_Import h'

	SET @Strsql+=' left outer join ( select s.enq_id,s.enq_crm_id,s.IndustryId,ind.ind_industry,s.Misc_comments,s.enq_priorityID,'
	SET @Strsql+=' s.Is_Exist_Customer,s.source from '
	SET @Strsql+=' enquries_supervisorfeedback s left outer join tbl_master_industry ind on s.IndustryId=ind.ind_id'
	SET @Strsql+=' ) sprvsr on h.Crm_Id=sprvsr.enq_crm_id'
	

	SET @Strsql+=' left outer join '
	SET @Strsql+=' ( Select sl.enq_salesmanid,sl.enq_crm_id,sl.enq_prodreq,sl.feedback,'
	SET @Strsql+=' ind.ind_industry,sl.Is_useful,sl.last_contactdate,sl.next_contactdate,'
	SET @Strsql+=' isnull(con.cnt_firstName,'''')+'' ''+isnull(con.cnt_middleName,'''')+'' ''+isnull(con.cnt_lastName,'''') as Contactedby,sl.created_date '
	SET @Strsql+=' from enquries_salesmanfeedback sl left outer join tbl_master_industry ind on sl.final_industry=ind.ind_id '
	SET @Strsql+=' inner join #TEMPMAXSALESMANFEEDBACK tsl on tsl.created_date=sl.created_date'
	SET @Strsql+=' inner Join (select u.user_id,tmpslsmn.cnt_internalId,tmpslsmn.cnt_firstName,tmpslsmn.cnt_middleName,tmpslsmn.cnt_lastName '
	SET @Strsql+=' from #TEMPCONTACT tmpslsmn inner join tbl_master_user u on tmpslsmn.cnt_internalId=u.user_contactId) as con'
	SET @Strsql+=' on con.user_id=sl.Contactedby '
	SET @Strsql+=' ) slsman on h.Crm_Id=slsman.enq_crm_id'
	--End of Rev 3.0
	SET @Strsql+=' left outer join ( '
	SET @Strsql+='select v.enq_crm_id,isnull(con.cnt_firstName,'''')+'' ''+isnull(con.cnt_middleName,'''')+'' ''+isnull(con.cnt_lastName,'''') as verify_by,'
	SET @Strsql+='v.verified_on,v.closure_date from enquries_verify v '
	SET @Strsql+=' left outer Join #TEMPCONTACT con on con.cnt_internalId=v.verify_by '
	SET @Strsql+=') vrfy on h.Crm_Id=vrfy.enq_crm_id '

	SET @Strsql+=' left outer join(select user_id,user_name from tbl_master_user ) u on cast(u.user_id as int)=h.Created_By'
	SET @Strsql+=' left outer join(select user_id,user_name from tbl_master_user ) u1 on cast(u1.user_id as int)=h.Modified_By'
	SET @Strsql+=' left outer join tbl_master_user us on us.user_id=h.SalesmanId '
	--rev 1.0
	SET @Strsql+=' left outer join(select user_id,user_name from tbl_master_user ) ura on cast(ura.user_id as int)=h.ReAssignedSalesman'
	--End of rev 1.0
	--rev 2.0
	SET @Strsql+=' left outer join (SELECT Crm_Id,''location''+ CAST(ROW_NUMBER()OVER(PARTITION BY crm_id ORDER BY crm_id) AS VARCHAR) AS Col,Split.value FROM dbo.tbl_CRM_Import AS ci CROSS APPLY String_split(Location,'','') AS Split ) AS tbl Pivot (Max(Value) FOR Col IN ([location1],[location2])) AS Pvt on Pvt.Crm_Id=h.Crm_Id'
	--End of rev 2.0
	SET @Strsql+=' where CONVERT(NVARCHAR(10),h.Date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+=' and isnull(h.Is_deleted,0)=0'
	--IF @ENQUIRIESFROM<>'All'
	--	SET @Strsql+=' and h.vend_type='''+@ENQUIRIESFROM+''' '
	SET @Strsql+=' and h.vend_type in ('+@ENQUIRIESFROM+') '
	
	--select @ENQUIRIESFROM
	--SELECT @Strsql
	
	EXEC SP_EXECUTESQL @Strsql

	drop table #TEMPCONTACT
	drop table #TEMPSALESMAN
	drop table #TEMPMAXSALESMANFEEDBACK
END

