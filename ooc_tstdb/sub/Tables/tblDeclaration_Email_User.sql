CREATE TABLE [sub].[tblDeclaration_Email_User] (
    [EmailID]     INT      NOT NULL,
    [UserID]      INT      NOT NULL,
    [HandledDate] DATETIME CONSTRAINT [DF_sub_tblDeclaration_Email_User_HandledDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Email_User] PRIMARY KEY CLUSTERED ([EmailID] ASC, [UserID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Email_User_tblDeclaration_Email] FOREIGN KEY ([EmailID]) REFERENCES [sub].[tblDeclaration_Email] ([EmailID])
);

