

CREATE PROCEDURE [evc].[uspDeclaration_Update]
@DeclarationID				int,
@EmployerNumber				varchar(6),
@DeclarationDate			datetime,
@InstituteID				int,
@IntakeDate					date,
@CertificationDate			date,
@DeclarationAmount			decimal(9,4),
@Partition					xml,
@QualificationLevel			varchar(4),
@MentorCode					varchar(4),
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose: 	Update evc.tblDeclaration on basis of DeclarationID.

	30-09-2019	Sander van Houten		OTIBSUB-1598	Added transaction.
	07-11-2018 Jaap van Assenbergh		OTIBSUB-416		Parameters verwijderen uit subDeclaration_Upd
											- DeclarationStatus
											- StatusReason
											- InternalMemo
	02-11-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @SubsidySchemeID int = 3
 
DECLARE @Declaration TABLE (DeclarationID int)

BEGIN TRY
BEGIN TRANSACTION
	INSERT INTO @Declaration
	EXEC sub.uspDeclaration_upd
		@DeclarationID,
		@EmployerNumber,
		@SubsidySchemeID,
		@DeclarationDate,
		@InstituteID,
		@IntakeDate,
		@CertificationDate,
		@DeclarationAmount,
		@Partition,
		@CurrentUserID

	SELECT	@DeclarationID = DeclarationID 
	FROM	@Declaration

	EXEC evc.uspDeclaration_Upd @DeclarationID, @QualificationLevel, @MentorCode

	COMMIT TRANSACTION
END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION

	--		RAISERROR ('%s',16, 1, @variable_containing_error)
END CATCH

SELECT DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== evc.uspDeclaration_Update ==============================================================	*/
