IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FetchEmployeeChannelCircleSection]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FetchEmployeeChannelCircleSection] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FetchEmployeeChannelCircleSection]
(
@emp_cntId int=null
)
AS
/*****************************************************************************************************************************************************************************************************
Written By : Pratik Ghosh On 27/06/2022
Purpose : For ITC : Employee Channel/Circle/Section.Refer: 24982
******************************************************************************************************************************************************************************************************/
BEGIN

	declare @Emp_cnt_internalId varchar(20)
	--,@RptTo_cnt_internalId varchar(20),@AddRptHd_cnt_internalId varchar(20),@Colleague_cnt_internalId varchar(20)
	--,@Colleague1_cnt_internalId varchar(20),@Colleague2_cnt_internalId varchar(20)

	
	--set @Emp_cnt_internalId=(select tmc.cnt_internalId from tbl_master_contact as tmc where cnt_id=@emp_cntId)
	set @Emp_cnt_internalId=(select tmc.cnt_internalId from tbl_master_contact as tmc where cnt_id=@emp_cntId)

	select ISNULL(empcnt.cnt_firstName, '') + ' ' + ISNULL(empcnt.cnt_middleName, '') + ' ' + ISNULL(empcnt.cnt_lastName, '') +'['+empcnt.cnt_shortName+']' AS EmpName 
	,ISNULL(Rptempcnt.cnt_firstName, '') + ' ' + ISNULL(Rptempcnt.cnt_middleName, '') + ' ' + ISNULL(Rptempcnt.cnt_lastName, '') +'['+Rptempcnt.cnt_shortName+']' AS ReportToEmpName
	,ISNULL(Deputycnt.cnt_firstName, '') + ' ' + ISNULL(Deputycnt.cnt_middleName, '') + ' ' + ISNULL(Deputycnt.cnt_lastName, '') +'['+Deputycnt.cnt_shortName+']' AS DeputyEmpName
	,ISNULL(Clgempcnt.cnt_firstName, '') + ' ' + ISNULL(Clgempcnt.cnt_middleName, '') + ' ' + ISNULL(Clgempcnt.cnt_lastName, '') +'['+Clgempcnt.cnt_shortName+']' AS ColleagueName
	,ISNULL(Clgempcnt1.cnt_firstName, '') + ' ' + ISNULL(Clgempcnt1.cnt_middleName, '') + ' ' + ISNULL(Clgempcnt1.cnt_lastName, '') +'['+Clgempcnt1.cnt_shortName+']' AS Colleague_1Name
	,ISNULL(Clgempcnt2.cnt_firstName, '') + ' ' + ISNULL(Clgempcnt2.cnt_middleName, '') + ' ' + ISNULL(Clgempcnt2.cnt_lastName, '') +'['+Clgempcnt2.cnt_shortName+']' AS Colleague_2Name
	,(select  STRING_AGG( ISNULL(ch_Channel, ' '), ',') as Name  from Employee_Channel where ch_id in (select EP_CH_ID from Employee_ChannelMap where EP_EMP_CONTACTID=empcnt.cnt_internalId)) as EmpChannel
	,(select  STRING_AGG( ISNULL(ch_Channel, ' '), ',') as Name  from Employee_Channel where ch_id in (select EP_CH_ID from Employee_ChannelMap where EP_EMP_CONTACTID=Rptempcnt.cnt_internalId)) as ReportToChannel
	,(select  STRING_AGG( ISNULL(ch_Channel, ' '), ',') as Name  from Employee_Channel where ch_id in (select EP_CH_ID from Employee_ChannelMap where EP_EMP_CONTACTID=Deputycnt.cnt_internalId)) as DeputyChannel
	,(select  STRING_AGG( ISNULL(ch_Channel, ' '), ',') as Name  from Employee_Channel where ch_id in (select EP_CH_ID from Employee_ChannelMap where EP_EMP_CONTACTID=Clgempcnt.cnt_internalId)) as ColleagueChannel
	,(select  STRING_AGG( ISNULL(ch_Channel, ' '), ',') as Name  from Employee_Channel where ch_id in (select EP_CH_ID from Employee_ChannelMap where EP_EMP_CONTACTID=Clgempcnt1.cnt_internalId)) as ColleagueChannel_1
	,(select  STRING_AGG( ISNULL(ch_Channel, ' '), ',') as Name  from Employee_Channel where ch_id in (select EP_CH_ID from Employee_ChannelMap where EP_EMP_CONTACTID=Clgempcnt2.cnt_internalId)) as ColleagueChannel_2

	,(select  STRING_AGG( ISNULL(crl_Circle, ' '), ',') as Circle  from Employee_Circle where crl_id in (select EP_CRL_ID from Employee_CircleMap where EP_EMP_CONTACTID=empcnt.cnt_internalId)) as EmployeeCircle
	,(select  STRING_AGG( ISNULL(crl_Circle, ' '), ',') as Circle  from Employee_Circle where crl_id in (select EP_CRL_ID from Employee_CircleMap where EP_EMP_CONTACTID=Rptempcnt.cnt_internalId)) as ReportToCircle
	,(select  STRING_AGG( ISNULL(crl_Circle, ' '), ',') as Circle  from Employee_Circle where crl_id in (select EP_CRL_ID from Employee_CircleMap where EP_EMP_CONTACTID=Deputycnt.cnt_internalId)) as DeputyCircle
	,(select  STRING_AGG( ISNULL(crl_Circle, ' '), ',') as Circle  from Employee_Circle where crl_id in (select EP_CRL_ID from Employee_CircleMap where EP_EMP_CONTACTID=Clgempcnt.cnt_internalId)) as ColleagueCircle
	,(select  STRING_AGG( ISNULL(crl_Circle, ' '), ',') as Circle  from Employee_Circle where crl_id in (select EP_CRL_ID from Employee_CircleMap where EP_EMP_CONTACTID=Clgempcnt1.cnt_internalId)) as ColleagueCircle_1
	,(select  STRING_AGG( ISNULL(crl_Circle, ' '), ',') as Circle  from Employee_Circle where crl_id in (select EP_CRL_ID from Employee_CircleMap where EP_EMP_CONTACTID=Clgempcnt2.cnt_internalId)) as ColleagueCircle_2

	,(select  STRING_AGG( ISNULL(sec_Section, ' '), ',') as Section  from Employee_Section where sec_id in (select EP_SEC_ID from Employee_SectionMap where EP_EMP_CONTACTID=empcnt.cnt_internalId)) as EmployeeSection
	,(select  STRING_AGG( ISNULL(sec_Section, ' '), ',') as Section  from Employee_Section where sec_id in (select EP_SEC_ID from Employee_SectionMap where EP_EMP_CONTACTID=Rptempcnt.cnt_internalId)) as ReportToSection
	,(select  STRING_AGG( ISNULL(sec_Section, ' '), ',') as Section  from Employee_Section where sec_id in (select EP_SEC_ID from Employee_SectionMap where EP_EMP_CONTACTID=Deputycnt.cnt_internalId)) as DeputySection
	,(select  STRING_AGG( ISNULL(sec_Section, ' '), ',') as Section  from Employee_Section where sec_id in (select EP_SEC_ID from Employee_SectionMap where EP_EMP_CONTACTID=Clgempcnt.cnt_internalId)) as ColleagueSection
	,(select  STRING_AGG( ISNULL(sec_Section, ' '), ',') as Section  from Employee_Section where sec_id in (select EP_SEC_ID from Employee_SectionMap where EP_EMP_CONTACTID=Clgempcnt1.cnt_internalId)) as ColleagueSection_1
	,(select  STRING_AGG( ISNULL(sec_Section, ' '), ',') as Section  from Employee_Section where sec_id in (select EP_SEC_ID from Employee_SectionMap where EP_EMP_CONTACTID=Clgempcnt2.cnt_internalId)) as ColleagueSection_2
	
	from tbl_trans_employeeCTC as ttec
	inner join tbl_master_contact as empcnt on ttec.emp_cntId=empcnt.cnt_internalId
	left join tbl_master_employee as Rptttec on ttec.emp_reportTo=Rptttec.emp_id
	left join tbl_master_contact as Rptempcnt on Rptttec.emp_contactId=Rptempcnt.cnt_internalId
	left join tbl_master_employee as Deputyttec on ttec.emp_deputy=Deputyttec.emp_id
	left join tbl_master_contact as Deputycnt on Deputyttec.emp_contactId=Deputycnt.cnt_internalId
	left join tbl_master_employee as Clgttec on ttec.emp_colleague=Clgttec.emp_id
	left join tbl_master_contact as Clgempcnt on Clgttec.emp_contactId=Clgempcnt.cnt_internalId
	left join tbl_master_employee as Clg1ttec on ttec.emp_colleague1=Clg1ttec.emp_id
	left join tbl_master_contact as Clgempcnt1 on Clg1ttec.emp_contactId=Clgempcnt1.cnt_internalId
	left join tbl_master_employee as Clg2ttec on ttec.emp_colleague2=Clg2ttec.emp_id
	left join tbl_master_contact as Clgempcnt2 on Clg2ttec.emp_contactId=Clgempcnt2.cnt_internalId
	where empcnt.cnt_internalId=@Emp_cnt_internalId
END