
IF NOT EXISTS(SELECT * FROM LMS_POINTSECTION WHERE POINTSECTION_FOR='Watch')
BEGIN
	INSERT [dbo].[LMS_POINTSECTION] ([POINTSECTION_ID], [POINTSECTION_FOR], [CREATEDBY], [CREATEDON], [UPDATEDBY], [UPDATEDON]) 
	VALUES (1, N'Watch', NULL, NULL, NULL, NULL)
END
GO
IF NOT EXISTS(SELECT * FROM LMS_POINTSECTION WHERE POINTSECTION_FOR='Like')
BEGIN
	INSERT [dbo].[LMS_POINTSECTION] ([POINTSECTION_ID], [POINTSECTION_FOR], [CREATEDBY], [CREATEDON], [UPDATEDBY], [UPDATEDON]) 
	VALUES (2, N'Like', NULL, NULL, NULL, NULL)
END
GO
IF NOT EXISTS(SELECT * FROM LMS_POINTSECTION WHERE POINTSECTION_FOR='Comments')
BEGIN
	INSERT [dbo].[LMS_POINTSECTION] ([POINTSECTION_ID], [POINTSECTION_FOR], [CREATEDBY], [CREATEDON], [UPDATEDBY], [UPDATEDON]) 
	VALUES (3, N'Comments', NULL, NULL, NULL, NULL)
END
GO
IF NOT EXISTS(SELECT * FROM LMS_POINTSECTION WHERE POINTSECTION_FOR='Share')
BEGIN
	INSERT [dbo].[LMS_POINTSECTION] ([POINTSECTION_ID], [POINTSECTION_FOR], [CREATEDBY], [CREATEDON], [UPDATEDBY], [UPDATEDON]) 
	VALUES (4, N'Share', NULL, NULL, NULL, NULL)
END
GO




IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'LMS_QUESTIONS') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[LMS_QUESTIONS](
        [QUESTIONS_ID] [bigint] NOT NULL,
        [QUESTIONS_NAME] NVARCHAR(500) NULL,
        [QUESTIONS_DESCRIPTN] NVARCHAR(1000)NULL,       
        [CREATEDBY] [bigint] NULL,
        [CREATEDON] [datetime] NULL,
        [UPDATEDBY] [bigint] NULL,
        [UPDATEDON] [datetime] NULL,
 CONSTRAINT [PK_LMS_QUESTIONS] PRIMARY KEY CLUSTERED 
(
        [QUESTIONS_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO

--drop table LMS_QUESTIONSOPTIONS

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'LMS_QUESTIONSOPTIONS') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[LMS_QUESTIONSOPTIONS](
        [QUESTIONS_OPTIONSID] [bigint] NOT NULL,
		[QUESTIONS_ID] [bigint] NOT NULL,
        [OPTIONS_NUMBER1] NVARCHAR(500) NULL,
		[OPTIONS_POINT1] [bigint] NULL,	
		[OPTIONS_CORRECT1] bit DEFAULT ((0)) NULL,
        [OPTIONS_NUMBER2] NVARCHAR(500) NULL,
		[OPTIONS_POINT2] [bigint] NULL,
		[OPTIONS_CORRECT2] bit DEFAULT ((0)) NULL,
		[OPTIONS_NUMBER3] NVARCHAR(500) NULL,
		[OPTIONS_POINT3] [bigint] NULL,
		[OPTIONS_CORRECT3] bit DEFAULT ((0)) NULL,
		[OPTIONS_NUMBER4] NVARCHAR(500) NULL,
		[OPTIONS_POINT4] [bigint] NULL,
		[OPTIONS_CORRECT4] bit DEFAULT ((0)) NULL,	
        [CREATEDBY] [bigint] NULL,
        [CREATEDON] [datetime] NULL,
        [UPDATEDBY] [bigint] NULL,
        [UPDATEDON] [datetime] NULL,
 CONSTRAINT [PK_LMS_QUESTIONSOPTIONS] PRIMARY KEY CLUSTERED 
(
        [QUESTIONS_OPTIONSID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO




IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'LMS_QUESTIONS_TOPICMAP') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[LMS_QUESTIONS_TOPICMAP](
        [QUESTIONS_TOPICMAP_ID] [bigint] NOT NULL,        
        [QUESTIONS_TOPICID] [bigint] NULL, 
		[QUESTIONS_ID] [bigint] NULL, 
        [CREATEDBY] [bigint] NULL,
        [CREATEDON] [datetime] NULL,
        [UPDATEDBY] [bigint] NULL,
        [UPDATEDON] [datetime] NULL,
 CONSTRAINT [PK_LMS_QUESTIONS_TOPICMAP] PRIMARY KEY CLUSTERED 
(
        [QUESTIONS_TOPICMAP_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'LMS_QUESTIONS_CATEGORYMAP') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[LMS_QUESTIONS_CATEGORYMAP](
        [QUESTIONS_CATEGORYMAP_ID] [bigint] NOT NULL,
        [QUESTIONS_CATEGORYID] [bigint] NULL,  
		[QUESTIONS_ID] [bigint] NULL, 
        [CREATEDBY] [bigint] NULL,
        [CREATEDON] [datetime] NULL,
        [UPDATEDBY] [bigint] NULL,
        [UPDATEDON] [datetime] NULL,
 CONSTRAINT [PK_LMS_QUESTIONS_CATEGORYMAP] PRIMARY KEY CLUSTERED 
(
        [QUESTIONS_CATEGORYMAP_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO







IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'LMS_POINTSETUP') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[LMS_POINTSETUP](
        [POINTSETUPID] [bigint] NOT NULL,
        [POINTSECTION] [bigint] NULL,
        [POINTS] NUMERIC(18,5) NULL,
        [POINTSETUPSTATUS] [bit] DEFAULT ((1)) NULL,
        [CREATEDBY] [bigint] NULL,
        [CREATEDON] [datetime] NULL,
        [UPDATEDBY] [bigint] NULL,
        [UPDATEDON] [datetime] NULL,
 CONSTRAINT [PK_LMS_POINTSETUP] PRIMARY KEY CLUSTERED 
(
        [POINTSETUPID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'LMS_POINTSECTION') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[LMS_POINTSECTION](
        [POINTSECTION_ID] [bigint] NOT NULL,
        [POINTSECTION_FOR] NVARCHAR(200) NULL,       
        [CREATEDBY] [bigint] NULL,
        [CREATEDON] [datetime] NULL,
        [UPDATEDBY] [bigint] NULL,
        [UPDATEDON] [datetime] NULL,
 CONSTRAINT [PK_LMS_POINTSECTION] PRIMARY KEY CLUSTERED 
(
        [POINTSECTION_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'LMS_CATEGORY') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[LMS_CATEGORY](
        [CATEGORYID] [bigint] NOT NULL,
        [CATEGORYNAME] [nvarchar](250) NULL,
        [CATEGORYDESCRIPTION] [nvarchar](500) NULL,
        [CATEGORYSTATUS] [bit] DEFAULT ((1)) NULL,
        [CREATEDBY] [bigint] NULL,
        [CREATEDON] [datetime] NULL,
        [UPDATEDBY] [bigint] NULL,
        [UPDATEDON] [datetime] NULL,
 CONSTRAINT [PK_LMS_CATEGORY] PRIMARY KEY CLUSTERED 
(
        [CATEGORYID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO


update tbl_trans_menu set mnu_image='lnr lnr-book' WHERE [mnu_menuLink]=''  AND mnu_menuName='LMS'


IF NOT EXISTS(SELECT * FROM [tbl_trans_menu] WHERE [mnu_menuLink]=''  AND mnu_menuName='LMS')
BEGIN
        INSERT INTO [tbl_trans_menu]([mnu_menuName], [mnu_menuLink], [mun_parentId], [mnu_segmentId], [mnu_image], [mnu_HaveSubMenu], [mnu_HotKey], [RightsToCheck], [OrderNumber], 
		[mnu_menuPrefix], [isInDtop], [mnu_unique_id]) 
        VALUES('LMS', '', 0, 1, 'lnr lnr-book', 'N', NULL, '1,2,3,4,13', 1, 'LMS', NULL, NULL);               
END
GO


IF NOT EXISTS(SELECT * FROM [tbl_trans_menu] WHERE [mnu_menuLink]=''  AND mnu_menuName='MASTERS' and mnu_menuPrefix='LMS')
BEGIN
        INSERT INTO [tbl_trans_menu]([mnu_menuName], [mnu_menuLink], [mun_parentId], [mnu_segmentId], [mnu_image], [mnu_HaveSubMenu], [mnu_HotKey], [RightsToCheck], [OrderNumber], 
		[mnu_menuPrefix], [isInDtop], [mnu_unique_id]) 
        VALUES('MASTERS', '', (SELECT mnu_id FROM [tbl_trans_menu] WHERE [mnu_menuLink]='' AND mnu_menuName='LMS'), 1, '', 'N', NULL, '1,2,3,4,13', 1, 'LMS', NULL, NULL);
END
GO






IF NOT EXISTS(SELECT * FROM [tbl_trans_menu] WHERE [mnu_menuLink]='/LMSCategory/Index'  AND mnu_menuName='Category'  and mnu_menuPrefix='LMS')
BEGIN
        INSERT INTO [tbl_trans_menu]([mnu_menuName], [mnu_menuLink], [mun_parentId], [mnu_segmentId], [mnu_image], [mnu_HaveSubMenu], [mnu_HotKey], [RightsToCheck], [OrderNumber], 
		[mnu_menuPrefix], [isInDtop], [mnu_unique_id]) 
        VALUES('Category', '/LMSCategory/Index', (SELECT mnu_id FROM [tbl_trans_menu] WHERE [mnu_menuLink]='' AND mnu_menuName='MASTERS'and mnu_menuPrefix='LMS'), 1, '', 'N', NULL, '1,2,3,4,13', 1, 'LMS', NULL, 'LMS_CATEGORY');
END
GO

IF NOT EXISTS(SELECT * FROM [tbl_trans_menu] WHERE [mnu_menuLink]='/LMSPoint/Index'  AND mnu_menuName='Point Setup'  and mnu_menuPrefix='LMS')
BEGIN
        INSERT INTO [tbl_trans_menu]([mnu_menuName], [mnu_menuLink], [mun_parentId], [mnu_segmentId], [mnu_image], [mnu_HaveSubMenu], [mnu_HotKey], [RightsToCheck], [OrderNumber], 
		[mnu_menuPrefix], [isInDtop], [mnu_unique_id]) 
        VALUES('Point Setup', '/LMSPoint/Index', (SELECT mnu_id FROM [tbl_trans_menu] WHERE [mnu_menuLink]='' AND mnu_menuName='MASTERS'and mnu_menuPrefix='LMS'), 1, '', 'N', NULL, '1,2,3,4,13', 3, 'LMS', NULL, 'LMS_PointSetup');
END
GO


IF NOT EXISTS(SELECT * FROM [tbl_trans_menu] WHERE [mnu_menuLink]='/LMSQuestions/Index'  AND mnu_menuName='Question'  and mnu_menuPrefix='LMS')
BEGIN
        INSERT INTO [tbl_trans_menu]([mnu_menuName], [mnu_menuLink], [mun_parentId], [mnu_segmentId], [mnu_image], [mnu_HaveSubMenu], [mnu_HotKey], [RightsToCheck], [OrderNumber], 
		[mnu_menuPrefix], [isInDtop], [mnu_unique_id]) 
        VALUES('Question', '/LMSQuestions/Index', (SELECT mnu_id FROM [tbl_trans_menu] WHERE [mnu_menuLink]='' AND mnu_menuName='MASTERS'and mnu_menuPrefix='LMS'), 1, '', 'N', NULL, '1,2,3,4,13', 4, 'LMS', NULL, 'LMS_Question');
END
GO

