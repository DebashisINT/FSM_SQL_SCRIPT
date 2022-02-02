IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_UpdateChannelCircleSectionMap]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_UpdateChannelCircleSectionMap] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_UpdateChannelCircleSectionMap]
(
	@Action 		varchar(50) = NULL,
	@emp_contactid	varchar(100) = NULL,
	@ChannelType	varchar(max) = NULL,
	@Circle			varchar(max) = NULL,
	@Section		varchar(max) = NULL,
	@lastModifyUser	varchar(20) = NULL,
	@ChannelDefault bit=0,
	@CircleDefault bit=0,
	@SectionDefault bit=0
)
-- with encryption
AS
/***********************************************************************************************************************************
Written by Sanchita. refer: 24655
***********************************************************************************************************************************/
BEGIN
	DECLARE @sqlStrTable NVARCHAR(MAX) =''
	Declare @DefaultType varchar(50)=''

	if(@Action='Update')
	BEGIN
		----- Channel ----
		delete from Employee_ChannelMap where EP_EMP_CONTACTID=@emp_contactid

		if(@ChannelType is not null and @ChannelType<>'')
		begin
			set @ChannelType = REPLACE(''''+@ChannelType+'''',',',''',''')

			SET @sqlStrTable =''
			SET @sqlStrTable=' insert into Employee_ChannelMap select ch_id,'''+@emp_contactid+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Channel where ch_id in ('+@ChannelType+') '
			EXEC SP_EXECUTESQL @sqlStrTable

		end

		
		------

		----- Circle ----
		delete from Employee_CircleMap where EP_EMP_CONTACTID=@emp_contactid

		if(@Circle is not null and @Circle<>'')
		begin
			set @Circle = REPLACE(''''+@Circle+'''',',',''',''')

			SET @sqlStrTable =''
			SET @sqlStrTable=' insert into Employee_CircleMap select crl_id,'''+@emp_contactid+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Circle where crl_id in ('+@Circle+') '
			EXEC SP_EXECUTESQL @sqlStrTable
		end
		------

		----- Section ----
		delete from Employee_SectionMap where EP_EMP_CONTACTID=@emp_contactid

		if(@Section is not null and @Section<>'')
		begin
			set @Section = REPLACE(''''+@Section+'''',',',''',''')

			SET @sqlStrTable =''
			SET @sqlStrTable=' insert into Employee_SectionMap select sec_id,'''+@emp_contactid+''' as EP_EMP_CONTACTID, getdate() as CreateDate , '''+@lastModifyUser+''' as CreateUser from Employee_Section where sec_id in ('+@Section+') '
			EXEC SP_EXECUTESQL @sqlStrTable
		end
		------

		if(@ChannelDefault = 1)
			set @DefaultType = 'Channel'
		else if(@CircleDefault = 1)
			set  @DefaultType = 'Circle'
		else if(@SectionDefault = 1)
			set @DefaultType = 'Section'
		
		update tbl_master_employee set DefaultType=@DefaultType where emp_contactId=@emp_contactid


	end
end