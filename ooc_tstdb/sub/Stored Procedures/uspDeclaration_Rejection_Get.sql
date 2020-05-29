
CREATE PROCEDURE [sub].[uspDeclaration_Rejection_Get]
	@DeclarationID		int,
	@RejectionReason	varchar(24)
AS
/*	==========================================================================================
	27-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblDeclaration_Rejection op basis van DeclarationID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			DeclarationID,
			RejectionReason,
			RejectionDateTime,
			RejectionXML
	FROM	sub.tblDeclaration_Rejection
	WHERE	DeclarationID = @DeclarationID
	AND		RejectionReason = @RejectionReason

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Rejection_Get ===========================================================	*/
