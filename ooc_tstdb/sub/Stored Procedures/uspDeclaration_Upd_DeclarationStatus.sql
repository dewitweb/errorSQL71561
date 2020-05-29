CREATE PROCEDURE [sub].[uspDeclaration_Upd_DeclarationStatus]
@DeclarationID		int,
@DeclarationStatus	varchar(24),
@StatusReason		varchar(max),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Update status only

	04-07-2019	Sander van Houten		OTIBSUB-1323	Only write a new log record if there 
											is a change in status (this is not the case if 
											an employer still has a paymentarrear.
	10-01-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record.
SELECT	@XMLdel = (SELECT * 
				   FROM   sub.tblDeclaration 
				   WHERE  DeclarationID = @DeclarationID
				   FOR XML PATH)

-- Update exisiting record.
UPDATE	sub.tblDeclaration
SET
		DeclarationStatus	= @DeclarationStatus,
		StatusReason		= @StatusReason
WHERE	DeclarationID		= @DeclarationID

-- Save new record
SELECT	@XMLins = (SELECT * 
				   FROM   sub.tblDeclaration 
				   WHERE  DeclarationID = @DeclarationID
				   FOR XML PATH)

-- Log action in tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	DECLARE @PreviousDeclarationStatus	varchar(4)

	SET @KeyID = CAST(@DeclarationID AS varchar(18))

	-- First check on last log on declaration.
	SELECT	@PreviousDeclarationStatus = x.r.value('DeclarationStatus[1]', 'varchar(4)')
	FROM	his.tblHistory
	CROSS APPLY NewValue.nodes('row') AS x(r)
	WHERE	HistoryID IN (
							SELECT	MAX(HistoryID)	AS MaxHistoryID
							FROM	his.tblHistory
							WHERE	TableName = 'sub.tblDeclaration'
							AND		KeyID = @KeyID
						 )

	-- Only write a new log record if there is a change in status
	-- (this is not the case if an employer still has a paymentarrear).
	IF @DeclarationStatus <> @PreviousDeclarationStatus
	BEGIN
		EXEC his.uspHistory_Add
				'sub.tblDeclaration',
				@KeyID,
				@CurrentUserID,
				@LogDate,
				@XMLdel,
				@XMLins
	END
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Upd_DeclarationStatus ==============================================	*/
