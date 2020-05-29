
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_Upd]
@EmployerNumber					varchar(8),
@SubsidySchemeID				int,
@StartDate						date,
@EndDate						date,
@Amount							decimal(19,4),
@SubsidyAmountPerEmployer		decimal(19,4),
@SubsidyAmountPerEmployee		decimal(19,4),
@NrOfEmployees					int, 
@NrOfEmployeesWithoutSubsidy	int,
@ChangeReason					varchar(max),
@CurrentUserID					int = 1
AS
/*	==========================================================================================
	Purpose:	Add/Update sub.tblEmployer on the basis of EmployerNumber, @SubsidySchemeID 
																				and StartDate.

	13-08-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(EmployerNumber)
	FROM	sub.tblEmployer_Subsidy
	WHERE	EmployerNumber = @EmployerNumber
	  AND	SubsidySchemeID = @SubsidySchemeID
	  AND	StartDate = @StartDate) = 0
BEGIN
	INSERT INTO sub.tblEmployer_Subsidy
		(
			EmployerNumber,
			SubsidySchemeID,
			StartDate,
			EndDate,
			Amount,
			ChangeReason,
			SubsidyAmountPerEmployer,
			SubsidyAmountPerEmployee,
			NumberOfEmployee,
			NumberOfEmployee_WithoutSubsidy
		)
	VALUES
		(
			@EmployerNumber,
			@SubsidySchemeID,
			@StartDate,
			@EndDate,
			@Amount,
			@ChangeReason,
			@SubsidyAmountPerEmployer,
			@SubsidyAmountPerEmployee,
			@NrOfEmployees, 
			@NrOfEmployeesWithoutSubsidy
		)

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM sub.tblEmployer_Subsidy
					   WHERE EmployerNumber = @EmployerNumber
						 AND SubsidySchemeID = @SubsidySchemeID
						 AND StartDate = @StartDate
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM sub.tblEmployer_Subsidy
					   WHERE EmployerNumber = @EmployerNumber
						 AND SubsidySchemeID = @SubsidySchemeID
						 AND StartDate = @StartDate
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblEmployer_Subsidy
	SET
			EndDate	= @EndDate,
			Amount = @Amount,
			ChangeReason = @ChangeReason,
			SubsidyAmountPerEmployer = @SubsidyAmountPerEmployer,
			SubsidyAmountPerEmployee = @SubsidyAmountPerEmployee,
			NumberOfEmployee = @NrOfEmployees, 
			NumberOfEmployee_WithoutSubsidy = @NrOfEmployeesWithoutSubsidy
	WHERE	EmployerNumber = @EmployerNumber
	  AND	SubsidySchemeID = @SubsidySchemeID
	  AND	StartDate = @StartDate

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM sub.tblEmployer_Subsidy
					   WHERE EmployerNumber = @EmployerNumber
						 AND SubsidySchemeID = @SubsidySchemeID
						 AND StartDate = @StartDate
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @EmployerNumber + '|' + CONVERT(varchar(18), @SubsidySchemeID) + '|' + CONVERT(varchar(10), @StartDate, 105)

	EXEC his.uspHistory_Add
			'sub.tblEmployer_Subsidy',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

--SELECT EmployerNumber = @EmployerNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_Upd ===========================================================	*/
