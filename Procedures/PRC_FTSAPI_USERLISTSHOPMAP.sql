--EXEC PRC_FTSAPI_USERLISTSHOPMAP 'FaceMatch',11986

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSAPI_USERLISTSHOPMAP]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSAPI_USERLISTSHOPMAP] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSAPI_USERLISTSHOPMAP]
(
--Rev 1.0
--@USER_ID BIGINT,
@Action NVARCHAR(100),
@USER_ID BIGINT,
@BaseURL NVARCHAR(500)=NULL
--End of Rev 1.0
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Tanmoy Ghosh
Purpose : For API/FaceRegistration/UserList & API/FaceRegistration/FaceMatch API
1.0		v2.0.24		Debashis	19/07/2021		API/FaceRegistration/FaceMatch implemented.
2.0		v2.0.24		Debashis	26/07/2021		Two new columns added as IsPhotoDeleteShow & ShowDDInFaceRegistration.
3.0		v2.0.24		Debashis	05/08/2021		A new column added as Registration_Datetime.
4.0		v2.0.24		Tanmoy		15/08/2021		@Action='UserList' add Active user checking
5.0		v2.0.25		Debashis	13/09/2021		Three new columns added as IsAadhaarRegistered,RegisteredAadhaarNo & RegisteredAadhaarDocLink.
6.0		v2.0.25		Debashis	06/10/2021		A new column added as aadhaar_remarks.
7.0		v2.0.25		Debashis	01/12/2021		Aadhar link send and Aadhar info delete.
8.0		v2.0.26		Debashis	13/12/2021		Some new fields has been added.
9.0		v2.0.26		Debashis	20-12-2021		A new fields has been added.
10.0	v2.0.26		Debashis	18-01-2022		A new fields has been added.Row No: 613
11.0	v2.0.26		Debashis	31-01-2022		A new fields has been added.Row No: 630 & 631
12.0	v2.0.27		Debashis	23-02-2022		A new fields has been added.Row No: 657
13.0	v2.0.27		Debashis	02-03-2022		A new fields has been added.Row No: 664
14.0	v2.0.27		Debashis	08-03-2022		Some new fields has been added.Row No: 665
***************************************************************************************************************************************************************************************************/
BEGIN
	--Rev 1.0
	--SELECT USR.USER_NAME AS user_name,USR.USER_LOGINID AS user_login_id,Convert(bigint,USR.USER_ID) AS user_id,USR.USER_CONTACTID AS user_contactid,
	--0 AS isFaceRegistered 
	--FROM FTS_EmployeeShopMap MAP
	--INNER JOIN TBL_MASTER_USER USR ON MAP.USER_ID=USR.USER_ID
	--WHERE EXISTS(SELECT SHOP_CODE FROM FTS_EmployeeShopMap WHERE USER_ID=@USER_ID AND MAP.SHOP_CODE =FTS_EmployeeShopMap.SHOP_CODE )

	SET NOCOUNT ON
	IF @Action='UserList'
		BEGIN
			--Rev 2.0 && Two new columns added as IsPhotoDeleteShow & ShowDDInFaceRegistration
			--Rev 3.0 && A new column added as Registration_Datetime
			--Rev 5.0 && Three new columns added as IsAadhaarRegistered,RegisteredAadhaarNo & RegisteredAadhaarDocLink
			--Rev 6.0 && A new column added as aadhaar_remarks
			SELECT USR.USER_NAME AS user_name,USR.USER_LOGINID AS user_login_id,Convert(bigint,USR.USER_ID) AS user_id,USR.USER_CONTACTID AS user_contactid,
			@BaseURL+ISNULL(USR.FaceImage,'') AS face_image_link,isFaceRegistered AS isFaceRegistered,USR.IsPhotoDeleteShow AS IsPhotoDeleteShow,MS.Shop_Name AS ShowDDInFaceRegistration,
			CASE WHEN USR.Registration_Datetime IS NULL THEN NULL ELSE CONVERT(NVARCHAR(10),USR.Registration_Datetime,105)+' '+CONVERT(VARCHAR(5),CAST(USR.Registration_Datetime AS TIME),108) END AS registration_date_time,
			CASE WHEN AADHINFO.AADHAAR_NO<>'' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsAadhaarRegistered,ISNULL(AADHINFO.AADHAAR_NO,'') AS RegisteredAadhaarNo,
			CASE WHEN AADHINFO.AADHAAR_NO<>'' THEN @BaseURL+ISNULL(AADHINFO.DOCUMENTIMAGE,'') ELSE '' END AS RegisteredAadhaarDocLink,ISNULL(AADHINFO.FEEDBACK,'') AS aadhaar_remarks,
			--Rev 7.0
			@BaseURL+ISNULL(USR.AadharImage,'') AS aadhar_image_link,
			--End of Rev 7.0
			--Rev 8.0
			USR.FaceRegTypeID AS [type_id],ISNULL(FTSSTG.Stage,'') AS [type_name],
			--End of Rev 8.0
			--Rev 9.0
			ISNULL(AADHDETINFO.REG_DOC_TYPE,'') AS Registered_with,
			--End of Rev 9.0
			--Rev 10.0
			ISNULL(PHNO.phf_phoneNumber,'') AS emp_phone_no,
			--End of Rev 10.0
			--Rev 11.0
			USR.IsShowManualPhotoRegnInApp,USR.IsTeamAttenWithoutPhoto,
			--End of Rev 11.0
			--Rev 12.0
			USR.IsAllowClickForVisitForSpecificUser,
			--End of Rev 12.0
			--Rev 13.0
			CASE WHEN USR.user_inactive='N' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsActiveUser,
			--End of Rev 13.0
			--Rev 14.0
			USR.UpdateOtherID,USR.UpdateUserID,EMP.cnt_OtherID AS OtherID
			--End of Rev 14.0
			FROM FTS_EmployeeShopMap MAP WITH(NOLOCK)
			INNER JOIN TBL_MASTER_USER USR WITH(NOLOCK) ON MAP.USER_ID=USR.USER_ID
			--Rev 4.0
			and USR.user_inactive='N'
			--End of Rev 4.0
			--Rev 2.0
			INNER JOIN tbl_Master_shop MS WITH(NOLOCK) ON MAP.SHOP_CODE=MS.Shop_Code AND MS.type=4
			--End of Rev 2.0
			--Rev 14.0
			INNER JOIN tbl_master_employee EMP WITH(NOLOCK) ON USR.user_contactId=EMP.emp_contactId
			--End of Rev 14.0
			--Rev 6.0
			LEFT OUTER JOIN FSMEMPLOYEEAADHARINFORMATION AADHINFO WITH(NOLOCK) ON USR.USER_ID=AADHINFO.USER_ID
			--End of Rev 6.0
			--Rev 9.0
			LEFT OUTER JOIN FSMUSERAADHARIMAGEDETECTION AADHDETINFO WITH(NOLOCK) ON USR.USER_ID=AADHDETINFO.USER_ID
			--End of Rev 9.0
			--Rev 8.0
			LEFT OUTER JOIN FTS_Stage FTSSTG WITH(NOLOCK) ON USR.FaceRegTypeID=FTSSTG.StageID
			--End of Rev 8.0
			--Rev 10.0
			LEFT OUTER JOIN tbl_master_phonefax PHNO WITH(NOLOCK) ON USR.user_contactId=PHNO.phf_cntId AND phf_entity='employee' AND phf_type='Office'
			--End of Rev 10.0
			WHERE EXISTS(SELECT SHOP_CODE FROM FTS_EmployeeShopMap WITH(NOLOCK) WHERE USER_ID=@USER_ID AND MAP.SHOP_CODE =FTS_EmployeeShopMap.SHOP_CODE )
		END
	ELSE IF @Action='FaceMatch'
		BEGIN
			SELECT USR.USER_ID AS user_id,ISNULL(USR.FaceImage,'') AS face_image_link,isFaceRegistered AS isFaceRegistered 
			FROM TBL_MASTER_USER USR WITH(NOLOCK) WHERE user_id=@USER_ID AND FaceImage<>''
		END
	ELSE IF @Action='FaceImgDel'
		BEGIN
			--Rev 7.0
			--SELECT USR.USER_ID,ISNULL(USR.FaceImage,'') AS face_image_link INTO #TMPGETIMG FROM TBL_MASTER_USER USR WHERE user_id=@USER_ID

			--SELECT USER_ID,face_image_link FROM #TMPGETIMG

			--UPDATE TBL_MASTER_USER SET FaceImage='',isFaceRegistered=0 WHERE user_id=@USER_ID

			SELECT USR.USER_ID,ISNULL(USR.FaceImage,'') AS face_image_link,ISNULL(USR.AadharImage,'') AS aadhar_image_link INTO #TMPGETIMG FROM TBL_MASTER_USER USR WITH(NOLOCK) WHERE user_id=@USER_ID

			SELECT USER_ID,face_image_link,aadhar_image_link FROM #TMPGETIMG

			UPDATE TBL_MASTER_USER  WITH(TABLOCK)SET FaceImage='',isFaceRegistered=0,Registration_Datetime=NULL,AadharImage='',isAadharRegistered=0,AadharRegistration_Datetime=NULL WHERE user_id=@USER_ID

			DELETE FROM FSMUSERAADHARIMAGEDETECTION WITH(TABLOCK) WHERE USER_ID=@USER_ID
			--End of Rev 7.0

			--SELECT USR.USER_ID AS user_id,ISNULL(USR.FaceImage,'') AS face_image_link,isFaceRegistered AS isFaceRegistered 
			--FROM TBL_MASTER_USER USR WHERE user_id=@USER_ID
		END

	SET NOCOUNT OFF
	--End of Rev 1.0
END