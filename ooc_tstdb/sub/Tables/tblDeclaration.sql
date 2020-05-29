CREATE TABLE [sub].[tblDeclaration] (
    [DeclarationID]     INT             IDENTITY (1, 1) NOT NULL,
    [EmployerNumber]    VARCHAR (6)     NOT NULL,
    [SubsidySchemeID]   INT             NOT NULL,
    [DeclarationDate]   DATETIME        CONSTRAINT [DF_sub_tblDeclaration_DeclarationDate] DEFAULT (getdate()) NOT NULL,
    [InstituteID]       INT             NULL,
    [StartDate]         DATE            NULL,
    [EndDate]           DATE            NULL,
    [DeclarationAmount] DECIMAL (19, 4) NULL,
    [ApprovedAmount]    DECIMAL (19, 4) NULL,
    [DeclarationStatus] VARCHAR (4)     NOT NULL,
    [StatusReason]      VARCHAR (MAX)   NULL,
    [InternalMemo]      VARCHAR (MAX)   NULL,
    CONSTRAINT [PK_sub_tblDeclaration] PRIMARY KEY CLUSTERED ([DeclarationID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_tblEmployer] FOREIGN KEY ([EmployerNumber]) REFERENCES [sub].[tblEmployer] ([EmployerNumber]),
    CONSTRAINT [FK_sub_tblDeclaration_tblInstitute] FOREIGN KEY ([InstituteID]) REFERENCES [sub].[tblInstitute] ([InstituteID]),
    CONSTRAINT [FK_sub_tblDeclaration_tblSubsidyScheme] FOREIGN KEY ([SubsidySchemeID]) REFERENCES [sub].[tblSubsidyScheme] ([SubsidySchemeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblDeclaration_SubsidiyScheme_Status]
    ON [sub].[tblDeclaration]([SubsidySchemeID] ASC, [DeclarationStatus] ASC)
    INCLUDE([EmployerNumber], [StartDate], [EndDate], [DeclarationAmount], [ApprovedAmount], [DeclarationDate]);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblDeclaration_EmployerNumber]
    ON [sub].[tblDeclaration]([EmployerNumber] ASC, [SubsidySchemeID] ASC, [DeclarationStatus] ASC);


GO
CREATE TRIGGER [sub].[trgDeclaration_Upd_Search] ON [sub].[tblDeclaration]
AFTER INSERT, UPDATE
AS
/*	==========================================================================================
	Purpose:	Generate a record for creating a SearchString for Declaration_List

	16-09-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

	UPDATE	decls
	SET		decls.DateChanged = GETDATE()
	FROM	sub.tblDeclaration_Search decls
	INNER JOIN inserted i ON i.DeclarationID = decls.DeclarationID

	INSERT	sub.tblDeclaration_Search (DeclarationID, DateChanged)
	SELECT	i.DeclarationID, GETDATE()
	FROM	inserted i
	LEFT JOIN sub.tblDeclaration_Search decls 
			ON decls.DeclarationID = i.DeclarationID
	WHERE	decls.DeclarationID IS NULL
	AND		decls.DateChanged IS NULL

/*	== sub.trgDeclaration_Upd_Search ========================================================	*/

