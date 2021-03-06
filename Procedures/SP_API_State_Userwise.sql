IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SP_API_State_Userwise]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [SP_API_State_Userwise] AS' 
END
GO

ALTER PROCEDURE [dbo].[SP_API_State_Userwise]
(
@user_id NVARCHAR(10)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************
1.0			10-06-2020		TANMOY		EMPLOYEE MAP STATE BIND MANTIS:22421
****************************************************************************************************/
BEGIN

--select  cast(id as varchar(50)) as ID,state as StateName  from  tbl_master_state
--order by StateName

	IF ISNUMERIC(@user_id)=1
		BEGIN
			IF EXISTS (select * from FTS_EMPSTATEMAPPING where USER_ID=@user_id AND STATE_ID=0)
			BEGIN
				select  cast(id as varchar(50)) as ID,state as StateName  from  tbl_master_state
				order by StateName
			END
			ELSE
			BEGIN
				select  cast(STAT.id as varchar(50)) as ID,STAT.state as StateName  from  tbl_master_state STAT
				INNER JOIN FTS_EMPSTATEMAPPING MAP ON MAP.STATE_ID=STAT.id
				WHERE USER_ID=@user_id	order by STAT.state
			END
		END
	ELSE
		BEGIN
			SELECT DISTINCT cast(id as varchar(50)) as ID, state as StateName FROM tbl_master_state STAT
			INNER  JOIN (

			SELECT   add_cntId,add_state  FROM  tbl_master_address  where add_addressType='Office' 

			)S
			on STAT.id=S.add_state
			order by state
		END
END