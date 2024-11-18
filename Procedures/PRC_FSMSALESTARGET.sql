
--EXEC prc_FSMDashboardData 'TrackRoute','2018-12-28','2018-12-28',1677,15

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMSALESTARGET]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMSALESTARGET] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FSMSALESTARGET]
(
@Action varchar(200)='',
@USERID Varchar(10)='',
@RPTTYPE NVARCHAR(100)='',
@SearchKey VARCHAR(250) = NULL

) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************************
Written by : Priti Roy on 20/08/2024
0027667:LMS Dashboard
1.0		V2.0.49		Priti	    08/10/2024		0027753: In LMS Dashboard, the count of the Assigned topics will be all the topics under whom at least one content is mapped
*****************************************************************************************************************************************************************************************/
BEGIN    
	
	


	

	IF(@Action ='GETREGION' )
	BEGIN

		if(isnull(@SearchKey,'')!='')
		Begin		
			select convert(varchar(500),branch_id)+'|'+branch_internalId as ID ,branch_internalId as INTERNALID,branch_code as CODE,branch_description as NAME from tbl_master_branch
			where
			(branch_description like '%'+@SearchKey+'%' OR branch_code like '%'+@SearchKey+'%') ORDER BY branch_description ASC
		End
		else
		Begin
			select convert(varchar(500),branch_id)+'|'+branch_internalId as ID ,branch_internalId as INTERNALID,branch_code as CODE,branch_description as NAME from tbl_master_branch
		End
		
	END
	
	
END