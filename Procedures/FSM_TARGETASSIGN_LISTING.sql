
--EXEC prc_FSMDashboardData 'TrackRoute','2018-12-28','2018-12-28',1677,15

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FSM_TARGETASSIGN_LISTING]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FSM_TARGETASSIGN_LISTING] AS' 
END
GO

ALTER PROCEDURE [dbo].[FSM_TARGETASSIGN_LISTING]
(
@Action varchar(200)='',
@USERID Varchar(10)='',
@fromdate Varchar(10)=NULL,
@todate Varchar(10)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************************
Written by : Priti Roy on 06/11/2024
0027770:A new module is required as  Target Assign

*****************************************************************************************************************************************************************************************/
BEGIN    
	
	IF(@Action ='SalesTarget' )
	BEGIN
			select distinct
			 STARGET.SALESTARGET_ID as ID,
			'Sales Target' as [Target Type],
			STARGET.TARGETLEVEL as [Target Level],STARGET.TARGETDOCNUMBER as [Document No.],TARGETDATE as [Date]				
			,MUser.user_name as [Created By]
			,STARGET.CREATEDON	as [Created On]	
			,UpdateUser.user_name as [Updated By]
			,STARGET.UPDATEDON as [Updated On]
			, '' as Action
			from FSM_SALESTARGETASSIGN STARGET
			inner join FSM_SALESTARGETASSIGN_DETAILS DETAILS on DETAILS.SALESTARGET_ID=STARGET.SALESTARGET_ID 
			inner join tbl_master_user MUser on MUser.user_id=STARGET.CREATEDBY
			left outer join tbl_master_user UpdateUser on UpdateUser.user_id=STARGET.UPDATEDBY
		    WHERE CONVERT(nvarchar(10),TARGETDATE ,120) BETWEEN CONVERT(nvarchar(10),@fromdate,120) AND CONVERT(nvarchar(10),@todate,120)
			
	END
	Else IF(@Action ='ProductTarget' )
	BEGIN
			select distinct
			 STARGET.PRODUCTTARGET_ID as ID,
			'Product Target' as [Target Type],
			STARGET.TARGETLEVEL as [Target Level],STARGET.TARGETDOCNUMBER as [Document No.],TARGETDATE as [Date]				
			,MUser.user_name as [Created By]
			,STARGET.CREATEDON	as [Created On]	
			,UpdateUser.user_name as [Updated By]
			,STARGET.UPDATEDON as [Updated On]
			, '' as Action
			from FSM_PRODUCTTARGETASSIGN STARGET
			inner join FSM_PRODUCTTARGETASSIGN_DETAILS DETAILS on DETAILS.PRODUCTTARGET_ID=STARGET.PRODUCTTARGET_ID 
			inner join tbl_master_user MUser on MUser.user_id=STARGET.CREATEDBY
			left outer join tbl_master_user UpdateUser on UpdateUser.user_id=STARGET.UPDATEDBY
		    WHERE CONVERT(nvarchar(10),TARGETDATE ,120) BETWEEN CONVERT(nvarchar(10),@fromdate,120) AND CONVERT(nvarchar(10),@todate,120)
			
	END
	Else IF(@Action ='BrandTarget' )
	BEGIN
			select distinct
			 STARGET.BRANDTARGET_ID as ID,
			'Brand Volume/Value Target' as [Target Type],
			STARGET.BRANDTARGETTYPE as [Target Level],STARGET.BRANDTARGETDOCNUMBER as [Document No.],BRANDTARGETDATE as [Date]				
			,MUser.user_name as [Created By]
			,STARGET.CREATEDON	as [Created On]	
			,UpdateUser.user_name as [Updated By]
			,STARGET.UPDATEDON as [Updated On]
			, '' as Action
			from FSM_BRANDTARGETASSIGN STARGET
			inner join FSM_BRANDTARGETASSIGN_DETAILS DETAILS on DETAILS.BRANDTARGET_ID=STARGET.BRANDTARGET_ID 
			inner join tbl_master_user MUser on MUser.user_id=STARGET.CREATEDBY
			left outer join tbl_master_user UpdateUser on UpdateUser.user_id=STARGET.UPDATEDBY
		    WHERE CONVERT(nvarchar(10),BRANDTARGETDATE ,120) BETWEEN CONVERT(nvarchar(10),@fromdate,120) AND CONVERT(nvarchar(10),@todate,120)
			
	END
	Else IF(@Action ='WODTarget' )
	BEGIN
			select distinct
			 STARGET.WODTARGET_ID as ID,
			'WOD Target' as [Target Type],
			STARGET.WODTARGETTYPE as [Target Level],STARGET.WODTARGETDOCNUMBER as [Document No.],WODTARGETDATE as [Date]				
			,MUser.user_name as [Created By]
			,STARGET.CREATEDON	as [Created On]	
			,UpdateUser.user_name as [Updated By]
			,STARGET.UPDATEDON as [Updated On]
			, '' as Action
			from FSM_WODTARGETASSIGN STARGET
			inner join FSM_WODTARGETASSIGN_DETAILS DETAILS on DETAILS.WODTARGET_ID=STARGET.WODTARGET_ID 
			inner join tbl_master_user MUser on MUser.user_id=STARGET.CREATEDBY
			left outer join tbl_master_user UpdateUser on UpdateUser.user_id=STARGET.UPDATEDBY
		    WHERE CONVERT(nvarchar(10),WODTARGETDATE ,120) BETWEEN CONVERT(nvarchar(10),@fromdate,120) AND CONVERT(nvarchar(10),@todate,120)
			
	END
	Else
	Begin
			select 
			 STARGET.SALESTARGET_ID as ID,
			'Sales Target' as [Target Level],
			STARGET.TARGETLEVEL as [Target Type],STARGET.TARGETDOCNUMBER as [Document No.],TARGETDATE as [Date]				
			,MUser.user_name as [Created By]
			,STARGET.CREATEDON	as [Created On]	
			,UpdateUser.user_name as [Updated By]
			,STARGET.UPDATEDON as [Updated On]
			, '' as Action
			from FSM_SALESTARGETASSIGN STARGET
			inner join FSM_SALESTARGETASSIGN_DETAILS DETAILS on DETAILS.SALESTARGET_ID=STARGET.SALESTARGET_ID 
			left outer join tbl_master_user MUser on MUser.user_id=STARGET.CREATEDBY
			left outer join tbl_master_user UpdateUser on MUser.user_id=STARGET.UPDATEDBY
		    where STARGET.SALESTARGET_ID=0



		
	End
		
END