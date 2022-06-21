--select dbo.FN_AmountInForeignCurrency(1805526.50000000,2,1)

IF NOT EXISTS (SELECT * FROM sys.objects  WHERE  object_id = OBJECT_ID(N'[dbo].[FN_AmountInForeignCurrency]') AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
BEGIN
EXEC('CREATE FUNCTION [dbo].[FN_AmountInForeignCurrency](@Money AS money, @CurrencyID INT,@NestLevel int) RETURNS DECIMAL(18,2) AS BEGIN RETURN 0 END')
END
GO

ALTER FUNCTION [dbo].[FN_AmountInForeignCurrency](@Money AS money, @CurrencyID INT,@NestLevel int)
RETURNS NUMERIC(38,2)
--WITH ENCRYPTION
AS
/**********************************************************************************************************************************************************************
Written by : Debashis Talukder On 22/08/2018
Module	   : Amount In Words For Foreign Currency transactions.Refer: 0017761
**********************************************************************************************************************************************************************/
BEGIN
      DECLARE @Number AS BIGINT
	  DECLARE @Currency_Name NVARCHAR(100),@Currency_DecimalPortionName NVARCHAR(100)
      SET @Number = FLOOR(@Money)
      DECLARE @Below20 TABLE (ID int identity(0,1), number BIGINT)
      DECLARE @Below100 TABLE (ID int identity(2,1), number BIGINT)

	  SELECT @Currency_Name=Currency_Name,@Currency_DecimalPortionName=Currency_DecimalPortionName FROM Master_Currency WHERE Currency_ID=@CurrencyID
 
      INSERT @Below20 (number) VALUES
                        (0), (1),(2), (3),
                        (4), (5), (6), (7),
                        (8), (9), ( 10), (11),
                        (12), (13), (14),
                        (15), (16), (17),
                        (18), (19)
       INSERT @Below100 (number) VALUES (20), (30),(40), (50),
                               (60), (70), (80), (90)
 
DECLARE @AmountInFC NUMERIC(38,2) =
(
  SELECT Case
    WHEN @Number = 0 THEN  0
    WHEN @Number BETWEEN 1 AND 19
      THEN (SELECT number FROM @Below20 WHERE ID=@Number)
   WHEN @Number BETWEEN 20 AND 99
-- SQL Server recursive function   
     THEN  (SELECT number FROM @Below100 WHERE ID=@Number/10)+ '-' +
           dbo.FN_AmountInForeignCurrency( @Number % 10, @CurrencyID,@NestLevel)
   WHEN @Number BETWEEN 100 AND 999  
     THEN  (dbo.FN_AmountInForeignCurrency( @Number / 100, @CurrencyID,@NestLevel))+
         dbo.FN_AmountInForeignCurrency( @Number % 100, @CurrencyID,@NestLevel)
   WHEN @Number BETWEEN 1000 AND 999999  
     THEN  (dbo.FN_AmountInForeignCurrency( @Number / 1000, @CurrencyID,@NestLevel))+
         dbo.FN_AmountInForeignCurrency( @Number % 1000, @CurrencyID,@NestLevel) 
   WHEN @Number BETWEEN 1000000 AND 999999999  
     THEN  (dbo.FN_AmountInForeignCurrency( @Number / 1000000, @CurrencyID,@NestLevel))+
         dbo.FN_AmountInForeignCurrency( @Number % 1000000, @CurrencyID,@NestLevel)
   ELSE 0.00 END
)
-- ############# Convert decimal value to word ##################
DECLARE @Decimalpart BIGINT= convert(BIGINT,convert(int,100*(@Money - @Number)))
SELECT @AmountInFC = RTRIM(@AmountInFC)
SELECT @AmountInFC = RTRIM(LEFT(@AmountInFC,len(@AmountInFC)-1))
                 WHERE RIGHT(@AmountInFC,1)='-'
IF (@@NestLevel - @NestLevel) = 1
	BEGIN
		IF @Decimalpart<>0
			BEGIN
				SELECT @AmountInFC = @Currency_Name+' '+@AmountInFC+' and '
				SELECT @AmountInFC = @AmountInFC+CASE WHEN @Decimalpart BETWEEN 1 AND 19 THEN (SELECT number FROM @Below20 WHERE ID=@Decimalpart) 
				WHEN @Decimalpart BETWEEN 20 AND 99 THEN (SELECT number FROM @Below100 WHERE ID=@Decimalpart/10)+ ' ' +
				dbo.FN_AmountInForeignCurrency(@Decimalpart% 10, @CurrencyID,@NestLevel) END+' '+@Currency_DecimalPortionName 
			END
		ELSE
			BEGIN
				--SELECT @AmountInFC = @Currency_Name+' '+@AmountInFC 
				SELECT @AmountInFC = @AmountInFC 
			END
	END
SET @AmountInFC=LTRIM(RTRIM(REPLACE(@AmountInFC,'  ',' ')))
RETURN (@AmountInFC)
END
