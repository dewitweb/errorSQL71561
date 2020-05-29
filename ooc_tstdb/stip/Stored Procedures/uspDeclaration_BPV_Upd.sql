CREATE PROCEDURE [stip].[uspDeclaration_BPV_Upd]
@DeclarationID		int,
@StartDate			date,
@EndDate			date,
@Extension			bit,
@TerminationReason	varchar(20),
@TypeBPV            varchar(10),
@EmployerNumber     varchar(6),
@CourseID           int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update stip.tblDeclaration_BPV on basis of DeclarationID.

	27-01-2020	Sander van Houten	OTIBSUB-1852	Added BPV EmployerNumber and CourseID to 
                                        stip.Declaration_BPV.
	24-01-2020	Sander van Houten	OTIBSUB-1730	Added TypeBPV.
	12-06-2019	Sander van Houten	OTIBSUB-1148	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(DeclarationID)
	FROM	stip.tblDeclaration_BPV
	WHERE	DeclarationID = @DeclarationID) = 0
BEGIN
	-- Add new record
	INSERT INTO stip.tblDeclaration_BPV
		(
			DeclarationID,
			StartDate_BPV,
			EndDate_BPV,
			Extension,
			TerminationReason,
            TypeBPV,
            EmployerNumber,
            CourseID
		)
	VALUES
		(
			@DeclarationID,
			@StartDate,
			@EndDate,
			@Extension,
			@TerminationReason,
            @TypeBPV,
            @EmployerNumber,
            @CourseID
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	stip.tblDeclaration_BPV
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	stip.tblDeclaration_BPV
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	stip.tblDeclaration_BPV
	SET
			StartDate_BPV		= @StartDate,
			EndDate_BPV			= @EndDate,
			Extension			= @Extension,
			TerminationReason	= @TerminationReason,
            TypeBPV             = @TypeBPV
	WHERE	DeclarationID = @DeclarationID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	stip.tblDeclaration_BPV
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'stip.tblDeclaration_BPV',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_BPV_Upd ===========================================================	*/
