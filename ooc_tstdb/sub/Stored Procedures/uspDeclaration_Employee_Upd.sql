
CREATE PROCEDURE [sub].[uspDeclaration_Employee_Upd]
@DeclarationID			int,
@EmployeeNumber			varchar(8),
@ReversalPaymentID		int,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Insert/Add a record into sub.tblDeclaration_Employee.

	29-10-2019	Jaap van Aassenbergh	OTIBSUB-1647 Verwijderen alle partieites terugboeken.
	20-11-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(1)
	FROM	sub.tblDeclaration_Employee
	WHERE	DeclarationID = @DeclarationID
	  AND	EmployeeNumber = @EmployeeNumber) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Employee
		(
			DeclarationID,
			EmployeeNumber
		)
	VALUES
		(
			@DeclarationID,
			@EmployeeNumber
		)

	-- Save new data
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
						FROM	sub.tblDeclaration_Employee
						WHERE	DeclarationID = @DeclarationID
						  AND	EmployeeNumber = @EmployeeNumber
						FOR XML PATH)

	-- Log action in tblHistory
	SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + @EmployeeNumber

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Employee',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END
--ELSE											-- There only are inserts in theis procedure and deletes in the _del procudere.
--BEGIN
--	-- An update means a reversalpayment.
--	DECLARE @RC				int,
--			@PartitionID	int

--	DECLARE cur_reversals CURSOR FOR 
--		SELECT 
--				PartitionID
--		FROM	sub.tblDeclaration_Partition
--		WHERE	DeclarationID = @DeclarationID

--	OPEN cur_reversals

--	FETCH NEXT FROM cur_reversals INTO @PartitionID

--	WHILE @@FETCH_STATUS = 0  
--	BEGIN
--		EXEC @RC = [sub].[uspDeclaration_Employee_ReversalPayment_Upd] 
--		   @DeclarationID
--		  ,@EmployeeNumber
--		  ,@PartitionID
--		  ,@CurrentUserID

--		FETCH NEXT FROM cur_reversals INTO @PartitionID
--	END

--	CLOSE cur_reversals
--	DEALLOCATE cur_reversals
--END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Employee_Upd ========================================================	*/
