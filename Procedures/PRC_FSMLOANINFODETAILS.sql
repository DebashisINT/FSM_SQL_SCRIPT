IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FSMLOANINFODETAILS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FSMLOANINFODETAILS] AS' 
END
GO

ALTER PROCEDURE  [dbo].[PRC_FSMLOANINFODETAILS]
(
@ACTION NVARCHAR(50),
@USER_ID BIGINT=NULL,
@SHOP_ID NVARCHAR(100)=NULL,
@RISK_ID BIGINT=NULL,
@RISK_NAME NVARCHAR(100)=NULL,
@WORKABLE NVARCHAR(100)=NULL,
@DISPOSITION_CODE_ID BIGINT=NULL,
@DISPOSITION_CODE_NAME NVARCHAR(200)=NULL,
@PTP_DATE NVARCHAR(10)=NULL,
@PTP_AMT DECIMAL(18,2)=NULL,
@COLLECTION_DATE NVARCHAR(10)=NULL,
@COLLECTION_AMOUNT DECIMAL(18,2)=NULL,
@FINAL_STATUS_ID BIGINT=NULL,
@FINAL_STATUS_NAME NVARCHAR(200)=NULL
) --WITH ENCRYPTION
AS
/************************************************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 15/11/2024
Module	   : Loan Info Details.Refer: Row: 1000,1001,1002,1003 & 1004
************************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='LOANRISKLIST'
		BEGIN
			SELECT RISKID AS id,RISKNAME AS [name] FROM FSM_LOANRISK WHERE ISACTIVE=1
		END
	IF @ACTION='LOANDISPOSITIONLIST'
		BEGIN
			SELECT DISPOSITIONID AS id,DISPOSITIONCODE AS [name] FROM FSM_LOANDISPOSITIONCODE WHERE ISACTIVE=1
		END
	IF @ACTION='LOANFINALSTATUSLIST'
		BEGIN
			SELECT FINALSTATUSID AS id,FINALSTATUSNAME AS [name] FROM FSM_LOANFINALSTATUS WHERE ISACTIVE=1
		END
	IF @ACTION='LOANDETAILFETCH'
		BEGIN
			SELECT MS.Shop_Code AS shop_id,ISNULL(MS.BKT,'') AS bkt,ISNULL(MS.TOTALOUTSTANDING,0.00) AS total_outstanding,ISNULL(MS.POS,0.00) AS pos,ISNULL(MS.EMIAMOUNT,0.00) AS emi_amt,
			ISNULL(MS.ALLCHARGES,0.00) AS all_charges,ISNULL(MS.TOTALCOLLECTABLE,0.00) AS total_Collectable,ISNULL(MS.RISK,0) AS risk_id,ISNULL(LR.RISKNAME,'') AS risk_name,
			ISNULL(MS.WORKABLE,'') AS workable,ISNULL(MS.DISPOSITIONCODE,0) AS disposition_code_id,ISNULL(LD.DISPOSITIONCODE,'') AS disposition_code_name,
			ISNULL(CONVERT(NVARCHAR(10),MS.PTPDATE,120),'') AS ptp_Date,ISNULL(MS.PTPAMOUNT,0.00) AS ptp_amt,ISNULL(CONVERT(NVARCHAR(10),MS.COLLECTIONDATE,120),'') AS collection_date,
			ISNULL(MS.COLLECTIONAMOUNT,0.00) AS collection_amount,ISNULL(MS.FINALSTATUS,0) AS final_status_id,ISNULL(LFS.FINALSTATUSNAME,'') AS final_status_name
			FROM tbl_Master_shop MS
			LEFT OUTER JOIN FSM_LOANRISK LR ON MS.RISK=LR.RISKID AND LR.ISACTIVE=1
			LEFT OUTER JOIN FSM_LOANDISPOSITIONCODE LD ON MS.DISPOSITIONCODE=LD.DISPOSITIONID AND LD.ISACTIVE=1
			LEFT OUTER JOIN FSM_LOANFINALSTATUS LFS ON MS.FINALSTATUS=LFS.FINALSTATUSID AND LD.ISACTIVE=1
			WHERE Shop_CreateUser=@USER_ID
		END
	IF @ACTION='LOANDETAILUPDATE'
		BEGIN
			UPDATE tbl_Master_shop SET
			RISK=CASE WHEN @RISK_ID IS NULL OR @RISK_ID=0 THEN RISK ELSE @RISK_ID END,
			WORKABLE=CASE WHEN @WORKABLE IS NULL OR @WORKABLE='' THEN WORKABLE ELSE @WORKABLE END,
			DISPOSITIONCODE=CASE WHEN @DISPOSITION_CODE_ID IS NULL OR @DISPOSITION_CODE_ID=0 THEN DISPOSITIONCODE ELSE @DISPOSITION_CODE_ID END,
			PTPDATE=CASE WHEN @PTP_DATE IS NULL OR @PTP_DATE='' THEN PTPDATE ELSE @PTP_DATE END,
			PTPAMOUNT=CASE WHEN @PTP_AMT IS NULL OR @PTP_AMT=0 THEN PTPAMOUNT ELSE @PTP_AMT END,
			COLLECTIONDATE=CASE WHEN @COLLECTION_DATE IS NULL OR @COLLECTION_DATE='' THEN COLLECTIONDATE ELSE @COLLECTION_DATE END,
			COLLECTIONAMOUNT=CASE WHEN @COLLECTION_AMOUNT IS NULL OR @COLLECTION_AMOUNT=0 THEN COLLECTIONAMOUNT ELSE @COLLECTION_AMOUNT END,
			FINALSTATUS=CASE WHEN @FINAL_STATUS_ID IS NULL OR @FINAL_STATUS_ID=0 THEN FINALSTATUS ELSE @FINAL_STATUS_ID END
			WHERE Shop_Code=@SHOP_ID AND Shop_CreateUser=@USER_ID

			SELECT 1
		END

	SET NOCOUNT OFF
END
GO