CREATE PROCEDURE [sub].[uspDeclaration_List_Payment_Export]
@SearchString		varchar(max),
@SubsidySchemeID 	sub.uttSubsidySchemeID READONLY,
@EmployerNumber		varchar(6),
@PeriodFrom			date,
@PeriodTo			date,
@CurrentUserID		int,
@FileType			varchar(4)
AS
/*	==========================================================================================
	Purpose:	List declaration and payments for export.

	13-05-2019	Sander van Houten		OTIBSUB-1063	Added EmployeeNumber.
	06-05-2019	Sander van Houten		OTIBSUB-1045	Added logging to his.tblHistory.
	03-05-2019	Sander van Houten		OTIBSUB-1031	Added JournalEntryCode to resultset.
	02-05-2019	Sander van Houten		OTIBSUB-1019	Incorrect AmountPayment per employee.
	02-11-2018	Sander van Houten		OTIBSUB-386		Uitbreiden export betalingsoverzicht 
											met EVC kolommen.
	30-10-2018	Jaap van Assenbergh		OTIBSUB-385		Overzichten - filter op subsidieregeling.
										Multiple subsidy schemes possible.
										Userdefined Table Type.
	04-09-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata 
DECLARE	@SearchString		varchar(max) = N'',
		@SubsidySchemeID	sub.uttSubsidySchemeID,
		@EmployerNumber		varchar(6) = '009524',
		@PeriodFrom			date = NULL,
		@PeriodTo			date = NULL,

INSERT INTO @SubsidySchemeID
VALUES (1), (3)

*/

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(100)

DECLARE @OriginalFileName	varchar(max),
		@UploadDateTime		datetime

/*	Declare table variable for output of sub.uspDeclaration_List.	*/
DECLARE @Declaration_List_Payment_Export AS TABLE
	(
		PaymentDate					date,			
		DeclarationID				int,
		SpecificationSequence		int,
		SubsidySchemeID				int,
		SubsidySchemeName			varchar(50),
		EmployerNumber				varchar(6),
		DeclarationDate				datetime,
		CourseName					varchar(200),
		DeclarationStatus			varchar(4),
		StartDate					date,
		EndDate						date,
		DeclarationAmount			decimal(19, 4),
		CanDownloadSpecification	bit,
		AmountPayment				decimal(19, 4),
		JournalEntryCode			int
	)

/*	Declare table variable for number of employees per declaration.	*/
DECLARE @Declaration_EmployeeCount AS TABLE
	(
		DeclarationID	int,
		EmployeeCount	int
	)

SELECT	@SearchString		= ISNULL(@SearchString, ''),
		@Employernumber		= ISNULL(@Employernumber, '')

INSERT INTO @Declaration_List_Payment_Export
EXEC	sub.uspDeclaration_List_Payment 
		@SearchString = @SearchString,
		@SubsidySchemeID = @SubsidySchemeID,
		@Employernumber = @EmployerNumber,
		@PeriodFrom = @PeriodFrom,
		@PeriodTo = @PeriodTo,
		@CountOfPayment = NULL,
		@AmountPayment = NULL

/*	Get number of employees with selected declarations.	*/
INSERT INTO @Declaration_EmployeeCount
	(
		DeclarationID,
		EmployeeCount
	)
SELECT 
		dlpe.DeclarationID,
		COUNT(DISTINCT de.EmployeeNumber)	AS EmployeeCount
FROM	@Declaration_List_Payment_Export dlpe
INNER JOIN	sub.tblDeclaration_Employee de ON de.DeclarationID = dlpe.DeclarationID
GROUP BY
		dlpe.DeclarationID

/*	Log the download action.	*/
SET @KeyID = @Employernumber

SELECT	@XMLdel = CAST('<download>1</download>' AS xml),
		@XMLins = CAST('<row><FileName>Betalingsoverzicht</FileName><EmployerNumber>' + 
					@Employernumber + '</EmployerNumber><PeriodFrom>' + 
					CAST(ISNULL(@PeriodFrom, '') AS varchar(10)) + '</PeriodFrom><PeriodTo>' +
					CAST(ISNULL(@PeriodTo, '')  AS varchar(10)) + '</PeriodTo><FileType>' +
					@FileType + '</FileType></row>' AS xml)

EXEC his.uspHistory_Add
		'sub.Declaration_List_Payment',
		@KeyID,
		@CurrentUserID,
		@LogDate,
		@XMLdel,
		@XMLins

/*	Give back result.	*/
	SELECT	
			dlpe.SubsidySchemeID,
			dlpe.DeclarationID,
			dlpe.JournalEntryCode,
			dlpe.PaymentDate,
			dlpe.EmployerNumber,
			dlpe.DeclarationDate,
			e.EmployeeNumber,
			e.FullName								AS EmployeeName,
			dlpe.CourseName,
			dlpe.StartDate,
			dlpe.EndDate,
			dlpe.DeclarationStatus,
			dlpe.DeclarationAmount,
			dlpe.CanDownloadSpecification,
			dlpe.AmountPayment / ec.EmployeeCount	AS AmountPayment,
			evc.IntakeDate,
			evc.CertificationDate,
			evc.MentorCode,
			evc.QualificationLevel,
			CASE ISNULL(ssi.InstituteID, 0) 
				WHEN 0 THEN 0
				ELSE 1 
			END										AS EVCProvider
	FROM	@Declaration_List_Payment_Export dlpe
	INNER JOIN	sub.tblDeclaration_Employee de ON de.DeclarationID = dlpe.DeclarationID
	INNER JOIN	sub.tblEmployee e ON e.EmployeeNumber = de.EmployeeNumber
	INNER JOIN  @Declaration_EmployeeCount ec ON ec.DeclarationID = dlpe.DeclarationID
	LEFT JOIN	evc.viewDeclaration evc ON evc.DeclarationID = dlpe.DeclarationID
	LEFT JOIN	sub.tblSubsidyScheme_Institute ssi ON ssi.SubsidySchemeID = dlpe.SubsidySchemeID
													AND ssi.InstituteID = evc.InstituteID
	ORDER BY 
			dlpe.SubsidySchemeID,
			dlpe.PaymentDate,
			dlpe.DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_List_Payment_Export ===================================================	*/
