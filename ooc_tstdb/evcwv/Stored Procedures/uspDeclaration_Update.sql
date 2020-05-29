CREATE PROCEDURE [evcwv].[uspDeclaration_Update]
@DeclarationID				int,
@EmployerNumber				varchar(6),
@DeclarationDate			datetime,
@InstituteID				int,
@IntakeDate					date,
@CertificationDate			date,
@DeclarationAmount			decimal(9,4),
@Partition					xml,
@MentorCode					varchar(4),
@ParticipantID				int,
@OutflowPossibility			varchar(4),
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose: 	Update evcwv.tblDeclaration on basis of DeclarationID.

	14-10-2019	Sander van Houten		OTIBSUB-1618	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @SubsidySchemeID int = 5
 
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

	EXEC evcwv.uspDeclaration_Upd @DeclarationID, @MentorCode, @ParticipantID, @OutflowPossibility

	COMMIT TRANSACTION
END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION

	--		RAISERROR ('%s',16, 1, @variable_containing_error)
END CATCH

SELECT DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== evcwv.uspDeclaration_Update ============================================================	*/
