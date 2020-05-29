CREATE PROCEDURE [sub].[uspDeclaration_Rejection_Del]
@DeclarationID		int,
@PartitionID		int,
@RejectionReason	varchar(24),
@CurrentUserID		int = 1
AS

/*	==========================================================================================
	Purpose:	Remove tblDeclaration_Rejection record.

	02-08-2018	Sander van Houten		CurrentUserID added.
	27-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (
					SELECT	* 
					FROM	sub.tblDeclaration_Rejection
					WHERE	DeclarationID = @DeclarationID
					AND		PartitionID = @PartitionID
					AND		RejectionReason = @RejectionReason
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclaration_Rejection
WHERE	DeclarationID = @DeclarationID
  AND	RejectionReason = @RejectionReason

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + CAST(@PartitionID AS varchar(18)) + '|' + @RejectionReason

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Rejection',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Rejection_Del =======================================================	*/
