IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[V_GROUPBEATLIST]') AND type in (N'V'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE VIEW  [V_GROUPBEATLIST]  AS select 1 as a '
END
GO
/*************************************************************************************************************************
Rev 1.0		V2.0.38		Sanchita		02-01-2022		Add Area, Add Route, Add Beat button required in the Beat/Group master module
														Refer: 25536, 25535, 25542,25543, 25544
Rev 2.0		v2.0.38		Priti			31-01-2023		0025589:Separate column required for Area, Route, Beat 
******************************************************************************************************************************/
ALTER VIEW V_GROUPBEATLIST
AS
-- Rev 1.0
--SELECT ID,CODE Beat_Code,NAME Beat_Name,U1.user_name Created_By,CREATED_ON Created_On
--,U2.user_name Updated_By,MODIFIED_ON Updated_On FROM FSM_GROUPBEAT BEAT
--LEFT JOIN TBL_MASTER_USER U1 ON BEAT.CREATED_BY =U1.user_id
--LEFT JOIN TBL_MASTER_USER U2 ON BEAT.MODIFIED_BY =U2.user_id

SELECT BEAT.ID,BEAT.CODE Beat_Code,BEAT.NAME Beat_Name,U1.user_name Created_By,BEAT.CREATED_ON Created_On
,U2.user_name Updated_By,BEAT.MODIFIED_ON Updated_On,BEAT.CODE_TYPE  
--Rev start 2.0	
--,ISNULL(BEAT.AREANAME,'')AREANAME
--,ISNULL(BEAT.ROUTENAME,'')ROUTENAME
,case when isnull(BEAT.AREA_CODE,0)<>0 then area.AREANAME else ISNULL(BEAT.AREANAME,'') end as AREANAME
,case when isnull(BEAT.ROUTE_CODE,0)<>0 then route.ROUTENAME else ISNULL(BEAT.ROUTENAME,'') end as ROUTENAME
,ISNULL(BEAT.BEATNAME,'')BEATNAME
--Rev end 2.0	
FROM FSM_GROUPBEAT BEAT
LEFT outer JOIN FSM_GROUPBEAT area on  BEAT.AREA_CODE=area.ID
LEFT outer JOIN FSM_GROUPBEAT route on  BEAT.ROUTE_CODE=route.ID
LEFT JOIN TBL_MASTER_USER U1 ON BEAT.CREATED_BY =U1.user_id
LEFT JOIN TBL_MASTER_USER U2 ON BEAT.MODIFIED_BY =U2.user_id
-- End of Rev 1.0