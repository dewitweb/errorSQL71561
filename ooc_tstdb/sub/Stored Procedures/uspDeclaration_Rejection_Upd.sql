
CREATE PROCEDURE [sub].[uspDeclaration_Rejection_Upd]
@DeclarationID		int,
@RejectionReason	varchar(24),
@RejectionDateTime	smalldatetime,
@RejectionXML		xml,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_Rejection on the basis of 
				DeclarationID and RejectionReasonID.

	03-08-2018	Sander van Houten		CurrentUserID added.
	27-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(DeclarationID)
	FROM	sub.tblDeclaration_Rejection
	WHERE	DeclarationID = @DeclarationID
	  AND	RejectionReason = @RejectionReason) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Rejection
		(
			DeclarationID,
			RejectionReason,
			RejectionDateTime,
			RejectionXML
		)
	VALUES
		(
			@DeclarationID,
			@RejectionReason,
			@RejectionDateTime,
			@RejectionXML
		)

	SET	@DeclarationID = SCOPE_IDENTITY()

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM   sub.tblDeclaration_Rejection 
					   WHERE  DeclarationID = @DeclarationID 
						 AND  RejectionReason = @RejectionReason
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM   sub.tblDeclaration_Rejection 
					   WHERE  DeclarationID = @DeclarationID 
						 AND  RejectionReason = @RejectionReason
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclaration_Rejection
	SET
			RejectionDateTime	= @RejectionDateTime,
			RejectionXML		= @RejectionXML
	WHERE	DeclarationID		= @DeclarationID
	  AND	RejectionReason		= @RejectionReason

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblDeclaration_Rejection 
					   WHERE  DeclarationID = @DeclarationID 
						 AND  RejectionReason = @RejectionReason
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + @RejectionReason

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Rejection',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT	DeclarationID = @DeclarationID, 
		RejectionReason = @RejectionReason

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Rejection_Upd =======================================================	*/
