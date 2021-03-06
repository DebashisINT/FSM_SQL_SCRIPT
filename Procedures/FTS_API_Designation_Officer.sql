IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FTS_API_Designation_Officer]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FTS_API_Designation_Officer] AS' 
END
GO

ALTER PROCEDURE [dbo].[FTS_API_Designation_Officer]
--WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : TANMOY GHOSH  on 09/04/2019
Module	   : State Head,ASM,ZASM,TSM,Regional Manager,RM designation Bind for Salesman With Supervisor Tracking report
1.0		v30.0.0		Debashis	31/05/2019		Salesman with Supervisor tracking report enhancement.Refer: 0020251 & 0020239
****************************************************************************************************************************************************************************/
BEGIN
	--Rev 1.0 && A new designation has been introduced as 'DGM'
	select cast(deg_id as varchar(50)) as desgid,deg_designation as designame from tbl_master_designation where deg_designation IN ('State Head','ASM','ZASM','TSM','Regional Manager','RM','DGM')
	order by deg_designation
END