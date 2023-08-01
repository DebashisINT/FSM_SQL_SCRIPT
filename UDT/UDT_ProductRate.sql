

IF NOT EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'UDT_ProductRate')
BEGIN
	CREATE TYPE [dbo].[UDT_ProductRate] AS TABLE(
		[STATE] [nvarchar](300) NULL,
		[Code] [nvarchar](300) NULL,
		[Description] [nvarchar](500) NULL,
		[Price to Super] [decimal](18, 2) NULL,
		[Price to Distributor] [decimal](20, 2) NULL,
		[Price to Retailer] [decimal](20, 2) NULL,		
		[Qty per Unit (Distributor)][decimal](18, 4) NULL,
		[Scheme Qty (For Distributor)][decimal](18, 4) NULL,
		[Effective Price][decimal](18, 2) NULL
	)
END
GO




