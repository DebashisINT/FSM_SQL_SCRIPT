IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[insert_correspondence]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [insert_correspondence] AS' 
END
GO

ALTER procedure [dbo].[insert_correspondence]
@insuId varchar(50),
@Type varchar(50),
@contacttype varchar(50),
@Address1 varchar(500),
@Address2 varchar(500),
@Address3 varchar(500),
@LandMark varchar(500),
@Address4 varchar(200)=null,
@City int,
@area int,
@contactperson varchar(50)=null,
@Country int,
@State int,
@PinCode varchar(50),
@CreateUser decimal,
@Isdefault int=0,
@Branch int=0,
@Phone varchar(50)=null,
@add_Email  varchar(100)=null,
@add_Website  varchar(200)=null,
@add_Designation int=null,
@Id int=null

as
/**************************************************************************************************************************************
Rev 1.0		20-04-2023		Sanchita	V2.0.40		Employee Office address shall be updated along with City Long Lat in employee 
													address table. Refer: 25826
**************************************************************************************************************************************/
Begin
	declare @add_state int
	-- Rev 1.0
	declare @City_Lat nvarchar(max)='0.0', @City_Long nvarchar(max)='0.0'
	-- End of Rev 1.0

	select @add_state=add_state from tbl_master_address where add_cntId=@insuId
	-- Rev 1.0
	if(LTRIM(RTRIM(UPPER(@contacttype)))='EMPLOYEE')
	BEGIN
		set @City_Lat = (select top 1 isnull(City_lat,'0.0') from tbl_master_city where city_id=@City )
		set @City_Long = (select top 1 isnull(City_Long,'0.0') from tbl_master_city where city_id=@City )
	END
	-- End of Rev 1.0

	if(@add_state=0)
	begin
			-- Rev 1.0 [ columns City_lat and City_Long added in query]
			update tbl_master_address set Isdefault=@Isdefault,contactperson=@contactperson,add_entity=@contacttype,add_addressType=@Type,
			add_address1=@Address1,add_address2=@Address2,
			add_address3=@Address3,add_city=@City,add_landMark=@LandMark,add_country=@Country,add_state=@State,add_pin=@PinCode,add_area=@area,
			CreateDate=getdate(),CreateUser=@CreateUser,add_Phone=@Phone,add_Email=@add_Email,add_Website=@add_Website,add_Designation=@add_Designation
			,add_address4=@Address4,add_Lat=@City_Lat,add_Long=@City_Long  where add_cntId=@insuId
	end
	else
	begin
			-- Rev 1.0 [ columns City_lat and City_Long added in query ]
			insert into tbl_master_address(Isdefault,contactperson,add_cntId,add_entity,add_addressType,add_address1,add_address2,
			add_address3,add_city,add_landMark,add_country,add_state,add_area,add_pin,CreateDate,CreateUser,add_Phone,add_Email,add_Website,
			add_Designation,add_address4,add_Lat,add_Long) 
			values(@Isdefault,@contactperson,@insuId,@contacttype,@Type,@Address1,@Address2,
			@Address3,@City,@LandMark,@Country,@State,@area,@PinCode,getdate(),@CreateUser,@Phone,@add_Email,@add_Website
			,@add_Designation,@Address4,@City_Lat,@City_Long)
	end
end









-- Sp last modify by Priti on 28-11-2016 to change datatype length 

--ALTER procedure [dbo].[insert_correspondence]
--@insuId varchar(50),
--@Type varchar(50),
--@contacttype varchar(50),
--@Address1 varchar(50),
--@Address2 varchar(50),
--@Address3 varchar(50),
--@City int,
--@area int,
--@LandMark varchar(50),
--@Country int,
--@State int,
--@PinCode varchar(50),
--@CreateUser decimal
--as
--declare @add_state int
--Begin
--select @add_state=add_state from tbl_master_address where add_cntId=@insuId
--if(@add_state=0)
--begin
--update tbl_master_address set add_entity=@contacttype,add_addressType=@Type,add_address1=@Address1,add_address2=@Address2,
--add_address3=@Address3,add_city=@City,add_landMark=@LandMark,add_country=@Country,add_state=@State,add_pin=@PinCode,add_area=@area,
--CreateDate=getdate(),CreateUser=@CreateUser where add_cntId=@insuId
--end
--else
--begin
--insert into tbl_master_address(add_cntId,add_entity,add_addressType,add_address1,add_address2,add_address3,add_city,add_landMark,add_country,add_state,add_area,add_pin,CreateDate,CreateUser) 
--values(@insuId,@contacttype,@Type,@Address1,@Address2,@Address3,@City,@LandMark,@Country,@State,@area,@PinCode,getdate(),@CreateUser)
--end
--end