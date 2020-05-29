
CREATE PROCEDURE [auth].[uspUserValidation_Get]
@UserID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from auth.tblUserValidation on basis of UserID.

	17-01-2019	Sander van Houten		Record must exist. So if not... insert.
	21-11-2018	Jaap van Assenbergh		Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

IF NOT EXISTS (SELECT 1 FROM auth.tblUserValidation WHERE UserID = @UserID)
BEGIN
	DECLARE @RC int,
			@ContactDetailsCheck bit = 0,
			@AgreementCheck bit = 0,
			@EmailCheck bit = 0,
			@EmailValidationToken varchar(50) = NULL,
			@EmailValidationDateTime datetime = NULL,
			@CurrentUserID int = 1

	DECLARE @tblUserValidation TABLE (UserID int)

	INSERT INTO @tblUserValidation	-- Voorkomt een resultset naar de front-end
	EXECUTE [auth].[uspUserValidation_Upd] 
		@UserID,
		@ContactDetailsCheck,
		@AgreementCheck,
		@EmailCheck,
		@EmailValidationToken,
		@EmailValidationDateTime,
		@CurrentUserID
END

SELECT
		UserID,
		ContactDetailsCheck,
		AgreementCheck,
		EmailCheck,
		EmailValidationToken,
		EmailValidationDateTime
FROM	auth.tblUserValidation
WHERE	UserID = @UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspUserValidation_Get =================================================================	*/
