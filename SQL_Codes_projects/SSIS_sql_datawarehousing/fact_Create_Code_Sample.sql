-- this is used as an example for creating fact table, empty fact table

USE [AdventureWorksDW2019]
GO


DROP TABLE [dbo].[FactResellerOrders]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactResellerOrders](
	[ProductKey] [int] NULL,
	[ResellerKey] [int] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[ExtendedAmount] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[OrderDate] [datetime] NULL
) ON [PRIMARY]

GO