﻿CREATE TABLE [evcwv].[tblParticipant] (
    [ParticipantID]  INT           IDENTITY (1, 1) NOT NULL,
    [EmployerNumber] VARCHAR (6)   NULL,
    [EmployeeNumber] VARCHAR (8)   NULL,
    [CRMID]          INT           NULL,
    [Initials]       VARCHAR (10)  NULL,
    [Amidst]         VARCHAR (20)  NULL,
    [Surname]        VARCHAR (100) NULL,
    [Gender]         VARCHAR (1)   NULL,
    [Phone]          VARCHAR (20)  NULL,
    [Email]          VARCHAR (254) NULL,
    [DateOfBirth]    DATE          NULL,
    [FunctionCode]   VARCHAR (4)   NULL,
    [SearchName]     VARCHAR (255) NULL,
    [FullName]       AS            (case when [EmployeeNumber] IS NULL then rtrim((((isnull([Surname],'')+', ')+isnull([Initials],''))+' ')+isnull([Amidst],''))  end) PERSISTED,
    CONSTRAINT [PK_evcwv_tblParticipant] PRIMARY KEY CLUSTERED ([ParticipantID] ASC)
);
