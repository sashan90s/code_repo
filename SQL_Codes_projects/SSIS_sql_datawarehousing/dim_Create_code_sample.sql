USE [AdventureworksDW2019]
GO

/****** Object:  Table [dbo].[DimProduct2     Script Date: 12/7/2018 10:52:14 AM ******/
IF OBJECT_ID(N'[dbo].[DimProduct2]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [dbo].[DimProduct2]
GO

/****** Object:  Table [dbo].[DimProduct2]    Script Date: 12/7/2018 10:52:14 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimProduct2](
	[ProductSK] [int] IDENTITY(1,1) NOT NULL,
	[ProductID] [int] NOT NULL,
	[ProductName] [nvarchar](50) NOT NULL,
	[Category] [nvarchar](50) NOT NULL,
	[Model] [nvarchar](50) NOT NULL,
	[StandardCost] [money] NOT NULL,
	[ListPrice] [money] NOT NULL,
	[DaysToManufacture] [int] NOT NULL,
	[SellStartDate] [datetime] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[ExpiryDate] [date] NULL,
 CONSTRAINT [PK_DimProduct2] PRIMARY KEY CLUSTERED 
(
	[ProductSK] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DimProduct2] ADD  CONSTRAINT [DF_DimProduct2_EffectiveDate]  DEFAULT (getdate()) FOR [EffectiveDate]
GO

ALTER TABLE [dbo].[DimProduct2] ADD  CONSTRAINT [DF_DimProduct2_ExpiryDate]  DEFAULT (NULL) FOR [ExpiryDate]
GO