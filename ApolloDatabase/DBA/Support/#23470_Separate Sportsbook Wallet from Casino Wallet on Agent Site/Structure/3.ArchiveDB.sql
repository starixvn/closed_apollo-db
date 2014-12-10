 USE ArchiveDB
 GO

 ---- Create Filegroup

 ALTER DATABASE ArchiveDB
ADD FILEGROUP [AgentCredit] 
GO
ALTER DATABASE ArchiveDB
ADD FILE
(
 NAME = N'AgentCredit', 
 FILENAME = N'E:\APL_DB\ArchiveDB\AgentCredit.ndf' , 
 SIZE = 5120KB , 
 MAXSIZE = UNLIMITED, 
 FILEGROWTH = 1MB)
TO FILEGROUP  [AgentCredit]
GO 


CREATE TABLE [dbo].[CreditTrans_BK](
	[TransId] [bigint] NOT NULL,
	[AgentId] [int] NULL,
	[CustId] [int] NULL,
	[TransDate] [datetime] NULL,
	[BalanceBefore] [money] NULL,
	[Amount] [money] NULL,
	[BetType] [smallint] NULL,
	[WinlostDate] [smalldatetime] NULL,
	[TransDesc] [nvarchar](300) NULL,
	[Username] [nvarchar](50) NULL,
	[RefNo] [bigint] NULL,
	[Creator] [int] NULL,
	[IP] [varchar](40) NULL,
 CONSTRAINT [PK_CreditTrans_BK] PRIMARY KEY NONCLUSTERED 
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AgentCredit]
) ON [AgentCredit]

GO

 

/****** Object:  Index [IX_AgentId]    Script Date: 11/24/2014 10:29:24 AM ******/
CREATE NONCLUSTERED INDEX [IX_AgentId] ON [dbo].[CreditTrans_BK]
(
	[AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AgentCredit]
GO

/****** Object:  Index [IX_RefNo]    Script Date: 11/24/2014 10:29:35 AM ******/
CREATE NONCLUSTERED INDEX [IX_RefNo] ON [dbo].[CreditTrans_BK]
(
	[RefNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AgentCredit]
GO



