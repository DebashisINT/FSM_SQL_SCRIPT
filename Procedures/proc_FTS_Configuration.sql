--EXEC proc_FTS_Configuration @Action='GlobalCheck',@UserID=11738

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[proc_FTS_Configuration]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [proc_FTS_Configuration] AS' 
END
GO

ALTER PROCEDURE [dbo].[proc_FTS_Configuration]
(
@Action varchar(50)=NULL,
@UserID varchar(100)=NULL
) --WITH ENCRYPTION
AS
BEGIN
	/************************************************************************************************************************************************************************
	1.0			Tanmoy		16-10-2019	ADD THREE SETTINGS isStockAvailableForPopup,isOrderAvailableForPopup,isCollectionAvailableForPopup
	2.0			Tanmoy		30-10-2019	ADD column @isDDFieldEnabled
	3.0			Tanmoy		14-11-2019	ADD column @willStockShow  maxFileSize
	4.0			Tanmoy		21-11-2019	ADD column @maxFileSize for maximum File Size
	5.0			Tanmoy		27-11-2019	ADD column @willKnowYourStateShow FOR Know your state report show or not
	6.0			Tanmoy		29-11-2019	ADD column @willAttachmentCompulsory,@canAddBilling FOR Attachment in Invoice Mandatory and
																								Order with Multiple Invoice Allowed
	7.0			Tanmoy		23-12-2019	ADD column @willShowUpdateDayPlan,@updateDayPlanText,@dailyPlanListHeaderText for Primary Found plan 
													show or hide,Fund plan Button text and fund plan header text
	8.0			Tanmoy		31-12-2019	ADD column @addShopHeaderText for all user and willMoreVisitUpdateOptional,willMoreVisitUpdateCompulsory for user wise
	9.0			Tanmoy		06-01-2020	ADD column @allPlanListHeaderText for all PLAN LIST HEADER TEXT
	10.0		Tanmoy		07-01-2020	ADD column @willSetYourTodaysTargetVisible for Set Your Todays Target Visible
	11.0		Tanmoy		07-01-2020	ADD TWO column @attendenceAlertHeading,@attendenceAlertText for No Plan alert header and msg
	12.0		Tanmoy		15-01-2020	ADD TWO SETTINGS @Action='UserCheck' isMeetingAvailable ,isRateNotEditable
	13.0		Tanmoy		20-01-2020	ADD one  SETTINGS @Action='GlobalCheck' @meetingText FOR MEETING HEADER TEXT
	14.0		Tanmoy		21-01-2020	ADD one  SETTINGS @Action='GlobalCheck' @meetingDistance FOR Metting Force complet when out of this meter
	15.0		Tanmoy		23-01-2020	ADD TWO  SETTINGS @Action='UserCheck' autoRevisitDistance,autoRevisitTime FOR REVISIT COMPLETE TIME AND DISTANCE
	16.0		Tanmoy		27-01-2020	ADD SETTINGS @Action='UserCheck' IsAutoRevisitEnable FOR ENABLE AUTO REVISIT
	17.0		Tanmoy		18-02-2020	USER WISE SETTINGS MOVE TO MASTER_CONTACT TO MASTER_USER
	18.0		Tanmoy		02-04-2020	ADD one  SETTINGS @Action='GlobalCheck' @isActivatePJPFeature FOR Activate PJP Feature
	19.0		Tanmoy		02-04-2020	ADD SETTINGS @Action='UserCheck' willShowTeamDetails,isAllowPJPUpdateForTeam FOR TEAM DETAILS SHOW AND PJP FOR TEAM
	20.0		Tanmoy		10-04-2020	ADD one  SETTINGS @Action='GlobalCheck' @willReimbursementShow FOR Reimbursement Feature SHOW HIDE
	21.0		Tanmoy		16-04-2020	ADD one  SETTINGS @Action='UserCheck' willReportShow FOR report menu SHOW HIDE
	22.0		Tanmoy		22-04-2020	ADD three  SETTINGS @Action='UserCheck' willAttendanceReportShow,willPerformanceReportShow,willVisitReportShow
	23.0		Tanmoy		23-04-2020	ADD a  SETTINGS @Action='GlobalCheck' updateBillingText for Order to Billing button text
	24.0		Tanmoy		23-04-2020	ADD a  SETTINGS @Action='UserCheck' attendance_text for attendance time in time show
	25.0		Indranil	29-04-2020	ADD one  SETTINGS @Action='UserCheck' willTimeSheethow FOR Time sheet show hide in TAB
	26.0		Tanmoy		04-05-2020	ADD three  SETTINGS @Action='UserCheck' isOrderShow,isVisitShow,iscollectioninMenuShow FOR Report show hide in TAB
	27.0		Tanmoy		11-05-2020	ADD three  SETTINGS @Action='UserCheck' isShopAddEditAvailable,isEntityCodeVisible,isTeamWithoutDDList 
	28.0		Tanmoy		11-05-2020	ADD SETTINGS @Action='GlobalCheck' isRateOnline FOR ONLINE PRODUCT RATE SHOW HIDE
	29.0		Tanmoy		15-05-2020	ADD SETTINGS @Action='UserCheck' isAreaMandatoryInPartyCreation,isShowPartyInAreaWiseTeam
	30.0		Tanmoy		20-05-2020	ADD SETTINGS @Action='UserCheck' isChangePasswordAllowed,isHomeRestrictAttendance
	31.0		Tanmoy		02-06-2020	ADD SETTINGS @Action='GlobalCheck' ppText,ddText
	32.0		Tanmoy		09-06-2020	ADD SETTINGS shopText for all and isQuotationShow for User wise
	33.0		Tanmoy		09-06-2020	ADD SETTINGS @Action='GlobalCheck' isCustomerFeatureEnable,isAreaVisible
	34.0		Tanmoy		16-06-2020	ADD SETTINGS @Action='GlobalCheck' CGSTPercentage,SGSTPercentage,TCSPercentage
	35.0		Tanmoy		18-06-2020	ADD SETTINGS @Action='UserCheck' homeLocDistance,shopLocAccuracy,isQuotationPopupShow
	36.0		Tanmoy		23-06-2020	ADD SETTINGS @Action='UserCheck' isOrderReplacedWithTeam
	37.0		Tanmoy		24-06-2020	ADD SETTINGS @Action='UserCheck' isMultipleAttendanceSelection
	38.0		Tanmoy		30-06-2020	ADD SETTINGS @Action='UserCheck' isDDShowForMeeting,isDDMandatoryForMeeting
	39.0		Tanmoy		22-07-2020	ADD SETTINGS @Action='UserCheck' isNextVisitDateMandatory,isRecordAudioEnable,isAchievementEnable,isTarVsAchvEnable
	40.0		Tanmoy		29-07-2020	ADD SETTINGS @Action='UserCheck' isShowCurrentLocNotifiaction
	41.0		Tanmoy		04-08-2020	ADD SETTINGS @Action='UserCheck' isUpdateWorkTypeEnable
	42.0		Indranil		
	43.0		Tanmoy		11-08-2020	ADD SETTINGS @Action='UserCheck' isShopEditEnable
	44.0		Indranil	18-08-2020	ADD SETTINGS @Action='UserCheck' isTaskEnable
	45.0		Tanmoy		19-08-2020	ADD SETTINGS @Action='UserCheck' isAppInfoEnable,appInfoMins
	47.0		Tanmoy		20-10-2020	ADD SETTINGS @Action='GlobalCheck' docAttachmentNo
	48.0		Tanmoy		20-10-2020	ADD SETTINGS @Action='UserCheck' isDocumentRepoShow
	49.0		Tanmoy		29-10-2020	ADD SETTINGS @Action='UserCheck' isChatBotShow,isAttendanceBotShow,isVisitBotShow
	50.0		Tanmoy		30-10-2020	ADD SETTINGS @Action='GlobalCheck' chatBotMsg
	51.0		Tanmoy		04-11-2020	ADD SETTINGS @Action='GlobalCheck' contactMail
	52.0		Tanmoy		30-11-2020	ADD SETTINGS @Action='UserCheck' isInstrumentCompulsory,isBankCompulsory
	53.0		Tanmoy		04-12-2020	ADD SETTINGS @Action='UserCheck' isVisitPlanShow,isVisitPlanMandatory
	54.0		Tanmoy		08-12-2020	ADD SETTINGS @Action='UserCheck' isAttendanceDistanceShow
	55.0		Tanmoy		16-12-2020	ADD SETTINGS @Action='UserCheck' willTimelineWithFixedLocationShow
	56.0		Tanmoy		21-12-2020	ADD SETTINGS @Action='UserCheck' isShowOrderRemarks,isShowOrderSignature
	57.0		Tanmoy		21-12-2020	ADD SETTINGS @Action='GlobalCheck' isVoiceEnabledForAttendanceSubmit,isVoiceEnabledForOrderSaved,isVoiceEnabledForInvoiceSaved,isVoiceEnabledForCollectionSaved,isVoiceEnabledForHelpAndTipsInBot
	58.0		Tanmoy		24-12-2020	ADD SETTINGS @Action='UserCheck' isShowSmsForParty
	59.0		INDRANIL	25-12-2020	ADD SETTINGS @Action='UserCheck' willShowPartyStatus,willShowEntityTypeforShop
	60.0		INDRANIL	25-12-2020	ADD SETTINGS @Action='UserCheck' isShowRetailerEntity,isShowDealerForDD,isShowBeatGroup
	61.0		INDRANIL	25-12-2020	ADD SETTINGS @Action='UserCheck' isShowShopBeatWise,isShowBankDetailsForShop
	62.0		INDRANIL	25-12-2020	ADD SETTINGS @Action='UserCheck' isShowOTPVerificationPopup
	63.0		INDRANIL	25-12-2020	ADD SETTINGS @Action='UserCheck' locationTrackInterval
	64.0		INDRANIL	25-12-2020	ADD SETTINGS @Action='UserCheck' isShowMicroLearing
	65.0		INDRANIL	17-03-2021	ADD SETTINGS @Action='UserCheck' homeLocReasonCheckMins
	66.0		INDRANIL	18-03-2021	ADD SETTINGS @Action='UserCheck' currentLocationNotificationMins,isMultipleVisitEnable,isShowVisitRemarks
	67.0		INDRANIL	18-03-2021	ADD SETTINGS @Action='UserCheck' isShowNearbyCustomer
	68.0		TANMOY		08-04-2021	ADD SETTINGS @Action='UserCheck' isServiceFeatureEnable
	69.0		TANMOY		09-04-2021	ADD SETTINGS @Action='UserCheck' isPatientDetailsShowInOrder,isPatientDetailsShowInCollection
	70.0		TANMOY		22-04-2021	ADD SETTINGS @Action='UserCheck' isShopImageMandatory
	71.0		TANMOY		26-05-2021	ADD SETTINGS @Action='UserCheck' isLogShareinLogin,IsOrderStatusRequired,IsCompetitorenable
	72.0		TANMOY		14-07-2021	ADD SETTINGS @Action='UserCheck' ShowFaceRegInMenu,IsFaceDetection
	73.0		Debashis	26-07-2021	ADD SETTINGS @Action='UserCheck' IsFaceDetectionWithCaptcha
	74.0		Debashis	02-08-2021	ADD SETTINGS @Action='UserCheck' IsDocRepoFromPortal,IsDocRepShareDownloadAllowed and IsScreenRecorderEnable
	75.0		Tanmoy		05-08-2021	ADD SETTINGS @Action='UserCheck' app menu settings
	76.0		Debashis	11-08-2021	ADD SETTINGS @Action='UserCheck' IsShowPartyOnAppDashboard,IsShowAttendanceOnAppDashboard,IsShowTotalVisitsOnAppDashboard and IsShowVisitDurationOnAppDashboard
	77.0		Debashis	11-08-2021	ADD SETTINGS @Action='UserCheck' IsLeaveGPSTrack and IsShowActivitiesInTeam
	78.0		Debashis	16-08-2021	ADD SETTINGS @Action='UserCheck' IsShowLeaveInAttendance,IsShowDayStart,IsshowDayStartSelfie,IsShowDayEnd and IsShowActivitiesInTeam
	79.0		Debashis	20-08-2021	ADD SETTINGS @Action='UserCheck' IsShowMarkDistVisitOnDshbrd
	80.0		Debashis	02-09-2021	ADD SETTINGS @Action='UserCheck' IsActivateNewOrderScreenwithSize
	81.0		Debashis	21-09-2021	ADD SETTINGS @Action='UserCheck' IsPhotoDeleteShow
	82.0		Debashis	21-09-2021	ADD SETTINGS @Action='UserCheck' RevisitRemarksMandatory
	83.0		Debashis	11-10-2021	ADD SETTINGS @Action='UserCheck' GPSAlert & GPSAlertwithSound.Refer: 0024408
	84.0		Debashis	29-10-2021	ADD SETTINGS @Action='UserCheck' IsTeamAttendance
	85.0		Debashis	02-11-2021	ADD SETTINGS @Action='GlobalCheck' IsDuplicateShopContactnoAllowedOnline
	86.0		Debashis	24-11-2021	ADD SETTINGS @Action='UserCheck' FaceDetectionAccuracyUpper,FaceDetectionAccuracyLower & DistributorGPSAccuracy
	87.0		Debashis	29-11-2021	ADD SETTINGS @Action='UserCheck' & 'GlobalCheck' BatterySetting & PowerSaverSetting
	88.0		Debashis	06-12-2021	ADD SETTINGS @Action='GlobalCheck' IsnewleadtypeforRuby
	89.0		Debashis	09-12-2021	ADD SETTINGS @Action='UserCheck' & 'GlobalCheck' Show_App_Logout_Notification
	90.0		Debashis	13-12-2021	ADD SETTINGS @Action='UserCheck' IsShowTypeInRegistration
	91.0		Debashis	21-12-2021	ADD SETTINGS @Action='UserCheck' IsReturnEnableforParty
	92.0		Debashis	21-12-2021	ADD SETTINGS @Action='GlobalCheck' IsReturnActivatedforPP, IsReturnActivatedforDD & IsReturnActivatedforSHOP
	93.0		Debashis	10-01-2022	ADD SETTINGS @Action='UserCheck' & 'GlobalCheck' MRPInOrder & FaceRegistrationFrontCamera. Row 601 & 602
	94.0		Debashis	10-01-2022	ADD SETTINGS @Action='UserCheck' & 'GlobalCheck' IsShowMyDetails. Row 609 & 610
	95.0		Debashis	10-01-2022	ADD SETTINGS @Action='UserCheck' IslandlineforCustomer & IsprojectforCustomer. Row 614
	96.0		Debashis	28-01-2022	ADD SETTINGS @Action='GlobalCheck' IsAttendVisitShowInDashboard & IsShowInPortalManualPhotoRegn. Row 623
	97.0		Debashis	28-01-2022	ADD SETTINGS @Action='UserCheck' IsAttendVisitShowInDashboard,IsShowManualPhotoRegnInApp,Leaveapprovalfromsupervisorinteam & Leaveapprovalfromsupervisor.Row 624
	98.0		Debashis	04-02-2022	ADD SETTINGS @Action='UserCheck' IsIMEICheck,IsRestrictNearbyGeofence & IsNewQuotationfeatureOn.Row 634 & 655
	99.0		Debashis	04-02-2022	ADD SETTINGS @Action='GlobalCheck' SqMtrRateCalculationforQuotEuro. Row 635
	100.0		Debashis	04-02-2022	ADD SETTINGS @Action='UserCheck' IsAlternateNoForCustomer & IsWhatsappNoForCustomer.Row 636
	101.0		Debashis	14-02-2022	ADD SETTINGS @Action='UserCheck' MarkAttendNotification & UpdateUserName.Row 644
	102.0		Debashis	21-02-2022	ADD SETTINGS @Action='UserCheck' IsNewQuotationNumberManual,ShowQuantityNewQuotation & ShowAmountNewQuotation.Row 653
	103.0		Debashis	21-02-2022	ADD SETTINGS @Action='GlobalCheck' NewQuotationRateCaption & NewQuotationShowTermsAndCondition. Row 654
	104.0		Debashis	23-02-2022	ADD SETTINGS @Action='UserCheck' IsAllowClickForPhotoRegister & IsAllowClickForVisit.Row 656
	105.0		Debashis	01-03-2022	ADD SETTINGS @Action='UserCheck' ShowUserwiseLeadMenu.Row 659
	106.0		Debashis	22-03-2022	ADD SETTINGS @Action='UserCheck' AllowProfileUpdate & GeofencingRelaxationinMeter.Row 671
	107.0		Debashis	30-03-2022	ADD SETTINGS @Action='UserCheck' LogoutWithLogFile & InAppUpdateApplicable.Row 672
	108.0		Debashis	31-03-2022	ADD SETTINGS @Action='UserCheck' IsFeedbackHistoryActivated & IsAutoLeadActivityDateTime.Row 674
	109.0		Debashis	07-04-2022	ADD SETTINGS @Action='UserCheck' ShowAutoRevisitInDashboard & ShowAutoRevisitInAppMenu.Row 679
	110.0		Debashis	18-04-2022	ADD SETTINGS @Action='UserCheck' IsShowNearByTeam,IsShowRevisitRemarksPopup & IsAllowShopStatusUpdate.Row 680 & 681
	111.0		Debashis	02-05-2022	ADD SETTINGS @Action='UserCheck' ShowTotalVisitAppMenu & OfflineShopAccuracy.Row 683
	112.0		Debashis	04-05-2022	ADD SETTINGS @Action='UserCheck' AutoRevisitTimeInSeconds.Row 684
	113.0		Debashis	05-05-2022	ADD SETTINGS @Action='UserCheck' PartyUpdateAddrMandatory.Row 685
	114.0		Debashis	26-05-2022	ADD SETTINGS @Action='UserCheck' IsCollectionOrderWise,ShowCollectionOnlywithInvoiceDetails,ShowCollectionAlert,ShowZeroCollectioninAlert,
																		 & IsPendingCollectionRequiredUnderTeam.Row 686
	115.0		Debashis	26-02-2022	ADD SETTINGS @Action='GlobalCheck' IsCollectionEntryConsiderOrderOrInvoice.Row 687
	116.0		Debashis	03-06-2022	ADD SETTINGS @Action='UserCheck' IsShowRepeatOrderinNotification & IsShowRepeatOrdersNotificationinTeam.Row 695
	117.0		Debashis	08-06-2022	ADD SETTINGS @Action='UserCheck' AutoDDSelect & ShowPurposeInShopVisit.Row 696
	118.0		Debashis	08-06-2022	ADD SETTINGS @Action='GlobalCheck' ContactNameText,ContactNumberText,EmailText,DobText & DateOfAnniversaryText. Row 697
	119.0		Debashis	15-06-2022	ADD SETTINGS @Action='UserCheck' WillRoomDBShareinLogin & GPSAlertwithVibration.Row 698
	120.0		Debashis	17-06-2022	ADD SETTINGS @Action='GlobalCheck' & 'UserCheck' ShopScreenAftVisitRevisit. Row 699 & 700
	121.0		Debashis	29-06-2022	ADD SETTINGS @Action='UserCheck' IsFeedbackAvailableInShop.Row 705
	122.0		Debashis	29-06-2022	ADD SETTINGS @Action='UserCheck' IsAllowBreakageTracking,IsAllowBreakageTrackingunderTeam & IsRateEnabledforNewOrderScreenwithSize.Row 706
	123.0		Debashis	11-07-2022	ADD SETTINGS @Action='UserCheck' IgnoreNumberCheckwhileShopCreation.Row 711
	124.0		Debashis	13-07-2022	ADD SETTINGS @Action='UserCheck' Showdistributorwisepartyorderreport.Row 714
	125.0		Debashis	13-07-2022	ADD SETTINGS @Action='GlobalCheck' IsSurveyRequiredforNewParty & IsSurveyRequiredforDealer.Row 720
	126.0		Debashis	22-07-2022	ADD SETTINGS @Action=GlobalCheck' & 'UserCheck' IsShowHomeLocationMap.Row 721 & 722
	127.0		Debashis	08-08-2022	ADD SETTINGS @Action=GlobalCheck' IsBeatRouteAvailableinAttendance & IsAllBeatAvailableforParty.Row 726
	128.0		Debashis	08-08-2022	ADD SETTINGS @Action='UserCheck' IsBeatRouteReportAvailableinTeamr.Row 727
	129.0		Debashis	09-08-2022	ADD SETTINGS @Action='UserCheck' ShowAttednaceClearmenu.Row 729
	130.0		Debashis	12-08-2022	ADD SETTINGS @Action='GlobalCheck' BeatText & TodaysTaskText.Row 731
	131.0		Debashis	14-09-2022	ADD SETTINGS @Action='UserCheck' CommonAINotification & IsFaceRecognitionOnEyeblink.Row 738
	132.0		Debashis	15-09-2022	ADD SETTINGS @Action=GlobalCheck' IsDistributorSelectionRequiredinAttendance.Row 740
	133.0		Debashis	22-09-2022	ADD SETTINGS @Action='UserCheck' GPSNetworkIntervalMins.Row 741
	134.0		Debashis	02-11-2022	ADD SETTINGS @Action=GlobalCheck' IsAllowNearbyshopWithBeat & IsGSTINPANEnableInShop.Row 751 & 752
	135.0		Debashis	09-11-2022	ADD SETTINGS @Action=GlobalCheck' IsMultipleImagesRequired.Row 760
	136.0		Debashis	17-11-2022	ADD SETTINGS @Action=GlobalCheck' IsALLDDRequiredforAttendance.Row 766
	137.0		Debashis	18-11-2022	ADD SETTINGS @Action='UserCheck' IsShowTypeInRegistrationForSpecificUser & IsFeedbackMandatoryforNewShop.Row 767 & 768
	138.0		Debashis	28-11-2022	ADD SETTINGS @Action=GlobalCheck' IsShowNewOrderCart, IsmanualInOutTimeRequired & surveytext.Row 769
	139.0		Debashis	28-11-2022	ADD SETTINGS @Action='UserCheck' IsLoginSelfieRequired.Row 770
	140.0		Debashis	07-12-2022	ADD SETTINGS @Action=GlobalCheck' IsDiscountInOrder & IsViewMRPInOrder.Row 772
	141.0		Debashis	12-12-2022	ADD SETTINGS @Action=UserCheck' IsJointVisitEnable & IsShowAllEmployeeforJointVisit.Row 775
	142.0		Debashis	12-12-2022	ADD SETTINGS @Action=GlobalCheck' IsShowStateInTeam,IsShowBranchInTeam,IsShowDesignationInTeam & IsAllowZeroRateOrder.Row 778
	143.0		Debashis	09-01-2023	ADD SETTINGS @Action=UserCheck' IsMultipleContactEnableforShop & IsContactPersonSelectionRequiredinRevisit.Row 782
	144.0		Debashis	10-01-2023	ADD SETTINGS @Action=UserCheck' IsContactPersonRequiredinQuotation.Row 789
	145.0		Debashis	17-01-2023	ADD SETTINGS @Action=UserCheck' IsShowBeatInMenu.Row 796
	146.0		Debashis	17-01-2023	ADD SETTINGS @Action=GlobalCheck' IsBeatAvailable.Row 797
	147.0		Debashis	25-01-2023	ADD SETTINGS @Action=GlobalCheck' isExpenseFeatureAvailable.Row 808
	148.0		Debashis	02-02-2023	ADD SETTINGS @Action=GlobalCheck' IsDiscountEditableInOrder & IsRouteStartFromAttendance.Row 809
	149.0		Debashis	08-02-2023	ADD SETTINGS @Action=GlobalCheck' IsShowOtherInfoinShopMaster & IsShowQuotationFooterforEurobond.Row 812
	150.0		Debashis	22-03-2023	ADD SETTINGS @Action=GlobalCheck' ShowApproxDistanceInNearbyShopList.Row 815
	151.0		Debashis	06-04-2023	ADD SETTINGS @Action=UserCheck' IsAssignedDDAvailableForAllUser.Row 816
	152.0		Debashis	06-04-2023	ADD SETTINGS @Action=GlobalCheck' IsAssignedDDAvailableForAllUser.Row 817
	153.0		Debashis	24-04-2023	ADD SETTINGS @Action=UserCheck' IsShowEmployeePerformance.Row 823
	154.0		Debashis	24-04-2023	ADD SETTINGS @Action=GlobalCheck' IsShowEmployeePerformance.Row 824
	155.0		Debashis	08-05-2023	ADD SETTINGS @Action=GlobalCheck' IsShowPrivacyPolicyInMenu,IsAttendanceCheckedforExpense,IsShowLocalinExpense,IsShowOutStationinExpense,
																		  IsTAAttachment1Mandatory,IsTAAttachment2Mandatory,IsSingleDayTAApplyRestriction,
																		  NameforConveyanceAttachment1,NameforConveyanceAttachment2 & IsTaskManagementAvailable.Row 825,826 & 827
	156.0		Debashis	16-05-2023	ADD SETTINGS @Action=GlobalCheck' IsAttachmentAvailableForCurrentStock.Row 833
	157.0		Debashis	16-05-2023	ADD SETTINGS @Action=GlobalCheck' IsShowReimbursementTypeInAttendance.Row 838
	158.0		Debashis	19-05-2023	ADD SETTINGS @Action=GlobalCheck' IsBeatPlanAvailable.Row 841
	159.0		Debashis	01-06-2023	ADD SETTINGS @Action=UserCheck' IsShowWorkType,IsShowMarketSpendTimer,IsShowUploadImageInAppProfile,IsShowCalendar,
																		IsShowCalculator,IsShowInactiveCustomer & IsShowAttendanceSummary.Row 844
	160.0		Debashis	02-06-2023	ADD SETTINGS @Action=GlobalCheck' IsUpdateVisitDataInTodayTable.Row 848
	161.0		Debashis	06-06-2023	ADD SETTINGS @Action=UserCheck' IsMenuShowAIMarketAssistant.Row 849
	162.0		Debashis	30-06-2023	ADD SETTINGS @Action=GlobalCheck' ConsiderInactiveShopWhileLogin.Row 851
	163.0		Debashis	17-07-2023	ADD SETTINGS @Action=GlobalCheck' ShopSyncIntervalInMinutes.Row 856
	164.0		Debashis	17-07-2023	ADD SETTINGS @Action=UserCheck'	IsUsbDebuggingRestricted.Row 858
	165.0		Debashis	01-08-2023	ADD SETTINGS @Action=GlobalCheck' IsShowWhatsAppIconforVisit & IsAutomatedWhatsAppSendforRevisit.Row 860
	166.0		Debashis	17-08-2023	ADD SETTINGS @Action=GlobalCheck' IsAllowBackdatedOrderEntry & Order_Past_Days.Row 863
	167.0		Debashis	21-08-2023	ADD SETTINGS @Action=GlobalCheck' Show_distributor_scheme_with_Product.Row 864
	168.0		Debashis	06-10-2023	ADD SETTINGS @Action=GlobalCheck' GSTINPANMandatoryforSHOPTYPE4,FSSAILicNoEnableInShop & FSSAILicNoMandatoryInShop4.Row 871
	169.0		Debashis	06-10-2023	ADD SETTINGS @Action=UserCheck'	IsDisabledUpdateAddress.Row 872
	170.0		Debashis	16-11-2023	ADD SETTINGS @Action=UserCheck'	IsCheckBatteryOptimization.Row 877
	171.0		Debashis	16-11-2023	ADD SETTINGS @Action=GlobalCheck' isLeadContactNumber,isModelEnable,isPrimaryApplicationEnable,isBookingAmount,isLeadTypeEnable,
																		isStageEnable & isFunnelStageEnable.Row 879
	172.0		Debashis	04-12-2023	ADD SETTINGS @Action=GlobalCheck' MultiVisitIntervalInMinutes.Row 866
	173.0		Debashis	04-12-2023	ADD SETTINGS @Action=UserCheck'	IsShowMenuCRMContacts.Row 886
	174.0		Debashis	20-12-2023	ADD SETTINGS @Action=UserCheck'	IsCallLogHistoryActivated.Row 887
	175.0		Debashis	22-12-2023	ADD SETTINGS @Action=UserCheck'	IsAllDataInPortalwithHeirarchy.Row 890
	176.0		Debashis	22-12-2023	ADD SETTINGS @Action=GlobalCheck'	IsGPSRouteSync & IsSyncBellNotificationInApp.Row 891
	177.0		Debashis	05-01-2023	ADD SETTINGS @Action=GlobalCheck'	IsShowCustomerLocationShare.Row 899 & Refer: 0027139
	*****************************************************************************************************************************************************************************/ 
	SET NOCOUNT ON

	DECLARE @max_accuracy varchar(50)
	DECLARE @min_accuracy varchar(50)
	DECLARE @min_distance varchar(50)
	DECLARE @max_distance varchar(50)
	DECLARE @idle_time varchar(50)
	DECLARE @isRevisitCaptureImage bit
	DECLARE @isShowAllProduct bit
	DECLARE @isPrimaryTargetMandatory bit
	DECLARE @isStockAvailableForAll bit

	DECLARE @isStockAvailableForPopup bit
	DECLARE @isOrderAvailableForPopup bit
	DECLARE @isCollectionAvailableForPopup bit
	DECLARE @isDDFieldEnabled bit
	DECLARE @willStockShow bit
	DECLARE @maxFileSize nvarchar(10)
	DECLARE @willKnowYourStateShow bit
	DECLARE @willAttachmentCompulsory bit
	DECLARE @canAddBillingFromBillingList bit
	DECLARE @willShowUpdateDayPlan BIT
	DECLARE @updateDayPlanText NVARCHAR(100)
	DECLARE @dailyPlanListHeaderText NVARCHAR(200)
	DECLARE @addShopHeaderText NVARCHAR(200)
	DECLARE @allPlanListHeaderText NVARCHAR(200)
	DECLARE @willSetYourTodaysTargetVisible BIT
	DECLARE @attendenceAlertHeading NVARCHAR(200)
	DECLARE @attendenceAlertText NVARCHAR(200)
	DECLARE @meetingText NVARCHAR(200)
	DECLARE @meetingDistance NVARCHAR(100)
	--Rev 18.0 Start
	,@isActivatePJPFeature BIT
	--Rev 18.0 End
	--Rev 20.0 Start
	,@willReimbursementShow BIT
	--Rev 20.0 End
	--Rev 23.0
	,@updateBillingText NVARCHAR(200)
	--Rev 23.0 End
	--Rev 28.0
	,@isRateOnline BIT
	--Rev 28.0 End
	--Rev 31.0
	,@ppText nvarchar(500)
	,@ddText nvarchar(500)
	--Rev 31.0 End
	--Rev 32.0
	,@shopText nvarchar(100)
	--Rev 32.0 End
	--Rev 33.0
	,@isCustomerFeatureEnable BIT,@isAreaVisible BIT
	--Rev 33.0 End
	--Rev 33.0
	,@CGSTPercentage NVARCHAR(5),@SGSTPercentage NVARCHAR(5),@TCSPercentage NVARCHAR(10)
	--Rev 33.0 End
	--Rev 47.0
	,@docAttachmentNo INT
	--Rev 47.0 End
	--Rev 50.0
	,@chatBotMsg NVARCHAR(200)
	--Rev 50.0 End
	--Rev 51.0
	,@contactMail NVARCHAR(100)
	--Rev 51.0 End
	--Rev 57.0
	,@isVoiceEnabledForAttendanceSubmit BIT,@isVoiceEnabledForOrderSaved BIT,@isVoiceEnabledForInvoiceSaved BIT
	,@isVoiceEnabledForCollectionSaved BIT,@isVoiceEnabledForHelpAndTipsInBot BIT
	--Rev 57.0 End
	--Rev 83.0
	,@GPSAlert BIT
	--End of Rev 83.0
	--Rev 85.0
	,@IsDuplicateShopContactnoAllowedOnline BIT
	--End of Rev 85.0
	--Rev 87.0
	,@BatterySetting BIT
	,@PowerSaverSetting BIT
	--End of Rev 87.0
	--Rev 88.0
	,@IsnewleadtypeforRuby BIT
	--End of Rev 88.0
	--Rev 89.0
	,@Show_App_Logout_Notification BIT
	--End of Rev 89.0
	--Rev 92.0
	,@IsReturnActivatedforPP BIT
	,@IsReturnActivatedforDD BIT
	,@IsReturnActivatedforSHOP BIT
	--End of Rev 92.0
	--Rev 93.0
	,@MRPInOrder BIT
	,@FaceRegistrationFrontCamera BIT
	--End of Rev 93.0
	--Rev 94.0
	,@IsShowMyDetails BIT
	--End of Rev 94.0
	--Rev 96.0
	,@IsAttendVisitShowInDashboard BIT
	,@IsShowInPortalManualPhotoRegn BIT
	--End of Rev 96.0
	--Rev 99.0
	,@SqMtrRateCalculationforQuotEuro DECIMAL(18,3)
	--End of Rev 99.0
	--Rev 103.0
	,@NewQuotationRateCaption NVARCHAR(50)
	,@NewQuotationShowTermsAndCondition BIT
	--End of Rev 103.0
	--Rev 115.0
	,@IsCollectionEntryConsiderOrderOrInvoice BIT
	--End of Rev 115.0
	--Rev 118.0
	,@ContactNameText NVARCHAR(300)
	,@ContactNumberText NVARCHAR(300)
	,@EmailText NVARCHAR(300)
	,@DobText NVARCHAR(300)
	,@DateOfAnniversaryText NVARCHAR(300)
	--End of Rev 118.0
	--Rev 120.0
	,@ShopScreenAftVisitRevisit BIT
	--End of Rev 120.0
	--Rev 125.0
	,@IsSurveyRequiredforNewParty BIT
	,@IsSurveyRequiredforDealer BIT
	--End of Rev 125.0
	--Rev 126.0
	,@IsShowHomeLocationMap BIT
	--End of Rev 126.0
	--Rev 127.0
	,@IsBeatRouteAvailableinAttendance BIT
	,@IsAllBeatAvailable BIT
	--End of Rev 127.0
	--Rev 130.0
	,@BeatText NVARCHAR(200)
	,@TodaysTaskText NVARCHAR(200)
	--End of Rev 130.0
	--Rev 132.0
	,@IsDistributorSelectionRequiredinAttendance BIT
	--End of Rev 132.0
	--Rev 134.0
	,@IsAllowNearbyshopWithBeat BIT
	,@IsGSTINPANEnableInShop BIT
	--End of Rev 134.0
	--Rev 135.0
	,@IsMultipleImagesRequired BIT
	--End of Rev 135.0
	--Rev 136.0
	,@IsALLDDRequiredforAttendance BIT
	--End of Rev 136.0
	--Rev 138.0
	,@IsShowNewOrderCart BIT
	,@IsmanualInOutTimeRequired BIT
	,@surveytext NVARCHAR(200)
	--End of Rev 138.0
	--Rev 140.0
	,@IsDiscountInOrder BIT
	,@IsViewMRPInOrder BIT
	--End of Rev 140.0
	--Rev 142.0
	,@IsShowStateInTeam BIT
	,@IsShowBranchInTeam BIT
	,@IsShowDesignationInTeam BIT
	,@IsAllowZeroRateOrder BIT
	--End of Rev 142.0
	--Rev 146.0
	,@IsBeatAvailable BIT
	--End of Rev 146.0
	--Rev 147.0
	,@isExpenseFeatureAvailable BIT
	--End of Rev 147.0
	--Rev 148.0
	,@IsDiscountEditableInOrder BIT
	,@IsRouteStartFromAttendance BIT
	--End of Rev 148.0
	--Rev 149.0
	,@IsShowOtherInfoinShopMaster BIT
	,@IsShowQuotationFooterforEurobond BIT
	--End of Rev 149.0
	--Rev 150.0
	,@ShowApproxDistanceInNearbyShopList BIT
	--End of Rev 150.0
	--Rev 152.0
	,@IsAssignedDDAvailableForAllUser BIT
	--End of Rev 152.0
	--Rev 154.0
	,@IsShowEmployeePerformance BIT
	--End of Rev 154.0
	--Rev 155.0
	,@IsShowPrivacyPolicyInMenu BIT
	,@IsAttendanceCheckedforExpense BIT
	,@IsShowLocalinExpense BIT
	,@IsShowOutStationinExpense BIT
	,@IsTAAttachment1Mandatory BIT
	,@IsTAAttachment2Mandatory BIT
	,@IsSingleDayTAApplyRestriction BIT
	,@NameforConveyanceAttachment1 NVARCHAR(200)
	,@NameforConveyanceAttachment2 NVARCHAR(200)
	,@IsTaskManagementAvailable BIT
	--End of Rev 155.0
	--Rev 156.0
	,@IsAttachmentAvailableForCurrentStock BIT
	--End of Rev 156.0
	--Rev 157.0
	,@IsShowReimbursementTypeInAttendance BIT
	--End of Rev 157.0
	--Rev 158.0
	,@IsBeatPlanAvailable BIT
	--End of Rev 158.0
	--Rev 160.0
	,@IsUpdateVisitDataInTodayTable BIT
	--End of Rev 160.0
	--Rev 162.0
	,@ConsiderInactiveShopWhileLogin BIT
	--End of Rev 162.0
	--Rev 163.0
	,@ShopSyncIntervalInMinutes NVARCHAR(200)
	--End of Rev 163.0
	--Rev 165.0
	,@IsShowWhatsAppIconforVisit BIT
	,@IsAutomatedWhatsAppSendforRevisit BIT
	--End of Rev 165.0
	--Rev 166.0
	,@IsAllowBackdatedOrderEntry BIT
	,@Order_Past_Days INT
	--End of Rev 166.0
	--Rev 167.0
	,@Show_distributor_scheme_with_Product BIT
	--End of Rev 167.0
	--Rev 168.0
	,@GSTINPANMandatoryforSHOPTYPE4 BIT
	,@FSSAILicNoEnableInShop BIT
	,@FSSAILicNoMandatoryInShop4 BIT
	--End of Rev 168.0
	--Rev 171.0
	,@isLeadContactNumber BIT
	,@isModelEnable BIT
	,@isPrimaryApplicationEnable BIT
	,@isSecondaryApplicationEnable BIT
	,@isBookingAmount BIT
	,@isLeadTypeEnable BIT
	,@isStageEnable BIT
	,@isFunnelStageEnable BIT
	--End of Rev 171.0
	--Rev 172.0
	,@MultiVisitIntervalInMinutes INT
	--End of Rev 172.0
	--Rev 176.0
	,@IsGPSRouteSync BIT
	,@IsSyncBellNotificationInApp BIT
	--End of Rev 176.0
	--Rev 177.0
	,@IsShowCustomerLocationShare BIT
	--End of Rev 177.0
	
	if(@Action='GlobalCheck')
	BEGIN
		set @max_accuracy=(select value from FTS_APP_CONFIG_SETTINGS where [Key]='max_accuracy' AND IsActive=1)
		set @min_accuracy=(select value from FTS_APP_CONFIG_SETTINGS where [Key]='min_accuracy' AND IsActive=1)
		set @min_distance=(select value from FTS_APP_CONFIG_SETTINGS where [Key]='min_distance' AND IsActive=1)
		set @max_distance=(select value from FTS_APP_CONFIG_SETTINGS where [Key]='max_distance' AND IsActive=1)
		set @idle_time=(select value from FTS_APP_CONFIG_SETTINGS where [Key]='idle_time' AND IsActive=1)
		set @isRevisitCaptureImage=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='RevisitCaptureImage' AND IsActive=1)
		set @isShowAllProduct=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ShowAllProduct' AND IsActive=1)
		set @isPrimaryTargetMandatory=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='PrimaryTargetMandatory' AND IsActive=1)
		set @isStockAvailableForAll=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='StockAvailableForAll' AND IsActive=1)

		--START REV 1.0
		set @isStockAvailableForPopup=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isStockAvailableForPopup' AND IsActive=1)
		set @isOrderAvailableForPopup=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isOrderAvailableForPopup' AND IsActive=1)
		set @isCollectionAvailableForPopup=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isCollectionAvailableForPopup' AND IsActive=1)
		--END REV 1.0

		--START REV 2.0
		set @isDDFieldEnabled=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isDDFieldEnabled' AND IsActive=1)
		--END REV 2.0

		--START REV 3.0
		set @willStockShow=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='willStockShow' AND IsActive=1)
		--END REV 3.0

		--START REV 4.0
		set @maxFileSize=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='maxFileSize' AND IsActive=1)
		--END REV 4.0

		--START REV 5.0
		set @willKnowYourStateShow=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='willKnowYourStateShow' AND IsActive=1)
		--END REV 5.0

		--START REV 6.0
		set @willAttachmentCompulsory=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='willAttachmentCompulsory' AND IsActive=1)
		set @canAddBillingFromBillingList=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='canAddBillingFromBillingList' AND IsActive=1)
		--END REV 6.0

		--START REV 7.0
		SET @willShowUpdateDayPlan=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='willShowUpdateDayPlan' AND IsActive=1)
		SET @updateDayPlanText=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='updateDayPlanText' AND IsActive=1)
		SET @dailyPlanListHeaderText=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='dailyPlanListHeaderText' AND IsActive=1)
		--END REV 7.0
		--START REV 8.0
		SET @addShopHeaderText=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='addShopHeaderText' AND IsActive=1)
		--END REV 8.0
		--START REV 9.0
		SET @allPlanListHeaderText=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='allPlanListHeaderText' AND IsActive=1)
		--END REV 9.0

		--START REV 10.0
		SET @willSetYourTodaysTargetVisible=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='willSetYourTodaysTargetVisible' AND IsActive=1)
		--END REV 10.0
		--START REV 11.0
		SET @attendenceAlertHeading=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='attendenceAlertHeading' AND IsActive=1)
		SET @attendenceAlertText=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='attendenceAlertText' AND IsActive=1)
		--END REV 11.0

		--START REV 13.0
		SET @meetingText=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='meetingHeaderText' AND IsActive=1)
		--END REV 13.0
		--START REV 14.0
		SET @meetingDistance=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='meetingDistance' AND IsActive=1)
		--END REV 14.0
		--Rev 18.0 Start
		SET @isActivatePJPFeature=(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isActivatePJPFeature' AND IsActive=1)
		--Rev 18.0 End

		--Rev 20.0 Start
		SET @willReimbursementShow =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='willReimbursementShow' AND IsActive=1)
		--Rev 20.0 End

		--Rev 23.0 Start
		SET @updateBillingText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='updateBillingText' AND IsActive=1)
		--Rev 23.0 End
		--Rev 28.0 Start
		SET @isRateOnline =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isRateOnline' AND IsActive=1)
		--Rev 28.0 End

		--Rev 31.0 Start
		SET @ppText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ppText' AND IsActive=1)
		SET @ddText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ddText' AND IsActive=1)
		--Rev 31.0 End

		--Rev 32.0 Start
		SET @shopText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='shopText' AND IsActive=1)
		--Rev 32.0 End

		--Rev 33.0 Start
		SET @isCustomerFeatureEnable =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isCustomerFeatureEnable' AND IsActive=1)
		SET @isAreaVisible =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isAreaVisible' AND IsActive=1)
		--Rev 33.0 End

		--Rev 34.0 Start
		SET @CGSTPercentage =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='CGSTPercentage' AND IsActive=1)
		SET @SGSTPercentage =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='SGSTPercentage' AND IsActive=1)
		SET @TCSPercentage =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='TCSPercentage' AND IsActive=1)
		--Rev 34.0 End

		--Rev 47.0 Start
		SET @docAttachmentNo =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='docAttachmentNo' AND IsActive=1)
		--Rev 47.0 End

		--Rev 50.0 Start
		SET @chatBotMsg =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='chatBotMsg' AND IsActive=1)
		--Rev 50.0 End

		--Rev 51.0 Start
		SET @contactMail =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='contactMail' AND IsActive=1)
		--Rev 51.0 End

		--Rev 57.0
		set @isVoiceEnabledForAttendanceSubmit =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isVoiceEnabledForAttendanceSubmit' AND IsActive=1)
		set @isVoiceEnabledForOrderSaved =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isVoiceEnabledForOrderSaved' AND IsActive=1)
		set @isVoiceEnabledForInvoiceSaved =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isVoiceEnabledForInvoiceSaved' AND IsActive=1)
		set @isVoiceEnabledForCollectionSaved =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isVoiceEnabledForCollectionSaved' AND IsActive=1)
		set @isVoiceEnabledForHelpAndTipsInBot =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isVoiceEnabledForHelpAndTipsInBot' AND IsActive=1)
		--Rev 57.0 End

		--Rev 83.0
		SET @GPSAlert =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='GPSAlert' AND IsActive=1)
		--End of Rev 83.0
		--Rev 85.0
		SET @IsDuplicateShopContactnoAllowedOnline =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsDuplicateShopContactnoAllowedOnline' AND IsActive=1)
		--End of Rev 85.0
		--Rev 87.0
		SET @BatterySetting  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='BatterySetting' AND IsActive=1)
		SET @PowerSaverSetting  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='PowerSaverSetting' AND IsActive=1)
		--End of Rev 87.0
		--Rev 88.0
		SET @IsnewleadtypeforRuby  =(SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='IsnewleadtypeforRuby' AND IsActive=1)
		--End of Rev 88.0
		--Rev 89.0
		SET @Show_App_Logout_Notification  =(SELECT [Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='Show_App_Logout_Notification' AND IsActive=1)
		--End of Rev 89.0
		--Rev 92.0
		SET @IsReturnActivatedforPP =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsReturnActivatedforPP' AND IsActive=1)
		SET @IsReturnActivatedforDD =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsReturnActivatedforDD' AND IsActive=1)
		SET @IsReturnActivatedforSHOP =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsReturnActivatedforSHOP' AND IsActive=1)
		--End of Rev 92.0
		--Rev 93.0
		SET @MRPInOrder  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='MRPInOrder' AND IsActive=1)
		SET @FaceRegistrationFrontCamera  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='FaceRegistrationFrontCamera' AND IsActive=1)
		--End of Rev 93.0
		--Rev 94.0
		SET @IsShowMyDetails  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowMyDetails' AND IsActive=1)
		--End of Rev 94.0
		--Rev 96.0
		SET @IsAttendVisitShowInDashboard  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAttendVisitShowInDashboard' AND IsActive=1)
		SET @IsShowInPortalManualPhotoRegn  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowInPortalManualPhotoRegn' AND IsActive=1)
		--End of Rev 96.0
		--Rev 99.0
		SET @SqMtrRateCalculationforQuotEuro  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='SqMtrRateCalculationforQuotEuro' AND IsActive=1)
		--End of Rev 99.0
		--Rev 103.0
		SET @NewQuotationRateCaption =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='NewQuotationRateCaption' AND IsActive=1)
		SET @NewQuotationShowTermsAndCondition =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='NewQuotationShowTermsAndCondition' AND IsActive=1)
		--End of Rev 103.0
		--Rev 115.0
		SET @IsCollectionEntryConsiderOrderOrInvoice =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsCollectionEntryConsiderOrderOrInvoice' AND IsActive=1)
		--End of Rev 115.0
		--Rev 118.0
		SET @ContactNameText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ContactNameText' AND IsActive=1)
		SET @ContactNumberText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ContactNumberText' AND IsActive=1)
		SET @EmailText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='EmailText' AND IsActive=1)
		SET @DobText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='DobText' AND IsActive=1)
		SET @DateOfAnniversaryText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='DateOfAnniversaryText' AND IsActive=1)
		--End of Rev 118.0
		--Rev 120.0
		SET @ShopScreenAftVisitRevisit =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ShopScreenAftVisitRevisit' AND IsActive=1)
		--End of Rev 120.0
		--Rev 125.0
		SET @IsSurveyRequiredforNewParty =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsSurveyRequiredforNewParty' AND IsActive=1)
		SET @IsSurveyRequiredforDealer =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsSurveyRequiredforDealer' AND IsActive=1)
		--End of Rev 125.0
		--Rev 126.0
		SET @IsShowHomeLocationMap =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowHomeLocationMap' AND IsActive=1)
		--End of Rev 126.0
		--Rev 127.0
		SET @IsBeatRouteAvailableinAttendance =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsBeatRouteAvailableinAttendance' AND IsActive=1)
		SET @IsAllBeatAvailable =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAllBeatAvailable' AND IsActive=1)
		--End of Rev 127.0
		--Rev 130.0
		SET @BeatText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='BeatText' AND IsActive=1)
		SET @TodaysTaskText =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='TodaysTaskText' AND IsActive=1)
		--End of Rev 130.0
		--Rev 132.0
		SET @IsDistributorSelectionRequiredinAttendance =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsDistributorSelectionRequiredinAttendance' AND IsActive=1)
		--End of Rev 132.0
		--Rev 134.0
		SET @IsAllowNearbyshopWithBeat =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAllowNearbyshopWithBeat' AND IsActive=1)
		SET @IsGSTINPANEnableInShop =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsGSTINPANEnableInShop' AND IsActive=1)
		--End of Rev 134.0
		--Rev 135.0
		SET @IsMultipleImagesRequired =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsMultipleImagesRequired' AND IsActive=1)
		--End of Rev 135.0
		--Rev 136.0
		SET @IsALLDDRequiredforAttendance =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsALLDDRequiredforAttendance' AND IsActive=1)
		--End of Rev 136.0
		--Rev 138.0
		SET @IsShowNewOrderCart =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowNewOrderCart' AND IsActive=1)
		SET @IsmanualInOutTimeRequired =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsmanualInOutTimeRequired' AND IsActive=1)
		SET @surveytext =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='surveytext' AND IsActive=1)
		--End of Rev 138.0
		--Rev 140.0
		SET @IsDiscountInOrder =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsDiscountInOrder' AND IsActive=1)
		SET @IsViewMRPInOrder =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsViewMRPInOrder' AND IsActive=1)
		--End of Rev 140.0
		--Rev 142.0
		SET @IsShowStateInTeam =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowStateInTeam' AND IsActive=1)
		SET @IsShowBranchInTeam =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowBranchInTeam' AND IsActive=1)
		SET @IsShowDesignationInTeam =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowDesignationInTeam' AND IsActive=1)
		SET @IsAllowZeroRateOrder =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAllowZeroRateOrder' AND IsActive=1)
		--End of Rev 142.0
		--Rev 146.0
		SET @IsBeatAvailable =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsBeatAvailable' AND IsActive=1)
		--End of Rev 146.0
		--Rev 147.0
		SET @isExpenseFeatureAvailable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isExpenseFeatureAvailable' AND IsActive=1)
		--End of Rev 147.0
		--Rev 148.0
		SET @IsDiscountEditableInOrder  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsDiscountEditableInOrder' AND IsActive=1)
		SET @IsRouteStartFromAttendance  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsRouteStartFromAttendance' AND IsActive=1)
		--End of Rev 148.0
		--Rev 149.0
		SET @IsShowOtherInfoinShopMaster  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowOtherInfoinShopMaster' AND IsActive=1)
		SET @IsShowQuotationFooterforEurobond  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowQuotationFooterforEurobond' AND IsActive=1)
		--End of Rev 149.0
		--Rev 150.0
		SET @ShowApproxDistanceInNearbyShopList  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ShowApproxDistanceInNearbyShopList' AND IsActive=1)
		--End of Rev 150.0
		--Rev 152.0
		SET @IsAssignedDDAvailableForAllUser  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAssignedDDAvailableForAllUser' AND IsActive=1)
		--End of Rev 152.0
		--Rev 154.0
		SET @IsShowEmployeePerformance  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowEmployeePerformance' AND IsActive=1)
		--End of Rev 154.0
		--Rev 155.0
		SET @IsShowPrivacyPolicyInMenu  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowPrivacyPolicyInMenu' AND IsActive=1)
		SET @IsAttendanceCheckedforExpense  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAttendanceCheckedforExpense' AND IsActive=1)
		SET @IsShowLocalinExpense  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowLocalinExpense' AND IsActive=1)
		SET @IsShowOutStationinExpense  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowOutStationinExpense' AND IsActive=1)
		SET @IsTAAttachment1Mandatory  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsTAAttachment1Mandatory' AND IsActive=1)
		SET @IsTAAttachment2Mandatory  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsTAAttachment2Mandatory' AND IsActive=1)
		SET @IsSingleDayTAApplyRestriction  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsSingleDayTAApplyRestriction' AND IsActive=1)
		SET @NameforConveyanceAttachment1  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='NameforConveyanceAttachment1' AND IsActive=1)
		SET @NameforConveyanceAttachment2  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='NameforConveyanceAttachment2' AND IsActive=1)
		SET @IsTaskManagementAvailable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsTaskManagementAvailable' AND IsActive=1)
		--End of Rev 155.0
		--Rev 156.0
		SET @IsAttachmentAvailableForCurrentStock  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAttachmentAvailableForCurrentStock' AND IsActive=1)
		--End of Rev 156.0
		--Rev 157.0
		SET @IsShowReimbursementTypeInAttendance  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowReimbursementTypeInAttendance' AND IsActive=1)
		--End of Rev 157.0
		--Rev 158.0
		SET @IsBeatPlanAvailable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsBeatPlanAvailable' AND IsActive=1)
		--End of Rev 158.0
		--Rev 160.0
		SET @IsUpdateVisitDataInTodayTable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsUpdateVisitDataInTodayTable' AND IsActive=1)
		--End of Rev 160.0
		--Rev 162.0
		SET @ConsiderInactiveShopWhileLogin  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ConsiderInactiveShopWhileLogin' AND IsActive=1)
		--End of Rev 162.0
		--Rev 163.0
		SET @ShopSyncIntervalInMinutes  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='ShopSyncIntervalInMinutes' AND IsActive=1)
		--End of Rev 163.0
		--Rev 165.0
		SET @IsShowWhatsAppIconforVisit  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowWhatsAppIconforVisit' AND IsActive=1)
		SET @IsAutomatedWhatsAppSendforRevisit  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAutomatedWhatsAppSendforRevisit' AND IsActive=1)
		--End of Rev 165.0
		--Rev 166.0
		SET @IsAllowBackdatedOrderEntry  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsAllowBackdatedOrderEntry' AND IsActive=1)
		SET @Order_Past_Days  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='Order_Past_Days' AND IsActive=1)
		--End of Rev 166.0
		--Rev 167.0
		SET @Show_distributor_scheme_with_Product  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='Show_distributor_scheme_with_Product' AND IsActive=1)
		--End of Rev 167.0
		--Rev 168.0
		SET @GSTINPANMandatoryforSHOPTYPE4  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='GSTINPANMandatoryforSHOPTYPE4' AND IsActive=1)
		SET @FSSAILicNoEnableInShop  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='FSSAILicNoEnableInShop' AND IsActive=1)
		SET @FSSAILicNoMandatoryInShop4  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='FSSAILicNoMandatoryInShop4' AND IsActive=1)
		--End of Rev 168.0
		--Rev 171.0
		SET @isLeadContactNumber  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isLeadContactNumber' AND IsActive=1)
		SET @isModelEnable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isModelEnable' AND IsActive=1)
		SET @isPrimaryApplicationEnable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isPrimaryApplicationEnable' AND IsActive=1)
		SET @isSecondaryApplicationEnable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isSecondaryApplicationEnable' AND IsActive=1)
		SET @isBookingAmount  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isBookingAmount' AND IsActive=1)
		SET @isLeadTypeEnable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isLeadTypeEnable' AND IsActive=1)
		SET @isStageEnable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isStageEnable' AND IsActive=1)
		SET @isFunnelStageEnable  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='isFunnelStageEnable' AND IsActive=1)
		--End of Rev 171.0
		--Rev 172.0
		SET @MultiVisitIntervalInMinutes  =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='MultiVisitIntervalInMinutes' AND IsActive=1)
		--End of Rev 172.0
		--Rev 176.0
		SET @IsGPSRouteSync =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsGPSRouteSync' AND IsActive=1)
		SET @IsSyncBellNotificationInApp =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsSyncBellNotificationInApp' AND IsActive=1)
		--End of Rev 176.0
		--Rev 177.0
		SET @IsShowCustomerLocationShare =(select [Value] from FTS_APP_CONFIG_SETTINGS where [Key]='IsShowCustomerLocationShare' AND IsActive=1)
		--End of Rev 177.0

		select  @max_accuracy as max_accuracy,
			    @min_accuracy as min_accuracy,
				@min_distance as min_distance,
				@max_distance as max_distance,
				@isRevisitCaptureImage as isRevisitCaptureImage,
				@isShowAllProduct as isShowAllProduct,
				@isPrimaryTargetMandatory as isPrimaryTargetMandatory,
				@isStockAvailableForAll as isStockAvailableForAll,
				--START REV 1.0
				@isStockAvailableForPopup as isStockAvailableForPopup,
				@isOrderAvailableForPopup as isOrderAvailableForPopup,
				@isCollectionAvailableForPopup as isCollectionAvailableForPopup,
			--END REV 1.0
			--START REV 2.0
			@isDDFieldEnabled AS isDDFieldEnabled,
			--END REV 2.0
			--START REV 3.0
			@willStockShow AS willStockShow,
			--END REV 3.0

			--START REV 4.0
			@maxFileSize as maxFileSize,
			--END REV 4.0
			--START REV 5.0
			@willKnowYourStateShow AS willKnowYourStateShow,
			--END REV 5.0
			--START REV 6.0
			@willAttachmentCompulsory AS willAttachmentCompulsory,
			@canAddBillingFromBillingList AS canAddBillingFromBillingList,
			--END REV 6.0

			--START REV 7.0
			@willShowUpdateDayPlan AS willShowUpdateDayPlan,
			@updateDayPlanText AS updateDayPlanText,
			@dailyPlanListHeaderText AS dailyPlanListHeaderText,
			--END REV 7.0
			--START REV 8.0
			@addShopHeaderText AS addShopHeaderText,
			--END REV 8.0
			--START REV 9.0
			@allPlanListHeaderText AS allPlanListHeaderText,
			--END REV 9.0
			--START REV 10.0
			@willSetYourTodaysTargetVisible AS willSetYourTodaysTargetVisible,
			--END REV 10.0
			--START REV 11.0
			@attendenceAlertHeading AS attendenceAlertHeading,
			@attendenceAlertText AS attendenceAlertText,
			--END REV 11.0
			--START REV 13.0
			@meetingText AS meetingText
			--END REV 13.0 
			--START REV 14.0
			,@meetingDistance AS meetingDistance
			--END REV 14.0 
			--Rev 18.0 Start
			,@isActivatePJPFeature AS isActivatePJPFeature
			--Rev 18.0 End
			--Rev 20.0 Start
			,@willReimbursementShow AS willReimbursementShow
			--Rev 20.0 End
			--Rev 23.0 Start
			,@updateBillingText AS updateBillingText
			--Rev 23.0 End
			--Rev 28.0 Start
			,@isRateOnline AS isRateOnline
			--Rev 28.0 End
			--Rev 31.0 Start
			,@ppText AS ppText
			,@ddText AS ddText
			--Rev 31.0 End
			--Rev 32.0 Start
			,@shopText AS shopText
			--Rev 32.0 End
			--Rev 33.0 Start
			,@isCustomerFeatureEnable AS isCustomerFeatureEnable
			,@isAreaVisible AS isAreaVisible
			--Rev 33.0 End
			--Rev 34.0 Start
			,@CGSTPercentage AS CGSTPercentage
			,@SGSTPercentage AS SGSTPercentage
			,@TCSPercentage AS TCSPercentage
			--Rev 34.0 End
			--Rev 47.0 Start
			,@docAttachmentNo AS docAttachmentNo
			--Rev 47.0 End
			--Rev 50.0 Start
			,@chatBotMsg AS chatBotMsg
			--Rev 50.0 End
			--Rev 51.0 Start
			,@contactMail AS contactMail
			--Rev 51.0 End
			--Rev 57.0
			,@isVoiceEnabledForAttendanceSubmit  as isVoiceEnabledForAttendanceSubmit
			,@isVoiceEnabledForOrderSaved as isVoiceEnabledForOrderSaved
			,@isVoiceEnabledForInvoiceSaved as isVoiceEnabledForInvoiceSaved
			,@isVoiceEnabledForCollectionSaved as isVoiceEnabledForCollectionSaved
			,@isVoiceEnabledForHelpAndTipsInBot as isVoiceEnabledForHelpAndTipsInBot
			--Rev 57.0 End
			--Rev 83.0
			,@GPSAlert AS GPSAlert
			--End of Rev 83.0
			--Rev 85.0
			,@IsDuplicateShopContactnoAllowedOnline AS IsDuplicateShopContactnoAllowedOnline
			--End of Rev 85.0
			--Rev 87.0
			,@BatterySetting AS BatterySetting
			,@PowerSaverSetting AS PowerSaverSetting
			--End of Rev 87.0
			--Rev 88.0
			,@IsnewleadtypeforRuby AS IsnewleadtypeforRuby
			--End of Rev 88.0
			--Rev 89.0
			,@Show_App_Logout_Notification AS Show_App_Logout_Notification
			--End of Rev 89.0
			--Rev 92.0
			,@IsReturnActivatedforPP AS IsReturnActivatedforPP
			,@IsReturnActivatedforDD AS IsReturnActivatedforDD
			,@IsReturnActivatedforSHOP AS IsReturnActivatedforSHOP
			--End of Rev 92.0
			--Rev 93.0
			,@MRPInOrder AS MRPInOrder
			,@FaceRegistrationFrontCamera AS FaceRegistrationFrontCamera
			--End of Rev 93.0
			--Rev 94.0
			,@IsShowMyDetails AS IsShowMyDetails
			--End of Rev 94.0
			--Rev 96.0
			,@IsAttendVisitShowInDashboard AS IsAttendVisitShowInDashboard
			,@IsShowInPortalManualPhotoRegn AS IsShowInPortalManualPhotoRegn
			--End of Rev 96.0
			--Rev 99.0
			,@SqMtrRateCalculationforQuotEuro AS SqMtrRateCalculationforQuotEuro
			--End of Rev 99.0
			--Rev 103.0
			,@NewQuotationRateCaption AS NewQuotationRateCaption
			,@NewQuotationShowTermsAndCondition AS NewQuotationShowTermsAndCondition
			--End of Rev 103.0
			--Rev 115.0
			,@IsCollectionEntryConsiderOrderOrInvoice AS IsCollectionEntryConsiderOrderOrInvoice
			--End of Rev 115.0
			--Rev 118.0
			,@ContactNameText AS contactNameText
			,@ContactNumberText AS contactNumberText
			,@EmailText AS emailText
			,@DobText AS dobText
			,@DateOfAnniversaryText AS dateOfAnniversaryText
			--End of Rev 118.0
			--Rev 120.0
			,@ShopScreenAftVisitRevisit AS ShopScreenAftVisitRevisit
			--End of Rev 120.0
			--Rev 125.0
			,@IsSurveyRequiredforNewParty AS IsSurveyRequiredforNewParty
			,@IsSurveyRequiredforDealer AS IsSurveyRequiredforDealer
			--End of Rev 125.0
			--Rev 126.0
			,@IsShowHomeLocationMap AS IsShowHomeLocationMap
			--End of Rev 126.0
			--Rev 127.0
			,@IsBeatRouteAvailableinAttendance AS IsBeatRouteAvailableinAttendance
			,@IsAllBeatAvailable AS IsAllBeatAvailable
			--End of Rev 127.0
			--Rev 130.0
			,@BeatText AS BeatText
			,@TodaysTaskText AS TodaysTaskText
			--End of Rev 130.0
			--Rev 132.0
			,@IsDistributorSelectionRequiredinAttendance AS IsDistributorSelectionRequiredinAttendance
			--End of Rev 132.0
			--Rev 134.0
			,@IsAllowNearbyshopWithBeat AS IsAllowNearbyshopWithBeat
			,@IsGSTINPANEnableInShop AS IsGSTINPANEnableInShop
			--End of Rev 134.0
			--Rev 135.0
			,@IsMultipleImagesRequired AS IsMultipleImagesRequired
			--End of Rev 135.0
			--Rev 136.0
			,@IsALLDDRequiredforAttendance AS IsALLDDRequiredforAttendance
			--End of Rev 136.0
			--Rev 138.0
			,@IsShowNewOrderCart AS IsShowNewOrderCart
			,@IsmanualInOutTimeRequired AS IsmanualInOutTimeRequired
			,@surveytext AS surveytext
			--End of Rev 138.0
			--Rev 140.0
			,@IsDiscountInOrder AS IsDiscountInOrder
			,@IsViewMRPInOrder AS IsViewMRPInOrder
			--End of Rev 140.0
			--Rev 142.0
			,@IsShowStateInTeam AS IsShowStateInTeam
			,@IsShowBranchInTeam AS IsShowBranchInTeam
			,@IsShowDesignationInTeam AS IsShowDesignationInTeam
			,@IsAllowZeroRateOrder AS IsAllowZeroRateOrder
			--End of Rev 142.0
			--Rev 146.0
			,@IsBeatAvailable AS IsBeatAvailable
			--End of Rev 146.0
			--Rev 147.0
			,@isExpenseFeatureAvailable AS isExpenseFeatureAvailable
			--End of Rev 147.0
			--Rev 148.0
			,@IsDiscountEditableInOrder  AS IsDiscountEditableInOrder
			,@IsRouteStartFromAttendance  AS IsRouteStartFromAttendance
			--End of Rev 148.0
			--Rev 149.0
			,@IsShowOtherInfoinShopMaster  AS IsShowOtherInfoinShopMaster
			,@IsShowQuotationFooterforEurobond  AS IsShowQuotationFooterforEurobond
			--End of Rev 149.0
			--Rev 150.0
			,@ShowApproxDistanceInNearbyShopList  AS ShowApproxDistanceInNearbyShopList
			--End of Rev 150.0
			--Rev 152.0
			,@IsAssignedDDAvailableForAllUser  AS IsAssignedDDAvailableForAllUser
			--End of Rev 152.0
			--Rev 154.0
			,@IsShowEmployeePerformance  AS IsShowEmployeePerformance
			--End of Rev 154.0
			--Rev 155.0
			,@IsShowPrivacyPolicyInMenu  AS IsShowPrivacyPolicyInMenu
			,@IsAttendanceCheckedforExpense  AS IsAttendanceCheckedforExpense
			,@IsShowLocalinExpense  AS IsShowLocalinExpense
			,@IsShowOutStationinExpense  AS IsShowOutStationinExpense
			,@IsTAAttachment1Mandatory  AS IsTAAttachment1Mandatory
			,@IsTAAttachment2Mandatory AS IsTAAttachment2Mandatory
			,@IsSingleDayTAApplyRestriction AS IsSingleDayTAApplyRestriction
			,@NameforConveyanceAttachment1 AS NameforConveyanceAttachment1
			,@NameforConveyanceAttachment2 AS NameforConveyanceAttachment2
			,@IsTaskManagementAvailable AS IsTaskManagementAvailable
			--End of Rev 155.0
			--Rev 156.0
			,@IsAttachmentAvailableForCurrentStock AS IsAttachmentAvailableForCurrentStock
			--End of Rev 156.0
			--Rev 157.0
			,@IsShowReimbursementTypeInAttendance AS IsShowReimbursementTypeInAttendance
			--End of Rev 157.0
			--Rev 158.0
			,@IsBeatPlanAvailable AS IsBeatPlanAvailable
			--End of Rev 158.0
			--Rev 160.0
			,@IsUpdateVisitDataInTodayTable AS IsUpdateVisitDataInTodayTable
			--End of Rev 160.0
			--Rev 162.0
			,@ConsiderInactiveShopWhileLogin AS ConsiderInactiveShopWhileLogin
			--End of Rev 162.0
			--Rev 163.0
			,@ShopSyncIntervalInMinutes AS ShopSyncIntervalInMinutes
			--End of Rev 163.0
			--Rev 165.0
			,@IsShowWhatsAppIconforVisit AS IsShowWhatsAppIconforVisit
			,@IsAutomatedWhatsAppSendforRevisit AS IsAutomatedWhatsAppSendforRevisit
			--End of Rev 165.0
			--Rev 166.0
			,@IsAllowBackdatedOrderEntry AS IsAllowBackdatedOrderEntry
			,@Order_Past_Days AS Order_Past_Days
			--End of Rev 166.0
			--Rev 167.0
			,@Show_distributor_scheme_with_Product AS Show_distributor_scheme_with_Product
			--End of Rev 167.0
			--Rev 168.0
			,@GSTINPANMandatoryforSHOPTYPE4 AS GSTINPANMandatoryforSHOPTYPE4
			,@FSSAILicNoEnableInShop AS FSSAILicNoEnableInShop
			,@FSSAILicNoMandatoryInShop4 AS FSSAILicNoMandatoryInShop4
			--End of Rev 168.0
			--Rev 171.0
			,@isLeadContactNumber AS isLeadContactNumber
			,@isModelEnable AS isModelEnable
			,@isPrimaryApplicationEnable AS isPrimaryApplicationEnable
			,@isSecondaryApplicationEnable AS isSecondaryApplicationEnable
			,@isBookingAmount AS isBookingAmount
			,@isLeadTypeEnable AS isLeadTypeEnable
			,@isStageEnable AS isStageEnable
			,@isFunnelStageEnable AS isFunnelStageEnable
			--End of Rev 171.0
			--Rev 172.0
			,@MultiVisitIntervalInMinutes AS MultiVisitIntervalInMinutes
			--End of Rev 172.0
			--Rev 176.0
			,@IsGPSRouteSync AS IsGPSRouteSync
			,@IsSyncBellNotificationInApp AS IsSyncBellNotificationInApp
			--End of Rev 176.0
			--Rev 177.0
			,@IsShowCustomerLocationShare AS IsShowCustomerLocationShare
			--End of Rev 177.0
	END

	else if(@Action='UserCheck')
	BEGIN
		select [key] as  [Key], [value] as [Value]  from FTS_APP_USER_CONFIG_SETTINGS WHERE USER_Id=@UserID
		UNION ALL
		SELECT [Key],[Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='updateDayPlanText'
		UNION ALL
		SELECT [Key],[Value] FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='dailyPlanListHeaderText'
		--UNION ALL
		--SELECT 'willShowUpdateDayPlan' as [Key],CASE WHEN IsShowPlanDetails=0 THEN '0' ELSE '1' END AS [Value] 
		--FROM tbl_master_contact CNT
		--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE USR.USER_ID=@UserID
		----START REV 8.0
		--UNION ALL
		--SELECT 'willMoreVisitUpdateOptional' as [Key],CASE WHEN IsShowMoreDetailsMandatory=0 THEN '0' ELSE '1' END AS [Value] 
		--FROM tbl_master_contact CNT
		--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE USR.USER_ID=@UserID
		--UNION ALL
		--SELECT 'willMoreVisitUpdateCompulsory' as [Key],CASE WHEN IsMoreDetailsMandatory=0 THEN '0' ELSE '1' END AS [Value] 
		--FROM tbl_master_contact CNT
		--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE USR.USER_ID=@UserID
		----END REV 8.0
		----12.0 Rev Start
		--UNION ALL
		--SELECT 'isMeetingAvailable' as [Key],CASE WHEN isMeetingAvailable=0 THEN '0' ELSE '1' END AS [Value] 
		--FROM tbl_master_contact CNT
		--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE USR.USER_ID=@UserID
		--UNION ALL
		--SELECT 'isRateNotEditable' as [Key],CASE WHEN isRateNotEditable=0 THEN '0' ELSE '1' END AS [Value] 
		--FROM tbl_master_contact CNT
		--INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE USR.USER_ID=@UserID
		----12.0 Rev End

		--REV 17.0 START
		UNION ALL
		SELECT 'willShowUpdateDayPlan' as [Key],CASE WHEN IsShowPlanDetails=0 THEN '0' ELSE '1' END AS [Value] 
		FROM tbl_master_user WHERE USER_ID=@UserID
	
		UNION ALL
		SELECT 'willMoreVisitUpdateOptional' as [Key],CASE WHEN IsShowMoreDetailsMandatory=0 THEN '0' ELSE '1' END AS [Value] 
		FROM tbl_master_user WHERE USER_ID=@UserID
		UNION ALL
		SELECT 'willMoreVisitUpdateCompulsory' as [Key],CASE WHEN IsMoreDetailsMandatory=0 THEN '0' ELSE '1' END AS [Value] 
		FROM tbl_master_user WHERE USER_ID=@UserID
		
		UNION ALL
		SELECT 'isMeetingAvailable' as [Key],CASE WHEN isMeetingAvailable=0 THEN '0' ELSE '1' END AS [Value] 
		FROM tbl_master_user WHERE USER_ID=@UserID
		UNION ALL
		SELECT 'isRateNotEditable' as [Key],CASE WHEN isRateNotEditable=0 THEN '0' ELSE '1' END AS [Value] 
		FROM tbl_master_user WHERE USER_ID=@UserID
		--17.0 Rev END

		--15.0 Rev Start
		UNION ALL
		SELECT 'autoRevisitDistance' as [Key],CONVERT(NVARCHAR(15),convert(decimal(8,0),ISNULL(USR.autoRevisitDistanceInMeter,'0'))) AS [Value]
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'autoRevisitTime' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.autoRevisitTimeInMinutes,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--15.0 Rev End
		--REV INDRO
		UNION ALL
		SELECT 'willLeaveApprovalEnable' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.willLeaveApprovalEnable,'0')) AS [Value]
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--END REV INDRO
		--16.0 Rev Start
		UNION ALL
		SELECT 'willAutoRevisitEnable' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.IsAutoRevisitEnable,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--16.0 Rev End

		--19.0 Rev Start
		UNION ALL
		SELECT 'willShowTeamDetails' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.IsShowTeamDetails,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		
		UNION ALL
		SELECT 'isAllowPJPUpdateForTeam' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.IsAllowPJPUpdateForTeam,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--19.0 Rev End

		--21.0 Rev Start
		UNION ALL
		SELECT 'willReportShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.willReportShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--21.0 Rev End

		--21.0 Rev Start
		UNION ALL
		SELECT 'willAttendanceReportShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isAttendanceReportShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		
		UNION ALL
		SELECT 'willPerformanceReportShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isPerformanceReportShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		
		UNION ALL
		SELECT 'willVisitReportShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isVisitReportShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--21.0 Rev End

		--24.0 Rev Start
		UNION ALL
		SELECT 'attendance_text' as [Key],''+CONVERT(varchar(15),CAST(BeginTime AS TIME),100) AS [Value] 
		FROM tbl_master_user USR 
		INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMPCTC.emp_cntId=USR.user_contactId
		INNER JOIN tbl_EmpWorkingHours EMPWH ON EMPWH.Id=EMPCTC.emp_workinghours 
		INNER JOIN(
		SELECT DISTINCT hourId,BeginTime,Grace FROM tbl_EmpWorkingHoursDetails) EMPWHD ON EMPWHD.hourId=EMPWH.Id 
		WHERE USR.USER_ID=@UserID
		--24.0 Rev End
		-- 25.0 REV
		UNION ALL
		SELECT 'willTimesheetShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.willTimesheetShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isAttendanceFeatureOnly' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isAttendanceFeatureOnly,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		
		--25.0 Rev End
		-- 26.0 REV
		UNION ALL
		SELECT 'isOrderShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isOrderShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isVisitShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isVisitShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'iscollectioninMenuShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.iscollectioninMenuShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--26.0 Rev End
		-- 27.0 REV
		UNION ALL
		SELECT 'isShopAddEditAvailable' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isShopAddEditAvailable,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isEntityCodeVisible' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isEntityCodeVisible,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--27.0 Rev End

		-- 29.0 REV
		UNION ALL
		SELECT 'isAreaMandatoryInPartyCreation' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isAreaMandatoryInPartyCreation,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isShowPartyInAreaWiseTeam' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isShowPartyInAreaWiseTeam,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--29.0 Rev End

		-- 30.0 REV
		UNION ALL
		SELECT 'isChangePasswordAllowed' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isChangePasswordAllowed,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isHomeRestrictAttendance' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isHomeRestrictAttendance,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--30.0 Rev End

		-- 32.0 REV
		UNION ALL
		SELECT 'isQuotationShow' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isQuotationShow,'0')) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--32.0 Rev End

		--35.0 REV
		UNION ALL
		SELECT 'homeLocDistance' as [Key],CONVERT(NVARCHAR(15),USR.homeLocDistance) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'shopLocAccuracy' as [Key],CONVERT(NVARCHAR(15),USR.shopLocAccuracy) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isQuotationPopupShow' as [Key],CONVERT(NVARCHAR(15),USR.isQuotationPopupShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--35.0 Rev End

		--36.0 REV
		UNION ALL
		SELECT 'isOrderReplacedWithTeam' as [Key],CONVERT(NVARCHAR(15),USR.isOrderReplacedWithTeam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--36.0 Rev End

		--37.0 REV
		UNION ALL
		SELECT 'isMultipleAttendanceSelection' as [Key],CONVERT(NVARCHAR(15),USR.isMultipleAttendanceSelection) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--37.0 Rev End

		--38.0 REV
		UNION ALL
		SELECT 'isDDShowForMeeting' as [Key],CONVERT(NVARCHAR(15),USR.isDDShowForMeeting) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
			UNION ALL
		SELECT 'isDDMandatoryForMeeting' as [Key],CONVERT(NVARCHAR(15),USR.isDDMandatoryForMeeting) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--38.0 Rev End
		UNION ALL
		SELECT 'isOfflineTeam' as [Key],CONVERT(NVARCHAR(15),USR.isOfflineTeam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--38.0 Rev End
		UNION ALL
		SELECT 'isAllTeamAvailable' as [Key],CONVERT(NVARCHAR(15),USR.isAllTeamAvailable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID

		--39.0 Rev End
		UNION ALL
		SELECT 'isNextVisitDateMandatory' as [Key],CONVERT(NVARCHAR(15),USR.isNextVisitDateMandatory) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID

		UNION ALL
		SELECT 'isRecordAudioEnable' as [Key],CONVERT(NVARCHAR(15),USR.isRecordAudioEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isAchievementEnable' as [Key],CONVERT(NVARCHAR(15),USR.isAchievementEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isTarVsAchvEnable' as [Key],CONVERT(NVARCHAR(15),USR.isTarVsAchvEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--39.0 Rev End

		--40.0 Rev 
		UNION ALL
		SELECT 'isShowCurrentLocNotifiaction' as [Key],CONVERT(NVARCHAR(15),USR.isShowCurrentLocNotifiaction) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--40.0 Rev End
		--41.0 Rev 
		UNION ALL
		SELECT 'isUpdateWorkTypeEnable' as [Key],CONVERT(NVARCHAR(15),USR.isUpdateWorkTypeEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--41.0 Rev End
		--42.0 Rev 
		UNION ALL
		SELECT 'isLeaveEnable' as [Key],CONVERT(NVARCHAR(15),USR.isLeaveEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isOrderMailVisible' as [Key],CONVERT(NVARCHAR(15),USR.isOrderMailVisible) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--42.0 Rev End

		--43.0 Rev 
		UNION ALL
		SELECT 'isShopEditEnable' as [Key],CONVERT(NVARCHAR(15),USR.isShopEditEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--43.0 Rev End

		--44.0 Rev 
		UNION ALL
		SELECT 'isTaskEnable' as [Key],CONVERT(NVARCHAR(15),USR.isTaskEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--44.0 Rev End

		--45.0 Rev 
		UNION ALL
		SELECT 'isAppInfoEnable' as [Key],CONVERT(NVARCHAR(15),USR.isAppInfoEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID

		UNION ALL
		SELECT 'appInfoMins' as [Key],CONVERT(NVARCHAR(15),USR.appInfoMins) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--45.0 Rev End
		--46.0 Rev 
		UNION ALL
		SELECT 'willActivityShow' as [Key],CONVERT(NVARCHAR(15),USR.willActivityShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--46.0 Rev End

		--48.0 Rev 
		UNION ALL
		SELECT 'isDocumentRepoShow' as [Key],CONVERT(NVARCHAR(15),USR.isDocumentRepoShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--48.0 Rev End

		--48.0 Rev 
		UNION ALL
		SELECT 'isChatBotShow' as [Key],CONVERT(NVARCHAR(15),USR.isChatBotShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isAttendanceBotShow' as [Key],CONVERT(NVARCHAR(15),USR.isAttendanceBotShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isVisitBotShow' as [Key],CONVERT(NVARCHAR(15),USR.isVisitBotShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--48.0 Rev End

		--52.0 Rev 
		UNION ALL
		SELECT 'isInstrumentCompulsory' as [Key],CONVERT(NVARCHAR(15),USR.isInstrumentCompulsory) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isBankCompulsory' as [Key],CONVERT(NVARCHAR(15),USR.isBankCompulsory) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--52.0 Rev End

		--53.0 Rev 
		UNION ALL
		SELECT 'isVisitPlanShow' as [Key],CONVERT(NVARCHAR(15),USR.isVisitPlanShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isVisitPlanMandatory' as [Key],CONVERT(NVARCHAR(15),USR.isVisitPlanMandatory) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--53.0 Rev End
		--54.0 Rev 
		UNION ALL
		SELECT 'isAttendanceDistanceShow' as [Key],CONVERT(NVARCHAR(15),USR.isAttendanceDistanceShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--54.0 Rev End
		--55.0 Rev 
		UNION ALL
		SELECT 'willTimelineWithFixedLocationShow' as [Key],CONVERT(NVARCHAR(15),USR.willTimelineWithFixedLocationShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--55.0 Rev End
		--56.0 Rev 
		UNION ALL
		SELECT 'isShowOrderRemarks' as [Key],CONVERT(NVARCHAR(15),USR.isShowOrderRemarks) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isShowOrderSignature' as [Key],CONVERT(NVARCHAR(15),USR.isShowOrderSignature) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--56.0 Rev End
		--58.0 Rev 
		UNION ALL
		SELECT 'isShowSmsForParty' as [Key],CONVERT(NVARCHAR(15),USR.isShowSmsForParty) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--58.0 Rev End
		--58.0 Rev 
		UNION ALL
		SELECT 'isShowTimeline' as [Key],CONVERT(NVARCHAR(15),USR.isShowTimeline) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'willScanVisitingCard' as [Key],CONVERT(NVARCHAR(15),USR.willScanVisitingCard) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isCreateQrCode' as [Key],CONVERT(NVARCHAR(15),USR.isCreateQrCode) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isScanQrForRevisit' as [Key],CONVERT(NVARCHAR(15),USR.isScanQrForRevisit) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--58.0 Rev End
		UNION ALL
		SELECT 'isShowLogoutReason' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.isShowLogoutReason,0)) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'willShowHomeLocReason' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.willShowHomeLocReason,0)) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'willShowShopVisitReason' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.willShowShopVisitReason,0)) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'minVisitDurationSpentTime' as [Key],CONVERT(NVARCHAR(15),ISNULL(USR.minVisitDurationSpentTime,0)) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--- rev 59
		UNION ALL
		SELECT 'willShowPartyStatus' as [Key],CONVERT(NVARCHAR(15),USR.willShowPartyStatus) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'willShowEntityTypeforShop' as [Key],CONVERT(NVARCHAR(15),USR.willShowEntityTypeforShop) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- eND rEV 59

		--- rev 60
		UNION ALL
		SELECT 'isShowRetailerEntity' as [Key],CONVERT(NVARCHAR(15),USR.isShowRetailerEntity) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isShowDealerForDD' as [Key],CONVERT(NVARCHAR(15),USR.isShowDealerForDD) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isShowBeatGroup' as [Key],CONVERT(NVARCHAR(15),USR.isShowBeatGroup) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- eND rEV 60
		--- rev 61
		UNION ALL
		SELECT 'isShowShopBeatWise' as [Key],CONVERT(NVARCHAR(15),USR.isShowShopBeatWise) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isShowBankDetailsForShop' as [Key],CONVERT(NVARCHAR(15),USR.isShowBankDetailsForShop) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- eND rEV 61
		--- rev 62
		UNION ALL
		SELECT 'isShowOTPVerificationPopup' as [Key],CONVERT(NVARCHAR(15),USR.isShowOTPVerificationPopup) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- eND rEV 62

		--- rev 63
		UNION ALL
		SELECT 'locationTrackInterval' as [Key],CONVERT(NVARCHAR(15),USR.locationTrackInterval) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- eND rEV 63
		--- rev 64
		UNION ALL
		SELECT 'isShowMicroLearning' as [Key],CONVERT(NVARCHAR(15),USR.isShowMicroLearing) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- eND rEV 64

		--- rev 65
		UNION ALL
		SELECT 'homeLocReasonCheckMins' as [Key],CONVERT(NVARCHAR(15),USR.homeLocReasonCheckMins) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- eND rEV 65

		--- rev 66
		UNION ALL
		SELECT 'currentLocationNotificationMins' as [Key],CONVERT(NVARCHAR(15),USR.currentLocationNotificationMins) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isMultipleVisitEnable' as [Key],CONVERT(NVARCHAR(15),USR.isMultipleVisitEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isShowVisitRemarks' as [Key],CONVERT(NVARCHAR(15),USR.isShowVisitRemarks) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- END REV 66
		--- REV 67
		UNION ALL
		SELECT 'isShowNearbyCustomer' as [Key],CONVERT(NVARCHAR(15),USR.isShowNearbyCustomer) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- END REV 67
		--- REV 68
		UNION ALL
		SELECT 'isServiceFeatureEnable' as [Key],CONVERT(NVARCHAR(15),USR.isServiceFeatureEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- END REV 68
		-- REV 69
		UNION ALL
		SELECT 'isPatientDetailsShowInOrder' as [Key],CONVERT(NVARCHAR(15),USR.isPatientDetailsShowInOrder) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isPatientDetailsShowInCollection' as [Key],CONVERT(NVARCHAR(15),USR.isPatientDetailsShowInCollection) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- END REV 69
		-- REV 70
		UNION ALL
		SELECT 'isAttachmentMandatory' as [Key],CONVERT(NVARCHAR(15),USR.isAttachmentMandatory) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'isShopImageMandatory' as [Key],CONVERT(NVARCHAR(15),USR.isShopImageMandatory) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- END REV 70
		-- REV 71
		UNION ALL
		SELECT 'isLogShareinLogin' as [Key],CONVERT(NVARCHAR(15),USR.isLogShareinLogin) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsCompetitorenable' as [Key],CONVERT(NVARCHAR(15),USR.IsCompetitorenable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsOrderStatusRequired' as [Key],CONVERT(NVARCHAR(15),USR.IsOrderStatusRequired) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID

		UNION ALL
		SELECT 'willDynamicShow' as [Key],CONVERT(NVARCHAR(15),USR.willDynamicShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsCurrentStockEnable' as [Key],CONVERT(NVARCHAR(15),USR.IsCurrentStockEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsCurrentStockApplicableforAll' as [Key],CONVERT(NVARCHAR(15),USR.IsCurrentStockApplicableforAll) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID

		UNION ALL
		SELECT 'IscompetitorStockRequired' as [Key],CONVERT(NVARCHAR(15),USR.IscompetitorStockRequired) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsCompetitorStockforParty' as [Key],CONVERT(NVARCHAR(15),USR.IsCompetitorStockforParty) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		-- END REV 71
		--REV 72
		UNION ALL
		SELECT 'ShowFaceRegInMenu' as [Key],CONVERT(NVARCHAR(15),USR.ShowFaceRegInMenu) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsFaceDetection' as [Key],CONVERT(NVARCHAR(15),USR.IsFaceDetection) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--END REV 72
		--Rev 73.0
		UNION ALL
		SELECT 'IsFaceDetectionWithCaptcha' AS [Key],CONVERT(NVARCHAR(15),USR.IsFaceDetectionWithCaptcha) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 73.0
		--Rev 74.0
		UNION ALL
		SELECT 'IsDocRepoFromPortal' AS [Key],CONVERT(NVARCHAR(15),USR.IsDocRepoFromPortal) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsDocRepShareDownloadAllowed' AS [Key],CONVERT(NVARCHAR(15),USR.IsDocRepShareDownloadAllowed) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsScreenRecorderEnable' AS [Key],CONVERT(NVARCHAR(15),USR.IsScreenRecorderEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 74.0
		--Rev 75.0
		UNION ALL
		SELECT 'IsShowMenuAddAttendance' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuAddAttendance) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuAttendance' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuAttendance) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuShops' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuShops) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuOutstanding Details PP/DD' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuOutstandingDetailsPPDD) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuStock Details - PP/DD' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuStockDetailsPPDD) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuTA' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuTA) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuMIS Report' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuMISReport) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuReimbursement' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuReimbursement) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuAchievement' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuAchievement) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuMap View' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuMapView) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuShare Location' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuShareLocation) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuHome Location' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuHomeLocation) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuWeather Details' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuWeatherDetails) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuChat' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuChat) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuScan QR Code' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuScanQRCode) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuPermission Info' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuPermissionInfo) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMenuAnyDesk' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuAnyDesk) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID		
		--End of Rev 75.0
		--Rev 76.0
		UNION ALL
		SELECT 'IsShowPartyOnAppDashboard' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowPartyOnAppDashboard) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowAttendanceOnAppDashboard' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowAttendanceOnAppDashboard) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowTotalVisitsOnAppDashboard' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowTotalVisitsOnAppDashboard) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowVisitDurationOnAppDashboard' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowVisitDurationOnAppDashboard) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 76.0
		--Rev 77.0
		UNION ALL
		SELECT 'IsLeaveGPSTrack' AS [Key],CONVERT(NVARCHAR(15),USR.IsLeaveGPSTrack) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowActivitiesInTeam' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowActivitiesInTeam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 77.0
		--Rev 78.0
		UNION ALL
		SELECT 'IsShowLeaveInAttendance' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowLeaveInAttendance) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowDayStart' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowDayStart) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsshowDayStartSelfie' AS [Key],CONVERT(NVARCHAR(15),USR.IsshowDayStartSelfie) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowDayEnd' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowDayEnd) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsshowDayEndSelfie' AS [Key],CONVERT(NVARCHAR(15),USR.IsshowDayEndSelfie) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 78.0
		--Rev 79.0
		UNION ALL
		SELECT 'IsShowMarkDistVisitOnDshbrd' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMarkDistVisitOnDshbrd) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 79.0
		--Rev 80.0
		UNION ALL
		SELECT 'IsActivateNewOrderScreenwithSize' AS [Key],CONVERT(NVARCHAR(15),USR.IsActivateNewOrderScreenwithSize) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 80.0
		--Rev 81.0
		UNION ALL
		SELECT 'IsPhotoDeleteShow' AS [Key],CONVERT(NVARCHAR(15),USR.IsPhotoDeleteShow) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 81.0
		--Rev 82.0
		UNION ALL
		SELECT 'RevisitRemarksMandatory' AS [Key],CONVERT(NVARCHAR(15),USR.RevisitRemarksMandatory) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 82.0
		--Rev 83.0
		UNION ALL
		SELECT 'GPSAlert' AS [Key],CONVERT(NVARCHAR(15),USR.GPSAlert) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'GPSAlertwithSound' AS [Key],CONVERT(NVARCHAR(15),USR.GPSAlertwithSound) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 83.0
		--Rev 84.0
		UNION ALL
		SELECT 'IsTeamAttendance' AS [Key],CONVERT(NVARCHAR(15),USR.IsTeamAttendance) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 84.0
		--Rev 86.0
		UNION ALL
		SELECT 'FaceDetectionAccuracyUpper' AS [Key],CONVERT(NVARCHAR(15),USR.FaceDetectionAccuracyUpper) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'FaceDetectionAccuracyLower' AS [Key],CONVERT(NVARCHAR(15),USR.FaceDetectionAccuracyLower) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'DistributorGPSAccuracy' AS [Key],CONVERT(NVARCHAR(15),USR.DistributorGPSAccuracy) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 86.0
		--Rev 87.0
		UNION ALL
		SELECT 'BatterySetting' AS [Key],CONVERT(NVARCHAR(15),USR.BatterySetting) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'PowerSaverSetting' AS [Key],CONVERT(NVARCHAR(15),USR.PowerSaverSetting) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 87.0
		--Rev 89.0
		UNION ALL
		SELECT 'Show_App_Logout_Notification' AS [Key],CONVERT(NVARCHAR(15),USR.Show_App_Logout_Notification) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 89.0
		--Rev 90.0
		UNION ALL
		SELECT 'IsShowTypeInRegistration' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowTypeInRegistration) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 90.0
		--Rev 91.0
		UNION ALL
		SELECT 'IsReturnEnableforParty' AS [Key],CONVERT(NVARCHAR(15),USR.IsReturnEnableforParty) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 91.0
		--Rev 93.0
		UNION ALL
		SELECT 'MRPInOrder' AS [Key],CONVERT(NVARCHAR(15),USR.MRPInOrder) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'FaceRegistrationFrontCamera' AS [Key],CONVERT(NVARCHAR(15),USR.FaceRegistrationFrontCamera) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 93.0
		--Rev 94.0
		UNION ALL
		SELECT 'IsShowMyDetails' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMyDetails) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 94.0
		--Rev 95.0
		UNION ALL
		SELECT 'IslandlineforCustomer' AS [Key],CONVERT(NVARCHAR(15),USR.IslandlineforCustomer) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsprojectforCustomer' AS [Key],CONVERT(NVARCHAR(15),USR.IsprojectforCustomer) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 95.0
		--Rev 97.0
		UNION ALL
		SELECT 'IsAttendVisitShowInDashboard' AS [Key],CONVERT(NVARCHAR(15),USR.IsAttendVisitShowInDashboard) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowManualPhotoRegnInApp' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowManualPhotoRegnInApp) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'Leaveapprovalfromsupervisorinteam' AS [Key],CONVERT(NVARCHAR(15),USR.Leaveapprovalfromsupervisorinteam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'Leaveapprovalfromsupervisor' AS [Key],CONVERT(NVARCHAR(15),USR.Leaveapprovalfromsupervisor) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 97.0
		--Rev 98.0
		UNION ALL
		SELECT 'IsIMEICheck' AS [Key],CONVERT(NVARCHAR(15),USR.IsIMEICheck) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsRestrictNearbyGeofence' AS [Key],CONVERT(NVARCHAR(15),USR.IsRestrictNearbyGeofence) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsNewQuotationfeatureOn' AS [Key],CONVERT(NVARCHAR(15),USR.IsNewQuotationfeatureOn) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 98.0
		--Rev 100.0
		UNION ALL
		SELECT 'IsAlternateNoForCustomer' AS [Key],CONVERT(NVARCHAR(15),USR.IsAlternateNoForCustomer) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsWhatsappNoForCustomer' AS [Key],CONVERT(NVARCHAR(15),USR.IsWhatsappNoForCustomer) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 100.0
		--Rev 101.0
		UNION ALL
		SELECT 'MarkAttendNotification' AS [Key],CONVERT(NVARCHAR(15),USR.MarkAttendNotification) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'UpdateUserName' AS [Key],CONVERT(NVARCHAR(15),USR.UpdateUserName) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 101.0
		--Rev 102.0
		UNION ALL
		SELECT 'IsNewQuotationNumberManual' AS [Key],CONVERT(NVARCHAR(15),USR.IsNewQuotationNumberManual) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'ShowQuantityNewQuotation' AS [Key],CONVERT(NVARCHAR(15),USR.ShowQuantityNewQuotation) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'ShowAmountNewQuotation' AS [Key],CONVERT(NVARCHAR(15),USR.ShowAmountNewQuotation) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 102.0
		--Rev 104.0
		UNION ALL
		SELECT 'IsAllowClickForPhotoRegister' AS [Key],CONVERT(NVARCHAR(15),USR.IsAllowClickForPhotoRegister) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsAllowClickForVisit' AS [Key],CONVERT(NVARCHAR(15),USR.IsAllowClickForVisit) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 104.0
		--Rev 105.0
		UNION ALL
		SELECT 'ShowUserwiseLeadMenu' AS [Key],CONVERT(NVARCHAR(15),USR.ShowUserwiseLeadMenu) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 105.0
		--Rev 106.0
		UNION ALL
		SELECT 'AllowProfileUpdate' AS [Key],CONVERT(NVARCHAR(15),USR.AllowProfileUpdate) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'GeofencingRelaxationinMeter' AS [Key],CONVERT(NVARCHAR(15),USR.GeofencingRelaxationinMeter) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 106.0
		--Rev 107.0
		UNION ALL
		SELECT 'LogoutWithLogFile' AS [Key],CONVERT(NVARCHAR(15),USR.LogoutWithLogFile) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'InAppUpdateApplicable' AS [Key],CONVERT(NVARCHAR(15),USR.InAppUpdateApplicable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 107.0
		--Rev 108.0
		UNION ALL
		SELECT 'IsFeedbackHistoryActivated' AS [Key],CONVERT(NVARCHAR(15),USR.IsFeedbackHistoryActivated) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsAutoLeadActivityDateTime' AS [Key],CONVERT(NVARCHAR(15),USR.IsAutoLeadActivityDateTime) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 108.0
		--Rev 109.0
		UNION ALL
		SELECT 'ShowAutoRevisitInDashboard' AS [Key],CONVERT(NVARCHAR(15),USR.ShowAutoRevisitInDashboard) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'ShowAutoRevisitInAppMenu' AS [Key],CONVERT(NVARCHAR(15),USR.ShowAutoRevisitInAppMenu) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 109.0
		--Rev 110.0
		UNION ALL
		SELECT 'IsShowNearByTeam' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowNearByTeam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowRevisitRemarksPopup' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowRevisitRemarksPopup) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsAllowShopStatusUpdate' AS [Key],CONVERT(NVARCHAR(15),USR.IsAllowShopStatusUpdate) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 110.0
		--Rev 111.0
		UNION ALL
		SELECT 'ShowTotalVisitAppMenu' AS [Key],CONVERT(NVARCHAR(15),USR.ShowTotalVisitAppMenu) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'OfflineShopAccuracy' AS [Key],CONVERT(NVARCHAR(15),USR.OfflineShopAccuracy) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 111.0
		--Rev 112.0
		UNION ALL
		SELECT 'AutoRevisitTimeInSeconds' AS [Key],CONVERT(NVARCHAR(15),USR.AutoRevisitTimeInSeconds) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 112.0
		--Rev 113.0
		UNION ALL
		SELECT 'PartyUpdateAddrMandatory' AS [Key],CONVERT(NVARCHAR(15),USR.PartyUpdateAddrMandatory) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 113.0
		--Rev 114.0
		UNION ALL
		SELECT 'IsCollectionOrderWise' AS [Key],CONVERT(NVARCHAR(15),USR.IsCollectionOrderWise) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'ShowCollectionOnlywithInvoiceDetails' AS [Key],CONVERT(NVARCHAR(15),USR.ShowCollectionOnlywithInvoiceDetails) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'ShowCollectionAlert' AS [Key],CONVERT(NVARCHAR(15),USR.ShowCollectionAlert) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'ShowZeroCollectioninAlert' AS [Key],CONVERT(NVARCHAR(15),USR.ShowZeroCollectioninAlert) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsPendingCollectionRequiredUnderTeam' AS [Key],CONVERT(NVARCHAR(15),USR.IsPendingCollectionRequiredUnderTeam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 114.0
		--Rev 116.0
		UNION ALL
		SELECT 'IsShowRepeatOrderinNotification' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowRepeatOrderinNotification) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowRepeatOrdersNotificationinTeam' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowRepeatOrdersNotificationinTeam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 116.0
		--Rev 117.0
		UNION ALL
		SELECT 'AutoDDSelect' AS [Key],CONVERT(NVARCHAR(15),USR.AutoDDSelect) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'ShowPurposeInShopVisit' AS [Key],CONVERT(NVARCHAR(15),USR.ShowPurposeInShopVisit) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 117.0
		--Rev 119.0
		UNION ALL
		SELECT 'WillRoomDBShareinLogin' AS [Key],CONVERT(NVARCHAR(15),USR.WillRoomDBShareinLogin) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'GPSAlertwithVibration' AS [Key],CONVERT(NVARCHAR(15),USR.GPSAlertwithVibration) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 119.0
		--Rev 120.0
		UNION ALL
		SELECT 'ShopScreenAftVisitRevisit' AS [Key],CONVERT(NVARCHAR(15),USR.ShopScreenAftVisitRevisit) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 120.0
		--Rev 121.0
		UNION ALL
		SELECT 'IsFeedbackAvailableInShop' AS [Key],CONVERT(NVARCHAR(15),USR.IsFeedbackAvailableInShop) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 121.0
		--Rev 122.0
		UNION ALL
		SELECT 'IsAllowBreakageTracking' AS [Key],CONVERT(NVARCHAR(15),USR.IsAllowBreakageTracking) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsAllowBreakageTrackingunderTeam' AS [Key],CONVERT(NVARCHAR(15),USR.IsAllowBreakageTrackingunderTeam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsRateEnabledforNewOrderScreenwithSize' AS [Key],CONVERT(NVARCHAR(15),USR.IsRateEnabledforNewOrderScreenwithSize) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 122.0
		--Rev 123.0
		UNION ALL
		SELECT 'IgnoreNumberCheckwhileShopCreation' AS [Key],CONVERT(NVARCHAR(15),USR.IgnoreNumberCheckwhileShopCreation) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 123.0
		--Rev 124.0
		UNION ALL
		SELECT 'Showdistributorwisepartyorderreport' AS [Key],CONVERT(NVARCHAR(15),USR.Showdistributorwisepartyorderreport) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 124.0
		--Rev 126.0
		UNION ALL
		SELECT 'IsShowHomeLocationMap' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowHomeLocationMap) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 126.0
		--Rev 128.0
		UNION ALL
		SELECT 'IsBeatRouteReportAvailableinTeam' AS [Key],CONVERT(NVARCHAR(15),USR.IsBeatRouteReportAvailableinTeam) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 128.0
		--Rev 129.0
		UNION ALL
		SELECT 'ShowAttednaceClearmenu' AS [Key],CONVERT(NVARCHAR(15),USR.ShowAttednaceClearmenu) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 129.0
		--Rev 131.0
		UNION ALL
		SELECT 'CommonAINotification' AS [Key],CONVERT(NVARCHAR(15),USR.CommonAINotification) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsFaceRecognitionOnEyeblink' AS [Key],CONVERT(NVARCHAR(15),USR.IsFaceRecognitionOnEyeblink) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 131.0
		--Rev 133.0
		UNION ALL
		SELECT 'GPSNetworkIntervalMins' AS [Key],CONVERT(NVARCHAR(15),USR.GPSNetworkIntervalMins) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 133.0
		--Rev 137.0
		UNION ALL
		SELECT 'IsShowTypeInRegistrationForSpecificUser' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowTypeInRegistrationForSpecificUser) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsFeedbackMandatoryforNewShop' AS [Key],CONVERT(NVARCHAR(15),USR.IsFeedbackMandatoryforNewShop) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 137.0
		--Rev 139.0
		UNION ALL
		SELECT 'IsLoginSelfieRequired' AS [Key],CONVERT(NVARCHAR(15),USR.IsLoginSelfieRequired) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 139.0
		--Rev 141.0
		UNION ALL
		SELECT 'IsJointVisitEnable' AS [Key],CONVERT(NVARCHAR(15),USR.IsJointVisitEnable) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowAllEmployeeforJointVisit' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowAllEmployeeforJointVisit) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 141.0
		--Rev 143.0
		UNION ALL
		SELECT 'IsMultipleContactEnableforShop' AS [Key],CONVERT(NVARCHAR(15),USR.IsMultipleContactEnableforShop) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsContactPersonSelectionRequiredinRevisit' AS [Key],CONVERT(NVARCHAR(15),USR.IsContactPersonSelectionRequiredinRevisit) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 143.0
		--Rev 144.0
		UNION ALL
		SELECT 'IsContactPersonRequiredinQuotation' AS [Key],CONVERT(NVARCHAR(15),USR.IsContactPersonRequiredinQuotation) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 144.0
		--Rev 145.0
		UNION ALL
		SELECT 'IsShowBeatInMenu' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowBeatInMenu) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 145.0
		--Rev 151.0
		UNION ALL
		SELECT 'IsAssignedDDAvailableForAllUser' AS [Key],CONVERT(NVARCHAR(15),USR.IsAssignedDDAvailableForAllUser) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 151.0
		--Rev 153.0
		UNION ALL
		SELECT 'IsShowEmployeePerformance' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowEmployeePerformance) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 153.0
		--Rev 159.0
		UNION ALL
		SELECT 'IsShowWorkType' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowWorkType) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowMarketSpendTimer' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMarketSpendTimer) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowUploadImageInAppProfile' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowUploadImageInAppProfile) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowCalendar' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowCalendar) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowCalculator' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowCalculator) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowInactiveCustomer' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowInactiveCustomer) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		UNION ALL
		SELECT 'IsShowAttendanceSummary' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowAttendanceSummary) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 159.0
		--Rev 161.0
		UNION ALL
		SELECT 'IsMenuShowAIMarketAssistant' AS [Key],CONVERT(NVARCHAR(15),USR.IsMenuShowAIMarketAssistant) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 161.0
		--Rev 164.0
		UNION ALL
		SELECT 'IsUsbDebuggingRestricted' AS [Key],CONVERT(NVARCHAR(15),USR.IsUsbDebuggingRestricted) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 164.0
		--Rev 169.0
		UNION ALL
		SELECT 'IsDisabledUpdateAddress' AS [Key],CONVERT(NVARCHAR(15),USR.IsDisabledUpdateAddress) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 169.0
		--Rev 170.0
		UNION ALL
		SELECT 'IsCheckBatteryOptimization' AS [Key],CONVERT(NVARCHAR(15),USR.IsCheckBatteryOptimization) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 170.0
		--Rev 173.0
		UNION ALL
		SELECT 'IsShowMenuCRMContacts' AS [Key],CONVERT(NVARCHAR(15),USR.IsShowMenuCRMContacts) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 173.0
		--Rev 174.0
		UNION ALL
		SELECT 'IsCallLogHistoryActivated' AS [Key],CONVERT(NVARCHAR(15),USR.IsCallLogHistoryActivated) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 174.0
		--Rev 175.0
		UNION ALL
		SELECT 'IsAllDataInPortalwithHeirarchy' AS [Key],CONVERT(NVARCHAR(15),USR.IsAllDataInPortalwithHeirarchy) AS [Value] 
		FROM tbl_master_user USR WHERE USR.USER_ID=@UserID
		--End of Rev 175.0
	END

	SET NOCOUNT OFF
END
GO