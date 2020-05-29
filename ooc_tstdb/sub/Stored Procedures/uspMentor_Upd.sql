
CREATE PROCEDURE [sub].[uspMentor_Upd]
@MentorID		int,
@EmployeeNumber	varchar(8),
@CRMID			int,
@Initials		varchar(10),
@Amidst			varchar(20),
@Surname		varchar(100),
@Gender			varchar(1),
@Phone			varchar(20),
@Email			varchar(254),
@DateOfBirth	date,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblMentor on basis of MentorID.

	02-05-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

IF (
		SELECT COUNT(EmployeeNumber)
		FROM	sub.tblEmployee 
		WHERE EmployeeNumber = ISNULL(@EmployeeNumber, 0)
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

IF ISNULL(@MentorID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblMentor
		(
			EmployeeNumber,
			CRMID,
			Initials,
			Amidst,
			Surname,
			Gender,
			Phone,
			Email,
			DateOfBirth
		)
	VALUES
		(
			@EmployeeNumber,
			@CRMID,
			@Initials,
			@Amidst,
			@Surname,
			@Gender,
			@Phone,
			@Email,
			@DateOfBirth
		)

	SET	@MentorID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblMentor
						WHERE	MentorID = @MentorID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblMentor
						WHERE	MentorID = @MentorID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblMentor
	SET
			EmployeeNumber	= @EmployeeNumber,
			CRMID			= @CRMID,
			Initials		= @Initials,
			Amidst			= @Amidst,
			Surname			= @Surname,
			Gender			= @Gender,
			Phone			= @Phone,
			Email			= @Email,
			DateOfBirth		= @DateOfBirth
	WHERE	MentorID = @MentorID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblMentor
						WHERE	MentorID = @MentorID
						FOR XML PATH )
END

IF @@ROWCOUNT > 0
--	Update SearchName
BEGIN
	UPDATE	sub.tblMentor 
	SET		SearchName = sub.usfCreateSearchString(FullName)
	WHERE	MentorID = @MentorID
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @MentorID

	EXEC his.uspHistory_Add
			'sub.tblMentor',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT MentorID = @MentorID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspMentor_Upd =====================================================================	*/
