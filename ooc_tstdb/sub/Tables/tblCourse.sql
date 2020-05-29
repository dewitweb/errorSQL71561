CREATE TABLE [sub].[tblCourse] (
    [CourseID]             INT             NOT NULL,
    [InstituteID]          INT             NOT NULL,
    [CourseName]           VARCHAR (200)   NULL,
    [FollowedUpByCourseID] INT             NULL,
    [CourseCosts]          DECIMAL (19, 4) NULL,
    [ClusterNumber]        VARCHAR (11)    NULL,
    [SearchName]           VARCHAR (255)   NULL,
    [IsNotEligible]        BIT             CONSTRAINT [DF_sub_tblCourse_IsNotEligible] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_sub_tblCourse] PRIMARY KEY CLUSTERED ([CourseID] ASC),
    CONSTRAINT [FK_sub_tblCourse_tblInstitute] FOREIGN KEY ([InstituteID]) REFERENCES [sub].[tblInstitute] ([InstituteID])
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblCourse_InstituteID]
    ON [sub].[tblCourse]([InstituteID] ASC, [FollowedUpByCourseID] ASC);


GO
CREATE TRIGGER [sub].[trgCourse_Upd_Search] ON [sub].[tblCourse]
AFTER INSERT, UPDATE
AS
/*	==========================================================================================
	Purpose:	Generate a record for creating a SearchString for Declaration_List

	16-09-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

IF UPDATE (SearchName)
BEGIN
	UPDATE	decls
	SET		decls.DateChanged = GETDATE()
	FROM	sub.tblDeclaration_Search decls
	INNER JOIN osr.tblDeclaration decl 
			ON	decl.DeclarationID = decls.DeclarationID
	INNER JOIN inserted i 
			ON	i.CourseID = decl.CourseID
	WHERE	decls.DateChanged IS NULL
END	

/*	== sub.trg_trgCourse_Upd_Search ==========================================================	*/

