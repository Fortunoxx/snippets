USE [Utilities]
GO

/****** Object:  Table [dbo].[MyKeyTypes]    Script Date: 17.05.2021 20:31:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MyKeyTypes](
	[KeyTypeId] [int] IDENTITY(1,1) NOT NULL,
	[ShortName] [varchar](16) NOT NULL,
	[Description] [nvarchar](256) NOT NULL,
	[HasKey2] [bit] NOT NULL,
	[HasKey3] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[KeyTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[MyKeyTypes] ADD  CONSTRAINT [DF_MyKeyTypes_HasKey2]  DEFAULT ((0)) FOR [HasKey2]
GO

ALTER TABLE [dbo].[MyKeyTypes] ADD  CONSTRAINT [DF_MyKeyTypes_HasKey3]  DEFAULT ((0)) FOR [HasKey3]
GO

USE [Utilities]
GO

/****** Object:  Table [dbo].[MyKeys2]    Script Date: 17.05.2021 20:43:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MyKeys2](
	[KeyId] [int] IDENTITY(1,1) NOT NULL,
	[KeyTypeId] [int] NOT NULL,
	[KeyValue] [nvarchar](256) NOT NULL,
	[ParentKeyId] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[KeyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [NCI_UQ_Type_Value_Parent]    Script Date: 17.05.2021 20:43:05 ******/
CREATE UNIQUE NONCLUSTERED INDEX [NCI_UQ_Type_Value_Parent] ON [dbo].[MyKeys2]
(
	[KeyTypeId] ASC,
	[KeyValue] ASC,
	[ParentKeyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[MyKeys2]  WITH CHECK ADD  CONSTRAINT [FK_MyKeys2_MyKeys2] FOREIGN KEY([ParentKeyId])
REFERENCES [dbo].[MyKeys2] ([KeyId])
GO

ALTER TABLE [dbo].[MyKeys2] CHECK CONSTRAINT [FK_MyKeys2_MyKeys2]
GO

ALTER TABLE [dbo].[MyKeys2]  WITH CHECK ADD  CONSTRAINT [FK_MyKeys2_MyKeyTypes] FOREIGN KEY([KeyTypeId])
REFERENCES [dbo].[MyKeyTypes] ([KeyTypeId])
GO

ALTER TABLE [dbo].[MyKeys2] CHECK CONSTRAINT [FK_MyKeys2_MyKeyTypes]
GO

/*
Seeds
*/

insert into MyKeyTypes(ShortName, Description)
values ('AG', 'Arbeitgeber'), ('EMAIL', 'E-Mail')

/*
Query for all keys of a certain type
*/

select mk2.KeyId, kt1.ShortName, mk1.KeyValue, kt2.ShortName, mk2.KeyValue, * 
from MyKeys2 mk1
join MyKeyTypes kt1 on kt1.KeyTypeId = mk1.KeyTypeId and kt1.ShortName = 'AG'
join MyKeys2 mk2 on mk2.ParentKeyId = mk1.KeyId
join MyKeyTypes kt2 on kt2.ShortName = 'EMAIL'
left join MyKeys2 mk3 on mk3.ParentKeyId = mk2.KeyId
where mk1.ParentKeyId is null
and mk3.KeyId is null -- keine weiteren childs
order by mk1.KeyValue, mk2.KeyValue


