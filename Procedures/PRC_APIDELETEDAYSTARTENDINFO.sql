IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIDELETEDAYSTARTENDINFO]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIDELETEDAYSTARTENDINFO] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APIDELETEDAYSTARTENDINFO]
(
@ACTION NVARCHAR(50),
@USER_ID BIGINT=NULL,
@DATE NVARCHAR(20)=NULL,
@ISDAYSTARTDEL NCHAR(1)=NULL,
@ISDAYENDDEL NCHAR(1)=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************************************************************
Written By : Debashis Talukder On 29/08/2022
Purpose : For Clear DayStart DayEnd data.Row: 736
***************************************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
		
	IF @ACTION='DELETEDAYSTARTENDATTENDANCE'
		BEGIN
			IF @ISDAYSTARTDEL='1' AND @ISDAYENDDEL='0'
				BEGIN
					IF EXISTS(SELECT User_Id FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) AND ISSTART=CAST(@ISDAYSTARTDEL AS BIT))
						BEGIN
							SELECT User_Id FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) AND ISSTART=CAST(@ISDAYSTARTDEL AS BIT)
							DELETE FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) AND ISSTART=CAST(@ISDAYSTARTDEL AS BIT)
						END
				END
			ELSE IF @ISDAYSTARTDEL='0' AND @ISDAYENDDEL='1'
				BEGIN
					IF EXISTS(SELECT User_Id FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) AND ISEND=CAST(@ISDAYENDDEL AS BIT))
						BEGIN
							SELECT User_Id FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) AND ISEND=CAST(@ISDAYENDDEL AS BIT)
							DELETE FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) AND ISEND=CAST(@ISDAYENDDEL AS BIT)
						END
				END
			ELSE IF @ISDAYSTARTDEL='1' AND @ISDAYENDDEL='1'
				BEGIN
					IF EXISTS(SELECT User_Id FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) 
					AND (ISSTART=CAST(@ISDAYSTARTDEL AS BIT) OR ISEND=CAST(@ISDAYENDDEL AS BIT)))
						BEGIN
							SELECT User_Id FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) 
							AND (ISSTART=CAST(@ISDAYSTARTDEL AS BIT) OR ISEND=CAST(@ISDAYENDDEL AS BIT))
							DELETE FROM FSMUSERWISEDAYSTARTEND WHERE User_Id=@USER_ID AND CAST(STARTENDDATE AS DATE)=CAST(@DATE AS DATE) 
							AND (ISSTART=CAST(@ISDAYSTARTDEL AS BIT) OR ISEND=CAST(@ISDAYENDDEL AS BIT))
						END
				END
		END
	SET NOCOUNT OFF
END