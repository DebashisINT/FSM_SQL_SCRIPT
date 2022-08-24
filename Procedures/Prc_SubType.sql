IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Prc_SubType]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Prc_SubType] AS' 
END
GO
ALTER PROC [dbo].[Prc_SubType] 
(
@action varchar(100) =null,
@user_id bigint =null
)
as
/*******************************************************************************************************************************************************************************************
1.0			v2.0.32		Pratik		23-08-2022		Code for get all group Beat. refer : Mantis Issue 25133
********************************************************************************************************************************************************************************************/
begin
	if(@action='RetailerList')
	begin

			select cast(id as varchar(20)) id , name,cast(parent_id as varchar(20)) type_id from tbl_shoptypeDetails where isactive=1 and TYPE_ID=1

	end
	else if(@action='DDList')
	begin

			select cast(id as varchar(20)) id , name from tbl_shoptypeDetails where isactive=1 and TYPE_ID=4

	end
	else if(@action='BeatList')
	begin

		select  cast(id as varchar(20)) id , name from fsm_groupbeat beat
		inner join FSM_GROUPBEAT_USERMAP map on beat.ID=map.BEAT_ID
		where USER_ID=@user_id and ISACTIVE=1

	end
	--Rev 1.0
	else if(@action='BeatListAll')
	begin

		select cast(ID as varchar(20)) ID,[NAME] from fsm_groupbeat beat

	end
	--End of Rev 1.0



end


