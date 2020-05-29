
CREATE PROCEDURE [sub].[uspDeclaration_Employee_ReversalPayment_Upd]
@DeclarationID			int,
@EmployeeNumber			varchar(8),
@PartitionID			int,
@ReversalPaymentID		int,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Insert/Add a record into sub.tblDeclaration_Employee_ReversalPayment.

	21-02-2019	Sander van Houten		OTIBSUB-792	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(1)
	FROM	sub.tblDeclaration_Employee_ReversalPayment
	WHERE	DeclarationID = @DeclarationID
	  AND	EmployeeNumber = @EmployeeNumber
	  AND	PartitionID = @PartitionID ) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Employee_ReversalPayment
		(
			DeclarationID,
			EmployeeNumber,
			PartitionID,
			ReversalPaymentID
		)
	VALUES
		(
			@DeclarationID,
			@EmployeeNumber,
			@PartitionID,
			@ReversalPaymentID
		)

	-- Save new data
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
						FROM	sub.tblDeclaration_Employee_ReversalPayment
						WHERE	DeclarationID = @DeclarationID
						  AND	EmployeeNumber = @EmployeeNumber
						  AND	PartitionID = @PartitionID
						FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
						FROM	sub.tblDeclaration_Employee_ReversalPayment
						WHERE	DeclarationID = @DeclarationID
						  AND	EmployeeNumber = @EmployeeNumber
						  AND	PartitionID = @PartitionID
						FOR XML PATH)

	-- Update existing record
	UPDATE	sub.tblDeclaration_Employee_ReversalPayment
	SET
			ReversalPaymentID	= @ReversalPaymentID
	WHERE	DeclarationID = @DeclarationID
	  AND	EmployeeNumber = @EmployeeNumber
	  AND	PartitionID = @PartitionID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
						FROM	sub.tblDeclaration_Employee_ReversalPayment
						WHERE	DeclarationID = @DeclarationID
						  AND	EmployeeNumber = @EmployeeNumber
						  AND	PartitionID = @PartitionID
						FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + @EmployeeNumber + '|' + CAST(@PartitionID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Employee_ReversalPayment',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Employee_ReversalPayment_Upd =======================================	*/
