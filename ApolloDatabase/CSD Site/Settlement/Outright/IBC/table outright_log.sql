/****** Object:  Table [dbo].[match_log]    Script Date: 7/11/2013 9:55:42 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[outright_log](
	[LogId] [bigint] IDENTITY(1,1) NOT NULL,
	[orid] [int] NOT NULL,
	[ActionId] [tinyint] NOT NULL,
	[status] nvarchar(10) NULL,	
	deadheat float NULL,	
	[LogTime] [datetime] NOT NULL,
	[IsSettled] [bit] NOT NULL	
CONSTRAINT [PK_outright_log] PRIMARY KEY NONCLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Event_Index]
) ON [event_table]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Index [[CIX_orid]]    Script Date: 7/11/2013 9:55:42 AM ******/
CREATE CLUSTERED INDEX [CIX_orid] ON [dbo].[outright_log]
(
	[orid] ASC,
	LogID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [event_table]
GO

ALTER TABLE [dbo].[outright_log] ADD  CONSTRAINT [DF_outright_log_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO

ALTER TABLE [dbo].[outright_log] ADD  CONSTRAINT [DF_outright_log_IsSettled]  DEFAULT ((0)) FOR [IsSettled]
GO



