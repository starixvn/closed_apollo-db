 USE [TransDB]
 GO

 ---- Create Filegroup

 ALTER DATABASE TRANSDB
ADD FILEGROUP [AgentCredit] 
GO
ALTER DATABASE TRANSDB
ADD FILE
(
 NAME = N'AgentCredit', 
 FILENAME = N'E:\APL_DB\TransDB\AgentCredit.ndf' , 
 SIZE = 5120KB , 
 MAXSIZE = UNLIMITED, 
 FILEGROWTH = 1MB)
TO FILEGROUP  [AgentCredit]
GO 



 ---- Create Table 
 CREATE TABLE [dbo].[CreditBalance_Agent](
	[AgentId] [int] NOT NULL,
	[Balance] [money] NULL,
 CONSTRAINT [PK_CreditBalance_Agent] PRIMARY KEY NONCLUSTERED 
(
	[AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AgentCredit]
) ON [AgentCredit]

GO


CREATE TABLE [dbo].[CreditTrans](
	[TransId] [bigint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
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
 CONSTRAINT [PK_CreditTrans] PRIMARY KEY NONCLUSTERED 
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AgentCredit]
) ON [AgentCredit]

GO


---------------------------------------
 

CREATE TABLE [dbo].[BalanceCreditTrans](
	[AgentId] [int] NOT NULL,
	[WinlostDate] [DATE] NOT NULL ,
	[Amount] [money] NOT NULL,	
	[Username] [nvarchar](30) NULL,
	[TicketCount] [int] NULL
) ON [Balance]

GO

ALTER TABLE [dbo].[BalanceCreditTrans] ADD  CONSTRAINT [DF_BalanceCreditTrans_agentid]  DEFAULT ((0)) FOR [AgentId]
GO

ALTER TABLE [dbo].[BalanceCreditTrans] ADD  CONSTRAINT [DF_BalanceCreditTrans_amount]  DEFAULT ((0)) FOR [Amount]
GO
 

 
/****** Object:  Index [CIX_AgentId]    Script Date: 11/24/2014 10:28:02 AM ******/
CREATE CLUSTERED INDEX [CIX_AgentId] ON [dbo].[CreditTrans]
(
	[AgentId] ASC,
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AgentCredit]
GO

/****** Object:  Index [IX_RefNo]    Script Date: 11/24/2014 10:28:10 AM ******/
CREATE NONCLUSTERED INDEX [IX_RefNo] ON [dbo].[CreditTrans]
(
	[RefNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AgentCredit]
GO


