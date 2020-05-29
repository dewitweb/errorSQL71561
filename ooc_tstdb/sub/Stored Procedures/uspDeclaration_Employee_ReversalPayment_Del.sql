CREATE PROCEDURE [sub].[uspDeclaration_Employee_ReversalPayment_Del]
@DeclarationID	int,
@EmployeeNumber	varchar(8),
@PartitionID	int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Remove Declaration_Employee_ReversalPayment record.

	21-02-2019	Sander van Houten		OTIBSUB-792	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT * 
				   FROM   sub.tblDeclaration_Employee_ReversalPayment
				   WHERE  DeclarationID = @DeclarationID
					 AND  EmployeeNumber = @EmployeeNumber
					 AND  PartitionID = @PartitionID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclaration_Employee_ReversalPayment
WHERE	DeclarationID = @DeclarationID
AND		EmployeeNumber = @EmployeeNumber
AND		PartitionID = @PartitionID

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

/*	== sub.uspDeclaration_Employee_ReversalPayment_Del ===========================================	*/
