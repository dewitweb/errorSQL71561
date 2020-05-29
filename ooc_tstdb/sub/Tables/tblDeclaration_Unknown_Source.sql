CREATE TABLE [sub].[tblDeclaration_Unknown_Source] (
    [DeclarationID]                INT           NOT NULL,
    [InstituteID]                  INT           NULL,
    [InstituteName]                VARCHAR (255) NULL,
    [CourseID]                     INT           NULL,
    [CourseName]                   VARCHAR (200) NULL,
    [SentToSourceSystemDate]       DATETIME      NULL,
    [ReceivedFromSourceSystemDate] DATETIME      NULL,
    [DeclarationAcceptedDate]      DATETIME      NULL,
    [NominalDuration]              INT           NULL,
    [EducationID]                  INT           NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Unknown_Source] PRIMARY KEY CLUSTERED ([DeclarationID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Unknown_Source_tblCourse] FOREIGN KEY ([CourseID]) REFERENCES [sub].[tblCourse] ([CourseID]),
    CONSTRAINT [FK_sub_tblDeclaration_Unknown_Source_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID]),
    CONSTRAINT [FK_sub_tblDeclaration_Unknown_Source_tblInstitute] FOREIGN KEY ([InstituteID]) REFERENCES [sub].[tblInstitute] ([InstituteID])
);


GO
CREATE TRIGGER [sub].[trgDeclaration_Unknown_Source_Upd_Search] ON [sub].[tblDeclaration_Unknown_Source]
AFTER INSERT, UPDATE
AS
/*	==========================================================================================
	Purpose:	Generate a record for creating a SearchString for Declaration_List

	16-09-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

IF UPDATE (CourseName)
 
BEGIN
	UPDATE	decls
	SET		decls.DateChanged = GETDATE()
	FROM	sub.tblDeclaration_Search decls
	INNER JOIN sub.tblDeclaration_Unknown_Source dus 
			ON	dus.DeclarationID = decls.DeclarationID
	WHERE	decls.DateChanged IS NULL
END	

/*	== sub.trgDeclaration_Unknown_Source_Upd_Search ==========================================	*/

