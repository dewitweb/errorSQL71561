
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_Del]
@EmployerNumber		varchar(8),
@SubsidySchemeID	int,
@StartDate			date,
@CurrentUserID		int = 1
AS

/*	==========================================================================================
	Purpose:	Remove employer_subsidy record.

	13-08-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record sub.tblEmployer_Subsidy
SELECT	@XMLdel = (SELECT * 
				   FROM sub.tblEmployer_Subsidy
			       WHERE EmployerNumber = @EmployerNumber
				     AND SubsidySchemeID = @SubsidySchemeID
					 AND StartDate = @StartDate
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record sub.tblEmployer_Subsidy
DELETE
FROM	sub.tblEmployer_Subsidy
WHERE	EmployerNumber = @EmployerNumber
  AND	SubsidySchemeID = @SubsidySchemeID
  AND	StartDate = @StartDate
	
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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_Del ===========================================================	*/
