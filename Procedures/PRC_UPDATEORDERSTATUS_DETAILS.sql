
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_UPDATEORDERSTATUS_DETAILS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_UPDATEORDERSTATUS_DETAILS] AS' 
END
GO
ALTER Proc [dbo].[PRC_UPDATEORDERSTATUS_DETAILS]
@OrderID int=0,
@Action varchar(100)=NULL,
@ORDERSTATUSNEW nvarchar(200)=NULL,
@USERID int=0
As
/*********************************************************************************************************************************************
Written by : Priti Roy ON 23/09/2024
0027698: Customization work of New Order Status Update module

*******************************************************************************************************************************************/

Begin
Declare @LastCount bigint=0

If(@Action='Update')
BEGIN
	Update tbl_trans_fts_Orderupdate set ORDERSTATUS=@ORDERSTATUSNEW
	where OrderId=@OrderID 

	select  @LastCount=iSNULL(MAX(ORDERSTAUSLOG_ID),0) from FSM_ORDERUPDATESTAUSLOG  
	insert into FSM_ORDERUPDATESTAUSLOG(ORDERSTAUSLOG_ID,SHOP_CODE,ORDER_CODE,ORDER_VALUE,ORDER_DESCRIPTION,ORDER_DATE,USERID,ORDER_STATUS,ACTION,CREATEDBY,CREATEDON)
	select @LastCount+1,SHOP_CODE,ORDERCODE,ORDERVALUE,ORDER_DESCRIPTION,ORDERDATE,USERID,ORDERSTATUS,'U',@USERID,GETDATE() from tbl_trans_fts_Orderupdate where OrderId=@OrderID 


END

Else If(@Action='Edit')
BEGIN

select  ORDERSTATUS
from tbl_trans_fts_Orderupdate where OrderId=@OrderID 

END

End
