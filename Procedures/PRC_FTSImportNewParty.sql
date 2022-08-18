IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSImportNewParty]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSImportNewParty] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSImportNewParty]
(
@CreateUser_Id NVARCHAR(10)=NULL,
--rev 6.0
--@IMPORT_TABLE UDT_ImportParty READONLY
@IMPORT_TABLE UDT_ImportParty_New READONLY
--End of rev 6.0
) 
AS
/******************************************************************************************************************************
1.0			Tanmoy		08-05-2020			create sp
2.0			Tanmoy		20-05-2020			iMPORT WITH VALIDATION
3.0			Tanmoy		22-05-2020			Insert DD shop code
4.0			Tanmoy		25-05-2020			Insert Shop Create User
5.0			Tanmoy		18-06-2020			Shop lat,long set 0 when its blank
6.0			Pratik		10-01-2022			replaced UDT_ImportParty with UDT_ImportParty_New
											to include new columns
7.0			Sanchita	11-02-2022			[Assign to User] in Import Excel will hold user_loginId instead of user name since 
											two or more user canexist with same name but user_loginId will be unique.
8.0			Swatilekha	18-08-2022			Beat/Group column should be added in the party master import log Refer:0025137
******************************************************************************************************************************/
BEGIN

declare @i bigint=1
declare @user_id bigint=NULL
declare @state_id bigint=NULL
declare @city_id bigint=null
declare @ShopTypeid bigint=null
declare @area_id bigint=null
declare @OutletType_id bigint=1
declare @PartyCode nvarchar(100)
declare @state nvarchar(300)
declare @EntityType nvarchar(200)
DECLARE @AreaName NVARCHAR(500)
DECLARE @CityName NVARCHAR(500)
DECLARE @ShopType NVARCHAR(200)
DECLARE @username NVARCHAR(500)
DECLARE @PartyName NVARCHAR(300)=null
DECLARE @Address NVARCHAR(500)=null
DECLARE @PinCode NVARCHAR(100)=null
DECLARE @Owner NVARCHAR(300)=null
DECLARE @Status NVARCHAR(50)=null

DECLARE @Retailer_Type NVARCHAR(500)=null
DECLARE @Dealer_Type NVARCHAR(100)=null
DECLARE @Entity NVARCHAR(300)=null
DECLARE @Party_Status NVARCHAR(500)=null
DECLARE @Beat NVARCHAR(300)=NULL

DECLARE @Retailer_ID NVARCHAR(500)=null
DECLARE @Dealer_ID NVARCHAR(100)=null
DECLARE @Entity_ID NVARCHAR(300)=null
DECLARE @Party_Status_ID NVARCHAR(500)=null
DECLARE @Beat_ID NVARCHAR(300)=NULL

DECLARE @Shop_Owner_Contact nVARCHAR(50)=''


DECLARE DB_CURSOR CURSOR FOR
 SELECT [Contact],State,[Entity Category],Area,City,[Type],[Assign to User],[Party Name],[Party Code],[Address],[Pin Code],[Owner],[Status],
 [DD Type],[Shop type],[Party Status],[Group/Beat],[Entity Type] FROM @IMPORT_TABLE where [Contact] is not NULL
 OPEN DB_CURSOR
 FETCH NEXT FROM DB_CURSOR INTO @Shop_Owner_Contact,@state,@EntityType,@AreaName,@CityName,@ShopType,@username,@PartyName,@PartyCode,@Address,@PinCode,@Owner,@Status
 ,@Dealer_Type,@Retailer_Type,@Party_Status,@Beat,@Entity WHILE @@FETCH_STATUS=0
 begin

	IF NOT EXISTS (SELECT 1 FROM TBL_MASTER_SHOP WHERE Shop_Owner_Contact=@Shop_Owner_Contact)
		BEGIN
			set @ShopTypeid =(select top(1)shop_typeId from tbl_shoptype where Name=@ShopType and isActive=1)
			set @area_id =(select top(1)area_id from tbl_master_area where area_name=@AreaName)
			set @city_id =(select top(1)city_id from tbl_master_city where city_name=@CityName)
			set @state_id=(select TOP(1)ID from tbl_master_state where state=@state)
			-- Rev 7.0
			--SET @user_id=(SELECT top(1)user_id FROM tbl_master_user WHERE user_inactive='N' and user_name=@username)
			SET @user_id=(SELECT top(1)user_id FROM tbl_master_user WHERE user_inactive='N' and user_loginId=@username)
			-- End of Rev 7.0
			set @OutletType_id=(select TOP(1)TypeID from Master_OutLetType where TypeName=@EntityType)

			set @Retailer_ID =(select ISNULL(id,0) from tbl_shoptypeDetails where name=@Retailer_Type AND isactive=1 and TYPE_ID=1)
			set @Dealer_ID =(select ISNULL(id,0) from tbl_shoptypeDetails where name=@Dealer_Type AND isactive=1 and TYPE_ID=4)
			set @Entity_ID =(select ISNULL(ID,0) from FSM_ENTITY where ENTITY=@Entity)
			set @Party_Status_ID=(select ISNULL(ID,0) from FSM_PARTYSTATUS where PARTYSTATUS=@Party_Status)
			SET @Beat_ID=(SELECT ISNULL(id,0) FROM fsm_groupbeat WHERE ISACTIVE=1 AND name=@Beat)

			IF ISNULL(@Status,'')<>''
			BEGIN
				IF ISNULL(@Owner,'')<>''
				BEGIN
					IF ISNULL(@PinCode,'')<>''
					BEGIN
						IF ISNULL(@Address,'')<>''
						BEGIN
							IF ISNULL(@PartyCode,'')<>''
							BEGIN
								IF ISNULL(@ShopTypeid,'')<>''
								BEGIN
									IF ISNULL(@PartyName,'')<>''
									BEGIN
										IF ISNULL(@city_id,'')<>''
										BEGIN
											IF ISNULL(@state_id,'')<>''
											BEGIN
												IF ISNULL(@user_id,'')<>''
													BEGIN
														IF ISNULL(@ShopTypeid,'')<>''
															BEGIN
																INSERT INTO tbl_Master_shop(
																Shop_Code,Shop_Name,Address,Pincode,Shop_Lat,Shop_Long,Shop_City,Shop_Owner,Shop_WebSite,Shop_Owner_Email,Shop_Owner_Contact,dob,date_aniversary,type,Shop_CreateUser,
																Shop_CreateTime,Shop_ModifyUser,Shop_ModifyTime,Shop_Image,total_visitcount,Lastvisit_date,isAddressUpdated,assigned_to_pp_id,assigned_to_dd_id,
																stateId,OTPCode,VerifiedOTP,AssignTo,Amount
																,OLD_CreateUser,EntityCode,Entity_Location,Alt_MobileNo,Entity_Status,Entity_Type,ShopOwner_PAN,ShopOwner_Aadhar,Remarks,Area_id,Entered_By,Entered_On
																,retailer_id,dealer_id,Party_Status_id,beat_id,account_holder,bank_name,account_no,ifsc,upi_id
																--rev 6.0
																,[Cluster],[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																--End of rev 6.0
																)
																SELECT
																CAST(@user_id AS varchar(20)) + '_' + cast((CAST(DATEDIFF(SECOND,'1970-01-01',getdate()) AS bigint) * 1155)+@i AS varchar(20)) as Shop_Code,
																[Party Name],[Address],[Pin Code] as Pincode
																,CASE WHEN ISNULL([Party Location Lat],'')='' THEN '0' ELSE [Party Location Lat] END as Shop_Lat 
																,CASE WHEN ISNULL([Party Location Lang],'')='' THEN '0' ELSE [Party Location Lang] END as Shop_Long 
																, @city_id as city_id
																,[Owner] as Shop_Owner
																, '' as Shop_WebSite
																,Email as Shop_Owner_Email
																,[Contact] as Shop_Owner_Contact
																,DOB as Owner_dob
																,Anniversary as [Owner_Anniversary Date]
																,@ShopTypeid,@user_id,
																GETDATE(),NULL,NULL,'' AS Shop_Image,0,NULL,0,(SELECT TOP(1)Shop_Code FROM tbl_Master_shop WHERE Shop_Name=temp.[Assigned To PP]),
																(SELECT TOP(1)Shop_Code FROM tbl_Master_shop WHERE Shop_Name=temp.[Assigned To DD]),@state_id,NULL,NULL,NULL,0,
																NULL,[Party Code],[Location],[Alternate Contact],case when [Status]='Active' then 1 else 0 end AS Entity_Status,@OutletType_id AS Entity_Type,[Owner PAN],[Owner Aadhaar],
																Remarks,@area_id,@CreateUser_Id,GETDATE()
																,@Retailer_ID,@Dealer_ID,@Party_Status_ID,@Beat_ID,
																[Account Holder],[Bank Name],[Account No],[IFSC Code],[UPI ID]
																--rev 6.0
																,[Cluster],[Alternate Email],[Alternate Contact 1],[GSTIN],[Trade License]
																--End of rev 6.0
																FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
																----rev 6.0
																--INSERT INTO FTS_PartyImportLog
																--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
																--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

																INSERT INTO FTS_PartyImportLog
																([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
																,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
																----End of rev 6.0
																--Rev work 8.0
																--SELECT *,'Sucess','Sucess',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
																SELECT 
																[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
																[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																,'Sucess','Sucess',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
																--End of Rev work 8.0
																
															END
														ELSE
															BEGIN
															--	--INSERT INTO FTS_PartyImportLog
															--	--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
															--	--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
															--	--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
															--	--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
															--	--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

																INSERT INTO FTS_PartyImportLog
																([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
																,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
																----End of rev 6.0
																--Rev work 8.0
																--SELECT *,'Faild','Invalid Entity Type',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
																SELECT 
																[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
																[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																,'Faild','Invalid Entity Type',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
																--End of Rev work 8.0
															END
													END
												ELSE
													BEGIN
														--INSERT INTO FTS_PartyImportLog
																--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
																--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

																INSERT INTO FTS_PartyImportLog
																([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
																,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
																----End of rev 6.0
														--Rev work 8.0
														--SELECT *,'Faild','Invalid User',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
														SELECT 
														[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
														[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
														[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
														,'Faild','Invalid User',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
															--End of Rev work 8.0
													END
											END
											ELSE
											BEGIN
												--INSERT INTO FTS_PartyImportLog
																--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
																--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

																INSERT INTO FTS_PartyImportLog
																([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
																,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
																----End of rev 6.0
												--Rev work 8.0
												--SELECT *,'Faild','Invalid State',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
														SELECT 
														[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
														[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
														[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
														,'Faild','Invalid State',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
												--End of rev work 8.0
												
											END
										END
										ELSE
										BEGIN
											--INSERT INTO FTS_PartyImportLog
																--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
																--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

																INSERT INTO FTS_PartyImportLog
																([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
																,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
																----End of rev 6.0
											--Rev work 8.0
											--SELECT *,'Faild','Invalid City',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
											SELECT 
											[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
											[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
											[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
											,'Faild','Invalid City',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
											--End of Rev 8.0
											
										END
									END
									ELSE
									BEGIN
										--INSERT INTO FTS_PartyImportLog
																--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
																--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

																INSERT INTO FTS_PartyImportLog
																([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
																[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
																,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
																,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
																----End of rev 6.0
										--Rev work 8.0
										--SELECT *,'Faild','Party Name Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
										
											SELECT 
											[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
											[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
											[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
											,'Faild','Party Name Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
										--End of Rev 8.0
									END
								END
								ELSE
								BEGIN
									--INSERT INTO FTS_PartyImportLog
									--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
									--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
									--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

									INSERT INTO FTS_PartyImportLog
									([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
									,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
									----End of rev 6.0
									--Rev work 8.0
									--SELECT *,'Faild','Invalid Shop Type',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
									
											SELECT 
											[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
											[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
											[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
											,'Faild','Invalid Shop Type',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
									--End of Rev 8.0
								END
							END
							ELSE
							BEGIN
								--INSERT INTO FTS_PartyImportLog
									--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
									--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
									--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

									INSERT INTO FTS_PartyImportLog
									([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
									,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
									----End of rev 6.0
								--SELECT *,'Faild','Party Code Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
								--Rev work 8.0
								SELECT 
								[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
								[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
								[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
								,'Faild','Party Code Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
								--End of Rev 8.0
								
							END
						END
						ELSE
						BEGIN
							--INSERT INTO FTS_PartyImportLog
									--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
									--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
									--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

									INSERT INTO FTS_PartyImportLog
									([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
									,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
									----End of rev 6.0
							--SELECT *,'Faild','Address Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
							--Rev work 8.0
								SELECT 
								[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
								[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
								[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
								,'Faild','Address Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
							--End of Rev 8.0
							
						END
					END
					ELSE
					BEGIN
						--INSERT INTO FTS_PartyImportLog
									--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
									--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
									--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

									INSERT INTO FTS_PartyImportLog
									([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
									,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
									----End of rev 6.0
							--Rev work 8.0
						--SELECT *,'Faild','Pin Code Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
						SELECT 
						[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
						[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
						[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
						,'Faild','Pin Code Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
						--End of Rev 8.0
						
					END
				END
				ELSE
				BEGIN
					--INSERT INTO FTS_PartyImportLog
									--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
									--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
									--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

									INSERT INTO FTS_PartyImportLog
									([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
									,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
									----End of rev 6.0
					--SELECT *,'Faild','Owner Name Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
					--Rev work 8.0
					SELECT 
					[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
					[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
					[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
					,'Faild','Owner Name Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
					--End of Rev 8.0
					
				END
			END
			ELSE
			BEGIN
				--INSERT INTO FTS_PartyImportLog
									--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
									--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
									--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

									INSERT INTO FTS_PartyImportLog
									([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
									,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
									----End of rev 6.0
				--SELECT *,'Faild','Status Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
				--Rev work 8.0
				SELECT 
				[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
				[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
				[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
				,'Faild','Status Blank',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
				--End of Rev 8.0

			END
			
		END
	ELSE
		BEGIN
			--INSERT INTO FTS_PartyImportLog
									--([State],[City],[Area],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									--[Contact],[Alternate Contact],[Email],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									--,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
									--,,[Shop_Owner_Email2],[Alt_MobileNo1],[GSTN_NUMBER],[Trade_Licence_Number]
																
									--,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])

									INSERT INTO FTS_PartyImportLog
									([State],[City],[Area],[Cluster],[Type],[Shoptype],[Entity],[Assigned To PP],[DDType],[Assigned To DD],[Party Name],[Party Code],[Party_Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
									[Contact],[Alternate Contact],[Alt_MobileNo1],[Email],[Shop_Owner_Email2],[Status],[Entity Type],[Owner PAN],[Owner Aadhaar],[GSTN_NUMBER],[Trade_Licence_Number],[Location],[beat_id],[account_holder],[account_no],[bank_name],[ifsc],[upi_id]
									,[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
																
																
																
									,[ImportStatus],[ImportMsg],[ImportDate],[CreateUser])
									----End of rev 6.0		
				--Rev work 8.0
			--SELECT *,'Faild','Owner Contact already Exists.',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
				SELECT 
				[State],[City],[Area],[Cluster],[Type],[Shop type],[Entity Type],[Assigned To PP],[DD Type],[Assigned To DD],[Party Name],[Party Code],[Party Status],[Address],[Pin Code],[Owner],[DOB],[Anniversary],
				[Contact],[Alternate Contact],[Alternate Contact 1],[Email],[Alternate Email],[Status],[Entity Category],[Owner PAN],[Owner Aadhaar],[GSTIN],[Trade License],[Location],@Beat_ID,[Account Holder],[Account No],[Bank Name],[IFSC Code],[UPI ID],
				[Remarks],[Assign to User],[Party Location Lat],[Party Location Lang]
				,'Faild','Owner Contact already Exists.',GETDATE(),@CreateUser_Id FROM @IMPORT_TABLE temp where [Contact]=@Shop_Owner_Contact
			--End of Rev work 8.0
		END
	SET @i=@i+1
	FETCH NEXT FROM DB_CURSOR INTO @Shop_Owner_Contact,@state,@EntityType,@AreaName,@CityName,@ShopType,@username,@PartyName,@PartyCode,@Address,@PinCode,@Owner,@Status
	,@Dealer_Type,@Retailer_Type,@Party_Status,@Beat,@Entity

 end

 close db_cursor
 deallocate db_cursor

 SELECT logs.* FROM FTS_PartyImportLog AS logs
 INNER JOIN @IMPORT_TABLE temp ON logs.[Contact] =temp.[Contact] 


 END
 GO