IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[V_GROUPBEATLIST]') AND type in (N'V'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE VIEW  [V_GROUPBEATLIST]  AS select 1 as a '
END
GO
/*************************************************************************************************************************
Rev 1.0		V2.0.38		Sanchita		02-01-2022		Add Area, Add Route, Add Beat button required in the Beat/Group master module
														Refer: 25536, 25535, 25542,25543, 25544
******************************************************************************************************************************/
ALTER VIEW V_GROUPBEATLIST
AS
-- Rev 1.0
--SELECT ID,CODE Beat_Code,NAME Beat_Name,U1.user_name Created_By,CREATED_ON Created_On
--,U2.user_name Updated_By,MODIFIED_ON Updated_On FROM FSM_GROUPBEAT BEAT
--LEFT JOIN TBL_MASTER_USER U1 ON BEAT.CREATED_BY =U1.user_id
--LEFT JOIN TBL_MASTER_USER U2 ON BEAT.MODIFIED_BY =U2.user_id

SELECT ID,CODE Beat_Code,NAME Beat_Name,U1.user_name Created_By,CREATED_ON Created_On
,U2.user_name Updated_By,MODIFIED_ON Updated_On,CODE_TYPE  FROM FSM_GROUPBEAT BEAT
LEFT JOIN TBL_MASTER_USER U1 ON BEAT.CREATED_BY =U1.user_id
LEFT JOIN TBL_MASTER_USER U2 ON BEAT.MODIFIED_BY =U2.user_id
-- End of Rev 1.0