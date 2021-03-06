IF NOT EXISTS (SELECT * FROM sys.objects  WHERE  object_id = OBJECT_ID(N'[dbo].[FN_AmountInWordsForForeignCurrency]') AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
BEGIN
EXEC('CREATE FUNCTION [dbo].[FN_AmountInWordsForForeignCurrency](@Money AS money, @CurrencyID INT,@NestLevel int) RETURNS DECIMAL(18,2) AS BEGIN RETURN 0 END')
END
GO

ALTER FUNCTION [dbo].[FN_AmountInWordsForForeignCurrency](@Money AS money, @CurrencyID INT,@NestLevel int)
RETURNS VARCHAR(8000)
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
      DECLARE @Below20 TABLE (ID int identity(0,1), Word varchar(32))
      DECLARE @Below100 TABLE (ID int identity(2,1), Word varchar(32))

	  SELECT @Currency_Name=Currency_Name,@Currency_DecimalPortionName=Currency_DecimalPortionName FROM Master_Currency WHERE Currency_ID=@CurrencyID
 
      INSERT @Below20 (Word) VALUES
                        ( 'Zero'), ('One'),( 'Two' ), ( 'Three'),
                        ( 'Four' ), ( 'Five' ), ( 'Six' ), ( 'Seven' ),
                        ( 'Eight'), ( 'Nine'), ( 'Ten'), ( 'Eleven' ),
                        ( 'Twelve' ), ( 'Thirteen' ), ( 'Fourteen'),
                        ( 'Fifteen' ), ('Sixteen' ), ( 'Seventeen'),
                        ('Eighteen' ), ( 'Nineteen' )
       INSERT @Below100 VALUES ('Twenty'), ('Thirty'),('Forty'), ('Fifty'),
                               ('Sixty'), ('Seventy'), ('Eighty'), ('Ninety')
 
DECLARE @AmountInWord varchar(8000) =
(
  SELECT Case
    WHEN @Number = 0 THEN  ''
    WHEN @Number BETWEEN 1 AND 19
      THEN (SELECT Word FROM @Below20 WHERE ID=@Number)
   WHEN @Number BETWEEN 20 AND 99
-- SQL Server recursive function   
     THEN  (SELECT Word FROM @Below100 WHERE ID=@Number/10)+ '-' +
           dbo.FN_AmountInWordsForForeignCurrency( @Number % 10, @CurrencyID,@NestLevel)
   WHEN @Number BETWEEN 100 AND 999  
     THEN  (dbo.FN_AmountInWordsForForeignCurrency( @Number / 100, @CurrencyID,@NestLevel))+' Hundred '+
         dbo.FN_AmountInWordsForForeignCurrency( @Number % 100, @CurrencyID,@NestLevel)
   WHEN @Number BETWEEN 1000 AND 999999  
     THEN  (dbo.FN_AmountInWordsForForeignCurrency( @Number / 1000, @CurrencyID,@NestLevel))+' Thousand '+
         dbo.FN_AmountInWordsForForeignCurrency( @Number % 1000, @CurrencyID,@NestLevel) 
   WHEN @Number BETWEEN 1000000 AND 999999999  
     THEN  (dbo.FN_AmountInWordsForForeignCurrency( @Number / 1000000, @CurrencyID,@NestLevel))+' Million '+
         dbo.FN_AmountInWordsForForeignCurrency( @Number % 1000000, @CurrencyID,@NestLevel)
   ELSE ' INVALID INPUT' END
)
-- ############# Convert decimal value to word ##################
DECLARE @Decimalpart BIGINT= convert(BIGINT,convert(int,100*(@Money - @Number)))
SELECT @AmountInWord = RTRIM(@AmountInWord)
SELECT @AmountInWord = RTRIM(LEFT(@AmountInWord,len(@AmountInWord)-1))
                 WHERE RIGHT(@AmountInWord,1)='-'
IF (@@NestLevel - @NestLevel) = 1
	BEGIN
		IF @Decimalpart<>0
			BEGIN
				SELECT @AmountInWord = @Currency_Name+' '+@AmountInWord+' and '
				SELECT @AmountInWord = @AmountInWord+CASE WHEN @Decimalpart BETWEEN 1 AND 19 THEN (SELECT Word FROM @Below20 WHERE ID=@Decimalpart) 
				WHEN @Decimalpart BETWEEN 20 AND 99 THEN (SELECT Word FROM @Below100 WHERE ID=@Decimalpart/10)+ ' ' +
				dbo.FN_AmountInWordsForForeignCurrency(@Decimalpart% 10, @CurrencyID,@NestLevel) END+' '+@Currency_DecimalPortionName 
			END
		ELSE
			BEGIN
				SELECT @AmountInWord = @Currency_Name+' '+@AmountInWord 
			END
	END
SET @AmountInWord=LTRIM(RTRIM(REPLACE(@AmountInWord,'  ',' ')))
RETURN (@AmountInWord)
END
