CREATE TABLE [sub].[tblEmployer] (
    [EmployerNumber]             VARCHAR (6)   NOT NULL,
    [EmployerName]               VARCHAR (100) NULL,
    [Email]                      VARCHAR (254) NULL,
    [IBAN]                       VARCHAR (34)  NULL,
    [Ascription]                 VARCHAR (100) NULL,
    [CoC]                        VARCHAR (11)  NULL,
    [Phone]                      VARCHAR (100) NULL,
    [BusinessAddressStreet]      VARCHAR (100) NULL,
    [BusinessAddressHousenumber] VARCHAR (20)  NULL,
    [BusinessAddressZipcode]     VARCHAR (10)  NULL,
    [BusinessAddressCity]        VARCHAR (100) NULL,
    [BusinessAddressCountrycode] VARCHAR (2)   NULL,
    [PostalAddressStreet]        VARCHAR (100) NULL,
    [PostalAddressHousenumber]   VARCHAR (20)  NULL,
    [PostalAddressZipcode]       VARCHAR (10)  NULL,
    [PostalAddressCity]          VARCHAR (100) NULL,
    [PostalAddressCountrycode]   VARCHAR (2)   NULL,
    [StartDateMembership]        DATE          NULL,
    [EndDateMembership]          DATE          NULL,
    [TerminationReason]          VARCHAR (4)   NULL,
    [SearchName]                 VARCHAR (100) NULL,
    CONSTRAINT [PK_sub_tblEmployer] PRIMARY KEY CLUSTERED ([EmployerNumber] ASC)
);


GO
CREATE TRIGGER [sub].[trgEmployer_Upd_Search] ON [sub].[tblEmployer]
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
	INNER JOIN sub.tblDeclaration decl 
			ON	decl.DeclarationID = decls.DeclarationID
	INNER JOIN inserted i 
			ON	i.EmployerNumber = decl.EmployerNumber
	WHERE	decls.DateChanged IS NULL
END	

/*	== sub.trg_trgEmployer_Upd_Search ========================================================	*/

