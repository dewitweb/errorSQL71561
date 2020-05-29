CREATE TABLE [eml].[tblEmail] (
    [EmailID]               INT            IDENTITY (1, 1) NOT NULL,
    [EmailHeaders]          XML            NOT NULL,
    [EmailTemplateFileName] VARCHAR (1024) NULL,
    [EmailBody]             VARCHAR (MAX)  NOT NULL,
    [EmailSignature]        VARCHAR (1024) NULL,
    [EmailFooter]           VARCHAR (1024) NULL,
    [CreationDate]          DATETIME       CONSTRAINT [DF_tblEmail_CreationDate] DEFAULT (getdate()) NOT NULL,
    [SentDate]              DATETIME       NULL,
    [RetryCount]            TINYINT        CONSTRAINT [DF_tblEmail_RetryCount] DEFAULT ((0)) NOT NULL,
    [SendLog]               VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_eml_tblEmail] PRIMARY KEY CLUSTERED ([EmailID] ASC)
);

