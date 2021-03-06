--select dbo.FN_AmountInWords(1805526.50000000,1)

IF NOT EXISTS (SELECT * FROM sys.objects  WHERE  object_id = OBJECT_ID(N'[dbo].[FN_AmountInWords]') AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
BEGIN
EXEC('CREATE FUNCTION [dbo].[FN_AmountInWords]() RETURNS DECIMAL(18,2) AS BEGIN RETURN 0 END')
END
GO

ALTER FUNCTION [dbo].[FN_AmountInWords](@Money AS money, @NestLevel int)
    RETURNS VARCHAR(1024)
--WITH ENCRYPTION
AS
BEGIN
      DECLARE @Number as BIGINT
      SET @Number = FLOOR(@Money)
      DECLARE @Below20 TABLE (ID int identity(0,1), Word varchar(32))
      DECLARE @Below100 TABLE (ID int identity(2,1), Word varchar(32))
 
      INSERT @Below20 (Word) VALUES
                        ( 'Zero'), ('One'),( 'Two' ), ( 'Three'),
                        ( 'Four' ), ( 'Five' ), ( 'Six' ), ( 'Seven' ),
                        ( 'Eight'), ( 'Nine'), ( 'Ten'), ( 'Eleven' ),
                        ( 'Twelve' ), ( 'Thirteen' ), ( 'Fourteen'),
                        ( 'Fifteen' ), ('Sixteen' ), ( 'Seventeen'),
                        ('Eighteen' ), ( 'Nineteen' )
       INSERT @Below100 VALUES ('Twenty'), ('Thirty'),('Forty'), ('Fifty'),
                               ('Sixty'), ('Seventy'), ('Eighty'), ('Ninety')
 
DECLARE @English varchar(1024) =
(
  SELECT Case WHEN @Number = 0 THEN  '' WHEN @Number BETWEEN 1 AND 19 THEN (SELECT Word FROM @Below20 WHERE ID=@Number)
   WHEN @Number BETWEEN 20 AND 99 
	-- SQL Server recursive function   
     THEN  (SELECT Word FROM @Below100 WHERE ID=@Number/10)+ '-' +
           dbo.FN_AmountInWords( @Number % 10, @NestLevel)
   WHEN @Number BETWEEN 100 AND 999  
     THEN  (dbo.FN_AmountInWords( @Number / 100, @NestLevel))+' Hundred '+
         dbo.FN_AmountInWords( @Number % 100, @NestLevel)
   WHEN @Number BETWEEN 1000 AND 99999  
     THEN  (dbo.FN_AmountInWords( @Number / 1000, @NestLevel))+' Thousand '+
         dbo.FN_AmountInWords( @Number % 1000, @NestLevel) 
   WHEN @Number BETWEEN 100000 AND 9999999  
     THEN  (dbo.FN_AmountInWords( @Number / 100000, @NestLevel))+' Lac '+
         dbo.FN_AmountInWords( @Number % 100000, @NestLevel) 
   WHEN @Number BETWEEN 10000000 AND 999999999  
     THEN  (dbo.FN_AmountInWords( @Number / 10000000, @NestLevel))+' Crore '+
         dbo.FN_AmountInWords( @Number % 10000000, @NestLevel)
   ELSE ' INVALID INPUT' END
)
SELECT @English = RTRIM(@English)
SELECT @English = RTRIM(LEFT(@English,len(@English)-1))
                 WHERE RIGHT(@English,1)='-'
IF (@@NestLevel - @NestLevel) = 1
BEGIN
      SELECT @English = ' Rupees '+@English
-- ############# Convert Number to word ##################
-- ############# Convert decimal value to word ##################
DECLARE @Chhetrum BIGINT= convert(BIGINT,convert(int,100*(@Money - @Number)))
DECLARE @ChhetrumInWords varchar(1024) =
(
	  SELECT Case WHEN @Chhetrum = 0 THEN  '' WHEN @Chhetrum BETWEEN 1 AND 19 THEN ' And '+(SELECT Word FROM @Below20 WHERE ID=@Chhetrum) +' Paise'
	  WHEN @Chhetrum BETWEEN 20 AND 99 THEN  ' And '+(SELECT Word FROM @Below100 WHERE ID=@Chhetrum/10)+ ' ' +
           dbo.FN_AmountInWords( @Chhetrum % 10, @NestLevel)+' Paise'
		ELSE ' INVALID INPUT' END
)
-- ############# Convert decimal value to word ##################
SELECT @English = @English+@ChhetrumInWords+' Only'
END
SET @English=LTRIM(RTRIM(REPLACE(@English,'  ',' ')))
RETURN (@English)
END
GO
