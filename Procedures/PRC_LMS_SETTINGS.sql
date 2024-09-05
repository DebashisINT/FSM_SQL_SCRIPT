
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_SETTINGS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_SETTINGS] AS' 
END
GO

ALTER PROC [dbo].[PRC_LMS_SETTINGS]
(
@ACTION VARCHAR(500)=NULL,
@USER_ID BIGINT=NULL,
@ReturnValue BIGINT=0 OUTPUT
)
AS
/*************************************************************************************************************************
Written by : Priti Roy ON 02/09/2024
0027682: Changes in LMS module.
0027684:Create a new user setting as ShowClearQuiz
******************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	Declare @LastCount bigint=0
	IF(@ACTION='ClearQuiz')
	BEGIN
	
		IF EXISTS (SELECT 1 FROM FSMUSERTOPICCONTENTWISEQA WHERE USERID=@USER_ID )
		BEGIN			
			 delete from FSMUSERTOPICCONTENTWISEQA  where USERID=@USER_ID	
			SET @ReturnValue=1
		END
		ELSE
		BEGIN
			SET @ReturnValue=-1
		END
	END
	Else IF(@ACTION='ShowSettings')
	Begin
		select ShowClearQuiz from tbl_master_user  where user_id=@USER_ID
	End
	SET NOCOUNT OFF
END