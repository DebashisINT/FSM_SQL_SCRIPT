IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_PARTYSTATUS]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_PARTYSTATUS] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_PARTYSTATUS]
(
@ACTION NVARCHAR(500)=NULL,
@session_token NVARCHAR(500)=NULL,
@user_id NVARCHAR(500)=NULL,
@party_status_id BIGINT=null,
@shop_id NVARCHAR(200)=null,
@reason NVARCHAR(500)=null
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF(@ACTION='GETLIST')
		BEGIN
			SELECT convert(NVARCHAR(50),ID) id,PARTYSTATUS name FROM FSM_PARTYSTATUS WITH(NOLOCK) WHERE ISACTIVE=1
		END
	ELSE IF(@ACTION='UPDATE')
		BEGIN
			update tbl_master_shop WITH(TABLOCK) set Party_Status_id=@party_status_id,party_status_reason=@reason where Shop_Code=@shop_id
			SELECT 1
		END

	SET NOCOUNT OFF
END