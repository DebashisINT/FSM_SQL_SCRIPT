IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSContactListingShow]') AND type in (N'P', N'PC')) 
BEGIN 
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSContactListingShow] AS'  
END 
GO

--exec PRC_FTSContactListingShow @USERID='378',@CONTACTSFROM='', @FROMDATE='2023-11-19',@TODATE='2023-11-23'

ALTER PROCEDURE [dbo].[PRC_FTSContactListingShow]
(
@ACTION NVARCHAR(500)=NULL,
@IS_PAGELOAD NVARCHAR(100)=NULL,
@USERID INT=NULL,
@CONTACTSFROM NVARCHAR(500)=NULL,
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL
)
 
AS
/****************************************************************************************************************************************************************************
Written by Sanchita on 23-11-2023 for V2.0.43	A new design page is required as Contact (s) under CRM menu. 
												Refer: 27034
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	DECLARE @Strsql NVARCHAR(MAX)

	IF(@ACTION='GETLISTINGDATA')
	BEGIN
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'CRMCONTACT_LISTING') AND TYPE IN (N'U'))
			BEGIN
				CREATE TABLE CRMCONTACT_LISTING
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
				  PRODUCT_REQUIRED NVARCHAR(500) NULL,
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
				  ReASSIGNED_TO NVARCHAR(100) NULL,
				  Day NVARCHAR(10) NULL,
				  Month NVARCHAR(10) NULL,
				  Year NVARCHAR(10) NULL,
				  State NVARCHAR(100) NULL,
				  Area NVARCHAR(100) NULL,
				 SalesmanAssign_date nvarchar(50) NULL,
				 ReSalesmanAssign_date nvarchar(50) NULL,
				 ACTIVITY_DATE NVARCHAR(50) NULL,
				 ACTIVITY_TIME NVARCHAR(50) NULL,
				 ACTIVITY_DETAILS NVARCHAR(1000) NULL,
				 OTHER_REMARKS NVARCHAR(1000) NULL,
				 ACTIVITY_STATUS NVARCHAR(200) NULL,
				 ACTIVITY_TYPE_NAME NVARCHAR(200) NULL,
				 ACTIVITY_NEXT_DATE NVARCHAR(50) NULL,
				 ReASSIGNED_BY NVARCHAR(100) NULL,
				 MODIFIED_ON NVARCHAR(50) NULL
				)
				CREATE NONCLUSTERED INDEX IX1 ON CRMCONTACT_LISTING (SEQ)
			END
		DELETE FROM CRMCONTACT_LISTING WHERE USERID=@USERID

		if(@IS_PAGELOAD <> 'is_pageload')
		BEGIN
			set @CONTACTSFROM = ''''+ replace(@CONTACTSFROM,',',''',''') + ''''

			--------IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPMAXSALESMANFEEDBACK') AND TYPE IN (N'U'))
			--------	DROP TABLE #TEMPMAXSALESMANFEEDBACK
			--------CREATE TABLE #TEMPMAXSALESMANFEEDBACK
			--------	(
			--------		created_date DATETIME NULL
			--------	)
			--------CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPMAXSALESMANFEEDBACK(created_date ASC)
			--------INSERT INTO #TEMPMAXSALESMANFEEDBACK
			--------select max(s.created_date) as Created_Date from ENQURIES_SALESMANFEEDBACK s
			--------inner join tbl_CRM_Import h on h.Crm_Id=s.enq_crm_id
			--------group by s.enq_crm_id


			--------IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPSALESMAN') AND TYPE IN (N'U'))
			--------	DROP TABLE #TEMPSALESMAN
			--------CREATE TABLE #TEMPSALESMAN
			--------	(
			--------		cnt_id int,
			--------		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_UCC NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
			--------	)
			--------CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPSALESMAN(cnt_internalId,cnt_contactType ASC)
			--------INSERT INTO #TEMPSALESMAN
			--------Select cnt_id,cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType
			--------from tbl_master_contact  where Substring(cnt_internalId,1,2)='AG' 
			--------union all 
			--------select cnt_id,cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType
			--------from (select row_number() over (partition by emp_cntId order by emp_id desc ) as Row, emp_cntId,emp_id 
			--------from tbl_trans_employeeCTC where emp_type=19) ctc inner join tbl_master_contact cnt on ctc.emp_cntId=cnt.cnt_internalId 
			--------where ctc.Row=1  


			--------IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
			--------	DROP TABLE #TEMPCONTACT
			--------CREATE TABLE #TEMPCONTACT
			--------	(
			--------		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_UCC NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--------		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
			--------	)
			--------CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
			--------INSERT INTO #TEMPCONTACT
			--------SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_UCC,cnt_contactType FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
 
 		--------	SET @Strsql=' INSERT INTO CRMCONTACT_LISTING(USERID,SEQ,CRM_ID,DATE,CUSTOMER_NAME,CONTACT_PERSON,PHONENO,EMAIL,LOCATION,PRODUCT_REQUIRED,QTY,UOM,ORDER_VALUE,ENQ_DETAILS,CREATED_DATE,'
			--------SET @Strsql+='CREATED_BY,MODIFIED_BY,MODIFIED_DATE,TAGED_VENDOR,VEND_TYPE,SUPERVISOR,SALESMAN,VERIFY,ENQ_NUMBER,SOURCE,INDUSTRY,'
			--------SET @Strsql+='MISC_COMMENTS,PRIORITYS,EXIST_CUST,LAST_CONTACT_DATE,NEXT_CONTACT_DATE,CONTACTEDBY,ENQ_PRODREQ,FEEDBACK,FINAL_INDUSTRY,'
			--------SET @Strsql+='ACTIVITY,VERIFY_BY,VERIFY_ON,VERIFY_CLOSUREDATE'
			--------SET @Strsql+=',ENQUIRY_WORKFLOW,STATUS,ASSIGNED_TO'
			--------SET @Strsql+=',ReASSIGNED_TO,Day,Month,Year,State,Area'
			--------SET @Strsql+=',SalesmanAssign_date,ReSalesmanAssign_date'
			--------SET @Strsql+=',ACTIVITY_DATE, ACTIVITY_TIME, ACTIVITY_DETAILS, OTHER_REMARKS, ACTIVITY_STATUS, ACTIVITY_TYPE_NAME, ACTIVITY_NEXT_DATE, ReASSIGNED_BY, MODIFIED_ON '
			--------SET @Strsql+=') '

			--------SET @Strsql+=' select '+STR(@USERID)+',ROW_NUMBER() OVER(ORDER BY h.Date desc) AS SEQ,h.Crm_Id,h.Date,h.Customer_Name,h.Contact_Person'
			--------SET @Strsql+=' ,isnull(h.PhoneNo,'''') '
			--------SET @Strsql+=' +case when isnull(h.PhoneNo,'''')<>'''' then (case when isnull(h.Alt_PhoneNo,'''')<>'''' then '' / ''+isnull(h.Alt_PhoneNo,'''') else isnull(h.Alt_PhoneNo,'''') end) else '''' end '
			--------SET @Strsql+=' +case when isnull(h.Alt_PhoneNo,'''')<>'''' then (case when isnull(h.MobileNo,'''')<>'''' then '' / ''+isnull(h.MobileNo,'''') else isnull(h.MobileNo,'''') end) else '''' end '
			--------SET @Strsql+=' +case when isnull(h.MobileNo,'''')<>'''' then (case when isnull(h.Alt_MobileNo,'''')<>'''' then '' / ''+isnull(h.Alt_MobileNo,'''') else isnull(h.Alt_MobileNo,'''') end) else '''' end  as PhoneNo'
			--------SET @Strsql+=',Email,h.Location,LEFT(h.Product_Required,500),h.Qty,h.UOM,h.Order_Value,h.Enq_Details'
			--------SET @Strsql+=',h.Created_Date,u.user_name,u1.user_name,h.Modified_Date,h.Taged_vendor,h.vend_type,isnull(h.Supervisor,0) as Supervisor,isnull(h.salesman,0) as salesman,
			-------- isnull(h.verify,0) as verify'
	
			--------SET @Strsql+=',sprvsr.enq_id as supervsr_enq_no,sprvsr.source as supervsr_source'
			--------SET @Strsql+=',sprvsr.ind_industry as supervsr_Industry,sprvsr.Misc_comments as supervsr_Misc_comments'
			--------SET @Strsql+=',case when sprvsr.enq_priorityID=0 then ''Low'' when sprvsr.enq_priorityID=1 then ''Normal'' when sprvsr.enq_priorityID=2 then ''High'''
			--------SET @Strsql+=' when sprvsr.enq_priorityID=3 then ''Urgent'' when sprvsr.enq_priorityID=4 then ''Immediate'' end as supervsr_Prioritys'
			--------SET @Strsql+=',case when sprvsr.Is_Exist_Customer=''Y'' then ''Yes'' when sprvsr.Is_Exist_Customer=''N'' then ''No'' end as supervsr_Is_Exist_Customer'
			--------SET @Strsql+=',slsman.last_contactdate as salesman_last_contactdate,slsman.next_contactdate as salesman_next_contactdate'
			--------SET @Strsql+=',slsman.Contactedby as salesman_Contactedby'
			--------SET @Strsql+=',slsman.enq_prodreq as salesman_enq_prodreq,slsman.feedback as salesman_feedback,slsman.ind_industry as salesman_final_industry '
			--------SET @Strsql+=',case when slsman.Is_useful=''Y'' then ''Usefull'' when slsman.Is_useful=''N'' then ''No use'' end as salesman_Activity'
			--------SET @Strsql+=',vrfy.verify_by,vrfy.verified_on,vrfy.closure_date as veryfy_closure_date'
			--------SET @Strsql+=',(select Variable_Value from Config_SystemSettings where Variable_Name=''Enquiry_Workflow'') as Variable_Value '
			--------SET @Strsql+=',case when SalesmanId=0 then ''Pending'' when isnull(ReAssignedSalesman,0)<>0 then ''Re Assigned'' when SalesmanId<>0 then ''Assigned'' else '''' end as STATUS   '
			--------SET @Strsql+=',case when SalesmanId=0 then '''' else us.user_name end as ASSIGNED_TO'
			--------SET @Strsql+=',case when isnull(ReAssignedSalesman,0)=0 then '''' else ura.user_name end as ReASSIGNED_TO '
			--------SET @Strsql+=',FORMAT(h.Date,''dd'') as Day,FORMAT(h.Date,''MM'') as Month,FORMAT(h.Date,''yyyy'') as Year'
			--------SET @Strsql+=',ISNULL(pvt.[location1],'''') AS State,ISNULL(pvt.[location2],'''') AS Area'
			--------SET @Strsql+=',CONVERT(NVARCHAR(10),h.SalesmanAssign_dt,105)+'' ''+ CONVERT(NVARCHAR(10),h.SalesmanAssign_dt,108) as SalesmanAssign_date'
			--------SET @Strsql+=',CONVERT(NVARCHAR(10),h.ReSalesmanAssignDT,105)+'' ''+ CONVERT(NVARCHAR(10),h.ReSalesmanAssignDT,108) as ReSalesmanAssign_date'
			--------SET @Strsql+=',CONVERT(NVARCHAR(10),ACTV.ACTIVITY_DATE,105) AS ACTIVITY_DATE '
			--------SET @Strsql+=',ACTV.ACTIVITY_TIME, ACTV.ACTIVITY_DETAILS, ACTV.OTHER_REMARKS, ACTV.ACTIVITY_STATUS, ACTV.ACTIVITY_TYPE_NAME '
			--------SET @Strsql+=',CONVERT(NVARCHAR(10),ACTV.ACTIVITY_NEXT_DATE,105) AS ACTIVITY_NEXT_DATE '
			--------SET @Strsql+=',case when isnull(h.ReSalesmanAssignedBy,0)=0 then '''' else uraBy.user_name end as ReASSIGNED_BY '
			--------SET @Strsql+=',CONVERT(NVARCHAR(10),h.MODIFIED_DATE,105)+'' ''+ CONVERT(NVARCHAR(10),h.MODIFIED_DATE,108) as MODIFIED_ON '
			--------SET @Strsql+=' from tbl_CRM_Import h'

			--------SET @Strsql+=' left outer join ( select s.enq_id,s.enq_crm_id,s.IndustryId,ind.ind_industry,s.Misc_comments,s.enq_priorityID,'
			--------SET @Strsql+=' s.Is_Exist_Customer,s.source from '
			--------SET @Strsql+=' enquries_supervisorfeedback s left outer join tbl_master_industry ind on s.IndustryId=ind.ind_id'
			--------SET @Strsql+=' ) sprvsr on h.Crm_Id=sprvsr.enq_crm_id'
	

			--------SET @Strsql+=' left outer join '
			--------SET @Strsql+=' ( Select sl.enq_salesmanid,sl.enq_crm_id,sl.enq_prodreq,sl.feedback,'
			--------SET @Strsql+=' ind.ind_industry,sl.Is_useful,sl.last_contactdate,sl.next_contactdate,'
			--------SET @Strsql+=' isnull(con.cnt_firstName,'''')+'' ''+isnull(con.cnt_middleName,'''')+'' ''+isnull(con.cnt_lastName,'''') as Contactedby,sl.created_date '
			--------SET @Strsql+=' from enquries_salesmanfeedback sl left outer join tbl_master_industry ind on sl.final_industry=ind.ind_id '
			--------SET @Strsql+=' inner join #TEMPMAXSALESMANFEEDBACK tsl on tsl.created_date=sl.created_date'
			--------SET @Strsql+=' inner Join (select u.user_id,tmpslsmn.cnt_internalId,tmpslsmn.cnt_firstName,tmpslsmn.cnt_middleName,tmpslsmn.cnt_lastName '
			--------SET @Strsql+=' from #TEMPCONTACT tmpslsmn inner join tbl_master_user u on tmpslsmn.cnt_internalId=u.user_contactId) as con'
			--------SET @Strsql+=' on con.user_id=sl.Contactedby '
			--------SET @Strsql+=' ) slsman on h.Crm_Id=slsman.enq_crm_id'
			--------SET @Strsql+=' left outer join ( '

			--------SET @Strsql+='select v.enq_crm_id,isnull(con.cnt_firstName,'''')+'' ''+isnull(con.cnt_middleName,'''')+'' ''+isnull(con.cnt_lastName,'''') as verify_by,'
			--------SET @Strsql+='v.verified_on,v.closure_date from enquries_verify v '
			--------SET @Strsql+=' left outer Join #TEMPCONTACT con on con.cnt_internalId=v.verify_by '
			--------SET @Strsql+=') vrfy on h.Crm_Id=vrfy.enq_crm_id '

			--------SET @Strsql+=' left outer join(select user_id,user_name from tbl_master_user ) u on cast(u.user_id as int)=h.Created_By'
			--------SET @Strsql+=' left outer join(select user_id,user_name from tbl_master_user ) u1 on cast(u1.user_id as int)=h.Modified_By'
			--------SET @Strsql+=' left outer join tbl_master_user us on us.user_id=h.SalesmanId '
			--------SET @Strsql+=' left outer join(select user_id,user_name from tbl_master_user ) ura on cast(ura.user_id as int)=h.ReAssignedSalesman'
			--------SET @Strsql+=' left outer join (SELECT Crm_Id,''location''+ CAST(ROW_NUMBER()OVER(PARTITION BY crm_id ORDER BY crm_id) AS VARCHAR) AS Col,Split.value FROM dbo.tbl_CRM_Import AS ci CROSS APPLY String_split(Location,'','') AS Split ) AS tbl Pivot (Max(Value) FOR Col IN ([location1],[location2])) AS Pvt on Pvt.Crm_Id=h.Crm_Id'
			--------SET @Strsql+=' left outer join (SELECT CRM_ID, ACTIVITY_DATE, ACTIVITY_TIME, ACTIVITY_DETAILS, OTHER_REMARKS, ACTIVITY_STATUS, ACTIVITY_TYPE_NAME, ACTIVITY_NEXT_DATE FROM FSMAPILEADACTIVITY ) ACTV ON h.Crm_Id=ACTV.CRM_ID  '
			--------SET @Strsql+=' left outer join(select user_id,user_name from tbl_master_user ) uraBy on cast(uraBy.user_id as int)=h.ReSalesmanAssignedBy'

			--------SET @Strsql+=' where CONVERT(NVARCHAR(10),h.Date,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			--------SET @Strsql+=' and isnull(h.Is_deleted,0)=0'
			--------SET @Strsql+=' and h.vend_type in ('+@CONTACTSFROM+') '
	
			----------select @CONTACTSFROM
			----------SELECT @Strsql
	
			--------EXEC SP_EXECUTESQL @Strsql

			--------drop table #TEMPCONTACT
		END
	END
	ELSE IF(@ACTION='GetContactFrom')
	begin
		SELECT EnqID, EnquiryFromDesc from tbl_master_EnquiryFrom order by EnqID
	end
	--------ELSE IF(@ACTION='GetEnquiriesCountData')
	--------begin
	--------	DECLARE @TotalPendingEnquiry INT = 0, @TotalInProcessEnquiry INT = 0,
 --------               @TotalNotInterestedEnquiry INT = 0, @TotalAssignedEnquiry INT = 0,
 --------               @TotalReassignedEnquiry INT = 0, @TotalHighRiskEnquiry INT = 0

	--------	IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'CRMCONTACT_LISTING') AND TYPE IN (N'U'))
	--------	BEGIN
	--------		SET @TotalPendingEnquiry = (SELECT COUNT(0) FROM CRMCONTACT_LISTING WHERE USERID=@USERID AND [STATUS]= 'Pending')
	--------		SET @TotalInProcessEnquiry = (SELECT COUNT(0) FROM CRMCONTACT_LISTING WHERE USERID=@USERID AND [ACTIVITY_STATUS]= 'In Process')
	--------		SET @TotalNotInterestedEnquiry = (SELECT COUNT(0) FROM CRMCONTACT_LISTING WHERE USERID=@USERID AND [ACTIVITY_STATUS]= 'Not Interested')
	--------		SET @TotalAssignedEnquiry = (SELECT COUNT(0) FROM CRMCONTACT_LISTING WHERE USERID=@USERID AND [STATUS]= 'Assigned')
	--------		SET @TotalReassignedEnquiry = (SELECT COUNT(0) FROM CRMCONTACT_LISTING WHERE USERID=@USERID AND  (ReASSIGNED_TO is not null  and ReASSIGNED_TO != '') )
	--------		SET @TotalHighRiskEnquiry = (SELECT COUNT(0) FROM CRMCONTACT_LISTING WHERE USERID=@USERID AND (ACTIVITY_DATE is null OR ACTIVITY_DATE = '') )
	--------	END

	--------	SELECT @TotalPendingEnquiry AS cnt_PendingEnquiry , @TotalInProcessEnquiry AS cnt_InProcessEnquiry,
 --------       @TotalNotInterestedEnquiry AS cnt_NotInterestedEnquiry, @TotalAssignedEnquiry AS cnt_AssignedEnquiry,
 --------       @TotalReassignedEnquiry AS cnt_ReassignedEnquiry, @TotalHighRiskEnquiry AS cnt_HighRiskEnquiry

	--------end
END
GO