IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSInsertUpdateUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSInsertUpdateUser] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSInsertUpdateUser]
(
@txtusername NVARCHAR(300)=NULL,
@b_id NVARCHAR(100)=NULL,
@txtuserid NVARCHAR(500)=NULL,
@Encryptpass NVARCHAR(500)=NULL,
@contact NVARCHAR(100)=NULL,
@usergroup NVARCHAR(100)=NULL,
@CreateDate  NVARCHAR(50)=NULL,
@CreateUser  NVARCHAR(100)=NULL,
@superuser NVARCHAR(100)=NULL,
@ddDataEntry NVARCHAR(100)=NULL,
@IPAddress NVARCHAR(100)=NULL,
@isactive NVARCHAR(100)=NULL,
@isactivemac NVARCHAR(100)=NULL,
@txtgps NVARCHAR(100)=NULL,
@istargetsettings INT=NULL,
@isLeaveApprovalEnable INT=NULL,
@IsAutoRevisitEnable INT=NULL,
@IsShowPlanDetails INT=NULL,
@IsMoreDetailsMandatory INT=NULL,
@IsShowMoreDetailsMandatory INT=NULL,
@isMeetingAvailable INT=NULL,
@isRateNotEditable INT=NULL,
@IsShowTeamDetails INT=NULL,
@IsAllowPJPUpdateForTeam INT=NULL,
@willReportShow INT=NULL,
@isFingerPrintMandatoryForAttendance INT=NULL,
@isFingerPrintMandatoryForVisit INT=NULL,
@isSelfieMandatoryForAttendance INT=NULL,
--Rev 2.0 Start
@isAttendanceReportShow INT=NULL,
@isPerformanceReportShow INT=NULL,
@isVisitReportShow INT=NULL,
@willTimesheetShow INT=NULL,
@isAttendanceFeatureOnly INT=NULL,
@isOrderShow INT=NULL,
@isVisitShow INT=NULL,
@iscollectioninMenuShow INT=NULL,
@isShopAddEditAvailable INT=NULL,
@isEntityCodeVisible INT=NULL,
@isAreaMandatoryInPartyCreation INT=NULL,
@isShowPartyInAreaWiseTeam INT=NULL,
@isChangePasswordAllowed INT=NULL,
@isHomeRestrictAttendance INT=NULL,
--Rev 2.0 End
--Rev 3.0 End
@isQuotationShow INT=NULL,
@IsStateMandatoryinReport INT=NULL,
--Rev 3.0 End
@user_id BIGINT=NULL,
@ACTION NVARCHAR(MAX),
--Rev 4.0 End
@isAchievementEnable INT=NULL,
@isTarVsAchvEnable INT=NULL,
@shopLocAccuracy numeric(18,2)=NULL,
@homeLocDistance numeric(18,2)=NULL
--Rev 4.0 End
--Rev 5.0 End
,@isQuotationPopupShow INT=NULL,
@isOrderReplacedWithTeam INT=NULL,
@isMultipleAttendanceSelection INT=NULL,
@isOfflineTeam INT=NULL,
@isDDShowForMeeting INT=NULL,
@isDDMandatoryForMeeting INT=NULL,
@isAllTeamAvailable INT=NULL,
@isRecordAudioEnable INT=NULL,
@isNextVisitDateMandatory INT=NULL,
@isShowCurrentLocNotifiaction INT=NULL,
@isUpdateWorkTypeEnable INT=NULL,
@isLeaveEnable INT=NULL,
@isOrderMailVisible INT=NULL,
@LateVisitSMS INT=NULL,
@isShopEditEnable INT=NULL,
@isTaskEnable INT=NULL,
@PartyType nvarchar(max)=null,
@isAppInfoEnable  INT=NULL,
@willDynamicShow INT=NULL,
@willActivityShow INT=NULL,
@isDocumentRepoShow INT=NULL,
@isChatBotShow INT=NULL,
@isAttendanceBotShow INT=NULL,
@isVisitBotShow INT=NULL,
@appInfoMins INT=NULL
--Rev 5.0 End
--Rev 7.0 Start
,@isInstrumentCompulsory INT=NULL,
@isBankCompulsory INT=NULL
--Rev 7.0 End
--Rev 8.0 Start
,@isComplementaryUser INT=NULL,
@isVisitPlanShow INT=NULL
,@isVisitPlanMandatory INT=NULL,
@isAttendanceDistanceShow INT=NULL
,@willTimelineWithFixedLocationShow INT=NULL,
@isShowOrderRemarks INT=NULL
,@isShowOrderSignature INT=NULL,
@isShowSmsForParty INT=NULL
,@isShowTimeline INT=NULL,
@willScanVisitingCard INT=NULL
,@isCreateQrCode INT=NULL,
@isScanQrForRevisit INT=NULL
,@isShowLogoutReason INT=NULL,
@willShowHomeLocReason INT=NULL
,@willShowShopVisitReason INT=NULL,
@willShowPartyStatus INT=NULL
,@willShowEntityTypeforShop INT=NULL,
@isShowRetailerEntity INT=NULL
,@isShowDealerForDD INT=NULL,
@isShowBeatGroup INT=NULL
,@isShowShopBeatWise INT=NULL,
@isShowBankDetailsForShop INT=NULL
,@isShowOTPVerificationPopup INT=NULL,
@isShowMicroLearing INT=NULL
,@isMultipleVisitEnable INT=NULL,
@isShowVisitRemarks INT=NULL
,@isShowNearbyCustomer INT=NULL,
@isServiceFeatureEnable INT=NULL
,@isPatientDetailsShowInOrder INT=NULL,
@isPatientDetailsShowInCollection INT=NULL
,@isAttachmentMandatory INT=NULL,
@isShopImageMandatory INT=NULL
--Rev 8.0 End
--Rev 9.0
,@isLogShareinLogin INT=0,
@IsCompetitorenable INT=0
,@IsOrderStatusRequired INT=0,
@IsCurrentStockEnable INT=0
,@IsCurrentStockApplicableforAll INT=0,
@IscompetitorStockRequired INT=0
,@IsCompetitorStockforParty INT=0
,@ShowFaceRegInMenu INT=0
,@IsFaceDetection INT=0
,@IsUserwiseDistributer INT=0,
@IsPhotoDeleteShow INT=0
,@IsAllDataInPortalwithHeirarchy INT=0,
@IsFaceDetectionWithCaptcha INT=0
--Rev 9.0 End
--Rev 10.0
,@IsShowMenuAddAttendance INT=0,
@IsShowMenuAttendance INT=0
,@IsShowMenuShops INT=0,
@IsShowMenuOutstandingDetailsPPDD INT=0
,@IsShowMenuStockDetailsPPDD INT=0,
@IsShowMenuTA INT=0
,@IsShowMenuMISReport INT=0
,@IsShowMenuReimbursement INT=0
,@IsShowMenuAchievement INT=0
,@IsShowMenuMapView INT=0,
@IsShowMenuShareLocation INT=0
,@IsShowMenuHomeLocation INT=0,
@IsShowMenuWeatherDetails INT=0
,@IsShowMenuChat INT=0,
@IsShowMenuScanQRCode INT=0
,@IsShowMenuPermissionInfo INT=0,
@IsShowMenuAnyDesk INT=0
--Rev 10.0 End
--Rev 11.0 
,@IsDocRepoFromPortal INT=0
,@IsDocRepShareDownloadAllowed INT=0,
@IsScreenRecorderEnable INT=0
--Rev 11.0 End
--Rev 12.0 
,@IsShowPartyOnAppDashboard INT=0
,@IsShowAttendanceOnAppDashboard INT=0
,@IsShowTotalVisitsOnAppDashboard INT=0
,@IsShowVisitDurationOnAppDashboard INT=0
,@IsShowDayStart INT=0
,@IsshowDayStartSelfie INT=0
,@IsShowDayEnd INT=0
,@IsshowDayEndSelfie INT=0
,@IsShowLeaveInAttendance INT=0
,@IsShowMenu INT=0
,@IsLeaveGPSTrack INT=0
,@IsShowActivitiesInTeam INT=0
,@IsShowMarkDistVisitOnDshbrd INT=0
--End of rev 12.0
--rev 13.0
,@IsRevisitRemarksMandatory INT=0
,@GPSAlert INT=0
,@GPSAlertwithSound INT=0
--End of rev 13.0
-- Rev 14.0
,@FaceRegistrationFrontCamera INT=0
,@MRPInOrder INT=0,
-- End of Rev 14.0
--Rev Work 15.0 start
@isHorizontalPerformReportShow INT=0
--Rev Work 15.0 close
) 
AS
/***************************************************************************************************************************************
1.0		20-05-2020		Tanmoy		inactive user IMEI and password update
2.0		25-05-2020		Tanmoy		Insert update extra column
3.0		11-06-2020		Tanmoy		Insert update extra column
4.0		17-08-2020		Tanmoy		Insert update extra column
5.0		18-08-2020		Tanmoy		Insert update extra column
6.0		11-11-2020		Tanmoy		Insert update extra column
7.0		30-11-2020		Tanmoy		Insert update extra column
8.0		12-05-2021		Tanmoy		Insert update extra column
9.0		27-07-2021		Tanmoy		Insert update extra column
10.0	06-08-2021		Tanmoy		Insert update extra column
11.0	13-08-2021		Tanmoy		Insert update extra column
13.0	20-10-2021		Pratik		Insert update extra column
14.0	07-01-2022		Sanchita	Add two checkboxes "Face Registration - Open Front camera" and "MRP in Order". Refer: 24596,24597
15.0	11-05-2022		Swati	    Add one checkboxes "Show Horizontal Performance Report"  Refer: 0024880

***************************************************************************************************************************************/
BEGIN
	DECLARE @sqlStrTable NVARCHAR(MAX)
	IF OBJECT_ID('tempdb..#Shoptype_List') IS NOT NULL
	DROP TABLE #Shoptype_List
	CREATE TABLE #Shoptype_List (TypeId BIGINT)	
	IF @PartyType<>''
	BEGIN
		set @PartyType = REPLACE(''''+@PartyType+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #Shoptype_List select TypeId from tbl_shoptype where TypeId in('+@PartyType+')'
		EXEC SP_EXECUTESQL @sqlStrTable
	END

	IF @ACTION='INSERT'
		BEGIN
			INSERT INTO tbl_master_user 
			( user_name,user_branchId,user_loginId,user_password,user_contactId,user_group,CreateDate,CreateUser,user_lastsegement,user_TimeForTickerRefrsh,user_superuser,
			user_EntryProfile,user_AllowAccessIP,user_inactive,user_maclock,Gps_Accuracy,HierarchywiseTargetSettings,willLeaveApprovalEnable,IsAutoRevisitEnable,IsShowPlanDetails,
			IsMoreDetailsMandatory,IsShowMoreDetailsMandatory,isMeetingAvailable,isRateNotEditable,IsShowTeamDetails,IsAllowPJPUpdateForTeam,willReportShow,
			isFingerPrintMandatoryForAttendance,isFingerPrintMandatoryForVisit,isSelfieMandatoryForAttendance
			--Rev 2.0 Start
			,isAttendanceReportShow,isPerformanceReportShow,isVisitReportShow,willTimesheetShow,isAttendanceFeatureOnly,isOrderShow,isVisitShow,iscollectioninMenuShow,	
			isShopAddEditAvailable,isEntityCodeVisible,isAreaMandatoryInPartyCreation,isShowPartyInAreaWiseTeam,isChangePasswordAllowed,isHomeRestrictAttendance
			--Rev 2.0 End
			--Rev 3.0 Start 
			,isQuotationShow,IsStateMandatoryinReport
			--Rev 3.0 End
			--Rev 4.0 Start 
			,homeLocDistance,shopLocAccuracy,isAchievementEnable,isTarVsAchvEnable
			--Rev 4.0 End
			--Rev 5.0 Start 
			,isQuotationPopupShow,isOrderReplacedWithTeam,isMultipleAttendanceSelection,isOfflineTeam,isDDShowForMeeting,isDDMandatoryForMeeting,
			isAllTeamAvailable,isRecordAudioEnable,isNextVisitDateMandatory,isShowCurrentLocNotifiaction,isUpdateWorkTypeEnable,isLeaveEnable,
			isOrderMailVisible,LateVisitSMS,isShopEditEnable,isTaskEnable
			--Rev 5.0 End
			--Rev 6.0 Start
			,isAppInfoEnable,willDynamicShow,willActivityShow,isDocumentRepoShow,isChatBotShow,isAttendanceBotShow,isVisitBotShow,appInfoMins
			--Rev 6.0 End
			--Rev 7.0 Start
			,isInstrumentCompulsory,isBankCompulsory
			--Rev 7.0 End
			--Rev 8.0 Start
			,isComplementaryUser,isVisitPlanShow,isVisitPlanMandatory,isAttendanceDistanceShow,willTimelineWithFixedLocationShow,isShowOrderRemarks,isShowOrderSignature	
			,isShowSmsForParty,isShowTimeline,willScanVisitingCard,isCreateQrCode,isScanQrForRevisit,isShowLogoutReason,willShowHomeLocReason,willShowShopVisitReason
			,willShowPartyStatus,willShowEntityTypeforShop,isShowRetailerEntity,isShowDealerForDD,isShowBeatGroup,isShowShopBeatWise,isShowBankDetailsForShop,isShowOTPVerificationPopup
			,isShowMicroLearing,isMultipleVisitEnable,isShowVisitRemarks,isShowNearbyCustomer,isServiceFeatureEnable,isPatientDetailsShowInOrder,isPatientDetailsShowInCollection
			,isAttachmentMandatory,isShopImageMandatory
			--Rev 8.0 End
			--Rev 9.0 Start
			,isLogShareinLogin,IsCompetitorenable,IsOrderStatusRequired,IsCurrentStockEnable,IsCurrentStockApplicableforAll,IscompetitorStockRequired,IsCompetitorStockforParty	
			,ShowFaceRegInMenu,IsFaceDetection,IsUserwiseDistributer,IsPhotoDeleteShow,IsAllDataInPortalwithHeirarchy,IsFaceDetectionWithCaptcha
			--Rev 9.0 End
			--Rev 10.0 Start
			,IsShowMenuAddAttendance,IsShowMenuAttendance,IsShowMenuShops,IsShowMenuOutstandingDetailsPPDD,IsShowMenuStockDetailsPPDD,IsShowMenuTA,IsShowMenuMISReport,IsShowMenuReimbursement
			,IsShowMenuAchievement,IsShowMenuMapView,IsShowMenuShareLocation,IsShowMenuHomeLocation,IsShowMenuWeatherDetails,IsShowMenuChat,IsShowMenuScanQRCode,
			IsShowMenuPermissionInfo,IsShowMenuAnyDesk
			--End of Rev 10.0
			--Rev 11.0 Start
			,IsDocRepoFromPortal,IsDocRepShareDownloadAllowed,IsScreenRecorderEnable
			--End of Rev 11.0
			--Rev 12.0 
			,IsShowPartyOnAppDashboard,IsShowAttendanceOnAppDashboard,IsShowTotalVisitsOnAppDashboard,IsShowVisitDurationOnAppDashboard,IsShowDayStart,IsshowDayStartSelfie
			,IsShowDayEnd,IsshowDayEndSelfie,IsShowLeaveInAttendance,IsLeaveGPSTrack,IsShowActivitiesInTeam,IsShowMarkDistVisitOnDshbrd
			--End of rev 12.0
			--Rev 13.0 Start
			,RevisitRemarksMandatory,GPSAlert,GPSAlertwithSound
			--End of Rev 13.0
			-- Rev 14.0
			,FaceRegistrationFrontCamera,MRPInOrder
			-- End of Rev 14.0
			--Rev work 15.0 start
			,IsHierarchyforHorizontalPerformanceReport
			--Rev work 15.0 close
			)
			VALUES (@txtusername,@b_id,@txtuserid,@Encryptpass,@contact,@usergroup,@CreateDate,@CreateUser ,
			( select top 1 grp_segmentId from tbl_master_userGroup where grp_id in(@usergroup)),86400,@superuser,@ddDataEntry,@IPAddress,@isactive,@isactivemac,@txtgps,
			@istargetsettings,@isLeaveApprovalEnable,@IsAutoRevisitEnable,@IsShowPlanDetails,@IsMoreDetailsMandatory,@IsShowMoreDetailsMandatory,@isMeetingAvailable,
			@isRateNotEditable,@IsShowTeamDetails,@IsAllowPJPUpdateForTeam,@willReportShow,@isFingerPrintMandatoryForAttendance,
			@isFingerPrintMandatoryForVisit,@isSelfieMandatoryForAttendance
			--Rev 2.0 Start
			,@isAttendanceReportShow,@isPerformanceReportShow,@isVisitReportShow,@willTimesheetShow,@isAttendanceFeatureOnly,@isOrderShow,@isVisitShow,@iscollectioninMenuShow,	
			@isShopAddEditAvailable,@isEntityCodeVisible,@isAreaMandatoryInPartyCreation,@isShowPartyInAreaWiseTeam,@isChangePasswordAllowed,@isHomeRestrictAttendance
			--Rev 2.0 End
			--Rev 3.0 Start 
			,@isQuotationShow,@IsStateMandatoryinReport
			--Rev 3.0 End

			--Rev 4.0 Start 
			,@homeLocDistance,@shopLocAccuracy,@isAchievementEnable,@isTarVsAchvEnable
			--Rev 4.0 End
			--Rev 5.0 Start 
			,@isQuotationPopupShow,@isOrderReplacedWithTeam,@isMultipleAttendanceSelection,@isOfflineTeam,@isDDShowForMeeting,@isDDMandatoryForMeeting,
			@isAllTeamAvailable,@isRecordAudioEnable,@isNextVisitDateMandatory,@isShowCurrentLocNotifiaction,@isUpdateWorkTypeEnable,@isLeaveEnable,
			@isOrderMailVisible,@LateVisitSMS,@isShopEditEnable,@isTaskEnable
			--Rev 5.0 End
			--Rev 6.0 Start
			,@isAppInfoEnable,@willDynamicShow,@willActivityShow,@isDocumentRepoShow,@isChatBotShow,@isAttendanceBotShow,@isVisitBotShow,@appInfoMins
			--Rev 6.0 End
			--Rev 7.0 Start
			,@isInstrumentCompulsory,@isBankCompulsory
			--Rev 7.0 End
			--Rev 8.0 Start
			,@isComplementaryUser,@isVisitPlanShow,@isVisitPlanMandatory,@isAttendanceDistanceShow,@willTimelineWithFixedLocationShow,@isShowOrderRemarks,@isShowOrderSignature	
			,@isShowSmsForParty,@isShowTimeline,@willScanVisitingCard,@isCreateQrCode,@isScanQrForRevisit,@isShowLogoutReason,@willShowHomeLocReason,@willShowShopVisitReason
			,@willShowPartyStatus,@willShowEntityTypeforShop,@isShowRetailerEntity,@isShowDealerForDD,@isShowBeatGroup,@isShowShopBeatWise,@isShowBankDetailsForShop,@isShowOTPVerificationPopup
			,@isShowMicroLearing,@isMultipleVisitEnable,@isShowVisitRemarks,@isShowNearbyCustomer,@isServiceFeatureEnable,@isPatientDetailsShowInOrder,@isPatientDetailsShowInCollection
			,@isAttachmentMandatory,@isShopImageMandatory
			--Rev 8.0 End
			--Rev 9.0 Start
			,@isLogShareinLogin,@IsCompetitorenable,@IsOrderStatusRequired,@IsCurrentStockEnable,@IsCurrentStockApplicableforAll,@IscompetitorStockRequired,@IsCompetitorStockforParty	
			,@ShowFaceRegInMenu,@IsFaceDetection,@IsUserwiseDistributer,@IsPhotoDeleteShow,@IsAllDataInPortalwithHeirarchy,@IsFaceDetectionWithCaptcha
			--Rev 9.0 End
			--Rev 10.0 Start
			,@IsShowMenuAddAttendance,@IsShowMenuAttendance,@IsShowMenuShops,@IsShowMenuOutstandingDetailsPPDD,@IsShowMenuStockDetailsPPDD,@IsShowMenuTA,@IsShowMenuMISReport,@IsShowMenuReimbursement
			,@IsShowMenuAchievement,@IsShowMenuMapView,@IsShowMenuShareLocation,@IsShowMenuHomeLocation,@IsShowMenuWeatherDetails,@IsShowMenuChat,@IsShowMenuScanQRCode,
			@IsShowMenuPermissionInfo,@IsShowMenuAnyDesk
			--End of Rev 10.0
			--Rev 11.0 Start
			,@IsDocRepoFromPortal,@IsDocRepShareDownloadAllowed,@IsScreenRecorderEnable
			--End of Rev 11.0
			--Rev 12.0 
			,@IsShowPartyOnAppDashboard,@IsShowAttendanceOnAppDashboard,@IsShowTotalVisitsOnAppDashboard,@IsShowVisitDurationOnAppDashboard,@IsShowDayStart,@IsshowDayStartSelfie
			,@IsShowDayEnd,@IsshowDayEndSelfie,@IsShowLeaveInAttendance,@IsLeaveGPSTrack,@IsShowActivitiesInTeam,@IsShowMarkDistVisitOnDshbrd
			--End of rev 12.0
			--Rev 13.0 Start
			,@IsRevisitRemarksMandatory,@GPSAlert,@GPSAlertwithSound
			--End of Rev 13.0
			-- Rev 14.0
			,@FaceRegistrationFrontCamera,@MRPInOrder
			-- End of Rev 14.0
			--Rev work 15.0 start
			,@isHorizontalPerformReportShow
			--Rev work 15.0 close
			)

			set @user_id=SCOPE_IDENTITY();

			if exists (Select * from #Shoptype_List)
			BEGIN
				DELETE FROM FTS_UserPartyCreateAccess WHERE User_Id=@user_id

				INSERT INTO FTS_UserPartyCreateAccess
				SELECT @user_id,TypeId FROM #Shoptype_List
			END

		END

	ELSE IF @ACTION='UPDATE'
		BEGIN
			Update tbl_master_user SET user_name=@txtusername,user_branchId=@b_id,user_group=@usergroup,user_loginId=@txtuserid,user_inactive=@isactive,user_maclock=@isactivemac,user_contactid=@contact,
			LastModifyDate=@CreateDate,LastModifyUser=@CreateUser,user_superuser =@superuser,user_EntryProfile=@ddDataEntry,user_AllowAccessIP=@IPAddress,Gps_Accuracy=@txtgps,HierarchywiseTargetSettings=@istargetsettings,
			willLeaveApprovalEnable=@isLeaveApprovalEnable,IsAutoRevisitEnable=@IsAutoRevisitEnable,IsShowPlanDetails=@IsShowPlanDetails,IsMoreDetailsMandatory=@IsMoreDetailsMandatory,
			IsShowMoreDetailsMandatory=@IsShowMoreDetailsMandatory,isMeetingAvailable=@isMeetingAvailable,isRateNotEditable=@isRateNotEditable,
			IsShowTeamDetails=@IsShowTeamDetails,IsAllowPJPUpdateForTeam=@IsAllowPJPUpdateForTeam,willReportShow=@willReportShow,
			isFingerPrintMandatoryForAttendance=@isFingerPrintMandatoryForAttendance,isFingerPrintMandatoryForVisit=@isFingerPrintMandatoryForVisit,
			isSelfieMandatoryForAttendance=@isSelfieMandatoryForAttendance
			--Rev 2.0 Start
			,isAttendanceReportShow=@isAttendanceReportShow,isPerformanceReportShow=@isPerformanceReportShow,isVisitReportShow=@isVisitReportShow,willTimesheetShow=@willTimesheetShow,
			isAttendanceFeatureOnly=@isAttendanceFeatureOnly,isOrderShow=@isOrderShow,isVisitShow=@isVisitShow,iscollectioninMenuShow=@iscollectioninMenuShow,	
			isShopAddEditAvailable=@isShopAddEditAvailable,isEntityCodeVisible=@isEntityCodeVisible,isAreaMandatoryInPartyCreation=@isAreaMandatoryInPartyCreation,
			isShowPartyInAreaWiseTeam=@isShowPartyInAreaWiseTeam,isChangePasswordAllowed=@isChangePasswordAllowed,isHomeRestrictAttendance=@isHomeRestrictAttendance
			--Rev 2.0 End
			--Rev 3.0 Start 
			,isQuotationShow=@isQuotationShow,IsStateMandatoryinReport=@IsStateMandatoryinReport
			--Rev 3.0 End
			--Rev 4.0 Start 
			,homeLocDistance=@homeLocDistance,shopLocAccuracy=@shopLocAccuracy,isAchievementEnable=@isAchievementEnable,isTarVsAchvEnable=@isTarVsAchvEnable
			--Rev 4.0 End

			--Rev 5.0 Start 
			,isQuotationPopupShow=@isQuotationPopupShow,isOrderReplacedWithTeam=@isOrderReplacedWithTeam,isMultipleAttendanceSelection=@isMultipleAttendanceSelection,
			isOfflineTeam=@isOfflineTeam,isDDShowForMeeting=@isDDShowForMeeting,isDDMandatoryForMeeting=@isDDMandatoryForMeeting,
			isAllTeamAvailable=@isAllTeamAvailable,isRecordAudioEnable=@isRecordAudioEnable,isNextVisitDateMandatory=@isNextVisitDateMandatory,
			isShowCurrentLocNotifiaction=@isShowCurrentLocNotifiaction,isUpdateWorkTypeEnable=@isUpdateWorkTypeEnable,isLeaveEnable=@isLeaveEnable,
			isOrderMailVisible=@isOrderMailVisible,LateVisitSMS=@LateVisitSMS,isShopEditEnable=@isShopEditEnable,isTaskEnable=@isTaskEnable	
			--Rev 5.0 End
			--Rev 6.0 Start
			,isAppInfoEnable=@isAppInfoEnable,willDynamicShow=@willDynamicShow,willActivityShow=@willActivityShow,
			isDocumentRepoShow=@isDocumentRepoShow,isChatBotShow=@isChatBotShow,isAttendanceBotShow=@isAttendanceBotShow,isVisitBotShow=@isVisitBotShow,
			appInfoMins=@appInfoMins
			--Rev 6.0 End
			--Rev 7.0 Start
			,isInstrumentCompulsory=@isInstrumentCompulsory,isBankCompulsory=@isBankCompulsory
			--Rev 7.0 End
			--Rev 8.0 Start
			,isComplementaryUser=@isComplementaryUser,isVisitPlanShow=@isVisitPlanShow,isVisitPlanMandatory=@isVisitPlanMandatory,isAttendanceDistanceShow=@isAttendanceDistanceShow,
			willTimelineWithFixedLocationShow=@willTimelineWithFixedLocationShow,isShowOrderRemarks=@isShowOrderRemarks,isShowOrderSignature=@isShowOrderSignature
			,isShowSmsForParty=@isShowSmsForParty,isShowTimeline=@isShowTimeline,willScanVisitingCard=@willScanVisitingCard,isCreateQrCode=@isCreateQrCode,isScanQrForRevisit=@isScanQrForRevisit,
			isShowLogoutReason=@isShowLogoutReason,willShowHomeLocReason=@willShowHomeLocReason,willShowShopVisitReason=@willShowShopVisitReason
			,willShowPartyStatus=@willShowPartyStatus,willShowEntityTypeforShop=@willShowEntityTypeforShop,isShowRetailerEntity=@isShowRetailerEntity,isShowDealerForDD=@isShowDealerForDD,
			isShowBeatGroup=@isShowBeatGroup,isShowShopBeatWise=@isShowShopBeatWise,isShowBankDetailsForShop=@isShowBankDetailsForShop,isShowOTPVerificationPopup=@isShowOTPVerificationPopup
			,isShowMicroLearing=@isShowMicroLearing,isMultipleVisitEnable=@isMultipleVisitEnable,isShowVisitRemarks=@isShowVisitRemarks,isShowNearbyCustomer=@isShowNearbyCustomer,
			isServiceFeatureEnable=@isServiceFeatureEnable,isPatientDetailsShowInOrder=@isPatientDetailsShowInOrder,isPatientDetailsShowInCollection=@isPatientDetailsShowInCollection
			,isAttachmentMandatory=@isAttachmentMandatory,isShopImageMandatory=@isShopImageMandatory
			--Rev 8.0 End
			--Rev 9.0 Start
			,isLogShareinLogin=@isLogShareinLogin,IsCompetitorenable=@IsCompetitorenable,IsOrderStatusRequired=@IsOrderStatusRequired,IsCurrentStockEnable=@IsCurrentStockEnable,
			IsCurrentStockApplicableforAll=@IsCurrentStockApplicableforAll,IscompetitorStockRequired=@IscompetitorStockRequired,IsCompetitorStockforParty=@IsCompetitorStockforParty	
			,ShowFaceRegInMenu=@ShowFaceRegInMenu,IsFaceDetection=@IsFaceDetection,IsUserwiseDistributer=@IsUserwiseDistributer,
			IsPhotoDeleteShow=@IsPhotoDeleteShow,IsAllDataInPortalwithHeirarchy=@IsAllDataInPortalwithHeirarchy,IsFaceDetectionWithCaptcha=@IsFaceDetectionWithCaptcha
			--Rev 9.0 End
			--Rev 10.0 Start
			,IsShowMenuAddAttendance=@IsShowMenuAddAttendance,IsShowMenuAttendance=@IsShowMenuAttendance,IsShowMenuShops=@IsShowMenuShops,IsShowMenuOutstandingDetailsPPDD=@IsShowMenuOutstandingDetailsPPDD,
			IsShowMenuStockDetailsPPDD=@IsShowMenuStockDetailsPPDD,IsShowMenuTA=@IsShowMenuTA,IsShowMenuMISReport=@IsShowMenuMISReport,IsShowMenuReimbursement=@IsShowMenuReimbursement
			,IsShowMenuAchievement=@IsShowMenuAchievement,IsShowMenuMapView=@IsShowMenuMapView,IsShowMenuShareLocation=@IsShowMenuShareLocation,IsShowMenuHomeLocation=@IsShowMenuHomeLocation,
			IsShowMenuWeatherDetails=@IsShowMenuWeatherDetails,IsShowMenuChat=@IsShowMenuChat,IsShowMenuScanQRCode=@IsShowMenuScanQRCode,
			IsShowMenuPermissionInfo=@IsShowMenuPermissionInfo,IsShowMenuAnyDesk=@IsShowMenuAnyDesk
			--End of Rev 10.0
			--Rev 11.0 Start
			,IsDocRepoFromPortal=@IsDocRepoFromPortal,IsDocRepShareDownloadAllowed=@IsDocRepShareDownloadAllowed,IsScreenRecorderEnable=@IsScreenRecorderEnable
			--End of Rev 11.0
			--Rev 12.0 
			,IsShowPartyOnAppDashboard=@IsShowPartyOnAppDashboard,IsShowAttendanceOnAppDashboard=@IsShowAttendanceOnAppDashboard,IsShowTotalVisitsOnAppDashboard=@IsShowTotalVisitsOnAppDashboard,
			IsShowVisitDurationOnAppDashboard=@IsShowVisitDurationOnAppDashboard,IsShowDayStart=@IsShowDayStart,IsshowDayStartSelfie=@IsshowDayStartSelfie
			,IsShowDayEnd=@IsShowDayEnd,IsshowDayEndSelfie=@IsshowDayEndSelfie,IsShowLeaveInAttendance=@IsShowLeaveInAttendance,IsLeaveGPSTrack=@IsLeaveGPSTrack,
			IsShowActivitiesInTeam=@IsShowActivitiesInTeam,IsShowMarkDistVisitOnDshbrd=@IsShowMarkDistVisitOnDshbrd
			--End of rev 12.0
			--Rev 13.0 Start
			,RevisitRemarksMandatory=@IsRevisitRemarksMandatory,GPSAlert=@GPSAlert,GPSAlertwithSound=@GPSAlertwithSound
			--End of Rev 13.0
			-- Rev 14.0
			,FaceRegistrationFrontCamera=@FaceRegistrationFrontCamera,MRPInOrder=@MRPInOrder
			-- End of Rev 14.0
			--Rev work 15.0 start
			,IsHierarchyforHorizontalPerformanceReport=@isHorizontalPerformReportShow
			--Rev work 15.0 close
			 Where  user_id =@user_id

			 --Rev 1.0 Start
			IF ISNULL(@isactive,'N')='Y'
			BEGIN
				UPDATE tbl_User_IMEI SET Imei_No='NOT IN USE' WHERE UserId=@user_id
				Update tbl_master_user SET user_password=@Encryptpass WHERE  user_id =@user_id
			END
			--Rev 1.0 End

			if exists (Select * from #Shoptype_List)
			BEGIN
				DELETE FROM FTS_UserPartyCreateAccess WHERE User_Id=@user_id

				INSERT INTO FTS_UserPartyCreateAccess
				SELECT @user_id,TypeId FROM #Shoptype_List
			END

		END

	ELSE IF @ACTION='EDIT'
		BEGIN
			Select u.user_name as user1 , u.user_loginId as Login,u.user_branchId as Branchid,u.user_group as usergroup,u.user_AllowAccessIP,u.user_contactId as ContactId, 
			c.cnt_firstName + ' ' +c.cnt_lastName+'['+c.cnt_shortName+']' AS Name,c.cnt_internalId,c.cnt_id,u.user_id,u.user_superUser 
			,u.user_inactive,u.user_maclock,u.user_EntryProfile,u.Gps_Accuracy,u.HierarchywiseTargetSettings,ISNULL(u.willLeaveApprovalEnable,0) AS willLeaveApprovalEnable,
			ISNULL(u.IsAutoRevisitEnable,0) AS IsAutoRevisitEnable,ISNULL(u.IsShowPlanDetails,0) AS IsShowPlanDetails,ISNULL(u.IsMoreDetailsMandatory,0) AS IsMoreDetailsMandatory,
			ISNULL(u.IsShowMoreDetailsMandatory,0) AS IsShowMoreDetailsMandatory,ISNULL(u.isMeetingAvailable,0) AS isMeetingAvailable,
			ISNULL(u.isRateNotEditable,0) AS isRateNotEditable,ISNULL(u.IsShowTeamDetails,0) AS IsShowTeamDetails,ISNULL(u.IsAllowPJPUpdateForTeam,0) AS IsAllowPJPUpdateForTeam,
			ISNULL(u.willReportShow,0) AS willReportShow,ISNULL(u.isFingerPrintMandatoryForAttendance,0) AS isFingerPrintMandatoryForAttendance,
			ISNULL(u.isFingerPrintMandatoryForVisit,0) AS isFingerPrintMandatoryForVisit,ISNULL(u.isSelfieMandatoryForAttendance,0) AS isSelfieMandatoryForAttendance,
			ISNULL(u.isAttendanceReportShow,0) AS isAttendanceReportShow,ISNULL(u.isPerformanceReportShow,0) AS isPerformanceReportShow,ISNULL(u.isVisitReportShow,0) AS isVisitReportShow,
			ISNULL(u.willTimesheetShow,0) AS willTimesheetShow,ISNULL(u.isAttendanceFeatureOnly,0) AS isAttendanceFeatureOnly,ISNULL(u.isOrderShow,0) AS isOrderShow,
			ISNULL(u.isVisitShow,0) AS isVisitShow,ISNULL(u.iscollectioninMenuShow,0) AS iscollectioninMenuShow,ISNULL(u.isShopAddEditAvailable,0) AS isShopAddEditAvailable,
			ISNULL(u.isEntityCodeVisible,0) AS isEntityCodeVisible,ISNULL(u.isAreaMandatoryInPartyCreation,0) AS isAreaMandatoryInPartyCreation,
			ISNULL(u.isShowPartyInAreaWiseTeam,0) AS isShowPartyInAreaWiseTeam,ISNULL(u.isChangePasswordAllowed,0) AS isChangePasswordAllowed,
			ISNULL(u.isHomeRestrictAttendance,0) AS isHomeRestrictAttendance,ISNULL(u.isQuotationShow,0) AS isQuotationShow,ISNULL(u.IsStateMandatoryinReport,0) AS IsStateMandatoryinReport,
			ISNULL(u.isAchievementEnable,0) AS isAchievementEnable,ISNULL(u.isTarVsAchvEnable,0) AS isTarVsAchvEnable,u.homeLocDistance,u.shopLocAccuracy,
			ISNULL(u.isQuotationPopupShow,0) AS isQuotationPopupShow,ISNULL(u.isOrderReplacedWithTeam,0) AS isOrderReplacedWithTeam,ISNULL(u.isMultipleAttendanceSelection,0)AS isMultipleAttendanceSelection,
			ISNULL(u.isOfflineTeam,0) AS isOfflineTeam,ISNULL(u.isDDShowForMeeting,0) AS isDDShowForMeeting,ISNULL(u.isDDMandatoryForMeeting,0) AS isDDMandatoryForMeeting,
			ISNULL(u.isAllTeamAvailable,0) AS isAllTeamAvailable,ISNULL(u.isRecordAudioEnable,0) AS isRecordAudioEnable,ISNULL(u.isNextVisitDateMandatory,0) AS isNextVisitDateMandatory,
			ISNULL(u.isShowCurrentLocNotifiaction,0) AS isShowCurrentLocNotifiaction,ISNULL(isUpdateWorkTypeEnable,0) AS isUpdateWorkTypeEnable,ISNULL(u.isLeaveEnable,0) AS isLeaveEnable,
			ISNULL(u.isOrderMailVisible,0) AS isOrderMailVisible,ISNULL(u.LateVisitSMS,0) AS LateVisitSMS,ISNULL(u.isShopEditEnable,0) AS isShopEditEnable,ISNULL(u.isTaskEnable,0) AS isTaskEnable

			,ISNULL(u.isAppInfoEnable,0) AS isAppInfoEnable,ISNULL(u.willDynamicShow,0) AS willDynamicShow,ISNULL(u.willActivityShow,0) AS willActivityShow,ISNULL(u.isDocumentRepoShow,0) AS isDocumentRepoShow
			,ISNULL(u.isChatBotShow,0) AS isChatBotShow,ISNULL(u.isAttendanceBotShow,0) AS isAttendanceBotShow,ISNULL(u.isVisitBotShow,0) AS isVisitBotShow,ISNULL(u.appInfoMins,0) AS appInfoMins
			--Rev 7.0 Start
			,ISNULL(u.isInstrumentCompulsory,0) as isInstrumentCompulsory,ISNULL(u.isBankCompulsory,0) as isBankCompulsory
			--Rev 7.0 End
			--Rev 8.0 Start
			,ISNULL(u.isComplementaryUser,0) AS isComplementaryUser,ISNULL(u.isVisitPlanShow,0) AS isVisitPlanShow,ISNULL(u.isVisitPlanMandatory,0) AS isVisitPlanMandatory,
			ISNULL(u.isAttendanceDistanceShow,0) AS isAttendanceDistanceShow,ISNULL(u.willTimelineWithFixedLocationShow,0) AS willTimelineWithFixedLocationShow,
			ISNULL(u.isShowOrderRemarks,0) AS isShowOrderRemarks,ISNULL(u.isShowOrderSignature,0) AS isShowOrderSignature,ISNULL(u.isShowSmsForParty,0) AS isShowSmsForParty,
			ISNULL(u.isShowTimeline,0) AS isShowTimeline,ISNULL(u.willScanVisitingCard,0) AS willScanVisitingCard,ISNULL(u.isCreateQrCode,0) AS isCreateQrCode,
			ISNULL(u.isScanQrForRevisit,0) AS isScanQrForRevisit,ISNULL(u.isShowLogoutReason,0) AS isShowLogoutReason,ISNULL(u.willShowHomeLocReason,0) AS willShowHomeLocReason,
			ISNULL(u.willShowShopVisitReason,0) AS willShowShopVisitReason,ISNULL(u.willShowPartyStatus,0) AS willShowPartyStatus,ISNULL(u.willShowEntityTypeforShop,0) AS willShowEntityTypeforShop,
			ISNULL(u.isShowRetailerEntity,0) AS isShowRetailerEntity,ISNULL(u.isShowDealerForDD,0) AS isShowDealerForDD,ISNULL(u.isShowBeatGroup,0) AS isShowBeatGroup,
			ISNULL(u.isShowShopBeatWise,0) AS isShowShopBeatWise,ISNULL(u.isShowBankDetailsForShop,0) AS isShowBankDetailsForShop,ISNULL(u.isShowOTPVerificationPopup,0) AS isShowOTPVerificationPopup
			,ISNULL(u.isShowMicroLearing,0) AS isShowMicroLearing,ISNULL(u.isMultipleVisitEnable,0) AS isMultipleVisitEnable,ISNULL(u.isShowVisitRemarks,0) AS isShowVisitRemarks,
			ISNULL(u.isShowNearbyCustomer,0) AS isShowNearbyCustomer,ISNULL(u.isServiceFeatureEnable,0) AS isServiceFeatureEnable,ISNULL(u.isPatientDetailsShowInOrder,0) AS isPatientDetailsShowInOrder,
			ISNULL(u.isPatientDetailsShowInCollection,0) AS isPatientDetailsShowInCollection,ISNULL(u.isAttachmentMandatory,0) AS isAttachmentMandatory,ISNULL(u.isShopImageMandatory,0) AS isShopImageMandatory
			--Rev 8.0 End
			--Rev 9.0 Start
			,ISNULL(u.isLogShareinLogin,0) AS isLogShareinLogin,ISNULL(u.IsCompetitorenable,0) AS IsCompetitorenable,ISNULL(u.IsOrderStatusRequired,0) AS IsOrderStatusRequired,
			ISNULL(u.IsCurrentStockEnable,0) AS IsCurrentStockEnable,ISNULL(u.IsCurrentStockApplicableforAll,0) AS IsCurrentStockApplicableforAll,ISNULL(u.IscompetitorStockRequired,0) AS IscompetitorStockRequired,
			ISNULL(u.IsCompetitorStockforParty,0) AS IsCompetitorStockforParty,ISNULL(u.ShowFaceRegInMenu,0) AS ShowFaceRegInMenu,ISNULL(u.IsFaceDetection,0) AS IsFaceDetection,
			ISNULL(u.IsUserwiseDistributer,0) AS IsUserwiseDistributer,ISNULL(u.IsPhotoDeleteShow,0) AS IsPhotoDeleteShow,ISNULL(u.IsAllDataInPortalwithHeirarchy,0) AS IsAllDataInPortalwithHeirarchy,ISNULL(u.IsFaceDetectionWithCaptcha,0) AS IsFaceDetectionWithCaptcha
			--Rev 9.0 End
			--Rev 10.0 Start
			,IsShowMenuAddAttendance,IsShowMenuAttendance,IsShowMenuShops,IsShowMenuOutstandingDetailsPPDD,IsShowMenuStockDetailsPPDD,IsShowMenuTA,IsShowMenuMISReport,IsShowMenuReimbursement
			,IsShowMenuAchievement,IsShowMenuMapView,IsShowMenuShareLocation,IsShowMenuHomeLocation,IsShowMenuWeatherDetails,IsShowMenuChat,IsShowMenuScanQRCode,
			IsShowMenuPermissionInfo,IsShowMenuAnyDesk
			--End of Rev 10.0
			--Rev 11.0 Start
			,IsDocRepoFromPortal,IsDocRepShareDownloadAllowed,IsScreenRecorderEnable
			--End of Rev 11.0
			--Rev 12.0 
			,IsShowPartyOnAppDashboard,IsShowAttendanceOnAppDashboard,IsShowTotalVisitsOnAppDashboard,IsShowVisitDurationOnAppDashboard,IsShowDayStart,IsshowDayStartSelfie
			,IsShowDayEnd,IsshowDayEndSelfie,IsShowLeaveInAttendance,IsLeaveGPSTrack,IsShowActivitiesInTeam,IsShowMarkDistVisitOnDshbrd
			--End of rev 12.0
			--Rev 13.0 
			,GPSAlert,GPSAlertwithSound,RevisitRemarksMandatory as IsRevisitRemarksMandatory
			--End of rev 13.0
			-- Rev 14.0
			,FaceRegistrationFrontCamera,MRPInOrder
			-- End of Rev 14.0
			--Rev work 15.0 start
			,ISNULL(u.ISHIERARCHYFORHORIZONTALPERFORMANCEREPORT,0) AS IsHorizontalPerformReportShow
			--rev work 15.0 close
			From tbl_master_user u,tbl_master_contact c Where u.user_id=@user_id AND u.user_contactId=c.cnt_internalId


			SELECT STUFF(
             (SELECT ',' + CONVERT(NVARCHAR(10),t1.Shop_TypeId)
              FROM FTS_UserPartyCreateAccess t1
              WHERE t1.User_Id=@user_id
              FOR XML PATH (''))
             , 1, 1, '') as Shop_TypeId 

		END

	ELSE IF @ACTION='ShowSettings'
		BEGIN
			select [key],[Value] from FTS_APP_CONFIG_SETTINGS 
			where [Key] in ('EnableLeaveonApproval','ActiveAutomaticRevisit','InputDayPlan','ActiveMoreDetailsMandatory','DisplayMoreDetailsWhileNewVisit',
			'ShowMeetingsOption','ShowProductRateInApp','isActivatePJPFeature','FingerPrintAttend','FingerPrintVisit','SelfieAttend','IsShowReport',
			'isAttendanceReportShow','isPerformanceReportShow','isVisitReportShow','willTimesheetShow','isAttendanceFeatureOnly','isOrderShow',
			'isVisitShow','iscollectioninMenuShow','isShopAddEditAvailable','isEntityCodeVisible','isAreaMandatoryInPartyCreation','isShowPartyInAreaWiseTeam',
			'isChangePasswordAllowed','isHomeRestrictAttendance','isQuotationShow','isCustomerFeatureEnable','IsShowTeamDetails','isQuotationPopupShow','isAchievementEnable',
			'isTarVsAchvEnable','isOrderReplacedWithTeam','isMultipleAttendanceSelection','isOfflineTeam','isDDShowForMeeting','isDDMandatoryForMeeting',
			'isAllTeamAvailable','isRecordAudioEnable','isNextVisitDateMandatory','isShowCurrentLocNotifiaction','isUpdateWorkTypeEnable','isLeaveEnable',
			'isOrderMailVisible','LateVisitSMS','isShopEditEnable','isTaskEnable','HierarchywiseTargetSettings'
			,'isAppInfoEnable','willDynamicShow','IsCRMApplicable','isDocumentRepoShow','isChatBotShow','isAttendanceBotShow','isVisitBotShow'
			--Rev 7.0 Start
			,'isInstrumentCompulsory','isBankCompulsory'
			--Rev 7.0 End
			--Rev 8.0 Start
			,'isComplementaryUser','isVisitPlanShow','isVisitPlanMandatory','isAttendanceDistanceShow','willTimelineWithFixedLocationShow','isShowOrderRemarks','isShowOrderSignature'	
			,'isShowSmsForParty','isShowTimeline','willScanVisitingCard','isCreateQrCode','isScanQrForRevisit','isShowLogoutReason','willShowHomeLocReason','willShowShopVisitReason'
			,'willShowPartyStatus','willShowEntityTypeforShop','isShowRetailerEntity','isShowDealerForDD','isShowBeatGroup','isShowShopBeatWise','isShowBankDetailsForShop','isShowOTPVerificationPopup'
			,'isShowMicroLearing','isMultipleVisitEnable','isShowVisitRemarks','isShowNearbyCustomer','isServiceFeatureEnable','isPatientDetailsShowInOrder','isPatientDetailsShowInCollection'
			,'isAttachmentMandatory','isShopImageMandatory'
			--Rev 8.0 End
			--Rev 9.0 Start
			,'isLogShareinLogin','IsCompetitorenable','IsOrderStatusRequired','IsCurrentStockEnable','IsCurrentStockApplicableforAll','IscompetitorStockRequired','IsCompetitorStockforParty','IsFaceDetectionOn'
			,'IsUserwiseDistributer','IsAllDataInPortalwithHeirarchy'
			--Rev 9.0 End
			--Rev 10.0 Start
			,'IsShowMenuAddAttendance','IsShowMenuAttendance','IsShowMenuShops','IsShowMenuOutstandingDetailsPPDD','IsShowMenuStockDetailsPPDD','IsShowMenuTA','IsShowMenuMISReport','IsShowMenuReimbursement'
			,'IsShowMenuAchievement','IsShowMenuMapView','IsShowMenuShareLocation','IsShowMenuHomeLocation','IsShowMenuWeatherDetails','IsShowMenuChat','IsShowMenuScanQRCode',
			'IsShowMenuPermissionInfo','IsShowMenuAnyDesk'
			--End of Rev 10.0
			--Rev 11.0 Start
			,'IsDocRepoFromPortal','IsDocRepShareDownloadAllowed','IsScreenRecorderEnable'
			--End of Rev 11.0
			--Rev 12.0 
			,'IsShowPartyOnAppDashboard','IsShowAttendanceOnAppDashboard','IsShowTotalVisitsOnAppDashboard','IsShowVisitDurationOnAppDashboard','IsShowLeaveInAttendance','IsLeaveGPSTrack','IsShowActivitiesInTeam'
			--End of rev 12.0
			--Rev 13.0 
			,'GPSAlert','IsRevisitRemarksMandatory'
			--End of rev 13.0
			-- Rev 14.0
			,'FaceRegistrationFrontCamera','MRPInOrder'
			-- End of Rev 14.0
			--Rev work 15.0 start
			,'IsHierarchyforHorizontalPerformanceReport'
			--Rev work 15.0 close
			)
		END
END