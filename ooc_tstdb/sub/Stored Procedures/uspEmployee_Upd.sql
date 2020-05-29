
CREATE PROCEDURE [sub].[uspEmployee_Upd]
@EmployeeNumber	varchar(8),
@Initials		varchar(10),
@Amidst			varchar(20),
@Surname		varchar(200),
@Gender			varchar(1),
@AmidstSpous	varchar(10),
@SurnameSpous	varchar(100),
@Email			varchar(254),
@IBAN			varchar(34),
@DateOfBirth	date,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployee on the basis of EmployeeNumber.

	15-11-2018	Sander van Houten		Added extended name data.
	02-08-2018	Sander van Houten		CurrentUserID added.
	20-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

IF (SELECT	COUNT(EmployeeNumber)
	FROM	sub.tblEmployee
	WHERE	EmployeeNumber = @EmployeeNumber) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblEmployee
		(
			EmployeeNumber,
			Initials,
			Amidst,
			Surname,
			Gender,
			AmidstSpous,
			SurnameSpous,
			Email,
			IBAN,
			DateOfBirth
		)
	VALUES
		(
			@EmployeeNumber,
			@Initials,
			@Amidst,
			@Surname,
			@Gender,
			@AmidstSpous,
			@SurnameSpous,
			@Email,
			@IBAN,
			@DateOfBirth
		)
END
ELSE
BEGIN
	-- Update exisiting record
	UPDATE	sub.tblEmployee
	SET
			Initials		= @Initials,
			Amidst			= @Amidst,
			Surname			= @Surname,
			Gender			= @Gender,
			AmidstSpous		= @AmidstSpous,
			SurnameSpous	= @SurnameSpous,
			Email			= @Email,
			IBAN			= @IBAN,
			DateOfBirth		= @DateOfBirth
	WHERE	EmployeeNumber	= @EmployeeNumber
END

--	Update SearchName
IF @@ROWCOUNT > 0
BEGIN
	UPDATE	sub.tblEmployee
	SET		SearchName = sub.usfCreateSearchString(FullName)
	WHERE	EmployeeNumber = @EmployeeNumber
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Upd ====================================================================	*/
