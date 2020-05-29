

CREATE PROCEDURE [evcwv].[uspParticipant_Upd]
@ParticipantID		int,
@EmployerNumber	varchar(6),
@EmployeeNumber	varchar(8),
@CRMID			int,
@Initials		varchar(10),
@Amidst			varchar(20),
@Surname		varchar(100),
@Gender			varchar(1),
@Phone			varchar(20),
@Email			varchar(254),
@DateOfBirth	date,
@FunctionCode	varchar(4),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update evcwv.tblParticipant on basis of ParticipantID.

	15-10-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

IF (
		SELECT	COUNT(ParticipantID)
		FROM	evcwv.tblParticipant 
		WHERE	ParticipantID = @ParticipantID

	) > 0
SELECT	@Initials		= NULL,
		@Amidst			= NULL,
		@Surname		= NULL,
		@Gender			= NULL,
		@DateOfBirth	= NULL

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@ParticipantID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO evcwv.tblParticipant
		(
			EmployerNumber,
			EmployeeNumber,
			CRMID,
			Initials,
			Amidst,
			Surname,
			Gender,
			Phone,
			Email,
			DateOfBirth,
			FunctionCode
		)
	VALUES
		(
			@EmployerNumber,
			@EmployeeNumber,
			@CRMID,
			@Initials,
			@Amidst,
			@Surname,
			@Gender,
			@Phone,
			@Email,
			@DateOfBirth,
			@FunctionCode
		)

	SET	@ParticipantID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	evcwv.tblParticipant
						WHERE	ParticipantID = @ParticipantID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	evcwv.tblParticipant
						WHERE	ParticipantID = @ParticipantID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	evcwv.tblParticipant
	SET
			EmployerNumber	= @EmployerNumber,
			EmployeeNumber	= @EmployeeNumber,
			CRMID			= @CRMID,
			Initials		= @Initials,
			Amidst			= @Amidst,
			Surname			= @Surname,
			Gender			= @Gender,
			Phone			= @Phone,
			Email			= @Email,
			DateOfBirth		= @DateOfBirth,
			FunctionCode	= @FunctionCode
	WHERE	ParticipantID = @ParticipantID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	evcwv.tblParticipant
						WHERE	ParticipantID = @ParticipantID
						FOR XML PATH )
END

IF @@ROWCOUNT > 0
--	Update SearchName
BEGIN
	UPDATE	evcwv.tblParticipant 
	SET		SearchName = sub.usfCreateSearchString(FullName)
	WHERE	ParticipantID = @ParticipantID
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @ParticipantID

	EXEC his.uspHistory_Add
			'evcwv.tblParticipant',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT ParticipantID = @ParticipantID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== evcwv.uspParticipant_Upd ==================================================================	*/
