IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_ApiLogin]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_ApiLogin] AS'  
END 
GO

ALTER PROCEDURE [dbo].[Sp_ApiLogin]
(
@userName NVARCHAR(MAX),
@password NVARCHAR(MAX),
@DeviceId NVARCHAR(MAX)=NULL,
@Devicetype NVARCHAR(MAX)=NULL,
@SessionToken NVARCHAR(MAX)=NULL,
@Imei_no NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @UserId INT
	DECLARE @Cnt_Id NVARCHAR(100)
	DECLARE @User_Type NVARCHAR(MAX)
	DECLARE @branchid INT

	set @branchid=(select user_branchid from tbl_master_user WITH(NOLOCK) where user_loginId=@userName and user_password=@password)
	IF EXISTS(select user_id from tbl_master_user WITH(NOLOCK) where user_loginId=@userName and user_password=@password and user_inactive='N')
		BEGIN
		if Exists(select user_id from tbl_master_user WITH(NOLOCK) where user_loginId=@userName and user_password=@password and ((user_status=0)  or (user_status=1  and user_imei_no=@Imei_no)))
			BEGIN
				set @UserId=(select user_id from tbl_master_user WITH(NOLOCK) where user_loginId=@userName and user_password=@password)
				set @Cnt_Id=(select user_contactId from tbl_master_user WITH(NOLOCK) where user_loginId=@userName and user_password=@password)

				if Exists(select  *  from tbl_master_MobileConfiguration WITH(NOLOCK) where
				 (( Salesman like '%,'+cast(@UserId as varchar)+',%' or Salesman like '%,'+cast(@UserId as varchar) or  Salesman like cast(@UserId as varchar)+',%' or Salesman=cast(@UserId as varchar))
				  or
				 ( Manager like '%,'+cast(@UserId as varchar)+',%' or Manager like '%,'+cast(@UserId as varchar) or  Manager like cast(@UserId as varchar)+',%' or Manager=cast(@UserId as varchar))
				 or
  
				  (Financer like '%,'+cast(@UserId as varchar)+',%' or Financer like '%,'+cast(@UserId as varchar) or  Financer like cast(@UserId as varchar)+',%' or Financer=cast(@UserId as varchar))  
   
   
					or
  
				  (TopApproval like '%,'+cast(@UserId as varchar)+',%' or TopApproval like '%,'+cast(@UserId as varchar) or  TopApproval like cast(@UserId as varchar)+',%' or TopApproval=cast(@UserId as varchar))  
   

				   ) 
				   --and IsActived=1 
				 --  and branch_Id=@branchid 
				   )
				BEGIN
					set @UserId=(select user_id from tbl_master_user WITH(NOLOCK) where user_loginId=@userName and user_password=@password)

					update tbl_master_user set user_status=1,Mac_Address=@DeviceId,DeviceType=@Devicetype
					where user_loginId=@userName and user_password=@password

					insert into tbl_master_UserLogin_Log (User_Id,Datelogin,MacAddr,Devicetype)
					values (@UserId,getdate(),@DeviceId,'Mobile')

					if(@@ROWCOUNT>0)
						BEGIN

							update tbl_master_user set SessionToken=@SessionToken,user_status=1,user_imei_no=@Imei_no where user_id=@UserId

							set  @User_Type=(select  distinct case when ( 
							Salesman like '%,'+cast(@UserId as varchar)+',%' or Salesman like '%,'+cast(@UserId as varchar) or  Salesman like cast(@UserId as varchar)+',%' or Salesman=cast(@UserId as varchar)) then 'Salesman' 
							when ( Manager like '%,'+cast(@UserId as varchar)+',%' or Manager like '%,'+cast(@UserId as varchar) or  Manager like cast(@UserId as varchar)+',%' or Manager=cast(@UserId as varchar)) then 'Manager' when

							 ( Financer like '%,'+cast(@UserId as varchar)+',%' or Financer like '%,'+cast(@UserId as varchar) or  Financer like cast(@UserId as varchar)+',%' or Financer=cast(@UserId as varchar)) then 'Financer'
 
							 when ( TopApproval like '%,'+cast(@UserId as varchar)+',%' or TopApproval like '%,'+cast(@UserId as varchar) or  TopApproval like cast(@UserId as varchar)+',%' or TopApproval=cast(@UserId as varchar)) then 'TopApproval'
 
							  end as Usertype

							from tbl_master_MobileConfiguration WITH(NOLOCK) 
							where  						
							(( Salesman like '%,'+cast(@UserId as varchar)+',%' or Salesman like '%,'+cast(@UserId as varchar) or  Salesman like cast(@UserId as varchar)+',%' or Salesman=cast(@UserId as varchar))
							or
							( Manager like '%,'+cast(@UserId as varchar)+',%' or Manager like '%,'+cast(@UserId as varchar) or  Manager like cast(@UserId as varchar)+',%' or Manager=cast(@UserId as varchar))
							or
							(Financer like '%,'+cast(@UserId as varchar)+',%' or Financer like '%,'+cast(@UserId as varchar) or  Financer like cast(@UserId as varchar)+',%' or Financer=cast(@UserId as varchar))  
							or  
							(TopApproval like '%,'+cast(@UserId as varchar)+',%' or TopApproval like '%,'+cast(@UserId as varchar) or  TopApproval like cast(@UserId as varchar)+',%' or TopApproval=cast(@UserId as varchar))  
							) 
							 --and IsActived=1 
 
							 --and branch_Id=@branchid 
							)

							select '200' as ResponseCode,'Success' as Responsedetails,@Cnt_Id as userId,@UserId as User_login_Id,@User_Type as user_type,
							user_country_id=isnull((select  top 1 isnull(add_country,0) add_country  from tbl_master_address WITH(NOLOCK) where Isdefault=1 and add_cntId=@Cnt_Id order by Isdefault),0)
							,user_state_id=isnull((select  top 1  isnull(add_state,0)  add_state from tbl_master_address WITH(NOLOCK) where  add_cntId=@Cnt_Id order by Isdefault),0)
							,user_city_id=isnull((select   top 1 isnull(add_city,0)  add_city from tbl_master_address WITH(NOLOCK) where   add_cntId=@Cnt_Id order by Isdefault),0)

							,Logintype=case when (@User_Type<>'Financer') then 
							'Branch : '+(select  branch_description from tbl_master_branch WITH(NOLOCK) where branch_id=@branchid) 
							when (@User_Type='Financer') then 


							  (select UPPER(cc.cnt_firstName) from tbl_master_FinancerExecutive ff  WITH(NOLOCK) 
							  inner join tbl_master_contact as cc WITH(NOLOCK) on ff.Fin_InternalId=cc.cnt_internalId
  
							 where ff.executive_id in(
							 select  cont.cnt_id  from tbl_master_contact cont WITH(NOLOCK) 
							 inner join tbl_master_user as usr WITH(NOLOCK) on usr.user_contactId=cont.cnt_internalId  and usr.user_id=@UserId
 
							 ))

							 end


							,full_name=(select  cc.cnt_firstName +' '+ cc.cnt_lastName  from tbl_master_contact  as cc WITH(NOLOCK) where cnt_internalId=@Cnt_Id)

							,notification_count=
							case when @User_Type='Salesman' then

							cast((select isnull(count(*),0)  from tbl_API_MainSalesBasket WITH(NOLOCK) where salesmanid=@UserId 

							and
							((DiscountApprovedStatus<>'Pending' and    FinanceApprovedStatus is null) or 
							 (FinanceApprovedStatus='Rejected')) and (Requesttype='Discount' or  Requesttype='Finance') 
							  and (Noti_Readstatus_Salesmandiscount is null or Noti_Readstatus_Salesmandiscount=0) )  as varchar(50))

							when 
							@User_Type='Manager' then
							cast((select isnull(count(*),0)  from tbl_API_MainSalesBasket WITH(NOLOCK) where 

							salesmanid in (select items from dbo.SplitString((select  Salesman from tbl_master_MobileConfiguration WITH(NOLOCK) where

							 ( Manager like '%,'+cast(@UserId as varchar)+',%' or Manager like '%,'+cast(@UserId as varchar) or  Manager like cast(@UserId as varchar)+',%' or Manager=cast(@UserId as varchar))
							),','))
							and
							(Noti_Readstatus_Managerdiscount is null or Noti_Readstatus_Managerdiscount=0) and DiscountApprovedStatus='Pending' and Is_topapprovalrequest=0) as varchar(50))
							when

							--@User_Type='Financer' then
							--cast((select isnull(count(*),0)  from tbl_API_MainSalesBasket where FinancerId=@UserId and (Noti_Readstatus_Financerloan is null or Noti_Readstatus_Financerloan=0) and FinanceApprovedStatus='Pending' ) as varchar(50))

							@User_Type='Financer' then
							cast((select isnull(count(*),0)  from tbl_API_MainSalesBasket where 


							FinancerId=(select cc.cnt_id  from tbl_master_FinancerExecutive ff  WITH(NOLOCK) 
							inner join tbl_master_contact as cc on ff.Fin_InternalId=cc.cnt_internalId
							where ff.executive_id in(
							select  cont.cnt_id  from tbl_master_contact  cont WITH(NOLOCK) 
							inner join tbl_master_user as usr WITH(NOLOCK) on usr.user_contactId=cont.cnt_internalId  and usr.user_id=@UserId) ) 
							and (Noti_Readstatus_Financerloan is null or Noti_Readstatus_Financerloan=0) and FinanceApprovedStatus='Pending' ) as varchar(50))
							when
							--@User_Type='TopApproval' then
							--cast((select isnull(count(*),0)  from tbl_API_MainSalesBasket where Is_topapprovalrequest=1 and (Noti_Readstatus_topapprovaldiscount is null or Noti_Readstatus_topapprovaldiscount=0) and DiscountApprovedStatus='Pending' ) as varchar(50))

							@User_Type='TopApproval' then
							cast((select isnull(count(*),0)  from tbl_API_MainSalesBasket WITH(NOLOCK) where 

							salesmanid in (select items from dbo.SplitString(STUFF((select  

							',' + Salesman from tbl_master_MobileConfiguration WITH(NOLOCK) where

							 ( TopApproval like '%,'+cast(@UserId as varchar)+',%' or TopApproval like '%,'+cast(@UserId as varchar) or  TopApproval like cast(@UserId as varchar)+',%' or TopApproval=cast(@UserId as varchar))

							 FOR XML PATH(''))
							,1,1,''),','))
							and
							(Noti_Readstatus_topapprovaldiscount is null or Noti_Readstatus_topapprovaldiscount=0) and DiscountApprovedStatus='Pending' and Is_topapprovalrequest=1) as varchar(50))
							END
						END
					ELSE
						BEGIN
							SELECT 0
						END
				END
			ELSE
				BEGIN
					SELECT 0
				END
			END
		ELSE
			BEGIN
				select -1
			END
		END
	ELSE
		BEGIN
			SELECT 0
		END

	SET NOCOUNT OFF
END