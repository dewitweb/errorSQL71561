
CREATE PROCEDURE [sub].[uspDeclaration_Employee_Del]
@DeclarationID	int,
@EmployeeNumber	varchar(8),
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Remove Declaration_Employee record.

	21-02-2019	Sander van Houten		OTIBSUB-792	Manier van vastlegging terugboeking 
										bij werknemer veranderen.
	02-08-2018	Sander van Houten		CurrentUserID added.
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

/* First remove all records from tblDeclaration_Employee_ReversalPayment.	*/
DECLARE @RC				int,
		@PartitionID	int

DECLARE cur_reversals CURSOR FOR 
	SELECT 
			PartitionID
	FROM	sub.tblDeclaration_Employee_ReversalPayment
	WHERE	DeclarationID = @DeclarationID
	  AND	EmployeeNumber = @EmployeeNumber

OPEN cur_reversals

FETCH NEXT FROM cur_reversals INTO @PartitionID

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXEC @RC = [sub].[uspDeclaration_Employee_ReversalPayment_Del] 
	   @DeclarationID
	  ,@EmployeeNumber
	  ,@PartitionID
	  ,@CurrentUserID

	FETCH NEXT FROM cur_reversals INTO @PartitionID
END

CLOSE cur_reversals
DEALLOCATE cur_reversals

/* Then proceed with tblDeclaration_Employee.	*/
-- Save old record
SELECT	@XMLdel = (SELECT * 
				   FROM   sub.tblDeclaration_Employee
				   WHERE  DeclarationID = @DeclarationID
					 AND  EmployeeNumber = @EmployeeNumber
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclaration_Employee
WHERE	DeclarationID = @DeclarationID
AND		EmployeeNumber = @EmployeeNumber

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + @EmployeeNumber

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Employee',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Employee_Del ========================================================	*/
