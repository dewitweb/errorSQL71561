CREATE TABLE [sub].[tblEducation] (
    [EducationID]     INT           NOT NULL,
    [EducationName]   VARCHAR (200) NULL,
    [EducationType]   VARCHAR (24)  NOT NULL,
    [EducationLevel]  VARCHAR (24)  NULL,
    [StartDate]       DATE          NULL,
    [LatestStartDate] DATE          NULL,
    [EndDate]         DATE          NULL,
    [Duration]        INT           NULL,
    [SearchName]      VARCHAR (255) NULL,
    [IsNotEligible]   BIT           CONSTRAINT [DF_sub_tblEducation_IsNotEligible] DEFAULT ((0)) NOT NULL,
    [NominalDuration] INT           NULL,
    CONSTRAINT [PK_sub_tblEducation] PRIMARY KEY CLUSTERED ([EducationID] ASC)
);


GO
CREATE TRIGGER [sub].[trgEducation_Upd_Search] ON [sub].[tblEducation]
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
	INNER JOIN stip.tblDeclaration decl 
			ON	decl.DeclarationID = decls.DeclarationID
	INNER JOIN inserted i 
			ON	i.EducationID = decl.EducationID
	WHERE	decls.DateChanged IS NULL
END	

/*	== sub.trg_trgEducation_Upd_Search =======================================================	*/

