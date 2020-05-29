CREATE TABLE [sub].[tblUser_Role_Employer] (
    [UserID]          INT           NOT NULL,
    [EmployerNumber]  VARCHAR (6)   NOT NULL,
    [RequestSend]     SMALLDATETIME CONSTRAINT [DF_sub_tblUser_Role_Employer_RequestSend] DEFAULT (getdate()) NULL,
    [RequestApproved] SMALLDATETIME NULL,
    [RequestDenied]   SMALLDATETIME NULL,
    [RoleID]          INT           NOT NULL,
    CONSTRAINT [PK_auth_tblUserRole] PRIMARY KEY CLUSTERED ([UserID] ASC, [EmployerNumber] ASC, [RoleID] ASC),
    CONSTRAINT [FK_sub_tblUser_Role_Employer_tblEmployer] FOREIGN KEY ([EmployerNumber]) REFERENCES [sub].[tblEmployer] ([EmployerNumber])
);

