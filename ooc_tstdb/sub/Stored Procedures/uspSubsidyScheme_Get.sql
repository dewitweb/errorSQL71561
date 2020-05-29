
CREATE PROCEDURE [sub].[uspSubsidyScheme_Get]
	@SubsidySchemeID	int
AS
/*	==========================================================================================
	18-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblSubsidyScheme op basis van SubsidySchemeID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			SubsidySchemeID,
			SubsidySchemeName,
			ActiveFromDate
	FROM	sub.tblSubsidyScheme
	WHERE	SubsidySchemeID = @SubsidySchemeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspSubsidyScheme_Get ===================================================================	*/
