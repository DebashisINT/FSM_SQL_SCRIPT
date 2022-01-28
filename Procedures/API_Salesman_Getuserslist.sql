--exec [API_Salesman_Getuserslist] '1700'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[API_Salesman_Getuserslist]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [API_Salesman_Getuserslist] AS' 
END
GO

ALTER PROCEDURE [dbo].[API_Salesman_Getuserslist]
(
@userreportto varchar(50)=NULL,
@Type varchar(10)='0'
) --WITH ENCRYPTION
AS
/***************************************************************************************************
1.0		Tanmoy		17-11-2020		null checking in user name
2.0		Debashis	19-10-2021		usr.user_loginId added.Refer: 0024419
***************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @ReportTABLE Table(userid int)

	--insert into  @ReportTABLE

	--select  user_id  from dbo.[Get_UserReporthierarchy](@userreportto)

	--union
	--select @userreportto as user_id

	--Rev 1.0
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userreportto)=1)
		BEGIN
			DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@userreportto)		
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
	--End of Rev 1.0

	IF(@Type is null or @Type='0')
		BEGIN
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userreportto)=1)
				BEGIN
					--Rev 2.0 && usr.user_loginId added
					select  cast(user_id as varchar(10)) as UserID   ,
					--cont.cnt_firstName + ' '+ cnt_middleName +' '+cnt_lastName as username
					isnull(cont.cnt_firstName,'') + ' '+ case when isnull(cnt_middleName,'')='' then '' else isnull(cnt_middleName,'') +' ' end +isnull(cnt_lastName,'')+'  '+usr.user_loginId as username
					from tbl_master_user as usr
					INNER JOIN #EMPHR_EDIT ON usr.user_contactId=EMPCODE
					inner join tbl_master_contact as cont on usr.user_contactId=cont.cnt_internalId
					--inner join @ReportTABLE as rt on rt.userid=usr.user_id 
					WHERE usr.user_inactive='N'
					order  by cont.cnt_firstName 
				END
			ELSE
				BEGIN
					--Rev 2.0 && usr.user_loginId added
					select  cast(user_id as varchar(10)) as UserID   ,
					--cont.cnt_firstName + ' '+ cnt_middleName +' '+cnt_lastName as username
					isnull(cont.cnt_firstName,'') + ' '+ case when isnull(cnt_middleName,'')='' then '' else isnull(cnt_middleName,'') +' ' end +isnull(cnt_lastName,'')+'  '+usr.user_loginId as username
					from tbl_master_user as usr
					inner join tbl_master_contact as cont on usr.user_contactId=cont.cnt_internalId
					--inner join @ReportTABLE as rt on rt.userid=usr.user_id 
					WHERE usr.user_inactive='N'
					order  by cont.cnt_firstName 
				END

		 --where usr.user_id=@userreportto


		--UNION 

		--SELECT  cast(MSUS.user_id   as varchar(10)) as UserID ,CNT.cnt_firstName + ' '+ cnt_middleName +' '+cnt_lastName as username 
		--  FROM tbl_trans_employeeCTC CTC
		--       INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId = CTC.emp_cntId
		--	   INNER JOIN tbl_master_user MSUS ON  MSUS.user_contactId = CNT.cnt_internalId
		--       INNER JOIN 
		--	   (
		--		SELECT emp_id
		--		  FROM tbl_master_user MU
		--			   INNER JOIN tbl_master_employee EMP ON MU.user_contactId = EMP.emp_contactId
		--		 WHERE USER_ID = @userreportto
		--       ) USR ON CTC.emp_reportTo = USR.emp_id

		--where Substring(cnt_internalId,1,2)='AG'  
		--1354	KALYAN  ROY  
		END
	ELSE IF(@Type='1')
		BEGIN
			IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userreportto)=1)
				BEGIN
					--Rev 2.0 && usr.user_loginId added
					select  cast(user_id as varchar(10)) as UserID   ,
					--cont.cnt_firstName + ' '+ cnt_middleName +' '+cnt_lastName as username
					isnull(cont.cnt_firstName,'') + ' '+ case when isnull(cnt_middleName,'')='' then '' else isnull(cnt_middleName,'') +' ' end +isnull(cnt_lastName,'')+'  '+usr.user_loginId as username
					from tbl_master_user as usr
					INNER JOIN #EMPHR_EDIT ON usr.user_contactId=EMPCODE
					inner join tbl_master_contact as cont on usr.user_contactId=cont.cnt_internalId
					--inner join @ReportTABLE as rt on rt.userid=usr.user_id 
					where usr.user_status=1 and usr.user_inactive='N'
					order  by cont.cnt_firstName
				END
			ELSE
				BEGIN
					--Rev 2.0 && usr.user_loginId added
					select  cast(user_id as varchar(10)) as UserID   ,
					--cont.cnt_firstName + ' '+ cnt_middleName +' '+cnt_lastName as username
					isnull(cont.cnt_firstName,'') + ' '+ case when isnull(cnt_middleName,'')='' then '' else isnull(cnt_middleName,'') +' ' end +isnull(cnt_lastName,'')+'  '+usr.user_loginId as username
					from tbl_master_user as usr
					inner join tbl_master_contact as cont on usr.user_contactId=cont.cnt_internalId
					--inner join @ReportTABLE as rt on rt.userid=usr.user_id 
					where usr.user_status=1 and usr.user_inactive='N'
					order  by cont.cnt_firstName
				END
		END
	ELSE IF(@Type='2')
		BEGIN
			IF ((SELECT IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userreportto)=1)
				BEGIN
					--Rev 2.0 && usr.user_loginId added
					SELECT CAST(user_id as varchar(10)) as UserID   ,
					--cont.cnt_firstName + ' '+ cnt_middleName +' '+cnt_lastName as username
					isnull(cont.cnt_firstName,'') + ' '+ case when isnull(cnt_middleName,'')='' then '' else isnull(cnt_middleName,'') +' ' end +isnull(cnt_lastName,'')+'  '+usr.user_loginId as username
					from tbl_master_user as usr
					INNER JOIN #EMPHR_EDIT ON usr.user_contactId=EMPCODE
					inner join tbl_master_contact as cont on usr.user_contactId=cont.cnt_internalId
					--inner join @ReportTABLE as rt on rt.userid=usr.user_id 
					where usr.user_status=0 and usr.user_inactive='N'
					order  by cont.cnt_firstName
				END
			ELSE
				BEGIN
					--Rev 2.0 && usr.user_loginId added
					SELECT CAST(user_id as varchar(10)) as UserID   ,
					--cont.cnt_firstName + ' '+ cnt_middleName +' '+cnt_lastName as username
					isnull(cont.cnt_firstName,'') + ' '+ case when isnull(cnt_middleName,'')='' then '' else isnull(cnt_middleName,'') +' ' end +isnull(cnt_lastName,'')+'  '+usr.user_loginId as username
					from tbl_master_user as usr
					inner join tbl_master_contact as cont on usr.user_contactId=cont.cnt_internalId
					--inner join @ReportTABLE as rt on rt.userid=usr.user_id 
					where usr.user_status=0 and usr.user_inactive='N'
					order  by cont.cnt_firstName
				END
		END
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userreportto)=1)
			BEGIN
				DROP TABLE #EMPHR_EDIT
				DROP TABLE #EMPHR
			END
	
	SET NOCOUNT OFF
END
