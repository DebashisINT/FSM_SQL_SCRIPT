IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMLEADERBOARDMASTER]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMLEADERBOARDMASTER] AS' 
END
GO

ALTER Proc [dbo].[PRC_FSMLEADERBOARDMASTER]
	@Action varchar(100)=NULL,
	@PointSectionId INT=NULL,
	@PointAmount DECIMAL(18,2)=NULL,
	@IsActive INT=NULL,
	@USERID INT=NULL
As
/***********************************************************************************************************************
Written by	Sanchita	V2.0.46		01-04-2024		0027299: One settings page required for Leaderboard in the backend. 
													Below points should be captured for different section.
***************************************************************************************************************************/
Begin
	IF(@Action ='GETPOINTS')
	BEGIN
		SELECT CAST (ID AS VARCHAR(100)) ID,POINT_SECTION FROM MASTER_LEADERBOARDPOINTS WHERE IS_ACTIVE=1 AND POINT_VALUE=0 ORDER BY ID
	END
	IF(@Action ='GETPOINTSLISTING')
	BEGIN
		SELECT CAST (ID AS VARCHAR(100)) pointID, POINT_SECTION , POINT_VALUE, 
		(CASE WHEN IS_ACTIVE=1 THEN 'True' ELSE 'False' END) IS_ACTIVE FROM MASTER_LEADERBOARDPOINTS 
		WHERE POINT_VALUE<>0
		ORDER BY ID
	END
	IF(@Action ='UPDATEPOINTAMOUNT')
	BEGIN
		UPDATE MASTER_LEADERBOARDPOINTS SET POINT_VALUE=@PointAmount,IS_ACTIVE=@IsActive  WHERE ID=@PointSectionId
	END
	IF(@Action ='EDITPOINTAMOUNT')
	BEGIN
		SELECT CAST (ID AS VARCHAR(100)) pointID, POINT_SECTION , POINT_VALUE,IS_ACTIVE as IsActive FROM MASTER_LEADERBOARDPOINTS 
		WHERE ID=@PointSectionId
	END
END
GO